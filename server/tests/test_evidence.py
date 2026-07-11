"""Phase 18 — Req 7 (cross-letter evidence from day one) — Wave-0 RED contract.

INTENTIONALLY RED at Wave 0: imports the not-yet-built `evidence_rows_from_facts` /
`append_evidence` from `app.evidence`. Plans 18-02 (exercise letters/criteria labels)
/ 18-05 (the server deriver + /coach append) turn this green with ZERO test edits.

The contract (18-SPEC.md Req 7 / RESEARCH Pitfall 3, §Firestore Layout, D-13):
  * A WORD attempt (e.g. باب on writeWord) records a COARSE per-letter signal for
    EVERY letter it touches (باب → baa AND alif), each row {letter, criterion,
    passed, source} with source == "word" and the coarse criteria (present/correct/
    dot) — NOT the 5 geometric criteria (a word attempt never produced those).
  * An ISOLATED-LETTER attempt records the 5 geometric criteria
    (strokeCount/strokeOrder/shape/direction/dot), each row source == "letter".
  * `append_evidence` writes the rows in ONE batch via the Admin SDK (no hot doc,
    no live network here — a fake client). Evidence is server-written only (D-13).

Model-free / network-free: a plain `code` check that gates every PR.
"""

from __future__ import annotations

import pytest

pytestmark = pytest.mark.code

# RED: this module does not exist yet (Plans 18-02 / 18-05 write app/evidence.py).
from app.evidence import append_evidence, evidence_rows_from_facts

# A WORD attempt: باب (baa · alif · baa) on the dictation exercise. Word attempts
# yield a word-level verdict + transcription, NOT per-letter geometric criteria.
WORD_FACTS = {
    "letterId": "baa",
    "section": "baa.writeWord.dictation",
    "passed": True,
    "expectedWord": "باب",
    "writtenWord": "باب",
    "criteria": [],
}

# An ISOLATED-LETTER attempt: the scorer produced the 5 geometric criteria.
LETTER_FACTS = {
    "letterId": "baa",
    "section": "baa.traceLetter.isolated",
    "passed": False,
    "weakestCriterion": "shape",
    "criteria": [
        {"criterion": "strokeCount", "zone": "certainlyCorrect", "score": 1.0},
        {"criterion": "strokeOrder", "zone": "certainlyCorrect", "score": 1.0},
        {"criterion": "shape", "zone": "certainlyWrong", "score": 0.0},
        {"criterion": "direction", "zone": "fuzzy", "score": 0.6},
        {"criterion": "dot", "zone": "certainlyCorrect", "score": 1.0},
    ],
}

COARSE_CRITERIA = {"present", "correct", "dot"}
GEOMETRIC_CRITERIA = {"strokeCount", "strokeOrder", "shape", "direction", "dot"}


def test_word_attempt_credits_every_letter_it_touches_with_source_word():
    """باب records a coarse per-letter signal for baa AND alif (Req 7 / Pitfall 3)."""
    rows = evidence_rows_from_facts(WORD_FACTS)
    letters = {r["letter"] for r in rows}
    assert letters == {"baa", "alif"}, "باب touches baa AND alif — every letter credited"
    assert all(r["source"] == "word" for r in rows), "word attempts tag source=='word'"
    seen = {r["criterion"] for r in rows}
    assert seen, "the coarse signal is non-empty"
    assert seen <= COARSE_CRITERIA, "word attempts write only the coarse present/correct/dot signal"


def test_isolated_letter_attempt_writes_the_five_geometric_criteria_source_letter():
    """An isolated-letter attempt writes the 5 geometric criteria (source=='letter')."""
    rows = evidence_rows_from_facts(LETTER_FACTS)
    assert all(r["source"] == "letter" for r in rows), "isolated-letter attempts tag source=='letter'"
    assert all(r["letter"] == "baa" for r in rows)
    assert {r["criterion"] for r in rows} == GEOMETRIC_CRITERIA


def test_every_row_carries_letter_criterion_passed_source():
    """Each derived row is keyed letter × criterion with a verdict and a source tag."""
    for facts in (WORD_FACTS, LETTER_FACTS):
        for r in evidence_rows_from_facts(facts):
            assert {"letter", "criterion", "passed", "source"} <= set(r)
            assert isinstance(r["passed"], bool)


def test_append_evidence_writes_one_batch_off_network(monkeypatch):
    """append_evidence writes the rows in a single Admin-SDK batch — a FAKE client so
    the test never hits live Firestore (D-13: server-written, off the critical path)."""
    import firebase_admin.firestore as fb_firestore

    recorded = {"sets": 0, "commits": 0}

    class _FakeDoc:
        def collection(self, *_a, **_k):
            return _FakeCol()

    class _FakeCol:
        def document(self, *_a, **_k):
            return _FakeDoc()

    class _FakeBatch:
        def set(self, _doc, _data):
            recorded["sets"] += 1

        def commit(self):
            recorded["commits"] += 1

    class _FakeDb:
        def batch(self):
            return _FakeBatch()

        def collection(self, *_a, **_k):
            return _FakeCol()

    monkeypatch.setattr(fb_firestore, "client", lambda: _FakeDb())

    rows = evidence_rows_from_facts(LETTER_FACTS)
    append_evidence("test-child-uid", rows)

    assert recorded["sets"] == len(rows), "one set per evidence row"
    assert recorded["commits"] == 1, "a single batch commit (one round-trip)"
