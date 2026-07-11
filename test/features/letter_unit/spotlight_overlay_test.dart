// SpotlightOverlay behavior — Plan 18-10 Task 2 (D-05, sketch 002 Variant B).
//
// During a `type=='microDrill'` exercise the full letter stays visible, the
// target criterion's zone (from the drill's authored `spotlightZone`) is lit, and
// everything else dims. The overlay is PRESENTATIONAL ONLY — the child still
// WRITES on the existing WriteSurface/StrokeCanvas/scorer path; the overlay adds
// no gesture handling and never intercepts capture. These tests prove:
//   • a micro-drill renders the SpotlightOverlay carrying the correct lit zone.
//   • a non-drill exercise renders NO overlay (it is inert).
//   • the overlay adds no GestureDetector and wraps in IgnorePointer, and stroke
//     capture still reaches the StrokeCanvas (D-05 "the child still writes").

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/widgets/spotlight_overlay.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/features/practice/widgets/stroke_canvas.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';

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

/// A baa "just the dot" micro-drill — type microDrill, spotlightZone 'dot',
/// criterion 'dot' (the D-08 verdict owner). Write mode / glyph (the real config).
Exercise _dotDrill() => const Exercise(
      id: 'baa.microDrill.dot',
      type: 'microDrill',
      skill: 'formation',
      prompt: [SayPart('Just the dot this time.')],
      surface: Surface(mode: 'write', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {'pass': 'There it is.'},
      signedOff: false,
      criteria: ['dot'],
      spotlightZone: 'dot',
    );

/// A normal (non-drill) trace exercise — no spotlight.
Exercise _traceGlyph() => const Exercise(
      id: 'baa.traceLetter',
      skill: 'formation',
      prompt: [SayPart('Trace baa.')],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {'pass': 'Beautiful baa.'},
      signedOff: false,
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SizedBox(width: 900, height: 600, child: child)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('Test 1: a micro-drill renders the Spotlight lighting the target zone',
      (tester) async {
    await _pump(
      tester,
      WriteSurface(
        exercise: _dotDrill(),
        surface: _dotDrill().surface!,
        letter: _baa(),
      ),
    );

    expect(find.byType(SpotlightOverlay), findsOneWidget);
    final overlay =
        tester.widget<SpotlightOverlay>(find.byType(SpotlightOverlay));
    // The overlay reads the drill's authored lit-region string.
    expect(overlay.spotlightZone, 'dot');
  });

  testWidgets('Test 2: a non-drill exercise renders NO Spotlight (inert)',
      (tester) async {
    await _pump(
      tester,
      WriteSurface(
        exercise: _traceGlyph(),
        surface: _traceGlyph().surface!,
        letter: _baa(),
      ),
    );

    expect(find.byType(SpotlightOverlay), findsNothing);
  });

  testWidgets('Test 3: the overlay never intercepts stroke capture (D-05)',
      (tester) async {
    CheckResult? received;
    await _pump(
      tester,
      WriteSurface(
        exercise: _dotDrill(),
        surface: _dotDrill().surface!,
        letter: _baa(),
        onResult: (r) => received = r,
      ),
    );

    // Presentational only: no gesture handling inside the overlay, wrapped in
    // IgnorePointer so pointer events pass straight through to the StrokeCanvas.
    expect(
      find.descendant(
        of: find.byType(SpotlightOverlay),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(SpotlightOverlay),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );

    // Capture still reaches the StrokeCanvas — the child writes as usual and the
    // verdict flows to the host (the overlay changed nothing on the score path).
    final canvas = tester.widget<StrokeCanvas>(find.byType(StrokeCanvas));
    canvas.onLetterComplete!(const [
      [Offset(20, 40), Offset(50, 60), Offset(80, 40)],
      [Offset(50, 75)],
    ]);
    await tester.pumpAndSettle();
    expect(received, isNotNull);
    expect(received, isA<CheckResult>());
  });
}
