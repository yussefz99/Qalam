---
phase: 19-question-presentation-overhaul-every-question-self-explanato
reviewed: 2026-07-18T08:04:03Z
depth: standard
files_reviewed: 35
files_reviewed_list:
  - lib/data/app_database.dart
  - lib/data/arc_state_repository.dart
  - lib/data/drift_progress_repository.dart
  - lib/data/evidence_repository.dart
  - lib/data/graph_position_repository.dart
  - lib/data/progress_repository.dart
  - lib/demo/seeded_demo_state.dart
  - lib/features/letter_unit/letter_unit_controller.dart
  - lib/features/letter_unit/letter_unit_screen.dart
  - lib/features/letter_unit/widgets/copy_stimulus.dart
  - lib/features/letter_unit/widgets/exercise_scaffold.dart
  - lib/features/letter_unit/widgets/prompt_header.dart
  - lib/curriculum/selection_policy.dart
  - lib/providers/parent_providers.dart
  - lib/providers/practice_providers.dart
  - lib/providers/progression_providers.dart
  - lib/l10n/app_en.arb
  - assets/curriculum/curriculum_graph.json
  - assets/curriculum/exercises.json
  - docs/architecture/ADR-018-child-identity-keying.md
  - server/app/curriculum_data/baa_authored_ids.json
  - server/app/curriculum_data/curriculum_graph.json
  - server/app/curriculum_data/exercises.json
  - test/curriculum/baa_signoff_test.dart
  - test/curriculum/curriculum_graph_test.dart
  - test/curriculum/learned_letters_lint_test.dart
  - test/data/app_database_test.dart
  - test/data/curriculum_repository_v2_test.dart
  - test/features/letter_unit/child_profile_keying_test.dart
  - test/features/letter_unit/copy_stimulus_test.dart
  - test/features/letter_unit/exercise_scaffold_instruction_bar_test.dart
  - test/features/letter_unit/exercise_scaffold_test.dart
  - test/features/letter_unit/instruction_template_test.dart
  - test/features/letter_unit/prompt_header_slot_audio_test.dart
  - test/features/letter_unit/prompt_header_test.dart
  - test/features/letter_unit/recall_no_model_test.dart
  - test/providers/progression_providers_test.dart
findings:
  critical: 2
  warning: 6
  info: 5
  total: 13
status: issues_found
---

# Phase 19: Code Review Report

**Reviewed:** 2026-07-18T08:04:03Z
**Depth:** standard
**Files Reviewed:** 35
**Status:** issues_found

## Summary

Reviewed the Phase-19 question-presentation surface (instruction bar, CopyStimulus, gap-slot / hero-audio stimulus renderers), the ADR-018 v6→v7 per-child re-key migration and the five repositories over it, the D-15 LetterReps fold, the 19-05 curriculum content edits (micro-drill restore, 6-card gating, kitaab rewrite), and the selection-policy arc logic, plus their tests.

The migration itself is well-guarded (version-guarded, `alreadyKeyed` idempotency probe, `Constant<int>` backfill matching the verified drift 2.31 `TableMigration` API) and the ADR-017 wire boundary is respected — no `childProfileId` reaches `TutorFacts` or any wire shape. The child-keying threading through the repositories, controller, and providers is consistent and cached once per Pitfall 4.

However, two Critical cross-file defects survive: the only live `completeWord` card's authored text uses a plain `_` instead of the `_letter_` marker the renderer splits on, so the D-06 highlighted gap slot never renders on device (the widget tests pass only because their fixtures author the marker form); and `baa.traceLetter.final` is a live *essential* graph node whose passes are silently discarded on the legacy Forms path and which the scoped mastery gate ignores — the star is earnable without the owner-mandated fourth form. Six Warnings follow, including a stale server G4 membership set that prevents the coach from ever proposing the very micro-drill nodes 19-05 restored.

## Critical Issues

### CR-01: The live `completeWord` card never renders the D-06 gap slot — its authored text uses `_`, not the `_letter_` marker

**File:** `assets/curriculum/exercises.json:514` (and the derived `server/app/curriculum_data/exercises.json:514`), renderer at `lib/features/letter_unit/widgets/prompt_header.dart:526-548`
**Issue:** `_TextPart._tokens` splits prompt text on the regex `(__blank__|_letter_)` and renders `_GapWord` / `_GapLetter` (the `Key('gapSlot')` highlighted box, QP-04/D-06) only for those exact markers. The authored `baa.completeWord.middle` prompt is `"text": "با_"` — a plain trailing underscore that matches neither marker. On device the child therefore sees the literal string `با_` at 40px (a raw underscore inside the Arabic word) and the "big highlighted missing-letter slot" is never rendered. This is the **only** live `completeWord` node in the 19-05 graph (`baa.fillBlank.adjective`, the one card whose `__blank__` marker is correct, was gated out), so the entire QP-04 deliverable is dead on the live path. The contract tests pass only because their fixtures author different text: `exercise_scaffold_instruction_bar_test.dart:132` uses `'با_letter_'` and `prompt_header_slot_audio_test.dart:64-67` uses `'كبير _letter_'` — the classic fixture-masks-live-data trap; no test loads the shipped asset through the renderer.
**Fix:** Either author the marker into the asset (both copies):
```json
{ "kind": "text", "text": "با_letter_", "gaps": [{ "kind": "letter", "index": 2 }] }
```
or make `_TextPart` render slots from the `gaps` metadata (which it already receives but only uses for font sizing) so authored content cannot silently miss the marker. Add an asset-backed widget test that pumps the real `baa.completeWord.middle` config and asserts `find.byKey(Key('gapSlot'))` — mirroring `learned_letters_lint_test`'s read-the-shipped-asset posture.

### CR-02: `baa.traceLetter.final` is a live essential node, but its passes are discarded and the mastery gate ignores it — the star fires without the fourth form

**File:** `lib/features/letter_unit/letter_unit_controller.dart:589-597` (`_presentedExerciseIds`), `assets/curriculum/curriculum_graph.json:92-96`, corroborated by `lib/features/letter_unit/sections/forms_section.dart:240-247` and `lib/demo/seeded_demo_state.dart:51-59`
**Issue:** The owner's 2026-07-12 amendment made `baa.traceLetter.final` a live **essential** graph node (`competency: positionalForms`, `minCleanReps: 3`) so the child traces all four forms before production tasks, and 19-05 re-shipped the graph with it. But:
1. The legacy Forms section still maps the final form to `graphId = null` behind a now-false comment ("baa.traceLetter.final is NOT in the signed graph (15 nodes)" — the live graph has 17 nodes including it). A clean pass on the final-form trace is silently dropped: no `incrementExerciseCleanReps`, no `markNodeCleared` — real child progress discarded.
2. `_presentedExerciseIds()` (the T5 scoped mastery set) lists 7 ids and omits `baa.traceLetter.final`, so `isMasteryMetForPresented` grants the quiet star without the fourth form ever being completed — even though the unit *does present it* (FormsSection renders initial/medial/final), which breaks the stated rule that the set contains what "the scaffold actually increments"... only because of bug (1).
3. `seedDemoState._presentedEssentials` mirrors the same stale 7-id set, so the demo bakes in the gap.
Net effect: the star — the product's one mastery marker — is granted while an essential node in the signed live graph sits at 0 reps, and the full `isMasteryMet` fallback can never pass on the legacy path. This contradicts the curriculum data shipped in this same phase.
**Fix:** Map the final form to its node and include it in the presented set:
```dart
// forms_section.dart — all four forms are live graph nodes now
final graphId = step.exercise.id; // isolated handled by WatchTrace; initial/medial/final here

// letter_unit_controller.dart
Set<String> _presentedExerciseIds() => const {
      'baa.teachCard.meet',
      'baa.traceLetter.isolated',
      'baa.traceLetter.initial',
      'baa.traceLetter.medial',
      'baa.traceLetter.final',   // owner amendment 2026-07-12 — essential
      'baa.connectWord.baab',
      'baa.writeWord.dictation',
      'baa.writeLetter.fromSound',
    };
```
and update `seeded_demo_state.dart`'s `_presentedEssentials` to match (banking the final form at threshold so the demo star still hinges on the wobble form only).

## Warnings

### WR-01: `_essentialFloor` records `cleanReps: 0` on a scoped-mastery star — the exact value the fix was written to eliminate

**File:** `lib/features/letter_unit/letter_unit_controller.dart:563-612`
**Issue:** When mastery passes via the scoped `isMasteryMetForPresented` (7 of 15 essential nodes), `recordMastery` is called with `_essentialFloor(graph, reps)` — which computes the minimum over **all** `graph.essentialNodes`, including the 8 unpresented ones whose reps are 0. The floor is therefore 0 whenever any unpresented essential has no reps (the common path), so the mastery row is stamped `cleanReps: 0` — directly contradicting the method's own doc ("a real, non-zero progress value to record — never the old cleanReps:0") and rendering "Mastered · 0 clean reps" on the parent dashboard (`parentRowMastered`).
**Fix:** Scope the floor to the same presented set the gate used:
```dart
int _essentialFloor(CurriculumGraph graph, Map<String, int> reps, Set<String> presented) {
  int? min;
  for (final node in graph.essentialNodes) {
    if (presented.isNotEmpty && !presented.contains(node.exerciseId)) continue;
    final r = reps[node.exerciseId] ?? 0;
    if (min == null || r < min) min = r;
  }
  return min ?? 0;
}
```

### WR-02: `CopyStimulus.hideSignal` is dead at its only call site — the copy word stays visible while the child writes

**File:** `lib/features/letter_unit/widgets/prompt_header.dart:489`; widget at `lib/features/letter_unit/widgets/copy_stimulus.dart:34-96`
**Issue:** The D-05 contract (and the widget's own doc, plus the Wave-0 test header: "the child taps 'I'm Ready' **(or starts the first stroke)** to HIDE it") includes a first-stroke hide trigger via `hideSignal`. The only construction site is `_TextPart.build` → `CopyStimulus(word: part.text)` — no `hideSignal` is ever wired, and `PromptHeader` has no seam to thread one from `WriteSurface`. Consequence: on `baa.writeWord.copy` ("write it **from memory**") the child can leave the word revealed and copy it stroke-by-stroke while looking at it, passing the `manzur` recall card with the stimulus on screen. The entire listener plumbing in `CopyStimulus` (initState/didUpdateWidget/dispose/_onExternalHide) is dead code. The recall-honesty intent of D-05 is only half implemented.
**Fix:** Thread a `Listenable` from the scaffold's stroke-start seam through `PromptHeader` into `CopyStimulus` (e.g. a `ChangeNotifier` pinged by `StrokeCanvasController` on first stroke), or remove the dead `hideSignal` machinery and document that hiding is button-only — but then the test header and widget doc must stop claiming the stroke trigger exists.

### WR-03: Listen-and-write mount plays two audio streams at once — the TTS instruction and the hero card's auto-played clip

**File:** `lib/features/letter_unit/widgets/exercise_scaffold.dart:414-463` and `lib/features/letter_unit/widgets/prompt_header.dart:208-221`
**Issue:** On mounting a listen-and-write node (`[say, audio]`, e.g. `baa.writeWord.dictation`), two post-frame callbacks fire in the same frame: the scaffold's `_speakInstructionThenRelease` speaks the say line through `ttsCoachSpeakerProvider`, and the hero `_AudioPart` auto-plays the word clip through `onAudioTap` → the audio player. These are independent channels with no sequencing, so the child hears the spoken instruction and the dictation word simultaneously — on the one exercise type where hearing the word clearly IS the question. This recurs on every re-present (the 18-12 epoch remount re-runs both initStates). The Phase-07 double-Hear-button device bug is the recorded precedent for exactly this class of overlap, and no widget test can catch it (both seams are mocked separately).
**Fix:** Sequence them: have the hero card's auto-play defer until the instruction hold releases (e.g. gate auto-play on `_instructionHold == false` via a callback/notifier from the scaffold), or suppress the say-line TTS when the lone visual is an auto-playing `AudioPart` (the clip is the instruction). Verify on device, not only in widget tests.

### WR-04: Selection and arc advancement are gated on the scaffold's `mounted` flag — a fast tap skips the remediation step-down

**File:** `lib/features/letter_unit/widgets/exercise_scaffold.dart:584-639`; consumed by `lib/features/letter_unit/letter_unit_screen.dart:309-335` and `lib/features/letter_unit/letter_unit_controller.dart:396-452`
**Issue:** `controller.selectNext(facts, decision:)` — which consumes `_pendingNarrow`, advances `_sessionArc`, persists the arc (D-12), and sets `_nextReady` — runs inside `brain.next(facts).then((decision) { if (!mounted) return; ... })`. The controller deliberately outlives scaffold key swaps (that was audit finding 1.4), but the moment that advances it is tied to a *widget's* lifetime plus a network round-trip. If the child taps "Try again"/"Next exercise" (`advanceOnFix` routes the fix CTA to `onNext`) before the coach call resolves: `_advanceSelection` awaits `nextReady()` — the **previous** moment's already-completed future (or null on the first moment) — re-presents a stale/same node, the epoch bump remounts the scaffold, `mounted` goes false, and `selectNext` never runs for that moment. The fail is recorded in `_sessionHistory` but the arc produced by `beginSelection` is never persisted or advanced, so under fast repeated taps the "fail the same criterion twice → the very next card steps down" guarantee (D-02, owner directive 2026-07-12) silently degrades to retry-in-place, coach latency permitting.
**Fix:** Split the verdict-time selection from the coach round-trip: call `controller.selectNext(facts)` (walker/policy path, no decision) synchronously at verdict so `_nextReady` is always fresh for THIS moment, then upgrade the pick when the coach decision lands (the router already validates the decision against the same candidate set); or move the `brain.next` continuation onto the controller so it is not gated on the scaffold's `mounted`.

### WR-05: Server G4 membership set (`AUTHORED_BAA_IDS`) diverges from the live graph — the coach can never propose the restored micro-drills, the final trace, or kitaab

**File:** `server/app/curriculum_data/baa_authored_ids.json:17-36`; enforced by `server/app/curriculum.py:63-73`, `server/app/nodes/plan.py`, `server/app/nodes/coach.py`
**Issue:** 19-05 re-derived `server/app/curriculum_data/{curriculum_graph,exercises}.json` but `baa_authored_ids.json` still holds the pre-19-05 18-id set. It is missing four ids that ARE live graph nodes — `baa.traceLetter.final`, `baa.microDrill.dot`, `baa.microDrill.bowl`, `baa.microDrill.start` (`baa.connectWord.kitaab` is likewise absent) — and still contains the six D-19 gated ids (`baa.buildSentence.*`, `baa.fillBlank.adjective`, `baa.transformWord.*`) that no longer exist in any graph. Since G4 requires `Plan.next_exercise_id ∈ AUTHORED_BAA_IDS`, the server will reject every coach proposal of a micro-drill or the final-form trace even when the client's policy-narrowed `legalNextExerciseIds` offers them — so online, the D-18 micro-drill restore can only ever surface via the offline walker fallback, which partially defeats the point of restoring them behind the agent. Conversely the server will happily emit picks for the six gated ids (the client's R5 re-check absorbs those, but the round-trip is wasted). The client graph's `_meta.source` line ("the 19 signed baa.* exercise ids") is stale for the same reason.
**Fix:** Re-run the derivation (`cd server && uv run python -m app.curriculum_data.generate`) after aligning its source with the live graph node set (or derive the membership set from `curriculum_graph.json` nodes instead of `units.json` sections), and redeploy. Update the graph `_meta.source` count while there.

### WR-06: The v6→v7 migration test never exercises the `letter_criterion_evidence` re-key branch — one of the five adopted tables ships untested

**File:** `test/data/app_database_test.dart:443-577`
**Issue:** The migration test (the gate ADR-018 explicitly names for "the phase's highest-risk change") seeds an exact v6 schema for six tables but not `letter_criterion_evidence`. That table is therefore left as `onCreate` built it — already at v7 with `child_profile_id` — so `alreadyKeyed('letter_criterion_evidence')` short-circuits and the production `TableMigration` recreate + `Constant<int>` backfill for the evidence queue never runs under test. A regression in that branch (e.g. a wrong `columnTransformer`, or the surrogate-PK copy) would pass this suite and only surface on real upgrading devices, where accrued offline evidence rows would be lost or mis-adopted. No assertion covers evidence-row adoption either.
**Fix:** Seed the v6 `letter_criterion_evidence` DDL + one evidence row in the same block, and assert post-migration that the row survives with `child_profile_id = profileA` and that `unsyncedEvidence(childProfileId: profileB)` is empty.

## Info

### IN-01: `incrementExerciseCleanReps` claims atomicity but is a non-transactional read-modify-write

**File:** `lib/data/app_database.dart:604-623`
**Issue:** The doc says "Atomically increment…"; the implementation is `getExerciseCleanReps` then `setExerciseCleanReps` with no transaction and no SQL-side `clean_reps + 1`. Two overlapping calls can lose an increment. Low risk for a single-child UI, but the doc misleads future callers.
**Fix:** Wrap in `transaction(...)` or use a single `INSERT ... ON CONFLICT DO UPDATE SET clean_reps = clean_reps + 1`, or correct the doc.

### IN-02: All Phase-19 l10n keys are dead — no call site consumes them, and the new widgets hardcode their Semantics strings

**File:** `lib/l10n/app_en.arb:3-66, 1141-1172`; `lib/features/letter_unit/widgets/copy_stimulus.dart:171-189`; `lib/features/letter_unit/widgets/prompt_header.dart:275`; `lib/features/letter_unit/exercise_presenter.dart` (no `strings:` threaded)
**Issue:** The 16 `instructionBar*` keys, `promptAudioListen(+Semantics)`, and the six `copy*` keys have zero consumers: `presentGraphExercise` never passes `strings:` to `ExerciseScaffold`, and `CopyStimulus`/the hero audio card hardcode their Semantics labels with no constructor seam at all — so the l10n keys authored for them are unreachable by design. The arb "mirrors" are pure dead weight and will silently drift from the widget defaults.
**Fix:** Either thread `AppLocalizations` through the presenter into `ExerciseScaffoldStrings`/`CopyStimulus` (adding semantics-label params), or drop the unused keys until localization is a real workstream — dead mirrors invite drift.

### IN-03: The persistent instruction bar is hidden for any graded exercise without a say line

**File:** `lib/features/letter_unit/widgets/exercise_scaffold.dart:398-402, 891`
**Issue:** `_hasInstruction` gates the D-01 bar ("readable with sound off, same place on every graded type") on a non-empty **spoken** `SayPart` — but the bar's text is the per-type template, not the say line. A graded config with no say line would lose the visual instruction entirely. All current authored configs carry say lines, so this is latent, but the coupling inverts the design's stated independence of the two layers.
**Fix:** Always show the bar on graded surfaces; hide only the trailing speaker glyph / disable the tap when there is nothing to re-speak.

### IN-04: `_presentedExerciseIds()` is baa-hardcoded while alif and taa units exist — their Mastery sections can never record a star

**File:** `lib/features/letter_unit/letter_unit_controller.dart:539-597`; `assets/curriculum/units.json` (units for baa, taa, alif)
**Issue:** For the alif/taa units, `recordMasteryIfMet` intersects the baa graph's essential nodes with the baa-id presented set against reps keyed under `alif`/`taa` — always 0 — so `isMasteryMetForPresented` returns false forever and those units' Mastery sections silently record nothing. Documented as INTERIM, and it predates this phase, but it is live dead-end behavior in a reviewed file.
**Fix:** Derive the presented set from the unit config (`data.unit.sections` → graph ids) as the comment already prescribes, or short-circuit non-baa letters to a non-graph mastery path.

### IN-05: `_criterionDominates` triggers drill injection off ANY repeated mistake, not the weakest criterion's

**File:** `lib/curriculum/selection_policy.dart:319-328`
**Issue:** The dominance check counts occurrences per `mistakeId` and fires when *any* id repeats ≥2, then injects `drillForCriterion(letterId, facts.weakestCriterion)` — a criterion that may be unrelated to the repeated mistake (mistake ids and criteria are different vocabularies). A child repeatedly missing the dot but currently weakest on shape gets the shape drill injected on dot-mistake dominance.
**Fix:** Map mistake ids to criteria (or count `SessionAttempt.weakestCriterion` occurrences) and require the dominant signal to match the criterion whose drill is injected.

---

_Reviewed: 2026-07-18T08:04:03Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
