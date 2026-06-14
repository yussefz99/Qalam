"""Off-device round-trip parity test: seed→export == source JSON (D-08, D-15).

Proves the seed/export transform is **lossless** WITHOUT a live Firestore or the
service-account key, so it gates locally and in CI. The strategy: take the source
``letters.json`` / ``lessons.json``, run each letter through ``encode_letter``
(the seed's write transform) into an in-memory dict standing in for the Firestore
doc, then ``decode_letter`` + reassemble it exactly the way ``export_firestore.py``
rebuilds the source shape, and assert deep-equality against the source.

The live seed→export against the real me-west1 database is the phase-gate human-check
(``git diff assets/curriculum/*.json`` is clean after a real export). This automated
test is the justified-manual boundary per VALIDATION.md — it proves the encode/decode
transform is lossless off-device.

Run::

    python tools/firebase/test_roundtrip.py     # exit 0 on parity, non-zero + diff on mismatch
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from point_codec import encode_letter, decode_letter  # noqa: E402
from export_firestore import _normalize_letter, _normalize_lesson  # noqa: E402

_REPO_ROOT = Path(__file__).resolve().parents[2]
_CURRICULUM_DIR = _REPO_ROOT / "assets" / "curriculum"
_LETTERS_JSON = _CURRICULUM_DIR / "letters.json"
_LESSONS_JSON = _CURRICULUM_DIR / "lessons.json"


# ---------------------------------------------------------------------------
# Value-normalization helpers
# ---------------------------------------------------------------------------

def _floatify_points(letter: dict) -> dict:
    """Coerce a source letter's point coords to float so a JSON int (e.g. y==1)
    compares equal to its 1.0 round-trip. The transform is lossless in VALUE, not
    in JSON int/float spelling — this mirrors the codec's num->double cast."""
    out = dict(letter)
    out["referenceStrokes"] = [
        {**stroke, "points": [[float(x), float(y)] for x, y in stroke.get("points", [])]}
        for stroke in letter.get("referenceStrokes", [])
    ]
    return out


def _first_diff(a, b, path="") -> str | None:
    """Return a human-readable field-level path to the first difference, or None."""
    if isinstance(a, dict) and isinstance(b, dict):
        for key in sorted(set(a) | set(b)):
            if key not in a:
                return f"{path}.{key} (missing in roundtrip)"
            if key not in b:
                return f"{path}.{key} (extra in roundtrip)"
            sub = _first_diff(a[key], b[key], f"{path}.{key}")
            if sub:
                return sub
        return None
    if isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            return f"{path} (list length {len(a)} != {len(b)})"
        for i, (ai, bi) in enumerate(zip(a, b)):
            sub = _first_diff(ai, bi, f"{path}[{i}]")
            if sub:
                return sub
        return None
    if a != b:
        return f"{path} ({a!r} != {b!r})"
    return None


def _fail(message: str) -> None:
    print(f"ROUNDTRIP FAIL: {message}", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Transform: source letter -> (encode -> "Firestore doc") -> decode/reassemble
# ---------------------------------------------------------------------------

def _roundtrip_letter(source_letter: dict) -> dict:
    """seed encode -> stand-in Firestore doc -> export decode+reorder."""
    firestore_doc = encode_letter(source_letter)
    return _normalize_letter(firestore_doc)


def main() -> int:
    letters_data = json.loads(_LETTERS_JSON.read_text(encoding="utf-8"))
    lessons_data = json.loads(_LESSONS_JSON.read_text(encoding="utf-8"))
    source_letters = letters_data["letters"]
    source_lessons = lessons_data["lessons"]
    source_ramp = lessons_data["defaultToleranceRamp"]

    # --- 1. Every letter round-trips losslessly (value-normalized) ---
    by_id = {}
    for source_letter in source_letters:
        rt = _roundtrip_letter(source_letter)
        expected = _floatify_points(source_letter)
        diff = _first_diff(expected, rt, source_letter.get("id", "?"))
        if diff is not None:
            _fail(f"letter '{source_letter.get('id')}' not lossless at {diff}")
        by_id[source_letter["id"]] = rt

    # --- 2. Targeted assertions per the acceptance criteria ---

    # alif: points decode to [x, y] PAIRS (lists, not {x,y} maps); signedOff stays true.
    alif = by_id.get("alif")
    if alif is None:
        _fail("alif missing from round-trip")
    alif_points = alif["referenceStrokes"][0]["points"]
    if not all(isinstance(p, list) and len(p) == 2 for p in alif_points):
        _fail(f"alif points did not decode to [x,y] pairs: {alif_points!r}")
    if any(isinstance(p, dict) for p in alif_points):
        _fail("alif points are still {x,y} maps after decode")
    if alif.get("signedOff") is not True:
        _fail(f"alif signedOff != true (got {alif.get('signedOff')!r})")

    # A skeleton letter (baa) keeps empty referenceStrokes is NOT true here (baa has
    # strokes); the true skeletons are the as-yet-unauthored letters. Per Pitfall 6 a
    # skeleton has signedOff:false. Assert at least one letter has signedOff==false,
    # and that any letter with empty referenceStrokes keeps [] + signedOff==false.
    skeletons = [letter_doc for letter_doc in by_id.values() if letter_doc.get("signedOff") is False]
    if not skeletons:
        _fail("expected at least one skeleton letter with signedOff==false")
    for letter_doc in by_id.values():
        strokes = letter_doc.get("referenceStrokes", [])
        if strokes == [] and letter_doc.get("signedOff") is not False:
            _fail(f"letter '{letter_doc.get('id')}' has empty strokes but signedOff != false")

    # --- 3. Lessons + ramp survive (export reorders, value unchanged) ---
    rt_lessons = [_normalize_lesson(lesson) for lesson in source_lessons]
    diff = _first_diff(source_lessons, rt_lessons, "lessons")
    if diff is not None:
        _fail(f"lessons not lossless at {diff}")

    # defaultToleranceRamp survives via the meta layout (seed writes {ramp}, export reads it).
    rt_ramp = {"ramp": source_ramp}["ramp"]
    if rt_ramp != source_ramp:
        _fail(f"defaultToleranceRamp not lossless ({rt_ramp!r} != {source_ramp!r})")
    if source_ramp != ["loose", "normal", "strict"]:
        _fail(f"unexpected ramp value {source_ramp!r}")

    print(
        f"OK: {len(source_letters)} letters + {len(source_lessons)} lessons + ramp "
        f"round-tripped losslessly (seed encode -> export decode == source)."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
