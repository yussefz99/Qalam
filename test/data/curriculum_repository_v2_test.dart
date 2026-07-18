import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/models/exercise.dart';

/// Schema v2 repository-path tests (Plan 07-01 Task 2).
///
/// Proves the typed `getExercises` / `getWords` / `getUnit` read Firestore-first
/// via the injected `FakeFirebaseFirestore` (`.withFirestore` seam) and fall
/// back to the bundled `assets/curriculum/{exercises,words,units}.json` seed
/// when Firestore is empty (cold/offline first run, D-02 / T-07-01-03). The
/// bundle seed is the 19 baa configs; the baa unit orders 6 sections.

Map<String, dynamic> _exerciseDoc(String id) => <String, dynamic>{
      'id': id,
      'type': 'traceLetter',
      'skill': 'formation',
      'prompt': [
        {'kind': 'say', 'line': 'seeded line'}
      ],
      'surface': {'mode': 'trace', 'unit': 'glyph', 'guideForm': 'isolated'},
      'expected': {
        'glyph': {'char': 'ب', 'form': 'isolated'}
      },
      'check': 'glyph',
      'feedback': {'pass': 'seeded pass'},
      'signedOff': false,
    };

Map<String, dynamic> _wordDoc(String id, String text) => <String, dynamic>{
      'id': id,
      'text': text,
      'audio': 'word.$id',
      'image': 'img.$id',
      'gloss': {'en': id},
      'letters': ['baa'],
    };

Map<String, dynamic> _unitDoc(String letterId) => <String, dynamic>{
      'letterId': letterId,
      'sections': [
        {
          'id': 'meet',
          'exercises': ['$letterId.teachCard.meet']
        }
      ],
    };

void main() {
  group('Schema v2 repository — Firestore-first path', () {
    test('getExercises() returns the seeded Firestore exercises', () async {
      final db = FakeFirebaseFirestore();
      await db
          .collection('exercises')
          .doc('seeded.one')
          .set(exerciseToFirestoreOrRaw(_exerciseDoc('seeded.one')));
      await db
          .collection('exercises')
          .doc('seeded.two')
          .set(exerciseToFirestoreOrRaw(_exerciseDoc('seeded.two')));
      final repo = CurriculumRepository.withFirestore(db);

      final exercises = await repo.getExercises();

      expect(exercises, hasLength(2));
      expect(exercises.map((e) => e.id), containsAll(['seeded.one', 'seeded.two']));
      expect(exercises.first, isA<Exercise>());
    });

    test('getWords() returns the seeded Firestore words', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('words').doc('baab').set(_wordDoc('baab', 'باب'));
      final repo = CurriculumRepository.withFirestore(db);

      final words = await repo.getWords();

      expect(words, hasLength(1));
      expect(words.first.text, 'باب');
    });

    test('getUnit() returns the seeded Firestore unit', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('units').doc('baa').set(_unitDoc('baa'));
      final repo = CurriculumRepository.withFirestore(db);

      final unit = await repo.getUnit('baa');

      expect(unit, isNotNull);
      expect(unit!.letterId, 'baa');
      expect(unit.sections.single.id, 'meet');
    });
  });

  group('Schema v2 repository — bundled-seed fallback (empty Firestore)', () {
    test('getExercises() returns the bundled baa+taa+alif configs as Exercises',
        () async {
      final db = FakeFirebaseFirestore(); // nothing seeded → bundle fallback
      final repo = CurriculumRepository.withFirestore(db);

      final exercises = await repo.getExercises();

      // Phase 8 demo: baa (19) + taa (19) + alif (10) + baa micro-drills (3, Plan 18-02)
      // + the 19-05 micro-drill re-add config (dc45ba6) = 52.
      expect(exercises, hasLength(52));
      expect(exercises, everyElement(isA<Exercise>()));
      // All three demo letters' CORE configs are signed off. Carve-outs:
      // the baa micro-drill enrichment (dot/bowl/start, Plan 18-02) and the
      // 19-05 kitaab→baab rewrite (D-11) are signedOff:false until the mother
      // signs them (18-11 HUMAN-UAT gate / 19-REVIEW-PACKET.md).
      expect(
          exercises
              .where((e) =>
                  e.type != 'microDrill' && e.id != 'baa.connectWord.kitaab')
              .every((e) => e.signedOff == true),
          isTrue);
      expect(exercises.map((e) => e.id),
          containsAll(['baa.teachCard.meet', 'taa.teachCard.meet', 'alif.teachCard.meet']));
      // The teachCard config parses with null assessed fields.
      final teachCard = exercises.firstWhere((e) => e.type == 'teachCard');
      expect(teachCard.surface, isNull);
      expect(teachCard.check, isNull);
    });

    test('getWords() returns the bundled vocab for the three demo letters',
        () async {
      final db = FakeFirebaseFirestore();
      final repo = CurriculumRepository.withFirestore(db);

      final words = await repo.getWords();

      // baa (باب/بطة/حليب) + taa (تاج/توت/بيت) + alif (أسد/أم); باب shared.
      expect(words, hasLength(8));
      expect(words.map((w) => w.text),
          containsAll(['باب', 'بطة', 'حليب', 'تاج', 'توت', 'بيت', 'أسد', 'أم']));
    });

    test('getUnit("baa").sections has the 6 sections in order', () async {
      final db = FakeFirebaseFirestore();
      final repo = CurriculumRepository.withFirestore(db);

      final unit = await repo.getUnit('baa');

      expect(unit, isNotNull);
      expect(unit!.sections.map((s) => s.id).toList(),
          ['meet', 'watchTrace', 'forms', 'words', 'listenWrite', 'mastery']);
      // Every exercise id referenced by the unit exists in the bundled seed.
      final exercises = await repo.getExercises();
      final ids = exercises.map((e) => e.id).toSet();
      for (final section in unit.sections) {
        for (final exId in section.exercises) {
          expect(ids, contains(exId),
              reason: 'unit references unknown exercise $exId');
        }
      }
    });

    test('getUnit() returns null for an unknown letter', () async {
      final db = FakeFirebaseFirestore();
      final repo = CurriculumRepository.withFirestore(db);

      expect(await repo.getUnit('nonexistent'), isNull);
    });
  });

  group('Schema v2 repository — JSON-override path is gracefully empty', () {
    test('.fromStrings yields empty exercises/words/units (no v2 seed)',
        () async {
      final repo = CurriculumRepository.fromStrings(
        '{"letters": []}',
        '{"lessons": []}',
      );

      expect(await repo.getExercises(), isEmpty);
      expect(await repo.getWords(), isEmpty);
      expect(await repo.getUnit('baa'), isNull);
    });
  });
}

/// Exercises carry no nested point arrays, so the Firestore doc shape equals the
/// JSON shape — this is an identity copy, named for symmetry with
/// `letterToFirestoreMap` in the seeding helpers above.
Map<String, dynamic> exerciseToFirestoreOrRaw(Map<String, dynamic> json) =>
    Map<String, dynamic>.from(json);
