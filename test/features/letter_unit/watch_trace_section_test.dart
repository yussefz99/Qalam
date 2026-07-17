// WatchTraceSection (Section 2 — Watch & Trace) behavior — Plan 07-05 Task 2.
//
// Section 2 first PLAYS the stroke-order demo (StrokeOrderAnimation) with
// "Watch again" / "I'll try", then lets the child TRACE the isolated baa over
// the dotted guide (WriteSurface mode:trace, guideForm:isolated, demo). A scored
// pass shows one star + the authored praise; a fail shows the authored
// "shallowBowl" fix (never a generic message). The Listen side card's Play plays
// the baa sound offline.
//
// Each section renders by feeding the `baa.traceLetter.isolated` Exercise config
// into the engine components — no bespoke grading UI.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/exercise_controller.dart';
import 'package:qalam/features/letter_unit/sections/watch_trace_section.dart';
import 'package:qalam/features/letter_unit/widgets/feedback_panel_v2.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/features/practice/widgets/stroke_order_animation.dart';
import 'package:qalam/providers/audio_providers.dart';
import 'package:qalam/tutor/tutor_providers.dart';

import 'section_test_support.dart';

class _CapturingAudioPlayer implements LetterAudioPlayer {
  final List<String> played = <String>[];
  @override
  Future<void> playLetter(String assetPath) async {
    played.add(assetPath);
  }
}

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
          body: WatchTraceSection(
            exercise: traceIsolatedExercise(),
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
  testWidgets('Test 1: the Watch phase shows the stroke-order demo + I\'ll try',
      (tester) async {
    await _pump(tester);

    // The Watch phase plays the existing StrokeOrderAnimation demo.
    expect(find.byType(StrokeOrderAnimation), findsOneWidget);
    // No trace surface yet (we are still watching).
    expect(find.byType(WriteSurface), findsNothing);
    // The "I'll try" CTA advances to the Trace phase.
    expect(find.text("I'll try"), findsOneWidget);
  });

  testWidgets('Test 2: I\'ll try advances to the Trace phase with a WriteSurface',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text("I'll try"));
    await tester.pumpAndSettle();

    // The Trace phase shows the config-driven trace surface.
    expect(find.byType(WriteSurface), findsOneWidget);
  });

  testWidgets('Test 3: a fail surfaces the authored shallowBowl line, not generic',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text("I'll try"));
    await tester.pumpAndSettle();

    // Drive a fail through the controller (as the WriteSurface would on a miss).
    final ctx = tester.element(find.byType(WatchTraceSection));
    final container = ProviderScope.containerOf(ctx);
    container.read(exerciseControllerProvider.notifier)
      ..load(traceIsolatedExercise())
      ..applyResult(const CheckResult.fail('shallowBowl'));
    // Phase 17.2 (owner directive): baa's feedback WORDS now flow through the
    // tutor channel — the RemoteAgentBrain's offline floor delivers the authored
    // line here (the scaffold no longer renders `state.line` on the baa path).
    // Set it as that floor would, then assert the panel renders it.
    container.read(tutorLineProvider.notifier).set(
        'A little shallow — give the bowl a deeper curve. Try again, slower.');
    await tester.pumpAndSettle();

    // The SPECIFIC authored fix (from EXERCISE-CONFIGS.json), in the panel.
    expect(
      find.descendant(
        of: find.byType(FeedbackPanelV2),
        matching: find.text(
            'A little shallow — give the bowl a deeper curve. Try again, slower.'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('Test 4: a pass shows one star + the authored praise',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text("I'll try"));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(WatchTraceSection));
    final container = ProviderScope.containerOf(ctx);
    container.read(exerciseControllerProvider.notifier)
      ..load(traceIsolatedExercise())
      ..applyResult(const CheckResult.pass());
    // Phase 17.2 (owner directive): baa's praise WORDS flow through the tutor
    // channel now (the offline floor delivers the authored line here); set it as
    // that floor would, then assert the panel renders it beside the star.
    container.read(tutorLineProvider.notifier)
        .set('Beautiful — a deep, smooth bowl. أحسنت!');
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FeedbackPanelV2),
        matching: find.text('Beautiful — a deep, smooth bowl. أحسنت!'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Test 5: the trace PromptHeader hero audio card auto-plays the baa sound '
      'on mount and replays on tap (D-07)', (tester) async {
    final audio = await _pump(tester);
    await tester.tap(find.text("I'll try"));
    await tester.pumpAndSettle();

    // 19-03 (D-07): the lone audio prompt is the hero "sound to write" card — it
    // AUTO-PLAYS the clip once on entering the trace phase (reconciled from the
    // Phase-07 empty-until-tap assertion; auto-play is the locked D-07 behavior).
    expect(audio.played, contains('snd.baa'),
        reason: 'the hero audio card auto-plays the clip once on mount');
    final playedOnMount = audio.played.length;

    // Tapping the 'Listen' card replays the clip any time.
    await tester.tap(find.text('Listen'));
    await tester.pump();
    expect(audio.played.length, greaterThan(playedOnMount),
        reason: 'tapping the hero audio card replays the clip');
  });
}
