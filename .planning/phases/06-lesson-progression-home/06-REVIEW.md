---
phase: 06-lesson-progression-home
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - lib/core/scoring/letter_scorer.dart
  - lib/core/scoring/tolerances.dart
  - lib/core/strokes/stroke_normalization.dart
  - lib/data/app_database.dart
  - lib/data/curriculum_repository.dart
  - lib/data/drift_progress_repository.dart
  - lib/data/progress_repository.dart
  - lib/dev/authoring_export.dart
  - lib/features/journey/journey_screen.dart
  - lib/features/journey/widgets/journey_node_widget.dart
  - lib/features/onboarding/onboarding_data.dart
  - lib/features/practice/practice_screen.dart
  - lib/features/practice/widgets/ghost_comparison.dart
  - lib/features/practice/widgets/mastery_celebration.dart
  - lib/features/practice/widgets/stroke_order_animation.dart
  - lib/models/lesson.dart
  - lib/models/lesson_progression.dart
  - lib/providers/journey_providers.dart
  - lib/providers/practice_providers.dart
  - lib/providers/progression_providers.dart
  - lib/router/app_router.dart
  - lib/screens/home_screen.dart
findings:
  critical: 1
  warning: 7
  info: 6
  total: 14
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-06-13
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Reviewed the Phase 6 lesson-progression + home slice: the pure-Dart progression
engine, the live Riverpod providers bridging Drift streams, the Drift schema +
migration, the Journey/Home/Practice/Celebration UI, and the scoring/normalization
helpers touched this phase. The architecture is disciplined — the deviation patterns
(hand-written Drift providers, the `_bindDriftStream` AsyncNotifier bridge, the bounded
3s profile await) are well-documented and consistent with the stated project rules, and
the child-data-minimization story holds at the persistence and provider layers (only
`letterId` + int counts are stored; raw point lists stay in widget State).

The single blocker is a privacy/data-lifetime defect in `_TraceWorkspace`: the child's
normalized stroke points are retained in widget State even on a **passing** rep, despite
the code comment asserting they are staged "only on a fresh miss." This holds the most
privacy-sensitive data in the app longer than the design contract permits and contradicts
the T-03-01/T-06-04 invariant the file claims to enforce. The remaining findings are
robustness gaps (unguarded JSON casts in hand-edited curriculum data, dead per-stroke
code paths, a swallowed-error degradation that can mask a genuine misconfiguration) and
quality items.

## Critical Issues

### CR-01: Child stroke points retained on a passing rep, contradicting the T-03-01 data-lifetime invariant

**File:** `lib/features/practice/practice_screen.dart:637-652`
**Issue:** `_handleLetterComplete` builds the normalized `candidate` stroke list and then
unconditionally assigns it to `_failingStrokes` after scoring, regardless of whether the
rep passed or failed:

```dart
setState(() {
  _isScoring = false;
  _failingStrokes = candidate;   // set even when the rep PASSED
  _showGhost = false;
});
```

The doc comment two lines above claims "Staging only on a fresh miss avoids showing a
stale stroke after the child retries," but the code does not branch on pass/fail. On a
**clean rep** the phase advances to `showPraise` (or `celebrate`), and the child's full
normalized stroke geometry sits in `_failingStrokes` until the next `_clear()` fires on
"Keep going" / retry. The file header and the field doc both assert these points are held
"only ever true in showFix" and are "cleared on retry, on pass, and on dispose" (T-03-01 /
T-06-04) — this code violates that contract: on a pass they are neither cleared nor
gated, and they survive the praise phase. This is a data-lifetime/privacy defect on the
single most sensitive data class in the app, not a cosmetic one.

It is also a latent functional bug: any future `_ActionRow` branch (or test) that gates
on `_failingStrokes != null` will now see a retained stroke after a *successful* rep.

**Fix:** Only stage the candidate when the resulting phase is `showFix`. Read the
post-scoring phase and gate the assignment:

```dart
await widget.onLetterComplete(strokes);
if (!mounted) return;
final bool failed = widget.state.phase == PracticePhase.showFix;
setState(() {
  _isScoring = false;
  _failingStrokes = failed ? candidate : null; // clear on pass (T-03-01)
  _showGhost = false;
});
```

Because `widget.state` is the pre-rebuild value, prefer reading the controller's current
phase via `ref.read(practiceSessionControllerProvider(...))` after the await, or have
`onLetterComplete` return the pass/fail result so the workspace can branch deterministically
rather than inferring from a rebuilt `widget.state`.

## Warnings

### WR-01: `progressionProvider` swallows ALL profile errors, masking real misconfiguration

**File:** `lib/providers/progression_providers.dart:125-133`
**Issue:** The `catch (_)` around the profile read degrades every failure — including a
genuine bug (e.g. a corrupt profile row, a schema mismatch, a programming error in
`childProfileProvider`) — silently to `startingLessonId = null` → first lesson. The
T-05-07 degradation pattern is meant to cover the platform-channel hang and the
no-profile case, but catching bare `Object` also hides defects that should surface in
logs/tests. A child whose real `startingLessonId` is `lesson_05` would be silently sent
back to `lesson_01` on any transient read error, with no signal that anything went wrong.
**Fix:** Narrow the catch to the expected degradation conditions (`TimeoutException` and a
null profile) and let unexpected errors propagate to the provider's `AsyncError` (the UI
already degrades on error at the widget layer). At minimum, distinguish timeout from other
errors so the deliberate-hang path stays covered without swallowing logic bugs:

```dart
} on TimeoutException {
  startingLessonId = null;
}
```

### WR-02: Unguarded JSON casts in `Lesson.fromJson` / `LessonItem` will throw on hand-edited curriculum

**File:** `lib/models/lesson.dart:7,17,30-31,65-71`
**Issue:** The project explicitly states the owner's mother hand-edits `lessons.json`
(see the defensive `toleranceRamp` parse, which correctly never throws). But the
surrounding parse is not defensive: `json['id'] as String`, `json['order'] as int`,
`json['type'] as String`, `json['ref'] as String`, `LessonTitle(display: json['display']
as String)`, and `passRule: json['passRule'] as String` all hard-cast. A missing or
mistyped key (e.g. `order` written as `"1"`, or an item missing `ref`) throws a
`TypeError` / `CastError` that is NOT a `FormatException` and is NOT caught by
`getLesson`'s `on StateError` handler — it propagates up through `getLessons()` and
`progressionProvider`, where it lands in the `.when(error:)` degradation. Result: a single
typo in any lesson silently collapses the entire progression to the alif fallback for the
whole journey, with the real cause buried. This is inconsistent with the deliberately
defensive `toleranceRamp` and `requires` handling in the same file.
**Fix:** Validate-and-report at load time the way `CurriculumRepository._ensureLoaded`
does for `referenceStrokes` (throw a `StateError` naming the offending lesson id +
field), or make the casts tolerant with clear per-field errors. Do not let a raw
`CastError` reach the degradation layer where it is indistinguishable from a hang.

### WR-03: Dead per-stroke code path (`onStrokeResult`) is unreachable and risks divergence

**File:** `lib/providers/practice_providers.dart:283-297`
**Issue:** `onStrokeResult(StrokeResult)` is never called from any reviewed file — the
practice screen scores the whole letter via `scoreLetter` and dispatches exclusively
through `onLetterResult(LetterResult)` (`practice_screen.dart:181-183`). The comment calls
it "(legacy) per-stroke pass path." It duplicates the pass/miss dispatch logic of
`onLetterResult`; if the clean-rep/miss semantics change in one and not the other, a future
caller wiring up `onStrokeResult` inherits stale behavior. Dead, duplicated control-flow in
the session state machine is a correctness hazard, not just clutter.
**Fix:** Remove `onStrokeResult` (and confirm `StrokeResult` is still needed by the
import). If it must stay for an imminent feature, mark it `@visibleForTesting` or guard it
behind a clear "not wired" assertion so it cannot silently drift.

### WR-04: `future`-state node drops its shadow and is excluded from the pulse rebuild

**File:** `lib/features/journey/widgets/journey_node_widget.dart:151-186,219-223`
**Issue:** `_buildCircle` is invoked inside an `AnimatedBuilder(animation: _pulseSpread)`,
but for `JourneyNodeState.future` it returns an entirely separate `SizedBox`/`CustomPaint`
subtree that ignores `_buildShadow()` and never reads `_pulseSpread`. That is acceptable
for `future` (no pulse intended), but the structure is fragile: the inner `Container` in
the future branch re-declares `color: QalamColors.surfaceRaised` and omits the
`boxShadow`, so the solid `circle` built immediately above it (lines 152-162, including its
shadow) is constructed and then discarded every animation frame. For a node that doesn't
animate this is wasted work, and the duplicated 68px / color literals invite drift between
the two render paths.
**Fix:** Build the future-state subtree without first constructing the unused `circle`
(early-return the dashed variant before building `circle`), and source the diameter/color
from shared constants so the two paths cannot diverge.

### WR-05: `_GreetingHeaderReader` resolves nickname label but renders nothing for an unknown id

**File:** `lib/screens/home_screen.dart:289-293,380-400`; `lib/features/onboarding/onboarding_data.dart:73-78`
**Issue:** `resolveNicknameLabel` returns `null` for an unknown `nicknameId` (correct,
no-PII degradation). But `_GreetingHeaderReader` passes that potentially-null label
straight into `_GreetingLayout`, where `nicknameLabel != null` gates the entire greeting
line. If a profile carries an id not in `kNicknames` (e.g. after the owner's mother prunes
the nickname set per the TODO at onboarding_data.dart:29 — which the comment says "possibly
which nicknames appear" can change), the child sees the avatar but the greeting silently
falls through to the *literal* "Welcome back, Layla." branch (line 406) — a hardcoded
wrong name, not the child's. Because labels can change with no data migration (by design),
this mismatch is reachable in normal operation, not just corruption.
**Fix:** When `profile != null` but `resolveNicknameLabel` returns null, fall back to the
generic localized greeting *without* the placeholder "Layla" literal (use
`l10n?.homeGreeting('')` semantics), or treat an unresolvable id as the no-nickname path
explicitly so the stale literal name is never shown over a real profile.

### WR-06: `cleanReps` is never clamped to non-negative before becoming a ramp index

**File:** `lib/providers/practice_providers.dart:184-187,161-167`
**Issue:** `_presetFor(int cleanReps)` indexes the ramp with `ramp[math.min(cleanReps,
ramp.length - 1)]`. It clamps the upper bound but not the lower. `cleanReps` is seeded from
`getCleanReps` which the repository documents as "0 when never practiced," and the int
column is only ever written via `setCleanReps` with values the controller computes (`+1` or
`0`), so a negative is not reachable today. But there is no guard: a corrupt/hand-poked
`letter_reps` row with a negative `cleanReps` (the DB is on-device and not validated on
read) would produce `ramp[negative]` → `RangeError`, crashing the session-build path. The
same unclamped value also drives `glyphAlpha` math and the pip loop.
**Fix:** Clamp on read: `final reps = math.max(0, persisted);` in `_loadLetter`, and/or
`ramp[math.min(math.max(cleanReps, 0), ramp.length - 1)]` in `_presetFor`. Defensive reads
of on-device data match the rest of the file's posture.

### WR-07: `_todayCardDataProvider` error fallback can itself throw, escaping the degradation contract

**File:** `lib/screens/home_screen.dart:585-612`
**Issue:** The `catch (_)` recovery branch re-issues awaits (`childProfileProvider.future`
with a 3s timeout, then `getLesson`, then `resolve`). If the timeout fires
(`TimeoutException`) or `resolve` throws (`StateError('unknown letter ...')` at line 591
when a lesson references a letter id absent from `letters.json`), that exception escapes
the `catch` block entirely and surfaces as the provider's error — relying on
`_TodaysLessonCardReader`'s `.when(error:)` static-alif fallback to catch it. That outer
fallback does exist, so the child never sees a raw error — but the layering means a
genuine curriculum integrity problem (lesson points at a non-existent letter) is masked
twice and only ever renders as a silent alif card. The comment claims this branch
guarantees "the child always has a Start," which is only true because of the outer
`.when`, not this block.
**Fix:** This is defensible as written, but the double-masking hides curriculum
misconfiguration. Add a load-time integrity check (every `LessonItem.ref` of type `letter`
resolves to a real letter) in `CurriculumRepository._ensureLoaded` — the same
fail-loud-at-load pattern already used for `referenceStrokes` — so a dangling ref is a
build-time/test failure, not a silently-degraded home card in production.

## Info

### IN-01: Hardcoded `'lesson_01'` / `'alif'` / `'ا'` literals scattered as fallbacks

**File:** `lib/screens/home_screen.dart:606,639,715,718`; `lib/features/practice/practice_screen.dart:111,295-297`; `lib/providers/progression_providers.dart:133` (indirect); `lib/features/onboarding/onboarding_data.dart:54-66`
**Issue:** The first-lesson identity is spread across many files as raw string literals
(`'lesson_01'`, `'alif'`, `'ا'`). The namespace migration note in `onboarding_data.dart`
explicitly warns that this map and the v3→v4 migration "must agree" — magic strings make
that agreement unenforced. A rename of the first lesson requires touching ~6 files.
**Fix:** Define a single `kFirstLessonId` (and `kFallbackGlyph`) constant and reference it
everywhere a degradation default is needed.

### IN-02: `_MascotCheer` wraps `SvgPicture.asset` in try/catch that cannot catch async load failures

**File:** `lib/features/practice/widgets/mastery_celebration.dart:303-315`
**Issue:** The `try { return SvgPicture.asset(...) } catch (_)` only catches synchronous
throws from the *constructor*, which does not perform the asset load — decode failures
happen asynchronously inside the widget. The intended "graceful fallback if asset missing"
is actually delivered by `flutter_svg`'s own `placeholderBuilder`, not this try/catch
(which is effectively dead). Compare the correct pattern in `home_screen.dart:365-373`
which uses `placeholderBuilder`.
**Fix:** Remove the misleading try/catch and add `placeholderBuilder: (_) => const
SizedBox.shrink()` to match the home-screen mascot pattern.

### IN-03: Stale `TODO(03.1)` and structural-constant comments left in shipped UI

**File:** `lib/features/journey/journey_screen.dart:312` (`// TODO(03.1): dashed border for fidelity`); `lib/router/app_router.dart:112-120` (commented-out parent redirect block)
**Issue:** A Phase-03.1 TODO survives in Phase-6 shipped code; the parent-redirect example
is a large commented-out block. The parent block is intentional seam documentation (D-08),
but the dashed-border TODO is an unresolved fidelity gap with no tracking.
**Fix:** Either resolve the dashed-border TODO or move it to the issue tracker; keep the
parent-seam comment (it is referenced by the architecture decision).

### IN-04: Magic layout numbers throughout `journey_screen.dart`

**File:** `lib/features/journey/journey_screen.dart:45-56,184,267-309`
**Issue:** The canvas is built from many bare pixel literals (1180/816 implied, `take(28)`,
`left: 450, top: 634`, `left: 390, top: 717`, `pos.dx - 34`). The `34 = half of 68px node
diameter` is commented but the 68 lives in `journey_node_widget.dart` as its own literal —
a change to node size silently breaks centering. `take(28)` hardcodes the curriculum size.
**Fix:** Centralize the node diameter and the 28-letter count as named constants shared
between the screen and the node widget.

### IN-05: `_combinedBounds` / `_Bounds` duplicated across scorer and normalization

**File:** `lib/core/scoring/letter_scorer.dart:191-209,236-239`; `lib/core/strokes/stroke_normalization.dart:33-53`
**Issue:** `letter_scorer.dart` defines its own private `_Bounds` + `_combinedBounds`, and
`stroke_normalization.dart` defines a near-identical pair, while the normalization file's
header explicitly positions itself as "the one source of the combined-bbox math … no
duplicated bbox derivation." The scorer's dot-position check (`_checkDots`) re-derives the
same bbox logic the shared core was created to centralize.
**Fix:** Have `letter_scorer.dart`'s `_checkDots` consume the shared
`normalizeStrokesToUnitBox` (or expose the bounds helper from the core) rather than
maintaining a second copy of the math the core was extracted to own.

### IN-06: `getDefaultToleranceRamp` length can mismatch `cleanRepsToAdvance` with no warning

**File:** `lib/providers/practice_providers.dart:155-157,184-187`; `lib/core/scoring/tolerances.dart:44-60`
**Issue:** The ramp index is clamped to the last entry when `cleanReps` exceeds the ramp
length, so a letter requiring 5 clean reps with a 3-entry ramp `[loose, normal, strict]`
scores reps 3 and 4 at `strict` (the last entry). That is a reasonable default, but it is
silent — the curriculum author gets no signal that the ramp is shorter than the rep target,
so a letter intended to ease through 5 reps quietly hardens to strict for the final two.
**Fix:** Not a defect, but consider a debug-mode assertion or load-time note when a
letter's `cleanRepsToAdvance` exceeds the resolved ramp length, so the owner's mother sees
the mismatch during authoring rather than discovering it through play.

---

_Reviewed: 2026-06-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
