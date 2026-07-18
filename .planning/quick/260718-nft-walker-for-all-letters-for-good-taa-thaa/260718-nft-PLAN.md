---
phase: quick-260718-nft
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
requirements: [WALKER-ALL-LETTERS, TAA-THAA-BOWL]
files_modified:
  - lib/features/letter_unit/widgets/exercise_scaffold.dart
  - lib/features/letter_unit/letter_unit_controller.dart
  - test/features/letter_unit/thaa_walker_progression_test.dart
  - assets/curriculum/letters.json
  - test/curriculum/thaa_contextual_forms_merge_test.dart (or a sibling test)
must_haves:
  truths:
    - "A thaa PASS advances to the WALKER's next node through the live scaffold apply path — never the static section order (pinned by a progression test, not a presentation test)"
    - "A thaa FAIL routes through the walker's remediation (one tier down / drill-in-place candidate set)"
    - "Baa's agent/server path is byte-identical in behavior: facts payload, agent plan acceptance, teacher eye, agent-line-only feedback all still gated to baa"
    - "Letters WITHOUT a graph asset (alif, taa) keep the current static flow with graceful degrade — no crash, no behavior change"
    - "taa.isolated and thaa.isolated contextualForms stroke[0] deep-equal baa.isolated stroke[0] (the bowl); their dot strokes and all other forms unchanged"
    - "Prod Firestore letters/{taa,thaa} carry the updated isolated stroke (REST readback)"
  artifacts:
    - path: "test/features/letter_unit/thaa_walker_progression_test.dart"
      provides: "live-path PROGRESSION pin (pass→walker-next, fail→remediation) for a graph letter that is NOT baa"
---

<objective>
Owner directives (2026-07-18, after on-device thaa test):
1. Graph-driven progression for ALL letters with a graph, for good. The bug:
   exercise_scaffold.dart:439 `_isAgentPath => widget.letter.id == 'baa'` gates BOTH the
   server/agent legs (correctly baa-only) AND `selectionBegan` (line ~585) — so every
   non-baa letter silently falls back to the static section walk.
2. taa/thaa isolated-form body stroke keeps failing the scorer — replace it with baa's
   isolated bowl stroke (ب ت ث share the bowl body; only the dots differ). Then re-seed
   prod Firestore (owner-directed; the device reads letters Firestore-first).
</objective>

<tasks>

<task type="auto">
  <name>Task 1: Un-gate graph selection from the agent path (walker for all graph letters)</name>
  <files>lib/features/letter_unit/widgets/exercise_scaffold.dart, lib/features/letter_unit/letter_unit_controller.dart, test/features/letter_unit/thaa_walker_progression_test.dart</files>
  <action>
Split the conflated gate in exercise_scaffold.dart:
- `_isAgentPath` (== 'baa') KEEPS: the server facts payload + RemoteAgentBrain leg,
  agent plan.nextExerciseId acceptance, `_legalNextExerciseIds()` payload, profile facts,
  teacher-eye demo widget, and the "agent line only / no instant authored line" feedback
  behavior (~lines 598/624/628/636/656/676/696/884/896/963 — audit each use and classify).
- NEW predicate (e.g. `_isGraphRailed`): true when the letter's graph is available
  (curriculumGraphProvider(widget.letter.id) has data). `selectionBegan` / `beginSelection`
  / graph-cursor sync / walker-driven next-question presentation run under IT — for ANY
  graph letter. The offline CurriculumGraphWalker supplies selection for non-agent letters.
- Fix the cold-load race: letter_unit_controller.start() must warm the graph
  unconditionally (`try { await ref.read(curriculumGraphProvider(_letterId).future); } catch (_) {}`)
  — today it only awaits when a saved cursor exists, so a first visit's synchronous
  `.asData?.value` read at ~:355 races to null → static fallback.
- Missing-graph letters (alif/taa today) degrade exactly as now: static flow, no crash.

TEST (the day's hard lesson — pin PROGRESSION, not presentation):
`test/features/letter_unit/thaa_walker_progression_test.dart`, modeled on the existing
live-path harness but driving SCORED RESULTS through the scaffold's real apply path:
  (a) mount a thaa graded node via presentGraphExercise with the real thaa graph;
  (b) apply a PASS → assert the next presented/selected node is the WALKER's nextForward
      from the thaa graph cursor (assert the actual node id), NOT the static section
      successor when they differ (pick a cursor node where they DO differ, or assert via
      the controller's selection candidates/cursor state);
  (c) apply a FAIL → assert the candidate set / next pick is the walker's remediation
      (one tier down same competency, or drill-in-place at floor);
  (d) baa regression: the agent path still gates (_isAgentPath true only for baa) — a
      compile-time/widget assertion that a thaa mount never builds the teacher-eye/agent
      legs, plus the existing baa suites stay green.
Run: flutter analyze on both lib files; flutter test test/features/letter_unit/ — commit
atomically (conventional message, quick-260718-nft).
  </action>
  <verify>flutter analyze (2 files) clean; flutter test test/features/letter_unit/ green (known pre-existing failures excluded); the new progression test proves pass→walker-next and fail→remediation for thaa.</verify>
</task>

<task type="auto">
  <name>Task 2: taa/thaa isolated bowl = baa's bowl + prod re-seed</name>
  <files>assets/curriculum/letters.json, test/curriculum/ (extend or sibling), tools/curriculum/ (one-shot script ok)</files>
  <action>
In assets/curriculum/letters.json contextualForms: set taa.isolated.referenceStrokes[0]
and thaa.isolated.referenceStrokes[0] to a DEEP COPY of baa.isolated.referenceStrokes[0]
(the 12-point bowl). Keep taa's 2 dot strokes and thaa's 3 dot strokes untouched; keep
initial/medial/final forms untouched; keep every other field (signedOff included) untouched.
Owner-directed data change (his isolated bodies kept failing the scorer on device) — note
in the SUMMARY for the mother's review. Implement via a small documented script (repo
convention: Python stdlib, tools/curriculum/) so it is reproducible; verify with git diff
that ONLY the two arrays changed.
Add/extend a test pinning: taa.isolated stroke[0] == thaa.isolated stroke[0] ==
baa.isolated stroke[0] (deep equality from the shipped bundle).
Then RE-SEED prod Firestore letters (owner-directed this session; the device reads
letters Firestore-first): `cd tools/firebase && GOOGLE_CLOUD_PROJECT=qalam-app-bd7d0
/tmp/l12-seed/bin/python seed_firestore.py` (venv exists from earlier; if gone, recreate:
python3 -m venv /tmp/l12-seed && pip install -r tools/firebase/requirements.txt; ADC is
live). REST readback: GET letters/taa and letters/thaa, assert isolated stroke counts and
that isolated stroke[0] point count matches baa's bowl (12).
Commit the data change + test atomically.
  </action>
  <verify>Diff shows only the two stroke arrays changed; new/extended test green; seed output "Seeded 28 letters..."; readback confirms.</verify>
</task>

</tasks>

<success_criteria>
- thaa progresses graph-driven on device exactly like baa (walker selection + remediation), baa unchanged, alif/taa static-degrade unchanged.
- taa/thaa isolated body = baa bowl in bundle AND prod Firestore.
- Full flutter test: no NEW failures beyond the known pre-existing set (alif_reference cluster, all_letters_validation signedOff, reference_overlay golden, meet_section img.door, mastery_celebration golden, glyph_audit golden).
</success_criteria>
