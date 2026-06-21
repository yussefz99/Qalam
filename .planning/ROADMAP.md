# Roadmap: Qalam — v1 Core Learning Loop

## Overview

Qalam v1 delivers the handwriting-first learning loop: a child traces an Arabic
letter with a stylus, gets immediate specific on-device feedback on shape and stroke
order, and advances through the owner's-mother's curriculum — local-only, offline, no
account, no cloud, no AI tutor (that is v2). This roadmap is built as **vertical
slices**: we get a thin "trace one real letter end-to-end with on-device feedback and
a quiet star" capability working early, then thicken scoring quality, layer on
profiles, progression, the full curriculum + audio, the sentence/grammar exercises,
and finally the parent dashboard and offline hardening. The deepest-risk work — the
**custom geometric stroke scorer** that ML Kit does NOT provide — is isolated and
flagged. The curriculum schema and its reference-stroke-path format (an upstream open
question requiring the owner's-mother sign-off) is surfaced in the first slice that
needs it.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundations & RTL Shell** - Runnable RTL app skeleton with Arabic font, routing, theme, and local DB; resolves the connected-script rendering question. (completed 2026-05-31)
- [x] **Phase 2: Curriculum Schema & First-Letter Seed** - A faithful curriculum data schema plus a small owner's-mother-signed-off seed (forms, reference stroke paths, common mistakes) for the first letters. (completed — commit 419cc21) <!-- reconciled 2026-06-11: all 3 plans have SUMMARY files; curriculum_repository + models exist in lib/. Checkbox was stale. -->
- [x] **Phase 02.1: Stroke Reference Correction** (INSERTED) - Replace broken glyph-outline reference strokes with correct open-centerline teaching strokes; in-app authoring trace screen, schema `type` field + closed-loop validator, and a re-signed-off alif. Unblocks Phase 3. (completed 2026-06-01)
- [x] **Phase 3: Trace One Letter End-to-End** - A child can watch the stroke-order animation, trace a real seeded letter, get on-device geometric feedback, and earn a quiet star — the whole loop, thin. (completed — commit 3761794, "151 tests pass") <!-- reconciled 2026-06-11: all 6 plans (03-00..03-05) have SUMMARY files; geometric_stroke_scorer + letter_scorer exist in lib/. Checkbox was stale. -->
- [ ] **Phase 03.1: Journey Map Screen** (INSERTED) - Winding-path progress view showing all 28 letters as nodes; mocked progress data; pulse animation on current letter; tap to practice; unlocked from Home nav.
- [ ] **Phase 4: Scoring Quality & Calibration** - The scorer rejects wrong-order/sloppy work and accepts good-faith child attempts, with per-letter tolerances calibrated against real child samples with the owner's mother.
- [ ] **Phase 5: Profiles & Onboarding** - A parent creates a local child profile (name + grade), and the child picks an avatar and nickname on first open.
- [x] **Phase 6: Lesson Progression & Home** - On open the child sees today's prepared lesson with one Start; the next lesson unlocks only after passing the current one. (completed 2026-06-13)
- [ ] **Phase 7: Learning Engine & Letter Unit** - Build the production learning engine + multi-section Letter Unit, pixel-faithful to the Claude Design prototype and driven by Curriculum Schema v2 on Firestore, proven end-to-end on baa (5 reusable components, every exercise from config, audio, one star).
- [ ] **Phase 8: First Three Letters — Demo-Complete** - Author the first three letters (**alif · baa · taa**) as COMPLETE Letter Units through the Phase 7 engine — every applicable section, every question type, vocab, audio, common mistakes — with journey progression across the three, polished and rock-solid for the live Technion demo. baa is done; alif + taa to author (data only). The full 28-letter curriculum is deferred to a later phase (Phase 8 was rescoped 2026-06-15 for the demo).
- [x] **Phase 9: Parent Dashboard** - A parent enters a PIN and sees a read-only view of the child's completed lessons and scores. (completed 2026-06-13)
- [ ] **Phase 10: Offline Hardening & Release** - Every flow works airplane-mode on a fresh install, the ML Kit model is fetched-once-and-cached, and child data stays minimal and private.

## Phase Details

### Phase 1: Foundations & RTL Shell

**Goal**: A runnable Android app with correct RTL layout, a glyph-audited Arabic font, declarative routing, theme, and a local Drift database — the foundation everything else builds on.
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: PLAT-02
**Success Criteria** (what must be TRUE):

  1. The app launches on an Android tablet with English/LTR chrome (nav and buttons NOT mirrored) while Arabic content renders as correctly-mirrored RTL islands — `Directionality(rtl)` applied only to Arabic blocks, per D-05; not a globally-mirrored app.
  2. Arabic glyphs render with correct isolated/initial/medial/final connected-script forms across a test set, with no tofu/boxes and no broken joining.
  3. The chosen numeral system is displayed deliberately and consistently (decided, not left to defaults).
  4. The app persists and reads a trivial value via the local database across a restart (the persistence seam works).

**Plans**: 3 plans
Plans:

- [x] 01-01-PLAN.md — Wave 0: dependency/font/gen-l10n/lint scaffold + six failing validation tests
- [x] 01-02-PLAN.md — Walking Skeleton: theme tokens, ArabicText RTL island, Drift persist/read, go_router, landscape lock, Home screen
- [x] 01-03-PLAN.md — Glyph-audit risk gate (D-12 golden + human PASS), Practice ink-spike, Settings shell

**UI hint**: yes
**Research hint**: yes — RTL + connected-script rendering (R3) is an open question; audit the font against curriculum letters and decide the numeral system before any tracing surface.

### Phase 2: Curriculum Schema & First-Letter Seed

**Goal**: A faithful, code-reads-only curriculum data schema, plus a small seed of real letters (signed off by the owner's mother) carrying contextual forms, ordered reference stroke paths as coordinates, stroke order, clean-reps-to-advance, per-letter tolerances, and named common mistakes with child-friendly fix messages — enough to drive the first end-to-end slice.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: (seeds CUR-01; CUR-01 fully satisfied in Phase 7)
**Success Criteria** (what must be TRUE):

  1. Curriculum content loads from bundled data (not Dart code) into typed models the app only reads.
  2. The seeded letters carry reference stroke paths as coordinates usable both to draw the dotted guide and to score against — one source of truth.
  3. Each seeded letter's 3–4 common mistakes are present with their child-friendly fix messages and map to named scorer checks.
  4. Any not-yet-authored content is explicitly marked as placeholder, and the seeded letters carry the owner's-mother sign-off.

**Plans**: 3 plans
Plans:

- [x] 02-01-PLAN.md — Wave 1: Python extraction script + 28-letter letters.json + lessons.json skeleton + pubspec asset declaration + owner sign-off checkpoint for alif
- [x] 02-02-PLAN.md — Wave 2: Typed Dart models (Letter, Lesson, sub-types) + unit tests
- [x] 02-03-PLAN.md — Wave 3: CurriculumRepository (rootBundle loader, Riverpod provider) + integration tests + Phase 2 completeness gate

<!-- reconciled 2026-06-11: 02-01/02/03 all have SUMMARY files (executed) — checkboxes were stale. -->

### Phase 02.1: Stroke Reference Correction (INSERTED)

**Goal**: Replace the broken glyph-**outline** reference strokes (a closed silhouette loop, perimeter ≈ 3.27) with correct **open centerline** teaching strokes that a pen tip actually travels. Build an in-app authoring trace screen the owner (with his mother) uses to capture each stroke in her prescribed order and direction over a faint Noto Naskh glyph; add a `type` field (line/curve/dot) to the schema and a load-time validator that rejects closed-loop/outline strokes; and re-author **alif** correctly with the owner's re-sign-off as the proven exemplar. The other 27 letters stay `signedOff: false` placeholders, authored at Phase 7's existing sign-off gate. This unblocks Phase 3 (the scorer and the "watch me write" animation both require a correct centerline).
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: CUR-01 (corrects the Phase-2 reference-stroke seed — ordered centerline paths + owner's-mother sign-off; prerequisite for the Phase 3 trace loop)
**Success Criteria** (what must be TRUE):

  1. No non-dot reference stroke is a closed outline loop — a load-time/test validator rejects closed loops, out-of-range coordinates, and any `direction` string that disagrees with the actual point order; the test suite fails if an outline reaches `letters.json`.
  2. The owner can author a letter's strokes in-app by tracing over a faint Noto Naskh glyph, in his mother's order and direction, exporting normalized `referenceStrokes` (`order`, `label`, `type`, `direction`).
  3. Alif carries a correct open top→bottom centerline (length ≈ 1.0, monotonic, straight), its three `commonMistakes` checks are valid against it, and it is re-signed-off by the owner after a visual overlay confirmation.
  4. The same authored path drives the dotted guide, the stroke-order animation, and the geometric scorer (one source of truth, S1-04) — verified by a path-identity test and a per-letter overlay golden.

**Plans**: 4 plans
**UI hint**: minor — an internal owner/authoring tool (trace screen + overlay golden), not child-facing brand UI; a full UI-SPEC is optional (`--skip-ui` acceptable).
**Research hint**: DONE — see `.planning/research/STROKE-REFERENCE.md` (method survey, data-model change, staged fix, alif correction, owner decisions) and `03-RESEARCH.md` Q1. Plan with `--skip-research`.
Plans:
**Wave 1**

- [x] 02.1-01-PLAN.md — Wave 1: StrokeSpec `type` field (D-03) + pure-Dart closed-loop validator (D-04) + `ReferencePath.resolve` identity (S1-04) + Wave-0 tests
- [x] 02.1-03-PLAN.md — Wave 1: repurpose the Python extractor to dot-centroid/bbox authoring hints only, deprecate outlines (D-05)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02.1-02-PLAN.md — Wave 2: corrected alif open centerline (D-06) + load-time validator guard + alif property test + overlay golden (D-07) + human re-sign-off gate
- [x] 02.1-04-PLAN.md — Wave 2: in-app authoring trace screen (D-02) + pure-Dart normalize/export + widget test

### Phase 02.1.1: Presentation Demo Screens (alif core loop) (INSERTED)

**Goal**: A beautiful, screenshot-ready, navigable walkthrough of the full Qalam core loop for alif — Home → Watch → Trace → Tutor Feedback → Celebration — built with the real Flutter widgets and design system but fed **mocked/static content** (no scoring engine, no persistence, no network/model). For the 2026-06-02 course-staff presentation: the screens are *implemented*, the tutor's warm specific feedback is *depicted* in copy, and the presenter narrates the rest. The same widgets become Phase 3's real UI once the engine is wired behind them — so this is the UI layer built first, not throwaway.
**Depends on**: Phase 1 (theme tokens, RTL shell, ArabicText, router), Phase 2 (alif curriculum data for glyph + mistake copy)
**Requirements**: S1-04, S1-05, PLAT-03
**Requirements note**: presentational coverage — these are *depicted* in polished screens (mocked data), not engine-backed; Phase 3 delivers them for real.
**Success Criteria** (what must be TRUE):

  1. A navigable walkthrough runs Home → Watch → Trace → Feedback → Celebration for alif, tappable in order, with no dead ends.
  2. Every screen is pixel-faithful to the Qalam design system in RTL on a tablet — tokens only, real mascot (bundled), Noto Naskh/Cairo Arabic glyphs, anti-gamification chrome omitted (no counter/weekly tally/streak/badges).
  3. The Feedback screen shows the hero state: the failing stroke highlighted in coral with a **specific named fix in the tutor's voice** (e.g. "Start your alif at the top and pull straight down — yours leans left"), plus a clean-pass praise variant — never a generic "try again".
  4. The Celebration shows exactly ONE quiet star + the mascot + a warm line; the screens are clean of debug chrome and ready to screenshot.

**Mode:** mvp
**Plans:** 5/5 plans complete
**UI hint:** yes — pure presentation UI; reuse Phase 3's 03-UI-SPEC + design kit. Mocked data only.
**Research hint:** no — design is locked (Phase 3 UI-SPEC + docs/design/kit). Skip research; plan directly.

Plans:

**Wave 1**

- [x] 02.1.1-01-PLAN.md — Bundle brand SVGs (mascot+icons) + QalamMascot widget (graceful fallback) + DemoAlif mock content source (S1-04/PLAT-03)
- [x] 02.1.1-02-PLAN.md — All six-screen demo copy in gen-l10n + /demo navigable route group (DemoStep, no dead ends) (S1-04/S1-05/PLAT-03)

**Wave 2** *(blocked on Wave 1)*

- [x] 02.1.1-03-PLAN.md — De-gamified demo Home (mascot+greeting+alif card→Watch) + Watch screen (dotted alif + gold start-dot + write mascot→Trace) (S1-04/PLAT-03)

**Wave 3** *(blocked on Wave 2)*

- [x] 02.1.1-04-PLAN.md — Trace screen (half-traced alif: ink over dotted guide) + reusable DottedGuidePainter → Feedback (S1-04/S1-05/PLAT-03)

**Wave 4** *(blocked on Wave 3)*

- [x] 02.1.1-05-PLAN.md — HERO Feedback (coral failing stroke + specific named fix; clean-pass praise) + Celebration (ONE quiet star→Back Home) (S1-05/PLAT-03)

### Phase 3: Trace One Letter End-to-End

**Goal**: The full core loop working thin: for a seeded letter, the child can watch and replay the correct-stroke-order animation, trace the dotted guide with a stylus, and receive instant on-device feedback on shape and stroke order from a first-cut custom geometric scorer, earning a single quiet star on a clean pass.
**Mode:** mvp
**Depends on**: Phase 2, Phase 02.1 (corrected centerline reference strokes — the scorer and animation require it)
**Requirements**: S1-04, S1-05, S1-10, PLAT-03
**Success Criteria** (what must be TRUE):

  1. The child can play and replay an animation of the correct stroke order, driven by the same reference paths used for scoring.
  2. The child traces the dotted guide letter with a stylus and the live ink renders smoothly; palm/finger touches are filtered.
  3. Within ~300 ms of stylus-up and fully offline, the child sees feedback that evaluates stroke count, order, direction, and shape — with the failing stroke highlighted and a specific named fix (never a generic "try again").
  4. A clean completion shows a single quiet star; there are no streaks, badges, confetti, timers, or over-praise.

**Plans**: 6 plans (03-00..03-05; ROADMAP previously listed only 4)
<!-- reconciled 2026-06-11: phase shipped 6 plans (03-00 demo-home wave + 03-05 added during execution), all with SUMMARY files. All checked. -->
Plans:
**Wave 1**

- [x] 03-00-PLAN.md — Wave 1: demo Home foundation (mascot + greeting + Today's-lesson alif card)
- [x] 03-01-PLAN.md — Wave 1 (TDD): pure-Dart geometric stroke scorer + resampler + named-mistake mapping (S1-05)
- [x] 03-02-PLAN.md — Wave 1: Drift LetterMastery table + 1→2 migration + ProgressRepository (S1-10/D-09)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 03-03-PLAN.md — Wave 2: stylus-filtered capture canvas + dotted guide + PathMetric stroke-order animation + recognizer seam (S1-04/S1-05/D-13/D-16)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 03-04-PLAN.md — Wave 3: Watch→Trace→Celebrate flow + session controller + one-star celebration + anti-gamification omissions (S1-04/S1-05/S1-10/PLAT-03)

**Wave 4**

- [x] 03-05-PLAN.md — Wave 4: demo-home warmth pass (Welcome-back greeting + alif lesson card, D-17)

**UI hint**: yes
**Research hint**: yes — DEEPEST-RISK PHASE. The custom geometric stroke-order/shape scorer is NOT provided by ML Kit (ML Kit returns only {text, score} as a secondary letter-identity check). Stroke capture must use low-level pointer events (not GestureDetector) to preserve per-stroke order/count; the ML Kit Arabic model must be downloaded-and-cached before first scoring. Flag for deep iteration with the owner's mother.

### Phase 03.1: Journey Map Screen (INSERTED)

**Goal**: Implement the Journey Map screen in Flutter: a winding-path progress view showing all 28 letters as nodes across 4 rows of 7, with 4 node states (complete/current/future/locked), pulse animation on the current letter, a Level 1 Quiz checkpoint, and a locked Level 2 banner. Wired from the Home nav-rail and navigates to the Practice screen on node tap. Uses mocked progress data.
**Depends on**: Phase 3 (nav shell, theme tokens, GoRouter, MasteryCelebration widget)
**Requirements**: D-01 through D-24 (see 03.1-CONTEXT.md)
**Success Criteria** (what must be TRUE):

  1. All 28 Arabic letters appear as nodes in 4 rows of 7, following the alternating direction from the design reference (Row 1 R-to-L, Row 2 L-to-R, etc.).
  2. Node visual states match the mock progress (alif/baa/taa complete, thaa current, 5-28 future); current node pulses with a 2.4s glow animation.
  3. Tapping a complete or current node navigates to /practice; tapping future/locked nodes is inert.
  4. The Journey nav item on the Home screen is unlocked; the "See journey" button in MasteryCelebration is wired to /journey.
  5. No running star counter, no streak, no "+N" copy anywhere on the screen.

**Plans**: 3 plans

Plans:

**Wave 1**

- [x] 03.1-01-PLAN.md -- Wave 1: JourneyProgress model + JourneyNodeState enum + mockJourneyProgressProvider + /journey GoRoute + unlock Home nav + wire "See journey"

**Wave 2** *(blocked on Wave 1)*

- [x] 03.1-02-PLAN.md -- Wave 2: JourneyScreen layout + JourneyPathPainter winding path + 28 positioned nodes + 4 visual states + TODAY pill + Level 1 header pill

**Wave 3** *(blocked on Wave 2)*

- [x] 03.1-03-PLAN.md -- Wave 3: Pulse animation + tap handlers + gold star badges + Level 1 Quiz checkpoint + Level 2 locked banner + human verify checkpoint <!-- reconciled 2026-06-11: has SUMMARY + commit 4a97d87; checkbox was stale. -->

**UI hint**: yes -- PRIMARY design reference: docs/design/kit/project/ui_kits/qalam_app/journey_preview.html
**Research hint**: no -- design is locked (journey_preview.html). Plan directly.

### Phase 4: Scoring Quality & Calibration

**Goal**: The geometric scorer is tuned to the right strictness: it firmly rejects wrong stroke order and wrong stroke count and sloppy shapes, while accepting good-faith age-appropriate attempts, with per-letter pass tolerances calibrated against real child handwriting samples together with the owner's mother. Built as vertical slices: the capture→accumulate→scoreLetter→feedback spine makes SC#1 real on a multi-stroke letter (baa) first, then the ML Kit identity gate, calibration harness, and the mother-in-the-loop tolerance tuning thicken it.
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: (deepens S1-05 and PLAT-03 from Phase 3; no new requirement IDs)
**Success Criteria** (what must be TRUE):

  1. A correct-shape-but-wrong-stroke-order or wrong-stroke-count attempt is rejected, with the message naming the specific problem.
  2. A scribble or clearly-wrong letter is rejected (ML Kit identity check catches "wrote a completely different letter").
  3. A good-faith, size-and-position-varied child attempt passes (normalization prevents penalizing small/offset-but-correct letters).
  4. Pass tolerances are per-letter curriculum data the owner's mother can adjust without a code change, and regression tests encode the named common mistakes.

**Plans**: 6 plans

Plans:

**Wave 1**

- [x] 04-01-PLAN.md — Wave 0/1: extend MistakeId + LetterResult, data-driven Tolerances (normal == legacy constants), Letter.tolerances + validator, RED LetterScorer contract tests (D-03/D-04, SC#1/SC#2/SC#4)

**Wave 2** *(blocked on Wave 1)*

- [x] 04-02-PLAN.md — THE SPINE: pure-Dart scoreLetter orchestrator (count→order→per-stroke→dot, combined-bbox normalization), threshold-parameterized scorer, green contract tests (SC#1/SC#3/SC#4)
- [x] 04-03-PLAN.md — ML Kit advisory identity gate (MlKitRecognizer, D-04) + best-effort background model download with getting-ready degradation (D-05, SC#2)

**Wave 3** *(blocked on Wave 2)*

- [x] 04-04-PLAN.md — Wire the spine into the UI: multi-stroke capture accumulation fix + scoreLetter in practice_screen + authored feedback l10n for new MistakeIds + getting-ready state (SC#1/SC#2/PLAT-03/D-05)
- [x] 04-05-PLAN.md — Calibration infra: labeled-sample capture mode (D-02) + pure-Dart confusion-table harness over the real scorer + synthetic seed regression fixtures (SC#4)

**Wave 4** *(blocked on Wave 3 — human-gated, real-tablet)*

- [ ] 04-06-PLAN.md — autonomous:false — author + sign off baa/taa/thaa, capture real-tablet child samples, tune per-letter tolerances (FN/FP separately) with the owner's mother, freeze as regression (D-01/D-02, SC#1/SC#3/SC#4)

**Research hint**: yes — false-negative and false-positive rates must be tuned separately and per-letter against labeled child samples; this is a dedicated calibration step with the owner's mother, not a code constant. Environment blocker: SC#4 tolerance-setting requires a real Android tablet + real child samples (emulator/mouse rejected); Plans 01-05 ship autonomously, Plan 06 is the isolated human-gated calibration.

### Phase 5: Profiles & Onboarding

**Goal**: A parent can create a local child profile by picking a grade (which selects the curriculum entry point), and on first open the child picks an avatar and a nickname from fixed sets (no free-text, no real name) — all persisted locally with minimum child data.
**Mode:** mvp
**Depends on**: Phase 1 (DB), benefits from Phase 2 (grade→entry mapping)
**Requirements**: S1-02, S1-03
**Success Criteria** (what must be TRUE):

  1. A parent can create a child profile by picking a grade; it persists across restarts, and the grade maps to a starting lesson (default alif).
  2. The child can pick an avatar and a nickname from a fixed set (no free-text identity leak); the choice persists and shows on the home surface.
  3. Child data is stored in app-private local storage only, with no cloud, no account, and no real-name exposure beyond the device.

**Plans**: 4 plans
Plans:

**Wave 0**

- [x] 05-01-PLAN.md — Wave 0 (Nyquist): RED test stubs for profile repo, onboarding data, onboarding screen (no free-text/PopScope), and the redirect gate (no loop); extend app_database + home_screen tests (S1-02/S1-03) (completed 2026-06-08)

**Wave 1** *(blocked on Wave 0)*

- [x] 05-02-PLAN.md — Wave 1 (data slice): ChildProfiles table + v2→v3 migration + ChildProfileRepository + childProfile/OnboardingGate providers + onboarding_data (6 avatars, 8-10 placeholder nicknames, grade→alif map) (S1-02/S1-03) ✅

**Wave 2** *(blocked on Wave 1)*

- [x] 05-03-PLAN.md — Wave 2 (onboarding + gate slice): router /onboarding + sync redirect + boot gate read; single combined onboarding card (grade chips→avatar grid→nickname grid→Let'''s go, no free-text, PopScope) + l10n; end-to-end human verify (S1-02/S1-03) ✅

**Wave 3** *(blocked on Wave 2)*

- [x] 05-04-PLAN.md — Wave 3 (home integration slice): Home greeting reads chosen nickname label + avatar from childProfileProvider; {nickname} ARB template; scope-aware fallback; PLAT-03 preserved (S1-03) ✅

**UI hint**: yes

### Phase 6: Lesson Progression & Home

**Goal**: On opening the app the child immediately sees today's prepared lesson — the next unlocked lesson for the active child — with a single prominent Start and no navigation; the next lesson unlocks only after the child passes the current one per the curriculum's clean-reps-to-advance rule.
**Mode:** mvp
**Depends on**: Phase 3 (a passable lesson), Phase 5 (active child)
**Requirements**: S1-01, S1-09
**Success Criteria** (what must be TRUE):

  1. On launch the child lands on today's lesson for the active child with one clear Start and no navigation required.
  2. Locked lessons are visibly unavailable until their prerequisite is passed.
  3. Passing a lesson (meeting its clean-reps-to-advance rule) immediately unlocks the next lesson, which then appears as today's lesson.

**Plans:** 10/10 plans complete
Plans:
**Wave 1**

- [x] 06-01-PLAN.md — 28-lesson catalog + pure-Dart progression engine (D-01/D-02/D-06)
- [x] 06-02-PLAN.md — Schema v4: LetterReps persistence, watch streams, startingLessonId namespace (D-10)
- [x] 06-09-PLAN.md — Fix A (gap): lower kClosedLoopEpsilon 0.30→0.10 so 9 curl letters load (owner sign-off gate)
- [x] 06-10-PLAN.md — Fix B (gap): render type==dot strokes as calm ink circles in Watch animation + Trace guide

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 06-03-PLAN.md — Live progression providers + /practice?lesson= route parameterization (S1-09 immediacy)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 06-04-PLAN.md — Tolerance ramp + persisted-rep write-through (D-18/D-19/D-20)
- [x] 06-05-PLAN.md — Home today-card live: ink-fill, prepared desk, all-mastered state (S1-01)
- [x] 06-06-PLAN.md — Journey live data, canonical IDs, skipped taps, highlight arrival (D-07/D-15)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 06-07-PLAN.md — Celebration: Next Lesson, last-lesson variant, tutor line (D-14/D-16/D-17)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 06-08-PLAN.md — Slow-motion ghost comparison (D-21)

**UI hint**: yes

### Phase 06.1: Firebase Curriculum Backend (INSERTED)

**Goal:** Stand up **Firestore** in the existing `qalam-app-bd7d0` project as the cloud
source-of-truth for curriculum content (`letters` + `lessons`), wire the Flutter app to
Firebase with a **full, v2-ready Firebase Auth foundation** (anonymous at runtime), migrate
the signed-off **alif** seed + 28-lesson skeleton into Firestore, and make the app **read
curriculum live from Firestore** (one-shot `.get()` into the kept-alive cache) with **Firestore
offline persistence + a bundled-seed cold-start fallback** so it still works fully offline.
A Python `firebase-admin` export refreshes the bundled snapshot. This phase delivers the
schema/collections/wiring + auth + alif migration + seed/export tooling — **not** full content
(letters 2–28 and grammar/sentence questions are authored under the owner's-mother sign-off in
Phases 7–8).

**Mode:** mvp
**Depends on:** Phase 2 (curriculum schema + bundled-loader seam), Phase 6
**Requirements**: (infra for CUR-01; preserves PLAT-01 offline-first)

**⚠ Owner override (2026-06-14):** This reverses the Decided "v1 local-only, no Firebase"
item (PROJECT.md / STATE.md). The owner chose a **live Firestore read** at runtime (CONTEXT
D-01). The offline-first promise (PLAT-01) is held NOT by avoiding cloud but by **Firestore
offline persistence (on by default) + a bundled-seed cold-start fallback** (CONTEXT D-02/D-03):
the practice/trace path is cache-served and never blocks on a network round-trip. The owner
also chose a **full, v2-ready auth foundation** (CONTEXT D-09..D-10a): real providers enabled,
anonymous at runtime, anonymous→permanent linking architected, role-ready rules — but **no
child login UI and no child PII** (Decided child-safety holds).

**⚠ Flag:** the existing project is configured for **Data Connect (Cloud SQL/Postgres)**
in a sibling spike folder (`../qalam_ink_spike`) with billing OFF. This phase uses
**Firestore** per the Decided stack (free Spark tier suffices for now).

**Success Criteria** (what must be TRUE):

  1. The Flutter app is wired to Firebase (`firebase_options.dart`, `google-services.json`, FlutterFire deps) and builds/runs on Android against `qalam-app-bd7d0`.
  2. Firestore has a `letters` collection + a `lessons` collection (doc-per-entry, nested) plus a `meta/toleranceRamp` config doc, whose shape round-trips losslessly with the existing Dart curriculum models — including the `{x,y}`⇄`[x,y]` point codec and the empty-stroke skeleton letters (no content lost vs `letters.json`/`lessons.json`).
  3. The signed-off alif (referenceStrokes, commonMistakes, tolerances, sign-off flag) plus the 28-lesson skeleton are migrated into Firestore via the Python `firebase-admin` seed.
  4. The app reads curriculum **live from Firestore** (one-shot `.get()` into the kept-alive cache); with Firestore offline persistence + a bundled-seed cold-start fallback, **every flow still works fully offline** (incl. airplane-mode cold install) and the practice/trace path never blocks on a network round-trip. A Python export refreshes the bundled snapshot.
  5. Firestore security rules require authentication to read curriculum and deny all client writes (content written only via the admin service account / console); the app authenticates **anonymously** (no accounts, no child PII), and rules leave a seam to tighten by custom-claim roles in v2.

**Plans:** 5/5 plans complete

Plans:

**Wave 1**

- [x] 06.1-01-PLAN.md — FlutterFire wiring + Gradle/minSdk + anonymous-auth boot + linkWithCredential seam (SC#1; D-09/09a/b/c/12/16/17)
- [x] 06.1-02-PLAN.md — Shared point codec ({x,y}⇄[x,y]) + Firestore⇄Letter/Lesson mapper, Dart + Python, round-trip parity tests (SC#2; D-06/08/13/15)

**Wave 2** *(blocked on Wave 1)*

- [x] 06.1-03-PLAN.md — Python firebase-admin seed + export + round-trip test + Firestore DB/region/SA-key checkpoints (SC#3, SC#4-export; D-07/13/14/15/16)
- [x] 06.1-04-PLAN.md — CurriculumRepository Firestore-read + bundle fallback + validator + .withFirestore seam (SC#2, SC#4; D-01/02/03/04/05/07)

**Wave 3** *(blocked on Wave 2)*

- [x] 06.1-05-PLAN.md — firestore.rules (read-requires-auth, client-writes-denied, v2 claim seam) + deploy + Rules-Playground verify (SC#5; D-10/10a/11)

### Phase 7: Learning Engine & Letter Unit (built to the Claude Design prototype)

**Goal**: Build the production learning engine and the multi-section **Letter Unit**, implemented
**pixel-faithful to the Claude Design prototype** and driven by **Curriculum Schema v2** in Firestore
(extending Phase 06.1). Deliver the full experience end-to-end for **baa**: the 6-section unit
(Meet → Watch & trace → Forms → Words → Listen & write → Mastery), the **5 reusable components**
(ExerciseScaffold, PromptHeader, WriteSurface, FeedbackPanel, ProgressRibbon), every exercise type
rendered from config, real on-device scoring, pronunciation audio, and one quiet star.

**⚠ HARD CONSTRAINT (owner, 2026-06-15):** implement the Claude Design prototype
(`docs/design/prototypes/letter-unit-baa/`) **EXACTLY as delivered** — no restyling, no design
changes, no anti-gamification or other "corrections" to the prototype's surfaces. The **prototype +
Schema v2 are the locked contracts.** Build new surfaces to match the prototype's HTML/CSS 1:1; for
surfaces the prototype matched to existing widgets (trace canvas, stroke animation, celebration,
mascot), reuse those widgets. Be smart: the engine is data-driven, so a new question is a new config,
never new UI.

**Mode:** mvp
**Depends on**: Phase 06.1 (Firebase/Firestore + curriculum backend), Phase 3 (trace/scoring/celebration widgets), Phase 4 (scorer)
**Requirements**: CUR-01 (engine + baa), S1-06 (pronunciation audio)
**Success Criteria** (what must be TRUE):

  1. The app renders the baa Letter Unit **pixel-faithful to the prototype** — the 6 sections, navigable, RTL, landscape — assembled from the 5 reusable components.
  2. Every exercise is **data-driven from a Schema v2 `Exercise` config** (the 19 baa configs load and render through the same components; a new question = a new config, no new UI).
  3. Schema v2 (forms + vocab + exercises + unit) lives in Firestore extending 06.1; the app reads it **live + offline** (bundled-seed fallback) via `CurriculumRepository`.
  4. **baa is end-to-end real:** all its contextual forms authored + owner's-mother signed off, vocab + pronunciation audio play offline, on-device geometric scoring + authored feedback, one quiet star at mastery.
  5. The journey map and home deep-link into the resume-aware unit (reusing existing nav).

**Plans**: 7 plans
Plans:

**Wave 1** *(engine spine — parallel, no file overlap)*

- [x] 07-01-PLAN.md — Schema v2 typed models (Exercise/PromptPart/Surface/Answer/Check + Word + LetterUnit + per-form Form) + CurriculumRepository getExercises/getWords/getUnit (Firestore-first, bundle fallback); 19 baa configs deserialize 1:1 (CUR-01)
- [x] 07-02-PLAN.md — Audio slice (S1-06): vetted audio package + AssetLetterAudioPlayer over the existing seam + bundled baa clips (offline) + Firestore rules for words/exercises/units (autonomous:false — package legitimacy gate)
- [x] 07-03-PLAN.md — Validator spine (TDD): validateExercise (glyph/sequence/order + positionalForm/joinContinuity/transformRule) reusing the existing geometric scorer → CheckResult (CUR-01)

**Wave 2** *(blocked on Wave 1)*

- [x] 07-04-PLAN.md — The 5 reusable components pixel-faithful: ExerciseScaffold + PromptHeader + WriteSurface (wraps existing StrokeCanvas) + FeedbackPanel + ProgressRibbon + ExerciseController + QalamTokens; config-driven, Riverpod-only (CUR-01)

**Wave 3** *(blocked on Wave 2)*

- [x] 07-05-PLAN.md — Sections 1-3: Meet (teachCard + four-forms morph) + Watch & Trace (isolated baa) + Forms in context; config-driven, offline audio (CUR-01 / S1-06)

**Wave 4** *(blocked on Wave 3 — shares app_en.arb with 07-05)*

- [x] 07-06-PLAN.md — Sections 4-6: Words + Listen & Write (recall gate) + Mastery (one quiet star) + LetterUnit shell (R→L ribbon, resume-aware) + /unit route + home/journey deep-links (CUR-01 / S1-06; SC#1/#2/#5)

**Wave 5** *(blocked on Wave 4 — human-gated)*

- [ ] 07-07-PLAN.md — autonomous:false — DRAFT baa's four contextual-form reference strokes + vocab + audio → owner's-mother sign-off human gate → Firestore seed/export; baa end-to-end real, signed off (CUR-01 / S1-06; SC#4)

**Canonical refs (MUST read before planning/implementing):**

- `docs/design/prototypes/letter-unit-baa/` — **the visual contract; implement EXACTLY** (HANDOFF.md, COMPONENTS.md, SCHEMA-BINDINGS.md, EXERCISE-CONFIGS.json, TOKENS.md, `prototype/` HTML/CSS/JS).
- `.planning/research/learning-experience/SCHEMA-V2.md` — the locked data schema.
- `.planning/research/learning-experience/COMPONENT-SYSTEM.md` — the 5-component architecture.
- The Phase 06.1 plans — the Firestore/`CurriculumRepository` seam this extends.

**UI hint**: yes — implement the prototype exactly; **no new design work**.
**Research hint**: no — design + schema are locked (prototype + Schema v2). Plan directly.

### Phase 8: First Three Letters — Demo-Complete

**Goal**: Make the **first three letters — alif (ا) · baa (ب) · taa (ت)** — each a COMPLETE, polished
Letter Unit running through the Phase 7 engine, so the live Technion demo shows a real, *scaling*
product (not a one-letter prototype). Every applicable section, every question type that fits the
letter, vocab + pronunciation audio + common mistakes — all **Schema v2 data**, no design changes.
The journey map shows the three as a walkable progression. baa is already done end-to-end; this phase
brings **alif** and **taa** to the same bar and hardens all three for a flawless on-device demo.

**Rescoped 2026-06-15** from "all 28 letters" → "first 3, demo-complete" for the Technion meeting.
The full 28-letter curriculum + grammar/sentence batches move to a later phase.

**⚠ HARD CONSTRAINT:** same as Phase 7 — all surfaces use the existing Phase 7 components built to the
Claude Design prototype; content is added **as data only, no design changes**. Handwriting-first
throughout (the child writes; never tap-one-of-four). taa models on baa (boat body + dots); the owner
authors/edits the per-form reference strokes via the Stroke Studio / DB and signs off.

**Mode:** mvp
**Depends on**: Phase 7 (the engine + components + Schema v2 + the proven baa exemplar)
**Requirements**: CUR-01 (first-3 slice), S1-07 (sentence-building, where it fits), S1-08 (grammar, where it fits)
**Success Criteria** (what must be TRUE):

  1. alif, baa, taa each authored as a complete Letter Unit (sections appropriate to the letter — taa is a connector with 4 forms like baa; alif is a non-connector → isolated+final + a leaner unit), loaded from data, signed off.
  2. The question types that suit each letter are present as data and render through the Phase 7 components — at minimum trace/write letter + the per-form trace + words; richer types (grammar transform, fill-blank, sentence) wherever the content supports them.
  3. Real scoring works for all three: geometric stroke scorer for letters/forms, ML Kit word recognition for words; handwriting-first, never tap-one-of-four.
  4. All three letter units are reachable from Home/Journey, the journey shows them as a progression (e.g. alif/baa complete → taa current), and walking alif→baa→taa works end-to-end.
  5. Demo-hardened: no dead-ends, no stuck states, no placeholder "Coming soon" in the demo path; stable on the Pixel-Tablet build.

**Plans**: TBD
**Canonical refs**: same as Phase 7 (`docs/design/prototypes/letter-unit-baa/` + `SCHEMA-V2.md` + `COMPONENT-SYSTEM.md`).
**UI hint**: no new design — reuse the Phase 7 components.
**Research hint**: no — locked. Content modeled on the signed-off baa; the owner authors strokes + signs off.

### Phase 9: Parent Dashboard

**Goal**: A parent can enter a PIN to reach a read-only local area showing the child's completed lessons and scores — no cloud, no account.
**Mode:** mvp
**Depends on**: Phase 5 (profiles), Phase 6 (progress recorded)
**Requirements**: S1-11
**Success Criteria** (what must be TRUE):

  1. The parent area is reachable only after entering a PIN; the child cannot reach it without it.
  2. The parent sees a read-only list of completed lessons and their scores for the child, sourced from local storage.
  3. No cloud, account, or network is involved, and the PIN is stored hashed locally (not an account).

**Plans**: 3 plans
Plans:

**Wave 0**

- [x] 09-01-PLAN.md — Wave 0 (Nyquist RED): failing tests for PIN hash/verify, persisted cooldown, route gate, read-only dashboard + all Phase-9 ARB copy keys (S1-11)

**Wave 1** *(blocked on Wave 0)*

- [x] 09-02-PLAN.md — Security/data slice: PinService (salted PBKDF2 + constant-time verify), persisted brute-force cooldown, read-only aggregate accessors, ParentProgress model (S1-11)

**Wave 2** *(blocked on Wave 1)*

- [x] 09-03-PLAN.md — UI/wiring slice: ParentGate + parentProgressProvider, /parent route gate, PIN create/enter screen, read-only dashboard, Home nav unlock, boot seed; end-of-phase device UAT (S1-11)

**UI hint**: yes

### Phase 10: Offline Hardening & Release

**Goal**: Verify and harden the local-only, offline-first promise end-to-end: every v1 flow works in airplane mode on a fresh install, the ML Kit Arabic model is fetched once at onboarding then cached, and child data collection stays minimal and private with no PII/stroke logging in release builds.
**Mode:** mvp
**Depends on**: Phases 1–9
**Requirements**: PLAT-01
**Success Criteria** (what must be TRUE):

  1. On a fresh install with no network, every v1 flow either works fully offline or explicitly handles the one-time model-download case at onboarding.
  2. After onboarding, the ML Kit Arabic model is cached so the scoring path never waits on a download; verified in airplane mode.
  3. Release builds contain no child-PII or stroke logging, and child data lives only in app-private storage.

**Plans**: TBD
**Research hint**: yes — offline-first behavior and the one-time model-download-on-first-run case (R2) must be verified on a fresh install, not just in dev where the model is already cached.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10

<!-- reconciled 2026-06-11: Phase 2 (0/3) and Phase 3 (0/4) were stale — both fully shipped
     (commits 419cc21, 3761794; every plan has a SUMMARY; scorer + curriculum repo live in lib/).
     Phase 4/5 were correctly built ON TOP of completed 2/3, not in spite of them.
     Table now includes the 3 inserted decimal phases. 13 tracked phases, 7 complete = 54%. -->

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundations & RTL Shell | 3/3 | Complete | 2026-05-31 |
| 2. Curriculum Schema & First-Letter Seed | 3/3 | Complete | 2026-06-01 |
| 02.1 Stroke Reference Correction (INSERTED) | 4/4 | Complete | 2026-06-01 |
| 02.1.1 Presentation Demo Screens (INSERTED) | 5/5 | Complete | 2026-06-02 |
| 3. Trace One Letter End-to-End | 6/6 | Complete | 2026-06-02 |
| 03.1 Journey Map Screen (INSERTED) | 3/3 | Complete | - |
| 4. Scoring Quality & Calibration | 5/6 | In Progress (04-06 deferred, human-gated) | - |
| 5. Profiles & Onboarding | 4/4 | Complete | - |
| 6. Lesson Progression & Home | 10/10 | Complete   | 2026-06-14 |
| 06.1 Firebase Curriculum Backend (INSERTED) | 5/5 | Complete    | 2026-06-14 |
| 7. Learning Engine & Letter Unit | 6/7 | In Progress|  |
| 8. Full Curriculum & All Question Types | 0/TBD | Not started | - |
| 9. Parent Dashboard | 3/3 | Complete    | 2026-06-13 |
| 10. Offline Hardening & Release | 0/TBD | Not started | - |

**Totals:** 7 of 13 tracked phases complete (54%); 33 of 34 plans complete (only 04-06 deferred).


---

## Milestone v2.0 — AI Tutor (Technion build)

### Overview

v2.0 turns the fixed-order baa drill into a **dynamic, grounded AI agent-tutor** on one
letter family (**baa**), reusing the v1 durable layers (StrokeCanvas/WriteSurface, the
geometric scorer, Schema-v2 curriculum) untouched. The model reasons, coaches, and chooses
which exercise to show next — but **every factual claim about the child's writing is pinned to
the deterministic geometry scorer**: the scorer owns pass/fail + the star, the agent owns the
words. The "API key never in the client" rule is preserved via Firebase AI Logic + App Check;
only derived non-PII facts ever cross the network; and an `AuthoredFallback` floor keeps the
whole loop fully offline + grounded with zero model loaded.

This roadmap is **spikes-first by deliberate design**: the three riskiest unknowns — (1) can a
GenUI catalog host a real-time native stylus canvas, (2) does the full on-device stroke→agent→
TTS path stay within a presence budget, and (3) can a small/cloud model actually coach grounded,
correct, age-appropriate Arabic — are de-risked up front, each ending in a written
decision/GATE, before any production code commits to an architecture. Then a grounded vertical
slice builds the brain spine, dynamic selection on baa, and presence + voice + the eval gate +
demo-hardening. The spikes (Phases 11–13) own **no requirements** by design — they are
investigations whose findings choose the path the build phases (14–16) then execute.

### Phases

- [ ] **Phase 11: SPIKE — GenUI catalog + native stylus canvas (kill-shot)** - Prove (or refute) a GenUI core catalog driven by a local firebase_ai function-calling loop can host the real-time native StrokeCanvas via a present_activity tool; GATE to a raw firebase_ai-drives-native-widgets fallback if it can't.
- [ ] **Phase 12: SPIKE — full-path latency & presence budget (Pixel Tablet)** - Measure the real on-device stroke→scorer→agent→render→first-TTS path on a Pixel Tablet across Gemini Flash / Flash-Lite / Live API + Gemma; produce a written latency budget and the model/transport choice.
- [ ] **Phase 13: SPIKE — 3-way bake-off (Authored vs Gemini vs Gemma) on grounding + Arabic** - Score AuthoredFallback vs GeminiBrain vs Gemma-on-device on grounding faithfulness + Arabic register over one harness; the data decides whether fully-offline Gemma is viable. Seeds the eval harness.
- [ ] **Phase 14: BUILD — TutorBrain spine + grounding invariant** - The swappable TutorBrain interface + AuthoredFallback floor + GeminiBrain + GemmaBrain stub, the 4 ACTION tools with FACTS injected, the scorer-owns-verdict seam at ExerciseController, and the non-PII-facts network guard — durable layers stay free of GenUI/firebase_ai types.
- [ ] **Phase 15: BUILD — dynamic grounded exercise selection on baa** - Replace LetterUnitController's fixed walk with agent-driven present_activity selection over baa's 19 Schema-v2 configs, reasoning about recent mistakes; the curriculum rails the choices; resume-aware; one quiet star at mastery; first-measure grounding faithfulness.
- [ ] **Phase 16: BUILD — presence + voice + eval gate + demo-harden** - Streamed/TTS coaching within the Phase-12 budget (reflex stays local), the Phase-13 harness promoted to a regression gate, the baa AI-tutor path demo-hardened on the Pixel Tablet, and the Gemma-adoption decision finalized.

### Phase Details

#### Phase 11: SPIKE — GenUI catalog + native stylus canvas (kill-shot)

**Goal**: Prove (or refute) that the GenUI **core catalog** driven by a local `firebase_ai`
function-calling loop can host a **real-time NATIVE stylus canvas** (the existing
StrokeCanvas/WriteSurface) via a `present_activity` tool, with the stylus path staying
native and real-time (no per-stroke network round-trip, no rendering lag).
**Mode**: spike
**Depends on**: v1 Phase 7 (the WriteSurface/StrokeCanvas + ExerciseController seam this must host)
**Requirements**: none (architecture-decision spike — owns no requirement by design)
**Success Criteria** (what must be TRUE):

  1. A throwaway harness shows a `firebase_ai` function-calling loop calling a `present_activity` tool that renders the **real native StrokeCanvas/WriteSurface**, and a child can trace baa on it with the stroke path staying native and real-time (visibly no per-stroke lag).
  2. There is a written, evidence-backed verdict on whether the GenUI core catalog can cleanly host that real-time native canvas — pass or fail stated explicitly, with what was observed.
  3. A **GATE decision is recorded**: keep GenUI, OR fall back to **raw `firebase_ai` function-calling driving our native widgets directly (drop GenUI)** — and Phase 14 is told which architecture to build.
  4. Either way, the durable layers (canvas, scorer, curriculum) are confirmed unchanged — the spike touches no production canvas/scorer/curriculum code.

**Plans**: TBD
**Research hint**: yes — riskiest unknown of the milestone (the kill-shot). The whole architecture branches on this result; spend the iteration to reach a confident GATE decision, not a guess.

#### Phase 12: SPIKE — full-path latency & presence budget (Pixel Tablet)

**Goal**: Measure the **real on-device full-path latency** — stroke → scorer → agent → render →
first-TTS — on a **Pixel Tablet**, comparing Gemini Flash vs Flash-Lite vs the Live API, plus
Gemma's on-device footprint/latency; then produce a written latency budget and the model/transport
choice, confirming the "two clocks" split (the millisecond stroke reflex stays local) feels present.
**Mode**: spike
**Depends on**: v1 Phase 7 (the scorer + canvas timings this measures against), Phase 11 (the agent-loop transport whose latency is being measured)
**Requirements**: none (measurement spike — feeds PRES-01; owns no requirement by design)
**Success Criteria** (what must be TRUE):

  1. The full stroke→scorer→agent→render→first-TTS path is measured **on a real Pixel Tablet** (not emulator/dev) with numbers recorded for Gemini Flash, Flash-Lite, and the Live API, plus Gemma's on-device footprint/latency.
  2. A **written latency budget** exists that names the acceptable delay for each segment and shows the local stroke reflex stays local (never routes through the agent) — confirming the "two clocks" split feels present.
  3. A **model + transport choice is recorded** for the build phases, justified by the measured numbers, with explicit headroom for the demo build.

**Plans**: TBD
**Research hint**: yes — presence is felt, not specified; numbers must come from the real device. The chosen model/transport here is a hard input to Phase 16's presence/voice work.

#### Phase 13: SPIKE — 3-way bake-off (Authored vs Gemini vs Gemma) on grounding + Arabic

**Goal**: On ONE grounding+Arabic-register harness, score **AuthoredFallback** (baseline) vs
**GeminiBrain** vs **Gemma-on-device** for: never-contradicts-geometry, names-the-specific-fix,
register-for-a-5-10-year-old, and correct-Arabic — so the **data** decides whether Gemma's
fully-offline ideal is viable. The harness built here seeds the v2.0 eval harness.
**Mode**: spike
**Depends on**: v1 Phase 7 (the signed-off baa content + scorer the cases are built from)
**Requirements**: none (decision spike — feeds EVAL-01, GROUND-03, and the TUTOR-04 Gemma decision; owns no requirement by design)
**Success Criteria** (what must be TRUE):

  1. A single labeled harness scores all three brains (AuthoredFallback baseline, GeminiBrain, Gemma-on-device) on never-contradicts-geometry, names-the-specific-fix, register-for-a-5-10-year-old, and correct-Arabic, with comparable per-brain scores reported.
  2. A **written verdict on Gemma viability** is recorded — whether the fully-offline on-device ideal is good enough on grounding + Arabic, or stays an experimental-only candidate — feeding the TUTOR-04 adoption decision finalized in Phase 16.
  3. The harness is **reusable** — it is the seed of the Phase 16 regression gate (EVAL-01/EVAL-02), not a throwaway, and the labeled (verdict, learner-state) case format is documented.

**Plans**: TBD
**Research hint**: yes — small-model Arabic + grounding is unproven; this is where the Gemma bet is tested with evidence, off the demo's critical path. The labeled set authored here is reused by Phase 16's gate.

#### Phase 14: BUILD — TutorBrain spine + grounding invariant

**Goal**: Build the swappable **`TutorBrain`** interface with the **AuthoredFallback** floor (offline,
zero-model, mother-signed-off lines), the **GeminiBrain** (Firebase AI Logic + App Check), and a
**GemmaBrain** stub behind the same interface; expose the **4 ACTION tools** (`present_activity`,
`say`, `give_hint`, `advance`) with FACTS injected as context (not tools); wire the "agent owns the
line, scorer owns pass/fail + star" seam at the existing `ExerciseController`; and enforce the
non-PII-facts network guard — all while keeping the durable layers free of GenUI/A2UI/firebase_ai types.
**Mode**: mvp
**Depends on**: Phase 11 (the GATE: GenUI vs raw firebase_ai — which architecture this spine is built on), v1 Phase 7 (the ExerciseController seam + scorer this wires to)
**Requirements**: TUTOR-01, TUTOR-02, TUTOR-03, TUTOR-04, TUTOR-05, GROUND-01, GROUND-02
**Success Criteria** (what must be TRUE):

  1. One `TutorBrain` interface hosts three swappable backends — AuthoredFallback, GeminiBrain, GemmaBrain (stub OK) — and swapping the backend changes no canvas, scorer, or curriculum code; the durable layers carry zero GenUI/A2UI/firebase_ai imports (TUTOR-01, TUTOR-04).
  2. In airplane mode with no model loaded, every coaching moment still shows a grounded, correctly-Arabic AuthoredFallback line and the trace loop never blocks; online, GeminiBrain coaches and auto-degrades to the floor on timeout/offline, with the Gemini key never in the client (App-Check-gated) (TUTOR-02, TUTOR-03).
  3. The agent acts only through the 4 ACTION tools (`present_activity`, `say`, `give_hint`, `advance`); the geometry verdict and learner state arrive as injected FACTS (mistakeId, struggles, letterId, section) — the model cannot request or fabricate a verdict (TUTOR-05).
  4. The pass/fail + star is decided by the deterministic scorer at the `ExerciseController` seam and no agent path can flip a fail to a pass; the agent only supplies the displayed line (GROUND-01).
  5. A guard/test fails the build if raw stroke coordinates or any PII field (nickname/PII) can reach the network payload — only derived non-PII facts cross (GROUND-02).

**Plans**: TBD
**UI hint**: yes
**Research hint**: no — the architecture is decided by the Phase 11 GATE; this phase executes it.

#### Phase 15: BUILD — dynamic grounded exercise selection on baa

**Goal**: Replace `LetterUnitController`'s fixed section walk with **agent-driven `present_activity`
selection** over baa's existing **19 Schema-v2 configs**, reasoning about the child's recent
mistakeIds/struggle tags (injected facts); the **curriculum rails the choices** (only valid,
signed-off baa configs are selectable); the flow is **resume-aware** and ends in **one quiet star**
at mastery; and grounding faithfulness is enforced and first-measured here.
**Mode**: mvp
**Depends on**: Phase 14 (the TutorBrain spine + ACTION tools + grounding seam), Phase 13 (the grounding-faithfulness harness this first-measures with), v1 Phase 7 (the 19 signed-off baa configs + LetterUnit)
**Requirements**: DYN-01, DYN-02, GROUND-03
**Success Criteria** (what must be TRUE):

  1. Entering the baa unit runs the **agent-driven flow** (not `LetterUnitController`'s static sequence); the agent picks the next exercise via `present_activity` from baa's 19 configs, and its choice visibly responds to recent mistakeIds/struggles rather than a fixed order (DYN-01, DYN-02).
  2. The agent can select **only valid, signed-off baa configs** — the curriculum rails the choices; an invalid or unsigned config can never be presented (DYN-01).
  3. The dynamic flow is **resume-aware** (re-entering resumes correctly) and ends in **one quiet star** at mastery — no streaks, totals, or extra stars (DYN-02).
  4. Grounding faithfulness is **measurable and enforced** here — given a fixed scorer verdict, the harness flags any coaching that praises a failed stroke or names the wrong fix, and a faithfulness rate is reported (GROUND-03).

**Plans**: TBD
**UI hint**: yes
**Research hint**: no — runs on the Phase 13 harness + the Phase 14 spine; no new unknowns.

#### Phase 16: BUILD — presence + voice + eval gate + demo-harden

**Goal**: Make the tutor **feel present** — streamed/TTS coaching that plays at the right moments
within the **Phase-12 latency budget** while the millisecond stroke reflex stays local; **promote
the Phase-13 harness into a regression gate** that catches tutor-quality regressions before they
ship; **demo-harden** the baa AI-tutor path (no dead ends, graceful offline/timeout fallback to
authored lines) on the **Pixel-Tablet build**; and **finalize the Gemma-adoption decision** from
the bake-off.
**Mode**: mvp
**Depends on**: Phase 15 (the dynamic grounded baa flow being voiced + hardened), Phase 12 (the latency budget + model/transport choice met here), Phase 13 (the harness promoted to the gate; the Gemma verdict finalized here)
**Requirements**: PRES-01, PRES-02, EVAL-01, EVAL-02, DEMO-01
**Success Criteria** (what must be TRUE):

  1. Coaching is **spoken/streamed** on pass/miss and degrades gracefully to text on offline/timeout without breaking the flow (PRES-02); the stroke→scorer→agent→render→first-TTS path **meets the written Phase-12 budget** on a real Pixel Tablet and instant stroke feedback never routes through the agent (PRES-01).
  2. The **eval harness scores** tutor quality (never-contradicts-geometry, names-the-specific-fix, register-for-a-5-10-year-old, correct-Arabic) against the labeled set (EVAL-01) and **runs as a regression gate** (CI or a documented pre-merge step) that fails on a regression below threshold (EVAL-02).
  3. The baa AI-tutor path is **demo-hardened** end-to-end on the Pixel-Tablet build — Home/Journey → baa unit → mastery star, with no dead ends or stuck states and graceful offline/timeout fallback to authored lines (DEMO-01).
  4. The **Gemma-adoption decision is finalized** from the Phase-13 bake-off and recorded (adopt as a real backend vs keep experimental-only, never on the demo's critical path) (closes the TUTOR-04 decision).

**Plans**: TBD
**UI hint**: yes
**Research hint**: no — presence numbers come from Phase 12; the gate harness from Phase 13. This phase integrates and hardens.

### Progress (v2.0)

**Execution Order:**
Spikes first, then the grounded vertical slice: 11 → 12 → 13 → 14 → 15 → 16

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 11. SPIKE — GenUI catalog + native stylus canvas | 0/TBD | Not started | - |
| 12. SPIKE — full-path latency & presence budget | 0/TBD | Not started | - |
| 13. SPIKE — 3-way bake-off (grounding + Arabic) | 0/TBD | Not started | - |
| 14. BUILD — TutorBrain spine + grounding invariant | 0/TBD | Not started | - |
| 15. BUILD — dynamic grounded exercise selection on baa | 0/TBD | Not started | - |
| 16. BUILD — presence + voice + eval gate + demo-harden | 0/TBD | Not started | - |

**Coverage:** all 14 v2.0 requirements mapped across Phases 14–16; the three spikes (11–13) own no requirements by design. See REQUIREMENTS.md → v2.0 Traceability.
