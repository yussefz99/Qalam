"""The `coach` node — the voice, the action-space lock, the online grounding guards (Plan 14-02).

`coach` is the only node that ACTS. It binds the closed 4 ACTION tools with
`bind_tools(ACTION_TOOLS, tool_choice="any")` (AI-SPEC §4 — G2 / GROUND-01 / TUTOR-05): the model
MUST emit exactly one of {present_activity, say, give_hint, advance}; it cannot emit a 5th action
or a free-text-only reply. There is no verdict/star tool — the scorer owns the verdict.

It injects {facts, insight, plan} as TEXT (HumanMessage) with the mother's-voice COACH_PROMPT
(warm/calm/specific + the gold few-shot exemplars + the grounding rule). Then two ONLINE guards
run on the forced call (defence-in-depth — the prompt also forbids these, but the guard makes it
structural):

  * G3 — verdict lock: a forced `advance` while `facts.passed` is False is rewritten to a grounded
    `say` and flagged `grounded=False`. The agent can never flip a fail to a pass (T-14-07).
  * G4 — curriculum membership: a `present_activity` whose `letter_id` is not in AUTHORED_BAA_IDS
    is rejected to a grounded `say` and flagged (T-14-08). The agent cannot fabricate an exercise.

`state["decision"]` carries the single chosen tool call (name + args); the FastAPI handler
serializes it to CoachOut and the Flutter dispatcher maps the name to a controller call.
"""

from __future__ import annotations

import logging

from langchain_core.messages import HumanMessage, SystemMessage

from app.curriculum import is_authored
from app.models import build_coach_model
from app.prompts import COACH_NEXT_EXERCISE_ADDENDUM, COACH_PROMPT, COACH_STROKE_ADDENDUM
from app.state import TutorState
from app.tools import ACTION_TOOL_NAMES, ACTION_TOOLS

logger = logging.getLogger("qalam.tutor.nodes")

# A grounded fallback line when a guard rewrites the forced action. Short, warm, specific.
_GROUNDED_RETRY_LINE = "Almost — let's try this one more time, slower. You're getting closer."
_PASS_FALLBACK_LINE = "أحسنت! That was a good one — ready for the next step?"


def build_coach_with_tools():
    """Build the coach model and force the closed 4-tool ACTION space (G2 lock).

    Lazy: importing this module never needs a provider key. Tests monkeypatch this to return a
    fake bound model that yields a forced tool call offline.
    """
    return build_coach_model().bind_tools(ACTION_TOOLS, tool_choice="any")


def coach(state: TutorState) -> dict:
    """Force one grounded ACTION; apply the online G3 / G4 guards."""
    facts = state["facts"]
    insight = state.get("insight", {})
    plan = state.get("plan")

    # Phase 17 (STRK-01, 17-05): when the FACTS carry ANY derived evidence of THIS attempt — a
    # strokeDiff, the structured per-criterion `criteria`, or the F6 `writtenWord` — append the
    # stroke addendum so the coach names the specific failed criterion / geometry / word difference
    # (and stops parroting the exemplars) in the English-primary register. No derived evidence ->
    # byte-identical to the prior behavior (the existing flow is unchanged). The G2/G3/G4 guards
    # below are the structural grounding backstop and are UNAFFECTED by this trigger.
    has_derived_facts = facts.get("strokeDiff") or facts.get("criteria") or facts.get("writtenWord")
    # Phase 17.2 (demo): the client sent the graph-legal next-exercise candidates → let the coach ALSO
    # propose the next exercise FROM that list (Option B: announce it in the line). Purely additive — no
    # candidates → the addendum is not appended and the prior behavior is byte-identical. The rail below
    # strips any proposed id that is not in this list, so an illegal/hallucinated id is never forwarded.
    # Phase 18 (18-08, D-10): the addendum also GROUNDS the pick's WHY in the policy facts already on the
    # wire — `weakestCriterion` (the targeted criterion the WHY names) and the micro-drill-ness of the pick
    # (a `microDrill` id → a warm NAMED step-down). This lives on the COACH path because the plan node is
    # SKIPPED on a clean pass (graph.py `needs_plan`) — the pass→move-forward WHY would never fire otherwise.
    legal_next = facts.get("legalNextExerciseIds") or []
    system_prompt = (
        COACH_PROMPT
        + (COACH_STROKE_ADDENDUM if has_derived_facts else "")
        + (COACH_NEXT_EXERCISE_ADDENDUM if legal_next else "")
    )

    coach_with_tools = build_coach_with_tools()
    resp = coach_with_tools.invoke(
        [
            SystemMessage(content=system_prompt),  # mother's-voice + grounding rule (cache-stable)
            HumanMessage(content=str({"facts": facts, "insight": insight, "plan": plan})),
        ]
    )

    tool_calls = getattr(resp, "tool_calls", None) or []
    if not tool_calls:
        # tool_choice="any" should make this impossible; degrade to a grounded say defensively (G2).
        logger.warning("coach emitted no tool call despite tool_choice='any'; degrading to say.")
        return {
            "decision": {"name": "say", "args": {"text": _GROUNDED_RETRY_LINE}},
            "grounded": False,
            "log": ["coach"],
        }

    call = tool_calls[0]
    name = call.get("name", "say")
    args = dict(call.get("args", {}) or {})
    grounded = True

    # Defence-in-depth: an out-of-set name (shouldn't happen under tool_choice='any') -> say (G2).
    if name not in ACTION_TOOL_NAMES:
        logger.warning("coach emitted out-of-set tool name %r; rejecting to say (G2).", name)
        name, args, grounded = "say", {"text": _GROUNDED_RETRY_LINE}, False

    # G3 — verdict lock: never advance on a fail.
    elif name == "advance" and not facts.get("passed", False):
        logger.warning("G3 verdict lock: coach forced 'advance' on a fail; rewriting to grounded say.")
        name, args, grounded = "say", {"text": _GROUNDED_RETRY_LINE}, False

    # G4 — curriculum membership: a present_activity must reference an authored baa id.
    elif name == "present_activity" and not is_authored(args.get("letter_id")):
        logger.warning(
            "G4 curriculum guard: coach present_activity letter_id=%r is not authored; rewriting to say.",
            args.get("letter_id"),
        )
        name, args, grounded = "say", {"text": _GROUNDED_RETRY_LINE}, False

    # 17.2 always-speak rail: the client renders ONLY the agent's words on the agent path (owner
    # directive 2026-07-07 — the authored floor is retired there), so a word-less action
    # (give_hint/advance, or say with an empty text) renders as SILENCE on-device and reads as a
    # hang. Coerce those to a spoken `say`, verdict-aware, PRESERVING args so a legal
    # nextExerciseId/rationale survives the rewrite. Runs after G2–G4 (which already produce
    # spoken says) and before the next-exercise rail (which validates the surviving args).
    if name in ("give_hint", "advance") or (name == "say" and not str(args.get("text") or "").strip()):
        _text = str(args.get("text") or "").strip()
        if not _text:
            _text = _PASS_FALLBACK_LINE if facts.get("passed", False) else _GROUNDED_RETRY_LINE
        logger.info("17.2 always-speak rail: coerced word-less %r to spoken say.", name)
        name = "say"
        args = {**args, "text": _text}

    # Phase 17.2 next-exercise RAIL (18-08: CASING-SAFE): the coach MAY add the pick under EITHER the
    # camelCase wire key (`nextExerciseId`) OR the tool's own snake_case arg name (`next_exercise_id`) —
    # accept it ONLY when it is in the client-provided candidate list; otherwise STRIP it so an ILLEGAL /
    # hallucinated / off-graph id is NEVER forwarded to the client. BOTH keys MUST be checked here: main.py
    # renames snake→camel AFTER this node runs, so a snake_case emission that skipped validation would be
    # renamed to `nextExerciseId` and forwarded — the exact casing bypass 18-08 closes. The id is the only
    # thing the client acts on (it re-checks legality too, D-04 defence-in-depth); the spoken line is
    # advisory, so it is left as-is. A guard rewrite to `say` above carries no id, so this is a no-op there.
    # Empty candidate list → any proposed id is stripped (fail closed). Logged at info for the demo trace.
    for _id_key in ("nextExerciseId", "next_exercise_id"):
        proposed_next = args.get(_id_key)
        if proposed_next is not None and proposed_next not in legal_next:
            logger.info(
                "17.2 next-exercise rail: stripped proposed %s=%r (not in candidates %r).",
                _id_key,
                proposed_next,
                legal_next,
            )
            args.pop(_id_key, None)
    # Drop the now-orphaned `rationale` only when NO legal next-exercise id (under either casing) survives.
    if not any(args.get(k) is not None for k in ("nextExerciseId", "next_exercise_id")):
        args.pop("rationale", None)

    return {"decision": {"name": name, "args": args}, "grounded": grounded, "log": ["coach"]}
