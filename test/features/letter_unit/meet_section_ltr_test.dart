// MeetSection English-copy LTR pin — Plan 17-08 Task 2 (UAT F1).
//
// UAT F1 (docs/testing/UAT-FULL-2026-07-01.md): the baa Meet card's English
// helper lines render RTL under the app's right-to-left Directionality, so the
// trailing period jumps to the left (".On its own…"). The fix forces
// `textDirection: TextDirection.ltr` on the ENGLISH guidance Text only — the
// Arabic glyph beside it (rendered through ArabicText) stays RTL, untouched.
//
// This test pins the fix: pumped under an EXPLICIT RTL Directionality ancestor,
// the English explain line's resolved textDirection must be LTR. A grep cannot
// see a resolved TextDirection — this widget test is the durable regression pin.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/features/letter_unit/sections/meet_section.dart';
import 'package:qalam/providers/audio_providers.dart';

import 'section_test_support.dart';

/// A no-op audio player so the offline `_play` seam has an override to read.
class _SilentAudioPlayer implements LetterAudioPlayer {
  @override
  Future<void> playLetter(String assetPath) async {}
}

Future<void> _pumpMeetRtl(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 800); // tablet landscape
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [audioPlayerProvider.overrideWithValue(_SilentAudioPlayer())],
      child: MaterialApp(
        // The app is RTL: wrap the whole section in an explicit RTL ancestor so
        // any un-directed Text would resolve RTL (the F1 failure mode).
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: MeetSection(
              exercise: meetExercise(),
              letter: baaLetter(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // The isolated form's explain copy (MeetSectionStrings.isolatedExplain) — the
  // exact "On its own …" line UAT F1 named.
  const explain = 'On its own — the full bowl with its tail.';

  testWidgets(
      'F1: the English helper line resolves LTR under an RTL Directionality ancestor',
      (tester) async {
    await _pumpMeetRtl(tester);

    final explainFinder = find.text(explain);
    expect(explainFinder, findsOneWidget);

    // Sanity leg: the AMBIENT direction at the Text is genuinely RTL (so this is
    // a real test of the fix, not an LTR-by-default false pass).
    expect(
      Directionality.of(tester.element(explainFinder)),
      TextDirection.rtl,
      reason: 'the helper line must sit under an RTL ancestor for F1 to bite',
    );

    // The fix: the English helper Text carries an explicit LTR direction, so its
    // trailing period stays on the right regardless of the RTL ancestor.
    final explainText = tester.widget<Text>(explainFinder);
    expect(explainText.textDirection, TextDirection.ltr);
  });
}
