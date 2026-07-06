// GROUND-02 — the build-failing non-PII guard on the CLIENT payload (Plan 14-04
// Task 1 / ADR-015 §4 / G1).
//
// This is the permanent regression guard that fails the build if the serialized
// `TutorFacts` request body ever exposes a key outside the explicit non-PII
// whitelist OR a key matching the TIGHTENED coordinate/PII token guard. The only
// data that crosses the network to /coach is `TutorFacts.toJson()`; if a future
// field leaks geometry (`x`/`y`/`strokes`/`offset`) or PII (`childName`/
// `nickname`) this test goes red before the leak can ship.
//
// It is the client side of the GROUND-02 chokepoint; `server/tests/
// test_payload_nonpii.py` is the server side. Both must hold.
//
// Pure Dart: serialize + scan only. No Firebase, no network, no model — runs in a
// plain `flutter test`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/tutor/tutor_facts.dart';

/// The COMPLETE set of keys the FACTS payload is allowed to expose — top-level
/// and nested (the trajectory `AttemptFact` records). Anything outside this set
/// is a leak the guard must catch. Mirrors the server `TutorFactsIn` /
/// `AttemptFactIn` field set (`server/app/schema.py`) exactly.
const _whitelist = <String>{
  // TutorFactsIn (the 6 base + 2 enlarged + 2 graph-position fields).
  'letterId',
  'section',
  'passed',
  'mistakeId',
  'struggleTags',
  'recentMistakes',
  'trajectory',
  'strengthTags',
  // Phase 15 (15-04): the graph-position fields — pure non-PII id string-lists
  // mirroring server/app/schema.py TutorFactsIn (Pitfall 1 — the 422 lockstep).
  'clearedTiers',
  'clearedCompetencies',
  // Phase 17 (STRK-01/GROUND-04): the DERIVED, point-free stroke-geometry diff —
  // a nested object whose own keys are listed in [_strokeDiffKeys]. The field
  // itself is non-PII; raw strokes never leave the device, only this derived map.
  'strokeDiff',
  // Phase 17 (17-07, D-A / GROUND-04): `strokeImage` is GONE. The Phase-17.1
  // rendered-handwriting-image (AI-owns-pass/fail) path is RETIRED — the scorer
  // owns the verdict on-device, so no image of the child's handwriting ever leaves
  // the device (a net privacy win; the client half of the GROUND-04 surface
  // shrink). `stroke_image_grep_guard_test.dart` pins its absence from lib/.
  // Phase 17 (17-06, STRK-01/D-B/GROUND-04): the STRUCTURED per-criterion result
  // + derived word facts. `criteria` is a list of point-free records whose own
  // keys are listed in [_criteriaKeys]; the three scalars are derived strings. All
  // mirror server/app/schema.py TutorFactsIn byte-for-byte (Pitfall 1 — the 422
  // lockstep). GROUND-04: criteria hold only {criterion,zone,score} scalars, the
  // word facts are DERIVED text, never geometry.
  'criteria',
  'weakestCriterion',
  'expectedWord',
  'writtenWord',
  // AttemptFactIn (nested trajectory record keys) — passed/mistakeId/section
  // overlap the base set above, all already whitelisted.
};

/// The keys allowed INSIDE each derived [criteria] entry (Phase 17 / 17-06). All
/// are derived scalars/strings — NO coordinate keys. Mirrors the server
/// `CriterionIn` (`server/app/schema.py`); the server `extra="forbid"` 422s any
/// stray coordinate key nested in a criterion, and the token guard below
/// independently catches one. `criterion` (never `name`) keeps the guard green.
const _criteriaKeys = <String>{'criterion', 'zone', 'score'};

/// The keys allowed INSIDE the derived [strokeDiff] object (Phase 17). All are
/// derived scalars/strings/booleans — NO coordinate keys. Mirrors the server
/// `StrokeDiffIn` (`server/app/schema.py`); the server `extra="forbid"` 422s any
/// stray coordinate key, and the token guard below independently catches it.
const _strokeDiffKeys = <String>{
  'summary',
  'strokeCount',
  'bodySegments',
  'bowlDepthRatio',
  'bowlDepthVerdict',
  'bowlSymmetry',
  'sizeVerdict',
  'directionChild',
  'directionReference',
  'tailPresent',
  'dotPresent',
  'dotHorizontal',
  'dotVertical',
  'dotPlacementOk',
};

/// The TIGHTENED coordinate/PII token guard (the exact regex Plan 14-03 settled
/// on — `lib/tutor/tutor_facts.dart` doc + `tutor_facts_builder_test.dart`). Do
/// NOT regress this to a bare-substring scan: the lone single letters `x`/`y` are
/// word-boundary-anchored so the legit keys `trajectory` (contains "y") and
/// `nextExerciseId` (ne**x**t) PASS, while the multi-char geometry/PII tokens
/// stay substrings because no legit field name contains them. A real
/// `x`/`y`/`strokes`/`offset`/`childName`/`nickname` key FAILS.
// NOTE (Phase 17): the raw-array token is `strokes` (plural), NOT bare `stroke`,
// so the DERIVED keys `strokeDiff` / `strokeCount` PASS while a raw `strokes`
// array still FAILS. The whitelist ([_whitelist] ∪ [_strokeDiffKeys]) is the
// primary guard; this token scan is defense-in-depth against a future leak.
final _forbiddenKey = RegExp(
  r'\b[xy]\b|strokes|offset|coord|point|raw|nick|name',
  caseSensitive: false,
);

/// Recursively collect every key in a serialized FACTS map, descending into
/// nested maps + lists (the trajectory records) so a leaked key inside an
/// `AttemptFact` entry is caught too.
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

/// A FULLY-populated `TutorFacts`: every field set, a multi-record trajectory,
/// and both struggle + strength tags — so the scan exercises every emitted key,
/// including the nested `AttemptFact` records.
TutorFacts _fullyPopulatedFacts() => const TutorFacts(
      letterId: 'baa',
      section: 'traceLetter',
      passed: false,
      mistakeId: 'shallowBowl',
      struggleTags: ['boat-curvature', 'shallowBowl'],
      strengthTags: ['writeWord', 'connectWord'],
      recentMistakes: ['shallowBowl', 'noDot', 'hasTail'],
      trajectory: [
        AttemptFact(passed: false, mistakeId: 'shallowBowl', section: 'traceLetter'),
        AttemptFact(passed: false, mistakeId: 'noDot', section: 'traceLetter'),
        AttemptFact(passed: true, mistakeId: null, section: 'writeWord'),
      ],
      clearedTiers: ['manqul', 'manzur'],
      clearedCompetencies: ['recognize', 'positionalForms'],
      // Phase 17: a representative DERIVED diff exercising every nested key — all
      // derived scalars/strings/booleans, NO coordinates.
      strokeDiff: <String, Object?>{
        'summary': 'bowl shallower than the reference; dot left of center',
        'strokeCount': 2,
        'bodySegments': 1,
        'bowlDepthRatio': 0.62,
        'bowlDepthVerdict': 'shallower',
        'bowlSymmetry': 'right side flat, left side curves',
        'sizeVerdict': 'matches',
        'directionChild': 'rightToLeft',
        'directionReference': 'rightToLeft',
        'tailPresent': false,
        'dotPresent': true,
        'dotHorizontal': 'left of center',
        'dotVertical': 'below the bowl',
        'dotPlacementOk': false,
      },
      // Phase 17 (17-06): a representative DERIVED criteria list exercising every
      // nested key — {criterion, zone, score} scalars ONLY (never a coordinate) —
      // plus the weakest criterion + the F6 word facts (derived TEXT, no geometry).
      criteria: <Map<String, Object?>>[
        {'criterion': 'strokeCount', 'zone': 'certainlyCorrect', 'score': 1.0},
        {'criterion': 'strokeOrder', 'zone': 'certainlyCorrect', 'score': 1.0},
        {'criterion': 'shape', 'zone': 'certainlyWrong', 'score': 0.0},
        {'criterion': 'direction', 'zone': 'fuzzy', 'score': 0.62},
        {'criterion': 'dot', 'zone': 'certainlyCorrect', 'score': 1.0},
      ],
      weakestCriterion: 'shape',
      expectedWord: 'باب',
      writtenWord: 'بب',
    );

void main() {
  group('GROUND-02 — the client payload carries only the non-PII whitelist', () {
    test('a fully-populated TutorFacts serializes to only whitelisted keys '
        '(top-level AND nested trajectory records)', () {
      final json = _fullyPopulatedFacts().toJson();
      final keys = _allKeys(json);

      // Sanity: the scan actually descended into the trajectory records AND the
      // nested strokeDiff object AND the nested criteria records (17-06).
      expect(keys, containsAll(<String>{'trajectory', 'passed', 'mistakeId', 'section'}));
      expect(keys, containsAll(<String>{'strokeDiff', 'bowlDepthVerdict', 'dotHorizontal'}));
      expect(keys, containsAll(<String>{'criteria', 'criterion', 'zone', 'score', 'weakestCriterion'}));

      expect(
        keys.difference(_whitelist.union(_strokeDiffKeys).union(_criteriaKeys)),
        isEmpty,
        reason: 'TutorFacts leaked a non-whitelisted key (incl. nested): $keys',
      );
    });

    test('no serialized key (top-level or nested) matches the tightened '
        'coordinate/PII token guard', () {
      final json = _fullyPopulatedFacts().toJson();
      for (final k in _allKeys(json)) {
        expect(
          _forbiddenKey.hasMatch(k),
          isFalse,
          reason: 'TutorFacts key "$k" matches the forbidden stroke/PII guard',
        );
      }
    });

    test('BOTH directions: synthetic geometry/PII keys FAIL the guard; the real '
        'enlarged keys PASS it', () {
      // (a) a synthetic key set of real geometry/PII keys — each MUST trip the
      // guard. This proves the guard still catches a leak.
      for (final bad in const [
        'x',
        'y',
        'strokes',
        'offsets',
        'childName',
        'nickname',
        'rawPoints',
        'coordList',
      ]) {
        expect(
          _forbiddenKey.hasMatch(bad),
          isTrue,
          reason: 'the guard must catch the geometry/PII key "$bad"',
        );
      }

      // (b) the real serialized + plan field names — each MUST NOT trip the
      // guard. This proves the tightened regex does not collide with legit
      // fields (the original substring trap on lone x/y).
      for (final ok in const [
        'trajectory',
        'strengthTags',
        'struggleTags',
        'recentMistakes',
        'nextExerciseId',
        'letterId',
        'section',
        'passed',
        'mistakeId',
        // Phase 17 derived diff keys — must PASS the guard (derived, point-free).
        'strokeDiff',
        'strokeCount',
        'bowlDepthRatio',
        'dotHorizontal',
        'dotPlacementOk',
        // Phase 17 (17-06) criteria + word mirror keys — must PASS the guard
        // (`criterion`, never `name`; no key contains a `point` substring).
        'criteria',
        'criterion',
        'zone',
        'score',
        'weakestCriterion',
        'expectedWord',
        'writtenWord',
      ]) {
        expect(
          _forbiddenKey.hasMatch(ok),
          isFalse,
          reason: 'the guard must PASS the legit field "$ok"',
        );
      }
    });

    test('TutorFacts exposes no field accepting raw geometry (a reflection-free '
        'source + serialized-surface check)', () {
      // Reflection-free, mirroring the builder test's intent: the serialized key
      // set IS the field surface, so if no key trips the guard there is no
      // stroke/Offset field. We also assert the source code declares no
      // `Offset` / `List<Stroke>` typed field (doc-comments stripped first so
      // the prose that NAMES Offset/stroke to explain their absence can't
      // self-trip the check).
      final source = File('lib/tutor/tutor_facts.dart').readAsStringSync();
      final code = source
          .split('\n')
          .where((l) =>
              !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
          .join('\n');

      expect(
        code.contains('Offset'),
        isFalse,
        reason: 'tutor_facts.dart code declares an Offset — raw geometry must '
            'not be representable in the FACTS type',
      );
      expect(
        RegExp(r'List<\s*Stroke\b').hasMatch(code),
        isFalse,
        reason: 'tutor_facts.dart code declares a stroke list — raw geometry '
            'must not be representable in the FACTS type',
      );
      // And the only emitted keys are the 8 whitelisted server-DTO fields.
      expect(
        _fullyPopulatedFacts().toJson().keys.toSet(),
        _whitelist,
        reason: 'the serialized field surface must equal the non-PII whitelist',
      );
    });
  });
}
