// Plan 18-06 — ChildModelRepository (D-16) + arc/evidence repository bridges.
//
// Proves the returning-child memory plumbing:
//   • boot reads the Drift mirror synchronously (offline-safe, last-known);
//   • a background one-shot Firestore .get() write-throughs the mirror;
//   • a permission-denied / offline error keeps the last-known mirror (never throws);
//   • the arc repo maps the Drift ArcStateRow ↔ the pure ArcState;
//   • the evidence repo aggregates the {letter,criterion,pass,fail} digest + clears.
//
// The ChildModelRepository is exercised through the `.withFirestore` seam against a
// `FakeFirebaseFirestore` (happy paths) and a throwing mocktail mock (error path).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qalam/curriculum/arc_state.dart';
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/arc_state_repository.dart';
import 'package:qalam/data/child_model_repository.dart';
import 'package:qalam/data/evidence_repository.dart';

class _ThrowingFirestore extends Mock implements FirebaseFirestore {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ChildModelRepository — Firestore-first, Drift-mirror fallback (D-16)', () {
    test('cold boot with no mirror reads the neutral empty snapshot (offline-safe)',
        () async {
      final repo = ChildModelRepository.withFirestore(db, FakeFirebaseFirestore());

      final snapshot = await repo.get('parent-uid');

      expect(snapshot.strengths, isEmpty);
      expect(snapshot.struggles, isEmpty);
      expect(snapshot.perCriterion, isEmpty);
    });

    test('refresh write-throughs a non-empty child_models/{uid} doc into the mirror',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('child_models').doc('parent-uid').set(<String, Object?>{
        'strengths': ['baa/shape'],
        'struggles': ['baa/dot'],
        'perCriterion': {'baa/dot': 0.18, 'baa/shape': 0.92},
        'schemaVersion': 1,
      });
      final repo = ChildModelRepository.withFirestore(db, fake);

      // Before refresh: cold (empty). After a fire-and-forget-style refresh: the
      // compiled profile is mirrored and the next boot read returns it.
      expect((await repo.get('parent-uid')).struggles, isEmpty);
      await repo.refresh('parent-uid');

      final mirrored = await repo.get('parent-uid');
      expect(mirrored.struggles, contains('baa/dot'));
      expect(mirrored.strengths, contains('baa/shape'));
      expect(mirrored.perCriterion['baa/shape'], closeTo(0.92, 1e-9));
    });

    test('refresh against a MISSING doc keeps the last-known mirror (offline-safe)',
        () async {
      final fake = FakeFirebaseFirestore();
      // Seed a last-known mirror directly.
      await db.setProfileMirror(
        uid: 'parent-uid',
        strengths: const ['baa/shape'],
        struggles: const ['baa/dot'],
        perCriterion: const {'baa/dot': 0.2},
      );
      final repo = ChildModelRepository.withFirestore(db, fake);

      // The Firestore doc does not exist — refresh must not wipe the mirror.
      await repo.refresh('parent-uid');

      final kept = await repo.get('parent-uid');
      expect(kept.struggles, contains('baa/dot'),
          reason: 'a missing doc keeps the last-known mirror');
    });

    test('refresh NEVER throws and keeps the mirror on a permission-denied error',
        () async {
      final throwing = _ThrowingFirestore();
      when(() => throwing.collection(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await db.setProfileMirror(
        uid: 'parent-uid',
        strengths: const [],
        struggles: const ['baa/dot'],
        perCriterion: const {},
      );
      final repo = ChildModelRepository.withFirestore(db, throwing);

      // Must complete without throwing (the practice path never blocks/crashes).
      await expectLater(repo.refresh('parent-uid'), completes);
      final kept = await repo.get('parent-uid');
      expect(kept.struggles, contains('baa/dot'),
          reason: 'a permission-denied refresh keeps the last-known mirror');
    });
  });

  group('ArcStateRepository — Drift ArcStateRow <-> pure ArcState (D-12)', () {
    test('an entered arc round-trips its observable resume cursor', () async {
      final repo = ArcStateRepository(db);

      expect(await repo.getArc('baa'), isNull,
          reason: 'no stored arc reads as null (clean default)');

      await repo.setArc(
        'baa',
        ArcState.enter(
          targetCriterion: 'dot',
          exerciseToRetry: 'baa.writeWord.copy',
          failStreak: 2,
        ).toStepDown(),
      );

      final restored = await repo.getArc('baa');
      expect(restored, isNotNull);
      expect(restored!.active, isTrue);
      expect(restored.step, 'stepDown');
      expect(restored.targetCriterion, 'dot');
      expect(restored.exerciseToRetry, 'baa.writeWord.copy');
    });
  });

  group('EvidenceRepository — {letter,criterion,pass,fail} digest + rollup cap (D-14)',
      () {
    test('aggregates unsynced evidence into fixed-vocabulary digest rows, then clears',
        () async {
      final repo = EvidenceRepository(db);

      // dot: 2 pass / 1 fail; shape: 1 fail — appended in order.
      await db.appendEvidence(letterId: 'baa', criterion: 'dot', passed: true, source: 'letter');
      await db.appendEvidence(letterId: 'baa', criterion: 'dot', passed: true, source: 'letter');
      await db.appendEvidence(letterId: 'baa', criterion: 'dot', passed: false, source: 'letter');
      await db.appendEvidence(letterId: 'baa', criterion: 'shape', passed: false, source: 'word');

      final digest = await repo.pendingDigest();

      expect(digest.rows, hasLength(2));
      final dotRow = digest.rows.firstWhere((r) => r['criterion'] == 'dot');
      expect(dotRow['letter'], 'baa');
      expect(dotRow['pass'], 2);
      expect(dotRow['fail'], 1);
      final shapeRow = digest.rows.firstWhere((r) => r['criterion'] == 'shape');
      expect(shapeRow['pass'], 0);
      expect(shapeRow['fail'], 1);
      expect(digest.sourceIds, hasLength(4));

      // Rollup cap: after the digest syncs, the synced rows are cleared.
      await repo.clearSynced(digest.sourceIds);
      final drained = await repo.pendingDigest();
      expect(drained.isEmpty, isTrue,
          reason: 'cleared evidence caps on-device growth (T-18-03-03)');
    });
  });
}
