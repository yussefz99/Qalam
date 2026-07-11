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


class _CapturingBoundCoach:
    """Like _FakeBoundCoach but records the messages it was invoked with, so a test can assert
    what the coach node placed in the SystemMessage (the Phase-17 addendum trigger, 17-05)."""

    def __init__(self, tool_calls):
        self._tool_calls = tool_calls
        self.messages = None

    def invoke(self, messages):
        self.messages = messages
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
    # 17.2 always-speak rail: advance on a PASS is semantically fine (G3 does not fire,
    # grounded stays True), but a WORD-LESS action renders as silence on-device now that
    # the authored floor is retired (owner directive 2026-07-07) — so it is coerced to a
    # spoken `say` with a verdict-aware line, args preserved.
    _patch_coach_only(monkeypatch, [{"name": "advance", "args": {}}])
    out = coach({"facts": PASS_FACTS})
    assert out["decision"]["name"] == "say"
    assert out["decision"]["args"].get("text")  # never word-less
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
    # 17.2 always-speak rail: the word-less advance is coerced to a spoken say.
    assert result["decision"]["name"] == "say"
    assert result["decision"]["args"].get("text")


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


# --- Phase 17 (STRK-01, 17-05): the criterion-aware addendum trigger ----------------------
# The coach appends COACH_STROKE_ADDENDUM when the FACTS carry any DERIVED evidence of THIS
# attempt — strokeDiff OR the structured `criteria` OR the F6 `writtenWord`. The trigger is
# additive: label-only facts append nothing (prior behavior byte-identical). The G2/G3/G4
# guards are unaffected by the trigger (regression-pinned below).

_CRITERIA_FAIL = [
    {"criterion": "strokeCount", "zone": "certainlyCorrect", "score": 1.0},
    {"criterion": "shape", "zone": "certainlyWrong", "score": 0.0},
    {"criterion": "dot", "zone": "certainlyCorrect", "score": 1.0},
]


def _capture_system_prompt(monkeypatch, facts, tool_calls):
    import app.nodes.coach as coach_mod

    fake = _CapturingBoundCoach(tool_calls)
    monkeypatch.setattr(coach_mod, "build_coach_with_tools", lambda: fake)
    coach({"facts": facts})
    return fake.messages[0].content


def test_addendum_appended_on_criteria_without_strokediff(monkeypatch):
    """FACTS carrying only the structured `criteria` (no strokeDiff) still triggers the stroke
    addendum — the STRK-01 transport of the per-criterion result to the coach."""
    from app.prompts import COACH_STROKE_ADDENDUM

    facts = {**FAIL_FACTS, "criteria": _CRITERIA_FAIL, "weakestCriterion": "shape"}
    assert "strokeDiff" not in facts
    system_prompt = _capture_system_prompt(
        monkeypatch, facts, [{"name": "say", "args": {"text": "deeper curve"}}]
    )
    assert COACH_STROKE_ADDENDUM in system_prompt


def test_addendum_appended_on_writtenword_only(monkeypatch):
    """FACTS carrying only the F6 word facts (writtenWord/expectedWord, no strokeDiff/criteria)
    still triggers the addendum so word/sentence coaching can be specific (UAT F6)."""
    from app.prompts import COACH_STROKE_ADDENDUM

    facts = {**PASS_FACTS, "expectedWord": "باب", "writtenWord": "داد"}
    assert "strokeDiff" not in facts and "criteria" not in facts
    system_prompt = _capture_system_prompt(
        monkeypatch, facts, [{"name": "say", "args": {"text": "so close"}}]
    )
    assert COACH_STROKE_ADDENDUM in system_prompt


def test_no_addendum_when_no_derived_facts(monkeypatch):
    """A label-only payload (no strokeDiff/criteria/writtenWord) appends NOTHING — the prior
    behavior stays byte-identical (the addendum trigger is purely additive)."""
    from app.prompts import COACH_PROMPT, COACH_STROKE_ADDENDUM

    system_prompt = _capture_system_prompt(
        monkeypatch, FAIL_FACTS, [{"name": "say", "args": {"text": "deeper curve"}}]
    )
    assert system_prompt == COACH_PROMPT
    assert COACH_STROKE_ADDENDUM not in system_prompt


def test_g3_advance_on_fail_still_rewritten_with_criteria(monkeypatch):
    """Guards regression: the G3 advance-on-fail verdict lock still fires on a criteria-bearing
    fail — the addendum trigger never weakens the guard ladder (G2/G3/G4 byte-unchanged)."""
    facts = {**FAIL_FACTS, "criteria": _CRITERIA_FAIL, "weakestCriterion": "shape"}
    _patch_coach_only(monkeypatch, [{"name": "advance", "args": {}}])
    out = coach({"facts": facts})
    assert out["decision"]["name"] == "say"  # never advance on a fail, even with criteria
    assert out["grounded"] is False


# --- Phase 17.2 (demo): the next-exercise proposal addendum + the candidate-list RAIL ------
# When the FACTS carry `legalNextExerciseIds`, the coach ALSO proposes the next exercise FROM that
# list (Option B: announced in the line). The RAIL in coach.py strips any proposed nextExerciseId
# NOT in the candidate list, so an illegal / hallucinated / off-graph id is NEVER forwarded.

_CANDIDATES = ["baa.traceLetter.isolated", "baa.writeWord.dictation"]
_FAIL_WITH_CANDIDATES = {**FAIL_FACTS, "legalNextExerciseIds": _CANDIDATES}


def test_next_exercise_addendum_appended_when_candidates_present(monkeypatch):
    """FACTS carrying `legalNextExerciseIds` append the next-exercise addendum so the coach can
    propose the next step FROM the graph (17.2 demo). Additive: no candidates → not appended."""
    from app.prompts import COACH_NEXT_EXERCISE_ADDENDUM

    system_prompt = _capture_system_prompt(
        monkeypatch, _FAIL_WITH_CANDIDATES, [{"name": "say", "args": {"text": "deeper curve"}}]
    )
    assert COACH_NEXT_EXERCISE_ADDENDUM in system_prompt


def test_no_next_exercise_addendum_without_candidates(monkeypatch):
    """A payload with no `legalNextExerciseIds` appends no next-exercise addendum — the prior
    behavior stays byte-identical (the trigger is purely additive)."""
    from app.prompts import COACH_NEXT_EXERCISE_ADDENDUM

    system_prompt = _capture_system_prompt(
        monkeypatch, FAIL_FACTS, [{"name": "say", "args": {"text": "deeper curve"}}]
    )
    assert COACH_NEXT_EXERCISE_ADDENDUM not in system_prompt


def test_next_exercise_rail_keeps_a_legal_proposed_id(monkeypatch):
    """A proposed nextExerciseId that IS in the candidate list is forwarded untouched (with its
    rationale) — the client acts on the graph-legal pick."""
    _patch_coach_only(
        monkeypatch,
        [
            {
                "name": "say",
                "args": {
                    "text": "Lovely deep bowl — ready for the next form?",
                    "nextExerciseId": "baa.writeWord.dictation",
                    "rationale": "clean pass, move forward",
                },
            }
        ],
    )
    out = coach({"facts": _FAIL_WITH_CANDIDATES})
    assert out["decision"]["name"] == "say"
    assert out["decision"]["args"]["nextExerciseId"] == "baa.writeWord.dictation"
    assert out["decision"]["args"]["rationale"] == "clean pass, move forward"


def test_next_exercise_rail_strips_an_illegal_proposed_id(monkeypatch):
    """A proposed nextExerciseId NOT in the candidate list is STRIPPED (with its now-orphaned
    rationale) and never forwarded — the coach can never smuggle an off-graph exercise to the
    client. The spoken line is advisory and left as-is."""
    _patch_coach_only(
        monkeypatch,
        [
            {
                "name": "say",
                "args": {
                    "text": "Deeper curve at the bottom — try that dot once more.",
                    "nextExerciseId": "baa.fake.notInGraph",  # NOT in _CANDIDATES
                    "rationale": "hallucinated pick",
                },
            }
        ],
    )
    out = coach({"facts": _FAIL_WITH_CANDIDATES})
    assert out["decision"]["name"] == "say"
    assert "nextExerciseId" not in out["decision"]["args"]  # stripped — never forwarded
    assert "rationale" not in out["decision"]["args"]  # the orphaned rationale goes too
    assert out["decision"]["args"]["text"]  # the advisory line survives unchanged


def test_next_exercise_rail_strips_any_id_when_no_candidates_provided(monkeypatch):
    """With no `legalNextExerciseIds` in the FACTS, ANY proposed id is stripped (fail closed) —
    the coach may never forward an id the client did not authorize."""
    _patch_coach_only(
        monkeypatch,
        [
            {
                "name": "say",
                "args": {"text": "deeper curve", "nextExerciseId": "baa.traceLetter.isolated"},
            }
        ],
    )
    out = coach({"facts": FAIL_FACTS})  # no candidate list at all
    assert "nextExerciseId" not in out["decision"]["args"]


# --- Phase 18 (18-08): the pick's WHY is grounded on the COACH path (fires on BOTH branches) + the
# next-exercise rail is CASING-SAFE (a snake_case `next_exercise_id` bypass is closed) ---------------

_PASS_WITH_CANDIDATES = {**PASS_FACTS, "legalNextExerciseIds": _CANDIDATES, "weakestCriterion": "dot"}


def test_next_exercise_addendum_grounds_why_in_weakest_criterion():
    """18-08 (D-10): the WHY grounding lives on the COACH path — the addendum names the targeted
    `weakestCriterion` and frames a `microDrill` pick as a warm named step-down. This is the ONLY
    place the WHY can cover the clean-pass branch (the plan node is skipped there)."""
    from app.prompts import COACH_NEXT_EXERCISE_ADDENDUM

    assert "weakestCriterion" in COACH_NEXT_EXERCISE_ADDENDUM
    assert "microDrill" in COACH_NEXT_EXERCISE_ADDENDUM
    # ADR-014: the WHY never claims a pass / mastery / star — the addendum explicitly forbids it.
    lowered = COACH_NEXT_EXERCISE_ADDENDUM.lower()
    assert "mastered" in lowered and "star" in lowered


def test_clean_pass_branch_gets_why_grounded_addendum(monkeypatch):
    """On a CLEAN pass (passed=true, no struggleTags) the plan node is SKIPPED (see
    test_clean_pass_skips_plan), so the WHY must ride on the coach path: with candidates present the
    coach system prompt carries the WHY-grounded next-exercise addendum even on the pass branch."""
    from app.prompts import COACH_NEXT_EXERCISE_ADDENDUM

    system_prompt = _capture_system_prompt(
        monkeypatch, _PASS_WITH_CANDIDATES, [{"name": "say", "args": {"text": "beautiful bowl"}}]
    )
    assert COACH_NEXT_EXERCISE_ADDENDUM in system_prompt


def test_next_exercise_rail_strips_illegal_snake_case_id(monkeypatch):
    """18-08 CASING HOLE CLOSED: a snake_case `next_exercise_id` proposal OUTSIDE the candidates is
    stripped exactly like the camelCase key. main.py renames snake→camel AFTER this rail, so an
    unrailed snake_case emission would bypass candidate validation and reach the client."""
    _patch_coach_only(
        monkeypatch,
        [
            {
                "name": "say",
                "args": {
                    "text": "Deeper curve — try that dot once more.",
                    "next_exercise_id": "baa.fake.notInGraph",  # snake_case, NOT in _CANDIDATES
                    "rationale": "hallucinated pick",
                },
            }
        ],
    )
    out = coach({"facts": _FAIL_WITH_CANDIDATES})
    assert out["decision"]["name"] == "say"
    assert "next_exercise_id" not in out["decision"]["args"]  # stripped — the bypass is closed
    assert "nextExerciseId" not in out["decision"]["args"]
    assert "rationale" not in out["decision"]["args"]  # the orphaned rationale goes too
    assert out["decision"]["args"]["text"]  # the advisory line survives unchanged


def test_next_exercise_rail_keeps_a_legal_snake_case_id(monkeypatch):
    """A snake_case `next_exercise_id` that IS in the candidates survives the casing-safe rail (it must
    not over-strip a legal pick); main.py renames it to `nextExerciseId` on the wire."""
    _patch_coach_only(
        monkeypatch,
        [
            {
                "name": "say",
                "args": {
                    "text": "Lovely — ready for the next form?",
                    "next_exercise_id": "baa.writeWord.dictation",  # snake_case, IN _CANDIDATES
                    "rationale": "clean pass, move forward",
                },
            }
        ],
    )
    out = coach({"facts": _FAIL_WITH_CANDIDATES})
    assert out["decision"]["args"]["next_exercise_id"] == "baa.writeWord.dictation"
    assert out["decision"]["args"]["rationale"] == "clean pass, move forward"
