// Phase 19-01 (Wave 0) — QP-06 / D-08 contract: recall write types show NO
// letter model.
//
// D-08 (locked): `writeLetter`/`writeWord` RECALL questions show no letter model
// (no ghost, no faint glyph). The Phase-18 remediation arc IS the only hint path
// (same-criterion fail streak steps down to trace) — one hint mechanism, not two;
// recall stays honest.
//
// This is a static assertion over the authored configs: a recall write config (a
// writeLetter/writeWord with no audio prompt to reproduce and no revealed word to
// copy) must NOT author a model/ghost surface part — no dotted `guideForm`, no
// "Watch me" `demo`, and no pre-filled `given`-ink. It LOCKS the invariant so a
// future card rewrite (19-05) can never reintroduce a copy-able model on a recall
// node. 19-03 owns keeping this green (a data edit if any config ever leaks a
// model, else the assertion itself is the deliverable — no new UI).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> _loadExercisesRaw() {
  final raw = File('assets/curriculum/exercises.json').readAsStringSync();
  return (jsonDecode(raw) as Map<String, dynamic>)['exercises']
      .cast<Map<String, dynamic>>();
}

List<Map<String, dynamic>> _prompt(Map<String, dynamic> e) =>
    ((e['prompt'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>();

bool _hasAudioPart(Map<String, dynamic> e) =>
    _prompt(e).any((p) => p['kind'] == 'audio');

/// A revealed word (`reveal:"thenHide"` copy flag) is the COPY hint path, not
/// recall — exclude those from the recall set.
bool _hasReveal(Map<String, dynamic> e) =>
    _prompt(e).any((p) => p['kind'] == 'text' && p['reveal'] != null);

/// A recall write config: a `writeLetter`/`writeWord` question asking the child to
/// write from MEMORY — no audio clip to reproduce, no revealed word to copy.
bool _isRecallWriteConfig(Map<String, dynamic> e) {
  final type = e['type'] as String?;
  if (type != 'writeLetter' && type != 'writeWord') return false;
  return !_hasAudioPart(e) && !_hasReveal(e);
}

/// A model/ghost surface part = a dotted `guideForm`, a "Watch me" `demo`, or a
/// pre-filled `given`-ink — any faint-glyph letter model the child could trace or
/// copy instead of recalling.
List<String> _modelParts(Map<String, dynamic> e) {
  final surface = e['surface'] as Map<String, dynamic>?;
  if (surface == null) return const [];
  return [
    if ((surface['guideForm'] as String?) != null) 'guideForm',
    if (surface['demo'] == true) 'demo',
    if (surface['given'] != null) 'given',
  ];
}

void main() {
  test('recall writeLetter/writeWord configs carry NO letter model (QP-06 / D-08)',
      () {
    final recall = _loadExercisesRaw().where(_isRecallWriteConfig).toList();

    // Non-vacuity: at least one recall config must exist — else the "no model"
    // assertion would be trivially (vacuously) true and prove nothing.
    expect(recall, isNotEmpty,
        reason: 'there must be ≥1 writeLetter/writeWord recall config to guard');

    final offenders = <String, List<String>>{
      for (final e in recall)
        if (_modelParts(e).isNotEmpty) e['id'] as String: _modelParts(e),
    };

    expect(offenders, isEmpty,
        reason: 'recall write types must show no letter model — the remediation '
            'arc is the only hint path (D-08). Offending configs → parts: '
            '$offenders');
  });
}
