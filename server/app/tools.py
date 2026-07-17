"""The closed 4-tool ACTION space (Plan 01 Task 2).

Mirrors `lib/tutor/tutor_decision.dart` `TutorTool` — the same four names, the single source
of truth shared with the Flutter dispatcher. These tools are BOUND to the coach model and
FORCED (`tool_choice="any"`), but the server NEVER executes them: there is no tool-return loop.
The coach node forces exactly one call; the FastAPI handler serializes the chosen tool name +
args into `CoachOut`, and the Flutter dispatcher maps the name to an imperative controller call.

`tool_choice="any"` over exactly this set is the structural action-space lock (GROUND-01 / G2):
the model cannot emit a 5th action or a free-text-only reply.
"""

from __future__ import annotations

from langchain_core.tools import tool

# --- The per-attempt WHY parameters (18-14) ---
#
# Every ACTION tool ALSO declares two OPTIONAL parameters — `next_exercise_id` and `rationale` — so
# a real Gemini/Vertex function-calling model can attach the coach's per-attempt next-step + WHY. A
# function-calling API constrains returned tool-call arguments to the tool's DECLARED schema, so an
# UNdeclared key is silently dropped — the exact gap that left `rationale` null on the common
# clean-pass path and forced the client to a static fallback line (see
# .planning/debug/coach-feedback-feels-static.md). COACH_NEXT_EXERCISE_ADDENDUM (prompts.py) asks
# for exactly these two arg names; the coach node rails `next_exercise_id` against the client's
# legalNextExerciseIds (an off-graph id is stripped, T-18-14-01), main.py renames
# next_exercise_id→nextExerciseId, and the Dart TutorPlan parser reads both. This module only opens
# the FIRST link (the schema); the rest of the chain is already built.
#
# Both DEFAULT to "" (optional): a clean say/present_activity with no pick stays legal, and the
# coach's word-less-action coercion never breaks. The server NEVER executes tools — only the SCHEMA
# matters for the model's function-calling — so the bodies keep returning their existing dicts. The
# docstrings below become each tool's schema description; the per-arg guidance mirrors the addendum:
#   next_exercise_id — the single best next exercise chosen FROM legalNextExerciseIds, never invented.
#   rationale        — one short phrase naming the targeted criterion, NO verdict/mastery/star claim
#                      (the scorer owns pass/fail, ADR-014).


@tool
def present_activity(
    letter_id: str,
    coaching_line: str,
    next_exercise_id: str = "",
    rationale: str = "",
) -> dict:
    """Show the child the next authored exercise for letter_id, with a warm coaching line.

    letter_id: the authored baa letter id to present. coaching_line: the warm, specific spoken line.
    next_exercise_id (optional): the single best next exercise chosen FROM legalNextExerciseIds —
    never invented, never outside that list; omit when there is no pick.
    rationale (optional): one short phrase tying the pick to what you saw, naming the targeted
    criterion in plain words (the dot, the bowl's depth, a missing tooth). NO verdict/mastery/star
    claim (the scorer owns pass/fail — ADR-014); omit when there is no pick.
    """
    # Server does not execute — the Flutter dispatcher acts on the serialized call.
    return {"letter_id": letter_id, "coaching_line": coaching_line}


@tool
def say(text: str, next_exercise_id: str = "", rationale: str = "") -> dict:
    """Speak one short, warm, specific line to the child (mother's-voice register).

    text: the one or two short sentences the child hears.
    next_exercise_id (optional): the single best next exercise chosen FROM legalNextExerciseIds —
    never invented, never outside that list; omit when there is no pick.
    rationale (optional): one short phrase tying the pick to what you saw, naming the targeted
    criterion in plain words. NO verdict/mastery/star claim (the scorer owns pass/fail — ADR-014).
    """
    return {"text": text}


@tool
def give_hint(next_exercise_id: str = "", rationale: str = "") -> dict:
    """Offer the next authored hint for the current exercise.

    next_exercise_id (optional): the single best next exercise chosen FROM legalNextExerciseIds —
    never invented, never outside that list; omit when there is no pick.
    rationale (optional): one short phrase naming the targeted criterion, no verdict/mastery/star
    claim (the scorer owns pass/fail — ADR-014); omit when there is no pick.
    """
    return {}


@tool
def advance(next_exercise_id: str = "", rationale: str = "") -> dict:
    """Move the child forward — only valid when the scorer's verdict was a pass.

    next_exercise_id (optional): the single best next exercise chosen FROM legalNextExerciseIds —
    never invented, never outside that list; omit when there is no pick.
    rationale (optional): one short phrase naming the targeted criterion, no verdict/mastery/star
    claim (the scorer owns pass/fail — ADR-014); omit when there is no pick.
    """
    return {}


# The closed action space bound on the coach node. Order is stable for deterministic binding.
ACTION_TOOLS = [present_activity, say, give_hint, advance]

# The set of valid tool names, for the dispatcher-side guard (G2 reject-out-of-set).
ACTION_TOOL_NAMES: frozenset[str] = frozenset(t.name for t in ACTION_TOOLS)
