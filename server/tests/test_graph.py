"""analyze + plan node tests (Plan 14-02 Task 1) — model-free `code` checks.

Covers the Task-1 behaviors with the node models monkeypatched to return canned structured
objects (no network):
  * analyze struggle detection on a fail trajectory,
  * analyze empty-struggle on a clean pass (so the router skips plan),
  * the curriculum-membership guard (G4): an authored id passes, a fabricated id raises,
  * the advance-on-fail downgrade (G3) in the plan node,
  * the 2-retry-then-raise path of the bounded structured-retry helper,
  * the per-node model routing table builds via init_chat_model with explicit max_tokens,
  * the conditional-edge router `needs_plan`.
"""

from __future__ import annotations

import pytest
from pydantic import BaseModel, ValidationError

pytestmark = pytest.mark.code

from app.curriculum import AUTHORED_BAA_IDS, is_authored
from app.graph import needs_plan
from app.nodes._retry import StructuredOutputError, with_structured_retry
from app.nodes.analyze import Insight, analyze
from app.nodes.plan import Plan, plan


# --- Fakes ---------------------------------------------------------------------------------


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
    "recentMistakes": ["shallowBowl", "shallowBowl"],
    "trajectory": [
        {"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter"},
        {"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter"},
    ],
    "strengthTags": ["steady-hand"],
}

PASS_FACTS = {
    "letterId": "baa",
    "section": "traceLetter",
    "passed": True,
    "mistakeId": None,
    "struggleTags": [],
    "recentMistakes": [],
    "trajectory": [{"passed": True, "mistakeId": None, "section": "traceLetter"}],
    "strengthTags": ["steady-hand", "deep-bowl"],
}


# --- analyze ------------------------------------------------------------------------------


def test_analyze_detects_boat_curve_struggle(monkeypatch):
    import app.nodes.analyze as analyze_mod

    canned = Insight(
        struggle_tags=["boat-curvature"],
        strength_tags=["steady-hand"],
        pattern_note="shallow bowl on the last tries",
    )
    monkeypatch.setattr(analyze_mod, "build_analyze_model", lambda: _FakeModel(canned))

    out = analyze({"facts": FAIL_FACTS})
    assert "boat-curvature" in out["insight"]["struggle_tags"]
    assert "dot-placement" not in out["insight"]["struggle_tags"]
    assert out["log"] == ["analyze"]


def test_analyze_clean_pass_has_empty_struggle(monkeypatch):
    import app.nodes.analyze as analyze_mod

    canned = Insight(struggle_tags=[], strength_tags=["deep-bowl"], pattern_note="clean")
    monkeypatch.setattr(analyze_mod, "build_analyze_model", lambda: _FakeModel(canned))

    out = analyze({"facts": PASS_FACTS})
    assert out["insight"]["struggle_tags"] == []


# --- needs_plan conditional edge ----------------------------------------------------------


def test_needs_plan_routes_struggle_to_plan():
    state = {"facts": FAIL_FACTS, "insight": {"struggle_tags": ["boat-curvature"]}}
    assert needs_plan(state) == "plan"


def test_needs_plan_routes_clean_pass_to_coach():
    state = {"facts": PASS_FACTS, "insight": {"struggle_tags": []}}
    assert needs_plan(state) == "coach"


def test_needs_plan_routes_pass_with_struggle_to_plan():
    # A pass that still surfaced a struggle should NOT shortcut — it routes through plan.
    state = {"facts": PASS_FACTS, "insight": {"struggle_tags": ["proportion"]}}
    assert needs_plan(state) == "plan"


# --- plan node + curriculum guard (G4) + verdict lock (G3) --------------------------------


def test_plan_authored_id_passes(monkeypatch):
    import app.nodes.plan as plan_mod

    canned = Plan(
        next_exercise_id="baa.traceLetter.isolated",
        intent="drill_isolated",
        rationale="drill the failed trace",
    )
    monkeypatch.setattr(plan_mod, "build_plan_model", lambda: _FakeModel(canned))

    out = plan({"facts": FAIL_FACTS, "insight": {"struggle_tags": ["boat-curvature"]}})
    assert out["plan"]["next_exercise_id"] == "baa.traceLetter.isolated"
    assert out["plan"]["intent"] == "drill_isolated"
    assert out["plan"]["grounded"] is True


@pytest.mark.parametrize("bad_id", ["baa.notreal.x", "zaa.traceLetter.isolated", "totally-made-up"])
def test_plan_unauthored_id_raises(monkeypatch, bad_id):
    import app.nodes.plan as plan_mod

    canned = Plan(next_exercise_id=bad_id, intent="drill_isolated", rationale="x")
    monkeypatch.setattr(plan_mod, "build_plan_model", lambda: _FakeModel(canned))

    with pytest.raises(StructuredOutputError):
        plan({"facts": FAIL_FACTS, "insight": {"struggle_tags": ["boat-curvature"]}})


def test_plan_advance_on_fail_downgraded(monkeypatch):
    import app.nodes.plan as plan_mod

    canned = Plan(
        next_exercise_id="baa.traceLetter.isolated", intent="advance", rationale="x"
    )
    monkeypatch.setattr(plan_mod, "build_plan_model", lambda: _FakeModel(canned))

    out = plan({"facts": FAIL_FACTS, "insight": {"struggle_tags": ["boat-curvature"]}})
    assert out["plan"]["intent"] == "retest_whole"  # downgraded away from advance
    assert out["plan"]["grounded"] is False


def test_plan_advance_on_pass_allowed(monkeypatch):
    import app.nodes.plan as plan_mod

    canned = Plan(
        next_exercise_id="baa.traceLetter.isolated", intent="advance", rationale="x"
    )
    monkeypatch.setattr(plan_mod, "build_plan_model", lambda: _FakeModel(canned))

    out = plan({"facts": PASS_FACTS, "insight": {"struggle_tags": []}})
    assert out["plan"]["intent"] == "advance"  # legal on a pass
    assert out["plan"]["grounded"] is True


# --- curriculum membership directly -------------------------------------------------------


def test_is_authored_real_seed_id():
    assert is_authored("baa.traceLetter.isolated") is True
    assert is_authored("baa.writeWord.dictation") is True


def test_is_authored_section_and_family():
    assert is_authored("watchTrace") is True   # a baa section id
    assert is_authored("baa") is True           # the letter family token


def test_is_authored_rejects_fabricated_and_empty():
    assert is_authored("baa.notreal.x") is False
    assert is_authored("zaa.traceLetter.isolated") is False
    assert is_authored(None) is False
    assert is_authored("") is False
    assert is_authored("   ") is False


def test_authored_set_mirrors_live_graph_nodes():
    """G4 rails exactly what the live graph rails (19 review WR-05).

    The membership set is DERIVED from the graph's baa.* node ids, so the coach can
    propose every live node (incl. the 19-05 restored micro-drills + the final-form
    trace + the rewritten kitaab) and nothing else (the six D-19 gated ids are out).
    A structural assertion — never a magic count that silently rots when the graph
    changes (the old `== 19` did exactly that).
    """
    import json
    import pathlib

    graph_path = (
        pathlib.Path(__file__).resolve().parent.parent
        / "app"
        / "curriculum_data"
        / "curriculum_graph.json"
    )
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    node_ids = {
        str(n["exerciseId"])
        for n in graph.get("nodes", [])
        if str(n.get("exerciseId", "")).startswith("baa.")
    }
    baa_exercises = {i for i in AUTHORED_BAA_IDS if i.startswith("baa.")}
    assert baa_exercises == node_ids
    # The 19-05 dispositions hold: restored ids in, gated ids out.
    assert {
        "baa.microDrill.dot",
        "baa.microDrill.bowl",
        "baa.microDrill.start",
        "baa.traceLetter.final",
        "baa.connectWord.kitaab",
    } <= baa_exercises
    assert baa_exercises.isdisjoint({
        "baa.buildSentence.hear",
        "baa.buildSentence.picture",
        "baa.fillBlank.adjective",
        "baa.transformWord.dual",
        "baa.transformWord.plural",
        "baa.transformWord.opposite",
    })


# --- the bounded structured retry (2 retries then raise) ----------------------------------


class _DummyModel(BaseModel):
    ok: bool = True


def test_retry_succeeds_first_try():
    out = with_structured_retry("analyze", "m", lambda: _DummyModel(ok=True))
    assert out.ok is True


def test_retry_recovers_on_second_attempt():
    calls = {"n": 0}

    def flaky():
        calls["n"] += 1
        if calls["n"] < 2:
            raise ValidationError.from_exception_data("Dummy", [])
        return _DummyModel(ok=True)

    out = with_structured_retry("analyze", "m", flaky)
    assert out.ok is True
    assert calls["n"] == 2


def test_retry_exhausts_then_raises():
    calls = {"n": 0}

    def always_bad():
        calls["n"] += 1
        raise ValidationError.from_exception_data("Dummy", [])

    with pytest.raises(StructuredOutputError):
        with_structured_retry("analyze", "m", always_bad)
    assert calls["n"] == 3  # 1 initial + 2 retries


def test_retry_none_parse_fails_closed():
    with pytest.raises(StructuredOutputError):
        with_structured_retry("analyze", "m", lambda: None)


# --- model routing table ------------------------------------------------------------------


def test_model_routing_builds_with_explicit_max_tokens(monkeypatch):
    """Each node builds via init_chat_model with an explicit max_tokens (AI-SPEC §4 / 4b.3)."""
    import app.models as models_mod

    captured = []

    def fake_init(model, **kwargs):
        captured.append({"model": model, **kwargs})
        return object()

    monkeypatch.setattr("langchain.chat_models.init_chat_model", fake_init)

    models_mod.build_analyze_model()
    models_mod.build_plan_model()
    models_mod.build_coach_model()

    assert len(captured) == 3
    for c in captured:
        assert "max_tokens" in c and c["max_tokens"] > 0
        assert "model_provider" in c
    # coach is the bounded short voice; analyze/plan get the larger structured budget.
    by_model = {c["model"]: c for c in captured}
    assert any(c["max_tokens"] == 256 for c in captured)  # coach
    assert any(c["max_tokens"] == 512 for c in captured)  # analyze/plan
    assert by_model  # routing table is non-empty
