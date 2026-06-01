// QalamMascot tests — the tutor's persona, rendered from the bundled brand SVGs
// with a graceful missing-asset fallback (DP-08/DP-09).
//
// The mascot is the consistent face of the patient teacher (CLAUDE.md: "Qalam
// mascot = the tutor's persona"). Each pose maps to a screen state; a missing
// asset must degrade to a calm placeholder, never a red error box or a crash —
// so a stage screenshot can never break.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/widgets/qalam_mascot.dart';

void main() {
  // Helper: pump a single mascot inside a minimal LTR app shell and return the
  // rendered SvgPicture (there is exactly one render path).
  Future<SvgPicture> pumpMascot(WidgetTester tester, QalamPose pose) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: QalamMascot(pose: pose)))),
    );
    return tester.widget<SvgPicture>(find.byType(SvgPicture));
  }

  testWidgets('Test 1: idle pose renders an SvgPicture for qalam-idle.svg',
      (WidgetTester tester) async {
    final SvgPicture svg = await pumpMascot(tester, QalamPose.idle);
    final loader = svg.bytesLoader as SvgAssetLoader;
    expect(loader.assetName, 'assets/mascot/qalam-idle.svg');
  });

  testWidgets('Test 2: each pose maps to its correct asset path',
      (WidgetTester tester) async {
    const expected = <QalamPose, String>{
      QalamPose.idle: 'assets/mascot/qalam-idle.svg',
      QalamPose.write: 'assets/mascot/qalam-write.svg',
      QalamPose.cheer: 'assets/mascot/qalam-cheer.svg',
      QalamPose.tryAgain: 'assets/mascot/qalam-try-again.svg',
      QalamPose.think: 'assets/mascot/qalam-think.svg',
    };
    for (final entry in expected.entries) {
      final SvgPicture svg = await pumpMascot(tester, entry.key);
      final loader = svg.bytesLoader as SvgAssetLoader;
      expect(loader.assetName, entry.value, reason: 'pose ${entry.key}');
    }
  });

  testWidgets(
      'Test 3: missing-asset errorBuilder renders a calm fallback, never throws',
      (WidgetTester tester) async {
    final SvgPicture svg = await pumpMascot(tester, QalamPose.idle);
    // The single render path supplies an error fallback builder.
    expect(svg.errorBuilder, isNotNull);

    // Invoke the errorBuilder as flutter_svg would on a decode failure and
    // render the result: it must produce a widget (the calm placeholder) and
    // must not throw or surface an exception.
    final BuildContext ctx = tester.element(find.byType(QalamMascot));
    final Widget fallback =
        svg.errorBuilder!(ctx, Exception('missing'), StackTrace.empty);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: fallback)));

    expect(tester.takeException(), isNull);
    expect(find.byType(Container), findsWidgets);
    // No red, no debug text leaking into the screenshot.
    expect(find.textContaining('Error'), findsNothing);
  });

  testWidgets('Test 4: exposes a non-empty semanticsLabel and respects size',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: QalamMascot(pose: QalamPose.cheer, size: 120),
          ),
        ),
      ),
    );
    final SvgPicture svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.semanticsLabel, isNotNull);
    expect(svg.semanticsLabel!.isNotEmpty, isTrue);
    expect(svg.width, 120);
    expect(svg.height, 120);
  });
}
