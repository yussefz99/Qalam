---
phase: 07-learning-engine-letter-unit-built-to-the-claude-design-proto
plan: 05
subsystem: ui
tags: [flutter, riverpod, letter-unit, sections, rtl, design-system, offline-audio, anti-gamification]

# Dependency graph
requires:
  - phase: 07-04
    provides: the 5 exercise components (ExerciseScaffold/PromptHeader/WriteSurface/FeedbackPanelV2/ProgressRibbon) + ExerciseController + exerciseSpecFromExercise adapter + QalamTokens
  - phase: 07-01
    provides: the Schema-v2 Exercise/Surface/PromptPart models + Letter.contextualForms Form objects (per-form reference strokes)
  - phase: 07-02
    provides: the offline AssetLetterAudioPlayer behind audioPlayerProvider (bundled clips, no network)
  - phase: 03/04
    provides: StrokeOrderAnimation (the Watch-me demo), StrokeCanvas, ArabicText
provides:
  - "MeetSection (Section 1) — teachCard morph card: one big contextual form + a four-stop scrub strip (isolated/initial/medial/final), the door image stub, an offline Hear button; PromptHeader-only via ExerciseScaffold, nothing to write."
  - "WatchTraceSection (Section 2) — a Watch phase (StrokeOrderAnimation demo + Tip card + Watch again/I'll try) then a Trace phase (ExerciseScaffold-driven WriteSurface trace/isolated, one-star+authored grading, a Listen side card that plays snd.baa offline)."
  - "FormsSection (Section 3) — three form-step chips (initial/medial/final) each loading a trace surface with the matching guideForm, a graceful 'not yet authored' placeholder for un-signed-off forms, then a join-into-باب stage."
  - "section_side_cards.dart — shared TipCard/ListenCard + PrimaryButton/QuietButton reproducing the prototype .tip-card/.listen-card/.btn."
affects: [07-06, 07-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Sections render by FEEDING configs into the engine — each graded surface is an ExerciseScaffold fed one Exercise; no bespoke grading UI (the CUR-01 config-driven rule)."
    - "Section child-facing copy is a *Strings constructor param with English defaults (call site passes l10n) — keeps widget tests independent of `flutter gen-l10n` (the 07-04 precedent)."
    - "A side card (Listen/Tip) is overlaid on the scaffold via a Stack + PositionedDirectional, so the engine keeps full ownership of grading while the section adds the offline-audio affordance."
    - "Graceful degrade for un-authored content: read letter.contextualForms[form]; a null/empty Form renders a calm 'Coming soon' placeholder and NEVER fabricates reference strokes (the human sign-off gate)."

key-files:
  created:
    - lib/features/letter_unit/sections/meet_section.dart
    - lib/features/letter_unit/sections/watch_trace_section.dart
    - lib/features/letter_unit/sections/forms_section.dart
    - lib/features/letter_unit/sections/section_side_cards.dart
    - test/features/letter_unit/meet_section_test.dart
    - test/features/letter_unit/watch_trace_section_test.dart
    - test/features/letter_unit/forms_section_test.dart
    - test/features/letter_unit/section_test_support.dart
  modified:
    - lib/l10n/app_en.arb

key-decisions:
  - "The Trace phase (Section 2) and each form-step (Section 3) ARE the engine's ExerciseScaffold fed the relevant baa Exercise — the authored fix/praise come straight from the config's feedback map, never a generic message. No new grading widget exists."
  - "The Listen/Tip side cards live in a shared section_side_cards.dart (added under deviation Rule 3) so Sections 2/3 and the later sections (07-06) reuse one faithful .listen-card/.tip-card rather than each re-cutting the CSS."
  - "Un-authored contextual forms (initial/medial/final, which Plan 07-07 fills) render a 'Coming soon' placeholder keyed `formNotYetAuthored`; the section stays navigable and the canvas never scores empty/fabricated strokes (T-07-05-02)."
  - "Section copy is constructor params with English defaults (no AppLocalizations import in the section widgets); the new ARB keys are added for the real call sites but gen-l10n is run post-merge."

patterns-established:
  - "A unit Section = thin orchestration over the engine + a couple of side cards; the morph card / scrub strip / form chips are the only bespoke presentation, and they grade nothing."
  - "Anti-gamification holds in every section: a teach card shows no star at all; the graded sections show exactly the engine's ONE star on a pass and zero counters/tallies/streaks."

requirements-completed: [CUR-01, S1-06]

# Metrics
duration: ~55min
completed: 2026-06-15
---

# Phase 7 Plan 05: Letter-Unit Sections 1–3 (Meet / Watch-Trace / Forms) Summary

**The front half of the baa unit, built pixel-faithful to the Claude Design prototype and entirely config-driven through the 07-04 engine: the child HEARS baa and watches its four shapes morph (Meet), WATCHES its stroke order then TRACES the isolated baa scored on-device with the authored fix/praise (Watch & Trace), and traces baa's initial/medial/final forms before joining them into باب (Forms) — with offline audio and a calm degrade where forms are not yet signed off.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 2 (both TDD)
- **Files created:** 8 (4 lib + 4 test); 1 modified (app_en.arb)
- **Tests:** 13 new widget tests, all GREEN (`flutter test test/features/letter_unit/{meet,watch_trace,forms}_section_test.dart`)

## Accomplishments

- **MeetSection** reproduces the prototype `meet()` 1:1: it feeds the `baa.teachCard.meet` Exercise into ExerciseScaffold (surface == null → PromptHeader-only, no WriteSurface, no grading) and supplies the morph card as the scaffold's `customSurface` — one large ZWJ-joined contextual glyph + an explain line, the join-hint arrows, the door image stub (via the prompt's image part), an offline "Hear" button, and the four-stop `.scrub` track (isolated/initial/medial/final) that morphs the big glyph on tap. The "Got it" support CTA is relabelled "Start Writing" and advances to Section 2.
- **WatchTraceSection** is two phases. The Watch phase auto-plays the existing `StrokeOrderAnimation` inside a writebox with a `.tip-card`, and "Watch again" / "I'll try" CTAs. The Trace phase is the ExerciseScaffold fed `baa.traceLetter.isolated` (trace/glyph/isolated + demo) — the WriteSurface the child traces, graded by the ExerciseController so a pass shows ONE star + the authored praise and a miss shows the SPECIFIC authored `shallowBowl` line (from EXERCISE-CONFIGS.json), with a `.listen-card` that plays `snd.baa` offline.
- **FormsSection** reproduces `context()`: three `.fstep` chips (initial/medial/final) each loading a trace ExerciseScaffold with the matching `guideForm`; a completed chip turns leaf-green with a ✓; once all three are done the section advances to the join-into-باب stage (its own write surface). When a form's contextual `Form` is null (the pre-07-07 un-authored state) it shows a calm "Coming soon" placeholder and never crashes or fabricates strokes.
- **Shared side cards** (`section_side_cards.dart`) — `TipCard` (.tip-card gold-tint), `ListenCard` (.listen-card aqua + offline Play), `PrimaryButton`/`QuietButton` (.btn.primary/.quiet) — all on QalamTokens, reused by Sections 2/3 (and ready for 07-06).
- **Offline audio (S1-06):** every Play/Hear affordance plays a bundled clip through `audioPlayerProvider.playLetter(audioId)`; an unknown id / missing clip degrades to the player's silent no-op, so the child is never blocked.

## Contracts for downstream plans (07-06 the LetterUnit shell)

The section constructor APIs the shell sequences:

```dart
MeetSection({ required Exercise exercise, required Letter letter, VoidCallback? onAdvance, MeetSectionStrings strings });
WatchTraceSection({ required Exercise exercise, required Letter letter, VoidCallback? onAdvance, WatchTraceStrings strings });
FormsSection({ required Exercise initial, required Exercise medial, required Exercise finalForm, required Exercise join,
               required Letter letter, VoidCallback? onAdvance, FormsSectionStrings strings });
// FormsSectionState.debugMarkFormDone(String form) — host/test sequencing hook; advances to the join stage when all 3 are done.
```

- Each section takes the baa Exercise config(s) + the Letter and one `onAdvance` callback; the shell supplies the configs (from the 07-01 seeds), the letter, and wires `onAdvance` to its section index.
- **Null-Form degrade (07-07 resolves):** FormsSection reads `letter.contextualForms[form]`; initial/medial/final are expected null until Plan 07-07 authors + signs them off, at which point the placeholder is automatically replaced by the real trace surface (no FormsSection change needed).

## Task Commits

> **BLOCKED — `git commit` is hard-denied in this worktree environment.** All 9 owned files are STAGED (`git add` succeeded) and verified GREEN. The intended atomic commits (the orchestrator creates them from the staged tree):

1. **Task 1:** `feat(07-05): MeetSection — teachCard morph card + four-forms scrub + offline Hear (Section 1)` — `lib/features/letter_unit/sections/meet_section.dart`, `lib/features/letter_unit/sections/section_side_cards.dart`, `lib/l10n/app_en.arb`, `test/features/letter_unit/meet_section_test.dart`, `test/features/letter_unit/section_test_support.dart`.
2. **Task 2:** `feat(07-05): WatchTraceSection + FormsSection — watch demo + scored trace + forms-in-context with graceful degrade (Sections 2–3)` — `lib/features/letter_unit/sections/watch_trace_section.dart`, `lib/features/letter_unit/sections/forms_section.dart`, `test/features/letter_unit/watch_trace_section_test.dart`, `test/features/letter_unit/forms_section_test.dart`.
3. **Plan metadata:** `docs(07-05): complete letter-unit sections 1-3 plan` — this SUMMARY.

> NOTE: `section_side_cards.dart` and `section_test_support.dart` are shared by both tasks; they are grouped with Task 1 above (first use) so each commit compiles+tests independently. The orchestrator may instead place them in their own `feat(07-05): shared section side-cards + test fixtures` commit before Task 1 — either grouping is atomic.

## Deviations from Plan

### Structural / blocking (Rule 3)

**1. [Rule 3 - Blocking] The 07-04 engine components were absent from this worktree's base — vendored, NOT staged**
- **Found during:** Task 1 (first compile).
- **Issue:** `depends_on: [07-04]`, but this worktree's actual base is `e070319` (the expected base `6a44b64` reset was DENIED at the permission layer). `e070319` predates the 07-04 merge (`8f08661`), so `lib/features/letter_unit/*` and `lib/theme/qalam_tokens.dart` were missing — my sections cannot compile or `flutter test` without them. (07-01 + 07-03 + 07-02 deps WERE present at this base.)
- **Fix:** Vendored the byte-identical 07-04 files from the `6a44b64` ref (`git show 6a44b64:<path> > <path>`): `lib/theme/qalam_tokens.dart`, `lib/features/letter_unit/widgets/{prompt_header,progress_ribbon,feedback_panel_v2,write_surface,exercise_scaffold}.dart`, `lib/features/letter_unit/{exercise_controller,exercise_spec_adapter}.dart`. These are **NOT staged** — they arrive via 07-04's own merge before this plan integrates (mirrors the 07-04 SUMMARY's own parallel-wave vendoring precedent).
- **Files (vendored, unstaged):** `lib/theme/qalam_tokens.dart`, `lib/features/letter_unit/widgets/*` (5 files), `lib/features/letter_unit/{exercise_controller,exercise_spec_adapter}.dart`.
- **Verification:** 13/13 new section tests GREEN against the vendored engine.

**2. [Rule 3 - Blocking] The ARB was vendored from `6a44b64` so the 07-04 keys are present**
- **Found during:** Task 1 (the section call-site keys).
- **Issue:** `lib/l10n/app_en.arb` at base `e070319` lacks the 07-04 exercise keys; my sections' real call sites need both the 07-04 chrome keys and the new 07-05 section keys.
- **Fix:** Vendored the `6a44b64` ARB (which has the 07-04 keys), then ADDED the 07-05 section keys (`meetKick`, `meetHear`, `meetStartWriting`, `form{Isolated,Initial,Medial,Final}`, `meetExplain*`, `watch*`, `listen*`, `forms*`, `formNotYetAuthored{Title,Body}`). The staged ARB therefore contains 07-04 + 07-05 keys. **Integration note:** applied onto the 07-04-merged base (`6a44b64`), the diff is ONLY the 07-05 keys — correct. The orchestrator should commit my staged ARB onto that base. ARB validated as well-formed JSON.

### Process / environment

**3. `git commit`, `git reset --hard`, `flutter gen-l10n`, `flutter analyze`, and `flutter pub get` are denied in this worktree (no SCOPE change)**
- The new ARB keys are added but `flutter gen-l10n` could not be run (denied); the generated `lib/l10n/app_localizations*.dart` is gitignored/absent. Every section's child-facing string is a `*Strings` constructor param with an English default, so the widgets never import `AppLocalizations` and the tests run WITHOUT regenerated l10n. **Action for integration:** run `flutter gen-l10n` after merge so the new keys reach the real call sites. The actual base is `e070319` (expected `6a44b64`) — the `git reset --hard` to the expected base was denied.

**4. [Rule 3] Added `section_side_cards.dart` (not in the plan's files_modified)**
- The plan's `<action>` calls for the `.listen-card`/`.tip-card` side cards and the `.btn` CTAs in Sections 2/3. Rather than duplicate them in each section, I factored them into one shared `lib/features/letter_unit/sections/section_side_cards.dart`. Presentation-only (no grading), QalamTokens-based, prototype-faithful. Staged.

## Known Stubs

- **Door / form image** — the Meet section's image is the engine's `_ImagePart` hatched stub + imageId caption (illustration assets are Plan 07-07's content job; 07-01 ships placeholder imageIds). Component shape complete; only the asset is pending.
- **Initial/medial/final contextual Forms are intentionally un-authored** — FormsSection renders the "Coming soon" placeholder for them by design. Plan 07-07 authors + signs them off (the human gate); when present, the real trace surface replaces the placeholder with NO FormsSection change. This is a tracked, intentional degrade — not a behavioral gap in this plan.

## Threat surface

No new threat surface beyond the plan's `<threat_model>`. T-07-05-01 (strokes stay in WriteSurface/StrokeCanvas; only the CheckResult leaves) is upheld — the sections never touch raw strokes. T-07-05-02 (audio bundled/offline; a null un-signed-off Form renders a calm placeholder and never fabricates strokes) is implemented and tested. T-07-05-03 (one quiet star, no counters) holds — the teach card shows no star; the graded sections show the engine's single star. No package installs (T-07-05-SC).

## Self-Check: PASSED (files) / BLOCKED (commits)

- All 9 owned source/test files + this SUMMARY exist on disk (verified by Write success + the passing test compile).
- 13/13 new section tests GREEN (`flutter test test/features/letter_unit/{meet,watch_trace,forms}_section_test.dart`).
- Commit verification N/A — `git commit` is denied in this worktree; all 9 owned files are STAGED (the vendored 07-04 deps + the gitignored generated l10n are correctly left unstaged). The orchestrator must create the commits (sequence under "Task Commits").

## Next Phase Readiness

- Sections 1–3 are config-driven vertical slices over the 07-04 engine; Plan 07-06 sequences them (plus Sections 4–6) into the LetterUnit shell via the constructor APIs above.
- **Blockers to clear before merge:** (a) 07-04 must merge first so the vendored engine + ARB keys become authoritative; (b) run `flutter gen-l10n` post-merge for the new ARB keys; (c) create the staged commits.

---
*Phase: 07-learning-engine-letter-unit-built-to-the-claude-design-proto*
*Completed: 2026-06-15*
