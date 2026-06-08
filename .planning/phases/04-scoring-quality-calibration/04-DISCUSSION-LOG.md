# Phase 4: Scoring Quality & Calibration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 4-Scoring Quality & Calibration
**Areas discussed:** Letter scope, Calibration sample collection, Tolerance schema, ML Kit identity check + model download

---

## Letter scope for calibration

| Option | Description | Selected |
|--------|-------------|----------|
| Alif + baa | Author/sign off baa (body + dot); calibrate count/order/dot on one real multi-stroke letter | |
| Alif only | Calibrate alif; verify order/count with synthetic fixtures; defer real multi-stroke to Phase 7 | |
| Alif + a few early letters (baa, taa, thaa) | Pull the baa-family forward; same body, differing dot count — stress-tests dot count + ML Kit confusion | ✓ |

**User's choice:** Alif + a few early letters (baa-family).
**Notes:** baa/taa/thaa differ only by dot count (1 below / 2 above / 3 above) — chosen as the sharpest test of dot-count scoring AND ML Kit ب/ت/ث confusion. Pulls the mother's authoring + sign-off for these three forward from Phase 7 into Phase 4 (captured as a dependency/gate in CONTEXT D-01).

---

## Calibration sample collection

| Option | Description | Selected |
|--------|-------------|----------|
| In-app capture tool | Extend the Phase 02.1 authoring screen into a labeled-sample mode; mother labels live | |
| Offline session + manual entry | Record on paper/generic canvas, hand-enter coordinate fixtures | |
| Synthetic fixtures only | Owner + mother hand-craft good/bad fixtures from known common mistakes | |
| (Free-text) Research it deeply | Owner asked for a deep research pass — emulator capture distrusted | ✓ |

**User's choice:** Free-text — "i want your advice... taking them from the emulator i dont think is the best option... can we research this deeply." Then, when asked about realistic hardware/child access, chose **"Let research decide."**
**Notes:** Captured as an OPEN high-priority research directive (CONTEXT D-02). Claude's leading hypothesis recorded for the researcher to confirm or beat: real children on a real Android tablet, captured via an in-app tool, labeled live by the mother; reject emulator/mouse data for tolerance-setting (Pitfall 3). Researcher must also determine minimum viable sample sizes and feasibility-ranked options.

---

## Tolerance schema (what the mother edits)

| Option | Description | Selected |
|--------|-------------|----------|
| Named presets + overrides | `loose`/`normal`/`strict` per letter expanding to numeric thresholds; optional numeric overrides | |
| Raw numeric thresholds | Explicit per-letter tolerances block (maxCurvature, minLength, …) she edits directly | |
| Let research/planner decide | Defer exact form; surface tradeoffs + the knobs that need tuning | ✓ |

**User's choice:** Let research/planner decide.
**Notes:** Locked hard requirements regardless of form (CONTEXT D-03): per-letter, data-not-code (editable JSON, no recompile, SC#4), teacher-legible. Claude's leading hypothesis: named presets + numeric overrides.

---

## ML Kit identity check role

| Option | Description | Selected |
|--------|-------------|----------|
| Coarse safety net | Catches "completely different letter / scribble" only; never overrides a good-faith correct geometric pass | ✓ |
| Co-judge | Both geometric + ML Kit must agree to pass; stricter but risks ب/ت/ث false rejections | |
| Let research decide | Defer gating logic + confidence threshold | |

**User's choice:** Coarse safety net.
**Notes:** Honors Pitfall 1 (don't over-trust ML Kit). Geometric scorer stays sole judge of shape/order/count/dot quality (CONTEXT D-04).

---

## ML Kit model download

| Option | Description | Selected |
|--------|-------------|----------|
| Background on first launch | Fetch quietly after install/onboarding; "getting ready" state if practice starts early | ✓ |
| On first practice, with a wait | Lazy download at first practice screen with a one-time "preparing" moment | |
| Let research/planner decide | Defer timing + offline-reconcile UX | |

**User's choice:** Background on first launch.
**Notes:** Fully offline after the one-time fetch; never blocks a lesson mid-flow (CONTEXT D-05).

---

## Claude's Discretion

- Shape-distance algorithm for whole-letter scoring (resampled point distance vs Procrustes/Fréchet).
- Riverpod wiring for the letter-level scoring orchestrator above per-stroke `scoreStroke`.
- Labeled-fixture file format and location in the repo.
- ML Kit package selection/version (verify vs STACK.md at plan time).

## Deferred Ideas

- Calibrating the remaining 24 letters + words → Phase 7.
- Gentle "show me again" auto-replay after repeated misses → optional UX polish.
- Updating design assets to drop legacy star-counter/weekly-tally chrome → housekeeping.
</content>
