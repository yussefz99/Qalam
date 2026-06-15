// MeetSection (Section 1 — Meet the letter) behavior — Plan 07-05 Task 1.
//
// MeetSection teaches baa with NOTHING to write: it feeds the
// `baa.teachCard.meet` Exercise config into the ExerciseScaffold (teachCard
// path → PromptHeader-only) and renders the prototype's `meet()` morph card as
// the scaffold's customSurface — one large contextual form + a scrub strip of
// the four MFORMS (isolated/initial/medial/final), the door image stub, and a
// "Hear" Play button wired to the offline audio player.
//
// These tests prove (the plan's <behavior>):
//   • the four contextual form glyphs render (the morph scrub strip);
//   • it is PromptHeader-only — NO WriteSurface, NO grading;
//   • tapping a Play/Hear button plays snd.baa offline (captured via a fake
//     LetterAudioPlayer overriding audioPlayerProvider);
//   • the "Start Writing" CTA fires the section-advance callback;
//   • no star counter / weekly tally / streak (anti-gamification).

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/features/letter_unit/sections/meet_section.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/providers/audio_providers.dart';

import 'section_test_support.dart';

/// A fake audio player that records every id it is asked to play, so the test
/// can assert the offline player was invoked with `snd.baa` (no real playback).
class _CapturingAudioPlayer implements LetterAudioPlayer {
  final List<String> played = <String>[];
  @override
  Future<void> playLetter(String assetPath) async {
    played.add(assetPath);
  }
}

Future<_CapturingAudioPlayer> _pumpMeet(
  WidgetTester tester, {
  VoidCallback? onAdvance,
}) async {
  final audio = _CapturingAudioPlayer();
  tester.view.physicalSize = const Size(1280, 800); // tablet landscape
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [audioPlayerProvider.overrideWithValue(audio)],
      child: MaterialApp(
        home: Scaffold(
          body: MeetSection(
            exercise: meetExercise(),
            letter: baaLetter(),
            onAdvance: onAdvance,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return audio;
}

void main() {
  testWidgets(
      'Test 1: renders the four contextual forms + the door image, PromptHeader-only',
      (tester) async {
    await _pumpMeet(tester);

    // The four contextual form glyphs of baa appear in the morph scrub strip.
    // isolated ب, initial بـ, medial ـبـ, final ـب — assert each is present
    // somewhere in the rendered Arabic text.
    expect(findArabic('ب'), findsWidgets); // isolated (also inside others)
    expect(findArabic('بـ'), findsWidgets); // initial
    expect(findArabic('ـبـ'), findsWidgets); // medial
    expect(findArabic('ـب'), findsWidgets); // final

    // The door image stub carries its imageId caption.
    expect(find.textContaining('img.door'), findsWidgets);

    // PromptHeader-only — NOTHING to write: no WriteSurface anywhere.
    expect(find.byType(WriteSurface), findsNothing);
  });

  testWidgets('Test 2: tapping Hear plays snd.baa via the offline player',
      (tester) async {
    final audio = await _pumpMeet(tester);
    expect(audio.played, isEmpty);

    // The single "Hear" affordance is the engine PromptHeader's audio button
    // (the duplicate morph-card Hear was removed — owner bug #2a).
    await tester.tap(find.text('Hear'));
    await tester.pump();

    expect(audio.played, contains('snd.baa'));
  });

  testWidgets('Test 3: the Start Writing CTA fires onAdvance', (tester) async {
    var advanced = 0;
    await _pumpMeet(tester, onAdvance: () => advanced++);

    expect(advanced, 0);
    await tester.tap(find.text('Start Writing'));
    await tester.pump();

    expect(advanced, 1);
  });

  testWidgets('Test 4: no grading + no gamification chrome', (tester) async {
    await _pumpMeet(tester);

    // No star, no fix X — a teach card grades nothing.
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
