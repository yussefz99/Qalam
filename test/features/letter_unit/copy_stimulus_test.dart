// Phase 19-01 (Wave 0) — QP-03 RED contract: writeWord.copy child-controlled
// hide + peek.
//
// INTENTIONALLY RED until 19-03: imports the not-yet-built
// `lib/features/letter_unit/widgets/copy_stimulus.dart`, so this file fails to
// COMPILE today (RED-by-missing-symbol). 19-03 creates the `CopyStimulus`
// StatefulWidget and turns it green with ZERO test edits.
//
// The contract (UI-SPEC §4 / D-05): the word shows LARGE (40px Arabic) with an
// "I'm Ready" button; the child taps "I'm Ready" (or starts the first stroke) to
// HIDE it; a "Peek" button re-reveals it; a "Hide" toggle returns to hidden.
// NOTHING vanishes on a timer — every reveal/hide is child-controlled, so recall
// stays honest. Three states: revealed · hidden · peeking.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/features/letter_unit/widgets/copy_stimulus.dart';
import 'package:qalam/widgets/arabic_text.dart';

const _word = 'باب'; // the copy word (alif + baa only — door)

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pump();
}

/// The copy word as it renders through the Arabic RTL island.
Finder _wordFinder() =>
    find.byWidgetPredicate((w) => w is ArabicText && w.text == _word);

void main() {
  testWidgets('revealed: shows the word + "I\'m Ready" (D-05)', (tester) async {
    await _pump(tester, const CopyStimulus(word: _word));

    expect(_wordFinder(), findsOneWidget,
        reason: 'the word shows large in the revealed state');
    expect(find.text("I'm Ready"), findsOneWidget,
        reason: 'the child taps "I\'m Ready" to hide the word');
  });

  testWidgets('tapping "I\'m Ready" hides the word (revealed → hidden)',
      (tester) async {
    await _pump(tester, const CopyStimulus(word: _word));

    await tester.tap(find.text("I'm Ready"));
    await tester.pumpAndSettle();

    expect(_wordFinder(), findsNothing,
        reason: 'the word hides on the child action, not on a timer');
    expect(find.text('Peek'), findsOneWidget,
        reason: 'a Peek affordance appears while hidden');
  });

  testWidgets('Peek re-reveals, Hide returns to hidden (hidden → peeking → hidden)',
      (tester) async {
    await _pump(tester, const CopyStimulus(word: _word));

    // Hide first.
    await tester.tap(find.text("I'm Ready"));
    await tester.pumpAndSettle();

    // Peek re-reveals the word (peeking).
    await tester.tap(find.text('Peek'));
    await tester.pumpAndSettle();
    expect(_wordFinder(), findsOneWidget,
        reason: 'Peek brings the word back (a deliberate, child-initiated assist)');

    // Hide toggles back to hidden.
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();
    expect(_wordFinder(), findsNothing,
        reason: 'Hide returns the word to the hidden state');
  });

  testWidgets('NOTHING hides on a timer — a long pump keeps the revealed word (D-05)',
      (tester) async {
    await _pump(tester, const CopyStimulus(word: _word));

    // Only time passes — no tap. The word must NOT auto-fade/auto-hide (this is
    // the whole D-05 change: replace the static timed dim with child control).
    await tester.pump(const Duration(seconds: 5));

    expect(_wordFinder(), findsOneWidget,
        reason: 'no timer-driven hide — the reveal is child-controlled (D-05)');
    expect(find.text("I'm Ready"), findsOneWidget);
  });
}
