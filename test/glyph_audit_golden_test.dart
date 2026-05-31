// D-12 — the four-form glyph-audit risk gate (baseline landed in plan 01-03).
//
// This golden is the regression gate: a font swap or Flutter upgrade that breaks
// Arabic shaping (tofu, wrong contextual form, لا not forming the ﻻ ligature,
// clipped tashkeel) changes the rendered grid and fails this test.
//
// FONTS: test/flutter_test_config.dart loads the BUNDLED TTFs (Noto Naskh Arabic
// et al.) into the test engine before this runs — without it, headless
// `flutter test` falls back to a font with no Arabic glyphs and the grid renders
// as tofu (Pitfall 3), which would defeat the whole gate. With it, this golden
// genuinely exercises Noto Naskh's contextual shaping.
//
// SURFACE: the audit renders every cell at the child-facing 96px display size.
// The surface is sized TALL (1280 logical wide × the full content height) so the
// committed baseline PNG shows ALL critical rows in one image — the four-form
// grid, the لا ligature, the tashkeel row at line-height 2.0, and the mixed
// Arabic+Western-digit row — so the Task-3 human visual-PASS can inspect the
// whole audit from the single golden file, not just the top fold.
//
// BASELINE STATUS: the committed baseline is PROVISIONAL until the D-12 human
// visual-PASS (plan 01-03, Task 3). Regenerate with:
//   flutter test --update-goldens test/glyph_audit_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/dev/glyph_audit_screen.dart';

void main() {
  testWidgets('Noto Naskh shapes all four contextual forms — golden gate (D-12)',
      (WidgetTester tester) async {
    // Tablet width (1280 logical) × a tall surface so the full scrollable audit
    // is captured in the baseline. dpr 2.0 → physical 2560 wide.
    const double logicalWidth = 1280;
    const double logicalHeight = 2700;
    tester.view.physicalSize = const Size(logicalWidth * 2, logicalHeight * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: GlyphAuditScreen()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GlyphAuditScreen),
      matchesGoldenFile('goldens/glyph_audit.png'),
    );
  });
}
