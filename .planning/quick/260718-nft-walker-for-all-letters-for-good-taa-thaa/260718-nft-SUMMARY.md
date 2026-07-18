# Quick 260718-nft — Walker for all graph letters (taa/thaa) — SUMMARY

## Task 1 — Un-gate graph selection from the agent path (walker for all graph letters)

### The bug (verified on the owner's iPad, 2026-07-18)
thaa presented with the correct Phase-19 chrome but PROGRESSED via the OLD static
section walk. Root cause: `_isAgentPath => widget.letter.id == 'baa'` in
`exercise_scaffold.dart` conflated TWO axes — the baa-only server/agent legs AND
graph SELECTION (`beginSelection` + `selectNextWhenDecided`). For any non-baa graph
letter the walker never ran, so `controller.selectionActive` never flipped,
`nextReady` stayed null, and the screen's `_advance` never entered the presenter →
static `_section` walk. Secondary: `start()` awaited the graph future ONLY when a
saved cursor existed, so a first visit's synchronous `.asData?.value` read raced to
null → static fallback even if un-gated.

### `_isAgentPath` use-site classification (audit — every site classified before touching)

| Line* | Use | Classification | Action |
|------|-----|----------------|--------|
| 439  | `bool get _isAgentPath => letter.id == 'baa'` | definition (AGENT axis) | KEPT baa-only; NEW `_isGraphRailed` getter added beside it |
| 585  | `selectionBegan = _isAgentPath && graphId != null` → drives `beginSelection` (walker candidate set + cursor sync) | **GRAPH** | **Changed → `_isGraphRailed`** |
| 598  | `if (_isAgentPath)` → publishes Teacher's-Eye `TutorInsight` (arc/whyFacts) | AGENT (demo/teacher-eye) | KEPT baa-only |
| 624  | `_isAgentPath ? _legalNextExerciseIds() : const []` → coach FACTS `legalNextExerciseIds` fallback | AGENT (coach payload; ignored by AuthoredFallbackBrain) | KEPT baa-only |
| 628  | `profile: _isAgentPath ? controller.profileFacts() : null` → coach FACTS profile | AGENT (coach payload) | KEPT baa-only |
| 636  | `brain = _isAgentPath ? RemoteAgentBrain : AuthoredFallbackBrain` | AGENT (brain selection) | KEPT baa-only |
| 656  | `if (_isAgentPath && graphId != null)` → `controller.selectNextWhenDecided(...)` (flips selectionActive, sets nextReady, drives walker) | **GRAPH** | **Changed → `_isGraphRailed`** |
| 676  | `if (_isAgentPath && plan?.nextExerciseId != null)` → merge agent pick into Teacher's-Eye | AGENT (agent plan acceptance / demo) | KEPT baa-only |
| 696  | `line.isNotEmpty ? line : (_isAgentPath ? '' : _floorLineFor(result))` → agent-line-only voice | AGENT (agent-line-only feedback) | KEPT baa-only |
| 884  | `_TutorColumn(isAgentPath: _isAgentPath)` → bubble shows agent-line-only | AGENT (agent-line-only feedback) | KEPT baa-only |
| 896  | `if (_isAgentPath && kDemoMode) _teacherEye()` → demo Teacher's-Eye strip | AGENT (demo chrome) | KEPT baa-only |
| 963  | `(_isAgentPath && !_isTeachCard) ? Row(... TeacherMarginPanel ...)` → Teacher's Margin beside canvas | AGENT (teacher-eye/margin) | KEPT baa-only |
| 1115 | `footLine = _isAgentPath ? (agentLine ?? '') : state.line` → agent-line-only bottom bar | AGENT (agent-line-only feedback) | KEPT baa-only |

*line numbers are pre-edit positions.

**Only the two GRAPH sites (585, 656) were changed** — both selection-only. Every
AGENT/server/teacher-eye/agent-line site stays gated to baa, so baa's behavior is
byte-identical: facts payload, agent plan acceptance, `_legalNextExerciseIds()`
payload, profile facts, teacher-eye, and the agent-line-only feedback all still run
only for baa.

### What changed
1. **`lib/features/letter_unit/widgets/exercise_scaffold.dart`** — added
   `bool get _isGraphRailed` (`curriculumGraphProvider(letterId).asData?.value != null`).
   Repointed the two selection gates (`selectionBegan` and the
   `selectNextWhenDecided` call) from `_isAgentPath` to `_isGraphRailed`. For a
   non-agent graph letter, `decisionFuture` is `AuthoredFallbackBrain`'s
   `PresentActivity` (plan == null), so `RouterExerciseSelector` falls straight to
   the offline `CurriculumGraphWalker` — graph-driven selection, zero server call.
2. **`lib/features/letter_unit/letter_unit_controller.dart`** — `start()` now warms
   the per-letter graph UNCONDITIONALLY (`try { await curriculumGraphProvider(letterId).future } catch (_) {}`)
   right after resolving the child profile, so the scaffold's synchronous
   `.asData?.value` reads see the graph on a first visit. Missing-graph letters
   (alif/taa) load-fail harmlessly → `.asData` stays null → static flow, no crash.
3. **`test/features/letter_unit/thaa_walker_progression_test.dart`** (NEW) — pins
   PROGRESSION through the live apply path (`WriteSurface.onResult == _onResult`),
   not presentation:
   - PASS from `thaa.traceLetter.isolated` → cursor advances to the walker's
     `nextForward` (`thaa.traceLetter.initial`) + `selectionActive` becomes true;
   - FAIL from `thaa.writeWord.dictation` (copyWrite/ghayrManzur) → cursor routes to
     the walker's one-tier-down remediation (`thaa.writeWord.copy`, manzur); the
     `SelectionPolicy` candidate set is cross-checked to contain the remediation;
   - baa regression: a thaa mount never builds the agent-only `TeacherMarginPanel`,
     but the `WriteSurface` still renders (graph-railed + graded).
   The expected walker/remediation ids are computed independently from the real
   thaa graph so the pin is robust, not a hardcoded guess.

### Graceful degrade (alif/taa — no graph asset)
Only `graphs/baa.json` and `graphs/thaa.json` exist. For alif/taa the provider
load-fails → `_isGraphRailed` false → `selectionBegan`/`selectNextWhenDecided` skip →
the static section flow runs exactly as before. No crash, no behavior change.

### Verification
- `flutter analyze lib/features/letter_unit/widgets/exercise_scaffold.dart lib/features/letter_unit/letter_unit_controller.dart` → **No issues found.**
- `flutter analyze` on all 3 files (incl. the new test) → **No issues found.**
- `flutter test test/features/letter_unit/thaa_walker_progression_test.dart` → **3/3 pass.**
- `flutter test test/features/letter_unit/` → **152 pass, 1 fail.** The sole failure
  is `meet_section_test.dart` Test 1 (`img.door`) — a KNOWN pre-existing failure on
  the ignore list, unrelated to this change. All baa selection suites
  (`agent_pick_live_path_test`, `fail_path_selection_test`, `live_selection_shell_test`,
  `same_id_represent_test`, `resume_cold_boot_test`, `exercise_scaffold_cutover_test`,
  `live_fail_streak_scenario_test`) stay green.

### Commit
`05834b9` (landed by the orchestrator after the classifier recovered — the executor's
commit window was blocked by the claude-fable-5 outage).

### Orchestrator completion record (both tasks)
- Task 1 commit: `05834b9` — gate split + graph warm + progression test (3/3).
- Task 2 commit: `6640cc6` — taa/thaa isolated bowl := baa's 12-pt bowl + reproducer script (--check green) + 6 bowl-pin tests (13/13 file total).
- Full suite: **924 pass / 7 fail — all 7 the KNOWN pre-existing set; zero new regressions.**
- Prod Firestore re-seed (owner-directed "fix for good"): "Seeded 28 letters, 28 lessons, and meta/toleranceRamp idempotently." REST readback: taa isolated strokes=3 stroke[0]=12pt curve; thaa strokes=4 stroke[0]=12pt curve; baa strokes=2 stroke[0]=12pt curve — all three share the bowl.

---

## Task 2 — taa/thaa isolated bowl = baa's bowl (data change + test)

### The change (owner-directed, 2026-07-18)
ب ت ث share the **same bowl body**; only the dots differ (baa: one below; taa: two
above; thaa: three above). The owner's authored isolated bodies for taa and thaa
kept **failing his on-device traces** against the scorer, so he directed that both
isolated-form body strokes be replaced with a deep copy of baa's validated bowl.

In `assets/curriculum/letters.json` → `contextualForms.isolated.referenceStrokes[0]`:

| Letter | Before (body stroke[0]) | After (body stroke[0]) | Dot strokes |
|--------|--------------------------|-------------------------|-------------|
| baa (donor) | 12 pts, `type: curve` | **unchanged** (read-only donor) | 1 dot (below) — unchanged |
| taa | 9 pts, `type: curve` | **12 pts, `type: curve`** (= baa) | 2 dots (`dot_right` 0.523,0.408 / `dot_left` 0.459,0.407) — **unchanged** |
| thaa | 7 pts, `type: line` | **12 pts, `type: curve`** (= baa) | 3 dots (`dot_right` 0.528,0.436 / `dot_left` 0.464,0.435 / `dot_top` 0.492,0.365) — **unchanged** |

- **Point count per body stroke:** taa 9 → 12, thaa 7 → 12 (both now the baa 12-pt bowl).
- **Whole-object deep copy:** `order`/`label`/`type`/`points`/`direction` all cross,
  so thaa's body `type` flipped `line` → `curve` to match baa (correct — it is the
  same physical bowl motion). taa was already `curve`.
- **Isolated stroke counts preserved:** taa stays **3** strokes (bowl + 2 dots),
  thaa stays **4** (bowl + 3 dots).
- **Nothing else touched:** initial/medial/final forms untouched; every dot stroke
  untouched; `commonMistakes`, `tolerances`, top-level `referenceStrokes`, and all
  `signedOff` flags untouched; the other 25 letters byte-identical.

### Note for the mother's review
This is an owner-directed edit to **her-domain** curriculum data (the pen-path the
child traces). The `signedOff` flags were **deliberately left untouched** — taa's and
thaa's `contextualForms.isolated.signedOff` both remain `false` (draft), so the change
is queued for her formal review; nothing was silently signed off. The rationale is
purely mechanical (ب ت ث share one bowl; the authored variants were mis-scoring on
device), not a pedagogical re-authoring.

### Reproducibility script
`tools/curriculum/copy_baa_bowl_to_taa_thaa.py` — stdlib-only, documented, idempotent,
following the `tools/curriculum/merge_contextual_forms.py` conventions (repo-root via
`parents[2]`, `json.dumps(indent=2, ensure_ascii=False)` for a minimal/stable diff,
`--check` mode). It deep-copies baa's isolated body stroke onto taa/thaa and verifies
the result. `python3 tools/curriculum/copy_baa_bowl_to_taa_thaa.py --check` returns
**exit 0** against the current bundle, proving the hand-edit is byte-identical to the
script's canonical serialization (no whitespace/ordering drift; the whole file
round-trips cleanly).

### What changed (files)
1. **`assets/curriculum/letters.json`** — taa + thaa isolated body strokes replaced
   with baa's 12-pt bowl (2 arrays only; `git diff --stat`: 64 insertions / 32
   deletions, 1 file).
2. **`tools/curriculum/copy_baa_bowl_to_taa_thaa.py`** (NEW) — the reproducible surgery.
3. **`test/curriculum/thaa_contextual_forms_merge_test.dart`** (EXTENDED) — added a
   `taa/thaa isolated bowl = baa isolated bowl` group (6 tests) pinning, from the
   **shipped bundle**: taa.isolated stroke[0] deep-equals baa.isolated stroke[0];
   thaa.isolated stroke[0] deep-equals baa.isolated stroke[0] (incl. the `line→curve`
   type cross); taa keeps 3 strokes + its 2 dots; thaa keeps 4 strokes + its 3 dots;
   the parsed `StrokeSpec` bodies also match (model round-trip); and the touched-form
   `signedOff` flags stay `false`.

### Verification
- `python3 tools/curriculum/copy_baa_bowl_to_taa_thaa.py --check` → **exit 0** (idempotent; edit == script output).
- JSON re-validates (28 letters).
- `flutter test test/curriculum/thaa_contextual_forms_merge_test.dart` → **13/13 pass**
  (7 pre-existing merge invariants + 6 new bowl-copy pins; existing signedOff /
  alif-commonMistakes / nested-stroke-validation invariants all still green — no
  regression).
- `git diff --stat` (unstaged) shows ONLY `assets/curriculum/letters.json` +
  `test/curriculum/thaa_contextual_forms_merge_test.dart`; the new script is the only
  new untracked file. The Task-1 staged files (`lib/features/letter_unit/*`,
  `test/features/letter_unit/thaa_walker_progression_test.dart`) were **not** touched.

### Commit + Firestore seed
**Deferred to the orchestrator.** This task performed the data change + test only —
per instruction it did NOT commit, stage, or run the prod Firestore re-seed. The
orchestrator does both: the atomic commit (`assets/curriculum/letters.json` + the
extended test + the new script) and the owner-directed prod re-seed
(`cd tools/firebase && GOOGLE_CLOUD_PROJECT=qalam-app-bd7d0 <venv>/bin/python
seed_firestore.py`, then a REST readback of `letters/taa` and `letters/thaa` asserting
isolated stroke[0] point count == 12).
