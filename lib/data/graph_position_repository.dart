// Plan 15-04 — Drift implementation of GraphPositionRepository (DYN-02 / D-08).
//
// The durable resume cursor for the dynamic baa unit: it persists the child's
// graph position (current node + cleared competencies/tiers) so re-entering the
// unit after an app restart restores exactly where they left off. The server
// stays stateless (COPPA posture) — this on-device state is the ONLY resume
// source. Plan 15-05 reads it to drive the selection flow and replay the
// trajectory into the FACTS.
//
// SECURITY (T-15-04-ID): delegates to AppDatabase.getPosition/setPosition which
// persist ONLY ids/timestamps — the current exercise id + derived competency/tier
// id lists. Stroke points / Offsets / child names are never passed here and never
// stored. The competency/tier lists are pure non-PII string-lists.

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'graph_position_repository.g.dart';

/// The child's durable position in a letter's curriculum graph — the non-PII
/// resume cursor (mirrors `GraphPosition` in lib/curriculum/curriculum_graph_walker.dart,
/// the value type the walker reads). Pure ids: the current exercise plus the
/// cleared competencies/tiers; no child name, no geometry.
///
/// Defined HERE (not in app_database.dart) so the Drift accessors stay
/// primitive-typed and there is no circular import between the repo and the DB.
class GraphPosition {
  const GraphPosition({
    required this.letterId,
    required this.currentExerciseId,
    this.clearedCompetencies = const [],
    this.clearedTiers = const [],
  });

  /// The letter family this position belongs to (e.g. `baa`).
  final String letterId;

  /// The exercise the child is currently on (the walk cursor), or null at the
  /// graph root before any node has been entered.
  final String? currentExerciseId;

  /// The competency ids the child has already cleared (forward-progress state).
  final List<String> clearedCompetencies;

  /// The إملاء tiers the child has already cleared (ramp-progress state).
  final List<String> clearedTiers;
}

/// Reads/writes the durable [GraphPosition] for a letter. A letter the child has
/// never started reads as null (clean default — start at the graph root).
abstract class GraphPositionRepository {
  /// The persisted position for [letterId], or null if never started.
  Future<GraphPosition?> getPosition(String letterId);

  /// Write (or overwrite) the position.
  Future<void> setPosition(GraphPosition position);
}

/// Drift-backed implementation of [GraphPositionRepository].
///
/// Thin delegation layer: all SQL is in [AppDatabase] (mirrors
/// [DriftProgressRepository]). The only logic here is mapping the persisted
/// JSON-encoded competency/tier lists to/from the [GraphPosition] value type.
class DriftGraphPositionRepository implements GraphPositionRepository {
  const DriftGraphPositionRepository(this._db);
  final AppDatabase _db;

  @override
  Future<GraphPosition?> getPosition(String letterId) async {
    final row = await _db.getPosition(letterId);
    if (row == null) return null;
    return GraphPosition(
      letterId: row.letterId,
      currentExerciseId: row.currentExerciseId,
      clearedCompetencies: _decodeStringList(row.clearedCompetencies),
      clearedTiers: _decodeStringList(row.clearedTiers),
    );
  }

  @override
  Future<void> setPosition(GraphPosition position) => _db.setPosition(
        letterId: position.letterId,
        currentExerciseId: position.currentExerciseId,
        clearedCompetencies: position.clearedCompetencies,
        clearedTiers: position.clearedTiers,
      );

  /// Decode a JSON-encoded `List<String>` text column back into a list,
  /// defaulting to const [] on any malformed/empty value (never throws).
  static List<String> _decodeStringList(String encoded) {
    if (encoded.isEmpty) return const [];
    final decoded = jsonDecode(encoded);
    if (decoded is! List) return const [];
    return [for (final e in decoded) e.toString()];
  }
}

/// Riverpod provider for [GraphPositionRepository] — keepAlive mirrors the
/// appDatabaseProvider / progressRepositoryProvider pattern (D-11).
@Riverpod(keepAlive: true)
GraphPositionRepository graphPositionRepository(Ref ref) =>
    DriftGraphPositionRepository(ref.watch(appDatabaseProvider));
