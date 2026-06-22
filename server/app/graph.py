"""The minimal one-node grounding graph (Plan 01 Task 2).

A SINGLE `coach` node: START -> coach -> END. The coach binds its model with
`bind_tools(ACTION_TOOLS, tool_choice="any")` — the action-space lock (GROUND-01 / G2) — and
forces exactly one ACTION. The FACTS are injected as TEXT in a HumanMessage (never as a tool
result, never combined with a responseSchema — ADR-014 §2 / AI-SPEC).

This is the THIN end-to-end slice. The minimal node may ignore the enlarged
`trajectory`/`strengthTags` fields — Plan 02's analyze node consumes them. This plan proves
the secure seam + the locked DTO + one grounded action.

Server-side grounding guard (G3): if the forced tool is `advance` while `facts.passed` is
False, the run rewrites it to a grounded `say` and marks `grounded=False`. The scorer's
verdict is the frozen FACT; no agent path may flip a fail to a pass.

The model is built lazily and env-driven (COACH_MODEL / COACH_MODEL_PROVIDER) so importing
this module never requires a provider key — tests monkeypatch `build_coach_model`.
`InMemorySaver` keeps the server stateless (AI-SPEC pitfall 4): nothing child-derived persists.
"""

from __future__ import annotations

import os

from langchain_core.messages import HumanMessage, SystemMessage
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import END, START, StateGraph

from app.prompts import COACH_PROMPT
from app.state import TutorState
from app.tools import ACTION_TOOLS

# A grounded fallback line used when an advance-on-fail is rewritten (G3). Short, warm, specific.
_GROUNDED_RETRY_LINE = "Almost — let's try this one more time, slower. You're getting closer."


def build_coach_model():
    """Build the coach model, bound + tool-forced. Env-driven; eval-tunable (AI-SPEC §4).

    Imported lazily inside so module import never needs a provider key. Tests monkeypatch
    this function to return a fake bound model that yields a forced tool call offline.
    """
    from langchain.chat_models import init_chat_model

    model_id = os.environ.get("COACH_MODEL", "claude-haiku-4-5")
    provider = os.environ.get("COACH_MODEL_PROVIDER", "anthropic")
    model = init_chat_model(
        model_id,
        model_provider=provider,
        temperature=0.5,
        max_tokens=256,  # coaching lines are short; never unbounded (4b.3 / G6)
    )
    # tool_choice="any" forces exactly one ACTION from the closed set (GROUND-01 / G2).
    return model.bind_tools(ACTION_TOOLS, tool_choice="any")


def _coach_node(state: TutorState) -> dict:
    facts = state["facts"]
    coach_with_tools = build_coach_model()
    resp = coach_with_tools.invoke(
        [
            SystemMessage(content=COACH_PROMPT),
            HumanMessage(content=str(facts)),  # FACTS as TEXT, never a tool result
        ]
    )

    tool_calls = getattr(resp, "tool_calls", None) or []
    if not tool_calls:
        # tool_choice="any" should make this impossible; degrade to a grounded say defensively.
        decision = {"name": "say", "args": {"text": _GROUNDED_RETRY_LINE}}
        return {"decision": decision, "grounded": True, "log": ["coach"]}

    call = tool_calls[0]
    name = call["name"]
    args = call.get("args", {}) or {}
    grounded = True

    # G3 — grounding-faithfulness verdict lock: never advance on a fail.
    if name == "advance" and not facts.get("passed", False):
        name = "say"
        args = {"text": _GROUNDED_RETRY_LINE}
        grounded = False

    return {"decision": {"name": name, "args": args}, "grounded": grounded, "log": ["coach"]}


def build_graph():
    """Compile the minimal one-node graph. Stateless (InMemorySaver)."""
    builder = StateGraph(TutorState)
    builder.add_node("coach", _coach_node)
    builder.add_edge(START, "coach")
    builder.add_edge("coach", END)
    return builder.compile(checkpointer=InMemorySaver())
