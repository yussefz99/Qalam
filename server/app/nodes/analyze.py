"""The `analyze` node + the `Insight` schema (Plan 14-02 — AI-SPEC §4b.1, D8).

`analyze` reads the frozen FACTS (verdict + trajectory + session tags) and extracts a structured
`Insight`: the emerging struggle/strength tags and a one-line analyst note. It is deterministic
(temp 0) so the same trajectory yields the same tags, and it routes the graph — `needs_plan`
reads `Insight.struggle_tags` to decide whether the plan hop is needed.

The model is built via `app.models.build_analyze_model()` (per-node routing) and bound with
`with_structured_output(Insight)`. The call is wrapped in the bounded retry (2 retries then a
typed `StructuredOutputError`) so a malformed reply fails closed to AuthoredFallback (G5 / D9).

FACTS go in the HumanMessage as TEXT (never a tool result, never concatenated into the cached
system prompt) — the trust-boundary + caching discipline (AI-SPEC §4b.3).
"""

from __future__ import annotations

from langchain_core.messages import HumanMessage, SystemMessage
from pydantic import BaseModel, Field

from app.models import ANALYZE_MODEL, build_analyze_model
from app.nodes._retry import with_structured_retry
from app.prompts import ANALYZE_PROMPT
from app.state import TutorState


class Insight(BaseModel):
    """The analyze node's structured session insight (AI-SPEC §4b.1)."""

    struggle_tags: list[str] = Field(
        default_factory=list,
        description="Emerging struggles from the trajectory, e.g. ['boat-curvature', 'dot-placement']. Empty on a clean pass.",
    )
    strength_tags: list[str] = Field(
        default_factory=list,
        description="What the child is doing consistently well, e.g. ['steady-hand'].",
    )
    pattern_note: str = Field(
        default="",
        description="One-line analyst note, e.g. 'over-curved the boat on 3 of the last 4 tries'.",
    )


def _structured_analyze(facts: dict) -> Insight:
    """One structured analyze invocation — bind the model and parse an Insight."""
    # json_mode = Gemini native controlled generation (responseSchema). The default
    # (function_calling) extraction came back empty on gemini-2.5-flash; json_mode lands
    # reliably. Harmless on other providers that support json_mode.
    model = build_analyze_model().with_structured_output(Insight, method="json_mode")
    return model.invoke(
        [
            SystemMessage(content=ANALYZE_PROMPT),
            HumanMessage(content=str(facts)),  # FACTS as TEXT
        ]
    )


def analyze(state: TutorState) -> dict:
    """Extract the validated `Insight` from the FACTS; retry-bounded, fail-closed."""
    facts = state["facts"]
    insight = with_structured_retry(
        node="analyze",
        model_id=ANALYZE_MODEL,
        invoke=lambda: _structured_analyze(facts),
    )
    return {"insight": insight.model_dump(), "log": ["analyze"]}
