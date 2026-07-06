"""STRK-01 / GROUND-04 — the non-PII guard over the Phase-17 per-criterion + word wire fields.

Plan 17-05 enlarges `TutorFactsIn` with the DERIVED structured coaching input the scorer now
produces (Plan 17-03 `LetterScore.criteria` + `weakest`) plus the F6 derived word facts:

  * `criteria`         — a list of `CriterionIn` {criterion, zone, score} records (the Dart
                          `CriterionResult` mirror, lib/core/scoring/scoring_models.dart);
  * `weakestCriterion` — the name of the lowest-score criterion (the D-B coaching target);
  * `expectedWord`     — the curriculum's expected word (derived text, never geometry);
  * `writtenWord`      — ML Kit's recognized transcription (derived text, never geometry).

All FOUR are optional/defaulted, so this is an ADDITIVE (strict-superset) contract: an OLD client
that sends none of them still validates — no 422 window, the server ships FIRST and the Dart mirror
(Plan 17-06) follows. `extra="forbid"` on `CriterionIn` means a leaked coordinate/point key NESTED
inside a criterion record is a 422 (GROUND-04): raw stroke geometry can never ride in on a criterion.

Model-free, network-free — a `code` check that gates every PR. This is the same discipline as
`test_payload_nonpii.py` (the four moves copied here for the new fields).
"""

from __future__ import annotations

import re

import pytest
from pydantic import ValidationError

pytestmark = pytest.mark.code

from app.schema import CriterionIn, TutorFactsIn

# The minimal, day-one BASE payload — the exact 3 required fields an OLD client sends. It MUST
# validate with the four new fields defaulted (backward-compat, no 422 window).
MINIMAL_FACTS = {"letterId": "baa", "section": "traceLetter", "passed": True}

# A LEGIT, fully-populated Phase-17 payload — the enlarged base PLUS the four new derived fields.
# This is what the Plan 17-06 Dart TutorFacts.toJson() will produce; it MUST validate.
LEGIT_CRITERIA_FACTS = {
    "letterId": "baa",
    "section": "traceLetter",
    "passed": False,
    "mistakeId": "tooCurved",
    "struggleTags": ["boat-curvature"],
    "recentMistakes": ["tooCurved"],
    "criteria": [
        {"criterion": "strokeCount", "zone": "certainlyCorrect", "score": 1.0},
        {"criterion": "shape", "zone": "certainlyWrong", "score": 0.0},
        {"criterion": "dot", "zone": "certainlyCorrect", "score": 1.0},
    ],
    "weakestCriterion": "shape",
    "expectedWord": "باب",
    "writtenWord": "داد",
}

# The four new fields — their NAMES must be accepted and must carry no PII/geometry token.
NEW_FIELDS = ["criteria", "weakestCriterion", "expectedWord", "writtenWord"]

# The SERVER mirror of the Dart coordinate/PII token guard (test/tutor/payload_nonpii_test.dart):
# a standalone x/y, or any of stroke/offset/coord/point/raw/nick/name. None of the new field NAMES
# (nor the criterion/zone id values) may trip it.
_PII_TOKEN_RE = re.compile(r"\b[xy]\b|stroke|offset|coord|point|raw|nick|name", re.IGNORECASE)


# --- Test 1: additive — the minimal payload validates with the new fields defaulted ---------


def test_minimal_payload_validates_with_new_fields_defaulted():
    """An OLD client that sends none of the Phase-17 fields still validates — the additive
    strict-superset contract (no 422 window; server ships FIRST)."""
    facts = TutorFactsIn.model_validate(MINIMAL_FACTS)
    assert facts.criteria == []
    assert facts.weakestCriterion is None
    assert facts.expectedWord is None
    assert facts.writtenWord is None


# --- Test 2: a stray key INSIDE a CriterionIn entry is rejected (nested extra=forbid) --------


def test_leaked_key_inside_a_criterion_entry_is_rejected():
    """A leaked geometry/PII key NESTED inside a criteria record is a 422 (GROUND-04): the
    CriterionIn `extra="forbid"` means raw points can never ride in on a criterion entry."""
    payload = {
        **LEGIT_CRITERIA_FACTS,
        "criteria": [
            {"criterion": "shape", "zone": "certainlyWrong", "score": 0.0, "points": [[0, 0]]}
        ],
    }
    with pytest.raises(ValidationError):
        TutorFactsIn.model_validate(payload)


def test_criterionin_rejects_a_stray_key_directly():
    """The same nested forbid, asserted directly on CriterionIn."""
    with pytest.raises(ValidationError):
        CriterionIn.model_validate(
            {"criterion": "shape", "zone": "certainlyWrong", "score": 0.0, "x": 1}
        )


# --- Test 3: a fully-populated payload (criteria + weakest + word facts) validates -----------


def test_fully_populated_payload_validates():
    """The enlarged Phase-17 payload — criteria + weakestCriterion + the two word facts — validates
    and round-trips its values (this is what the Plan 17-06 client mirror will send)."""
    facts = TutorFactsIn.model_validate(LEGIT_CRITERIA_FACTS)
    assert len(facts.criteria) == 3
    assert facts.criteria[1].criterion == "shape"
    assert facts.criteria[1].zone == "certainlyWrong"
    assert facts.criteria[1].score == 0.0
    assert facts.weakestCriterion == "shape"
    assert facts.expectedWord == "باب"
    assert facts.writtenWord == "داد"


# --- Test 4: no new field NAME (nor the criterion/zone id values) trips the PII token guard --


def test_new_field_names_and_ids_carry_no_pii():
    """The four new field NAMES trip no PII/stroke token, and the criterion/zone id values
    (derived, non-PII) trip none either — the GROUND-04 regression over the enlarged contract."""
    for field in NEW_FIELDS:
        assert not _PII_TOKEN_RE.search(field), (
            f"the Phase-17 field name {field!r} matches the PII/stroke guard"
        )
    facts = TutorFactsIn.model_validate(LEGIT_CRITERIA_FACTS)
    for crit in facts.criteria:
        assert not _PII_TOKEN_RE.search(crit.criterion), crit.criterion
        assert not _PII_TOKEN_RE.search(crit.zone), crit.zone
    # weakestCriterion is a plain criterion-name id (never PII).
    assert not _PII_TOKEN_RE.search(facts.weakestCriterion)


# --- extra="forbid" is pinned as config on CriterionIn, not incidental -----------------------


def test_extra_forbid_is_pinned_on_criterionin():
    """A permanent assertion that extra=forbid stays on CriterionIn (the nested regression guard)."""
    assert CriterionIn.model_config.get("extra") == "forbid"


def test_criterion_has_only_the_three_scalar_fields():
    """CriterionIn carries EXACTLY {criterion, zone, score} — no room for a coordinate field."""
    assert set(CriterionIn.model_fields) == {"criterion", "zone", "score"}
