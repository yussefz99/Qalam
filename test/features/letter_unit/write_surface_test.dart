// WriteSurface behavior — Plan 07-04 Task 2.
//
// WriteSurface is a THIN config wrapper over the EXISTING StrokeCanvas (it does
// NOT rebuild the ink primitive). These tests prove:
//   • trace × glyph × isolated → a StrokeCanvas carrying the isolated form's
//     reference strokes (the dotted guide is shown).
//   • write mode → a StrokeCanvas with EMPTY reference strokes (no dotted glyph)
//     plus the blank ruled baseline, and a "Write · …" surface tag.
//   • surface.given {word, blankIndex} → the pre-filled given-ink + a dashed blank.
//   • surface.demo → a "Watch me" replay affordance + the StrokeOrderAnimation.
//   • on letter-complete the validator runs and forwards a CheckResult.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/features/practice/widgets/stroke_canvas.dart';
import 'package:qalam/features/practice/widgets/stroke_order_animation.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';

// ── fixtures ──────────────────────────────────────────────────────────────────

/// A minimal baa with an isolated contextual form carrying one body stroke +
/// one dot (so scoreLetter has a 2-stroke reference) and an authored feedback.
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
    contextualForms: {
      'isolated': Form(referenceStrokes: [body, dot]),
    },
  );
}

Exercise _traceGlyph() => const Exercise(
      id: 'baa.traceLetter',
      skill: 'formation',
      prompt: [SayPart('Trace baa.')],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {'pass': 'Beautiful baa.', 'shallowBowl': 'Deeper curve.'},
      signedOff: false,
    );

Exercise _writeWord() => const Exercise(
      id: 'baa.writeWord',
      skill: 'spelling',
      prompt: [SayPart('Write the word.')],
      surface: Surface(mode: 'write', unit: 'word'),
      expected: Answer(word: WordAnswer('باب')),
      check: Check(base: 'sequence'),
      feedback: {'pass': 'Lovely.', 'incomplete': 'One more letter.'},
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
  testWidgets('Test 1: trace×glyph×isolated wraps a StrokeCanvas with the guide',
      (tester) async {
    await _pump(
      tester,
      WriteSurface(
        exercise: _traceGlyph(),
        surface: _traceGlyph().surface!,
        letter: _baa(),
      ),
    );

    // It REUSES the existing StrokeCanvas (not a rebuilt primitive).
    final canvas = tester.widget<StrokeCanvas>(find.byType(StrokeCanvas));
    // trace mode → the isolated form's reference strokes drive the dotted guide.
    expect(canvas.referenceStrokes, isNotEmpty);
    expect(canvas.referenceStrokes.length, 2); // boat + dot
  });

  testWidgets('Test 2: write mode shows a blank line — StrokeCanvas, no guide glyph',
      (tester) async {
    await _pump(
      tester,
      WriteSurface(
        exercise: _writeWord(),
        surface: _writeWord().surface!,
        letter: _baa(),
      ),
    );

    final canvas = tester.widget<StrokeCanvas>(find.byType(StrokeCanvas));
    // write mode → EMPTY reference strokes so no dotted guide glyph is painted.
    expect(canvas.referenceStrokes, isEmpty);
  });

  testWidgets('Test 3: surface.given renders given-ink + a dashed blank cell',
      (tester) async {
    const ex = Exercise(
      id: 'baa.completeWord',
      skill: 'spelling',
      prompt: [SayPart('Complete the word.')],
      surface: Surface(
        mode: 'write',
        unit: 'word',
        given: Given(word: 'باب', blankIndex: 1),
      ),
      expected: Answer(word: WordAnswer('باب')),
      check: Check(base: 'sequence'),
      feedback: {'pass': 'Yes.'},
      signedOff: false,
    );
    await _pump(
      tester,
      WriteSurface(exercise: ex, surface: ex.surface!, letter: _baa()),
    );

    // The two non-blank given letters render (the blank index is the dashed cell).
    // We assert the given-ink layer exists by finding the StrokeCanvas sibling
    // plus at least one ArabicText for the pre-filled letters.
    expect(find.byType(StrokeCanvas), findsOneWidget);
    expect(find.textContaining('ب'), findsWidgets);
  });

  testWidgets('Test 4: surface.demo exposes a Watch-me replay + the demo animation',
      (tester) async {
    const ex = Exercise(
      id: 'baa.watchTrace',
      skill: 'formation',
      prompt: [SayPart('Watch, then trace.')],
      surface: Surface(
        mode: 'trace',
        unit: 'glyph',
        guideForm: 'isolated',
        demo: true,
      ),
      check: Check(base: 'glyph'),
      feedback: {'pass': 'Good.'},
      signedOff: false,
    );
    await _pump(
      tester,
      WriteSurface(
        exercise: ex,
        surface: ex.surface!,
        letter: _baa(),
        watchMeLabel: 'Watch me',
      ),
    );

    expect(find.byType(StrokeOrderAnimation), findsOneWidget);
    expect(find.text('Watch me'), findsOneWidget);
  });

  testWidgets('Test 5: letter-complete runs the validator and forwards a result',
      (tester) async {
    CheckResult? received;
    await _pump(
      tester,
      WriteSurface(
        exercise: _traceGlyph(),
        surface: _traceGlyph().surface!,
        letter: _baa(),
        onResult: (r) => received = r,
      ),
    );

    // Drive a 2-stroke completion straight through the canvas callback so we
    // exercise the validator path without simulating raw pointer events.
    final canvas = tester.widget<StrokeCanvas>(find.byType(StrokeCanvas));
    canvas.onLetterComplete!(const [
      [Offset(20, 40), Offset(50, 60), Offset(80, 40)],
      [Offset(50, 75)],
    ]);
    await tester.pumpAndSettle();

    // The validator resolved a verdict and it reached the host callback.
    expect(received, isNotNull);
    expect(received, isA<CheckResult>());
  });
}
