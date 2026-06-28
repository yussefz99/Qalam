# Phase 16: BUILD — presence + voice + eval gate + demo-harden - Context

**Gathered:** 2026-06-29
**Status:** Ready for planning
**Source:** ROADMAP.md Phase 16 (PRES-01, PRES-02, EVAL-01, EVAL-02, DEMO-01) + the v2.0
milestone spike→build linkages (Phases 12/13 unrun) + ADR-014/ADR-015 + 14-AI-SPEC + the
Phase 15 dynamic-grounded baa flow being voiced/hardened.
**Mode:** mvp (vertical slices)

<domain>
## Phase Boundary

The **final BUILD phase of the v2.0 AI-tutor milestone.** Take Phase 15's dynamic, grounded,
resume-aware baa flow and make it:

1. **Feel present (PRES-01/02)** — the tutor *speaks* its coaching (on-device TTS) a beat after
   the instant on-screen feedback, on both pass and miss, while the millisecond stroke reflex
   stays local; the full stroke→scorer→server→render→first-TTS path is measured on a real Pixel
   Tablet and meets a written latency budget.
2. **Guarded (EVAL-01/02)** — the Phase-15 model-free faithfulness check is grown into a real
   eval harness scoring four dimensions and run as a documented **pre-merge regression gate**.
3. **Demo-hardened (DEMO-01)** — the baa AI-tutor path (client + Cloud Run server) is bulletproof
   on the Pixel-Tablet build: no dead ends, graceful offline/timeout fallback to the authored floor.
4. **Settled** — the per-node model choices (analyze/plan/coach) are finalized from an inline
   Claude-vs-Gemini comparison, all routed through Vertex AI.

**Folded into this phase (were Phases 12 & 13, never run):** the latency-budget measurement
(was Phase 12) and the coach-model bake-off (was Phase 13) are done as **lean inline steps** of
Phase 16, not separate phases (D-01).

**NOT in this phase:** premium/cloud TTS voice (on-device is the baseline — deferred upgrade);
GitHub Actions CI (local pre-merge gate now); on-device Gemma backend (stays deferred); voice
input / STT (S2-03); cross-letter ب/ت/ث contrast; any letter other than baa; parent analytics;
durable server-side child memory.
</domain>

<decisions>
## Implementation Decisions

### Spike fold-in & model routing (latency budget + coach-model verdict)
- **D-01:** **Fold lean Phase-12 + Phase-13 work into Phase 16** — no separate spike phases (the
  Technion timeline can't carry two more phases before the finale). Measure the real
  stroke→scorer→**client→Cloud Run→model→back**→render→**first-TTS** path **on the Pixel Tablet
  while demo-hardening** → produce the **written latency budget** PRES-01 is measured against
  (incl. the Cloud Run cold-start-vs-warm delta). Run a **small Claude-vs-Gemini coach
  comparison on the EVAL-01 harness** (built here anyway) → the per-node model verdict (SC#4).
  This is the "de-risk on the live system" the roadmap intended, done in-phase.
- **D-02:** **ALL tutor nodes (analyze / plan / coach) route through Vertex AI — keyless, on the
  Technion credits** (same posture as the already-deployed Gemini-on-Vertex setup). **No Anthropic
  API key anywhere** — this **supersedes 14-AI-SPEC §4's `model_provider="anthropic"` +
  Anthropic-key-in-Secret-Manager path.** A nice security simplification: nothing keyed.
- **D-03:** **Coach = the strongest-Arabic-register model available *on Vertex*,** chosen by the
  eval (D-09). **Default to `claude-haiku-4-5` IF reachable on Vertex Model Garden in the
  project's region**; if not reachable in-region, fall back to the best Vertex-available Claude,
  or **Gemini if it wins the Arabic eval.** **Research MUST verify Vertex reachability + region
  for the candidate Claude model(s) before the planner locks the routing table** (Gemini-on-Vertex
  is already proven on this project).

### Voice / TTS (PRES-02)
- **D-04:** **On-device TTS via `flutter_tts`** (the Pixel's built-in voices). It voices **both
  the live agent line AND the `AuthoredFallback` floor**, so coaching **speaks in airplane mode**
  (TUTOR-02). Lowest **first-TTS** latency (no extra network hop → helps the PRES-01 budget); no
  cloud TTS cost. Premium/cloud TTS (warmer voice) is a **deferred** future upgrade, not the demo
  baseline.
- **D-05:** **Rhythm — the two clocks.** The millisecond stroke reflex + scorer verdict render
  **instantly on-screen (local, silent)**; the **spoken** coaching arrives **a beat later, on
  BOTH a clean pass** (warm praise — e.g. "أحسنت — that curve is perfect") **and a miss** (the
  specific fix). The **whole short line** (1–2 sentences) is spoken; token-by-token text streaming
  + incremental TTS is **optional / nice-to-have, not required** (the line is short; 14-AI-SPEC
  §4b.2 flags forced-tool-call streaming as provider-dependent).
- **D-06:** `flutter_tts` is a **new package → subject to the project's package-legitimacy
  checkpoint** (autonomous:false gate, as used for `audioplayers` / `crypto`). **Mixed
  English+Arabic locale-switching within one utterance** is a known pitfall to research and handle
  (the coach line is mostly the child's working language with occasional Arabic words/letter names).

### Eval regression gate (EVAL-01 / EVAL-02)
- **D-07:** The gate is a **LOCAL documented pre-merge step** (`make eval` / a pytest run), **not
  CI** — EVAL-02 explicitly allows "a documented pre-merge step." It can graduate to GitHub Actions
  CI later; standing CI up (service-account Vertex auth in CI) is **out of scope** now.
- **D-08:** **Faithfulness is a ZERO-TOLERANCE hard gate.** Any praise-on-fail or wrong-fix (a
  coach line that contradicts the geometry verdict) **fails the build** — it's the grounding safety
  invariant (ADR-014). This dimension is **model-free** and **grows the Phase-15 `app/faithfulness.py`
  seed** (15-06).
- **D-09:** **Register-for-a-5–10-year-old + correct-Arabic** are scored by a **Vertex LLM-judge**
  against a rubric, **calibrated to a small mom-signed gold set.** Claude **DRAFTS** the gold
  (verdict → ideal-coaching) examples covering baa's mistakes × pass/fail; the **owner's mother
  REVIEWS + SIGNS** (her register authority — same gate as the curriculum sign-off; nothing
  register-shaping ships unsigned). These two dimensions gate on a **threshold** (not zero-tolerance).
- **D-10:** The harness runs the coach over labeled **(verdict, learner-state)** cases and reports
  **per-dimension scores** for all four 14-AI-SPEC §5 dimensions (never-contradicts-geometry,
  names-the-specific-fix, register, correct-Arabic). It **is the reusable seed** the roadmap
  assigned to Phase 13 — promoted here, not a throwaway. **Regulatory note (14-AI-SPEC §1b):** the
  labeled set / any logged transcripts must **not** be used to train/fine-tune models without
  separate verifiable parental consent.

### Demo-harden (DEMO-01)
- **D-11:** The live demo runs the **REAL online agent (Vertex)**, with a **session-start warm-up
  ping** to defeat **Cloud Run cold-start** (`qalam-tutor` idles at min-instances=0 — the folded-in
  Phase-12 mitigation), and the **`AuthoredFallback` floor as an INVISIBLE auto safety net** that
  silently takes over on any timeout/drop — **never a dead end or a hang on stage.** (A one-tap
  manual "switch to offline" control was considered as belt-and-suspenders — optional, Claude's
  discretion whether to add.)
- **D-12:** **Hero moment = grounded adaptivity.** Seed a **known starting state** where the child
  "wobbles" on a form → the tutor **re-surfaces an easier exercise (backward remediation** — the
  clearest visible dynamism, per Phase 15) → **speaks the specific fix** → earns **one quiet star**
  at mastery. Needs a **reliable seeded demo state** so the moment fires **on cue, repeatably.** The
  **grounding guarantee** (a wrong-stroke-order attempt gets the right fix; the agent **never fakes a
  pass**) is a strong **second beat** for the technical Technion audience.
- **D-13:** Demo path = **Home/Journey → baa unit → mastery star** on the **Pixel-Tablet build**;
  no dead ends, no stuck states; graceful offline/timeout fallback to authored lines (DEMO-01 accept).

### Claude's Discretion
- The exact **latency budget numbers** (come from the on-device measurement, not pre-set); whether
  to add **SSE text streaming** (optional per D-05); the **warm-up-ping mechanism + timing**; the
  **seeded-demo-state mechanism** (a debug/demo seed); the **LLM-judge prompt/rubric + gold-set size
  & file format**; whether to add the **one-tap manual demo fallback** (D-11); `flutter_tts` config
  (voice, rate, pitch, locale switching); the eval-gate `make`/pytest harness shape; Riverpod wiring;
  where the latency instrumentation lives.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 16 spec sources
- `.planning/ROADMAP.md` — Phase 16 details (v2.0 milestone): goal, the 4 success criteria, and the
  spike→build linkages that explain why 12/13's outputs are needed here.
- `.planning/REQUIREMENTS.md` — PRES-01, PRES-02, EVAL-01, EVAL-02, DEMO-01 acceptance criteria +
  v2.0 traceability.

### The AI-tutor spine (locked — do NOT relitigate)
- `docs/architecture/ADR-014-v2-tutor-agent-architecture.md` — the **grounding invariant**: the
  scorer owns pass/fail + the star; the agent owns only the words and the sequence. **Voice/TTS is
  display-only and can never imply a pass.**
- `docs/architecture/ADR-015-v2-tutor-server-langgraph-agent.md` — server topology/framework;
  enables mature server-side streaming (the presence work builds on this).
- `.planning/phases/14-build-tutorbrain-spine-grounding-invariant/14-AI-SPEC.md` — **§4** per-node
  model routing (**NOTE: §4's Anthropic-key path is SUPERSEDED by D-02 — all Vertex, keyless**);
  **§4b.2** "stream only the coach turn" guidance; **§5** the eval dimensions/rubrics the gate grows
  from; **§1b** domain context + the **no-training-on-child-transcripts** regulatory constraint.
- `.planning/phases/14-build-tutorbrain-spine-grounding-invariant/14-CONTEXT.md` — Phase 14 spine
  decisions this phase builds on.
- `.planning/phases/15-build-dynamic-grounded-exercise-selection-on-baa/15-CONTEXT.md` — the dynamic
  selection + curriculum graph + faithfulness-seed decisions this phase voices/hardens; **its
  "roadmap-sequencing flag" (Phases 12/13 unrun) is the question D-01 resolves.**

### Code seams to extend
- `server/app/main.py` — the `/coach` endpoint (today returns a **single JSON `CoachOut`** — no
  streaming yet; presence work adds streaming of the coach turn IF pursued, plus the warm-up path).
- `server/app/models.py` + `server/app/nodes/{analyze,plan,coach}.py` — the per-node model routing
  table → **switch all providers to Vertex** (D-02); coach model per D-03.
- `server/app/faithfulness.py` + `server/tests/test_faithfulness.py` — the **model-free faithfulness
  check (Phase 15 / 15-06)** the zero-tolerance gate grows from (D-08).
- `server/tests/` (+ a new `server/tests/test_eval/` set per 14-AI-SPEC §3 structure) — where the
  gate, the labeled cases, and the mom-signed gold set live.
- `lib/tutor/remote_agent_brain.dart`, `lib/tutor/authored_fallback_brain.dart`,
  `lib/tutor/tutor_dispatcher.dart` — the client seam: TTS hooks in here; the floor fallback (D-11)
  already lives here.
- `lib/providers/audio_providers.dart` + `lib/services/asset_audio_player.dart` — the **existing
  audio seam** (bundled `audioplayers` clips, S1-06). **TTS is a SEPARATE coaching-voice surface**
  alongside it — S1-06's "no TTS" applies only to letter/word *pronunciation*, not the coach voice.
- `lib/features/letter_unit/` + `exercise_scaffold` — where the coach line surfaces and the spoken
  line plays (a beat after the visual, on pass/miss — D-05).

### Deployment / infra
- Cloud Run service **`qalam-tutor`** (project `qalam-app-bd7d0`, `us-central1`), **keyless Gemini
  on Vertex AI** (Technion credits), **min-instances=0 when idle → cold-start** (the D-11 warm-up-ping
  target). Google edge reserves `/healthz` → the health route is `/health`.

### Curriculum / register authority
- `docs/curriculum/national-curriculum-grade1.md` + the signed baa curriculum graph (Phase 15) —
  the source of truth the gold-set coaching examples (D-09) must stay consistent with.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`AuthoredFallback` floor (Phase 14):** already the offline/timeout fallback. D-11 makes it the
  **invisible demo safety net**; D-04 makes it **speak** via on-device TTS.
- **`app/faithfulness.py` (Phase 15 / 15-06):** the model-free praise-on-fail / wrong-fix check
  (currently 69%). The **zero-tolerance gate (D-08) grows it** — no new faithfulness engine needed.
- **The deployed keyless-Vertex server (Phase 14):** proves the **keyless-Vertex posture** that D-02
  extends to **all** nodes (including the coach, dropping the Anthropic-key path).
- **The eval-harness intent (14-AI-SPEC §5):** EVAL-01 builds it; D-03's Claude-vs-Gemini comparison
  rides on the same harness.
- **The `audioplayers` seam + its legitimacy gate:** the pattern for adding `flutter_tts` + its
  package-legitimacy checkpoint (D-06).

### Established Patterns
- **Grounding invariant (ADR-014):** the scorer owns the star → voice/TTS is display-only, never a
  verdict.
- **Non-PII chokepoint (GROUND-02):** only derived facts cross the wire — unchanged; TTS voices the
  (non-PII) coach **text** on-device.
- **Model-drafts / mother-signs sign-off gate:** the curriculum pattern — D-09's gold set follows it.
- **Anti-gamification:** one quiet star; the voice stays warm/specific, **never hype** (PLAT-03).
- **Package-legitimacy checkpoint (autonomous:false)** for new deps (D-06 / `flutter_tts`).

### Integration Points
- Server coach turn → (optional stream) → client → **on-device TTS** → plays a beat after the visual
  (D-05).
- **EVAL harness** → faithfulness (model-free, **zero-tolerance**) + **Vertex LLM-judge** (register /
  Arabic, **threshold**) → pass/fail gate (`make eval`).
- **Warm-up ping** at session start → Cloud Run warm → demo round-trip within the measured budget.
- **Seeded demo state** → backward remediation fires on cue (D-12).
- All nodes → **Vertex AI provider** (keyless) — the routing-table change of D-02/D-03.
</code_context>

<specifics>
## Specific Ideas

- **Demo hero line (from Phase 15):** "watch the tutor re-surface the isolated trace because she's
  still wobbling on the medial form" — now **voiced** + **seeded** to fire reliably on stage (D-12).
- **Keep everything keyless:** Vertex + Technion credits means **no API keys anywhere** (analyze /
  plan / coach all on Vertex) — the owner's explicit framing of the routing decision.
- **Best-Arabic model wins the coach voice** — the voice is the product's signature, so the eval's
  Arabic-register score is the deciding criterion (within what Vertex offers).
- **The audience is technical Technion staff** — the grounding guarantee ("how do you keep the LLM
  honest?") is a deliberate second demo beat, not just polish.
</specifics>

<deferred>
## Deferred Ideas

- **Premium / cloud TTS voice** (warmer, more natural, closer to a real teacher) — a future
  voice-quality upgrade; on-device TTS is the demo baseline (D-04).
- **Token-by-token text streaming + incremental TTS** — optional; whole-line is the baseline (D-05).
- **GitHub Actions CI for the eval gate** — local pre-merge now; graduate to CI later (D-07).
- **One-tap manual demo fallback control** — considered as belt-and-suspenders; optional, Claude's
  discretion (D-11).
- **On-device `GemmaBrain` coach backend (TUTOR-04)** — stays deferred/experimental, never on the
  demo's critical path; the swappable `TutorBrain` seam keeps a future Gemma backend possible.
- **Voice input / STT (S2-03), cross-letter ب/ت/ث contrast unit, parent struggle-analytics** — out
  of v2.0 scope; future milestones.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>

---

*Phase: 16-build-presence-voice-eval-gate-demo-harden*
*Context gathered: 2026-06-29*
