# Roadmap: Qalam — v1 Core Learning Loop

## Overview

> **Scope note (owner override, 2026-06-22):** the "no account" line below was
> relaxed for **parent accounts only**. Real Email/Password + Google parent
> sign-in/up is now live (`AuthService` + `lib/screens/parent_auth_screen.dart`),
> reachable only from behind the PIN-gated parent area. **Children still never log
> in** (D-09b holds). Foundation scope — the account does not yet gate or sync data.
> Cloud/tutor remain v2.

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
words. The tutor runs as a **server-side LangGraph agent on Cloud Run** (ADR-015 + the Phase-14
AI-SPEC): model keys live in **Secret Manager** (never the client), client→server is gated by a
**Firebase ID token + App Check**, only derived non-PII facts ever cross the network, and an
`AuthoredFallback` floor keeps the whole loop offline + grounded with zero model.

The architecture is **decided up front** in ADR-014/ADR-015 + the AI-SPEC, not left to a spike:
Phase 11's kill-shot GATE refuted GenUI-hosting (**GATE: drop**), and the capable-agent topology
re-evaluation landed on the server-side LangGraph design (framework chosen by a scored matrix —
LangGraph). So the order is **build the spine first (Phase 14), then de-risk on the deployed
system**: Phase 12 measures the real client→Cloud Run→model round-trip against a presence budget,
and Phase 13 builds the eval harness + settles the coach-node model (Claude vs Gemini) — both now
follow the build because they measure/score the *deployed* server. Then dynamic grounded selection
(15) and presence + voice + the eval gate + demo-hardening (16). Phases 12/13 own **no
requirements** by design — investigations that tune the deployed system.

### Phases

- [x] **Phase 11: SPIKE — GenUI catalog + native stylus canvas (kill-shot)** - Prove (or refute) a GenUI core catalog driven by a local firebase_ai function-calling loop can host the real-time native StrokeCanvas via a present_activity tool; GATE to a raw firebase_ai-drives-native-widgets fallback if it can't. (completed 2026-06-22)
- [ ] **Phase 12: SPIKE — full-path latency & presence budget (Pixel Tablet)** - Measure the real stroke→scorer→**client→Cloud Run server→model→back**→render→first-TTS path on a Pixel Tablet (incl. Cloud Run cold-start) across the server's per-node models (Claude Haiku/Sonnet, Gemini Flash/Pro); produce a written latency budget + the per-node model/transport choice and the cold-start mitigation.
- [ ] **Phase 13: SPIKE — eval harness + Claude-vs-Gemini coach bake-off (grounding + Arabic)** - Build the AI-SPEC grounding+Arabic eval harness and score the LangGraph server's **coach node on Claude vs Gemini** (+ the AuthoredFallback baseline) for never-contradicts-geometry, names-the-fix, register, and correct-Arabic; the data picks the coach-node model. Seeds the Phase-16 gate. (On-device Gemma deferred — offline floor is AuthoredFallback.)
- [x] **Phase 14: BUILD — TutorBrain spine + grounding invariant** - The server-side **LangGraph** tutoring agent on Cloud Run (analyze→plan→coach, per-node models, 4 ACTION tools, FACTS-as-text) + the Flutter `RemoteAgentBrain` + `AuthoredFallback` floor + the scorer-owns-verdict seam at ExerciseController + the non-PII request-body guard — durable layers stay free of agent/framework imports. (ADR-015 + 14-AI-SPEC.md.) (completed 2026-06-22)
- [x] **Phase 15: BUILD — dynamic grounded exercise selection on baa** - The server agent's **plan node** drives `present_activity` selection over baa's 19 Schema-v2 configs (reasoning about recent mistakes); the curriculum rails the choices; resume-aware; one quiet star at mastery; first-measure grounding faithfulness. (completed 2026-06-28)
- [ ] **Phase 16: BUILD — presence + voice + eval gate + demo-harden** - Server-**streamed/TTS** coaching within the Phase-12 budget (reflex stays local), the Phase-13 harness promoted to a regression gate, the baa AI-tutor path (client + Cloud Run server) demo-hardened on the Pixel Tablet, and the per-node model choices finalized.
- [x] **Phase 17: BUILD — stroke-aware coaching (on-device geo-diff → coach)** - The coach names the specific geometry of the child's actual attempt via an on-device derived diff; raw strokes never leave the device. (completed 2026-07-06)
- [x] **Phase 18: BUILD — the living tutor: per-child dynamic exercise selection** - Two-timescale child model, remediation arcs, just-this-part micro-drills, railed to the signed graph. (owner-closed 2026-07-17; 18-11 human gates + UAT device retest deferred — see the phase's deferred-items.md)
- [ ] **Phase 18.1: Content & audio at scale (INSERTED — partner track)** - Real pronunciation clips through a manifest-driven pipeline, a draft vocabulary bank for all 28 letters, and per-letter sign-off review packets — runs parallel with Phase 19, feeds Phases 20–21.
- [x] **Phase 19: Question presentation overhaul** - Every question self-explanatory on screen (persistent instruction, big stimulus, per-type affordance); language cards rewritten with the mother; micro-drills return; per-child position keying fixed. (completed 2026-07-18)
- [x] **Phase 20: Curriculum graph + authoring pipeline for all 28 letters** - ABSORBED (2026-07-19): delivered outside the phase — 18.1 partner track built the pipeline + drafts; finalization Lane A landed per-letter graphs + the letter-generic engine. Never executed as written; retained for the historical record.
- [ ] ~~**Phase 21: Letter content at scale**~~ - SUPERSEDED (2026-07-19) → Phase 27 (The whole alphabet).
- [ ] ~~**Phase 22: Cross-letter mistake-aware selection + next-day lesson planner**~~ - SUPERSEDED (2026-07-19) → Phase 28 (Smart across letters + the parent window).
- [ ] ~~**Phase 23: Parent insight — strengths and struggles dashboard**~~ - SUPERSEDED (2026-07-19) → Phase 28 (Smart across letters + the parent window).
- [ ] ~~**Phase 24: Submission readiness**~~ - SUPERSEDED (2026-07-19): the Sprint-2 submission itself SHIPPED via the finalization push (v2.0.0+3 in Play production review, release/2.0 frozen, webcourse APK). The hardening residue → Phase 29 (Hardening + milestone close).
- [ ] **Phase 25: Trusted content — the seen-letters wall + the mother's confirmation** - Every question provably demands only letters the child has seen (labels → lint wall → seeder gate → runtime guard), and every demo-night content change goes back to the mother for a verdict.
- [ ] **Phase 26: The finished experience — entry, polish, and the 2.0.1 release** - The front-door identity decision made real, sign-out never strands anyone, the real Qalam icon everywhere, the scorer re-tightened, the two tutor-feedback bugs closed, the Android device pass done — shipped as 2.0.1+4 after grading.
- [ ] **Phase 27: The whole alphabet — 24 letters in mother-signed batches** - Every remaining letter promoted through the Phase-25 wall in her-signed batches, with the tutor server un-fenced per batch so coaching follows the content.
- [ ] **Phase 28: Smart across letters + the parent window** - Selection and remediation reason across the full alphabet, the nightly job prepares tomorrow's lesson, and the PIN-gated parent dashboard shows strengths/struggles (S2-04/S2-05/S2-06).
- [ ] **Phase 29: Hardening + milestone close** - Airplane-mode-proof on a fresh install, the no-PII release audit, the verification-debt ledger at zero, and the final release — the app is genuinely finished.

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

**Plans**: 3 plans
Plans:

**Wave 1**

- [x] 11-01-PLAN.md — Install genui (not flutter_genui) + firebase_ai + firebase_core bump; SC-4 durable-diff guard + correct-package guard; baa read-only fixture; Firebase AI Logic console enable (SC-4; D-09/D-10/D-13)

**Wave 2** *(blocked on Wave 1)*

- [x] 11-02-PLAN.md — The A/B harness: read installed genui source, present_activity CatalogItem hosting StrokeCanvas under a stable key (mixed tree), Gemini Flash A2UI transport, embedded-vs-standalone toggle target (SC-1; D-03/D-04/D-11/D-12)

**Wave 3** *(blocked on Wave 2)*

- [x] 11-03-PLAN.md — On-device A/B on a real Pixel Tablet (feel-based, D-06), write SPIKE-FINDINGS verdict + GATE keep|drop, package via /gsd:spike-wrap-up for Phase 14 (SC-2/SC-3; D-05/D-06/D-08/D-13)

**Research hint**: yes — riskiest unknown of the milestone (the kill-shot). The whole architecture branches on this result; spend the iteration to reach a confident GATE decision, not a guess.

#### Phase 12: SPIKE — full-path latency & presence budget (Pixel Tablet)

**Goal**: Measure the **real full-path latency** — stroke → scorer → **client → Cloud Run server → model → back** → render → first-TTS — on a **Pixel Tablet**, including **Cloud Run cold-start** and the network hop, across the server's per-node models (Claude Haiku/Sonnet, Gemini Flash/Pro); then produce a written latency budget, the per-node model/transport choice, and the cold-start mitigation (e.g. session-start warm-up ping), confirming the "two clocks" split (the millisecond stroke reflex stays local, never routes through the server) feels present.
**Mode**: spike
**Depends on**: v1 Phase 7 (the scorer + canvas timings this measures against), Phase 14 (the deployed LangGraph server whose round-trip latency is being measured) + ADR-015
**Requirements**: none (measurement spike — feeds PRES-01; owns no requirement by design)
**Success Criteria** (what must be TRUE):

  1. The full stroke→scorer→client→server→model→back→render→first-TTS path is measured **on a real Pixel Tablet** (not emulator/dev), with numbers recorded per server node-model (Claude Haiku/Sonnet, Gemini Flash/Pro) and the **Cloud Run cold-start vs warm** delta called out.
  2. A **written latency budget** exists that names the acceptable delay for each segment and shows the local stroke reflex stays local (never routes through the agent) — confirming the "two clocks" split feels present.
  3. A **model + transport choice is recorded** for the build phases, justified by the measured numbers, with explicit headroom for the demo build.

**Plans**: TBD
**Research hint**: yes — presence is felt, not specified; numbers must come from the real device. The chosen model/transport here is a hard input to Phase 16's presence/voice work.

#### Phase 13: SPIKE — eval harness + Claude-vs-Gemini coach bake-off (grounding + Arabic)

**Goal**: Build the AI-SPEC grounding+Arabic-register **eval harness** and use it to score the LangGraph server's **coach node on Claude vs Gemini** (plus the **AuthoredFallback** baseline) for: never-contradicts-geometry, names-the-specific-fix, register-for-a-5-10-year-old, and correct-Arabic — so the **data** picks the coach-node model. The harness built here seeds the Phase-16 regression gate. (On-device Gemma is deferred — the offline floor is AuthoredFallback; a Gemma backend can slot into the swappable seam in a later milestone.)
**Mode**: spike
**Depends on**: Phase 14 (the deployed LangGraph server whose coach node is scored), v1 Phase 7 (the signed-off baa content + scorer the cases are built from), 14-AI-SPEC.md §5 (the eval dimensions/rubrics)
**Requirements**: none (decision spike — feeds EVAL-01, GROUND-03, and the per-node model choice; owns no requirement by design)
**Success Criteria** (what must be TRUE):

  1. A single labeled harness scores the coach node on **Claude vs Gemini** (plus the AuthoredFallback baseline) on never-contradicts-geometry, names-the-specific-fix, register-for-a-5-10-year-old, and correct-Arabic, with comparable per-model scores reported.
  2. A **written verdict on the coach-node model** is recorded (Claude vs Gemini for Arabic register + grounding), feeding the per-node model choice finalized in Phase 16. (On-device Gemma stays deferred/experimental — not on the demo path.)
  3. The harness is **reusable** — it is the seed of the Phase 16 regression gate (EVAL-01/EVAL-02), not a throwaway, and the labeled (verdict, learner-state) case format is documented.

**Plans**: TBD
**Research hint**: yes — Arabic register + grounding faithfulness is where the coach-node model choice (Claude vs Gemini) must be settled with evidence, off the demo's critical path. The labeled set authored here is reused by Phase 16's gate.

#### Phase 14: BUILD — TutorBrain spine + grounding invariant

**Goal**: Build the **capable server-side tutoring agent** + its client seam. Server (per **ADR-015** / `14-AI-SPEC.md`): a Python **LangGraph** agent on **Cloud Run** with the `analyze → plan → coach` graph, per-node model routing (model-agnostic — Claude + Gemini), the **4 ACTION tools** (`present_activity`, `say`, `give_hint`, `advance`) selected via `tool_choice="any"`, FACTS injected as text (never a verdict tool), keys in **Secret Manager**, client→server gated by **Firebase ID token + App Check**. Client: the swappable **`TutorBrain`** interface with a **`RemoteAgentBrain`** (calls the server) and the **`AuthoredFallback`** offline floor (zero-model, mother-signed-off lines), the dispatcher, and the "agent owns the line, scorer owns pass/fail + star" seam wired at the existing `ExerciseController`; the **non-PII-facts guard** on the request body — all while keeping the durable layers free of agent/framework imports. (`GemmaBrain` on-device is deferred — the offline floor is `AuthoredFallback`.)
**Mode**: mvp
**Depends on**: Phase 11 (the GATE → drop GenUI) + **ADR-015** (server-side LangGraph, model-agnostic per-task routing) + `14-AI-SPEC.md` (the implementation + eval contract), v1 Phase 7 (the ExerciseController seam + scorer this wires to)
**Requirements**: TUTOR-01, TUTOR-02, TUTOR-03, TUTOR-04, TUTOR-05, GROUND-01, GROUND-02
**Success Criteria** (what must be TRUE):

  1. One `TutorBrain` interface hosts swappable backends — `RemoteAgentBrain` (the LangGraph server) + `AuthoredFallback` (offline floor); swapping the backend changes no canvas, scorer, or curriculum code; the durable layers carry zero agent/framework/network imports (TUTOR-01, TUTOR-04).
  2. In airplane mode every coaching moment still shows a grounded, correctly-Arabic `AuthoredFallback` line and the trace loop never blocks; online, the LangGraph server coaches and the client auto-degrades to the floor on timeout/offline, with model keys never in the client (Secret Manager; App-Check + Firebase-ID-token gated) (TUTOR-02, TUTOR-03).
  3. The agent acts only through the 4 ACTION tools (`present_activity`, `say`, `give_hint`, `advance`); the geometry verdict and learner state arrive as injected FACTS (mistakeId, struggles, letterId, section) — the model cannot request or fabricate a verdict (TUTOR-05).
  4. The pass/fail + star is decided by the deterministic scorer at the `ExerciseController` seam and no agent path can flip a fail to a pass; the agent only supplies the displayed line (GROUND-01).
  5. A guard/test fails the build if raw stroke coordinates or any PII field (nickname/PII) can reach the network payload — only derived non-PII facts cross (GROUND-02).

**Plans**: 4 plans (RE-PLANNED 2026-06-22 against ADR-015 server-side LangGraph — supersedes the prior client-only plan set)
Plans:

**Wave 1**

- [x] 14-01-PLAN.md — SERVER: scaffold the Python LangGraph `server/` sub-project — FastAPI app + minimal one-node graph + POST /coach (tool_choice="any") + GET /healthz + Firebase-ID-token & App-Check verify + Secret-Manager keys + Cloud Run deploy → a grounded coach line end-to-end (TUTOR-03 partial, TUTOR-05)

**Wave 2** *(blocked on 14-01 — both depend on the 14-01 server DTO contract; no file overlap between them)*

- [x] 14-02-PLAN.md — SERVER: the grounded agent graph — analyze→plan→coach StateGraph + conditional edge + per-node model routing (model-agnostic) + the 4 ACTION tools (tool_choice="any") + FACTS-as-text + server-side grounding (no verdict tool; advance-on-fail impossible; curriculum guard) + bounded retry (TUTOR-05, GROUND-01)
- [x] 14-03-PLAN.md — autonomous:false — CLIENT: RemoteAgentBrain (calls the server with ID token + App Check, auto-degrades to AuthoredFallback) + reshape TutorFacts(trajectory+learner model)/TutorDecision(plan) + route via the single tutorBrainFactoryProvider + wire the line into exercise_scaffold (ExerciseController untouched) (TUTOR-01, TUTOR-02, TUTOR-03)

**Wave 3** *(blocked on 14-02, 14-03)*

- [x] 14-04-PLAN.md — GUARDS: build-failing non-PII payload test on BOTH the client payload and the server request body (GROUND-02) + durable-layers-no-agent/framework/network-imports guard (TUTOR-04) + AuthoredFallback offline-floor coverage for every baa coaching moment (TUTOR-01, TUTOR-02)

**UI hint**: yes
**Research hint**: no — the architecture is decided by the Phase 11 GATE; this phase executes it.

#### Phase 15: BUILD — dynamic grounded exercise selection on baa

**Goal**: Replace `LetterUnitController`'s fixed section walk with the **server agent's plan node
driving `present_activity` selection** over baa's existing **19 Schema-v2 configs**, reasoning about
the child's recent mistakeIds/struggle tags (the FACTS sent to the server); the **curriculum rails the choices** (only valid,
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

**Plans**: 7 plans

Plans:

**Wave 0**

- [x] 15-01-PLAN.md — Nyquist RED contract: all failing tests (server + Dart) + the PROVISIONAL baa curriculum graph asset (signedOff:false) + the owner-mother sign-off sheet (DYN-01/DYN-02/GROUND-03; D-04/D-05)

**Wave 1** *(blocked on Wave 0)*

- [x] 15-02-PLAN.md — Server graph rail: derive the server graph copy via generate.py, load it in curriculum.py, G5/G6 guards + thickened plan prompt on top of G3/G4, server-side cleared-* FACTS fields (DYN-01; D-01/D-02/D-04)
- [x] 15-03-PLAN.md — Offline parity + mastery: pure-Dart CurriculumGraph + CurriculumGraphWalker (advance/remediate) + isMasteryMet (70/30, on-device star); backward remediation demoable offline (DYN-01/DYN-02; D-01/D-06/D-09)
- [x] 15-04-PLAN.md — Resume persistence: Drift LetterGraphPosition table + per-exercise clean-reps (v4→v5) + GraphPositionRepository + the Dart cleared-* FACTS fields (DYN-02; D-08)
- [x] 15-06-PLAN.md — GROUND-03 faithfulness seed: model-free Python check flags praise-on-fail / wrong-fix + reports a rate (GROUND-03; D-10)

**Wave 2** *(blocked on Wave 1)*

- [x] 15-05-PLAN.md — Dynamic flow integration: ExerciseSelector router (online↔offline) replaces the fixed section walk; mastery-gated quiet star; non-PII regression (DYN-01/DYN-02; D-02/D-06)

**Wave 3** *(blocked on Waves 1-2 — human-gated)*

- [x] 15-07-PLAN.md — autonomous:false — owner-mother signs the curriculum graph at the tier level; flip signedOff:true; re-derive + re-deploy (DYN-01/DYN-02; D-05/D-07/D-11)

**UI hint**: yes
**Research hint**: no — runs on the Phase 14 spine; the grounding harness is seeded here (the narrow GROUND-03 slice, D-10) rather than depending on the unrun Phase-13 bake-off.

#### Phase 16: BUILD — presence + voice + eval gate + demo-harden

**Goal**: Make the tutor **feel present** — **server-streamed/TTS** coaching that plays at the right
moments within the **Phase-12 latency budget** while the millisecond stroke reflex stays local;
**promote the Phase-13 harness into a regression gate** that catches tutor-quality regressions
before they ship; **demo-harden** the baa AI-tutor path (client + Cloud Run server; no dead ends,
graceful offline/timeout fallback to the authored floor) on the **Pixel-Tablet build**; and
**finalize the per-node model choices** (analyze/plan/coach) from the Phase-13 bake-off.
**Mode**: mvp
**Depends on**: Phase 15 (the dynamic grounded baa flow being voiced + hardened), Phase 12 (the latency budget + model/transport choice met here), Phase 13 (the harness promoted to the gate; the Gemma verdict finalized here)
**Requirements**: PRES-01, PRES-02, EVAL-01, EVAL-02, DEMO-01
**Success Criteria** (what must be TRUE):

  1. Coaching is **spoken/streamed** on pass/miss and degrades gracefully to text on offline/timeout without breaking the flow (PRES-02); the stroke→scorer→agent→render→first-TTS path **meets the written Phase-12 budget** on a real Pixel Tablet and instant stroke feedback never routes through the agent (PRES-01).
  2. The **eval harness scores** tutor quality (never-contradicts-geometry, names-the-specific-fix, register-for-a-5-10-year-old, correct-Arabic) against the labeled set (EVAL-01) and **runs as a regression gate** (CI or a documented pre-merge step) that fails on a regression below threshold (EVAL-02).
  3. The baa AI-tutor path is **demo-hardened** end-to-end on the Pixel-Tablet build — Home/Journey → baa unit → mastery star, with no dead ends or stuck states and graceful offline/timeout fallback to authored lines (DEMO-01).
  4. The **per-node model choices are finalized** (analyze / plan / coach) from the Phase-13 bake-off and recorded (e.g. coach = Claude vs Gemini for Arabic register). On-device Gemma stays deferred/experimental — never on the demo's critical path; the swappable seam keeps a future Gemma backend possible (the TUTOR-04 "swappable candidate" intent is met by the seam, with on-device Gemma a later-milestone option).

**Plans**: TBD
**UI hint**: yes
**Research hint**: no — presence numbers come from Phase 12; the gate harness from Phase 13. This phase integrates and hardens.

#### Phase 17: BUILD — stroke-aware coaching (on-device geo-diff → coach)

**Goal**: Make the coach name the **specific geometry of the child's actual baa attempt** — where the
curve fell short, which side is flat, where the dot landed — instead of being capped by the scorer's
small `mistakeId` set. The agent consumes a **derived stroke-geometry diff computed ON-DEVICE** (Dart)
and sent as a structured fact; **raw strokes never leave the device**. The diff flows to the `coach`
node only (v1), which verbalizes it in the mother's voice through the existing 4 ACTION tools. The
deterministic scorer stays the **frozen judge** (GROUND-01); grounding holds (G2/G3/G4 + faithfulness);
and the eval grows to score stroke-level coaching. Validated by the stroke-aware spike (GATE: BUILD —
`geo_diff`, grounding held, image rejected; see `.planning/spikes/SPIKE-FINDINGS.md`).
**Mode**: build
**Depends on**: Phase 16 (the voiced + hardened coach spine — Phase 17 executes after 16 closes); the stroke-aware spike (VALIDATED)
**Requirements**: STRK-01, GROUND-04, EVAL-03
**Success Criteria** (what must be TRUE):

  1. The coach produces attempt-specific, varied, grounded lines that name the actual geometry (dot left/right/above; which side of the bowl is flat) — measurably beating the label-only baseline on the eval's specificity/variety, grounding intact (0 advance-on-fail, 0 praise-on-fail) (STRK-01).
  2. Raw strokes never leave the device; only the derived `strokeDiff` crosses the wire; `extra="forbid"` still rejects raw points/PII; client + server contracts match (no 422) (GROUND-04).
  3. The eval scores stroke-level coaching with a **semantic** faithfulness gate (the coarse substring floor retired) + a no-false-geometry check, re-signed by the owner's mother, and runs as the regression gate (EVAL-03).
  4. The **softened** GROUND-02 reversal (a derived diff leaves the device, NOT raw strokes) is recorded as an ADR.

**Deferred (NOT in this phase)**: sending raw strokes or rendered images to the model (spike rejected image; on-device derived diff chosen); enriching the `analyze` node with geometric struggle tags (later follow-up); letters beyond baa; the **cheap-win prompt fix** (exemplars as register guidance, never copied) — ships separately first as a `/gsd:quick`, a prerequisite, not part of this phase.
**Canonical refs**: docs/architecture/STROKE-AWARE-COACH-SPIKE-BRIEF.md; .planning/spikes/SPIKE-FINDINGS.md; .planning/spikes/MANIFEST.md; .planning/spikes/_lib/geometry.py; server/app/faithfulness.py; server/app/schema.py; server/app/nodes/coach.py; server/app/prompts.py
**Plans**: 10 plans in 8 waves
Plans:
**Wave 1**

- [x] 17-01-PLAN.md — Wave-0 RED contract: soft-verdict + per-form scorer tests
- [x] 17-04-PLAN.md — EVAL-03 semantic faithfulness gate + no-false-geometry + two-arm STRK-01 baseline

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 17-02-PLAN.md — DTW shape-match into the per-stroke scorer (soft 3-zone verdict)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 17-03-PLAN.md — Per-form multi-criteria letter scorer + validator form threading

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 17-05-PLAN.md — Coaching contract, server side FIRST: criteria + word-facts DTO, criterion-aware addendum
- [x] 17-09-PLAN.md — Calibration harness per letter × form + threshold-fit report

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 17-06-PLAN.md — Coaching contract, client mirror: CheckResult → TutorFacts + lockstep guards

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 17-07-PLAN.md — Client verdict cutover: scorer owns pass/fail, image render deleted, D-A behavioral test

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 17-08-PLAN.md — Server image-path retirement + F1 RTL fix

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 17-10-PLAN.md — ADR-017 + re-deploy + HUMAN-UAT ledger + baseline reconciliation

**UI hint**: no — server + client-contract + on-device diff; no new screens.
**Research hint**: no — the spike already validated representation, grounding, latency, and privacy; this phase implements the spike's verdict.

#### Phase 18: BUILD — the living tutor: per-child dynamic exercise selection (two-timescale child model, remediation arcs, just-this-part micro-drills, railed to the curriculum graph)

**Goal:** Every "next exercise" pick is a deliberate, explainable teaching move informed by a persistent per-child model — targeting the weakest criterion, building remediation arcs back to confidence, injecting just-this-part micro-drills — while staying railed to the signed curriculum graph, preserving the offline walker floor, and closing the cost/latency research question with measured numbers.
**Requirements**: SPEC-18-R1..R9 (the 9 locked requirements in 18-SPEC.md)
**Depends on:** Phase 17 (LetterScore criteria + weakest; ADR-017); Phase 17.2 (graph-legal candidates over the wire, coach proposes+announces, Teacher's Eye strip — merge to main before branching)
**Plans:** 15/16 plans executed

Plans:

**Wave 1**

- [x] 18-01-PLAN.md — Wave 0 RED contract: one failing test per R1..R9 + EMA Dart↔Python parity + non-PII/422 guards + signed:false selection gold-set stub (completed 2026-07-11)

**Wave 2** *(blocked on Wave 1)*

- [x] 18-02-PLAN.md — Cross-letter labels (letters+criteria on every exercise) + baa micro-drill set (dot/bowl/start, signedOff:false) + generate.py server re-derive (R3/R7, the early pedagogy ask)
- [x] 18-03-PLAN.md — Per-criterion EMA (pure Dart + Python mirror, D-15) + Drift schemaVersion 5→6 (evidence/arc-state/profile-mirror tables) (R8)

**Wave 3** *(blocked on Wave 2)*

- [x] 18-04-PLAN.md — Pure-Dart SelectionPolicy in lib/curriculum/ (arc state machine + anti-boredom filter + micro-drill injection, D-09/D-11) + ArcState/ChildModelSnapshot pure types (R1/R3/R4)
- [x] 18-05-PLAN.md — Server FIRST (422 lockstep): TutorFactsIn +profile +evidenceDigest + Admin-SDK evidence append at /coach (D-13) + firestore.rules child_models owner-read (R2/R7)

**Wave 4** *(blocked on Wave 3)*

- [x] 18-06-PLAN.md — Client mirror (422 second): TutorFacts +profile +evidenceDigest + non-PII guard extend + ChildModelRepository Firestore-first/Drift-mirror (D-16) + arc/evidence repos (R2/R6)
- [x] 18-08-PLAN.md — Server coach picks among policy candidates + grounds the WHY line (D-10) + selection_policy eval dimension + signed:false gold set (R1/R9)
- [x] 18-09-PLAN.md — Nightly compiler (Cloud Run Job entrypoint, letter-agnostic EMA compile → child_models/{uid}) + second-letter + PII guard (R2/R8)

**Wave 5** *(blocked on Wave 4)*

- [x] 18-07-PLAN.md — Wire the policy into the live path: candidate-aware selector + walker + D-08 drill scoring + offline WHY template + controller orchestration + arc persistence (R1/R4/R5/R6)

**Wave 6** *(blocked on Wave 5)*

- [x] 18-10-PLAN.md — Child-facing Teacher's Margin panel (arc narration + WHY, D-01) + Spotlight overlay (light the criterion zone, D-05); anti-gamification (R1/R3/R4)

**Wave 7** *(blocked on Wave 6 — human/infra gates, autonomous:false)*

- [ ] 18-11-PLAN.md — Ordered deploy (server FIRST, rules, Cloud Run Job + Scheduler) + CLOSE cost/latency with measured numbers + mother sign-off flips signed:false→true + make eval (R2/R3/R4/R7/R8/R9)

**Gap closure — UAT 2026-07-17** *(5 issues diagnosed; plans 18-12..18-16)*

- [x] 18-12-PLAN.md — BLOCKER+major: one coordinated same-id re-present remount fix (presentation-epoch key) for the retry no-op (T3) AND the active-arc stuck state (T6) + replay-instruction control (UAT T3/T6)
- [x] 18-13-PLAN.md — cosmetic: responsive stimulus image sizing + caption LTR bidi fix (UAT T2)
- [x] 18-14-PLAN.md — major: server tool-schema fix so the coach's per-attempt rationale reaches the client on the clean-pass path (structural half of T5) + Cloud Run re-deploy gate (UAT T5)
- [x] 18-15-PLAN.md — major: restore selection/presenter mode from the durable cursor on cold boot so relaunch resumes in place (UAT T7) *(depends on 18-12)*
- [x] 18-16-PLAN.md — blocker/major: Teacher's Margin distinct identity beside the canvas + real arc-step narration + per-attempt WHY variance; demo Teacher's Eye gated out of non-demo builds (margin half of T6 + client half of T5) *(depends on 18-12, 18-15)*

#### Phase 18.1: Content & audio at scale (INSERTED — partner track)

**Goal:** All raw content inputs needed to take the app from a one-letter demo to the full
28-letter curriculum are produced or pipelined by the partner, in parallel with Phase 19 and
without touching any file Phase 19 owns: real (non-placeholder) pronunciation audio flowing
through a manifest-driven Python pipeline, a draft vocabulary bank covering every letter with
per-word letter decomposition, and per-letter review packets that make the mother's sign-off
sessions fast. Drafts only — nothing child-facing ships until she signs (the standing
curriculum-governance rule).
**Mode:** build (partner-executed; owner merges PRs to main)
**Depends on:** Phase 18 (Schema-v2 audioId convention; letters.json stroke drafts). Runs
parallel with Phase 19. Feeds Phases 20–21 (authoring pipeline + content at scale).
**Working brief:** `.planning/phases/18.1-content-and-audio-at-scale-partner-track/PARTNER-BRIEF.md`
**Requirements**: derived from the brief (audio pipeline, vocab bank, review packets)
**Success Criteria** (what must be TRUE):

  1. A Python audio pipeline (`tools/audio_pipeline/`) turns raw recordings into normalized
     clips named by the existing `snd.*`/`word.*`/`sentence.*` convention, and the
     `assets/audio/README.md` manifest table AND the Dart `_audioIdToAsset` map are GENERATED
     from one manifest source — never hand-edited again.

  2. All 28 `snd.<letterId>` placeholder clips are replaced with real recordings (voice choice
     is the owner + mother's call; TTS drafts allowed meanwhile but always marked `draft-tts`,
     never passed off as real).

  3. A draft vocabulary bank (staged outside the live curriculum files) covers all 28 letters
     with the words.json schema (id/text/audio/image/gloss/letters[]), and a validator proves
     which words are legal at each point in the mother's intro order.

  4. Review packets exist for all 26 unsigned letters (per-form stroke diagrams with order +
     direction, common mistakes, reps-to-advance, sign-off checklist), ready for batch review.

  5. Zero edits to Phase-19 territory: `lib/features/letter_unit/`, `lib/data/`,
     `assets/curriculum/exercises.json`, `assets/curriculum/curriculum_graph.json`, `server/`.

**UI hint**: no — Python tooling + assets + generated docs; no app screens.
**Research hint**: no — conventions already exist in-repo (audio README, words.json schema, letters.json).

#### Phase 19: Question presentation overhaul — every question self-explanatory on screen

**Goal:** Every non-trace question shows what is being asked without depending on the spoken
line (the 2026-07-12 owner UAT finding: non-trace questions "need serious work"): a persistent
child-readable instruction area (icon + short text per question type, never TTS-only), a large
stimulus zone (image / replayable audio / word-to-copy), and a per-type "what to do" affordance
(trace ghost, copy model, gap highlight). The language cards (№ 10, 15–20) are rewritten with
the owner's mother so the first unit demands only learned letters — this rewrite becomes the
template every later letter follows. Micro-drills return to the live graph once presentation
supports them (selection logic already pinned by `microdrill_selection_test.dart`). Includes the
per-child position keying fix: `LetterGraphPosition`, arc-state, and profile-mirror rows re-keyed
by (childProfileId, letterId) with migration, so a new profile starts fresh.
**Mode:** build
**Depends on:** Phase 18 (Teacher's Margin + live selection path). Source findings: `.planning/todos/pending/2026-07-12-question-presentation-overhaul.md`
**Requirements**: QP-01, QP-02, QP-03, QP-04, QP-05, QP-06, QP-07, QP-08, QP-09, QP-10 (derived at plan time 2026-07-17 from the folded 2026-07-12 owner UAT findings — see 19-RESEARCH.md Phase Requirements map)
**Success Criteria** (what must be TRUE):

  1. Any question type read cold from the screen alone tells the child what to do — instruction + stimulus + affordance — with the spoken line as reinforcement, never the only carrier.
  2. The first unit's language cards use only letters the child has learned; sentences/grammar gate to later letters.
  3. Micro-drills are back in the live graph behind the reworked presentation.
  4. Two child profiles on one device keep separate graph cursors/arc state (a fresh profile starts at the opening).

**UI hint**: yes
**Plans:** 6/6 plans complete
Plans:

**Wave 1**

- [x] 19-01-PLAN.md — Wave 0 RED contract: failing live-path + migration + lint tests for QP-01..QP-10

**Wave 2** *(blocked on Wave 1)*

- [x] 19-02-PLAN.md — Instruction bar in ExerciseScaffold + _HearAgainCta fold (QP-01/QP-02; D-01..D-04)
- [x] 19-03-PLAN.md — Stimulus zone: slot box, audio card, copy hide+peek, recall no-model (QP-03..QP-06; D-05..D-08)
- [x] 19-04-PLAN.md — LetterReps reader/writer fold onto LetterExerciseReps aggregates (QP-09 prep; D-15)
- [x] 19-05-PLAN.md — Micro-drill re-add + learned-letters lint + card gate/rewrite + mother's review packet (QP-07/QP-08; D-09..D-12/D-18/D-19/D-21)

**Wave 3** *(blocked on 19-04)*

- [x] 19-06-PLAN.md — Per-child keying migration v6→v7 + childProfileId threading + drop LetterReps + ADR-018 (QP-09/QP-10; D-13..D-17/D-20)

#### Phase 20: Curriculum graph and authoring pipeline for all 28 letters

**Goal:** Generalize the baa-only curriculum machinery to the full alphabet: the curriculum
graph (server + pure-Dart mirror) covers all 28 letters with tiers, prerequisites, and the
letter intro order taken from the owner's-mother's materials; and a repeatable authoring
pipeline exists per the decided drafting strategy (2026-06-11) — the model DRAFTS each letter's
stroke data / common mistakes / vocab, the mother REVIEWS and signs, nothing ships unsigned.
Proven end-to-end on the first batch of letters in her intro order, so every later batch is
content work, not code work.
**Mode:** build
**Depends on:** Phase 19 (the presentation template all content renders through); Phases 15/18 (graph rails + cross-letter labels)
**Requirements**: CUR-01 (full-curriculum carry-over)
**Success Criteria** (what must be TRUE):

  1. The signed curriculum graph spans all 28 letters in the mother's intro order, and `generate.py` derives the server copy from the single signed asset.
  2. The pipeline turns "next letter batch" into: model draft → reference strokes → mother review sitting → signedOff flip — documented and exercised on the first batch.
  3. Unsigned letters/exercises can never be selected on the live path (rails hold per letter).

**Plans:** TBD

#### Phase 21: Letter content at scale — remaining letters in mother-signed batches

**Goal:** Run the Phase-20 pipeline across all remaining letters in mother-signed batches —
per-form reference strokes, vocab, audio, common mistakes, and graph nodes for each — as data
through the existing components (no design changes). Pays the alif unsigned-forms debt (the
known baseline red in `curriculum_repository_v2_test`). The mother's review time is the
bottleneck: batches are sized to sign-off sittings.
**Mode:** build
**Depends on:** Phase 20 (the pipeline + first signed batch)
**Requirements**: CUR-01
**Success Criteria** (what must be TRUE):

  1. All 28 letters are authored, signed, and live — reachable via Journey/graph with real per-form scoring.
  2. No unsigned content in the bundle (the every-signedOff test leg is GREEN).
  3. Each batch's sign-off is recorded (HUMAN-UAT pattern).

**Plans:** TBD

#### Phase 22: Cross-letter mistake-aware selection and the next-day lesson planner

**Goal:** The living tutor reasons across the whole alphabet, at both timescales.
Within-session: selection and remediation arcs use criterion struggles ACROSS letters (a bowl
struggle on taa can pull a baa bowl drill), railed to the signed graph. Across-session: the
nightly job, after compiling the child model, EMITS tomorrow's prepared unit — the child opens
the app to "today's lesson, already chosen for you" (S1-01 finally meets S2-05), with the
offline walker producing the default plan when no fresh compile exists.
**Mode:** build
**Depends on:** Phase 18 (two-timescale child model, letter-agnostic compiler, cross-letter labels); Phase 21 (content beyond baa to select from)
**Requirements**: S2-04, S2-05
**Success Criteria** (what must be TRUE):

  1. Selection demonstrably responds to cross-letter criterion struggles; unsigned/unreachable nodes are never selectable.
  2. The nightly job writes a next-day plan per child; Home presents it as today's prepared lesson; airplane mode yields the walker's default plan.
  3. Grounding + non-PII guards hold over any new wire surface (422 lockstep preserved).

**Plans:** TBD

#### Phase 23: Parent insight — strengths and struggles dashboard

**Goal:** Surface the child model to the parent: the PIN-gated dashboard gains a read-only
per-letter / per-criterion strengths-and-struggles view (S2-06) sourced from the compiled
`child_models` profile (Firestore-first, Drift-mirror offline). No new child data is collected —
this renders what the tutor already knows. Optional second plan: the weekly progress report (S2-10).
**Mode:** build
**Depends on:** Phase 18 (compiled child model); Phase 9 (PIN-gated dashboard)
**Requirements**: S2-06 (S2-10 optional)
**Success Criteria** (what must be TRUE):

  1. A parent behind the PIN sees which letters/criteria the child is strong or struggling on, matching the compiled profile.
  2. Read-only; works offline from the Drift mirror; no new child-data collection surface.

**UI hint**: yes
**Plans:** TBD

#### Phase 24: Submission readiness — offline and release hardening for the Technion submission

**Goal:** Close the milestone with the app ready for the Technion course submission (the
milestone's end state — owner, 2026-07-16): every flow works airplane-mode on a fresh install
(walker floor + AuthoredFallback + cached ML Kit model), the release build carries no child-PII
or stroke logging, the outstanding verification/UAT debt is swept (each item resolved or
explicitly waived), and the submission package (release build + docs) is assembled. Absorbs old
v1 Phase 10's intent, pointed at the submission instead of a public release.
**Mode:** build
**Depends on:** Phases 19–23
**Requirements**: PLAT-01 (v1 carry-over)
**Success Criteria** (what must be TRUE):

  1. A fresh-install airplane-mode walkthrough passes every flow (or explicitly handles the one-time model download at onboarding).
  2. The release build is audited: no child-PII/stroke logging; child data stays app-private.
  3. The verification/UAT debt ledger reaches zero — each item resolved or waived with a recorded reason.
  4. The submission package is built and handed over.

**Plans:** TBD

#### Phase 25: Trusted content — the seen-letters wall + the mother's confirmation

**Goal:** Content becomes something the app can TRUST, mechanically. Two legs. **The wall**
— the owner's rule (*a question may only demand letters the child has already seen*) is
enforced at every layer instead of aspirational (the 2026-07-19 audit found 34 live cards
violating it or using unlabeled words): L0 generate `letters[]` for every word/inflection
any exercise references (mother-reviewable diff); L1 the learned-letters lint holds EVERY
letter — draft exemption removed, the 34 cards re-pointed/removed/excepted, the baa
allowlist reduced to mother-approved exceptions only; L2 `seed_curriculum_v2.py` refuses
violating content (closes the Firestore-first bypass); L3 the runtime guard — the
walker/selector never presents an illegal card even if bad data ships (skip vs substitute
vs tier-down decided with the owner in discuss-phase; the star always stays reachable;
every firing logged loudly). **The confirmation** — every demo-night owner-directed change
goes back to the mother as one packet: minCleanReps=1 across all graphs (including baa's
signed spec), the buildSentence removals (baa/taa/thaa), the alif letter-level shrink + the
new `alif.writeLetter.fromPicture` draft card, and Lane B's image re-points / feedback
rewordings (each carries an inline `_review` note). Her verdicts are ingested: signedOff
flips where she confirms; anything she rejects is restored or re-worked to her instruction.
**Mode:** build (autonomous:false on every mother verdict + the L3 degradation decision)
**Depends on:** the finalization content state (landed 2026-07-19)
**Requirements:** QP-07 / D-12 (universal), CUR-01 lineage (curriculum authority)
**Success Criteria** (what must be TRUE):

  1. The audit script reports ZERO unlabeled words and ZERO violating cards; the lint covers every letter with no draft exemption; the allowlist holds only mother-approved exceptions (id + reason each).
  2. The seeder rejects a crafted violating fixture (proven by test) — nothing can reach prod Firestore that the bundle lint would refuse.
  3. A live-path test seeds an illegal card via the data path and proves the walker never presents it, the star stays reachable, and the guard logs loudly.
  4. The mother's packet covers every owner-directed change since her last sign-off; every verdict is recorded; signedOff flags match her answers exactly; rejected changes are restored or re-worked.

**Plans:** 6/7 plans executed
Plans:

- [x] 25-01-PLAN.md — L0: the shared learned-letters predicate + audit build-gate (validate.py)
- [x] 25-02-PLAN.md — the 34-card triage (re-point/remove) + the new alif.writeLetter.fromPicture draft card
- [x] 25-03-PLAN.md — L1: the lint enforces every live letter (signedOff decoupled from enforcement)
- [x] 25-04-PLAN.md — L2: the seeder learned-letters refusal + a crafted-fixture test
- [x] 25-05-PLAN.md — L3: the runtime guard (skip illegal, star-reachable, loud log) + live-path test [autonomous:false — L3 decision gate]
- [x] 25-06-PLAN.md — the mother's packet assembly + baa honest-state flip
- [ ] 25-07-PLAN.md — the mother's walkthrough + verdict ingestion + conditional server redeploy [autonomous:false — mother verdicts]

**Research hint:** no — the mechanism is known; the L3 degradation choice is a discuss-phase decision, not research.

#### Phase 26: The finished experience — entry, polish, and the 2.0.1 release

**Goal:** The app FEELS finished the moment it opens. **Entry & identity** — resolve the
Decided-vs-as-built contradiction (the Decided architecture says children never log in and
anonymous suffices; the live router makes a parent account the front door — discovered
2026-07-19 when sign-out stranded the owner at /auth). The OWNER decides the entry model;
then router, sign-out behavior (never strand anyone), the published legal pages, and the
Play declarations (app access, data safety) all state the same model — zero contradictions.
**Polish** — the real Qalam adaptive launcher icon on Android + iOS (the app still ships
the Flutter default; the Play listing already has the store mark), matched to the listing
art. **Coaching quality** — re-tighten the widened scorer thresholds (tcc/tcw 0.12/0.16 →
originals, driven by device feel + the mother-labelled calibration set, or explicitly
re-affirm with reason) and close the two standing tutor-feedback debts (gold exemplars
copied verbatim; the bottom feedback bar showing the authored line instead of the agent
line). **Verification** — the Android device pass the submission skipped: alif→thaa walk
with fail→retry, two-profile isolation spot-check, and the course's v1.x→2.x
update-must-not-crash check. Ships as **2.0.1+4** — cut ONLY after grading; Play and
webcourse artifacts move in lockstep or not at all.
**Mode:** build (autonomous:false on the entry-model decision)
**Depends on:** Phase 25 (ships its confirmed content); grading freeze for the release cut
**Requirements:** D-09b/D-09c lineage (child-login ban, anonymous boot), PLAT-01 lineage, Phase-14/17 feedback debt
**Success Criteria** (what must be TRUE):

  1. A recorded owner decision names the entry model; router + sign-out implement exactly it; legal pages and Play forms agree with the code word for word; fresh-install and sign-out verified on device.
  2. The Qalam mark is the launcher icon on both platforms — no Flutter default anywhere.
  3. tcc/tcw re-tightened (or re-affirmed) with the decision recorded against calibration data; the tutor's on-screen line is the agent's line and repeated attempts produce non-verbatim coaching.
  4. The Android pass is green: 4-letter walk incl. fail→retry, profile isolation, and v1→v2 update opens without crashing.
  5. 2.0.1+4 is live on Play production with the matching APK archived.

**Plans:** TBD
**Research hint:** no — decision + alignment + known fixes.

#### Phase 27: The whole alphabet — 24 letters in mother-signed batches

**Goal:** Every remaining letter goes live as DATA through the Phase-25 wall: drafts
(18.1 already produced exercises, graphs, packets, and audio for the full alphabet) are
promoted batch by batch in the mother's intro order via `promote_letter.py`, each batch
passing the labels/lint/seeder gates by construction, reviewed and signed by the mother
before it ships live. The tutor server is un-fenced per signed batch (`generate.py` emits
that batch's data; the D-11 guard widens with it) so live AI coaching follows the content —
never coaching on unsigned drafts. Journey/home/mastery need NO code: the Lane-A
letter-generic engine makes each letter a pure data operation (that is the point of it).
**Mode:** build (autonomous:false on every batch sign-off)
**Depends on:** Phase 25 (the wall + the confirmation cadence), Phase 26 (a release train exists for bundle updates)
**Requirements:** absorbs old Phase 21; CUR-01
**Success Criteria** (what must be TRUE):

  1. All 28 letters have live, lint-clean content; every non-draft letter is mother-signed; any letter still in draft is explicitly marked and excluded from the default journey.
  2. Each batch entered through the wall: zero violations at promote time, proven by the audit in CI.
  3. The tutor server serves per-letter data for every signed batch, with baa's behavior regression-guarded at each widening.
  4. A child can walk the journey from alif through the final signed letter — mastery rows, stars, and unlocks all data-driven, no letter-id literals anywhere.

**Plans:** TBD
**Research hint:** no — the pipeline exists; this is disciplined batch execution with the mother.

#### Phase 28: Smart across letters + the parent window

**Goal:** With the full alphabet live, the tutor gets its memory and the parents get their
window. **Cross-letter selection** (S2-04) — selection and remediation reason across
letters: a child struggling with bowls on taa is remembered from baa; the per-criterion EMA
child model (built in Phase 18, letter-agnostic by design) drives it. **Next-day planner**
(S2-05) — the nightly Cloud Run job composes tomorrow's prepared lesson from the child
model + curriculum position, so opening the app tomorrow starts exactly where it should.
**Parent window** (S2-06) — the PIN-gated dashboard surfaces the compiled strengths[] /
struggles[] per letter and criterion, in the same warm, specific voice as the tutor
(weekly report optional stretch).
**Mode:** build
**Depends on:** Phase 27 (content breadth to reason across), Phase 18 (the two-timescale child model + nightly compiler)
**Requirements:** S2-04, S2-05, S2-06 (absorbs old Phases 22 + 23)
**Success Criteria** (what must be TRUE):

  1. A cross-letter struggle provably influences selection (live-path test: struggle seeded on letter A changes what letter B presents, with the WHY line naming it).
  2. The nightly job emits tomorrow's prepared unit per child; the app opens INTO it; a child with no history gets the sensible default.
  3. The parent dashboard renders the real compiled model (strengths/struggles per letter/criterion) behind the PIN, readable by a non-technical parent.
  4. Non-PII posture holds everywhere (payload guards extend to the new surfaces).

**Plans:** TBD
**Research hint:** yes — light: dashboard information design for non-technical parents (what a parent can act on, not raw EMAs).

#### Phase 29: Hardening + milestone close

**Goal:** The app is genuinely FINISHED: it survives the real world and the debt ledger
reads zero. A fresh-install airplane-mode walkthrough passes every flow (walker floor +
AuthoredFallback + the one-time ML Kit model download handled explicitly at onboarding);
the release build is audited — no child PII, no stroke logging, child data app-private;
the standing verification/UAT debt ledger (including Phase-16's eval-trust legs: gold-set
sign-off + judge calibration, and any 18-11 residue: constants sign-off, cost/latency
close-out) is swept — each item resolved or explicitly waived with a recorded reason; and
the final release ships with the docs that make the project handover-able (README,
architecture, ADRs current).
**Mode:** build
**Depends on:** Phases 25–28
**Requirements:** PLAT-01 (v1 carry-over); absorbs old Phase 24's residue
**Success Criteria** (what must be TRUE):

  1. Fresh install + airplane mode: every flow works or degrades warmly by design (recorded walkthrough).
  2. Release-build audit: zero child-PII/stroke logging; storage audit recorded.
  3. The debt ledger reaches zero — every open verification item resolved or waived with reason, including the eval-trust legs.
  4. The final release is live and the repo docs (README/architecture/ADRs) match what shipped.

**Plans:** TBD
**Research hint:** no.

### Progress (v2.0)

**Execution Order:**
11 (GATE, done) → **14 (build the server-side LangGraph spine)** → 12 (measure the deployed round-trip latency) → 13 (eval harness + coach-node model bake-off) → 15 (dynamic selection) → 16 (presence/voice/eval-gate/demo). The latency + eval spikes (12/13) now follow the build because they measure/score the **deployed** server (ADR-015) — the architecture decision moved from a pre-build spike to ADR-014/015 + the AI-SPEC.

**Closing arc (added 2026-07-16, post-demo):** 18 close-out → 19 (presentation overhaul) →
20 (all-letters graph + pipeline) → 21 (content batches) → 22 (cross-letter selection +
next-day planner) → 23 (parent insight) → 24 (submission readiness). The Technion demo
passed on the Phase-18 build; the milestone now ends when the app is **submission-ready**.
Phase 12 was absorbed by 18-11's measured cost/latency closure and Phase 13 by 16-03's eval
harness (both retained above for the historical record, never to be executed as written);
Phase 16's surviving work is the eval-trust legs (gold-set sign-off + judge calibration) —
re-scope before executing; DEMO-01's demo-harden pressure is moot. Ask-Qalam voice (S2-03)
is DROPPED from this milestone's scope (owner, 2026-07-16).

**The finishing arc (reorganized 2026-07-19 at the owner's direction — five consolidated
phases, run strictly one after the other):**
**25 (Trusted content)** → **26 (The finished experience — ships 2.0.1+4 after grading)**
→ **27 (The whole alphabet)** → **28 (Smart across letters + the parent window)** →
**29 (Hardening + milestone close)**. Old Phases 20–24 are absorbed/superseded into this
arc (annotated above; details retained for the historical record — never execute them as
written). Standing rule until grading closes: the frozen release/2.0 branch, the submitted
AAB, and the webcourse APK are untouchable — all new work lands on main.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 11. SPIKE — GenUI catalog + native stylus canvas | 3/3 | Complete    | 2026-06-22 |
| 12. SPIKE — full-path latency & presence budget | 0/TBD | Absorbed (18-11 closes cost/latency) | - |
| 13. SPIKE — 3-way bake-off (grounding + Arabic) | 0/TBD | Absorbed (16-03 built the harness) | - |
| 14. BUILD — TutorBrain spine + grounding invariant | 4/4 | Complete   | 2026-06-22 |
| 15. BUILD — dynamic grounded exercise selection on baa | 8/7 | Complete    | 2026-06-28 |
| 16. BUILD — presence + voice + eval gate + demo-harden | 3/6 | In Progress (re-scope: eval-trust legs survive; demo-harden moot) |  |
| 17. BUILD — stroke-aware coaching (on-device geo-diff → coach) | 10/10 | Complete   | 2026-07-06 |
| 18. BUILD — the living tutor (per-child dynamic exercise selection) | 15/16 | In Progress|  |
| 19. Question presentation overhaul | 6/6 | Complete    | 2026-07-18 |
| 20. Curriculum graph + pipeline for all 28 letters | - | Absorbed (18.1 + finalization Lane A delivered it) | 2026-07-19 |
| 21. Letter content at scale | - | Superseded → 27 | - |
| 22. Cross-letter selection + next-day planner | - | Superseded → 28 | - |
| 23. Parent insight dashboard | - | Superseded → 28 | - |
| 24. Submission readiness | - | Superseded: submission SHIPPED 2026-07-19; residue → 29 | - |
| 25. Trusted content — seen-letters wall + mother's confirmation | 6/7 | In Progress|  |
| 26. The finished experience — entry, polish, 2.0.1 release | 0/TBD | Not started | - |
| 27. The whole alphabet — 24 letters in signed batches | 0/TBD | Not started | - |
| 28. Smart across letters + the parent window | 0/TBD | Not started | - |
| 29. Hardening + milestone close | 0/TBD | Not started | - |

**Coverage:** the 14 original v2.0 requirements map across Phases 14–16; Phase 17 (added 2026-06-30 from the stroke-aware spike) adds STRK-01 / GROUND-04 / EVAL-03. The three spikes (11–13) own no requirements by design. The closing arc (19–24, added 2026-07-16) picks up CUR-01 + PLAT-01 (v1 carry-overs) and S2-04 / S2-05 / S2-06 (S2-10 optional); S2-03 (ask-Qalam voice) is out of scope this milestone. See REQUIREMENTS.md → v2.0 Traceability.
