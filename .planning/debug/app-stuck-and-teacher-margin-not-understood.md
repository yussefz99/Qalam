---
status: diagnosed
trigger: "app-stuck-and-teacher-margin-not-understood — owner UAT 2026-07-17: 'it got stuck now and wont let me move to the next one i got out of the app and went again , now for the teacher margin i never understood at all'"
created: 2026-07-17T00:00:00Z
updated: 2026-07-17T01:10:00Z
---

## Current Focus

hypothesis: BOTH CONFIRMED (see Resolution). Stuck = same ValueKey no-remount mechanism as sibling bug but via the ACTIVE-ARC pass path (arc entry→stepDown/rebuild deterministically re-selects the currently-presented floor-trace id on a PASS, where the CTA row is ONLY "Next exercise" — no Clear escape → hard stuck → force-quit). Margin = panel DID render (owner quoted its _authoredWhy('shape') string verbatim in test 5) but is indistinguishable from the other 4 simultaneous feedback surfaces, and its signature arc-narration line is structurally unreachable (keyed to microDrill picks that are parked out of the live graph; arcStep/whyFacts never threaded into TutorInsight).
test: n/a — root causes confirmed via direct code trace (selection_policy._advanceArc, curriculum_graph_walker.selectFrom, letter_unit_controller._selectNext/nextReady, letter_unit_screen._advanceSelection, exercise_presenter, exercise_scaffold._ctaFor/build, teacher_margin_panel).
expecting: n/a
next_action: Return ROOT CAUSE FOUND to caller (goal: find_root_cause_only — do not fix).

## Symptoms

expected: (a) child-facing session should never hard-block progress to the point of requiring app restart; (b) a warm "Teacher's Margin" note should be visibly present near the canvas narrating WHY/arc step-downs, no gamification language
actual: (1) app hit hard stuck state mid-session, no control worked, owner force-quit and relaunched; (2) owner never perceived/understood any "Teacher's Margin" element during the session
errors: none reported (silent stuck state)
reproduction: play baa Letter Unit incl. one fail→retry cycle and one same-criterion-fail-twice step-down; watch for progress halt with no working control, and whether a distinct text panel appears near canvas
started: Phase 18 UAT 2026-07-17, same session as sibling gap "retry-does-nothing-after-fail" (test 3)

## Eliminated

- hypothesis: H2 — an unresolved Future / provider stuck loading with no timeout causes the hard hang.
  evidence: letter_unit_controller.dart `_selectNext` cannot hang — every await is try/catch-guarded (graph read failure → return null; persist failures swallowed). A null result routes the shell to the Mastery section (letter_unit_screen.dart:282-287), never a stall. `nextReady()` returns the CACHED `_nextReady` future; repeated "Next" taps re-await the same already-RESOLVED future and get the same id back instantly — a deterministic no-op, not a hang. The stuck state is a presentation-layer no-remount, not an async deadlock.
  timestamp: 2026-07-17T01:00:00Z

- hypothesis: H3a — Teacher's Margin never rendered at all (gated off in the owner's build).
  evidence: The panel is gated `if (_isAgentPath)` (exercise_scaffold.dart:626) where `_isAgentPath = widget.letter.id == 'baa'` (line 214). The owner was testing the baa unit, so the gate was OPEN. Decisive proof it rendered: the owner's test-5 quote "your baa wants a deeprer bowl a low smooth scoop before you lift" is VERBATIM `_authoredWhy('shape')` from teacher_margin_panel.dart:183 — a string that exists nowhere else in the client (grep: only that file + unrelated server eval fixtures). The owner was READING the margin panel without recognizing it as a feature.
  timestamp: 2026-07-17T01:02:00Z

## Evidence

- timestamp: 2026-07-17T00:00:00Z
  checked: prior sibling debug finding (retry-does-nothing-after-fail)
  found: "SelectionPolicy.narrow resolving retry-in-place to SAME node id → presentGraphExercise rebuilds ExerciseScaffold with identical ValueKey('graph:$exerciseId') → element UPDATE not remount → initState never re-runs (no didUpdateWidget) → controller stays non-idle, CTA row stays 'Clear'/'Try again', tap is silent no-op"
  implication: first-fail retry-in-place path already explained; must verify whether SECOND-fail arc/step-down path shares the same key-collision mechanics or has its own failure

- timestamp: 2026-07-17T00:20:00Z
  checked: 18-UAT.md test sequence + timeline
  found: Test 4 ("two same-mistake fails step down immediately") PASSED — the arc entry step-down DID appear (id changed original→trace, so the scaffold remounted fine). The stuck report landed at test 6, i.e. AFTER the arc step-down was on screen. Test 5's "static feedback" quote is the margin panel's shape template.
  implication: The stuck moment is inside the ACTIVE arc, one attempt after the step-down trace appeared — a code path (`_advanceArc`) the sibling session did not cover.

- timestamp: 2026-07-17T00:35:00Z
  checked: lib/curriculum/selection_policy.dart `_advanceArc` (lines 201-265) + `_drillOrRetry` (330-345) + arc_state.dart constants
  found: With an ACTIVE arc at step=entry (set at test 4's step-down), the NEXT feedback moment (pass or fail, ceiling not reached — kArcMaxAttempts=5, attempts=0) hits the switch case entry → `stepCands = _drillOrRetry(...)`. Micro-drills are PARKED (drillForCriterion returns null), so `_drillOrRetry` returns `_legalize([floorTrace, retryOriginal])` — the floor trace FIRST. The SAME happens at step=stepDown→rebuild. So for TWO consecutive moments the candidate list's head is the floor-trace id — the exercise CURRENTLY on screen.
  implication: The arc BY DESIGN re-presents the same floor-trace card consecutively ("do the drill, rebuild") — legitimate pedagogy, but it hands the presentation layer a same-id re-present, which the ValueKey('graph:$id') keying cannot express.

- timestamp: 2026-07-17T00:42:00Z
  checked: lib/curriculum/curriculum_graph_walker.dart `selectFrom` (121-136) + lib/tutor/exercise_selector_provider.dart `RouterExerciseSelector.selectNext` (104-133)
  found: On a PASS, `selectFrom` skips the fail branch and returns `candidates.first` — which during arc entry/stepDown IS the on-screen floor-trace id. On a FAIL of the trace, `remediateOneTier(trace)` is null (non-tiered) and `candidates.contains(current)` is true → also returns the same trace id. Online, the agent's proposal is accepted only if it is IN the candidate set — it can also legally echo the trace id; absent/illegal proposals fall to the walker. So during arc steps entry/stepDown, selection deterministically (offline) or near-deterministically (online) resolves to the id already on screen, on pass AND fail.
  implication: Confirms the same-id outcome on the PASS path — the path the sibling diagnosis did not cover.

- timestamp: 2026-07-17T00:50:00Z
  checked: lib/features/letter_unit/widgets/exercise_scaffold.dart `_ctaFor` (750-774) + letter_unit_screen.dart `_advanceSelection` (274-291) + exercise_presenter.dart (64-76)
  found: In ExercisePhase.pass the CTA row is ONLY `[_PrimaryCta(label: s.next, onTap: widget.onNext)]` — no Clear, no Done. `onNext` → `_advanceSelection` → awaits the cached `nextReady()` future → same id → `setState(_presentedId = same)` → `presentGraphExercise` builds `ExerciseScaffold(key: ValueKey('graph:$id'))` with the IDENTICAL key → Flutter element UPDATE, no remount, no initState → `exerciseControllerProvider` stays phase=pass → CTA stays the single dead "Next exercise" button. No new scoring can occur (canvas in pass state, ink retained), so `_nextReady` is never replaced — EVERY subsequent tap no-ops forever.
  implication: HARD STUCK confirmed: unlike the sibling's fail-path no-op (where Clear offered a partial escape), the pass-path stuck has ZERO working controls. Only escape is force-quit — exactly the owner's report.

- timestamp: 2026-07-17T01:05:00Z
  checked: teacher_margin_panel.dart (full) + exercise_scaffold.dart build/left column (607-631), `_teacherEye` (471-544), TutorInsight publish points (316-324, 399-410)
  found: |
    (a) Panel renders SizedBox.shrink() until tutorInsightProvider != null — insight only publishes AT the verdict. So the panel is INVISIBLE while writing and pops in at the exact instant 4 other feedback surfaces change: mascot pose, toned speech bubble ("QALAM SAYS" + agent line), demo Teacher's Eye strip ("WHAT THE TUTOR SAW" + criterion marks + "➜ next: pick — rationale"), and the bottom FeedbackPanel bar.
    (b) It is mounted in the LEFT 258px tutor column sandwiched between the speech bubble and the Teacher's Eye strip (lines 626+628) — not "beside the canvas" as the UAT truth describes. Its heading "TEACHER'S MARGIN" is 10px uppercase muted — same visual weight as the Teacher's Eye heading directly beneath it.
    (c) Content redundancy: ONLINE its WHY line IS insight.rationale — the same rationale text the Teacher's Eye strip prints after "➜ next:". OFFLINE/pre-coach it shows _authoredWhy(criterion) — a line that reads exactly like a coaching sentence, duplicating the bubble's role. rationale only merges into the insight when the agent decision carries plan.nextExerciseId (scaffold 402-410); otherwise the panel shows the SAME authored template every attempt. _targetedCriterion picks the first non-certainlyCorrect criterion EVEN ON A PASS → "Your baa wants a deeper bowl…" after correct attempts too — the owner reported this verbatim as test 5 "feels static".
    (d) The panel's SIGNATURE feature — the arc step-down narration ("Let's practice just the bowl for a moment — then we'll come back") — requires `pick.contains('microDrill')` (teacher_margin_panel.dart:197-198). Micro-drills are parked OUT of the live graph (owner 2026-07-12); the policy's step-down lands a traceLetter floor id instead. The condition can NEVER fire in this build. The policy emits `arcStep:*` whyFacts and `authoredWhyLine()` (exercise_selector_provider.dart:144-177) exists to phrase them — but NEITHER the whyFacts NOR the arc step is threaded into TutorInsight (which carries only criteria/diffSummary/pick/rationale). The panel structurally cannot see the arc it was built to narrate.
    (e) Interplay with the stuck bug: on a same-key no-remount, initState's `tutorInsightProvider.clear()` (line 231) never runs, so the previous attempt's margin content lingers stale into the "new" presentation.
  implication: The margin was present and rendering but had no perceivable identity: appears only in the verdict blast alongside 4 other surfaces, duplicates their text, its one distinctive behavior (arc narration) is dead code in this build, and it goes stale under the same-key bug. "I never understood it at all" is the expected user experience of this wiring.

## Resolution

root_cause: |
  TWO DISTINCT ROOT CAUSES — related to but not identical with the sibling
  finding (retry-does-nothing-after-fail).

  ── (1) HARD STUCK REQUIRING FORCE-QUIT ──
  Same underlying MECHANISM as the sibling bug (identical
  ValueKey('graph:$exerciseId') → Flutter element update instead of remount →
  _ExerciseScaffoldState.initState() never re-runs → phase machine / CTA row /
  canvas never reset), but a DIFFERENT trigger path with a strictly worse
  manifestation:

  Inside an ACTIVE remediation arc (entered at test 4's two-fail step-down),
  SelectionPolicy._advanceArc's entry→stepDown and stepDown→rebuild transitions
  both return stepCands whose head is the floor-trace id (micro-drills are
  parked, so _drillOrRetry falls to [_floorTrace, retryOriginal]) — i.e. the
  exercise ALREADY ON SCREEN. On a PASS of that trace card,
  CurriculumGraphWalker.selectFrom returns candidates.first == the same id
  (and on a FAIL it also returns current). The pass-phase CTA row is ONLY
  ["Next exercise"] (exercise_scaffold.dart _ctaFor, ExercisePhase.pass) — no
  Clear, no Done. Tapping it awaits the cached, already-resolved nextReady()
  future, gets the same id, setState + presentGraphExercise rebuild with the
  identical ValueKey → no remount → nothing changes → the single button is
  dead. No new scoring can occur (canvas locked in pass state), so _nextReady
  is never replaced: every tap no-ops forever. Unlike the sibling's fail-path
  no-op (where "Clear" gave a partial escape: clear ink → rewrite → pass out),
  the pass path has ZERO working controls. Only escape: force-quit. This is
  exactly "won't let me move to the next one, I got out of the app".

  Implication for the fix: patching only the sibling's first-fail
  retry-in-place path will NOT fix this. The presentation layer must support
  re-presenting the SAME graph node id (e.g. a presentation-epoch/attempt
  counter in the key, or a didUpdateWidget/manual reset path) — that single
  fix covers both the sibling bug and this one.

  ── (2) TEACHER'S MARGIN "NEVER UNDERSTOOD" ──
  NOT a gating/no-render bug — the panel rendered (the owner quoted its
  _authoredWhy('shape') string verbatim in test 5). It failed to register as
  a feature because of four compounding design/wiring gaps:
    (a) Renders nothing (SizedBox.shrink) until the first verdict, then
        appears simultaneously with 4 other feedback surfaces (toned bubble,
        demo Teacher's Eye strip, bottom feedback bar, mascot pose) — no
        distinct moment of introduction.
    (b) Mounted in the 258px left tutor column BETWEEN the speech bubble and
        the demo Teacher's Eye strip — visually one more small text box among
        three, its 10px muted heading identical in weight to the Teacher's
        Eye heading below it. Not "beside the canvas" as the UAT truth
        expects.
    (c) Content duplicates its neighbors: online it shows the same coach
        rationale the Teacher's Eye prints; offline it shows an authored
        template that reads like the coaching line — and _targetedCriterion
        selects a non-certainlyCorrect criterion even on a PASS, so the same
        "deeper bowl" template repeats after correct attempts (the owner's
        test-5 "static" complaint is this same panel).
    (d) Its one DISTINCTIVE behavior — the arc step-down narration — is dead
        code in this build: it fires only on pick.contains('microDrill'),
        but micro-drills are parked out of the live graph and the arc's
        actual step-down lands a traceLetter floor id. The policy's
        arcStep:*/whyFacts (and the ready-made authoredWhyLine() in
        exercise_selector_provider.dart) are never threaded into TutorInsight,
        so the panel structurally cannot narrate the arc it was built for
        (18-10 D-01's premise "reads the SAME TutorInsight" lost the arc
        signal — TutorInsight has no arcStep field).
fix: NOT APPLIED (goal find_root_cause_only — diagnosis only, per mode flag).
verification: N/A (not fixed in this session).
files_changed: []
