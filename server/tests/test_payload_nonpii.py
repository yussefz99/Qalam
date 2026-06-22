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

import pytest
from pydantic import ValidationError

pytestmark = pytest.mark.code

from app.schema import AttemptFactIn, TutorFactsIn

# A LEGIT, fully-populated enlarged payload — the exact field set from
# server/app/schema.py (6 base + a populated trajectory + strengthTags). It MUST
# validate (this is what the client's TutorFacts.toJson() produces).
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
}

# The geometry/PII keys that must NEVER be accepted on either model.
FORBIDDEN_KEYS = ["strokes", "x", "y", "offsets", "nickname", "childName"]


# --- TutorFactsIn (top-level request body) ------------------------------------------------


def test_tutorfactsin_accepts_the_legit_enlarged_payload():
    """The day-one-final enlarged payload (populated trajectory + strengthTags) validates."""
    facts = TutorFactsIn.model_validate(LEGIT_FACTS)
    assert facts.letterId == "baa"
    assert len(facts.trajectory) == 2
    assert facts.strengthTags == ["writeWord"]


@pytest.mark.parametrize("bad_key", FORBIDDEN_KEYS)
def test_tutorfactsin_rejects_each_nonwhitelisted_key(bad_key):
    """Any non-whitelisted / PII key at the top level is a ValidationError (422)."""
    payload = {**LEGIT_FACTS, bad_key: [[1, 2], [3, 4]] if bad_key in {"strokes", "offsets"} else 1}
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
