---
phase: quick-260720-wcs
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
subsystem: curriculum
tags: [curriculum-graph, mastery, selection, letter-unit, dormancy, starter-unit]
requirements: [F2-interim (owner 2026-07-20), D-16-supersede (owner 2026-07-20)]
files_modified:
  - assets/curriculum/graphs/taa.json
  - assets/curriculum/graphs/thaa.json
  - tools/content/validate.py
  - test/curriculum/learned_letters_lint_test.dart
  - lib/tutor/exercise_selector_provider.dart
  - test/tutor/l3_learned_letters_parity_test.dart
  - tools/firebase/test_seed_curriculum_v2.py
  - assets/curriculum/graphs/jeem.json
  - assets/curriculum/graphs/haa_c.json
  - assets/curriculum/exercises.json
  - assets/curriculum/units.json
  - test/features/letter_unit/taa_live_path_mastery_test.dart
  - test/features/letter_unit/thaa_live_path_mastery_test.dart
  - test/features/letter_unit/jeem_starter_unit_test.dart

must_haves:
  truths:
    - "A child can complete the taa unit to its mastery star (7 live all-essential nodes, reps=1)"
    - "A child can complete the thaa unit to its mastery star (7 live all-essential nodes, reps=1)"
    - "jeem appears as a finishable isolated-form STARTER unit that reaches the star"
    - "haa_c appears as a finishable isolated-form STARTER unit that reaches the star"
    - "No live graph-node card reaches ahead of the learned set — the owner-approved allowlist is EMPTY everywhere and all four wall layers are green"
    - "The canonical baa graph (curriculum_graph.json) and the deployed server data are UNTOUCHED"
  artifacts:
    - path: "assets/curriculum/graphs/taa.json"
      provides: "7-node taa graph (10 reach-ahead word nodes removed; competencies retained)"
      contains: "taa.writeLetter.writeForm"
    - path: "assets/curriculum/graphs/thaa.json"
      provides: "7-node thaa graph (10 reach-ahead word nodes removed; competencies retained)"
      contains: "thaa.writeLetter.writeForm"
    - path: "assets/curriculum/graphs/jeem.json"
      provides: "3-node isolated-form-only jeem starter graph (all essential)"
      contains: "jeem.traceLetter.isolated"
    - path: "assets/curriculum/graphs/haa_c.json"
      provides: "3-node isolated-form-only haa_c starter graph (all essential)"
      contains: "haa_c.traceLetter.isolated"
    - path: "assets/curriculum/units.json"
      provides: "jeem + haa_c unit entries (meet/watchTrace/forms/mastery)"
      contains: "\"letterId\": \"jeem\""
    - path: "assets/curriculum/exercises.json"
      provides: "jeem + haa_c letter-form cards (signedOff:false, letters:[<id>], minCleanReps context)"
      contains: "jeem.writeLetter.writeForm"
    - path: "tools/content/validate.py"
      provides: "OWNER_APPROVED_EXCEPTIONS emptied (0 exempt reach-ahead ids)"
    - path: "test/features/letter_unit/taa_live_path_mastery_test.dart"
      provides: "live-path proof taa reaches the star + advances to thaa"
    - path: "test/features/letter_unit/thaa_live_path_mastery_test.dart"
      provides: "live-path proof thaa reaches the star + advances to jeem"
    - path: "test/features/letter_unit/jeem_starter_unit_test.dart"
      provides: "starter smoke: jeem graph loads, unit routes, selection rails, mastery reachable"
  key_links:
    - from: "lib/tutor/exercise_selector_provider.dart curriculumGraphProvider('jeem')"
      to: "assets/curriculum/graphs/jeem.json"
      via: "per-letter graph asset load"
      pattern: "graphs/.*jeem"
    - from: "lib/data/curriculum_repository.dart getUnitLetterIds()"
      to: "assets/curriculum/units.json jeem + haa_c entries"
      via: "Home/Journey routing"
      pattern: "letterId.*jeem"
    - from: "tools/content/validate.py --gate"
      to: "OWNER_APPROVED_EXCEPTIONS"
      via: "exempt reach-ahead count MUST be 0"
      pattern: "OWNER_APPROVED_EXCEPTIONS"
---

<objective>
Make 6 letters finishable tonight (Technion deadline) by (1) UNLOCKING taa + thaa —
their 10 reach-ahead word cards each go DORMANT (nodes removed from the graphs; configs
stay parked in exercises.json), leaving 7 all-essential letter-form nodes that a child
can clean-rep to the star; and (2) PROMOTING jeem + haa_c as isolated-form-only STARTER
units (both letters have ZERO contextualForms, so isolated form is the only honest scope).

This is the F2-INTERIM mechanism — the mother ruled 2026-07-20 that taa/thaa's reach-ahead
questions must become letter-FORM practice she has not yet authored; until she authors it
they must not run as word cards. This DIRECTLY mirrors quick 260720-up4 (baa dormancy +
terminate-on-mastery-met), which already shipped the graph-node-removal mechanism and the
`_selectNext` termination fix this plan depends on — no source-logic changes here.

Purpose: 6 finishable letters (alif, baa, taa, thaa, jeem, haa_c) for the demo, with the
owner-approved reach-ahead allowlist collapsed to ZERO everywhere (any reach-ahead now
fails the wall by design).

Output: 7-node taa/thaa graphs; 3-node jeem/haa_c starter graphs + units + cards; the
four-layer allowlist emptied 18→0; 3 new live-path/smoke tests; all gates green.
NO server regen, NO Firestore seed, NO Play/webcourse rebuild (freeze intact).
</objective>

<execution_context>
@/Users/mareekhalila/Documents/Qalam/qalam/.claude/get-shit-done/workflows/execute-plan.md
@/Users/mareekhalila/Documents/Qalam/qalam/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/quick/260720-up4-fix-baa-never-advances-dormant-4-reach-a/260720-up4-SUMMARY.md
@assets/curriculum/graphs/taa.json
@assets/curriculum/graphs/thaa.json
@assets/curriculum/units.json
@test/features/letter_unit/baa_live_path_mastery_test.dart

# Reference structures (READ, do not blind-copy):
# - tools/content/promote_letter.py — the enrichment rule (letters + criteria per type)
#   and the type→section map. jeem/haa_c are scoped BELOW its full-draft output.
# - taa live exercise configs in exercises.json (taa.teachCard.meet /
#   taa.traceLetter.isolated / taa.writeLetter.writeForm) are the byte-for-byte template.
# - the alif units.json entry (meet/watchTrace/forms/mastery, no words section) is the
#   proven shape for a form-only letter.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Unlock taa + thaa (dormant the 18 reach-ahead nodes) and empty the four-layer allowlist 18→0</name>
  <files>assets/curriculum/graphs/taa.json, assets/curriculum/graphs/thaa.json, tools/content/validate.py, test/curriculum/learned_letters_lint_test.dart, lib/tutor/exercise_selector_provider.dart, test/tutor/l3_learned_letters_parity_test.dart, tools/firebase/test_seed_curriculum_v2.py</files>
  <action>
Per F2-interim (owner 2026-07-20, superseding D-16). MECHANICAL — mirrors up4 Task 1 exactly.

GRAPH DORMANCY (node removal only — configs STAY in exercises.json, fully reversible):
- `assets/curriculum/graphs/taa.json`: remove these 10 reach-ahead nodes, leaving 7 —
  REMOVE: taa.writeWord.dictation, taa.writeWord.copy, taa.writeWord.picture,
  taa.connectWord.taaj, taa.connectWord.bayt, taa.completeWord.middle,
  taa.transformWord.dual, taa.transformWord.plural, taa.transformWord.opposite,
  taa.fillBlank.adjective.
  KEEP the 7: taa.teachCard.meet + taa.traceLetter.isolated/initial/medial +
  taa.writeLetter.fromSound/fromPicture/writeForm.
- `assets/curriculum/graphs/thaa.json`: remove the matching 10 — thaa.writeWord.{dictation,copy,picture},
  thaa.connectWord.{thalab,thalj}, thaa.completeWord.middle, thaa.transformWord.{dual,plural,opposite},
  thaa.fillBlank.adjective (thaa.transformWord.plural/.opposite are retired null-placeholders — they
  come out too, even though never allowlisted). KEEP the same 7 thaa.* form nodes.
- RETAIN all 5 competency declarations in BOTH graphs (recognize/positionalForms/copyWrite/
  wordBuilding/grammarTransform) even though copyWrite/wordBuilding/grammarTransform become
  node-less — parser-tolerated + reversible, exactly the up4 baa precedent. Add an
  `owner_dormant_2026_07_20` / F2-interim provenance note to each graph's `_meta` block.
- minCleanReps stay 1 on all 7 nodes (mother A2 confirmed). Do NOT touch curriculum_graph.json.

ALLOWLIST 18→ZERO (all four wall layers, so any reach-ahead now fails by design):
- `tools/content/validate.py`: set `_TAA_THAA_D16_EXCEPTIONS` to `frozenset()` (KEEP the symbol —
  it is referenced at the union + reason + report-string sites, and len() self-updates those to 0;
  the seeder imports `OWNER_APPROVED_EXCEPTIONS`, which stays as the now-empty union). Refresh the
  provenance comment block to record the F2-interim dormancy (mirror the up4 `_BAA_D09_EXCEPTIONS` note).
- `test/curriculum/learned_letters_lint_test.dart`: empty BOTH `taaOwnerApprovedExceptions` and
  `thaaOwnerApprovedExceptions` to `const <String>{}`. (The non-rot check requires every allowlisted id
  be a live node — since the nodes are removed AND the allowlist emptied together, this stays consistent.
  Keep the `__parity.taaAtBaa__` parity assertion untouched.)
- `lib/tutor/exercise_selector_provider.dart`: `kApprovedReachAheadExceptions` → `const <String>{}`.
- `test/tutor/l3_learned_letters_parity_test.dart`: change `hasLength(18)` → `hasLength(0)` and the
  `expected` set → empty; drop the now-obsolete 18-id enumeration.
- `tools/firebase/test_seed_curriculum_v2.py`: fixtures are already vacuous (`_BAA_D09_IDS=[]`, no
  taa/thaa assertions) — only refresh the stale comment (line ~56) that claims "the taa/thaa D-16
  exceptions remain in OWNER_APPROVED_EXCEPTIONS" so it reads that the union is now EMPTY. No functional edit.
  </action>
  <verify>
    <automated>python3 -m tools.content.validate --gate</automated>
  </verify>
  <done>taa.json + thaa.json each have exactly 7 nodes; `--gate` exits 0 reporting "owner-approved exceptions (exempt): 0"; the L1 lint, L3 parity, and seed tests are green (verified in Task 3's gate sweep). curriculum_graph.json is byte-unchanged.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Author jeem + haa_c as isolated-form-only STARTER units (letter ids jeem, haa_c)</name>
  <files>assets/curriculum/graphs/jeem.json, assets/curriculum/graphs/haa_c.json, assets/curriculum/exercises.json, assets/curriculum/units.json</files>
  <behavior>
    - `CurriculumGraph.fromJson(graphs/jeem.json)` loads with 3 nodes, all essential (recognize + positionalForms).
    - `getUnitLetterIds()` returns a set that INCLUDES 'jeem' and 'haa_c'.
    - Every jeem/haa_c graph node id resolves to a LIVE exercise config in exercises.json (no dangling → no fallback card).
    - No jeem/haa_c card has a `letters[]` entry beyond its own id → `--gate` still reports 0 exempt reach-ahead ids.
  </behavior>
  <action>
Per owner 2026-07-20 (promote jeem + haa_c as isolated-form-only starters). Letter ids are `jeem`
and `haa_c` (NOT "haa"; haa_f is the OTHER haa, introOrder 26 — untouched).

EVIDENCE + SCOPE (verified): jeem/haa_c letters.json rows carry base referenceStrokes (2 / 1) + 4
commonMistakes but ZERO contextualForms → isolated form is the ONLY honest scope. Their existing full
drafts (docs/curriculum/drafts/{graphs,exercises}/05-jeem.*, 06-haa_c.*) mirror the taa 17/19-node
reach-ahead shape and MUST NOT be promoted wholesale (allowlist is now EMPTY → any reach-ahead card
fails L0/L1). Word-audio (`word.jamal`) and word-images (`img.jamal`/`img.jabal`) do NOT exist — only
letter audio `snd.jeem` / `snd.haa_c` exist. So `writeLetter.fromSound` and `writeLetter.fromPicture`
are OMITTED (they need absent word assets; inventing vocab is banned). Read promote_letter.py's
enrichment rule for the `letters`/`criteria` field shapes, but author the TRIMMED set directly (do NOT
run `promote_letter --letter`, which appends all ~19 reach-ahead cards).

PER LETTER (jeem: char ج, audio snd.jeem; haa_c: char ح, audio snd.haa_c):

exercises.json — append 3 cards each, modeled BYTE-FOR-BYTE on the taa live equivalents, with
`letters:["jeem"]`/`["haa_c"]`, `signedOff:false`, and the taa criteria per type:
  1. `<id>.teachCard.meet` — type teachCard, skill comprehension; prompt = [say "This card just
     teaches — the sound and the shapes.", audio `snd.<id>`, forms {char, forms:["isolated"] ONLY}];
     surface/expected/check/feedback null; criteria []. NO `image` kind (word art absent). If the meet
     widget hard-requires an image or non-isolated forms, SURFACE it rather than inventing vocab — the
     jeem smoke test (Task 3) is the render check.
  2. `<id>.traceLetter.isolated` — type traceLetter, skill formation; prompt [say "Trace <name> —
     isolated form.", audio `snd.<id>`]; surface {mode:trace, unit:glyph, guideForm:isolated, demo:true};
     expected {glyph {char, form:isolated}}; check "glyph"; feedback {pass}; criteria = the 5-stroke set.
  3. `<id>.writeLetter.writeForm` — type writeLetter, skill recall; prompt [say "Write <name> in its
     isolated form."]; surface {mode:write, unit:glyph}; expected {glyph {char, form:isolated}}; check
     "glyph+positionalForm"; feedback {pass}; criteria = the 5-stroke set.

graphs/<id>.json — new asset, `letterId:"<id>"`, `signedOff:false`, tiers ["manqul","manzur","ghayrManzur"],
competencies = ONLY {recognize (essential, prereq []), positionalForms (essential, prereq [recognize])},
nodes = the 3 above, ALL essential, tier null, minCleanReps 1 (A2 precedent for demo-era letters — FLAG
for the mother's packet). Add an F2-interim/starter provenance `_meta` note.

units.json — append a `<id>` entry shaped like alif's (meet → watchTrace → forms → mastery, NO
words/listenWrite sections, NO presentedEssentials so the full-graph essential check applies):
meet:[<id>.teachCard.meet], watchTrace:[<id>.traceLetter.isolated], forms:[<id>.writeLetter.writeForm],
mastery:[].

FIRESTORE CAUTION (verify only — do NOT seed, do NOT fix): device reads `letters` Firestore-first;
jeem/haa_c docs are June-14 vintage but the bundle rows were touched by post-June-14 commits
(260718-l12 / 260718-nft). Diff the jeem/haa_c ROWS specifically against the June-14 seed
(`git log -p -- assets/curriculum/letters.json` around those rows). If the bundle base strokes diverged
for jeem/haa_c, SURFACE it in the SUMMARY (device would render the old Firestore strokes; the
contextualForms splice does not apply to base strokes). Do not silently change letters.json.
  </action>
  <verify>
    <automated>flutter test test/features/letter_unit/jeem_starter_unit_test.dart</automated>
  </verify>
  <done>graphs/jeem.json + graphs/haa_c.json each load as a 3-node all-essential graph; getUnitLetterIds() includes both; every graph node resolves to a live exercises.json card; `--gate` still reports 0 exempt reach-ahead ids; the jeem starter smoke test (Task 3) passes. Firestore vintage finding recorded (or "no divergence") in the SUMMARY.</done>
</task>

<task type="auto">
  <name>Task 3: Live-path + smoke tests and the full gate sweep</name>
  <files>test/features/letter_unit/taa_live_path_mastery_test.dart, test/features/letter_unit/thaa_live_path_mastery_test.dart, test/features/letter_unit/jeem_starter_unit_test.dart</files>
  <action>
Model all three on `test/features/letter_unit/baa_live_path_mastery_test.dart`. HARD RULES: exactly ONE
`testWidgets` per file (rootBundle deadlock — a 2nd asset fetch stalls forever), use the `_awaitPumping`
dual-drain helper, and run `flutter gen-l10n` before widget tests on a fresh worktree (the generated
l10n is gitignored).

- `taa_live_path_mastery_test.dart`: load `assets/curriculum/graphs/taa.json` (assert nodes hasLength(7),
  essentialNodes hasLength(7)); use `letterUnitDataProvider('taa')`; seed alif+baa+taa mastered as the
  progression state; seed all 7 taa essential nodes at reps=1; drive a scored PASS through
  `WriteSurface.onResult`; assert `_selectNext` terminates (nextReady resolves null → Mastery), the star
  row persists, and today's letter advances to thaa (the next by introOrder, computed from letters.json —
  never hardcoded). taa has NO presentedEssentials → the controller uses the full-graph essential check.
- `thaa_live_path_mastery_test.dart`: same shape against `graphs/thaa.json` (7 nodes); advance target = jeem.
- `jeem_starter_unit_test.dart`: lighter smoke — load `graphs/jeem.json` (assert 3 nodes, all essential),
  `letterUnitDataProvider('jeem')` routes, the walker rails to a legal jeem node, and seeding the 3 essential
  nodes at reps=1 then a PASS reaches MasterySection (mastery reachable). One testWidgets, own file.

Then run the FULL gate sweep and record honest outcomes in the SUMMARY:
  1. `python3 -m tools.content.validate --gate` (exit 0, exempt count 0)
  2. `python3 -m pytest tools/firebase/test_seed_curriculum_v2.py -q`
  3. `flutter test test/curriculum/learned_letters_lint_test.dart test/curriculum/graph_asset_parity_test.dart test/tutor/l3_learned_letters_parity_test.dart`
  4. `flutter test test/features/letter_unit/ test/curriculum/ test/tutor/`
KNOWN-ONLY failures allowed (5, verified pre-existing in up4): alif goldens/reference ×3
(alif_reference_test ×2, reference_overlay_golden_test), all_letters_validation_test (alif signedOff),
meet_section_test door-image. ANY OTHER failure must be fixed before done.

SUMMARY MUST RECORD: F2-interim provenance (owner 2026-07-20; mother's packet OWED — taa/thaa dormancy +
jeem/haa_c starter content + reps=1); coaching for taa/thaa/jeem/haa_c DEGRADES BY DESIGN (server is
baa-only, D-11; the never-silent feedback floor holds); iPad build/install is the OWNER's step (owner
performs after green); Play/webcourse artifacts NOT built (freeze intact); curriculum_graph.json UNTOUCHED
+ NO server regen; the jeem/haa_c Firestore-vintage finding from Task 2.
  </action>
  <verify>
    <automated>flutter test test/features/letter_unit/taa_live_path_mastery_test.dart test/features/letter_unit/thaa_live_path_mastery_test.dart test/features/letter_unit/jeem_starter_unit_test.dart</automated>
  </verify>
  <done>All 3 new tests pass; the full 4-command gate sweep is green except the 5 known pre-existing failures; the SUMMARY records every provenance + degrade-by-design + freeze note above.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| bundle assets → device render | letters are Firestore-first; a bundle edit does NOT reach a device whose Firestore doc is stale |
| curriculum content → child | any card that reaches ahead of the learned set is untrusted content |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-wcs-01 | Tampering | jeem/haa_c letters.json rows vs June-14 Firestore seed | mitigate | Task 2 VERIFY-ONLY diff of those rows; SURFACE any divergence in SUMMARY; never silently edit, never seed |
| T-wcs-02 | Elevation (of unauthored content) | reach-ahead word cards running as live nodes | mitigate | Task 1 removes the 18 nodes + empties the allowlist 18→0 → any reach-ahead fails the four-layer wall (`--gate`) by design |
| T-wcs-03 | Repudiation | server data / Play freeze drifting from this change | accept | NO server regen, NO seed, NO Play/webcourse rebuild — curriculum_graph.json byte-unchanged; iPad build is the owner's explicit step |
| T-wcs-SC | Tampering | npm/pip/cargo installs | accept | zero new package installs — pure content/asset + test edits |
</threat_model>

<verification>
- taa.json and thaa.json each contain exactly 7 nodes; curriculum_graph.json unchanged (git diff empty).
- `python3 -m tools.content.validate --gate` exits 0 and reports "owner-approved exceptions (exempt): 0".
- graphs/jeem.json + graphs/haa_c.json load as 3-node all-essential graphs; getUnitLetterIds() includes both.
- Every jeem/haa_c graph node id resolves to a live exercises.json card (no fallback).
- The 4-command gate sweep is green except the 5 documented pre-existing failures.
- 6 letters (alif, baa, taa, thaa, jeem, haa_c) each have a finishable unit.
</verification>

<success_criteria>
- taa + thaa are finishable (7 all-essential nodes each, reps=1) with their 18 reach-ahead cards dormant + reversible.
- jeem + haa_c ship as isolated-form-only starter units (3 essential nodes each) that reach the star.
- The owner-approved reach-ahead allowlist is EMPTY across validate.py / learned_letters_lint / exercise_selector / l3 parity.
- 3 new tests (2 live-path, 1 smoke) pass; full sweep green except the 5 known pre-existing failures.
- No server regen, no Firestore seed, no Play/webcourse rebuild; iPad build is the owner's step.
- SUMMARY records F2-interim provenance, the mother's owed packet, degrade-by-design coaching, and the Firestore-vintage finding.
</success_criteria>

<output>
Create `.planning/quick/260720-wcs-unlock-taa-thaa-dormant-18-f2-interim-wo/260720-wcs-SUMMARY.md` when done.
</output>
