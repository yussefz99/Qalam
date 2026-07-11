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
//   • during an arc (the coach picked a micro-drill) it narrates the named
//     step-down ("just the dot … then we'll come back") — the D-03 register.
//   • NO reward surface: no counter / streak / badge / points / "+N" token
//     renders (anti-gamification, CLAUDE.md Decided).

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/teacher_margin_panel.dart';
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

/// Pump the panel and publish [insight] into the shared [tutorInsightProvider]
/// (the SAME channel the scaffold uses), then settle so the panel reads it.
Future<void> _pump(WidgetTester tester, {TutorInsight? insight}) async {
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
              child: TeacherMarginPanel(letter: _baa()),
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

  testWidgets('Test 4: during an arc it narrates the named step-down',
      (tester) async {
    await _pump(
      tester,
      insight: const TutorInsight(
        criteria: [
          {'criterion': 'dot', 'zone': 'certainlyWrong'},
        ],
        pick: 'baa.microDrill.dot',
        rationale: "Let's give the dot a moment.",
      ),
    );
    final text = _allText(tester).toLowerCase();
    // The warm named step-down: practice just this part, then come back.
    expect(text.contains('just the'), isTrue);
    expect(text.contains('come back'), isTrue);
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
}
