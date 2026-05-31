// Wave-0 validation scaffold — D-12 (the four-form glyph-audit risk gate).
//
// INTENTIONALLY RED at Wave 0: imports package:qalam/dev/glyph_audit_screen.dart,
// which does not yet exist. A later plan builds GlyphAuditScreen (the ZWJ
// four-form grid rendered with the bundled Noto Naskh Arabic font) and lands
// the baseline golden image. Do NOT add a lib/ stub or a baseline here.
//
// This golden is the regression gate: once GlyphAuditScreen and its baseline
// exist, a font swap or Flutter upgrade that breaks Arabic shaping (tofu,
// wrong contextual form, لا not forming the ﻻ ligature) fails this test.
//
// The baseline file (test/goldens/glyph_audit.png) is a TODO until the screen
// lands — so matchesGoldenFile is red now for the right reason.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/dev/glyph_audit_screen.dart';

void main() {
  testWidgets('Noto Naskh shapes all four contextual forms — golden gate (D-12)',
      (WidgetTester tester) async {
    // The audit grid renders at the child-facing 96px display size so shaping
    // is inspectable; landscape surface matches the tablet canvas.
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: GlyphAuditScreen()));
    await tester.pumpAndSettle();

    // TODO(baseline): generate test/goldens/glyph_audit.png with
    //   `flutter test --update-goldens test/glyph_audit_golden_test.dart`
    // ONLY after a human confirms the four-form shaping is genuinely correct
    // (no tofu, لا → single ﻻ ligature, joins intact, tashkeel unclipped).
    await expectLater(
      find.byType(GlyphAuditScreen),
      matchesGoldenFile('goldens/glyph_audit.png'),
    );
  });
}
