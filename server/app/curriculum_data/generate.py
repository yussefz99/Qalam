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
_EXERCISES_OUT = _HERE / "exercises.json"

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
    # AUTHORED_BAA_IDS is the SIGNED baa reference set the agent's G4 gate honors, so it
    # carries only SIGNED baa exercises. Plan 18-02 adds baa.microDrill.* enrichment as
    # signedOff:false content — it is DELIBERATELY excluded here until the owner-mother
    # signs the drill copy at the 18-11 HUMAN-UAT gate, at which point (signedOff:true)
    # it auto-joins this set with no generator change. The micro-drill NODES still ship in
    # the derived graph copy (below); only the G4 signed-reference set waits for sign-off.
    exercise_ids = sorted(
        e["id"]
        for e in exercises["exercises"]
        if e["id"].startswith("baa.") and e.get("signedOff") is True
    )

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
    exercises_payload = _regenerate_exercises(exercises)
    return payload


def _regenerate_exercises(exercises: dict) -> dict:
    """Derive the server's read-only exercise copy from the canonical asset (Plan 18-02).

    Keeps every `baa.*` exercise VERBATIM (including the `baa.microDrill.*` enrichment set),
    preserving the new `letters` + `criteria` labels and each micro-drill's `spotlightZone` /
    `signedOff:false`. baa-only (D-11 — no ت/ث/ا exercises leak). This copy ships in the Docker
    image where the Flutter assets do not; the evidence deriver / compiler read the labels here.
    NEVER hand-edit — re-run this generator.
    """
    baa_exercises = [
        e for e in exercises["exercises"] if str(e.get("id", "")).startswith("baa.")
    ]
    payload = {
        "_meta": {
            "title": "Derived baa exercise copy — letters/criteria labels + micro-drills (Plan 18-02).",
            "source": "assets/curriculum/exercises.json, filtered to baa.* (D-11 baa-only).",
            "regenerate": "cd server && uv run python -m app.curriculum_data.generate",
            "note": "DERIVED — never hand-edit. baa.microDrill.* ship signedOff:false until the 18-11 mother sign-off.",
        },
        "exercises": baa_exercises,
    }
    _EXERCISES_OUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return payload


def _regenerate_graph() -> dict:
    """Derive the server's read-only curriculum-graph copy from the canonical asset (Plan 15-02).

    Reads `assets/curriculum/curriculum_graph.json`, keeps every top-level field verbatim
    (including the Plan 18-02 `microDrill` competency), and filters `nodes` to the `baa.*` ids
    only (the server rails only baa this phase). The `baa.*` filter admits `baa.microDrill.*`,
    and each node is copied whole so the micro-drill `criterion` tag is preserved. Returns the
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
    exercises_copy = json.loads(_EXERCISES_OUT.read_text(encoding="utf-8"))
    micro = [
        n for n in graph.get("nodes", []) if n.get("competency") == "microDrill"
    ]
    print(
        f"Wrote {_OUT} — {len(written['section_ids'])} sections, "
        f"{len(written['exercise_ids'])} signed baa exercise ids.\n"
        f"Wrote {_GRAPH_OUT} — letterId={graph.get('letterId')!r}, "
        f"signedOff={graph.get('signedOff')}, {len(graph.get('nodes', []))} baa.* graph nodes "
        f"({len(micro)} microDrill).\n"
        f"Wrote {_EXERCISES_OUT} — {len(exercises_copy.get('exercises', []))} baa.* exercises "
        f"(letters/criteria labels + micro-drills)."
    )
    sys.exit(0)
