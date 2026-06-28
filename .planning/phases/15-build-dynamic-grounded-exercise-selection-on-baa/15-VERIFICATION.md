---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
verified: 2026-06-28T15:40:05Z
status: human_needed
score: 4/4 success criteria verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/4
  gaps_closed:
    - "DYN-01/DYN-02 — dynamic selection is now invoked by the running unit (selectNext + the clean-rep recorder are wired into letter_unit_screen._onNodePassed via every scoring section; a FAIL keeps the child on the current exercise's remediation state rather than advancing linearly)"
    - "DYN-02 — the quiet star can now fire: clean-reps are WRITTEN at the single scoring chokepoint (exercise_scaffold._onResult → onGraphNodePassed → app_database.incrementExerciseCleanReps), and the star is gated on isMasteryMetForPresented so it fires on real clean-reps and cannot fire on click-through (verified by Test 3 FLIPPED + Test 5)"
  gaps_remaining: []
  regressions: []
follow_ups:  # Documented, accepted interims — NOT blockers, NOT roadmap-deferred
  - item: "Content coverage: the 6-section baa unit presents+records reps on only 7 of the signed graph's 15 essential nodes; the star is scoped to the presented essential set via isMasteryMetForPresented. The signed curriculum_graph.json and the full isMasteryMet are unchanged. Surfacing the remaining 8 essential exercises (writeLetter.fromPicture/writeForm, connectWord.kitaab, completeWord.middle, writeWord.copy/picture, buildSentence.hear/picture) grows the UNIT, not the graph — a content-coverage task for the owner-mother + a later phase. Not covered by Phase 16's roadmap goal (presence/voice/eval/demo-harden)."
    severity: noted_limitation
human_verification:
  - test: "On a Pixel Tablet build, enter the baa unit, deliberately FAIL a stroke, and observe what comes next."
    expected: "The child stays on the current exercise in its remediation/fix state (does NOT auto-advance to the next linear section on a fail); the offline walker remediates one tier down within the competency. Code evidence now supports this — selectNext is invoked only on a PASS, and a FAIL never advances the cursor."
    why_human: "Real on-device flow + ML-Kit scoring; the per-stroke verdict and the felt remediation behaviour cannot be confirmed by static analysis. Code is now wired (was the blocker); confirm the observable behaviour on device."
  - test: "On a Pixel Tablet build, complete the baa unit to genuine mastery (meet the essential clean-rep floor on every PRESENTED essential node), then reach the Mastery section."
    expected: "Exactly one quiet star is recorded and shown; a clicked-through unit with unmet reps records nothing."
    why_human: "Requires a full real-device practice run with real scored passes. Widget tests prove the star fires on real reps and not on click-through; on-device confirmation of the felt single-star celebration is still a human check."
  - test: "Re-enter the baa unit after closing it mid-progress (and after an app relaunch)."
    expected: "The unit resumes at (near) the child's last position; the durable Drift graph cursor restores currentExerciseId/clearedCompetencies/clearedTiers, and the section hint now grows with cleared competencies (no longer pinned to section 0)."
    why_human: "Durable Drift resume + the cleared-state-derived section hint cannot be exercised across a real relaunch in a widget test. cleared-state now grows (markNodeCleared is wired), so the hint is no longer degenerate; confirm the resume lands sensibly on device."
  - test: "ONLINE selection path (needs the Cloud Run server reachable + TUTOR_BASE_URL configured): trace baa, fail a stroke, confirm a graph-legal agent-proposed next exercise drives the screen, and an illegal proposal falls to the offline walker."
    expected: "Agent-proposed next exercise (when graph-legal per isLegalSelection) drives the screen; illegal/absent proposals degrade to the offline walker; never the fixed linear walk. The selector router is now READ by the running unit."
    why_human: "Requires the deployed server AND a live network. The screen-side wiring is now present (selectNext → exerciseSelectorProvider → RouterExerciseSelector), so the path is no longer inert; the online leg still needs a real server round-trip to observe."
---

# Phase 15: Dynamic Grounded Exercise Selection on baa — Verification Report

**Phase Goal:** Replace `LetterUnitController`'s fixed section walk with dynamic, grounded exercise selection on baa — the agent picks the next exercise (responding to recent mistakes), the curriculum rails the choices, the flow is resume-aware and ends in ONE quiet star at real mastery, and grounding faithfulness is measured/enforced.

**Verified:** 2026-06-28T15:40:05Z
**Status:** human_needed (all 4 success criteria VERIFIED in code; 4 on-device MVP user-flow confirmations queued — see Human Verification)
**Re-verification:** Yes — after gap-closure plan 15-08 (commits 1be1669 + 5033fda)

**Owner decision honoured (2026-06-28):** The owner explicitly chose to KEEP the bespoke 6-section unit UI and plumb selection INTO it, rather than rewrite the unit into a flat one-exercise-at-a-time flow. SC1 is judged against that decision: "agent-driven" is realized WITHIN the preserved 6-section shell (a per-section seam), not as a full replacement of the section shell. The 6-section macro-order is the intended bound, not a defect.

## Re-verification Summary

The prior verification (gaps_found, 2/4) correctly found that the entire selection/mastery machinery was DEAD from the running screen: `selectNext`, `incrementExerciseCleanReps`/`setExerciseCleanReps`, and `markNodeCleared` had ZERO production callers, so a FAIL surfaced the next linear section and the star could never fire. Plan 15-08 closed both blockers by wiring the running unit through that machinery. This re-verification confirms the wiring is real, substantive, and tested in the actual production call-graph (not just in tests that drive the bare walker).

| Prior gap | Status now | Evidence |
|-----------|-----------|----------|
| Gap 1 — selection never invoked (DYN-01/DYN-02) | ✓ CLOSED | `letter_unit_screen._onNodePassed` (screen:212-239) now calls `incrementExerciseCleanReps` → `markNodeCleared` → `controller.selectNext`. All 4 scoring sections pass canonical graph ids via `onGraphNodePassed`. `selectNext` has 2 real production callers (controller:182, screen:234). |
| Gap 2 — star can never fire (DYN-02) | ✓ CLOSED | Clean-reps are WRITTEN at the single scoring chokepoint (`exercise_scaffold._onResult:178-180` → `onGraphNodePassed` → `incrementExerciseCleanReps`, screen:219). The star is gated on `isMasteryMetForPresented`. Test 3 (FLIPPED): click-through with unmet reps records NOTHING — PASS. Test 5: essential core at owner-mother reps → exactly one star — PASS. |

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Entering the baa unit runs the **agent-driven flow** (not the static sequence); the agent picks the next exercise responding to recent mistakes, within the owner's keep-sections shell (DYN-01, DYN-02) | ✓ VERIFIED | The selection seam is now LIVE in the running unit. `letter_unit_screen._onNodePassed` (screen:212-239) calls `controller.selectNext(facts)` on each scored PASS → `exerciseSelectorProvider` → `RouterExerciseSelector` (online `plan.nextExerciseId` when `isLegalSelection`, else the offline `CurriculumGraphWalker`). A FAIL never reaches `selectNext` (it is gated on `result.passed`, exercise_scaffold:178), so the child stays on the current exercise's remediation state rather than blindly advancing — **Pitfall 5 fixed within the preserved 6-section shell** (the owner's intended bound). The walker forward-advance is now reachability-aware (`_nextReachableForward` → `graph.isLegalSelection`, walker:108-123; +4 T4 tests pass). `markNodeCleared` grows `clearedCompetencies`/`clearedTiers` (controller:199-237, wired at screen:225). |
| 2 | The agent can select **only valid, signed-off baa configs** — the curriculum rails the choices (DYN-01) | ✓ VERIFIED | Server rail unchanged & green: `curriculum.py` G4 `is_authored` / G5 `tier_of`+`reachable_tiers` / G6 `prerequisites_met`; `plan.py` raises fail-closed → AuthoredFallback. Client mirror `graph.isLegalSelection` (curriculum_graph:288-302) re-checks authored+tier-reachable+prereqs before accepting any agent proposal; illegal/absent → offline walker (selector:87-99). Server tests: 32 passed, 40 deselected. |
| 3 | The dynamic flow is **resume-aware** and ends in **ONE quiet star** at real mastery — no streaks/totals/extra stars (DYN-02) | ✓ VERIFIED | **Star fires on real reps:** clean-reps are written at the single scoring chokepoint (`exercise_scaffold._onResult` → `onGraphNodePassed` → `incrementExerciseCleanReps`, screen:217-223); `recordMasteryIfMet` (controller:253-290) gates on `isMasteryMetForPresented(graph, reps, presented)` — fires on real clean-reps, returns false on click-through. Verified by `letter_unit_screen_test` Test 3 (FLIPPED — unmet reps record NOTHING) + Test 5 (essential core at reps → exactly one star), both PASS. **Resume:** durable Drift cursor read/write wired (controller:131,150,328); cleared-state now GROWS (`markNodeCleared`), so the section hint is no longer pinned to 0. **No gamification:** the old `atMastery → recordMastery(cleanReps:0)` nav auto-write stays deleted; `goTo`/`advance` carry no recordMastery. |
| 4 | Grounding faithfulness is **measurable and enforced** — flags praise-on-fail / wrong-fix and reports a rate (GROUND-03) | ✓ VERIFIED | Unchanged from prior (already verified). `faithfulness.py` flags praise-on-fail (`_PRAISE` lexicon) + wrong-fix (expected-fix token), both gated on a FAIL; `evaluate_faithfulness` reports `faithful/total`. Behavioral run: `python -m app.faithfulness` → "GROUND-03 faithfulness rate: 9/13 = 69.23% (4 flagged)". Tests pass. |

**Score:** 4/4 success criteria verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/letter_unit/letter_unit_screen.dart` | Selection + clean-rep recording wired into the running unit (`_onNodePassed`) | ✓ VERIFIED | `_onNodePassed` (212-239): increment clean-reps → markNodeCleared → selectNext. All 4 scoring sections pass canonical graph ids via `onGraphNodePassed`. The bespoke `_section(index)` switch is preserved by owner choice; selection is plumbed into it per the keep-sections decision. |
| `lib/features/letter_unit/letter_unit_controller.dart` | `selectNext` invoked; `markNodeCleared` grows cleared state; mastery gated | ✓ VERIFIED | `selectNext` (174) now has 2 production callers (self:182, screen:234). `markNodeCleared` (199) wired at screen:225, dedup-grows cleared comps/tiers once minCleanReps met. `recordMasteryIfMet` (253) gates on `isMasteryMetForPresented`. |
| `lib/features/letter_unit/widgets/exercise_scaffold.dart` | Scoring chokepoint fires `onGraphNodePassed` on a clean pass | ✓ VERIFIED | `_onResult` (169-218): on `result.passed && graphExerciseId != null` calls `onGraphNodePassed` (178-180), BEFORE the CTA, never on a fail, never for teach-cards/per-word ids. |
| `lib/data/app_database.dart` (`incrementExerciseCleanReps`) | Per-exercise clean-rep writer feeding mastery, with a production caller | ✓ VERIFIED | `incrementExerciseCleanReps` (387) now called from screen:219 (was orphaned). Read by `exerciseCleanRepsFor`/`getExerciseCleanReps`. Stores ids/counts/timestamps only — no PII. |
| `lib/curriculum/curriculum_graph_walker.dart` | Reachability-aware forward advance; backward remediation legal | ✓ VERIFIED | `_nextReachableForward` (108) scans declaration order for the next `isLegalSelection` node (T4 — no tier-skip, no prereq-skip). Fail → `remediateOneTier ?? current`. +4 T4 walker tests pass. CR-04 (prior G5-bypass WARNING) closed. |
| `lib/curriculum/mastery_condition.dart` | `isMasteryMet` / `isMasteryMetForPresented` over essential 70/30 core | ✓ VERIFIED | `isMasteryMetForPresented` (52-65) returns `hasAny` (false on empty intersection → fail-CLOSED for the live path). The vacuous true-on-empty in bare `isMasteryMet` is now unreachable in production (`_presentedExerciseIds()` is a non-empty const set, so the `presented.isEmpty` fallback never triggers). +4 mastery tests pass. |
| `lib/tutor/exercise_selector_provider.dart` | ExerciseSelector router (online↔offline), single switch point | ✓ VERIFIED | `RouterExerciseSelector` accepts a graph-legal agent proposal else the walker; `_PendingSelector` no-ops while the graph loads. Now READ by the controller's `selectNext` which is itself called by the running screen (no longer orphaned). |
| `server/app/curriculum.py` / `nodes/plan.py` | G4/G5/G6 rail, fail-closed | ✓ VERIFIED | Unchanged; 32 server tests pass. |
| `server/app/faithfulness.py` | praise-on-fail / wrong-fix flag + rate | ✓ VERIFIED | Reporter runs, reports 9/13 = 69.23%. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `letter_unit_screen._onNodePassed` | `controller.selectNext` | screen drives selection on a scored pass | ✓ WIRED | screen:234 — builds TutorFacts(passed:true) and calls selectNext after the clean-rep + cleared-state writes. |
| every scoring section | `exercise_scaffold.onGraphNodePassed` | section passes canonical graph id | ✓ WIRED | meet:154, watchTrace:200, forms:257+274, listenWrite:218 — all pass `graphExerciseId` + `onGraphNodePassed: _onNodePassed`. |
| `exercise_scaffold._onResult` | `onGraphNodePassed` | clean pass → host increments reps | ✓ WIRED | scaffold:178-180, gated on `result.passed && graphExerciseId != null`. |
| `letter_unit_screen._onNodePassed` | `app_database.incrementExerciseCleanReps` | write per-exercise clean-reps | ✓ WIRED | screen:219 — the table is now populated in the running app. |
| `letter_unit_screen._onNodePassed` | `controller.markNodeCleared` | grow cleared competencies/tiers | ✓ WIRED | screen:225 — cleared-state grows when minCleanReps met (WR-01 closed). |
| `controller.recordMasteryIfMet` | `mastery_condition.isMasteryMetForPresented` | gate the star on real reps | ✓ WIRED | controller:269-272; fed real reps via `exerciseCleanRepsFor`. |
| `controller.selectNext` | `exerciseSelectorProvider` → walker/router | offline+online selection | ✓ WIRED | controller:175,182. |
| `controller.start` | `graphPositionRepository` | persist/restore durable cursor | ✓ WIRED | controller:131,150,328. |
| `plan.py` | `curriculum.py` (G4/G5/G6) | server rail | ✓ WIRED | Unchanged; fail-closed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `recordMasteryIfMet` star | `reps` | `appDatabase.exerciseCleanRepsFor(letterId)` | Yes — table now written by `incrementExerciseCleanReps` on every clean pass | ✓ FLOWING |
| `selectNext` cursor | `currentExerciseId` | walker/router over the signed graph, seeded from `facts.section` (a canonical graph id passed from `_onNodePassed`) | Yes — `_onNodePassed` passes the canonical `baa.*` node id, not the synthetic per-word id | ✓ FLOWING |
| `markNodeCleared` cleared-state | `clearedCompetencies`/`clearedTiers` | graph node lookup + Drift rep count vs `minCleanReps` | Yes — grows only when the threshold is met; persisted | ✓ FLOWING |
| online plan rail | `cleared_tiers`/`cleared_competencies` | Dart cleared-state now grows + is persisted | Yes — the client no longer feeds the server rail empty state forever (WR-01 closed) | ✓ FLOWING |
| `faithfulness` report | labeled cases | `faithfulness_set.jsonl` fixture | Yes — 13 real cases, 4 flagged | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Star fires on real reps / not on click-through | `flutter test test/features/letter_unit/letter_unit_screen_test.dart` | Test 3 (FLIPPED, unmet reps → NO mastery) PASS; Test 5 (essential core at reps → exactly one star) PASS; All tests passed | ✓ PASS |
| Walker is reachability-aware (T4) | `flutter test test/curriculum/curriculum_graph_walker_test.dart` | T4 forward-reachability + no-prereq-skip + backward-legal tests PASS | ✓ PASS |
| Scoped mastery condition | `flutter test test/curriculum/mastery_condition_test.dart` | +4 mastery tests PASS | ✓ PASS |
| Affected Dart suites green | `flutter test test/features/letter_unit/ test/curriculum/ test/tutor/` | 231 passed, 4 failed — all 4 are pre-existing drift (see below) | ✓ PASS (no new failures) |
| Server rail green | `cd server && uv run pytest tests/ -q -k "faithful or curriculum or plan or graph"` | 32 passed, 40 deselected | ✓ PASS |
| GROUND-03 reporter | `cd server && uv run python -m app.faithfulness` | "9/13 = 69.23% (4 flagged)" | ✓ PASS |

**The 4 Dart failures are ALL pre-existing drift, independently confirmed (none touch 15-08's files or the selection/mastery wiring):**
- `meet_section_test.dart` Test 1 — `img.door` `Image.asset` not found in the test env (door-image render).
- `reference_overlay_golden_test.dart` — `alif_reference_overlay.png` golden pixel diff 1.47% (font/render drift).
- `alif_reference_test.dart` ×2 — alif corrected-centerline geometry drift (shipped letters.json).

These exactly match the documented acceptable-failures list and the known "golden tests font drift" memory.

### Probe Execution

No probes declared for this phase and no conventional `scripts/*/tests/probe-*.sh` found. Step 7c: N/A.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DYN-01 | 15-02/03/05/07/08 | The agent selects the next exercise from baa's authored configs, reasoning about recent mistakes; the curriculum rails the choices | ✓ SATISFIED | Rail VERIFIED server-side (G4/G5/G6) + client mirror (`isLegalSelection`). Selection is now INVOKED by the running unit (`_onNodePassed → selectNext`), within the owner's keep-sections shell. REQUIREMENTS.md still shows `[ ]`/In Progress — should be reconciled to Complete. |
| DYN-02 | 15-03/04/05/07/08 | The dynamic, resume-aware flow replaces the fixed section walk for baa end-to-end | ✓ SATISFIED | Within the owner's keep-sections decision: a PASS advances reachability-aware, a FAIL remediates (never the next linear section), resume is durable + cleared-state grows, and the quiet star fires on real reps (scoped to presented essential nodes). The interim content-coverage limitation is noted (follow-up), not a blocker. REQUIREMENTS.md still shows `[ ]`/In Progress — should be reconciled to Complete. |
| GROUND-03 | 15-06 | Faithfulness measurable — flags claims contradicting geometry | ✓ SATISFIED | faithfulness.py flags praise-on-fail/wrong-fix; reporter outputs a rate; tests pass. REQUIREMENTS.md already Complete. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/curriculum/mastery_condition.dart` | 29-35 | `isMasteryMet` still returns true vacuously on an empty-essential graph | ℹ️ Info | Latent only — the live path uses `isMasteryMetForPresented` (fail-closed) with a non-empty hardcoded presented set, so the vacuous fallback is unreachable in production. Hardening `isMasteryMet` to fail-closed remains nice-to-have, not a phase blocker. |
| `lib/features/letter_unit/letter_unit_controller.dart` | 300-308 | `_presentedExerciseIds()` is a hardcoded baa-specific const set | ℹ️ Info | Correct for the signed baa graph today; a later phase should derive it from the unit config so it stays in sync when content coverage grows. Documented in-code as INTERIM. |

No 🛑 Blockers. The two prior BLOCKER dead-code anti-patterns (`selectNext` and `setExerciseCleanReps`/`incrementExerciseCleanReps` with no production caller) are RESOLVED — both now have live production callers. No `TBD`/`FIXME`/`XXX` debt markers in the modified files.

### Documented Interim / Follow-up (NOT a blocker)

**Content coverage (owner/mother + later phase):** The signed curriculum graph has 15 essential nodes (across the 4 essential competencies `recognize`, `positionalForms`, `copyWrite`, `fluentReading`), but the 6-section baa unit presents and records reps on only 7 of them: `baa.teachCard.meet`, `baa.traceLetter.isolated`, `baa.traceLetter.initial`, `baa.traceLetter.medial`, `baa.connectWord.baab`, `baa.writeWord.dictation`, `baa.writeLetter.fromSound` (independently confirmed: all 7 ARE essential nodes; intersection = 7). The 8 not-yet-surfaced essential nodes (`writeLetter.fromPicture`/`writeForm`, `connectWord.kitaab`, `completeWord.middle`, `writeWord.copy`/`picture`, `buildSentence.hear`/`picture`) are exactly the SUMMARY's list. The star is therefore scoped to the PRESENTED essential set via `isMasteryMetForPresented`; the signed `curriculum_graph.json` and the full `isMasteryMet` are UNCHANGED. Surfacing the remaining 8 grows the UNIT, not the pedagogy. This is NOT addressed by Phase 16 (whose roadmap goal is presence/voice/eval-gate/demo-harden), so it is recorded here as a noted limitation/follow-up rather than a roadmap-deferred item. Accepted per the owner's keep-sections decision (2026-06-28).

### Human Verification Required

See the `human_verification` frontmatter. Unlike the prior verification (where code evidence predicted the first two would FAIL), the code is now wired and the widget tests support the expected behaviours; the four items below are the on-device MVP user-flow confirmations that static analysis + widget tests cannot fully settle:

1. **FAIL → stays-on-remediation (not next section).** A fail keeps the child on the current exercise; the walker remediates one tier down. *(Code now supports this — selectNext fires only on a PASS.)*
2. **Genuine mastery → one quiet star.** Master the presented essential set; expect exactly one star; a click-through earns none. *(Widget tests prove both directions; confirm the felt celebration on device.)*
3. **Resume after relaunch.** Re-enter mid-progress; expect a sensible resume position (cleared-state now grows the hint). *(Durable cursor + cleared-state wired; confirm across a real relaunch.)*
4. **Online agent selection** (needs the deployed server + network). *(Screen now reads the selector; the online leg needs a real round-trip to observe.)*

### Gaps Summary

No gaps. Phase 15's two prior BLOCKERs are closed by 15-08: the selection + clean-rep + cleared-state machinery is now invoked by the running unit (via `_onNodePassed` fed by every scoring section's `onGraphNodePassed`), and the quiet star fires on real clean-reps (scoped to the presented essential set) and cannot fire on click-through — proven by the FLIPPED Test 3 + Test 5 pair and the +8 new walker/mastery tests. The work was done WITHIN the owner's explicit keep-sections decision (selection plumbed into the bespoke 6-section shell, not a flat rewrite), which is the intended bound. The curriculum rail (server G4/G5/G6 + client mirror) and GROUND-03 faithfulness remain solid and green.

One documented interim remains: the unit under-covers the signed essential set (7 of 15 essential nodes presented), so the star is scoped to what is taught. This is an accepted, flagged content-coverage follow-up — the signed graph and the full mastery condition are unchanged — and it is not addressed by Phase 16, so it is recorded as a noted limitation, not a blocker.

All four success criteria are VERIFIED in code (score 4/4, no gaps). Per the gates decision tree, because four on-device MVP user-flow confirmations are queued, the overall phase status is `human_needed` (the empty-human-section requirement for `passed` is not met). These four items are confirmations of now-wired behaviour, not predictions of failure — a contrast with the prior verification, where code evidence predicted the first two would fail.

---

_Verified: 2026-06-28T15:40:05Z_
_Verifier: Claude (gsd-verifier)_
