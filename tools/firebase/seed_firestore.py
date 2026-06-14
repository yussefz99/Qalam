"""Seed the bundled curriculum JSON into Firestore (D-13).

Reads ``assets/curriculum/letters.json`` + ``assets/curriculum/lessons.json`` and
writes them into Firestore:

* every letter  -> collection ``letters``, doc id == ``letter["id"]``
* every lesson  -> collection ``lessons``, doc id == ``lesson["id"]``
* the file-level ``defaultToleranceRamp`` -> ``meta/toleranceRamp`` field ``ramp`` (D-07)

Idempotent by design (D-13): every write uses ``doc(id).set(...)``, never ``add()``.
Re-running overwrites the same docs in place — it never creates duplicates, so the
collection always holds exactly 28 letters + 28 lessons + one meta doc.

The point representation is rewritten through the SHARED ``point_codec`` (Plan 02):
``encode_letter`` turns each stroke's ``[x, y]`` pairs into ``{"x": x, "y": y}`` maps,
because Firestore forbids arrays-of-arrays (Pitfall 1 / D-06). The Dart read path and
``export_firestore.py`` apply the exact inverse, so the round-trip is lossless.

Authentication: the Admin SDK authenticates via Application Default Credentials. Point
``GOOGLE_APPLICATION_CREDENTIALS`` at the downloaded service-account key before running::

    export GOOGLE_APPLICATION_CREDENTIALS=tools/firebase/<your-key>.json
    python tools/firebase/seed_firestore.py

The Admin SDK bypasses Firestore security rules, so the production deny-all rules do
NOT block this tool. NEVER commit the key (it is gitignored; see README).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

# Make point_codec importable whether run as a script or a module.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from point_codec import encode_letter  # noqa: E402

_REPO_ROOT = Path(__file__).resolve().parents[2]
_CURRICULUM_DIR = _REPO_ROOT / "assets" / "curriculum"
_LETTERS_JSON = _CURRICULUM_DIR / "letters.json"
_LESSONS_JSON = _CURRICULUM_DIR / "lessons.json"

LETTERS_COLLECTION = "letters"
LESSONS_COLLECTION = "lessons"
META_COLLECTION = "meta"
TOLERANCE_RAMP_DOC = "toleranceRamp"


def _init_app() -> None:
    """Initialize firebase-admin once, via Application Default Credentials.

    Relies on GOOGLE_APPLICATION_CREDENTIALS pointing at the service-account key.
    Safe to call repeatedly — re-init raises, so we guard on the default app.
    """
    if not firebase_admin._apps:
        # credentials.ApplicationDefault() reads GOOGLE_APPLICATION_CREDENTIALS.
        firebase_admin.initialize_app(credentials.ApplicationDefault())


def seed(db) -> dict:
    """Write letters, lessons, and the tolerance-ramp meta doc to Firestore.

    Returns a small summary dict for logging/tests. Uses set() everywhere so the
    seed is idempotent by doc id (D-13).
    """
    letters_data = json.loads(_LETTERS_JSON.read_text(encoding="utf-8"))
    lessons_data = json.loads(_LESSONS_JSON.read_text(encoding="utf-8"))

    letters = letters_data["letters"]
    lessons = lessons_data["lessons"]
    default_ramp = lessons_data["defaultToleranceRamp"]

    # Letters — encode the {x,y} point shape before writing (Pitfall 1 / D-06).
    letters_col = db.collection(LETTERS_COLLECTION)
    for letter in letters:
        letters_col.document(letter["id"]).set(encode_letter(letter))

    # Lessons — no point transform needed; written verbatim by doc id.
    lessons_col = db.collection(LESSONS_COLLECTION)
    for lesson in lessons:
        lessons_col.document(lesson["id"]).set(lesson)

    # defaultToleranceRamp -> meta/toleranceRamp, field `ramp` (D-07, Plan 02 layout).
    db.collection(META_COLLECTION).document(TOLERANCE_RAMP_DOC).set({"ramp": default_ramp})

    return {
        "letters": len(letters),
        "lessons": len(lessons),
        "ramp": default_ramp,
    }


def main() -> int:
    _init_app()
    db = firestore.client()
    summary = seed(db)
    print(
        f"Seeded {summary['letters']} letters, {summary['lessons']} lessons, "
        f"and meta/{TOLERANCE_RAMP_DOC} (ramp={summary['ramp']}) idempotently."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
