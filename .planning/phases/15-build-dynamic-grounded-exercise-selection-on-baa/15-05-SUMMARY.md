---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
plan: 05
subsystem: tutor
tags: [tutor, letter_unit, riverpod, grounding, selection, mastery, drift, wire-contract]

# Dependency graph
requires:
  - phase: 15-01
    provides: "the RED dynamic_selection_test (imports lib/tutor/exercise_selector_provider.dart + exerciseSelectorProvider) this plan turns GREEN; the provisional curriculum_graph asset"
  - phase: 15-02
    provides: "the server-side wire contract (TutorFactsIn.clearedTiers/clearedCompetencies, extra=forbid) + the G5/G6 reachable_tiers/prerequisites_met legality model this plan mirrors client-side"
  - phase: 15-03
    provides: "CurriculumGraph + the ExerciseSelector seam + CurriculumGraphWalker + isMasteryMet (the pure on-device spine this plan wires)"
  - phase: 15-04
    provides: "GraphPositionRepository + the Drift LetterGraphPosition/LetterExerciseReps tables + the already-extended Dart payload_nonpii_test (the 10-field wire contract, GREEN)"
provides:
  - "lib/tutor/exercise_selector_provider.dart — exerciseSelectorProvider + RouterExerciseSelector (online↔offline single switch point) + curriculumGraphProvider (the keepAlive rootBundle loader)"
  - "CurriculumGraph.{isAuthored, reachableTiers, prerequisitesMet, isLegalSelection} — the pure-Dart client mirror of the server's G5/G6 rail (client + server agree, T-15-05-T)"
  - "the ExerciseSelector seam extended with an optional `decision` (the online agent reply); the offline walker ignores it"
  - "LetterUnitController rewired: durable Drift resume (replaces _resumeByLetter), selectNext() unit-level selection, recordMasteryIfMet() gated strictly on isMasteryMet (the cleanReps:0 navigation auto-write DELETED)"
  - "the server non-PII regression (server/tests/test_payload_nonpii.py) extended over the two graph-position FACTS fields"
affects: [15-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Selection router beside coaching router — exerciseSelectorProvider mirrors tutorBrainFactoryProvider's single-switch shape; the two degrade on SEPARATE axes (selection→walker, coaching→AuthoredFallbackBrain)"
    - "Graph-legality re-check client-side: the agent's plan.nextExerciseId is UNTRUSTED and re-validated against CurriculumGraph.isLegalSelection (the same authored+tier-reachable+prereqs-met rules the server's G5/G6 applies) before presenting"
    - "Optional-named-param override widening: ExerciseSelector.selectNext gains an optional `decision` so the online router can read it while the offline walker (and all existing callers) ignore it — no breaking change"
    - "Star gated on a Future-resolving on-device condition, recorded post-frame only when the Mastery section is actually presented (never on navigation — Pitfall 2)"

key-files:
  created:
    - lib/tutor/exercise_selector_provider.dart
  modified:
    - lib/curriculum/curriculum_graph.dart
    - lib/curriculum/curriculum_graph_walker.dart
    - lib/features/letter_unit/letter_unit_controller.dart
    - lib/features/letter_unit/letter_unit_screen.dart
    - test/features/letter_unit/letter_unit_screen_test.dart
    - server/tests/test_payload_nonpii.py

key-decisions:
  - "Provider file named lib/tutor/exercise_selector_provider.dart with a top-level exerciseSelectorProvider symbol — to MATCH the 15-01 RED contract's hard import + symbol exactly (zero test edits). The plan's files_modified listed lib/tutor/selection_providers.dart; the RED contract is binding, so I reconciled to the contract's name (documented as a deviation)."
  - "The selection ROUTER lives in lib/tutor/, NOT lib/curriculum/ — the durable_layers_no_agent_imports guard forbids riverpod/network/remote_agent imports in lib/curriculum. The pure legality HELPERS (reachableTiers/prerequisitesMet/isLegalSelection) live in lib/curriculum/curriculum_graph.dart (pure Dart, mirroring the server); the router combines them with the agent decision in lib/tutor/."
  - "The rich Phase-07 section widgets (Meet/Watch&Trace/Forms/Words/Listen&Write/Mastery) are KEPT, not replaced with a bare ExerciseScaffold config-presenter. A wholesale UI replacement would discard signed product surface (the Watch demo, Forms-in-context, vocab illustrations) — an architectural change beyond this slice. Instead the CONTROLLER became the unit-level selection+mastery driver (the load-bearing DYN-02 behavior the plan's key_links/truths require), and the sections stay as the presenters they already are. Every plan acceptance criterion is met; the dynamic_selection_test end-to-end proof is green via the seam."
  - "recordMasteryIfMet records the essential-core clean-rep FLOOR (the smallest banked essential count), never the old cleanReps:0 navigation write — a real, non-zero progress value."

patterns-established:
  - "Client G5/G6 mirror: CurriculumGraph.isLegalSelection(id, clearedTiers, clearedCompetencies) = authored membership + reachableTiers(strict ladder) + prerequisitesMet — byte-for-byte the server's reachable_tiers/prerequisites_met so an agent suggestion is gated identically on both ends."
  - "Durable resume in the controller: getPosition (Future, Pitfall 6) at start, setPosition on each cleared step, via graphPositionRepository — the in-memory _resumeByLetter map is gone."

requirements-completed: [DYN-01, DYN-02]

# Metrics
duration: 16min
completed: 2026-06-27
---

# Phase 15 Plan 05: Dynamic Grounded Selection Wired End-to-End on baa Summary

**A Riverpod `exerciseSelectorProvider` router picks the next baa exercise online (the RemoteAgent's `plan.nextExerciseId`, re-checked against the client's own G5/G6 graph-legality mirror) vs. offline (the `CurriculumGraphWalker`) on a SEPARATE axis from coaching; the `LetterUnitController` now reads/writes its graph position to Drift for durable resume and records the quiet star ONLY when `isMasteryMet` is true (the `cleanReps:0` navigation auto-write is deleted); and the non-PII regression is proven over the two new FACTS fields on both client and server — turning the 15-01 RED `dynamic_selection_test` GREEN and flipping the old mastery-on-navigation assertion.**

## Performance

- **Duration:** ~16 min
- **Started:** 2026-06-27T15:30:15Z
- **Completed:** 2026-06-27
- **Tasks:** 3
- **Files modified:** 1 created, 6 modified

## Accomplishments

- **DYN-02 is real end-to-end.** The `exerciseSelectorProvider` is the single SELECTION switch point — the sibling of `tutorBrainFactoryProvider`. Online it accepts the agent's `plan.nextExerciseId` ONLY when graph-legal; offline / illegal / absent it delegates to the deterministic `CurriculumGraphWalker`. Selection degrades on a SEPARATE axis from coaching (Pitfall 5) — a fail re-surfaces a remediation (one tier down), NEVER the old fixed 6-section linear sequence. The 15-01 RED `dynamic_selection_test` is GREEN.
- **The agent's choice is UNTRUSTED (T-15-05-T).** I added a pure-Dart client mirror of the server's G5/G6 rail to `CurriculumGraph` (`isAuthored` / `reachableTiers` / `prerequisitesMet` / `isLegalSelection`), byte-for-byte the server's `reachable_tiers` / `prerequisites_met`. The router re-checks an agent proposal against the child's cleared state before presenting it; an illegal forward jump falls to the walker. Backward remediation passes both ends (Pitfall 3).
- **The star is gated on real mastery (D-06 / Pitfall 2).** The old `state.atMastery → recordMastery(cleanReps:0)` auto-write — which fired the star for merely NAVIGATING to the Mastery section — is DELETED. `recordMasteryIfMet()` now records mastery ONLY when `isMasteryMet(graph, perExerciseCleanReps)` is true over the essential 70/30 core, and records the real essential-core floor (never `cleanReps:0`). The flipped Test-3 proves a clicked-through unit with unmet reps records NOTHING; a new Test-5 proves the essential core at the owner-mother reps records exactly one quiet star.
- **Resume is durable (D-08).** The in-memory `_resumeByLetter` map (lost on a relaunch) is replaced by reads/writes through `graphPositionRepository` (getPosition — a Future, Pitfall 6; setPosition on each step).
- **The enlarged FACTS are proven non-PII on BOTH ends (GROUND-02).** The server `test_payload_nonpii.py` now carries `clearedTiers`/`clearedCompetencies` in `LEGIT_FACTS`, asserts `TutorFactsIn` accepts them, that their names+values trip no PII/stroke token (the server mirror of the Dart regex), and that omitting them defaults to `[]` (backward-compatible). The Dart side was already extended in lockstep by 15-04 (verified green as-is — not re-touched).

## Task Commits

Each task was committed atomically:

1. **Task 1: The ExerciseSelector router provider (online↔offline single switch point)** — `23e85ee` (feat)
2. **Task 2: Drive the baa unit by selection + gate the star on isMasteryMet (retire the fixed walk)** — `9cf0f12` (feat)
3. **Task 3: Extend the non-PII regression over the two new FACTS fields (server side)** — `75d39d7` (test)

_Note: Tasks 1 & 2 are TDD GREEN-phase commits whose RED contract (`dynamic_selection_test`, `graph_position_repository_test`) was authored in 15-01. See TDD Gate Compliance below._

## Files Created/Modified

- `lib/tutor/exercise_selector_provider.dart` (created, 133 lines) — `kCurriculumGraphAsset`; `curriculumGraphProvider` (a keepAlive `FutureProvider` that `rootBundle`-loads + parses the single-source graph — the rootBundle read lives HERE, never in the pure layer); `RouterExerciseSelector` (accepts a graph-legal `plan.nextExerciseId`, else delegates to `CurriculumGraphWalker`); `exerciseSelectorProvider` (the `Provider<ExerciseSelector>` switch point); `_PendingSelector` (calm no-op while the graph loads).
- `lib/curriculum/curriculum_graph.dart` (modified, +86) — added `isAuthored`, `reachableTiers` (strict progressive ladder unlock), `prerequisitesMet`, and `isLegalSelection` (the combined G4+G5+G6 gate). Pure Dart; mirrors the server's `app.curriculum` helpers.
- `lib/curriculum/curriculum_graph_walker.dart` (modified, +21) — the `ExerciseSelector` seam gains an optional `decision` param (the offline walker ignores it); imports the pure `tutor/tutor_decision.dart` (allowed by the lib/curriculum ban list — no cloud/network/render token).
- `lib/features/letter_unit/letter_unit_controller.dart` (rewired, +244/-65) — `LetterUnitState` gains the durable `currentExerciseId`/`clearedCompetencies`/`clearedTiers`/`masteryRecorded` fields; `start()` is now async and reads the durable Drift position; `_resumeByLetter` is gone; `selectNext()` is the unit-level selection seam; `recordMasteryIfMet()` is the isMasteryMet-gated star; the `_onEnterSection → _recordMastery(cleanReps:0)` auto-write is DELETED.
- `lib/features/letter_unit/letter_unit_screen.dart` (modified, +20) — `_recordMasteryIfMet()` fires post-frame ONLY when the Mastery section is presented (never on navigation).
- `test/features/letter_unit/letter_unit_screen_test.dart` (modified, +132) — FLIPPED Test-3 (unmet reps → NO mastery), added Test-5 (essential core at reps → one quiet star); harness overrides `appDatabaseProvider` (in-memory `AppDatabase`), `graphPositionRepositoryProvider` (a fake), and `curriculumGraphProvider` (off-disk, hermetic).
- `server/tests/test_payload_nonpii.py` (modified, +54) — the two fields in `LEGIT_FACTS`; `test_graph_position_fields_carry_no_pii` + `test_graph_position_fields_default_empty_when_omitted`; the server PII-token regex mirror.

## Decisions Made

- **Provider name reconciled to the RED contract (deviation, see below).** Named the file/symbol per the 15-01 RED test's hard import (`lib/tutor/exercise_selector_provider.dart` / `exerciseSelectorProvider`), not the plan's `selection_providers.dart` — the binding contract wins, zero test edits.
- **Router in `lib/tutor/`, legality helpers in `lib/curriculum/`.** The durable-layers purity guard forbids riverpod/network in `lib/curriculum`; the pure G5/G6-mirror helpers are pure Dart and belong on the graph, while the router (which reads the agent decision) belongs beside `tutor_providers.dart`.
- **Kept the rich Phase-07 section widgets; made the CONTROLLER the unit-level driver.** See key-decisions frontmatter — a wholesale UI replacement was out of scope (it would discard signed product surface); every plan acceptance criterion is met without it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Provider file/symbol reconciled to the 15-01 RED contract**
- **Found during:** Task 1.
- **Issue:** The plan's `files_modified` listed `lib/tutor/selection_providers.dart`, but the Wave-0 RED `dynamic_selection_test.dart` (authored in 15-01) hard-imports `package:qalam/tutor/exercise_selector_provider.dart` and asserts on a top-level `exerciseSelectorProvider`. Creating only `selection_providers.dart` would leave the RED test failing to compile (unresolved import) — DYN-01/DYN-02 would stay RED.
- **Fix:** Named the provider file `lib/tutor/exercise_selector_provider.dart` and exposed `exerciseSelectorProvider` — matching the RED contract exactly, zero test edits.
- **Files modified:** `lib/tutor/exercise_selector_provider.dart` (created).
- **Verification:** `flutter test test/features/letter_unit/dynamic_selection_test.dart` GREEN (both cases).
- **Committed in:** `23e85ee` (Task 1 commit).

**2. [Rule 2 — Missing critical] Added the client-side G5/G6 graph-legality mirror**
- **Found during:** Task 1.
- **Issue:** The plan's action requires the online path to accept `plan.nextExerciseId` "ONLY if graph-legal … reuse the curriculum_graph legality helpers." But `CurriculumGraph` (15-03) had only `tierOf`/`nextForward`/`remediateOneTier` — it had NO `reachableTiers`/`prerequisitesMet`/`isLegalSelection`. Without them the router could not re-check an untrusted agent proposal (T-15-05-T mitigation absent).
- **Fix:** Added `isAuthored`/`reachableTiers`/`prerequisitesMet`/`isLegalSelection` to `CurriculumGraph` — pure-Dart, byte-for-byte the server's `app.curriculum.reachable_tiers`/`prerequisites_met` (so client and server agree).
- **Files modified:** `lib/curriculum/curriculum_graph.dart`.
- **Verification:** the curriculum + tutor suites stay GREEN; the durable-layers purity guard stays GREEN (no forbidden import added).
- **Committed in:** `23e85ee` (Task 1 commit).

**3. [Rule 3 — Blocking] Widened the ExerciseSelector seam with an optional `decision`**
- **Found during:** Task 1.
- **Issue:** The router must read the online agent reply, but the `ExerciseSelector.selectNext(facts, position)` seam (15-03) had no parameter for it; adding it only on the router would make callers holding the `ExerciseSelector` static type unable to pass the decision.
- **Fix:** Added an optional named `decision` param to the abstract seam + the walker (which ignores it) so all implementations + callers share one signature.
- **Files modified:** `lib/curriculum/curriculum_graph_walker.dart`.
- **Verification:** `curriculum_graph_walker_test` + `dynamic_selection_test` GREEN.
- **Committed in:** `23e85ee` (Task 1 commit).

---

**Total deviations:** 3 auto-fixed (1 blocking-contract, 1 missing-critical, 1 blocking-seam).
**Impact on plan:** All three were necessary to satisfy the plan's own acceptance criteria + threat model (T-15-05-T). No scope creep — the provider rename matches the binding RED contract, and the two helper/seam additions are exactly the "reuse the legality helpers" the plan's action specifies. Test 3 of `payload_nonpii_test.dart` (Dart) was NOT re-touched (already done by 15-04, per the cross-plan note — verified green as-is).

## Issues Encountered

- **`meet_section_test.dart` Test 1 (`img.door`) fails on the full suite** — RE-CONFIRMED RED on a clean Task-1-only checkout (via `git stash`) BEFORE any Task-2 change, proving it is a PRE-EXISTING image-asset failure unrelated to this plan (it lives in `meet_section.dart`, untouched). Logged in `deferred-items.md`; not fixed (executor scope boundary).
- **Full client suite: `+632 -6`** (vs the 15-04 baseline `+629 -7`): the previously-RED `dynamic_selection_test` is now GREEN, 3 new tests pass, and all 6 remaining failures are the same documented golden/data/image drift. NONE reference any symbol this plan changed (verified by grep).

## TDD Gate Compliance

Tasks 1 & 2 are the GREEN side of a plan-level TDD cycle split across waves:
- **RED gate:** `24be19f` (15-01) — authored `dynamic_selection_test.dart` (DYN-02) failing first (verified RED at execution start: compile-fail on the missing `exercise_selector_provider.dart`).
- **GREEN gate:** `23e85ee` + `9cf0f12` (this plan) — make the RED test pass + flip the screen test.
- **REFACTOR gate:** none needed — clean on first pass (analyzer clean on all touched lib files; the only infos are pre-existing string-interpolation lint in untouched code).

The RED→GREEN sequence is present in git history. No warning needed.

## Authentication Gates

None. The work is on-device Dart wiring + a pure-Dart graph mirror + an offline server `pytest.mark.code` test extension; no auth, no network, no deploy in this autonomous slice.

## Known Stubs

None. The `_PendingSelector` returns null only while the graph asset loads (the unit shows its calm "preparing" state) — that is the designed degrade, not a stub. The curriculum graph asset stays `signedOff:false` by design (the owner-mother review gate, D-05; Plan 15-07 owns the flip) — no code path in this plan consumes it as signed.

## Threat Surface

No new security-relevant surface beyond the plan's `<threat_model>`. All mitigations satisfied:
- **T-15-05-E** (agent grants the star / flips fail→pass): mitigated — `recordMasteryIfMet` is gated strictly on `isMasteryMet` (on-device, never off a CoachOut, ADR-014); the `cleanReps:0` navigation auto-write is DELETED (Pitfall 2).
- **T-15-05-T** (online selection presents an illegal/unauthored config): mitigated — `RouterExerciseSelector` re-checks `CurriculumGraph.isLegalSelection` (authored + tier-reachable + prereqs-met) CLIENT-SIDE before presenting; illegal → walker (Pitfall 5).
- **T-15-05-ID** (enlarged FACTS leak PII): mitigated — the non-PII regression is now extended on BOTH client (15-04) + server (this plan, Task 3) over the two new fields; `buildTutorFacts` accepts no stroke/profile param.
- **T-15-05-D11** (cross-letter ت/ث coaching): mitigated — no ت/ث content introduced; baa only (D-11).
- **T-15-SC** (pub installs): N/A — zero packages installed.

## Verification

- **Task 1:** `dart run build_runner build` clean (78 outputs, no tracked .g.dart churn); `flutter test test/tutor/ test/features/letter_unit/dynamic_selection_test.dart test/curriculum/curriculum_graph_test.dart test/curriculum/curriculum_graph_walker_test.dart` → **106 passed**; `flutter analyze` over the 3 Task-1 lib files → clean.
- **Task 2:** `flutter test test/features/letter_unit/dynamic_selection_test.dart test/features/letter_unit/letter_unit_screen_test.dart` → **7 passed** (the flipped Test-3 + the new Test-5); `flutter analyze` over the controller + test → clean.
- **Task 3:** `flutter test test/tutor/payload_nonpii_test.dart` → **4 passed** (Dart, already-extended by 15-04, verified green as-is); `cd server && uv run pytest tests/test_payload_nonpii.py -q` → **18 passed** (+2 new).
- **Per-wave merge:** full server suite `uv run pytest -q` → **72 passed**; full client suite `flutter test` → **+632 -6** (the 6 are the documented pre-existing golden/data/image drift; none reference a symbol this plan changed).

## Device-UAT (human gate — flagged)

The online selection path needs the re-deployed Cloud Run server (mirrors the Phase-14 UAT gate, and the 15-02/15-04 422-lockstep): run the app with `--dart-define=TUTOR_BASE_URL=<service URL>` AFTER re-deploying the server (both wire sides — 15-02 server + 15-04 Dart — have landed), trace baa, fail a stroke, and confirm a remediation exercise re-surfaces ONLINE. This autonomous slice does no deploy; the offline remediation path is proven by `dynamic_selection_test` + the walker tests.

## Next Plan Readiness

- **15-07** (sign-off checkpoint) is the only remaining plan: it flips `signedOff:false → true` on the curriculum graph behind a `checkpoint:human-verify` (owner-mother tier-level sign-off, D-05). All of 15-05's consumers read the graph as PROVISIONAL by design.
- **Deploy gate (phase UAT):** re-deploy the Cloud Run server before the on-device online-selection test (Pitfall 1 lockstep — both wire sides landed).

## Self-Check: PASSED

All claims verified: the created file (`lib/tutor/exercise_selector_provider.dart`) and this SUMMARY exist on disk; all three task commits (`23e85ee`, `9cf0f12`, `75d39d7`) are present in git history; the 15-01 RED `dynamic_selection_test` is GREEN and the screen-test Test-3 assertion is flipped.

---
*Phase: 15-build-dynamic-grounded-exercise-selection-on-baa*
*Completed: 2026-06-27*
