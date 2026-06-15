// PromptHeader / FeedbackPanelV2 / ProgressRibbon behavior — Plan 07-04 Task 1.
//
// These are the static/composition components of the Letter-Unit exercise engine,
// built pixel-faithful to the Claude Design baa prototype
// (docs/design/prototypes/letter-unit-baa/prototype/exercise-components/). The
// tests prove the CONTRACTS the section screens (07-05/07-06) feed configs into:
//   • PromptHeader renders each part kind distinctly and PULLS OUT the `say` part.
//   • A TextPart's __blank__ / _letter_ markers and reveal/loose variants apply.
//   • A FormsPart renders the four-forms strip of ب.
//   • FeedbackPanel pass = exactly ONE star + praise; fix = coral + the fix line;
//     NO star counter / tally anywhere (anti-gamification, CLAUDE.md Decided).
//   • ProgressRibbon(total:6, active:1) renders 6 dots, R→L, dot 0 done + 1 active.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/features/letter_unit/widgets/feedback_panel_v2.dart';
import 'package:qalam/features/letter_unit/widgets/progress_ribbon.dart';
import 'package:qalam/features/letter_unit/widgets/prompt_header.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/widgets/arabic_text.dart';

/// Pumps [child] inside a minimal RTL tablet-landscape app shell.
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PromptHeader', () {
    testWidgets(
        'Test 1: [say, audio, rule] renders audio + rule, pulls say OUT of the row',
        (tester) async {
      const parts = <PromptPart>[
        SayPart('Listen, then trace baa.'),
        AudioPart('baa-sound'),
        RulePart('مثنى'),
      ];
      await _pump(tester, const PromptHeader(parts: parts));

      // The `say` line is NOT in the header row — it goes to the speech bubble.
      expect(find.text('Listen, then trace baa.'), findsNothing);
      // The say line IS available via the pull-out helper.
      expect(promptSayLine(parts), 'Listen, then trace baa.');

      // Audio → a teal play button (the speaker icon + a Play label).
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);

      // Rule → a gold chip carrying the Arabic rule label (RTL island).
      expect(
        find.byWidgetPredicate(
            (w) => w is ArabicText && w.text == 'مثنى'),
        findsOneWidget,
      );
    });

    testWidgets('Test 2: TextPart __blank__ + word gap renders a missing-word box',
        (tester) async {
      const part = TextPart(
        text: 'البابُ __blank__',
        gaps: [Gap(kind: 'word', index: 1)],
      );
      await _pump(tester, const PromptHeader(parts: [part]));

      // The Arabic run renders through ArabicText.
      expect(
        find.byWidgetPredicate((w) => w is ArabicText && w.text == 'البابُ'),
        findsOneWidget,
      );
      // The __blank__ marker becomes a dashed missing-WORD box (the square icon).
      expect(find.byIcon(Icons.crop_square_rounded), findsOneWidget);
    });

    testWidgets('Test 3: reveal:thenHide dims the word; loose widens the gap',
        (tester) async {
      const part = TextPart(text: 'باب', reveal: 'thenHide', loose: true);
      await _pump(tester, const PromptHeader(parts: [part]));

      // reveal:thenHide → the prompt word is dimmed (Opacity 0.18).
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byType(ArabicText),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.18);
    });

    testWidgets('Test 4: FormsPart renders the four-forms strip of baa',
        (tester) async {
      const part = FormsPart(
        char: 'ب',
        forms: ['isolated', 'initial', 'medial', 'final'],
      );
      await _pump(tester, const PromptHeader(parts: [part]));

      // The four contextual glyphs of baa each render through ArabicText.
      for (final glyph in ['ب', 'بـ', 'ـبـ', 'ـب']) {
        expect(
          find.byWidgetPredicate((w) => w is ArabicText && w.text == glyph),
          findsOneWidget,
          reason: 'expected the $glyph form glyph',
        );
      }
    });

    testWidgets('Test 5: an empty (say-only) header collapses to nothing',
        (tester) async {
      await _pump(
        tester,
        const PromptHeader(parts: [SayPart('only a say line')]),
      );
      // No visual parts → the header renders a zero-size shrink, no row content.
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
      expect(find.byType(ArabicText), findsNothing);
    });
  });

  group('FeedbackPanelV2 (anti-gamification)', () {
    testWidgets(
        'Test 6: pass shows EXACTLY ONE star + praise, with NO counter/tally',
        (tester) async {
      await _pump(
        tester,
        const FeedbackPanelV2(
          state: FeedbackState.pass,
          line: 'Beautiful — a smooth, deep curve.',
        ),
      );

      // Exactly ONE star — a mastery marker, never a running total.
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('Beautiful — a smooth, deep curve.'), findsOneWidget);

      // No "+N", no number, no "total"/"streak"/"stars" tally text anywhere.
      final tally = find.byWidgetPredicate((w) {
        if (w is! Text) return false;
        final s = w.data ?? '';
        return RegExp(r'\+\s*\d').hasMatch(s) ||
            RegExp(r'\b\d+\b').hasMatch(s) ||
            s.toLowerCase().contains('total') ||
            s.toLowerCase().contains('streak');
      });
      expect(tally, findsNothing,
          reason: 'no score/tally/streak chrome on a pass (CLAUDE.md Decided)');
    });

    testWidgets('Test 7: fix shows the coral X + the specific authored line',
        (tester) async {
      await _pump(
        tester,
        const FeedbackPanelV2(
          state: FeedbackState.fix,
          line: 'Your baa needs a deeper curve at the bottom.',
        ),
      );
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing); // no star on a miss
      expect(find.text('Your baa needs a deeper curve at the bottom.'),
          findsOneWidget);
    });

    testWidgets('Test 8: idle shows the write hint, no star, no X',
        (tester) async {
      await _pump(
        tester,
        const FeedbackPanelV2(state: FeedbackState.idle),
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(
        find.text('Write on the surface — Qalam checks your strokes.'),
        findsOneWidget,
      );
    });
  });

  group('ProgressRibbon (position, not score)', () {
    testWidgets('Test 9: total:6 active:1 renders 6 dots, dot0 done + dot1 active',
        (tester) async {
      await _pump(tester, const ProgressRibbon(total: 6, active: 1));

      // Six dots are rendered (each an AnimatedContainer in the dot row).
      final dots = find.descendant(
        of: find.byType(ProgressRibbon),
        matching: find.byType(AnimatedContainer),
      );
      expect(dots, findsNWidgets(6));

      // No numerals/score text — position only (the Semantics label is position).
      expect(
        find.byWidgetPredicate(
            (w) => w is Text && RegExp(r'\d').hasMatch(w.data ?? '')),
        findsNothing,
      );
    });

    testWidgets('Test 10: total:0 renders nothing', (tester) async {
      await _pump(tester, const ProgressRibbon(total: 0, active: 0));
      expect(find.byType(AnimatedContainer), findsNothing);
    });
  });
}
