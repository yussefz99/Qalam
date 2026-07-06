"""GROUND-02 — the build-failing non-PII guard on the SERVER REQUEST body (Plan 14-04 Task 1).

The chokepoint per ADR-015 §4 is the SERVER request DTO: `extra="forbid"` on BOTH
`TutorFactsIn` AND the nested `AttemptFactIn` means any unexpected field — a leaked
stroke/PII key (`strokes`, `x`, `y`, `offsets`, `childName`, `nickname`, …) — is a
Pydantic `ValidationError` (a 422 over the wire), never silently accepted.

This is a PERMANENT regression guard, not an incidental config: it pins `extra="forbid"`
on both models so no future change can quietly widen the contract to admit PII. It is the
server side of the GROUND-02 chokepoint; `test/tutor/payload_nonpii_test.dart` is the
client side. Both must hold.

Model-free, network-free — a plain `code` check that gates every PR.
"""

from __future__ import annotations

import re

import pytest
from pydantic import ValidationError

pytestmark = pytest.mark.code

from app.schema import AttemptFactIn, CriterionIn, TutorFactsIn

# A LEGIT, fully-populated enlarged payload — the exact field set from
# server/app/schema.py (6 base + a populated trajectory + strengthTags + the two
# Phase-15 graph-position fields). It MUST validate (this is what the client's
# TutorFacts.toJson() produces).
LEGIT_FACTS = {
    "letterId": "baa",
    "section": "traceLetter",
    "passed": False,
    "mistakeId": "shallowBowl",
    "struggleTags": ["boat-curvature", "shallowBowl"],
    "recentMistakes": ["shallowBowl", "noDot"],
    "trajectory": [
        {"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter"},
        {"passed": True, "mistakeId": None, "section": "writeWord"},
    ],
    "strengthTags": ["writeWord"],
    # Phase 15 (15-02 server / 15-04 Dart): the graph-position fields — pure
    # non-PII id string-lists (tier ids / competency ids). Mirror the Dart
    # TutorFacts whitelist byte-for-byte (Pitfall 1 — the 422 lockstep).
    "clearedTiers": ["manqul", "manzur"],
    "clearedCompetencies": ["recognize", "positionalForms"],
    # Phase 17 (17-05 server / 17-06 Dart): the DERIVED per-criterion result +
    # word facts. `criteria` records are the CriterionIn {criterion, zone, score}
    # mirror; weakestCriterion is the coaching target (D-B); the two word facts
    # are derived text (never geometry). All non-PII; nested extra="forbid".
    "criteria": [
        {"criterion": "shape", "zone": "certainlyWrong", "score": 0.0},
        {"criterion": "dot", "zone": "certainlyCorrect", "score": 1.0},
    ],
    "weakestCriterion": "shape",
    "expectedWord": "باب",
    "writtenWord": "داد",
}

# The graph-position field names — they must be ACCEPTED and must carry no PII.
GRAPH_POSITION_FIELDS = ["clearedTiers", "clearedCompetencies"]

# The Phase-17 field names — they must be ACCEPTED and must carry no PII.
CRITERIA_WORD_FIELDS = ["criteria", "weakestCriterion", "expectedWord", "writtenWord"]

# The geometry/PII keys that must NEVER be accepted on either model.
# `strokeImage` joins the list at Plan 17-08 (D-A): the Phase-17.1 rendered-image field was
# DELETED from TutorFactsIn, so an image key is now an unknown field — the 422 is the PROOF the
# off-device child-data surface shrank (GROUND-04 server half; a rendered image can no longer
# reach the server). The client stopped sending it in 17-07 (client-first removal ordering).
FORBIDDEN_KEYS = ["strokes", "x", "y", "offsets", "nickname", "childName", "strokeImage"]

# The tightened coordinate/PII token guard — the SERVER mirror of the Dart regex
# in test/tutor/payload_nonpii_test.dart (`\b[xy]\b|stroke|offset|coord|point|raw|
# nick|name`). The two graph-position fields + their id values must trip none of it.
_PII_TOKEN_RE = re.compile(r"\b[xy]\b|stroke|offset|coord|point|raw|nick|name", re.IGNORECASE)


# --- TutorFactsIn (top-level request body) ------------------------------------------------


def test_tutorfactsin_accepts_the_legit_enlarged_payload():
    """The day-one-final enlarged payload (trajectory + strengthTags + the two
    Phase-15 graph-position fields + the Phase-17 criteria/word facts) validates."""
    facts = TutorFactsIn.model_validate(LEGIT_FACTS)
    assert facts.letterId == "baa"
    assert len(facts.trajectory) == 2
    assert facts.strengthTags == ["writeWord"]
    # The two Phase-15 fields are accepted and round-trip their id string-lists.
    assert facts.clearedTiers == ["manqul", "manzur"]
    assert facts.clearedCompetencies == ["recognize", "positionalForms"]
    # The four Phase-17 fields are accepted and round-trip.
    assert len(facts.criteria) == 2
    assert facts.criteria[0].criterion == "shape"
    assert facts.weakestCriterion == "shape"
    assert facts.expectedWord == "باب"
    assert facts.writtenWord == "داد"


def test_criteria_and_word_fields_carry_no_pii():
    """The four Phase-17 fields — their NAMES and the criterion/zone id values — trip no
    PII/stroke token (GROUND-04 regression over the enlarged wire contract)."""
    facts = TutorFactsIn.model_validate(LEGIT_FACTS)
    dumped = facts.model_dump()
    for field in CRITERIA_WORD_FIELDS:
        assert field in dumped, f"{field} must serialize on the server DTO"
        assert not _PII_TOKEN_RE.search(field), (
            f"the Phase-17 field name {field!r} matches the PII/stroke guard"
        )
    # The criterion/zone id values are derived, non-PII strings.
    for crit in facts.criteria:
        assert not _PII_TOKEN_RE.search(crit.criterion), crit.criterion
        assert not _PII_TOKEN_RE.search(crit.zone), crit.zone


def test_leaked_key_inside_a_criterion_entry_is_rejected():
    """A leaked geometry/PII key INSIDE a criteria record is rejected (nested forbid on
    CriterionIn) — raw points can never ride in on a criterion entry (GROUND-04)."""
    payload = {
        **LEGIT_FACTS,
        "criteria": [{"criterion": "shape", "zone": "certainlyWrong", "score": 0.0, "y": 1}],
    }
    with pytest.raises(ValidationError):
        TutorFactsIn.model_validate(payload)


def test_extra_forbid_is_pinned_on_criterionin():
    """extra=forbid stays on CriterionIn (the nested Phase-17 regression guard)."""
    assert CriterionIn.model_config.get("extra") == "forbid"


def test_graph_position_fields_carry_no_pii():
    """The two enlarged graph-position fields — their NAMES and VALUES — trip no
    PII/stroke token (GROUND-02 regression over the enlarged wire contract)."""
    facts = TutorFactsIn.model_validate(LEGIT_FACTS)
    dumped = facts.model_dump()
    for field in GRAPH_POSITION_FIELDS:
        # The field is present in the serialized payload …
        assert field in dumped, f"{field} must serialize on the server DTO"
        # … its key name trips no PII/stroke token …
        assert not _PII_TOKEN_RE.search(field), (
            f"the graph-position field name {field!r} matches the PII/stroke guard"
        )
        # … and every id value it carries is a plain non-PII tier/competency id.
        for value in dumped[field]:
            assert not _PII_TOKEN_RE.search(str(value)), (
                f"the {field} value {value!r} matches the PII/stroke guard"
            )


def test_graph_position_fields_default_empty_when_omitted():
    """Omitting the two fields is backward-compatible: they default to [] (a fresh
    child at the graph root), never a 422 — the standalone-redeploy safety."""
    minimal = {"letterId": "baa", "section": "traceLetter", "passed": True}
    facts = TutorFactsIn.model_validate(minimal)
    assert facts.clearedTiers == []
    assert facts.clearedCompetencies == []


@pytest.mark.parametrize("bad_key", FORBIDDEN_KEYS)
def test_tutorfactsin_rejects_each_nonwhitelisted_key(bad_key):
    """Any non-whitelisted / PII key at the top level is a ValidationError (422)."""
    payload = {**LEGIT_FACTS, bad_key: [[1, 2], [3, 4]] if bad_key in {"strokes", "offsets"} else 1}
    with pytest.raises(ValidationError):
        TutorFactsIn.model_validate(payload)


def test_strokeimage_key_is_now_rejected_422():
    """Plan 17-08 (D-A): the retired Phase-17.1 rendered-image field is DELETED from the DTO, so a
    payload carrying an image key is now an unknown field → ValidationError (422). This 422 is the
    structural PROOF that the off-device child-data surface shrank — a rendered image of child
    handwriting can no longer reach the server (GROUND-04 server half; ADR-017 at 17-10)."""
    payload = {**LEGIT_FACTS, "strokeImage": "data:image/png;base64,AAAA"}
    with pytest.raises(ValidationError):
        TutorFactsIn.model_validate(payload)


def test_tutorfactsin_rejects_a_leaked_key_inside_a_trajectory_entry():
    """A leaked geometry/PII key INSIDE a trajectory record is also rejected (nested forbid)."""
    payload = {
        **LEGIT_FACTS,
        "trajectory": [
            {"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter", "strokes": [[0, 0]]}
        ],
    }
    with pytest.raises(ValidationError):
        TutorFactsIn.model_validate(payload)


# --- AttemptFactIn (the nested trajectory record) -----------------------------------------


def test_attemptfactin_accepts_the_legit_record():
    rec = AttemptFactIn.model_validate(
        {"passed": True, "mistakeId": None, "section": "traceLetter"}
    )
    assert rec.passed is True
    assert rec.section == "traceLetter"


@pytest.mark.parametrize("bad_key", FORBIDDEN_KEYS)
def test_attemptfactin_rejects_each_nonwhitelisted_key(bad_key):
    """Each geometry/PII key is rejected directly on the nested AttemptFactIn too."""
    payload = {
        "passed": True,
        "mistakeId": None,
        "section": "traceLetter",
        bad_key: [[1, 2]] if bad_key in {"strokes", "offsets"} else 1,
    }
    with pytest.raises(ValidationError):
        AttemptFactIn.model_validate(payload)


# --- extra="forbid" is pinned as config, not incidental -----------------------------------


def test_extra_forbid_is_pinned_on_both_models():
    """A permanent assertion that extra=forbid stays on BOTH models (the regression guard)."""
    assert TutorFactsIn.model_config.get("extra") == "forbid"
    assert AttemptFactIn.model_config.get("extra") == "forbid"
