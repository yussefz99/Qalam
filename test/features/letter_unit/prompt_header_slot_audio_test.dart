// Phase 19-01 (Wave 0) — QP-04/QP-05 RED contract: the big RTL slot box + the
// large replayable audio card. Extends the existing PromptHeader coverage
// (prompt_header_test.dart) with the new stimulus-zone contracts.
//
// INTENTIONALLY RED until 19-03. Today `_GapWord`/`_GapLetter` are small inline
// chips with no `Key('gapSlot')`, and an AudioPart renders a small teal "Play"
// button with no `Key('audioCard')`, no "Listen" label, and no auto-play. This
// test names the D-06/D-07 contract 19-03 must satisfy with ZERO test edits:
//   • completeWord/fillBlank render a big highlighted slot box (Key('gapSlot')) at
//     the gap; the literal `__blank__`/`_letter_` marker never reaches the screen,
//   • a listen-and-write question renders a large audio card (Key('audioCard'),
//     min-height ≥96, a "Listen" label) that auto-plays once on mount and replays
//     on tap, and still renders when the clip id is unknown (silent-degrade).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/features/letter_unit/widgets/prompt_header.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/widgets/arabic_text.dart';

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

void main() {
  group('gap slot box (QP-04 / D-06)', () {
    testWidgets(
        'completeWord __blank__ renders a big slot box; the literal marker never '
        'leaks', (tester) async {
      const part = TextPart(
        text: 'البابُ __blank__',
        gaps: [Gap(kind: 'word', index: 1)],
      );
      await _pump(tester, const PromptHeader(parts: [part]));

      // The word renders at full stimulus size through the Arabic RTL island.
      expect(
        find.byWidgetPredicate((w) => w is ArabicText && w.text == 'البابُ'),
        findsOneWidget,
      );
      // A big highlighted slot box marks the gap (RED until 19-03 keys it).
      expect(find.byKey(const Key('gapSlot')), findsOneWidget,
          reason: 'the gap is a big highlighted RTL slot box (D-06)');
      // The literal marker NEVER reaches the screen (Pitfall 6).
      expect(find.text('__blank__'), findsNothing,
          reason: 'the __blank__ marker stays filtered out of the header');
    });

    testWidgets(
        'fillBlank _letter_ renders a slot box; the literal marker never leaks',
        (tester) async {
      const part = TextPart(
        text: 'كبير _letter_',
        gaps: [Gap(kind: 'letter', index: 1)],
      );
      await _pump(tester, const PromptHeader(parts: [part]));

      expect(find.byKey(const Key('gapSlot')), findsOneWidget,
          reason: 'the missing letter is a highlighted slot box (D-06)');
      expect(find.text('_letter_'), findsNothing,
          reason: 'the _letter_ marker stays filtered out of the header');
    });
  });

  group('audio stimulus card (QP-05 / D-07)', () {
    testWidgets(
        'a listen-and-write question renders a large audio card that auto-plays '
        'once on mount', (tester) async {
      final calls = <String>[];
      await _pump(
        tester,
        PromptHeader(
          parts: const [SayPart('Listen and write.'), AudioPart('snd.baab')],
          onAudioTap: (id) => calls.add(id),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('audioCard'));
      expect(card, findsOneWidget,
          reason: 'listen-and-write shows a large audio stimulus card (D-07)');
      expect(find.descendant(of: card, matching: find.text('Listen')),
          findsOneWidget,
          reason: 'the card carries a "Listen" label');
      // Hero target — min-height ≥ 96 (--target-large), distinct from the small
      // teal play button it replaces.
      expect(tester.getSize(card).height, greaterThanOrEqualTo(96.0),
          reason: 'the audio card fills the stimulus zone (min-height 96)');
      // Auto-plays ONCE on mount (mirrors the scaffold auto-speak).
      expect(calls, hasLength(1),
          reason: 'the clip auto-plays exactly once on mount');
    });

    testWidgets('tapping the audio card replays the clip', (tester) async {
      final calls = <String>[];
      await _pump(
        tester,
        PromptHeader(
          parts: const [SayPart('Listen and write.'), AudioPart('snd.baab')],
          onAudioTap: (id) => calls.add(id),
        ),
      );
      await tester.pumpAndSettle();
      calls.clear(); // ignore the mount auto-play

      await tester.tap(find.byKey(const Key('audioCard')));
      await tester.pump();

      expect(calls, contains('snd.baab'),
          reason: 'tapping the card replays the clip any time');
    });

    testWidgets('the audio card still renders with an unknown clip id '
        '(silent-degrade, D-07/D-11)', (tester) async {
      await _pump(
        tester,
        const PromptHeader(
          parts: [SayPart('Listen and write.'), AudioPart('snd.nope')],
        ),
      );
      await tester.pumpAndSettle();

      // No clip / no handler → the card still renders; no error surface, no
      // broken-audio icon (mirrors the _ImagePart errorBuilder posture).
      expect(find.byKey(const Key('audioCard')), findsOneWidget,
          reason: 'a missing clip never removes the card (silent-degrade)');
    });
  });
}
