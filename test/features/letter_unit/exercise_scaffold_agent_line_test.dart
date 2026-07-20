// exercise_scaffold_agent_line — the LIVE-PATH regression PIN for D-06b (Plan 26-04).
//
// Standing bug (Phase-14/17 feedback debt): the bottom feedback bar showed the
// AUTHORED floor line instead of the AGENT's line. Phase 17.2 routed the agent line
// to the foot + bubble on the baa/agent path; THIS test PINS that invariant so it can
// never silently regress (project memory: "live-path widget tests mandatory" and
// "bottom feedback bar shows authored line not the agent line").
//
// It drives the REAL _onResult seam — WriteSurface.onResult, exactly what the canvas
// fires on completion — with the fake brain injected at the ONE switch point
// (tutorBrainFactoryProvider), never a hand-built widget. It proves:
//   1. before the agent line resolves, the foot WORDS are empty (the verdict ✕/star
//      still renders INSTANTLY from the scorer) — the authored floor never flashes;
//   2. when the agent answers, its DISTINCTIVE line is the ONLY feedback text — shown
//      in BOTH the bottom FeedbackPanelV2 and the tutor bubble; the authored floor is
//      absent from the agent-path foot;
//   3. a NON-agent letter (alif) still shows its own authored state.line in the foot
//      (the floor is correct off the baa path);
//   4. a source pin: the agent-path foot line reads from agentLine, not the floor.
//
// GROUND-01 is untouched: the deterministic scorer owns pass/fail + the star; only the
// WORDS are the agent's. Pure widget test: no Firebase, no network, no model.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/feedback_panel_v2.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/providers/tts_providers.dart';
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/tutor/tutor_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_providers.dart';

// ── fixtures ────────────────────────────────────────────────────────────────

const _authoredPass = 'Lovely — a smooth, round bowl.'; // authored floor (pass)
const _authoredFix =
    'Round the bottom of your baa a little more.'; // authored floor (fail)
// A DISTINCTIVE agent line that could never be mistaken for the authored floor.
const _agentSentinel = 'AGENT_LINE_SENTINEL — nudge the dot a touch left.';

Letter _letter(String id) {
  const body = StrokeSpec(
    order: 1,
    label: 'boat',
    type: 'curve',
    points: [
      [0.2, 0.4],
      [0.5, 0.6],
      [0.8, 0.4],
    ],
    direction: 'rightToLeft',
  );
  const dot = StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    points: [
      [0.5, 0.75],
    ],
    direction: 'none',
  );
  return Letter(
    id: id,
    char: 'ب',
    name: const LetterName(ar: 'باء', display: 'baa'),
    introOrder: 2,
    forms: const LetterForms(
        isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
    referenceStrokes: const [body, dot],
    cleanRepsToAdvance: 1,
    commonMistakes: const [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: const {'isolated': Form(referenceStrokes: [body, dot])},
  );
}

/// The live-agent letter — its feedback WORDS come ONLY from the brain.
Letter _baa() => _letter('baa');

/// A non-agent letter — keeps the instant authored floor (unchanged path).
Letter _alif() => _letter('alif');

Exercise _graded() => const Exercise(
      id: 'baa.traceLetter',
      skill: 'formation',
      prompt: [SayPart('Trace baa.')],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {'pass': _authoredPass, 'shallowBowl': _authoredFix},
      signedOff: false,
    );

/// A brain whose next() answer is held on a Completer, so the test can assert the
/// EMPTY-until-resolved window, then release the DISTINCTIVE agent line.
class _DeferredSayBrain implements TutorBrain {
  _DeferredSayBrain(this.line);
  final String line;
  final Completer<TutorDecision> _c = Completer<TutorDecision>();
  bool called = false;

  @override
  Future<TutorDecision> next(TutorFacts facts) {
    called = true;
    return _c.future;
  }

  void resolve() {
    if (!_c.isCompleted) _c.complete(Say(line));
  }
}

/// A brain that never answers — used on the NON-agent letter case, where the
/// injected brain must never be consulted (the authored floor is instant).
class _NeverBrain implements TutorBrain {
  final Completer<TutorDecision> _c = Completer<TutorDecision>();
  bool called = false;

  @override
  Future<TutorDecision> next(TutorFacts facts) {
    called = true;
    return _c.future;
  }
}

Future<void> _pumpScaffold(
  WidgetTester tester,
  Widget child, {
  required TutorBrain brain,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // The ONE backend switch point — the injected brain IS the agent path.
        tutorBrainFactoryProvider
            .overrideWithValue((Map<String, String> feedback) => brain),
        // No real synthesis in a widget test — the coach voice is a silent no-op.
        ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'baa agent path: the foot + bubble show the AGENT line, never the authored '
      'floor — and the words stay EMPTY until it resolves (D-06b)',
      (tester) async {
    final brain = _DeferredSayBrain(_agentSentinel);
    await _pumpScaffold(
      tester,
      ExerciseScaffold(exercise: _graded(), letter: _baa()),
      brain: brain,
    );

    // Drive a scored FAIL through the REAL seam (WriteSurface.onResult == the
    // scaffold's _onResult, exactly what the canvas fires on completion).
    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.fail('shallowBowl'));
    await tester.pump(); // ONE frame — the brain future is still pending

    // (1) The verdict ✕ renders INSTANTLY from the scorer, but the WORDS are empty:
    // neither the authored floor nor the (unresolved) agent line is on screen.
    expect(brain.called, isTrue);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text(_authoredFix), findsNothing,
        reason: 'the authored floor must NEVER flash on the agent path (D-06b)');
    expect(find.text(_agentSentinel), findsNothing);

    // (2) When the agent answers, its line is the ONLY feedback text — shown in
    // BOTH the bottom FeedbackPanelV2 and the tutor bubble; the floor stays absent.
    brain.resolve();
    await tester.pumpAndSettle();

    expect(find.text(_agentSentinel), findsNWidgets(2),
        reason: 'the agent line renders in the foot bar AND the tutor bubble');
    expect(
      find.descendant(
        of: find.byType(FeedbackPanelV2),
        matching: find.text(_agentSentinel),
      ),
      findsOneWidget,
      reason: 'the bottom feedback bar renders the agent line, not the floor',
    );
    expect(find.text(_authoredFix), findsNothing,
        reason: 'the authored floor never leaks into the agent-path foot/bubble');
    // The verdict ✕ still stands under the agent's words (GROUND-01 untouched).
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets(
      'non-agent letter (alif): the foot shows the authored state.line — the floor '
      'is correct off the baa path', (tester) async {
    // The brain override is only consulted on the baa/agent path; alif uses the
    // AuthoredFallbackBrain internally, so the authored line shows instantly.
    await _pumpScaffold(
      tester,
      ExerciseScaffold(exercise: _graded(), letter: _alif()),
      brain: _NeverBrain(),
    );

    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.pass());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FeedbackPanelV2),
        matching: find.text(_authoredPass),
      ),
      findsOneWidget,
      reason: 'off the agent path the foot renders the authored floor (state.line)',
    );
  });

  test(
      'source pin: the agent-path foot line reads from agentLine, not the floor '
      '(D-06b key link)', () {
    final src = File(
      'lib/features/letter_unit/widgets/exercise_scaffold.dart',
    ).readAsStringSync();
    expect(
      src.contains("_isAgentPath ? (agentLine ?? '') : state.line"),
      isTrue,
      reason:
          'the _foot must render the agent line on the baa path (pattern: agentLine)',
    );
  });
}
