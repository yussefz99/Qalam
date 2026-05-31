// Wave-0 validation scaffold — D-05 (mixed-direction shell) / D-10 reference.
//
// INTENTIONALLY RED at Wave 0: imports package:qalam/ screen + ArabicText
// symbols that do not yet exist. A later plan builds them and turns this green.
// Do NOT add lib/ stubs here.
//
// Proof: the app chrome defaults to LTR (no global Directionality.rtl —
// Pitfall 1), and TextDirection.rtl appears ONLY inside an ArabicText island.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/screens/home_screen.dart';
import 'package:qalam/widgets/arabic_text.dart';

void main() {
  testWidgets('app chrome is LTR; only the ArabicText island is RTL (D-05)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Chrome default: LTR everywhere outside an Arabic island.
    final BuildContext chromeContext = tester.element(find.byType(HomeScreen));
    expect(Directionality.of(chromeContext), TextDirection.ltr);

    // Render an Arabic island and assert it — and only it — is RTL.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ArabicText('بَاء')),
      ),
    );
    final BuildContext arabicContext = tester.element(find.byType(Text));
    expect(Directionality.of(arabicContext), TextDirection.rtl);
  });
}
