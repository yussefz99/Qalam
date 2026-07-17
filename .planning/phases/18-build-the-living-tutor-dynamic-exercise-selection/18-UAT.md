---
status: diagnosed
phase: 18-build-the-living-tutor-dynamic-exercise-selection
source: [18-01-SUMMARY.md, 18-02-SUMMARY.md, 18-03-SUMMARY.md, 18-04-SUMMARY.md, 18-05-SUMMARY.md, 18-06-SUMMARY.md, 18-07-SUMMARY.md, 18-08-SUMMARY.md, 18-09-SUMMARY.md, 18-10-SUMMARY.md, commits 2d5f0b0/7bf60e7 (owner UAT fixes 2026-07-12)]
started: "2026-07-16T18:41:38.353Z"
updated: "2026-07-17T08:17:53.651Z"
---

## Current Test

[testing complete]

## Tests

### 1. Exercise opens with instruction held, not a bare canvas
expected: Open any exercise. The tutor speaks what's needed for that question, and the canvas is visible but NOT writable (dimmed / strokes don't register) until the instruction finishes speaking (capped ~8s). It should never open as a bare, immediately-writable canvas with no instruction.
result: pass

### 2. Stimulus picture is large and readable
expected: For an exercise with a picture prompt, the image renders large (roughly 260x176) and clearly — easy to make out on the tablet, not a tiny thumbnail.
result: issue
reported: "here i gave you a screenshot it can be much much better"
severity: cosmetic

### 3. A single wrong attempt never jumps forward
expected: Get one attempt wrong. The app offers retry-in-place (or a one-tier-down remediation) — it does NOT silently advance to a new, unrelated exercise after just one miss.
result: issue
reported: "the question now is write baa intial form without the dots and i write it wring it succesfuly caught the mistake but now when i press write again nothing happens and i am stuck i can only press clear and there should be somthing to make the tutor speak again the instructions of the question"
severity: major

### 4. Two same-mistake fails in a row step down immediately
expected: Make the same kind of mistake twice in a row on the same letter. The very next card steps DOWN to a simpler guided trace exercise for that letter (not a third repeat of the identical failing card). Since micro-drills are currently parked, the step-down should land on tracing, not a drill screen.
result: pass

### 5. A pass gives a specific reason, not generic praise
expected: After a correct attempt, the tutor's feedback/next-pick names something specific about what you're working on — not just a bare "Great job, next!" with no reason.
result: issue
reported: "its feels static always showing your baa wants a deeprer bowl a low smooth scoop before you lift"
severity: major

### 6. Teacher's Margin note is visible beside the canvas, with no gamification language
expected: A small warm text note near the writing canvas narrates what's happening (e.g. naming the focus of the current exercise or step-down). No points, streaks, badges, "+N", or score language appears anywhere on screen.
result: issue
reported: "it got stuck now and wont let me move to the next one i got out of the app and went again , now for the teacher margin i never understood at all"
severity: blocker

### 7. A returning child's session reflects past struggles (across-session memory)
expected: If you can test this (requires a prior session's data plus the nightly profile compile, or a manual job re-run), a returning child's first pick in a new session should reflect what they struggled with before — not start cold every time. If you can't set this up right now, say "blocked" and why.
result: issue
reported: "when i closed the app and reopend it did start from scrathc in unit baa , i dont think so and i think we should chage that nightly job"
severity: major

## Summary

total: 7
passed: 2
issues: 5
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "For an exercise with a picture prompt, the image renders large (roughly 260x176) and clearly — easy to make out on the tablet, not a tiny thumbnail."
  status: failed
  reason: "User reported: here i gave you a screenshot it can be much much better"
  severity: cosmetic
  test: 2
  root_cause: "prompt_header.dart's _ImagePart uses a hardcoded fixed-size Container/Image (260x176 literal, just doubled from 128x84 in the 2026-07-12 fix) instead of sizing relative to available layout space (_mainColumn is 700-1500+px on a real tablet) — the sizing STRATEGY was never fixed, only the constant. Separately, the picture caption Text has no explicit textDirection, so it inherits the ambient RTL Directionality from ExerciseScaffold and the trailing '?' bidi-resolves to the front ('?what does it start with')."
  artifacts:
    - path: "lib/features/letter_unit/widgets/prompt_header.dart"
      issue: "_ImagePart fixed-size image box (not responsive); caption Text missing textDirection: TextDirection.ltr"
    - path: "lib/features/letter_unit/widgets/exercise_scaffold.dart"
      issue: "root Directionality(rtl) + mascot-column/_mainColumn layout establishes the real available space the image should size against"
    - path: "lib/features/letter_unit/widgets/feedback_panel_v2.dart"
      issue: "reference: already has the correct textDirection:ltr fix for the same caption-bidi bug class, never applied to prompt_header.dart"
  missing:
    - "Size the stimulus image responsively (LayoutBuilder/AspectRatio/flex) against actual available header-row width instead of a hardcoded pixel constant"
    - "Add textDirection: TextDirection.ltr to the _ImagePart caption Text"
  debug_session: ".planning/debug/stimulus-picture-too-small.md"

- truth: "Get one attempt wrong. The app offers retry-in-place (or a one-tier-down remediation) — it does NOT silently advance to a new, unrelated exercise after just one miss."
  status: failed
  reason: "User reported: the question now is write baa intial form without the dots and i write it wring it succesfuly caught the mistake but now when i press write again nothing happens and i am stuck i can only press clear and there should be somthing to make the tutor speak again the instructions of the question"
  severity: major
  test: 3
  root_cause: "When SelectionPolicy's retry-in-place outcome resolves to the SAME graph-node id already on screen (the common case on a first non-tiered fail), exercise_presenter.dart rebuilds ExerciseScaffold with an IDENTICAL ValueKey('graph:$exerciseId'). Flutter's element reconciliation treats this as an UPDATE, not a remount, so _ExerciseScaffoldState.initState() (the only place that resets the controller phase, clears canvas/insight state, and re-arms instruction-hold/TTS) never re-runs. The 'Write again' tap becomes a genuine silent no-op — same root cause as gap/test 6 below, via a different trigger path."
  artifacts:
    - path: "lib/features/letter_unit/exercise_presenter.dart"
      issue: "keys ExerciseScaffold purely by exercise id — a same-id retry collides with the mounted Element and is treated as a no-op update"
    - path: "lib/features/letter_unit/widgets/exercise_scaffold.dart"
      issue: "all reset logic lives in initState only; no didUpdateWidget; advanceOnFix CTA never falls back to _clear() on a same-id retry"
    - path: "lib/features/letter_unit/letter_unit_screen.dart"
      issue: "_advanceSelection sets _presentedId without detecting a same-id no-op"
  missing:
    - "A way to force a fresh ExerciseScaffold mount (or explicit reset) when the selected next id equals the currently presented id — e.g. an attempt/generation counter folded into the presenter's key, or a didUpdateWidget reset path"
    - "A control to replay the tutor's spoken instruction on demand (secondary ask from the same report)"
  debug_session: ".planning/debug/retry-does-nothing-after-fail.md"

- truth: "After a correct attempt, the tutor's feedback/next-pick names something specific about what you're working on — not just a bare 'Great job, next!' with no reason."
  status: failed
  reason: "User reported: its feels static always showing your baa wants a deeprer bowl a low smooth scoop before you lift (same line every time, not generated per-attempt)"
  severity: major
  test: 5
  root_cause: "NOT the LLM echoing a gold exemplar (that Phase-14 mitigation already shipped in prompts.py). The exact reported phrase is a hardcoded Dart fallback string in TeacherMarginPanel._authoredWhy('shape'). TutorInsight.rationale (the only trigger to use the coach's real per-attempt line) is structurally null on almost every clean pass: the coach's ACTION tool schemas in server/app/tools.py don't declare nextExerciseId/rationale as parameters (so a real model call can never attach them, despite prompts.py asking for them in prose), and the schema-backed plan node (the other rationale source) is skipped entirely on a clean pass by graph.py's needs_plan(). So the panel always falls to the fixed lookup table, keyed by _targetedCriterion() which picks 'shape' (bowl) most often because that criterion's soft-band tolerance is still uncalibrated/provisional."
  artifacts:
    - path: "lib/features/letter_unit/widgets/teacher_margin_panel.dart"
      issue: "_authoredWhy() hardcoded fallback table is the majority-path output, not the exception; _targetedCriterion() skews toward 'shape'"
    - path: "lib/features/letter_unit/widgets/exercise_scaffold.dart"
      issue: "insight.rationale only ever set from decision.plan?.nextExerciseId"
    - path: "lib/tutor/remote_agent_brain.dart"
      issue: "parses nextExerciseId/rationale from coach tool-call args, which never carry them"
    - path: "server/app/tools.py"
      issue: "the 4 ACTION tool schemas don't declare nextExerciseId/rationale as parameters"
    - path: "server/app/graph.py"
      issue: "needs_plan() skips the plan node (the schema-backed rationale source) on every clean pass"
  missing:
    - "A schema-backed way for the coach's tool calls to carry nextExerciseId/rationale (declare them as tool parameters, or keep using structured output) so insight.rationale is populated on the common clean-pass path"
    - "A plan-equivalent step on the clean-pass path so rationale isn't structurally unavailable there"
    - "Vary the _authoredWhy fallback beyond a static 6-entry lookup, or reduce reliance on it"
  debug_session: ".planning/debug/coach-feedback-feels-static.md"

- truth: "A small warm text note near the writing canvas narrates what's happening. No points, streaks, badges, '+N', or score language appears anywhere on screen."
  status: failed
  reason: "User reported: it got stuck now and wont let me move to the next one i got out of the app and went again , now for the teacher margin i never understood at all"
  severity: blocker
  test: 6
  root_cause: "TWO distinct causes. (1) STUCK STATE: the same ValueKey('graph:$exerciseId') no-remount collision as test 3's gap, but on the ACTIVE-ARC PASS path (not the first-fail path) — during a remediation arc (micro-drills parked), the arc legitimately re-presents the same floor-trace id across entry/stepDown/rebuild; on a PASS of that trace the pass-phase CTA is a SINGLE 'Next exercise' button with no Clear/Done escape, and the cached nextReady() future never changes, so every tap after that point is a permanent no-op with zero working controls — only a force-quit recovers (strictly worse than test 3's case, which still had a working Clear button). Fixing only the first-fail case will NOT fix this; both need the same underlying fix (support re-presenting the same node id). (2) MARGIN NOT UNDERSTOOD: the panel IS rendering (proven — the user's test-5 quote is byte-identical to its hardcoded _authoredWhy('shape') string) but has no perceivable identity: no distinct introduction moment (pops in simultaneously with 4 other feedback surfaces), buried in the tutor column visually identical in weight to the demo 'Teacher's Eye' strip directly below it, duplicate content with that same demo strip, and its arc step-down narration (_arcStepDownLine) is dead code since it only fires on a microDrill pick and micro-drills are parked — so the panel's signature behavior never triggers in the current live graph."
  artifacts:
    - path: "lib/features/letter_unit/exercise_presenter.dart"
      issue: "ValueKey('graph:$exerciseId') cannot express a same-id re-present (shared with test-3 gap)"
    - path: "lib/features/letter_unit/widgets/exercise_scaffold.dart"
      issue: "no didUpdateWidget; pass-phase CTA has no escape control; Teacher's Margin mounted beside/visually indistinct from the demo Teacher's Eye strip"
    - path: "lib/curriculum/selection_policy.dart"
      issue: "_advanceArc/_drillOrRetry legitimately emit consecutive same-id presentations during a step-down (correct pedagogy, but the UI can't render it)"
    - path: "lib/features/letter_unit/letter_unit_controller.dart"
      issue: "_nextReady cached future never invalidated after a no-op present"
    - path: "lib/features/letter_unit/widgets/teacher_margin_panel.dart"
      issue: "insight-gated visibility with no distinct entrance; _arcStepDownLine's microDrill-only condition is unreachable in the live (drills-parked) graph"
    - path: "lib/tutor/exercise_selector_provider.dart"
      issue: "authoredWhyLine()/whyFacts already exist but are never wired into TutorInsight, so the panel can't see the arc it was built to narrate"
  missing:
    - "Make same-id re-presentation a first-class operation (presentation-epoch/attempt counter in the key, or an explicit reset-on-update path) — fixes this and the test-3 gap together"
    - "Thread arcStep/whyFacts into TutorInsight so the arc narration actually fires post-micro-drill-parking"
    - "Give the Teacher's Margin panel a distinct, persistent presence and de-duplicate it against the demo Teacher's Eye strip (which should likely be gated out of non-demo builds)"
  debug_session: ".planning/debug/app-stuck-and-teacher-margin-not-understood.md"

- truth: "A returning child's session reflects past struggles (across-session memory); resuming should not lose in-progress position within the same unit either."
  status: failed
  reason: "User reported: when i closed the app and reopend it did start from scrathc in unit baa , i dont think so and i think we should chage that nightly job"
  severity: major
  test: 7
  root_cause: "Confirmed unrelated to the nightly job (which has no read/write path to the resume cursor or selection-mode state) and confirmed a DIFFERENT bug from the already-filed per-child position-keying gap (that one is about cross-profile collisions; this reproduces on a single profile). Phase 18-07's live 'selection mode' render state (selectionActive + the shell-local _presentedId) is entirely session-scoped, in-memory, and never persisted or re-seeded from the durable Drift GraphPosition cursor. LetterUnitController.start() resets selectionActive to false on every fresh call, and a cold relaunch creates a new screen state with _presentedId == null, so the render condition always falls back to the legacy _section(index) walk. That legacy fallback's own section-hint heuristic (keyed on clearedCompetencies.length, not on the actual currentExerciseId) commonly resolves to section 0 in a short session — matching 'started from scratch' exactly, even though the underlying GraphPosition.currentExerciseId IS still correctly persisted and read from Drift."
  artifacts:
    - path: "lib/features/letter_unit/letter_unit_screen.dart"
      issue: "_UnitShellState._presentedId never seeded from the restored currentExerciseId on initState; render condition falls back to the legacy section walk after any cold boot"
    - path: "lib/features/letter_unit/letter_unit_controller.dart"
      issue: "start() resets selectionActive to false every call; _sectionHintFor() is a coarse, currentExerciseId-blind fallback that commonly resolves to section 0"
    - path: "lib/data/app_database.dart"
      issue: "LetterGraphPosition table has no field to persist selection-mode state (by design, but incomplete for resume)"
  missing:
    - "On start()/initState(), when a saved GraphPosition.currentExerciseId exists and resolves to a real graph node, restore selectionActive: true and seed _presentedId directly from it — bypassing the legacy section-hint walk — so a relaunch re-enters presenter mode on the exact node the child was on"
  debug_session: ".planning/debug/resume-position-lost-on-relaunch.md"
