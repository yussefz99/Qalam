---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 06
subsystem: database
tags: [wire-contract, non-pii, child-model, firestore-first, drift-mirror, across-session-memory, offline-first, riverpod, 422-lockstep]

# Dependency graph
requires:
  - phase: 18
    plan: 01
    provides: "the RED contract this plan greens — payload_nonpii (missing TutorFacts.profile/evidenceDigest params) + across_session_memory (missing TutorFacts.profile wire field); both re-green by SHIPPING the fields with ZERO test edits"
  - phase: 18
    plan: 03
    provides: "the Drift v6 primitives this plumbs — getProfileMirror/setProfileMirror (D-16 boot mirror), getArcStateRow/setArcStateRow (D-12 resume), unsyncedEvidence/appendEvidence/clearEvidence (D-14 digest queue)"
  - phase: 18
    plan: 04
    provides: "the pure value types the repos map to — ChildModelSnapshot (.toMap wire mirror), ArcState (+ArcStep), SelectionPolicy.narrow consuming profile.struggles"
  - phase: 18
    plan: 05
    provides: "the SERVER half of the wire — TutorFactsIn.profile (ChildProfileIn) + evidenceDigest (EvidenceDigestRowIn), additive/defaulted/extra=forbid — the byte-for-byte contract this client mirror copies (server ships FIRST, client SECOND)"
  - phase: 15
    provides: "the Firestore-first one-shot .get() + .withFirestore seam idiom (curriculum_repository) + the Drift-primitive↔pure-value-type bridge (graph_position_repository)"
provides:
  - "TutorFacts.profile (Map {strengths,struggles,perCriterion,schemaVersion}) + TutorFacts.evidenceDigest (rows {letter,criterion,pass,fail}) — emitted omit-when-null, key names byte-for-byte matching server/app/schema.py (the CLIENT half of the 422 lockstep, SECOND)"
  - "ChildModelRepository — Firestore-first (one-shot child_models/{uid}.get() write-through) with a Drift-mirror fallback that reads synchronously at boot and NEVER blocks the practice path; a permission-denied/offline/malformed refresh keeps the last-known mirror (D-16 / Req 6 / T-18-06-02)"
  - "ArcStateRepository (Drift ArcStateRow ↔ pure ArcState resume cursor, D-12) + EvidenceRepository (unsynced Drift evidence → {letter,criterion,pass,fail} digest + clearSynced rollup cap, D-14)"
  - "child_model_providers.dart — hand-written keepAlive Providers for the three repos + a hand-written FutureProvider (childModelProvider) that reads the mirror then fires refresh fire-and-forget (Pitfall 6 avoided, no StreamProvider.future)"
affects: [18-07, 18-09, 18-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Server-first / client-second additive wire field (omit-when-null, byte-for-byte key mirror) — the 422 lockstep completed on the Dart side (15-04/17-06 discipline)"
    - "Firestore-first one-shot .get() with a Drift-mirror fallback that NEVER blocks the practice path — boot reads the mirror synchronously, refresh is fire-and-forget (D-16 non-blocking read)"
    - "Hand-written FutureProvider for a Drift-adjacent read (Pitfall 6 / Phase-05 childProfileProvider precedent) — never @riverpod codegen, never StreamProvider.future"
    - "Thin repository bridge: raw Drift rows ↔ pure lib/curriculum value types, keeping the DB layer type-cycle-free (15-04 precedent)"

key-files:
  created:
    - lib/data/child_model_repository.dart
    - lib/data/arc_state_repository.dart
    - lib/data/evidence_repository.dart
    - lib/tutor/child_model_providers.dart
    - test/data/child_model_repository_test.dart
  modified:
    - lib/tutor/tutor_facts.dart
    - lib/tutor/tutor_facts_builder.dart

key-decisions:
  - "TutorFacts.profile is a Map<String,Object?>? and evidenceDigest a List<Map<String,Object?>>? — both emitted omit-when-null so an unchanged payload byte-matches the prior shape; the key names + nested keys mirror server/app/schema.py TutorFactsIn.profile/evidenceDigest byte-for-byte (client SECOND, single re-deploy gated at 18-11)"
  - "buildTutorFacts threads profile/evidenceDigest as pure pass-through OPTIONAL params (from the ChildModelSnapshot mirror + the Drift evidence digest) — NO new stroke/Offset/PII parameter; the signature stays the non-PII guard"
  - "ALL provider wiring is hand-written in child_model_providers.dart (keepAlive Provider for each repo + a FutureProvider for the mirror) — the repo files are plain classes with NO @riverpod codegen, so no .g.dart is generated and the Pitfall-6 InvalidTypeException is impossible by construction"
  - "ChildModelRepository resolves FirebaseFirestore LAZILY (curriculum_repository idiom) so the offline get() path never constructs FirebaseFirestore.instance; the .withFirestore seam runs the refresh against a FakeFirebaseFirestore in tests"
  - "The 18-03 ArcStateRows table persists only the OBSERVABLE resume cursor (active/step/targetCriterion/exerciseToRetry), not failStreak/attempts — so ArcStateRepository maps those in-session counters to 0 on resume (re-accumulated by SelectionPolicy); the faithful bridge for the shipped schema, not a data loss bug"

patterns-established:
  - "The returning-child memory loop is now wired end-to-end on the CLIENT: the compiled profile mirrors into Drift at boot and rides the next session's TutorFacts.profile, while the boot read stays instant and offline-safe"
  - "A .withFirestore-seam repository proven with fake_cloud_firestore (happy paths) + a throwing mocktail mock (the permission-denied error path) — the offline-safe fallback is falsifiable"

requirements-completed: []

# Metrics
duration: 9min
completed: 2026-07-11
---

# Phase 18 Plan 06: Client Profile/Evidence Wire + Child-Model Repository Summary

**The CLIENT half of the wire now carries the final 422-safe shape — `TutorFacts` gains `profile` + `evidenceDigest` (omit-when-null, byte-for-byte mirroring server/app/schema.py, client SECOND) — and the returning-child memory is wired end-to-end on-device: `ChildModelRepository` reads the compiled profile Firestore-first with a Drift-mirror fallback that reads synchronously at boot and NEVER blocks the practice path, plus the thin arc-state / evidence repositories bridging the Drift primitives (18-03) to the pure value types (18-04).**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-07-11T11:23:39Z
- **Completed:** 2026-07-11T11:31:43Z
- **Tasks:** 2
- **Files modified:** 7 (5 created, 2 modified)

## Accomplishments

- **Wire contract client-half (Task 1, D-14/D-16):** `TutorFacts` gains `profile` (a fixed-vocabulary Map `{strengths,struggles,perCriterion,schemaVersion}` = `ChildModelSnapshot.toMap()`) and `evidenceDigest` (rows `{letter,criterion,pass,fail}`). BOTH emitted omit-when-null in `toMap()` so an unchanged payload byte-matches the prior shape; the key names + nested keys mirror `server/app/schema.py` `TutorFactsIn.profile`/`evidenceDigest` byte-for-byte (the server shipped FIRST in 18-05, the client is SECOND). `buildTutorFacts` threads both as pure pass-through OPTIONAL params — NO new stroke/Offset/PII parameter, so the signature stays the non-PII guard. `payload_nonpii_test` (whitelist + nested-key sets) and `across_session_memory` test 1 turn GREEN with zero test edits.
- **ChildModelRepository (Task 2, D-16, non-blocking):** `get(uid)` reads the Drift `ChildProfileMirror` synchronously and returns the last-known `ChildModelSnapshot` (offline-safe, never a Firestore call); `refresh(uid)` does a ONE-SHOT `child_models/{uid}.get()` and write-throughs the mirror on a non-empty doc — a permission-denied / offline / malformed read is swallowed and the last-known mirror is kept (never throws, never blocks; T-18-06-02). A lazy `FirebaseFirestore` + a `.withFirestore` seam (fake_cloud_firestore) mirror the curriculum_repository idiom.
- **Arc/evidence bridges + hand-written providers (Task 2):** `ArcStateRepository` maps the Drift `ArcStateRow` ↔ the pure `ArcState` resume cursor (D-12); `EvidenceRepository` drains the unsynced Drift evidence into the fixed-vocabulary `{letter,criterion,pass,fail}` digest and clears synced rows (the rollup cap, D-14/T-18-03-03). `child_model_providers.dart` holds hand-written keepAlive `Provider`s for the three repos + a hand-written `FutureProvider` (`childModelProvider`) that reads the mirror via `await repo.get(uid)` then fires `unawaited(repo.refresh(uid))` — no `@riverpod` on a Drift-adjacent read (Pitfall 6), never a `StreamProvider.future`.

## Task Commits

Each task was committed atomically (GREEN leg — the RED phase was authored in 18-01):

1. **Task 1: TutorFacts +profile +evidenceDigest + non-PII guard extend (D-14)** — `b0e5af3` (feat)
2. **Task 2: ChildModelRepository (Firestore-first + Drift mirror, D-16) + arc/evidence repos** — `5b495e6` (feat)

**Plan metadata:** (this docs commit)

_Both tasks are `tdd="true"`: the RED phase was authored in 18-01; this plan is the GREEN leg (feat commits turning the existing tests green, zero test edits)._

## Files Created/Modified

- `lib/tutor/tutor_facts.dart` — `profile` (Map) + `evidenceDigest` (list of rows) fields + omit-when-null emission in `toMap()`, byte-for-byte mirroring `server/app/schema.py`
- `lib/tutor/tutor_facts_builder.dart` — `profile`/`evidenceDigest` threaded as pure pass-through OPTIONAL params (no PII-capable parameter added)
- `lib/data/child_model_repository.dart` (NEW) — Firestore-first + Drift-mirror `ChildModelRepository` (get = sync mirror read; refresh = one-shot .get() write-through, never throws/blocks); `.withFirestore` seam; lazy Firestore
- `lib/data/arc_state_repository.dart` (NEW) — Drift `ArcStateRow` ↔ pure `ArcState` resume-cursor bridge (D-12)
- `lib/data/evidence_repository.dart` (NEW) — unsynced Drift evidence → `{letter,criterion,pass,fail}` digest + `clearSynced` rollup cap (D-14); `EvidenceDigest` carries rows + source ids
- `lib/tutor/child_model_providers.dart` (NEW) — hand-written keepAlive `Provider`s for the repos + hand-written `FutureProvider` `childModelProvider` (mirror read, then fire-and-forget refresh)
- `test/data/child_model_repository_test.dart` (NEW) — 6 tests: cold-boot empty read, write-through refresh, missing-doc keeps mirror, permission-denied never throws/keeps mirror, arc round-trip, evidence digest aggregate + clear

## Decisions Made

- **All providers are hand-written in `child_model_providers.dart`; the repo files carry NO codegen.** The plan sketched a `@Riverpod` provider in the repository file, but consolidating every provider (repos + `childModelProvider`) as hand-written keepAlive `Provider`/`FutureProvider` (a) honors the must-have literally ("a hand-written FutureProvider … NOT @riverpod codegen"), (b) makes the Pitfall-6 `InvalidTypeException` impossible by construction, and (c) needs no `build_runner` run for the new files. See Deviations.
- **The 18-03 `ArcStateRows` schema persists only the observable resume cursor.** `ArcStateRepository` maps `active`/`step`/`targetCriterion`/`exerciseToRetry` back to `ArcState`; the un-persisted `failStreak`/`attempts` default to 0 (re-accumulated in-session by `SelectionPolicy`). This is the faithful bridge for the shipped 18-03 table — not a data-loss bug.
- **Requirements SPEC-18-R2 / SPEC-18-R6 NOT checkbox-marked.** This plan lands the CLIENT wire + repository half. R2 (across-session memory) is not delivered end-to-end until the nightly compiler (18-09) writes the `child_models/{uid}` doc AND the single Cloud Run re-deploy (18-11) goes live; R6 (offline-safe non-blocking selection) is completed by the selector wiring (18-07). Following the strong phase precedent (18-01/18-03/18-04/18-05 left `requirements-completed: []` at every foundation/leg plan; STATE: "R1..R9 NOT checkbox-marked"), the plan landing the final leg (or the phase verifier) flips them.

## Deviations from Plan

### Reconciled

**1. [Rule 3 - Blocking] Provider wiring consolidated into `child_model_providers.dart` (no `@riverpod` in the repo files)**
- **Found during:** Task 2
- **Issue:** The plan's `<read_first>`/`<action>` sketch left a `@Riverpod(keepAlive)` `childModelRepository` provider in `child_model_repository.dart`; the must-have + acceptance grep require the providers to be HAND-WRITTEN in `child_model_providers.dart` with NO `@riverpod` on a Drift-adjacent provider (Pitfall 6). A codegen provider in the repo file would also require a `.g.dart` build_runner pass.
- **Fix:** Removed the `@Riverpod`/`part`/`riverpod_annotation` from the repo files (they are now plain classes) and defined all four providers hand-written in `child_model_providers.dart` (three keepAlive `Provider`s + one `FutureProvider`).
- **Files modified:** lib/data/child_model_repository.dart, lib/tutor/child_model_providers.dart
- **Verification:** `flutter analyze` clean on all four files; the acceptance grep confirms `FutureProvider`/`Provider` only, no `@riverpod`, no `StreamProvider.future`.
- **Committed in:** `5b495e6` (Task 2 commit)

---

**Total deviations:** 1 reconciliation (Rule 3, blocking).
**Impact on plan:** The reconciliation honors the must-have + acceptance grep literally and removes a build_runner dependency. No scope creep — no new packages, no wire/schema change, all inside the planned files.

## Issues Encountered

- **One pre-existing baseline red in `test/data/curriculum_repository_v2_test.dart`** (`getExercises() … every((e) => e.signedOff == true)`, `Expected: true / Actual: <false>`) surfaces when running the whole `test/data/` suite. It is NOT caused by this plan — it is the documented alif-unsigned-exercise-forms failure (one of the phase's "748/8-known" baseline reds, already logged in the 18-03 and 18-04 summaries + `deferred-items.md`). It touches `assets/curriculum/exercises.json`, a surface this plan never modifies. Out of scope per the SCOPE BOUNDARY rule; left untouched. The rest of `test/data/` (incl. the new `child_model_repository_test` 6/6) is green.

## Known Stubs

None — `TutorFacts.profile`/`evidenceDigest`, `ChildModelRepository`, `ArcStateRepository`, `EvidenceRepository`, and the four providers are all fully implemented. `ChildModelSnapshot.empty()` on a cold boot is the intended neutral "no across-session signal" state (never a false struggle), not a stub. The provisional α/threshold constants (18-03) and the micro-drill copy / gold set (18-11) remain the tracked mother-sign-off pedagogy gates — unrelated to this plan's surface.

## Threat Flags

None — no security-relevant surface beyond the plan's `<threat_model>`. The new wire fields are omit-when-null, fixed-vocabulary, non-PII, and re-greened the extended `payload_nonpii` guard (T-18-06-01); the profile read only ever queries `child_models/{uid}` for the child's own uid (the owner-read rule shipped in 18-05, T-18-06-04); the refresh is off the practice path and keeps the last-known mirror on any error (T-18-06-02); the client ships SECOND, byte-for-byte after the server (T-18-06-03). No new package.

## Next Phase Readiness

- **18-07 (router wiring):** `RouterExerciseSelector` can now consume `SelectionPolicy.narrow` with the `childModelProvider` snapshot + persist `nextArc` via `arcStateRepositoryProvider` and `SessionAttempt` history — the returning-child memory is available on the client, ready to thread into the live path (live-path widget proof mandatory — the phase15-dynamic-selection dead-wire lesson).
- **18-09 (nightly compiler):** must write the `child_models/{uid}` profile doc (the owner-read rule permits the client read; `ChildModelRepository.refresh` mirrors it on the next boot) using the SAME `update_ema` the client uses.
- **18-11 (HUMAN-UAT + deploy):** the single Cloud Run re-deploy goes live now that BOTH wire sides (server 18-05 + client 18-06) carry `profile`/`evidenceDigest` byte-for-byte; the mother signs the provisional constants + micro-drill copy + gold set.
- No blockers. No new packages.

## Self-Check: PASSED

- All 5 created files present on disk (verified): `lib/data/child_model_repository.dart`, `lib/data/arc_state_repository.dart`, `lib/data/evidence_repository.dart`, `lib/tutor/child_model_providers.dart`, `test/data/child_model_repository_test.dart`.
- Both task commits present in git history: `b0e5af3`, `5b495e6`.
- Task 1 verify: `payload_nonpii_test` 4/4 GREEN. Task 2 verify: `child_model_repository_test` 6/6 + `across_session_memory` 2/2 GREEN; `durable_layers_no_agent_imports_test` 4/4 GREEN; full tutor selection + facts suite 29/29 GREEN. `test/data/` green except the single documented pre-existing alif-unsigned baseline red.

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-11*
