import '../../models/letter.dart';

/// One source of truth for the reference geometry (S1-04) — pure Dart, no
/// `dart:ui`.
///
/// `ReferencePath.resolve` turns a letter's authored [StrokeSpec]s into the
/// ordered point data that the dotted guide, the stroke-order animation, and
/// the geometric scorer ALL consume. Because every consumer resolves through
/// this one function, by construction:
///
///   authored path == guide path == animation path == scored path.
///
/// On correct authored *centerline* data this is the IDENTITY: it returns the
/// authored points in stroke (draw) order, unchanged. There is deliberately no
/// outline→centerline derivation step here.
///
/// This SUPERSEDES Phase-3 research question Q1 (see
/// `.planning/phases/03-trace-one-letter-end-to-end/03-RESEARCH.md`, the
/// "derive-from-outline" option). Phase 02.1 re-authors letters as correct
/// centerlines — gated by `stroke_validation.dart` — so resolution collapses to
/// identity and the derive-from-outline path is abandoned. If `resolve` ever
/// returned a raw glyph outline, the animation pen-tip would trace *around* the
/// letter instead of writing it; keeping this an identity over validated
/// centerlines makes that impossible.
///
/// Phase 3 wraps the returned points into a `dart:ui` `Path` for `PathMetric`;
/// that UI concern stays out of this pure-Dart layer.
///
/// `type` IS DELIBERATELY NOT CARRIED HERE (plan 06-10). `resolve` is
/// point-geometry only — the scorer's source of truth — and its signature
/// `List<List<List<double>>>` is depended on by the scorer and every existing
/// caller. Dot detection for RENDERING (a `type == "dot"` stroke must paint a
/// calm ink circle, and must be kept out of the polyline length math because a
/// single-point dot has no length) reads `StrokeSpec.type` DIRECTLY in the
/// Watch-animation and Trace-guide painters
/// (`stroke_order_animation.dart` / `stroke_canvas.dart`).
///
/// Do NOT "fix" the dot bug by threading `type` through `resolve` or changing
/// its return type — that would break the scorer's contract. The dot fix lives
/// in the typed-`StrokeSpec` painter path, by design (threat T-06-10-01).
class ReferencePath {
  const ReferencePath._();

  /// Resolves [strokes] into ordered point lists for the guide/animation/scorer.
  ///
  /// Returns one entry per stroke, ordered by the stroke's `order` field
  /// (ascending = draw order), each entry being that stroke's `[x, y]` points
  /// in their authored order. Points are deep-copied so callers cannot mutate
  /// the source [StrokeSpec] data. Deterministic: the same input always yields
  /// an equal result.
  static List<List<List<double>>> resolve(List<StrokeSpec> strokes) {
    final ordered = [...strokes]..sort((a, b) => a.order.compareTo(b.order));
    return ordered
        .map((stroke) =>
            stroke.points.map((p) => <double>[p[0], p[1]]).toList())
        .toList();
  }
}
