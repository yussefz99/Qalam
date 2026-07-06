// exercise_scaffold_cutover — the BEHAVIORAL pin for D-A (Plan 17-07 Task 2).
//
// The grep-guard (stroke_image_grep_guard_test) proves the strokeImage render is
// gone from source. THIS test proves the RUNTIME contract the cutover exists for:
// the deterministic on-device scorer OWNS pass/fail on every path, so a cold,
// slow, offline, or FAILING brain can never affect the verdict or the star — only
// the words (D-A; GROUND-01 restored; UAT F2 made structurally impossible).
//
// The brain is stubbed at the ONE switch point (tutorBrainFactoryProvider): a
// never-completing future (the network never answers) and an error-completing
// future (the network fails). In both, the verdict must already stand.
//
// Pure widget test: no Firebase, no network, no model (flutter_test_config.dart
// loads the Arabic fonts automatically).

import 'dart:async';

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/exercise_controller.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/tutor/tutor_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_providers.dart';

// ── fixtures ──────────────────────────────────────────────────────────────────

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
      prompt: [SayPart('Trace baa.')],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {
        'pass': 'Beautiful — a smooth, deep curve.',
        'shallowBowl': 'Your baa needs a deeper curve.',
      },
      signedOff: false,
    );

/// A [TutorBrain] whose next() NEVER answers — the network hangs forever. If the
/// verdict were gated on the brain, the star/CTA would never appear.
class _NeverBrain implements TutorBrain {
  final Completer<TutorDecision> _pending = Completer<TutorDecision>();
  bool called = false;

  @override
  Future<TutorDecision> next(TutorFacts facts) {
    called = true;
    return _pending.future; // deliberately never completed
  }
}

/// A [TutorBrain] whose next() FAILS — the network errors. The catchError path
/// may clear the tutor line, but must NEVER touch the applied verdict.
class _ErrorBrain implements TutorBrain {
  bool called = false;

  @override
  Future<TutorDecision> next(TutorFacts facts) {
    called = true;
    return Future<TutorDecision>.error(StateError('brain down'));
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
        // The ONE backend switch point — return the stub for baa's factory.
        tutorBrainFactoryProvider
            .overrideWithValue((Map<String, String> feedback) => brain),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('D-A cutover — the scorer verdict never waits on, and is never overturned '
      'by, the brain', () {
    testWidgets('Test 1: verdict applies WITHOUT the brain — a never-completing '
        'brain future still yields the star + pass CTA', (tester) async {
      final brain = _NeverBrain();
      await _pumpScaffold(
        tester,
        ExerciseScaffold(exercise: _graded(), letter: _baa()),
        brain: brain,
      );

      // Drive a scored PASS through the public path (WriteSurface.onResult ==
      // the scaffold's _onResult, exactly what the canvas fires on completion).
      final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
      ws.onResult!(const CheckResult.pass());
      await tester.pump(); // ONE frame — the brain future is left pending

      // The brain WAS consulted (for the words), but the verdict did not wait:
      // the pass star + "Next exercise" CTA rendered while the future is pending.
      expect(brain.called, isTrue);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('Next exercise'), findsOneWidget);
    });

    testWidgets('Test 2: a FAILING brain future leaves the verdict standing — only '
        'the tutor line clears, no reversal, no flash-then-overwrite',
        (tester) async {
      final brain = _ErrorBrain();
      await _pumpScaffold(
        tester,
        ExerciseScaffold(exercise: _graded(), letter: _baa()),
        brain: brain,
      );

      final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
      ws.onResult!(const CheckResult.fail('shallowBowl'));
      await tester.pumpAndSettle(); // let the brain error surface via catchError

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ExerciseScaffold)),
      );

      // The FIX verdict STANDS after the error — the coral X, the authored fix
      // line, and NO star. The brain failure did not reverse the scorer.
      expect(brain.called, isTrue);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.text('Your baa needs a deeper curve.'), findsWidgets);
      // Only the tutor coaching-line channel was cleared (null) — the words, not
      // the verdict.
      expect(container.read(tutorLineProvider), isNull);
    });

    testWidgets('Test 3: no deferral path — the verdict is set SYNCHRONOUSLY in the '
        'same call as the scorer result; the brain fires AFTER', (tester) async {
      final brain = _NeverBrain();
      await _pumpScaffold(
        tester,
        ExerciseScaffold(exercise: _graded(), letter: _baa()),
        brain: brain,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ExerciseScaffold)),
      );
      // Before the result the controller is idle.
      expect(container.read(exerciseControllerProvider).phase, ExercisePhase.idle);

      final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
      ws.onResult!(const CheckResult.pass());

      // IMMEDIATELY after the call returns — NO pump, NO await — the verdict is
      // already applied (synchronous, not gated on the network) and the brain has
      // already been fired (after the verdict). This is the structural D-A pin:
      // there is no code path that gates applyResult on the brain response.
      expect(container.read(exerciseControllerProvider).phase, ExercisePhase.pass);
      expect(brain.called, isTrue);
    });
  });
}
