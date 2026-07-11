"""Phase 18 — D-14 wire guards for the NEW `profile` / `evidenceDigest` fields — Wave-0 RED.

INTENTIONALLY RED at Wave 0: the ACCEPT legs construct a `TutorFactsIn` carrying the
new `profile` + `evidenceDigest` fields, which do NOT exist on the DTO yet — so under
`extra="forbid"` they raise `ValidationError` TODAY and the accept assertions fail
(RED). Plan 18-05 adds the fields (additive/defaulted, nested `extra="forbid"`,
fixed-vocabulary) and turns these green with ZERO test edits — the server-ships-first
half of the 422 lockstep (Pitfall 2).

The contract (GROUND-04 / 18-SPEC.md Req 8, D-14):
  * TutorFactsIn ACCEPTS the fixed-vocabulary `profile` (strengths/struggles/
    perCriterion/schemaVersion) + `evidenceDigest` (rows of letter/criterion/pass/
    fail) shape.
  * TutorFactsIn REJECTS a `profile` / `evidenceDigest` payload with a stray
    coordinate key (`x` / `points`) nested inside — the nested `extra="forbid"`
    teeth mean raw geometry can never ride in on the child model (GROUND-04).

Model-free / network-free: a plain `code` check that gates every PR.
"""

from __future__ import annotations

import pytest
from pydantic import ValidationError

pytestmark = pytest.mark.code

from app.schema import TutorFactsIn

# A minimal LEGIT base — the required TutorFactsIn fields, everything else defaulted.
BASE_FACTS = {
    "letterId": "baa",
    "section": "traceLetter.isolated",
    "passed": True,
}

# The derived-only, fixed-vocabulary child-model profile (per D-16 / RESEARCH
# §Firestore Layout) — the exact keys the compiler writes to child_models/{uid}.
VALID_PROFILE = {
    "strengths": ["baa/shape"],
    "struggles": ["baa/dot"],
    "perCriterion": {"baa/dot": 0.18, "baa/shape": 0.92},
    "schemaVersion": 1,
}

# The offline-accrued unsynced evidence digest (D-14) — rows of letter×criterion
# pass/fail counts (fixed-vocabulary, non-PII).
VALID_EVIDENCE_DIGEST = [
    {"letter": "baa", "criterion": "dot", "pass": 3, "fail": 1},
    {"letter": "baa", "criterion": "shape", "pass": 5, "fail": 0},
]


def test_accepts_fixed_vocabulary_profile_and_digest():
    """RED now: `profile`/`evidenceDigest` are not declared on TutorFactsIn yet, so
    this ACCEPT leg fails under extra=forbid until Plan 18-05 adds the fields."""
    facts = TutorFactsIn(
        **BASE_FACTS,
        profile=VALID_PROFILE,
        evidenceDigest=VALID_EVIDENCE_DIGEST,
    )
    assert facts.profile is not None
    assert facts.profile.struggles == ["baa/dot"]
    assert facts.evidenceDigest[0].letter == "baa"


def test_rejects_stray_coordinate_key_nested_in_profile():
    """A coordinate key (`points`) nested inside the profile must 422 — the nested
    extra=forbid teeth (GROUND-04: raw geometry can never enter the child model)."""
    poisoned_profile = {**VALID_PROFILE, "points": [[0.0, 1.0], [0.2, 0.9]]}
    with pytest.raises(ValidationError):
        TutorFactsIn(**BASE_FACTS, profile=poisoned_profile)


def test_rejects_stray_coordinate_key_nested_in_evidence_digest():
    """A coordinate key (`x`) nested inside an evidence-digest row must 422."""
    poisoned_digest = [{"letter": "baa", "criterion": "dot", "pass": 1, "fail": 0, "x": 0.5}]
    with pytest.raises(ValidationError):
        TutorFactsIn(**BASE_FACTS, evidenceDigest=poisoned_digest)
