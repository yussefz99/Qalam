// Plan 18-06 — the remediation-arc resume repository (Req 4 / D-12).
//
// The pure [ArcState] (lib/curriculum/arc_state.dart, 18-04) is the state of the
// confidence-rebuilding remediation arc; the Drift `ArcStateRows` table (18-03)
// persists it per letter so a mid-arc force-quit resumes where it left off (D-12).
// This thin repository is the BRIDGE between the two — it maps the raw Drift
// `ArcStateRow` ↔ the pure `ArcState`, keeping the DB accessors primitive-typed and
// free of any `lib/curriculum` import (the 15-04 type-cycle precedent).
//
// NOTE: the 18-03 `ArcStateRows` table persists the OBSERVABLE arc position
// (`active` / `step` / `targetCriterion` / `exerciseToRetry`) — the resume cursor —
// but NOT the in-session `failStreak` / `attempts` counters. So a resumed arc
// restores its step + target + original exercise (where the child was), while the
// session counters restart at 0 (they are re-accumulated within the new session by
// SelectionPolicy). This is the faithful bridge for the 18-03 schema.
//
// SECURITY (T-18-03-01): only ids / a bool / fixed-vocabulary step & criterion ids
// cross here — never a stroke point or PII. Values are never logged.

import 'package:qalam/curriculum/arc_state.dart';
import 'app_database.dart';

/// Reads/writes the durable [ArcState] for a letter's remediation arc. A letter
/// with no active (or last-known) arc reads as null (clean default — no arc).
class ArcStateRepository {
  const ArcStateRepository(this._db);
  final AppDatabase _db;

  /// The persisted arc for [letterId], or null if none. Maps the raw Drift
  /// `ArcStateRow` into the pure [ArcState]; the un-persisted `failStreak` /
  /// `attempts` counters default to 0 (re-accumulated in-session).
  Future<ArcState?> getArc(String letterId) async {
    final row = await _db.getArcStateRow(letterId);
    if (row == null) return null;
    return ArcState(
      active: row.active,
      stepValue: _stepFromName(row.step),
      targetCriterion: row.targetCriterion,
      exerciseToRetry: row.exerciseToRetry,
    );
  }

  /// Write (or overwrite) the arc for [letterId]. Persists only the observable
  /// resume cursor (`active` / `step` / `targetCriterion` / `exerciseToRetry`).
  Future<void> setArc(String letterId, ArcState arc) => _db.setArcStateRow(
        letterId: letterId,
        active: arc.active,
        step: arc.step,
        targetCriterion: arc.targetCriterion,
        exerciseToRetry: arc.exerciseToRetry,
      );

  /// Map a persisted step NAME string back to the [ArcStep] enum, defaulting to
  /// [ArcStep.entry] on any unknown value (never throws — a malformed row resumes
  /// warm at the arc entry).
  static ArcStep _stepFromName(String name) => ArcStep.values.firstWhere(
        (s) => s.name == name,
        orElse: () => ArcStep.entry,
      );
}
