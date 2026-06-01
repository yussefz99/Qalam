# Phase 3: Trace One Letter End-to-End - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the full core learning loop, thin, for **alif** (the one signed-off letter):
the child watches a replayable stroke-order animation, traces the dotted guide with a
stylus, receives instant on-device geometric feedback per stroke (failing stroke
highlighted + a specific named fix in the tutor's voice, < ~300 ms after stylus-up,
fully offline), and earns a single quiet **mastery star** after 3 clean reps — with a
dignified full-screen celebration. The trace flow is built **pixel-faithfully to the
owner's Claude Design** (`docs/design/kit/`).

**In scope:**
- The **practice/trace flow screens** built faithfully to the design:
  - "Watch me write" stroke-order animation step (`02-flow` mockup)
  - "Now you trace" stylus tracing step over the dotted guide (`03-flow` mockup)
  - The mastery celebration moment (faithful to the celebration design, minus the
    running star counter)
- A minimal **"Start" entry point** to reach the flow (e.g. wired off the existing
  Home shell's lesson card / a dev route) — NOT a rebuilt Home.
- The **custom geometric stroke scorer** (pure Dart): stroke count, order, direction,
  shape deviation vs alif's `referenceStrokes`; maps failures to alif's named
  `commonMistakes` (`too_short` / `wrong_direction` / `too_curved`).
- **Stylus capture** via low-level pointer events (not GestureDetector), preserving
  per-stroke order/count; **stylus-only in production** with a **debug flag to allow
  finger input** for development.
- The **stroke-order animation engine**: an animated pen-tip traces alif's reference
  path on the dotted guide, driven by the SAME `referenceStrokes` used for scoring.
- **Clean-rep counting (3 → mastery)** and **persistence of alif mastery to Drift**.
- The quiet **mastery star** + **dignified full-screen celebration**.

**Out of scope (later phases):**
- **ML Kit** wiring and its one-time model download-and-cache → **Phase 4** (the
  HandwritingRecognizer seam is left ready, but no ML Kit in Phase 3).
- **Scorer calibration / strictness tuning** against real child samples with the
  owner's mother → **Phase 4** (Phase 3 ships a deliberately lenient first-cut).
- A *fully* rebuilt **Home** with real profiles (Phase 5) and progression/journey data
  (Phase 6). **Amended by D-17:** a presentable **demo home shell** (de-gamified, static
  greeting, locked future nav) IS pulled into Phase 3 for the 2026-06-02 meeting; the
  data-backed Home is still Phase 5/6.
- The **Journey / alphabet map** where the star normally lands → **Phase 6**.
- **Pronunciation audio** / the "Play sound" button → **Phase 7** (no audio assets
  exist yet; the button is omitted in Phase 3).
- **Parent dashboard** → Phase 9. **Multi-letter / second letter** → Phases 6–7.

</domain>

<decisions>
## Implementation Decisions

### UI scope & fidelity (the owner's question: "why not build the whole UI now?")

- **D-01:** Phase 3 builds **only the trace flow** (Watch → Trace → Celebrate),
  **faithfully to the owner's Claude Design** in `docs/design/kit/` — not throwaway UI.
  Home/Journey/Parent stay as Phase-1 shells and get built for real in Phases 5/6/9
  when their backing data (profiles, progression, dashboard) exists. Rationale agreed
  with owner: the roadmap is intentionally **vertical slices** — building hollow
  Home/Journey screens now would be facades over non-existent data that get reworked.
  Same destination (the full design); each later phase "lights up" more of it with real
  data underneath.
- **D-02:** The trace flow is reachable from a **minimal entry point** (the existing
  Home shell's lesson card / a dev route to `lesson_01`). Do NOT rebuild Home in this
  phase.

### Anti-gamification — star display (FLAGGED contradiction, resolved)

- **D-03:** The owner's design screenshots (dated **2026-05-24**) show a running star
  total ("⭐ 39"), "stars this week" tallies, and a weekly progress bar. These
  **contradict the Decided anti-gamification rules** in CLAUDE.md (no running totals,
  no weekly tallies, no streaks). The design **predates** the design-system
  reconciliation (owner's call, **2026-05-30**). **Resolution (owner, 2026-06-01):**
  follow the Decided rules — **a star marks real mastery of a letter only**; **NO**
  running counter, **NO** "stars this week", **NO** weekly bar. Build the trace screens
  from the design but **omit the gamification chrome in the header**. (Design assets may
  be updated to match; they are not "wrong," just pre-decision.)

### Feedback & retry flow

- **D-04:** **Per-stroke feedback.** The child traces one stroke, lifts the pen, and
  gets instant feedback on THAT stroke (good → advance to next stroke; off → the named
  fix + retry that same stroke). Matches the design's "Stroke X of N" UI. For alif (one
  stroke) this is a single judgement, but the model is built for multi-stroke letters.
- **D-05:** **On a miss: hold, show the fix, let them retry.** The failing stroke is
  highlighted, the named fix appears in the tutor's voice (e.g. "Start your alif at the
  top and come down — not from the bottom up."), the child's ink clears, and they retry
  the SAME stroke. **Unlimited gentle retries — no fail state, no try-counter, no
  pressure.** (Optional gentle "show me again" replay after repeated misses is a
  nice-to-have, not required.)
- **D-06:** The **"Mark correct" button** in the design's trace mockup is a
  design/dev placeholder — **drop it**. Pass/fail comes only from the geometric scorer;
  the child cannot self-declare success.

### Star, clean-reps & celebration

- **D-07:** **3 clean reps → 1 mastery star.** Honour the curriculum: the child traces
  alif cleanly 3 times in the session (1/3, 2/3, 3/3); the single mastery star +
  celebration come after the 3rd clean rep. One star = "you mastered alif" (per S1-10).
  Uses alif's `cleanRepsToAdvance: 3`.
- **D-08:** **Dignified full-screen celebration:** a calm full-screen moment — the
  qalam mascot, the mastered alif, one gold star settling in, a warm line (e.g. "You
  learned alif. أحسنت."), then back to Done/Home. **No confetti spam, no sound blast, no
  running counter.** Built faithfully to the celebration design.
- **D-09:** **Persist alif mastery + clean-rep count to Drift now** (the Phase-1
  persistence seam exists). Phase 6's journey map will read it. Proves the loop
  end-to-end including "it remembers" across restarts.

### Animation & demo style

- **D-10:** **Auto-play once, then Replay.** On entering the "Watch me write" step the
  demo plays once automatically; the child can Replay / "Watch again" freely, then
  "I'll try" to start tracing. Matches the design and the show-then-invite rhythm.
- **D-11:** **Animated pen-tip traces the path on the guide.** A moving marker draws
  the stroke along alif's reference path on the dotted guide, starting at the numbered
  gold start-dot, in the correct direction — driven by the **SAME `referenceStrokes`
  used for scoring** (S1-04 requires one source of truth). The qalam mascot stands
  beside as the tutor persona (per CLAUDE.md — pedagogical, not a game character).
- **D-12:** **Omit the audio / "Play sound" button in Phase 3.** No audio assets exist
  (alif's audio is empty); pronunciation is explicitly Phase 7. The button returns,
  wired to real recordings, in Phase 7 — no dead button now.

### Input & palm rejection

- **D-13:** **Stylus-only in production; finger allowed in a debug flag.** Real builds
  capture stylus only and ignore touch — **palm rejection comes free** (a resting palm
  is a touch event, not a stylus event). A **debug/dev flag** lets finger input through
  so the owner can develop and test on a **finger-only tablet/emulator** (their actual
  test hardware — no active stylus). The scorer treats both input sources identically.
- **D-14:** Because the owner tests with a **finger**, the debug-finger path must be
  easy to enable and the loop must be fully exercisable without a stylus. Do not let
  stylus-only filtering silently block all input during development.

### Scope boundary with Phase 4 (carried forward, confirmed)

- **D-15:** **Phase 3 wires the scorer; Phase 4 calibrates it.** Ship a deliberately
  **lenient first-cut** threshold so good-faith child attempts pass; real per-letter
  tolerance tuning against labeled child samples (with the owner's mother) is Phase 4.
- **D-16:** **ML Kit deferred to Phase 4.** Phase 3 is a **pure geometric scorer,
  fully offline, zero network**. ML Kit's secondary "wrote a completely different
  letter" identity check and its one-time model download-and-cache land in Phase 4
  (Phase 4 SC#2). Leave the `HandwritingRecognizer` interface seam ready but
  unimplemented-by-ML-Kit in Phase 3. This isolates the flagged model-download risk
  out of the deepest-risk phase.

### Demo home screen (added 2026-06-01 — pulled forward for course-staff meeting)

- **D-17:** **A presentable "demo home" is pulled forward into Phase 3**, amending D-02's
  "minimal Start entry point / NOT a rebuilt Home." Rationale: a crucial course-staff
  meeting on 2026-06-02 needs a partial app that *feels* real — Home → Watch → Trace →
  Celebrate → Home. This supersedes the "rebuilt Home → Phase 5/6" out-of-scope line for
  the **demo shell only** (no profiles, no real progression data — those stay Phase 5/6).
  Built faithfully to `docs/design/kit/project/screenshots/home.png` **warmth** (mascot,
  "Welcome back", a "Today's lesson" card showing the **alif** glyph that taps into the
  trace flow at `lesson_01`), with these binding constraints:
  - **De-gamified (owner's call):** OMIT the header running-star counter ("⭐ 39"), the
    "THIS WEEK · N stars" weekly tally + weekly progress bar, and the per-lesson 3-star
    rating on the lesson card. Consistent with D-03/D-08, PLAT-03, and
    [[design-predates-antigamification]]. Stars remain mastery-only.
  - **No dead routes:** the **Journey** and **Parent** side-nav items and any "See
    journey" affordance render as visibly **"Coming soon" / locked** (disabled, not
    wired) — they signal the roadmap without breaking. Journey is Phase 6, Parent Phase 9.
  - The greeting name is a **static placeholder** (no profile system yet, Phase 5); do
    not invent a fake stars/lessons dataset to populate omitted widgets.

### Claude's Discretion

- Exact smoothing/resampling and shape-distance algorithm for the geometric scorer
  (Procrustes / Fréchet-style vs simpler resampled point distance) — planner/researcher
  choice; Phase 4 tunes it anyway.
- Exact Drift schema shape for recording mastery + clean-rep count (D-09).
- Precise visual treatment of the animated pen-tip and celebration motion (within the
  design's look) — UI designer's call.
- How the named `commonMistakes` checks (`strokeLengthBelowThreshold`,
  `strokeDirectionInverted`, `strokeCurvatureExceedsThreshold`) map to concrete scorer
  predicates and their first-cut thresholds (lenient default per D-15).
- Riverpod structure for the session (`practiceSessionController` family by lessonId,
  separate high-frequency stroke-capture provider) — per research ARCHITECTURE.md.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The scoring pipeline & component architecture (the deepest-risk design)
- `.planning/research/ARCHITECTURE.md` §"Component Breakdown" / §"Scoring pipeline" —
  defines `StrokeCanvas`, `practiceSessionController`, `ScoringService`,
  `GeometricStrokeScorer`, `HandwritingRecognizer` (interface) + `MlKitRecognizer`
  (v1 impl, **deferred to Phase 4 per D-16**), `ProgressRepository`; the
  "two judges on the same Ink" model; the pointer→StrokePoint capture flow
- `.planning/research/PITFALLS.md` §Pitfall 1 (don't over-trust ML Kit), §Pitfall 2
  (capture from low-level pointer events, NOT GestureDetector), §Pitfall 3 (too strict
  = false negatives that make a child quit), §Pitfall 4 (too lenient), §Pitfall 7
  (anti-gamification erosion + generic feedback) — directly govern this phase
- `.planning/research/STACK.md` — prescriptive packages/versions (verify at plan time)

### Requirements & scope
- `.planning/ROADMAP.md` §"Phase 3: Trace One Letter End-to-End" — success criteria +
  research hint (DEEPEST-RISK; pointer-level capture; ML Kit model download)
- `.planning/REQUIREMENTS.md` §S1-04 (replayable stroke-order animation, same paths as
  scoring), §S1-05 (stylus capture + instant on-device per-stroke feedback, named fix,
  < ~300 ms, offline), §S1-10 (mastery star via clean-reps), §PLAT-03
  (anti-gamification: no totals/tallies/streaks/badges/confetti, specific feedback)
- `.planning/PROJECT.md` §"The tutor's voice" + §"Decided" (anti-gamification reconcil.
  2026-05-30; mascot = tutor persona; stars = mastery markers)

### The design (canonical product visuals — build the trace flow to these)
- `docs/design/kit/` — **canonical source of truth for product visuals & feel**
- `docs/design/kit/project/screenshots/02-flow.png` — "Watch me write" stroke-order
  animation screen (mascot beside, numbered gold start-dot, Replay / "I'll try")
- `docs/design/kit/project/screenshots/03-flow.png` — "Now you trace" tracing screen
  over the dotted guide ("Stroke X of N", Replay, Try again; **"Mark correct" dropped
  per D-06; "Play sound" omitted per D-12; running "39" counter omitted per D-03**)
- `docs/design/kit/project/screenshots/01-celebration*.png` + celebration variants —
  the mastery celebration (build dignified version, no counter)
- `docs/design/kit/project/SKILL.md` — brand hard-rules (gold = rewards-only, no red,
  coral not red, Western numerals, no emoji/pseudo-icons)
- `docs/design/kit/project/colors_and_type.css` — design tokens

### Curriculum data (the one source of truth for paths)
- `assets/curriculum/letters.json` — alif entry: 1 `referenceStroke` (`vertical_stroke`,
  `topToBottom`, 64 normalized 0..1 points), `cleanRepsToAdvance: 3`, 3 authored
  `commonMistakes` (`too_short`/`wrong_direction`/`too_curved`), `signedOff: true`
- `assets/curriculum/lessons.json` — `lesson_01` (alif) — the Phase 3 boot target
- `lib/models/letter.dart`, `lib/models/lesson.dart` — typed read-only models
- `lib/data/curriculum_repository.dart` — `rootBundle` loader + keepAlive Riverpod
  provider; `getLesson("lesson_01")` → alif (Phase 2, D-10)

### Conventions & existing code
- `.planning/codebase/CONVENTIONS.md` — Dart naming, import rules (models import
  nothing from data/features)
- `.planning/codebase/STRUCTURE.md` — current `lib/` layout
- `.planning/phases/02-curriculum-schema-first-letter-seed/02-CONTEXT.md` — curriculum
  schema decisions; reference paths normalized to per-letter 0..1 bounding box

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/practice_screen.dart` — **the Phase-1 stylus ink spike**. Already does:
  pointer-event capture via `Listener` (not GestureDetector), per-stroke point lists
  (`List<List<Offset>>`), quadratic-smoothed ink rendering on parchment via
  `CustomPainter`, in-memory-only strokes (threat T-01-05), Clear-with-confirm. **This
  is the foundation** — Phase 3 extends it with the dotted guide, the animation, the
  scorer hook, stylus filtering, and the star. The existing capture already preserves
  per-stroke order/count (Pitfall 2 already respected).
- `lib/data/app_database.dart` — Drift DB + `@Riverpod(keepAlive: true)` provider; the
  persistence seam for recording mastery + clean-reps (D-09). Phase 1 proved
  persist/read across restart.
- `lib/data/curriculum_repository.dart` — loads alif from bundled JSON (Phase 2).
- Theme tokens: `lib/theme/colors.dart` (`inkStroke`, `primary`, parchment `bg`, gold
  reward token, coral `warnSoft`), `dimens.dart` (`QalamInk.strokeWidth`), text styles.
- `lib/widgets/arabic_text.dart` — RTL Arabic island widget (Phase 1).
- l10n: all copy via `AppLocalizations` (gen-l10n) — feedback/celebration strings go here.

### Established Patterns
- **Pointer capture via `Listener`** (NOT GestureDetector) is already the pattern —
  preserves stroke structure/order (Pitfall 2). Extend it to filter on
  `PointerDeviceKind.stylus` in production, debug-flag to allow touch (D-13/D-14).
- **Riverpod codegen** (`@riverpod` / `@Riverpod`) established (Phase 1).
- **In-memory-only stroke data** (T-01-05) — captured points are never persisted/logged
  /transmitted; only the derived mastery result is written to Drift (D-09).
- **No red, no emoji/pseudo-icons, gold = rewards-only** (D-13 brand rule, Phase 1).
- **All user-facing copy via gen-l10n** AppLocalizations.

### Integration Points
- New `practiceSessionController` (Riverpod Notifier, autoDispose, family by lessonId)
  → reads alif via `CurriculumRepository.getLesson("lesson_01")` → drives Watch/Trace/
  Celebrate states + clean-rep count.
- New `GeometricStrokeScorer` (pure Dart) ← consumes captured strokes + alif's
  `referenceStrokes` → emits per-stroke feedback mapped to `commonMistakes`.
- New `HandwritingRecognizer` interface seam — defined but ML-Kit impl deferred (D-16).
- Mastery result → `ProgressRepository`/Drift (D-09) → read by Phase 6 journey map.
- Entry point off the existing Home shell's lesson card / dev route (D-02).

</code_context>

<specifics>
## Specific Ideas

- Build the **"Watch me write"** and **"Now you trace"** screens to match
  `02-flow.png` and `03-flow.png` closely: mascot beside the canvas, numbered gold
  start-dot, "Stroke X of N" progress, Replay affordance — but **omit** the header star
  counter (D-03), the "Play sound" button (D-12), and the "Mark correct" button (D-06).
- The animated demo and the dotted guide and the scorer **all consume the same
  `referenceStrokes`** — one source of truth (S1-04). Reference points are normalized
  0..1; scale to the actual canvas at render time, and normalize the child's captured
  strokes the same way before scoring (so size/offset don't penalize a correct letter).
- Feedback strings come straight from alif's `commonMistakes[].feedback` — already
  authored in the tutor's warm, specific voice. The scorer's named `check` values map
  to predicates; a generic fallback ("Something looks off — try again, slower this
  time.") covers a miss with no matching named mistake.
- The celebration is **calm and dignified** (qalam + alif + one gold star + "أحسنت"),
  explicitly NOT confetti/streak/score energy (PLAT-03).
- Owner's **test hardware is finger-only** — the debug-finger flag (D-13/D-14) is not
  optional polish; it's required for the owner to run Phase 3 at all.

</specifics>

<deferred>
## Deferred Ideas

- **ML Kit identity check + model download-and-cache** → Phase 4 (D-16).
- **Scorer calibration / per-letter tolerance tuning** with the owner's mother → Phase 4.
- **Rebuilt Home screen** (real child + today's lesson) → Phase 5/6.
- **Journey / alphabet map** (where the mastery star lands) → Phase 6.
- **Pronunciation audio + "Play sound" button** → Phase 7.
- **Parent dashboard** → Phase 9.
- **Updating the design assets** to remove the running star counter / weekly tallies so
  the mockups match the Decided anti-gamification rules → housekeeping, not Phase 3 code.
- **Gentle "show me again" auto-replay after repeated misses** (D-05) → optional polish,
  candidate for Phase 4's UX pass.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 3-Trace One Letter End-to-End*
*Context gathered: 2026-06-01*
