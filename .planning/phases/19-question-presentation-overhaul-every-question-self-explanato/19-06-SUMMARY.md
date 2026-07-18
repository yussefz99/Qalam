---
phase: 19-question-presentation-overhaul-every-question-self-explanato
plan: 06
subsystem: database
tags: [drift, table-migration, adr-018, per-child-keying, childProfileId, riverpod, pitfall-4, ground-boundary]

# Dependency graph
requires:
  - phase: 19
    plan: 01
    provides: "the skip-marked v6→v7 two-profile migration RED case (QP-09) this plan un-skips + greens"
  - phase: 19
    plan: 04
    provides: "the LetterReps→LetterExerciseReps fold (readers re-pointed) so the legacy table is safe to DROP"
provides:
  - "ADR-018: the child-identity keying rule (account uid = db file; childProfileId = child within it; every progress table carries childProfileId) + the D-17 cloud-model deferral + the verified drift 2.31 TableMigration API"
  - "Schema v7: five per-child progress tables keyed by (childProfileId, letterId[, exerciseId]); LetterCriterionEvidence carries childProfileId as a filtered column (A3); ChildProfileMirror stays uid-keyed (D-17)"
  - "The v6→v7 TableMigration recreate+backfill: existing rows adopted into the current profile (D-16), the legacy LetterReps table DROPPED (D-15), idempotent across intermediate versions"
  - "childProfileId threaded through graph_position/arc_state/evidence/drift_progress repositories + cached once in LetterUnitController.start() (Pitfall 4) and every consumer provider (practice/progression/parent/seeded-demo)"
  - "The profile-resume leak closed as a first-class identity rule: a fresh profile in the same account file reads clean (QP-09 success criterion 4)"
affects: ["future per-child progress tables (must carry childProfileId — ADR-018)", "20-21 curriculum expansion (new letters inherit the keyed schema)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Drift 2.31 TableMigration recreate+backfill: Migrator.alterTable(TableMigration(table, columnTransformer: {col: Constant<int>(id)}, newColumns: [col])) recreates a PK-changed table from the current schema and backfills the new key onto every existing row (SQLite cannot alter a PK in place)"
    - "Idempotent PK-change migration: guard each alterTable with a pragma_table_info column-exists check so an upgrade that already created a table at the current schema in an earlier if(from<N) block is not re-altered"
    - "Cache-the-async-id-once (Pitfall 4): resolve childProfileProvider.future ONCE at a controller/notifier entry point (start()/_loadLetter/build()) and store it in a field; every scored-feedback write reads the cached int, never an inline FutureProvider read on the hot path"
    - "Client-local dimension never crosses the wire: childProfileId is an int key on the DB seam only — absent from lib/tutor/, TutorFacts, and the coach payload (ADR-017 boundary, asserted by the non-PII guards)"

key-files:
  created:
    - docs/architecture/ADR-018-child-identity-keying.md
    - test/features/letter_unit/child_profile_keying_test.dart
  modified:
    - lib/data/app_database.dart
    - lib/data/progress_repository.dart
    - lib/data/drift_progress_repository.dart
    - lib/data/graph_position_repository.dart
    - lib/data/arc_state_repository.dart
    - lib/data/evidence_repository.dart
    - lib/features/letter_unit/letter_unit_controller.dart
    - lib/features/letter_unit/letter_unit_screen.dart
    - lib/providers/practice_providers.dart
    - lib/providers/progression_providers.dart
    - lib/providers/parent_providers.dart
    - lib/demo/seeded_demo_state.dart
    - test/data/app_database_test.dart

key-decisions:
  - "Verified drift 2.31.0 TableMigration API BEFORE any schema code (A4): fields are newColumns (List<Column>) + columnTransformer (Map<Column, Expression>); alterTable recreates the table from the CURRENT (v7) schema and copies data through the transformer. Recorded in ADR-018 so Task 2 wrote against a confirmed API, not a guess."
  - "LetterCriterionEvidence keeps its autoincrement surrogate PK and gains childProfileId as a REQUIRED FILTERED COLUMN, not a PK member (A3) — append-only evidence rows need a stable surrogate; every append stamps childProfileId and every read filters by it."
  - "childProfileId threaded as a METHOD PARAMETER through the repository layer (not a repo-cached field): the GraphPosition value type carries it; getPosition/getArc/setArc/pendingDigest + the ProgressRepository methods take it explicitly. The single cache lives in the CONTROLLER (Pitfall 4), so the id source is one place and the repos stay stateless."
  - "The legacy ProgressRepository.setCleanReps/getCleanReps/watchCleanReps were REMOVED from the interface + DriftProgressRepository (their AppDatabase accessors were dropped with LetterReps in Task 2). The folded letterCleanReps/watchLetterCleanReps/setLetterCleanReps survive, re-keyed by childProfileId."
  - "Fresh-install / headless-test default: a null/missing profile resolves to kUnassignedChildProfileId (0) — the same sentinel the migration adopts orphan rows under (D-16). Writes and reads under 0 stay consistent, so the live-path tests (no profile created) pass unchanged."
  - "QP-09 + QP-10 completed by this plan (the keying migration + table drop + ADR); the 19-01 v6→v7 migration case greened with skip-removal as its ONLY edit (Track C closed)."

patterns-established:
  - "Every FUTURE table that records a child's progress MUST carry childProfileId in its key (ADR-018) — the rule exists so new tables start correct instead of repeating the profile-agnostic-key leak."
  - "Interface-fold-in-lockstep (19-04 precedent): changing a shared repository interface forces every implements-fake to update; map each fake's new keyed methods onto its existing store so test bodies stay behavior-identical."

requirements-completed: [QP-09, QP-10]

# Metrics
duration: ~30min (Task 3 session; Tasks 1–2 pre-committed in a prior session)
completed: 2026-07-18
---

# Phase 19 Plan 06: Per-Child Keying Migration (ADR-018 / QP-09/QP-10) Summary

**Re-keyed the five per-child progress tables by `(childProfileId, letterId)` in one v6→v7 `TableMigration` (recreate + `Constant<int>` backfill), carried `childProfileId` as a filtered column on the surrogate-keyed `LetterCriterionEvidence`, adopted existing rows into the current profile (no progress loss) while a fresh profile reads clean, DROPPED the now-folded legacy `LetterReps`, and threaded `childProfileId` through the repositories + cached it once in `LetterUnitController.start()` — closing the profile-resume leak as a first-class identity rule (ADR-018), with `childProfileId` a local int that never crosses the ADR-017 wire boundary.**

## Performance

- **Duration:** ~30 min for Task 3 (this session); Tasks 1 (ADR) + 2 (schema v7) were committed in a prior session and verified intact on entry.
- **Completed:** 2026-07-18
- **Tasks:** 3
- **Files:** ADR-018 + schema/migration (Tasks 1–2) + 12 lib files threaded / 21 test files reconciled / 1 new guard test (Task 3)

## Accomplishments

- **Task 1 — ADR-018 + verified TableMigration API (already committed `ac32272`):** `docs/architecture/ADR-018-child-identity-keying.md` records the D-13 identity rule (account uid selects the db file; `childProfileId` = `ChildProfiles.id` selects the child within it; every progress table carries `childProfileId`), the D-14 scope (4 tables re-keyed by PK + evidence filtered column), the D-16 adoption, the D-15 `LetterReps` retirement, and the D-17 cloud-model deferral (`ChildProfileMirror`/`child_models/{uid}` stay uid-keyed). The drift 2.31.0 `TableMigration(newColumns/columnTransformer)` recreate+backfill signature is verified and written down (A4) so the schema code was written against a confirmed API. Notes that `childProfileId` is client-local and never a wire field.
- **Task 2 — schema v7 + migration (already committed `f990b28`):** `LetterMastery`/`LetterGraphPosition`/`LetterExerciseReps`/`ArcStateRows` gain `childProfileId` in the PRIMARY KEY; `LetterCriterionEvidence` gains it as a filtered column (A3); `ChildProfileMirror` stays `{uid}`. `schemaVersion` 6→7. The `if (from < 7)` block reads the single adopted profile id (sentinel `0` if none), backfills via a `Constant<int>` `columnTransformer`, recreates each PK-changed table, then `DROP TABLE IF EXISTS letter_reps` (D-15) — each recreate guarded by a `pragma_table_info` column-exists check for idempotence across intermediate `from` versions. The `class LetterReps` + its accessors are gone; the account-isolation seam (per-account sha256 db file) is preserved. The 19-01 v6→v7 two-profile migration case is greened with skip-removal as its only edit.
- **Task 3 — thread + cache childProfileId (this session, `c96cbf3`):**
  - `ProgressRepository`/`DriftProgressRepository`: `recordMastery`/`isMastered`/`watchMasteredLetterIds`/`letterCleanReps`/`watchLetterCleanReps`/`setLetterCleanReps` keyed by `childProfileId`; the legacy `setCleanReps`/`getCleanReps`/`watchCleanReps` REMOVED (their DB accessors were dropped in Task 2).
  - `GraphPosition` value type + `getPosition` carry `childProfileId`; `arc_state_repository` (`getArc`/`setArc`) and `evidence_repository` (`pendingDigest`) keyed the same way.
  - `LetterUnitController.start()` resolves `childProfileProvider.future` ONCE, caches the id in `_childProfileId`, exposes it via `childProfileId()`, and threads it to every keyed write (`setPosition`/`getArc`/`setArc`/`getExerciseCleanReps`/`exerciseCleanRepsFor`/`recordMastery`). The screen's scored-feedback increment reads the cached id — never an inline `childProfileProvider.future` read on the hot path (Pitfall 4).
  - Consumer providers (`practice_providers` cache-in-`_loadLetter`, `progression_providers` via a defensive `_resolveChildProfileId` with the file's T-05-07 timeout-degradation, `parent_providers`, `seeded_demo_state` via `db.getProfile()`) resolve the in-file child and key their reads/writes by it.
  - New `child_profile_keying_test.dart`: a real-DB behavior guard (a created profile's id is cached at `start()`, the durable cursor is keyed by it, a different profile reads null) + a source assertion (`childProfileProvider.future` read exactly once).

## Task Commits

1. **Task 1: ADR-018 + verified drift 2.31 TableMigration API** — `ac32272` (docs)
2. **Task 2: Schema v7 — re-key 5 tables + evidence column + drop LetterReps** — `f990b28` (feat)
3. **Task 3: Thread childProfileId through repos + cache in the controller** — `c96cbf3` (feat)

**Plan metadata:** _(this SUMMARY + STATE/ROADMAP/REQUIREMENTS — final docs commit)_

## RED/GREEN Evidence

| Test | Status | Note |
|------|--------|------|
| `test/data/app_database_test.dart` v6→v7 two-profile case (QP-09) | **GREEN** | skip-marker removed (Task 2); rows survive keyed to the current profile, a fresh profile reads clean, LetterReps absent, idempotent — `+10 All tests passed!` |
| `test/features/letter_unit/child_profile_keying_test.dart` | **GREEN (new)** | cache-once behavior (a created profile's id is cached + keys the cursor; a different profile reads null) + source assertion (`childProfileProvider.future` read == 1) |
| `test/features/letter_unit/ test/providers/ test/data/app_database_test.dart` (plan verify) | **GREEN** | `+145` (minus the documented `meet_section img.door`) — live path advances + records mastery with the threaded id |
| `test/tutor/payload_nonpii_test.dart` + `tutor_facts_builder_test.dart` | **GREEN** | `childProfileId` absent from `lib/tutor/` / TutorFacts / the coach payload (ADR-017 boundary holds) |
| `test/data/progress_repository_test.dart` / `graph_position_repository_test.dart` / `account_data_isolation_test.dart` / `child_model_repository_test.dart` / `seeded_demo_state_test.dart` / practice+home+router suites | **GREEN** | fakes + direct db calls threaded (Rule 3 fold across 21 files) |

## Decisions Made

See the frontmatter `key-decisions`. Load-bearing: (1) the drift 2.31 `TableMigration(newColumns/columnTransformer)` recreate path was VERIFIED before schema code (A4); (2) `LetterCriterionEvidence` carries `childProfileId` as a filtered column, not a PK member (A3); (3) `childProfileId` is threaded as an explicit method parameter through the repos with a SINGLE cache in the controller (Pitfall 4), keeping repos stateless and the id source in one place; (4) the legacy `setCleanReps`/`getCleanReps`/`watchCleanReps` were removed from the interface (folded away in 19-04); (5) a null profile resolves to `kUnassignedChildProfileId` (0), the same sentinel the migration adopts orphans under, so no-profile tests stay consistent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Interface + signature change forced fake/caller updates across 21 test files**
- **Found during:** Task 3 (threading `childProfileId` through the shared `ProgressRepository` interface + repo/DB signatures)
- **Issue:** Adding `childProfileId` to the interface + repo methods (and removing the three legacy methods whose DB accessors were dropped in Task 2) made every `implements ProgressRepository`/`GraphPositionRepository` fake non-compiling and every direct `db.*`/`repo.*` call site in tests missing a required argument — 102 compile errors across 21 test files, most outside the plan's declared `files_modified`. The tree cannot compile without them (mirrors the 19-04 interface-fold-in-lockstep precedent).
- **Fix:** Threaded `childProfileId` through every fake signature (mapped onto each fake's existing store so bodies stay behavior-identical), removed the three legacy fake overrides, and passed a consistent id at each direct call site (0 where no profile is created; the overridden profile's id where one exists; the created profile id in the isolation/keying tests). Re-folded `progress_repository_test` Test 4 from the removed `setCleanReps`/`getCleanReps` onto the surviving `setLetterCleanReps`/`letterCleanReps` and added a per-child isolation assertion.
- **Files modified:** the 21 test files listed in RED/GREEN (data/, features/letter_unit/, features/practice/, providers/, router/, screens/, demo/).
- **Verification:** `flutter analyze` → 0 errors project-wide; the plan verify suite + all touched suites green (minus documented pre-existing goldens).
- **Committed in:** `c96cbf3`

**2. [Rule 2 — Added guard] `progression_providers` child-id resolution is defensively timeout-degraded**
- **Found during:** Task 3 (the two live ribbon/mastery `AsyncNotifier`s now need `childProfileId`)
- **Issue:** Reading `childProfileProvider.future` in the notifier `build()` could hang in a headless test env (the platform-channel-hang case the file's own `progressionProvider` already guards with a 3s timeout + fallback).
- **Fix:** Added a shared `_resolveChildProfileId(ref)` helper applying the SAME T-05-07 degradation (3s timeout → `kUnassignedChildProfileId` on miss/error/hang), so the ribbon/unlock streams never hang or error out. Consistent with the file's established defensive posture; `ref.watch` keeps the dependency live so streams re-key if the profile resolves later.
- **Files modified:** `lib/providers/progression_providers.dart`
- **Committed in:** `c96cbf3`

## Issues Encountered

- **`test/spike_genui/durable_layers_unchanged_test.dart` went RED mid-task, GREEN on commit** — the Phase-11 throwaway spike guard runs `git diff --quiet HEAD -- lib/features/letter_unit/` (a WORKING-TREE check). It reported the uncommitted Task-3 edits to `letter_unit_controller.dart`/`letter_unit_screen.dart` as a "durable layer change" while uncommitted; it returned GREEN automatically once `c96cbf3` landed those edits into HEAD (verified: `+2 All tests passed!` post-commit). Not a regression — an in-flight-working-tree artifact.

## Out-of-Scope / Pre-existing (NOT fixed — logged to deferred-items.md)

The full client suite has 8 remaining failures, ALL pre-existing and independent of the keying migration (my working tree touches zero curriculum/golden files):
- **Documented goldens/cluster (6):** `alif_reference_test` (2), `reference_overlay_golden_test`, `glyph_audit_golden_test`, `meet_section_test` (img.door), `mastery_celebration_golden_test` — font-drift goldens + the obsolete img.door assertion (MEMORY: don't re-bake).
- **Exercise-count drift (2):** `curriculum_repository_v2_test` + `all_letters_validation_test` expect 51 bundled configs but HEAD ships 52 (the 19-05 micro-drill re-add, `dc45ba6`). Curriculum-data assertions owned by a curriculum plan / the phase verifier; `git diff HEAD -- assets/curriculum/ lib/curriculum/` over the 19-06 tree is empty.

## User Setup Required

None — no packages added, no external service configuration. Device UAT of two-profiles-on-one-tablet remains the end-of-phase human gate.

## Next Phase Readiness

- **QP-09 + QP-10 complete.** The profile-resume leak is closed as an identity rule; five progress tables are keyed by `(childProfileId, letterId)`, evidence carries `childProfileId`, `LetterReps` is dropped, and `childProfileId` is threaded + cached without crossing the wire.
- **ADR-018 governs future tables:** any new per-child progress table must carry `childProfileId` in its key (the rule that prevents the leak from recurring).
- **Do NOT re-bake goldens** (`alif_reference`, `reference_overlay`, `glyph_audit`, `mastery_celebration`) or touch `assets/curriculum/exercises.json` (the 52-vs-51 count is a curriculum-data / owner's-mother concern).

---
*Phase: 19-question-presentation-overhaul-every-question-self-explanato*
*Completed: 2026-07-18*

## Self-Check: PASSED

- Files: ADR-018, `child_profile_keying_test.dart`, and `19-06-SUMMARY.md` all FOUND.
- Commits: `ac32272` (Task 1), `f990b28` (Task 2), `c96cbf3` (Task 3) all FOUND.
