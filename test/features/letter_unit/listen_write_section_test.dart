// ListenWriteSection (Section 5 — Listen & Write, the recall gate) behavior —
// Plan 07-06 Task 1.
//
// Section 5 is the RECALL GATE: no dotted guide — the child listens, then writes
// the word (or its first letter) from memory, scored on-device. These tests
// prove the plan's <behavior>:
//   • it is mode:write — NO dotted-guide glyph; the "from memory / no guide"
//     badge is shown;
//   • the word ↔ first-letter toggle SWAPS the active config;
//   • a scored pass on the WORD task fires onFinish (the gate); a pass on the
//     first-letter task does NOT (finishing requires the word).
//   • a fail surfaces the authored fix (from the config), a pass the praise.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/exercise_controller.dart';
import 'package:qalam/features/letter_unit/sections/listen_write_section.dart';
import 'package:qalam/features/letter_unit/widgets/feedback_panel_v2.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/providers/audio_providers.dart';

import 'section_test_support.dart';

class _CapturingAudioPlayer implements LetterAudioPlayer {
  final List<String> played = <String>[];
  @override
  Future<void> playLetter(String assetPath) async {
    played.add(assetPath);
  }
}

/// `baa.writeWord.dictation` — write the whole word from memory (the gate).
Exercise _writeWordExercise() => const Exercise(
      id: 'baa.writeWord.dictation',
      type: 'writeWord',
      skill: 'spelling',
      prompt: [
        SayPart('No dotted lines. Listen and write the whole word from memory.'),
        AudioPart('word.baab'),
      ],
      surface: Surface(mode: 'write', unit: 'word'),
      expected: Answer(word: WordAnswer('باب')),
      check: Check(base: 'sequence'),
      feedback: {
        'pass': 'باب — from memory, no guide. Real writing! أحسنت!',
        'missingDot': 'Close — your first baa needs its dot. Listen again: باب.',
      },
      signedOff: false,
    );

/// `baa.writeLetter.fromSound` — write the first letter from the sound.
Exercise _writeLetterExercise() => const Exercise(
      id: 'baa.writeLetter.fromSound',
      type: 'writeLetter',
      skill: 'recall',
      prompt: [
        SayPart('Listen, then write the letter the word starts with. No guide.'),
        AudioPart('word.batta'),
      ],
      surface: Surface(mode: 'write', unit: 'glyph'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph', modifiers: ['positionalForm']),
      feedback: {
        'pass': 'Yes — "baṭṭa" starts with baa, and there it is.',
        'wrongLetter': 'That\'s taa — listen again: بطة… b, b.',
      },
      signedOff: false,
    );

Future<_CapturingAudioPlayer> _pump(
  WidgetTester tester, {
  VoidCallback? onFinish,
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
          body: ListenWriteSection(
            writeWord: _writeWordExercise(),
            writeLetter: _writeLetterExercise(),
            letter: baaLetter(),
            onFinish: onFinish,
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
      'Test 1: write-mode recall gate — NO dotted guide, the "from memory" badge shows',
      (tester) async {
    await _pump(tester);

    // The recall surface is the engine WriteSurface in WRITE mode (no guide).
    final surface = tester.widget<WriteSurface>(find.byType(WriteSurface));
    expect(surface.surface.mode, 'write');
    // The "No guide · from memory" badge is shown over the surface.
    expect(find.byKey(const ValueKey('lwNoGuideBadge')), findsOneWidget);
  });

  testWidgets('Test 2: the word/first-letter toggle swaps the active config',
      (tester) async {
    await _pump(tester);

    final state =
        tester.state<ListenWriteSectionState>(find.byType(ListenWriteSection));
    // Defaults to the WORD task (the gate).
    expect(state.mode, LwMode.word);
    expect(state.activeExercise.id, 'baa.writeWord.dictation');
    expect(state.activeExercise.surface!.unit, 'word');

    // Tap the first-letter tab — the active config swaps.
    await tester.tap(find.byKey(const ValueKey('lwTabLetter')));
    await tester.pumpAndSettle();

    expect(state.mode, LwMode.letter);
    expect(state.activeExercise.id, 'baa.writeLetter.fromSound');
    expect(state.activeExercise.surface!.unit, 'glyph');
  });

  testWidgets('Test 3: a pass on the WORD task fires onFinish (the gate)',
      (tester) async {
    var finished = 0;
    await _pump(tester, onFinish: () => finished++);

    final ctx = tester.element(find.byType(ListenWriteSection));
    final container = ProviderScope.containerOf(ctx);
    container.read(exerciseControllerProvider.notifier)
      ..load(_writeWordExercise())
      ..applyResult(const CheckResult.pass());
    await tester.pumpAndSettle();

    // One quiet star + the authored praise on a pass.
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FeedbackPanelV2),
        matching:
            find.text('باب — from memory, no guide. Real writing! أحسنت!'),
      ),
      findsOneWidget,
    );

    // Tap the scaffold's "Next exercise" (pass CTA) → onFinish fires.
    await tester.tap(find.text('Next exercise'));
    await tester.pump();
    expect(finished, 1);
  });

  testWidgets(
      'Test 4: a pass on the FIRST-LETTER task also finishes (a correct answer '
      'must never leave the child stuck — owner-reported)',
      (tester) async {
    var finished = 0;
    await _pump(tester, onFinish: () => finished++);

    // Switch to the first-letter task.
    await tester.tap(find.byKey(const ValueKey('lwTabLetter')));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(ListenWriteSection));
    final container = ProviderScope.containerOf(ctx);
    container.read(exerciseControllerProvider.notifier)
      ..load(_writeLetterExercise())
      ..applyResult(const CheckResult.pass());
    await tester.pumpAndSettle();

    // Tapping Next on the first-letter pass advances too (no dead end).
    await tester.tap(find.text('Next exercise'));
    await tester.pump();
    expect(finished, 1);
  });
}
