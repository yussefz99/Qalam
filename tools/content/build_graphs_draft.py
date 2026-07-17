"""Generate DRAFT baa-shaped curriculum graphs, one per letter (except alif/baa).

Mirrors the SIGNED baa graph (``assets/curriculum/curriculum_graph.json``): the same
6 competencies, the same منقول→منظور→غير-منظور tier lattice, and the same
exercise→competency/tier/minCleanReps mapping — applied mechanically to each letter's
exercise set. Reusing the mother's signed tier structure is not inventing pedagogy;
the per-node CONTENT stays her call, so every graph is ``signedOff: false``.

Node id sources:
  * taa — the live signed ``taa.*`` ids in ``exercises.json`` (read-only);
  * letters 4..28 — the draft ids in ``docs/curriculum/drafts/exercises/``.

Output: ``docs/curriculum/drafts/graphs/<order>-<letterId>.graph.json``. Never writes
the live ``curriculum_graph.json``.

Run from ``tools/``:  ``python -m content.build_graphs_draft`` (needs the draft
exercises first: ``python -m content.build_exercises_draft``).
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LETTERS_JSON = REPO_ROOT / "assets" / "curriculum" / "letters.json"
EXERCISES_JSON = REPO_ROOT / "assets" / "curriculum" / "exercises.json"
DRAFT_EX_DIR = REPO_ROOT / "docs" / "curriculum" / "drafts" / "exercises"
OUT_DIR = REPO_ROOT / "docs" / "curriculum" / "drafts" / "graphs"

# Exactly the baa graph's competencies + tiers (the mother's signed structure).
COMPETENCIES = [
    {"id": "recognize", "essential": True, "prerequisites": []},
    {"id": "positionalForms", "essential": True, "prerequisites": ["recognize"]},
    {"id": "copyWrite", "essential": True, "prerequisites": ["positionalForms"]},
    {"id": "fluentReading", "essential": True, "prerequisites": ["copyWrite"]},
    {"id": "wordBuilding", "essential": False, "prerequisites": ["copyWrite"]},
    {"id": "grammarTransform", "essential": False, "prerequisites": ["copyWrite"]},
]
TIERS = ["manqul", "manzur", "ghayrManzur"]

# Graphs are built for every letter EXCEPT alif and baa (baa is the live signed one).
SKIP_GRAPH = {"alif", "baa"}


def classify(suffix: str) -> tuple[str, str | None, int]:
    """Map an exercise id suffix (after '<lid>.') to (competency, tier, minCleanReps).

    Mirrors the baa graph node mapping exactly.
    """
    if suffix.startswith("teachCard"):
        return "recognize", None, 1
    if suffix.startswith("traceLetter") or suffix.startswith("writeLetter"):
        return "positionalForms", None, 3
    if suffix.startswith("connectWord") or suffix.startswith("completeWord"):
        return "copyWrite", "manqul", 3
    if suffix == "writeWord.copy" or suffix == "writeWord.picture":
        return "copyWrite", "manzur", 3
    if suffix == "writeWord.dictation":
        return "copyWrite", "ghayrManzur", 3
    if suffix == "buildSentence.hear":
        return "fluentReading", "ghayrManzur", 1
    if suffix == "buildSentence.picture":
        return "fluentReading", "manzur", 1
    if suffix.startswith("fillBlank"):
        return "wordBuilding", None, 1
    if suffix.startswith("transformWord"):
        return "grammarTransform", None, 1
    # Unknown shape — surface it rather than guess a competency.
    return "UNCLASSIFIED", None, 1


def node_for(exercise_id: str, lid: str) -> dict:
    suffix = exercise_id[len(lid) + 1:] if exercise_id.startswith(lid + ".") else exercise_id
    competency, tier, reps = classify(suffix)
    return {"exerciseId": exercise_id, "competency": competency, "tier": tier, "minCleanReps": reps}


def taa_live_ids() -> list[str]:
    data = json.loads(EXERCISES_JSON.read_text(encoding="utf-8"))
    return [e["id"] for e in data["exercises"] if e["id"].startswith("taa.")]


def draft_ids(lid: str, order: int) -> list[str] | None:
    path = DRAFT_EX_DIR / f"{order:02d}-{lid}.exercises.json"
    if not path.exists():
        return None
    doc = json.loads(path.read_text(encoding="utf-8"))
    return [e["id"] for e in doc["exercises"]]


def main() -> int:
    letters = json.loads(LETTERS_JSON.read_text(encoding="utf-8"))["letters"]
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    written = 0
    summary: list[str] = []
    for letter in sorted(letters, key=lambda l: int(l["introOrder"])):
        lid = letter["id"]
        order = int(letter["introOrder"])
        if lid in SKIP_GRAPH:
            continue

        if lid == "taa":
            ids = taa_live_ids()
            id_source = "live signed taa.* ids in exercises.json"
        else:
            ids = draft_ids(lid, order)
            id_source = f"draft ids in docs/curriculum/drafts/exercises/{order:02d}-{lid}.exercises.json"
        if not ids:
            summary.append(f"  SKIP {lid}: no exercise ids (run build_exercises_draft first)")
            continue

        nodes = [node_for(eid, lid) for eid in ids]
        unclassified = [n["exerciseId"] for n in nodes if n["competency"] == "UNCLASSIFIED"]
        doc = {
            "_meta": {
                "title": f"{lid} curriculum graph — DRAFT (mirrors the signed baa structure)",
                "status": "DRAFT — signedOff:false. The mother signs at the TIER level; owner promotes into curriculum_graph.json.",
                "structureSource": "assets/curriculum/curriculum_graph.json (signed baa graph — competencies + tiers reused mechanically).",
                "nodeIdSource": id_source,
                "reviewNote": "Confirm the competency/tier placement + per-skill clean-reps for THIS letter, and the exercise content (which stays signedOff:false at the exercise level).",
            },
            "letterId": lid,
            "signedOff": False,
            "competencies": COMPETENCIES,
            "tiers": TIERS,
            "nodes": nodes,
        }
        out = OUT_DIR / f"{order:02d}-{lid}.graph.json"
        out.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n",
                       encoding="utf-8", newline="\n")
        written += 1
        flag = f" · UNCLASSIFIED: {unclassified}" if unclassified else ""
        summary.append(f"  {lid}: {len(nodes)} nodes ({id_source.split(' ')[0]}){flag}")

    print(f"Wrote {written} draft graph(s) to {OUT_DIR.relative_to(REPO_ROOT)}")
    print("\n".join(summary))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
