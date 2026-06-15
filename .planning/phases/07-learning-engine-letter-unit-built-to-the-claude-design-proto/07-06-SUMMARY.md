---
phase: 07-learning-engine-letter-unit-built-to-the-claude-design-proto
plan: 06
subsystem: ui
tags: [flutter, riverpod, letter-unit, sections, shell, routing, rtl, design-system, offline-audio, anti-gamification, resume]

# Dependency graph
requires:
  - phase: 07-05
    provides: the front-half sections (Meet/Watch-Trace/Forms) + section_side_cards (TipCard/ListenCard/PrimaryButton/QuietButton) + section_test_support fixtures
  - phase: 07-04
    provides: the 5 engine components (ExerciseScaffold/PromptHeader/WriteSurface/FeedbackPanelV2/ProgressRibbon) + ExerciseController + QalamTokens
  - phase: 07-01
    provides: Schema-v2 Exercise/Surface/Answer/Check + Word + LetterUnit/UnitSection models + getUnit/getExercises/getWords + the baa seeds (units.json/words.json/exercises.json)
  - phase: 06-07
    provides: the MasteryCelebration one-quiet-star widget (reused verbatim for Section 6)
  - phase: 03-02
    provides: the ProgressRepository.recordMastery seam (local Drift mastery write)
provides:
  - "WordsSection (Section 4) — three baa vocab cards (door/duck/milk) from words.json; each plays its word clip offline and opens a config-driven trace surface; the baa runs in each word are highlighted teal."
  - "ListenWriteSection (Section 5) — the recall gate: write-mode WriteSurface (NO dotted guide, the 'No guide · from memory' badge), a word↔first-letter toggle swapping the active config, the big offline Play; finishing requires the WORD task."
  - "MasterySection (Section 6) — REUSES MasteryCelebration for ONE quiet star + mascot + warm line; 'Next letter'/'See journey' wired; no totals/streaks/badges."
  - "LetterUnitScreen — the 6-section shell (app bar + R→L unit ribbon + kid chip) hosting the current section; loads getUnit(letterId), sequences via LetterUnitController, resume-aware; calm degrade on load."
  - "LetterUnitController — a Riverpod NotifierProvider.family<…, String> holding the section index + visited set, resume-per-letter (keep-alive), recording mastery LOCALLY on the Mastery section."
  - "the /unit?letter= route + home/journey deep-links into the resume-aware unit (baa → /unit; other letters keep /practice)."
affects: [07-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "The unit shell is config-driven end-to-end: getUnit(letterId) gives the section ORDER, getExercises()/getWords() give the configs, and each section renders entirely through the 07-04 engine — the shell builds NO bespoke exercise UI."
    - "Section copy stays a *Strings constructor param with English defaults (call site passes l10n) — the 07-04/05 precedent that keeps widget tests independent of flutter gen-l10n."
    - "Resume is a keep-alive per-letter Notifier.family: the section index + visited set survive navigation so re-entry resumes; durable cross-session persistence can layer on the ProgressRepository seam later without changing the controller API."
    - "Shared-file deep-links are minimal and additive: home + journey route ONLY baa to /unit (id == 'baa'), leaving every other letter's /practice path untouched until its unit is built."
    - "The /unit route validates the letter DOWNSTREAM (mirroring /practice T-06-03): empty/missing → the built unit (baa); an unknown id → the calm 'preparing' panel (loader returns null), never an error or arbitrary load."

key-files:
  created:
    - lib/features/letter_unit/sections/words_section.dart
    - lib/features/letter_unit/sections/listen_write_section.dart
    - lib/features/letter_unit/sections/mastery_section.dart
    - lib/features/letter_unit/letter_unit_screen.dart
    - lib/features/letter_unit/letter_unit_controller.dart
    - test/features/letter_unit/words_section_test.dart
    - test/features/letter_unit/listen_write_section_test.dart
    - test/features/letter_unit/letter_unit_screen_test.dart
    - test/router/letter_unit_route_test.dart
  modified:
    - lib/router/app_router.dart
    - lib/screens/home_screen.dart
    - lib/features/journey/journey_screen.dart
    - lib/l10n/app_en.arb
    - test/screens/home_screen_test.dart

key-decisions:
  - "Section 6 REUSES the existing MasteryCelebration (grep-guarded) rather than rebuilding a star — the one-quiet-star moment stays consistent app-wide and its anti-gamification invariants (one star, no totals/streaks/badges) carry over for free. The prototype's gold 'spark' burst is a one-off settle, not a counter, so omitting it changes nothing about the anti-gamification posture."
  - "The unit shell maps UnitSection.id → the section widget and resolves each section's exact baa configs by id (with calm fallbacks), rather than trusting units.json's section→exercise grouping verbatim (which groups differently than the prototype's section semantics). This keeps every section navigable even if a specific exercise id is absent."
  - "baa's today-card and journey node open /unit?letter=baa; alif (and every other letter) keep /practice?lesson= until their units are built. Documented inline at both call sites — alif's thin loop is intentionally untouched."
  - "LetterUnitController is a NotifierProvider.family keyed by letterId (the family arg feeds the constructor, matching the 07-03 _CleanRepsNotifier pattern); resume is an in-memory keep-alive map, sufficient for the plan's 'resume-aware' within-session/re-navigation requirement."

patterns-established:
  - "A unit = a thin shell over the engine: the app bar + R→L ribbon + a section host, with the LetterUnitController as the only state. The 6 sections are pure config-fed widgets."
  - "Anti-gamification holds end-to-end: the unit ribbon is position-only (never gold, no numerals), and the Mastery close shows exactly the one quiet star — grep-guarded in mastery_section.dart."

requirements-completed: [CUR-01, S1-06]

# Metrics
duration: ~75min
completed: 2026-06-15
---

# Phase 7 Plan 06: Letter-Unit Back Half + Shell + Route Summary

**The baa Letter Unit, now end-to-end on the engine: the back-half sections — Words (three vocab cards that play offline and open a config-driven trace), Listen & Write (the recall gate: write from memory, no guide), and Mastery (the reused one-quiet-star celebration) — sequenced behind the R→L ProgressRibbon app bar by a resume-aware LetterUnitController, reachable from home and the journey map via a validated /unit?letter= deep-link. Pixel-faithful to the Claude Design prototype; config-driven through the 07-04 engine; anti-gamification held throughout.**

## Performance

- **Duration:** ~75 min
- **Tasks:** 2 (Task 1 TDD: 3 sections; Task 2: shell + controller + route + deep-links)
- **Files created:** 9 (5 lib + 4 test); 5 modified (3 shared lib + ARB + 1 test)
- **Tests:** 12 new (4 Words + 4 Listen&Write + 4 shell/route), all GREEN; full `test/features/letter_unit/ test/router/` suite 49/49 GREEN; `home_screen` 13/13 and `journey` 10/10 GREEN after the deep-link update.

## Accomplishments

- **WordsSection (Section 4)** reproduces the prototype `words()` grid + `traceWord()`: a `.wordgrid` of three `.wordcard`s built from `words.json` (door/duck/milk), each with an image stub, the Arabic word with its **baa runs highlighted teal** (`_HighlightedWord` splits on the base glyph), the romanization + gloss, and a round offline Play. Tapping a card opens its trace surface — the engine `ExerciseScaffold` fed the word's connectWord/writeWord config — with a Listen side card and a "Back to words" CTA. A clean pass flags the card "Traced".
- **ListenWriteSection (Section 5)** is the **recall gate**, reproducing `listenWrite()`: a left prompt column (the word↔first-letter `.lw-sub` toggle, the `.lw-card` task + sub, the big `.bigplay`) and a right **write-mode** WriteSurface with the `.noguide` "No guide · from memory" badge (NO dotted glyph). The toggle swaps the active config between `baa.writeWord.dictation` and `baa.writeLetter.fromSound`; a scored pass shows the authored praise, a miss the authored fix. **Finishing requires the WORD task** — `onFinish` fires only on a word-mode pass.
- **MasterySection (Section 6)** REUSES the existing **MasteryCelebration** (grep-guarded): ONE settling gold star + the mascot + the warm, letter-specific line, "Next letter" → the next unit, "See journey" → `/journey?highlight=<id>`. No totals, tallies, streaks, or badges (grep-guarded in the file).
- **LetterUnitScreen** is the 6-section shell, pixel-faithful to `index.html`: a `.appbar` (back / close `.iconbtn`s + the centred unit label + the **R→L unit ribbon** of 6 tappable dots + the kid chip) over a body that hosts the current section. It loads the section order from `getUnit(letterId)`, resolves each section's baa configs from `getExercises()`/vocab from `getWords()`, and degrades calmly to a "preparing" panel on load/error/unknown-letter — never a raw error.
- **LetterUnitController** (Riverpod `NotifierProvider.family`, no BLoC/GetX) holds the current section index + the `visited` set, advances forward, jumps via the ribbon, and is **resume-aware** (a keep-alive per-letter index so exiting and re-entering returns to where the child left off). Reaching **Mastery records the letter mastered through the existing ProgressRepository seam — a LOCAL Drift write only** (idempotent; never crashes the celebration).
- **Routing + deep-links:** added `GoRoute(path: '/unit')` reading `?letter=` (validated downstream; empty→baa, unknown→calm degrade — mirrors the `/practice` T-06-03 pattern; the onboarding/parent gates are untouched). Home's today-card and the journey node now open `/unit?letter=baa` for baa, leaving every other letter's `/practice?lesson=` path working.

## Contracts for downstream plans (07-07 content)

- **Section APIs** the shell feeds:
  ```dart
  WordsSection({ required List<WordTrace> words, required Letter letter, VoidCallback? onAdvance, WordsSectionStrings strings });
  //   WordTrace { Word word; Exercise exercise }  · WordsSectionState.debugMarkWordTraced(i)
  ListenWriteSection({ required Exercise writeWord, required Exercise writeLetter, required Letter letter, VoidCallback? onFinish, ListenWriteStrings strings });
  //   ListenWriteSectionState.mode / .activeExercise  (LwMode.word | LwMode.letter)
  MasterySection({ required Letter letter, VoidCallback? onNext, VoidCallback? onSeeJourney, bool isLastLetter });
  ```
- **The /unit route + resume contract:** `/unit?letter=<id>` → `LetterUnitScreen(letterId)`; the screen loads `letterUnitDataProvider(letterId)` (getUnit + getLetter + getExercises + getWords) and sequences via `letterUnitControllerProvider(letterId)`. Re-entry resumes the persisted section index. An unknown id → the calm "preparing" panel.
- **SC#1/#2/#5 met structurally:** the full 6-section baa unit is reachable, navigable, resume-aware, and pixel-faithful (CUR-01 engine end-to-end). **Content sign-off + the real per-form reference strokes land in Plan 07-07** — until then the Forms section's initial/medial/final degrade to "Coming soon", and image/audio ids remain placeholders.

## Task Commits

> **BLOCKED — `git commit` is hard-denied in this worktree environment.** All 14 owned files are STAGED (`git add` succeeded) and verified GREEN. The vendored 07-05 section files + the generated l10n are correctly LEFT UNSTAGED. The intended atomic commits (the orchestrator creates them from the staged tree):

1. **Task 1:** `feat(07-06): Words + Listen&Write + Mastery sections (Sections 4-6)` — `lib/features/letter_unit/sections/words_section.dart`, `lib/features/letter_unit/sections/listen_write_section.dart`, `lib/features/letter_unit/sections/mastery_section.dart`, `lib/l10n/app_en.arb`, `test/features/letter_unit/words_section_test.dart`, `test/features/letter_unit/listen_write_section_test.dart`.
2. **Task 2:** `feat(07-06): LetterUnit shell + controller + /unit route + home/journey deep-links` — `lib/features/letter_unit/letter_unit_screen.dart`, `lib/features/letter_unit/letter_unit_controller.dart`, `lib/router/app_router.dart`, `lib/screens/home_screen.dart`, `lib/features/journey/journey_screen.dart`, `test/features/letter_unit/letter_unit_screen_test.dart`, `test/router/letter_unit_route_test.dart`, `test/screens/home_screen_test.dart`.
3. **Plan metadata:** `docs(07-06): complete letter-unit back-half + shell + route plan` — this SUMMARY.

> The ARB is grouped with Task 1 (first new call-site keys). The orchestrator may instead split the ARB into its own `chore` commit — either grouping is atomic.

## Deviations from Plan

### Structural / blocking (Rule 3)

**1. [Rule 3 - Blocking] The 07-05 section files were absent from this worktree's base — vendored, NOT staged**
- **Found during:** Task 1 (first compile).
- **Issue:** `depends_on: [07-05]`, but this worktree's ACTUAL base is `fa2b42a` (the expected base `1f40c96` `git reset --hard` was DENIED / not applied — `fa2b42a` is an ANCESTOR of `1f40c96`). `fa2b42a` has 07-01 + 07-04 (engine widgets, QalamTokens, models, repo, seeds) but PREDATES the 07-05 merge, so `section_side_cards.dart`, `meet_section.dart`, `watch_trace_section.dart`, `forms_section.dart`, and `test/.../section_test_support.dart` were missing — my Words/Listen sections and the shell cannot compile/test without them.
- **Fix:** Vendored byte-identical 07-05 copies of those 5 files into the worktree so the tests compile + run GREEN. **NOT staged** — they arrive via 07-05's own merge before this plan integrates (mirrors the 07-05 SUMMARY's own parallel-wave vendoring precedent).
- **Files (vendored, unstaged):** `lib/features/letter_unit/sections/{section_side_cards,meet_section,watch_trace_section,forms_section}.dart`, `test/features/letter_unit/section_test_support.dart`.
- **Verification:** 49/49 `test/features/letter_unit/ test/router/` GREEN against the vendored sections.

**2. [Rule 3 - Blocking] The generated l10n was absent — vendored, NOT staged (gitignored)**
- **Found during:** Task 2 (the shell test imports MasterySection → MasteryCelebration → `app_localizations.dart`).
- **Issue:** `lib/l10n/app_localizations*.dart` is gitignored (MEMORY l10n-generated-gitignored) and absent; `flutter gen-l10n` is denied here and `flutter test` does NOT auto-regenerate it in this worktree, so ANY test importing `MasteryCelebration` (a pre-existing 06-07 widget that imports AppLocalizations) failed to compile.
- **Fix:** Vendored the canonical generated `app_localizations.dart` + `app_localizations_en.dart` (from the up-to-date checkout, which carries the 06-07 + 07-05 keys MasteryCelebration needs) into `lib/l10n/`. They are GITIGNORED, so git never sees them — correctly UNSTAGED. The orchestrator regenerates them post-merge via `flutter gen-l10n`.
- **My section widgets never import AppLocalizations** (they use `*Strings` defaults), so my new 07-06 ARB keys not yet being in the generated file is harmless for the tests.

### Process / environment

**3. `git commit`, `git reset --hard`, `flutter gen-l10n`, `flutter pub get`, `flutter analyze` are denied in this worktree (no SCOPE change)**
- The new 07-06 ARB keys were added but `flutter gen-l10n` could not be run; every section's child-facing string is a `*Strings` constructor param with an English default, so the widgets never import `AppLocalizations` and the tests run WITHOUT the new keys reaching real call sites. **Action for integration:** run `flutter gen-l10n` post-merge so the new keys (`wordsKick`, `listenWriteKick`, `letterUnitLabel`, …) reach the call sites. The actual base is `fa2b42a` (expected `1f40c96`).

**4. [Rule 1 - Behavior change] Updated `home_screen_test` Test 5 for the new baa route**
- The plan instructs baa's today-card to open `/unit?letter=baa`. The existing `home_screen_test` Test 5 pinned baa → `/practice?lesson=lesson_02`. I updated that assertion to `/unit?letter=baa`, added a `/unit` stub route to the test's `_makeRouter()`, and renamed the test. This is the deviation the plan's own change requires — not a regression. 13/13 home_screen tests GREEN after the update.

## Shared-file edits (for re-application if the base moved)

- **`lib/router/app_router.dart`** — ADDED: (a) an import `import '../features/letter_unit/letter_unit_screen.dart';` (in the import block, after `journey_screen.dart`); (b) a `GoRoute(path: '/unit')` placed BEFORE the existing `/settings` route, reading `state.uri.queryParameters['letter']`, degrading empty→`'baa'`, and building `LetterUnitScreen(key: ValueKey('unit:$letterId'), letterId: letterId)`. No existing route or gate was touched.
- **`lib/screens/home_screen.dart`** — CHANGED ONE expression in `_TodaysLessonCardReader` (the live today-card `route:` arg, ~line 682): from `route: '/practice?lesson=${data.lessonId}'` to a ternary `route: data.letter.id == 'baa' ? '/unit?letter=${data.letter.id}' : '/practice?lesson=${data.lessonId}'`. The all-mastered, loading, and error branches are untouched.
- **`lib/features/journey/journey_screen.dart`** — CHANGED the node `onTap` (~line 413): from `context.go('/practice?lesson=$lessonId')` to a ternary routing baa → `/unit?letter=${letter.id}`, others → `/practice?lesson=$lessonId`.
- **`lib/l10n/app_en.arb`** — ADDED only the 07-06 keys at the END (after `exerciseTeachCardHint`): the `words*`, `listenWrite*`, and `letterUnit*` keys. NOTE: this worktree's staged ARB is based on `fa2b42a`, which has the 07-04 keys but NOT the 07-05 section keys — the orchestrator should merge the staged ARB as a SUPERSET onto the 07-05-inclusive base and run `flutter gen-l10n` post-merge.

## Known Stubs

- **Word / form images** — the word cards' illustrations are hatched `_PicStub`s with the imageId caption (art is Plan 07-07's content job; words.json ships placeholder imageIds). Component shape complete; only the asset is pending.
- **Initial/medial/final contextual Forms remain un-authored** — the Forms section (07-05) still degrades to "Coming soon" for them by design; Plan 07-07 authors + signs them off. Not a gap in this plan.
- **Resume persistence is in-memory keep-alive** (per-letter, survives navigation/re-entry within the app lifetime). Durable cross-session resume can layer on the ProgressRepository seam later; the controller API does not change.

## Threat surface

No new threat surface beyond the plan's `<threat_model>`. **T-07-06-01** (the `/unit?letter=` param is validated downstream — empty→baa, unknown→calm degrade, never an error/arbitrary load) is implemented + route-tested. **T-07-06-02** (mastery writes go to LOCAL Drift via the existing ProgressRepository — no child data to Firestore; resume position is local) holds. **T-07-06-03** (anti-gamification — one quiet star, grep-guarded) holds. **T-07-06-04** (the onboarding + parent gates are untouched by the new `/unit` route) — `test/router/` 0 regressions. No package installs (T-07-06-SC).

## Self-Check: PASSED (files) / BLOCKED (commits)

- All 9 owned source/test files + the 5 shared/modified files + this SUMMARY exist on disk (verified by Write success + the passing test compile).
- 12 new tests GREEN; full `test/features/letter_unit/ test/router/` 49/49 GREEN; `home_screen` 13/13, `journey` 10/10, `practice_screen` + `onboarding_gate` GREEN (no regression).
- Commit verification N/A — `git commit` is denied; all 14 owned files are STAGED. The vendored 07-05 sections + the gitignored generated l10n are correctly left unstaged. The orchestrator must create the commits (sequence under "Task Commits").

## Next Phase Readiness

- The baa Letter Unit is end-to-end on the engine: reachable from home + journey, navigable through all 6 sections R→L, resume-aware, with the one quiet star at mastery. Plan 07-07 fills the content (signed-off per-form reference strokes, real audio/art, the owner's-mother's final feedback copy) — the Forms/Words/Listen sections pick those up with NO structural change.
- **Blockers to clear before merge:** (a) 07-05 must merge first so the vendored sections become authoritative; (b) run `flutter gen-l10n` post-merge so the new ARB keys reach the call sites; (c) create the staged commits.

---
*Phase: 07-learning-engine-letter-unit-built-to-the-claude-design-proto*
*Completed: 2026-06-15*
