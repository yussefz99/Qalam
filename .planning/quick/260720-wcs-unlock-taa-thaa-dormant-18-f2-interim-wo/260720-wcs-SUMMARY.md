---
phase: quick-260720-wcs
plan: 01
subsystem: curriculum
tags: [curriculum-graph, mastery, selection, letter-unit, dormancy, starter-unit, f2-interim]

# Dependency graph
requires:
  - phase: "260720-up4 (baa dormancy + terminate-on-mastery-met)"
    provides: "the graph-node-removal dormancy mechanism + the _selectNext mastery-met termination this plan depends on (no source-logic changes here)"
  - phase: "25-03/25-05 (seen-letters wall)"
    provides: "the four-layer allowlist (L0 validate.py / L1 lint / L3 selector / L2 seeder) this plan collapses to ZERO"
  - phase: "260718-il4/nft (Stage-1 all-letters-live)"
    provides: "the per-letter graph asset load + the walker-for-all-letters live apply path taa/thaa/jeem rail on"
provides:
  - "7-node taa/thaa graphs (10 reach-ahead word/grammar nodes each made dormant; competencies retained)"
  - "3-node jeem + haa_c isolated-form-only STARTER units (graphs + cards + units)"
  - "the owner-approved reach-ahead allowlist collapsed to EMPTY across all four wall layers"
  - "6 finishable letters (alif, baa, taa, thaa, jeem, haa_c) for the Technion demo"
  - "3 new live-path/smoke tests proving each of taa/thaa/jeem reaches the star + advances"
affects: [phase-27 (mother F2 taa/thaa letter-form authoring), mother re-confirmation packet, server redeploy (NOT done)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dormant-by-node-removal extended to taa/thaa (remove graph nodes to park a card while keeping its exercise config reversible in exercises.json) — mirrors 260720-up4 baa"
    - "Isolated-form-only STARTER unit: a letter with ZERO contextualForms ships a 3-node all-essential graph (meet -> trace isolated -> write isolated) so the star is reachable at reps=1"

key-files:
  created:
    - assets/curriculum/graphs/jeem.json
    - assets/curriculum/graphs/haa_c.json
    - test/features/letter_unit/taa_live_path_mastery_test.dart
    - test/features/letter_unit/thaa_live_path_mastery_test.dart
    - test/features/letter_unit/jeem_starter_unit_test.dart
  modified:
    - assets/curriculum/graphs/taa.json
    - assets/curriculum/graphs/thaa.json
    - assets/curriculum/exercises.json
    - assets/curriculum/units.json
    - tools/content/validate.py
    - tools/content/validation_report.md
    - test/curriculum/learned_letters_lint_test.dart
    - lib/tutor/exercise_selector_provider.dart
    - test/tutor/l3_learned_letters_parity_test.dart
    - tools/firebase/test_seed_curriculum_v2.py
    - test/features/letter_unit/thaa_unit_live_path_test.dart
    - test/features/letter_unit/thaa_walker_progression_test.dart

key-decisions:
  - "F2-INTERIM (owner 2026-07-20, supersedes D-16): taa/thaa's 18 reach-ahead word cards are made DORMANT (nodes removed; 17->7 all-essential form nodes each) because the mother ruled they must become letter-FORM practice she has not yet authored — PENDING her re-confirmation packet"
  - "jeem + haa_c promoted as isolated-form-only STARTER units (both have ZERO contextualForms → isolated is the only honest scope); fromSound/fromPicture OMITTED (absent word audio/images; inventing vocab is banned)"
  - "the owner-approved reach-ahead allowlist is collapsed to EMPTY across all four wall layers → ANY reach-ahead card now fails the gate by design"
  - "curriculum_graph.json UNTOUCHED, NO server regen, NO Firestore seed, NO Play/webcourse rebuild (v2.0.0+3 freeze intact)"

requirements-completed: []

# Metrics
duration: ~55min
completed: 2026-07-20
---

# Quick 260720-wcs: Unlock taa/thaa (dormant 18 F2-interim word cards) + jeem/haa_c isolated-form starter units Summary

**Six letters are now finishable for the Technion demo: taa + thaa were unlocked by making their 18 reach-ahead word/grammar cards dormant (17->7 all-essential letter-FORM nodes each), jeem + haa_c ship as new isolated-form-only starter units (3 all-essential nodes each), and the owner-approved reach-ahead allowlist is collapsed to ZERO across all four wall layers so any reach-ahead now fails the gate by design — no source-logic changes, no server regen, no Play rebuild.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 3
- **Files:** 5 created / 12 modified
- **New tests:** 3 (2 live-path, 1 starter smoke)

## Accomplishments

- **Task 1 — unlock taa + thaa (dormancy + allowlist 18->0).** Removed the 10 reach-ahead word/grammar nodes from each of `taa.json`/`thaa.json` (17->7 nodes), leaving the 7 all-essential letter-FORM nodes (teachCard.meet + traceLetter.isolated/initial/medial + writeLetter.fromSound/fromPicture/writeForm). Retained the 5 competency declarations in both graphs (copyWrite/wordBuilding/grammarTransform become node-less, parser-tolerated). Emptied `_TAA_THAA_D16_EXCEPTIONS` in `validate.py` (the public `OWNER_APPROVED_EXCEPTIONS` union is now EMPTY = 0 baa + 0 taa/thaa), the `taaOwnerApprovedExceptions`/`thaaOwnerApprovedExceptions` sets in the L1 lint, `kApprovedReachAheadExceptions` in the L3 selector, and pinned the L3 parity test 18->0. Added an `owner_dormant_2026_07_20` / F2-interim provenance note to each graph's `_meta`. Refreshed the stale seed-test comment. minCleanReps stays 1 on all 7 nodes.
- **Task 2 — jeem + haa_c isolated-form-only STARTER units.** New `graphs/jeem.json` + `graphs/haa_c.json`: 3-node all-essential graphs (competencies = recognize + positionalForms only), minCleanReps 1, F2-interim/starter `_meta` provenance. Appended 3 cards each to `exercises.json` (teachCard.meet / traceLetter.isolated / writeLetter.writeForm) modeled byte-for-byte on the taa live equivalents, `letters:[<id>]` only, `signedOff:false`, NO word-image kind (word art absent), `fromSound`/`fromPicture` omitted (need absent word assets). Appended jeem + haa_c entries to `units.json` shaped like alif (meet/watchTrace/forms/mastery, no words/listenWrite, no presentedEssentials).
- **Task 3 — live-path + smoke tests + the full gate sweep.** 3 new one-testWidgets-per-file tests (dual-drain `_awaitPumping`) proving the real bundled 7-node taa graph reaches the star + advances to thaa, the 7-node thaa graph reaches the star + advances to jeem, and the 3-node jeem starter reaches the star + advances to haa_c — all through the REAL selection path (`WriteSurface.onResult`), never a direct `recordMasteryIfMet`. Full 4-command gate sweep run and recorded honest.

## Task Commits

1. **Task 1: unlock taa+thaa — dormant 18 reach-ahead nodes, empty allowlist 18->0** — `eecfc50` (feat)
2. **Task 2: promote jeem + haa_c as isolated-form-only starter units** — `fe56405` (feat)
3. **Task 3: live-path proofs + fix 2 thaa tests coupled to removed nodes** — `c7dd036` (test)

## (a) F2-INTERIM PROVENANCE (record, do not relitigate)

Making taa/thaa's 18 reach-ahead word cards dormant, and promoting jeem/haa_c as isolated-form starters at **minCleanReps 1**, is the **owner's decision of 2026-07-20** (F2-INTERIM, superseding D-16). The mother ruled 2026-07-20 that taa/thaa's reach-ahead questions must become **letter-FORM practice she has not yet authored**; until she authors it they must NOT run as word cards. **The mother's re-confirmation packet is OWED** and must cover, per id / per unit:
- taa/thaa **dormancy** (the 18 parked word/grammar cards — confirm the letter-form rework, or restore),
- jeem/haa_c **starter content** (the 6 new isolated-form cards, `signedOff:false`),
- the **reps=1** demo-era precedent (A2) on all taa/thaa/jeem/haa_c form nodes,
- the **haa_c "dot" criterion** — haa_c (ح) has NO dot; the `dot` criterion on its trace/write cards is a DRAFT template artifact flagged in-card (`_review`) for her to confirm/strip.

All dormancy is REVERSIBLE: the 18 taa/thaa exercise configs remain intact in `exercises.json`; restore by re-adding the 18 graph nodes + the 18 ids to L0/L1/L3 + the pinned fixtures.

## (b) Coaching for non-baa letters DEGRADES BY DESIGN

The tutor server curriculum_data is **baa-only (D-11)** and was **NOT regenerated** here (curriculum_graph.json is byte-unchanged; no `generate.py` run, no Cloud Run redeploy). So on-device coaching for taa/thaa/jeem/haa_c degrades by design — the deterministic scorer still runs on-device and the **never-silent feedback floor** (260718-l12) holds, so a child always gets a warm authored line even where the server has no letter-specific WHY. This is expected and unchanged by this task.

## (c) jeem/haa_c Firestore-vintage finding (T-wcs-01, VERIFY-ONLY — no Firestore writes)

The device reads `letters` Firestore-first; the jeem/haa_c Firestore docs are June-14 vintage. I diffed the jeem/haa_c ROWS in `assets/curriculum/letters.json` against the June-14-era seed and across every post-June-14 letters.json commit:
- **NO divergence.** The jeem/haa_c rows are **byte-identical** between HEAD and the last pre-260718 letters.json commit (`c1ecd2c`). The post-June-14 surgical merges (`260718-l12` contextualForms merge for alif/baa/taa/thaa; `260718-nft` taa/thaa isolated-body fix) touched ZERO jeem/haa_c content (0 mentions each).
- Consequence: the device's June-14 Firestore jeem/haa_c docs MATCH the current bundle base strokes (jeem 2 strokes, haa_c 1 stroke). The device will render the same isolated forms the bundle ships. **No seed, no letters.json edit was made** (verify-and-report only, per the plan + environment note).

## (d) Honest gate results (actual commands + outcomes)

1. `python3 -m tools.content.validate --gate` -> **GATE PASS (exit 0)**. Live graph nodes **39** (33 after Task 1 + 6 new jeem/haa_c). Owner-approved exceptions (exempt) = **0** = 0 baa (D-09) + 0 taa/thaa (D-16). Any reach-ahead now fails by design.
2. `python3 -m pytest tools/firebase/test_seed_curriculum_v2.py -q` -> **8 passed**.
3. `flutter test test/curriculum/learned_letters_lint_test.dart test/curriculum/graph_asset_parity_test.dart test/tutor/l3_learned_letters_parity_test.dart` -> **all passed** (L1 lint green with taa/thaa 7 nodes + empty exceptions; graphs/baa.json byte-parity D-14 intact; L3 pinned set now 0).
4. `flutter test test/features/letter_unit/ test/curriculum/ test/tutor/` -> **426 passed / 5 failed**. All 5 failures are the DOCUMENTED known-only pre-existing set (verified in 260720-up4, none touch this task's files):
   - `test/curriculum/alif_reference_test.dart` x2 (alif centerline top / normalized length)
   - `test/curriculum/reference_overlay_golden_test.dart` (alif golden pixel drift)
   - `test/curriculum/all_letters_validation_test.dart` (expects alif signedOff:true; alif is unsigned)
   - `test/features/letter_unit/meet_section_test.dart` Test 1 (door-image render)
5. `flutter test <taa/thaa/jeem live-path files>` -> **all 3 passed** (each reaches Mastery + advances to the next letter by introOrder).

`curriculum_graph.json` git diff is **EMPTY** (byte-unchanged) after every task.

## (e) Freeze + owner-gated steps

- **iPad build/install is the OWNER's step.** No build/install was run here; the owner performs it after this lands green.
- **Play + webcourse artifacts were NOT built.** The v2.0.0+3 freeze is intact (no AAB/APK rebuild).
- **No server regen, no Firestore writes of any kind.** curriculum_graph.json byte-unchanged; server curriculum_data stays baa-only (D-11).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `thaa_unit_live_path_test.dart` coupled to a removed thaa node**
- **Found during:** Task 3 full-sweep verification.
- **Issue:** `kThaaGradedNode = 'thaa.completeWord.middle'` — a node the Task-1 dormancy removed from the 7-node thaa graph — so `graph.isAuthored(kThaaGradedNode)` flipped true->false and the "rails on the thaa graph" test failed.
- **Fix:** Retargeted `kThaaGradedNode` to `thaa.writeLetter.writeForm` (a still-live graded write node, one of the 7 kept form nodes; surface.mode == 'write'). Both tests in the file pass; the intent (a promoted graded thaa node presents live) is preserved.
- **Files modified:** `test/features/letter_unit/thaa_unit_live_path_test.dart`
- **Committed in:** `c7dd036`

**2. [Rule 1 - Bug] `thaa_walker_progression_test.dart` FAIL-path coupled to a removed ramp node**
- **Found during:** Task 3 full-sweep verification.
- **Issue:** The FAIL-path test used `kFailCursor = 'thaa.writeWord.dictation'` (copyWrite/ghayrManzur) to assert a one-tier-down remediation. Task-1 dormancy removed that node AND all other ramp nodes, so thaa is now FORM-ONLY (all 7 nodes tier-null) and `graph.remediateOneTier('thaa.writeWord.dictation')` returns null -> the test's `isNotNull` assertion failed.
- **Fix:** Retargeted the FAIL-path to a live tier-null form node (`thaa.traceLetter.medial`) and rewrote the test to prove the NEW correct behavior: a form-node fail DRILLS IN PLACE at the floor (the walker's fail pick when there is no ramp tier), which is STILL distinguishable from the old static-walk bug (a pass from the same node advances; the fail stays put). The test remains fully LIVE (real thaa graph + real scaffold apply path) and asserts `cursor == walkerFailPick` AND `cursor != walkerForward`. The tier-step-down remediation invariant itself stays covered by the walker/`remediation_arc_test` suites on ramp-bearing graphs.
- **Files modified:** `test/features/letter_unit/thaa_walker_progression_test.dart`
- **Committed in:** `c7dd036`

**3. [Plan-literal clarification] taa/thaa live-path prior-mastery seed**
- The plan text "seed alif+baa+taa mastered" for the taa test was read as: seed the PRECEDING letters as prior mastery (alif+baa for taa; alif+baa+taa for thaa) and earn THIS letter's star LIVE via the scored pass — mirroring the 260720-up4 baa template exactly. Seeding the letter-under-test as pre-mastered would make the "advances to next" assertion trivially true. No behavior change; the tests earn the star through the real selection path.

Both Rule-1 fixes are test-coupling breaks DIRECTLY caused by this task's node removal (the up4 precedent for the same kind of fix). No scope creep.

## haa_c "dot" criterion (draft flag for the mother)

haa_c (ح) has NO dot, but its `traceLetter.isolated` / `writeLetter.writeForm` cards carry the 5-criterion set `[strokeCount, strokeOrder, shape, direction, dot]` per the plan's "the taa criteria per type" template. The `dot` entry is a DRAFT template artifact — flagged in each card's `_review` note and in `graphs/haa_c.json` `_meta` for the mother to confirm/strip in her packet. Not silently changed (the criteria are the mother's pedagogical call; surfaced, not decided).

## Known Stubs

None that block the goal. The 18 dormant taa/thaa exercise configs remain fully authored in `exercises.json` (intentional, reversible parking — the same mechanism as baa/buildSentence). The node-less copyWrite/wordBuilding/grammarTransform competency declarations in taa/thaa are intentional parser-tolerated placeholders for restore. jeem/haa_c cards are `signedOff:false` DRAFTS by design (mother's packet is the sign-off gate).

## Self-Check: PASSED

- FOUND: `assets/curriculum/graphs/jeem.json`, `assets/curriculum/graphs/haa_c.json`
- FOUND: `test/features/letter_unit/{taa_live_path_mastery,thaa_live_path_mastery,jeem_starter_unit}_test.dart`
- FOUND commits: `eecfc50`, `fe56405`, `c7dd036`
- `curriculum_graph.json` git diff EMPTY (byte-unchanged); gate exempt count = 0; 39 live nodes.

## Next steps (owner-gated / future)

- **Owner:** build + install on the iPad and device-check the 6 finishable letters; source the Android device for the recorded demo.
- **Mother:** the re-confirmation packet — taa/thaa dormancy (letter-form rework, Phase 27), jeem/haa_c starter content + reps=1, and the haa_c no-dot criterion.
- **Server (owner-gated, NOT this task):** any future taa/thaa/jeem/haa_c coaching needs a `generate.py` regen + Cloud Run redeploy (curriculum_data is baa-only today).

---
*Quick task: 260720-wcs*
*Completed: 2026-07-20*
