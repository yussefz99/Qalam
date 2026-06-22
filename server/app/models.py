"""Per-node model routing table (Plan 14-02 — ADR-015 §3 / AI-SPEC §4).

The whole reason LangGraph was chosen: each node binds its OWN best-fit model via
`init_chat_model(model, model_provider=...)`. This table is the single place that builds them,
env-driven so the Phase-16 eval bake-off can retune the routing WITHOUT a code change.

AI-SPEC §4 initial assignment (all eval-tunable):

  | node    | model (default)    | provider     | temperature | max_tokens |
  |---------|--------------------|--------------|-------------|------------|
  | analyze | gemini-2.5-flash   | google_genai | 0.0         | 512        |
  | plan    | claude-sonnet-4-6  | anthropic    | 0.2         | 512        |
  | coach   | claude-haiku-4-5   | anthropic    | 0.5         | 256        |

`max_tokens` is ALWAYS set (AI-SPEC §4b.3 — never unbounded: a rambling coach turn is both a
cost leak and a child-UX failure). Confirm the exact model strings at deploy (Gemini Flash /
Claude version ids shift release-to-release) — override via the env vars below.

Models are built LAZILY (inside each `build_*_model()`), so importing this module never needs a
provider key. Tests monkeypatch the node-level `build_*_model` to return a fake model offline.
"""

from __future__ import annotations

import os

# Per-node defaults (AI-SPEC §4). Overridable by env for the eval bake-off.
ANALYZE_MODEL = os.environ.get("ANALYZE_MODEL", "gemini-2.5-flash")
ANALYZE_MODEL_PROVIDER = os.environ.get("ANALYZE_MODEL_PROVIDER", "google_genai")
ANALYZE_TEMPERATURE = float(os.environ.get("ANALYZE_TEMPERATURE", "0"))
ANALYZE_MAX_TOKENS = int(os.environ.get("ANALYZE_MAX_TOKENS", "512"))

PLAN_MODEL = os.environ.get("PLAN_MODEL", "claude-sonnet-4-6")
PLAN_MODEL_PROVIDER = os.environ.get("PLAN_MODEL_PROVIDER", "anthropic")
PLAN_TEMPERATURE = float(os.environ.get("PLAN_TEMPERATURE", "0.2"))
PLAN_MAX_TOKENS = int(os.environ.get("PLAN_MAX_TOKENS", "512"))

COACH_MODEL = os.environ.get("COACH_MODEL", "claude-haiku-4-5")
COACH_MODEL_PROVIDER = os.environ.get("COACH_MODEL_PROVIDER", "anthropic")
COACH_TEMPERATURE = float(os.environ.get("COACH_TEMPERATURE", "0.5"))
COACH_MAX_TOKENS = int(os.environ.get("COACH_MAX_TOKENS", "256"))


def _provider_kwargs(provider: str) -> dict:
    """Provider-specific construction kwargs.

    On `google_vertexai` the Gemini 2.5 models default to *thinking* mode, which both slows the
    call (a child-facing latency cost) and was observed to break `with_structured_output` (the
    structured reply came back empty). `thinking_budget=0` disables it — fast, deterministic, and
    structured output lands. Verified live at the Phase-14 deploy. Other providers get nothing.
    """
    if provider == "google_vertexai":
        return {"thinking_budget": 0}
    return {}


def build_analyze_model():
    """Build the analyze model (structured-output, deterministic). Lazy import — no key at import."""
    from langchain.chat_models import init_chat_model

    return init_chat_model(
        ANALYZE_MODEL,
        model_provider=ANALYZE_MODEL_PROVIDER,
        temperature=ANALYZE_TEMPERATURE,
        max_tokens=ANALYZE_MAX_TOKENS,  # never unbounded (4b.3)
        **_provider_kwargs(ANALYZE_MODEL_PROVIDER),
    )


def build_plan_model():
    """Build the plan model (the hardest reasoning; runs less often). Lazy import."""
    from langchain.chat_models import init_chat_model

    return init_chat_model(
        PLAN_MODEL,
        model_provider=PLAN_MODEL_PROVIDER,
        temperature=PLAN_TEMPERATURE,
        max_tokens=PLAN_MAX_TOKENS,
        **_provider_kwargs(PLAN_MODEL_PROVIDER),
    )


def build_coach_model():
    """Build the coach model (the voice — short, warm, bounded). Lazy import.

    Returned UNbound; the coach node calls `.bind_tools(ACTION_TOOLS, tool_choice="any")` so the
    action-space lock lives next to the node that needs it.
    """
    from langchain.chat_models import init_chat_model

    return init_chat_model(
        COACH_MODEL,
        model_provider=COACH_MODEL_PROVIDER,
        temperature=COACH_TEMPERATURE,
        max_tokens=COACH_MAX_TOKENS,
        **_provider_kwargs(COACH_MODEL_PROVIDER),
    )
