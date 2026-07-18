// CR-01 regression (Phase-19 code review) — the LIVE completeWord card must
// render the D-06 gap slot from the SHIPPED asset, not just from test fixtures.
//
// The Wave-0 contract tests (prompt_header_slot_audio_test.dart /
// exercise_scaffold_instruction_bar_test.dart) author their own `_letter_`
// fixture text, so a live card whose authored text drifted off the marker
// grammar (the shipped `"با_"` — a plain trailing underscore) passed every
// widget test while the child saw a raw underscore at 40px and never the
// highlighted slot box — the fixture-masks-live-data trap. These cases read
// assets/curriculum/exercises.json itself (the learned_letters_lint_test
// read-the-shipped-asset posture):
//   • a marker-format LINT: every text part carrying `gaps` metadata must spell
//     exactly one `__blank__`/`_letter_` marker per gap — asset-wide, so no
//     future card can silently miss the renderer's split grammar;
//   • an asset-backed RENDER: the real baa.completeWord.middle prompt pumps
//     through PromptHeader and must produce the Key('gapSlot') box, with no
//     literal marker (and no bare `_`) reaching the screen (Pitfall 6).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/features/letter_unit/widgets/prompt_header.dart';
import 'package:qalam/models/exercise.dart';

/// The exact split grammar `_TextPart._tokens` renders slots from — a text part
/// whose gap is authored in any OTHER shape ships an invisible slot.
final RegExp _markerPattern = RegExp('(__blank__|_letter_)');

List<Map<String, dynamic>> _loadExercises() =>
    ((jsonDecode(File('assets/curriculum/exercises.json').readAsStringSync())
            as Map<String, dynamic>)['exercises'] as List)
        .cast<Map<String, dynamic>>();

void main() {
  test(
      'marker-format lint: every shipped text part with gaps spells one '
      'renderer marker per gap (CR-01 — the fixture-masks-live-data guard)', () {
    final violations = <String>[];
    for (final e in _loadExercises()) {
      final prompt = (e['prompt'] as List<dynamic>?) ?? const <dynamic>[];
      for (final p in prompt.whereType<Map<String, dynamic>>()) {
        if (p['kind'] != 'text') continue;
        final gaps = (p['gaps'] as List<dynamic>?) ?? const <dynamic>[];
        if (gaps.isEmpty) continue;
        final text = (p['text'] as String?) ?? '';
        final markers = _markerPattern.allMatches(text).length;
        if (markers != gaps.length) {
          violations.add('${e['id']}: text ${jsonEncode(text)} spells '
              '$markers marker(s) for ${gaps.length} gap(s)');
        }
      }
    }
    expect(violations, isEmpty,
        reason: 'a gap slot renders ONLY from the literal __blank__/_letter_ '
            'markers _TextPart._tokens splits on — `gaps` metadata without the '
            'marker ships an invisible slot (the live "با_" bug): '
            '${violations.join('; ')}');
  });

  testWidgets(
      'the SHIPPED baa.completeWord.middle prompt renders the D-06 gap slot '
      'through PromptHeader (asset-backed, CR-01)', (tester) async {
    final raw = _loadExercises()
        .firstWhere((e) => e['id'] == 'baa.completeWord.middle');
    final exercise = Exercise.fromJson(raw);

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(child: PromptHeader(parts: exercise.prompt)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('gapSlot')), findsOneWidget,
        reason: 'the ONE live completeWord node must render the highlighted '
            'missing-letter slot (QP-04/D-06) — never a raw underscore inside '
            'the word');
    expect(find.textContaining('_'), findsNothing,
        reason: 'no literal marker or bare underscore ever reaches the screen '
            '(Pitfall 6)');
  });
}
