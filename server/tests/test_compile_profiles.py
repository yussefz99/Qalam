"""Phase 18 — Req 8 (nightly compiler over all letters) — Wave-0 RED contract.

INTENTIONALLY RED at Wave 0: imports the not-yet-built `compile_child` from
`app.jobs.compile_profiles`. Plan 18-09 writes the Cloud Run Job entrypoint + the
pure `compile_child` and turns this green with ZERO test edits.

The contract (18-SPEC.md Req 8 / RESEARCH §Nightly Job, §EMA, D-15, GROUND-04):
  * `compile_child(evidence_rows)` aggregates per-letter×criterion evidence via the
    per-criterion EMA into a DERIVED-ONLY profile doc:
    {strengths[], struggles[], perCriterion{}, schemaVersion} — nothing else.
  * A SECOND letter (alif) proves ZERO schema change: the same code path yields a
    new perCriterion key `alif/dot`, same top-level shape (letter-agnostic by
    construction — Req 8).
  * A PII/token guard asserts the profile doc keys are only fixed-vocabulary
    `<letter>/<criterion>` ids — no x/y/points/childName/nickname (GROUND-04).

Model-free / network-free: a plain `code` check that gates every PR.
"""

from __future__ import annotations

import json
import re

import pytest

pytestmark = pytest.mark.code

# RED: this module does not exist yet (Plan 18-09 writes app/jobs/compile_profiles.py).
from app.jobs.compile_profiles import compile_child

# The SERVER mirror of the payload_nonpii token guard — the profile doc must trip none of it.
_PII_TOKEN_RE = re.compile(r"\b[xy]\b|stroke|offset|coord|point|raw|nick|name", re.IGNORECASE)

# The ONLY keys a derived, non-PII profile doc may carry.
PROFILE_KEYS = {"strengths", "struggles", "perCriterion", "schemaVersion"}


def _rows(letter, criterion, n_pass, n_fail, source="letter"):
    return [
        {"letter": letter, "criterion": criterion, "passed": True, "source": source}
        for _ in range(n_pass)
    ] + [
        {"letter": letter, "criterion": criterion, "passed": False, "source": source}
        for _ in range(n_fail)
    ]


# Clear-cut multi-letter evidence: baa/dot fails hard (struggle), baa/shape passes
# hard (strength), alif/dot passes hard (a SECOND letter, strength).
MULTI_LETTER = (
    _rows("baa", "dot", n_pass=0, n_fail=8)
    + _rows("baa", "shape", n_pass=8, n_fail=0)
    + _rows("alif", "dot", n_pass=8, n_fail=0)
)


def test_compile_emits_only_the_derived_profile_shape():
    """The compiled doc carries EXACTLY {strengths, struggles, perCriterion, schemaVersion}."""
    profile = compile_child(MULTI_LETTER)
    assert set(profile) == PROFILE_KEYS


def test_clearcut_evidence_derives_struggle_and_strength():
    """Overwhelming fails → struggle; overwhelming passes → strength (EMA + min-count)."""
    profile = compile_child(MULTI_LETTER)
    assert "baa/dot" in profile["struggles"], "8 fails on baa/dot → a struggle"
    assert "baa/shape" in profile["strengths"], "8 passes on baa/shape → a strength"
    assert "baa/dot" in profile["perCriterion"]


def test_second_letter_needs_zero_schema_change():
    """A newly-signed letter (alif) rides the SAME code path — a new perCriterion key,
    identical top-level shape (letter-agnostic by construction, Req 8)."""
    profile = compile_child(MULTI_LETTER)
    assert "alif/dot" in profile["perCriterion"], "alif compiles with zero schema change"
    baa_only = compile_child(_rows("baa", "dot", n_pass=0, n_fail=8))
    assert set(profile) == set(baa_only), "same top-level keys with or without a second letter"


def test_profile_doc_is_fixed_vocabulary_non_pii():
    """GROUND-04: the profile doc is fixed-vocabulary <letter>/<criterion> ids only —
    no coordinate / PII token anywhere in the serialized doc."""
    profile = compile_child(MULTI_LETTER)
    blob = json.dumps(profile, ensure_ascii=False)
    assert not _PII_TOKEN_RE.search(blob), f"profile doc leaked a PII/coordinate token: {blob}"
    for key in profile["perCriterion"]:
        assert re.fullmatch(r"[a-z]+/[a-zA-Z]+", key), f"perCriterion key not a <letter>/<criterion> id: {key}"
