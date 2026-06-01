// Wave-1 copy contract for the six demo screens (DP-04, DP-05, DP-06).
//
// These tests pin the tutor's WARM, SPECIFIC voice (named fixes, never a bare
// "Oops, try again") and the anti-gamification rule (no streak/badge/weekly/
// "+N" hype). The strings are sourced VERBATIM from the 03-UI-SPEC Copywriting
// Contract for alif and from letters.json alif commonMistakes[].feedback.
//
// AppLocalizations is gen-l10n output (regenerated from app_en.arb on build),
// loaded here via the en delegate exactly the way the app loads it.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/l10n/app_localizations.dart';

Future<AppLocalizations> _loadEn() {
  // AppLocalizations.delegate.load is synchronous-ish (SynchronousFuture) for
  // the bundled locale; await resolves it for the test.
  return AppLocalizations.delegate.load(const Locale('en'));
}

void main() {
  group('demo copy — screen labels & headings (Test 1)', () {
    test('Home greeting + Today\'s Lesson + Watch/Trace eyebrows & headings',
        () async {
      final AppLocalizations l = await _loadEn();

      // Home greeting uses a STATIC placeholder name (no profile system — Phase 5).
      expect(l.demoHomeGreeting, contains('Layla'));

      // "Today's Lesson" eyebrow + title (the alif lesson card).
      expect(l.demoLessonEyebrow, isNotEmpty);
      expect(l.demoLessonTitle, contains('Alif'));

      // Watch / Trace eyebrows (Label scale, the kit's dotted-caption voice).
      expect(l.demoWatchEyebrow, 'WATCH · STROKE ORDER');
      expect(l.demoTraceEyebrow, 'YOUR TURN · TRACE');

      // Watch / Trace headings (the mascot speaks: "Watch me write baa.").
      // The demo loop is BAA end-to-end — coherent with the rebuilt Home and
      // every walkthrough mockup (0X-*).
      expect(l.demoWatchHeading.toLowerCase(), contains('baa'));
      expect(l.demoWatchHeading.toLowerCase(), contains('watch'));
      expect(l.demoTraceHeading.toLowerCase(), contains('baa'));
      expect(l.demoTraceHeading.toLowerCase(), contains('trace'));

      // Stroke progress — Western numerals only (the demo baa is one stroke).
      expect(l.demoTraceProgress, contains('1'));
    });
  });

  group('demo copy — buttons & celebration (Test 2)', () {
    test('Title-Case CTAs incl. demoTraceSubmit, + celebration heading & praise',
        () async {
      final AppLocalizations l = await _loadEn();

      // CTAs in Title Case.
      expect(l.demoStartTracing, 'Start Tracing');
      // The named Trace submit / stylus-up CTA — plan 04 references it BY NAME.
      expect(l.demoTraceSubmit, isNotEmpty);
      expect(l.demoTraceSubmit, contains('Check My Work'));
      expect(l.demoTryAgain, 'Try Again');
      expect(l.demoBackHome, 'Back Home');

      // Celebration: English heading + the Arabic praise island.
      expect(l.demoCelebrationHeading, 'You learned the letter baa.');
      expect(l.demoCelebrationPraiseAr, 'أحسنت');
    });
  });

  group('demo copy — named fixes in the tutor voice (Test 3)', () {
    test('miss names the exact fix; pass praise is specific; never "Oops"',
        () async {
      final AppLocalizations l = await _loadEn();

      // HERO miss state: a SPECIFIC named fix in the tutor's warm voice (baa).
      expect(l.demoMissFix.toLowerCase(), contains('baa'));
      expect(l.demoMissFix.toLowerCase(), contains('curve'));
      // The pass praise is specific warm praise (e.g. "smooth, deep curve").
      expect(l.demoPassPraise.toLowerCase(), contains('deep curve'));

      // Neither is a generic chatbot bounce.
      expect(l.demoMissFix.toLowerCase(), isNot(contains('oops')));
      expect(l.demoPassPraise.toLowerCase(), isNot(contains('oops')));
    });
  });

  group('demo copy — zero gamification language (Test 4, DP-06)', () {
    test('no demo value contains streak/badge/weekly/"stars left"/"+N" hype',
        () async {
      final AppLocalizations l = await _loadEn();

      final List<String> demoValues = <String>[
        l.demoHomeGreeting,
        l.demoLessonEyebrow,
        l.demoLessonTitle,
        l.demoWatchEyebrow,
        l.demoWatchHeading,
        l.demoWatchTip,
        l.demoTraceEyebrow,
        l.demoTraceHeading,
        l.demoTraceProgress,
        l.demoStartTracing,
        l.demoTraceSubmit,
        l.demoTryAgain,
        l.demoCelebrationEyebrow,
        l.demoCelebrationHeading,
        l.demoCelebrationPraiseAr,
        l.demoBackHome,
        l.demoMissFix,
        l.demoPassPraise,
      ];

      final RegExp gamification = RegExp(
        r'streak|badge|weekly|stars left|\+\d',
        caseSensitive: false,
      );
      for (final String v in demoValues) {
        expect(
          gamification.hasMatch(v),
          isFalse,
          reason: 'gamification language found in: "$v"',
        );
      }
    });
  });
}
