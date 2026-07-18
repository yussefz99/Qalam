---
phase: quick-260718-il4
plan: 01
subsystem: curriculum / letter-unit / journey
tags: [all-letters-live, multi-letter-graph, thaa-promotion, per-letter-provider, riverpod-family]
requires:
  - "18.1 thaa drafts (docs/curriculum/drafts/exercises/04-thaa.exercises.json + graphs/04-thaa.graph.json)"
  - "tools/content/arabic.py decompose (stdlib-only)"
  - "the signed baa curriculum graph (assets/curriculum/curriculum_graph.json)"
provides:
  - "tools/content/promote_letter.py — reusable, idempotent, letter-parameterized draft->live promoter (Stage 2 runs it for 24 more)"
  - "assets/curriculum/graphs/{baa,thaa}.json — per-letter curriculum graphs"
  - "curriculumGraphProvider as FutureProvider.family<CurriculumGraph,String> keyed by letterId"
  - "a live, reachable, playable thaa Letter Unit (Journey node -> /unit?letter=thaa)"
affects:
  - "every letter-unit consumer of the curriculum graph (controller/screen/scaffold/demo)"
  - "the learned-letters lint (now covers every live unit) + a new graph-asset parity guard"
tech-stack:
  added: []
  patterns:
    - "Riverpod FutureProvider.family keyed by letterId for per-letter asset loading (keepAlive)"
    - "idempotent id-keyed replace-in-place JSON promotion (never blind append)"
    - "graph-as-single-source: units.json generated from the graph + question types"
key-files:
  created:
    - tools/content/promote_letter.py
    - tools/content/test_promote_letter.py
    - assets/curriculum/graphs/baa.json
    - assets/curriculum/graphs/thaa.json
    - test/features/letter_unit/per_letter_graph_provider_test.dart
    - test/curriculum/graph_asset_parity_test.dart
    - test/features/letter_unit/thaa_unit_live_path_test.dart
  modified:
    - assets/curriculum/exercises.json
    - assets/curriculum/units.json
    - lib/tutor/exercise_selector_provider.dart
    - lib/features/letter_unit/letter_unit_controller.dart
    - lib/features/letter_unit/letter_unit_screen.dart
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - lib/demo/seeded_demo_state.dart
    - lib/features/journey/journey_screen.dart
    - pubspec.yaml
    - test/curriculum/learned_letters_lint_test.dart
    - test/data/curriculum_repository_v2_test.dart
    - "11 test/features/letter_unit/*.dart (mechanical family-arity override sweep)"
    - test/features/journey/journey_screen_test.dart
decisions:
  - "_presentedExerciseIds() returns the scoped baa 8-id set ONLY when letterId=='baa' (documented legacy exception); any other letter returns const {} so mastery falls back to the full-graph isMasteryMet over that letter's OWN essential nodes (owner amendment 1)"
  - "thaa promoted WHOLLY signedOff:false (exercise- and file-level); the mother reviews via the 18.1 packets"
  - "graphs/baa.json is a byte-parity DUPLICATE of curriculum_graph.json (server + baa lint still read the latter this stage); a parity test guards drift until Stage 2 unifies the server"
  - "10 thaa reaching-ahead cards stay LIVE with an owner-approved-style exception (mirrors baa's owner-restored cards); listed below for the mother's review packet"
metrics:
  duration: "~1 session (continuation of a prior partial session)"
  completed: 2026-07-18
---

# Quick Task 260718-il4: Stage 1 all-letters-live — multi-letter graph provider + thaa promotion Summary

Per-letter curriculum-graph loading (`curriculumGraphProvider` is now a
`FutureProvider.family` keyed by letterId, loading `graphs/<letterId>.json`) plus a
reusable Python promotion script that lifts thaa (ث) from the 18.1 drafts into the
live app — so a thaa Letter Unit runs end-to-end exactly like baa: reachable from
the Journey map, mounting through the live `presentGraphExercise` seam with the
Phase-19 instruction bar + write-surface stimulus, and gated for mastery on its OWN
graph, never a silent baa default.

## What shipped

**Task 1 — reusable letter-promotion script + thaa promoted into all live assets**
(committed in a prior session as `50bcf12`, verified this session):
- `tools/content/promote_letter.py`: idempotent, `--letter`-parameterized promoter.
  It globs the draft by letter suffix, ENRICHES every draft exercise with `letters`
  (via `arabic.decompose` of the expected text, deduped; `[letterId]` for
  teachCard/placeholder) and per-type `criteria` (mirroring the signed baa map),
  forces `signedOff:false` everywhere, id-keyed REPLACE-in-place appends into
  `exercises.json`, GENERATES the `units.json` entry from the graph's exercise
  types (type→section map), and writes `graphs/<letter>.json`. A `--migrate-baa`
  mode writes the byte-parity `graphs/baa.json`.
- 19 thaa exercises + a generated 6-section thaa unit + `graphs/thaa.json`.
- `tools/content/test_promote_letter.py`: idempotence, enrichment parity, baa
  spot-check (5 tests, green).

**Task 2 — per-letter graph provider (family) + consumer/test migration + mastery guard**
(committed this session as `44fdd96`):
- `curriculumGraphProvider` → `FutureProvider.family<CurriculumGraph,String>`
  (keepAlive), loading `assets/curriculum/graphs/$letterId.json`.
  `exerciseSelectorProvider` is the matching `Provider.family`.
- All lib consumers pass their own letterId: controller (5 reads → `_letterId`),
  screen (`widget.letterId`), scaffold (3 reads → `widget.letter.id`). Demo points
  `kSeedDemoGraphAsset` at the migrated `graphs/baa.json` (demo stays baa-scoped).
- `pubspec.yaml` bundles `assets/curriculum/graphs/` explicitly (a bare dir entry
  does NOT include subdirectories → rootBundle reads would fail at runtime).
- Per-letter mastery guard (owner amendment 1): `_presentedExerciseIds()` returns
  the scoped baa 8-id set ONLY when `_letterId=='baa'`; any other letter returns
  `const {}` so `recordMasteryIfMet` falls back to full-graph `isMasteryMet` over
  THAT letter's essential nodes.
- Mechanical family-arity override sweep across 11 existing `letter_unit` tests
  (`(ref)` → `(ref, letterId)`); no assertion changed. New
  `per_letter_graph_provider_test.dart` pins baa/thaa load distinctness, per-letter
  railing, the bundled thaa asset, and owner amendment 1 (a thaa star requires the
  thaa graph's essential nodes, never baa ids).

**Task 3 — thaa reachability + parity guard + learned-letters coverage + live-path test**
(committed this session as `ff77467`):
- Journey reachability: `const _fullUnitLetters = {'alif','baa','taa','thaa'}` (one
  source of truth for both the `tappable` predicate and the onTap route) → a thaa
  node opens `/unit?letter=thaa`. Every other letter keeps the S1-09 unlock gate.
- `graph_asset_parity_test.dart`: `graphs/baa.json` deep-equals
  `curriculum_graph.json` (the Stage-1 duplication drift guard).
- Extended `learned_letters_lint_test.dart`: covers EVERY live unit graph.
  signedOff:true (baa) stays ENFORCED (tuned subset rule + owner-approved
  exceptions unchanged); signedOff:false (thaa) is ACKNOWLEDGED — non-vacuity +
  reaching-ahead surfaced via `printOnFailure` (documented, never a failure/silent
  skip; auto-enforces when the mother signs). Plus a COVERAGE assertion so a new
  promoted letter can't slip through unlinted.
- `thaa_unit_live_path_test.dart`: mounts a REAL promoted thaa graded node
  (`thaa.completeWord.middle`) through the live `presentGraphExercise` seam
  (loading the thaa Letter/Exercise/Unit/graph from the bundled assets) and asserts
  the instruction bar + WriteSurface render for thaa exactly as for baa.
- `flutter build ios --no-codesign` succeeds.

## Per-task commit hashes

| Task | Commit | Notes |
|------|--------|-------|
| 1 — promotion script + thaa assets | `50bcf12` | committed prior session; re-verified idempotent + pytest green this session |
| 2 — per-letter provider + consumer/test migration + mastery guard | `44fdd96` | this session |
| 3 — reachability + parity + lint coverage + live-path test + iOS build | `ff77467` | this session |
| deviation — v2 repo test reconciliation (Rule 1) | `<PENDING — see Deviations>` | count 52→71 + thaa-scoped unsigned-core guard |

## Test results

- **Task 1 gate:** `promote_letter --letter thaa` + `--migrate-baa` idempotent (no
  asset drift); `pytest content/test_promote_letter.py -q` → **5 passed**.
- **Task 2 gate:** `flutter analyze` (2 lib files) clean; `flutter test
  test/features/letter_unit/ test/curriculum/` → all letter_unit tests green
  (family sweep compiles), curriculum green except the known pre-existing set.
  `per_letter_graph_provider_test.dart` → 4 passed.
- **Task 3 gate:** `flutter test` (3 new/changed files) → 4 passed;
  `flutter test test/features/journey/` → 10 passed (Test 5 reconciled);
  `flutter build ios --no-codesign` → `✓ Built build/ios/iphoneos/Runner.app`.
- **Whole-plan `flutter test`:** **893 passed, 8 failed.** All 8 failures are on the
  owner-locked KNOWN pre-existing list (none are this plan's regressions):
  - `alif_reference_test.dart` (2) — alif_reference cluster.
  - `all_letters_validation_test.dart` (1) — signedOff (alif drift).
  - `reference_overlay_golden_test.dart` (1) — reference_overlay golden.
  - `meet_section_test.dart` (1) — meet_section img.door.
  - `mastery_celebration_golden_test.dart` (1) — mastery_celebration golden (font drift).
  - `glyph_audit_golden_test.dart` (1) — glyph_audit golden (font drift).
  - `curriculum_repository_v2_test.dart` (1) — **was NOT on the known list; it was
    a stale hardcoded count caused by Task 1's thaa promotion (52→71) and is now
    FIXED (see Deviations). It is green after the fix.**
- `flutter analyze` (full): 70 issues, ALL pre-existing warnings/infos in unrelated
  test files (practice/router/screens/tutor `scoped_providers_should_specify_
  dependencies`, `unnecessary_underscores`, an unused http import) — none in this
  plan's files; no analyzer errors.

## Reaching-ahead thaa cards (for the mother's review packet)

Learned set for the thaa unit = introOrder ≤ 4 = {alif, baa, taa, thaa}. These 10
LIVE thaa cards demand letters BEYOND that set. Per owner amendment 3 they stay LIVE
with an owner-approved-style exception (mirroring the owner-restored baa cards),
listed here for the mother to review/sign or rewrite:

| Card | Reaching-ahead letters |
|------|------------------------|
| `thaa.writeWord.dictation`  | ayn, laam |
| `thaa.writeWord.copy`       | laam, jeem |
| `thaa.writeWord.picture`    | ayn, laam |
| `thaa.connectWord.thalab`   | ayn, laam |
| `thaa.connectWord.thalj`    | laam, jeem |
| `thaa.completeWord.middle`  | waaw, meem |
| `thaa.transformWord.dual`   | ayn, laam, noon |
| `thaa.fillBlank.adjective`  | ayn, laam |
| `thaa.buildSentence.hear`   | laam, ayn, kaaf, yaa, raa |
| `thaa.buildSentence.picture`| laam, ayn, jeem, meem, yaa |

(The other 9 thaa cards — teachCard, the three traceLetter forms, the three
writeLetter forms, `transformWord.plural`, `transformWord.opposite` — are within the
learned set.)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reconciled the schema-v2 repository bundle-fallback test for the thaa promotion**
- **Found during:** whole-plan `flutter test` (a 9th failure beyond the 8 expected).
- **Issue:** `test/data/curriculum_repository_v2_test.dart` hardcoded
  `expect(exercises, hasLength(52))` and an exact 5-id `unsignedCore` set. Task 1
  (committed `50bcf12` in a prior session) appended 19 thaa exercises (all
  `signedOff:false` by owner lock), so the count is now 71 and thaa's 19 unsigned
  configs entered the unsigned-core set — both assertions failed. This is a direct
  consequence of the plan's own Task 1, not a pre-existing failure.
- **Fix:** count `52`→`71`; scoped the `unsignedCore` drift guard to EXCLUDE thaa
  (`!e.id.startsWith('thaa.')`) — Stage 1 promoted thaa wholly unsigned by design,
  so it is not "silent drift" in the signed baa/taa/alif demo core (which the guard
  was tuned for). thaa is covered instead by the learned-letters lint + the
  graph-asset parity guard. Documented the rationale inline.
- **Files modified:** `test/data/curriculum_repository_v2_test.dart`
- **Commit:** `<PENDING — dedicated fix commit; see completion notes>`

**2. [Rule 1 - Bug] Reconciled journey Test 5 for thaa's new full-unit routing**
- **Found during:** Task 3 (`flutter test test/features/journey/`).
- **Issue:** Test 5 tapped the current thaa (ث) node and expected
  `Practice lesson_04` — the generic practice route thaa used BEFORE it had a unit.
  The Stage-1 reachability change (correctly) routes a thaa node to
  `/unit?letter=thaa`, so the stale assertion failed.
- **Fix:** updated Test 5 to assert `Unit thaa` (mirroring Test 4 for taa), with a
  documented rationale.
- **Files modified:** `test/features/journey/journey_screen_test.dart`
- **Commit:** `ff77467` (Task 3).

## NOT done (per owner lock — confirmed)

- Server NOT deployed; `server/app/curriculum_data/generate.py` untouched; tutor
  prompt untouched; nothing under `server/` touched.
- `assets/curriculum/curriculum_graph.json` STAYS PUT (server + baa lint read it);
  `graphs/baa.json` is the parity-guarded duplicate.
- No thaa content flipped to signed; the baa AI-judge path untouched (scorer owns
  thaa pass/fail).
- Micro-drills remain OUT of every graph (thaa carries none).
- ROADMAP.md NOT updated (quick task). No device install (orchestrator handles the
  iPad install).
