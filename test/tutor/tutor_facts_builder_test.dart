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
/// outside this set is a leak the test must catch. Enlarged for the capable
/// agent (Plan 14-03): `trajectory` + `strengthTags`, plus the nested
/// `AttemptFact` record keys (`passed`/`mistakeId`/`section` — already covered).
const _whitelist = <String>{
  'letterId',
  'mistakeId',
  'passed',
  'section',
  'struggleTags',
  'strengthTags',
  'recentMistakes',
  'trajectory',
  // Phase 15 (15-04): the graph-position fields — pure non-PII id string-lists
  // mirroring server/app/schema.py TutorFactsIn (Pitfall 1 — the 422 lockstep).
  'clearedTiers',
  'clearedCompetencies',
  // Phase 17 (17-06, STRK-01/D-B/GROUND-04): the criteria + word mirror fields —
  // top-level, omit-when-null. `criteria` is a list of point-free records whose
  // own keys live in [_criteriaKeys]; the three word/weakest scalars are strings.
  // All mirror server/app/schema.py TutorFactsIn byte-for-byte (the 422 lockstep).
  'criteria',
  'weakestCriterion',
  'expectedWord',
  'writtenWord',
};

/// The keys allowed INSIDE each derived [criteria] entry (Phase 17 / 17-06).
/// EXACTLY {criterion, zone, score} scalars — NO coordinate keys. Mirrors the
/// server `CriterionIn` (`server/app/schema.py`); `criterion` (never `name`) and
/// the absence of any `point` substring keep the token guard green by construction.
const _criteriaKeys = <String>{'criterion', 'zone', 'score'};

/// Matches a key that would smell like raw stroke geometry or PII.
///
/// TIGHTENED (Plan 14-03 Blocker fix): the old pattern
/// `/stroke|offset|nick|name|x|y|point/i` was a SUBSTRING scan — the bare single
/// letters `x`/`y` falsely matched the new legit keys `trajectory` (contains "y")
/// and `nextExerciseId` (ne**x**t). The trap was ONLY the lone `x`/`y`; the
/// multi-char PII/geometry tokens (`stroke`/`offset`/`name`/`nick`/`point`) are
/// safe as substrings because no legit field name contains them. So we anchor
/// ONLY `x`/`y` to a word boundary and keep the rest as substrings. A real
/// `x`/`y`/`strokes`/`offset`/`childName` key still FAILS; `trajectory`/
/// `strengthTags`/`nextExerciseId` PASS.
final _forbiddenKey = RegExp(
  r'\b[xy]\b|stroke|offset|coord|point|raw|nick|name',
  caseSensitive: false,
);

/// Recursively collect every key in a serialized FACTS map, descending into
/// nested maps (the trajectory records) so a leaked key inside a trajectory
/// entry is caught too.
Set<String> _allKeys(Object? node) {
  final keys = <String>{};
  if (node is Map) {
    for (final entry in node.entries) {
      keys.add(entry.key.toString());
      keys.addAll(_allKeys(entry.value));
    }
  } else if (node is Iterable) {
    for (final item in node) {
      keys.addAll(_allKeys(item));
    }
  }
  return keys;
}

void main() {
  group('buildTutorFacts — the non-PII chokepoint', () {
    test('a miss → passed:false carrying the mistakeId; payload keys whitelisted',
        () {
      final facts = buildTutorFacts(
        letterId: 'baa',
        section: 'traceLetter',
        result: const CheckResult.fail('shallowBowl'),
        recentMistakes: const ['shallowBowl', 'missingDot'],
        trajectory: const [
          AttemptFact(passed: false, mistakeId: 'shallowBowl', section: 'traceLetter'),
          AttemptFact(passed: true, mistakeId: null, section: 'traceLetter'),
        ],
      );

      expect(facts.passed, isFalse);
      expect(facts.mistakeId, 'shallowBowl');
      expect(facts.letterId, 'baa');
      expect(facts.section, 'traceLetter');

      final map = facts.toMap();
      // (a) every emitted key — including nested trajectory record keys — is in
      // the whitelist.
      expect(
        _allKeys(map).difference(_whitelist),
        isEmpty,
        reason: 'TutorFacts leaked a non-whitelisted key: ${_allKeys(map)}',
      );
      // (b) no key (top-level or nested) matches the tightened raw-stroke / PII
      // pattern.
      for (final k in _allKeys(map)) {
        expect(
          _forbiddenKey.hasMatch(k),
          isFalse,
          reason: 'TutorFacts key "$k" matches a forbidden stroke/PII pattern',
        );
      }
    });

    test('derives the criteria + word mirror facts from the CheckResult (17-06): '
        'toMap emits them with only {criterion,zone,score} per entry', () {
      final facts = buildTutorFacts(
        letterId: 'baa',
        section: 'writeWord',
        result: const CheckResult(
          passed: false,
          mistakeId: 'shallowBowl',
          criteria: [
            {'criterion': 'shape', 'zone': 'certainlyWrong', 'score': 0.1},
            {'criterion': 'direction', 'zone': 'fuzzy', 'score': 0.7},
          ],
          weakestCriterion: 'shape',
          expectedWord: 'باب',
          writtenWord: 'بب',
        ),
      );

      final map = facts.toMap();
      // (a) the four mirror fields reached the payload (derived FROM the result).
      expect(map['criteria'], isA<List<Object?>>());
      expect(map['weakestCriterion'], 'shape');
      expect(map['expectedWord'], 'باب');
      expect(map['writtenWord'], 'بب');
      // (b) each criteria entry carries EXACTLY {criterion, zone, score}.
      for (final entry in (map['criteria'] as List)) {
        expect((entry as Map).keys.toSet(), {'criterion', 'zone', 'score'});
      }
      // (c) no emitted key (nested included) escapes the whitelist ∪ criteria keys.
      expect(
        _allKeys(map).difference(_whitelist.union(_criteriaKeys)),
        isEmpty,
        reason:
            'criteria-bearing TutorFacts leaked a non-whitelisted key: ${_allKeys(map)}',
      );
      // (d) no emitted key (top-level or nested) trips the stroke/PII token guard.
      for (final k in _allKeys(map)) {
        expect(
          _forbiddenKey.hasMatch(k),
          isFalse,
          reason: 'criteria payload key "$k" trips the stroke/PII guard',
        );
      }
    });

    test('omits the criteria + word facts when the CheckResult carries none '
        '(17-06 omit-when-null: byte-identical to the pre-plan shape)', () {
      final facts = buildTutorFacts(
        letterId: 'baa',
        section: 'traceLetter',
        result: const CheckResult.fail('shallowBowl'),
      );
      final map = facts.toMap();
      expect(map.containsKey('criteria'), isFalse);
      expect(map.containsKey('weakestCriterion'), isFalse);
      expect(map.containsKey('expectedWord'), isFalse);
      expect(map.containsKey('writtenWord'), isFalse);
    });

    test('the tightened guard FAILS real geometry/PII keys, PASSES legit fields',
        () {
      // (1) real coordinate / stroke / PII keys MUST trip the guard.
      for (final bad in const ['x', 'y', 'strokes', 'offset', 'childName',
          'rawPoints', 'coordList', 'nickname']) {
        expect(
          _forbiddenKey.hasMatch(bad),
          isTrue,
          reason: 'the guard must catch the geometry/PII key "$bad"',
        );
      }
      // (2) the new legit field names MUST NOT trip the guard.
      for (final ok in const ['trajectory', 'strengthTags', 'struggleTags',
          'nextExerciseId', 'letterId', 'section', 'passed', 'mistakeId',
          'recentMistakes']) {
        expect(
          _forbiddenKey.hasMatch(ok),
          isFalse,
          reason: 'the guard must PASS the legit field "$ok"',
        );
      }
    });

    test('strengthTags is the inverse of struggles: a cleanly-passed section', () {
      final facts = buildTutorFacts(
        letterId: 'baa',
        section: 'traceLetter',
        result: const CheckResult.pass(),
        recentMistakes: const ['shallowBowl', 'shallowBowl'],
        trajectory: const [
          AttemptFact(passed: false, mistakeId: 'shallowBowl', section: 'traceLetter'),
          AttemptFact(passed: false, mistakeId: 'shallowBowl', section: 'traceLetter'),
          AttemptFact(passed: true, mistakeId: null, section: 'writeWord'),
        ],
      );
      // 'shallowBowl' is a struggle (seen 2+ times) → not a strength.
      expect(facts.struggleTags, contains('shallowBowl'));
      // 'writeWord' was passed cleanly with no miss → a derived strength tag.
      expect(facts.strengthTags, contains('writeWord'));
      expect(facts.strengthTags, isNot(contains('traceLetter')));
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
      expect(_allKeys(json).difference(_whitelist), isEmpty);
      expect(json['letterId'], isA<String>());
      expect(json['section'], isA<String>());
      expect(json['struggleTags'], isA<List<String>>());
      expect(json['strengthTags'], isA<List<String>>());
      expect(json['recentMistakes'], isA<List<String>>());
      expect(json['trajectory'], isA<List<Object?>>());
    });

    test('toJson mirrors the server TutorFactsIn field set exactly (no extra '
        'keys that would 422 under extra=forbid)', () {
      final facts = buildTutorFacts(
        letterId: 'baa',
        section: 'traceLetter',
        result: const CheckResult.fail('shallowBowl'),
        recentMistakes: const ['shallowBowl'],
        trajectory: const [
          AttemptFact(passed: false, mistakeId: 'shallowBowl', section: 'traceLetter'),
        ],
        clearedTiers: const ['manqul'],
        clearedCompetencies: const ['recognize'],
      );
      // The 10 TutorFactsIn fields, exactly — the 8 base + the two Phase-15
      // graph-position fields — no more, no fewer (Pitfall 1: extra=forbid).
      expect(
        facts.toJson().keys.toSet(),
        {
          'letterId',
          'section',
          'passed',
          'mistakeId',
          'struggleTags',
          'recentMistakes',
          'trajectory',
          'strengthTags',
          'clearedTiers',
          'clearedCompetencies',
        },
      );
      // The two new fields are pure string-lists, threaded straight through.
      expect(facts.toJson()['clearedTiers'], const ['manqul']);
      expect(facts.toJson()['clearedCompetencies'], const ['recognize']);
      // Each AttemptFactIn carries exactly {passed, mistakeId, section}.
      final entry = (facts.toJson()['trajectory'] as List).first as Map;
      expect(entry.keys.toSet(), {'passed', 'mistakeId', 'section'});
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

    test('a decision can carry an optional plan; one with no plan still builds '
        '(the offline floor path)', () {
      // The closed ACTION-shape set is unchanged; the plan rides alongside it.
      const withPlan = Advance(
        plan: TutorPlan(
          nextExerciseId: 'baa-q4',
          intent: 'advance',
          rationale: 'two clean reps on traceLetter',
        ),
      );
      const noPlan = PresentActivity(coachingLine: 'Deeper curve.', letterId: 'baa');

      expect(withPlan.plan, isNotNull);
      expect(withPlan.plan!.nextExerciseId, 'baa-q4');
      expect(withPlan.toolName, TutorTool.advance);
      // The offline floor never sets a plan — it must still construct.
      expect(noPlan.plan, isNull);
      expect(noPlan.toolName, TutorTool.presentActivity);
      // The action space stays closed — exactly the 4 tool names.
      expect(TutorTool.all.length, 4);
    });
  });
}
