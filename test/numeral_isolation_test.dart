// Wave-0 validation scaffold — D-06 (Western numerals, LTR-isolated in RTL).
//
// INTENTIONALLY RED at Wave 0: imports package:qalam/widgets/arabic_text.dart,
// which does not yet exist. A later plan builds ArabicText (with the LRI/PDI
// digit-isolation behavior) and turns this green. Do NOT add a lib/ stub here.
//
// Proof: ArabicText rendering a mixed Arabic+digit string emits the literal
// Western digits U+0030–U+0039 wrapped in LRI (U+2066) … PDI (U+2069) isolates,
// and NEVER substitutes Eastern-Arabic digits U+0660–U+0669 (٠..٩).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/widgets/arabic_text.dart';

void main() {
  // Eastern-Arabic digits this app must NEVER render (D-06 forbids them).
  // U+0660 = ٠ (zero) … U+0669 = ٩ (nine).
  const int easternZero = 0x0660; // ٠
  const int easternNine = 0x0669; // ٩
  const String easternDigits = '٠١٢٣٤٥٦٧٨٩';

  // Unicode directional isolates that must wrap a Western digit run inside RTL.
  const String lri = '\u{2066}'; // LEFT-TO-RIGHT ISOLATE (LRI)
  const String pdi = '\u{2069}'; // POP DIRECTIONAL ISOLATE (PDI)

  testWidgets('digits render as Western 0-9, LRI/PDI-isolated, never Eastern (D-06)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ArabicText('العمر 7 سنوات')),
      ),
    );

    final Text rendered = tester.widget<Text>(find.byType(Text));
    final String shown = rendered.data ?? '';

    // The literal Western digit survives.
    expect(shown.contains('7'), isTrue);

    // It is wrapped in an LTR isolate (LRI … PDI).
    expect(shown.contains(lri), isTrue);
    expect(shown.contains(pdi), isTrue);

    // No Eastern-Arabic digit codepoint (U+0660–U+0669) is ever present.
    for (final int cp in shown.runes) {
      expect(cp >= easternZero && cp <= easternNine, isFalse,
          reason: 'Eastern-Arabic digit ${String.fromCharCode(cp)} leaked in');
    }
    expect(easternDigits.runes.any(shown.runes.contains), isFalse);
  });
}
