# Requirements: Qalam

> Spans milestones. **v1 — Core Learning Loop** (below) is the shipped/in-flight base.
> **v2.0 — AI Tutor (Technion build)** is the **current milestone**; its requirements
> and traceability are in their own sections further down.

**Defined:** 2026-05-30
**Core Value:** A child traces an Arabic letter, gets immediate specific feedback on their actual strokes, and advances through a real teacher's curriculum — so the language sticks through the hand.

v1 = the owner's **Sprint 1** (`docs/USER_STORIES.md`), built as written. Local-only,
on-device, no auth, **no Claude AI tutor** (the tutor is the v2 milestone). Story IDs
(S1-xx) are preserved as canonical requirement IDs; derived technical requirements use
CUR-/PLAT- IDs.

## v1 Requirements

### Onboarding & Profiles

- [x] **S1-02**: A parent can create a child profile with name and grade, and the grade selects the curriculum entry point
  - *Accept:* profile persists locally; grade maps to a starting lesson; no real-name exposure beyond the device (minimum child data)
- [x] **S1-03**: A child can pick an avatar and nickname on first open
  - *Accept:* selection persists; choices are from a fixed set (no free-text that leaks identity); shown on the home screen

### Daily Lesson & Progression

- [x] **S1-01**: On opening the app, the child immediately sees today's lesson already prepared, with one clear way to start
  - *Accept:* landing shows the next unlocked lesson for the current child; a single prominent Start; no navigation required
- [x] **S1-09**: The next lesson unlocks only after the child passes the current one
  - *Accept:* "pass" = the curriculum's clean-reps-to-advance for that item; locked lessons are visibly unavailable; unlock is immediate on pass

### Handwriting Practice (the core loop)

- [x] **S1-04**: Before writing a letter, the child can watch (and replay) an animation of the correct stroke order
  - *Accept:* animation is driven by the same reference stroke paths used for scoring; replayable; plays per letter and per contextual form
- [x] **S1-05**: The child traces letters with a stylus and receives instant on-device feedback on shape and stroke order
  - *Accept:* feedback evaluates stroke count, order, direction, and shape match; the failing stroke is highlighted; the message names the specific fix using the letter's curriculum "common mistakes"; feedback appears < ~300 ms after stylus-up, fully offline; built on a custom geometric scorer (ML Kit used only as a secondary letter-identity check)
- [ ] **S1-10**: The child earns a mastery star when they complete a lesson
  - *Accept:* a star marks **real mastery** (earned via the curriculum's clean-reps), shown on the journey map as progress; a single dignified celebration at mastery; NO running totals, NO weekly tallies, NO streaks/badges, no "+N keep going" hype

### Audio

- [ ] **S1-06**: The child can hear the correct pronunciation of each letter and word
  - *Accept:* tappable audio per letter and per word; bundled pre-recorded clips (works offline); no TTS

### Exercises

- [ ] **S1-07**: The child can complete sentence-building exercises that show how Arabic words connect to form meaning
  - *Accept:* handwriting-first interaction (never reduces to tap-one-of-four); content comes from the curriculum schema
- [ ] **S1-08**: The child can complete grammar exercises at their level
  - *Accept:* level-appropriate per the child's progression; handwriting-first; content authored in the curriculum, not invented

### Parent View

- [x] **S1-11**: A parent can see the child's completed lessons and scores
  - *Accept:* PIN-gated parent area; read-only local progress (lessons completed, scores); no cloud, no account

### Curriculum Content & Platform (derived from research)

- [x] **CUR-01**: The full curriculum (28 letters + words + sentences + grammar) authored by the owner's mother is held in a faithful data schema that the code only reads
  - *Accept:* schema holds, per letter: contextual forms, ordered reference stroke paths (coordinates), stroke order, intro order, clean-reps-to-advance, per-letter pass tolerances, 3–4 common mistakes (each with a child-friendly fix message), and audio references; words/sentences/grammar content modeled; placeholder entries (if any) are explicitly marked; owner's-mother sign-off gate before lessons ship
- [x] **PLAT-01**: The app runs fully offline, local-only, with no account or login (satisfies NTH-05 by design)
  - *Accept:* every v1 flow works airplane-mode; the ML Kit Arabic model is fetched once at onboarding then cached; verified on a fresh install with no network
- [x] **PLAT-02**: Arabic renders correctly RTL with connected-script shaping
  - *Accept:* correct isolated/initial/medial/final forms; the dotted guide letter is drawn from reference paths (not a Text widget); chosen font glyph-audited across all curriculum letters and forms; numeral system chosen explicitly
- [x] **PLAT-03**: The experience stays not-points-chasing and on-brand (per `docs/design/kit/`)
  - *Accept:* no running star totals, no weekly tallies, no streaks, no badges, no confetti spam, no timed tests, no over-praise of sloppy work; feedback is specific, not generic "Oops, try again". The **Qalam mascot is the tutor's persona** (in), and **mastery stars** + a dignified per-mastery celebration + the journey map are in. Visuals follow the design system tokens (gold = rewards-only, coral not red, no emoji/unicode pseudo-icons)

## v2.0 Requirements (AI Tutor — Technion build) — CURRENT MILESTONE

The client-side, grounded AI agent-tutor, proven on one letter family (**baa**). A demo-scoped
slice of the full Sprint-2 AI Tutor: the server brain, placement exam, voice-in (STT), and
parent analytics remain deferred (see Future Requirements). New REQ-IDs below; phases continue
numbering from the v1 roadmap (start at Phase 11). Traceability filled by the v2.0 roadmap.

### Tutor Brain & Agent

- [ ] **TUTOR-01**: A child's tutor is driven by a swappable `TutorBrain` with three backends (Authored / Gemini / Gemma), selected without changing the durable canvas/scorer/curriculum layers
  - *Accept:* the backend is chosen behind one interface; durable layers carry zero GenUI/A2UI/firebase_ai imports; swapping the backend changes no widget or scorer code
- [ ] **TUTOR-02**: The tutor works fully offline with no model loaded — the `AuthoredFallback` floor coaches from the owner's-mother signed-off lines
  - *Accept:* airplane-mode, zero model: every coaching moment still shows a grounded, correctly-Arabic authored line; the practice/trace loop never blocks
- [ ] **TUTOR-03**: When online, the `GeminiBrain` (Firebase AI Logic + App Check) provides the adaptive coaching, and auto-degrades to the floor on offline/timeout
  - *Accept:* the Gemini API key never ships in the client (proxied + App-Check-gated); a network failure or timeout silently falls back to authored lines, never a dead end
- [ ] **TUTOR-04**: An on-device `GemmaBrain` backend exists behind the same interface as an evaluated candidate
  - *Accept:* GemmaBrain runs on-device via flutter_gemma/MediaPipe; its adoption is gated by the spike bake-off, not assumed; it is never on the demo's critical path
- [ ] **TUTOR-05**: The agent acts only through ACTION tools (`present_activity`, `say`, `give_hint`, `advance`); the geometry verdict and learner state are injected as FACTS, never exposed as tools
  - *Accept:* tools are actions; facts (mistakeId, struggles, letterId, current section) arrive in the model's context; the model cannot "ask" for a verdict or fabricate one

### Grounding & Child-Safety

- [ ] **GROUND-01**: The scorer owns pass/fail and the star; the agent may rephrase or coach but can never override or contradict the verdict
  - *Accept:* the pass/fail + star is decided by the deterministic scorer at the `ExerciseController` seam; the agent only supplies the displayed line; no agent path can flip a fail to a pass
- [ ] **GROUND-02**: Only derived, non-PII facts (mistakeId, struggle tags, letterId) ever cross the network — never raw strokes, never nickname/PII — enforced automatically
  - *Accept:* a guard/test fails the build if raw stroke coordinates or any PII field can reach the network payload
- [x] **GROUND-03**: Grounding faithfulness is measurable — the harness detects any model claim that contradicts the geometry
  - *Accept:* given a fixed scorer verdict, the harness flags coaching that praises a failed stroke or names the wrong fix; a faithfulness rate is reported

### Dynamic Teaching

- [x] **DYN-01**: The agent selects the next exercise from baa's authored configs, reasoning about the child's recent mistakes; the curriculum rails the choices
  - *Accept:* the agent can only pick valid, signed-off baa configs; its choice visibly responds to recent mistakeIds/struggles, not a fixed order
- [x] **DYN-02**: The dynamic, resume-aware flow replaces the fixed section walk for the baa unit end-to-end
  - *Accept:* entering the baa unit runs the agent-driven flow (not `LetterUnitController`'s static sequence); resume still works; one quiet star at mastery

### Presence & Voice

- [ ] **PRES-01**: The tutor feels present — coordination stays within a defined latency budget on a real Pixel Tablet, and the millisecond stroke reflex stays local
  - *Accept:* a written budget for stroke→scorer→agent→render→first-TTS is met on-device; instant stroke feedback/nudges never route through the agent
- [ ] **PRES-02**: The tutor speaks — streamed/TTS coaching plays at the right moments and degrades gracefully offline
  - *Accept:* coaching is spoken (or streamed) on pass/miss; offline/timeout falls back to text without breaking the flow

### Evaluation

- [ ] **EVAL-01**: An eval harness scores tutor quality on grounding faithfulness + Arabic coaching register against a labeled set
  - *Accept:* a reusable harness runs the brain over labeled (verdict, learner-state) cases and scores never-contradicts-geometry, names-the-specific-fix, register-for-a-5-10-year-old, correct-Arabic
- [ ] **EVAL-02**: The harness runs as a regression gate that catches tutor-quality regressions before they ship
  - *Accept:* the harness runs in CI (or a documented pre-merge step) and fails on a regression below threshold

### Demo Readiness

- [ ] **DEMO-01**: The baa AI-tutor path is demo-hardened for the live Technion meeting
  - *Accept:* no dead ends or stuck states; graceful offline/timeout fallback to authored lines; stable on the Pixel-Tablet build end-to-end (Home/Journey → baa unit → mastery star)

## Future Requirements (full AI Tutor — deferred beyond the Technion build)

The remaining Sprint-2 scope, **not** in the v2.0 roadmap. The Technion build is a client-side,
demo-scoped slice; these bring in the server-side A2UI brain + its framework, cloud sync, and
the second adaptation timescale.

### AI Tutor & Adaptation

- **S2-01**: Placement exam on first join to set the correct level across subjects
- **S2-02**: The Qalam character gives specific spoken feedback (in English) on exactly what was wrong
- **S2-03**: The child can press a button and ask Qalam a question out loud
- **S2-04**: Qalam gives extra practice on the topics/letters the child keeps getting wrong
- **S2-05**: The app adjusts the daily lesson based on recent performance
- **S2-06**: A parent can see which specific topics and letters the child struggles with
- **S2-07**: A parent can set a daily practice-duration goal
- **S2-08**: Vocabulary flashcards with pictures
- **S2-09**: Short Arabic reading passages with comprehension questions
- **S2-10**: A parent receives a weekly progress report

*(These bring in Firebase Auth, Firestore cloud sync, and Python Cloud Functions, plus the across-session nightly profile compiler.)*

## Out of Scope

Explicitly excluded for v1. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Daily streaks (NTH-01) | Pressure mechanic — contradicts anti-gamification |
| Badges (NTH-02) | Pressure mechanic — contradicts anti-gamification; only the gentle star (S1-10) is allowed |
| Reminder notifications (NTH-03) | Pressure mechanic; backlog |
| Multiple children under one account (NTH-04) | Needs auth; revisit after v2 introduces accounts |
| Teacher dashboards / lesson assignment (NTH-06, NTH-07) | Backlog; not a near-term goal |
| Tap-the-answer / multiple-choice foreign-language drills | The anti-product Qalam positions against |
| Cartoon mascot, confetti, timed tests | Anti-gamification |
| iOS (deployment, PencilKit) | Android-only for now |
| Any backend (Firebase Auth/Firestore/Functions), Claude tutor | Deferred to v2 |

## Traceability

Which phase covers which requirement. Each v1 requirement maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLAT-02 | Phase 1 — Foundations & RTL Shell | Complete |
| CUR-01 | Phase 7 — Full Curriculum & Pronunciation Audio (seeded in Phase 2) | Complete |
| S1-04 | Phase 3 — Trace One Letter End-to-End | Complete |
| S1-05 | Phase 3 — Trace One Letter End-to-End (deepened in Phase 4) | Complete |
| S1-10 | Phase 3 — Trace One Letter End-to-End | Pending |
| PLAT-03 | Phase 3 — Trace One Letter End-to-End | Complete |
| S1-02 | Phase 5 — Profiles & Onboarding | Complete |
| S1-03 | Phase 5 — Profiles & Onboarding | Complete |
| S1-01 | Phase 6 — Lesson Progression & Home | Complete |
| S1-09 | Phase 6 — Lesson Progression & Home | Complete |
| S1-06 | Phase 7 — Full Curriculum & Pronunciation Audio | Pending |
| S1-07 | Phase 8 — Sentence-Building & Grammar Exercises | Pending |
| S1-08 | Phase 8 — Sentence-Building & Grammar Exercises | Pending |
| S1-11 | Phase 9 — Parent Dashboard | Complete |
| PLAT-01 | Phase 10 — Offline Hardening & Release | Complete |

**Notes:**

- **CUR-01** is *seeded* in Phase 2 (small signed-off subset that unblocks the end-to-end slice) and *fully satisfied* in Phase 7 (all 28 letters + words). It maps to Phase 7 for coverage.
- **S1-05 / PLAT-03** are first delivered in Phase 3 and *deepened* in Phase 4 (scorer calibration) — counted under Phase 3 for coverage.
- **PLAT-03 (anti-gamification)** is cross-cutting; its acceptance is folded into Phase 3 (feedback tone, quiet star) and re-checked in every UI phase rather than owning a standalone phase.

**Coverage:**

- v1 requirements: 15 total (11 stories + 4 derived)
- Mapped to phases: 15 ✓
- Unmapped: 0 ✓

## v2.0 Traceability (AI Tutor — Technion build)

Which phase covers which v2.0 requirement. Each v2.0 requirement maps to exactly one phase.
Phases 11–13 are **spikes** — de-risking investigations that own **no requirement by design**
(their findings feed the build phases via the GATE/decision/harness noted below).

| Requirement | Phase | Status |
|-------------|-------|--------|
| TUTOR-01 | Phase 14 — TutorBrain spine + grounding invariant | Pending |
| TUTOR-02 | Phase 14 — TutorBrain spine + grounding invariant | Pending |
| TUTOR-03 | Phase 14 — TutorBrain spine + grounding invariant | Pending |
| TUTOR-04 | Phase 14 — TutorBrain spine + grounding invariant | Pending |
| TUTOR-05 | Phase 14 — TutorBrain spine + grounding invariant | Pending |
| GROUND-01 | Phase 14 — TutorBrain spine + grounding invariant | Pending |
| GROUND-02 | Phase 14 — TutorBrain spine + grounding invariant | Pending |
| DYN-01 | Phase 15 — Dynamic grounded exercise selection on baa | Complete |
| DYN-02 | Phase 15 — Dynamic grounded exercise selection on baa | Complete |
| GROUND-03 | Phase 15 — Dynamic grounded exercise selection on baa | Complete |
| PRES-01 | Phase 16 — Presence + voice + eval gate + demo-harden | Pending |
| PRES-02 | Phase 16 — Presence + voice + eval gate + demo-harden | Pending |
| EVAL-01 | Phase 16 — Presence + voice + eval gate + demo-harden | Pending |
| EVAL-02 | Phase 16 — Presence + voice + eval gate + demo-harden | Pending |
| DEMO-01 | Phase 16 — Presence + voice + eval gate + demo-harden | Pending |

**Spike → build linkages (spikes own no REQ-IDs):**

- **Phase 11 (SPIKE)** — GenUI-vs-native-canvas kill-shot. Output: the GATE (keep GenUI vs drop to raw firebase_ai) that decides the architecture **Phase 14** builds.
- **Phase 12 (SPIKE)** — full-path latency/presence on Pixel Tablet. Output: the written latency budget + model/transport choice **PRES-01** is measured against in **Phase 16**.
- **Phase 13 (SPIKE)** — Authored vs Gemini vs Gemma bake-off on grounding + Arabic. Output: the seed harness promoted to the **EVAL-01/EVAL-02** gate, the first **GROUND-03** faithfulness method, and the **TUTOR-04** Gemma-adoption decision (finalized in Phase 16).

**Coverage:**

- v2.0 requirements: 14 total (TUTOR-01..05, GROUND-01..03, DYN-01..02, PRES-01..02, EVAL-01..02, DEMO-01)
- Mapped to phases (14–16): 14 ✓
- Each mapped exactly once: ✓ (Phase 14 → 7, Phase 15 → 3, Phase 16 → 4 = 14 ✓)
- Unmapped: 0 ✓
- Spikes (11–13) owning no requirement, by design: ✓

---
*Requirements defined: 2026-05-30*
*Last updated: 2026-06-21 after v2.0 roadmap creation (v2.0 traceability populated; v1 traceability untouched)*
