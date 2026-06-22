"""The `plan` node + the `Plan` schema + the post-parse grounding guards (Plan 14-02).

`plan` runs only when `analyze` found a struggle (the conditional edge skips it on a clean pass).
It chooses the next authored baa step that responds to the Insight: a structured `Plan` with
`next_exercise_id` (an AUTHORED id), an `intent`, and a rationale.

Two grounding guards run AFTER the Pydantic parse (Pydantic validates shape, not curriculum /
verdict semantics):

  * G4 — curriculum membership: `Plan.next_exercise_id` MUST be in `AUTHORED_BAA_IDS` (the
    owner-signed seed). A fabricated id (T-14-08) raises `StructuredOutputError` → AuthoredFallback.
  * G3 — verdict lock: `intent == "advance"` is only legal when `facts.passed` is True. On a fail
    (T-14-07) the intent is DOWNGRADED to `retest_whole` — the agent cannot plan an advance off a
    failed verdict. The frozen verdict wins.

The model is built via `app.models.build_plan_model()` and wrapped in the same bounded retry.
"""

from __future__ import annotations

import logging
from typing import Literal

from langchain_core.messages import HumanMessage, SystemMessage
from pydantic import BaseModel, Field

from app.curriculum import is_authored
from app.models import PLAN_MODEL, build_plan_model
from app.nodes._retry import StructuredOutputError, with_structured_retry
from app.prompts import PLAN_PROMPT
from app.state import TutorState

logger = logging.getLogger("qalam.tutor.nodes")

PlanIntent = Literal["drill_isolated", "retest_whole", "hint", "advance"]


class Plan(BaseModel):
    """The plan node's structured next-step (AI-SPEC §4b.1). Chosen from AUTHORED baa configs only."""

    next_exercise_id: str = Field(
        description="An authored, signed-off baa exercise id (e.g. 'baa.traceLetter.isolated') — never invented.",
    )
    intent: PlanIntent = Field(
        description="What this step accomplishes. 'advance' is legal only on a PASS verdict.",
    )
    rationale: str = Field(
        default="",
        description="Why this step, grounded in the Insight (for the coach + logs).",
    )


def _structured_plan(facts: dict, insight: dict) -> Plan:
    """One structured plan invocation — bind the model and parse a Plan."""
    model = build_plan_model().with_structured_output(Plan)
    return model.invoke(
        [
            SystemMessage(content=PLAN_PROMPT),  # cache-stable curriculum prefix
            HumanMessage(content=str({"facts": facts, "insight": insight})),  # FACTS as TEXT
        ]
    )


def plan(state: TutorState) -> dict:
    """Produce a validated, grounded `Plan`; enforce the curriculum + verdict guards."""
    facts = state["facts"]
    insight = state.get("insight", {})

    plan_out = with_structured_retry(
        node="plan",
        model_id=PLAN_MODEL,
        invoke=lambda: _structured_plan(facts, insight),
    )

    # G4 — curriculum membership guard (after parse). An unauthored id fails closed.
    if not is_authored(plan_out.next_exercise_id):
        logger.warning(
            "G4 curriculum guard: plan emitted unauthored next_exercise_id=%r; failing closed.",
            plan_out.next_exercise_id,
        )
        raise StructuredOutputError(
            f"plan next_exercise_id {plan_out.next_exercise_id!r} is not an authored baa exercise"
        )

    grounded = True
    intent = plan_out.intent

    # G3 — verdict lock: cannot advance on a fail. Downgrade to a re-test of the whole letter.
    if intent == "advance" and not facts.get("passed", False):
        logger.warning("G3 verdict lock: plan intent 'advance' on a fail downgraded to 'retest_whole'.")
        intent = "retest_whole"
        grounded = False

    plan_dict = plan_out.model_dump()
    plan_dict["intent"] = intent
    plan_dict["grounded"] = grounded
    return {"plan": plan_dict, "log": ["plan"]}
