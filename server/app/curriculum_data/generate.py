"""Regenerate the bundled baa server data from the canonical Flutter assets (Plans 14-02 / 15-02).

Run from the server directory with the repo checked out:

    cd server && uv run python -m app.curriculum_data.generate

It reads the canonical, owner-signed Flutter assets and rewrites the server's read-only copies:

  * `baa_authored_ids.json` (the G4 membership set) from `assets/curriculum/units.json`
    (the baa section ids) and `assets/curriculum/exercises.json` (every `baa.`-prefixed id);
  * `curriculum_graph.json` (the G5/G6 graph rail — Plan 15-02) from
    `assets/curriculum/curriculum_graph.json`, filtered to the `baa.*` nodes.

This keeps the bundled copies provably in sync with the canonical source; they are NOT planner
guesses. If the asset layout changes, re-run this rather than hand-editing the derived JSON —
the derived files are committed (so they ship in the Docker image, where the Flutter assets do
not) but MUST never be hand-edited.
"""

from __future__ import annotations

import json
import pathlib
import sys

_HERE = pathlib.Path(__file__).resolve().parent
_OUT = _HERE / "baa_authored_ids.json"
_GRAPH_OUT = _HERE / "curriculum_graph.json"

# server/app/curriculum_data -> server/app -> server -> repo root
_REPO_ROOT = _HERE.parent.parent.parent
_UNITS = _REPO_ROOT / "assets" / "curriculum" / "units.json"
_EXERCISES = _REPO_ROOT / "assets" / "curriculum" / "exercises.json"
_GRAPH = _REPO_ROOT / "assets" / "curriculum" / "curriculum_graph.json"


def regenerate() -> dict:
    """Read the canonical assets and rewrite the bundled server copies.

    Returns the written authored-id payload (the graph payload is written as a side effect).
    """
    if not _UNITS.exists() or not _EXERCISES.exists() or not _GRAPH.exists():
        raise FileNotFoundError(
            f"Canonical curriculum assets not found at {_UNITS} / {_EXERCISES} / {_GRAPH}. "
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

    graph_payload = _regenerate_graph()
    return payload


def _regenerate_graph() -> dict:
    """Derive the server's read-only curriculum-graph copy from the canonical asset (Plan 15-02).

    Reads `assets/curriculum/curriculum_graph.json`, keeps every top-level field verbatim, and
    filters `nodes` to the `baa.*` ids only (the server rails only baa this phase). Returns the
    written payload. NEVER hand-edit the derived file — re-run this generator.
    """
    graph = json.loads(_GRAPH.read_text(encoding="utf-8"))
    baa_nodes = [n for n in graph.get("nodes", []) if str(n.get("exerciseId", "")).startswith("baa.")]
    payload = {**graph, "nodes": baa_nodes}
    _GRAPH_OUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return payload


if __name__ == "__main__":
    written = regenerate()
    graph = json.loads(_GRAPH_OUT.read_text(encoding="utf-8"))
    print(
        f"Wrote {_OUT} — {len(written['section_ids'])} sections, "
        f"{len(written['exercise_ids'])} baa exercise ids.\n"
        f"Wrote {_GRAPH_OUT} — letterId={graph.get('letterId')!r}, "
        f"signedOff={graph.get('signedOff')}, {len(graph.get('nodes', []))} baa.* graph nodes."
    )
    sys.exit(0)
