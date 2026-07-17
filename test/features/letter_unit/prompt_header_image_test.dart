// PromptHeader stimulus-image sizing + caption bidi — Plan 18-13 (UAT T2).
//
// Two confirmed render bugs in _ImagePart (see .planning/debug/
// stimulus-picture-too-small.md):
//   1. The stimulus picture used an ABSOLUTE fixed-size box (260x176), so on a
//      real tablet's wide main column it read as a small island in a wide row.
//      The fix sizes the lone picture-prompt image RESPONSIVELY to a fraction of
//      the available header width, at the authored ~260:176 aspect — big on a
//      wide column, shrinking to fit a narrow one.
//   2. The English caption ("what does it start with?") had no explicit
//      textDirection, so under the exercise's ambient RTL Directionality its
//      trailing "?" bidi-jumped to the front ("?what does it start with"). The
//      fix pins the caption LTR (mirrors feedback_panel_v2's idle-hint fix).
//
// These tests fail against the pre-18-13 code (fixed box → no AspectRatio; caption
// → null textDirection) and pass once _ImagePart is responsive + LTR-pinned.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/features/letter_unit/widgets/prompt_header.dart';
import 'package:qalam/models/exercise.dart';

/// Pumps a [PromptHeader] inside a bounded-width column so the responsive image
/// has a real available width to size against (mirrors _mainColumn's stretch
/// Column). The ambient Directionality is RTL, exactly like ExerciseScaffold —
/// so the caption's LTR pin is exercised under the same base direction that
/// caused the trailing-"?" jump.
Future<void> _pumpHeader(
  WidgetTester tester, {
  required double width,
  required List<PromptPart> parts,
}) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: PromptHeader(parts: parts),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The lone-image picture prompt shape (baa.writeLetter.fromPicture): [say, image]
/// with NO TextPart sibling — the exercise the owner UAT flagged.
List<PromptPart> _picturePrompt() => const [
      SayPart('Look at the picture.'),
      ImagePart('img.duck', caption: 'what does it start with?'),
    ];

void main() {
  group('_ImagePart responsive stimulus sizing (UAT T2)', () {
    testWidgets(
        'Test 1: on a WIDE header the stimulus grows well past the old 260px box',
        (tester) async {
      const double available = 900;
      await _pumpHeader(tester, width: available, parts: _picturePrompt());

      // The responsive image sizes via an AspectRatio box (the pre-fix fixed
      // Container had none) — so its presence alone proves the sizing strategy
      // changed from a pixel constant to responsive.
      final box = find.byType(AspectRatio);
      expect(box, findsOneWidget,
          reason: 'the stimulus must size via a responsive AspectRatio box, '
              'not a hardcoded pixel Container');

      final double w = tester.getSize(box).width;
      // Materially larger than the old 260px cap AND a readable fraction of the
      // available header width (>= ~55%): the child reads the question from it.
      expect(w, greaterThan(260),
          reason: 'the image must be larger than the old fixed 260px box');
      expect(w, greaterThanOrEqualTo(available * 0.55),
          reason: 'the image must claim a readable fraction of the wide column');
    });

    testWidgets(
        'Test 2: on a NARROW header the stimulus shrinks to fit and never overflows',
        (tester) async {
      const double narrow = 360;
      await _pumpHeader(tester, width: narrow, parts: _picturePrompt());

      final box = find.byType(AspectRatio);
      expect(box, findsOneWidget);

      final double w = tester.getSize(box).width;
      // Shrinks to fit the narrow column (fits inside it) and is materially
      // smaller than the wide-column size (proves it scales with available width,
      // it is not a fixed pixel box).
      expect(w, lessThanOrEqualTo(narrow),
          reason: 'the image must fit inside a narrow column, never overflow');
      expect(w, lessThan(900 * 0.55),
          reason: 'the narrow-column image must be smaller than the wide one');
      // No layout overflow was thrown during the pump.
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Test 3: a lone stimulus still silently degrades (unknown id → stub, no throw)',
        (tester) async {
      await _pumpHeader(
        tester,
        width: 900,
        parts: const [
          SayPart('Look.'),
          ImagePart('img.nope', caption: 'what does it start with?'),
        ],
      );
      // The unmapped id degrades to the hatched stub (the id shown as Text),
      // never throws — the silent-degrade posture is preserved under responsive
      // sizing.
      expect(find.text('img.nope'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
      // Still sized responsively (the AspectRatio box wraps the stub too).
      expect(find.byType(AspectRatio), findsOneWidget);
    });
  });

  group('_ImagePart caption bidi (UAT T2)', () {
    testWidgets(
        'Test 4: the English caption is pinned LTR so trailing "?" stays at the end',
        (tester) async {
      await _pumpHeader(tester, width: 900, parts: _picturePrompt());

      final caption = find.byWidgetPredicate(
        (w) => w is Text && w.data == 'what does it start with?',
      );
      expect(caption, findsOneWidget,
          reason: 'the source caption string must render unchanged');

      final text = tester.widget<Text>(caption);
      expect(text.textDirection, TextDirection.ltr,
          reason: 'the caption must be pinned LTR under the ambient RTL '
              'Directionality (mirrors feedback_panel_v2.dart), so the trailing '
              '"?" does not bidi-jump to the front');
    });
  });
}
