---
phase: 19-question-presentation-overhaul-every-question-self-explanato
fixed_at: 2026-07-18T08:37:01Z
review_path: .planning/phases/19-question-presentation-overhaul-every-question-self-explanato/19-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 19: Code Review Fix Report

**Fixed at:** 2026-07-18T08:37:01Z
**Source review:** 19-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 8 (2 Critical + 6 Warning; the 5 Info findings are out of scope per fix_scope)
- Fixed: 8
- Skipped: 0

All work was done in an isolated worktree on a temp branch and fast-forwarded
onto `main` (9 commits, `a8ce079..e2322e6`).

## Fixed Issues

### CR-01: Live `completeWord` card never renders the D-06 gap slot

**Files modified:** `assets/curriculum/exercises.json`, `server/app/curriculum_data/exercises.json`, `test/features/letter_unit/prompt_header_live_asset_gap_test.dart` (new)
**Commit:** a8ce079
**Applied fix:** Authored the `_letter_` marker into the shipped `baa.completeWord.middle` text (`"با_"` → `"با_letter_"` — a mechanical marker-format fix, no wording change; curriculum stays the mother's domain) in both the client asset and the derived server copy. Added the asset-backed guard the review prescribed: a marker-format lint over EVERY shipped text part carrying `gaps` metadata (marker count must equal gap count) plus a render test that pumps the real card through `PromptHeader` and asserts `Key('gapSlot')` with no literal underscore on screen — closing the fixture-masks-live-data hole.
**Test evidence:** new file 3/3 green; `prompt_header_slot_audio_test` 4/4 green (Wave-0 contract untouched).

### CR-02: `baa.traceLetter.final` passes discarded; mastery gate + demo seed omit it

**Files modified:** `lib/features/letter_unit/sections/forms_section.dart`, `lib/features/letter_unit/letter_unit_controller.dart`, `lib/demo/seeded_demo_state.dart`, `test/features/letter_unit/letter_unit_screen_test.dart`
**Commits:** d7f5888 + e2322e6 (fixture follow-up)
**Applied fix:** All three Forms-section forms now map to their canonical graph node id (`final graphId = step.exercise.id;` — the stale "final is NOT in the signed graph" comment and `_ => null` arm removed), so a clean final-form pass reaches `incrementExerciseCleanReps`/`markNodeCleared`. `_presentedExerciseIds()` carries `baa.traceLetter.final` (8 presented essentials), and `seeded_demo_state._presentedEssentials` banks it at threshold so the demo star still hinges on the wobble form only. Follow-up commit: `letter_unit_screen_test` Test 5's "every essential at reps" seed list predated the owner amendment and omitted the final form — the corrected gate rightly stopped granting the star over the stale fixture; the seed now fulfils its own stated intent (assertions untouched). Node NOT removed from the graph, per constraints.
**Test evidence:** `forms_section_test`, `seeded_demo_state_test`, `live_selection_shell_test`, `mastery_condition_test` — 17/17 green; `letter_unit_screen_test` 5/5 green after the seed follow-up.

### WR-01: `_essentialFloor` records `cleanReps: 0` on a scoped-mastery star

**Files modified:** `lib/features/letter_unit/letter_unit_controller.dart`
**Commit:** e4bdf9f
**Applied fix:** `_essentialFloor(graph, reps, presented)` now floors over the SAME presented set `isMasteryMetForPresented` gated on (per the review's sketch); an empty presented set (the full-graph `isMasteryMet` fallback) keeps the all-essentials floor. The scoped-mastery star can no longer stamp "Mastered · 0 clean reps" on the parent dashboard.
**Test evidence:** `flutter analyze` clean; `live_selection_shell_test` green.

### WR-02: `CopyStimulus.hideSignal` dead at its only call site

**Files modified:** `lib/features/letter_unit/widgets/copy_stimulus.dart`, `test/features/letter_unit/copy_stimulus_test.dart` (comment-only)
**Commit:** 33e4aa8
**Applied fix:** Removal route, as the constraints direct: no stroke-START seam exists anywhere (`StrokeCanvas` exposes only pointer-UP `onStrokeSubmitted` and letter-complete callbacks; `WriteSurface` surfaces neither; `StrokeCanvasController` is clear/submit only), so no seam was invented. The dead `hideSignal` parameter and its entire listener plumbing (initState/didUpdateWidget/dispose/_onExternalHide) are removed; the widget doc and the Wave-0 test HEADER now state hide is button-only and that "hide on first stroke" is DEFERRED until a stroke-begin capture seam exists. The test edit is comment-only — zero assertions touched.
**Test evidence:** `copy_stimulus_test` 4/4 green (all original assertions intact).

### WR-03: Listen-and-write mount plays two audio streams at once

**Files modified:** `lib/features/letter_unit/widgets/exercise_scaffold.dart`, `test/features/letter_unit/exercise_scaffold_audio_overlap_test.dart` (new)
**Commit:** 7457643
**Applied fix:** The minimal suppression path the review offered, consistent with the UI-SPEC "spoken line as reinforcement" rule: the MOUNT auto-TTS is skipped when the lone visual stimulus is the auto-playing hero `AudioPart` AND the audio seam is actually wired (`onAudioTap != null` — with no seam the clip cannot sound, so the say line remains the only audible instruction and still speaks; this also keeps the pre-existing bare-scaffold Test 5 valid with zero edits). The say line stays as the instruction bar's TEXT and its tap-to-re-hear reinforcement — a deliberate bar tap still speaks (`mountAutoSpeak` flag scopes the suppression to mount only). New live-seam (`presentGraphExercise`) regression test asserts both sides: clip auto-plays once with no say-line TTS on mount; bar tap still re-speaks.
**Status note:** fixed — **requires device verification** (the review itself flags that both audio channels are separately mocked in widget tests; verify no overlap on the tablet on `baa.writeWord.dictation` / `writeLetter.fromSound` / the micro-drills / `traceLetter.isolated`).
**Test evidence:** new file 2/2 green; `exercise_scaffold_instruction_bar_test` 4/4 and `exercise_scaffold_test` 7/7 green, untouched.

### WR-04: Selection/arc advancement gated on the scaffold's `mounted` flag

**Files modified:** `lib/features/letter_unit/letter_unit_controller.dart`, `lib/features/letter_unit/widgets/exercise_scaffold.dart`
**Commit:** 8fa56dc
**Applied fix:** The review's "move the continuation onto the controller" option, strengthened with its "fresh `_nextReady` for THIS moment" property: new controller-owned `selectNextWhenDecided(facts, decisionFuture)` is handed the in-flight coach future SYNCHRONOUSLY at verdict — `_nextReady` is set immediately (a fast "Try again"/"Next exercise" tap awaits THIS moment's pick, never a stale prior future) and the continuation (arc advance + D-12 persist + cursor swap) runs on the controller even when the 18-12 epoch remount disposes the scaffold mid-round-trip. A failed coach call degrades to the walker/policy path (no decision) so the awaited future always completes. The old `selectNext` call inside the mounted-gated `.then` is removed; the mounted gate now guards ONLY UI work (tutor line, insight merge, TTS). The `_pendingNarrow` consume-once semantics are preserved (single `_selectNext` invocation per moment — no arc double-advance).
**Status note:** fixed — **requires human verification** of the fast-tap race on device (the widget suites can't reproduce coach latency + tap timing; the D-02 step-down guarantee should now hold under rapid taps).
**Test evidence:** `fail_path_selection_test`, `agent_pick_live_path_test`, `resume_cold_boot_test`, `same_id_represent_test`, `live_selection_shell_test` — 11/11 green.

### WR-05: Server G4 membership set diverges from the live graph

**Files modified:** `server/app/curriculum_data/generate.py`, `server/app/curriculum_data/baa_authored_ids.json` (re-derived), `server/app/curriculum_data/curriculum_graph.json` (re-derived), `assets/curriculum/curriculum_graph.json` (`_meta.source`), `server/tests/test_graph.py`
**Commit:** 46f42da
**Applied fix:** Per the constraints, re-derived via the repo's Python `generate.py` rail after switching its `exercise_ids` source from the signedOff filter to the canonical graph's `baa.*` NODE ids (the review's "derive the membership set from curriculum_graph.json nodes" option — G4 now rails exactly what G5/G6 rail; content sign-off stays tracked per exercise + the mother's review packet). Result verified: 17 ids; `baa.traceLetter.final`, `baa.microDrill.{dot,bowl,start}`, `baa.connectWord.kitaab` IN; the six D-19 gated ids OUT; server graph node set == authored set. The stale client `_meta.source` ("the 19 signed baa.* exercise ids") corrected. The server's magic-count test (`== 19`, already red at the committed 18) rewritten as a structural graph-mirror assertion with explicit restored-in/gated-out checks. The regenerated server `exercises.json` came out byte-identical to the CR-01 mirror edit, validating it.
**NOT done:** the server redeploy. Prod deploys require fresh explicit owner approval (standing project rule) — the fix takes effect on the next authorized deploy.
**Test evidence:** server `pytest tests/test_graph.py -m code` 20/20, `tests/test_plan_graph.py tests/test_grounding.py` 28/28; client `curriculum_graph_test` + `learned_letters_lint_test` 5/5.

### WR-06: v6→v7 migration never exercises the `letter_criterion_evidence` re-key branch

**Files modified:** `test/data/app_database_test.dart`
**Commit:** 5038c35
**Applied fix:** A NEW temp-file-DB case (the existing migration case is byte-for-byte untouched, per constraints): seeds the exact v6 `letter_criterion_evidence` DDL (surrogate autoincrement PK, no `child_profile_id`) plus one accrued evidence row and a single profile, rewinds `user_version` to 6, reopens, and asserts through the typed `unsyncedEvidence` accessor that the production `TableMigration` recreate + `Constant<int>` backfill ran: the row survives with payload intact and `childProfileId == profileA`, `unsyncedEvidence(childProfileId: profileB)` is empty (T-19-01 leak invariant), and a second open is idempotent.
**Test evidence:** `app_database_test` 11/11 green (was 10 cases).

## Skipped Issues

None — all 8 in-scope findings were fixed.

## Verification summary

- `flutter analyze` — **0 errors**; 70 pre-existing warnings/infos, none in any modified file.
- Full constraint gate `flutter test test/features/letter_unit/ test/data/ test/curriculum/ test/tutor/microdrill_selection_test.dart test/providers/` — **308 passed, 5 failed**, and the 5 failures are exactly the known pre-existing clusters the constraints list to ignore (meet_section img.door, reference_overlay golden, alif_reference ×2, all_letters_validation signedOff). The mastery_celebration / glyph_audit golden font-drift failures did not reproduce in this run.
- Server suites (WR-05 blast radius): `test_graph.py` 20/20, `test_plan_graph.py` + `test_grounding.py` 28/28.

## Follow-ups owed (not in scope here)

1. **WR-03 / WR-04 device verification** — audio overlap and fast-tap step-down must be confirmed on the tablet (widget tests mock the seams).
2. **WR-05 server redeploy** — the corrected G4 set ships only on the next owner-authorized deploy.
3. **WR-02 deferral** — "hide on first stroke" needs a stroke-begin capture seam out of `StrokeCanvas` (a future phase; documented in the widget).

---

_Fixed: 2026-07-18T08:37:01Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
