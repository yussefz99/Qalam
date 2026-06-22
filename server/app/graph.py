"""The full analyze -> {plan | coach} -> coach grounding graph (Plan 14-02).

This DEEPENS the Plan-01 single-node stub into the real DAG (AI-SPEC §3 Entry Point Pattern):

    START -> analyze -> needs_plan? --(struggle)--> plan -> coach -> END
                                    \\--(clean pass)--------------> coach -> END

  * `analyze` extracts a structured Insight (struggle/strength tags).
  * `needs_plan` is the conditional edge / cost lever: a clean pass with NO struggle is ONE cheap
    hop straight to `coach`; a struggle takes the three-hop analyze -> plan -> coach.
  * `plan` chooses the next authored baa step (curriculum + verdict guards inside the node).
  * `coach` forces exactly one of the 4 ACTION tools (tool_choice="any") and applies the online
    G3 / G4 guards.

Per-node model routing lives in `app.models`; each node builds its own best-fit model. The graph
compiles with `InMemorySaver()` so the server stays stateless (ADR-015 §5 / AI-SPEC pitfall 4) —
nothing child-derived persists across requests.
"""

from __future__ import annotations

from typing import Literal

from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import END, START, StateGraph

from app.nodes.analyze import analyze
from app.nodes.coach import coach
from app.nodes.plan import plan
from app.state import TutorState


def needs_plan(state: TutorState) -> Literal["plan", "coach"]:
    """Conditional edge: skip `plan` on a clean pass with no struggle (one cheap hop).

    A struggle (any struggle_tags) OR a fail verdict routes through `plan`; only a passed attempt
    with an empty struggle set shortcuts straight to `coach`.
    """
    facts = state.get("facts", {})
    insight = state.get("insight", {})
    if facts.get("passed", False) and not insight.get("struggle_tags"):
        return "coach"
    return "plan"


def build_graph():
    """Compile the full analyze -> {plan|coach} -> coach DAG. Stateless (InMemorySaver)."""
    builder = StateGraph(TutorState)
    builder.add_node("analyze", analyze)
    builder.add_node("plan", plan)
    builder.add_node("coach", coach)

    builder.add_edge(START, "analyze")
    builder.add_conditional_edges("analyze", needs_plan)  # analyze -> plan | coach
    builder.add_edge("plan", "coach")
    builder.add_edge("coach", END)

    return builder.compile(checkpointer=InMemorySaver())
