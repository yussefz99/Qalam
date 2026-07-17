"""ACTION-tool schema contract (Plan 18-14 Task 1) — the FIRST link of the per-attempt WHY chain.

The recurring "static feedback" the owner sees on a clean pass traces to a tool-schema gap:
`COACH_NEXT_EXERCISE_ADDENDUM` (prompts.py) already ASKS the coach to attach `next_exercise_id` +
a `rationale` argument, the coach node already rails those args (coach.py), main.py already renames
`next_exercise_id`→`nextExerciseId`, and the Dart client already parses them into a `TutorPlan` —
but the four bound ACTION tools do NOT DECLARE those parameters. A real Gemini/Vertex
function-calling model can only return arguments the tool's schema declares, so it structurally
CANNOT attach the undeclared keys. This test pins the schema fix: each ACTION tool must DECLARE
`next_exercise_id` + `rationale` as OPTIONAL parameters, without changing the closed action space.

Deterministic, model-free — `-m code` (the PR gate).
"""

from __future__ import annotations

import pytest

from app.tools import ACTION_TOOL_NAMES, ACTION_TOOLS, advance, give_hint, present_activity, say

pytestmark = pytest.mark.code

# The two per-attempt-WHY parameters every ACTION tool must declare so a real function-calling
# model can attach them (the addendum asks for exactly these two arg names).
_WHY_PARAMS = ("next_exercise_id", "rationale")


@pytest.mark.parametrize("action_tool", ACTION_TOOLS, ids=lambda t: t.name)
@pytest.mark.parametrize("param", _WHY_PARAMS)
def test_action_tool_declares_why_param(action_tool, param):
    """Each ACTION tool's args schema DECLARES next_exercise_id + rationale (the schema-backed fix)."""
    assert param in action_tool.args, (
        f"{action_tool.name} must declare {param!r} so a real function-calling model can attach it; "
        f"declared params: {sorted(action_tool.args)}"
    )


@pytest.mark.parametrize("action_tool", ACTION_TOOLS, ids=lambda t: t.name)
@pytest.mark.parametrize("param", _WHY_PARAMS)
def test_why_param_is_optional(action_tool, param):
    """next_exercise_id + rationale must be OPTIONAL — a call omitting them still validates.

    A clean say/present_activity with no pick must remain legal, and the coach's word-less-action
    coercion (coach.py) must not break because a required WHY param went unset.
    """
    field = action_tool.args_schema.model_fields[param]
    assert not field.is_required(), (
        f"{action_tool.name}.{param} must be OPTIONAL (defaulted); a call omitting it must validate."
    )


def test_present_activity_still_validates_without_why_params():
    """The common clean path (present_activity with only its own args) still validates."""
    # Omitting next_exercise_id + rationale must NOT raise — they are optional.
    result = present_activity.invoke({"letter_id": "baa", "coaching_line": "Let's trace the boat."})
    assert result["letter_id"] == "baa"


def test_say_still_validates_without_why_params():
    """A bare `say` (the always-speak floor) still validates with no WHY params."""
    result = say.invoke({"text": "Beautiful — a deep, smooth bowl."})
    assert result["text"]


def test_giveHint_and_advance_validate_with_no_args():
    """give_hint / advance stay callable with zero required args (the WHY params are optional)."""
    assert give_hint.invoke({}) == {}
    assert advance.invoke({}) == {}


def test_action_space_is_still_exactly_the_four_names():
    """Declaring params must NOT change the action-space lock (tool_choice='any' over the same 4)."""
    assert ACTION_TOOL_NAMES == frozenset({"present_activity", "say", "give_hint", "advance"})
    assert [t.name for t in ACTION_TOOLS] == ["present_activity", "say", "give_hint", "advance"]
