---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
verified: 2026-06-28T14:55:47Z
status: gaps_found
score: 2/4 success criteria verified
overrides_applied: 0
gaps:
  - truth: "Entering the baa unit runs the agent-driven dynamic selection flow (the agent picks the next exercise responding to recent mistakes), not LetterUnitController's fixed 6-section linear walk (DYN-01/DYN-02)"
    status: failed
    reason: >-
      The entire selection seam (ExerciseSelector → RouterExerciseSelector → CurriculumGraphWalker,
      LetterUnitController.selectNext) is dead code from the running UI's perspective.
      letter_unit_screen.dart still renders sections through the fixed `_section(data, index)` switch
      (line 249, 256-319) driven by `_advance()` → `controller.advance()` → `goTo(index + 1)` (a pure
      linear index bump, controller line 164). `LetterUnitController.selectNext` (controller:173) has
      ZERO production callers — grep finds it invoked only from
      test/curriculum/curriculum_graph_walker_test.dart and
      test/features/letter_unit/dynamic_selection_test.dart, both of which construct the walker
      directly rather than driving the screen. The live scored-attempt path (exercise_scaffold.dart:168)
      builds TutorFacts and calls brain.next(facts) but uses the result ONLY for a coaching LINE
      (line 183-184 → tutorLineProvider); it never calls selectNext and never drives section choice.
      A FAIL therefore still surfaces the next linear section, not a remediation — Pitfall 5 (the
      phase's primary target) is still live in the running app. The green dynamic_selection_test
      masks this: its own header says Plan 15-05 was to replace the `_section(index)` switch, but it
      passes by exercising CurriculumGraphWalker in isolation (test line 40), not the UI.
    artifacts:
      - path: "lib/features/letter_unit/letter_unit_screen.dart"
        issue: "Still uses the fixed `_section(data, index)` switch + `_advance()`→`controller.advance()`; never reads exerciseSelectorProvider or calls controller.selectNext. The plan's promised config-presenter-fed-by-selector replacement was not done."
      - path: "lib/features/letter_unit/letter_unit_controller.dart"
        issue: "selectNext (line 173) is defined but has no production caller; it is dead code reachable only from tests."
      - path: "lib/features/letter_unit/widgets/exercise_scaffold.dart"
        issue: "The live scoring path (line 150-190) routes facts to the coaching LINE only; it never feeds selectNext or advances via the selector."
    missing:
      - "Wire letter_unit_screen.dart's advance/present-activity dispatch through the selector: after a scored attempt produces TutorFacts, call controller.selectNext(facts, decision: lastAgentDecision) and present the section/exercise the chosen nextExerciseId maps to (id→section), instead of goTo(index+1)."
      - "Add an end-to-end widget test that pumps LetterUnitScreen, scores a FAIL through the UI, and asserts a remediation exercise surfaces (not section index+1) — the dynamic_selection_test must drive the UI, not the bare walker."
      - "Resolve facts.section (a section id like 'traceLetter') to a concrete graph node id before constructing GraphPosition (WR-02: selectNext currently feeds a bare section id into the walker, producing an off-graph cursor)."
  - truth: "The dynamic flow ends in ONE quiet star at REAL mastery (DYN-02) — recordMasteryIfMet records the star only when per-exercise clean-reps meet the essential floor"
    status: failed
    reason: >-
      The mastery star can never fire in the unit. recordMasteryIfMet (controller:194) gates the star
      on isMasteryMet(graph, exerciseCleanRepsFor(letterId)), which requires every essential node to
      have met its minCleanReps in the LetterExerciseReps table. But setExerciseCleanReps
      (app_database.dart:357) — the ONLY writer of that table — is never called from any production
      code: grep finds its sole caller is test/features/letter_unit/letter_unit_screen_test.dart:266
      (a test seeding the DB directly). With the real graph, exerciseCleanRepsFor always returns an
      empty map, every essential node reads 0 reps, isMasteryMet returns false forever, and a child
      who genuinely masters baa in the unit never earns the star. The anti-gamification DELETION (the
      old atMastery→recordMastery(cleanReps:0) nav auto-write) was done correctly, but its functional
      replacement (write clean-reps on a clean pass, then fire the star at the floor) was never wired
      into the scoring sections.
    artifacts:
      - path: "lib/data/app_database.dart"
        issue: "setExerciseCleanReps (line 357) — the only per-exercise clean-rep writer — has no production caller; the table is never populated in the running app."
      - path: "lib/features/letter_unit/widgets/exercise_scaffold.dart"
        issue: "On a clean pass the scoring path never writes setExerciseCleanReps for the presented exercise; the counter isMasteryMet reads stays empty."
      - path: "lib/curriculum/mastery_condition.dart"
        issue: "isMasteryMet returns true vacuously when graph.essentialNodes is empty (a structurally-degraded-but-decodable asset) — fail-OPEN on the anti-gamification invariant (WR-03)."
    missing:
      - "On every clean pass inside a scoring section, write the per-exercise counter for the presented exercise's graph node id via appDatabase.setExerciseCleanReps(letterId, exerciseId, cleanReps)."
      - "Add a test that drives real reps to the essential floor through the unit and asserts exactly one recordMastery write fires, and that an under-floor clicked-through unit records NOTHING."
      - "Make isMasteryMet fail closed: return false when graph.essentialNodes is empty (WR-03)."
deferred: []
human_verification:
  - test: "On a Pixel Tablet build, enter the baa unit, deliberately FAIL a stroke, and observe what comes next."
    expected: "A remediation exercise (one tier down / a re-test) surfaces, NOT the next linear section in the fixed ribbon order."
    why_human: "Real on-device flow + ML-Kit scoring; cannot be verified by static analysis. Code evidence indicates this will NOT happen (selectNext is unwired) — confirm the observable failure."
  - test: "On a Pixel Tablet build, complete baa to genuine mastery (meet the essential clean-rep floor on every essential node), then reach the Mastery section."
    expected: "Exactly one quiet star is recorded and shown."
    why_human: "Requires a full real-device practice run. Code evidence indicates the star can NEVER fire (clean-reps never written) — confirm whether mastery yields a star or a dead end."
  - test: "Re-enter the baa unit after closing it mid-progress (and after an app relaunch)."
    expected: "The unit resumes at the child's last position rather than restarting at section 0."
    why_human: "Durable Drift resume cursor is wired (start→getPosition/setPosition), but the section hint derives from cleared-competency count which is never grown (WR-01/WR-05), so resume likely lands at section 0 in practice. Confirm on device."
  - test: "ONLINE selection path (needs the Cloud Run re-deploy + TUTOR_BASE_URL): trace baa, fail a stroke, confirm a remediation re-surfaces and the agent's choice responds to the mistake."
    expected: "Agent-proposed next exercise (graph-legal) drives the screen; illegal proposals fall to the offline walker; never the fixed linear walk."
    why_human: "Requires the deployed server (OPS follow-up not done) AND the screen-side wiring (gap 1). Even with the deploy, the screen never reads the selector, so this path is currently inert."
---

# Phase 15: Dynamic Grounded Exercise Selection on baa — Verification Report

**Phase Goal:** Replace `LetterUnitController`'s fixed section walk with dynamic, grounded exercise selection on baa — the agent picks the next exercise (responding to recent mistakes), the curriculum rails the choices, the flow is resume-aware and ends in ONE quiet star at real mastery, and grounding faithfulness is measured/enforced.

**Verified:** 2026-06-28T14:55:47Z
**Status:** gaps_found
**Re-verification:** No — initial verification
**Mode note:** ROADMAP marks this phase `mode: mvp`, but the goal is not in strict User-Story format ("As a … I want to … so that …"). Verification proceeded goal-backward against the four explicit ROADMAP Success Criteria (the contract). The MVP User-Flow-Coverage framing is reflected in the Human Verification section.

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Entering the baa unit runs the **agent-driven flow** (not the static sequence); the agent picks the next exercise via `present_activity` from baa's configs, responding to recent mistakes (DYN-01/DYN-02) | ✗ FAILED | `letter_unit_screen.dart:249,256-319` still renders by fixed `_section(data, index)` switch; `_advance()` → `controller.advance()` → `goTo(index+1)` (controller:164). `LetterUnitController.selectNext` (controller:173) has **zero** production callers (grep: only the two walker/dynamic-selection tests, which call the walker directly). Live scoring path (`exercise_scaffold.dart:168-184`) routes facts to the coaching LINE only, never to selection. Selection is dead code in the running unit — Pitfall 5 unfixed. |
| 2 | The agent can select **only valid, signed-off baa configs** — the curriculum rails the choices; an invalid/unsigned config can never be presented (DYN-01) | ✓ VERIFIED | Server rail genuinely working & fail-closed. `curriculum.py`: G4 `is_authored` (closed AUTHORED_BAA_IDS set), G5 `tier_of`/`reachable_tiers` (strict إملاء ladder), G6 `prerequisites_met`; empty-graph degrade rejects (lines 79-103). `plan.py:92-139` enforces G4/G5/G6 + G3 verdict-lock, raising `StructuredOutputError` → AuthoredFallback on any violation. Client mirror `graph.isLegalSelection` re-checks the agent proposal. Server tests: 32 passed (curriculum/plan/graph). |
| 3 | The dynamic flow is **resume-aware** and ends in **ONE quiet star** at mastery — no streaks/totals/extra stars (DYN-02) | ✗ FAILED | **Star can never fire:** `recordMasteryIfMet` (controller:194) → `isMasteryMet(graph, exerciseCleanRepsFor)` always false because `setExerciseCleanReps` (app_database.dart:357, the only writer) has no production caller (grep: only a test at line 266). **Anti-gamification half VERIFIED:** the nav auto-write is deleted (`goTo`/`advance` carry no `recordMastery`); `recordMastery` in the unit fires only behind `isMasteryMet`. **Resume half PARTIAL:** durable cursor read/write wired (`start`→getPosition controller:130 / setPosition:241), but cleared-state is never grown (WR-01) so the section hint is always 0 (WR-05). Net: criterion FAILED on the star. |
| 4 | Grounding faithfulness is **measurable and enforced** — flags praise-on-fail / wrong-fix and reports a rate (GROUND-03) | ✓ VERIFIED | `faithfulness.py` flags both failure modes (`_contradicts` lines 49-67: praise-on-fail + wrong-fix, gated on FAIL) and reports `faithful/total`. Behavioral run: `python -m app.faithfulness` → "GROUND-03 faithfulness rate: 9/13 = 69.23% (4 flagged)". Fixture present at `server/tests/fixtures/faithfulness_set.jsonl`. Tests pass. (Robustness WARNINGs WR-06/WR-07 noted, not functional failures.) |

**Score:** 2/4 success criteria verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/tutor/exercise_selector_provider.dart` | ExerciseSelector router (online↔offline), single switch point | ⚠️ ORPHANED | Exists, substantive, well-built (RouterExerciseSelector + _PendingSelector). Imported by the controller, but the controller method that uses it (`selectNext`) is never called from production → effectively unwired. (Plan named it `selection_providers.dart`; renamed — acceptable.) |
| `lib/curriculum/curriculum_graph_walker.dart` | Pure offline walker (advance/remediate) | ⚠️ ORPHANED | Exists, substantive. `selectNext` (line 82) used only by tests + the orphaned router. CR-04: on a PASS returns `graph.nextForward` with NO tier/prereq re-check (G5 bypass) — latent because the whole path is unused. |
| `lib/curriculum/mastery_condition.dart` | `isMasteryMet` over essential 70/30 core | ⚠️ Substantive but fail-OPEN | Exists, called by `recordMasteryIfMet`. WR-03: returns `true` vacuously on a degenerate (empty-essential) graph. |
| `lib/features/letter_unit/letter_unit_controller.dart` | Drift-persisted position + mastery gated on isMasteryMet | ⚠️ PARTIAL | Resume read/write + mastery gate present; but `selectNext` has no caller and cleared-state never grows (WR-01). |
| `lib/features/letter_unit/letter_unit_screen.dart` | Config-presenter fed by the selector (replaces `_section` switch) | ✗ NOT DELIVERED | `_section(index)` switch untouched; selector never read. The plan's load-bearing replacement was not performed. |
| `lib/data/app_database.dart` (`setExerciseCleanReps`) | Per-exercise clean-rep writer feeding mastery | ✗ ORPHANED writer | Defined (line 357); no production caller → the table is never populated. |
| `server/app/curriculum.py` | G4/G5/G6 rail, fail-closed | ✓ VERIFIED | Correct, fail-closed, tested. |
| `server/app/nodes/plan.py` | Post-parse G4/G5/G6/G3 guards → AuthoredFallback | ✓ VERIFIED | Correct, raises fail-closed. |
| `server/app/faithfulness.py` | praise-on-fail / wrong-fix flag + rate | ✓ VERIFIED | Working; reporter runs and reports a real rate. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `letter_unit_screen.dart` | `exerciseSelectorProvider` / `controller.selectNext` | screen reads selector to choose next exercise | ✗ NOT_WIRED | The screen never references the selector or selectNext; it advances by linear index. |
| `exercise_scaffold.dart` (scoring) | `controller.selectNext` | feed scored facts into selection | ✗ NOT_WIRED | Facts feed only the coaching line (`tutorLineProvider`). |
| scoring section (clean pass) | `app_database.setExerciseCleanReps` | write per-exercise clean-reps | ✗ NOT_WIRED | No production write; mastery counter stays empty. |
| `letter_unit_controller.dart` | `mastery_condition.isMasteryMet` | gate recordMastery | ✓ WIRED | Gate present (controller:204); but its input (reps) is always empty → always false. |
| `letter_unit_controller.dart` | `graph_position_repository` | persist/restore graph position | ✓ WIRED | getPosition/setPosition wired (controller:130,241); start() called from screen:181. |
| `plan.py` | `curriculum.py` (G4/G5/G6) | enforce rail on agent proposal | ✓ WIRED | Imported + enforced; raises fail-closed. |
| `exercise_selector_provider.dart` | `curriculum_graph_walker.dart` | offline fallback | ✓ WIRED | RouterExerciseSelector delegates to the walker — but the whole router is orphaned (see above). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `letter_unit_screen.dart` section render | `index` | `state.index` from controller `goTo`/`advance` (linear) | Yes (but linear, not selection-driven) | ⚠️ HOLLOW vs goal — renders sections, but the section choice is a fixed index, not the agent/walker's nextExerciseId. |
| `recordMasteryIfMet` star | `reps` | `appDatabase.exerciseCleanRepsFor(letterId)` | No — table never written (`setExerciseCleanReps` has no caller) | ✗ DISCONNECTED — always empty map → star never fires. |
| `plan` node rail | `cleared_tiers`/`cleared_competencies` | `facts["clearedTiers"/...]` from the wire | No — Dart never grows cleared-state (WR-01) → always `[]` → `has_graph_position` always false → G5/G6 are a documented no-op online | ⚠️ STATIC — server rail correct but fed empty state from the client. |
| `faithfulness` report | labeled cases | `faithfulness_set.jsonl` fixture | Yes — 13 real cases, 4 flagged | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| GROUND-03 faithfulness reporter produces a rate | `cd server && uv run python -m app.faithfulness` | `GROUND-03 faithfulness rate: 9/13 = 69.23% (4 flagged)` | ✓ PASS |
| Server curriculum/plan/graph/faithfulness tests pass | `cd server && uv run pytest tests/ -q -k "faithful or curriculum or plan or graph"` | `32 passed, 40 deselected` | ✓ PASS |
| Dart dynamic-selection + walker tests | `flutter test test/features/letter_unit/dynamic_selection_test.dart test/curriculum/curriculum_graph_walker_test.dart` | Could not run — native build failed (`lipo`/objective_c.dylib missing; toolchain/env, not phase code) | ? SKIP — but source inspection shows these tests exercise the walker directly, not the UI, so a green result would not evidence the integration. |

### Probe Execution

No probes declared for this phase and no conventional `scripts/*/tests/probe-*.sh` found. Step 7c: N/A.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DYN-01 | 15-02, 15-03, 15-05, 15-07 | Agent selects next exercise from authored configs reasoning about mistakes; curriculum rails the choices | ✗ BLOCKED (partial) | Rail VERIFIED server-side (G4/G5/G6). But "agent selects the next exercise" is not wired into the running unit (selectNext dead) → the selection half of DYN-01 is not achieved end-to-end. REQUIREMENTS.md marks it Complete — contradicted by the call-graph. |
| DYN-02 | 15-03, 15-04, 15-05, 15-07 | Dynamic, resume-aware flow REPLACES the fixed section walk for baa end-to-end | ✗ BLOCKED | The fixed `_section(index)` walk is NOT replaced; selectNext is dead; the star can never fire. The end-to-end replacement (the heart of DYN-02) did not land. REQUIREMENTS.md marks it Complete — contradicted. |
| GROUND-03 | 15-06 | Faithfulness measurable — flags claims contradicting geometry | ✓ SATISFIED | faithfulness.py flags praise-on-fail/wrong-fix; reporter outputs a rate; tests pass. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/features/letter_unit/letter_unit_controller.dart` | 173 | Public `selectNext` with no production caller (dead code) | 🛑 Blocker | The phase's central deliverable is unreachable from the running app. |
| `lib/data/app_database.dart` | 357 | `setExerciseCleanReps` writer with no production caller | 🛑 Blocker | Mastery star can never fire — `isMasteryMet` always false. |
| `lib/tutor/exercise_selector_provider.dart` | 112-133 | Router orphaned (only reachable via the dead `selectNext`) | ⚠️ Warning | Correct-but-dead machinery. |
| `lib/curriculum/curriculum_graph_walker.dart` | 90-92 | Offline walker advances across tiers without re-checking reachability (G5 bypass) | ⚠️ Warning | CR-04 — latent while selectNext is unused; live once wired. |
| `lib/curriculum/mastery_condition.dart` | 29-35 | `isMasteryMet` returns true on empty-essential graph (fail-open) | ⚠️ Warning | WR-03 — fail-open against the anti-gamification invariant. |
| `lib/features/letter_unit/letter_unit_controller.dart` | 139-150,177 | cleared-state never grown; `facts.section` (section id) fed as a graph node id | ⚠️ Warning | WR-01/WR-02 — G5/G6 fed empty state forever; off-graph cursor when wired. |
| `server/app/faithfulness.py` | 80-84,105-108 | Direct `c["passed"]`/`c["coaching"]` indexing (KeyError on malformed row) | ℹ️ Info | WR-06 — not fail-soft; not a functional failure. |

### Note on the curriculum-graph `signedOff` flag (REVIEW CR-03 — partially refuted)

The code review flagged `signedOff: true` as shipped prematurely. **Chesterton's-Fence check refutes the "shipped unsigned" half:** Plan 15-07 was the human-gated plan that owns the flip, and the owner-mother sign-off is recorded in `15-HUMAN-UAT.md` (reviewer: Owner-mother, status passed, 2026-06-28) and `docs/curriculum/baa-curriculum-graph-signoff-sheet.md` (marked SIGNED, Q1/Q2/Q3 recorded, Q3 reps adjustment 2→3 applied). Both the asset and the re-derived server copy carry `signedOff: true` legitimately. The asset's stale `_meta.sign_off` string (still saying "stays false until … Plan 15-07 owns the flip") was not updated to reflect that 15-07 executed — cosmetic drift, not a pedagogy violation. **The "flag is decorative" half stands as a WARNING:** no consumer in `lib/` or `server/` branches on `graph.signedOff` to refuse driving selection/mastery off an unsigned graph. Recommend adding a real gate, but this is defense-in-depth, not a phase-goal blocker (the graph IS signed).

### Human Verification Required

See the `human_verification` frontmatter. The four items below are the MVP user-flow walk-throughs that automated checks cannot settle; code evidence predicts the first two will FAIL on device:

1. **FAIL → remediation (not next section).** Fail a stroke in the baa unit; expect a remediation exercise, not the next ribbon section. *(Code evidence: will not happen — selectNext unwired.)*
2. **Genuine mastery → one quiet star.** Master baa to the essential floor; expect exactly one star. *(Code evidence: star can never fire — clean-reps never written.)*
3. **Resume after relaunch.** Re-enter mid-progress; expect resume to last position. *(Cursor wired; section hint likely degenerate to 0 — confirm.)*
4. **Online agent selection** (needs Cloud Run re-deploy + screen wiring). *(Currently inert — the screen never reads the selector.)*

### Gaps Summary

Phase 15 built a large body of **correct, well-tested, but DEAD** selection + mastery machinery and placed it beside a unit that still walks the fixed 6-section linear sequence. The green test suite masks two integration failures because the tests call the new machinery directly (the walker / DB) rather than driving the screen:

- **Gap 1 (CR-01 — DYN-01/DYN-02):** Dynamic selection is never invoked. `letter_unit_screen.dart` still uses `_section(index)` + `controller.advance()`; `controller.selectNext` has no production caller. A fail surfaces the next linear section, not a remediation — Pitfall 5, the phase's primary target, is unfixed in the running app.
- **Gap 2 (CR-02 — DYN-02):** The mastery star can never fire. The only writer of per-exercise clean-reps (`setExerciseCleanReps`) is never called in production, so `isMasteryMet` is always false. The anti-gamification DELETION is correct, but its functional replacement was never wired.

Both gaps share a single root cause: **the scoring/advance path in the running screen was never routed through the new selection + clean-rep machinery.** A focused fix wiring `exercise_scaffold`'s scored-attempt path (and `letter_unit_screen`'s advance dispatch) into `controller.selectNext` + `setExerciseCleanReps`, plus an end-to-end widget test that drives a FAIL and a real-mastery run through the UI, closes both.

Criteria 2 (curriculum rail) and 4 (faithfulness) are genuinely working and verified — the server side is solid and fail-closed. The WARNINGs (CR-04 G5 bypass, WR-01 cleared-state, WR-02 off-graph cursor, WR-03 fail-open mastery, WR-05 resume hint) become live the moment Gaps 1-2 are wired and should be closed in the same effort.

**Not deferred to Phase 16:** Phase 16's goal explicitly *depends on* "Phase 15 (the dynamic grounded baa flow being voiced + hardened)" and its demo-harden criterion assumes a working baa flow with a reachable mastery star. The integration wiring is a Phase 15 deliverable, not a Phase 16 one.

---

_Verified: 2026-06-28T14:55:47Z_
_Verifier: Claude (gsd-verifier)_
