"""Regenerate the bundled baa authored-id seed from the canonical Flutter assets (Plan 14-02).

Run from the server directory with the repo checked out:

    cd server && uv run python -m app.curriculum_data.generate

It reads `assets/curriculum/units.json` (the baa section ids) and
`assets/curriculum/exercises.json` (every `baa.`-prefixed exercise id) — the owner-signed
bundled seed — and rewrites `baa_authored_ids.json`. This keeps the bundled copy provably
in sync with the canonical source; it is NOT a planner guess. If the asset layout changes,
re-run this rather than hand-editing the JSON.
"""

from __future__ import annotations

import json
import pathlib
import sys

_HERE = pathlib.Path(__file__).resolve().parent
_OUT = _HERE / "baa_authored_ids.json"

# server/app/curriculum_data -> server/app -> server -> repo root
_REPO_ROOT = _HERE.parent.parent.parent
_UNITS = _REPO_ROOT / "assets" / "curriculum" / "units.json"
_EXERCISES = _REPO_ROOT / "assets" / "curriculum" / "exercises.json"


def regenerate() -> dict:
    """Read the canonical assets and rewrite the bundled seed. Returns the written payload."""
    if not _UNITS.exists() or not _EXERCISES.exists():
        raise FileNotFoundError(
            f"Canonical curriculum assets not found at {_UNITS} / {_EXERCISES}. "
            "Run this from a full repo checkout (the Flutter assets are not in the Docker image)."
        )

    units = json.loads(_UNITS.read_text(encoding="utf-8"))
    exercises = json.loads(_EXERCISES.read_text(encoding="utf-8"))

    baa_unit = next(u for u in units["units"] if u["letterId"] == "baa")
    section_ids = [s["id"] for s in baa_unit["sections"]]
    exercise_ids = sorted(e["id"] for e in exercises["exercises"] if e["id"].startswith("baa."))

    payload = {
        "_meta": {
            "title": "Canonical baa authored id set — transcribed verbatim from the owner-signed seed.",
            "source": "assets/curriculum/units.json (baa sections) + assets/curriculum/exercises.json (baa.* exercise ids).",
            "regenerate": "cd server && uv run python -m app.curriculum_data.generate",
            "sign_off": "Owner / owner-mother must confirm this id set matches the signed curriculum (14-02 SUMMARY).",
        },
        "letterId": "baa",
        "section_ids": section_ids,
        "exercise_ids": exercise_ids,
    }
    _OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return payload


if __name__ == "__main__":
    written = regenerate()
    print(
        f"Wrote {_OUT} — {len(written['section_ids'])} sections, "
        f"{len(written['exercise_ids'])} baa exercise ids."
    )
    sys.exit(0)
