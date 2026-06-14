import '../models/letter.dart';
import '../models/lesson.dart';

/// Shared Firestore curriculum codec — the spine that crosses the Firestore
/// boundary in BOTH directions (D-06 / D-08).
///
/// THE landmine this solves (Pitfall 1): `StrokeSpec.points` is
/// `List<List<double>>` (an array of `[x,y]` pairs), and **Firestore forbids
/// arrays whose elements are themselves arrays**. So on the way *out* (to a
/// Firestore document map) every `[x, y]` pair becomes a `{"x": x, "y": y}`
/// map, and on the way *in* (from a Firestore document map) it rebuilds to
/// `[x, y]`. The exact same transform is mirrored in the Python codec
/// (`tools/firebase/point_codec.py`) so seed / export / read all agree.
///
/// This file is **pure Dart**: it operates on `Map<String, dynamic>` and does
/// NOT import `package:cloud_firestore`, so it stays unit-testable with no
/// Firebase project, emulator, or device. Reads defer to the existing
/// `Letter.fromJson` / `Lesson.fromJson` contracts (type default, nullable
/// audio/tolerances, signedOff, mistakesStatus, defensive ramp parse) — the
/// codec only re-shapes the point representation, never re-implements field
/// parsing.

// ---------------------------------------------------------------------------
// Point codec — the {x,y} <-> [x,y] transform (Pitfall 1)
// ---------------------------------------------------------------------------

/// Encode a list of `[x, y]` pairs to a list of `{"x": x, "y": y}` maps
/// (JSON/bundle shape -> Firestore shape).
List<Map<String, dynamic>> encodePoints(List<dynamic> pairs) {
  return pairs.map((p) {
    final pair = p as List<dynamic>;
    return <String, dynamic>{
      'x': (pair[0] as num).toDouble(),
      'y': (pair[1] as num).toDouble(),
    };
  }).toList();
}

/// Decode a list of `{"x": x, "y": y}` maps back to `[x, y]` pairs
/// (Firestore shape -> JSON/bundle shape). Tolerant of Firestore ints
/// (e.g. `y == 1`) by casting `num -> double`.
List<List<double>> decodePoints(List<dynamic> maps) {
  return maps.map((m) {
    final point = m as Map<String, dynamic>;
    return <double>[
      (point['x'] as num).toDouble(),
      (point['y'] as num).toDouble(),
    ];
  }).toList();
}

// ---------------------------------------------------------------------------
// Letter codec
// ---------------------------------------------------------------------------

/// Build a Firestore document map from a JSON-shaped letter map.
///
/// Copies the letter map field-for-field, rewriting every
/// `referenceStrokes[i].points` element from a 2-element `[x,y]` list to a
/// `{"x": x, "y": y}` map (the nested-array workaround). Accepts either a
/// JSON-decoded letter map or a model-derived map of the same shape.
Map<String, dynamic> letterToFirestoreMap(Map<String, dynamic> jsonLetter) {
  final out = Map<String, dynamic>.from(jsonLetter);

  final rawStrokes = jsonLetter['referenceStrokes'] as List<dynamic>? ?? [];
  out['referenceStrokes'] = rawStrokes.map((s) {
    final stroke = Map<String, dynamic>.from(s as Map<String, dynamic>);
    final rawPoints = stroke['points'] as List<dynamic>? ?? [];
    stroke['points'] = encodePoints(rawPoints);
    return stroke;
  }).toList();

  return out;
}

/// Read a Firestore letter document map into a `Letter`.
///
/// Rewrites each `referenceStrokes[i].points` element from a `{x,y}` map back
/// to a `[x,y]` list, then defers to `Letter.fromJson` so the existing field
/// contract (type default, nullable audio/tolerances, signedOff,
/// mistakesStatus) is reused verbatim — no field parsing is re-implemented.
Letter letterFromFirestore(Map<String, dynamic> doc) {
  final jsonShaped = Map<String, dynamic>.from(doc);

  final rawStrokes = doc['referenceStrokes'] as List<dynamic>? ?? [];
  jsonShaped['referenceStrokes'] = rawStrokes.map((s) {
    final stroke = Map<String, dynamic>.from(s as Map<String, dynamic>);
    final rawPoints = stroke['points'] as List<dynamic>? ?? [];
    stroke['points'] = decodePoints(rawPoints);
    return stroke;
  }).toList();

  return Letter.fromJson(jsonShaped);
}

// ---------------------------------------------------------------------------
// Lesson codec
// ---------------------------------------------------------------------------

/// Build a Firestore document map from a JSON-shaped lesson map.
///
/// Lessons have no nested arrays, so this is a near-identity copy; it exists
/// for symmetry with the letter codec and to carry the optional
/// `toleranceRamp` (a flat `List<String>`, which Firestore stores natively).
Map<String, dynamic> lessonToFirestoreMap(Map<String, dynamic> jsonLesson) {
  return Map<String, dynamic>.from(jsonLesson);
}

/// Read a Firestore lesson document map into a `Lesson`, deferring to
/// `Lesson.fromJson` (defensive `toleranceRamp` parse preserved — D-19).
Lesson lessonFromFirestore(Map<String, dynamic> doc) {
  return Lesson.fromJson(Map<String, dynamic>.from(doc));
}

// ---------------------------------------------------------------------------
// meta/toleranceRamp doc (D-07)
// ---------------------------------------------------------------------------
//
// The file-level `defaultToleranceRamp` lives outside any lesson, so it is
// stored as its own doc: collection `meta`, doc id `toleranceRamp`, field
// `ramp`. These helpers carry that single list in and out (Pitfall 5).

/// Build the `meta/toleranceRamp` document map: `{"ramp": [...]}`.
Map<String, dynamic> metaToleranceRampToFirestore(List<String> ramp) {
  return <String, dynamic>{'ramp': List<String>.from(ramp)};
}

/// Read the `ramp` list out of the `meta/toleranceRamp` document map.
/// Defensive: a missing/malformed `ramp` field yields an empty list rather
/// than throwing (consumers fall back to their own default).
List<String> metaToleranceRampFromFirestore(Map<String, dynamic> doc) {
  final raw = doc['ramp'];
  if (raw is List) {
    return raw.whereType<String>().toList();
  }
  return <String>[];
}
