"""Export Firestore curriculum back into the bundled JSON snapshot (D-15).

The inverse of ``seed_firestore.py``. Reads every doc from the ``letters`` and
``lessons`` collections plus ``meta/toleranceRamp``, rebuilds the exact source JSON
shapes, and overwrites::

    assets/curriculum/letters.json   -> {"letters": [...] }              (sorted by introOrder)
    assets/curriculum/lessons.json   -> {"defaultToleranceRamp": [...],   "lessons": [...]}  (sorted by order)

Every letter is passed through the SHARED ``point_codec.decode_letter`` (Plan 02) so
the Firestore ``{"x": x, "y": y}`` point maps rebuild into ``[x, y]`` pairs — the inverse
of the seed's ``encode_letter`` (Pitfall 1 / D-06). This is how a curriculum author who
edited a letter directly in the Firebase Console (the D-14 operating policy) pulls those
edits back into the offline bundle.

JSON is written with ``indent=2``, ``ensure_ascii=False`` (preserve the Arabic glyphs),
and the field key order normalized to match the source so ``git diff`` is clean when the
round-trip is lossless. A non-empty diff after an export is a REAL signal that the seed
or codec dropped/changed a field — not something to overwrite away.

Authentication is identical to the seed: GOOGLE_APPLICATION_CREDENTIALS -> service-account
key (Admin SDK, bypasses security rules). NEVER commit the key.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

sys.path.insert(0, str(Path(__file__).resolve().parent))
from point_codec import decode_letter  # noqa: E402

_REPO_ROOT = Path(__file__).resolve().parents[2]
_CURRICULUM_DIR = _REPO_ROOT / "assets" / "curriculum"
_LETTERS_JSON = _CURRICULUM_DIR / "letters.json"
_LESSONS_JSON = _CURRICULUM_DIR / "lessons.json"

LETTERS_COLLECTION = "letters"
LESSONS_COLLECTION = "lessons"
META_COLLECTION = "meta"
TOLERANCE_RAMP_DOC = "toleranceRamp"

# Canonical field order for a letter doc, matching assets/curriculum/letters.json.
# Keys absent on a given doc are simply skipped, so an optional field (e.g. audio)
# that a doc lacks does not break ordering.
_LETTER_KEY_ORDER = [
    "id",
    "char",
    "name",
    "introOrder",
    "forms",
    "referenceStrokes",
    "cleanRepsToAdvance",
    "commonMistakes",
    "mistakesStatus",
    "signedOff",
    "tolerances",
    "audio",
]

_STROKE_KEY_ORDER = ["order", "label", "type", "points", "direction"]

_LESSON_KEY_ORDER = ["id", "order", "title", "items", "unlock"]


def _ordered(doc: dict, key_order: list) -> dict:
    """Return a new dict with known keys first (in key_order), then any extras.

    Extra keys (not in key_order) are appended in their existing order so nothing
    is silently dropped — they would surface as a diff for a human to reconcile.
    """
    out = {k: doc[k] for k in key_order if k in doc}
    for k, v in doc.items():
        if k not in out:
            out[k] = v
    return out


def _normalize_letter(letter: dict) -> dict:
    """Decode the points, then reorder the letter + its strokes to the source shape."""
    decoded = decode_letter(letter)
    decoded["referenceStrokes"] = [
        _ordered(stroke, _STROKE_KEY_ORDER) for stroke in decoded.get("referenceStrokes", [])
    ]
    return _ordered(decoded, _LETTER_KEY_ORDER)


def _init_app() -> None:
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.ApplicationDefault())


def export(db) -> dict:
    """Read Firestore, rebuild the two source JSON structures, and write them.

    Returns the in-memory structures (for tests) after writing them to disk.
    """
    # Letters — decode points, sort by introOrder to match the source file.
    raw_letters = [d.to_dict() for d in db.collection(LETTERS_COLLECTION).stream()]
    letters = [_normalize_letter(letter) for letter in raw_letters]
    letters.sort(key=lambda letter_doc: letter_doc.get("introOrder", 0))

    # Lessons — sort by order to match the source file.
    raw_lessons = [d.to_dict() for d in db.collection(LESSONS_COLLECTION).stream()]
    lessons = [_ordered(lesson, _LESSON_KEY_ORDER) for lesson in raw_lessons]
    lessons.sort(key=lambda lesson_doc: lesson_doc.get("order", 0))

    # meta/toleranceRamp -> defaultToleranceRamp (D-07).
    ramp_snapshot = db.collection(META_COLLECTION).document(TOLERANCE_RAMP_DOC).get()
    default_ramp = ramp_snapshot.to_dict().get("ramp", []) if ramp_snapshot.exists else []

    letters_obj = {"letters": letters}
    lessons_obj = {"defaultToleranceRamp": default_ramp, "lessons": lessons}

    _write_json(_LETTERS_JSON, letters_obj)
    _write_json(_LESSONS_JSON, lessons_obj)

    return {"letters": letters_obj, "lessons": lessons_obj}


def _write_json(path: Path, obj: dict) -> None:
    """Write obj as 2-space-indented UTF-8 JSON with a trailing newline."""
    text = json.dumps(obj, indent=2, ensure_ascii=False)
    path.write_text(text + "\n", encoding="utf-8")


def main() -> int:
    _init_app()
    db = firestore.client()
    result = export(db)
    print(
        f"Exported {len(result['letters']['letters'])} letters and "
        f"{len(result['lessons']['lessons'])} lessons to assets/curriculum/ "
        f"(ramp={result['lessons']['defaultToleranceRamp']})."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
