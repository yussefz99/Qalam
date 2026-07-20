---
phase: quick-260720-up4
plan: 01
subsystem: curriculum
tags: [curriculum-graph, mastery, selection, letter-unit, riverpod, drift]

# Dependency graph
requires:
  - phase: "15 (dynamic selection)"
    provides: "CurriculumGraph + isMasteryMet/isMasteryMetForPresented + the exercise-selector router"
  - phase: "18-07 (live selection wiring)"
    provides: "LetterUnitController.selectNext live path + recordMasteryIfMet"
  - phase: "25-03/25-05 (seen-letters wall)"
    provides: "the four-layer allowlist (L0 validate.py / L1 lint / L3 selector) the union of which this shrinks"
provides:
  - "14-node baa graph (both assets, byte-parity) — the 4 reach-ahead grammar cards are dormant"
  - "D-06 routing invariant: _selectNext terminates on presented-essential mastery-met (baa now advances)"
  - "shared _isMasteryMetNow predicate (routing check == recording check)"
  - "screen-supplied presentedEssentials into start() (no getUnit on the scored hot path)"
  - "live-path regression test proving the 14-node graph reaches the star + advances to taa"
affects: [phase-27 (mother F2 taa/thaa letter-form rework), phase-25/29 (mother re-confirmation packet), server redeploy]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Screen hands already-loaded config (presentedEssentials) to the controller so a hot-path predicate resolves synchronously — no per-moment repo/rootBundle read"
    - "Dormant-by-node-removal: remove graph nodes to park a card while keeping its exercise config reversible in exercises.json (mirrors buildSentence)"

key-files:
  created:
    - test/features/letter_unit/baa_live_path_mastery_test.dart
  modified:
    - assets/curriculum/graphs/baa.json
    - assets/curriculum/curriculum_graph.json
    - lib/features/letter_unit/letter_unit_controller.dart
    - lib/features/letter_unit/letter_unit_screen.dart
    - lib/tutor/exercise_selector_provider.dart
    - tools/content/validate.py
    - test/curriculum/learned_letters_lint_test.dart
    - test/tutor/l3_learned_letters_parity_test.dart
    - tools/firebase/test_seed_curriculum_v2.py
    - server/app/curriculum_data/curriculum_graph.json
    - server/app/curriculum_data/baa_authored_ids.json
    - test/curriculum/curriculum_graph_test.dart
    - test/curriculum/mastery_condition_test.dart
    - test/features/letter_unit/l3_illegal_card_guard_test.dart

key-decisions:
  - "The 4 baa reach-ahead grammar cards are made DORMANT by node removal (owner 2026-07-20), reversing the mother's F1 verdict pending her re-confirmation packet"
  - "Routing termination MUST use the presented-essential subset (not full-graph), else baa's 6 unpresented essentials block the star forever — so the screen supplies presentedEssentials to the controller"
  - "The mastery-met predicate is resolved synchronously on the scored hot path from a screen-supplied list, never a controller getUnit (that stalled _selectNext in multi-case widget tests)"

patterns-established:
  - "Hot-path config injection: the widget that already loaded a config passes it into the controller's start() so the controller avoids a redundant async repo read on the per-frame/per-moment path"

requirements-completed: [D-06, D-14]

# Metrics
duration: 48min
completed: 2026-07-20
---

# Quick 260720-up4: Fix "baa never advances" — dormant 4 reach-ahead cards + mastery-route termination Summary

**The baa unit now reaches the star and advances to taa: the 4 reach-ahead grammar cards are dormant (18→14 all-essential graph nodes) and `_selectNext` terminates selection the moment presented-essential mastery is met — closing the never-terminating walk that starved `recordMasteryIfMet`.**

## Performance

- **Duration:** ~48 min
- **Started:** 2026-07-20T19:15:33Z
- **Completed:** 2026-07-20T20:04:14Z
- **Tasks:** 3 (plus 1 follow-on test-fix commit)
- **Files modified:** 16 (1 created)

## Accomplishments

- **Task 1 — dormancy + allowlist shrink.** Removed `baa.fillBlank.adjective` + `baa.transformWord.{dual,plural,opposite}` nodes from both baa graph assets (byte-parity holds; the now node-less `wordBuilding` + `grammarTransform` competencies are retained, parser-tolerated). Shrank every wall layer's union 22→18 (L0 `_BAA_D09_EXCEPTIONS` emptied, L1 `baaOwnerApprovedExceptions` emptied, L3 `kApprovedReachAheadExceptions` drops the 4 baa ids, the l3 pinned-set is now 18, the seed-test `_BAA_D09_IDS` emptied). Regenerated the server copies (14 nodes / 14 authored ids). Exercise CONFIGS stay dormant in `exercises.json` (fully reversible).
- **Task 2 — D-06 routing invariant.** `_selectNext` now returns null (routes to Mastery) the moment presented-essential mastery is met, on pass AND fail, BEFORE the pick logic. A shared `_isMasteryMetNow` predicate means the routing-termination check and `recordMasteryIfMet` can never drift (no Mastery-with-no-star dead-end). The presented set is resolved synchronously on the scored hot path from a screen-supplied list.
- **Task 3 — live-path regression.** A one-case-per-file test drives the REAL bundled 14-node baa graph through the REAL selection path to the star and asserts progression to taa, without ever calling `recordMasteryIfMet()` directly.

## Task Commits

1. **Task 1: dormant 4 cards + shrink allowlists + regen server** — `85e14ae` (feat)
2. **Task 1 follow-on: baa-graph structure tests for the 14-node graph** — `b4d53b0` (test)
3. **Task 2: terminate selection on presented-essential mastery-met** — `9380d8c` (feat)
4. **Task 3: live-path regression (real 14-node baa graph → star → taa)** — `f7b8315` (test)

## Files Created/Modified

- `assets/curriculum/graphs/baa.json` + `assets/curriculum/curriculum_graph.json` — 14-node baa graph (byte-parity), enrichment competencies retained, `owner_dormant_2026_07_20` provenance note added to both `_meta` blocks
- `lib/features/letter_unit/letter_unit_controller.dart` — `_selectNext` mastery-met early exit; shared `_isMasteryMetNow`; `start()` gains `presentedEssentials`; presented set resolved via a screen-supplied list (sync) with a getUnit fallback only in `recordMasteryIfMet`
- `lib/features/letter_unit/letter_unit_screen.dart` — passes `unit.presentedEssentials` into `controller.start()`
- `lib/tutor/exercise_selector_provider.dart` — `kApprovedReachAheadExceptions` shrunk to the 18 taa/thaa ids
- `tools/content/validate.py` — `_BAA_D09_EXCEPTIONS` emptied (union → 18); `tools/content/validation_report.md` regenerated
- `test/curriculum/learned_letters_lint_test.dart` — `baaOwnerApprovedExceptions` emptied
- `test/tutor/l3_learned_letters_parity_test.dart` — pinned set 22→18; obsolete D-09 baa-exception test removed
- `tools/firebase/test_seed_curriculum_v2.py` — `_BAA_D09_IDS` emptied
- `server/app/curriculum_data/{curriculum_graph,baa_authored_ids}.json` — regenerated (14 nodes / 14 ids)
- `test/curriculum/curriculum_graph_test.dart` + `test/curriculum/mastery_condition_test.dart` — updated for the 14-node all-essential graph
- `test/features/letter_unit/l3_illegal_card_guard_test.dart` — reseeded so mastery is unmet at the pass (guard skip observable), then complete the skip target
- `test/features/letter_unit/baa_live_path_mastery_test.dart` — NEW live-path regression

## PROVENANCE (record, do not relitigate)

Making the 4 baa cards dormant is the **owner's decision of 2026-07-20**. It **REVERSES the mother's F1 verdict** (she had confirmed those baa cards live) and is **PENDING her re-confirmation packet**. The exercise configs remain intact in `exercises.json`, so restoring them is a data-only change (re-add the 4 graph nodes + the 4 ids to L0/L1/L3 + the two pinned-set fixtures, then regenerate the server data). Both graph `_meta` blocks now carry an `owner_dormant_2026_07_20` note recording this reversal.

## Server redeploy — OPEN (owner-gated)

The server data (`server/app/curriculum_data/curriculum_graph.json` + `baa_authored_ids.json`) was **regenerated locally** from the canonical asset (`cd server && uv run python -m app.curriculum_data.generate`) and committed. The **Cloud Run `qalam-tutor` redeploy that would push the 14-node graph + shrunk membership rail live remains OWNER-GATED and was NOT done here.** Until redeploy, the deployed server still rails the old 18-node baa set (the G4 membership check would accept the 4 now-dormant ids the client no longer offers — harmless: the client is the source of what renders, and it never presents them).

## KNOWN LIMITATION — taa/thaa remain unfinishable (do NOT fix here)

This task fixed **baa + the D-06 routing invariant only**. The taa (unit 3) and thaa (unit 4) units remain **unfinishable**: their 18 reach-ahead word cards (the D-16 owner-approved exceptions, still live) include **ESSENTIAL** competency nodes that demand letters far beyond their unit, so a child cannot clean-rep them to the star. Their fix is the **mother's F2 letter-form rework** — turning those reach-ahead word cards into letter-FORM practice — which is her Phase-27 authoring (see MEMORY: taa/thaa letterform rework supersedes D-16). The taa/thaa allowlist entries were deliberately left untouched.

## Task 2 timing note (production behavior)

`_isMasteryMetNow` reads the freshest Drift clean-reps. The live-path test (Task 3) seeds reps at threshold before the final scored moment so termination is deterministic. In production, on the exact final rep a fire-and-forget increment race could at worst re-present the terminal essential once more before terminating — still advancing, self-healing on re-entry, and strictly better than today's never-terminating walk.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Controller getUnit on the scored hot path stalled multi-case widget tests**
- **Found during:** Task 2 verification (`flutter test test/features/letter_unit/`)
- **Issue:** The plan's `_isMasteryMetNow` resolved the presented set via `_presentedExerciseIds` → `getUnit` (a rootBundle read) on the `_selectNext` hot path. That rootBundle load stalls in the 2nd+ `testWidgets` of a process (the documented flutter/assets-channel deadlock), leaving the selection future unresolved — regressing `agent_pick_live_path`, `live_selection_shell`, `same_id_represent`, and `thaa_walker_progression` (7 test cases). Confirmed by reverting the controller (base had only the pre-existing `meet_section` failure) and by running the Mastery case in isolation (it passes as the first testWidgets).
- **Fix:** The controller no longer runs `getUnit` on the hot path. `start()` gains a `presentedEssentials` parameter; `LetterUnitScreen` passes the unit's already-loaded `presentedEssentials`; `_isMasteryMetNow` resolves the presented set synchronously from that list (memoized), degrading to the full-graph essential check when nothing was declared. `recordMasteryIfMet` keeps a `getUnit` fallback (off the hot path) and memoizes into the same cache so the two predicates never disagree.
- **Files modified:** `lib/features/letter_unit/letter_unit_controller.dart`, `lib/features/letter_unit/letter_unit_screen.dart`
- **Verification:** All 7 regressed cases green; full `letter_unit` suite green except the pre-existing `meet_section` render test.
- **Committed in:** `9380d8c` (Task 2 commit)

**2. [Rule 1 - Bug] baa-graph-structure tests coupled to the old 18-node graph**
- **Found during:** Task 2 verification (`test/curriculum/`)
- **Issue:** `curriculum_graph_test` asserted 18 nodes + a strict essential/enrichment split, and `mastery_condition_test`'s "enrichment never gates" test asserted the baa graph carries enrichment nodes — both false once the 4 enrichment cards were removed (Task 1).
- **Fix:** Updated `curriculum_graph_test` to 14 all-essential nodes (asserting no enrichment nodes remain + the retained node-less enrichment competency declarations). Rewrote the `mastery_condition_test` D-06 invariant onto a SYNTHETIC graph carrying an enrichment node, so the invariant stays meaningfully tested independent of baa's live inventory.
- **Files modified:** `test/curriculum/curriculum_graph_test.dart`, `test/curriculum/mastery_condition_test.dart`
- **Verification:** Both green.
- **Committed in:** `b4d53b0` (Task 1 follow-on)

**3. [Rule 1 - Bug] l3_illegal_card_guard pre-seeded mastery, hiding the SKIP under Task 2**
- **Found during:** Task 2 verification
- **Issue:** The guard test seeded ALL essential nodes at threshold before the pass. Under Task 2 that means mastery is met, so `_selectNext` correctly terminates to Mastery BEFORE the L3 candidate-narrowing runs — so the guard's skip + loud log never fired and the cursor did not advance to the skip target.
- **Fix:** Seed every essential EXCEPT the skip target (mastery unmet → selection runs → guard skips the illegal card + advances), then complete the skip target and assert the star. Preserves all three of the test's proofs (D-01 skip, D-02 star, D-03 log) while respecting the new terminate-on-mastery-met invariant.
- **Files modified:** `test/features/letter_unit/l3_illegal_card_guard_test.dart`
- **Verification:** Green.
- **Committed in:** `9380d8c` (Task 2 commit)

**4. [Plan-literal adjustment] Removed obsolete D-09 tests rather than emptying their id lists**
- **Found during:** Task 1
- **Issue:** The plan directed emptying the 4-baa-id lists in `l3_learned_letters_parity_test.dart` and `test_seed_curriculum_v2.py`. In `l3_learned_letters_parity_test.dart`, keeping the ids would FAIL (they no longer resolve as exceptions) and emptying leaves a vacuous test.
- **Fix:** Removed the now-obsolete "4 D-09 baa exceptions is KEPT" test entirely (kept the parity pin at 18). In `test_seed_curriculum_v2.py`, followed the plan literally (emptied `_BAA_D09_IDS`) with a provenance comment noting the two D-09 seed tests now iterate nothing (pass vacuously).
- **Files modified:** `test/tutor/l3_learned_letters_parity_test.dart`, `tools/firebase/test_seed_curriculum_v2.py`
- **Verification:** L3 parity + seed test green.
- **Committed in:** `85e14ae` (Task 1 commit)

---

**Total deviations:** 4 (3 Rule-1 test-coupling/hot-path fixes directly caused by this task's changes; 1 plan-literal cleanliness adjustment). No scope creep — every change is required for correctness of the current task.

## Issues Encountered

- The presented-set-on-hot-path stall (Deviation 1) took the most iteration: getUnit is fragile in the widget-test environment, and routing MUST use the presented subset (full-graph would leave baa's 6 unpresented essentials blocking the star forever). Resolved by injecting `presentedEssentials` from the screen, which also removes a redundant repo read on-device.

## Honest gate results (actual commands + outcomes)

- `python3 -m tools.content.validate --gate` → **PASS** (exit 0). Live nodes 53; owner-approved exceptions exempt = **18** = 0 baa (D-09) + 18 taa/thaa (D-16).
- `pytest tools/firebase/test_seed_curriculum_v2.py -q` → **8 passed**.
- `flutter test test/curriculum/learned_letters_lint_test.dart test/curriculum/graph_asset_parity_test.dart test/tutor/l3_learned_letters_parity_test.dart` → **all passed** (L1 lint, byte-parity D-14, L3 pinned set = 18).
- `cd server && uv run python -m app.curriculum_data.generate` → wrote 14 sections-derived exercise ids + 14 baa.* graph nodes.
- `flutter test test/features/letter_unit/baa_live_path_mastery_test.dart` → **PASS** (Task 3).
- `flutter test test/features/letter_unit/ test/curriculum/ test/tutor/` → **423 passed / 5 failed**. All 5 failures are PRE-EXISTING and unrelated (none touch this task's files):
  - `test/curriculum/alif_reference_test.dart` ×2 (alif centerline top / normalized length)
  - `test/curriculum/reference_overlay_golden_test.dart` (alif golden pixel drift)
  - `test/curriculum/all_letters_validation_test.dart` (expects alif signedOff:true; alif is unsigned)
  - `test/features/letter_unit/meet_section_test.dart` Test 1 (door-image render)

  Verified pre-existing: reverting ONLY the controller left the letter_unit base with exactly the `meet_section` failure; the alif-reference + golden set is documented in project memory as the known "4 pre-existing failures (alif-reference + mastery golden)".

## Self-Check: PASSED

- FOUND: `test/features/letter_unit/baa_live_path_mastery_test.dart`
- FOUND commits: `85e14ae`, `b4d53b0`, `9380d8c`, `f7b8315`
- Server data: 14 graph nodes / 14 authored ids; no `fillBlank`/`transformWord` ids present.

## Known Stubs

None — no stub patterns introduced. The 4 dormant exercise configs remain fully authored in `exercises.json` (intentional, reversible parking, mirroring `buildSentence`); the empty `wordBuilding`/`grammarTransform` competency declarations are intentional (parser-tolerated placeholders for restore).

## Next steps (owner-gated / future)

- Owner: redeploy Cloud Run `qalam-tutor` from the regenerated server data (out of scope here).
- Mother: F1 re-confirmation of the baa dormancy (packet); F2 letter-form rework for taa/thaa (Phase 27) to make those units finishable.

---
*Quick task: 260720-up4*
*Completed: 2026-07-20*
