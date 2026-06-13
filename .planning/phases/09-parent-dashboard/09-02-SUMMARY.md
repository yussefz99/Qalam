---
phase: 09-parent-dashboard
plan: 02
subsystem: parent-security-data
tags: [flutter, drift, riverpod, crypto, pbkdf2, pin, security, tdd-green, read-only]

# Dependency graph
requires:
  - phase: 09-parent-dashboard
    plan: 01
    provides: Wave-0 RED contract (pin_service_test.dart + app_database_test.dart accessor assertions) + 17 ARB keys
  - phase: 06-journey-progression
    provides: AppDatabase LetterMastery/LetterReps tables + the shared-in-memory simulated-restart (D-09) test shape
provides:
  - PinService — salted PBKDF2-HMAC-SHA256 PIN hash/verify (constant-time compare) + a Drift-PERSISTED brute-force cooldown that survives force-quit
  - pinServiceProvider (@Riverpod keepAlive — codegen allowed; no Drift-typed return)
  - AppDatabase.allMastered() / allInProgress() — read-only aggregate accessors (no write/edit/delete path)
  - ParentProgress + ParentLetterRow immutable view model (const ctors, status enum, named factories)
  - crypto ^3.0.7 runtime dependency (human-approved legitimacy gate)
affects: [09-03-parent-gate-and-dashboard]

# Tech tracking
tech-stack:
  added:
    - "crypto ^3.0.7 (pub.dev, dart.dev first-party) — SHA-256/HMAC primitives for the hand-rolled PBKDF2 loop"
  patterns:
    - "Hand-rolled PBKDF2 iteration loop over crypto's Hmac(sha256) — single 32-byte block (dkLen==hLen), 100k iters; the hash function itself is never hand-rolled"
    - "Constant-time XOR-accumulate verify (no early-out) for the PIN compare (T-09-06)"
    - "Persisted cooldown over AppSettings k/v (failCount + lockUntil epoch-ms) — survives a simulated restart; NOT in-memory (Pitfall 1)"
    - "@Riverpod codegen is allowed for a service whose signatures return only bool/void/Duration (Drift-typed returns are what trip InvalidTypeException)"

key-files:
  created:
    - lib/features/parent/pin_service.dart
    - lib/features/parent/pin_service.g.dart
    - lib/features/parent/parent_progress.dart
  modified:
    - pubspec.yaml
    - pubspec.lock
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart

key-decisions:
  - "crypto (not cryptography) — smallest new surface; PBKDF2 hand-rolled over its HMAC (research recommendation, human-approved on the legitimacy gate)"
  - "No new Drift table and no schemaVersion bump (still 4) — all PIN material + cooldown live in the existing AppSettings keys parentPinHash/parentPinSalt/parentPinFailCount/parentPinLockUntil"
  - "flutter_secure_storage deliberately NOT added — a one-way PIN hash needs no recovery (T-09-08)"
  - "allInProgress() returns List<LetterRep> (the drift in-progress row class), allMastered() returns List<LetterMasteryData> — exact generated names verified against app_database.g.dart and the RED test"

requirements-completed: [S1-11]

# Metrics
duration: 7min
completed: 2026-06-13
---

# Phase 9 Plan 02: PIN Security Core + Read-Only Data Accessors Summary

**A pure-Dart PinService (salted PBKDF2-HMAC-SHA256 hash/verify with a constant-time compare and a Drift-persisted brute-force cooldown that survives a force-quit) plus two read-only aggregate accessors and an immutable ParentProgress view model — turning the 09-01 data-layer RED tests GREEN.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-06-13T21:23:49Z
- **Completed:** 2026-06-13T21:30:18Z
- **Tasks:** 3 (Task 1 = human-approved legitimacy gate; Tasks 2-3 implementation)
- **Files modified:** 7 (3 created, 4 modified)

## Accomplishments
- **crypto ^3.0.7 added** after the human-approved package-legitimacy gate (Task 1). dart.dev first-party; provides SHA-256 + HMAC (no built-in KDF — PBKDF2 is hand-rolled over its HMAC).
- **PinService** (`lib/features/parent/pin_service.dart`): `setPin`/`verify`/`isPinSet` over salted PBKDF2-HMAC-SHA256 (100k iters, `Random.secure()` 16-byte salt), with a **constant-time XOR-accumulate compare** (no early-out, T-09-06). The same PIN set twice yields different stored hashes (fresh salt).
- **Persisted brute-force cooldown** (`registerFailure`/`registerSuccess`/`remainingCooldown`): 5 wrong attempts → `parentPinLockUntil = now + 30s`, persisted in AppSettings — **survives a simulated restart** (a second AppDatabase over the same store still reports a positive cooldown). This is the phase's single most important security correctness point (T-09-02).
- **`pinServiceProvider`** via `@Riverpod(keepAlive)` — codegen is allowed because no signature returns a Drift data class.
- **Read-only accessors** on AppDatabase: `allMastered()` (ordered by masteredAt) and `allInProgress()` (cleanReps > 0). No write/edit/delete accessor was added to the parent surface (T-09-09, read-only hard constraint).
- **ParentProgress + ParentLetterRow** immutable view model with const constructors, a `ParentLetterStatus` enum (not a String), and `ParentLetterRow.mastered`/`.inProgress` named factories sourcing glyph + display name from `Letter.char` / `Letter.name.display`.

## Task Commits

Each implementation task was committed atomically:

1. **Task 1: crypto package legitimacy gate** — pre-approved by the human ("approved"); folded into the Task 2 commit (the install is `flutter pub add crypto`).
2. **Task 2: crypto + PinService (PBKDF2 + persisted cooldown)** — `0a68686` (feat)
3. **Task 3: read-only accessors + ParentProgress view model** — `65ccb80` (feat)

**Plan metadata:** committed separately (docs: complete plan).

## Files Created/Modified
- `lib/features/parent/pin_service.dart` (created) — salted PBKDF2 hash/verify + constant-time compare + persisted cooldown; pinServiceProvider; no-log convention enforced.
- `lib/features/parent/pin_service.g.dart` (created) — generated Riverpod provider part file.
- `lib/features/parent/parent_progress.dart` (created) — ParentProgress + ParentLetterRow + ParentLetterStatus immutable view model.
- `pubspec.yaml` / `pubspec.lock` (modified) — crypto ^3.0.7 added.
- `lib/data/app_database.dart` (modified) — allMastered() / allInProgress() read-only accessors.
- `lib/data/app_database.g.dart` (modified) — regenerated (LetterMasteryData/LetterRep already present; provider-hash sync).

## Decisions Made
- **`crypto` over `cryptography`** — smallest new dependency surface; the PBKDF2 loop is a dozen well-specified lines over `crypto`'s HMAC (the only thing worth hand-writing; the hash function itself is never hand-rolled). Human approved the legitimacy gate.
- **No schema bump (still v4)** — PIN material + cooldown live entirely in the existing `AppSettings` k/v table, so no new table and no migration.
- **`allInProgress()` returns `List<LetterRep>`** — the drift-generated in-progress row class is `LetterRep` (mastered rows are `LetterMasteryData`); names verified against `app_database.g.dart` and the RED test, matching the 09-01 correction.

## Deviations from Plan

None — plan executed exactly as written. Task 1's blocking-human legitimacy checkpoint was pre-resolved by the human ("approved", crypto confirmed dart.dev first-party on pub.dev), so execution proceeded straight through Tasks 2-3 without re-prompting, as instructed.

## Issues Encountered
None blocking. A benign drift "database created multiple times" debug warning appears in the persisted-cooldown restart test — that is the **intended** simulated-restart pattern (two AppDatabase instances over one shared in-memory executor, the D-09 shape), not a defect.

## Verification
- `flutter test test/services/pin_service_test.dart` → **GREEN** (8 tests: round-trip verify, wrong-PIN, hash≠plaintext, salt randomness, isPinSet, fresh-no-cooldown, registerSuccess-clears, 5-fail-cooldown-survives-restart).
- `flutter test test/data/app_database_test.dart` → **GREEN** (8 tests, incl. the two new allMastered()/allInProgress() accessor assertions).
- `flutter analyze lib/data/app_database.dart lib/features/parent/*.dart` → **No issues found.**
- grep: no `print`/`debugPrint` of pin/salt/hash anywhere in `pin_service.dart` (only the no-log comment mentions the words).
- `schemaVersion` is still **4** (no migration introduced).
- Full suite: **361 passing, 3 failing** — all 3 failures are out of scope and pre-existing/expected:
  - `mastery_celebration_golden_test.dart` — documented Phase 06-07 golden local-font pixel-drift (STATE.md caveat).
  - `parent_gate_test.dart` + `parent_dashboard_test.dart` — the Wave-0 RED tests for plan **09-03** (they import the not-yet-built `lib/providers/parent_providers.dart`); intentionally RED until 09-03.

## Known Stubs
None. PinService and the accessors are fully implemented production logic; the view model is a complete value type. Provider wiring for the dashboard (`parent_providers.dart`) and the screen are explicitly out of scope here — they land in 09-03.

## Threat Flags
None. No new security surface beyond the threat-modeled PIN gate was introduced. The read accessors are read-only by construction (no write/edit/delete path), and crypto crossed the build boundary through the planned, human-approved legitimacy gate.

## User Setup Required
None — `flutter pub get` already ran as part of `flutter pub add crypto`; no external service configuration.

## Next Phase Readiness
- **09-03** (Wave 2) builds `lib/providers/parent_providers.dart` (`parentGateProvider`/`ParentGate`, `parentProgressProvider` assembling `ParentProgress` from `curriculumRepository.getLetters()` + `allMastered()`/`allInProgress()`), the `ParentDashboardScreen`, the `/parent` route + redirect gate, and unlocks the Home nav "Parent" entry — turning `parent_gate_test.dart` and `parent_dashboard_test.dart` GREEN. All the data + security primitives it needs now exist.

## Self-Check: PASSED

All 3 created files exist on disk; both task commits (`0a68686`, `65ccb80`) are present in git history.

---
*Phase: 09-parent-dashboard*
*Completed: 2026-06-13*
