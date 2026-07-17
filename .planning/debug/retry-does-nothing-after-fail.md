---
status: diagnosed
trigger: "retry-does-nothing-after-fail"
created: "2026-07-17T08:21:18.000Z"
updated: "2026-07-17T08:36:00.000Z"
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: CONFIRMED (see Resolution). No further testing needed for find_root_cause_only mode.
test: n/a — root cause confirmed via direct code trace across selection_policy.dart, curriculum_graph_walker.dart, letter_unit_controller.dart, letter_unit_screen.dart, exercise_scaffold.dart.
expecting: n/a
next_action: Return ROOT CAUSE FOUND to caller (goal: find_root_cause_only — do not fix).

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: Get one attempt wrong on an exercise (e.g. "write baa initial form" without dots). The app should offer a working retry-in-place (or a legal one-tier-down remediation) — tapping the retry/"Write again" action should actually reset the canvas / re-arm it for a new attempt.
actual: "the question now is write baa intial form without the dots and i write it wring it succesfuly caught the mistake but now when i press write again nothing happens and i am stuck i can only press clear and there should be somthing to make the tutor speak again the instructions of the question" — the scorer correctly flagged the mistake, but the retry/"Write again" control (as distinct from the "Clear" button, which does work) is unresponsive, leaving the exercise stuck. The user also separately wants a way to re-trigger the spoken instruction (a nice-to-have, not the primary bug — note it but the retry no-op is the priority).
errors: None reported — appears to be a silent no-op, not a crash.
reproduction: Open a baa-unit trace/write exercise, deliberately write it incorrectly (e.g. omit the dots), submit/finish the stroke so it gets scored as a fail, then look for and tap whatever control is meant to let the child try again (separate from "Clear"). Observe whether anything happens.
started: Discovered during Phase 18 UAT on 2026-07-17. Phase 18 (2026-07-11) wired dynamic exercise selection into the live path (18-07-SUMMARY.md), including an `advanceOnFix` flag on ExerciseScaffold so the "fix" CTA advances to a selected node on a fail, and a subsequent fix commit 7bf60e7 (2026-07-12, "never advance on a fail — the fail menu is retry-or-step-down only") changed SelectionPolicy so a fail's candidate menu is {one-tier-down remediation, retry-in-place} only.

## Eliminated
<!-- APPEND only - prevents re-investigating -->

- hypothesis: Server/tutor (Cloud Run coach) issue causing the retry no-op.
  evidence: The verdict/star are entirely local (D-A/GROUND-01, exercise_controller.dart) and the presented-node swap that "Try again" drives is 100% client-side (letter_unit_screen.dart `_advanceSelection` / exercise_presenter.dart). The coach network call only supplies the WORDS (tutorLineProvider), never the selection outcome when the SelectionPolicy candidate set narrows to a single retry-in-place id. No server involvement in the no-op path.
  timestamp: "2026-07-17T08:35:00.000Z"

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: "2026-07-17T08:26:00.000Z"
  checked: lib/curriculum/selection_policy.dart `SelectionPolicy.narrow` (the 7bf60e7 fail-menu change)
  found: |
    On a FAIL below the anti-boredom streak threshold (`streak < kArcEntryFailStreak`, i.e. the FIRST wrong attempt — exactly the reported scenario), the candidate-building block is:
      final rem = graph.remediateOneTier(current);
      if (rem != null && _isLegal(rem, position)) candidates.add(rem);
      if (!candidates.contains(current) && _isLegal(current, position)) {
        candidates.add(current);
      }
    For a non-tiered competency (positionalForms trace/write-letter nodes, e.g. "write baa initial form" — tier is null per 15-01, tiers only exist on the إملاء writing ramp), `remediateOneTier` returns null, so `rem` is null and is skipped. `current` (the SAME exercise id the child just failed) is added instead. Result: `candidates == [current]` — "retry-in-place" is literally the exact same graph-node id as what's already on screen, not a distinct sentinel or a different exercise.
  implication: The very first candidate set SelectionPolicy hands back after a single fail on this exercise type is just the current id — confirms "retry-in-place" resolves to same-id, not a special case.

- timestamp: "2026-07-17T08:28:00.000Z"
  checked: lib/curriculum/curriculum_graph_walker.dart `CurriculumGraphWalker.selectFrom`
  found: |
    if (!facts.passed) {
      final rem = graph.remediateOneTier(current);
      if (rem != null && candidates.contains(rem)) return rem;
      if (candidates.contains(current)) return current; // floor: drill in place
    }
    With candidates == [current] (from the previous evidence entry), this returns `current` directly — the offline/degrade path picks the SAME id. lib/tutor/exercise_selector_provider.dart `RouterExerciseSelector.selectNext` only overrides this with the agent's `plan.nextExerciseId` when that proposal is BOTH in `candidates` AND graph-legal — since candidates is `[current]`, the only value the agent could legally propose here is also `current`. Either way (online agent pick or offline walker), `selectNext` resolves to `current`.
  implication: The end-to-end selection pipeline (SelectionPolicy → RouterExerciseSelector/CurriculumGraphWalker) deterministically returns the SAME exercise id as the one just failed, for a single fail on a non-tiered node. This is BY DESIGN (7bf60e7 "retry-or-step-down only") — not itself a bug.

- timestamp: "2026-07-17T08:30:00.000Z"
  checked: lib/features/letter_unit/letter_unit_controller.dart `_selectNext` (lines ~326-376)
  found: |
    `state = state.copyWith(currentExerciseId: next, selectionActive: true);` — writes `next` (== the same id) into `currentExerciseId`, and this is what `nextReady()`'s Future resolves to. No same-id guard here; the value is simply threaded through unchanged.
  implication: The controller layer correctly threads the (unchanged) id forward — no bug at this layer, but nothing here signals "this exercise is being re-presented, please reset."

- timestamp: "2026-07-17T08:32:00.000Z"
  checked: lib/features/letter_unit/letter_unit_screen.dart `_UnitShellState._advanceSelection` (lines 274-291) and `build()` body count (lines 375-383)
  found: |
    _advanceSelection awaits `ctrl.nextReady()`, gets `next` (== the same exercise id per above), then:
      _followRibbon(next);
      setState(() => _presentedId = next);
    `_presentedId` is reassigned to the SAME String value it already held. `setState` DOES trigger a `_UnitShellState.build()` rebuild (Flutter doesn't skip setState just because the field value is unchanged), and `build()` re-invokes:
      presentGraphExercise(data: data, exerciseId: _presentedId!, onNodeResult: _onNodePassed, onNext: _advanceSelection, onAudioTap: _onAudioTap)
  implication: A rebuild DOES happen — the bug is not "setState is skipped." The bug is in what that rebuild produces (next evidence entry).

- timestamp: "2026-07-17T08:33:00.000Z"
  checked: lib/features/letter_unit/exercise_presenter.dart `presentGraphExercise` (line 64-76) and lib/features/letter_unit/widgets/exercise_scaffold.dart (full file, no `didUpdateWidget` override present in `_ExerciseScaffoldState`)
  found: |
    presentGraphExercise returns `ExerciseScaffold(key: ValueKey('graph:$exerciseId'), ...)`. Since `exerciseId` (== `_presentedId`) is UNCHANGED from the previous build, the `ValueKey('graph:$exerciseId')` is IDENTICAL to the key already in the widget tree. Flutter's element reconciliation (`Element.updateChild`) sees the same `runtimeType` + same `Key` and treats this as an UPDATE to the EXISTING `ExerciseScaffold` Element/State — NOT a new mount. `_ExerciseScaffoldState` has no `didUpdateWidget` override, so nothing runs on this update beyond Flutter's default (silent) widget-reference swap. Critically, `initState()` — the ONLY place that (a) calls `exerciseControllerProvider.notifier.load(widget.exercise)` to reset the phase machine to idle, (b) clears `tutorLineProvider`/`tutorInsightProvider`, and (c) calls `_speakInstructionThenRelease()` to re-arm the canvas hold + re-speak the instruction — does NOT re-run, because the Element is reused.
  implication: ROOT CAUSE MECHANISM CONFIRMED. The global (non-family) `exerciseControllerProvider` state stays pinned at `ExercisePhase.fix` from the failed attempt (never reset to idle), the `StrokeCanvasController`'s ink is untouched (only `_clear()` resets it, which "Try again" does NOT call when `advanceOnFix==true`), and the CTA row keeps rendering "Clear" + "Try again" (`state.phase` unchanged) because `_ctaFor` is driven purely by `state.phase`. To the child, the tap produces literally zero visible change — exactly the reported "when I press write again nothing happens... I can only press clear."

- timestamp: "2026-07-17T08:34:00.000Z"
  checked: lib/features/letter_unit/widgets/exercise_scaffold.dart `_ctaFor` (lines 750-774) and `exercise_presenter.dart` line 75 (`advanceOnFix: true` always set for the live selection presenter)
  found: |
    `_PrimaryCta(label: s.tryAgain, onTap: widget.advanceOnFix ? widget.onNext : _clear)`. Every exercise rendered through the live selection path (`presentGraphExercise`, which is what 18-07 wired in for baa) sets `advanceOnFix: true` unconditionally — so "Try again" ALWAYS calls `widget.onNext` (== `_advanceSelection`) on this path, NEVER `_clear()`, regardless of whether the selection outcome is a genuinely different exercise or a same-id retry-in-place.
  implication: The `advanceOnFix` design assumed "advance" always means "go to a DIFFERENT node" (remediation/step-down/drill). It does not special-case the "the selected next node IS the current node" outcome (which 7bf60e7 legitimately produces for a first-time fail below the anti-boredom streak). That gap is what turns a by-design retry-in-place candidate into a stuck screen.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: |
  A widget re-key collision swallows the "Try again" tap when SelectionPolicy's
  by-design retry-in-place outcome (commit 7bf60e7) resolves to the SAME graph
  node id the child is already looking at.

  Chain: on a single fail below the anti-boredom streak (kArcEntryFailStreak) on
  a non-tiered node (e.g. "write baa initial form"), SelectionPolicy.narrow's
  candidates == [current] (selection_policy.dart, remediateOneTier returns null
  for non-ramp competencies) -> both CurriculumGraphWalker.selectFrom and
  RouterExerciseSelector.selectNext resolve to `current` (same id) ->
  LetterUnitController._selectNext threads `next == current` into
  state.currentExerciseId / nextReady() -> _UnitShellState._advanceSelection
  (letter_unit_screen.dart) does `setState(() => _presentedId = next)` with an
  unchanged value -> build() re-invokes presentGraphExercise(exerciseId:
  _presentedId!) -> exercise_presenter.dart builds
  ExerciseScaffold(key: ValueKey('graph:$exerciseId'), ...) with the SAME key as
  before -> Flutter's element reconciliation treats this as an UPDATE to the
  EXISTING ExerciseScaffold Element, not a new mount -> _ExerciseScaffoldState
  has no didUpdateWidget override, so initState() (the ONLY place that resets
  exerciseControllerProvider's phase to idle via .load(), clears
  tutorLineProvider/tutorInsightProvider, and re-arms
  _speakInstructionThenRelease()) never re-runs.

  Net effect: exerciseControllerProvider (a global singleton, not keyed per
  exercise) stays pinned at ExercisePhase.fix from the failed attempt, the
  StrokeCanvasController's ink is untouched (advanceOnFix routes "Try again" to
  widget.onNext, never _clear()), and the CTA row keeps rendering
  "Clear"/"Try again" because state.phase never changed. The tap is a true
  silent no-op -- matches the reported symptom exactly. This is a pure client
  Dart bug in lib/features/letter_unit/; no server/tutor involvement.
fix: NOT APPLIED (goal find_root_cause_only -- diagnosis only, per mode flag).
verification: N/A (not fixed in this session).
files_changed: []
