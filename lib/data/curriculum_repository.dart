import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/data/firestore_curriculum_codec.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/lesson.dart';

part 'curriculum_repository.g.dart';

class CurriculumRepository {
  // In-memory cache: loaded once, held for app lifetime (provider is kept-alive)
  List<Letter>? _letters;       // mutable backing list
  List<Letter>? _lettersView;   // unmodifiable view — same instance on every call
  List<Lesson>? _lessons;
  List<String>? _defaultToleranceRamp;

  // Non-null = test mode; null = load from rootBundle
  final String? _lettersJsonOverride;
  final String? _lessonsJsonOverride;

  // Live curriculum source-of-truth (D-01). Held lazily: the default and
  // .withFirestore paths resolve it on first read; .fromStrings never touches
  // it (the JSON-override path wins), so bundle/JSON tests stay network-free AND
  // Firebase-free (no FirebaseFirestore.instance is eagerly constructed). The
  // getter resolves FirebaseFirestore.instance only when actually needed.
  FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ??= FirebaseFirestore.instance;

  CurriculumRepository({FirebaseFirestore? firestore})
      : _lettersJsonOverride = null,
        _lessonsJsonOverride = null,
        _firestoreOverride = firestore;

  /// Test/seam constructor: inject a Firestore instance (e.g. a
  /// `FakeFirebaseFirestore`) and run the live Firestore read path against it.
  /// The JSON-override fields stay null so `_ensureLoaded()` takes the
  /// Firestore-or-bundle branch, not the `.fromStrings` test path.
  CurriculumRepository.withFirestore(FirebaseFirestore firestore)
      : _lettersJsonOverride = null,
        _lessonsJsonOverride = null,
        _firestoreOverride = firestore;

  CurriculumRepository.fromStrings(String lettersJson, String lessonsJson)
      : _lettersJsonOverride = lettersJson,
        _lessonsJsonOverride = lessonsJson,
        _firestoreOverride = null;

  /// The decided file-level tolerance ramp default — the last resort when
  /// neither Firestore's meta doc nor the bundle's `defaultToleranceRamp`
  /// supplies one (Pitfall 5; never throws).
  static const List<String> _decidedRampDefault = ['loose', 'normal', 'strict'];

  Future<void> _ensureLoaded() async {
    if (_letters != null) return; // already cached

    // The read happens once here, at the first getter call, into the kept-alive
    // cache; the practice/scoring path is cache-served thereafter and never
    // blocks on a network round-trip (D-03 / PLAT-01).
    final List<Letter> parsed;
    final List<Lesson> lessons;
    final List<String> ramp;

    final lettersOverride = _lettersJsonOverride;
    if (lettersOverride != null) {
      // Test / JSON-override path — unchanged, network-free and Firebase-free.
      // .fromStrings always sets both override fields together, so the lessons
      // override is non-null on this branch.
      parsed = _parseLettersJson(lettersOverride);
      final lessonsMap =
          json.decode(_lessonsJsonOverride!) as Map<String, dynamic>;
      lessons = _parseLessons(lessonsMap['lessons'] as List<dynamic>);
      ramp = _rampFromLessonsMap(lessonsMap);
    } else {
      // Live path — Firestore-first, bundle fallback (D-01/D-02/D-04).
      parsed = await _loadLettersFromFirestoreOrBundle();
      lessons = await _loadLessonsFromFirestoreOrBundle();
      ramp = await _loadRampFromFirestoreOrBundle();
    }

    parsed.sort((a, b) => a.introOrder.compareTo(b.introOrder));

    // Load-time D-04/D-05 guard (T-02.1-03 / T-06.1-10): run the closed-loop/
    // direction/dot/range/order validator over every letter's reference strokes
    // — over WHICHEVER source won (Firestore OR bundle). An outline (or any
    // invalid stroke) must NEVER load silently — throw with the offending letter
    // id + violation messages. Validate into locals first so a throw does not
    // poison the cache (`_letters` stays null and a retry re-runs the guard;
    // the invalid stroke never reaches the scorer).
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
    _lessons = lessons;
    _defaultToleranceRamp = ramp;
  }

  // --- JSON parse helpers (shared by the override path + the bundle fallback) -

  List<Letter> _parseLettersJson(String raw) {
    final decoded =
        (json.decode(raw) as Map<String, dynamic>)['letters'] as List<dynamic>;
    return decoded
        .map((e) => Letter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Lesson> _parseLessons(List<dynamic> decoded) {
    return decoded
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// D-19: file-level tolerance ramp from a parsed lessons map. Defensive parse:
  /// absent or malformed → the decided default, never throw.
  List<String> _rampFromLessonsMap(Map<String, dynamic> lessonsMap) {
    final rawRamp = lessonsMap['defaultToleranceRamp'];
    return rawRamp is List
        ? List.unmodifiable(rawRamp.whereType<String>())
        : _decidedRampDefault;
  }

  // --- Firestore-first read with bundle fallback (D-01/D-02) ------------------

  /// One-shot `.get()` of the `letters` collection (a single read, NOT a live
  /// stream subscription — Pitfall 2, Riverpod-3 stream-pause). Non-empty → map
  /// via the codec; empty or error (cold/no-network first run) → fall back to
  /// the bundled JSON (D-02).
  Future<List<Letter>> _loadLettersFromFirestoreOrBundle() async {
    try {
      final snap = await _firestore.collection('letters').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => letterFromFirestore(d.data())).toList();
      }
    } catch (_) {
      // network/permission/cold-first-run → fall through to the bundle.
    }
    final raw = await rootBundle.loadString('assets/curriculum/letters.json');
    return _parseLettersJson(raw);
  }

  Future<List<Lesson>> _loadLessonsFromFirestoreOrBundle() async {
    try {
      final snap = await _firestore.collection('lessons').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => lessonFromFirestore(d.data())).toList();
      }
    } catch (_) {
      // fall through to the bundle.
    }
    final raw = await rootBundle.loadString('assets/curriculum/lessons.json');
    final lessonsMap = json.decode(raw) as Map<String, dynamic>;
    return _parseLessons(lessonsMap['lessons'] as List<dynamic>);
  }

  /// Ramp source order (D-07, Pitfall 5 — defensive, never throws):
  /// 1. Firestore `meta/toleranceRamp` doc (field `ramp`) when present & non-empty;
  /// 2. else the bundle's `defaultToleranceRamp`;
  /// 3. else the decided `['loose','normal','strict']` default.
  Future<List<String>> _loadRampFromFirestoreOrBundle() async {
    try {
      final doc =
          await _firestore.collection('meta').doc('toleranceRamp').get();
      final data = doc.data();
      if (doc.exists && data != null) {
        final ramp = metaToleranceRampFromFirestore(data);
        if (ramp.isNotEmpty) return List.unmodifiable(ramp);
      }
    } catch (_) {
      // fall through to the bundle ramp.
    }
    try {
      final raw = await rootBundle.loadString('assets/curriculum/lessons.json');
      return _rampFromLessonsMap(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return _decidedRampDefault;
    }
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

  /// D-19: the file-level tolerance ramp from lessons.json, defaulting to
  /// ['loose', 'normal', 'strict'] when the key is absent. Consumed by the
  /// practice flow (plan 06-04) to ramp scoring tolerance across reps.
  Future<List<String>> getDefaultToleranceRamp() async {
    await _ensureLoaded();
    return _defaultToleranceRamp!;
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
