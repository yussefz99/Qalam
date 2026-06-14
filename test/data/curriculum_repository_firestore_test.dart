import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/data/firestore_curriculum_codec.dart';

/// Firestore-path tests for `CurriculumRepository` (Plan 06.1-04).
///
/// These exercise the LIVE read path via a `FakeFirebaseFirestore` injected
/// through the `.withFirestore` seam (Plan 04 Task 1). The repository reads
/// Firestore-first with a one-shot `.get()`, falls back to the bundled
/// `assets/curriculum/*.json` on a cold/empty/throwing Firestore (D-02), runs
/// `validateReferenceStrokes` over whichever source won (D-05), and serves the
/// validated result from the kept-alive in-memory cache.
///
/// Points are seeded in Firestore's `{x,y}` shape via the shared codec
/// (`letterToFirestoreMap` / `lessonToFirestoreMap` / `metaToleranceRampToFirestore`)
/// so the fake mirrors a real seeded project (Pitfall 1 nested-array workaround).

/// A minimal valid alif letter (one real vertical stroke), JSON-shaped
/// ([x,y] points) — encoded to Firestore shape before seeding.
Map<String, dynamic> _alifJson() => <String, dynamic>{
      'id': 'alif',
      'char': 'ا',
      'name': {'ar': 'اَلِف', 'display': 'Alif'},
      'introOrder': 1,
      'forms': {'isolated': 'ا', 'initial': 'ا', 'medial': 'ا', 'final': 'ا'},
      'referenceStrokes': [
        {
          'order': 1,
          'label': 'vertical_stroke',
          'type': 'line',
          'points': [
            [0.5, 0.191],
            [0.5, 0.5],
            [0.501, 0.798],
          ],
          'direction': 'topToBottom',
        }
      ],
      'cleanRepsToAdvance': 3,
      'commonMistakes': [],
      'mistakesStatus': 'authored',
      'signedOff': true,
      'audio': {'letter': null, 'examples': []},
    };

/// A skeleton (placeholder) letter — empty strokes, signedOff:false (Pitfall 6).
Map<String, dynamic> _skeletonJson() => <String, dynamic>{
      'id': 'baa',
      'char': 'ب',
      'name': {'ar': 'بَاء', 'display': 'Baa'},
      'introOrder': 2,
      'forms': {'isolated': 'ب', 'initial': 'ب', 'medial': 'ب', 'final': 'ب'},
      'referenceStrokes': [],
      'cleanRepsToAdvance': 3,
      'commonMistakes': [],
      'mistakesStatus': 'placeholder',
      'signedOff': false,
      'audio': {'letter': null, 'examples': []},
    };

/// A letter whose single non-dot stroke is a CLOSED loop — the exact shape the
/// load-time D-04 guard must reject, now seeded into Firestore to prove the
/// validator runs over the Firestore source too (D-05).
Map<String, dynamic> _loopLetterJson() => <String, dynamic>{
      'id': 'alif',
      'char': 'ا',
      'name': {'ar': 'x', 'display': 'Alif'},
      'introOrder': 1,
      'forms': {'isolated': 'ا', 'initial': 'ا', 'medial': 'ا', 'final': 'ا'},
      'referenceStrokes': [
        {
          'order': 1,
          'label': 'vertical_stroke',
          'type': 'line',
          'points': [
            [0.1, 0.1],
            [0.9, 0.1],
            [0.5, 0.9],
            [0.1, 0.1],
          ],
          'direction': 'topToBottom',
        }
      ],
      'cleanRepsToAdvance': 3,
      'commonMistakes': [],
      'mistakesStatus': 'authored',
      'signedOff': true,
      'audio': {'letter': null, 'examples': []},
    };

Map<String, dynamic> _lesson01Json() => <String, dynamic>{
      'id': 'lesson_01',
      'order': 1,
      'title': {'display': 'Lesson 1'},
      'items': [
        {'type': 'letter', 'ref': 'alif'}
      ],
      'unlock': {'requires': <String>[], 'passRule': 'allItemsPassed'},
    };

/// Seed letters/lessons/meta into the fake using the shared codec (so points
/// land as Firestore-shaped {x,y} maps).
Future<void> _seed(
  FakeFirebaseFirestore db, {
  required List<Map<String, dynamic>> letters,
  List<Map<String, dynamic>>? lessons,
  List<String>? ramp,
}) async {
  for (final l in letters) {
    await db.collection('letters').doc(l['id'] as String).set(
          letterToFirestoreMap(l),
        );
  }
  for (final l in (lessons ?? [_lesson01Json()])) {
    await db.collection('lessons').doc(l['id'] as String).set(
          lessonToFirestoreMap(l),
        );
  }
  if (ramp != null) {
    await db
        .collection('meta')
        .doc('toleranceRamp')
        .set(metaToleranceRampToFirestore(ramp));
  }
}

/// A FakeFirebaseFirestore subclass whose `collection().get()` throws — proves
/// the cold/error path falls back to the bundle (D-02), not just the empty path.
class _ThrowingFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
      message: 'simulated cold/no-network first run',
    );
  }
}

void main() {
  group('CurriculumRepository — Firestore path (Plan 06.1-04)', () {
    test('Test 1: Firestore present → getLetters() returns the seeded letters '
        'and getDefaultToleranceRamp() returns the seeded ramp', () async {
      final db = FakeFirebaseFirestore();
      await _seed(
        db,
        letters: [_alifJson(), _skeletonJson()],
        ramp: ['loose', 'strict'],
      );
      final repo = CurriculumRepository.withFirestore(db);

      final letters = await repo.getLetters();
      final ramp = await repo.getDefaultToleranceRamp();

      // Firestore path won — exactly the two seeded letters, sorted by introOrder.
      expect(letters.map((l) => l.id), ['alif', 'baa']);
      expect(letters.first.referenceStrokes.single.points.first, [0.5, 0.191]);
      expect(ramp, ['loose', 'strict']);
    });

    test('Test 2: cold fallback → empty Firestore yields the 28 BUNDLED letters '
        '(offline cold-first-run floor, D-02)', () async {
      final db = FakeFirebaseFirestore(); // nothing seeded → empty
      final repo = CurriculumRepository.withFirestore(db);

      final letters = await repo.getLetters();

      expect(letters.length, 28);
      expect(letters.first.id, 'alif'); // bundle sorted by introOrder
    });

    test('Test 2b: throwing Firestore also falls back to the bundle (D-02)',
        () async {
      final repo = CurriculumRepository.withFirestore(_ThrowingFirestore());

      final letters = await repo.getLetters();

      expect(letters.length, 28);
      expect(letters.first.id, 'alif');
    });

    test('Test 3: validator runs on the Firestore source → a closed-loop stroke '
        'makes getLetters() throw, cache stays unpoisoned (D-05)', () async {
      final db = FakeFirebaseFirestore();
      await _seed(db, letters: [_loopLetterJson()]);
      final repo = CurriculumRepository.withFirestore(db);

      // First call: the D-04 guard fires on the Firestore source.
      await expectLater(
        repo.getLetters(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('closed outline loop'),
        )),
      );

      // Cache must stay null on throw — a SECOND call re-runs the guard and
      // re-throws (the invalid stroke never reaches the scorer / cache).
      await expectLater(
        repo.getLetters(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('closed outline loop'),
        )),
      );
    });

    test('Test 4: round-trip parity → a Firestore-encoded bundled alif reads '
        'back deep-equal to the bundle-parsed alif (D-08 at repo layer)',
        () async {
      // Parse the REAL bundled alif via the JSON-override path for the baseline.
      final bundleLetters = File('assets/curriculum/letters.json')
          .readAsStringSync();
      final bundleLessons = File('assets/curriculum/lessons.json')
          .readAsStringSync();
      final bundleRepo =
          CurriculumRepository.fromStrings(bundleLetters, bundleLessons);
      final bundleAlif = (await bundleRepo.getLetters())
          .firstWhere((l) => l.id == 'alif');

      // Encode that same real alif JSON into Firestore and read it back.
      final realAlifJson = (json.decode(bundleLetters)
          as Map<String, dynamic>)['letters'] as List<dynamic>;
      final alifMap = realAlifJson
          .cast<Map<String, dynamic>>()
          .firstWhere((l) => l['id'] == 'alif');
      final db = FakeFirebaseFirestore();
      await _seed(db, letters: [alifMap]);
      final fsRepo = CurriculumRepository.withFirestore(db);
      final fsAlif =
          (await fsRepo.getLetters()).firstWhere((l) => l.id == 'alif');

      // Deep field-by-field parity — no loss across the Firestore boundary.
      expect(fsAlif.id, bundleAlif.id);
      expect(fsAlif.char, bundleAlif.char);
      expect(fsAlif.introOrder, bundleAlif.introOrder);
      expect(fsAlif.cleanRepsToAdvance, bundleAlif.cleanRepsToAdvance);
      expect(fsAlif.signedOff, bundleAlif.signedOff);
      expect(fsAlif.referenceStrokes.length,
          bundleAlif.referenceStrokes.length);
      for (var i = 0; i < bundleAlif.referenceStrokes.length; i++) {
        final a = fsAlif.referenceStrokes[i];
        final b = bundleAlif.referenceStrokes[i];
        expect(a.order, b.order);
        expect(a.label, b.label);
        expect(a.type, b.type);
        expect(a.direction, b.direction);
        expect(a.points, b.points); // [x,y] rebuilt losslessly
      }
      expect(fsAlif.commonMistakes.length, bundleAlif.commonMistakes.length);
    });

    test('Test 5a: ramp via meta doc → getDefaultToleranceRamp() returns the '
        'seeded ramp (D-07)', () async {
      final db = FakeFirebaseFirestore();
      await _seed(db, letters: [_alifJson()], ramp: ['loose', 'strict']);
      final repo = CurriculumRepository.withFirestore(db);

      final ramp = await repo.getDefaultToleranceRamp();

      expect(ramp, ['loose', 'strict']);
    });

    test('Test 5b: absent meta doc → ramp falls back to the bundle ramp '
        '(then the decided default), never throws (Pitfall 5)', () async {
      // Letters seeded (Firestore path wins for letters) but NO meta doc and NO
      // lessons override → ramp must defensively fall back. With letters in
      // Firestore but lessons absent, lessons fall back to the bundle, whose
      // defaultToleranceRamp is [loose, normal, strict].
      final db = FakeFirebaseFirestore();
      await _seed(db, letters: [_alifJson()]); // seeds default lesson_01, no ramp
      final repo = CurriculumRepository.withFirestore(db);

      final ramp = await repo.getDefaultToleranceRamp();

      // No meta doc → bundle ramp (or decided default if bundle absent).
      expect(ramp, ['loose', 'normal', 'strict']);
    });
  });
}
