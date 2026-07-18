// Shared guide-geometry mapping — the trace↔scorer agreement invariant.
//
// Root cause fixed here (debug session taa-thaa-shape-always-fails,
// 2026-07-18): both guide painters (`stroke_canvas.dart` /
// `stroke_order_animation.dart`) used to map normalized authored points by
// `(x * size.width, y * size.height)` — a NON-uniform stretch onto the
// letter-unit writebox, which is a wide Expanded band on a landscape tablet.
// The scorer's shape criterion (shape_match.dart) deliberately PRESERVES
// aspect ratio when it normalizes (a flat "line" bowl vs a round bowl must
// stay distinguishable), so a child who traces the stretched guide FAITHFULLY
// reproduces the stretch — and the DTW shape distance measures it as error.
// On a canvas at or beyond ~2:1 a PERFECT trace of the 12-pt bowl lands past
// the certainly-wrong threshold (shapeTcw 0.16): the trace exercise becomes
// unpassable, and tracing better makes the score worse. (baa masked this —
// its pass/fail is owned by the AI judge and its canvas is narrower beside
// the Teacher's Margin; taa/thaa met the raw deterministic verdict.)
//
// THE INVARIANT: the painted guide must be geometrically SIMILAR to the
// authored reference — ONE uniform scale plus translation, never a stretch —
// so what the child sees and traces IS the authored shape. Every painter that
// maps normalized [0..1] reference points to canvas pixels must go through
// [scaleNormalizedPoint]. Pinned by trace_guide_scorer_agreement_test.

import 'dart:math' as math;
import 'dart:ui';

/// Side length of the square glyph box a [size]-sized canvas paints into: the
/// SHORTER canvas side, so the whole [0..1] authored space stays visible and
/// the scale is uniform (never a stretch).
double glyphBoxSide(Size size) => math.min(size.width, size.height);

/// Top-left of the centered square glyph box within [size].
Offset glyphBoxOrigin(Size size) {
  final double side = glyphBoxSide(size);
  return Offset((size.width - side) / 2, (size.height - side) / 2);
}

/// Maps a normalized `[x, y]` authored point (0..1 space) into canvas pixels
/// with a UNIFORM, centered scale — the aspect-preserving mapping the scorer's
/// shape criterion assumes the child saw (see the invariant above).
Offset scaleNormalizedPoint(List<double> point, Size size) {
  final double side = glyphBoxSide(size);
  final Offset origin = glyphBoxOrigin(size);
  return Offset(origin.dx + point[0] * side, origin.dy + point[1] * side);
}
