"""Tests for the reusable letter-promotion script (quick task 260718-il4).

Run from `tools/`:
    python -m pytest content/test_promote_letter.py -q
    # (or, if pytest isn't on PATH: uv run --with pytest pytest content/test_promote_letter.py -q)

Three guarantees (owner threat register T-il4-01):
  (1) IDEMPOTENCE — capturing the three target files, running the promoter twice
      produces a byte-identical result (no duplicate ids, no baa/taa/alif drift).
  (2) ENRICHMENT PARITY — every promoted thaa exercise carries `letters`
      (= decompose(text), deduped), the correct per-type `criteria`, and
      `signedOff:false`.
  (3) baa SPOT-CHECK — the promoter's `letters`/`criteria` derivation reproduces
      three known live baa values (traceLetter, writeWord, buildSentence) so the
      mapping can never silently drift from the signed baa configs.

Each mutating test restores the touched files afterward so the suite is
side-effect-free on the working tree.
"""

from __future__ import annotations

import json
import os

import pytest

from content import promote_letter as P

# The files the promoter mutates — captured + restored around each mutating test.
_TARGETS = [
    P.LIVE_EXERCISES,
    P.LIVE_UNITS,
    os.path.join(P.GRAPHS_DIR, "thaa.json"),
    os.path.join(P.GRAPHS_DIR, "baa.json"),
]


def _read_bytes(rel: str) -> bytes | None:
    path = P._abs(rel)
    if not os.path.exists(path):
        return None
    with open(path, "rb") as fh:
        return fh.read()


@pytest.fixture()
def restore_targets():
    """Snapshot the target files, run the test, then restore them exactly."""
    before = {rel: _read_bytes(rel) for rel in _TARGETS}
    try:
        yield
    finally:
        for rel, blob in before.items():
            path = P._abs(rel)
            if blob is None:
                if os.path.exists(path):
                    os.remove(path)
            else:
                with open(path, "wb") as fh:
                    fh.write(blob)


def _load(rel: str) -> dict:
    with open(P._abs(rel), encoding="utf-8") as fh:
        return json.load(fh)


# ── (1) IDEMPOTENCE ──────────────────────────────────────────────────────────


def test_promote_thaa_is_idempotent(restore_targets):
    P.promote_letter("thaa")
    P.migrate_baa()
    first = {rel: _read_bytes(rel) for rel in _TARGETS}

    # Second run over the SAME already-promoted state must produce identical bytes.
    P.promote_letter("thaa")
    P.migrate_baa()
    second = {rel: _read_bytes(rel) for rel in _TARGETS}

    for rel in _TARGETS:
        assert first[rel] == second[rel], f"{rel} drifted on the second run"


def test_promote_thaa_no_duplicate_ids_and_no_baa_taa_alif_drift(restore_targets):
    before_ex = _load(P.LIVE_EXERCISES)
    before_ids = [e["id"] for e in before_ex["exercises"]]
    # Snapshot every non-thaa exercise verbatim (drift guard).
    before_non_thaa = {
        e["id"]: e for e in before_ex["exercises"]
        if not e["id"].startswith("thaa.")
    }

    P.promote_letter("thaa")

    after_ex = _load(P.LIVE_EXERCISES)
    after_ids = [e["id"] for e in after_ex["exercises"]]

    # No duplicate ids.
    assert len(after_ids) == len(set(after_ids)), "duplicate exercise ids appeared"

    # Every previously-present id is still present (nothing dropped).
    assert set(before_ids).issubset(set(after_ids))

    # No baa/taa/alif entry changed byte-for-byte.
    after_by_id = {e["id"]: e for e in after_ex["exercises"]}
    for ident, entry in before_non_thaa.items():
        assert after_by_id[ident] == entry, f"{ident} drifted during promotion"

    # The unit file gained a thaa unit but kept baa/taa/alif intact.
    before_units = {u["letterId"]: u for u in _load(P.LIVE_UNITS)["units"]}
    P.promote_letter("thaa")  # re-run is safe (idempotent)
    after_units = {u["letterId"]: u for u in _load(P.LIVE_UNITS)["units"]}
    for letter in ("baa", "taa", "alif"):
        # baa/taa/alif were present before and are unchanged.
        assert after_units[letter] == before_units[letter]
    assert "thaa" in after_units


# ── (2) ENRICHMENT PARITY ────────────────────────────────────────────────────


def _uniq(seq):
    out = []
    for x in seq:
        if x not in out:
            out.append(x)
    return out


def test_promoted_thaa_exercises_carry_letters_criteria_signedoff(restore_targets):
    P.promote_letter("thaa")
    ex = _load(P.LIVE_EXERCISES)
    thaa = [e for e in ex["exercises"] if e["id"].startswith("thaa.")]
    assert thaa, "no thaa exercises were appended"

    for e in thaa:
        # signedOff forced false on EVERY promoted exercise.
        assert e["signedOff"] is False, f"{e['id']} must ship signedOff:false"

        # criteria matches the per-type map exactly.
        assert e["criteria"] == P.CRITERIA_BY_TYPE[e["type"]], (
            f"{e['id']} criteria mismatch for type {e['type']}"
        )

        # letters == decompose(text) deduped, or [thaa] when there is no text.
        text = P._text_for(e)
        if text is None:
            assert e["letters"] == ["thaa"], (
                f"{e['id']} with no expected text must default letters to [thaa]"
            )
        else:
            expected_letters = _uniq(P.decompose(text).letters) or ["thaa"]
            assert e["letters"] == expected_letters, (
                f"{e['id']} letters {e['letters']} != decompose({text!r}) "
                f"{expected_letters}"
            )


def test_promoted_thaa_file_level_signedoff_false(restore_targets):
    P.promote_letter("thaa")
    graph = _load(os.path.join(P.GRAPHS_DIR, "thaa.json"))
    assert graph["signedOff"] is False
    assert graph["letterId"] == "thaa"
    # Micro-drills NEVER enter the graph (owner-locked).
    node_types = {n["exerciseId"].split(".")[1] for n in graph["nodes"]}
    assert "microDrill" not in node_types, "micro-drills must never enter the graph"


# ── (3) baa SPOT-CHECK (the mapping can't silently drift) ─────────────────────


def test_baa_enrichment_matches_live_signed_values():
    """The promoter's derivation reproduces the LIVE signed baa values for three
    representative types — so the enrichment rule can never drift from baa."""
    live = _load(P.LIVE_EXERCISES)
    by_id = {e["id"]: e for e in live["exercises"]}

    for probe_id in (
        "baa.traceLetter.isolated",   # glyph -> stroke criteria, letters [baa]
        "baa.writeWord.dictation",    # word  -> word criteria, letters [baa, alif]
        "baa.buildSentence.hear",     # sentence -> word criteria, multi-letter
    ):
        live_ex = by_id[probe_id]
        # Re-derive with the promoter over the live authored fields.
        derived = P.enrich_exercise(live_ex, "baa")
        assert derived["criteria"] == live_ex["criteria"], (
            f"{probe_id}: derived criteria {derived['criteria']} != live "
            f"{live_ex['criteria']}"
        )
        assert derived["letters"] == live_ex["letters"], (
            f"{probe_id}: derived letters {derived['letters']} != live "
            f"{live_ex['letters']}"
        )
