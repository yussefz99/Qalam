---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
reviewed: 2026-06-28T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - lib/curriculum/curriculum_graph.dart
  - lib/curriculum/curriculum_graph_walker.dart
  - lib/curriculum/mastery_condition.dart
  - lib/data/app_database.dart
  - lib/data/graph_position_repository.dart
  - lib/features/letter_unit/letter_unit_controller.dart
  - lib/features/letter_unit/letter_unit_screen.dart
  - lib/tutor/exercise_selector_provider.dart
  - lib/tutor/tutor_facts.dart
  - lib/tutor/tutor_facts_builder.dart
  - server/app/curriculum.py
  - server/app/curriculum_data/generate.py
  - server/app/faithfulness.py
  - server/app/nodes/plan.py
  - server/app/prompts.py
  - server/app/schema.py
findings:
  critical: 4
  warning: 7
  info: 5
  total: 16
status: issues_found
---

# Phase 15: Code Review Report

**Reviewed:** 2026-06-28
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Phase 15 set out to replace the baa unit's fixed 6-section linear walk with **dynamic,
grounded, graph-driven exercise selection**, gate the mastery star strictly on real
per-exercise clean-reps, and mirror the server's G4/G5/G6 grounding guards client-side.

The individual *components* are well-written, defensively parsed, and faithful to the
non-PII / verdict-lock invariants in isolation. The Python rail (G4/G5/G6, fail-closed
empty-graph degrade, backward-remediation legality) is correct and well-documented. The
non-PII whitelist on `TutorFacts` is clean — no stroke/Offset/childName leak path was found,
and the server `extra="forbid"` lockstep is honored.

**However, the phase's central deliverable is not actually wired into the running app, and
two on-device state inputs the new logic depends on are never written.** The result is a
large body of correct-but-dead machinery sitting beside a unit that still walks the fixed
linear sequence — the exact Pitfall 5 the phase was chartered to eliminate. Separately, the
PROVISIONAL curriculum graph has been flipped to `signedOff: true` while its own header and
the project's standing rule say it must stay unsigned until the owner-mother reviews it,
and nothing in the code actually enforces the `signedOff` gate.

The four BLOCKERs below are integration / grounding-invariant failures, not style. They
should be fixed (or the phase re-scoped) before this ships.

## Critical Issues

### CR-01: Dynamic selection is never invoked — the unit still walks the fixed linear sequence (Pitfall 5 unfixed)

**File:** `lib/features/letter_unit/letter_unit_screen.dart:256-319` (and `:198-199`)
**Issue:** The entire selection seam (`ExerciseSelector` → `RouterExerciseSelector` →
`CurriculumGraphWalker`, `LetterUnitController.selectNext`) is dead code from the UI's
perspective. The screen still renders sections through the fixed `_section(data, index)`
switch driven by `_advance()` → `controller.advance()` → `goTo(index + 1)` (a pure linear
index bump). `LetterUnitController.selectNext` is called from **no** production file — only
from `test/curriculum/curriculum_graph_walker_test.dart` and
`test/features/letter_unit/dynamic_selection_test.dart`, both of which construct the walker
directly rather than driving the UI. The Wave-0 test's own header states the contract:
*"Plan 15-05 replaces letter_unit_screen.dart's fixed `_section(index)` switch with a single
config-presenter fed by the selector, then turns this green."* That replacement was not
done; the test passes by exercising the walker in isolation, masking the integration gap.
Consequently a FAIL still surfaces the next linear section, not a remediation — Pitfall 5,
the phase's primary target, is still live in the running app.
**Fix:** Wire `_advance` (and the present-activity dispatch) through the selector:
```dart
// in _UnitShellState, after a scored attempt produces TutorFacts `facts`:
final nextId = ref
    .read(letterUnitControllerProvider(_letterId).notifier)
    .selectNext(facts, decision: lastAgentDecision);
// then present the exercise/section that `nextId` maps to, instead of goTo(index + 1).
```
Drive section rendering from the selector's chosen `nextExerciseId` (map id → section), and
add an end-to-end widget test that scores a FAIL through the UI and asserts a remediation
exercise surfaces (not section index + 1).

### CR-02: The mastery star can never fire in the unit — per-exercise clean-reps are never written

**File:** `lib/features/letter_unit/letter_unit_controller.dart:194-221`, `lib/data/app_database.dart:357-369`
**Issue:** `recordMasteryIfMet` gates the star on
`isMasteryMet(graph, exerciseCleanRepsFor(letterId))`, which requires every one of the 15
essential nodes to have met its `minCleanReps` (3 each, except `recognize`'s 1) in the
`LetterExerciseReps` table. But `AppDatabase.setExerciseCleanReps` — the only writer for
that table — is **never called from any production code** (confirmed repo-wide; the sole
caller is one test that seeds the DB directly). With the real graph, `exerciseCleanRepsFor`
always returns an empty map, every essential node reads 0 reps, `isMasteryMet` returns
`false` forever, and a child who genuinely masters baa in the unit never earns the star.
The anti-gamification *deletion* (removing the `atMastery → recordMastery(cleanReps:0)`
auto-write) was done correctly, but its replacement is non-functional: the scoring sections
that produce clean reps do not feed `setExerciseCleanReps`. (Note the legacy
`practice_providers.dart` star path is untouched and still works for free-practice; the
*unit* path is the broken one.)
**Fix:** On every clean pass inside a scoring section, write through the per-exercise
counter for the presented exercise id:
```dart
await ref.read(appDatabaseProvider).setExerciseCleanReps(
  letterId: _letterId,
  exerciseId: presentedExerciseId,   // the graph node id, not the section id
  cleanReps: bankedRepsForThatExercise,
);
```
Then add a test that drives real reps to the essential floor and asserts exactly one
`recordMastery` write fires (and that an under-floor unit records nothing).

### CR-03: PROVISIONAL curriculum graph shipped as `signedOff: true`, and the flag is dead (no gate enforces it)

**File:** `assets/curriculum/curriculum_graph.json:13` and `server/app/curriculum_data/curriculum_graph.json` (both `"signedOff": true`)
**Issue:** Two independent problems compound here.
(1) The asset's own `_meta.sign_off` says *"signedOff stays false until [owner-mother signs]
— Claude DRAFTED this; she REVIEWS and signs … Plan 15-07 owns the flip to true,"* and
`curriculum_graph.dart:106-108` / `generate.py` repeat that the asset is PROVISIONAL. The
file has nonetheless been set to `signedOff: true`. Per the project memory rule *"never ship
a model-authored letter unsigned"* (Curriculum drafting strategy, decided 2026-06-11), a
model-drafted tier/competency mapping presented as owner-signed is a pedagogy-integrity
violation — the owner-mother's domain (stroke order, clean-rep thresholds, the 70/30 split)
is being asserted as signed without her review.
(2) Worse, `signedOff` is **parsed but never read** by any consumer (grep finds no gate in
`lib/` or `server/` that branches on `CurriculumGraph.signedOff`). So even when the flag is
correct it does nothing — there is no guard that refuses to drive selection/mastery off an
unsigned graph. The flag is decorative.
**Fix:** Revert both copies to `"signedOff": false` until the owner-mother actually signs
(Plan 15-07), regenerate via `generate.py` so they cannot drift, and add a real gate — e.g.
`exerciseSelectorProvider` / `recordMasteryIfMet` should treat an unsigned graph as
"preparing" / no-star (fail-closed to the authored fallback), so the flag has teeth.

### CR-04: Offline walker advances across difficulty tiers without re-checking reachability (G5 bypass on the offline path)

**File:** `lib/curriculum/curriculum_graph_walker.dart:90-92`, `lib/curriculum/curriculum_graph.dart:189-193`
**Issue:** On a PASS the offline walker returns `graph.nextForward(current)`, which is purely
the **next node in declaration order** with no tier or prerequisite check. In the shipped
graph the forward chain crosses tier boundaries within `copyWrite`
(`completeWord.middle` [manqul] → `writeWord.copy` [manzur] → `writeWord.dictation`
[ghayrManzur]) and competency boundaries (`writeWord.dictation` [copyWrite] →
`buildSentence.hear` [fluentReading]). The online `RouterExerciseSelector` re-checks
`isLegalSelection` (G4/G5/G6) on the agent's proposal, but the offline walker — and the
router's own fallback to it — apply **no** such gate. So offline (airplane mode, the
"durable floor") a single pass can jump a child from the copy tier straight into dictation,
or from copyWrite into fluentReading, regardless of whether the intermediate tier/competency
was cleared. This contradicts the stated invariant that the offline walker "rails the SAME
graph the online rail uses" and that forward-only means "no skipping ahead." It is currently
masked only because `selectNext` is unused (CR-01); fixing CR-01 makes this live.
**Fix:** Have `nextForward` (or the walker) skip forward past any node whose tier is not in
`reachableTiers(clearedTiers)` or whose prerequisites are unmet given `clearedCompetencies`,
i.e. advance to the next **legal** node rather than the next declaration-order node — the
same legality the online path enforces. This also depends on CR-05 (cleared-state must
actually be maintained for the check to mean anything).

## Warnings

### WR-01: `clearedTiers` / `clearedCompetencies` are never grown — G5/G6 and the agent's reasoning are permanently fed empty state

**File:** `lib/features/letter_unit/letter_unit_controller.dart:139-150, 173-187, 239-253`
**Issue:** The cleared-state lists are read from Drift on `start`, passed straight through to
`selectNext`/`_persist`/`TutorFacts`, and written back — but **no code path ever appends to
them** when a competency or tier is actually cleared (no `copyWith(clearedTiers: [...])` with
a new value anywhere). They begin `[]` and stay `[]` for the unit's entire life. Downstream
this means: (a) the server's G5/G6 rail is the documented no-op forever (`plan.py:112`
`has_graph_position` is always false), so the online grounding rail never actually gates a
selection; (b) `isLegalSelection` on the client always evaluates against empty cleared-state,
so only the floor tier (`manqul`) and zero-prereq competencies are ever "legal" — a correct
agent proposal for a reached-but-non-floor tier would be wrongly rejected to the walker once
CR-01/CR-05 land; (c) the resume-replay promise (the agent "resumes where it left off") is
empty.
**Fix:** When a node/competency/tier is cleared (e.g. its essential reps hit the floor, or a
forward advance leaves a tier), update state:
`state = state.copyWith(clearedCompetencies: {...state.clearedCompetencies, comp}.toList())`
and persist. Add a test asserting cleared-state grows across passes and that G5/G6 then gate
a forward jump.

### WR-02: Selection fallback uses the section id as a graph node id, producing an off-graph cursor

**File:** `lib/features/letter_unit/letter_unit_controller.dart:177`
**Issue:** When `state.currentExerciseId` is null, `selectNext` builds the walker position
with `currentExerciseId: state.currentExerciseId ?? facts.section`. But `facts.section` is a
**section id** (e.g. `traceLetter`), not a graph **exercise id** (e.g.
`baa.traceLetter.isolated`). The walker's `nextForward`/`remediateOneTier` do
`indexWhere`/`_nodeFor` lookups that return -1/null for an unknown id, so on a fail the
walker returns `current` unchanged — i.e. it hands back `traceLetter`, a string that is not
a graph node and not an authored exercise id. That value then becomes the persisted cursor
and the next `present_activity` target. Currently masked by CR-01.
**Fix:** Resolve `facts.section` to its graph node id before constructing the position (map
section → first exercise of that section), or seed `currentExerciseId` to a concrete graph
node id at unit `start`, and never feed a bare section id into the walker.

### WR-03: `isMasteryMet` returns `true` vacuously when the graph has zero essential nodes (fail-open star)

**File:** `lib/curriculum/mastery_condition.dart:29-35`, `lib/curriculum/curriculum_graph.dart:121-148`
**Issue:** `CurriculumGraph.fromJson` is defensive and never throws: a malformed-but-decodable
asset (e.g. `nodes` or `competencies` missing/renamed) yields a graph with
`essentialNodes == []`. `isMasteryMet` then iterates zero nodes and returns `true` — granting
the star unconditionally. This is a fail-OPEN direction for the anti-gamification invariant
("star only on real clean-reps"). A hard parse failure (bad JSON) is safe because the
provider throws and `recordMasteryIfMet` catches it, but a structurally-degraded-yet-valid
JSON slips through.
**Fix:** Make mastery fail closed on a degenerate graph:
```dart
bool isMasteryMet(CurriculumGraph graph, Map<String, int> reps) {
  final essentials = graph.essentialNodes;
  if (essentials.isEmpty) return false; // no essential core => never the star
  for (final node in essentials) {
    if ((reps[node.exerciseId] ?? 0) < node.minCleanReps) return false;
  }
  return true;
}
```

### WR-04: Two divergent `GraphPosition` types invite a null-safety mismatch at the seam

**File:** `lib/curriculum/curriculum_graph_walker.dart:26-45` vs `lib/data/graph_position_repository.dart:30-50`
**Issue:** There are two classes named `GraphPosition` with **different nullability** on the
same field: the walker's `currentExerciseId` is required non-null `String`; the repo's is
`String?`. The controller imports the walker's via
`show GraphPosition` and the repo's via `as repo`, then hand-converts between them
(`:177` forces non-null with `?? facts.section`; `:241-247` uses the repo's nullable form).
This is fragile duplication: a future edit that routes a repo `GraphPosition` (nullable
cursor) into a walker API would compile-fail or, if "fixed" with a `!`, crash on a
never-started letter. The two types model the same concept and should be one.
**Fix:** Collapse to a single `GraphPosition` value type (nullable `currentExerciseId`, since
the graph-root case is real) shared by the walker, repo, and controller; have the walker
handle a null cursor explicitly instead of relying on callers to coerce it.

### WR-05: `_sectionHintFor` maps a competency *count* onto a section *index* — an unsound coordinate

**File:** `lib/features/letter_unit/letter_unit_controller.dart:259-266`
**Issue:** The resume hint returns `clearedCompetencies.length.clamp(0, total-2)` as the
section index. There is no defined correspondence between "number of cleared competencies"
and "section ribbon index" — competencies (recognize, positionalForms, copyWrite,
fluentReading, +2 enrichment) do not map 1:1 onto the 6 fixed sections (Meet, Watch&Trace,
Forms, Words, Listen&Write, Mastery). A child who cleared 3 competencies could resume on
section 3 (Words) regardless of which sections they actually completed. Combined with WR-01
(cleared-state never grows) the hint is always 0 today, so the bug is latent — but the
heuristic is unsound and will mis-resume once cleared-state is populated.
**Fix:** Derive the resume section from the persisted `currentExerciseId` → its section
(`competencyOf`/a node→section map), not from a list length; or persist the section index
explicitly alongside the cursor.

### WR-06: `faithfulness` raises `KeyError` on a fixture row missing `passed`/`coaching` (not fail-soft)

**File:** `server/app/faithfulness.py:80-84, 105-108`
**Issue:** Both `faithfulness_rate` and `evaluate_faithfulness` index `c["passed"]` and
`c["coaching"]` directly. A labeled JSONL row missing either key raises `KeyError` mid-scan,
aborting the whole GROUND-03 gate with a stack trace rather than reporting a flagged/invalid
case. For a regression-gate artifact that reads an externally-authored fixture, a malformed
row should be a controlled failure, not an uncaught exception.
**Fix:** Either validate rows up front (skip/flag rows lacking the required keys with a clear
message) or use `c.get("passed")` / `c.get("coaching", "")` with an explicit "invalid case"
classification so the report stays meaningful.

### WR-07: `evaluate_faithfulness` parses the labeled set twice and reads the file under no error guard

**File:** `server/app/faithfulness.py:98-110`
**Issue:** `evaluate_faithfulness` builds `cases` once, then re-runs `_contradicts` over the
full list a second time to compute `flagged`, and `faithful = total - len(flagged)` — a
second full pass that `faithfulness_rate` already encapsulates. Minor, but it duplicates the
scoring logic (two places that must stay in sync) and `read_text` has no guard for a missing
fixture path (the module elsewhere is careful to fail closed on file IO — `curriculum.py`).
**Fix:** Compute `flagged` and `faithful` in a single pass (or reuse `faithfulness_rate`),
and wrap the fixture read so a missing/unreadable set reports a clear error rather than a
bare `OSError`.

## Info

### IN-01: `regenerate()` ignores `_regenerate_graph()`'s return value

**File:** `server/app/curriculum_data/generate.py:68-69`
**Issue:** `graph_payload = _regenerate_graph()` is assigned and never used (the `__main__`
block re-reads the file from disk instead). Dead local.
**Fix:** Drop the unused binding (`_regenerate_graph()` on its own line) or return both
payloads and use them in `__main__` rather than re-reading.

### IN-02: `grounded`/`intent` recomputed after the graph rail with a redundant flag

**File:** `server/app/nodes/plan.py:141-149`
**Issue:** `grounded = True` is set unconditionally then only flipped by the G3 advance-on-fail
guard. The G5/G6 guards `raise` rather than setting `grounded=False`, so `grounded` only ever
tracks G3 — slightly surprising given the comment block frames G4/G5/G6 as grounding guards
too. Not a bug (the raises fail closed correctly), but the `grounded` semantic ("did a guard
rewrite this?") silently excludes the rail rejections.
**Fix:** A one-line comment clarifying that `grounded` reflects only the in-place G3 rewrite
(rail rejections fail closed to AuthoredFallback, never returning a `grounded` line) would
remove the ambiguity.

### IN-03: Comment/code count mismatches ("19 baa ids", "6 base fields", "ten fields")

**File:** `server/app/curriculum.py:19`, `server/app/schema.py:17,56`, `lib/tutor/tutor_facts.dart:22`
**Issue:** Several docstrings cite counts that have drifted from the code: `curriculum.py`
says "the 19 `baa.*` exercise ids" (the seed `exercise_ids` count is what it is — verify);
`schema.py` calls the whitelist "the 6 base fields" while `TutorFactsIn` has 6 base + 2
enlarged + 2 graph = 10 fields, and the matching `tutor_facts.dart` toMap emits 10. The Dart
header says "ten whitelisted … fields" (correct) but also "the eight base fields plus the
two." These are harmless but make the non-PII contract harder to audit precisely.
**Fix:** Normalize the counts in the docstrings to the actual field list so the GROUND-02
audit trail is exact.

### IN-04: `_PendingSelector` conflates "graph loading" with "graph failed to load"

**File:** `lib/tutor/exercise_selector_provider.dart:112-133`
**Issue:** `exerciseSelectorProvider` returns `_PendingSelector` for *both* the loading state
and the error/`orElse` state. A genuine asset-load failure therefore looks identical to a
transient loading state (selection silently returns null forever), with no surfaced signal
that the durable graph could not be parsed. Calm degradation is intended, but an error and a
slow load are different operational conditions.
**Fix:** Keep the calm UI, but log/telemeter the `error` branch distinctly so a broken
bundled asset is observable in the field rather than indistinguishable from "still loading."

### IN-05: `letter_unit_screen.dart` import grouping is slightly out of order

**File:** `lib/features/letter_unit/letter_unit_screen.dart:25-40`
**Issue:** Project imports are not consistently ordered (`model_download_service.dart` sits
between `models/letter.dart` and `models/letter_unit.dart`), splitting the `models/` group.
Cosmetic; `flutter analyze` with `directives_ordering` would flag it.
**Fix:** Group the `models/` imports together and order the rest per the project's lint rule.

---

## Verification notes (what was checked and found clean)

- **Non-PII whitelist:** `TutorFacts.toMap`/`AttemptFact.toMap` emit only derived scalars and
  id/tag string-lists; `buildTutorFacts`'s signature accepts no stroke/Offset/profile
  parameter; `LetterGraphPosition`/`LetterExerciseReps` store only ids/counts/timestamps. No
  raw-geometry or child-name leak path was found across the wire or into Drift. Clean.
- **Server fail-closed rail:** `curriculum.py`'s empty-graph degrade (G6 rejects, G4 still
  bounds) and `plan.py`'s post-parse G4/G5/G6 + G3 raises-to-AuthoredFallback are correct;
  backward remediation (a lower tier of a reached competency) is correctly legal in both the
  Python rail and the Dart `isLegalSelection` mirror.
- **Anti-gamification deletion:** the old `atMastery → recordMastery(cleanReps:0)` auto-write
  is gone; `goTo`/`advance` carry no mastery write. (The replacement is non-functional — see
  CR-02 — but the navigation-grants-star bug itself is removed.)
- **Migration:** the schemaVersion 5 bump and version-guarded `createTable` adds for
  `LetterGraphPosition`/`LetterExerciseReps` are idempotent and touch no existing rows.

_Reviewed: 2026-06-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
