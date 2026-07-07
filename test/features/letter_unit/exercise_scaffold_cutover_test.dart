// exercise_scaffold_cutover — the BEHAVIORAL pin for D-A (Plan 17-07 Task 2)
// EXTENDED for the 17.2 owner directive (2026-07-07): on the baa/agent path the
// AGENT's coaching line is the ONLY feedback words shown — the authored (offline)
// line NEVER renders, not first, not on brain error/timeout, and it is never
// spoken. The verdict + star still render INSTANTLY and synchronously from the
// on-device scorer (D-A untouched); only the WORDS wait for the agent.
//
// The grep-guard (stroke_image_grep_guard_test) proves the strokeImage render is
// gone from source. THIS test proves the RUNTIME contract:
//   1. the deterministic scorer OWNS pass/fail on every path — a cold, slow,
//      offline, or FAILING brain can never affect the verdict or the star;
//   2. on the baa/agent path NO authored line is ever visible (before OR after
//      the brain resolves) — the agent line is the only feedback text, shown
//      identically in the tutor bubble AND the bottom feedback bar;
//   3. a brain failure leaves the words area EMPTY with the verdict intact.
//   4. non-agent letters (alif) keep the instant authored line (unchanged).
//
// The brain is stubbed at the ONE switch point (tutorBrainFactoryProvider): a
// never-completing future, an error-completing future, and a line-answering
// future. The tts speaker is the Noop (no real synthesis in widget tests).
//
// Pure widget test: no Firebase, no network, no model (flutter_test_config.dart
// loads the Arabic fonts automatically).

import 'dart:async';

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/exercise_controller.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/feedback_panel_v2.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/providers/tts_providers.dart';
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/tutor/tutor_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_providers.dart';

// ── fixtures ──────────────────────────────────────────────────────────────────

const _passLine = 'Beautiful — a smooth, deep curve.'; // authored pass (baa)
const _fixLine = 'Your baa needs a deeper curve.'; // authored fix (baa)
const _agentLine = 'Deeper curve at the bottom — slower, you can do it.';

Letter _letter(String id) {
  const body = StrokeSpec(
    order: 1,
    label: 'boat',
    type: 'curve',
    points: [
      [0.2, 0.4],
      [0.5, 0.6],
      [0.8, 0.4],
    ],
    direction: 'rightToLeft',
  );
  const dot = StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    points: [
      [0.5, 0.75],
    ],
    direction: 'none',
  );
  return Letter(
    id: id,
    char: 'ب',
    name: const LetterName(ar: 'باء', display: 'baa'),
    introOrder: 2,
    forms: const LetterForms(
        isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
    referenceStrokes: const [body, dot],
    cleanRepsToAdvance: 1,
    commonMistakes: const [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: const {'isolated': Form(referenceStrokes: [body, dot])},
  );
}

/// The live-agent letter (baa) — its feedback words come ONLY from the brain.
Letter _baa() => _letter('baa');

/// A non-agent letter (alif) — keeps the instant authored line (unchanged path).
Letter _alif() => _letter('alif');

Exercise _graded() => const Exercise(
      id: 'baa.traceLetter',
      skill: 'formation',
      prompt: [SayPart('Trace baa.')],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {
        'pass': _passLine,
        'shallowBowl': _fixLine,
      },
      signedOff: false,
    );

/// A [TutorBrain] whose next() NEVER answers — the network hangs forever. If the
/// verdict were gated on the brain, the star/CTA would never appear.
class _NeverBrain implements TutorBrain {
  final Completer<TutorDecision> _pending = Completer<TutorDecision>();
  bool called = false;

  @override
  Future<TutorDecision> next(TutorFacts facts) {
    called = true;
    return _pending.future; // deliberately never completed
  }
}

/// A [TutorBrain] whose next() FAILS — the network errors. The catchError path
/// may clear the tutor line, but must NEVER touch the applied verdict, and must
/// NOT surface any authored line on the baa path.
class _ErrorBrain implements TutorBrain {
  bool called = false;

  @override
  Future<TutorDecision> next(TutorFacts facts) {
    called = true;
    return Future<TutorDecision>.error(StateError('brain down'));
  }
}

/// A [TutorBrain] that answers with a single coaching line — the agent path's
/// happy case. This is the ONLY feedback text that may appear on the baa path.
class _SayBrain implements TutorBrain {
  bool called = false;

  @override
  Future<TutorDecision> next(TutorFacts facts) async {
    called = true;
    return const Say(_agentLine);
  }
}

Future<void> _pumpScaffold(
  WidgetTester tester,
  Widget child, {
  required TutorBrain brain,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // The ONE backend switch point — return the stub for the agent factory.
        tutorBrainFactoryProvider
            .overrideWithValue((Map<String, String> feedback) => brain),
        // No real synthesis in widget tests — the coach voice is a silent no-op.
        ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('D-A cutover — the scorer verdict never waits on, and is never overturned '
      'by, the brain', () {
    testWidgets('Test 1: verdict applies WITHOUT the brain — a never-completing '
        'brain future still yields the star + pass CTA, and NO authored line '
        'shows while the agent is pending', (tester) async {
      final brain = _NeverBrain();
      await _pumpScaffold(
        tester,
        ExerciseScaffold(exercise: _graded(), letter: _baa()),
        brain: brain,
      );

      // Drive a scored PASS through the public path (WriteSurface.onResult ==
      // the scaffold's _onResult, exactly what the canvas fires on completion).
      final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
      ws.onResult!(const CheckResult.pass());
      await tester.pump(); // ONE frame — the brain future is left pending

      // The brain WAS consulted (for the words), but the verdict did not wait:
      // the pass star + "Next exercise" CTA rendered while the future is pending.
      expect(brain.called, isTrue);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('Next exercise'), findsOneWidget);
      // …and NOT the authored praise line — on the baa path the words area waits
      // for the agent; the offline floor never masks it (owner directive).
      expect(find.text(_passLine), findsNothing);
    });

    testWidgets('Test 2: a FAILING brain leaves the verdict standing while the '
        'words stay EMPTY — no authored line, no reversal, no crash',
        (tester) async {
      final brain = _ErrorBrain();
      await _pumpScaffold(
        tester,
        ExerciseScaffold(exercise: _graded(), letter: _baa()),
        brain: brain,
      );

      final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
      ws.onResult!(const CheckResult.fail('shallowBowl'));
      await tester.pumpAndSettle(); // let the brain error surface via catchError

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ExerciseScaffold)),
      );

      // The FIX verdict STANDS after the error — the coral X, and NO star. The
      // brain failure did not reverse the scorer.
      expect(brain.called, isTrue);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      // The authored fix line NEVER appears on the baa path — the words area is
      // empty because the agent produced nothing (owner directive).
      expect(find.text(_fixLine), findsNothing);
      // Only the tutor coaching-line channel is set — and it is null (empty).
      expect(container.read(tutorLineProvider), isNull);
    });

    testWidgets('Test 3: no deferral path — the verdict is set SYNCHRONOUSLY in the '
        'same call as the scorer result; the brain fires AFTER', (tester) async {
      final brain = _NeverBrain();
      await _pumpScaffold(
        tester,
        ExerciseScaffold(exercise: _graded(), letter: _baa()),
        brain: brain,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ExerciseScaffold)),
      );
      // Before the result the controller is idle.
      expect(container.read(exerciseControllerProvider).phase, ExercisePhase.idle);

      final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
      ws.onResult!(const CheckResult.pass());

      // IMMEDIATELY after the call returns — NO pump, NO await — the verdict is
      // already applied (synchronous, not gated on the network) and the brain has
      // already been fired (after the verdict). This is the structural D-A pin:
      // there is no code path that gates applyResult on the brain response.
      expect(container.read(exerciseControllerProvider).phase, ExercisePhase.pass);
      expect(brain.called, isTrue);
    });

    testWidgets('Test 4: when the agent answers, its line is the ONLY feedback '
        'text — shown identically in the bubble AND the bottom bar; the authored '
        'line never appears', (tester) async {
      final brain = _SayBrain();
      await _pumpScaffold(
        tester,
        ExerciseScaffold(exercise: _graded(), letter: _baa()),
        brain: brain,
      );

      final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
      ws.onResult!(const CheckResult.fail('shallowBowl'));
      await tester.pumpAndSettle(); // the agent line resolves + renders

      expect(brain.called, isTrue);
      // The agent line is present in BOTH the tutor bubble and the bottom
      // FeedbackPanelV2 (the same resolved words channel).
      expect(find.text(_agentLine), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(FeedbackPanelV2),
          matching: find.text(_agentLine),
        ),
        findsOneWidget,
      );
      // The authored floor line is NOWHERE — the agent owns the words on baa.
      expect(find.text(_fixLine), findsNothing);
      // The fix verdict (coral X) still stands under the agent's words.
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('Test 5: a NON-agent letter (alif) still shows the instant '
        'authored line — the agent-only gating is baa-scoped', (tester) async {
      // The brain override is only consulted on the agent path; alif uses the
      // AuthoredFallbackBrain internally, so the authored line must show.
      await _pumpScaffold(
        tester,
        ExerciseScaffold(exercise: _graded(), letter: _alif()),
        brain: _NeverBrain(),
      );

      final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
      ws.onResult!(const CheckResult.pass());
      await tester.pumpAndSettle();

      // The authored praise shows instantly in the bottom panel (unchanged path).
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FeedbackPanelV2),
          matching: find.text(_passLine),
        ),
        findsOneWidget,
      );
    });
  });
}
