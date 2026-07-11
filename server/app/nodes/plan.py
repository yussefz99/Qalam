"""The `plan` node + the `Plan` schema + the post-parse grounding guards (Plan 14-02).

`plan` runs only when `analyze` found a struggle (the conditional edge skips it on a clean pass).
It chooses the next authored baa step that responds to the Insight: a structured `Plan` with
`next_exercise_id` (an AUTHORED id), an `intent`, and a rationale.

Four grounding guards run AFTER the Pydantic parse (Pydantic validates shape, not curriculum /
verdict / graph semantics):

  * G4 — curriculum membership: `Plan.next_exercise_id` MUST be in `AUTHORED_BAA_IDS` (the
    owner-signed seed). A fabricated id (T-14-08) raises `StructuredOutputError` → AuthoredFallback.
  * G5 — tier-reachability (Plan 15-02): a chosen exercise whose إملاء `tier` is NOT in
    `reachable_tiers(facts["clearedTiers"])` raises `StructuredOutputError` → AuthoredFallback.
  * G6 — prerequisite chain, forward-only (Plan 15-02): a chosen exercise whose competency
    prerequisites are not all cleared raises `StructuredOutputError` → AuthoredFallback.
  * G3 — verdict lock: `intent == "advance"` is only legal when `facts.passed` is True. On a fail
    (T-14-07) the intent is DOWNGRADED to `retest_whole` — the agent cannot plan an advance off a
    failed verdict. The frozen verdict wins.

CRITICAL (Pitfall 3): G5/G6 restrict SELECTION only and check only *reachability* + *prereqs-met*,
so a LOWER tier of an already-reached competency passes BOTH — backward remediation (ghayrManzur
fail → manzur) is graph-LEGAL and must NOT be rejected. Forward-only means "no skipping ahead,"
not "no stepping back."

The graph rail (G5/G6) activates only when the child has a KNOWN graph position — at least one of
`facts["clearedTiers"]` / `facts["clearedCompetencies"]` is non-empty. A fresh request with both
empty (a child at the graph root, OR the pre-15-04 wire where the Dart side does not yet send
cleared-state — Pitfall 1, the extra="forbid" lockstep) is pre-graph: the rail is a no-op so a
fresh child is never dead-ended at the AuthoredFallback floor. G4 + G3 still hold unconditionally.

The model is built via `app.models.build_plan_model()` and wrapped in the same bounded retry.
"""

from __future__ import annotations

import logging
from typing import Literal

from langchain_core.messages import HumanMessage, SystemMessage
from pydantic import BaseModel, Field

from app.curriculum import is_authored, prerequisites_met, reachable_tiers, tier_of
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
        description="Why this step — the struggle-branch WHY (D-10), grounded in the child's weakest "
        "criterion (facts.weakestCriterion) + the Insight; it feeds the coach prompt and the logs. "
        "Names the targeted criterion in plain words; carries NO verdict / mastery / star claim (ADR-014).",
    )


def _structured_plan(facts: dict, insight: dict) -> Plan:
    """One structured plan invocation — bind the model and parse a Plan."""
    # json_mode = Gemini native controlled generation (responseSchema); reliable where the
    # default function_calling extraction returned empty on gemini-2.5-flash.
    model = build_plan_model().with_structured_output(Plan, method="json_mode")
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

    # The graph rail (G5/G6) reads the child's cleared-state from the FACTS (the resume-replay
    # fields, D-08). It activates ONLY when the child has a KNOWN graph position — i.e. at least
    # one of clearedTiers / clearedCompetencies is non-empty. A completely-fresh request (both
    # empty: a child at the graph root, OR the pre-15-04 wire where the Dart side does not yet
    # compute cleared-state — Pitfall 1, the extra="forbid" lockstep) is pre-graph: the rail has
    # no position to reason over and stays a no-op, so G4 membership + G3 verdict-lock still hold
    # but a fresh child is never dead-ended at the floor. Once cleared-state crosses the wire
    # (15-04 + a re-deploy), the rail gates every selection against the real position.
    cleared_tiers = facts.get("clearedTiers", [])
    cleared_competencies = facts.get("clearedCompetencies", [])
    has_graph_position = bool(cleared_tiers) or bool(cleared_competencies)

    if has_graph_position:
        # G5 — tier-reachability guard (Plan 15-02). The chosen exercise's إملاء tier must be
        # unlocked for the child. A LOWER tier of an already-reached competency IS reachable, so
        # backward remediation passes (Pitfall 3); only a forward jump to a locked tier fails closed.
        chosen_tier = tier_of(plan_out.next_exercise_id)
        if chosen_tier is not None and chosen_tier not in reachable_tiers(cleared_tiers):
            logger.warning(
                "G5 tier guard: plan chose next_exercise_id=%r in unreached tier %r; failing closed.",
                plan_out.next_exercise_id,
                chosen_tier,
            )
            raise StructuredOutputError(
                f"plan next_exercise_id {plan_out.next_exercise_id!r} is in an unreached tier {chosen_tier!r}"
            )

        # G6 — prerequisite-chain guard (Plan 15-02, forward-only). The chosen exercise's
        # competency prerequisites must all be cleared. Backward remediation passes because an
        # already-reached competency's prereqs are, by definition, already cleared.
        if not prerequisites_met(plan_out.next_exercise_id, cleared_competencies):
            logger.warning(
                "G6 prereq guard: plan chose next_exercise_id=%r with uncleared prerequisites; failing closed.",
                plan_out.next_exercise_id,
            )
            raise StructuredOutputError(
                f"plan next_exercise_id {plan_out.next_exercise_id!r} has uncleared prerequisites"
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
