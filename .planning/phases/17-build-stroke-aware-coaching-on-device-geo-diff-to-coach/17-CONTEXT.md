# Phase 17 — CONTEXT (Tutor Redesign: grounded, form-aware, on-device scorer)

> Captured 2026-07-01 from: the on-device UAT (F1–F6 punch-list), the design
> discussion (goals G1–G9), and the **clean-room deep research** on the pass/fail
> mechanism. Feeds `/gsd:plan-phase 17`. Companion: `TUTOR-REDESIGN.md`,
> `TUTOR-RESEARCH-FINDINGS.md`, `17-AI-SPEC.md`.

## Domain

Generalize the baa-isolated tutor into a **grounded, form-aware, personal**
handwriting tutor. The load-bearing decision — settled by research — is **how the
agent decides pass/fail**.

## Decisions (LOCKED)

- **D-A — The deterministic scorer OWNS pass/fail** (online, stroke-based,
  multi-criteria, soft-threshold, on-device). **This REVERSES Phase 17.1's
  AI-owns-pass/fail** (the image judge in `server/app/image_judge.py`): that was a
  reaction to a *mis-calibrated* scorer, not evidence the LLM should judge. The
  research is explicit that VLMs must not own fine-grained handwriting/dot
  judgment. `TUTOR-RESEARCH-FINDINGS.md` §"Bottom line" is the spec. **The
  AI-SPEC §1/§4 "AI owns the verdict" is SUPERSEDED by this decision.**
- **D-B — The LLM only explains + coaches** from the scorer's per-criterion
  output (the warm "why" G7 + mother's-voice line G4 + points at the failed
  criterion). It never sees a blank verdict to invent. Coaching is a *separate,
  degradable* layer over a scorer that already decided.
- **D-C — Scorer design = online, 5 criteria + explicit dot check, soft 3-zone
  thresholds, DTW-to-per-form-reference, spatial dot detection, advisory-only
  CNN/ML-Kit identity.** See findings F1–F9. The existing scorer is UPGRADED, not
  rewritten (it already has spatial dots + advisory ML-Kit + firm count/order).
- **D-D — Thresholds are DATA, calibrated on real child samples, and per-child
  adaptive** (findings F8/F11). Provisional synthetic values ship for the demo;
  owner's-mother-labelled calibration is the production gate. Adaptive bands tie to
  the G8 learner model.
- **D-E — Prove on baa fully (4 forms + words), then taa** (shares baa's skeleton,
  differs only by dots) — the cheapest generalization proof. Reuse boundary from
  `TUTOR-REDESIGN.md` holds (redesign brain, reuse body).
- **D-F — Coaching model is an open bake-off, decided later**: on-device Gemma
  (coaching-only) vs Gemini-on-Vertex, on the mother's register rubric. Not a
  blocker for the scorer work.
- **D-C amendment — kinematics descoped, position folded (OWNER-CONFIRMED
  2026-07-05, plan-phase checkpoint):** `StrokeCanvas` captures no timestamps, so
  the kinematics criterion is DESCOPED this phase — never fake speed from point
  spacing. Position folds into the firm dot-placement check. The five scored
  criteria are **shape / direction / strokeOrder / strokeCount / dot**. FOLLOW-UP
  (recorded): add `PointerEvent.timeStamp` capture in a later phase so kinematics
  can join with real data. Recorded in ADR-017.
- **A2 confirmed — demo scores unsigned forms (OWNER-CONFIRMED 2026-07-05,
  plan-phase checkpoint):** the demo MAY score baa initial/medial/final against
  form-level `signedOff:false` references (guides already render them). The
  mother's sign-off stays the recorded PRODUCTION gate (17-HUMAN-UAT + ADR-017).

## Build increments (for the planner to break into tasks)

1. **✅ DONE — Shape-match core.** DTW `shapeDistance` + `SoftBand` 3 zones
   (`lib/core/scoring/shape_match.dart` + test; commit 4e71d6b).
2. **Wire shape-match into the per-stroke scorer** — replace the chord-curvature
   proxy in `geometric_stroke_scorer.scoreStroke` with `shapeDistance` vs the
   **per-form** reference; verdict becomes soft (pass unless a criterion is
   certainly-wrong); keep direction as a criterion.
3. **Per-form + multi-criteria letter scorer** — `letter_scorer.scoreLetter`
   consumes the per-form reference (`contextualForms[form]`), scores the 5 criteria
   + dot check, emits a **structured per-criterion result** (each criterion's zone
   + score + the weakest one). Keep COUNT/ORDER firm; keep the advisory ML-Kit gate.
4. **Structured scorer output → coaching contract** — the per-criterion result is
   the input the LLM coaches from (which criterion failed, by how much) — replaces
   the image-judge path. Grounding holds by construction (LLM can't overturn it).
5. **Calibration harness upgrade** — extend `test/core/scoring/calibration_harness_test.dart`
   to fit the soft-band thresholds from a labelled child set (per letter × form);
   the mother's labels are the ground truth (production gate).
6. **Cutover** — route baa's pass/fail through the upgraded scorer; retire the
   `strokeImage` → `image_judge` short-circuit for the verdict (the image judge, if
   kept at all, becomes an advisory corroborator, never the owner).
7. **(Parallel, curriculum track)** per-form references for the other 25 letters —
   model drafts → owner's mother signs off. Blocks form-awareness beyond alif/baa/taa.

## Reusable assets (code_context)

- `lib/core/scoring/shape_match.dart` — the new DTW + soft-band core (done).
- `lib/core/scoring/{geometric_stroke_scorer,letter_scorer,stroke_resampler,tolerances,scoring_models}.dart` — the scorer to upgrade; already has `resample`, `normalizeToUnitBox`, spatial `_classifyChildDots`, advisory `_identityGate`, firm count/order.
- `assets/curriculum/letters.json` — `contextualForms.{isolated,initial,medial,final}` per-form references (alif/baa/taa only) + `commonMistakes` (all 28) + `tolerances`.
- `test/core/scoring/{calibration_harness_test,scoring_fixtures,calibration_fixtures}` — the calibration harness (Dart flutter-test) to extend.
- Server (coaching only, reused): `server/app/{main,nodes/coach,prompts,faithfulness}.py`.

## Canonical refs

- `docs/architecture/TUTOR-RESEARCH-FINDINGS.md` — the cited scorer spec (READ FIRST).
- `docs/architecture/TUTOR-REDESIGN.md` — goals G1–G9 + diagnosis-centric architecture.
- `docs/testing/UAT-FULL-2026-07-01.md` — the F1–F6 bugs this must fix.
- `.planning/phases/17-.../17-AI-SPEC.md` — implementation/eval contract (NOTE: its
  AI-owns-verdict stance is superseded by D-A; its eval §5 + Vertex/coaching guidance stand).

## Deferred / parallel

- Owner's-mother calibration labelling (production gate for D-D).
- Per-form references for 25 letters (curriculum track, D-E generalization).
- Gemma coaching-only bake-off (D-F).
- Letter audio (0/28 recorded).
- ADR + consent for any residual off-device data flow (the geometry path keeps
  strokes on-device, which shrinks this to near-zero — a win).
