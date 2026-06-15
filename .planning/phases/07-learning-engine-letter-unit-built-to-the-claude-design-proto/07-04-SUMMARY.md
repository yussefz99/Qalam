---
phase: 07-learning-engine-letter-unit-built-to-the-claude-design-proto
plan: 04
subsystem: ui
tags: [flutter, riverpod, letter-unit, exercise-components, rtl, design-system, anti-gamification]

# Dependency graph
requires:
  - phase: 07-01
    provides: the Schema-v2 Exercise/PromptPart/Surface/Answer/Check/Policy models + the additive Letter.contextualForms Form objects
  - phase: 07-03
    provides: validateExercise + CheckResult + the narrow ExerciseSpec view (the validator → FeedbackPanel contract)
  - phase: 03/04
    provides: StrokeCanvas (ink/trace primitive), StrokeOrderAnimation (Watch-me demo), scoreLetter, QalamMascot (5 poses), ArabicText, the theme tokens
provides:
  - "The 5 reusable exercise components — the whole engine UI: ExerciseScaffold (RTL landscape shell), PromptHeader (the ordered PromptPart composition engine), WriteSurface (a thin config wrapper over the existing StrokeCanvas), FeedbackPanelV2 (pass=one star+praise / fix=coral+authored line), ProgressRibbon (R→L position dots)"
  - "ExerciseController — a Riverpod Notifier idle→think→pass|fix state machine deriving the mascot pose + speech tone + FeedbackPanel state + the resolved authored line from a CheckResult"
  - "exerciseSpecFromExercise(Exercise) — the carry-forward adapter wiring the real Schema-v2 Exercise onto 07-03's ExerciseSpec view so WriteSurface drives validateExercise"
  - "QalamTokens — the kit :root mapped 1:1 (gold-ink/surface-raised name drifts reconciled + the new guide/ink/start-dot component constants)"
affects: [07-05, 07-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Config-driven UI: a new question type = a new Exercise config fed to ExerciseScaffold, never new UI (all 6 baa question types render through these same 5 components)"
    - "Component copy taken via constructor params with English defaults (call site passes l10n) — keeps widget tests independent of l10n generation"
    - "Adapter as a 07-04-owned free function (exerciseSpecFromExercise) rather than a static on 07-03's ExerciseSpec class — avoids a parallel-wave merge collision"
    - "IntrinsicHeight wraps the stretch prompt-header Row to resolve the prototype's align-items:stretch under an unbounded-height Column"

key-files:
  created:
    - lib/theme/qalam_tokens.dart
    - lib/features/letter_unit/widgets/prompt_header.dart
    - lib/features/letter_unit/widgets/progress_ribbon.dart
    - lib/features/letter_unit/widgets/feedback_panel_v2.dart
    - lib/features/letter_unit/widgets/write_surface.dart
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - lib/features/letter_unit/exercise_controller.dart
    - lib/features/letter_unit/exercise_spec_adapter.dart
    - test/features/letter_unit/prompt_header_test.dart
    - test/features/letter_unit/write_surface_test.dart
    - test/features/letter_unit/exercise_scaffold_test.dart
  modified:
    - lib/l10n/app_en.arb

key-decisions:
  - "The ExerciseSpec.fromExercise adapter (07-03's carry-forward) is implemented as a 07-04-OWNED free function exerciseSpecFromExercise(Exercise) in lib/features/letter_unit/exercise_spec_adapter.dart — NOT as a static factory added to 07-03's lib/core/exercise_engine/exercise_check.dart — so it cannot collide with 07-03 on merge. Semantically identical, field-for-field mechanical (#carry-forward)."
  - "Component child-facing copy is a constructor param with an English default; the section screens (07-05/07-06) pass the l10n string. This keeps the widget tests independent of `flutter gen-l10n` (which is denied in this worktree) while still adding all ARB keys for the real call sites."
  - "WriteSurface trace mode passes the guideForm's contextualForms reference strokes to StrokeCanvas (dotted guide shown); write mode passes EMPTY reference strokes (no dotted glyph) + a blank ruled baseline — matching the prototype's guide=path vs baseline split."
  - "The verdict line is shown in BOTH the speech bubble AND the FeedbackPanel (the prototype's tutorAndFeedback), so tests assert presence (findsWidgets) and scope the panel copy via find.descendant."

patterns-established:
  - "5 components + 1 reused canvas + 0 new structural components — the system held (COMPONENTS.md). The ink primitive, mascot, tokens, and demo animation are REUSED verbatim."
  - "Anti-gamification is grep-guarded in the panel test: pass shows exactly ONE star and zero +N/total/streak text; the ProgressRibbon is position-only and never gold."

requirements-completed: [CUR-01]

# Metrics
duration: ~75min
completed: 2026-06-15
---

# Phase 7 Plan 04: Exercise Component System Summary

**The 5 reusable Letter-Unit components — ExerciseScaffold + PromptHeader + WriteSurface + FeedbackPanelV2 + ProgressRibbon — plus a Riverpod ExerciseController and the ExerciseSpec adapter, built pixel-faithful to the Claude Design baa prototype: a new question type is a new Exercise config, never new UI. WriteSurface wraps the EXISTING StrokeCanvas and grades via validateExercise; FeedbackPanel shows one quiet star on a pass and the specific authored fix on a miss; no gamification chrome.**

## Performance

- **Duration:** ~75 min
- **Tasks:** 2 (both TDD)
- **Files created:** 11 (8 lib + 3 test); 1 modified (app_en.arb)
- **Tests:** 19 new widget tests, all GREEN (`flutter test test/features/letter_unit/`)

## Accomplishments

- **PromptHeader** renders the ordered PromptParts 1:1 with the prototype's `renderPart`: audio = teal play button, image = hatched stub + caption, text = Arabic with `__blank__`→word-box / `_letter_`→letter-slot + reveal(dim)/loose(wide-gap) variants, rule = gold-tint chip, forms = the four-forms strip of ب. The `say` part is PULLED OUT (it belongs in the speech bubble) and an empty header collapses.
- **WriteSurface** is a thin config wrapper over the EXISTING StrokeCanvas (not rebuilt): trace → the guideForm's `contextualForms` reference strokes (dotted guide); write → empty references + a blank ruled line; `given` → the faint given-ink cells + a dashed blank; `demo` → the existing StrokeOrderAnimation + a "Watch me" replay. On letter-complete it converts strokes to the validator's [x,y] shape, calls `validateExercise` through the adapter, and forwards the CheckResult.
- **ExerciseScaffold** reproduces the `.ex-scaffold` two-column RTL landscape layout: left `.ex-tutor` (mascot + "Qalam / Your Writing Tutor" + the toned speech bubble), right `.ex-main` (kick eyebrow + ProgressRibbon row · PromptHeader · WriteSurface/custom/none · FeedbackPanel + CTA). A teachCard (surface==null) renders PromptHeader-only with a "Got it" support CTA — no WriteSurface, no grading.
- **FeedbackPanelV2** — pass = exactly ONE gold star + the leaf eyebrow + the praise; fix = the coral ✕ disc + the coral eyebrow + the specific authored fix; idle = the calm write hint. Anti-gamification: no counter/tally/streak (grep-guarded).
- **ProgressRibbon** — R→L position dots, done/active/upcoming, never gold, no numerals.
- **ExerciseController** (Riverpod Notifier) holds idle→think→pass|fix, deriving the mascot pose (idle/think/cheer/tryAgain) + tone (neutral/leaf/coral) + the resolved authored line (`feedback['pass']` / `feedback[mistakeId]`) — exactly like the prototype's `tutorAndFeedback`. Reps gate via `policy.reps`.
- **QalamTokens** maps the kit `:root` 1:1, referencing the existing QalamColors palette (no fork), with the `--gold`→`goldInk` / `--white`→`surfaceRaised` drifts reconciled and the new `guideStroke`(3.4)/`inkStrokeWidth`(12)/`startDotRadius`(14)/`inkGuide`(#C7DCDC) component constants. `radiusXl`=28, `radiusMd`=14, `radiusLg`=20.

## Contracts for downstream plans (07-05 / 07-06)

The constructor signatures the section screens feed configs into:

```dart
// The page — feed it one Exercise, the letter, and the position.
ExerciseScaffold({
  required Exercise exercise,
  required Letter letter,
  ({int total, int active})? ribbon,
  String kick,
  VoidCallback? onNext,
  void Function(String audioId)? onAudioTap,
  ExerciseScaffoldStrings strings,   // l10n copy; English defaults
  WidgetBuilder? customSurface,      // teachCard escape hatch
});

// The composition engine — the ordered parts (say is pulled out).
PromptHeader({ required List<PromptPart> parts, void Function(String)? onAudioTap, String playLabel });
String promptSayLine(List<PromptPart> parts);   // the say line for the bubble

// The one canvas — wraps the existing StrokeCanvas.
WriteSurface({ required Exercise exercise, required Surface surface, required Letter letter,
  void Function(CheckResult)? onResult, VoidCallback? onValidating, ... });

// The graded panel.
FeedbackPanelV2({ required FeedbackState state, String line, String idleHint, String passTag, String fixTag });
enum FeedbackState { idle, pass, fix }

// The position dots.
ProgressRibbon({ required int total, required int active });

// The state machine (Riverpod).
final exerciseControllerProvider = NotifierProvider<ExerciseController, ExerciseState>(...);
//   .load(Exercise) → .think() → .applyResult(CheckResult) / .reset()
//   ExerciseState { phase, pose, tone, line, cleanReps, repsRequired, advanceReady }

// The carry-forward adapter (07-03's open task).
ExerciseSpec exerciseSpecFromExercise(Exercise e);   // lib/features/letter_unit/exercise_spec_adapter.dart
```

## Task Commits

> **BLOCKED — `git commit` is hard-denied in this worktree environment.** All 12 owned files are STAGED (`git add` succeeded) and verified GREEN. The intended atomic commits (the orchestrator creates them from the staged tree):

1. **Task 1:** `feat(07-04): QalamTokens + PromptHeader + ProgressRibbon + FeedbackPanelV2 (the static/composition components)` — `lib/theme/qalam_tokens.dart`, `lib/features/letter_unit/widgets/prompt_header.dart`, `lib/features/letter_unit/widgets/progress_ribbon.dart`, `lib/features/letter_unit/widgets/feedback_panel_v2.dart`, `lib/l10n/app_en.arb`, `test/features/letter_unit/prompt_header_test.dart`.
2. **Task 2:** `feat(07-04): WriteSurface + ExerciseScaffold + ExerciseController + ExerciseSpec adapter (validate→pass/fix→mascot)` — `lib/features/letter_unit/widgets/write_surface.dart`, `lib/features/letter_unit/widgets/exercise_scaffold.dart`, `lib/features/letter_unit/exercise_controller.dart`, `lib/features/letter_unit/exercise_spec_adapter.dart`, `test/features/letter_unit/write_surface_test.dart`, `test/features/letter_unit/exercise_scaffold_test.dart`.
3. **Plan metadata:** `docs(07-04): complete exercise-component-system plan` — this SUMMARY.

## Deviations from Plan

### Structural / blocking (Rule 3)

**1. [Rule 3 - Blocking] Wave-1 dependencies were absent from this worktree's base — vendored, NOT staged**
- **Found during:** Task 1 (first compile).
- **Issue:** `depends_on: [07-01, 07-03]`, but this worktree's base (`6be2bc5`) did NOT contain 07-01's `lib/models/exercise.dart` + the additive `Letter.contextualForms`/`Form` change, nor 07-03's `lib/core/exercise_engine/*` — those landed on sibling wave-1 worktree branches not yet merged into this base (the expected merged base `58791c0d` reset was denied). My components cannot compile or `flutter test` without them.
- **Fix:** Vendored byte-identical copies of 07-01's `lib/models/exercise.dart` and 07-03's `lib/core/exercise_engine/{check_result,exercise_check,exercise_validator}.dart` into the worktree, and applied 07-01's additive `Form`+`contextualForms` change to `lib/models/letter.dart`, SO THE TESTS COMPILE AND RUN GREEN. These files are **NOT staged** (they belong to 07-01/07-03; staging them would create a competing version on merge). They will arrive via 07-01/07-03's own merges before this plan integrates. Mirrors 07-03's own parallel-wave decoupling precedent.
- **Files (vendored, unstaged):** `lib/models/exercise.dart`, `lib/core/exercise_engine/*` (3 files), `lib/models/letter.dart` (additive edit).
- **Verification:** 19/19 letter_unit tests GREEN; `letter_test.dart` still 8/8 (the additive letter.dart change is non-breaking).

**2. [Rule 3 - Blocking] The carry-forward adapter is a 07-04-owned free function, not a static on 07-03's ExerciseSpec**
- **Found during:** Task 2.
- **Issue:** The carry-forward asked for `ExerciseSpec.fromExercise(Exercise)`. Adding a static factory to `ExerciseSpec` would mean editing 07-03's `lib/core/exercise_engine/exercise_check.dart` — a guaranteed merge collision with the parallel wave.
- **Fix:** Implemented the same mapping as `exerciseSpecFromExercise(Exercise)` in a NEW 07-04-owned file `lib/features/letter_unit/exercise_spec_adapter.dart`. Mechanical, field-for-field (the schema names match verbatim). No 07-03 file is touched.
- **Verification:** WriteSurface calls it on letter-complete; `write_surface_test` Test 5 proves the validator path resolves a verdict.

### Process / environment

**3. `flutter gen-l10n` and `flutter analyze` are denied in this worktree (no SCOPE change)**
- The new ARB keys (`promptPlay`, `feedbackIdleHint`, `feedbackPassTag`, `feedbackFixTag`, the `exercise*` chrome/CTA keys, `exerciseSurfaceTagWrite`) were added to `lib/l10n/app_en.arb`, but `flutter gen-l10n` could not be run (denied) and the generated `lib/l10n/app_localizations*.dart` is absent from this worktree (gitignored — MEMORY note). To keep the components testable WITHOUT regenerated l10n, every child-facing string is a constructor param with an English default; the section screens (07-05/07-06) pass the l10n string at the call site. The widgets therefore never import `AppLocalizations`. **Action for integration:** run `flutter gen-l10n` after merge so the new keys are available to the call sites.

## Known Stubs

- **`_ImagePart`** renders a hatched stub + the imageId caption (no real illustration). BY DESIGN — illustration assets are Plan 07-07's content job (07-01 SUMMARY ships placeholder imageIds). The component shape is complete; only the asset is pending.
- **`FourFormsStrip.contextualGlyph`** returns the explicit baa contextual forms (بـ/ـبـ/ـب) and falls back to the base glyph for other letters. baa is the built unit; other letters' forms arrive with their curriculum content (Plan 07-07+).

These are content stubs, not behavioral gaps — every component is config-complete and proven.

## Threat surface

No new threat surface beyond the plan's `<threat_model>`. T-07-04-01 (stroke capture stays in StrokeCanvas State; only the CheckResult — a bool + an authored key — leaves) and T-07-04-02 (all displayed text comes from the exercise's authored feedback map) are upheld: WriteSurface converts the in-memory strokes, scores, and discards; the controller resolves only authored keys. The FeedbackPanel pass state shows ONE star and zero tally (T-07-04-03, grep-guarded). No package installs (T-07-04-SC).

## Self-Check: PASSED (files) / BLOCKED (commits)

- All 12 owned source/test files + this SUMMARY exist on disk (verified by Write success + the passing test compile).
- 19/19 `test/features/letter_unit/` tests GREEN; `letter_test.dart` 8/8 (no regression).
- Commit verification N/A — `git commit` is denied in this worktree; all 12 files are STAGED. The orchestrator must create the commits (sequence under "Task Commits").

## Next Phase Readiness

- The 5 components + controller + adapter + tokens are the complete engine UI. Plans 07-05 (the 6 unit sections) and 07-06 build by FEEDING these components Exercise configs — no bespoke UI.
- **Blockers to clear before merge:** (a) 07-01 + 07-03 must merge first so the vendored deps become authoritative; (b) run `flutter gen-l10n` post-merge for the new ARB keys; (c) create the staged commits.

---
*Phase: 07-learning-engine-letter-unit-built-to-the-claude-design-proto*
*Completed: 2026-06-15*
