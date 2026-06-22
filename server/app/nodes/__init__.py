"""The analyze -> plan -> coach node set (Plan 14-02).

Each node is a plain `def node(state) -> dict` that binds its OWN model (via app.models) and
returns a partial-state delta LangGraph merges. `analyze`/`plan` use `with_structured_output`
(validated Pydantic) wrapped in a bounded retry; `coach` uses forced tool-calling
(`tool_choice="any"`) over the closed 4 ACTION tools.

`StructuredOutputError` is the typed fail-closed signal: when a structured node exhausts its
retries, it raises this, which the FastAPI handler maps to the degrade response the client turns
into an AuthoredFallback line (G5 / D9 — never block the child).
"""

from app.nodes._retry import StructuredOutputError, with_structured_retry

__all__ = ["StructuredOutputError", "with_structured_retry"]
