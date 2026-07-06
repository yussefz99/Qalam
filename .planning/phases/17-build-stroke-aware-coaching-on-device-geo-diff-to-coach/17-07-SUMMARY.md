---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 07
subsystem: coaching-contract
tags: [client, cutover, ground-04, strk-01, d-a, tutor-facts, exercise-scaffold, write-surface, grep-guard, wave-6]

# Dependency graph
requires:
  - phase: 17-06
    provides: "the client criteria/word mirror this cuts over on top of — CheckResult carries the derived facts, buildTutorFacts derives them off result, TutorFacts emits them omit-when-null; 17-06 deliberately LEFT the aiJudge/strokeImage/onStrokeImage seams untouched for THIS plan"
  - phase: 17-03
    provides: "the upgraded per-form multi-criteria scoreLetter → LetterScore that now OWNS pass/fail at the scorer (D-A) — the deterministic verdict this cutover routes every path through"
  - phase: 14-04
    provides: "the GROUND-02 client guard surface (payload_nonpii whitelist ∪ nested-key sets + the tightened token regex + the source-scan idiom) the new grep-guard copies"
provides:
  - "The deterministic on-device scorer OWNS pass/fail on EVERY client path — the verdict + star render instantly, synchronously, offline, from the CheckResult (GROUND-01 restored; D-A; the Phase-17.1 aiJudge deferral is DELETED, so UAT F2 flash-then-overwrite is structurally impossible)"
  - "strokeImage is GONE from the client — the onStrokeImage callback, the baa-only PNG render (_renderStrokesToBase64Png), the TutorFacts field/param/emission, and the TutorDecision verdict plumbing are all deleted (GROUND-04 surface shrink, client half); a rendered image of child handwriting can no longer leave the device"
  - "removal ordering satisfied (RESEARCH Pattern 3): the client stops sending strokeImage FIRST, so 17-08 can safely delete the optional server field + image_judge.py"
  - "a NEW source-scan grep-guard (strokeImage/_renderStrokesToBase64Png/aiJudge absent from lib/) + a NEW behavioral cutover test (verdict applies before/without the brain; brain failure only clears the tutor line) make the retirement regression-proof from the client side"
  - "the pre-existing write_surface Test 5 failure is RECONCILED (the hanging headless toImage render is deleted → onResult fires → verdict reaches the host); full-suite failures 9 → 8"
affects: [17-08, 17-10, coaching-contract, tutor-facts, exercise-scaffold]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Verdict-owns-instantly cutover (D-A): applyResult runs UNCONDITIONALLY and synchronously in _onResult; the brain call is fired AFTER and can only set/clear the tutor-owned coaching line (tutorLineProvider) — never the verdict, star, or trajectory. A cold/slow/offline/failing server affects only the words."
    - "Removal-direction wire hygiene (Pattern 3): CLIENT stops sending first (strokeImage field/param/emission deleted here), server field deleted next plan (17-08); the byte-shape of a normal payload is unchanged because strokeImage was already omit-when-null."
    - "Source-scan grep-guard: recursively read lib/*.dart, strip //-comment lines, assert a retired token (strokeImage/_renderStrokesToBase64Png/aiJudge) appears in NO code line — plus a sanity leg proving the scan reads real source (onStrokeDiff, the surviving transport, IS found)."
    - "Behavioral D-A pin via the ONE switch point: stub the brain at tutorBrainFactoryProvider (a never-completing Completer future and an error future) and drive a scored result through WriteSurface.onResult (== the scaffold's _onResult) — proving the verdict is applied synchronously, before/without the brain."

key-files:
  created:
    - test/features/letter_unit/stroke_image_grep_guard_test.dart
    - test/features/letter_unit/exercise_scaffold_cutover_test.dart
  modified:
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - lib/features/letter_unit/widgets/write_surface.dart
    - lib/tutor/tutor_facts.dart
    - lib/tutor/tutor_facts_builder.dart
    - lib/tutor/tutor_decision.dart
    - lib/tutor/remote_agent_brain.dart
    - test/tutor/payload_nonpii_test.dart

key-decisions:
  - "The scorer verdict applies UNCONDITIONALLY (D-A): the `if (!aiJudge)` guard is gone — applyResult/markLatency/onGraphNodePassed/_recordAttempt run once, synchronously, on every path. This restores GROUND-01 semantics and kills the flash-then-overwrite the deferral existed to hide (UAT F2 fixed by construction)."
  - "TutorDecision.verdict was FULLY REMOVED (not left null-tolerant): the plan allowed either; no test references `.verdict`, and its only consumer (the deleted aiJudge overrule block) is gone, so full removal keeps the code honest. _parseCoachOut now reads only toolName + args and tolerates an absent verdict key (the normal path never carried one; 17-08 deletes it from the server CoachOut)."
  - "All three orphaned imports removed from write_surface (dart:convert, dart:ui, AND dart:math) — the plan named convert/ui, but math (min/max) was used ONLY inside _renderStrokesToBase64Png and orphaned too; leaving it would fail flutter analyze."
  - "applyVerdict in exercise_controller.dart is now DEAD but LEFT in place — exercise_controller.dart is not in this plan's file scope, and an unused public method raises no analyze warning. Flagged in deferred-items for a 17-10 cleanup sweep."
  - "STRK-01 / GROUND-04 NOT checkbox-marked (17-01/03/04/05/06 precedent): this closes the CLIENT half of GROUND-04; ADR-017 (17-10) + the single live re-deploy complete it. requirements-completed stays []."

patterns-established:
  - "Grep-guard + behavioral test land in the SAME plan as the cutover (not after): the source-scan makes a strokeImage regression impossible to miss, and the widget test pins the runtime D-A guarantee a grep cannot see."

requirements-completed: []

# Metrics
duration: 32min
completed: 2026-07-06
---

# Phase 17 Plan 07: Client Geo-Diff Cutover (D-A) Summary

**The client half of CONTEXT increment 6 (locked D-A — this REVERSES Phase-17.1's AI-owns-pass/fail): the deterministic on-device scorer now OWNS pass/fail on every client path (the verdict + star render instantly, synchronously, offline), the aiJudge deferral and the whole `strokeImage` render/send flow are deleted (GROUND-04 surface shrink, client half; removal-ordering satisfied so 17-08 can drop the server field), and a source-scan grep-guard + a behavioral cutover test make the retirement regression-proof.**

## Performance

- **Duration:** ~32 min
- **Completed:** 2026-07-06
- **Tasks:** 2 (both `type="auto"`)
- **Files modified:** 7 (5 lib + 2 test); **created:** 2 test files

## Accomplishments

- **The verdict is instant, offline, $0, and un-overrulable (D-A / GROUND-01).** In `exercise_scaffold._onResult` the `final aiJudge = strokeImage != null;` branch and its `if (!aiJudge)` guard are gone — `applyResult` / `markLatency` / `onGraphNodePassed` / `_recordAttempt` now run UNCONDITIONALLY and synchronously, in the same call as the scorer result. The brain is fired AFTER and can only set/clear the tutor-owned coaching line; on brain failure the `catchError` just clears that line — the verdict/star STAND. UAT F2 (flash-then-overwrite) is now structurally impossible: nothing is ever applied twice.
- **No rendered handwriting image is ever constructed or sent (GROUND-04 client half).** `write_surface` loses `onStrokeImage`, the baa-only PNG render call in `_onLetterComplete`, and `_renderStrokesToBase64Png` entirely (plus the now-orphaned `dart:convert`/`dart:ui`/`dart:math` imports). `TutorFacts` loses the `strokeImage` field + param + emission; `TutorDecision` loses the `verdict` field; `RemoteAgentBrain._parseCoachOut` loses the verdict plumbing (it now reads only `toolName` + args, tolerating an absent verdict key). A rendered image of the child's handwriting can no longer leave the device — a net privacy win.
- **The retirement is regression-proof from the client side.** NEW `stroke_image_grep_guard_test.dart` recursively scans `lib/` (comments stripped) and fails the build if `strokeImage` / `_renderStrokesToBase64Png` / `aiJudge` / `_pendingStrokeImage` reappear — with a sanity leg proving the scan reads real source (`onStrokeDiff`, the surviving transport, is still found). NEW `exercise_scaffold_cutover_test.dart` pins the RUNTIME D-A contract behaviorally (a grep cannot see it): the verdict applies with a never-completing brain future, a failing brain future leaves the verdict standing and clears only the tutor line, and the verdict is set synchronously in the same call as the scorer result.
- **The pre-existing write_surface Test 5 failure is reconciled (in-scope, not silently absorbed).** Root cause: the baa-only `_renderStrokesToBase64Png` awaited `Picture.toImage()`, which never resolves in the headless `flutter test` VM, so `onResult` never fired and `received` stayed null. Deleting the render path fixes it — Test 5 is now GREEN. Full-suite failures dropped 9 → 8 (exactly `baseline minus write_surface`, recorded for 17-10's reconciliation).
- **Guards + regressions all green.** `flutter test test/tutor/ test/features/` → the only failures are the 2 known pre-existing baseline (meet_section door-image Test 1; mastery_celebration font-drift golden). `flutter analyze` over the six modified lib files → **No issues found!**. Server `-m code` regression → **105 passed, 1 skipped** (untouched, matches the 17-06 baseline exactly).

## Task Commits

Each task committed atomically:

1. **Task 1: client cutover — delete the aiJudge deferral + image render; scorer verdict unconditional** — `fce4828` (feat)
2. **Task 2: behavioral D-A cutover test** — `848db71` (test)

## Files Created/Modified

- `lib/features/letter_unit/widgets/exercise_scaffold.dart` — deleted `_pendingStrokeImage`, `_onStrokeImage`, the `aiJudge` branch + guard, the `strokeImage:` arg, the `decision.verdict` overrule block, and the `onStrokeImage:` wiring; `_onResult` now applies the scorer verdict unconditionally + synchronously; simplified `catchError` (verdict already applied → only clear the tutor line); doc-comments rewritten to D-A.
- `lib/features/letter_unit/widgets/write_surface.dart` — deleted the `onStrokeImage` param + doc, the baa-only PNG render call, `_renderStrokesToBase64Png`, and the orphaned `dart:convert`/`dart:ui`/`dart:math` imports; `onStrokeDiff` (the surviving derived-diff transport) untouched.
- `lib/tutor/tutor_facts.dart` — deleted the `strokeImage` field + constructor param + `toMap` emission + the 17.1 doc-comment; `toMap` doc updated.
- `lib/tutor/tutor_facts_builder.dart` — deleted the `strokeImage` param + pass-through (the signature stays the non-PII guard).
- `lib/tutor/tutor_decision.dart` — removed the `verdict` field from the sealed base + `super.verdict` from all four ACTION subtypes.
- `lib/tutor/remote_agent_brain.dart` — `_parseCoachOut` no longer reads/attaches a `verdict`; it reads only `toolName` + args and tolerates an absent verdict key.
- `test/tutor/payload_nonpii_test.dart` — removed `strokeImage` from the whitelist + the fully-populated fixture + the token-guard "OK" list; the `toJson().keys.toSet() == _whitelist` assertion stays balanced.
- `test/features/letter_unit/stroke_image_grep_guard_test.dart` — **NEW** source-scan guard.
- `test/features/letter_unit/exercise_scaffold_cutover_test.dart` — **NEW** behavioral D-A pin.

## Decisions Made

See frontmatter key-decisions. The load-bearing ones: the verdict applies **unconditionally + synchronously** (D-A, the F2 fix); `TutorDecision.verdict` **fully removed** (no test needs it; only the deleted aiJudge path consumed it); all three orphaned imports removed (`dart:math` beyond the plan's named two); `applyVerdict` left dead (out of file scope); STRK-01/GROUND-04 **not** checkbox-marked (ADR-017 at 17-10 completes GROUND-04).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed a third orphaned import (`dart:math`) beyond the plan's named two**
- **Found during:** Task 1 (write_surface cutover)
- **Issue:** The plan named `dart:convert` / `dart:ui` as the imports to drop if orphaned, but `dart:math as math` (min/max) was used ONLY inside `_renderStrokesToBase64Png`; after deleting the render it was orphaned too, and an unused import fails `flutter analyze`.
- **Fix:** Removed all three orphaned imports.
- **Files modified:** lib/features/letter_unit/widgets/write_surface.dart
- **Verification:** `flutter analyze` over the six modified lib files → "No issues found!"
- **Committed in:** `fce4828` (Task 1)

---

**Total deviations:** 1 auto-fixed (1 blocking, to keep `flutter analyze` green). No architectural changes; no scope creep; no server/Dart-runtime behavior changed beyond the intended cutover.

## Issues Encountered

- **Pre-existing `flutter analyze` info-lints in an untouched file.** The plan's verify runs `flutter analyze lib/tutor/ lib/features/letter_unit/`, which surfaces 12 info-level `unnecessary_brace_in_string_interps` lints in `lib/features/letter_unit/letter_unit_screen.dart` — a file NOT in this plan's touch set. Per the executor SCOPE BOUNDARY these are out of scope; logged to `deferred-items.md`. The six files this plan modified analyze clean.
- **2 known pre-existing full-suite failures remain** (meet_section door-image Test 1; mastery_celebration font-drift golden — both in MEMORY), plus the curriculum-data/golden family (alif_reference ×2, all_letters_validation, reference_overlay golden, glyph_audit golden, curriculum_repository_v2). None touch the changed code; total 8 = the 17-06 baseline (9) minus the now-reconciled write_surface Test 5.

## Known Stubs

None — this plan is pure removal + guards. No placeholder values, no TODO/FIXME, no UI-bound empty data introduced.

## Threat Flags

None new. The plan's threat register is satisfied:
- **T-17-15 (Information Disclosure — strokeImage client half):** MITIGATED — render + field + param + callback deleted; grep-guard scans `lib/` for the token; a net privacy win (a rendered image of child handwriting no longer leaves the device). Server half deleted in 17-08; recorded in ADR-017 (17-10).
- **T-17-16 (Elevation of Privilege — verdict spoofing by the model):** MITIGATED — structural: the verdict is computed on-device before any model call; the aiJudge overrule block + `TutorDecision.verdict` are deleted, so no client path can apply a model verdict; the behavioral cutover test pins it.
- **T-17-17 (Denial of Service — server cold/offline vs the child's flow):** MITIGATED — the verdict + star render synchronously before the network call; brain failure only clears the tutor line; pinned by the Task 2 behavioral test (never-completing + failing brain).
- **T-17-SC (Tampering — package installs):** green — zero new packages (pubspec untouched).

## Next Phase Readiness

- **17-08 (server harden) is unblocked:** the client no longer sends `strokeImage`, so the optional server field + `image_judge.py` + `CoachOut.verdict` can be deleted safely (removal ordering satisfied structurally — client-first, RESEARCH Pattern 3). `_parseCoachOut` already tolerates the field's absence.
- **17-10 (ADR-017 + single Cloud Run re-deploy + HUMAN-UAT):** GROUND-04's checkbox flips once ADR-017 records the verdict-authority un-reversal + the derived-diff data flow, and the widened contract re-deploys. This plan closes the CLIENT half of the surface shrink; STRK-01/GROUND-04 stay unmarked here per precedent.
- **Follow-up flagged (deferred-items):** the now-dead `applyVerdict` in `exercise_controller.dart` and the 12 `letter_unit_screen.dart` info-lints are queued for a cleanup sweep alongside 17-10.

## Self-Check: PASSED

- All 7 modified + 2 created files exist on disk; this SUMMARY exists.
- Commits `fce4828` (Task 1 feat) + `848db71` (Task 2 test) present in git log.
- Acceptance re-verified: `grep -rn "strokeImage" lib/ --include="*.dart" | grep -v "//"` → 0; `grep -rn "_renderStrokesToBase64Png\|aiJudge\|_pendingStrokeImage" lib/` → 0; `onStrokeDiff` still wired in write_surface; `flutter test test/features/letter_unit/write_surface_test.dart test/features/letter_unit/stroke_image_grep_guard_test.dart test/features/letter_unit/exercise_scaffold_cutover_test.dart test/features/letter_unit/exercise_scaffold_test.dart test/tutor/payload_nonpii_test.dart test/tutor/remote_agent_brain_test.dart test/tutor/tutor_facts_builder_test.dart` → all pass; `flutter analyze` (6 modified lib files) → 0 issues; server `-m code` → 105/1-skip (unchanged); full suite → 747 passed / 8 known-baseline failed (9 − write_surface).

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
