// WordsSection (Section 4 — Words with Baa) behavior — Plan 07-06 Task 1.
//
// Section 4 shows three baa vocab cards (door/duck/milk) from words.json. Each
// card plays its word clip OFFLINE (captured via a fake LetterAudioPlayer) and,
// when tapped, opens a trace surface (the engine ExerciseScaffold fed the word's
// trace config). These tests prove the plan's <behavior>:
//   • three vocab cards render;
//   • a card's Play calls the audio player with the word's audio id (offline);
//   • tapping a card opens its trace surface (a WriteSurface).

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/features/letter_unit/sections/words_section.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/word.dart';
import 'package:qalam/providers/audio_providers.dart';

import 'section_test_support.dart';

class _CapturingAudioPlayer implements LetterAudioPlayer {
  final List<String> played = <String>[];
  @override
  Future<void> playLetter(String assetPath) async {
    played.add(assetPath);
  }
}

/// The three baa-family vocab words (door/duck/milk), mirroring words.json.
List<WordTrace> _wordTraces() => [
      WordTrace(
        word: const Word(
          id: 'baab',
          text: 'باب',
          audio: 'word.baab',
          image: 'img.door',
          gloss: {'en': 'door'},
          letters: ['baa', 'alif', 'baa'],
        ),
        exercise: joinExercise(),
      ),
      WordTrace(
        word: const Word(
          id: 'batta',
          text: 'بطة',
          audio: 'word.batta',
          image: 'img.duck',
          gloss: {'en': 'duck'},
          letters: ['baa', 'taa_marbuta'],
        ),
        exercise: joinExercise(),
      ),
      WordTrace(
        word: const Word(
          id: 'haliib',
          text: 'حليب',
          audio: 'word.haliib',
          image: 'img.milk',
          gloss: {'en': 'milk'},
          letters: ['haa', 'laam', 'yaa', 'baa'],
        ),
        exercise: joinExercise(),
      ),
    ];

Future<_CapturingAudioPlayer> _pump(
  WidgetTester tester, {
  VoidCallback? onAdvance,
}) async {
  final audio = _CapturingAudioPlayer();
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [audioPlayerProvider.overrideWithValue(audio)],
      child: MaterialApp(
        home: Scaffold(
          body: WordsSection(
            words: _wordTraces(),
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
  testWidgets('Test 1: renders the three baa vocab cards (door/duck/milk)',
      (tester) async {
    await _pump(tester);

    expect(find.byType(WordCard), findsNWidgets(3));
    expect(find.byKey(const ValueKey('wordCard:baab')), findsOneWidget);
    expect(find.byKey(const ValueKey('wordCard:batta')), findsOneWidget);
    expect(find.byKey(const ValueKey('wordCard:haliib')), findsOneWidget);
    // The card grid is a teach-grid: nothing graded yet, no trace surface.
    expect(find.byType(WriteSurface), findsNothing);
  });

  testWidgets("Test 2: a card's Play plays the word's audio id offline",
      (tester) async {
    final audio = await _pump(tester);
    expect(audio.played, isEmpty);

    await tester.tap(find.byKey(const ValueKey('wordPlay:batta')));
    await tester.pump();

    // The OFFLINE player was invoked with the duck word's audio id.
    expect(audio.played, contains('word.batta'));
  });

  testWidgets('Test 3: tapping a card opens its trace surface',
      (tester) async {
    await _pump(tester);

    // No trace surface in the grid stage.
    expect(find.byType(WriteSurface), findsNothing);

    await tester.tap(find.byKey(const ValueKey('wordCard:baab')));
    await tester.pumpAndSettle();

    // The trace stage shows the config-driven WriteSurface for that word.
    expect(find.byKey(const ValueKey('wordTrace:baab')), findsOneWidget);
    expect(find.byType(WriteSurface), findsOneWidget);
  });

  testWidgets('Test 4: marking a word traced flags it + returns to the grid',
      (tester) async {
    await _pump(tester);

    final state = tester.state<WordsSectionState>(find.byType(WordsSection));
    state.debugMarkWordTraced(0);
    await tester.pumpAndSettle();

    // Back on the grid with three cards; one now reads "Traced".
    expect(find.byType(WordCard), findsNWidgets(3));
    expect(find.text('Traced'), findsOneWidget);
  });
}
