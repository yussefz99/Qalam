// THROWAWAY SPIKE FIXTURE (Phase 11 — GenUI/native-canvas kill-shot).
//
// Serves: the GATE-deciding A/B test. The embedded + standalone StrokeCanvas arms
// both need baa's reference strokes to render the dotted guide the child traces.
//
// Open Question Q1 resolution (D-09/D-10): this COPIES baa's signed-off
// referenceStrokes read-only from assets/curriculum/letters.json. It deliberately
// does NOT import the durable curriculum loader (CurriculumRepository) — that would
// drag Firestore + Drift providers into a throwaway target and complicate the spike.
// The CANVAS WIDGET under test stays the REAL one (lib/features/practice/widgets/
// stroke_canvas.dart, imported read-only); only its DATA is this local fixture.
//
// This file imports ONLY StrokeSpec from package:qalam/models/letter.dart — no
// curriculum loader, no Firestore, no Drift. It modifies no durable file; the SC-4
// git-diff guard (test/spike_genui/durable_layers_unchanged_test.dart) proves it.
//
// Source of truth: assets/curriculum/letters.json -> id:"baa".referenceStrokes
// (signedOff: true). The two strokes below were verified byte-for-byte against the
// LIVE letters.json baa entry at copy time (boat body sweeping rightToLeft +
// the single dot below). If the authored curriculum drifts, re-copy from
// letters.json — it, not this fixture, is the source of truth.

import 'package:qalam/models/letter.dart';

/// baa's signed-off reference strokes, copied read-only for the spike.
///
/// Stroke 1 (order 1, 'body'): the 12-point boat curve, normalized 0..1,
/// sweeping right-to-left. Stroke 2 (order 2, 'dot'): the single point below.
/// The painter draws non-'dot' strokes as the dotted trace guide and the 'dot'
/// stroke as a calm ink circle (stroke_canvas.dart).
const List<StrokeSpec> baaReferenceStrokes = <StrokeSpec>[
  StrokeSpec(
    order: 1,
    label: 'body',
    type: 'curve',
    direction: 'rightToLeft',
    points: <List<double>>[
      [0.608, 0.447],
      [0.619, 0.486],
      [0.620, 0.524],
      [0.594, 0.552],
      [0.551, 0.565],
      [0.511, 0.569],
      [0.474, 0.570],
      [0.436, 0.566],
      [0.407, 0.559],
      [0.386, 0.530],
      [0.381, 0.498],
      [0.382, 0.460],
    ],
  ),
  StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    direction: 'tap',
    points: <List<double>>[
      [0.498, 0.644],
    ],
  ),
];
