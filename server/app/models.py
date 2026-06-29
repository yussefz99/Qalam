"""Per-node model routing table (Plan 14-02 — ADR-015 §3 / AI-SPEC §4; Plan 16-01 — D-02/D-03).

The whole reason LangGraph was chosen: each node binds its OWN best-fit model via
`init_chat_model(model, model_provider=...)`. This table is the single place that builds them,
env-driven so the Phase-16 eval bake-off can retune the routing WITHOUT a code change.

LIVE BASELINE — keyless Gemini-on-Vertex for ALL three nodes (D-02, 16-RESEARCH live probe).
The deployed `qalam-tutor` service already routes analyze/plan/coach through `google_vertexai`
/ `gemini-2.5-flash`, keyless (runtime SA ADC — NO provider key, no ANTHROPIC_API_KEY anywhere).
This table now matches that deployed truth:

  | node    | model (default)    | provider        | location    | temperature | max_tokens |
  |---------|--------------------|-----------------|-------------|-------------|------------|
  | analyze | gemini-2.5-flash   | google_vertexai | us-central1 | 0.0         | 512        |
  | plan    | gemini-2.5-flash   | google_vertexai | us-central1 | 0.2         | 512        |
  | coach   | gemini-2.5-flash   | google_vertexai | us-central1 | 0.5         | 256        |

GATED UPGRADE — Claude-on-Vertex coach (D-03). Claude is a drop-in ENV SWAP, not a code change:
set COACH_MODEL_PROVIDER=anthropic_vertex, COACH_MODEL=claude-haiku-4-5@20251001, and
COACH_LOCATION=global. This is allowed ONLY AFTER a human Enables the Claude card in Vertex AI
Model Garden (the project is 404 "no access" until then — 16-RESEARCH D-03) AND the eval picks
Claude over Gemini on the Arabic-register dimension. Claude does NOT serve us-central1 (Gemini's
region) — it serves `global`/`us-east5`/`europe-west1`, so COACH_LOCATION is a separate env. Still
keyless (runtime SA ADC), still no provider key.

`max_tokens` is ALWAYS set (AI-SPEC §4b.3 — never unbounded: a rambling coach turn is both a
cost leak and a child-UX failure). Confirm the exact model strings at deploy (Gemini Flash /
Claude version ids shift release-to-release) — override via the env vars below.

Models are built LAZILY (inside each `build_*_model()`), so importing this module never needs a
provider key. Tests monkeypatch the node-level `build_*_model` to return a fake model offline.
"""

from __future__ import annotations

import os

# Per-node defaults — the live KEYLESS Gemini-on-Vertex baseline (D-02). Overridable by env for
# the eval bake-off WITHOUT a code change.
ANALYZE_MODEL = os.environ.get("ANALYZE_MODEL", "gemini-2.5-flash")
ANALYZE_MODEL_PROVIDER = os.environ.get("ANALYZE_MODEL_PROVIDER", "google_vertexai")
ANALYZE_TEMPERATURE = float(os.environ.get("ANALYZE_TEMPERATURE", "0"))
ANALYZE_MAX_TOKENS = int(os.environ.get("ANALYZE_MAX_TOKENS", "512"))

PLAN_MODEL = os.environ.get("PLAN_MODEL", "gemini-2.5-flash")
PLAN_MODEL_PROVIDER = os.environ.get("PLAN_MODEL_PROVIDER", "google_vertexai")
PLAN_TEMPERATURE = float(os.environ.get("PLAN_TEMPERATURE", "0.2"))
PLAN_MAX_TOKENS = int(os.environ.get("PLAN_MAX_TOKENS", "512"))

COACH_MODEL = os.environ.get("COACH_MODEL", "gemini-2.5-flash")
COACH_MODEL_PROVIDER = os.environ.get("COACH_MODEL_PROVIDER", "google_vertexai")
COACH_TEMPERATURE = float(os.environ.get("COACH_TEMPERATURE", "0.5"))
COACH_MAX_TOKENS = int(os.environ.get("COACH_MAX_TOKENS", "256"))
# Vertex region for the coach. Gemini runs us-central1 (default elsewhere); the gated
# Claude-on-Vertex coach must use `global` (Claude does NOT serve us-central1 — D-03/Pitfall 2).
COACH_LOCATION = os.environ.get("COACH_LOCATION", "global")


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

    Two providers, selected by the COACH_MODEL_PROVIDER env (no code change to swap):
      * `google_vertexai` (the live keyless baseline) — Gemini-on-Vertex via init_chat_model.
      * `anthropic_vertex` (the D-03 gated upgrade) — Claude-on-Vertex via ChatAnthropicVertex.
        `init_chat_model(model_provider="google_vertexai")` resolves to ChatVertexAI (Gemini only)
        and can NOT produce a Claude model, so the Anthropic-on-Vertex path is a distinct branch.
    """
    # The D-03 branch — Claude-on-Vertex, keyless via runtime SA ADC (no provider key). Allowed
    # ONLY after a human Enables Claude in Vertex AI Model Garden AND the eval picks Claude.
    if COACH_MODEL_PROVIDER == "anthropic_vertex":
        from langchain_google_vertexai.model_garden import ChatAnthropicVertex

        # Returned UNbound — coach.py's build_coach_with_tools() still calls
        # .bind_tools(ACTION_TOOLS, tool_choice="any"). Claude serves `global`, NOT us-central1.
        return ChatAnthropicVertex(
            model_name=COACH_MODEL,  # e.g. claude-haiku-4-5@20251001
            project=os.environ["GCP_PROJECT_ID"],
            location=COACH_LOCATION,  # "global" — NOT us-central1 (Gemini's region)
            temperature=COACH_TEMPERATURE,
            max_tokens=COACH_MAX_TOKENS,  # never unbounded (4b.3)
        )

    from langchain.chat_models import init_chat_model

    return init_chat_model(
        COACH_MODEL,
        model_provider=COACH_MODEL_PROVIDER,
        temperature=COACH_TEMPERATURE,
        max_tokens=COACH_MAX_TOKENS,
        **_provider_kwargs(COACH_MODEL_PROVIDER),
    )
