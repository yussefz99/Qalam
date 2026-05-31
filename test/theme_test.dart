// Wave-0 validation scaffold — D-01/D-02 (semantic theme tokens).
//
// This test is INTENTIONALLY RED at Wave 0: it imports lib/ symbols
// (QalamColors, QalamTheme) that do not yet exist. A later plan builds the
// theme layer and turns this green. Do NOT add lib/ stubs to satisfy it here.
//
// It asserts the semantic color tokens equal the design-kit CSS hex values
// (colors_and_type.css): primary ink-teal #168A8F, bg parchment #FAF6EE,
// reward gold #F2A60C — and that the QalamTheme ThemeExtension exposes the
// brand tokens Material's ColorScheme has no slot for.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/theme/colors.dart';
import 'package:qalam/theme/brand_theme_ext.dart';

void main() {
  group('Semantic color tokens match the design-kit CSS (D-01/D-02)', () {
    test('primary is ink-teal #168A8F', () {
      expect(QalamColors.primary, const Color(0xFF168A8F));
    });

    test('background is parchment #FAF6EE (never stark white)', () {
      expect(QalamColors.bg, const Color(0xFFFAF6EE));
    });

    test('reward is gold-ink #F2A60C (rewards only)', () {
      expect(QalamColors.reward, const Color(0xFFF2A60C));
    });

    test('warn-soft is coral #FF8A6B (never red)', () {
      expect(QalamColors.warnSoft, const Color(0xFFFF8A6B));
    });
  });

  group('QalamTheme ThemeExtension exposes brand tokens (D-01)', () {
    test('exposes reward, warnSoft, and the sticker buttonShadow', () {
      const QalamTheme ext = QalamTheme.light;
      expect(ext.reward, const Color(0xFFF2A60C));
      expect(ext.warnSoft, const Color(0xFFFF8A6B));
      expect(ext.buttonShadow, isA<List<BoxShadow>>());
    });

    test('is registered on the app ThemeData via extension<QalamTheme>()', () {
      final ThemeData theme = qalamTheme;
      expect(theme.extension<QalamTheme>(), isNotNull);
    });
  });
}
