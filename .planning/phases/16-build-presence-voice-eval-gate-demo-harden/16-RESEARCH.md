# Phase 16: BUILD — presence + voice + eval gate + demo-harden - Research

**Researched:** 2026-06-29
**Domain:** Vertex AI model routing (keyless Anthropic-on-Vertex) + on-device Flutter TTS (mixed Arabic/English) + a local pytest eval-gate
**Confidence:** HIGH on D-03 (live-probed the project's own Vertex endpoint) · HIGH on D-06 (pub.dev + official docs) · MEDIUM on the on-device latency/voice specifics (must be measured on the real Pixel Tablet in-phase, per ROADMAP "research hint: no")

## Summary

This is a **targeted** pass: the two planner-blocking unknowns are (D-03) whether a candidate Claude coach model is reachable on this project's Vertex AI and at which region/ID, and (D-06) how to voice a mixed English+Arabic coach line on a stock Pixel Tablet. Both are now resolved with concrete, lockable answers.

**D-03 — the decisive finding (live-probed, not inferred):** The deployed `qalam-tutor` Cloud Run service **already routes all three nodes (analyze/plan/coach) through `google_vertexai` with `gemini-2.5-flash`, keyless, in `us-central1`** — so D-02 (all-Vertex, keyless, no Anthropic key) is **already true in production today**. Against that working baseline I probed the project's Vertex endpoint directly: **Gemini returns 200 OK in us-central1 and us-east5; every Claude model returns `404 NOT_FOUND — "your project does not have access to it"`** (including the long-available `claude-3-5-haiku@20241022`, using the exact documented IDs). The caller is project **Owner** with the Vertex API enabled, so this is **not** an IAM or typo problem — it is the **Model Garden per-publisher "Enable"/terms-acceptance gate**: Anthropic models are not callable on a GCP project until someone clicks **Enable** on the Claude model card in Model Garden (after which access is immediate). Additionally, **Claude on Vertex does not serve `us-central1` at all** — Haiku 4.5 is offered in `us-east5`, `europe-west1`, `global`, and multi-region `us`/`eu`. So adopting Claude for the coach requires (a) a human Model-Garden Enable click, (b) a **separate region** for the Anthropic client (`global` recommended), and (c) a **code change** in `models.py` because `init_chat_model(model_provider="google_vertexai")` resolves to `ChatVertexAI` (Gemini only) — Claude-on-Vertex needs `ChatAnthropicVertex` (or the `anthropic[vertex]` SDK) instantiated directly.

**D-06 — flutter_tts:** Current version **4.2.5** (pub.dev, published 2026-01-05), verified publisher `eyedeadevelopment.com` (dlutton), 1586 likes, 150/160 pub points, ~267k downloads/30d — a strong-legitimacy package on the same evidence basis the project used for `audioplayers`. The mixed English+Arabic line **cannot be voiced reliably with a single `setLanguage` call** (the engine picks characters of only the set locale and drops the rest); the implementable pattern is **segment-the-line-by-script → `awaitSpeakCompletion(true)` → per-segment `setLanguage('ar')` / `setLanguage('en-US')` + sequential `speak()`**. Arabic voice data is **not guaranteed installed** on a stock Pixel Tablet (Google TTS often ships en-US, requires an Arabic voice-data download), so the plan must `isLanguageAvailable('ar')` / `areLanguagesInstalled` first and **gracefully degrade** (speak the English guidance, skip or romanize the Arabic token) — never block the trace loop.

**Primary recommendation:** **Lock the routing table as all-Gemini-on-Vertex (the live baseline) and treat the Claude coach as an eval-gated, human-enabled UPGRADE, not an assumption.** Concretely: keep `analyze`/`plan` on `gemini-2.5-flash` (us-central1); for `coach`, run the D-13 bake-off `gemini-2.5-flash` (us-central1, already working) vs `claude-haiku-4-5@20251001` (region `global`, **only after** a human Enables it in Model Garden) on the EVAL Arabic-register dimension, and let the eval pick the winner. If the Enable click can't happen before the Technion demo, **the demo ships all-Gemini-keyless and still meets every success criterion** (the coach voice is then a tuned-Gemini line, not Claude). For TTS, ship the segment-by-script + availability-check + graceful-degrade pattern.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Fold lean Phase-12 (latency budget) + Phase-13 (coach-model bake-off) into Phase 16 as inline steps; measure the real stroke→scorer→client→Cloud Run→model→render→first-TTS path **on the Pixel Tablet** and produce the written latency budget PRES-01 is measured against (incl. cold-start-vs-warm delta).
- **D-02:** ALL tutor nodes (analyze/plan/coach) route through Vertex AI — **keyless**, on Technion credits (same posture as the deployed Gemini-on-Vertex setup). **No Anthropic API key anywhere.** Supersedes 14-AI-SPEC §4's `model_provider="anthropic"` + Anthropic-key-in-Secret-Manager path.
- **D-03:** Coach = strongest-Arabic-register model available **on Vertex**, chosen by the eval (D-09). Default to `claude-haiku-4-5` **IF reachable on Vertex Model Garden in the project's region**; else fall back to best Vertex Claude, or Gemini if it wins the Arabic eval. **Research MUST verify Vertex reachability + region before the planner locks the routing table.** (← this RESEARCH resolves it.)
- **D-04:** On-device TTS via `flutter_tts` (Pixel built-in voices); voices both the live agent line AND the `AuthoredFallback` floor so coaching speaks in airplane mode. Premium/cloud TTS is deferred.
- **D-05:** Two clocks — the scorer verdict renders instantly on-screen (local, silent); the spoken coaching arrives a beat later, on **both** a clean pass and a miss. Whole short line spoken; token streaming + incremental TTS is optional/nice-to-have.
- **D-06:** `flutter_tts` is a NEW package → subject to the package-legitimacy checkpoint (autonomous:false, as for `audioplayers`/`crypto`). Mixed English+Arabic locale-switching within one utterance is a known pitfall to research and handle.
- **D-07:** Eval gate is a LOCAL documented pre-merge step (`make eval` / pytest), NOT CI. Standing CI up is out of scope.
- **D-08:** Faithfulness is a ZERO-TOLERANCE hard gate (praise-on-fail / wrong-fix fails the build). Model-free; grows the Phase-15 `app/faithfulness.py` seed.
- **D-09:** Register-for-a-5–10-year-old + correct-Arabic are scored by a **Vertex LLM-judge** against a rubric, calibrated to a small **mom-signed** gold set (Claude DRAFTS, owner's mother REVIEWS+SIGNS). These two dimensions gate on a **threshold** (not zero-tolerance).
- **D-10:** The harness runs the coach over labeled (verdict, learner-state) cases and reports per-dimension scores for all four 14-AI-SPEC §5 dimensions. Regulatory note: labeled set / logged transcripts must NOT train/fine-tune models without separate verifiable parental consent.
- **D-11:** Live demo runs the REAL online agent (Vertex), with a session-start warm-up ping to defeat Cloud Run cold-start (min-instances=0); `AuthoredFallback` floor is an INVISIBLE auto safety net on any timeout/drop — never a dead end. One-tap manual "switch to offline" is optional (Claude's discretion).
- **D-12:** Hero moment = grounded adaptivity (seed a wobble → backward remediation → speak the specific fix → one quiet star). Needs a reliable seeded demo state. Grounding guarantee (never fakes a pass) is the second demo beat.
- **D-13:** Demo path = Home/Journey → baa unit → mastery star on the Pixel-Tablet build; no dead ends; graceful offline/timeout fallback to authored lines.

### Claude's Discretion
The exact latency budget numbers (from on-device measurement, not pre-set); whether to add SSE text streaming (optional per D-05); the warm-up-ping mechanism + timing; the seeded-demo-state mechanism; the LLM-judge prompt/rubric + gold-set size & file format; whether to add the one-tap manual demo fallback; `flutter_tts` config (voice, rate, pitch, locale switching); the eval-gate `make`/pytest harness shape; Riverpod wiring; where the latency instrumentation lives.

### Deferred Ideas (OUT OF SCOPE)
Premium/cloud TTS voice; token-by-token streaming + incremental TTS; GitHub Actions CI for the eval gate; one-tap manual demo fallback; on-device GemmaBrain coach backend (TUTOR-04); voice input/STT (S2-03), cross-letter ب/ت/ث contrast, parent struggle-analytics. **Also out of scope (additional_context):** premium/cloud TTS, GitHub Actions CI, on-device Gemma, voice input/STT, any letter other than baa.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **PRES-01** | Tutor feels present — coordination within a defined latency budget on a real Pixel Tablet; the ms stroke reflex stays local | Latency instrumentation points + warm-up-ping pattern below (SECONDARY); the budget NUMBERS are measured in-phase, not researched (ROADMAP hint=no). First-TTS latency characteristics under "flutter_tts latency". |
| **PRES-02** | Tutor speaks — streamed/TTS coaching plays at the right moments, degrades gracefully offline | D-06 flutter_tts findings: version, mixed-language pattern, voice availability + graceful degradation; voices both agent line and `AuthoredFallback` (D-04). Hook point identified (`tutorLineProvider` in `exercise_scaffold.dart`). |
| **EVAL-01** | Eval harness scores grounding faithfulness + Arabic register against a labeled set | Grows `server/app/faithfulness.py` (model-free, zero-tolerance) + a Vertex LLM-judge for register/Arabic. Gate shape + Vertex LLM-judge model recommendation below. |
| **EVAL-02** | Harness runs as a regression gate (documented pre-merge step) | `make eval` / pytest shape reusing the existing `pytest.mark.code` marker + the `faithfulness_set.jsonl` fixture pattern. |
| **DEMO-01** | baa AI-tutor path demo-hardened on Pixel Tablet; no dead ends; graceful offline/timeout fallback | Warm-up-ping (`GET /health`), `AuthoredFallback` invisible safety net (already wired in `remote_agent_brain.dart`), seeded demo state (discretion). Routing-table lock removes the last build blocker. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stroke capture + geometric scoring + verdict + star | Browser/Client (on-device, Dart) | — | The ms reflex (PRES-01) and the grounding invariant (ADR-014): the scorer owns pass/fail; it must be local and instant, never network-routed. |
| Coach line generation (analyze→plan→coach) | API/Backend (Cloud Run LangGraph) | — | ADR-015: capable reasoning agent lives behind the boundary; keys (none now) and model calls server-side. |
| Model inference (Gemini / candidate Claude) | API/Backend → Vertex AI (managed) | — | Keyless Vertex via runtime service-account ADC; model is a per-node config in `models.py`. |
| **Spoken coaching (TTS)** | **Browser/Client (on-device, `flutter_tts`)** | — | D-04: on-device synthesis = lowest first-TTS latency (no extra hop), works in airplane mode, $0. The server returns TEXT; the client speaks it. |
| Offline floor (`AuthoredFallback`) | Browser/Client (pure Dart) | — | D-11/TUTOR-02: must work with zero model, airplane mode; voiced by the same on-device TTS. |
| Eval gate (faithfulness + LLM-judge) | Dev/CI tier (local pytest) | API→Vertex (for the LLM-judge call) | D-07: local pre-merge; faithfulness is model-free; the register/Arabic judge calls a Vertex model. |
| Warm-up ping (cold-start mask) | Client → API `GET /health` | — | D-11: client fires it at session/unit start; the route is `/health` (Google edge reserves `/healthz`). |

## Standard Stack

### Core (server — already installed; this phase tunes, doesn't add)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `langgraph` | `>=1.2,<2` (live) | analyze→plan→coach graph | ADR-015 framework decision (locked) `[CITED: server/pyproject.toml]` |
| `langchain` | `>=1.0,<2` | `init_chat_model` per-node binding | `[CITED: server/pyproject.toml]` |
| `langchain-google-vertexai` | `>=3.2.4` (installed) | **Gemini-on-Vertex (live) AND `ChatAnthropicVertex` for Claude-on-Vertex** | The single package that carries BOTH the working Gemini path and the Claude Model-Garden path `[VERIFIED: server/pyproject.toml + live deploy env]` |
| `langchain-google-genai` | `>=3.0,<5` | Gemini via AI-Studio key (NOT used in prod — prod uses `google_vertexai`) | Present but the live service uses `google_vertexai`, not `google_genai` `[VERIFIED: Cloud Run env probe]` |
| `langchain-anthropic` | `>=1.0,<2` | Anthropic-DIRECT-key path | **Superseded by D-02 (no key). Candidate for REMOVAL** — Claude-on-Vertex uses `ChatAnthropicVertex` from `langchain-google-vertexai`, not this. `[VERIFIED: server/pyproject.toml]` |

### Core (client — new package this phase)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_tts` | **4.2.5** (latest, 2026-01-05) | On-device TTS for the coach line + `AuthoredFallback` floor (D-04) | Verified publisher `eyedeadevelopment.com`; 1586 likes; 150/160 pub points; ~267k downloads/30d; Android + macOS + iOS + Web + Windows. The de-facto Flutter TTS package. `[VERIFIED: pub.dev API 2026-06-29]` |

### If adopting the Claude coach (only after Model-Garden Enable)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `anthropic[vertex]` (`AnthropicVertex`) | latest | Direct Anthropic SDK over Vertex (keyless ADC) — alternative to `ChatAnthropicVertex` | Only if the LangChain `ChatAnthropicVertex` tool-calling caveat (below) bites; the SDK is the lower-level fallback. `[CITED: platform.claude.com/docs/.../claude-on-vertex-ai]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `claude-haiku-4-5@20251001` coach | `claude-sonnet-4-5@20250929` / `claude-sonnet-4-6` coach | Sonnet is stronger but slower/costlier and overkill for a 1–2 sentence line; Haiku is the AI-SPEC choice. Both need the same Enable + region story. |
| Claude coach | Keep `gemini-2.5-flash` coach (live baseline) | Gemini already works keyless in us-central1, zero new infra/region/Enable. **This is the safe default if the eval doesn't clearly favor Claude or the Enable click is blocked.** |
| `ChatAnthropicVertex` (LangChain) | `AnthropicVertex` (anthropic[vertex] SDK) directly | LangChain keeps the graph uniform (`bind_tools`/`with_structured_output`); the raw SDK is a fallback if LangChain tool-calling misbehaves on Vertex (known caveat). |
| `flutter_tts` | `just_audio` + cloud TTS / pre-recorded clips | Cloud TTS is explicitly deferred (D-04); pre-recorded can't voice a dynamic agent line. `flutter_tts` is the only fit for on-device dynamic coaching. |

**Installation (client):**
```bash
flutter pub add flutter_tts   # 4.2.5 — AFTER the package-legitimacy checkpoint (D-06)
```

**Server (no new install needed for the Gemini baseline; for the Claude upgrade):**
```bash
# langchain-google-vertexai (already installed) carries ChatAnthropicVertex — no new dep for Claude-on-Vertex.
# If using the raw SDK fallback instead:  uv pip install "anthropic[vertex]"
```

**Version verification (done this session):**
- `flutter_tts` `4.2.5`, published `2026-01-05T17:54:55Z` — `[VERIFIED: https://pub.dev/api/packages/flutter_tts 2026-06-29]`
- Claude Haiku 4.5 Vertex model ID `claude-haiku-4-5@20251001` — `[CITED: platform.claude.com/docs/en/build-with-claude/claude-on-vertex-ai, model-ID table, 2026-06-29]`
- Live `gemini-2.5-flash` on `google_vertexai` in us-central1 returns 200 — `[VERIFIED: live rawPredict/generateContent probe of project qalam-app-bd7d0, 2026-06-29]`

## Package Legitimacy Audit

> slopcheck does not cover the **pub.dev (Dart)** ecosystem (it targets npm/PyPI/crates). Legitimacy for `flutter_tts` rests on pub.dev's own signals — the identical basis the project used for the `audioplayers` blocking-human checkpoint (07-02-PLAN T-07-02-01).

| Package | Registry | Age / latest | Likes / Points | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|--------------|----------------|-----------|-------------|-----------|-------------|
| `flutter_tts` | pub.dev | latest 4.2.5 (2026-01-05); long-lived | 1586 likes / 150-160 pts | ~267k/30d | github.com/dlutton/flutter_tts (verified publisher `eyedeadevelopment.com`) | n/a (Dart) | **Approved pending the D-06 blocking-human checkpoint** |

**Packages removed due to slopcheck [SLOP] verdict:** none.
**Packages flagged [SUS]:** none. `flutter_tts` is a verified-publisher package with strong metrics; treat exactly like `audioplayers` — a blocking-human legitimacy checkpoint (`autonomous:false`) confirming verified publisher + pinned version on pub.dev BEFORE `flutter pub add`, then proceed.

**Server side:** no new package is required for the recommended (Gemini) baseline. `langchain-anthropic` (the superseded Anthropic-direct-key client) is a **REMOVE candidate** under D-02 — it is unused once Claude-on-Vertex goes through `ChatAnthropicVertex`/`langchain-google-vertexai`.

## Architecture Patterns

### System Architecture Diagram

```
 CHILD traces baa on stylus
        │  (ms reflex — LOCAL, SILENT)
        ▼
 ┌─────────────────────────────┐         on-screen verdict + star render INSTANTLY (local)
 │ On-device geometric scorer  │────────────────────────────────────────────────────────────►
 │ (owns pass/fail + star)     │
 └─────────────┬───────────────┘
               │ derived NON-PII FACTS  {letterId, mistakeId, struggleTags, passed, trajectory}
               │ (chokepoint; raw strokes/PII never cross — GROUND-02)
               ▼
        warm-up GET /health  ──►  Cloud Run qalam-tutor (min-instances=0)
               │                       │  (mask cold-start at session start)
               ▼                       ▼
 ┌──────────────────────────────────────────────────────────────────────┐
 │ POST /coach  (Firebase ID token + App Check verified)                 │
 │  LangGraph:  analyze ──(needs_plan?)──► plan ──► coach                │
 │     analyze gemini-2.5-flash @ us-central1   (structured Insight)     │
 │     plan    gemini-2.5-flash @ us-central1   (structured Plan)        │
 │     coach   GEMINI @ us-central1  ──OR──  CLAUDE haiku @ global       │
 │             (eval picks; coach = forced 1 ACTION tool, G2/G3/G4)      │
 │  all KEYLESS via runtime SA ADC on Vertex AI (Technion credits)      │
 └─────────────┬────────────────────────────────────────────────────────┘
               │ CoachOut {toolName, args:{coachingLine|text}, grounded}
               │ (timeout/5xx/parse-fail → 503 → client AuthoredFallback)
               ▼
 ┌─────────────────────────────────┐
 │ RemoteAgentBrain (Dart)         │  on ANY failure → AuthoredFallbackBrain (offline floor)
 │  → tutorLineProvider.set(line)  │
 └─────────────┬───────────────────┘
               │  coach TEXT (mixed en + occasional ar)
               ▼
 ┌─────────────────────────────────────────────────────────┐
 │ TtsCoachSpeaker (NEW, on-device, flutter_tts 4.2.5)      │  a BEAT after the visual (D-05),
 │  segment-by-script → awaitSpeakCompletion(true)         │  on BOTH pass and miss
 │  → setLanguage('en-US'|'ar') per segment → speak()      │
 │  isLanguageAvailable('ar')? no → speak en, skip ar token │
 └─────────────────────────────────────────────────────────┘
```

### Recommended Project Structure (deltas only — both subprojects exist)
```
server/app/
├── models.py            # EDIT: add a coach-provider branch for ChatAnthropicVertex (Claude-on-Vertex)
│                        #       + COACH_LOCATION env (global for Claude) — keep Gemini default
├── nodes/coach.py       # unchanged shape; the bound model just may be Claude
└── tests/test_eval/     # NEW: labeled (verdict,learner-state) cases + LLM-judge runner + Makefile/`make eval`

lib/tutor/
├── tts_coach_speaker.dart   # NEW: the segment-by-script TTS surface (D-04/D-06)
└── (remote_agent_brain.dart, authored_fallback_brain.dart, tutor_dispatcher.dart — TTS hooks here)

lib/features/letter_unit/widgets/
└── exercise_scaffold.dart   # EDIT: after tutorLineProvider.set(line) → speak it a beat later (D-05)
```

### Pattern 1: Claude-on-Vertex per-node binding (keyless) — the D-03 code shape
**What:** `init_chat_model(model_provider="google_vertexai")` builds **`ChatVertexAI` (Gemini only)** — it will NOT produce a Claude model. Claude-on-Vertex requires `ChatAnthropicVertex` (region != us-central1).
**When to use:** only after a human Enables Claude in Model Garden AND the eval picks Claude for `coach`.
**Example:**
```python
# Source: docs.langchain.com/oss/python/integrations/chat/google_anthropic_vertex (2026-06-29)
from langchain_google_vertexai.model_garden import ChatAnthropicVertex
# Claude does NOT serve us-central1 — use 'global' (recommended, no premium) or 'us-east5'/'europe-west1'
coach = ChatAnthropicVertex(
    model_name="claude-haiku-4-5@20251001",
    project="qalam-app-bd7d0",
    location="global",                 # NOT us-central1 (Gemini's region)
    temperature=0.5, max_tokens=256,
)                                      # keyless: runtime SA ADC — no ANTHROPIC_API_KEY
coach_bound = coach.bind_tools(ACTION_TOOLS, tool_choice="any")   # G2 lock — see caveat in Pitfalls
```
The cleanest integration: add a `provider == "anthropic_vertex"` branch in `build_coach_model()` (and a `COACH_LOCATION` env defaulting to `global`) so the env-driven routing table still selects it without touching the node code.

### Pattern 2: Segment-by-script mixed-language TTS — the D-06 implementable approach
**What:** A single `setLanguage` can't voice "أحسنت — that curve is perfect" correctly (the engine drops the off-locale script). Split into runs by Unicode block, set the locale per run, await each.
**When to use:** every spoken coach line (it may contain an Arabic token).
**Example:**
```dart
// Source: dlutton/flutter_tts README + issue #581 + pub.dev FlutterTts API (2026-06-29)
final tts = FlutterTts();
await tts.awaitSpeakCompletion(true);            // make speak() resolve only when audio finishes
final arOk = await tts.isLanguageAvailable('ar') == true;  // Pixel may lack the Arabic voice

// segments: [('en-US','that curve is perfect'), ('ar','أحسنت'), ...] split on Arabic-block runs
for (final (locale, text) in segmentByScript(line)) {
  if (locale == 'ar' && !arOk) continue;         // graceful degrade: skip the Arabic token, keep flow
  await tts.setLanguage(locale);
  await tts.speak(text);                          // sequential because awaitSpeakCompletion(true)
}
```
`segmentByScript` = a small pure-Dart splitter on the Arabic Unicode range (U+0600–U+06FF, plus presentation forms) vs. the rest — unit-testable with no device.

### Anti-Patterns to Avoid
- **Routing Claude through `us-central1`** — it returns NOT_FOUND; Claude is not served there. Use `global`.
- **Assuming `init_chat_model("claude-…", model_provider="google_vertexai")` yields Claude** — it yields Gemini's `ChatVertexAI`. Use `ChatAnthropicVertex`.
- **Speaking the whole mixed line with one `setLanguage`** — drops the off-locale script.
- **Calling `speak()` for the Arabic token without checking `isLanguageAvailable('ar')`** — silent no-audio or a fallback mispronunciation on a stock Pixel.
- **Letting TTS block the trace loop / the visual** — TTS is display-only (ADR-014), fired a beat AFTER the instant visual; a missing voice must never stall the child.
- **Re-introducing an Anthropic API key** — D-02; keyless ADC only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| On-device TTS engine | A native MethodChannel to Android TextToSpeech | `flutter_tts` 4.2.5 | Cross-platform, awaited completion, voice enumeration, install checks — all solved. |
| Claude-on-Vertex auth | A custom OAuth/JWT signer | runtime SA **ADC** (already how Gemini-on-Vertex works here) | Keyless by design; the deployed service already authenticates to Vertex this way. |
| Claude-on-Vertex transport | Hand-rolled `rawPredict` HTTP | `ChatAnthropicVertex` (or `anthropic[vertex]`) | Handles the `anthropic_version`, region host, streaming, and tool serialization. |
| Faithfulness check | A new model-judge for praise-on-fail | Grow `server/app/faithfulness.py` (model-free, exists, 69% baseline) | D-08 zero-tolerance gate; the seed already flags praise-on-fail + wrong-fix deterministically. |
| Eval marker/gating plumbing | A new test framework | The existing `pytest.mark.code` marker + `faithfulness_set.jsonl` fixture pattern | Already in `server/tests/` and `pyproject.toml`. |

**Key insight:** D-02's "keyless everywhere" is **already shipped** — the live service proves the keyless-Vertex posture for all three nodes. The only genuinely new server work for D-03 is a *conditional* Claude branch gated on a human Enable + an eval verdict; the safe path needs **zero** new server infra.

## Runtime State Inventory

> This is a build phase, but D-02/D-03 touch live service config that is NOT fully captured in git. Included for the planner.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — server is stateless (ADR-015 §5, `InMemorySaver`); learner model lives on-device in Drift. | none |
| **Live service config** | **The deployed `qalam-tutor` env routes all 3 nodes to `google_vertexai`/`gemini-2.5-flash`, `GOOGLE_CLOUD_LOCATION=us-central1`, `COACH_TIMEOUT_SECONDS=12`** — this is NOT reflected in `server/.env.example` (which still shows the superseded `anthropic`/key path). | Update `.env.example` + README to the keyless-Vertex truth; any Claude adoption is a **`gcloud run deploy --set-env-vars`** change (`COACH_MODEL`/`COACH_MODEL_PROVIDER`/`COACH_LOCATION`), not just code. |
| **Model-Garden enablement** | **Claude is NOT enabled on `qalam-app-bd7d0`** — every Claude model returns 404 "no access" despite Owner role. | **Human console action:** Model Garden → Claude Haiku 4.5 card → **Enable** (accept Anthropic terms). One-time, self-serve, immediate. Required BEFORE any Claude eval/deploy. |
| **Org policy (structured outputs)** | Vertex partner-model structured outputs are gated by `constraints/vertexai.allowedPartnerModelFeatures` (default disabled). | Only relevant if a Claude node uses `with_structured_output` (analyze/plan). The **coach** uses `bind_tools` (tool-calling), not structured output, so a Claude *coach* is unaffected. If analyze/plan ever move to Claude, the constraint must be allowed first. `[CITED: docs.cloud.google.com/.../partner-models/claude/structured-outputs]` |
| Secrets/env vars | `ANTHROPIC_API_KEY`/`GOOGLE_API_KEY` Secret Manager refs are LEFTOVER from the superseded path; the live nodes use neither (Vertex ADC). | D-02 cleanup: the keys can be dropped from the deploy contract; `langchain-anthropic` can be removed. (Confirm nothing else reads them first.) |
| Build artifacts | `server/uv.lock` pins the resolved set incl. `langchain-google-vertexai` — already carries the Claude class. | Re-pin only if adding `anthropic[vertex]`. |

**Nothing found** in stored-data (verified: stateless server, on-device Drift).

## Common Pitfalls

### Pitfall 1: Claude "not reachable" looks like a code bug but is a console toggle
**What goes wrong:** Calls to `claude-haiku-4-5@20251001` return `404 NOT_FOUND — "your project does not have access to it"` even with Owner IAM and Vertex API enabled.
**Why it happens:** Anthropic partner models require a per-publisher **Enable/terms-acceptance** in Model Garden; it is separate from IAM and from the Vertex API.
**How to avoid:** Add a **`checkpoint:human-verify`** task: a human opens the Claude Haiku 4.5 Model Garden card and clicks Enable BEFORE the coach bake-off runs. Verify with a one-line `rawPredict` probe returning 200.
**Warning signs:** A 200 from `gemini-…:generateContent` but a 404 from `…/publishers/anthropic/models/…:rawPredict` on the same project = not-enabled (exactly what was observed 2026-06-29).

### Pitfall 2: Region mismatch (Claude ≠ Gemini regions)
**What goes wrong:** Reusing `us-central1` (Gemini's region) for Claude → permanent 404.
**Why it happens:** Claude Haiku 4.5 serves `us-east5`, `europe-west1`, `global`, multi-region `us`/`eu` — **not** `us-central1`.
**How to avoid:** Set the Anthropic client `location="global"` (recommended: no pricing premium, dynamic routing) while Gemini stays `us-central1`. Make region a per-node env (`COACH_LOCATION`).
**Warning signs:** 404 for a model you just Enabled — check the region first.

### Pitfall 3: `ChatAnthropicVertex` tool-calling caveat
**What goes wrong:** `bind_tools(..., tool_choice="any")` may not force a tool call as reliably on Vertex-hosted Claude as on the native Anthropic API (a community-reported intermittent issue).
**Why it happens:** Vertex's partner-model surface differs subtly from native; LangChain normalizes most but not all tool-forcing edge cases.
**How to avoid:** The coach node **already has defence-in-depth** (`coach.py` degrades a missing/out-of-set tool call to a grounded `say` and flags `grounded=False`). Keep that. Validate `tool_choice="any"` actually forces a call in the bake-off; if it misbehaves, fall back to the `anthropic[vertex]` SDK or keep Gemini coach.
**Warning signs:** coach turns returning free text instead of a tool call when running Claude.

### Pitfall 4: Arabic voice missing on a stock Pixel Tablet
**What goes wrong:** `speak('أحسنت')` produces no audio (or a wrong-locale mispronunciation) because the Google TTS Arabic voice isn't installed.
**Why it happens:** Google TTS ships en-US by default; Arabic is a downloadable voice-data pack (Settings → Accessibility → TTS output → Install voice data).
**How to avoid:** `await tts.isLanguageAvailable('ar')` (and/or `areLanguagesInstalled(['ar'])`) at startup; if absent, **skip the Arabic token** and speak the English guidance only (graceful degrade per D-04/PRES-02). Optionally surface a one-time "install Arabic voice for the warmest experience" note (discretion). Measure on the actual device (ROADMAP hint=no).
**Warning signs:** Silent gaps where an Arabic word should be; `getLanguages` not containing an `ar*` entry.

### Pitfall 5: AndroidManifest `<queries>` omission (Android 11+)
**What goes wrong:** TTS engine not discoverable on Android 11+ → no voices found.
**Why it happens:** Package-visibility rules require declaring the TTS intent.
**How to avoid:** Add to `AndroidManifest.xml`:
```xml
<queries><intent><action android:name="android.intent.action.TTS_SERVICE" /></intent></queries>
```
Also ensure Kotlin Gradle plugin ≥ 1.9.10 and `minSdkVersion ≥ 21` (the project already targets higher). `[CITED: github.com/dlutton/flutter_tts README]`

## Code Examples

### Probe Claude reachability before locking the routing table (the exact check used 2026-06-29)
```bash
# Source: live probe of project qalam-app-bd7d0 (2026-06-29). curl -g disables glob so @ in the path works.
TOKEN=$(gcloud auth print-access-token)
curl -sg -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"anthropic_version":"vertex-2023-10-16","messages":[{"role":"user","content":"hi"}],"max_tokens":8}' \
  "https://us-east5-aiplatform.googleapis.com/v1/projects/qalam-app-bd7d0/locations/us-east5/publishers/anthropic/models/claude-haiku-4-5@20251001:rawPredict"
# BEFORE Enable: 404 "...does not have access to it"   AFTER Enable: 200 with a Claude message
```

### Recommended routing table (env-driven; the live baseline + the gated upgrade)
```bash
# LIVE BASELINE (works today, keyless, us-central1) — ship this if Claude isn't enabled in time:
ANALYZE_MODEL=gemini-2.5-flash   ANALYZE_MODEL_PROVIDER=google_vertexai   # us-central1
PLAN_MODEL=gemini-2.5-flash      PLAN_MODEL_PROVIDER=google_vertexai      # us-central1
COACH_MODEL=gemini-2.5-flash     COACH_MODEL_PROVIDER=google_vertexai     # us-central1

# GATED UPGRADE for coach (only after Model-Garden Enable + eval win):
COACH_MODEL=claude-haiku-4-5@20251001   COACH_MODEL_PROVIDER=anthropic_vertex   COACH_LOCATION=global
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 14-AI-SPEC §4: coach via `model_provider="anthropic"` + Anthropic key in Secret Manager | Keyless Vertex for all nodes; Claude (if used) via `ChatAnthropicVertex`/ADC | D-02 (2026-06-29) + already live | No Anthropic key anywhere; `langchain-anthropic` is removable. |
| Claude ruled out on the client (ADR-014) | Claude available server-side via Vertex Model Garden (after Enable) | ADR-015 (2026-06-22) | Restores the warm-Claude voice option — but gated on Enable + region + eval. |
| Single `setLanguage` for a coach line | Segment-by-script + per-segment locale + availability check | this research | Correct mixed en/ar audio + graceful degrade. |

**Deprecated/outdated:**
- `server/.env.example` and `server/README.md` still describe the Anthropic-key path — **stale vs. the live keyless-Vertex deploy**; update as part of D-02.
- `claude-3-5-haiku@20241022` is marked **Deprecated** on Vertex; do not adopt it — use `claude-haiku-4-5@20251001`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Clicking **Enable** on the Claude Model Garden card grants the `qalam-app-bd7d0` project immediate keyless access (no quota/billing block on Technion credits). | D-03 / Pitfall 1 | If credits/quota block partner models, Claude coach is unavailable → fall back to Gemini coach (no demo impact). |
| A2 | `ChatAnthropicVertex.bind_tools(tool_choice="any")` reliably forces one tool call for the coach on Vertex. | Pitfall 3 | If it misbehaves, coach degrades to grounded `say` (already handled) or use the raw SDK / keep Gemini. |
| A3 | A stock Pixel Tablet has an installable (maybe not preinstalled) Arabic Google-TTS voice; en-US is present. | D-06 / Pitfall 4 | If no Arabic voice at all, the Arabic token is skipped (English guidance still spoken) — acceptable degrade. Must verify on-device. |
| A4 | `awaitSpeakCompletion(true)` sequences `speak()` calls on **Android** (README phrases it as iOS, but it gates the Dart completer on the engine's done-callback cross-platform). | Pattern 2 | If Android doesn't await, segments overlap → use `setQueueMode` / chain on the completion handler instead. Verify on-device. |
| A5 | The Vertex LLM-judge (D-09) can be a Gemini model (`gemini-2.5-flash`/`pro`) — no Claude needed for judging. | Validation / EVAL | If Gemini judging under-correlates with mom's gold labels (<0.7), use a stronger Vertex model (Gemini Pro, or Claude after Enable). |
| A6 | Latency/voice NUMBERS (PRES-01 budget, first-TTS start time, cold-start delta) are measured in-phase on the Pixel Tablet, not researched. | PRES-01 | Per ROADMAP hint=no; this is by design, not a gap. |

## Open Questions

1. **Will the owner Enable Claude in Model Garden before the Technion demo?**
   - What we know: it's a one-time, self-serve, immediate console click on an Owner-role project; Claude is otherwise unreachable.
   - What's unclear: whether it happens in time, and whether Technion credits cover partner-model billing.
   - Recommendation: plan a `checkpoint:human-verify` for the Enable; design the routing table so **all-Gemini is the shippable default** and Claude-coach is a drop-in env swap if Enabled + eval-won.

2. **Which Vertex model is the LLM-judge for register/Arabic (D-09)?**
   - What we know: it can differ from the coach; it calls Vertex; it must hit ≥0.7 correlation with mom's gold labels before it's trusted.
   - Recommendation: start with `gemini-2.5-flash` (already keyless in us-central1, zero new setup) as the judge; calibrate against the mom-signed gold set; escalate to `gemini-2.5-pro` (or Claude after Enable) only if correlation is weak. **Coach-under-test and judge should not be the same model instance** to avoid self-grading bias.

3. **First-TTS latency vs. the PRES-01 budget** — measured on-device (A6); the warm-up-ping + a possible TTS warm-up (a silent/empty `speak('')` at unit open) may be needed to avoid a cold first synthesis. Validate in-phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Vertex AI API (project qalam-app-bd7d0) | all coach inference | ✓ | enabled | — |
| Gemini on Vertex, us-central1 (keyless) | analyze/plan/coach baseline | ✓ (200 OK probed) | gemini-2.5-flash | — |
| Gemini on Vertex, us-east5 | region sanity for fallback | ✓ (200 OK probed) | gemini-2.5-flash | — |
| **Claude on Vertex (any region) for qalam-app-bd7d0** | D-03 Claude coach option | **✗ (404 "no access" — not Enabled)** | claude-haiku-4-5@20251001 | **Enable in Model Garden** (human) → then `global`; else keep Gemini coach |
| `flutter_tts` 4.2.5 | PRES-02 spoken coaching | ✓ (pub.dev) | 4.2.5 | — |
| Arabic Google-TTS voice on Pixel Tablet | speaking Arabic tokens | ? (device-dependent) | — | Skip ar token / install voice-data; speak en only |
| `gcloud` CLI + ADC | probing/deploy | ✓ (user token; deploy uses runtime SA) | present | — |
| slopcheck | pub.dev legitimacy | n/a (Dart not covered) | — | pub.dev metrics + blocking-human checkpoint |

**Missing dependencies with no fallback:** none that block the demo (all-Gemini ships).
**Missing dependencies with fallback:** Claude-on-Vertex (fallback: Enable, else Gemini coach); Arabic TTS voice (fallback: English-only spoken line).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework (server) | `pytest` 8.x + `pytest-asyncio` 0.24 (`asyncio_mode=auto`), marker `code` registered | `[CITED: server/pyproject.toml]` |
| Framework (client) | `flutter test` (widget/unit) — existing |
| Config file | `server/pyproject.toml` (`[tool.pytest.ini_options]`) |
| Quick run command | `cd server && uv run pytest -m code -q` (model-free, offline, gates every PR) |
| Full suite command | `cd server && uv run pytest -q` ; client: `flutter test` |
| Eval gate (NEW) | `make eval` → wraps the faithfulness (model-free) + the Vertex LLM-judge run; fails below threshold (D-07/D-08/D-10) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVAL-01 | Faithfulness rate over labeled set (zero-tolerance) | unit/code (model-free) | `uv run pytest server/tests/test_faithfulness.py -m code -x` | ✅ exists (grow it) |
| EVAL-01 | Register + correct-Arabic scored by Vertex LLM-judge vs rubric | integration (calls Vertex) | `make eval` → `uv run python server/tests/test_eval/run_judge.py` | ❌ Wave 0 |
| EVAL-02 | Gate fails the build below threshold (pre-merge) | gate | `make eval` exit-nonzero on D1<100% or D5/D2 below threshold | ❌ Wave 0 |
| EVAL-02 / D-13 | Coach bake-off Gemini-vs-Claude on the same labeled set | integration | `COACH_MODEL_PROVIDER=anthropic_vertex COACH_LOCATION=global make eval` vs Gemini run | ❌ Wave 0 |
| PRES-02 | Mixed-script segmentation + availability degrade (pure-Dart) | unit (no device) | `flutter test test/tutor/tts_coach_speaker_test.dart` | ❌ Wave 0 |
| PRES-01 / DEMO-01 | Warm-up ping + timeout→AuthoredFallback (no dead end) | code/fault-injection | existing `server/tests/test_endpoint.py` (503→fallback) + a `/health` test | ✅ partial |

### Sampling Rate
- **Per task commit:** `cd server && uv run pytest -m code -q` (faithfulness + grounding, model-free, <30s) + `flutter test` for touched client files.
- **Per wave merge:** full `uv run pytest -q` + `make eval` (the LLM-judge run, calibrated) + `flutter test`.
- **Phase gate:** `make eval` green (D1=100% faithfulness; D5/D2 ≥ threshold) + full suites green before `/gsd-verify-work`; PRES-01 latency budget measured + recorded on the Pixel Tablet.

### Wave 0 Gaps
- [ ] `server/tests/test_eval/` — labeled (verdict, learner-state) cases (grow from `faithfulness_set.jsonl`) + the Vertex LLM-judge runner (D-09/D-10)
- [ ] `server/Makefile` (or `server/tests/test_eval/run_eval.py`) — the `make eval` gate that exits non-zero below threshold (D-07/D-08)
- [ ] The **mom-signed gold set** file (Claude drafts → mother reviews+signs) — D-09; format is Claude's discretion (JSONL mirroring the existing fixture is the lowest-friction)
- [ ] `test/tutor/tts_coach_speaker_test.dart` — pure-Dart segmentation + degrade unit tests
- [ ] LLM-judge calibration record (≥0.7 vs mom labels) before the judge is trusted

## Security Domain

> `security_enforcement: true`, ASVS level 1, block-on: high. `[CITED: .planning/config.json]`

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | `/coach` already gated by Firebase ID token + App Check (`verify_caller`); unchanged. |
| V3 Session Management | no | Stateless server (ADR-015 §5). |
| V4 Access Control | yes | App Check limited-use token; warm-up `/health` is intentionally unauthenticated (no data, just a ping). |
| V5 Input Validation | yes | `TutorFactsIn` `extra="forbid"` (PII/stroke keys 422); the non-PII chokepoint (GROUND-02). Unchanged. |
| V6 Cryptography | no (this phase) | No new crypto; keyless ADC removes the Anthropic key surface entirely. |
| V8 Data Protection / Privacy | yes | COPPA: coach TEXT spoken on-device is non-PII; transcripts/labeled set must NOT train models without separate verifiable parental consent (D-10 / 14-AI-SPEC §1b). The eval gold set is synthetic/authored non-PII. |

### Known Threat Patterns for {Vertex keyless + on-device TTS + local eval}
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Supply-chain (new `flutter_tts` dep) | Tampering | Blocking-human package-legitimacy checkpoint (D-06), verified publisher + pinned version (mirrors audioplayers T-07-02-01). |
| Credential exposure | Information disclosure | Keyless ADC (D-02) — no Anthropic key in image/client/Secret Manager; remove leftover key refs. |
| Verdict contradiction via Claude coach | Tampering (grounding) | `coach.py` G2/G3/G4 guards already rewrite a fail-advance/out-of-set/unauthored action to a grounded `say`; provider-independent. |
| PII leak in coach line / TTS | Information disclosure | Server emits only non-PII derived facts → coach TEXT; TTS voices that text on-device; no new wire surface. |
| Eval-set used to train models | Privacy/compliance | D-10 constraint: no training/fine-tuning on child transcripts without separate parental consent; Vertex request-response logging off / no-training-use. |

## Sources

### Primary (HIGH confidence)
- **Live probe of project `qalam-app-bd7d0` Vertex AI** (2026-06-29): Gemini `generateContent` 200 in us-central1 & us-east5; Claude `rawPredict` 404 "no access" in us-central1/us-east5/global for `claude-haiku-4-5@20251001`, `claude-sonnet-4-5@20250929`, `claude-3-5-haiku@20241022`; caller = Owner; Vertex API enabled. — the decisive D-03 evidence.
- **Live Cloud Run service describe** `qalam-tutor` (2026-06-29): all 3 nodes `google_vertexai`/`gemini-2.5-flash`, `GOOGLE_CLOUD_LOCATION=us-central1`, `COACH_TIMEOUT_SECONDS=12` — D-02 already shipped.
- platform.claude.com/docs/en/build-with-claude/claude-on-vertex-ai — Vertex model-ID table (Haiku 4.5 = `claude-haiku-4-5@20251001`), keyless `AnthropicVertex` SDK, global/multi-region/regional endpoints, `anthropic_version: vertex-2023-10-16`. (2026-06-29)
- pub.dev API `/api/packages/flutter_tts` + `/score` + `/publisher` — version 4.2.5 (2026-01-05), verified publisher eyedeadevelopment.com, 1586 likes, 150/160 pts, ~267k/30d. (2026-06-29)
- github.com/dlutton/flutter_tts README — `awaitSpeakCompletion`, `isLanguageAvailable`/`areLanguagesInstalled`, `getVoices`, Android `<queries>` TTS_SERVICE, minSdk 21, Kotlin 1.9.10. (2026-06-29)
- Repo files read: `server/app/{models.py,nodes/coach.py,nodes/analyze.py,faithfulness.py,main.py,schema relations}`, `server/pyproject.toml`, `server/.env.example`, `server/Dockerfile`, `lib/tutor/remote_agent_brain.dart`, `lib/features/letter_unit/widgets/exercise_scaffold.dart`, `.planning/config.json`, ADR-014, ADR-015, 14-AI-SPEC, 16-CONTEXT, REQUIREMENTS.

### Secondary (MEDIUM confidence)
- docs.langchain.com/oss/python/integrations/chat/google_anthropic_vertex + reference.langchain.com `ChatAnthropicVertex` — `bind_tools`/`tool_choice`/`with_structured_output` support; `pip install -U langchain-google-vertexai anthropic[vertex]`.
- docs.cloud.google.com/.../partner-models/claude + .../claude/structured-outputs — Enable-in-Model-Garden flow; `constraints/vertexai.allowedPartnerModelFeatures` gates partner structured outputs.
- discuss.google.dev "developer's guide … Claude 4 on Vertex AI" — ADC keyless, us-east5 region, Enable-the-model step.
- Google Cloud blog: multi-region & global endpoints for Claude on Vertex (global = no premium, recommended).

### Tertiary (LOW confidence — flagged for in-phase device validation)
- flutter_tts issue #581 (Arabic "only picks english characters") — corroborates the single-`setLanguage`-fails-mixed conclusion; full thread not read.
- Pixel Tablet Arabic Google-TTS voice availability — general Android TTS support docs; **must be confirmed on the actual device** (A3).
- Community report of `ChatAnthropicVertex` tool-calling occasionally not working on Vertex (A2) — validate in the bake-off.

## Metadata

**Confidence breakdown:**
- D-03 Vertex/Claude reachability + region + ID + keyless: **HIGH** — live-probed the project's own endpoint; official model-ID table.
- Routing-table recommendation: **HIGH** — anchored to the live, working all-Gemini-keyless baseline.
- D-06 flutter_tts version/legitimacy/mixed-language pattern: **HIGH** (pub.dev + README); on-device voice availability & latency: **MEDIUM/LOW** — measured in-phase (ROADMAP hint=no).
- Eval-gate shape: **HIGH** — reuses existing pytest marker + fixture; LLM-judge model is a recommendation pending calibration.

**Research date:** 2026-06-29
**Valid until:** Vertex/Claude availability ~7–14 days (partner-model regions & IDs shift; re-probe before locking if planning slips). flutter_tts ~30 days. The live-deploy facts hold until the next `gcloud run deploy`.
