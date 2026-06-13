// Pure-Dart export helper for the dev authoring screen (D-02, plan 02.1-04).
//
// Turns the owner's traced + tagged strokes into a normalized `referenceStrokes`
// JSON fragment, shaped exactly like an entry in assets/curriculum/letters.json,
// ready to paste in. Pure Dart — NO Flutter widget imports — so the whole
// normalize/serialize path is unit-testable and reusable.
//
// Normalization (STROKE-REFERENCE.md §5): ALL strokes are normalized TOGETHER
// against the combined bounding box of every point, so relative positions (e.g.
// a dot sitting below a body stroke) are preserved. Output coordinates are 0..1
// and the fragment passes the D-04 validator (stroke_validation.dart) when the
// trace is a real open centerline.
//
// SECURITY (T-02.1-06 / T-01-05): this helper never logs, prints, or persists
// any point data — it only transforms in-memory values and returns a String.

import 'dart:convert';

import '../core/strokes/stroke_normalization.dart';
import '../models/letter.dart';

/// One stroke as captured by the authoring screen, BEFORE normalization.
///
/// [points] are raw local coordinates in any space (the screen passes pixel
/// coordinates from its capture canvas); `[x, y]` pairs. The export normalizes
/// them. A `type == "dot"` stroke carries exactly one point.
class CapturedStroke {
  final int order;
  final String label;
  final String type; // line | curve | dot
  final String direction; // topToBottom | bottomToTop | leftToRight | rightToLeft | tap
  final List<List<double>> points;

  const CapturedStroke({
    required this.order,
    required this.label,
    required this.type,
    required this.direction,
    required this.points,
  });
}

/// Normalizes all [strokes] together (combined bbox) into validator-shaped
/// [StrokeSpec]s, ordered by their `order` field.
///
/// The combined-bbox math itself lives in the shared
/// [normalizeStrokesToUnitBox] core (lib/core/strokes/stroke_normalization.dart)
/// — this adapter just orders the strokes, delegates the point math, and
/// reattaches the StrokeSpec metadata. No bbox math is re-derived here.
List<StrokeSpec> normalizeToStrokeSpecs(List<CapturedStroke> strokes) {
  if (strokes.isEmpty) return const <StrokeSpec>[];
  final ordered = [...strokes]..sort((a, c) => a.order.compareTo(c.order));
  // Delegate the combined-bbox normalization to the shared core (Pitfall 2).
  final normalized =
      normalizeStrokesToUnitBox(ordered.map((s) => s.points).toList());
  return <StrokeSpec>[
    for (var i = 0; i < ordered.length; i++)
      StrokeSpec(
        order: ordered[i].order,
        label: ordered[i].label,
        type: ordered[i].type,
        direction: ordered[i].direction,
        points: normalized[i],
      ),
  ];
}

/// Builds the normalized `referenceStrokes` JSON fragment (a pretty-printed JSON
/// array of `{order, label, type, points, direction}`) ready to paste into
/// letters.json. Returns `[]` for no strokes.
String exportReferenceStrokesJson(List<CapturedStroke> strokes) {
  final specs = normalizeToStrokeSpecs(strokes);
  final list = specs
      .map((s) => <String, dynamic>{
            'order': s.order,
            'label': s.label,
            'type': s.type,
            'points': s.points,
            'direction': s.direction,
          })
      .toList();
  return const JsonEncoder.withIndent('  ').convert(list);
}

// ── Labeled-sample capture (D-02 calibration mode, Plan 04-05) ───────────────

/// Serializes a LABELED multi-stroke calibration fixture — NOT the
/// `referenceStrokes` fragment. The shape mirrors `calibration_fixtures.dart`'s
/// `LabeledSample`:
/// `{ "letterId": ..., "label": ..., "strokes": List<List<List<double>>> }`.
///
/// [specs] are already whole-letter combined-bbox-normalized (the caller runs
/// [normalizeToStrokeSpecs] — the same Pitfall-2 normalization the orchestrator's
/// dot-position check uses), so the exported fixture lives in the exact 0..1
/// coordinate space the real `scoreLetter` consumes. Returns an empty-strokes
/// object for no strokes.
///
/// SECURITY (T-04-11 / T-01-05): only labeled fixture coordinates (intended test
/// data) are produced — no name, no age, no PII — and nothing is logged,
/// persisted, or transmitted here; the helper only returns a String.
String exportLabeledFixtureJson({
  required String letterId,
  required String label,
  required List<StrokeSpec> specs,
}) {
  // A labeled fixture carries the whole letter's strokes as a bare
  // List<List<List<double>>> (per stroke → per point → [x, y]) — the exact type
  // scoreLetter takes as its childStrokes argument.
  final strokeLists = specs.map((s) => s.points).toList();
  final fixture = <String, dynamic>{
    'letterId': letterId,
    'label': label,
    'strokes': strokeLists,
  };
  return const JsonEncoder.withIndent('  ').convert(fixture);
}
