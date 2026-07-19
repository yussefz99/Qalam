"""Seed the Schema-v2 curriculum content (graphs / exercises / units) into
Firestore — the finalization Lane A companion to ``seed_firestore.py``.

``seed_firestore.py`` owns ``letters`` / ``lessons`` / ``meta``; THIS script owns
the three collections the letter-progression engine resolves FIRST from
Firestore (with the bundled assets as fallback):

* every per-letter graph      -> collection ``graphs``,    doc id == letterId
  (``assets/curriculum/graphs/<letterId>.json``, written verbatim — graph JSON
  carries no nested arrays, so no point codec applies)
* every exercise config       -> collection ``exercises``, doc id == exercise id
  (``assets/curriculum/exercises.json``)
* every LetterUnit            -> collection ``units``,     doc id == letterId
  (``assets/curriculum/units.json`` — including the optional per-unit
  ``presentedEssentials`` declaration the scoped mastery gate derives from)

This is THE step that makes "add a letter by only touching the database" true:
once a letter's graph + exercises + unit docs exist in Firestore, the app
resolves them live (Firestore doc -> bundled asset fallback) with NO Dart
change and NO rebuild.

Usage::

    # one letter (graph + its exercises + its unit):
    python tools/firebase/seed_curriculum_v2.py --letter taa

    # every letter that has a graph asset (plus ALL exercises + ALL units):
    python tools/firebase/seed_curriculum_v2.py --all

Idempotent by design (mirrors seed_firestore.py, D-13): every write uses
``doc(id).set(...)``, never ``add()``. Re-running overwrites the same docs in
place — never a duplicate.

Safety guards:

* every payload is checked for Firestore-illegal nested arrays BEFORE any
  write (fail fast, nothing partially seeded);
* the seen-letters wall (L2, D-06): every LIVE graph-node exercise is refused
  BEFORE the first write if it reaches ahead of the learned set — reusing the
  L0 predicate from ``tools/content/validate.py`` so the seeder and the bundle
  lint/audit refuse the SAME content. The device reads curriculum Firestore-first,
  so this is what stops a bad seed reaching the child even when the bundle lint
  passes. Dormant configs (referenced by no live node) and the owner-approved
  exceptions are exempt, exactly as the L0/L1 layers scope them;
* ``--letter X`` refuses to run when ``graphs/X.json`` does not exist (seed
  the asset first — the graph is what rails progression);
* content posture is untouched: whatever ``signedOff`` value the asset carries
  is what lands in Firestore (the promotion pipeline already forces ``false``
  on unsigned content — this script never flips a flag either way).

Authentication: identical to seed_firestore.py — the Admin SDK reads
``GOOGLE_APPLICATION_CREDENTIALS`` (the gitignored service-account key; see
README "NEVER commit the service-account key")::

    export GOOGLE_APPLICATION_CREDENTIALS=tools/firebase/<your-key>.json
    python tools/firebase/seed_curriculum_v2.py --all
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

_REPO_ROOT = Path(__file__).resolve().parents[2]

# The seen-letters wall's L0 parity source lives in tools/content/validate.py. Import
# the SAME predicate + scoping the L0 audit / L1 lint use so the seeder (L2) refuses
# byte-identical content — nothing the bundle lint would refuse can reach prod (D-06).
# When this script is run directly (``python tools/firebase/seed_curriculum_v2.py``)
# sys.path[0] is tools/firebase/, NOT the repo root, so add the repo root explicitly.
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.validate import (  # noqa: E402
    OWNER_APPROVED_EXCEPTIONS,
    live_graph_node_ids,
    load_intro_order,
    unlearned_letters_for_exercise,
)

_CURRICULUM_DIR = _REPO_ROOT / "assets" / "curriculum"
_GRAPHS_DIR = _CURRICULUM_DIR / "graphs"
_EXERCISES_JSON = _CURRICULUM_DIR / "exercises.json"
_UNITS_JSON = _CURRICULUM_DIR / "units.json"

GRAPHS_COLLECTION = "graphs"
EXERCISES_COLLECTION = "exercises"
UNITS_COLLECTION = "units"


def _init_app() -> None:
    """Initialize firebase-admin once, via Application Default Credentials
    (GOOGLE_APPLICATION_CREDENTIALS -> the gitignored service-account key)."""
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.ApplicationDefault())


def _load_json(path: Path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def _nested_array_paths(obj, path: str = "") -> list[str]:
    """Every JSON path where an array directly contains another array —
    illegal in a Firestore document (Pitfall 1). Empty == safe to write."""
    hits: list[str] = []
    if isinstance(obj, list):
        for i, v in enumerate(obj):
            child = f"{path}[{i}]"
            if isinstance(v, list):
                hits.append(child)
            hits.extend(_nested_array_paths(v, child))
    elif isinstance(obj, dict):
        for k, v in obj.items():
            hits.extend(_nested_array_paths(v, f"{path}.{k}"))
    return hits


def _assert_firestore_legal(doc_id: str, payload) -> None:
    hits = _nested_array_paths(payload)
    if hits:
        raise SystemExit(
            f"seed_curriculum_v2: doc '{doc_id}' carries Firestore-illegal "
            f"nested arrays at {hits[:5]} (total {len(hits)}). Reshape the "
            f"data (see point_codec.py for the letters precedent) — nothing "
            f"was written."
        )


def _assert_learned_letters_legal(
    ex: dict, order: dict[str, int], live_ids: set[str]
) -> None:
    """Refuse a LIVE-node exercise that reaches ahead of the learned set — the L2
    sibling of ``_assert_firestore_legal``, reusing the L0 predicate so the seeder and
    the audit refuse byte-identical content (D-06). The device reads curriculum
    Firestore-first, so a bad seed reaches the child even when the bundle lint passes;
    this closes that bypass BEFORE the first write.

    Scoped to LIVE graph nodes exactly as the L0 gate / L1 lint are: a card referenced
    by NO live graph node (a dormant config — e.g. ``baa.buildSentence.hear``) is
    seeded but NEVER refused, because it is never presented. For a live node, a
    reach-ahead card (``unlearned_letters_for_exercise`` non-empty) raises SystemExit
    UNLESS its id is an ``OWNER_APPROVED_EXCEPTIONS`` member (the 4 baa D-09 + 18
    taa/thaa D-16 cards, mother-verdict pending). Fail-fast: this runs in the pre-write
    pass, before the first ``doc(id).set(...)`` — nothing is written on refusal.
    """
    ex_id = str(ex.get("id", ""))
    if ex_id not in live_ids:
        return  # dormant config — referenced by no live node; never gated (L0/L1 parity)
    ahead = unlearned_letters_for_exercise(ex, order)
    if ahead and ex_id not in OWNER_APPROVED_EXCEPTIONS:
        unseen = ", ".join(f"{l}({o})" for l, o in sorted(ahead, key=lambda x: x[1]))
        raise SystemExit(
            f"seed_curriculum_v2: doc '{ex_id}' demands unseen letter(s) {unseen}; "
            f"nothing was written."
        )


def _graph_letter_ids() -> list[str]:
    """Every letter that has a per-letter graph asset (the progression rail)."""
    return sorted(p.stem for p in _GRAPHS_DIR.glob("*.json"))


def seed(db, letter: str | None) -> dict:
    """Seed graphs/exercises/units for [letter] (or every letter when None).

    Returns a summary dict for logging. All payloads are validated BEFORE the
    first write (fail fast — never a partial seed on bad data).
    """
    graph_letters = _graph_letter_ids()
    if letter is not None and letter not in graph_letters:
        raise SystemExit(
            f"seed_curriculum_v2: no graph asset for '{letter}' "
            f"(assets/curriculum/graphs/{letter}.json missing). The graph is "
            f"what rails progression — promote/author it first "
            f"(tools/content/promote_letter.py). Available: {graph_letters}"
        )
    letters = [letter] if letter is not None else graph_letters

    all_exercises = _load_json(_EXERCISES_JSON)["exercises"]
    all_units = _load_json(_UNITS_JSON)["units"]

    # Scope exercises/units to the requested letter(s). In --all mode every
    # exercise and every unit is seeded (they are cheap, id-keyed docs).
    def _belongs(ex_id: str) -> bool:
        return letter is None or ex_id.startswith(f"{letter}.")

    exercises = [e for e in all_exercises if _belongs(str(e["id"]))]
    units = [u for u in all_units if letter is None or u["letterId"] == letter]
    graphs = {lid: _load_json(_GRAPHS_DIR / f"{lid}.json") for lid in letters}

    # The seen-letters wall's parity inputs, computed ONCE for the pre-write pass:
    # the live graph-node set (so dormant configs are never gated) + the intro order
    # (the learned-set bar). Both come from validate.py so L0/L1/L2 judge identically.
    live_ids = live_graph_node_ids()
    order = load_intro_order()

    # Validate EVERYTHING before the first write (fail fast, no partial seed).
    for lid, g in graphs.items():
        _assert_firestore_legal(f"graphs/{lid}", g)
    for e in exercises:
        _assert_firestore_legal(f"exercises/{e['id']}", e)
        _assert_learned_letters_legal(e, order, live_ids)  # refuse reach-ahead content
    for u in units:
        _assert_firestore_legal(f"units/{u['letterId']}", u)

    # Writes — doc(id).set() everywhere: idempotent by id, never a duplicate.
    graphs_col = db.collection(GRAPHS_COLLECTION)
    for lid, g in graphs.items():
        graphs_col.document(lid).set(g)

    exercises_col = db.collection(EXERCISES_COLLECTION)
    for e in exercises:
        exercises_col.document(str(e["id"])).set(e)

    units_col = db.collection(UNITS_COLLECTION)
    for u in units:
        units_col.document(str(u["letterId"])).set(u)

    return {
        "letters": letters,
        "graphs": len(graphs),
        "exercises": len(exercises),
        "units": len(units),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="seed_curriculum_v2",
        description=(
            "Seed graphs/exercises/units into Firestore (idempotent; the "
            "Lane-A companion to seed_firestore.py)."
        ),
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--letter", help="seed one letter's graph + exercises + unit (e.g. taa)"
    )
    group.add_argument(
        "--all", action="store_true",
        help="seed every letter that has a graph asset (+ all exercises/units)",
    )
    args = parser.parse_args(argv)

    _init_app()
    db = firestore.client()
    summary = seed(db, None if args.all else args.letter)
    print(
        f"Seeded {summary['graphs']} graph(s), {summary['exercises']} "
        f"exercise doc(s), {summary['units']} unit doc(s) idempotently "
        f"for {summary['letters']}."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
