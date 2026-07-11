---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 03
subsystem: database
tags: [ema, knowledge-tracing, drift, schema-migration, dart-python-parity, non-pii, child-model]

# Dependency graph
requires:
  - phase: 18
    provides: "18-01 Wave-0 RED contract — the byte-identical EMA parity fixtures (criterion_ema_test.dart / test_criterion_ema.py) this plan turns green"
  - phase: 15
    provides: "LetterGraphPosition resume-cursor pattern (schema v5) + JSON-encoded-list-column idiom this plan extends to arc-state / evidence / profile-mirror"
provides:
  - "Pure per-criterion EMA mirrored Dart↔Python (updateEma / update_ema) — byte-identical formula + provisional named constants (signed:false), agreeing on the shared fixtures (D-15)"
  - "classifyCriterion / classify_criterion — the sparse-data gate (unknown < kEmaMinAttempts, never a false struggle, Pitfall 4)"
  - "Drift schemaVersion 6 with three additive version-guarded tables: LetterCriterionEvidence (D-14 digest queue), ArcStateRows (D-12 resume), ChildProfileMirror (D-16 boot mirror)"
  - "Primitive DB accessors (appendEvidence/unsyncedEvidence/clearEvidence, get|setArcStateRow, get|setProfileMirror) — raw rows/primitives only, type-cycle-free"
affects: [18-04, 18-05, 18-06, 18-09, 18-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cross-language pure-function parity (Dart lib/core ↔ Python app/) pinned by byte-identical fixtures — the on-device within-session estimate and the nightly compile share one formula + one α"
    - "Additive version-guarded Drift migration (from < N createTable block) — resume-cursor pattern extended to three new non-PII tables with zero touch to existing rows"
    - "Provisional signed:false named constants (kEmaAlpha/HI/LO/MinAttempts) documented for mother sign-off at 18-11 — never magic numbers"

key-files:
  created:
    - lib/core/scoring/criterion_ema.dart
    - server/app/criterion_ema.py
  modified:
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart

key-decisions:
  - "EMA formula is alpha*(passed?1:0)+(1-alpha)*prior, byte-identical in Dart and Python; the 18-01 fixtures (0.5·pass·0.4→0.7, the 0.7→0.82→0.492 chain, α=0.5 saturation rows) pin the formula, not the mother's final α"
  - "classifyCriterion applies the sparse-data gate FIRST (attempts < kEmaMinAttempts → unknown) before the HI/LO band check — sparse data is never a false struggle (Pitfall 4), mirroring the _deriveStruggleTags '>=2 occurrences' idiom"
  - "criterion_ema.dart is a pure lib/core citizen (library; directive holds the file doc, no Flutter/Firebase import) — stays inside the durable_layers_no_agent_imports scan"
  - "The three new Drift tables store ONLY ids/counts/bools/timestamps/JSON-id-lists (T-18-03-01); ChildProfileMirror JSON-encodes strengths/struggles/perCriterion into text columns like LetterGraphPosition.clearedCompetencies"
  - "DB accessors return raw Drift rows (LetterCriterionEvidenceData / ArcStateRow / ChildProfileMirrorData) not lib/curriculum pure types — the repository (18-06) decodes, keeping the DB layer type-cycle-free (15-04 precedent)"
  - "clearEvidence(ids) is the storage-DoS rollup cap (T-18-03-03) — caps on-device evidence growth after the digest syncs; no-op on empty list"

patterns-established:
  - "Dart↔Python EMA parity: any drift on either side reddens one of the two shared-fixture tests"
  - "schemaVersion N→N+1 as a pure additive createTable block under a from<N guard — the low-migration-risk shape (never a data-rewriting table rebuild)"

requirements-completed: []

# Metrics
duration: 16min
completed: 2026-07-11
---

# Phase 18 Plan 03: Per-Criterion EMA + Drift v6 Child-Model Foundations Summary

**The two lowest-level child-model foundations: a pure per-criterion EMA mirrored byte-for-byte across Dart (lib/core) and Python (app/) that agrees on the 18-01 parity fixtures (D-15), plus a Drift schemaVersion 5→6 additive bump adding the evidence-accrual (D-14), arc-state-resume (D-12), and profile-mirror (D-16) tables — pure and additive, unblocking the policy, the repositories, and the nightly compiler.**

## Performance

- **Duration:** ~16 min
- **Started:** 2026-07-11T10:22Z
- **Completed:** 2026-07-11T10:38Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- **Per-criterion EMA, mirrored Dart↔Python (D-15):** `updateEma`/`update_ema` implement `alpha*(passed?1:0)+(1-alpha)*prior` byte-identically; the 18-01 RED parity fixtures (6 fixture rows + the 3-step pass/pass/fail chain landing on 0.492) turn GREEN on BOTH sides with zero test edits. The provisional α + thresholds ship as NAMED `signed:false` constants (`kEmaAlpha` 0.4 / `kEmaStrengthHi` 0.75 / `kEmaStruggleLo` 0.35 / `kEmaMinAttempts` 2, mirrored as module-level `ALPHA`/`HI`/`LO`/`MIN`), never magic numbers.
- **Sparse-data classifier (Pitfall 4):** `classifyCriterion`/`classify_criterion` gate on `kEmaMinAttempts` FIRST — a criterion is `unknown` (neither strength nor struggle) until it has ≥2 attempts, so sparse data is never a false struggle. Mirrors the `_deriveStruggleTags` ">=2 occurrences" idiom.
- **Durable-layer purity held:** `criterion_ema.dart` carries no Flutter/Firebase import and stays inside the `durable_layers_no_agent_imports_test` scan (green).
- **Drift schemaVersion 5→6 (three additive tables):** `LetterCriterionEvidence` (offline D-14 digest queue: letterId/criterion/passed/source/createdAt, auto-increment PK), `ArcStateRows` (D-12 resume: letterId PK + active/step/targetCriterion/exerciseToRetry), and `ChildProfileMirror` (D-16 boot mirror: uid PK + JSON strengths/struggles/perCriterion) all registered and created under a version-guarded `if (from < 6)` block — no data rewrite, existing `from<2..from<5` blocks untouched.
- **Primitive, type-cycle-free accessors:** `appendEvidence`/`unsyncedEvidence`/`clearEvidence` (the rollup cap, T-18-03-03), `get|setArcStateRow`, `get|setProfileMirror` (JSON encode/decode like `getPosition`/`setPosition`) — all return raw Drift rows/maps/primitives; `app_database.g.dart` regenerated and committed (15-04 precedent).

## Task Commits

Each task was committed atomically:

1. **Task 1: per-criterion EMA — Dart + Python mirror (D-15)** — `19e9d5f` (feat)
2. **Task 2: Drift schemaVersion 5→6 — evidence / arc-state / profile-mirror tables** — `822ed85` (feat)

**Plan metadata:** (this docs commit)

_Task 1 is `tdd="true"`: the RED phase was authored in 18-01; this plan is the GREEN leg (one feat commit turning the existing parity tests green, zero test edits)._

## Files Created/Modified

- `lib/core/scoring/criterion_ema.dart` — pure-Dart per-criterion EMA (`updateEma` + `classifyCriterion` + `CriterionClass` enum + provisional signed:false constants); no Flutter/Firebase import
- `server/app/criterion_ema.py` — byte-identical Python mirror (`update_ema`/`classify_criterion` + module-level `ALPHA`/`HI`/`LO`/`MIN`); model-free/network-free `code` check
- `lib/data/app_database.dart` — schemaVersion 6 + the three new tables + version-guarded `from < 6` migration + primitive accessors
- `lib/data/app_database.g.dart` — regenerated Drift codegen for the three new tables (tracked, not gitignored)

## Decisions Made

- **EMA fixtures pin the formula, not the α.** The α (0.4) + thresholds are PROVISIONAL (`signed:false`, mother-signed at 18-11 per D-15/A4). The parity tests assert the arithmetic; the constants are documented for the later sign-off.
- **Accessors return raw Drift rows, not pure types.** `getArcStateRow`/`getProfileMirror` hand back `ArcStateRow`/`ChildProfileMirrorData`; the repository layer (18-06) will decode the JSON columns. This keeps the DB layer free of any `lib/curriculum` type import (the 15-04 type-cycle precedent).
- **ArcState needs no JSON encoding.** Unlike the profile mirror (list/map columns), arc-state columns are all scalars (bool/text ids), so `set|getArcStateRow` write/read primitives directly — the "JSON encode/decode like getPosition/setPosition" note applies to the profile mirror's list/map columns only.
- **Requirement SPEC-18-R8 NOT checkbox-marked.** This is the foundation leg (EMA math + persistence tables) of R8, not the full requirement — R8's across-session memory / evidence digest also spans 18-05/18-06/18-09. Following the phase precedent (18-01/18-02 left R1..R9 unmarked at foundation plans; STATE: "R3/R7 NOT checkbox-marked (DATA leg only)"), `requirements-completed: []`; the plan landing the final leg (or the phase verifier) flips it.

## Deviations from Plan

None — plan executed exactly as written. Both tasks implemented the specified files; every per-task `<automated>` verify passed. No Rule 1–4 deviations were required.

## Issues Encountered

- **A pre-existing red in `test/data/curriculum_repository_v2_test.dart`** (`getExercises() ... every((e) => e.signedOff == true)`) surfaced when running the full `test/data/` suite. It is NOT caused by this plan — it is the documented alif-unsigned-exercise-forms failure already logged in `deferred-items.md` (one of the "748/8-known" baseline reds; the test touches `assets/curriculum/exercises.json`, a surface this plan never modifies). Out of scope per the SCOPE BOUNDARY rule; left untouched. The migration/schema-relevant data tests (`app_database_test`, `graph_position_repository_test`, `progress_repository_test`, `account_data_isolation_test`) all pass (16/16).

## Known Stubs

None — both EMA functions are fully implemented; the three Drift tables + accessors are complete. The α/threshold constants are PROVISIONAL (`signed:false`) by design, awaiting the mother's sign-off at 18-11 (D-15/A4) — this is a tracked pedagogy gate, not a stub that blocks the plan's goal.

## Threat Flags

None — no new security-relevant surface beyond the plan's `<threat_model>`. All three new tables store only ids/counts/bools/timestamps/JSON-id-lists (T-18-03-01 mitigated by construction); `clearEvidence` caps on-device growth (T-18-03-03); the EMA parity tests hold the Dart↔Python correctness boundary (T-18-03-02).

## Next Phase Readiness

- **18-04** (pure-Dart `SelectionPolicy`) can now consume `classifyCriterion` + the EMA to derive struggle/strength targets and drive the arc state machine.
- **18-05/18-06** (server-first evidence deriver + client repositories) have the Drift `LetterCriterionEvidence` queue + `ChildProfileMirror` mirror + arc-state table to persist against.
- **18-09** (nightly compiler) uses the SAME `update_ema` the client uses, so the compile agrees with the on-device within-session estimate (D-15).
- No blockers. No new packages.

## Self-Check: PASSED

- All 4 files present on disk (verified): `lib/core/scoring/criterion_ema.dart`, `server/app/criterion_ema.py`, `lib/data/app_database.dart`, `lib/data/app_database.g.dart`.
- Both task commits present in git history: `19e9d5f`, `822ed85`.
- Task 1 verify: Dart parity test green (8 tests) + durable-layers guard green + Python parity green (7 tests, `-m code`).
- Task 2 verify: `build_runner build` clean; `schemaVersion => 6`, `from < 6`, and all three tables registered; migration/schema data tests green (16/16). The only `test/data/` red is the documented pre-existing alif-unsigned failure.

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-11*
