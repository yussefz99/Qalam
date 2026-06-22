// TutorFacts builder — the ONE non-PII chokepoint (Plan 14-01 Task 1).
//
// These tests pin the grounding/non-PII invariant by CONSTRUCTION:
//   • buildTutorFacts emits ONLY whitelisted derived fields (no raw strokes, no
//     PII) — the serialized payload's keys are a subset of the whitelist and
//     match NONE of /stroke|offset|nick|name|x|y|point/i (GROUND-02, TUTOR-05).
//   • a passing CheckResult → passed:true, mistakeId:null.
//   • TutorDecision has NO verdict/star shape — the agent acts, the scorer judges.
//
// Pure Dart: no Firebase, no network, no model — runs in a plain `flutter test`.

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_facts_builder.dart';

/// The complete set of keys the FACTS payload is allowed to expose. Anything
/// outside this set is a leak the test must catch.
const _whitelist = <String>{
  'letterId',
  'mistakeId',
  'passed',
  'section',
  'struggleTags',
  'recentMistakes',
};

/// Matches any key that would smell like raw stroke geometry or PII.
final _forbiddenKey = RegExp(r'stroke|offset|nick|name|x|y|point', caseSensitive: false);

void main() {
  group('buildTutorFacts — the non-PII chokepoint', () {
    test('a miss → passed:false carrying the mistakeId; payload keys whitelisted',
        () {
      final facts = buildTutorFacts(
        letterId: 'baa',
        section: 'traceLetter',
        result: const CheckResult.fail('shallowBowl'),
        recentMistakes: const ['shallowBowl', 'missingDot'],
      );

      expect(facts.passed, isFalse);
      expect(facts.mistakeId, 'shallowBowl');
      expect(facts.letterId, 'baa');
      expect(facts.section, 'traceLetter');

      final map = facts.toMap();
      // (a) every emitted key is in the whitelist.
      expect(
        map.keys.toSet().difference(_whitelist),
        isEmpty,
        reason: 'TutorFacts leaked a non-whitelisted key: ${map.keys}',
      );
      // (b) no key matches the raw-stroke / PII pattern.
      for (final k in map.keys) {
        expect(
          _forbiddenKey.hasMatch(k),
          isFalse,
          reason: 'TutorFacts key "$k" matches a forbidden stroke/PII pattern',
        );
      }
    });

    test('a pass → passed:true, mistakeId:null', () {
      final facts = buildTutorFacts(
        letterId: 'baa',
        section: 'traceLetter',
        result: const CheckResult.pass(),
      );

      expect(facts.passed, isTrue);
      expect(facts.mistakeId, isNull);
      expect(facts.toMap()['passed'], isTrue);
      expect(facts.toMap()['mistakeId'], isNull);
    });

    test('toJson is the same whitelisted, scalar/string-list shape', () {
      final facts = buildTutorFacts(
        letterId: 'baa',
        section: 'writeWord',
        result: const CheckResult.fail('lifted'),
        recentMistakes: const ['lifted'],
      );

      final json = facts.toJson();
      expect(json.keys.toSet().difference(_whitelist), isEmpty);
      expect(json['letterId'], isA<String>());
      expect(json['section'], isA<String>());
      expect(json['struggleTags'], isA<List<String>>());
      expect(json['recentMistakes'], isA<List<String>>());
    });
  });

  group('TutorDecision — ACTIONS-out only, no verdict shape', () {
    test('the four ACTION tool-name constants are the single source of truth',
        () {
      expect(TutorTool.presentActivity, 'present_activity');
      expect(TutorTool.say, 'say');
      expect(TutorTool.giveHint, 'give_hint');
      expect(TutorTool.advance, 'advance');
      expect(TutorTool.all, {
        'present_activity',
        'say',
        'give_hint',
        'advance',
      });
    });

    test('each decision exposes its ACTION tool name; none is a verdict/star', () {
      const present = PresentActivity(coachingLine: 'Try a deeper curve.', letterId: 'baa');
      const say = Say('أحسنت');
      const hint = GiveHint();
      const advance = Advance();

      expect(present.toolName, TutorTool.presentActivity);
      expect(say.toolName, TutorTool.say);
      expect(hint.toolName, TutorTool.giveHint);
      expect(advance.toolName, TutorTool.advance);

      // Every decision's tool name is one of the 4 ACTION tools — never a
      // verdict/star (GROUND-01: the scorer owns pass/fail).
      for (final d in <TutorDecision>[present, say, hint, advance]) {
        expect(TutorTool.all.contains(d.toolName), isTrue);
      }
    });
  });
}
