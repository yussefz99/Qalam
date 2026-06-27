"""The authored-curriculum membership guard (G4) + the curriculum-graph rail (G5/G6).

`AUTHORED_BAA_IDS` is the closed set of signed-off baa ids the agent may reference (Plan 14-02,
G4 / TUTOR-05). The curriculum GRAPH (Plan 15-02, G5/G6) adds an order/prerequisite/difficulty
rail on TOP of membership: it maps each baa exercise to a competency, an إملاء difficulty tier
(منقول→منظور→غير منظور), and a forward prerequisite chain. Pydantic validates the *shape* of
`Plan.next_exercise_id`; THIS module validates *curriculum membership* (G4) AND *graph legality*
(G5 tier-reachability + G6 prerequisites). A fabricated id, an unreached tier, or a skipped
prerequisite is a grounding failure and the run fails closed to AuthoredFallback.

Sources of truth, both DERIVED from the canonical Flutter assets (never hand-edited):
  * `app/curriculum_data/baa_authored_ids.json` — the G4 membership set, from
    `assets/curriculum/units.json` + `assets/curriculum/exercises.json`.
  * `app/curriculum_data/curriculum_graph.json` — the G5/G6 graph, from
    `assets/curriculum/curriculum_graph.json` (the `baa.*` nodes only).
`app/curriculum_data/generate.py` regenerates BOTH from the canonical assets so the bundled
copies can never drift. Both are loaded ONCE at import.

The G4 guard accepts BOTH the 19 `baa.*` exercise ids AND the 6 baa section ids
(`meet`, `watchTrace`, `forms`, `words`, `listenWrite`, `mastery`) — `present_activity` may
reference either a concrete exercise (`baa.traceLetter.isolated`) or a section the child moves to.
A `letterId` family token (`baa`) is also accepted so the agent can name the letter family. The
graph (G5/G6) keys ONLY on exercise ids (the graph nodes are exercises); a section/family token
has no tier and no graph competency, so G5/G6 are no-ops for it (G4 still bounds it).

The إملاء tier ladder is a strict progressive unlock: `manqul` (copy) is always reachable;
`manzur` (look-then-write) unlocks once `manqul` is cleared; `ghayrManzur` (dictation) unlocks
once `manzur` is cleared. CRITICAL (Pitfall 3): a LOWER tier of an already-reached competency is
graph-LEGAL — backward remediation (ghayrManzur fail → manzur) passes G5/G6 because its tier is
reachable and its prereqs are met. Forward-only means "no skipping ahead," not "no stepping back."

Fail-closed (Security T-15-02-T): a missing/unreadable derived graph degrades to an EMPTY graph at
import (never raises in a way that 500s /coach). With an empty graph, `tier_of` returns None (so
G5 is a no-op) and `prerequisites_met` returns False (so G6 rejects every exercise that has graph
competencies) — the rail rejects → AuthoredFallback floor. G4 (`is_authored`) still bounds every
id independently.
"""

from __future__ import annotations

import json
import logging
import pathlib

logger = logging.getLogger("qalam.tutor.curriculum")

_CURRICULUM_DATA = pathlib.Path(__file__).resolve().parent / "curriculum_data"
_SEED_PATH = _CURRICULUM_DATA / "baa_authored_ids.json"
_GRAPH_PATH = _CURRICULUM_DATA / "curriculum_graph.json"


def _load_authored_ids() -> frozenset[str]:
    """Load the closed authored-id set from the bundled, owner-signed seed."""
    data = json.loads(_SEED_PATH.read_text(encoding="utf-8"))
    letter_id = data["letterId"]
    section_ids = data["section_ids"]
    exercise_ids = data["exercise_ids"]
    # The letter family token + every section id + every authored exercise id.
    return frozenset({letter_id, *section_ids, *exercise_ids})


# The single closed set the G4 guard validates against (loaded once at import).
AUTHORED_BAA_IDS: frozenset[str] = _load_authored_ids()


def is_authored(exercise_id: str | None) -> bool:
    """True iff `exercise_id` is in the owner-signed baa curriculum set (G4 membership).

    `None`/empty is NOT authored (a missing id cannot be presented). Whitespace-only is rejected.
    """
    if not exercise_id or not exercise_id.strip():
        return False
    return exercise_id in AUTHORED_BAA_IDS


# --- The curriculum graph (G5/G6 rail — Plan 15-02) ---------------------------------------


def _empty_graph() -> dict:
    """The fail-closed graph (T-15-02-T): no tiers, no competencies, no nodes."""
    return {"letterId": "baa", "signedOff": False, "competencies": [], "tiers": [], "nodes": []}


def _load_graph() -> dict:
    """Load the derived server graph copy ONCE at import; fail closed on any error.

    A missing/unreadable/malformed derived graph degrades to the empty graph rather than raising
    at import — that would 500 /coach. With the empty graph the rail rejects (G6 fails closed) and
    the run degrades to the AuthoredFallback floor.
    """
    try:
        data = json.loads(_GRAPH_PATH.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:  # missing file / unreadable / invalid JSON
        logger.warning(
            "curriculum graph unreadable at %s (%s); failing closed to an empty graph (rail rejects).",
            _GRAPH_PATH,
            exc,
        )
        return _empty_graph()
    if not isinstance(data, dict) or "nodes" not in data:
        logger.warning("curriculum graph at %s is malformed; failing closed to an empty graph.", _GRAPH_PATH)
        return _empty_graph()
    return data


# Loaded ONCE at import, exactly like AUTHORED_BAA_IDS.
CURRICULUM_GRAPH: dict = _load_graph()

# Derived index maps (built once from the loaded graph).
_NODE_BY_ID: dict[str, dict] = {
    str(n.get("exerciseId")): n for n in CURRICULUM_GRAPH.get("nodes", []) if n.get("exerciseId")
}
_COMPETENCY_PREREQS: dict[str, list[str]] = {
    str(c.get("id")): list(c.get("prerequisites", []))
    for c in CURRICULUM_GRAPH.get("competencies", [])
    if c.get("id")
}
# The إملاء difficulty ladder, in unlock order (copy < look-then-write < dictation).
_TIER_LADDER: list[str] = list(CURRICULUM_GRAPH.get("tiers", []))


def tier_of(exercise_id: str | None) -> str | None:
    """The إملاء difficulty tier of a graph node, or None.

    None for a non-writing exercise (recognize/positionalForms/reading/morphology — `tier:null`)
    OR for any id absent from the graph (a section/family token, or a fail-closed empty graph). A
    None tier makes G5 a no-op for that id (there is no tier to gate).
    """
    node = _NODE_BY_ID.get(exercise_id or "")
    return node.get("tier") if node else None


def reachable_tiers(cleared_tiers: list[str] | None) -> frozenset[str]:
    """The set of إملاء tiers the child may enter, given the tiers already cleared.

    Strict progressive unlock along the ladder: the FIRST tier (`manqul`) is always reachable;
    each subsequent tier unlocks only once its predecessor has been cleared. So with nothing
    cleared, only `manqul` is reachable (`ghayrManzur` is NOT). The check is order-based, not
    membership-based, so a child who has reached the top can still enter any lower tier
    (backward remediation — Pitfall 3).
    """
    cleared = set(cleared_tiers or [])
    reachable: set[str] = set()
    for index, tier in enumerate(_TIER_LADDER):
        if index == 0:
            reachable.add(tier)  # the floor tier is always reachable
            continue
        predecessor = _TIER_LADDER[index - 1]
        if predecessor in cleared:
            reachable.add(tier)
        else:
            break  # the ladder is strict — stop at the first locked rung
    return frozenset(reachable)


def prerequisites_met(exercise_id: str | None, cleared_competencies: list[str] | None) -> bool:
    """True iff every prerequisite competency of the node's competency is cleared (G6 forward-only).

    An id absent from the graph (section/family token, or a fail-closed empty graph) has no graph
    competency: `prerequisites_met` returns False (G6 rejects → AuthoredFallback). A node whose
    competency has NO prerequisites (e.g. `recognize`) is trivially met. Backward remediation
    passes because the prereqs of an already-reached competency are, by definition, already cleared.
    """
    node = _NODE_BY_ID.get(exercise_id or "")
    if node is None:
        return False
    competency = node.get("competency")
    if not competency:
        return False
    cleared = set(cleared_competencies or [])
    prereqs = _COMPETENCY_PREREQS.get(competency, [])
    return all(p in cleared for p in prereqs)
