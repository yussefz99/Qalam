---
phase: 19-question-presentation-overhaul-every-question-self-explanato
plan: 02
subsystem: letter-unit-presentation
tags: [flutter, exercise-scaffold, instruction-bar, l10n, rtl, anti-gamification, tdd]

# Dependency graph
requires:
  - phase: 19
    plan: 01
    provides: "exercise_scaffold_instruction_bar_test.dart (QP-01/02) — the live-path RED contract this plan greens with zero test edits"
  - phase: 18
    provides: "presentGraphExercise live-mount seam, _hasInstruction / _speakInstructionThenRelease / _instructionHold, the 18-12 _HearAgainCta pill (now folded away)"
provides:
  - "instructionTemplateFor(exercise) → InstructionSpec — the pure per-type icon+text resolver (D-02), keyed on exercise.type, NOT the say line (Pitfall 6)"
  - "The persistent instruction bar in ExerciseScaffold._mainColumn — one tap target, single replay affordance (D-01/D-02/D-03)"
  - "15 instructionBar* ARB keys + English defaults on ExerciseScaffoldStrings (l10n-independent widget tests)"
affects: ["19-03 stimulus renderers (PromptHeader gap slot + audio card)", "19-04 LetterReps fold", "19-05 card rewrite/gate", "19-06 keying migration"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure per-type resolver (InstructionSpec) — a switch on exercise.type with AudioPart/reveal/criteria disambiguation; unit-tested l10n-free, then read by the widget"
    - "English content island (Directionality.ltr) inside the RTL scaffold for the instruction line (the _teacherEye precedent)"
    - "Fold-not-duplicate: the 18-12 replay pill is absorbed into the bar (one affordance, never two — the Phase-07 double-Hear-button precedent)"

key-files:
  created:
    - test/features/letter_unit/instruction_template_test.dart
  modified:
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - lib/l10n/app_en.arb
    - test/features/letter_unit/exercise_scaffold_test.dart

key-decisions:
  - "The resolver takes the whole Exercise (not just the type string) — the writeWord/writeLetter sub-variants are disambiguated by an AudioPart (listen → 'Listen and write') vs a reveal:'thenHide' TextPart (copy → 'Copy the word'); audio wins over copy. microDrill overrides its base line per criteria.first (dot/shape/strokeOrder)."
  - "15 template strings shipped (not 10): the 11 base types + 2 writeWord sub-variants + 3 microDrill criterion overrides collapse to 15 distinct lines incl. the fallback. Inserted as ONE contiguous block at the TOP of app_en.arb (19-03 appends at the bottom — merge-clean split)."
  - "The bar's content is an LTR English island (like _teacherEye) so the English imperative reads left-to-right with a leading glyph and a trailing speaker, inside the otherwise-RTL scaffold."
  - "hearAgain default changed 'Hear again' → 'Hear it again' (UI-SPEC §1) and repurposed as the bar's Semantics(button:true, label:) — there is no visible replay text label anymore, only the speaker glyph + the accessible label."
  - "Reconciled the obsolete 18-12 exercise_scaffold_test Test 5/6 to the new bar contract (Rule 1) — they asserted the now-deleted visible 'Hear again' pill, which D-03 explicitly reverses."

requirements-completed: [QP-01, QP-02]

# Metrics
duration: 11min
completed: 2026-07-17
---

# Phase 19 Plan 02: Instruction Bar Summary

**A persistent, tappable instruction bar in `ExerciseScaffold._mainColumn` — a fixed strip (per-type icon + short child-readable line + trailing speaker glyph) that tells the child what to do on every graded question from the screen alone, absorbing the 18-12 "Hear again" pill so there is exactly ONE replay affordance; the 19-01 live-path RED test turns green with zero test edits.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-17T21:00:34Z
- **Completed:** 2026-07-17T21:11:43Z
- **Tasks:** 2
- **Files:** 4 (1 created, 3 modified; generated l10n is gitignored, not counted)

## Accomplishments

- **Task 1 — per-type resolver + strings (QP-02):** `instructionTemplateFor(Exercise) → InstructionSpec` (icon or brand nib SVG + text), a pure switch on `exercise.type` that never renders the `say` line (Pitfall 6). The `writeWord`/`writeLetter` copy-vs-listen split is resolved by a `reveal:"thenHide"` TextPart vs an `AudioPart`; `microDrill` overrides its base line per its first criterion. 15 template defaults live on `ExerciseScaffoldStrings` (so widget tests stay l10n-independent) and mirror to 15 `instructionBar*` ARB keys + a replay-label key, inserted as one contiguous block at the TOP of `app_en.arb`. A new 17-case unit test pins every UI-SPEC Copywriting-Contract string. `flutter gen-l10n` regenerates clean; `flutter analyze` exits 0.
- **Task 2 — the bar + fold (QP-01/QP-02, D-01/D-02/D-03):** a `Key('instructionBar')` strip between the ribbon row and `PromptHeader`, guarded by the existing `_hasInstruction` (hidden on teachCard + empty say-line). UI-SPEC §1 verbatim: `--teal-tint` fill, `--aqua-edge` 1.5px border, radius 16, min-height 64, padding 24, gap 12, 20px Fredoka text, ink-teal 24px leading glyph + trailing `Icons.volume_up_rounded`. The whole bar is one tap target → `_speakInstructionThenRelease` (re-hear), `Semantics(button:true, label:"Hear it again")`. The 18-12 `_HearAgainCta` block AND class are deleted — one replay affordance, never two (D-03). Every value cites `QalamTokens`/`QalamTextStyles`; no gold.
- **Greened the 19-01 contract with ZERO test edits** — all four `exercise_scaffold_instruction_bar_test.dart` cases (bar renders the per-type template not the say line; exactly one replay affordance; tap re-speaks; hidden on teachCard) pass.

## Task Commits

1. **Task 1 RED — resolver contract** — `710874f` (test)
2. **Task 1 GREEN — resolver + ARB strings** — `e73a2c4` (feat)
3. **Task 2 — instruction bar + fold _HearAgainCta** — `5a6f6bc` (feat)

**Plan metadata:** _(this SUMMARY + STATE/ROADMAP/REQUIREMENTS — final docs commit)_

## Files Created/Modified

- `test/features/letter_unit/instruction_template_test.dart` — 17-case resolver contract (per-type template, copy/listen variants, microDrill criterion override, unknown/null fallback, trace brand-glyph)
- `lib/features/letter_unit/widgets/exercise_scaffold.dart` — `InstructionSpec` + `instructionTemplateFor`; 15 template fields + `hearAgain` on `ExerciseScaffoldStrings`; `_instructionBar` / `_instructionLeading`; bar inserted in `_mainColumn`; `_HearAgainCta` block + class deleted; `flutter_svg` import for the nib glyph
- `lib/l10n/app_en.arb` — 15 `instructionBar*` keys + `instructionBarReplayLabel`, one contiguous block after `@@locale`
- `test/features/letter_unit/exercise_scaffold_test.dart` — Test 5/6 (18-12) reconciled to the bar contract (the visible "Hear again" pill is gone; the bar is the single replay control)

## RED/GREEN Evidence

| Test | Status | Note |
|------|--------|------|
| `instruction_template_test.dart` (17 cases) | RED → **GREEN** | RED by missing symbol (commit `710874f`), GREEN after the resolver (`e73a2c4`) |
| `exercise_scaffold_instruction_bar_test.dart` (4 cases, QP-01/02) | RED → **GREEN** | greened by `5a6f6bc` with ZERO test edits |
| `exercise_scaffold_test.dart` (6 cases) | **GREEN** | Test 5/6 reconciled to the bar; all pass |
| `flutter analyze` (edited files) | **0 issues** | resolver, bar, l10n, both tests |

## Decisions Made

- **Resolver keyed on the Exercise, not the bare type** — the plan's `instructionTemplateFor(type)` shorthand can't disambiguate the two `writeWord` sub-variants (both are `type:'writeWord'`). The resolver inspects the prompt parts: an `AudioPart` → listen ("Listen and write"), else a `reveal:"thenHide"` word → copy ("Copy the word"), else the base line. Confirmed against `exercises.json` (dictation carries audio; copy carries `reveal:thenHide`; picture carries neither). Audio takes precedence over copy.
- **15 strings, not 10** — the "~10" estimate excluded the 2 writeWord sub-variants + 3 microDrill overrides + fallback. All shipped as ARB keys + English defaults.
- **LTR English island for the bar** — the instruction imperative is English (working language); wrapping the bar's Row in `Directionality.ltr` (the `_teacherEye` precedent) gives the natural leading-glyph → text → trailing-speaker reading order inside the RTL scaffold. Direction is invisible to the 19-01 test (it checks text + tap only).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — obsolete test contradicts a locked decision] Reconciled the 18-12 "Hear again" pill test**
- **Found during:** Task 2 (running the letter_unit suite after deleting `_HearAgainCta`).
- **Issue:** `exercise_scaffold_test.dart` Test 5/6 (18-12) asserted `find.text('Hear again')` (the old pill's visible label). D-03 explicitly folds the pill into the bar, so those assertions now fail by design — the visible "Hear again" text no longer exists.
- **Fix:** Rewrote Test 5/6 to the new contract — the bar (`Key('instructionBar')`) is the single replay affordance, present in idle/fix/pass, re-speaking the say line on tap; the teachCard case asserts the bar is absent. The test's behavioral intent (a reachable replay control across phases that re-speaks the instruction) is preserved; only the finder changed from the deleted pill text to the bar key. This is NOT the protected 19-01 test.
- **Files modified:** `test/features/letter_unit/exercise_scaffold_test.dart`
- **Verification:** `flutter test .../exercise_scaffold_test.dart` → all 6 pass.
- **Committed in:** `5a6f6bc` (Task 2 commit)

**Total deviations:** 1 (Rule 1 — test/contract reconciliation). No scope creep; no source behavior beyond the plan.

## Threat Surface

- **T-19-06 (Tampering — double replay control) MITIGATED** per the plan register: `_HearAgainCta` is folded into the bar, exactly one replay affordance, enforced by the 19-01 test (`find.text('Hear again')` findsNothing + one `Key('instructionBar')`).
- **T-19-05 (Information disclosure) ACCEPTED**: the bar renders only fixed per-type templates from a code map — no PII, no child data, no user input.
- No new network endpoint, auth path, file access, or schema surface introduced. No threat flags.

## Known Stubs

None. The bar renders real per-type instruction text on every graded question; no hardcoded empty/placeholder values reach the UI.

## Issues Encountered

- **Out-of-scope pre-existing failures** (logged to `deferred-items.md`, NOT fixed here):
  - `meet_section_test.dart` Test 1 (`img.door` image text) — **verified pre-existing** by running it at the pre-plan baseline commit `6611495` in a throwaway worktree (fails identically). A PromptHeader `ImagePart` concern, untouched by this plan.
  - `copy_stimulus_test.dart` (1) + `prompt_header_slot_audio_test.dart` (5) — the Wave-0 RED contract for QP-03/04/05, greened by **19-03**, expected RED at 19-02.
- Goldens NOT re-baked (pre-existing font drift, per 19-01 guidance).

## User Setup Required

None — no packages added; `flutter_svg` was already a dependency; the nib glyph asset already ships.

## Next Phase Readiness

- **19-03** greens `copy_stimulus_test.dart` + `prompt_header_slot_audio_test.dart` (PromptHeader gap slot + hero audio card) and may address the pre-existing `meet_section` `img.door` rendering; appends its ARB keys at the BOTTOM of `app_en.arb` (this plan's block is at the TOP — merge-clean).
- The instruction bar reads its text from `ExerciseScaffoldStrings` defaults; the presenter (`presentGraphExercise`) uses those defaults (no l10n wired at that call site), so the ARB keys are l10n-ready for a later locale without touching the widget.
- Cold device UAT (reading the bar with sound off) remains the end-of-phase human gate.

---
*Phase: 19-question-presentation-overhaul-every-question-self-explanato*
*Completed: 2026-07-17*

## Self-Check: PASSED

- Files: all FOUND (instruction_template_test.dart, exercise_scaffold.dart, app_en.arb, exercise_scaffold_test.dart, 19-02-SUMMARY.md).
- Commits: 710874f FOUND, e73a2c4 FOUND, 5a6f6bc FOUND.
