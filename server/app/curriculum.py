"""The authored-curriculum membership guard (Plan 14-02 — G4 / TUTOR-05).

`AUTHORED_BAA_IDS` is the closed set of signed-off baa ids the agent may reference. Pydantic
validates the *shape* of `Plan.next_exercise_id` / `present_activity.letter_id`; THIS module
validates *curriculum membership* — an id the model fabricates that isn't in the owner-signed
set is a grounding failure (T-14-08) and the run fails closed to AuthoredFallback.

Source of truth: the set is loaded from `app/curriculum_data/baa_authored_ids.json`, a verbatim
transcription of the canonical Flutter bundled seed (`assets/curriculum/units.json` +
`assets/curriculum/exercises.json`) — the same seed `CurriculumRepository` reads. It is NOT a
planner guess. `app/curriculum_data/generate.py` regenerates the JSON from the canonical assets
so the bundled copy can never drift. The exact id set is recorded in the 14-02 SUMMARY for owner
sign-off.

The guard accepts BOTH the 19 `baa.*` exercise ids AND the 6 baa section ids
(`meet`, `watchTrace`, `forms`, `words`, `listenWrite`, `mastery`) — `present_activity` may
reference either a concrete exercise (`baa.traceLetter.isolated`) or a section the child moves to.
A `letterId` family token (`baa`) is also accepted so the agent can name the letter family.
"""

from __future__ import annotations

import json
import pathlib

_SEED_PATH = pathlib.Path(__file__).resolve().parent / "curriculum_data" / "baa_authored_ids.json"


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
