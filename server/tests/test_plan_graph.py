"""DYN-01 — the curriculum-graph rail on the plan node (Plan 15-02 implements; 15-01 RED).

The Phase-14 plan node already enforces G4 (membership) + G3 (verdict-lock). Phase 15 thickens
it to reason over the NEW `assets/curriculum/curriculum_graph.json` (derived to the server) and
adds two post-parse guards on top of G3/G4:

  * G5 — tier-reachability: a chosen exercise whose `tier` is NOT in `reachable_tiers(clearedTiers)`
    raises `StructuredOutputError` (degrades to the AuthoredFallback floor).
  * G6 — prerequisite chain (forward-only): a chosen exercise whose competency prerequisites are
    uncleared raises `StructuredOutputError`.

CRITICAL (Pitfall 3): backward remediation is LEGAL. A LOWER tier (ghayrManzur→manzur) of an
already-reached competency satisfies BOTH guards (its tier is reachable, its prereqs are met), so
it must NOT be rejected. Forward-only means "no skipping ahead," not "no stepping back."

This file is the Wave-0 RED contract. It:
  * imports `reachable_tiers`/`prerequisites_met`/`tier_of` from `app.curriculum` — these helpers
    do NOT exist yet (Plan 15-02 adds them) → RED by ImportError; and
  * asserts G5/G6 behavior the plan node does NOT yet have → RED by missing guard.

Model-free, network-free: the plan model is monkeypatched exactly like `test_grounding.py`'s
`_FakeModel` / `_patch_all`.
"""

from __future__ import annotations

import pytest

pytestmark = pytest.mark.code

from app.nodes import StructuredOutputError
from app.nodes.plan import Plan, plan

# RED: these graph helpers do not exist in app.curriculum yet (Plan 15-02 adds them, loading
# the derived curriculum_graph.json once at import like AUTHORED_BAA_IDS). The import errors
# until then — that is the Wave-0 failing contract.
from app.curriculum import prerequisites_met, reachable_tiers, tier_of  # noqa: E402  (RED import)


# --- Fakes (mirror test_grounding.py::_FakeModel / _FakeStructured) ------------------------


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


def _patch_plan(monkeypatch, plan_obj):
    import app.nodes.plan as plan_mod

    monkeypatch.setattr(plan_mod, "build_plan_model", lambda: _FakeModel(plan_obj))


# A repeated shallowBowl struggle, with the child having cleared the early graph position.
def _struggle_facts(*, cleared_competencies, cleared_tiers, passed=False):
    return {
        "letterId": "baa",
        "section": "traceLetter",
        "passed": passed,
        "mistakeId": "shallowBowl",
        "struggleTags": ["boat-curvature"],
        "recentMistakes": ["shallowBowl", "shallowBowl"],
        "trajectory": [
            {"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter"},
            {"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter"},
        ],
        "strengthTags": [],
        "clearedCompetencies": cleared_competencies,
        "clearedTiers": cleared_tiers,
    }


# --- DYN-01: within-tier choice on a repeated struggle ------------------------------------


def test_struggle_selects_within_tier(monkeypatch):
    """A repeated shallowBowl struggle → the plan picks a trace-drill within the reachable tier
    (not a forward jump). The plan node returns it grounded; G5/G6 do NOT reject it."""
    _patch_plan(
        monkeypatch,
        Plan(
            next_exercise_id="baa.traceLetter.isolated",
            intent="drill_isolated",
            rationale="repeated shallow bowl — drill the isolated trace",
        ),
    )
    facts = _struggle_facts(cleared_competencies=["recognize"], cleared_tiers=[])
    out = plan({"facts": facts, "insight": {"struggle_tags": ["boat-curvature"]}})
    assert out["plan"]["next_exercise_id"] == "baa.traceLetter.isolated"
    assert out["plan"]["grounded"] is True
    # The chosen exercise's competency (positionalForms) must be reachable from cleared recognize.
    assert prerequisites_met("baa.traceLetter.isolated", ["recognize"]) is True


# --- DYN-01 / G5: an unreached difficulty tier is rejected --------------------------------


def test_unreached_tier_rejected(monkeypatch):
    """G5: a plan choosing a ghayrManzur (dictation) exercise when no writing tier is unlocked
    raises StructuredOutputError → degrade."""
    _patch_plan(
        monkeypatch,
        Plan(
            next_exercise_id="baa.writeWord.dictation",  # tier: ghayrManzur (the hardest)
            intent="drill_isolated",
            rationale="jump straight to dictation",
        ),
    )
    # No tiers cleared → ghayrManzur is NOT reachable.
    facts = _struggle_facts(cleared_competencies=["recognize", "positionalForms"], cleared_tiers=[])
    assert tier_of("baa.writeWord.dictation") == "ghayrManzur"
    assert "ghayrManzur" not in reachable_tiers([])
    with pytest.raises(StructuredOutputError):
        plan({"facts": facts, "insight": {}})


# --- DYN-01 / G6: an exercise with an uncleared prerequisite competency is rejected -------


def test_prereq_unmet_rejected(monkeypatch):
    """G6: a plan choosing a copyWrite exercise before positionalForms is cleared raises
    StructuredOutputError (forward-only prerequisite chain)."""
    _patch_plan(
        monkeypatch,
        Plan(
            next_exercise_id="baa.writeWord.copy",  # competency: copyWrite (needs positionalForms)
            intent="drill_isolated",
            rationale="skip ahead to word copy",
        ),
    )
    # Only recognize cleared → copyWrite's prereq (positionalForms) is unmet.
    facts = _struggle_facts(cleared_competencies=["recognize"], cleared_tiers=["manqul", "manzur"])
    assert prerequisites_met("baa.writeWord.copy", ["recognize"]) is False
    with pytest.raises(StructuredOutputError):
        plan({"facts": facts, "insight": {}})


# --- DYN-01 / Pitfall 3: backward remediation is LEGAL (NOT rejected) ----------------------


def test_backward_remediation_allowed(monkeypatch):
    """A plan choosing a LOWER tier (ghayrManzur fail → manzur) of an ALREADY-REACHED competency
    is graph-legal — G5/G6 must NOT reject it. Forward-only ≠ no stepping back."""
    _patch_plan(
        monkeypatch,
        Plan(
            next_exercise_id="baa.writeWord.copy",  # competency: copyWrite, tier: manzur
            intent="drill_isolated",
            rationale="dictation failed — remediate down to look-write",
        ),
    )
    # copyWrite reached (positionalForms cleared) and the child has reached ghayrManzur, so
    # manzur is reachable AND copyWrite's prereqs are met → remediation passes both guards.
    facts = _struggle_facts(
        cleared_competencies=["recognize", "positionalForms"],
        cleared_tiers=["manqul", "manzur", "ghayrManzur"],
    )
    assert tier_of("baa.writeWord.copy") == "manzur"
    assert "manzur" in reachable_tiers(["manqul", "manzur", "ghayrManzur"])
    assert prerequisites_met("baa.writeWord.copy", ["recognize", "positionalForms"]) is True
    out = plan({"facts": facts, "insight": {}})
    # NOT rejected — the remediation node is returned (grounded; no StructuredOutputError raised).
    assert out["plan"]["next_exercise_id"] == "baa.writeWord.copy"
