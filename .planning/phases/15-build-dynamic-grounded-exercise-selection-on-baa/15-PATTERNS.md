# Phase 15: BUILD — dynamic grounded exercise selection on baa - Pattern Map

**Mapped:** 2026-06-27
**Files analyzed:** 13 (4 NEW + 9 EXTENDED/touched)
**Analogs found:** 13 / 13 (every seam already exists in the Phase-14 spine — this is a *thickening* phase)

> **Reading note for the planner/executor.** Phase 15 invents almost nothing. Every "how do I…"
> has a proven Phase-14 answer. The four genuinely NEW artifacts (graph asset, Dart walker +
> mastery condition, Drift position table, Python faithfulness check) each have a 1:1 in-repo
> analog whose mechanics they copy. Replicate the analog's idiom exactly; do not reinvent.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `assets/curriculum/curriculum_graph.json` (NEW) | config / data asset | transform (single-source → derived) | `server/app/curriculum_data/baa_authored_ids.json` + `assets/curriculum/units.json`/`exercises.json` | exact (mirror the seed shape + sign-off gate) |
| `server/app/curriculum_data/curriculum_graph.json` (NEW, derived) | config / data artifact | transform (derived copy) | `server/app/curriculum_data/baa_authored_ids.json` | exact |
| `server/app/curriculum_data/generate.py` (EXTEND) | utility (codegen/derive) | transform / file-I/O | itself (existing `regenerate()` derive-from-assets) | exact (extend the same function) |
| `server/app/curriculum.py` (EXTEND) | service (membership/graph loader) | file-I/O (load-once-at-import) | itself (`_load_authored_ids` / `AUTHORED_BAA_IDS` / `is_authored`) | exact |
| `server/app/nodes/plan.py` (THICKEN) | controller/node (LangGraph) | request-response + transform | itself (existing G3/G4 post-parse guards) | exact (add G5/G6 in the same shape) |
| `server/app/schema.py` (EXTEND) | model (Pydantic DTO) | request-response (wire contract) | itself (`TutorFactsIn`/`AttemptFactIn`, `extra="forbid"`) | exact |
| `lib/curriculum/curriculum_graph.dart` (NEW) | model/service (pure Dart parser) | file-I/O (asset parse) + transform | `lib/tutor/tutor_facts.dart` (defensive pure-Dart parse/serialize idiom) + the asset shape | role-match |
| `lib/curriculum/curriculum_graph_walker.dart` (NEW) | service (selection seam impl) | transform / event-driven | `lib/tutor/authored_fallback_brain.dart` (pure-Dart deterministic `TutorBrain` impl behind a seam) | role-match (sibling seam) |
| `lib/curriculum/mastery_condition.dart` (NEW) | service (pure-Dart evaluator) | transform | `lib/tutor/tutor_facts_builder.dart` (`_deriveStrengthTags` deterministic pure fn) | role-match |
| `lib/tutor/` selection seam (NEW provider/notifier) | provider/store (Riverpod) | event-driven (online↔offline router) | `lib/tutor/tutor_providers.dart` (`tutorBrainFactoryProvider`, `TutorLineNotifier`) | exact |
| `lib/data/app_database.dart` (EXTEND — `LetterGraphPosition` v4→v5) | model + migration | CRUD + file-I/O | itself (`LetterReps`/`LetterMastery` table + version-guarded `onUpgrade`) | exact |
| `lib/data/graph_position_repository.dart` (NEW) | service (repository) | CRUD | `lib/data/drift_progress_repository.dart` (thin delegation + keepAlive provider) | exact |
| `lib/tutor/tutor_facts.dart` + `tutor_facts_builder.dart` (EXTEND — 2 fields) | model + utility | request-response | itself (existing whitelisted `toMap` + builder chokepoint) | exact |
| `lib/features/letter_unit/letter_unit_controller.dart` + `letter_unit_screen.dart` (REPLACE for baa) | controller + component | event-driven (was index-walk) | itself (the `_section(id)` switch + `_resumeByLetter` map being retired) | exact (replace) |
| `server/tests/test_faithfulness.py` + `fixtures/faithfulness_set.jsonl` (NEW) | test + fixture | batch / transform | `server/tests/test_grounding.py` + `test_payload_nonpii.py` (`pytest.mark.code` model-free) | role-match |

---

## Pattern Assignments

### `assets/curriculum/curriculum_graph.json` + `server/app/curriculum_data/{generate.py, curriculum_graph.json}` (config/data, single-source→derive)

**Analog:** `server/app/curriculum_data/generate.py` + `baa_authored_ids.json` + `curriculum.py::_load_authored_ids`

**The derive-from-assets generator to EXTEND** (`generate.py` lines 20–56 — add a parallel `_GRAPH` read + write, do NOT add a new sync path):
```python
_HERE = pathlib.Path(__file__).resolve().parent
_OUT = _HERE / "baa_authored_ids.json"
# server/app/curriculum_data -> server/app -> server -> repo root
_REPO_ROOT = _HERE.parent.parent.parent
_UNITS = _REPO_ROOT / "assets" / "curriculum" / "units.json"
_EXERCISES = _REPO_ROOT / "assets" / "curriculum" / "exercises.json"

def regenerate() -> dict:
    if not _UNITS.exists() or not _EXERCISES.exists():
        raise FileNotFoundError(
            f"Canonical curriculum assets not found at {_UNITS} / {_EXERCISES}. "
            "Run this from a full repo checkout (the Flutter assets are not in the Docker image)."
        )
    units = json.loads(_UNITS.read_text(encoding="utf-8"))
    exercises = json.loads(_EXERCISES.read_text(encoding="utf-8"))
    ...
    _OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return payload
```
> **Copy exactly:** add `_GRAPH = _REPO_ROOT / "assets" / "curriculum" / "curriculum_graph.json"`,
> read it, filter to `baa.*` nodes, and `write_text(... ensure_ascii=False, indent=2 ...)` to a
> NEW `_HERE / "curriculum_graph.json"`. Keep `ensure_ascii=False` (Arabic survives in `_meta`).
> Print a one-line summary like the existing `__main__` block. The regenerate command stays
> `cd server && uv run python -m app.curriculum_data.generate`.

**The load-once-at-import + sign-off `_meta` block to mirror** (`baa_authored_ids.json` lines 1–8 + `curriculum.py` lines 26–40):
```python
_SEED_PATH = pathlib.Path(__file__).resolve().parent / "curriculum_data" / "baa_authored_ids.json"

def _load_authored_ids() -> frozenset[str]:
    data = json.loads(_SEED_PATH.read_text(encoding="utf-8"))
    ...

# The single closed set the G4 guard validates against (loaded once at import).
AUTHORED_BAA_IDS: frozenset[str] = _load_authored_ids()
```
> **Copy exactly:** add a sibling `_GRAPH_PATH = … / "curriculum_data" / "curriculum_graph.json"`,
> a `_load_graph()` that returns the parsed dict, and `CURRICULUM_GRAPH = _load_graph()` loaded
> ONCE at import — exactly like `AUTHORED_BAA_IDS`. Then expose the graph helpers the new G5/G6
> guards call: `tier_of(id)`, `reachable_tiers(cleared)`, `prerequisites_met(id, cleared)`.

**The `_meta` + sign-off shape** (mirror `baa_authored_ids.json` lines 2–7) — the asset MUST carry
its own `signedOff: false` gate (a SEPARATE file from `exercises.json` so signed exercises aren't
re-touched, RESEARCH Alternatives A5):
```jsonc
{ "_meta": { "title": "...", "source": "...", "regenerate": "cd server && uv run python -m app.curriculum_data.generate", "sign_off": "owner-mother signs at the TIER level (D-05); signedOff stays false until then" },
  "letterId": "baa", "signedOff": false, ... }
```
> **Sign-off gate (Pitfall 4 / D-05):** `signedOff: false` until mom signs at the tier level —
> mirror the `AUTHORED_BAA_IDS` gate. Flip to `true` ONLY behind a `checkpoint:human-verify` task.

**Asset shape to extend (verified live):** `units.json` is `{units:[{letterId, sections:[{id, exercises:[...]}]}]}`;
each `exercises.json` entry already carries `"signedOff": true`, a `feedback` map (`pass` + per-`mistakeId`
lines), and `type`/`skill`. The graph nodes key on the same `baa.*` exercise ids.

**Dockerfile / A4 — VERIFIED:** `server/Dockerfile` does `COPY app ./app` (line 31), and
`server/.dockerignore` excludes only `tests/`, secrets, and `.venv` — NOT JSON under `app/`. So a
new derived `app/curriculum_data/curriculum_graph.json` ships into the image automatically, exactly
like `baa_authored_ids.json`. No Dockerfile edit needed; re-deploy after regenerating.

**Test analog:** extend `server/tests/test_grounding.py` G4 cases (add a graph-membership case) and
add a load-shape assertion mirroring `test_payload_nonpii.py::test_extra_forbid_is_pinned_on_both_models`.

---

### `server/app/nodes/plan.py` (controller/node — THICKEN with G5/G6 on top of G3/G4)

**Analog:** itself — the existing post-parse guard block (lines 77–98).

**The exact guard idiom to copy** (`plan.py` lines 77–95 — every new guard is structurally identical):
```python
# G4 — curriculum membership guard (after parse). An unauthored id fails closed.
if not is_authored(plan_out.next_exercise_id):
    logger.warning(
        "G4 curriculum guard: plan emitted unauthored next_exercise_id=%r; failing closed.",
        plan_out.next_exercise_id,
    )
    raise StructuredOutputError(
        f"plan next_exercise_id {plan_out.next_exercise_id!r} is not an authored baa exercise"
    )
...
# G3 — verdict lock: cannot advance on a fail. Downgrade to a re-test of the whole letter.
if intent == "advance" and not facts.get("passed", False):
    logger.warning("G3 verdict lock: plan intent 'advance' on a fail downgraded to 'retest_whole'.")
    intent = "retest_whole"
    grounded = False
```
> **Copy exactly:** add G5 (tier-reachable) and G6 (prereqs-met) AFTER G4, each raising
> `StructuredOutputError` with a one-line `logger.warning`. Import the new helpers from
> `app.curriculum` (`tier_of`, `reachable_tiers`, `prerequisites_met`). The cleared-tier/cleared-
> competency context arrives in `facts` (the two NEW FACTS fields — see schema below).
> **Pitfall 3 (critical):** G5/G6 check only *reachability* and *prereqs-met* — a LOWER tier of an
> already-reached competency satisfies both, so **backward remediation passes**. Forward-only means
> "no skipping ahead," NOT "no stepping back." Add the `ghayrManzur fail → manzur` legal test.

**Degrade contract (unchanged, do not touch):** `StructuredOutputError` → existing
`with_structured_retry` → 503 → client `AuthoredFallback`. Pinned by
`test_grounding.py::test_endpoint_degrades_on_structured_error` (lines 234–260).

**Prompt thickening** — `PLAN_PROMPT` lives in `server/app/prompts.py` (lines 74–93). FACTS go in the
`HumanMessage`, the prompt in the `SystemMessage` (cache-stable) — preserve that split
(`plan.py::_structured_plan` lines 57–63). The existing prompt already states the GROUNDING RULE
("scorer owns pass/fail … only a PASS may advance"); ADD: the reachable-tier list + cleared
competencies as context, the explicit "remediate to the next-easier tier of the SAME competency
(ghayrManzur→manzur→manqul); never jump a tier forward" rule, and "within the reachable tier, choose
the exercise that targets the child's recent mistakeIds/struggleTags."

**Structured-output note (do not regress):** the plan model uses
`.with_structured_output(Plan, method="json_mode")` (line 57) — Gemini native controlled generation;
the default function-calling extraction returned empty on gemini-2.5-flash. Keep `json_mode`.

**Test analog:** new `server/tests/test_plan_graph.py` monkeypatching the plan model exactly like
`test_grounding.py::_patch_all` / `_FakeModel` (lines 50–55, 162–183). Cases: struggle→within-tier,
G5 unreached-tier rejected, G6 prereq-unmet rejected, **backward remediation allowed** (NOT rejected).

---

### `server/app/schema.py` (model — add `clearedTiers`/`clearedCompetencies`, the 422 trap)

**Analog:** itself — `TutorFactsIn` (lines 47–78).

**The DTO + `extra="forbid"` idiom to extend** (lines 47–78):
```python
class TutorFactsIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    # --- the 6 base whitelisted fields (mirror lib/tutor/tutor_facts.dart) ---
    letterId: str = Field(description="The letter family, e.g. 'baa'.")
    ...
    # --- the enlarged fields (the day-one-final shape; Plan 02 consumes them) ---
    trajectory: list[AttemptFactIn] = Field(default_factory=list, ...)
    strengthTags: list[str] = Field(default_factory=list, ...)
```
> **Copy exactly:** add
> `clearedTiers: list[str] = Field(default_factory=list, ...)` and
> `clearedCompetencies: list[str] = Field(default_factory=list, ...)` to `TutorFactsIn`.
> **Pitfall 1 (the 422 trap — CRITICAL):** `extra="forbid"` means the live `/coach` 422s any
> un-mirrored field. Add these two fields to `lib/tutor/tutor_facts.dart` (`toMap`) AND `schema.py`
> **in the same task**, and re-deploy the server BEFORE the device test. Warning sign: a build that
> works offline but 503/degrades the instant it goes online (server 422 → client falls to floor).

**Test analog:** extend BOTH `server/tests/test_payload_nonpii.py` (`LEGIT_FACTS` dict, lines 28–40;
the `test_extra_forbid_is_pinned_on_both_models` guard, lines 104–107) AND
`test/tutor/payload_nonpii_test.dart` (`_whitelist` set lines 27–39; `_fullyPopulatedFacts`
lines 74–87) to include the two new string-list fields and assert they carry no PII.

---

### `lib/tutor/tutor_facts.dart` + `tutor_facts_builder.dart` (model + utility — add 2 non-PII fields)

**Analog:** itself — the whitelisted `toMap` (lines 113–122) + the builder chokepoint (lines 24–41).

**The whitelisted serialize idiom to extend** (`tutor_facts.dart` lines 113–122):
```dart
Map<String, Object?> toMap() => {
      'letterId': letterId,
      'section': section,
      'passed': passed,
      'mistakeId': mistakeId,
      'struggleTags': struggleTags,
      'recentMistakes': recentMistakes,
      'trajectory': [for (final a in trajectory) a.toMap()],
      'strengthTags': strengthTags,
    };
```
> **Copy exactly:** add `clearedTiers` + `clearedCompetencies` as `final List<String>` fields
> (default `const []`), to the constructor, and to `toMap`. They are pure string-lists — no geometry,
> no PII. Keep them lockstep with `schema.py` (Pitfall 1). The doc comment in this file already names
> the `extra="forbid"` trap — honor it.

**The builder chokepoint to extend** (`tutor_facts_builder.dart` lines 24–41) — the signature IS the
guard (accepts no stroke/Offset/profile param):
```dart
TutorFacts buildTutorFacts({
  required String letterId,
  required String section,
  required CheckResult result,
  List<String> recentMistakes = const [],
  List<AttemptFact> trajectory = const [],
}) { ... }
```
> **Copy exactly:** add `List<String> clearedTiers = const []` + `List<String> clearedCompetencies = const []`
> params (read from the Drift position on resume — D-08 trajectory replay). The deterministic
> `_deriveStrengthTags`/`_deriveStruggleTags` (lines 47–80) are the model for any new pure derivation.

**Test analog:** `test/tutor/tutor_facts_builder_test.dart` + the non-PII pair above.

---

### `lib/curriculum/curriculum_graph.dart` + `curriculum_graph_walker.dart` + `mastery_condition.dart` (NEW pure Dart)

**Analog:** `lib/tutor/tutor_brain.dart` (the seam), `lib/tutor/authored_fallback_brain.dart`
(pure-Dart deterministic impl), `lib/tutor/tutor_facts_builder.dart` (deterministic pure fns).

**The seam declaration to mirror** (`tutor_brain.dart` lines 18–20 — one method, FACTS-in to
decision-out, "pure Dart, no cloud-AI imports"):
```dart
/// The single swappable tutor seam. Given a non-PII [TutorFacts] snapshot,
/// answer with exactly one ACTION [TutorDecision].
abstract class TutorBrain {
  Future<TutorDecision> next(TutorFacts facts);
}
```
> **Copy the shape:** declare a sibling `abstract class ExerciseSelector { String? selectNext(TutorFacts facts, GraphPosition position); }`
> — a DIFFERENT axis from `TutorBrain` (selection vs. coaching). The `RemoteAgentBrain` decision
> already carries a `TutorPlan{nextExerciseId, intent, rationale}` (`tutor_decision.dart` lines 36–47),
> so online selection reads `decision.plan.nextExerciseId`; offline selection is the walker. Do NOT add
> a 5th `TutorTool` — selection rides alongside the closed 4-action set.

**The pure-Dart deterministic impl to mirror** (`authored_fallback_brain.dart` lines 19–53 — a
`TutorBrain` impl with a small deterministic resolver, "no cloud-AI / Firebase / network imports"):
```dart
class AuthoredFallbackBrain implements TutorBrain {
  const AuthoredFallbackBrain({required this.feedback});
  @override
  Future<TutorDecision> next(TutorFacts facts) async {
    final line = _resolveLine(facts);
    return PresentActivity(coachingLine: line, letterId: facts.letterId);
  }
  String _resolveLine(TutorFacts facts) {
    if (facts.passed) return feedback['pass'] ?? '';
    ...
  }
}
```
> **Copy the shape:** `class CurriculumGraphWalker implements ExerciseSelector` — `selectNext` returns
> `graph.nextForward(pos)` on a pass, `graph.remediateOneTier(facts.section, pos)` on a fail (drop one
> tier within the same competency; at the `manqul` floor, re-present in place). Pure Dart, deterministic.
> **Pitfall 5 (D-09):** offline must still WALK the graph adaptively (advance/remediate) — never revert
> to the old fixed 6-section linear sequence. Coaching still degrades to `AuthoredFallbackBrain`
> independently; selection and coaching degrade on separate axes.

**The deterministic pure-fn idiom** (`tutor_facts_builder.dart::_deriveStrengthTags` lines 66–80) is
the model for `mastery_condition.dart` — a pure, in-first-appearance-order, no-PII evaluator:
```dart
bool isMasteryMet(CurriculumGraph g, Map<String,int> cleanRepsByExercise) {
  for (final node in g.essentialNodes) {              // essential==true (70/30 split)
    if ((cleanRepsByExercise[node.exerciseId] ?? 0) < node.minCleanReps) return false;
  }
  return true;
}
```
> **D-06 invariant:** mastery is computed ON-DEVICE from Drift clean-rep counts on ESSENTIAL nodes
> only; enrichment never gates the star. NEVER trust a server `CoachOut` for the star (ADR-014). This
> replaces `LetterUnitController._onEnterSection`'s "reaching Mastery records mastered" auto-write.

**The defensive parse idiom** for `curriculum_graph.dart` is the same "pure Dart, whitelisted fields,
no Flutter render import" discipline as `tutor_facts.dart` (lines 1–28). Load the asset via the
existing `rootBundle` curriculum-loader path (same place `CurriculumRepository` reads
`assets/curriculum/*.json` — see `lib/data/curriculum_repository*` and its v2 test).

**`durable_layers_no_agent_imports_test.dart`** already guards that the pure layers carry no
cloud/agent imports — the new `lib/curriculum/` files MUST stay equally pure (extend that test).

**Test analogs (Wave 0, RED):** `test/curriculum/curriculum_graph_test.dart`,
`curriculum_graph_walker_test.dart` (pass→forward, fail→one tier down), `mastery_condition_test.dart`
(star ONLY when essential core at mom's reps, NOT on navigation).

---

### `lib/tutor/` selection seam (NEW Riverpod provider/notifier — online↔offline router)

**Analog:** `lib/tutor/tutor_providers.dart` — `tutorBrainFactoryProvider` (lines 71–88) + `TutorLineNotifier` (lines 98–111).

**The single-switch-point factory to mirror** (lines 71–88 — the ONE place online↔offline routing lives):
```dart
final tutorBrainFactoryProvider =
    Provider<TutorBrain Function(Map<String, String> feedback)>((ref) {
  final baseUrl = ref.watch(tutorBaseUrlProvider);
  final client = ref.watch(tutorHttpClientProvider);
  final getIdToken = ref.watch(idTokenGetterProvider);
  final getAppCheckToken = ref.watch(appCheckTokenGetterProvider);
  return (Map<String, String> feedback) {
    final floor = AuthoredFallbackBrain(feedback: feedback);
    return RemoteAgentBrain(baseUrl: baseUrl, client: client, fallback: floor, ...);
  };
});
```
> **Copy the shape:** a `Provider<ExerciseSelector>` (or a small router notifier) that picks the
> online path (`RemoteAgentBrain` decision's `plan.nextExerciseId`, when present AND graph-legal) vs.
> the offline `CurriculumGraphWalker`. Riverpod-only (CLAUDE.md Decided). The `TutorLineNotifier`
> (Notifier<String?> with `set`/`clear`, lines 98–111) is the model for any new single-value notifier
> (Riverpod 3 dropped `StateProvider`). `keepAlive` mirrors `appDatabaseProvider`.

**Test analog:** `test/tutor/tutor_providers_test.dart` (ProviderScope overrides + MockClient).

---

### `lib/data/app_database.dart` (model + migration — `LetterGraphPosition`, schemaVersion 4→5)

**Analog:** itself — the `LetterReps` table (lines 67–74) + the version-guarded `onUpgrade` (lines 95–113).

**The table idiom to copy** (`LetterReps`, lines 59–74):
```dart
class LetterReps extends Table {
  TextColumn get letterId => text()();
  IntColumn get cleanReps => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {letterId};
}
```
> **Copy the shape:** `LetterGraphPosition` with `letterId` (PK), `currentExerciseId` (`text().nullable()`),
> `clearedCompetencies`/`clearedTiers` (`text()()` JSON-encoded `List<String>`), `updatedAt`.
> Register it in `@DriftDatabase(tables: [..., LetterGraphPosition])` (line 76).
> **Open Q3 (clean-rep accounting):** `LetterReps` keys ONE `cleanReps` per `letterId`; D-06 needs
> per-essential-EXERCISE reps. Either extend `LetterReps` to a `(letterId, exerciseId)` composite PK
> or add a sibling table — decide at plan time; flag as a schema concern alongside the position table.

**The version-guarded `onUpgrade` to extend** (lines 91–113 — the migration idempotency guard, Pitfall 4):
```dart
@override
int get schemaVersion => 4;

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        // Pitfall 4: guard by version to make the migration idempotent.
        if (from < 2) await m.createTable(letterMastery);
        if (from < 3) await m.createTable(childProfiles);
        if (from < 4) { await m.createTable(letterReps); ... }
      },
    );
```
> **Copy exactly:** bump `schemaVersion` 4→5; add `if (from < 5) await m.createTable(letterGraphPosition);`
> to the SAME `onUpgrade` switch (version-guarded for idempotency). Add `recordMastery`-style
> accessors (`setPosition`/`getPosition`, mirroring `recordMastery`/`setCleanReps` at lines 143–229).
> After editing the table set, run `dart run build_runner build` to regenerate `app_database.g.dart`
> (the `.g.dart` is gitignored/regenerated, NEVER hand-edited).

**The injected-executor "survives a restart" lifecycle** (lines 85–121) is load-bearing for the
resume test: `[close]` does NOT tear down an injected executor, so a second `AppDatabase` re-opens the
same store (the D-08 simulated restart).

**Test analog (the EXACT restart shapes to copy):** `test/data/app_database_test.dart`:
- **Shared in-memory restart** (lines 25–39): `DatabaseConnection(NativeDatabase.memory())` →
  `db1.set…` → `db1.close()` → `db2 = AppDatabase(shared.executor)` → assert value survived.
- **Real `onUpgrade` via a temp FILE db** (lines 118–187): `Directory.systemTemp.createTemp`, seed
  with current schema, `DROP TABLE` + `PRAGMA user_version = N`, re-open with a fresh executor so the
  REAL `onUpgrade(from:N)` runs, assert rows survive + a second restart is idempotent. **This is the
  Phase-09-shape persisted-restart test D-08 references** — use it for `LetterGraphPosition`
  (`test/data/graph_position_repository_test.dart`).

> **Pitfall 6 (Riverpod 3 StreamProvider hang):** for the one-shot resume read at unit entry, use a
> `Future`-returning repo method (`getPosition(letterId)`), NOT a bare `StreamProvider.future` (it
> hangs — Riverpod 3 pauses unlistened streams). For live drift-stream data use the `_bindDriftStream`
> AsyncNotifier bridge.

---

### `lib/data/graph_position_repository.dart` (NEW repository)

**Analog:** `lib/data/drift_progress_repository.dart` (the whole file, 53 lines).

**The thin-delegation + keepAlive-provider idiom to copy** (lines 18–53):
```dart
class DriftProgressRepository implements ProgressRepository {
  const DriftProgressRepository(this._db);
  final AppDatabase _db;
  @override
  Future<void> recordMastery({required String letterId, required int cleanReps}) =>
      _db.recordMastery(letterId: letterId, cleanReps: cleanReps);
  ...
}

@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) =>
    DriftProgressRepository(ref.watch(appDatabaseProvider));
```
> **Copy exactly:** a `GraphPositionRepository` interface + `DriftGraphPositionRepository` that
> delegates to the new `AppDatabase.getPosition`/`setPosition` accessors; expose a
> `@Riverpod(keepAlive: true)` provider reading `appDatabaseProvider`. Pure delegation — all SQL stays
> in `AppDatabase` (the Phase-1 convention).

**Test analog:** `test/data/progress_repository_test.dart` (the repo-level analog of the table test).

---

### `lib/features/letter_unit/letter_unit_controller.dart` + `letter_unit_screen.dart` (REPLACE the fixed walk for baa)

**Analog:** itself — the fixed `_resumeByLetter` index walk (controller lines 60–129) + the
`_section(id)` switch (screen lines 244–250) being RETIRED.

**What's being replaced (controller lines 109–129 — the bug to fix, Pitfall 2):**
```dart
void _onEnterSection(int index) {
  _resumeByLetter[_letterId] = index;          // in-memory only — LOST on restart (D-08 needs durable)
  if (state.atMastery) _recordMastery();        // fires on NAVIGATION, not real completion (Pitfall 2)
}

Future<void> _recordMastery() async {
  ...
  await ref.read(progressRepositoryProvider).recordMastery(letterId: _letterId, cleanReps: 0);  // cleanReps:0!
}
```
> **Replace for baa:** the in-memory `_resumeByLetter` map → the Drift `LetterGraphPosition` table
> (durable, D-08); the `state.atMastery → recordMastery` auto-write → gate `recordMastery()` behind the
> NEW `isMasteryMet(...)` deterministic condition (D-06). **Pitfall 2:** never grant the star for merely
> navigating to a node, and never write `cleanReps: 0` mastery rows. Drive selection at the UNIT level
> (Open Q1) — replace the `_section(id)` switch with a single config-presenter fed by the
> `ExerciseSelector`, reusing the already-config-driven `ExerciseScaffold`.

**The section switch to replace** (screen lines 244–250 — keyed by section ID, not index):
```dart
Widget _section(LetterUnitData data, int index) {
  ...
  final id = sections[index.clamp(0, sections.length - 1)].id;
  switch (id) {
    case 'meet':   return MeetSection(...);
    case 'watchTrace': return WatchTraceSection(...);
    ...
  }
}
```

**Test analog:** `test/features/letter_unit/letter_unit_screen_test.dart` — note Test 3 (lines 148–161)
currently asserts `recordMastery` fires on `goTo(5)` via a `_FakeProgressRepository`. That assertion
must FLIP under D-06 (star ONLY when `isMasteryMet`). Add the new
`test/features/letter_unit/dynamic_selection_test.dart` (a fail re-surfaces a remediation exercise, not
the next linear section) and extend the screen test to assert `recordMastery` is NOT called on a
clicked-through unit with unmet reps. Reuse `_pump` + ProviderScope-override harness (lines 94–113).

---

### `server/tests/test_faithfulness.py` + `fixtures/faithfulness_set.jsonl` (NEW — GROUND-03)

**Analog:** `server/tests/test_grounding.py` + `test_payload_nonpii.py` (the `pytest.mark.code` model-free pattern) + `conftest.py`.

**The model-free `code`-marker idiom to copy** (`test_grounding.py` lines 13–17; `test_payload_nonpii.py` lines 16–23):
```python
from __future__ import annotations
import pytest
pytestmark = pytest.mark.code   # model-free, network-free; gates every PR

from app.schema import ...
```
> **Copy exactly:** `pytestmark = pytest.mark.code` at module top, no model/network. Read the labeled
> JSONL fixture, run a deterministic lexicon/rule check (`_PRAISE` token set; on a fail the coaching
> must mention the `expectedFix` token), and PRINT + assert a faithfulness RATE. The `code` marker is
> declared in `server/pyproject.toml [tool.pytest.ini_options] markers`. The fixtures dir does NOT yet
> exist — create `server/tests/fixtures/` (NEW). Note `.dockerignore` excludes `tests/`, so fixtures
> never ship to the image (correct — the check is offline CI only).

**The labeled-fixture + parametrize discipline** mirrors `test_payload_nonpii.py` (the `LEGIT_FACTS`
constant + `@pytest.mark.parametrize` cases, lines 28–98) — keep the gold set constructed-faithful so
a regression drops the rate. **D-10 constraints:** model-AGNOSTIC (scores coaching against fixed
verdicts; does NOT call a model, does NOT pre-empt the Phase-13 Claude-vs-Gemini choice); it's a FLOOR,
not a ceiling (the lexicon is coarse by design — Phase 13/16 add the calibrated judge).

**Conftest note:** the new check needs NO auth/Firebase fixtures (`conftest.py`'s `fake_firebase`
autouse fixture is for endpoint tests) — the faithfulness check is a pure offline file read.

---

## Shared Patterns

### Single-source asset → `generate.py` → server-derived copy (NEVER hand-edit the derived file)
**Source:** `server/app/curriculum_data/generate.py` (`regenerate()`) + `curriculum.py` (`_load_*` at import).
**Apply to:** `curriculum_graph.json` (asset + derived copy). One command regenerates:
`cd server && uv run python -m app.curriculum_data.generate`. Provably can't drift; ship the derived
JSON in the image via the existing `COPY app ./app`.

### `extra="forbid"` wire-contract lockstep (the 422 trap)
**Source:** `server/app/schema.py` (`TutorFactsIn`/`AttemptFactIn`) ↔ `lib/tutor/tutor_facts.dart` (`toMap`).
**Apply to:** EVERY new FACTS field (`clearedTiers`/`clearedCompetencies`) — add to BOTH files in the
SAME task; re-deploy server before the device test. Guarded by `test_payload_nonpii.py` +
`payload_nonpii_test.dart` (extend both). A leaked geometry/PII key 422s on the server and trips the
client regex `\b[xy]\b|stroke|offset|coord|point|raw|nick|name`.

### Post-parse grounding guard → `StructuredOutputError` → degrade-to-floor
**Source:** `server/app/nodes/plan.py` (G3/G4) → `with_structured_retry` → 503 → client `AuthoredFallback`.
**Apply to:** the new G5/G6 graph guards. Same `raise StructuredOutputError(...)` + `logger.warning`
shape; same degrade path pinned by `test_grounding.py::test_endpoint_degrades_on_structured_error`.
**Remediation must pass the guards** (Pitfall 3) — guards reject illegal forward jumps, not legal backward steps.

### Scorer owns the verdict + the star (ADR-014 invariant)
**Source:** `lib/tutor/tutor_decision.dart` (no verdict/star tool in the closed 4-set; `TutorPlan` is a
SUGGESTION) + `lib/data/drift_progress_repository.dart::recordMastery`.
**Apply to:** `mastery_condition.dart` + the controller's `recordMastery` gate. Mastery is computed
ON-DEVICE from Drift clean-reps on essential nodes; the agent's `intent:"advance"` is never trusted for
the star. Never write `recordMastery()` off a `CoachOut`.

### Version-guarded idempotent Drift migration
**Source:** `lib/data/app_database.dart` (`onUpgrade` switch, `if (from < N)`); test in
`test/data/app_database_test.dart` (shared-memory restart + temp-file real-`onUpgrade` shapes).
**Apply to:** the `LetterGraphPosition` v4→v5 migration + its persisted-restart test. Regenerate
`app_database.g.dart` via `dart run build_runner build` after the table change.

### Pure-Dart, no-cloud-import seam impls
**Source:** `lib/tutor/{tutor_brain.dart, authored_fallback_brain.dart, tutor_facts_builder.dart}`;
guarded by `test/tutor/durable_layers_no_agent_imports_test.dart`.
**Apply to:** all of `lib/curriculum/` (graph, walker, mastery). No Flutter render import, no
cloud-AI/Firebase/network import. Extend the no-agent-imports test to cover `lib/curriculum/`.

---

## No Analog Found

None. Every Phase-15 file has an exact or role-match in-repo analog — the phase is a *thickening* of the
Phase-14 spine, not a greenfield. The only NEW-shaped pieces (the graph's tier/prereq edges, the
walker's backward-remediation step, the mastery 70/30 evaluator, the faithfulness lexicon) are new
*logic* built on existing *mechanics* (asset-derive, pure-Dart seam impl, deterministic pure fns,
`pytest.mark.code` fixture check).

---

## Metadata

**Analog search scope:** `server/app/` (`curriculum.py`, `curriculum_data/{generate.py, baa_authored_ids.json, __init__.py}`,
`nodes/plan.py`, `schema.py`, `prompts.py`), `server/tests/` (`test_grounding.py`, `test_payload_nonpii.py`,
`conftest.py`), `server/Dockerfile` + `.dockerignore`, `lib/tutor/` (8 files), `lib/data/`
(`app_database.dart`, `drift_progress_repository.dart`), `lib/features/letter_unit/`
(`letter_unit_controller.dart`, `letter_unit_screen.dart`), `assets/curriculum/` (`units.json`,
`exercises.json`), `test/data/app_database_test.dart`, `test/tutor/payload_nonpii_test.dart`,
`test/features/letter_unit/letter_unit_screen_test.dart`.
**Files scanned:** 26
**Pattern extraction date:** 2026-06-27
**Verified live (not assumed):** the `generate.py` derive idiom, `AUTHORED_BAA_IDS` load-at-import,
the G3/G4 guard block, `extra="forbid"` on both DTOs, the `LetterReps`/`onUpgrade` migration mechanics,
the two persisted-restart test shapes, the `_section(id)` switch, the mastery-on-navigation bug
(`cleanReps: 0`), and **A4** (`COPY app ./app` ships the derived graph; `.dockerignore` excludes only
tests/secrets — no Dockerfile edit needed).
