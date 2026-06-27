---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
plan: 04
subsystem: data-persistence
tags: [drift, tutor, resume, persistence, migration, wire-contract]

# Dependency graph
requires:
  - phase: 15-01
    provides: "the RED graph_position_repository_test (D-08 simulated restart) this plan turns GREEN, and the curriculum_graph asset whose competency/tier ids the cleared lists carry"
  - phase: 15-02
    provides: "the SERVER half of the wire contract — TutorFactsIn.clearedTiers/clearedCompetencies (extra=forbid); this plan ships the Dart mirror (the 422 lockstep)"
  - phase: 15-03
    provides: "GraphPosition (the cursor value type) + isMasteryMet (which consumes the per-exercise clean-reps this plan persists)"
  - phase: 14-tutor-grounded-agent-spine
    provides: "the LetterReps/LetterMastery Drift tables + version-guarded onUpgrade, the TutorFacts chokepoint + whitelisted toMap, the DriftProgressRepository thin-delegation idiom"
provides:
  - "lib/data/app_database.dart — LetterGraphPosition table (durable resume cursor) + LetterExerciseReps sibling table (per-essential-exercise clean-reps) + schemaVersion 5 + getPosition/setPosition + per-exercise reps accessors"
  - "lib/data/graph_position_repository.dart — GraphPositionRepository interface + DriftGraphPositionRepository (maps JSON-encoded cleared lists ↔ GraphPosition) + @Riverpod(keepAlive:true) provider"
  - "lib/tutor/tutor_facts.dart + tutor_facts_builder.dart — clearedTiers/clearedCompetencies as whitelisted non-PII string-list fields (the Dart side of the 422 wire contract)"
affects: [15-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Drift list column = JSON-encoded text + encode/decode in the accessors (no native list column, no extra package)"
    - "GraphPosition value type lives in the repository file (not app_database.dart) so the DB accessors stay primitive-typed — avoids a repo↔DB circular import"
    - "Open Q3 resolved with a SIBLING composite-PK table (LetterExerciseReps) rather than a PK change to LetterReps — a clean createTable add, zero data-migrating rebuild"

key-files:
  created:
    - lib/data/graph_position_repository.dart
  modified:
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart
    - lib/tutor/tutor_facts.dart
    - lib/tutor/tutor_facts_builder.dart
    - test/tutor/tutor_facts_builder_test.dart
    - test/tutor/payload_nonpii_test.dart
    - test/tutor/remote_agent_brain_test.dart

key-decisions:
  - "Open Q3 (per-exercise clean-reps for isMasteryMet): added a SIBLING LetterExerciseReps table with a (letterId, exerciseId) composite PK — NOT a PK change to the existing LetterReps. Rationale: changing LetterReps' PK forces a data-migrating table rebuild (Drift can't alter a PK in place); a new sibling table is a clean createTable that touches no existing rows (lower migration risk). The existing per-letter LetterReps in-progress counter stays untouched for the parent dashboard."
  - "GraphPosition is defined in graph_position_repository.dart (the test imports it from there), and the AppDatabase getPosition/setPosition accessors take/return PRIMITIVES (returning the generated LetterGraphPositionData row) — this avoids a circular import (the repo imports app_database.dart). The repo owns the GraphPosition ↔ row mapping."
  - "clearedCompetencies/clearedTiers persist as JSON-encoded List<String> in a text column (Drift has no native list column); _decodeStringList defaults to const [] on any malformed/empty value (never throws — clean default at the graph root)."
  - "schemaVersion 4→5; the v4→v5 onUpgrade is a pure createTable add inside the version-guarded if (from < 5) block (idempotent, Pitfall 4); a child with no position row reads null (clean start, no crash)."
  - "The Dart FACTS field names clearedTiers/clearedCompetencies mirror server/app/schema.py TutorFactsIn byte-for-byte (verified by reading both — Pitfall 1, the 422 trap)."

patterns-established:
  - "Drift list-column-as-JSON-text: encode on write, defensively decode on read (const [] on malformed) — the no-extra-package idiom for a List<String> column"
  - "Cross-plan wire-contract field added to BOTH the value type AND every exact-mirror test field-set assertion in the same task, so extra=forbid lockstep holds and the full suite stays green"

requirements-completed: [DYN-02]

# Metrics
duration: 10min
completed: 2026-06-27
---

# Phase 15 Plan 04: Drift Resume Persistence + the Dart Wire-Contract Mirror Summary

**A new Drift `LetterGraphPosition` table persists the child's graph position (current node + cleared competencies/tiers) so re-entering the baa unit restores it across an app restart (D-08), a sibling `LetterExerciseReps` composite-PK table persists per-essential-exercise clean-reps so `isMasteryMet` survives a relaunch (Open Q3), and `TutorFacts` gains `clearedTiers`/`clearedCompetencies` — the Dart half of the wire contract whose server half landed in 15-02 — turning the 15-01 RED `graph_position_repository_test` GREEN.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-06-27T15:05:54Z
- **Completed:** 2026-06-27T15:16:18Z
- **Tasks:** 2
- **Files modified:** 1 created, 7 modified (+ 2 generated `.g.dart`)

## Accomplishments

- **Resume is now durable (D-08).** A graph position written to one `AppDatabase` survives re-opening a second `AppDatabase` over the same store — the simulated restart in `graph_position_repository_test.dart` is GREEN. The in-memory `_resumeByLetter` map that was lost on restart now has its durable on-device replacement; the server stays stateless (COPPA posture), so this Drift state is the ONLY resume source. 15-05 reads it to drive the dynamic flow.
- **Open Q3 resolved without a risky migration.** The on-device star (`isMasteryMet`) needs clean-reps PER ESSENTIAL EXERCISE, but the existing `LetterReps` keys one count per letter. Rather than rebuild `LetterReps`' primary key (a data-migrating rebuild), a sibling `LetterExerciseReps` `(letterId, exerciseId)` composite-PK table was added — a clean `createTable` that touches no existing rows. `exerciseCleanRepsFor(letterId)` returns the exact `{exerciseId: cleanReps}` map `isMasteryMet` consumes.
- **The v4→v5 migration is version-guarded and idempotent (Pitfall 4).** Both new tables are created inside `if (from < 5)`; a child with no position row reads `null` (clean start at the graph root, never crashes). The existing `app_database_test.dart` migration tests (v2→v3, v3→v4) stay GREEN — prior tables intact.
- **The Dart side of the 422 wire contract landed (Pitfall 1).** `TutorFacts` carries `clearedTiers`/`clearedCompetencies` as pure non-PII string-list fields in its constructor AND its whitelisted `toMap`/`toJson`; `buildTutorFacts` accepts + threads them through (read from the Drift position on resume — trajectory replay). Field names mirror `server/app/schema.py` byte-for-byte, verified by reading both.

## Task Commits

Each task was committed atomically:

1. **Task 1: LetterGraphPosition + per-exercise reps (v4→v5) + GraphPositionRepository** — `980134b` (feat)
2. **Task 2: clearedTiers/clearedCompetencies on the non-PII FACTS (Dart side of the 422 lockstep)** — `f752290` (feat)

Plus one incidental-churn commit:

3. **chore: refresh app_router.g.dart provider hash (build_runner regen)** — `d46b764` (chore)

_Note: 15-04 is the GREEN side of the plan-level TDD cycle whose RED contract (`24be19f`, 15-01) authored `graph_position_repository_test.dart` first. See TDD Gate Compliance below._

## Files Created/Modified

- `lib/data/app_database.dart` (modified) — added `LetterGraphPosition` (letterId PK, currentExerciseId nullable, JSON-encoded clearedCompetencies/clearedTiers, updatedAt) + `LetterExerciseReps` ((letterId, exerciseId) composite PK, cleanReps, updatedAt); registered both in `@DriftDatabase(tables:[...])`; bumped `schemaVersion` 4→5; added `if (from < 5) { createTable(...) ×2 }` to the version-guarded onUpgrade; added `getPosition` (Future, not stream — Pitfall 6) / `setPosition` + `setExerciseCleanReps`/`getExerciseCleanReps`/`exerciseCleanRepsFor` accessors. `dart:convert` imported for jsonEncode.
- `lib/data/graph_position_repository.dart` (created) — `GraphPosition` value type (defined here to break the repo↔DB import cycle); `GraphPositionRepository` interface; `DriftGraphPositionRepository` thin delegation mapping JSON-encoded cleared lists ↔ `GraphPosition` (`_decodeStringList` defaults const [] on malformed); `@Riverpod(keepAlive:true)` provider reading `appDatabaseProvider`. Mirrors `DriftProgressRepository` exactly.
- `lib/tutor/tutor_facts.dart` (modified) — `clearedTiers`/`clearedCompetencies` as `final List<String>` (default const []) in the constructor, the fields, and the whitelisted `toMap`; doc comment updated 8→10 fields.
- `lib/tutor/tutor_facts_builder.dart` (modified) — `buildTutorFacts` accepts `clearedTiers`/`clearedCompetencies` params (default const []) and threads them through unmodifiable; the signature still accepts no stroke/Offset/profile param (the guard).
- `test/tutor/tutor_facts_builder_test.dart`, `test/tutor/payload_nonpii_test.dart`, `test/tutor/remote_agent_brain_test.dart` (modified) — extended the three exact-mirror field-set assertions to the 10-field contract (the 8 base + the 2 graph-position fields) and added the cleared fields to the populated-facts fixtures, so the full client suite stays GREEN under the enlarged `toMap`.

## Decisions Made

- **Open Q3 → sibling table, not a PK change.** A new `LetterExerciseReps` composite-PK table is a clean `createTable`; rebuilding `LetterReps`' PK would force a data-migrating rebuild. Lower migration risk; the per-letter `LetterReps` counter stays for the parent dashboard.
- **`GraphPosition` lives in the repository file** so the DB accessors stay primitive-typed (no repo↔DB circular import). The repo owns the JSON ↔ value-type mapping.
- **List columns are JSON-encoded text** (Drift has no native list column); decode defaults to `const []` on malformed/empty (never throws).
- **Field names verified byte-for-byte against the server** (`clearedTiers`/`clearedCompetencies`) to honor the `extra="forbid"` 422 lockstep.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking issue] Extended three exact-mirror field-set test assertions to the 10-field contract**
- **Found during:** Task 2.
- **Issue:** Three pre-existing GREEN tests pin the serialized `TutorFacts` field set to EXACTLY the 8 base fields: `tutor_facts_builder_test.dart` ("toJson mirrors the server TutorFactsIn field set exactly", line ~180 — **in this plan's own Task 2 verify command**), `payload_nonpii_test.dart` (the `==_whitelist` assertion + `_fullyPopulatedFacts`), and `remote_agent_brain_test.dart` (the `/coach` request-body key-set assertion). Adding `clearedTiers`/`clearedCompetencies` to `toMap` (required by the plan) makes `toJson` emit 10 keys, breaking all three — including Task 2's own verify, which CANNOT "stay GREEN" otherwise.
- **Fix:** Added the two new fields to each assertion's expected set and to the populated-facts fixtures. `tutor_facts_builder_test.dart` and `remote_agent_brain_test.dart` are 15-04's responsibility (the builder test is literally in my verify; the remote-agent test asserts the body 15-04 enlarges). `payload_nonpii_test.dart` is nominally owned by **15-05 Task 3** ("extend the non-PII regression"), but the per-wave merge (this plan's `<verification>`: full client suite green) requires it green NOW — so it was extended in place here. The change is the SAME one 15-05 Task 3 specifies (add the two fields to `_whitelist` + `_fullyPopulatedFacts`); 15-05 will find it already done (idempotent). Documented so 15-05 does not duplicate.
- **Files modified:** `test/tutor/tutor_facts_builder_test.dart`, `test/tutor/payload_nonpii_test.dart`, `test/tutor/remote_agent_brain_test.dart`
- **Commit:** `f752290`

**2. [Rule 3 — Blocking issue] Committed app_router.g.dart provider-hash churn**
- **Found during:** Task 1 (after `dart run build_runner build`).
- **Issue:** build_runner regenerated `lib/router/app_router.g.dart` with only a changed provider hash (the router source is unchanged) — incidental codegen drift unrelated to the task.
- **Fix:** Committed separately as `chore` to keep it out of the feat commits and leave no tracked-file drift. (Note: `.g.dart` files are TRACKED in this repo, NOT gitignored as the plan's note assumed — verified via `git check-ignore`.)
- **Commit:** `d46b764`

## Cross-Plan Deploy Lockstep (the 422 trap — Pitfall 1)

The server (`server/app/schema.py`) already declares `clearedTiers`/`clearedCompetencies` (landed in 15-02, `d4e76bc`). This plan ships the Dart mirror. **Server re-deploy ordering:** because the server side is backward-compatible (both fields default to `[]`) and the G5/G6 rail is a no-op on empty cleared-state (15-02 decision), a standalone server re-deploy is safe. The FORWARD trap is the one that bites: once the client sends these fields (this plan), the deployed `/coach` MUST already carry them under `extra="forbid"` or it 422s. **Recommended sequence (unchanged from 15-02's SUMMARY): 15-02 + 15-04 both landed → re-deploy the server → then run the on-device test.** 15-04 + 15-02 are now both landed; the server re-deploy + device test is the remaining gate (owned by the phase UAT, not this plan — no deploy in this autonomous slice).

## TDD Gate Compliance

15-04 is the GREEN side of a plan-level TDD cycle split across waves:
- **RED gate:** `24be19f` (15-01) — authored `graph_position_repository_test.dart` failing first (verified RED at execution start: `+1 -1`, the one failure being the missing `DriftGraphPositionRepository`/`GraphPosition` symbols).
- **GREEN gate:** `980134b` + `f752290` (this plan) — make the RED test pass.
- **REFACTOR gate:** none needed — minimal, clean on first pass (analyzer clean, no duplication).

The RED→GREEN sequence is present in git history. No warning needed.

## Authentication Gates

None. The work is on-device Drift code + a pure-Dart wire-contract field + offline `flutter test`; no auth, no network, no deploy in this plan.

## Known Stubs

None. The two new tables and the two FACTS fields are fully wired: `getPosition`/`setPosition` round-trip the position (proven by the GREEN restart test), and the cleared fields serialize into the live `/coach` body. The cleared lists default to `const []` for a fresh child — that is the designed clean-start-at-graph-root default (D-08), not a stub. The CONSUMERS of this persistence (the unit-level selection flow + the mastery-gated star) are 15-05's deliverable by design — this plan delivers the durable read/write seam they consume.

## Threat Surface

No new security-relevant surface beyond the plan's `<threat_model>`. All mitigations satisfied:
- **T-15-04-ID** (clearedTiers/clearedCompetencies leak PII): mitigated — both are derived string-lists of tier/competency ids; `buildTutorFacts` accepts no stroke/Offset/profile param (the guard); `payload_nonpii_test.dart` was extended to assert the two new fields carry no PII key (the `\b[xy]\b|stroke|offset|coord|point|raw|nick|name` regex) AND are in the whitelist. The Drift tables persist only ids/counts/timestamps.
- **T-15-04-DoS** (corrupt v4→v5 migration): mitigated — version-guarded idempotent onUpgrade (`if (from < 5)`); a child with no position row defaults to the graph root (getPosition null, no crash); `app_database_test.dart` covers the real-onUpgrade path and stays green.
- **T-15-04-T** (422 from un-mirrored FACTS field): mitigated — the two Dart field names mirror `server/app/schema.py` byte-for-byte (verified by reading both); the server re-deploy is gated to follow both sides landing (documented above).
- **T-15-SC** (pub installs): N/A — zero packages installed.

## Verification

- **Task 1:** `dart run build_runner build --delete-conflicting-outputs` regenerated cleanly (431 outputs). `flutter test test/data/graph_position_repository_test.dart test/data/app_database_test.dart` → **10 passed** (the 2 D-08 resume tests + the 8 app_database tests incl. the v2→v3 / v3→v4 idempotent-migration tests). `flutter analyze` over both Task 1 files → clean.
- **Task 2:** `flutter test test/tutor/tutor_facts_builder_test.dart` → **9 passed**; `flutter analyze lib/tutor/tutor_facts.dart lib/tutor/tutor_facts_builder.dart` → clean. Field names confirmed byte-for-byte against `server/app/schema.py`.
- **Per-wave merge:** `flutter test` (full client suite) → **+629 -7**. All 7 failures are pre-existing golden/data drift OR by-design Wave-0 RED owned by a later plan (`glyph_audit`, `reference_overlay`, `alif_reference`×2, `meet_section`, `mastery_celebration` = known font/data drift; `dynamic_selection_test` = compile-fail on 15-05's not-yet-built `exercise_selector_provider.dart`). NONE reference any symbol 15-04 changed (verified by grep). Logged in `deferred-items.md`.

## Next Plan Readiness

- **15-05** can now: read/write the durable `GraphPosition` via `graphPositionRepositoryProvider`; read per-exercise clean-reps via `exerciseCleanRepsFor`/`getExerciseCleanReps` to feed `isMasteryMet`; thread `clearedTiers`/`clearedCompetencies` from the Drift position into `buildTutorFacts` for trajectory replay. Its Task 3 (extend `payload_nonpii_test.dart`) will find the client side ALREADY extended here (idempotent) — it still owns the SERVER side (`server/tests/test_payload_nonpii.py`).
- **Deploy gate (phase UAT):** re-deploy the Cloud Run server BEFORE the on-device test, now that both wire-contract sides (15-02 server + 15-04 client) have landed (Pitfall 1).

## Self-Check: PASSED

All created/modified files verified on disk; all three commits (`980134b`, `f752290`, `d46b764`) verified in git history (see below).

---
*Phase: 15-build-dynamic-grounded-exercise-selection-on-baa*
*Completed: 2026-06-27*
