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


@tool
def present_activity(letter_id: str, coaching_line: str) -> dict:
    """Show the child the next authored exercise for letter_id, with a warm coaching line."""
    # Server does not execute — the Flutter dispatcher acts on the serialized call.
    return {"letter_id": letter_id, "coaching_line": coaching_line}


@tool
def say(text: str) -> dict:
    """Speak one short, warm, specific line to the child (mother's-voice register)."""
    return {"text": text}


@tool
def give_hint() -> dict:
    """Offer the next authored hint for the current exercise."""
    return {}


@tool
def advance() -> dict:
    """Move the child forward — only valid when the scorer's verdict was a pass."""
    return {}


# The closed action space bound on the coach node. Order is stable for deterministic binding.
ACTION_TOOLS = [present_activity, say, give_hint, advance]

# The set of valid tool names, for the dispatcher-side guard (G2 reject-out-of-set).
ACTION_TOOL_NAMES: frozenset[str] = frozenset(t.name for t in ACTION_TOOLS)
