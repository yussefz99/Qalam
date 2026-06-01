import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/lesson.dart';

part 'curriculum_repository.g.dart';

class CurriculumRepository {
  // In-memory cache: loaded once, held for app lifetime (provider is kept-alive)
  List<Letter>? _letters;       // mutable backing list
  List<Letter>? _lettersView;   // unmodifiable view — same instance on every call
  List<Lesson>? _lessons;

  // Non-null = test mode; null = load from rootBundle
  final String? _lettersJsonOverride;
  final String? _lessonsJsonOverride;

  CurriculumRepository()
      : _lettersJsonOverride = null,
        _lessonsJsonOverride = null;

  CurriculumRepository.fromStrings(String lettersJson, String lessonsJson)
      : _lettersJsonOverride = lettersJson,
        _lessonsJsonOverride = lessonsJson;

  Future<void> _ensureLoaded() async {
    if (_letters != null) return; // already cached

    final lettersRaw = _lettersJsonOverride ??
        await rootBundle.loadString('assets/curriculum/letters.json');
    final lessonsRaw = _lessonsJsonOverride ??
        await rootBundle.loadString('assets/curriculum/lessons.json');

    final lettersDecoded =
        (json.decode(lettersRaw) as Map<String, dynamic>)['letters']
            as List<dynamic>;
    final parsed = (lettersDecoded
            .map((e) => Letter.fromJson(e as Map<String, dynamic>))
            .toList())
      ..sort((a, b) => a.introOrder.compareTo(b.introOrder));

    // Load-time D-04 guard (T-02.1-03): run the closed-loop/direction/dot/range/
    // order validator over every letter's reference strokes. An outline (or any
    // invalid stroke) must NEVER load silently — throw with the offending letter
    // id + violation messages. Validate into a local first so a throw does not
    // poison the cache (`_letters` stays null and a retry re-runs the guard).
    for (final letter in parsed) {
      final violations = validateReferenceStrokes(letter.referenceStrokes);
      if (violations.isNotEmpty) {
        throw StateError(
          'Invalid referenceStrokes for letter "${letter.id}": '
          '${violations.join('; ')}',
        );
      }
    }

    _letters = parsed;
    _lettersView = List.unmodifiable(_letters!);

    final lessonsDecoded =
        (json.decode(lessonsRaw) as Map<String, dynamic>)['lessons']
            as List<dynamic>;
    _lessons = lessonsDecoded
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Letter>> getLetters() async {
    await _ensureLoaded();
    return _lettersView!;
  }

  Future<Letter?> getLetter(String id) async {
    final letters = await getLetters();
    try {
      return letters.firstWhere((l) => l.id == id);
    } on StateError {
      return null;
    }
  }

  Future<List<Lesson>> getLessons() async {
    await _ensureLoaded();
    return List.unmodifiable(_lessons!);
  }

  Future<Lesson?> getLesson(String id) async {
    final lessons = await getLessons();
    try {
      return lessons.firstWhere((l) => l.id == id);
    } on StateError {
      return null;
    }
  }

  /// Returns empty list if exercises.json does not exist (Phase 8 creates it).
  /// D-10: handle absence gracefully — return empty, never throw.
  Future<List<dynamic>> getExercises() async {
    if (_lettersJsonOverride != null) {
      return const []; // test mode: no exercises file
    }
    try {
      final raw =
          await rootBundle.loadString('assets/curriculum/exercises.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return (decoded['exercises'] as List<dynamic>?) ?? [];
    } catch (_) {
      return const [];
    }
  }
}

@Riverpod(keepAlive: true)
CurriculumRepository curriculumRepository(Ref ref) {
  return CurriculumRepository();
}
