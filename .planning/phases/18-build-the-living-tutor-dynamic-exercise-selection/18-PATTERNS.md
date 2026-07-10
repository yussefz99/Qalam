# Phase 18: The Living Tutor — per-child dynamic exercise selection - Pattern Map

**Mapped:** 2026-07-11
**Files analyzed:** 22 create/modify surfaces (+ ~11 Wave-0 test files)
**Analogs found:** 22 / 22 (every surface has a concrete in-repo analog; 0 with no analog)

This phase is **composition over existing seams** — almost every new file copies a
shipped pattern. The pure-Dart selection brain slots behind the `RouterExerciseSelector`
accept-if-legal seam, evidence rides the already-initialized `firebase_admin` ADC, the
Drift tables reuse the `LetterGraphPosition` resume shape, the wire fields reuse the
Phase-17 additive/`extra=forbid` discipline, and the profile mirror reuses the
`CurriculumRepository` Firestore-first idiom. The planner should reference the analog
file + line ranges directly in each plan's action section.

---

## File Classification

| New/Modified File | New? | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|------|-----------|----------------|---------------|
| `lib/tutor/selection_policy.dart` | NEW | policy/service (pure Dart) | transform / event-driven | `lib/curriculum/curriculum_graph_walker.dart` + `lib/curriculum/curriculum_graph.dart` | role-match (pure-layer sibling) |
| `lib/core/scoring/criterion_ema.dart` | NEW | utility (pure algorithm) | transform | `lib/core/scoring/tolerances.dart` / `scoring_models.dart` (pure scorer helpers) | role-match |
| `lib/data/child_model_repository.dart` | NEW | repository | request-response (Firestore-first + Drift fallback) | `lib/data/curriculum_repository.dart` + `lib/data/child_profile_repository.dart` | exact |
| `lib/tutor/exercise_selector_provider.dart` | MOD | provider / router | request-response | itself (accept-if-legal seam) | exact (self-extend) |
| `lib/tutor/tutor_facts.dart` | MOD | model (wire DTO) | transform / wire | itself (Phase-17 `criteria`/`weakestCriterion` field-add) | exact (self-extend) |
| `lib/tutor/tutor_facts_builder.dart` | MOD | utility (non-PII chokepoint) | transform | itself (Phase-17 derive-from-result) | exact (self-extend) |
| `lib/curriculum/curriculum_graph_walker.dart` | MOD | service (offline selector) | transform | itself | exact (self-extend) |
| `lib/curriculum/curriculum_graph.dart` | MOD | model (graph parser) | transform | itself (microDrill = more nodes) | exact (self-extend) |
| `lib/data/app_database.dart` | MOD | store (Drift) | CRUD | itself (`LetterGraphPosition` v5 table + migration) | exact (self-extend) |
| `lib/features/letter_unit/widgets/exercise_scaffold.dart` (+ new margin/spotlight widgets) | MOD/NEW | component (UI) | event-driven / render | `_teacherEye()` strip + `AuthoredFallbackBrain` degradation | role-match |
| `server/app/schema.py` | MOD | model (wire contract) | wire | itself (Phase-17 `criteria`/`strokeDiff` additive fields) | exact (self-extend) |
| `server/app/evidence.py` | NEW | service (Admin-SDK write) | batch / CRUD (write) | `server/app/auth.py` (`firebase_admin` ADC init) | role-match |
| `server/app/criterion_ema.py` | NEW | utility | transform | Dart `criterion_ema.dart` (byte-identical mirror) | exact (cross-lang mirror) |
| `server/app/jobs/compile_profiles.py` | NEW | job (Cloud Run Job) | batch | `server/app/curriculum_data/generate.py` (module `__main__` entrypoint) + `auth.py` | role-match |
| `server/app/main.py` | MOD | controller (FastAPI route) | request-response | itself (`/coach` handler) | exact (self-extend) |
| `server/app/nodes/plan.py` | MOD | node / service (agent pick + rails) | transform | itself (G4/G5/G6 candidate guards) | exact (self-extend) |
| `server/app/curriculum_data/generate.py` | MOD | utility (derive-from-assets) | file-I/O / batch | itself | exact (self-extend) |
| `server/tests/test_eval/run_eval.py` | MOD | test harness | batch | itself (DIMENSIONS registry) | exact (self-extend) |
| `server/tests/test_eval/selection_gold_set.jsonl` | NEW | test fixture | batch | `server/tests/test_eval/gold_set.jsonl` | exact |
| `assets/curriculum/exercises.json` | MOD | config / content | file-I/O | itself (baa exercise shape) | exact (self-extend) |
| `assets/curriculum/curriculum_graph.json` | MOD | config / content | file-I/O | itself (baa enrichment node shape) | exact (self-extend) |
| `firestore.rules` | MOD | config / security | n/a | itself (deny-all catch-all) | exact (self-extend) |
| `test/tutor/*` + `test/core/scoring/criterion_ema_test.dart` (Wave 0) | NEW | test | transform / batch | `test/core/scoring/calibration_harness_test.dart`, `test/tutor/payload_nonpii_test.dart`, `test/tutor/durable_layers_no_agent_imports_test.dart` | role-match |

---

## Pattern Assignments

### `lib/tutor/selection_policy.dart` (NEW — policy/service, pure Dart)

The new pure-Dart brain: arc state machine + anti-boredom filter + micro-drill injection +
candidate narrowing (D-09/D-11). It returns `(legalCandidates, arcStep, targetCriterion,
whyFacts)` and both the online router and the offline walker consume it.

**Primary analog:** `lib/curriculum/curriculum_graph_walker.dart` (the pure offline selector
that adapts on the same `TutorFacts` + `GraphPosition` inputs). **Legality analog:**
`lib/curriculum/curriculum_graph.dart` `isLegalSelection`.

**Pure-layer citizen pattern** — copy the file-header contract from the walker
(`curriculum_graph_walker.dart` lines 1-16): "No cloud-AI / Firebase / network /
Flutter-render import." The policy imports only `tutor_facts.dart`, `tutor_decision.dart`,
`curriculum_graph.dart`. **Decision needed by planner:** the durable-layer guard
(`durable_layers_no_agent_imports_test.dart`) currently scans `lib/core, lib/features/practice,
lib/models, lib/data, lib/curriculum` — NOT `lib/tutor`. To keep `selection_policy.dart` pure,
either place it in `lib/curriculum/` (subject to the strict ban list) or add `lib/tutor/
selection_policy.dart` to the guard's scanned set (see Shared Patterns §Durable-layer purity).

**Signal source (anti-boredom + arc entry share ONE counter, D-02)** — read straight off
`TutorFacts.trajectory` (List<AttemptFact>) + `weakestCriterion`, already on-device
(`tutor_facts.dart` lines 116, 154). Reuse the `_deriveStruggleTags` "≥2 occurrences" idiom
so a one-off slip is not a struggle (`tutor_facts_builder.dart` lines 83-96):
```dart
// counts an id, then emits only ids seen >= 2 times, first-appearance order
if ((counts[id] ?? 0) >= 2 && seen.add(id)) tags.add(id);
```

**Legality re-check the policy must preserve** (`curriculum_graph.dart` lines 288-302):
```dart
bool isLegalSelection(String? exerciseId, {
    required List<String> clearedTiers,
    required List<String> clearedCompetencies}) {
  if (!isAuthored(exerciseId)) return false;
  final tier = tierOf(exerciseId!);
  if (tier != null && !reachableTiers(clearedTiers).contains(tier)) return false;
  return prerequisitesMet(exerciseId, clearedCompetencies);
}
```
Every candidate the policy emits MUST pass this gate; the policy narrows, it never replaces
the rail (D-09 trust boundary).

---

### `lib/tutor/exercise_selector_provider.dart` (MOD — provider/router, request-response)

**Analog:** itself. The extension point is the `RouterExerciseSelector.selectNext` accept-if-legal
body (lines 81-100). Today it accepts the agent's `plan.nextExerciseId` iff `isLegalSelection`.
Phase 18 threads the policy: compute candidates first, then accept the agent pick only if it is
BOTH a policy candidate AND graph-legal, else delegate to the walker over the SAME candidates.

**Current seam to wrap** (lines 87-99):
```dart
final proposed = decision?.plan?.nextExerciseId;
if (proposed != null &&
    graph.isLegalSelection(proposed,
        clearedTiers: position.clearedTiers,
        clearedCompetencies: position.clearedCompetencies)) {
  return proposed;                       // ONLINE: agent picked a graph-legal next
}
return _walker.selectNext(facts, position); // OFFLINE / illegal → deterministic walker
```

**Provider wiring pattern** (lines 50-55, 112-118): the graph loads via a `FutureProvider`
(`curriculumGraphProvider`, keepAlive), and `exerciseSelectorProvider` yields a `_PendingSelector`
no-op while it loads (never a crash). Any new profile-mirror dependency the policy needs must
follow Pitfall 6 — a plain `FutureProvider`, never a bare `StreamProvider.future` (which hangs
under Riverpod 3).

---

### `lib/tutor/tutor_facts.dart` (MOD — wire model) + `tutor_facts_builder.dart` (MOD — chokepoint)

**Analog:** itself. Phase 18 adds `profile` (compiled strengths/struggles/EMA mirror, Req 2) +
`evidenceDigest` (offline unsynced counts, D-14) fields. The Phase-17 `criteria`/`weakestCriterion`/
`strokeDiff` additions are the EXACT precedent to copy.

**Field-add + omit-when-null serialization** (`tutor_facts.dart` lines 139-149, 197-213):
```dart
// declare optional, nullable, mirroring the server TutorFactsIn field name byte-for-byte
final Map<String, Object?>? strokeDiff;
final List<Map<String, Object?>>? criteria;
final String? weakestCriterion;
// ... in toMap(): emit ONLY when present so an unchanged payload byte-matches the prior shape
if (strokeDiff != null) 'strokeDiff': strokeDiff,
if (criteria != null) 'criteria': criteria,
if (weakestCriterion != null) 'weakestCriterion': weakestCriterion,
```
New Phase-18 fields (`profile`, `evidenceDigest`) follow this shape: nullable/defaulted,
omit-when-absent, key name mirrors `server/app/schema.py` byte-for-byte.

**Derive-in-the-chokepoint, never a new PII-capable parameter** (`tutor_facts_builder.dart`
lines 40-77): Phase-17 `criteria`/`weakestCriterion` are read straight off the already-non-PII
`CheckResult` (lines 68-71), NOT via new stroke/Offset parameters — the signature stays the guard.
The `profile` mirror is threaded like `clearedTiers`/`clearedCompetencies` (lines 46-47, passed
straight through from the Drift mirror), and `evidenceDigest` is threaded from the Drift accrual —
both are pure non-PII id/count strings, so the "signature is the guard" invariant holds.

**Non-PII whitelist obligation:** both new keys must be added to `test/tutor/payload_nonpii_test.dart`
`_whitelist` (lines 27-66) with any nested keys guarded like `_criteriaKeys`/`_strokeDiffKeys`
(lines 73-94). See Shared Patterns §Non-PII wire guard.

---

### `lib/curriculum/curriculum_graph.dart` + `curriculum_graph_walker.dart` (MOD)

**Analog:** itself. **micro-drills are just more nodes (D-06)** — the `GraphNode` model
(`curriculum_graph.dart` lines 66-91) and defensive `_nodeFromJson` parse (lines 150-162) already
handle arbitrary nodes; a `microDrill`-competency node with `essential:false` is covered by
`essentialNodes` (lines 167-168, enrichment excluded from the star) and by `isLegalSelection`
with zero rail changes. The walker's fail path (`curriculum_graph_walker.dart` lines 90-103,
`_nextReachableForward` 108-123) is what the SelectionPolicy sits in front of — it consumes the
narrowed candidate set instead of raw `nextForward`/`remediateOneTier`.

---

### `lib/data/app_database.dart` (MOD — Drift store, schemaVersion 5→6)

**Analog:** itself. `LetterGraphPosition` (lines 82-107) + `LetterExerciseReps` (lines 109-130)
are the exact table shape for the three new tables (evidence accrual, arc state, profile mirror).

**Table + JSON-encoded list column idiom** (lines 98-107): Drift has no native list column, so
`clearedCompetencies`/`clearedTiers` are `text()` holding JSON. Copy for arc state
(`step`/`targetCriterion`/`exerciseToRetry`) and the profile mirror (JSON strengths/struggles/EMA):
```dart
TextColumn get clearedCompetencies => text()(); // JSON-encoded List<String>
```

**Additive version-guarded migration** (lines 132-195): register new tables in `@DriftDatabase`,
bump `schemaVersion` 5→6, add a version-guarded `createTable` block:
```dart
if (from < 5) {
  await m.createTable(letterGraphPosition);   // Phase 15 precedent
  await m.createTable(letterExerciseReps);
}
// Phase 18 adds: if (from < 6) { createTable(letterCriterionEvidence); arcState; childProfileMirror; }
```

**Accessor + JSON encode/decode pattern** (lines 355-378 `getPosition`/`setPosition`): one-shot
`Future` reads (Pitfall 6 — never a bare StreamProvider.future), `jsonEncode` on write. Copy for
arc-state get/set and profile-mirror get/set. Aggregate reads for the digest mirror
`exerciseCleanRepsFor` (lines 435-440, returns a `{id: count}` map).

**Account isolation is already handled** (lines 153-160, 481-509): `AppDatabase.forAccount(uid)`
sha256-namespaces the DB file per account — the new tables inherit per-uid isolation for free.

---

### `lib/data/child_model_repository.dart` (NEW — repository, Firestore-first + Drift fallback, D-16)

**Primary analog:** `lib/data/curriculum_repository.dart` (the Firestore-first-with-bundle-fallback
idiom). **Structural analog:** `lib/data/child_profile_repository.dart` (thin class + keepAlive
codegen provider).

**One-shot `.get()` Firestore-first, never a live stream** (`curriculum_repository.dart` lines
151-182, 358-389): a single `.get()`, non-empty → map, empty/throw → fallback. For D-16 the
fallback is the **Drift mirror** (not the bundle): boot reads the Drift mirror synchronously; a
background one-shot `.get()` refreshes it. Copy the try/catch-into-fallback shape:
```dart
try {
  final snap = await _firestore.collection('child_models').doc(uid).get();
  if (snap.exists) { /* map + write-through to Drift mirror */ }
} catch (_) { /* permission/offline → keep the Drift mirror (last-known) */ }
```

**CRITICAL anti-pattern (Req 6 / D-16):** never `await` this `.get()` on the selection/practice
path. Boot reads the Drift mirror; the refresh is fire-and-forget (RESEARCH Anti-Patterns +
Pitfall 1: the deny-all rules would silently block the read anyway until `firestore.rules` ships
the owner-read rule).

**Thin repo + provider** (`child_profile_repository.dart` lines 17-49): a class wrapping
`AppDatabase` accessors + `@Riverpod(keepAlive: true)` provider that watches `appDatabaseProvider`.
Copy verbatim. Riverpod-codegen chokes on a Drift-data-class-returning provider (Pitfall 6) — if a
provider must return the mirror row, hand-write a plain `FutureProvider`, not `@riverpod`.

---

### `server/app/schema.py` (MOD — wire contract, ships FIRST)

**Analog:** itself. The `TutorFactsIn` field-addition precedent (`criteria`/`strokeDiff`/
`legalNextExerciseIds`, lines 154-199) is exactly the shape for the new `profile` +
`evidenceDigest` fields.

**Additive + defaulted + `extra="forbid"` nested model** (lines 84-104 `CriterionIn`, 157-199):
```python
class CriterionIn(BaseModel):
    model_config = ConfigDict(extra="forbid")   # a stray coordinate key nested here 422s
    criterion: str = Field(...); zone: str = Field(...); score: float = Field(...)
# ... on TutorFactsIn — ALL optional/defaulted => strict-superset, no 422 window:
criteria: list[CriterionIn] = Field(default_factory=list, ...)
weakestCriterion: str | None = Field(default=None, ...)
```
New `profile`/`evidenceDigest` are their own `extra="forbid"` nested models (fixed-vocabulary,
non-PII), added `default=None`/`default_factory=...`. **Server ships FIRST** (the comment at lines
140-144, 162-169 spells the 422 lockstep). See Shared Patterns §422 lockstep.

---

### `server/app/main.py` (MOD — FastAPI route, evidence append at /coach, D-13)

**Analog:** itself. The `/coach` handler (lines 71-144) already receives the validated
`TutorFactsIn` and the decoded claims. The uid for evidence keying comes from `verify_caller`
(`_claims = Depends(verify_caller)`, line 74 — `verify_caller` returns the ID-token claims dict
containing `uid`; see `auth.py` lines 108-116).

**Off-critical-path write (RESEARCH Anti-Pattern — the write must NOT delay `CoachOut`):** add a
FastAPI `BackgroundTask` (or write after building `out`) so the child never waits on Firestore.
The existing diagnostic logging at lines 122-143 already derives non-PII criteria/strokeDiff from
`facts_in` — the evidence rows derive from the SAME `facts_in.criteria` + the new
`evidenceDigest`, then `append_evidence(uid, rows)`.

---

### `server/app/evidence.py` (NEW — Admin-SDK append, D-13)

**Analog:** `server/app/auth.py` (already initializes `firebase_admin` with ADC at import — lines
34-51). Firestore writes need **zero new packages**: `firebase_admin.firestore` ships in the
installed package.

**Append-only batch, auto-id (no hot doc)** — the shape from RESEARCH §Code Examples, grounded in
`auth.py`'s ADC init:
```python
from firebase_admin import firestore
def append_evidence(uid: str, rows: list[dict]) -> None:
    db = firestore.client()
    batch = db.batch()                                   # one round-trip, up to 500 ops
    col = db.collection("children").document(uid).collection("evidence")
    for r in rows:                                       # {letter, criterion, passed, source, ts, ttlAt}
        batch.set(col.document(), r)                     # auto-id → append-only, no contention
    batch.commit()
```
Reuse `auth.py`'s `_ensure_firebase_initialized` sentinel pattern (lines 42-47) — do NOT re-init;
the default app is already up at import.

---

### `server/app/criterion_ema.py` (NEW) ↔ `lib/core/scoring/criterion_ema.dart` (NEW)

**Analog:** each other — byte-identical logic so on-device (within-session) and nightly agree
(D-15). Pure functions, no framework import (Dart side is a durable-layer citizen under `lib/core`).
```python
def update_ema(prior: float, passed: bool, alpha: float) -> float:
    outcome = 1.0 if passed else 0.0
    return alpha * outcome + (1.0 - alpha) * prior
```
```dart
double updateEma(double prior, bool passed, double alpha) =>
    alpha * (passed ? 1.0 : 0.0) + (1.0 - alpha) * prior;
```
Cold-start prior 0.5; a criterion is "unknown" until `>= kMinAttempts` (mirror the
`_deriveStruggleTags` ≥2 rule). `alpha`/thresholds are provisional (`signed:false`, D-15/A4).
Unit-test BOTH sides against the SAME fixtures (`criterion_ema_test.dart` + `test_criterion_ema.py`).

---

### `server/app/jobs/compile_profiles.py` (NEW — Cloud Run Job, nightly EMA compile, Req 8)

**Analog:** `server/app/curriculum_data/generate.py` (a module `__main__` entrypoint in the same
image — lines 88-97) + `auth.py` (firestore/ADC). The Job reuses the existing `server/Dockerfile`
and ADC; a new entrypoint overrides the container command; Cloud Scheduler fires nightly.

**Module-entrypoint pattern** (`generate.py` lines 88-97): a `main()`/`regenerate()` + `if
__name__ == "__main__":` that reads a canonical source, computes, writes, and prints a summary.
The compile iterates evidence keys as `f"{letter}/{criterion}"` (letter-agnostic by construction —
a newly signed letter needs ZERO schema change, Req 8) and writes `child_models/{uid}` derived-only:
```python
db.collection("child_models").document(uid).set({
    "strengths": strengths, "struggles": struggles, "perCriterion": ema,
    "schemaVersion": 1, "updatedAt": firestore.SERVER_TIMESTAMP})
```

---

### `server/app/nodes/plan.py` (MOD — agent pick + rails)

**Analog:** itself. The G4/G5/G6 guards (lines 92-139) already gate the agent's `next_exercise_id`
against membership + tier-reachability + prerequisites; the coach picks among policy-narrowed
candidates and voices the WHY (D-09/D-10). The guard structure to preserve (lines 93-100):
```python
if not is_authored(plan_out.next_exercise_id):
    raise StructuredOutputError(...)   # fail closed → AuthoredFallback
```
The policy-narrowed candidate list arrives via `facts["legalNextExerciseIds"]` (already the wire
field, `schema.py` lines 195-199); the node rails any proposal against it exactly as today. The
`Plan.rationale` field (lines 62-65) is where the WHY line is grounded.

---

### `server/app/curriculum_data/generate.py` (MOD — derive-from-assets)

**Analog:** itself. Extend `_regenerate_graph` (lines 72-85) to carry the new `microDrill` nodes,
and the authored-id/label derivation (lines 48-66) to carry `letters`+`criteria` labels. The
invariant to preserve: the server copy is DERIVED, never hand-edited (header lines 14-17); re-run
after authoring. The baa-filter (line 80, `startswith("baa.")`) extends to the microDrill ids.

---

### `server/tests/test_eval/run_eval.py` (MOD) + `selection_gold_set.jsonl` (NEW — Req 9)

**Analog:** itself + `gold_set.jsonl`. The `DIMENSIONS` registry (lines 55-65) is where the 5th
`selection_policy` dimension lands; it is a Vertex LLM-judge leg, so add it to
`JUDGE_GATED_DIMENSIONS` (lines 72-78) and give it a `_score_judge_dimension` wiring in
`score_eval_set` (lines 253-278) with a mother-agreed threshold (provisional, `signed:false`).
The judged dimension is complemented by deterministic property tests (Req 5). The gold set mirrors
`gold_set.jsonl` JSONL shape with fail-streak / returning-child / boredom-trap scenarios.

---

### `assets/curriculum/exercises.json` + `curriculum_graph.json` (MOD — content authoring)

**Analog:** itself. **Exercise shape** (`exercises.json` lines 9-42): each exercise has
`id`/`type`/`skill`/`prompt`/`surface`/`expected`/`check`/`feedback`/`signedOff`. Phase 18 adds
`letters` + `criteria` label arrays to EVERY exercise (Req 7) and authors new `microDrill`-type
entries (baa's 3 criteria: dot, bowl, start — D-07), each `signedOff:false` until the mother flips
it. **Graph node shape** (`curriculum_graph.json` lines 44-49): `exerciseId`/`competency`/`tier`/
`minCleanReps`. microDrill nodes are enrichment (a new `microDrill` competency with
`essential:false`, mirroring `wordBuilding`/`grammarTransform` lines 31-40) so they never gate the
star. Keep `signedOff:false` on the graph file until sign-off (D-06/D-07).

---

### `firestore.rules` (MOD — add owner-read for the profile doc)

**Analog:** itself. The current rules are deny-all-writes with read-requires-auth per curriculum
collection + a deny-by-default catch-all (lines 33-38, 84-86). Phase 18 adds ONE owner-scoped read
block BEFORE the catch-all (writes stay Admin-only, D-13):
```
match /child_models/{uid} {
  allow read: if request.auth != null && request.auth.uid == uid;  // D-16 refresh, owner-only
  allow write: if false;                                           // Admin SDK only (D-13)
}
```
The `children/{uid}/evidence/*` subcollection gets NO client match at all — the catch-all denies it
(Admin-only). Preserves the Phase-06.1 deny-all-client-writes posture; adds only a uid-scoped read.

---

### Wave-0 tests (NEW)

**Property/seeded-random rails test (Req 5)** — analog: `test/core/scoring/calibration_harness_test.dart`
parametrized-loop shape (lines 320-367): a `group` with a `for` loop generating cases and asserting
a contract per case. There is **no existing `Random(seed)` usage in `test/`** — this is a new
pattern, but it composes the calibration-harness loop with a seeded generator: `Random(fixedSeed)`
producing arbitrary agent proposals/histories, asserting 100% legal picks + illegal→walker. Plain
`flutter_test`, no new package (glados rejected — analyzer 9 conflict; RESEARCH §Don't Hand-Roll).

**Calibration-harness-style micro-drill selection (Req 3)** — analog: same file, the per-letter×form
loop + confusion-table (lines 324-367): a dominant failing criterion selects its micro-drill,
asserted per letter×form.

**Non-PII guard extension (D-14)** — analog: `test/tutor/payload_nonpii_test.dart`: add
`profile`/`evidenceDigest` to `_whitelist` (lines 27-66) + nested-key sets like `_criteriaKeys`
(lines 73-94), and keep the `_forbiddenKey` token scan green (lines 107-110).

**Pure-layer purity guard for the policy** — analog: `test/tutor/durable_layers_no_agent_imports_test.dart`:
the SelectionPolicy must carry zero Riverpod/Firebase/render imports; extend the scanned globs
(lines 34-40) or the `lib/curriculum` strict ban (lines 143-153) to cover it.

---

## Shared Patterns

### 422 lockstep — new wire fields ship server-FIRST
**Source:** `server/app/schema.py` (lines 140-199) + `lib/tutor/tutor_facts.dart` (lines 197-213).
**Apply to:** every new `TutorFactsIn` field (`profile`, `evidenceDigest`).
`extra="forbid"` means any field the client sends before the server declares it 422s the live
/coach — silently degrading every online session to the AuthoredFallback floor. Order: (1) server
adds the field additive+defaulted and re-deploys, (2) the Dart `toMap()` mirror follows with the
byte-identical key name + omit-when-null, (3) single re-deploy. This is the 15-02/15-04, 17-05/17-06
discipline.

### Non-PII wire guard — whitelist + `extra=forbid` + key-name token scan
**Source:** `test/tutor/payload_nonpii_test.dart` (lines 27-110) + `server/app/schema.py`
`ConfigDict(extra="forbid")` on every nested model (lines 38, 57, 94, 114).
**Apply to:** every new wire field and every Firestore doc schema (Req 8 PII/token guard).
Fixed-vocabulary (letter ids + criterion names + floats), non-PII. The KEY-name guard catches PII
keys; `extra=forbid` is the real teeth (17-05 precedent). Add a server `test_schema_forbid.py` +
extend the Dart whitelist in lockstep.

### Firestore-first with fallback, one-shot `.get()`, never blocks the path
**Source:** `lib/data/curriculum_repository.dart` (lines 68-93, 151-182, 358-389).
**Apply to:** `child_model_repository.dart` (D-16 profile read). For the child model the fallback
is the Drift mirror, not the bundle. Boot reads the mirror synchronously; the refresh is
fire-and-forget. A single `.get()`, never a live stream subscription (Riverpod-3 stream-pause,
Pitfall 6).

### Drift additive migration + JSON-encoded list columns
**Source:** `lib/data/app_database.dart` (lines 98-130 tables, 164-195 migration, 355-378 accessors).
**Apply to:** the three new tables (evidence, arc state, profile mirror). Bump `schemaVersion` 5→6;
version-guarded `createTable` (no data rewrite, no touch to existing rows); JSON-encode any list/map
column into a `text` column (Drift has no native list column); one-shot `Future` accessors.

### Firebase Admin SDK via ADC — zero new packages
**Source:** `server/app/auth.py` (lines 22, 34-51). `firebase_admin` is already initialized at
import with ADC (Cloud Run runtime SA / `gcloud auth application-default login`).
**Apply to:** `evidence.py` + `jobs/compile_profiles.py`. Call `firestore.client()` — do NOT
re-initialize the app; reuse the `_apps` sentinel guard (lines 42-47).

### Pure durable-layer purity (the offline floor is sacred)
**Source:** `lib/curriculum/curriculum_graph_walker.dart` (header lines 1-16) +
`test/tutor/durable_layers_no_agent_imports_test.dart` (lines 34-55, 143-153).
**Apply to:** `selection_policy.dart` + `criterion_ema.dart`. No Riverpod/Firebase/network/render
import. `criterion_ema.dart` under `lib/core` is already covered by `_durableDirs`; the policy
needs the guard's scan set extended to cover it (planner decision — place in `lib/curriculum` or
add the path to the guard).

### Provisional → mother-signs (`signed:false`)
**Source:** graph/exercise `signedOff:false` (`curriculum_graph.json` line 9 flips to true post
sign-off; `exercises.json` lines 5, 41 per-exercise `signedOff`). Precedent: 15-07/17-10 HUMAN-UAT.
**Apply to:** micro-drill content (D-07), arc-N (D-02/D-04), α + EMA thresholds (D-15), eval
threshold (Req 9), framing copy (D-03). Named constants with a sign-off flag, never magic numbers;
the flip is the only content change.

### Anti-gamification — enrichment nodes never gate the star
**Source:** `lib/curriculum/curriculum_graph.dart` `essentialNodes` (lines 164-168) — enrichment
competencies (`essential:false`) are excluded from the 70/30 core.
**Apply to:** all microDrill + arc nodes — author them `essential:false`. The one quiet star's
mastery condition is untouched; drills/arcs produce no new reward surfaces (CLAUDE.md Decided).

### UI: Teacher's Eye strip → Teacher's Margin panel + Spotlight
**Source:** `lib/features/letter_unit/widgets/exercise_scaffold.dart` `_teacherEye()` (lines
379-456) + the `tutorInsightProvider`/`TutorInsight` model (lines 80-86) + `AuthoredFallbackBrain`
degradation (lines 295-327, 465-472; `authored_fallback_brain.dart` lines 34-53).
**Apply to:** the Teacher's Margin panel (D-01, child-facing, carries the WHY line) and the
Spotlight overlay (D-05, lights the failing criterion's zone). The existing insight-publish
mechanism (criteria + pick + rationale merged into `TutorInsight` at verdict/coach time, lines
262-267, 311-322) is the plumbing to reuse; the WHY line rides the `AuthoredFallback` degradation
axis (D-10 — LLM online, authored template offline).

---

## No Analog Found

None. Every Phase-18 surface has a concrete in-repo analog. The two genuinely new algorithmic
pieces (per-criterion EMA; seeded-random property test) are trivial by design and mirror,
respectively, standard EMA (cited in RESEARCH) and the calibration-harness parametrized loop.

The only judgment call left to the planner (not a missing analog): whether `selection_policy.dart`
lives in `lib/curriculum/` (strict pure ban already enforced) or `lib/tutor/` (needs the
durable-layer guard scan set extended) — see the SelectionPolicy assignment above.

---

## Metadata

**Analog search scope:** `lib/tutor/`, `lib/curriculum/`, `lib/data/`, `lib/core/scoring/`,
`lib/features/letter_unit/widgets/`, `server/app/`, `server/app/nodes/`,
`server/app/curriculum_data/`, `server/tests/test_eval/`, `test/tutor/`, `test/core/scoring/`,
`assets/curriculum/`, `firestore.rules`.
**Files read (full or targeted):** 20 source/test/asset files.
**Pattern extraction date:** 2026-07-11
