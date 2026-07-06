---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
verified: 2026-07-06T18:17:13Z
status: human_needed
score: 4/4 must-haves code-verified (empirical/authority-gated portions routed to human)
overrides_applied: 0
requirements_verified: [STRK-01, GROUND-04, EVAL-03]
human_verification:
  - test: "Cloud Run re-deploy of the Phase-17 contract"
    expected: "Live qalam-tutor advances from rev 00020 (old contract) to the Phase-17 contract (criteria accepted, image path gone); /health 200, /coach {} 401. Client + server contracts already match in-repo, so a single deploy is safe."
    why_human: "The auto-mode safety classifier denied the production `gcloud run deploy` in the autonomous session and asked it run outside auto-mode for human review. Not a code defect — live /health already returns 200 on rev 00020."
  - test: "make eval judge legs + STRK-01 two-arm baseline (arm A stroke-aware vs arm B label-only)"
    expected: "run_baseline.py shows arm A beats arm B on specificity + variety with 0 grounding violations in BOTH arms; run_judge semantic_faithfulness / no_false_geometry / specificity legs meet the 0.7 threshold. This is the empirical demonstration of STRK-01's 'measurably beating the label-only baseline'."
    why_human: "The judge + baseline legs make live Vertex calls (keyless ADC, cost). No ~/.config/gcloud/application_default_credentials.json in this session, and the judge calibration is gated on the signed gold. The instrument is built and wired into `make eval`; it needs a credentialed run."
  - test: "Owner's-mother gold-set re-sign (EVAL-03 're-signed by the owner's mother')"
    expected: "Present the regrown stroke-level gold_set.jsonl (20 records, all `signed:false`) to the mother; she edits/approves each; flip reviewed cases to `signed:true` and create/append server/tests/test_eval/GOLD-SIGNOFF.md."
    why_human: "Pedagogy/register authority is the owner's mother's, never autonomous (15-07 precedent). Acceptance at plan close is `grep -c '\"signed\": true' == 0` (confirmed 0/20)."
  - test: "Owner's-mother per-form sign-off queue (A2 / ADR-017 §5)"
    expected: "Flip form-level signedOff:true in assets/curriculum/letters.json for baa initial/medial/final (+ alif) ONLY on her word. Demo scores these unsigned by owner-confirmed default; her sign-off is the PRODUCTION gate."
    why_human: "Form-level pedagogy sign-off is the mother's authority; the demo-scores-unsigned default is a demo-only allowance."
  - test: "Threshold calibration on real child samples (D-D production gate)"
    expected: "Capture real child baa/taa samples on-device, mother labels each, re-run calibration_harness_test.dart against her labels, adopt fitted per-form tcc/tcw as letters.json overrides. Shipped band (tcc 0.10 / tcw 0.15) is a provisional synthetic floor."
    why_human: "Real child handwriting cannot be synthesized; the ground-truth labels are the mother's. The harness prints PROVISIONAL only — it never mutates production values."
  - test: "Device re-walk of UAT F1-F6 on the tablet/iPad (new demo build)"
    expected: "F1 English helper reads LTR; F2 verdict+star render instantly on-device with no flash-then-overwrite; F3 coaching English-primary; F4/F6 wrong-answer + word-path feedback specific and warm; F5 an isolated bowl offered for the medial/final slot FAILS at the scorer."
    why_human: "Device rendering, latency, cold-start, and stylus capture are not reproducible in the headless flutter-test VM."
  - test: "Consent copy for the derived-diff data flow (owner/legal, pre-production)"
    expected: "Add onboarding/consent copy stating handwriting-DERIVED facts (no image, no raw strokes, no PII) are processed by an AI coaching service — the residual GROUND-01/02 consent debt from 17.1, now much smaller."
    why_human: "Consent/legal copy is an owner + legal decision, outside this phase's engineering scope."
warnings:
  - source: 17-REVIEW WR-01
    issue: "WriteSurface resolves the guide + computeStrokeDiff against surface.guideForm (write_surface.dart:158,207) while the scorer/validator resolves against exercise.expected?.glyph?.form ?? guideForm (exercise_validator.dart:128). The 'one shared resolver' invariant is shared in name only. Latent — masked by baa (all forms = body+dot) and the demo configs (both 'isolated'); would bite once a letter's forms differ in stroke count."
  - source: 17-REVIEW WR-02
    issue: "Tolerances.fromJson silently discards directionCc/directionCw overrides (tolerances.dart:130-144) — the D-D calibration-by-data story cannot be delivered for direction. Does not affect the baa demo (uses base preset)."
  - source: 17-REVIEW WR-03
    issue: "No ordering/range guard on shapeTcc/shapeTcw; SoftBand's assert(tcc<tcw) is stripped in release. An inverted authored band would silently disable shape-failure detection (F5/flat-bowl reject) in production. Surfaces only when the mother tunes calibration data (D-D)."
  - source: 17-REVIEW WR-04
    issue: "/coach logs the full derived attempt (geometry summary + child-facing line) at WARNING level on every request (main.py:133-143) — data-minimization smell; should be level-gated/env-flagged."
---

# Phase 17: Stroke-Aware Coaching (on-device geo-diff → coach) Verification Report

**Phase Goal:** Make the coach name the specific geometry of the child's actual baa attempt (where the curve fell short, which side is flat, where the dot landed) instead of being capped by the scorer's small `mistakeId` set. The agent consumes a derived stroke-geometry diff computed ON-DEVICE (Dart), sent as a structured fact; raw strokes never leave the device. The diff flows to the coach node only (v1), verbalized in the mother's voice through the existing 4 ACTION tools. The deterministic scorer owns the verdict (D-A); grounding holds; the eval grows to score stroke-level coaching.

**Verified:** 2026-07-06T18:17:13Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

All four roadmap success criteria are achieved at the CODE level: every artifact exists, is substantive, is wired, and the model-free regression gates are green (server `-m code` 109 passed / 1 skipped; 112 Phase-17 flutter tests passed). What remains are legitimately human-gated: a live Cloud Run deploy (auto-mode safety classifier denied prod deploy), the live-Vertex empirical baseline/judge run (needs ADC credentials), and the owner's-mother pedagogy authority (gold re-sign, per-form sign-off, real-child calibration). Per the phase's recorded human gates (17-HUMAN-UAT), these are deferred human/device/authority/ADC items, not defects — so the status is `human_needed`, not `gaps_found`.

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
| --- | ------- | ---------- | -------------- |
| 1 | Coach produces attempt-specific, varied, grounded lines naming actual geometry, measurably beating the label-only baseline on specificity/variety, grounding intact (STRK-01) | ✓ VERIFIED (mechanism) — empirical beat human-gated | On-device `lib/tutor/stroke_diff.dart` computes a point-free geo diff (bowl depth, which side flat, dot placement, tail, direction); `letter_scorer.dart` emits 5 structured `criteria` + weakest; the coach `COACH_STROKE_ADDENDUM` (prompts.py) names the specific criterion/geometry and forbids exemplar parroting; grounding guards G3/G4 intact (coach.py); model-free variety + praise-floor gates green. The two-arm baseline instrument (`run_baseline.py`) is built and wired into `make eval` but the empirical "arm A beats arm B" run needs live Vertex ADC → human item 2. |
| 2 | Raw strokes never leave the device; only derived `strokeDiff` crosses the wire; `extra="forbid"` rejects raw points/PII; client + server contracts match, no 422 (GROUND-04) | ✓ VERIFIED | `stroke_diff.dart` emits only whitelisted derived scalars/strings (no x/y/points); `TutorFacts` has no Offset/stroke field and `buildTutorFacts` accepts no stroke param; client `toMap` keys == server `TutorFactsIn` fields byte-for-byte; both DTOs + nested `StrokeDiffIn`/`CriterionIn` are `extra="forbid"`; guard tests green (client `payload_nonpii_test`, server `test_payload_nonpii` + `test_criteria_contract`). `strokeImage`/`image_judge.py`/`CoachOut.verdict` deleted (git rm 28440f3); `stroke_image_grep_guard_test` confirms strokeImage absent from lib/. |
| 3 | Eval scores stroke-level coaching with a SEMANTIC faithfulness gate (coarse substring floor retired) + no-false-geometry check, re-signed by the mother, runs as regression gate (EVAL-03) | ✓ VERIFIED (harness) — mother's re-sign human-gated | `run_eval.py` DIMENSIONS add `semantic_faithfulness`, `no_false_geometry`, `specificity`, `variety`; the expected-fix substring rule is retired for live lines (`evaluate_praise_floor`), `names_fix` demoted to advisory and dropped from `gate_passes`; gold regrown for stroke-level (20 records, 10 with strokeDiff, adversarial_false_geometry trap present). Model-free regression gate green (`eval-code` 22 passed / 1 skipped). Judge legs need ADC → human item 2; mother's re-sign 0/20 signed → human item 3. |
| 4 | The softened GROUND-02 reversal (derived diff leaves the device, NOT raw strokes) is recorded as an ADR | ✓ VERIFIED | `docs/architecture/ADR-017-scorer-owns-verdict-derived-facts.md` (189 lines): records D-A verdict authority un-reversal, the softened GROUND-02 (derived point-free diff crosses, raw strokes/images never), the image-path retirement, and the OWNER-CONFIRMED D-C amendment (kinematics descoped / position folded / unsigned forms scored). |

**Score:** 4/4 truths code-verified. Status is `human_needed` because the empirical/live/authority-gated portions of truths 1–3 require human action (7 items below).

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | ----------- | ------ | ------- |
| `lib/tutor/stroke_diff.dart` | On-device point-free geo diff | ✓ VERIFIED | 260 lines; scale/translation-invariant; whitelisted keys mirror `StrokeDiffIn`; wired into write_surface. |
| `lib/core/scoring/letter_scorer.dart` | Per-form multi-criteria `scoreLetter` → LetterScore | ✓ VERIFIED | 414 lines; 5 criteria (count/order/shape/direction/dot), firm count/order/dot, soft shape/direction, weakest, F5 form-trap via `resolveReferenceStrokes`. |
| `lib/core/scoring/geometric_stroke_scorer.dart` | `scoreStroke` via `shapeDistance` + SoftBand | ✓ VERIFIED | 220 lines; DTW shape criterion + soft-band from `Tolerances`; chord proxy removed. |
| `lib/core/scoring/reference_resolution.dart` | Single per-form resolver (Pitfall 7) | ✓ VERIFIED | 54 lines; `resolveReferenceStrokes` + `resolveTolerances`. See WR-01 — two call sites pass different form keys (latent, baa-masked). |
| `lib/core/scoring/scoring_models.dart` / `tolerances.dart` | CriterionResult + soft-band data knobs | ✓ VERIFIED | `CriterionResult{criterion,zone,score}`, `shapeTcc/shapeTcw/directionCc/directionCw`. WR-02/WR-03: direction overrides dropped in fromJson; no band range guard. |
| `lib/tutor/tutor_facts.dart` + `tutor_facts_builder.dart` | Derived criteria/word facts mirror, omit-when-null | ✓ VERIFIED | 15 whitelisted keys; strokeDiff/criteria/weakestCriterion/expectedWord/writtenWord derived from CheckResult; no stroke/Offset param. |
| `lib/features/letter_unit/widgets/exercise_scaffold.dart` | D-A cutover — scorer verdict unconditional/synchronous | ✓ VERIFIED | `_onResult` applies `applyResult(result)` synchronously; brain call fire-and-forget; behavioral cutover test green. |
| `server/app/schema.py` | CriterionIn + StrokeDiffIn + optional TutorFactsIn fields, extra=forbid | ✓ VERIFIED | 218 lines; image field + CoachOut.verdict retired; all Phase-17 fields optional/defaulted. |
| `server/app/prompts.py` + `nodes/coach.py` | Criterion-aware addendum, English-primary, addendum trigger | ✓ VERIFIED | `COACH_STROKE_ADDENDUM` triggered on strokeDiff/criteria/writtenWord; G3/G4 guards intact. |
| `server/tests/test_eval/{run_eval,run_judge,run_baseline,test_variety}.py` | Semantic gate + no-false-geometry + two-arm baseline | ✓ VERIFIED | New DIMENSIONS, praise-floor, variety detector, two-arm baseline; wired into `make eval` (eval-code / eval-judge / eval-baseline). |
| `server/tests/test_eval/gold_set.jsonl` | Regrown stroke-level, signed:false | ✓ VERIFIED | 20 records (47 physical lines incl. 27 comment lines), 10 stroke-level, adversarial traps present, 0/20 signed (awaits mother). |
| `docs/architecture/ADR-017-*.md` | The GROUND-04 ADR | ✓ VERIFIED | 189 lines; records D-A + softened GROUND-02 + image retirement + D-C amendment. |
| `server/app/image_judge.py` | DELETED | ✓ VERIFIED | Removed (git rm, commit 28440f3); absent from tree. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| write_surface `_onLetterComplete` | `computeStrokeDiff` | `computeStrokeDiff(pixelStrokes, _referenceStrokes)` → `onStrokeDiff` | ✓ WIRED | write_surface.dart:217,222. |
| exercise_scaffold `_onResult` | `buildTutorFacts(strokeDiff:)` | derived diff + CheckResult criteria → TutorFacts | ✓ WIRED | exercise_scaffold.dart:213-219. |
| client `TutorFacts.toMap` | server `TutorFactsIn` | byte-for-byte key mirror (422 lockstep) | ✓ WIRED | Keys match; nested StrokeDiffIn/CriterionIn extra=forbid; contract tests green. |
| coach node | `COACH_STROKE_ADDENDUM` | trigger: strokeDiff OR criteria OR writtenWord | ✓ WIRED | coach.py:61-62. |
| `make eval` | `run_baseline.py` | eval → eval-code → eval-judge → eval-baseline | ✓ WIRED | server/Makefile:27,46. |
| scorer / validator | `resolveReferenceStrokes(form)` | per-form reference | ⚠️ PARTIAL | Wired, but write_surface passes `surface.guideForm` while validator passes `expected.glyph.form ?? guideForm` (WR-01) — latent divergence, baa-masked. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| coach `/coach` line | `facts.strokeDiff` / `facts.criteria` | on-device `computeStrokeDiff` + `LetterScore.criteria` (real geometry) | Yes (derived from real child strokes at the surface seam) | ✓ FLOWING |
| TutorFacts payload | derived criteria/word facts | `CheckResult` (validator serializes real LetterScore) | Yes | ✓ FLOWING |
| STRK-01 baseline table | arm-A vs arm-B specificity/variety | live Vertex coach+judge | Not yet run (ADC absent) | ⚠️ pending human item 2 (instrument built) |

### Behavioral Spot-Checks / Probe Execution

| Check | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Model-free eval regression gate (EVAL-03 code leg) | `uv run pytest test_faithfulness test_eval_harness test_variety -m code` | 22 passed, 1 skipped | ✓ PASS |
| Phase-17 server contract + grounding + payload | `uv run pytest test_criteria_contract test_payload_nonpii test_grounding test_endpoint` | 57 passed | ✓ PASS |
| Full server PR gate | `uv run pytest -m code` | 109 passed, 1 skipped | ✓ PASS |
| Phase-17 flutter (scorer/tutor/cutover/guards/LTR) | `flutter test <11 files>` | 112 passed | ✓ PASS |
| `make eval` judge + two-arm baseline | `cd server && make eval` | not run — needs Vertex ADC | ? SKIP → human item 2 |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| STRK-01 | 17-01/02/03/04/06/07/09 | Coach names the specific geometry, measurably beats label-only baseline | ✓ SATISFIED (mechanism) | stroke_diff + criteria + addendum wired; grounding + variety green. Empirical beat = human item 2. |
| GROUND-04 | 17-05/06/07/08/10 | Derived diff crosses, never raw strokes; extra=forbid; contracts match; ADR | ✓ SATISFIED | Contract match, guards green, image path deleted, ADR-017. Live deploy = human item 1. |
| EVAL-03 | 17-04/10 | Semantic faithfulness gate + no-false-geometry + regrown gold, regression gate | ✓ SATISFIED (harness) | Semantic/no-false-geometry legs + praise floor + variety; eval-code green. Mother re-sign = human item 3; live judge = human item 2. |

All three declared requirement IDs are present in REQUIREMENTS.md → v2.0 Traceability, mapped to Phase 17, and each appears in ≥1 plan's `requirements` frontmatter. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (phase-17 modified source) | — | TBD/FIXME/XXX debt markers | ℹ️ none found | Completion is auditable. |
| write_surface.dart / exercise_validator.dart | 158/207 vs 128 | Divergent per-form resolution (WR-01) | ⚠️ Warning | Latent; masked by baa. Fails once forms differ in stroke count. |
| tolerances.dart | 130-144 | direction overrides silently dropped (WR-02) | ⚠️ Warning | D-D direction calibration unreachable via data; baa demo unaffected. |
| tolerances.dart / shape_match.dart | 69-77/57 | No range guard on soft-band; release strips assert (WR-03) | ⚠️ Warning | Inverted authored band could disable shape-fail in production. |
| server/app/main.py | 133-143 | /coach logs derived attempt at WARNING (WR-04) | ⚠️ Warning | Data-minimization smell; should be level-gated. |

These are the code-review warnings (0 critical, 4 warning, 3 info). None fails a Phase-17 success criterion for the baa demo; all bite only when the curriculum grows or the mother tunes calibration.

### Human Verification Required

7 items (from 17-HUMAN-UAT ledger, corroborated by this verification). All are device/live-service/ADC/pedagogy-authority gates — none is a code defect.

1. **Cloud Run re-deploy** — advance live qalam-tutor from rev 00020 to the Phase-17 contract. Blocked by the auto-mode safety classifier (denied prod deploy for human review), not a code/auth defect. Contracts already match in-repo.
2. **`make eval` judge legs + STRK-01 two-arm baseline** — the empirical demonstration that arm A (stroke-aware) beats arm B (label-only) on specificity + variety, grounding 0/0. Needs keyless Vertex ADC. Instrument built and wired.
3. **Owner's-mother gold-set re-sign (EVAL-03)** — 0/20 records signed; pedagogy authority, never autonomous.
4. **Owner's-mother per-form sign-off** — flip baa initial/medial/final (+alif) signedOff:true on her word; demo scores unsigned by owner-confirmed default.
5. **Threshold calibration on real child samples (D-D)** — capture + mother-label + re-run the harness; adopt fitted tcc/tcw. Shipped band is a provisional synthetic floor.
6. **Device re-walk of UAT F1-F6** — device rendering/latency/stylus not reproducible headless.
7. **Consent copy for the derived-diff data flow** — owner/legal, pre-production.

### Gaps Summary

No gaps. Every landed artifact for Phase 17 exists, is substantive, is wired, and passes its regression gate (server `-m code` 109 passed / 1 skipped; 112 Phase-17 flutter tests passed; eval-code 22 passed / 1 skipped). The scorer owns the verdict on-device (D-A), only the derived point-free diff crosses the wire (GROUND-04, guards green), the image path is deleted on both sides, the eval scores stroke-level coaching with a semantic gate + no-false-geometry check (EVAL-03), and the softened GROUND-02 reversal is recorded in ADR-017 (success criterion 4). The remaining work is the seven human/device/ADC/authority gates above — recorded, resumable, and correctly deferred per `human_verify_mode: end-of-phase`. Four code-review warnings (WR-01…04) are latent robustness/calibration gaps that do not bite the baa demo and do not fail a success criterion; they should be tracked before the curriculum grows or the mother tunes calibration data.

---

_Verified: 2026-07-06T18:17:13Z_
_Verifier: Claude (gsd-verifier)_
