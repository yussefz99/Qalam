// ExerciseScaffold + ExerciseController behavior — Plan 07-04 Task 2.
//
// ExerciseScaffold is the RTL landscape page shell that hosts the 5 components +
// the mascot, config-driven from a single Exercise. These tests prove:
//   • load(exercise) lays out the slots: mascot + speech (left), PromptHeader +
//     WriteSurface + FeedbackPanel + CTA + ProgressRibbon (right), RTL landscape.
//   • a pass drives the scaffold to the pass state (one star + praise, mascot
//     cheer); a fail drives the fix state (coral fix line, mascot tryAgain).
//   • a teachCard (surface == null) renders PromptHeader-only — NO WriteSurface,
//     NO graded FeedbackPanel — with a support CTA.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/exercise_controller.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/feedback_panel_v2.dart';
import 'package:qalam/features/letter_unit/widgets/progress_ribbon.dart';
import 'package:qalam/features/letter_unit/widgets/prompt_header.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/widgets/qalam_mascot.dart';

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
        'pass': 'Beautiful — a smooth, deep curve.',
        'shallowBowl': 'Your baa needs a deeper curve.',
      },
      signedOff: false,
    );

/// A teachCard — no surface, no check, no feedback (a SUPPORT card).
Exercise _teachCard() => const Exercise(
      id: 'baa.meet',
      skill: 'formation',
      prompt: [
        SayPart('Meet baa.'),
        FormsPart(char: 'ب', forms: ['isolated', 'initial', 'medial', 'final']),
      ],
      signedOff: false,
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 800); // tablet landscape
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Test 1: load lays out the RTL landscape slots',
      (tester) async {
    await _pump(
      tester,
      ExerciseScaffold(
        exercise: _graded(),
        letter: _baa(),
        kick: 'Q1 · traceLetter',
        ribbon: (total: 6, active: 0),
      ),
    );

    // RTL landscape frame.
    final dir = tester.widget<Directionality>(
      find.ancestor(
        of: find.byType(PromptHeader),
        matching: find.byType(Directionality),
      ).first,
    );
    expect(dir.textDirection, TextDirection.rtl);

    // The 5 slots + mascot are present.
    expect(find.byType(QalamMascot), findsOneWidget); // tutor column
    expect(find.byType(PromptHeader), findsOneWidget); // top
    expect(find.byType(WriteSurface), findsOneWidget); // center (graded)
    expect(find.byType(FeedbackPanelV2), findsOneWidget); // bottom
    expect(find.byType(ProgressRibbon), findsOneWidget); // edge
    expect(find.text('Q1 · traceLetter'), findsOneWidget); // kick eyebrow
  });

  testWidgets('Test 2: a pass drives the scaffold to pass — star + praise + cheer',
      (tester) async {
    await _pump(
      tester,
      ExerciseScaffold(exercise: _graded(), letter: _baa()),
    );

    // Drive the controller to a pass (as the WriteSurface would on a clean rep).
    final ctx = tester.element(find.byType(ExerciseScaffold));
    final container = ProviderScope.containerOf(ctx);
    container.read(exerciseControllerProvider.notifier)
      ..load(_graded())
      ..applyResult(const CheckResult.pass());
    await tester.pumpAndSettle();

    // One star + the authored praise; the mascot cheers. The praise appears in
    // BOTH the speech bubble AND the FeedbackPanel (the prototype's
    // tutorAndFeedback), so assert presence (findsWidgets), not exactly one.
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('Beautiful — a smooth, deep curve.'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(FeedbackPanelV2),
        matching: find.text('Beautiful — a smooth, deep curve.'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
          (w) => w is QalamMascot && w.pose == QalamPose.cheer),
      findsOneWidget,
    );
    // The pass CTA appears.
    expect(find.text('Next exercise'), findsOneWidget);
  });

  testWidgets('Test 3: a fail drives the scaffold to fix — coral line + tryAgain',
      (tester) async {
    await _pump(
      tester,
      ExerciseScaffold(exercise: _graded(), letter: _baa()),
    );

    final ctx = tester.element(find.byType(ExerciseScaffold));
    final container = ProviderScope.containerOf(ctx);
    container.read(exerciseControllerProvider.notifier)
      ..load(_graded())
      ..applyResult(const CheckResult.fail('shallowBowl'));
    await tester.pumpAndSettle();

    // The specific authored fix line (in both the bubble + the panel) + the
    // coral X; the mascot tries again.
    expect(find.text('Your baa needs a deeper curve.'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(FeedbackPanelV2),
        matching: find.text('Your baa needs a deeper curve.'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(
      find.byWidgetPredicate(
          (w) => w is QalamMascot && w.pose == QalamPose.tryAgain),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Test 4: teachCard renders PromptHeader-only — no WriteSurface/grading',
      (tester) async {
    await _pump(
      tester,
      ExerciseScaffold(exercise: _teachCard(), letter: _baa()),
    );

    // PromptHeader present (the forms strip); NO WriteSurface, NO graded panel.
    expect(find.byType(PromptHeader), findsOneWidget);
    expect(find.byType(WriteSurface), findsNothing);

    // The four-forms strip is shown.
    expect(find.byType(FourFormsStrip), findsOneWidget);

    // No star, no fix X (nothing is graded on a teach card).
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    // A support CTA ("Got it") is shown instead of grading CTAs.
    expect(find.text('Got it'), findsOneWidget);
    expect(find.text('Next exercise'), findsNothing);
  });
}
