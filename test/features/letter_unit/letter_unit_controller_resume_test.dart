// Phase 18-15 Task 1 — start() RESTORES selection mode from the durable cursor.
//
// Root cause (.planning/debug/resume-position-lost-on-relaunch.md): the durable
// `LetterGraphPosition.currentExerciseId` is persisted AND read back correctly on
// a cold relaunch, but `start()` never re-seeded the session-scoped
// `selectionActive` from it — so every fresh `start()` reset `selectionActive` to
// false and the screen fell back to the legacy `_section` walk (which its own
// coarse `_sectionHintFor` heuristic commonly resolved to section 0 = "Meet").
// That is the owner's "started from scratch" report (UAT T7).
//
// This pins the fix at the CONTROLLER: when the saved cursor is a REAL authored
// graph node, `start()` restores `selectionActive: true` (so the screen re-enters
// presenter mode on that node); a null / stale / unauthored cursor — or a graph
// that will not load — keeps `selectionActive: false` so a truly-fresh child still
// uses the legacy walk (no false resume) and a corrupt id never forces a dead-end
// (T-18-15-01). Never crashes (the never-throw posture holds).
//
// Controller-level (no widget): a ProviderContainer with the durable repo seeded.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/curriculum/child_model_snapshot.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/features/letter_unit/letter_unit_controller.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart';

CurriculumGraph _loadGraph() => CurriculumGraph.fromJson(
      json.decode(
        File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
      ) as Map<String, Object?>,
    );

/// A durable position repo seeded with one [GraphPosition] (or none).
class _StubPositionRepo implements GraphPositionRepository {
  _StubPositionRepo(this._pos);
  GraphPosition? _pos;
  @override
  Future<GraphPosition?> getPosition(String letterId,
          {required int childProfileId}) async =>
      _pos;
  @override
  Future<void> setPosition(GraphPosition position) async => _pos = position;
}

ProviderContainer _container({
  required GraphPositionRepository posRepo,
  bool graphFails = false,
}) {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
  addTearDown(db.close);
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    graphPositionRepositoryProvider.overrideWithValue(posRepo),
    curriculumGraphProvider.overrideWith((ref) async {
      if (graphFails) throw StateError('graph unavailable');
      return _loadGraph();
    }),
    // No Firebase in a unit test — the profile mirror is an empty snapshot.
    childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
      'a saved cursor on a REAL authored node restores selectionActive:true '
      '(the screen re-enters presenter mode on that exact node)', () async {
    final container = _container(
      posRepo: _StubPositionRepo(const GraphPosition(
        childProfileId: 0,
        letterId: 'baa',
        currentExerciseId: 'baa.traceLetter.medial', // a real authored node
        clearedCompetencies: ['recognize'],
        clearedTiers: [],
      )),
    );
    final controller =
        container.read(letterUnitControllerProvider('baa').notifier);
    await controller.start(letterId: 'baa', total: 6);

    final state = container.read(letterUnitControllerProvider('baa'));
    expect(state.selectionActive, isTrue,
        reason: 'a saved real-node cursor restores selection mode on relaunch');
    expect(state.currentExerciseId, 'baa.traceLetter.medial',
        reason: 'the restored cursor is the exact node the child left off on');
  });

  test(
      'a null cursor (never entered a node) keeps selectionActive:false — a fresh '
      'child still uses the legacy walk (no false resume)', () async {
    final container = _container(
      posRepo: _StubPositionRepo(const GraphPosition(
        childProfileId: 0,
        letterId: 'baa',
        currentExerciseId: null, // graph root — never entered a node
      )),
    );
    final controller =
        container.read(letterUnitControllerProvider('baa').notifier);
    await controller.start(letterId: 'baa', total: 6);

    expect(
        container.read(letterUnitControllerProvider('baa')).selectionActive,
        isFalse,
        reason: 'a null cursor is a truly-fresh child — never a false resume');
  });

  test(
      'a stale / unauthored cursor keeps selectionActive:false (T-18-15-01: a '
      'corrupt id degrades to the legacy walk, never a crash / dead-end)',
      () async {
    final container = _container(
      posRepo: _StubPositionRepo(const GraphPosition(
        childProfileId: 0,
        letterId: 'baa',
        currentExerciseId: 'baa.NOT_A_REAL_NODE',
        clearedCompetencies: ['recognize'],
      )),
    );
    final controller =
        container.read(letterUnitControllerProvider('baa').notifier);
    await controller.start(letterId: 'baa', total: 6);

    expect(
        container.read(letterUnitControllerProvider('baa')).selectionActive,
        isFalse,
        reason: 'isAuthored() rejects a non-graph id → no false selection mode');
  });

  test('no saved position (never started) keeps selectionActive:false', () async {
    final container = _container(posRepo: _StubPositionRepo(null));
    final controller =
        container.read(letterUnitControllerProvider('baa').notifier);
    await controller.start(letterId: 'baa', total: 6);

    expect(
        container.read(letterUnitControllerProvider('baa')).selectionActive,
        isFalse);
  });

  test(
      'a graph-load failure degrades to selectionActive:false — never crashes '
      '(the cursor cannot be validated → no false resume)', () async {
    final container = _container(
      graphFails: true,
      posRepo: _StubPositionRepo(const GraphPosition(
        childProfileId: 0,
        letterId: 'baa',
        currentExerciseId: 'baa.traceLetter.medial',
        clearedCompetencies: ['recognize'],
      )),
    );
    final controller =
        container.read(letterUnitControllerProvider('baa').notifier);
    // Must complete without throwing.
    await controller.start(letterId: 'baa', total: 6);

    expect(
        container.read(letterUnitControllerProvider('baa')).selectionActive,
        isFalse,
        reason: 'a graph that will not load cannot validate the cursor → no '
            'false resume, and no crash');
  });
}
