import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/data/firestore_curriculum_codec.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/models/lesson.dart';
import 'package:qalam/models/word.dart';

part 'curriculum_repository.g.dart';

class CurriculumRepository {
  // In-memory cache: loaded once, held for app lifetime (provider is kept-alive)
  List<Letter>? _letters;       // mutable backing list
  List<Letter>? _lettersView;   // unmodifiable view — same instance on every call
  List<Lesson>? _lessons;
  List<String>? _defaultToleranceRamp;

  // Schema v2 caches (Plan 07-01): loaded lazily on first read, held for the
  // app lifetime like _letters/_lessons. Each is read Firestore-first with a
  // bundled-seed fallback, the same pattern as the letters/lessons path.
  List<Exercise>? _exercises;
  List<Word>? _words;
  List<LetterUnit>? _units;

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
        // Backfill `contextualForms` from the bundle when a Firestore letter
        // doc lacks them. 07-07 authored the per-positional forms into the
        // bundled letters.json, but the Firestore seed that pushes them up
        // (07-07 Task 3) is gated on the owner's-mother sign-off — so docs
        // seeded earlier (Phase 06.1) carry no contextualForms. The bundle
        // stays the authored source until Firestore is reseeded; splicing the
        // bundle's contextualForms (already in [x,y]/bundle shape) into the doc
        // BEFORE the codec lets Letter.fromJson parse them verbatim. Once
        // Firestore carries them, the doc's own (non-null) forms win and this
        // backfill is a no-op.
        final bundleForms = await _bundleContextualFormsById();
        return snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data());
          final id = data['id'];
          if (data['contextualForms'] == null &&
              id is String &&
              bundleForms.containsKey(id)) {
            data['contextualForms'] = bundleForms[id];
          }
          return letterFromFirestore(data);
        }).toList();
      }
    } catch (_) {
      // network/permission/cold-first-run → fall through to the bundle.
    }
    final raw = await rootBundle.loadString('assets/curriculum/letters.json');
    return _parseLettersJson(raw);
  }

  /// Map of letterId → its bundled `contextualForms` JSON (bundle/`[x,y]`
  /// shape), for the Firestore backfill above. Defensive: any read/parse
  /// failure yields an empty map so the backfill simply does nothing.
  Future<Map<String, dynamic>> _bundleContextualFormsById() async {
    try {
      final raw =
          await rootBundle.loadString('assets/curriculum/letters.json');
      final letters = (json.decode(raw) as Map<String, dynamic>)['letters']
          as List<dynamic>;
      final out = <String, dynamic>{};
      for (final l in letters) {
        final m = l as Map<String, dynamic>;
        final id = m['id'];
        final cf = m['contextualForms'];
        if (id is String && cf != null) out[id] = cf;
      }
      return out;
    } catch (_) {
      return const <String, dynamic>{};
    }
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

  // --- Schema v2 typed reads: exercises / words / units (Plan 07-01) ---------
  //
  // Each follows the EXACT `_loadLettersFromFirestoreOrBundle` shape: one-shot
  // `.get()` of the collection, non-empty → map via the codec, empty/throw →
  // bundled JSON fallback. The `.fromStrings` JSON-override test path keeps the
  // graceful-absence contract (returns empty — no Schema v2 seed in that mode).

  /// Typed `getExercises()` (Plan 07-01) — Firestore-first, bundle fallback.
  ///
  /// The 19 baa configs ship as the bundled seed (`assets/curriculum/exercises.json`,
  /// `signedOff:false`). On the `.fromStrings` test path there is no Schema v2
  /// seed, so this returns empty (graceful absence, D-10 — never throws).
  Future<List<Exercise>> getExercises() async {
    final cached = _exercises;
    if (cached != null) return cached;

    if (_lettersJsonOverride != null) {
      return _exercises = const []; // JSON-override test mode: no exercises seed
    }

    final loaded = await _loadCollectionFirestoreOrBundle(
      collection: 'exercises',
      bundlePath: 'assets/curriculum/exercises.json',
      rootKey: 'exercises',
      fromFirestore: exerciseFromFirestore,
      fromJson: Exercise.fromJson,
    );
    return _exercises = loaded;
  }

  /// Typed `getWords()` (Plan 07-01) — Firestore-first, bundle fallback.
  Future<List<Word>> getWords() async {
    final cached = _words;
    if (cached != null) return cached;

    if (_lettersJsonOverride != null) {
      return _words = const [];
    }

    final loaded = await _loadCollectionFirestoreOrBundle(
      collection: 'words',
      bundlePath: 'assets/curriculum/words.json',
      rootKey: 'words',
      fromFirestore: wordFromFirestore,
      fromJson: Word.fromJson,
    );
    return _words = loaded;
  }

  /// The `LetterUnit` for [letterId] (Plan 07-01) — Firestore-first, bundle
  /// fallback. Returns null when no unit exists for that letter.
  Future<LetterUnit?> getUnit(String letterId) async {
    final units = await _getUnits();
    try {
      return units.firstWhere((u) => u.letterId == letterId);
    } on StateError {
      return null;
    }
  }

  Future<List<LetterUnit>> _getUnits() async {
    final cached = _units;
    if (cached != null) return cached;

    if (_lettersJsonOverride != null) {
      return _units = const [];
    }

    final loaded = await _loadCollectionFirestoreOrBundle(
      collection: 'units',
      bundlePath: 'assets/curriculum/units.json',
      rootKey: 'units',
      fromFirestore: unitFromFirestore,
      fromJson: LetterUnit.fromJson,
    );
    return _units = loaded;
  }

  /// Generic Schema v2 collection loader (mirrors
  /// `_loadLettersFromFirestoreOrBundle`): one-shot Firestore `.get()`,
  /// non-empty → map every doc via [fromFirestore]; empty / error / missing
  /// bundle → parse the bundled `{ <rootKey>: [...] }` JSON via [fromJson].
  /// Never throws — a malformed Firestore payload falls through to the seed
  /// and the practice path never blocks (T-07-01-03).
  Future<List<T>> _loadCollectionFirestoreOrBundle<T>({
    required String collection,
    required String bundlePath,
    required String rootKey,
    required T Function(Map<String, dynamic>) fromFirestore,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final snap = await _firestore.collection(collection).get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => fromFirestore(d.data())).toList();
      }
    } catch (_) {
      // network/permission/cold-first-run → fall through to the bundle.
    }
    try {
      final raw = await rootBundle.loadString(bundlePath);
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final rawList = decoded[rootKey] as List<dynamic>? ?? const [];
      return rawList
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }
}

@Riverpod(keepAlive: true)
CurriculumRepository curriculumRepository(Ref ref) {
  return CurriculumRepository();
}
