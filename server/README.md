# Qalam Tutor Server (Phase 14, Plan 01)

The server-side **LangGraph** tutor agent. A FastAPI app on **Cloud Run** that:

- verifies the caller (**Firebase ID token** + **App Check** limited-use token) before any model runs,
- runs a **minimal one-node LangGraph graph** (a single `coach` node forcing one of the 4 ACTION tools via `tool_choice="any"`),
- returns one **grounded** coaching ACTION end-to-end.

This plan (01) stands up the secure deploy seam and **the single, final, enlarged request DTO** (`TutorFactsIn`). Plan 02 deepens the reasoning (analyze→plan→coach); Plan 03 wires the Flutter client. They build against this contract; they do **not** widen it.

> Framework decision: **LangGraph (Python)** — ADR-015 / 14-AI-SPEC §2. We deploy a **custom FastAPI** server (NOT `langgraph dev` / LangGraph Platform); the graph is a library we import.

---

## The wire contract (the single source of truth)

`app/schema.py` defines the FULL enlarged, day-one-final `TutorFactsIn` with `extra="forbid"`:

| Field | Type | Notes |
|-------|------|-------|
| `letterId` | `str` | e.g. `baa` |
| `section` | `str` | e.g. `traceLetter` |
| `passed` | `bool` | the scorer's frozen verdict |
| `mistakeId` | `str \| None` | authored feedback key on a miss |
| `struggleTags` | `list[str]` | derived session struggles |
| `recentMistakes` | `list[str]` | recent mistake ids |
| `trajectory` | `list[AttemptFactIn]` | **enlarged** — the scored-attempt trajectory |
| `strengthTags` | `list[str]` | **enlarged** — the session learner-model strengths |

`AttemptFactIn` (nested, also `extra="forbid"`): `passed: bool`, `mistakeId: str | None`, `section: str`.

`extra="forbid"` on **both** models means any leaked stroke/PII key (`strokes`, `x`, `y`, `childName`, `nickname`, …) is a **422**, not silently accepted (server side of GROUND-02). This mirrors the client `lib/tutor/tutor_facts.dart` whitelist; Plan 03 enlarges the *client* type to add `trajectory` + `strengthTags` to match this DTO.

Response DTO `CoachOut`: `toolName` (one of `present_activity`, `say`, `give_hint`, `advance`), `args`, `source="agent"`, `grounded: bool`.

---

## Model routing (keyless Gemini-on-Vertex — D-02 / 16-RESEARCH)

All three nodes (analyze / plan / coach) run **Gemini-on-Vertex, keyless**: the server
authenticates to Vertex AI via the runtime service account's Application Default Credentials.
There is **no provider API key** anywhere — not in the image, not in Secret Manager, not on the
client. This is the live `qalam-tutor` deploy. The routing table lives in `app/models.py`
(env-driven, eval-tunable without a code change).

| node | model (default) | provider | location | temp | max_tokens |
|------|-----------------|----------|----------|------|------------|
| analyze | `gemini-2.5-flash` | `google_vertexai` | us-central1 | 0.0 | 512 |
| plan | `gemini-2.5-flash` | `google_vertexai` | us-central1 | 0.2 | 512 |
| coach | `gemini-2.5-flash` | `google_vertexai` | us-central1 | 0.5 | 256 |

**Gated upgrade — Claude-on-Vertex coach (D-03).** Claude is a drop-in **env swap**, not a code
change: set `COACH_MODEL_PROVIDER=anthropic_vertex`, `COACH_MODEL=claude-haiku-4-5@20251001`,
`COACH_LOCATION=global`. Allowed **only after** (a) a human clicks **Enable** on the Claude card in
Vertex AI Model Garden for `qalam-app-bd7d0` (it returns 404 "no access" until then), **and** (b)
the eval (`make eval`) picks Claude over Gemini on the Arabic-register dimension. Still keyless
(runtime SA ADC). Claude does **not** serve `us-central1` (Gemini's region) — hence the separate
`COACH_LOCATION=global` (`build_coach_model()` routes this branch through `ChatAnthropicVertex`,
since `init_chat_model(model_provider="google_vertexai")` resolves to Gemini's `ChatVertexAI`).

---

## Resolved dependency versions

Verified GA on PyPI at build (2026-06-22). Pinned ranges live in `pyproject.toml`; the exact resolved set is captured by `uv pip freeze` after install.

| Package | Pinned range | Latest GA at build |
|---------|--------------|--------------------|
| `langgraph` | `>=1.2,<2` | `1.2.6` |
| `langchain` | `>=1.0,<2` | `1.3.10` |
| `langchain-google-vertexai` | `>=3.2.4` | carries both Gemini (`ChatVertexAI`) and Claude-on-Vertex (`ChatAnthropicVertex`) |
| `langchain-anthropic` | `>=1.0,<2` | `1.4.6` — REMOVE candidate (D-02): the superseded Anthropic-direct-key path; Claude-on-Vertex uses `ChatAnthropicVertex` instead |
| `langchain-google-genai` | `>=3.0,<5` | `4.2.5` (AI-SPEC said `<4`; widened to `<5` since latest GA is 4.x) |
| `fastapi` | `>=0.115` | `0.138.0` |
| `uvicorn[standard]` | `>=0.32` | `0.49.0` |
| `pydantic` | `>=2.9,<3` | `2.13.4` |
| `sse-starlette` | `>=2.1` | `3.4.5` |
| `firebase-admin` | `>=7.0,<8` | `7.4.0` |

To record the exact resolved set after `uv sync`:
```bash
cd server && uv pip freeze | grep -Ei 'langgraph|langchain|fastapi|firebase-admin|pydantic'
```

All packages are GA, first-party or de-facto-standard PyPI packages named directly in 14-AI-SPEC §3 — none `[SUS]`/`[SLOP]` (Package Legitimacy: verified each at `pypi.org/project/<name>`).

---

## Local development

```bash
cd server
uv sync                 # resolve + install (creates .venv)
cp .env.example .env     # local dev only — NEVER commit a real .env
uv run pytest -q         # auth + endpoint tests (model-free `code` checks; offline)
uv run uvicorn app.main:app --reload --port 8080
```

Local token verification AND keyless Vertex model calls both use Application Default Credentials —
there is no provider key to set:
```bash
gcloud auth application-default login   # so firebase-admin resolves qalam-app-bd7d0 AND Vertex ADC works
```

---

## Cloud Run deploy

**Keyless (D-02):** the service authenticates to Vertex AI via the runtime service account's ADC.
There is **no provider API key** to create, store, or inject — no `ANTHROPIC_API_KEY`, no
`GOOGLE_API_KEY`, in the image, in Secret Manager, or on the client.

### 1. Grant the runtime service account Vertex AI access (one time, project `qalam-app-bd7d0`)

```bash
PROJECT=qalam-app-bd7d0
RUNTIME_SA="$(gcloud iam service-accounts list --project="$PROJECT" \
  --filter='displayName:Compute Engine default service account' --format='value(email)')"
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${RUNTIME_SA}" --role="roles/aiplatform.user"
```

The Vertex AI API must be enabled on the project (`gcloud services enable aiplatform.googleapis.com --project="$PROJECT"`).

### 2. Deploy (build + run, keyless env only)

```bash
gcloud run deploy qalam-tutor \
  --source . \
  --project=qalam-app-bd7d0 \
  --region=us-central1 \
  --allow-unauthenticated \
  --min-instances=0 \
  --timeout=30 \
  --set-env-vars=GCP_PROJECT_ID=qalam-app-bd7d0,GOOGLE_CLOUD_LOCATION=us-central1,COACH_TIMEOUT_SECONDS=12
```

> `--allow-unauthenticated` lets the public client reach the URL; the **app** enforces auth
> in `verify_caller` (Firebase ID token + App Check) — Cloud Run IAM is not the auth layer here.
> `--min-instances=0` is fine for the demo; the session-start `GET /health` warm-up ping masks cold start.
> **No `--set-secrets`:** keyless ADC means there is no provider key to inject.

**Gated Claude-on-Vertex upgrade (D-03):** after a human Enables the Claude card in Vertex AI
Model Garden AND the eval picks Claude, re-deploy with the coach env swap (still keyless — no key):

```bash
  --set-env-vars=...,COACH_MODEL=claude-haiku-4-5@20251001,COACH_MODEL_PROVIDER=anthropic_vertex,COACH_LOCATION=global
```

### 3. Verify the live service (the human-verify checkpoint)

```bash
URL="$(gcloud run services describe qalam-tutor --project=qalam-app-bd7d0 --region=us-central1 --format='value(status.url)')"
curl -i "$URL/health"                        # expect 200  (NOT /healthz — Google edge reserves that exact path)
curl -i -XPOST "$URL/coach" -d '{}'          # expect 401 (no tokens — endpoint is NOT open)
```

Also confirm in the GCP Console:
- The service has **no provider-key env var and no Secret Manager reference** (keyless ADC only); no key is in the container image.
- The runtime service account holds `roles/aiplatform.user` so Vertex calls authenticate via ADC.
- Firebase **App Check** shows the Android app registered with the **Play Integrity** provider.

---

## Files

```
server/
├── pyproject.toml          # pinned deps (uv)
├── Dockerfile              # python:3.12-slim + plain uvicorn (no langgraph-cli)
├── .dockerignore           # excludes tests/.env/__pycache__
├── .env.example            # GCP project id + keyless model routing (no provider key — D-02)
├── app/
│   ├── main.py             # FastAPI: POST /coach (Depends(verify_caller)) + GET /health; asyncio.wait_for
│   ├── auth.py             # verify_caller: Firebase ID token + App Check (401 before the graph)
│   ├── schema.py           # TutorFactsIn (FINAL enlarged) + AttemptFactIn + CoachOut — the wire contract
│   ├── state.py            # TutorState TypedDict (Annotated[list, add] reducer on the accumulator)
│   ├── tools.py            # the 4 @tool ACTION functions (bound + forced, never executed server-side)
│   ├── prompts.py          # COACH_PROMPT (mother's-voice + grounding rule); ANALYZE/PLAN stubs (Plan 02)
│   └── graph.py            # build_graph(): one coach node, bind_tools(tool_choice="any"), G3 advance-on-fail guard
└── tests/
    ├── conftest.py         # offline firebase + model monkeypatch; httpx ASGI client
    ├── test_auth.py        # 401 on missing/invalid ID token AND missing/invalid App Check token
    └── test_endpoint.py    # enlarged payload accepted (200); extra/PII keys rejected (422); G3 rewrite
```
