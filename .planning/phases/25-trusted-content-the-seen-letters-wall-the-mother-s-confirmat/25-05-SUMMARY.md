---
phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
plan: 05
subsystem: tutor
tags: [tutor, curriculum, selection, seen-letters-wall, runtime-guard, L3, riverpod, learned-letters, D-01, D-02, D-03]

# Dependency graph
requires:
  - phase: 25-02-triage-to-zero
    provides: "the OWNER_APPROVED_EXCEPTIONS union (22 ids = 4 baa D-09 + 18 taa/thaa D-16) L3 mirrors as kApprovedReachAheadExceptions"
  - phase: 19-question-presentation-overhaul
    provides: "the learned-letters lint (unlearnedFor + baaOwnerApprovedExceptions) whose predicate L3's SeenLettersFilter mirrors at runtime"
  - phase: 15-build-dynamic-grounded-exercise-selection-on-baa
    provides: "the RouterExerciseSelector / CurriculumGraphWalker forward-scan the SKIP reuses (no new rail)"
provides:
  - "L3 runtime guard: RouterExerciseSelector SKIPs any reach-ahead candidate (except the 22 owner-approved ids) on the LIVE selection path and advances to the next legal node (D-01), logging loudly (D-03)"
  - "SeenLettersFilter + kApprovedReachAheadExceptions (the 22-id Dart mirror of L1/L2) + seenLettersFilterProvider — the runtime learned-set read, kept in lib/tutor/ (lib/curriculum/ stays pure)"
  - "criterion 3 met: a live-path test seeds an illegal card via the real data path and proves it is never presented, the star stays reachable, and the guard logs loudly"
  - "owner verdict: accept-skip — D-01 SKIP is LOCKED as built (the roadmap's reserved L3 decision, resolved 2026-07-19)"
affects: [25-06-mothers-packet, 25-07-verdict-ingestion, 26-scorer-retighten, 27-server-unfencing]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "The seen-letters legality rule now has FOUR call sites refusing/exempting identically: L0 audit + L2 seeder (validate.py, python), L1 lint (dart), L3 runtime filter (dart, lib/tutor/). L3's kApprovedReachAheadExceptions is the 22-id mirror of validate.py's OWNER_APPROVED_EXCEPTIONS."
    - "New runtime I/O (reading letters.json introOrder + exercises.json letters[]) lives in lib/tutor/ (seenLettersFilterProvider), NEVER in the pure lib/curriculum/ spine — the durable_layers_no_agent_imports_test guard stays green."
    - "The L3 guard is wired onto the CONTROLLER's live _selectNext (what actually renders), not only the dead-code exerciseSelectorProvider — the Phase-15 dead-wire lesson applied. Read non-blocking (.asData?.value), warmed fire-and-forget in start()."
    - "Loud-degrade, never silent (D-03) is now file-wide in letter_unit_controller.dart: every catch names what failed + why + the consequence."

key-files:
  created:
    - "test/tutor/l3_learned_letters_parity_test.dart - pins the Dart predicate + 22-id exception set to L1/L2 (advisory-4 drift guard)"
    - "test/features/letter_unit/l3_illegal_card_guard_test.dart - the ONE-case live-path proof (criterion 3): inject illegal card → never presented, star reachable, loud log"
  modified:
    - "lib/tutor/exercise_selector_provider.dart - SeenLettersFilter + kApprovedReachAheadExceptions (22 ids) + seenLettersFilterProvider; RouterExerciseSelector.selectNext SKIPs reach-ahead candidates + logs loudly"
    - "lib/features/letter_unit/letter_unit_controller.dart - wire the filter into the live _selectNext + warm it in start(); de-silence every catch (loud-degrade, D-03)"

key-decisions:
  - "OWNER VERDICT (Task 4, 2026-07-19): accept-skip — lock SKIP (D-01) exactly as implemented. Owner selected the recommended option when asked: 'When the runtime meets a card that demands letters the child hasn't learned (and it's not one of the 22 approved exceptions), the built behavior is: SKIP it, advance to the next legal card, log loudly, star still reachable. Lock this in?'"
  - "L3 exception set = ALL 22 owner-approved ids (4 baa D-09 + 18 taa/thaa D-16), not the 4 the plan text named — the wave's L3 exception-parity revision. Dropping the taa/thaa D-16 ids at runtime would gut the units the owner deliberately kept live (D-16)."
  - "The guard MUST be wired into the controller's live _selectNext, not the dead-code exerciseSelectorProvider — the provider renders nothing (the Phase-15 dead-wire trap). The live-path test would go red without the controller wiring (verified)."
  - "D-02 (star-reachability) is preserved WITHOUT changing the mastery gate: the filter only narrows selection candidates; the mastery gate (recordMasteryIfMet / essentialNodes) is untouched. The common case (illegal card is enrichment, or the essential node has a legal sibling) leaves the star reachable — proven by the live-path test."

patterns-established:
  - "L3 mirrors L0/L1/L2 EXACTLY: same predicate (introOrder > unit), same 22-id exemption, same unknown-id-reads-legal rule. Parity pinned by test/tutor/l3_learned_letters_parity_test.dart so drift goes red."
  - "A runtime guard on the Firestore-first bypass reuses the existing forward scan (never invents a rail): a dropped candidate simply falls out of the SAME candidate set the walker already walks."

requirements-completed: []  # QP-07 / D-12 are ADVANCED by the L3 leg (the runtime guard now holds at read time), NOT fully satisfied — the wall's four-layer thesis is complete on the enforcement side, but every reach-ahead card stays PROVISIONAL until the mother's verdict (Plans 25-06 packet / 25-07 ingestion).

# Metrics
duration: ~60min active (across the owner-decision checkpoint + a transient-error resume)
completed: 2026-07-19
---

# Phase 25 Plan 05: L3 — the runtime seen-letters guard + the owner's SKIP verdict Summary

**The runtime selector now SKIPs any card demanding an unseen letter (except the 22 owner-approved ids) on the LIVE selection path, advances to the next legal node, keeps the mastery star reachable, and logs every firing loudly — proven by a live-path test that injects an illegal card through the real data path; the owner reviewed the demonstrated behavior and LOCKED it (accept-skip / D-01).**

## Performance

- **Duration:** ~60 min active (spanned the Task-4 owner-decision checkpoint + a transient-error resume)
- **Started:** 2026-07-19
- **Completed:** 2026-07-19
- **Tasks:** 4 (3 auto + 1 checkpoint:decision, all resolved)
- **Files modified:** 4 (2 lib, 2 test) + this SUMMARY

## Accomplishments
- Built the **L3 runtime guard** — the LAST line of the seen-letters wall: `RouterExerciseSelector.selectNext` drops any candidate whose `letters[]` reaches ahead of the child's learned set and advances to the next legal node (D-01 SKIP), reusing the SAME candidate set + walker forward scan (no new rail).
- Mirrored the wall's exemption **exactly**: `kApprovedReachAheadExceptions` = the 22 owner-approved ids (4 baa D-09 + 18 taa/thaa D-16) — the same set L0/L1/L2 exempt — so a mother-approved / owner-decision reach-ahead card stays presentable at runtime.
- Kept the new I/O (`seenLettersFilterProvider` reading letters.json/exercises.json) in **lib/tutor/**, leaving the pure `lib/curriculum/` spine untouched (`durable_layers_no_agent_imports_test` stays green).
- Wired the guard onto the **controller's live `_selectNext`** (what actually renders), not the dead-code `exerciseSelectorProvider` — the Phase-15 dead-wire lesson.
- De-silenced **every** `catch (_)` in `letter_unit_controller.dart` (D-03 loud-degrade thesis, file-wide) — behavior preserved, only logging added; the mastery/star seam untouched.
- Delivered **criterion 3**: a one-case live-path test injects an illegal card via the real data path (a `curriculumGraphProvider` graph whose enrichment node resolves to the real `taa.traceLetter.isolated` reach-ahead card), drives a scored pass through the live `WriteSurface.onResult` seam, and asserts the illegal card is never the cursor and never renders, `recordMasteryIfMet()` still returns true (D-02), and the loud `L3 guard` line fired with no child data (T-25-05-I). Verified genuinely RED when the guard is neutered.
- Captured the **owner's L3 verdict** — `accept-skip` — locking D-01 as built.

## Task Commits

Each task was committed atomically:

1. **Task 1: L3 seen-letters filter on the live selection path (D-01 SKIP + D-03 log)** - `a697911` (feat)
2. **Task 2: De-silence the selection/clear catches (D-03)** - `acfbb3e` (feat)
3. **Task 3: Live-path guard proof (criterion 3)** - `82980b1` (test)
4. **Task 4: Owner confirms the L3 degradation** - decision-only (verdict recorded here; no code commit)

## Files Created/Modified
- `lib/tutor/exercise_selector_provider.dart` — Added `SeenLettersFilter` (the pure `unlearnedFor`/`isSeenLegal` predicate + `fromAssets`/`disabled` factories), `kApprovedReachAheadExceptions` (the 22-id L1/L2 mirror, provenance-grouped), and `seenLettersFilterProvider` (never-throw loader). `RouterExerciseSelector` gained a `seenFilter` param; `selectNext` narrows candidates through it BEFORE the agent-accept / walker pick, logging each drop `L3 guard: <id> illegal (demands <letter>), skipped`.
- `lib/features/letter_unit/letter_unit_controller.dart` — `_selectNext` reads the filter non-blocking (`.asData?.value`) and threads it into `RouterExerciseSelector`; `start()` warms it fire-and-forget. Every silent `catch (_)` (the three named sites + the profile/position/cursor/arc/context/persist catches) became a loud `catch (e)` degrade (behavior identical, logging added); two doc comments reworded.
- `test/tutor/l3_learned_letters_parity_test.dart` — pure unit test pinning the predicate + the 22-id exemption to L1/L2.
- `test/features/letter_unit/l3_illegal_card_guard_test.dart` — the single-case live-path proof (criterion 3).

## Decisions Made
- **OWNER VERDICT — accept-skip (Task 4, 2026-07-19, via the orchestrator checkpoint).** Verbatim context on record: *"When the runtime meets a card that demands letters the child hasn't learned (and it's not one of the 22 approved exceptions), the built behavior is: SKIP it, advance to the next legal card, log loudly, star still reachable. Lock this in?"* — the owner selected **accept-skip**. D-01 SKIP is now LOCKED as implemented; no further L3 change. This finalizes the roadmap's reserved discuss-phase L3 decision (D-01/D-02/D-03). The D-02 star-reachability backstop is proven (the live-path test asserts `recordMasteryIfMet()` still fires after the skip) and the D-03 loud log is in place (`L3 guard: … skipped`, carrying only the exercise id + demanded letter — no strokes, no child id).
- **22-id exception parity, not the 4 the plan text named** (see Deviation 1).
- **Live-path wiring into the controller, not the dead-code provider** (see Deviation 2).
- **File-wide catch de-silencing** (see Deviation 3).

## Deviations from Plan

### 1. [Rule 2 - Missing Critical / parity correctness] L3 exception set mirrors ALL 22 owner-approved ids, not the 4 the plan text named
- **Found during:** Task 1 (the filter + exception const)
- **Issue:** The plan's Task-1 action text names `kApprovedReachAheadExceptions` as "the 4 D-09 ids". But the wave carried an L3 exception-parity revision: L3 must exempt the SAME set L0/L1/L2 do — the 22-id union (`_BAA_D09_EXCEPTIONS | _TAA_THAA_D16_EXCEPTIONS`) in `validate.py`. If L3 exempted only baa's 4, the runtime guard would DROP the 18 taa/thaa D-16 cards the owner deliberately kept live (D-16), gutting those units at read time — a regression.
- **Fix:** Defined `kApprovedReachAheadExceptions` as the full 22-id set (4 baa D-09 + 18 taa/thaa D-16), provenance-grouped and commented to name `validate.py::OWNER_APPROVED_EXCEPTIONS` + the lint's `baaOwnerApprovedExceptions` as the mirrored sources. The parity test asserts the literal 22-id set.
- **Files modified:** `lib/tutor/exercise_selector_provider.dart`, `test/tutor/l3_learned_letters_parity_test.dart`
- **Verification:** `l3_learned_letters_parity_test.dart` passes (predicate parity + 22-id equality); each of the 4 D-09 ids is kept despite reaching ahead.
- **Committed in:** `a697911`

### 2. [Rule 3 - Blocking] The guard is wired into the controller's live `_selectNext`, not only the dead-code `exerciseSelectorProvider`
- **Found during:** Task 1 (deciding the L3 seam)
- **Issue:** The plan says the filter is "supplied by the provider". But `exerciseSelectorProvider` is DEAD CODE — its only reference is a test `isNotNull` check; nothing renders from it. The LIVE selection path is `letter_unit_controller._selectNext`, which constructs `RouterExerciseSelector` directly. Wiring only the provider would make the guard a dead wire — the exact Phase-15 failure (dynamic selection shipped as dead code because the live path carried no decision). A selector-only unit test cannot catch this; the live-path test (Task 3) would fail.
- **Fix:** Threaded the `seenFilter` into the controller's `_selectNext` (read non-blocking via `.asData?.value`) and warmed `seenLettersFilterProvider` fire-and-forget in `start()`. Also wired the provider for parity, but the controller is the load-bearing path.
- **Files modified:** `lib/tutor/exercise_selector_provider.dart`, `lib/features/letter_unit/letter_unit_controller.dart`
- **Verification:** The live-path test drives the real `WriteSurface.onResult` seam and passes; it goes RED when the guard condition is neutered (proving the wire is live, not decorative).
- **Committed in:** `a697911`

### 3. [Rule 2 - Missing Critical / D-03 thesis] De-silenced EVERY catch in the controller, not only the three named sites
- **Found during:** Task 2 (de-silencing)
- **Issue:** Task 2's action names three catches, but its automated gate is `grep -c 'catch (_)' == 0` for the WHOLE file, and the phase thesis is "loud-degrade, never silent" (D-03). The file still had silent `catch (_)` at the `start()` profile/position/cursor reads, the `_loadSelectionContext` arc/profile reads, and both fire-and-forget persists — plus two doc comments that literally named `catch (_)`.
- **Fix:** Converted every silent `catch (_)` to a loud `catch (e)` degrade (each names what failed + why + the consequence, mirroring the `recordMasteryIfMet` template) and reworded the two doc comments. Control flow and fallback values are unchanged — only logging was added. The mastery/star seam (`recordMasteryIfMet`, `_presentedExerciseIds`) was NOT touched (it was already loud).
- **Files modified:** `lib/features/letter_unit/letter_unit_controller.dart`
- **Verification:** `grep -c 'catch (_)'` == 0; `flutter analyze` clean; `agent_pick_live_path_test`, `letter_generic_mastery_progression_test` (+ taa), `thaa_walker_progression_test`, `selection_rails_property_test`, `dynamic_selection_test` all still pass (behavior preserved).
- **Committed in:** `acfbb3e`

---

**Total deviations:** 3 (1 parity-correctness Rule 2, 1 blocking Rule 3, 1 D-03-thesis Rule 2).
**Impact on plan:** No scope creep beyond the plan's intent — each deviation makes a plan-named goal actually hold (parity across all four wall layers, a LIVE guard not a dead wire, D-03 no-silent-swallow). The L3 leg is complete and the owner locked the SKIP behavior.

## Issues Encountered
- **The Flutter test framework rejects a leaked `debugPrint` override** (`debugAssertAllFoundationVarsUnset`) — restoring it in `addTearDown` runs too late (after the binding verifies invariants). Fixed by snapshotting the captured guard logs and restoring `debugPrint` inside the test body, before the assertions.
- **l10n generated files were missing in the fresh worktree** (known: `lib/l10n/app_localizations*.dart` is gitignored). Ran `flutter gen-l10n`; all tests then compile. Not caused by this plan.
- **A transient API termination** interrupted the run twice; the worktree survived intact (all three task commits present, tree clean) and work resumed from there per the coordinator's verified state.

## Known Stubs
- None introduced. The `seenLettersFilterProvider` degrades to a **no-op filter** (`SeenLettersFilter.disabled()`) on any load failure — this is a deliberate never-throw fallback (L3 filtering off for the session; the graph legality rail + L0/L1/L2 build/seed gates still hold), not a stub. The 22 owner-approved exceptions remain PROVISIONAL pending the mother's verdict (Plans 25-06/25-07) — tracked, not silent.

## Threat Flags
None new. The threat register's `mitigate` dispositions are all satisfied: T-25-05-T (bad data reaching a child at runtime — the L3 filter SKIPs it, proven on the live path), T-25-05-D (a skip stranding the star — D-02 backstop, `recordMasteryIfMet()` still fires), T-25-05-R (a silent guard firing — D-03 loud log, all catches de-silenced), T-25-05-I (the log leaking child data — the `L3 guard` line names only the exercise id + demanded letter; asserted by the live-path test).

## Next Phase Readiness
- **The wall's enforcement side is complete** (L0 audit + L1 lint + L2 seeder + L3 runtime guard) — all four layers refuse/exempt the SAME 22-card set. The owner locked the L3 SKIP behavior (accept-skip / D-01).
- **Plan 25-06 (mother's packet):** every one of the 22 exceptions is still PROVISIONAL — the packet must present each (4 baa D-09 + 18 taa/thaa D-16) for the mother's confirm / reject / re-point. The L3 guard already honors whatever set survives her verdict (the exception const is the single runtime source to update if any id is removed).
- **Plan 25-07 (verdict ingestion):** if the mother removes an exception, delete its id from `kApprovedReachAheadExceptions` (and the L0/L1/L2 sources) — L3 will then SKIP it at runtime automatically; the parity test enforces the four sets stay in lock-step.

## Self-Check: PASSED
- `lib/tutor/exercise_selector_provider.dart` — FOUND (L3 guard + kApprovedReachAheadExceptions present)
- `lib/features/letter_unit/letter_unit_controller.dart` — FOUND (0 bare `catch (_)`, filter wired)
- `test/tutor/l3_learned_letters_parity_test.dart` — FOUND (passes)
- `test/features/letter_unit/l3_illegal_card_guard_test.dart` — FOUND (passes; RED when guard neutered)
- Commit `a697911` — FOUND
- Commit `acfbb3e` — FOUND
- Commit `82980b1` — FOUND

---
*Phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat*
*Completed: 2026-07-19*
