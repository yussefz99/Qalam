---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 13
subsystem: ui
tags: [flutter, rtl, bidi, responsive-layout, prompt-header, letter-unit]

# Dependency graph
requires:
  - phase: 07-letter-unit-exercise-engine
    provides: PromptHeader composition engine + _ImagePart picture card
provides:
  - Responsive stimulus-picture sizing for lone picture-prompt exercises (grows on a wide tablet column, shrinks to fit a narrow one, authored ~260:176 aspect preserved)
  - LTR-pinned picture caption so trailing punctuation stays in place under the exercise's ambient RTL Directionality
affects: [19-question-presentation-overhaul, letter-unit picture prompts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Lone-image PromptHeader special-case: a single ImagePart is rendered outside the Row/IntrinsicHeight so it can claim the full header width and host a LayoutBuilder"
    - "Two-mode _ImagePart: responsive (LayoutBuilder+AspectRatio) for a lone stimulus, fixed footprint (no LayoutBuilder) for a thumbnail under IntrinsicHeight"

key-files:
  created:
    - test/features/letter_unit/prompt_header_image_test.dart
  modified:
    - lib/features/letter_unit/widgets/prompt_header.dart

key-decisions:
  - "Only the LONE picture-prompt path is responsive; the multi-visual teachCard.meet row keeps the fixed 260x176 thumbnail so it survives the row's IntrinsicHeight (which cannot query a LayoutBuilder's intrinsic dimensions) and does not overflow with audio+forms siblings"
  - "Caption pinned TextDirection.ltr in _ImagePart (both paths) mirroring the shipped feedback_panel_v2 idle-hint fix for the identical trailing-punctuation-under-RTL bug class"

patterns-established:
  - "Responsive stimulus sizing constants (_kStimulusWidthFraction 0.6, min 220, max 560, aspect 260/176) drive the box off available header width, not a hardcoded pixel constant"

requirements-completed: [UAT-18-T2]

# Metrics
duration: ~15min
completed: 2026-07-17
---

# Phase 18 Plan 13: Responsive Stimulus Picture + LTR Caption Summary

**The lone picture-prompt image now sizes to a readable fraction of the available header width (big on a wide tablet, shrinking to fit a narrow column) at its authored aspect, and the English caption is pinned LTR so a trailing "?" no longer bidi-jumps to the front.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-07-17
- **Tasks:** 1 (TDD: RED → GREEN)
- **Files modified:** 1 source + 1 new test

## Accomplishments
- Replaced the hardcoded fixed-size stimulus box (260x176 — the 2026-07-12 fix only bumped the constant, never the strategy) with responsive sizing: a `LayoutBuilder` sizes the box to 60% of the available header width, clamped 220..560, at the ~260:176 aspect via `AspectRatio`.
- Made a lone picture prompt (`[say, image]` — writeLetter.fromPicture / writeWord.picture / buildSentence.picture) render on its own so it claims the full header width, instead of collapsing to a small island inside the Row+IntrinsicHeight path.
- Pinned the caption `TextDirection.ltr` so "what does it start with?" reads correctly (no more "?what does it start with") under the exercise's ambient RTL `Directionality`.
- Preserved the silent-degrade posture (unmapped id / load error → hatched stub, never throws) on both the responsive and fixed paths.

## Task Commits

Each task was committed atomically (TDD cycle):

1. **Task 1 (RED): failing tests for responsive image + LTR caption** - `085baef` (test)
2. **Task 1 (GREEN): responsive stimulus sizing + LTR caption** - `1d968e2` (feat)

_No REFACTOR commit — the GREEN implementation was already clean (`flutter analyze` on the changed files: no issues)._

## Files Created/Modified
- `lib/features/letter_unit/widgets/prompt_header.dart` - `PromptHeader.build` special-cases a lone `ImagePart` to render responsively; `_ImagePart` gains a `responsive` flag, a `_responsiveBox` (LayoutBuilder→fraction→AspectRatio), a shared `_decoratedBox`, and an LTR-pinned caption.
- `test/features/letter_unit/prompt_header_image_test.dart` - New widget tests: wide-column growth (≥55% of available), narrow-column shrink-to-fit (no overflow), silent-degrade under responsive sizing, and the LTR caption assertion.

## Decisions Made
- **Scope the responsive path to lone images.** Expanding the image inside the multi-visual `teachCard.meet` row (`[say, audio, image, forms]`) would (a) crash under `IntrinsicHeight` if it hosted a `LayoutBuilder`, and (b) risk a horizontal overflow with the audio+forms siblings. So the multi-visual path keeps the compact fixed 260x176 thumbnail; only the lone picture-prompt claims the width and sizes responsively.
- **Caption LTR pin follows the existing precedent** (`feedback_panel_v2.dart`'s idle-hint), keeping the fix consistent with the codebase's known-and-patched trailing-punctuation-under-RTL bug class. Source caption strings were not touched (the data is correct; it was a render bug).

## Deviations from Plan

None - plan executed exactly as written. The plan suggested wrapping the image in a LayoutBuilder inside `_ImagePart`; that is implemented, with the added lone-image special-case in `PromptHeader.build` to give the LayoutBuilder a bounded width to size against (a Row's non-flex child would otherwise receive unbounded width, and the IntrinsicHeight cannot host a LayoutBuilder). This realizes the plan's stated intent ("the image itself must now claim the row width") without breaking the teachCard row.

## Issues Encountered
- **Fresh worktree missing generated l10n.** `lib/l10n/app_localizations.dart` is gitignored (documented), so several letter_unit tests failed to *compile* until `flutter gen-l10n` was run. Environment issue, not a code regression — resolved by generating l10n.
- **Known-baseline failure unchanged.** `meet_section_test.dart` Test 1 expects the `img.door` *stub text*, but `img.door` resolves to real art (renders an `Image`) — this is the documented pre-existing baseline failure ("meet_section img.door"), on the unchanged multi-visual fixed path. Out of scope for this plan; not caused or fixed here.

## Verification
- `flutter test test/features/letter_unit/prompt_header_image_test.dart test/features/letter_unit/prompt_header_test.dart` → all 16 pass (4 new + 12 existing).
- Full `test/features/letter_unit/` + exercise-model + resolver suite → 106 pass, 1 pre-existing known-baseline failure (meet_section img.door).
- `flutter analyze` on the changed files → No issues found. (Full-project analyze surfaces only pre-existing warnings in unrelated files; zero new issues introduced.)

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- UAT T2 (stimulus picture too small + caption punctuation) is closed for the picture-prompt exercises. Phase 19's question-presentation overhaul can build on the responsive lone-image path.

## Self-Check: PASSED
- FOUND: lib/features/letter_unit/widgets/prompt_header.dart
- FOUND: test/features/letter_unit/prompt_header_image_test.dart
- FOUND commit: 085baef (test — RED)
- FOUND commit: 1d968e2 (feat — GREEN)

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-17*
