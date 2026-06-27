"""coach node + full-graph grounding tests (Plan 14-02 Task 2) — model-free `code` checks.

The D1 / D7 / D9 hard checks plus the conditional-edge routing, all with the node models
monkeypatched (no network):
  * (D7) the coach decision is exactly one tool call whose name is in the closed 4-set;
  * (D1/G3) a forced `advance` on a fail is rewritten to `say` and `advance` is never emitted;
  * (G4) a `present_activity` with an unauthored letter_id is rejected to `say`;
  * (D9/G5) an injected StructuredOutputError / timeout degrades to the client AuthoredFallback;
  * (routing) a clean no-struggle pass takes analyze -> coach (plan NOT invoked); a struggle takes
    analyze -> plan -> coach.
"""

from __future__ import annotations

import pytest

pytestmark = pytest.mark.code

from app.graph import build_graph
from app.nodes import StructuredOutputError
from app.nodes.analyze import Insight
from app.nodes.coach import coach
from app.nodes.plan import Plan, plan
from app.tools import ACTION_TOOL_NAMES


# --- Fakes ---------------------------------------------------------------------------------


class _FakeResp:
    def __init__(self, tool_calls):
        self.tool_calls = tool_calls


class _FakeBoundCoach:
    def __init__(self, tool_calls):
        self._tool_calls = tool_calls

    def invoke(self, _messages):
        return _FakeResp(self._tool_calls)


class _FakeStructured:
    def __init__(self, obj):
        self._obj = obj

    def invoke(self, _messages):
        return self._obj


class _FakeModel:
    def __init__(self, obj):
        self._obj = obj

    def with_structured_output(self, _schema, method=None):
        return _FakeStructured(self._obj)


FAIL_FACTS = {
    "letterId": "baa",
    "section": "traceLetter",
    "passed": False,
    "mistakeId": "shallowBowl",
    "struggleTags": ["boat-curvature"],
    "recentMistakes": ["shallowBowl"],
    "trajectory": [{"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter"}],
    "strengthTags": [],
}

PASS_FACTS = {
    "letterId": "baa",
    "section": "traceLetter",
    "passed": True,
    "mistakeId": None,
    "struggleTags": [],
    "recentMistakes": [],
    "trajectory": [{"passed": True, "mistakeId": None, "section": "traceLetter"}],
    "strengthTags": ["deep-bowl"],
}


def _patch_coach_only(monkeypatch, tool_calls):
    import app.nodes.coach as coach_mod

    monkeypatch.setattr(coach_mod, "build_coach_with_tools", lambda: _FakeBoundCoach(tool_calls))


# --- D7: exactly one in-set tool call -----------------------------------------------------


def test_coach_emits_exactly_one_in_set_tool(monkeypatch):
    _patch_coach_only(monkeypatch, [{"name": "say", "args": {"text": "deeper curve"}}])
    out = coach({"facts": FAIL_FACTS})
    assert out["decision"]["name"] in ACTION_TOOL_NAMES
    assert out["decision"]["name"] == "say"
    assert out["grounded"] is True


def test_coach_out_of_set_name_rejected_to_say(monkeypatch):
    _patch_coach_only(monkeypatch, [{"name": "set_verdict", "args": {"passed": True}}])
    out = coach({"facts": FAIL_FACTS})
    assert out["decision"]["name"] == "say"  # 5th/unknown action rejected (G2)
    assert out["grounded"] is False


def test_coach_no_tool_call_degrades_to_say(monkeypatch):
    _patch_coach_only(monkeypatch, [])
    out = coach({"facts": FAIL_FACTS})
    assert out["decision"]["name"] == "say"
    assert out["decision"]["args"].get("text")


# --- D1 / G3: advance on a fail is rewritten; never emitted -------------------------------


def test_coach_advance_on_fail_rewritten(monkeypatch):
    _patch_coach_only(monkeypatch, [{"name": "advance", "args": {}}])
    out = coach({"facts": FAIL_FACTS})
    assert out["decision"]["name"] == "say"   # never advance on a fail
    assert out["decision"]["name"] != "advance"
    assert out["grounded"] is False
    assert out["decision"]["args"].get("text")


def test_coach_advance_on_pass_allowed(monkeypatch):
    _patch_coach_only(monkeypatch, [{"name": "advance", "args": {}}])
    out = coach({"facts": PASS_FACTS})
    assert out["decision"]["name"] == "advance"
    assert out["grounded"] is True


# --- G4: unauthored present_activity letter_id rejected -----------------------------------


def test_coach_present_activity_unauthored_rejected(monkeypatch):
    _patch_coach_only(
        monkeypatch,
        [{"name": "present_activity", "args": {"letter_id": "baa.fake.exercise", "coaching_line": "go"}}],
    )
    out = coach({"facts": FAIL_FACTS})
    assert out["decision"]["name"] == "say"  # fabricated id rejected (G4)
    assert out["grounded"] is False


def test_coach_present_activity_authored_allowed(monkeypatch):
    _patch_coach_only(
        monkeypatch,
        [
            {
                "name": "present_activity",
                "args": {"letter_id": "baa.traceLetter.isolated", "coaching_line": "deeper curve"},
            }
        ],
    )
    out = coach({"facts": FAIL_FACTS})
    assert out["decision"]["name"] == "present_activity"  # authored id passes
    assert out["grounded"] is True


# --- G4 on the plan node: an unauthored next_exercise_id is rejected (graph guards present) ---


def test_plan_unauthored_id_rejected_by_g4(monkeypatch):
    """G4 stays the inner membership guard on the plan node even with the G5/G6 graph rail added:
    a fabricated next_exercise_id fails closed BEFORE the graph guards ever look at it."""
    import app.nodes.plan as plan_mod

    monkeypatch.setattr(
        plan_mod,
        "build_plan_model",
        lambda: _FakeModel(
            Plan(
                next_exercise_id="baa.fake.exercise",  # not in AUTHORED_BAA_IDS
                intent="drill_isolated",
                rationale="fabricated id",
            )
        ),
    )
    facts = {
        **FAIL_FACTS,
        "clearedTiers": ["manqul", "manzur"],
        "clearedCompetencies": ["recognize", "positionalForms"],
    }
    with pytest.raises(StructuredOutputError):
        plan({"facts": facts, "insight": {}})


# --- Full-graph routing: analyze -> coach on a clean pass; analyze -> plan -> coach else ---


def _patch_all(monkeypatch, *, insight, plan_obj, coach_calls, plan_spy=None):
    import app.nodes.analyze as analyze_mod
    import app.nodes.coach as coach_mod
    import app.nodes.plan as plan_mod

    monkeypatch.setattr(analyze_mod, "build_analyze_model", lambda: _FakeModel(insight))
    monkeypatch.setattr(coach_mod, "build_coach_with_tools", lambda: _FakeBoundCoach(coach_calls))

    if plan_spy is not None:
        orig_plan = plan_mod.plan

        def spy(state):
            plan_spy["called"] = True
            monkeypatch.setattr(plan_mod, "build_plan_model", lambda: _FakeModel(plan_obj))
            return orig_plan(state)

        monkeypatch.setattr(plan_mod, "plan", spy)
        import app.graph as graph_mod

        monkeypatch.setattr(graph_mod, "plan", spy)
    else:
        monkeypatch.setattr(plan_mod, "build_plan_model", lambda: _FakeModel(plan_obj))


async def test_clean_pass_skips_plan(monkeypatch):
    plan_spy = {"called": False}
    _patch_all(
        monkeypatch,
        insight=Insight(struggle_tags=[], strength_tags=["deep-bowl"], pattern_note="clean"),
        plan_obj=Plan(next_exercise_id="baa.traceLetter.isolated", intent="advance", rationale="x"),
        coach_calls=[{"name": "advance", "args": {}}],
        plan_spy=plan_spy,
    )

    graph = build_graph()
    result = await graph.ainvoke(
        {"facts": PASS_FACTS, "log": []}, {"configurable": {"thread_id": "t-pass"}}
    )

    assert plan_spy["called"] is False          # plan node NOT invoked on a clean pass
    assert "analyze" in result["log"]
    assert "plan" not in result["log"]
    assert "coach" in result["log"]
    assert result["decision"]["name"] == "advance"


async def test_struggle_runs_plan(monkeypatch):
    plan_spy = {"called": False}
    _patch_all(
        monkeypatch,
        insight=Insight(struggle_tags=["boat-curvature"], strength_tags=[], pattern_note="shallow"),
        plan_obj=Plan(
            next_exercise_id="baa.traceLetter.isolated", intent="drill_isolated", rationale="x"
        ),
        coach_calls=[{"name": "say", "args": {"text": "deeper curve at the bottom"}}],
        plan_spy=plan_spy,
    )

    graph = build_graph()
    result = await graph.ainvoke(
        {"facts": FAIL_FACTS, "log": []}, {"configurable": {"thread_id": "t-fail"}}
    )

    assert plan_spy["called"] is True           # plan node invoked on a struggle
    assert result["log"] == ["analyze", "plan", "coach"]
    assert result["decision"]["name"] == "say"
    assert result["grounded"] is True


# --- D9 / G5: a StructuredOutputError degrades to the client AuthoredFallback (503) --------


async def test_endpoint_degrades_on_structured_error(monkeypatch):
    """An exhausted-retry / curriculum failure in analyze yields the 503 the client maps to fallback."""
    import httpx

    import app.nodes.analyze as analyze_mod
    from app.main import app as fastapi_app
    from app.nodes import StructuredOutputError
    from tests.conftest import VALID_AUTH_HEADERS

    def boom(_state):
        raise StructuredOutputError("forced for the degradation test")

    monkeypatch.setattr(analyze_mod, "analyze", boom)
    import app.graph as graph_mod

    monkeypatch.setattr(graph_mod, "analyze", boom)
    # Rebuild the cached graph so it picks up the patched node.
    from app.main import _graph

    _graph.cache_clear()

    transport = httpx.ASGITransport(app=fastapi_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as ac:
        resp = await ac.post("/coach", json=FAIL_FACTS, headers=VALID_AUTH_HEADERS)

    assert resp.status_code == 503  # structured non-200 -> client AuthoredFallback (never a 200-empty)
    _graph.cache_clear()
