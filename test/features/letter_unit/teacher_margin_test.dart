// TeacherMarginPanel behavior — Plan 18-10 Task 1 (D-01, sketch 001 Variant C).
//
// The Teacher's Margin is the CHILD-FACING production panel (unlike the 17.2
// demo-only "Teacher's Eye" strip). It narrates the remediation arc beside the
// canvas and carries the WHY line in the tutor's warm register. It reads from the
// SAME [TutorInsight] the scaffold already publishes at verdict/coach time — no
// second insight source. These tests prove:
//   • the panel renders the WHY line naming the targeted criterion (from the
//     coach rationale when online).
//   • offline (no coach line, criteria only) it degrades to the authored-template
//     WHY line — same panel, degraded source (D-10).
//   • during a GENUINE remediation arc it narrates the named step-down ("just the
//     dot … then we'll come back") driven by the REAL `insight.arcStep` — NOT a
//     micro-drill pick (the drills are parked out of the live graph, D-03).
//   • NO reward surface: no counter / streak / badge / points / "+N" token
//     renders (anti-gamification, CLAUDE.md Decided).

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/teacher_margin_panel.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';

Letter _baa() {
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
  return const Letter(
    id: 'baa',
    char: 'ب',
    name: LetterName(ar: 'باء', display: 'baa'),
    introOrder: 2,
    forms: LetterForms(isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
    referenceStrokes: [body, dot],
    cleanRepsToAdvance: 1,
    commonMistakes: [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: {'isolated': Form(referenceStrokes: [body, dot])},
  );
}

/// A micro-drill exercise that DECLARES its focus (the bowl) via `criteria`, so
/// the resting note can name it before the first verdict (18-16).
Exercise _bowlDrill() => const Exercise(
      id: 'baa.microDrill.bowl',
      skill: 'formation',
      prompt: [SayPart('Just the bowl.')],
      signedOff: false,
      criteria: ['shape'],
    );

/// Pump the panel and publish [insight] into the shared [tutorInsightProvider]
/// (the SAME channel the scaffold uses), then settle so the panel reads it. Pass
/// [exercise] to give the panel its resting-presence context (18-16).
Future<void> _pump(
  WidgetTester tester, {
  TutorInsight? insight,
  Exercise? exercise,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SizedBox(
              width: 260,
              height: 600,
              child: TeacherMarginPanel(letter: _baa(), exercise: exercise),
            ),
          ),
        ),
      ),
    ),
  );
  if (insight != null) {
    final ctx = tester.element(find.byType(TeacherMarginPanel));
    ProviderScope.containerOf(ctx)
        .read(tutorInsightProvider.notifier)
        .set(insight);
  }
  await tester.pump();
}

/// Every text the panel renders, concatenated — for the reward-token guard.
String _allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n');

void main() {
  testWidgets('Test 1: null insight → the panel is silent (nothing before an attempt)',
      (tester) async {
    await _pump(tester);
    // No stray margin chrome before the first verdict publishes an insight.
    expect(find.textContaining('margin', findRichText: true), findsNothing);
  });

  testWidgets('Test 2: online — renders the coach WHY line + names the criterion',
      (tester) async {
    await _pump(
      tester,
      insight: const TutorInsight(
        criteria: [
          {'criterion': 'dot', 'zone': 'certainlyWrong'},
        ],
        pick: 'baa.microDrill.dot',
        rationale: "baa's dot lives just below the bowl — let's steady it there.",
      ),
    );
    // The coach's WHY line renders verbatim (the online source).
    expect(
      find.textContaining("baa's dot lives just below the bowl"),
      findsOneWidget,
    );
    // The targeted criterion is named for the child.
    expect(find.textContaining('dot'), findsWidgets);
  });

  testWidgets('Test 3: offline — degrades to the authored-template WHY line (D-10)',
      (tester) async {
    // No rationale (coach offline / pre-coach): only the verdict-time criteria.
    await _pump(
      tester,
      insight: const TutorInsight(
        criteria: [
          {'criterion': 'shape', 'zone': 'certainlyWrong'},
        ],
      ),
    );
    // Same panel, degraded source — an authored line about the bowl still shows.
    final text = _allText(tester).toLowerCase();
    expect(text.contains('bowl'), isTrue);
    expect(text.trim().isNotEmpty, isTrue);
  });

  testWidgets(
      'Test 4: a GENUINE arc step-down narrates from the real arcStep '
      '(no micro-drill pick required)', (tester) async {
    await _pump(
      tester,
      insight: const TutorInsight(
        criteria: [
          {'criterion': 'dot', 'zone': 'certainlyWrong'},
        ],
        // The REAL policy arc signal drives the step-down — NOT a `pick`
        // containing 'microDrill' (the drills are parked out of the live graph,
        // D-03; the step-down is a floor-trace detour). No `pick` is set here.
        arcStep: 'stepDown',
        whyFacts: ['criterion:dot', 'arcStep:stepDown'],
      ),
    );
    final text = _allText(tester).toLowerCase();
    // The warm named step-down: practice just this part, then come back.
    expect(text.contains('just the'), isTrue);
    expect(text.contains('come back'), isTrue);
    // Naming the arc's targeted part (the dot).
    expect(text.contains('just the dot'), isTrue);
  });

  testWidgets(
      'Test 4b: no arc (arcStep null) → no step-down line renders',
      (tester) async {
    await _pump(
      tester,
      insight: const TutorInsight(
        criteria: [
          {'criterion': 'dot', 'zone': 'certainlyWrong'},
        ],
        rationale: "baa's dot lives just below the bowl.",
        // arcStep omitted → null: no remediation arc in progress.
      ),
    );
    final text = _allText(tester).toLowerCase();
    expect(text.contains('come back'), isFalse,
        reason: 'no step-down narration without a real arc step');
  });

  testWidgets('Test 5: NO reward surface renders (anti-gamification guard)',
      (tester) async {
    await _pump(
      tester,
      insight: const TutorInsight(
        criteria: [
          {'criterion': 'dot', 'zone': 'certainlyWrong'},
        ],
        pick: 'baa.microDrill.dot',
        rationale: "baa's dot lives just below the bowl.",
      ),
    );
    final text = _allText(tester).toLowerCase();
    for (final token in ['streak', 'points', 'badge', '+', 'score']) {
      expect(text.contains(token), isFalse,
          reason: 'forbidden reward token "$token" must never render');
    }
  });

  testWidgets(
      'Test 6 (18-16): with an exercise + no insight, a calm resting note shows '
      '(persistent presence, not a verdict-only blast)', (tester) async {
    await _pump(tester, exercise: _bowlDrill());
    final text = _allText(tester).toLowerCase();
    // A calm resting line renders even before the first verdict.
    expect(text.contains('take your time'), isTrue);
    // The drill's declared focus (the bowl) is named.
    expect(text.contains('the bowl'), isTrue);
    // Still strictly anti-gamification.
    for (final token in ['streak', 'points', 'badge', 'score']) {
      expect(text.contains(token), isFalse,
          reason: 'forbidden reward token "$token" must never render');
    }
  });

  testWidgets(
      'Test 7 (18-16): a CLEAN PASS (no rationale, no failed criterion) does NOT '
      'show the static "deeper bowl" line — it shows a pass-appropriate line',
      (tester) async {
    // A genuinely good attempt: every criterion certainlyCorrect, no coach line.
    await _pump(
      tester,
      insight: const TutorInsight(
        criteria: [
          {'criterion': 'shape', 'zone': 'certainlyCorrect'},
          {'criterion': 'dot', 'zone': 'certainlyCorrect'},
        ],
      ),
    );
    final text = _allText(tester).toLowerCase();
    // The exact criterion-skewed static line must NOT fire on a clean pass.
    expect(text.contains('deeper bowl'), isFalse,
        reason: 'the static bowl fallback must not skew a clean pass');
    // A warm pass-appropriate line shows instead.
    expect(text.contains('lovely writing'), isTrue);
  });

  testWidgets(
      'Test 8 (18-16): a GENUINE criterion FAIL (no rationale) still shows the '
      'authored offline floor for THAT criterion', (tester) async {
    await _pump(
      tester,
      insight: const TutorInsight(
        criteria: [
          {'criterion': 'dot', 'zone': 'certainlyWrong'},
        ],
      ),
    );
    final text = _allText(tester).toLowerCase();
    // The authored floor for the FAILED criterion (the dot) is preserved.
    expect(text.contains("baa's dot lives just below"), isTrue);
  });

  testWidgets(
      'Test 9 (18-16): the coach rationale, when present, is shown verbatim as '
      'the per-attempt WHY (not the authored floor)', (tester) async {
    await _pump(
      tester,
      insight: const TutorInsight(
        criteria: [
          {'criterion': 'shape', 'zone': 'certainlyWrong'},
        ],
        rationale: 'Your scoop is a touch shallow today — dip a little lower.',
      ),
    );
    final text = _allText(tester);
    expect(
      text.contains('Your scoop is a touch shallow today — dip a little lower.'),
      isTrue,
    );
    // The authored floor is NOT the source when a rationale is present.
    expect(text.toLowerCase().contains('deeper bowl'), isFalse);
  });
}
