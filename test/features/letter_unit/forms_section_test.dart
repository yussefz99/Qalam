// FormsSection (Section 3 — Forms in context) behavior — Plan 07-05 Task 2.
//
// Section 3 shows the three form-step chips (initial/medial/final); selecting one
// loads its trace surface (the matching guideForm); completing all three advances
// to the join-into-باب stage. When a form's reference strokes are NOT yet
// authored (a null contextual Form — the pre-07-07 state), the section shows a
// calm "not yet authored" placeholder and does NOT crash or fabricate strokes —
// the human sign-off gate is honored.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/features/letter_unit/sections/forms_section.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/providers/audio_providers.dart';

import 'section_test_support.dart';

class _CapturingAudioPlayer implements LetterAudioPlayer {
  final List<String> played = <String>[];
  @override
  Future<void> playLetter(String assetPath) async {
    played.add(assetPath);
  }
}

/// A baa whose initial/medial/final Forms ARE authored — so selecting a chip
/// loads a real trace surface (the happy path).
Letter _baaWithAuthoredForms() {
  const body = StrokeSpec(
    order: 1,
    label: 'bowl',
    type: 'curve',
    points: [
      [0.25, 0.40],
      [0.50, 0.62],
      [0.75, 0.40],
    ],
    direction: 'rightToLeft',
  );
  return const Letter(
    id: 'baa',
    char: 'ب',
    name: LetterName(ar: 'باء', display: 'baa'),
    introOrder: 2,
    forms:
        LetterForms(isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
    referenceStrokes: [body],
    cleanRepsToAdvance: 1,
    commonMistakes: [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: {
      'isolated': Form(referenceStrokes: [body]),
      'initial': Form(referenceStrokes: [body]),
      'medial': Form(referenceStrokes: [body]),
      'final': Form(referenceStrokes: [body]),
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  Letter letter, {
  VoidCallback? onAdvance,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: FormsSection(
            initial: traceFormExercise('initial'),
            medial: traceFormExercise('medial'),
            finalForm: traceFormExercise('final'),
            join: joinExercise(),
            letter: letter,
            onAdvance: onAdvance,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Test 1: shows the three form-step chips', (tester) async {
    await _pump(tester, _baaWithAuthoredForms());

    expect(find.byType(FormStepChip), findsNWidgets(3));
    expect(find.byKey(const ValueKey('formChip:initial')), findsOneWidget);
    expect(find.byKey(const ValueKey('formChip:medial')), findsOneWidget);
    expect(find.byKey(const ValueKey('formChip:final')), findsOneWidget);
  });

  testWidgets('Test 2: selecting medial loads a trace surface with guideForm=medial',
      (tester) async {
    await _pump(tester, _baaWithAuthoredForms());

    // Tap the medial chip.
    await tester.tap(find.byKey(const ValueKey('formChip:medial')));
    await tester.pumpAndSettle();

    final surface = tester.widget<WriteSurface>(find.byType(WriteSurface));
    expect(surface.surface.mode, 'trace');
    expect(surface.surface.guideForm, 'medial');
  });

  testWidgets(
      'Test 3: a null (un-authored) Form degrades gracefully — placeholder, no crash, no scoring canvas',
      (tester) async {
    // baaLetter() has initial/medial/final as NULL Forms (the pre-07-07 state).
    await _pump(tester, baaLetter());

    // Select the initial chip — its Form is null.
    await tester.tap(find.byKey(const ValueKey('formChip:initial')));
    await tester.pumpAndSettle();

    // A calm "not yet authored" placeholder is shown.
    expect(find.byKey(const ValueKey('formNotYetAuthored')), findsOneWidget);
    // No WriteSurface scoring an empty / fabricated guide.
    expect(find.byType(WriteSurface), findsNothing);
    // No exception was thrown (reaching here proves it).
    expect(tester.takeException(), isNull);
  });

  testWidgets('Test 4: completing all three forms advances to the join-into-باب stage',
      (tester) async {
    await _pump(tester, _baaWithAuthoredForms());

    // Mark each form done via the section's test hook.
    final state =
        tester.state<FormsSectionState>(find.byType(FormsSection));
    state.debugMarkFormDone('initial');
    state.debugMarkFormDone('medial');
    state.debugMarkFormDone('final');
    await tester.pumpAndSettle();

    // The join stage shows its own trace/write surface for باب.
    expect(find.byKey(const ValueKey('joinStage')), findsOneWidget);
  });
}
