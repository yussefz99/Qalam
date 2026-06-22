---
phase: 14-build-tutorbrain-spine-grounding-invariant
plan: 01
subsystem: tutor-server
tags: [langgraph, fastapi, cloud-run, firebase-auth, app-check, grounding, wire-contract]
status: code-complete-checkpoint-pending
requires: []
provides:
  - "server/ FastAPI + LangGraph tutor sub-project (deployable to Cloud Run)"
  - "The FINAL enlarged non-PII wire DTO TutorFactsIn (6 base + AttemptFactIn trajectory + strengthTags, extra=forbid) — the single contract Plans 02/03/04 reference"
  - "verify_caller auth dependency (Firebase ID token + App Check, 401 before the graph)"
  - "Minimal one-node grounding graph with the G2 action-space lock + G3 verdict lock"
  - "POST /coach + GET /healthz endpoints"
affects:
  - "Plan 02 (deepens the graph: analyze->plan->coach; sets CoachOut.grounded; does NOT widen TutorFactsIn)"
  - "Plan 03 (enlarges the Flutter client TutorFacts to add trajectory + strengthTags to MATCH this DTO; wires the client to /coach)"
  - "Plan 04 (GROUND-02 build-failing guard builds on this extra=forbid DTO)"
tech-stack:
  added:
    - "langgraph 1.2.6"
    - "langchain 1.3.10"
    - "langchain-anthropic 1.4.6"
    - "langchain-google-genai 4.2.5"
    - "fastapi 0.138.0"
    - "uvicorn 0.49.0"
    - "pydantic 2.13.4"
    - "sse-starlette 3.4.5"
    - "firebase-admin 7.4.0"
  patterns:
    - "uv-managed Python sub-project (package=false; deps-only venv, app/ copied into the image)"
    - "FastAPI Depends(verify_caller) auth gate before any model runs"
    - "LangGraph bind_tools(tool_choice='any') as the structural action-space lock"
    - "asyncio.wait_for graph budget -> 503 on timeout so the client degrades (no dead-end)"
key-files:
  created:
    - server/pyproject.toml
    - server/uv.lock
    - server/Dockerfile
    - server/.dockerignore
    - server/.gitignore
    - server/.env.example
    - server/README.md
    - server/app/__init__.py
    - server/app/auth.py
    - server/app/schema.py
    - server/app/state.py
    - server/app/tools.py
    - server/app/prompts.py
    - server/app/graph.py
    - server/app/main.py
    - server/tests/__init__.py
    - server/tests/conftest.py
    - server/tests/test_auth.py
    - server/tests/test_endpoint.py
  modified: []
decisions:
  - "langchain-google-genai pinned >=3.0,<5 (AI-SPEC said <4; latest GA is 4.2.5, so widened to <5)"
  - "Project is package=false (a deployed app, not a distributed library) — sidesteps a hatchling VCS-exclusion UnicodeDecodeError and installs deps only"
  - ".env.example placeholders use __REPLACE_ME__ form (not sk-ant-/AIza- prefixes) so the no-committed-keys grep gate returns nothing"
metrics:
  tasks_completed: 2
  tasks_total: 3
  files_created: 19
  tests: "15 passed"
  duration: "~30m"
  completed: 2026-06-22
---

# Phase 14 Plan 01: TutorBrain Server Spine + Secure Deploy Seam Summary

Stood up the `server/` Python LangGraph tutor sub-project: a Cloud-Run-deployable FastAPI app whose `POST /coach` verifies the caller (Firebase ID token + App Check) before running a minimal one-node grounding graph that forces exactly one of the 4 ACTION tools, and which owns the single, final, enlarged non-PII `TutorFactsIn` wire contract.

## What was built

**Task 1 — secure deploy seam (commit `f635c6e`):**
- `server/` uv sub-project with pinned deps (resolved versions recorded in README.md), a `python:3.12-slim` Dockerfile on a plain `uvicorn` entrypoint (no `langgraph dev`/Platform), and `.dockerignore`/`.gitignore` keeping tests, `.env`, and the venv out of the image and git.
- `app/auth.py` `verify_caller`: a FastAPI dependency that 401s a missing/invalid Firebase ID token AND a missing/invalid App Check (`X-Firebase-AppCheck`) token before the graph runs. `firebase_admin` is initialized once at import via ADC for project `qalam-app-bd7d0`. Reads NO provider keys.
- `tests/conftest.py` (offline firebase monkeypatch + httpx ASGI client) and `tests/test_auth.py`.

**Task 2 — the contract + the graph + the endpoints (commit `4441683`):**
- `app/schema.py`: the FINAL enlarged `TutorFactsIn` = the 6 base fields (`letterId`, `section`, `passed`, `mistakeId`, `struggleTags`, `recentMistakes`) PLUS `trajectory: list[AttemptFactIn]` + `strengthTags: list[str]`, with `extra="forbid"` on BOTH `TutorFactsIn` and the nested `AttemptFactIn`. Plus the `CoachOut` response DTO. This is the day-one-final contract — not widened later.
- `app/tools.py`: the closed 4 ACTION tools mirroring `lib/tutor/tutor_decision.dart`.
- `app/graph.py` `build_graph()`: one `coach` node, `bind_tools(ACTION_TOOLS, tool_choice="any")` (G2 lock), FACTS injected as text, and the G3 verdict lock — an `advance` forced on a `passed=False` verdict is rewritten to a grounded `say` and flagged `grounded=False`. `InMemorySaver` keeps the server stateless.
- `app/prompts.py`: the mother's-voice `COACH_PROMPT` + grounding rule (ANALYZE/PLAN are Plan-02 stubs).
- `app/main.py`: `GET /healthz` (no auth, warm-up) + `POST /coach` (`Depends(verify_caller)`) under `asyncio.wait_for`; timeout/error returns a structured 503 so the client degrades to its AuthoredFallback floor (G5).

## Verification

- `cd server && uv run pytest -q` → **15 passed**.
  - Auth: 401 on no/malformed/invalid ID token; 401 on valid ID token + missing/invalid App Check; `/healthz` needs no auth.
  - Endpoint: the FULL enlarged payload (populated `trajectory` + `strengthTags`) → 200 with an in-set `toolName`; each of `{strokes, x, y, childName, nickname}` → 422 (top-level); a leaked key inside a `trajectory` entry → 422 (nested `AttemptFactIn`); `advance`-on-fail rewritten to a grounded `say` (`grounded=False`); `advance`-on-pass allowed (`grounded=True`).
- No-committed-keys gate: `grep -rEi "sk-ant|AIza[0-9A-Za-z_-]{20,}" server/` returns nothing.
- key_links satisfied: `main.py` has `Depends(verify_caller)` + `ainvoke`; `graph.py` binds `tool_choice="any"`.

## Resolved dependency versions

| Package | Resolved |
|---------|----------|
| langgraph | 1.2.6 |
| langchain | 1.3.10 |
| langchain-anthropic | 1.4.6 |
| langchain-google-genai | 4.2.5 |
| fastapi | 0.138.0 |
| uvicorn | 0.49.0 |
| pydantic | 2.13.4 |
| sse-starlette | 3.4.5 |
| firebase-admin | 7.4.0 |

All verified GA on `pypi.org` at build (2026-06-22) — package legitimacy confirmed, none `[SUS]`/`[SLOP]`.

## The final enlarged TutorFactsIn field set

`TutorFactsIn` (`extra="forbid"`): `letterId: str`, `section: str`, `passed: bool`, `mistakeId: str | None`, `struggleTags: list[str]`, `recentMistakes: list[str]`, `trajectory: list[AttemptFactIn]`, `strengthTags: list[str]`.
`AttemptFactIn` (`extra="forbid"`): `passed: bool`, `mistakeId: str | None`, `section: str`.

## Deviations from Plan

**1. [Rule 3 - Blocking] hatchling build failure → `package = false`**
- **Found during:** Task 1 `uv sync`.
- **Issue:** The default `[build-system] hatchling` build choked with a `UnicodeDecodeError` reading a VCS exclusion file while trying to build the project itself as a wheel.
- **Fix:** This is a deployed application, not a distributed library — set `[tool.uv] package = false` so uv installs only the dependencies (the Dockerfile copies `app/` directly). Removed the `[build-system]`/`[tool.hatch...]` blocks.
- **Files modified:** `server/pyproject.toml`. **Commit:** `f635c6e`.

**2. [Rule 2 - Correctness] `langchain-google-genai` range widened to `<5`**
- **Issue:** AI-SPEC §3 pinned `>=3.0,<4`, but the latest GA is `4.2.5` — the `<4` cap would resolve to an older line.
- **Fix:** Pinned `>=3.0,<5` and recorded the resolved `4.2.5` in README. **Commit:** `f635c6e`.

**3. [Rule 2 - Security] `.env.example` placeholders changed to `__REPLACE_ME__` form**
- **Issue:** The acceptance criterion requires `grep -rEi "sk-ant|AIza[0-9A-Za-z_-]{20,}" server/` to return nothing; the original `sk-ant-…`/`AIza-…` placeholders matched the gate pattern.
- **Fix:** Used `__REPLACE_ME_LOCAL_DEV_ONLY__` placeholders so the gate is clean and no string resembles a leaked key. **Commit:** `f635c6e`.

## Task 3 — deploy human-verify checkpoint: PENDING-HUMAN

Task 3 is a `checkpoint:human-verify` (gate=blocking) requiring a **live Cloud Run deploy + Secret Manager setup** in project `qalam-app-bd7d0`. A live `gcloud run deploy` / secret creation / device action **cannot be performed autonomously** by this worktree executor (no gcloud auth, live GCP). Per the orchestrator's checkpoint instruction, no live deploy was attempted.

**What IS done (code-complete + deployable):** the Dockerfile, `.dockerignore`, `.env.example`, and README make the service Cloud-Run-deployable, and the README contains the exact commands a human runs.

**The exact commands the human runs (project `qalam-app-bd7d0`):**

```bash
PROJECT=qalam-app-bd7d0

# 1. Create the two secrets (one time)
printf '%s' "<ANTHROPIC_API_KEY value>" | gcloud secrets create ANTHROPIC_API_KEY --project="$PROJECT" --data-file=-
printf '%s' "<GOOGLE_API_KEY value>"    | gcloud secrets create GOOGLE_API_KEY    --project="$PROJECT" --data-file=-

# 2. Grant the Cloud Run runtime SA secretAccessor
RUNTIME_SA="$(gcloud iam service-accounts list --project="$PROJECT" \
  --filter='displayName:Compute Engine default service account' --format='value(email)')"
for S in ANTHROPIC_API_KEY GOOGLE_API_KEY; do
  gcloud secrets add-iam-policy-binding "$S" --project="$PROJECT" \
    --member="serviceAccount:${RUNTIME_SA}" --role="roles/secretmanager.secretAccessor"
done

# 3. Deploy (build + run, secrets as env refs)
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

**Verification steps to clear the checkpoint (from the plan):**
1. Confirm the Cloud Run service URL printed by the deploy.
2. `GET <url>/healthz` → expect **200**.
3. `curl -XPOST <url>/coach` WITHOUT an Authorization header → expect **401** (endpoint not open).
4. In the GCP Console, confirm `ANTHROPIC_API_KEY` / `GOOGLE_API_KEY` are **Secret Manager references** on the service (not plaintext env values) and no key is in the image.
5. In Firebase App Check, confirm the Android app is registered with the **Play Integrity** provider.

**Resume signal:** Type "approved" once the live endpoint answers `/healthz`, rejects unauthenticated `/coach`, and keys are Secret Manager references — or describe what failed.

> Note: the README also includes the App Check registration step; that and the secret creation are the two `user_setup.dashboard_config` items the plan flags as human-only.

## Known Stubs

`app/prompts.py` `ANALYZE_PROMPT` / `PLAN_PROMPT` are intentional stubs labeled `[STUB — Plan 02]`. They are NOT wired into the minimal one-node graph (only `COACH_PROMPT` is used), so they do not affect this plan's goal — Plan 02 fills them when it adds the analyze/plan nodes. Documented here as intentional, resolved by Plan 02.

## Self-Check: PASSED
- All 19 created files exist (verified on disk).
- Commits `f635c6e` (Task 1) and `4441683` (Task 2) exist in git log.
- 15 tests pass; no-committed-keys grep gate clean.
