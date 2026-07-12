// The speak-the-line PRESENCE hook (Phase 16, PRES-01/PRES-02 — Plan 16-04 T1).
//
// PROVES the two-clocks contract (D-05) and the offline-floor-speaks rule (D-04):
//
//   • applyResult (GROUND-01 / the instant clock) runs FIRST and unchanged — the
//     scorer's verdict + star render synchronously; the spoken coach line is fired
//     a BEAT LATER (inside brain.next(...).then) on BOTH a clean pass and a miss.
//   • The speaker is handed the SAME resolved bubble text the UI shows: the live
//     agent line when present, else the AuthoredFallback floor's authored line —
//     so the floor speaks in airplane mode (D-04).
//   • Ordering: the verdict is recorded BEFORE speak() is ever called.
//   • On _clear (Clear / Try-again), any in-flight TTS is stopped (a cleared idle
//     is silent).
//
// The speak hook fires through the scaffold's _onResult, which the WriteSurface
// invokes via its onResult callback. We drive it the way the surface would: grab
// the live WriteSurface widget from the tree and call its onResult(result). That
// exercises the real _onResult path (applyResult → brain.next → set line → speak)
// without needing real strokes or a real recognizer.
//
// The speaker is a recording CoachSpeaker fake (the NoopTtsCoachSpeaker posture
// from 16-02, extended to record). No real TTS backend runs in flutter_test.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/exercise_controller.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/providers/tts_providers.dart';
import 'package:qalam/tutor/authored_fallback_brain.dart';
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/tutor/tutor_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_providers.dart';

/// A recording coach speaker — every speak()/stop() is logged so a test can assert
/// exactly which line was voiced, in what order, and that clearing stopped TTS.
class _RecordingSpeaker implements CoachSpeaker {
  final List<String> spoken = <String>[];
  int stopCalls = 0;

  @override
  Future<void> speak(String line) async {
    spoken.add(line);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {}
}

/// A brain that returns a fixed agent line on every next() — stands in for the
/// online RemoteAgentBrain's grounded coaching line.
class _FixedAgentBrain implements TutorBrain {
  _FixedAgentBrain(this.line);
  final String line;

  @override
  Future<TutorDecision> next(TutorFacts facts) async =>
      PresentActivity(coachingLine: line, letterId: facts.letterId);
}

Letter _baa() {
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
  return const Letter(
    id: 'baa',
    char: 'ب',
    name: LetterName(ar: 'باء', display: 'baa'),
    introOrder: 2,
    forms: LetterForms(isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
    referenceStrokes: [body, dot],
    cleanRepsToAdvance: 1,
    commonMistakes: [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: {'isolated': Form(referenceStrokes: [body, dot])},
  );
}

Exercise _graded() => const Exercise(
      id: 'baa.traceLetter',
      skill: 'formation',
      prompt: [SayPart('Trace baa.'), AudioPart('baa-sound')],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {
        'pass': 'أحسنت — a smooth, deep curve.',
        'shallowBowl': 'Your baa needs a deeper curve — try again, slower.',
      },
      signedOff: false,
    );

Future<void> _pump(
  WidgetTester tester, {
  required _RecordingSpeaker speaker,
  required TutorBrain Function(Map<String, String>) brainFactory,
}) async {
  tester.view.physicalSize = const Size(1280, 800); // tablet landscape
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ttsCoachSpeakerProvider.overrideWithValue(speaker),
        tutorBrainFactoryProvider.overrideWithValue(brainFactory),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ExerciseScaffold(exercise: _graded(), letter: _baa()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Drive _onResult the way the WriteSurface would: grab the live WriteSurface and
/// invoke its onResult callback with [result].
Future<void> _fireResult(WidgetTester tester, CheckResult result) async {
  final surface = tester.widget<WriteSurface>(find.byType(WriteSurface));
  surface.onResult!(result);
  await tester.pumpAndSettle();
}

void main() {
  group('speak-the-line hook (D-05 two clocks, D-04 floor speaks)', () {
    testWidgets('a PASS speaks the agent line a beat after the verdict',
        (tester) async {
      final speaker = _RecordingSpeaker();
      await _pump(
        tester,
        speaker: speaker,
        brainFactory: (_) => _FixedAgentBrain('Beautiful work — keep going.'),
      );

      await _fireResult(tester, const CheckResult.pass());

      // The verdict rendered (the star) AND the agent line was spoken.
      expect(find.byIcon(Icons.star_rounded), findsOneWidget,
          reason: 'GROUND-01: the scorer verdict + star render instantly');
      expect(speaker.spoken, contains('Beautiful work — keep going.'),
          reason: 'the agent line is voiced a beat after the verdict');
    });

    testWidgets('a MISS speaks the agent fix line a beat after the verdict',
        (tester) async {
      final speaker = _RecordingSpeaker();
      await _pump(
        tester,
        speaker: speaker,
        brainFactory: (_) => _FixedAgentBrain('Deeper curve at the bottom.'),
      );

      await _fireResult(tester, const CheckResult.fail('shallowBowl'));

      // The fix verdict rendered (no star, coral X) AND the line was spoken.
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(speaker.spoken, contains('Deeper curve at the bottom.'),
          reason: 'speak fires on a miss too (the .then runs for both)');
    });

    testWidgets('the AuthoredFallback FLOOR line is voiced (D-04 — offline)',
        (tester) async {
      final speaker = _RecordingSpeaker();
      // The floor brain returns the SAME authored line the bubble shows; the
      // hook must voice that authored line (airplane-mode coaching speaks).
      await _pump(
        tester,
        speaker: speaker,
        brainFactory: (feedback) => AuthoredFallbackBrain(feedback: feedback),
      );

      await _fireResult(tester, const CheckResult.fail('shallowBowl'));

      expect(
        speaker.spoken,
        contains('Your baa needs a deeper curve — try again, slower.'),
        reason: 'the floor authored line speaks offline (D-04)',
      );
    });

    testWidgets('the floor PASS line is voiced on a pass (D-04)', (tester) async {
      final speaker = _RecordingSpeaker();
      await _pump(
        tester,
        speaker: speaker,
        brainFactory: (feedback) => AuthoredFallbackBrain(feedback: feedback),
      );

      await _fireResult(tester, const CheckResult.pass());

      expect(speaker.spoken, contains('أحسنت — a smooth, deep curve.'),
          reason: 'the floor pass line speaks offline (D-04)');
    });

    testWidgets('verdict is recorded BEFORE speak() (ordering — GROUND-01)',
        (tester) async {
      final speaker = _RecordingSpeaker();
      await _pump(
        tester,
        speaker: speaker,
        brainFactory: (_) => _FixedAgentBrain('Lovely.'),
      );

      final ctx = tester.element(find.byType(ExerciseScaffold));
      final container = ProviderScope.containerOf(ctx);

      // At the synchronous instant _onResult returns, the verdict is already
      // applied (the instant clock) but the brain.next(...).then has NOT yet
      // resolved — so speak has NOT been called. The voice arrives a beat later.
      final surface = tester.widget<WriteSurface>(find.byType(WriteSurface));
      // The exercise-open INSTRUCTION utterance (owner directive 2026-07-12:
      // the tutor says what is needed before the child writes) may already be
      // in the log — snapshot it. GROUND-01 is about the VERDICT line only.
      final beforeVerdict = List<String>.of(speaker.spoken);
      surface.onResult!(const CheckResult.pass());

      // Verdict applied synchronously…
      expect(container.read(exerciseControllerProvider).phase,
          ExercisePhase.pass,
          reason: 'applyResult runs first/synchronously (GROUND-01)');
      // …but no NEW spoken line has landed yet (it is fired in the async .then).
      expect(speaker.spoken, beforeVerdict,
          reason: 'the verdict line is fired a BEAT later, never before the verdict');

      // After the microtask drains, the line is spoken.
      await tester.pumpAndSettle();
      expect(speaker.spoken, contains('Lovely.'));
    });

    testWidgets('clearing stops in-flight TTS (a cleared idle is silent)',
        (tester) async {
      final speaker = _RecordingSpeaker();
      await _pump(
        tester,
        speaker: speaker,
        brainFactory: (_) => _FixedAgentBrain('Try again, slower.'),
      );

      // A miss → fix state → the Clear / Try-again CTAs appear.
      await _fireResult(tester, const CheckResult.fail('shallowBowl'));
      // Baseline stops (initState fires one stale-clear stop at unit open); the
      // tap must add at least one MORE on top of whatever has happened so far.
      final before = speaker.stopCalls;

      // Tap "Try again" (which drives _clear) → in-flight TTS is stopped.
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(speaker.stopCalls, greaterThan(before),
          reason: '_clear stops any in-flight TTS so a cleared idle is silent');
    });
  });
}
