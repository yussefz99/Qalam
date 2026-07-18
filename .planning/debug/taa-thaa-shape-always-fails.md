---
slug: taa-thaa-shape-always-fails
status: resolved
trigger: "taa/thaa fail EVERY attempt with shape-criterion feedback ('needs a little more curve') on the graph letter-unit path — blocking all graph progression testing on device"
created: 2026-07-18
updated: 2026-07-18
---

## Symptoms

DATA_START
- **Expected:** A correctly-written taa/thaa (isolated form) passes the deterministic scorer at the `normal` preset on the graph letter-unit path, so the owner can advance through the curriculum graph and test progression.
- **Actual:** Every attempt fails with shape-criterion feedback — the on-screen line says it "needs a little more curve". Owner reports failing every single time, all day, on device (iPad).
- **Error messages:** No crash. Feedback line: "needs a little more curve" (shape criterion → certainly-wrong zone).
- **Timeline:** Failing today (2026-07-18), after quick-260718-nft swapped the taa/thaa isolated body to baa's 12-point bowl (owner-directed) and prod was re-seeded at 14:12 UTC. Earlier today quick-260718-l12 fixed a separate thaa always-wrong (stale June-14 seed). baa passes; taa/thaa do not.
- **Reproduction:** On device, enter taa or thaa letter unit via the graph walker path, trace the isolated form, submit. Fails every attempt.
DATA_END

## Evidence

- 2026-07-18 Tutor-server Cloud Run logs (project qalam-app-bd7d0, service qalam-tutor, rev 00027-nqw, via gcloud): 58 coach decisions today, ALL baa — zero taa/thaa entries. Consistent with `_isAgentPath` being baa-only (05834b9): taa/thaa never call the server; their verdict is fully on-device. Server logs cannot show taa/thaa wire fields — by design, not a gap.
- 2026-07-18 Prod Firestore letters/taa + letters/thaa (REST): iso body = 12-pt bowl (re-seed 14:12:45 landed), base = old authored bodies (taa 9-pt curve, thaa 7-pt line). Points stored as {x,y} maps — exactly what `firestore_curriculum_codec.decodePoints` expects. Prod data healthy.
- 2026-07-18 Self-score harness (Dart flutter-test, real `scoreLetter`): baa/taa/thaa iso references all PASS themselves (DTW ≈ 0.001). Base-fallback control: the iso bowl vs old base bodies scores d=0.0151 (taa) / 0.0245 (thaa) — far below tcc=0.12. NO version of the reference data can produce certainly-wrong (≥0.16) from a well-formed bowl.
- 2026-07-18 Feedback-line mapping (`_mapMistake`, exercise_validator.dart:408): on taa's trace exercises (authored keys pass/shallowBowl/noDot), tooCurved, tooShort, wrongDirection AND the generic fallback ALL render as "A little more curve — try again, slower." The line names shallowBowl, not necessarily the shape criterion.
- 2026-07-18 Canvas-stretch quantification (Dart harness, real `shapeDistance`): a PERFECT trace of the painted guide scores d=0.1051 at 1.5:1 canvas, 0.1612 at 2:1 (CERTAINLY-WRONG), 0.2473 at 3.6:1. The letter-unit writebox is an `Expanded` wide band on landscape tablet → the trace exercise was mathematically unpassable. Tracing better makes the score worse.
- 2026-07-18 Painter audit: `stroke_canvas.dart _CanvasPainter._scale` and `stroke_order_animation.dart:308` both mapped normalized points by `(x*width, y*height)` — non-uniform stretch. Scorer (`normalizeToUnitBox` + DTW, shape_match.dart) is deliberately aspect-preserving.
- 2026-07-18 baa masking asymmetry: (1) AI judge owns baa pass/fail since 2026-06-30 — adopted BECAUSE the scorer "false-failed correct writing" (same defect, undiagnosed); (2) baa's canvas is 242px narrower (Teacher's Margin row is `_isAgentPath`-gated) → less stretch. Today's baa deterministic wire fields: 22 certainlyCorrect / 15 fuzzy (several hugging the wrong edge: 0.10, 0.20, 0.27) / 5 certainlyWrong — consistent with a systematic stretch penalty.

## Eliminated

- **H1 (bowl-swap coordinate-frame mismatch):** shape is scored PER-STROKE with internal normalization (`shapeDistance(childStroke, reference.points)`); combined-bbox normalization only feeds the dot criterion. Merged iso geometry passes self-score cleanly. The swap is harmless (and unnecessary — the old bodies scored d≤0.025 vs a traced bowl).
- **H2 (per-form vs base resolution mismatch):** exercises author `expected.glyph.form='isolated'`; and even a full base fallback scores a traced bowl at d≤0.025 — benign either way.
- **H3 (stale device cache):** prod docs verified fresh + guide and scorer share ONE resolver (WR-01) and ONE letter object — any self-consistent data version lets a faithful trace pass. Data staleness cannot produce an every-attempt shape fail on trace.
- **Stale prod exercises:** prod has NO `exercises` collection (NOT_FOUND for baa too) — exercises are bundled-only.
- **positionalForm pre-check:** `writtenForm` is never passed on the glyph path → check skipped.
- **Split-gate selection code (05834b9):** selection-only; `result.passed` is computed before any of it.

## Investigation directives (from owner)

- READ THE TUTOR SERVER LOGS — done (see Evidence: taa/thaa never reach the server; baa distribution recovered instead).
- Self-score sanity check — done (decisive: data eliminated).
- Fix verified through the LIVE apply path — done (real pointer gestures on real StrokeCanvas → real validateExercise; walker progression suite green).
- Letters are Firestore-first — NO re-seed needed: the fix is client code only; prod data is correct as-is.

## Current Focus

hypothesis: RESOLVED
test: —
expecting: —
next_action: owner installs the rebuilt app and re-tests taa/thaa trace on device

## Resolution

root_cause: The trace-guide painters (`_CanvasPainter._scale` in stroke_canvas.dart and its twin in stroke_order_animation.dart) stretched the normalized authored glyph NON-uniformly onto the canvas (`x*width, y*height`). The letter-unit writebox is a wide `Expanded` band on a landscape tablet, so the painted guide was a flattened bowl; a child who traces it faithfully reproduces the stretch, and the aspect-PRESERVING shape scorer measures that stretch as error — past certainly-wrong (0.16) at any canvas ≥2:1. The taa/thaa trace nodes were therefore unpassable by the deterministic scorer. baa masked the defect (AI judge owns its verdict since 2026-06-30 — a decision made because the scorer "false-failed correct writing", i.e. this same bug; plus a narrower canvas). The nft walker un-gating exposed taa/thaa to the raw deterministic verdict. All three data re-seeds today fixed data that was never broken.
fix: New shared helper `lib/features/practice/widgets/guide_geometry.dart` (`scaleNormalizedPoint`): ONE uniform scale (shorter canvas side), centered — never a per-axis stretch. Both painters now delegate to it, so guide, demo animation, dots, and start-dot land where the scorer's geometry assumes. Client code only — no prod re-seed, no server deploy.
verification: `test/features/letter_unit/trace_guide_scorer_agreement_test.dart` — real pointer gestures trace the PAINTED guide on the real StrokeCanvas at a 3:1 writebox, captured strokes driven through the real `exerciseSpecFromExercise` → `validateExercise` (write_surface's exact call): taa PASSES, thaa PASSES; regression pin asserts the pre-fix stretched geometry stays certainly-wrong (the scorer's aspect sensitivity is intentional pedagogy). Affected suites re-run: only 6 pre-existing failures remain (alif signedOff/centerline data drift + known golden font drift + meet_section Test 1) — reproduced identically at HEAD without the fix. thaa_walker_progression_test (pass → walker nextForward) green.
files_changed:
  - lib/features/practice/widgets/guide_geometry.dart (new)
  - lib/features/practice/widgets/stroke_canvas.dart
  - lib/features/practice/widgets/stroke_order_animation.dart
  - test/features/letter_unit/trace_guide_scorer_agreement_test.dart (new)
