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
      // + quick task 260718-il4 (Stage 1 all-letters-live): thaa (19, promoted
      //   from the 18.1 drafts, ALL signedOff:false pending the mother's packet)
      //   = 71.
      // + finalization 2026-07-19: alif.writeLetter.fromPicture (the owner's
      //   alif shrink — "what does أسد start with", draft, signedOff:false) = 72.
      expect(exercises, hasLength(72));
      expect(exercises, everyElement(isA<Exercise>()));
      // Signed-off invariant for the SIGNED-demo core (baa/taa/alif), pinned as
      // an exact unsigned set so drift cannot grow silently. thaa is EXCLUDED
      // here: Stage 1 (260718-il4) promoted it WHOLLY unsigned by owner lock
      // (the mother reviews it via the 18.1 packets), so all 19 thaa configs are
      // signedOff:false BY DESIGN — they are not "drift" in the demo core. The
      // learned-letters lint + graph_asset_parity guard cover thaa; this guard
      // stays scoped to the baa/taa/alif set it was tuned for. Unsigned in that
      // core: the 19-05 kitaab→baab rewrite (D-11, pending sign-off) plus the
      // documented pre-existing alif/baa-final signedOff drift (alif-reference
      // cluster). Micro-drills are carved out separately (18-11 HUMAN-UAT gate).
      // WIDENED by finalization Lane B (e4cadeb, 2026-07-18): the content-
      // integrity pass re-pointed missing art (تاج→تفاح), reworded feedback
      // lines that referenced absent pictures, and wired the alif copy/
      // dictation cards to real audio — every touched config was HONESTLY
      // flipped signedOff:false pending the mother's re-confirmation (each
      // carries an inline `_review` note naming the exact change).
      final unsignedCore = exercises
          .where((e) =>
              e.type != 'microDrill' &&
              e.signedOff != true &&
              !e.id.startsWith('thaa.'))
          .map((e) => e.id)
          .toSet();
      expect(
          unsignedCore,
          equals({
            'baa.connectWord.kitaab',
            'baa.traceLetter.final',
            'alif.traceLetter.isolated',
            'alif.writeLetter.fromSound',
            'alif.writeLetter.writeForm',
            // NOTE (Phase 25 / 25-07, mother's walkthrough 2026-07-20): the alif
            // shrink card + the Lane-B alif flips (alif.writeLetter.fromPicture,
            // alif.teachCard.meet, alif.writeWord.copy, alif.writeWord.dictation)
            // were mother-CONFIRMED and signed (signedOff:true) — so they left the
            // unsigned set. taa.* stay unsigned pending the taa letter-form rework.
            'taa.teachCard.meet',
            'taa.writeLetter.fromPicture',
            'taa.writeWord.copy',
            'taa.writeWord.dictation',
            'taa.writeWord.picture',
            'taa.buildSentence.picture',
          }));
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
