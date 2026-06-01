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
- [ ] **Phase 2: Curriculum Schema & First-Letter Seed** - A faithful curriculum data schema plus a small owner's-mother-signed-off seed (forms, reference stroke paths, common mistakes) for the first letters.
- [x] **Phase 02.1: Stroke Reference Correction** (INSERTED) - Replace broken glyph-outline reference strokes with correct open-centerline teaching strokes; in-app authoring trace screen, schema `type` field + closed-loop validator, and a re-signed-off alif. Unblocks Phase 3. (completed 2026-06-01)
- [ ] **Phase 3: Trace One Letter End-to-End** - A child can watch the stroke-order animation, trace a real seeded letter, get on-device geometric feedback, and earn a quiet star — the whole loop, thin.
- [ ] **Phase 4: Scoring Quality & Calibration** - The scorer rejects wrong-order/sloppy work and accepts good-faith child attempts, with per-letter tolerances calibrated against real child samples with the owner's mother.
- [ ] **Phase 5: Profiles & Onboarding** - A parent creates a local child profile (name + grade), and the child picks an avatar and nickname on first open.
- [ ] **Phase 6: Lesson Progression & Home** - On open the child sees today's prepared lesson with one Start; the next lesson unlocks only after passing the current one.
- [ ] **Phase 7: Full Curriculum & Pronunciation Audio** - The complete 28-letter + words curriculum is authored and signed off, and the child can hear bundled pronunciation for each letter and word.
- [ ] **Phase 8: Sentence-Building & Grammar Exercises** - The child completes handwriting-first sentence-building and level-appropriate grammar exercises drawn from the curriculum.
- [ ] **Phase 9: Parent Dashboard** - A parent enters a PIN and sees a read-only view of the child's completed lessons and scores.
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

- [ ] 02-01-PLAN.md — Wave 1: Python extraction script + 28-letter letters.json + lessons.json skeleton + pubspec asset declaration + owner sign-off checkpoint for alif
- [ ] 02-02-PLAN.md — Wave 2: Typed Dart models (Letter, Lesson, sub-types) + unit tests
- [ ] 02-03-PLAN.md — Wave 3: CurriculumRepository (rootBundle loader, Riverpod provider) + integration tests + Phase 2 completeness gate

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

**Plans**: 4 plansPlans:
**Wave 1**

- [ ] 03-01-PLAN.md — Wave 1 (TDD): pure-Dart geometric stroke scorer + resampler + named-mistake mapping (S1-05)
- [ ] 03-02-PLAN.md — Wave 1: Drift LetterMastery table + 1→2 migration + ProgressRepository (S1-10/D-09)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 03-03-PLAN.md — Wave 2: stylus-filtered capture canvas + dotted guide + PathMetric stroke-order animation + recognizer seam (S1-04/S1-05/D-13/D-16)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 03-04-PLAN.md — Wave 3: Watch→Trace→Celebrate flow + session controller + one-star celebration + anti-gamification omissions (S1-04/S1-05/S1-10/PLAT-03)

**UI hint**: yes
**Research hint**: yes — DEEPEST-RISK PHASE. The custom geometric stroke-order/shape scorer is NOT provided by ML Kit (ML Kit returns only {text, score} as a secondary letter-identity check). Stroke capture must use low-level pointer events (not GestureDetector) to preserve per-stroke order/count; the ML Kit Arabic model must be downloaded-and-cached before first scoring. Flag for deep iteration with the owner's mother.

### Phase 4: Scoring Quality & Calibration

**Goal**: The geometric scorer is tuned to the right strictness: it firmly rejects wrong stroke order and wrong stroke count and sloppy shapes, while accepting good-faith age-appropriate attempts, with per-letter pass tolerances calibrated against real child handwriting samples together with the owner's mother.
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: (deepens S1-05 and PLAT-03 from Phase 3; no new requirement IDs)
**Success Criteria** (what must be TRUE):

  1. A correct-shape-but-wrong-stroke-order or wrong-stroke-count attempt is rejected, with the message naming the specific problem.
  2. A scribble or clearly-wrong letter is rejected (ML Kit identity check catches "wrote a completely different letter").
  3. A good-faith, size-and-position-varied child attempt passes (normalization prevents penalizing small/offset-but-correct letters).
  4. Pass tolerances are per-letter curriculum data the owner's mother can adjust without a code change, and regression tests encode the named common mistakes.

**Plans**: TBD
**Research hint**: yes — false-negative and false-positive rates must be tuned separately and per-letter against labeled child samples; this is a dedicated calibration step with the owner's mother, not a code constant.

### Phase 5: Profiles & Onboarding

**Goal**: A parent can create a local child profile with name and grade (grade selecting the curriculum entry point), and on first open the child picks an avatar and nickname — all persisted locally with minimum child data.
**Mode:** mvp
**Depends on**: Phase 1 (DB), benefits from Phase 2 (grade→entry mapping)
**Requirements**: S1-02, S1-03
**Success Criteria** (what must be TRUE):

  1. A parent can create a child profile with name and grade; it persists across restarts, and the grade maps to a starting lesson.
  2. The child can pick an avatar and a nickname from a fixed set (no free-text identity leak); the choice persists and shows on the home surface.
  3. Child data is stored in app-private local storage only, with no cloud, no account, and no real-name exposure beyond the device.

**Plans**: TBD
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

**Plans**: TBD
**UI hint**: yes

### Phase 7: Full Curriculum & Pronunciation Audio

**Goal**: The complete curriculum — all 28 letters plus words, in the owner's mother's intro order, with full stroke specs, tolerances, and common mistakes — is authored, validated, and signed off, replacing the seed; and the child can tap to hear bundled pre-recorded pronunciation for each letter and word, fully offline.
**Mode:** mvp
**Depends on**: Phase 2 (schema), Phase 4 (scorer applies to all letters)
**Requirements**: CUR-01, S1-06
**Success Criteria** (what must be TRUE):

  1. All 28 letters (plus words content) load from the curriculum data with full forms, reference stroke paths, stroke order, intro order, clean-reps-to-advance, per-letter tolerances, and 3–4 common mistakes each.
  2. No silently-fake pedagogy ships: every entry is the owner's-mother's spec or explicitly marked placeholder, and the full set carries her sign-off.
  3. The child can tap a letter or word and hear its correct pre-recorded pronunciation, working offline, with no TTS.

**Plans**: TBD
**Research hint**: yes — completing the full reference-path content for all 28 letters depends on the format resolved in Phase 2; if coordinate paths must be authored, this is where the bulk of that content work lands, gated by the owner's-mother sign-off.

### Phase 8: Sentence-Building & Grammar Exercises

**Goal**: The child can complete handwriting-first sentence-building exercises (showing how Arabic words connect to form meaning) and level-appropriate grammar exercises, with all content authored in the curriculum — never reduced to tap-one-of-four.
**Mode:** mvp
**Depends on**: Phase 3 (handwriting interaction), Phase 7 (exercise content)
**Requirements**: S1-07, S1-08
**Success Criteria** (what must be TRUE):

  1. The child can complete a sentence-building exercise using a handwriting-first interaction, with content drawn from the curriculum.
  2. The child can complete a grammar exercise appropriate to their progression level, authored in the curriculum (not invented in code).
  3. Neither exercise type degrades into multiple-choice tap-the-answer (the anti-product).

**Plans**: TBD
**UI hint**: yes

### Phase 9: Parent Dashboard

**Goal**: A parent can enter a PIN to reach a read-only local area showing the child's completed lessons and scores — no cloud, no account.
**Mode:** mvp
**Depends on**: Phase 5 (profiles), Phase 6 (progress recorded)
**Requirements**: S1-11
**Success Criteria** (what must be TRUE):

  1. The parent area is reachable only after entering a PIN; the child cannot reach it without it.
  2. The parent sees a read-only list of completed lessons and their scores for the child, sourced from local storage.
  3. No cloud, account, or network is involved, and the PIN is stored hashed locally (not an account).

**Plans**: TBD
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

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundations & RTL Shell | 3/3 | Complete   | 2026-05-31 |
| 2. Curriculum Schema & First-Letter Seed | 0/3 | Planned | - |
| 3. Trace One Letter End-to-End | 0/4 | Planned | - |
| 4. Scoring Quality & Calibration | 0/TBD | Not started | - |
| 5. Profiles & Onboarding | 0/TBD | Not started | - |
| 6. Lesson Progression & Home | 0/TBD | Not started | - |
| 7. Full Curriculum & Pronunciation Audio | 0/TBD | Not started | - |
| 8. Sentence-Building & Grammar Exercises | 0/TBD | Not started | - |
| 9. Parent Dashboard | 0/TBD | Not started | - |
| 10. Offline Hardening & Release | 0/TBD | Not started | - |
