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

## Resolved dependency versions

Verified GA on PyPI at build (2026-06-22). Pinned ranges live in `pyproject.toml`; the exact resolved set is captured by `uv pip freeze` after install.

| Package | Pinned range | Latest GA at build |
|---------|--------------|--------------------|
| `langgraph` | `>=1.2,<2` | `1.2.6` |
| `langchain` | `>=1.0,<2` | `1.3.10` |
| `langchain-anthropic` | `>=1.0,<2` | `1.4.6` |
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

Local token verification uses Application Default Credentials:
```bash
gcloud auth application-default login   # so firebase-admin can resolve qalam-app-bd7d0
```

---

## Cloud Run deploy

Provider keys live in **Secret Manager**, injected as env vars — **never** in the image or the client.

### 1. Create the two secrets (one time, project `qalam-app-bd7d0`)

```bash
PROJECT=qalam-app-bd7d0

# Anthropic key (Claude Haiku/Sonnet, coach voice)
printf '%s' "<ANTHROPIC_API_KEY value>" \
  | gcloud secrets create ANTHROPIC_API_KEY --project="$PROJECT" --data-file=-

# Google AI key (Gemini per-node routing, Plan 02)
printf '%s' "<GOOGLE_API_KEY value>" \
  | gcloud secrets create GOOGLE_API_KEY --project="$PROJECT" --data-file=-
```

Grant the Cloud Run runtime service account `secretAccessor`:
```bash
RUNTIME_SA="$(gcloud iam service-accounts list --project="$PROJECT" \
  --filter='displayName:Compute Engine default service account' --format='value(email)')"
for S in ANTHROPIC_API_KEY GOOGLE_API_KEY; do
  gcloud secrets add-iam-policy-binding "$S" --project="$PROJECT" \
    --member="serviceAccount:${RUNTIME_SA}" --role="roles/secretmanager.secretAccessor"
done
```

### 2. Deploy (build + run, secrets as env refs)

```bash
gcloud run deploy qalam-tutor \
  --source . \
  --project=qalam-app-bd7d0 \
  --region=us-central1 \
  --allow-unauthenticated \
  --min-instances=0 \
  --timeout=30 \
  --set-env-vars=GCP_PROJECT_ID=qalam-app-bd7d0,COACH_TIMEOUT_SECONDS=8 \
  --set-secrets=ANTHROPIC_API_KEY=ANTHROPIC_API_KEY:latest,GOOGLE_API_KEY=GOOGLE_API_KEY:latest
```

> `--allow-unauthenticated` lets the public client reach the URL; the **app** enforces auth
> in `verify_caller` (Firebase ID token + App Check) — Cloud Run IAM is not the auth layer here.
> `--min-instances=0` is fine for the demo; the session-start `GET /health` warm-up ping masks cold start.

### 3. Verify the live service (the human-verify checkpoint)

```bash
URL="$(gcloud run services describe qalam-tutor --project=qalam-app-bd7d0 --region=us-central1 --format='value(status.url)')"
curl -i "$URL/health"                        # expect 200  (NOT /healthz — Google edge reserves that exact path)
curl -i -XPOST "$URL/coach" -d '{}'          # expect 401 (no tokens — endpoint is NOT open)
```

Also confirm in the GCP Console:
- ANTHROPIC_API_KEY / GOOGLE_API_KEY are **Secret Manager references** on the service (not plaintext env values), and no key is in the container image.
- Firebase **App Check** shows the Android app registered with the **Play Integrity** provider.

---

## Files

```
server/
├── pyproject.toml          # pinned deps (uv)
├── Dockerfile              # python:3.12-slim + plain uvicorn (no langgraph-cli)
├── .dockerignore           # excludes tests/.env/__pycache__
├── .env.example            # GCP project id + key placeholders (real values in Secret Manager)
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
