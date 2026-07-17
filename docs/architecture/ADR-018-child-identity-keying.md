# ADR-018: Child identity is a first-class keying rule — account uid selects the DB file, childProfileId selects the child inside it, and every progress table carries childProfileId

**Status:** ACCEPTED (owner, 2026-07-18 — the Phase-19 D-13 decision date). The rule was
reframed with the owner from "patch the profile-resume bug" to "make child identity a
first-class schema rule" at the `/gsd-plan-phase 19` context gate and recorded in
[`19-CONTEXT.md`](../../.planning/phases/19-question-presentation-overhaul-every-question-self-explanato/19-CONTEXT.md)
§ Decisions (D-13..D-17, D-20).
**Supersedes:** the implicit pre-Phase-19 convention that a per-child progress table could be
keyed by `letterId` alone. That convention leaked across profiles: a fresh child in the same
account file read the previous child's graph cursor / mastery because the key omitted the child
dimension.
**Amends:** nothing in the wire/tutor spine. This ADR is **client-local persistence only**; it
adds **no** wire field and does **not** touch [`ADR-017`](ADR-017-scorer-owns-verdict-derived-facts.md).
**Affects:** [`lib/data/app_database.dart`](../../lib/data/app_database.dart) (schema v7: the four
per-child progress tables re-keyed by `(childProfileId, letterId[, exerciseId])`,
`LetterCriterionEvidence` gains a filtered `childProfileId` column, the legacy `LetterReps` table
dropped, one `v6→v7` `TableMigration`), the five repositories over those tables
([`graph_position_repository`](../../lib/data/graph_position_repository.dart),
[`arc_state_repository`](../../lib/data/arc_state_repository.dart),
[`evidence_repository`](../../lib/data/evidence_repository.dart),
[`drift_progress_repository`](../../lib/data/drift_progress_repository.dart) +
[`progress_repository`](../../lib/data/progress_repository.dart) interface), and the writers over
them ([`LetterUnitController`](../../lib/features/letter_unit/letter_unit_controller.dart),
`practice_providers`, `progression_providers`, `parent_providers`). Closes Phase-19 requirements
**QP-09** (per-child cursors) and **QP-10** (the identity-model ADR) with the v6→v7 migration and
the 19-01 two-profile migration test.

---

## Context

The device already isolates one Firebase **account** into its own on-device SQLite file:
`AppDatabase.forAccount(uid)` opens `qalam_account_<sha256(uid)>.db`, and `appDatabaseProvider`
rebuilds (and `close()`s the old file) only when the stable account identity changes (a bare token
refresh keeps the same uid → same file). Two parents on one tablet never share a file. That seam is
correct and **stays untouched** by this ADR.

The bug this ADR fixes lives **inside** one account file. The per-child progress tables
(`LetterMastery`, `LetterGraphPosition`, `LetterExerciseReps`, `ArcStateRows`,
`LetterCriterionEvidence`) were keyed by `letterId` (or a `letterId`-composite / a surrogate id) with
**no child dimension**. `ChildProfiles.id` (an autoincrement surrogate) identifies the child inside
the file, but the progress rows never referenced it. So when a second child profile was created in
the same account file — `createProfile` deletes the single old profile row and inserts a new one,
which (autoincrement never reuses) gets a **new** `id` — the new child read `getPosition('baa')` and
got the **previous** child's cursor, mastery, and remediation arc. The owner's device UAT surfaced
this as "the new profile starts where the old child left off"; the only workaround was
delete-and-reinstall.

The owner explicitly rejected a narrow patch ("just add the key to the resume table") because it
would leave the schema **half-keyed and fragile** — the next table added would repeat the leak. The
resolution was to make child identity a **written rule** that every current and future progress
table must follow.

### Verified drift 2.31.0 `TableMigration` API (recorded before schema code, per A4)

Adding `childProfileId` to a table's **primary key** is not an `ALTER TABLE ADD COLUMN` — SQLite
cannot alter a primary key in place, so the table must be recreated and its rows copied. Drift's
`Migrator.alterTable(TableMigration(...))` runs SQLite's recommended 12-step
recreate-and-copy procedure. The exact 2.31.0 signature (read from the installed package source,
`drift-2.31.0/lib/src/runtime/query_builder/migration.dart`) is:

```dart
TableMigration(
  TableInfo affectedTable, {                              // positional — the table to recreate
  Map<GeneratedColumn, Expression> columnTransformer = const {},
  List<GeneratedColumn> newColumns = const [],
})
```

Semantics confirmed from the `alterTable` implementation:

- `alterTable` recreates `affectedTable` **from the current (Dart-defined, i.e. v7) schema** — the
  new primary key is whatever the v7 table class declares — then copies every old row into it.
- For a column that is **new** in v7 (listed in `newColumns`), the copy uses
  `columnTransformer[column]` as the `SELECT` expression. A `Constant<int>(profileId)` backfills the
  adopted child id onto every existing row.
- A `newColumns` entry that has no table-level default value **must** appear in `columnTransformer`
  (the constructor asserts this), so the backfill is explicit and cannot be silently skipped.
- Columns that are **not** new are copied straight across, unchanged.

This is the API Phase-19's v6→v7 migration is written against — a verified signature, not a guess.

---

## Decision

### 1. The identity rule (D-13)

Child identity is a two-level key, and it is now a rule, not a convention:

1. **Account uid → which family's database file.** The (non-anonymous) account uid selects the
   `qalam_account_<sha256(uid)>.db` file via `AppDatabase.forAccount`. This is the cross-account
   isolation seam and is unchanged.
2. **`childProfileId` (`ChildProfiles.id`) → which child inside that file.** Every table that records
   a child's **progress** MUST carry `childProfileId` in its key (or, for a surrogate-keyed table, as
   a mandatory filtered column). No progress read or write may omit it.

The rule is prospective: any future progress table starts correct — it carries `childProfileId` from
its first migration — instead of repeating the leak.

### 2. Scope of the v6→v7 re-key (D-14, A3)

Five tables gain `childProfileId`:

- **Primary-key re-key (four tables).** `LetterMastery → {childProfileId, letterId}`,
  `LetterGraphPosition → {childProfileId, letterId}`,
  `LetterExerciseReps → {childProfileId, letterId, exerciseId}`,
  `ArcStateRows → {childProfileId, letterId}`.
- **Filtered column, not PK (one table).** `LetterCriterionEvidence` keeps its autoincrement
  surrogate `id` as the primary key (append-only evidence rows need a stable surrogate, A3) and gains
  `childProfileId` as a **required column** that every read filters by and every append stamps.

`ChildProfileMirror` is **not** in scope — see §5 (D-17).

### 3. Adoption, not reset (D-16, D-20)

The migration reads the single existing profile id (`SELECT id FROM child_profiles LIMIT 1`; a
sentinel `0` when no profile exists yet) and backfills it onto every existing progress row via the
`Constant<int>` column transformer. **Whoever was practicing keeps every bit of progress** — no
reset, no parent prompt, no delete-and-reinstall. A profile created *after* the migration gets a new
`ChildProfiles.id`, so its reads (filtered by that new id) find **no** rows and it starts clean at
the opening — the cross-profile leak is closed structurally. Orphaned rows from a replaced profile
are **left in place** (D-20 — no cleanup this phase; they are unreachable because no read matches
their stale `childProfileId`).

### 4. `LetterReps` is retired in the same migration (D-15)

There is now **one** way to count reps — `LetterExerciseReps`. The legacy per-letter `LetterReps`
table and its `AppDatabase` accessors (`setCleanReps` / `getCleanReps` / `watchCleanReps` /
`allInProgress`) are removed. Its three live readers (the journey ribbon, the parent-dashboard
in-progress list, and the `/practice` resume + write-through) were folded onto a `MAX`-aggregate over
`LetterExerciseReps` in Plan 19-04 **before** this drop, so retiring the table changes no live
behavior. The v6→v7 migration `DROP`s `letter_reps`.

### 5. The cloud model stays account-level (D-17 deferral)

`child_models/{uid}` (the Firestore compiled-profile doc) and its on-device
`ChildProfileMirror` (uid PK) **keep their uid key** and are explicitly **out of scope** for the
per-child re-key. The per-child cloud dimension (a `childProfileId` in the profile doc / the mirror /
the wire / the nightly compiler / the security rules) is **deferred until multi-profile is a real
feature** — the owner has deprioritized multi-profile (2026-07-16). When multi-profile ships, this
same identity rule extends to the cloud model; until then, the account-level mirror is the correct,
smaller surface.

### 6. `childProfileId` is client-local and never crosses the wire (ADR-017 boundary)

`childProfileId` is a local SQLite integer surrogate. It is **not** PII and it is **not** a stable
cross-device identity — but the [ADR-017](ADR-017-scorer-owns-verdict-derived-facts.md) boundary is
absolute regardless: only derived, non-PII, fixed-vocabulary facts cross the client→server boundary.
`childProfileId` MUST NOT be added to `TutorFacts`, the coach payload, `evidenceDigest`, or any other
wire field. The existing non-PII payload guard tests
([`test/tutor/payload_nonpii_test.dart`](../../test/tutor/payload_nonpii_test.dart),
[`server/tests/test_payload_nonpii.py`](../../server/tests/test_payload_nonpii.py)) stay green — the
re-key adds no wire field. The child dimension is an **in-file persistence** concern only.

---

## Consequences

**Good**

- The profile-resume leak is closed as an identity **rule**, not a patch: two profiles on one tablet
  keep separate cursors, mastery, and remediation arcs (QP-09 success criterion 4), and every future
  progress table starts correct.
- No progress loss on upgrade — existing rows are adopted into the current profile (D-16).
- The schema is simpler: one rep counter (`LetterExerciseReps`), the legacy `LetterReps` gone.
- Zero wire-surface change — the ADR-017 non-PII boundary is untouched.

**Bad / accepted costs**

- The v6→v7 migration recreates four tables (SQLite's 12-step procedure via `TableMigration`). It is
  the phase's highest-risk change; it is gated by the 19-01 two-profile temp-file migration test
  (rows survive, a fresh profile reads clean, `LetterReps` is dropped, the migration is idempotent).
- Orphaned rows from a replaced profile persist in the file (D-20) — unreachable, but not cleaned up
  this phase.
- The cloud model stays account-level; multi-profile cloud sync is deferred (D-17). Accepted — the
  owner deprioritized multi-profile.

## Revisit triggers

- **Multi-profile becomes a real feature** → extend this identity rule to the cloud model:
  `childProfileId` in the profile doc / `ChildProfileMirror` / the wire / the nightly compiler / the
  Firestore rules (lifts the D-17 deferral).
- **A profile-management UI ships** (create / switch / delete profiles) → add orphan cleanup for a
  deleted profile's rows (lifts D-20's "leave orphans in place").

## Seam impact

- `AppDatabase` keyed accessors take a `required int childProfileId` and filter/write by it; the
  five repositories thread it through; `LetterUnitController` resolves it **once** at `start()` and
  caches it in a field — never an async provider read on the scored-feedback hot path (Pitfall 4).
- `AppDatabase.forAccount` / the per-account sha256 db-file seam is preserved unchanged;
  `childProfileId` is strictly the in-file child dimension layered beside it.
