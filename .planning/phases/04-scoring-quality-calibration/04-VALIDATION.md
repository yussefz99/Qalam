---
phase: 04
slug: scoring-quality-calibration
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-08
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source of truth for validation design: the **Validation Architecture** section of `04-RESEARCH.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test (Dart) |
| **Config file** | none — uses existing `test/` tree + `flutter_test` |
| **Quick run command** | `flutter test test/core/scoring/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30-60 seconds full suite (pure-Dart scoring tests are sub-second; widget tests add a few seconds) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/core/scoring/` (pure-Dart, fast)
- **After every plan wave:** Run `flutter test` (full suite incl. widget tests)
- **Before `/gsd-verify-work`:** Full suite green + calibration harness asserts tuned per-letter tolerances
- **Max feedback latency:** ~60 seconds (full suite)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | SC#4 / S1-05 | T-04-02 | Pure-Dart value types, no I/O | unit | `flutter test test/core/scoring/tolerances_test.dart` | ❌ W0 | ⬜ pending |
| 04-01-02 | 01 | 1 | SC#1/SC#2 / S1-05 / PLAT-03 | T-04-01 | tolerances range-validated, no throw | unit | `flutter test test/core/scoring/ && flutter analyze` | ❌ W0 (RED contract) | ⬜ pending |
| 04-02-01 | 02 | 2 | SC#1/SC#3 / S1-05 | T-04-03, T-04-04 | in-memory points only, latency-bounded | unit | `flutter test test/core/scoring/letter_scorer_test.dart test/core/scoring/geometric_stroke_scorer_test.dart` | ❌ W0 | ⬜ pending |
| 04-02-02 | 02 | 2 | SC#3 / S1-05 | T-04-03 | normalization preserves dot position | unit | `flutter test test/core/scoring/` | ❌ W0 | ⬜ pending |
| 04-03-01 | 03 | 2 | SC#2 / S1-05 | T-04-07 | on-device only, no transmit | unit | `flutter test test/core/recognition/ml_kit_recognizer_test.dart` | ❌ W0 | ⬜ pending |
| 04-03-02 | 03 | 2 | D-05 / S1-05 | T-04-05, T-04-06 | best-effort, no hard-block | unit | `flutter test test/services/model_download_service_test.dart` | ❌ W0 | ⬜ pending |
| 04-04-01 | 04 | 3 | SC#1 / S1-05 | T-04-08 | accumulate in-memory only | widget | `flutter test test/features/practice/multi_stroke_capture_test.dart` | ❌ W0 | ⬜ pending |
| 04-04-02 | 04 | 3 | SC#1/SC#2/PLAT-03 / D-05 | T-04-09, T-04-10 | authored copy, getting-ready, advisory gate | unit+widget | `flutter test test/features/practice/getting_ready_test.dart test/core/scoring/mistake_mapping_test.dart` | ❌ W0 | ⬜ pending |
| 04-05-01 | 05 | 3 | SC#4 / S1-05 | T-04-11 | dev-only capture, fixtures only | analyze | `flutter analyze lib/dev/` | ✅ (extend) | ⬜ pending |
| 04-05-02 | 05 | 3 | SC#4 / PLAT-03 | T-04-12 | real scorer, no re-impl | unit/harness | `flutter test test/core/scoring/calibration_harness_test.dart` | ❌ W0 | ⬜ pending |
| 04-06-01 | 06 | 4 | SC#1/SC#3/SC#4 / D-01 | T-04-13, T-04-15 | real-tablet capture, coordinate-only | human-action | manual (real tablet + mother + children) | ❌ manual | ⬜ pending |
| 04-06-02 | 06 | 4 | SC#4 / D-01 | T-04-14 | load-time validated authored data | unit | `flutter test test/core/scoring/calibration_harness_test.dart && flutter analyze` | ❌ W0 | ⬜ pending |
| 04-06-03 | 06 | 4 | SC#4 | — | FN/FP tuned via data, no code change | decision | manual (harness FP/FN review with mother) | ❌ manual | ⬜ pending |
| 04-06-04 | 06 | 4 | SC#1/SC#3/SC#4 / D-01 | T-04-14 | signed-off, frozen regression | unit | `flutter test test/core/scoring/ test/features/practice/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Nyquist continuity check:** No 3 consecutive tasks lack an automated `<automated>` verify. The two manual checkpoints (04-06-01 human-action, 04-06-03 decision) are non-consecutive — each is bracketed by automated tasks (04-05-02 before, 04-06-02 after; 04-06-02 before, 04-06-04 after).

---

## Wave 0 Requirements

- [ ] `test/core/scoring/tolerances_test.dart` — preset→numeric expansion, normal==legacy constants (04-01)
- [ ] `test/core/scoring/letter_scorer_test.dart` — RED contract for SC#1/SC#2/D-04 (04-01, GREEN in 04-02)
- [ ] `test/core/recognition/ml_kit_recognizer_test.dart` — Ink-mapping with mocked plugin (04-03)
- [ ] `test/services/model_download_service_test.dart` — best-effort download, no-throw (04-03)
- [ ] `test/features/practice/multi_stroke_capture_test.dart` — accumulation closes the structural gap (04-04)
- [ ] `test/features/practice/getting_ready_test.dart` — model-not-ready degradation (04-04)
- [ ] `test/core/scoring/calibration_harness_test.dart` — confusion-table over real scoreLetter (04-05)
- [ ] `test/core/scoring/calibration_fixtures/` — labeled sample sets (synthetic seed 04-05 → real-tablet 04-06)
- [ ] Extend `geometric_stroke_scorer_test.dart` + `mistake_mapping_test.dart` for new multi-stroke / count / order / dot / identity paths (04-02, 04-04)
- [ ] Fake `HandwritingRecognizer` (mocktail) — no real ML Kit in unit tests (04-01/04-02/04-03)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| baa/taa/thaa authoring + sign-off; per-letter tolerance calibration against real child samples (FP/FN tuning with the owner's mother) | SC#4 / D-01 | Requires a real Android tablet + real child handwriting + the mother's pedagogical authority; cannot be emulator-captured (Pitfall 3) | Plan 06 Task 1 (capture/author) + Task 3 (tune): capture labeled samples via the authoring screen, run the harness, tune per-letter tolerances with the mother until FN/FP acceptable |
| ML Kit `ar` single-letter recognition quality on the target tablet | SC#2 / D-04 | On-device model behavior; needs a hardware spike (A4 / Open Q3) | Plan 06 Task 1: run the identity gate over a labeled set on the tablet, confirm confidently-different letters are caught without false rejects of correct ب/ت/ث |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are explicit manual checkpoints (no automatable task lacks one)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
