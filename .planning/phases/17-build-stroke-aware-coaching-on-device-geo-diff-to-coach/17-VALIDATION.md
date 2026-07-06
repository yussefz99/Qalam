---
phase: 17
slug: build-stroke-aware-coaching-on-device-geo-diff-to-coach
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-05
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `17-RESEARCH.md` § Validation Architecture. Task map filled from the
> final 10-plan set (plan-phase revision 1).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter 3.41.9) — client/scorer · pytest ≥8 via uv — server (`-m code` marker = model-free PR gate) |
| **Config file** | `pubspec.yaml` + `test/flutter_test_config.dart` (Arabic font loading); `server/pyproject.toml`; `server/Makefile` (`eval` / `eval-code` / `eval-judge`) |
| **Quick run command** | `flutter test test/core/scoring/` (66 tests, ~2 s) · `cd server && uv run pytest -m code -q` (78 passed, 1 skipped, ~0.5 s) — both verified green 2026-07-05 |
| **Full suite command** | `flutter test` (⚠ 9 known pre-existing failures — see baseline note) · `cd server && make eval` (needs Vertex ADC) |
| **Estimated runtime** | quick: <30 s combined · full: minutes (eval judge legs need ADC) |

**Full-suite baseline (do not chase, do not worsen):** 3 font-drift goldens (never re-bake),
`alif_reference`, `all_letters_validation`, `meet_section`, `write_surface`, `curriculum_repo_v2`.
`write_surface` is IN this phase's touch set — Plan 17-07 Task 1 reconciles it explicitly
(fix or re-baseline, recorded in the summary — never silently absorbed).

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/core/scoring/ test/tutor/` + `cd server && uv run pytest -m code -q`
- **After every plan wave:** Run `flutter test` (against the 9-failure baseline) + `cd server && make eval` (when ADC available; else `-m code` + defer judge legs to the phase gate)
- **Before `/gsd-verify-work`:** Full suite reconciled to baseline + `make eval` green + on-device HUMAN-UAT items + mom sign-off gates recorded (some may remain open as documented production gates per D-D)
- **Max feedback latency:** 30 seconds (quick commands)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | STRK-01 (D-A scorer) | — | N/A | unit (RED contract, inc 2) | `flutter test test/core/scoring/` | ❌ W0 (this task writes it) | ⬜ pending |
| 17-01-02 | 01 | 1 | STRK-01 (D-A scorer) | — | N/A | unit (RED contract, inc 3; F5 trap) | `flutter test test/core/scoring/` | ❌ W0 (this task writes it) | ⬜ pending |
| 17-02-01/02 | 02 | 2 | STRK-01 | — | N/A | unit (shapeDistance + SoftBand into scoreStroke; thresholds as data) | `flutter test test/core/scoring/` | ✓ from 17-01 | ⬜ pending |
| 17-03-01/02 | 03 | 3 | STRK-01 | T-17-05/06/07 | criteria hold only {criterion, zone, score} scalars | unit (per-form scorer + shared resolver) | `flutter test test/core/ && flutter analyze` | ✓ from 17-01 | ⬜ pending |
| 17-04-01 | 04 | 1 | EVAL-03 | T-17-10 | praise-lexicon floor stays zero-tolerance | eval (semantic faithfulness + `adv_broken_but_pass` no-false-geometry trap) | `cd server && uv run pytest tests/test_eval -m code -q` · `make eval` (judge legs) | ❌ W0 (this task writes it) | ⬜ pending |
| 17-04-02 | 04 | 1 | STRK-01, EVAL-03 | T-17-08/09 | gold cases signed:false, drafted_by claude; no geometry in facts | eval (variety/duplicate detector + two-arm baseline instrument) | `cd server && uv run pytest tests/test_eval -m code -q` | ❌ W0 (this task writes it) | ⬜ pending |
| 17-05-01 | 05 | 4 | GROUND-04, STRK-01 | T-17-11/13 | nested extra=forbid 422s any stray key; additive = server first | unit tdd (CriterionIn DTO + contract tests) | `cd server && uv run pytest -m code -q` | ❌ W0 (this task writes test_criteria_contract.py) | ⬜ pending |
| 17-05-02 | 05 | 4 | STRK-01 | T-17-12/14 | writtenWord stays HumanMessage DATA; logs exclude_none derived-only | unit tdd (criterion-aware addendum + trigger + logging) | `cd server && uv run pytest -m code -q` | ✓ extend test_grounding.py | ⬜ pending |
| 17-06-01 | 06 | 5 | GROUND-04, STRK-01 | T-17-11/12/13 | byte-for-byte mirror; whitelist + mirror-set + PII regex extended same-task | unit tdd (client mirror) | `flutter test test/tutor/` | ✓ extend (payload_nonpii, mirror-set, builder tests) | ⬜ pending |
| 17-07-01 | 07 | 6 | GROUND-04 (D-A cutover) | T-17-15/16/17 | strokeImage gone from lib/; verdict cannot be deferred or overturned | unit + grep-guard (client cutover; write_surface reconciled) | `flutter test test/tutor/ test/features/` | ❌ W0 (grep-guard test new) | ⬜ pending |
| 17-07-02 | 07 | 6 | GROUND-04 (D-A cutover) | T-17-16/17 | verdict applies before/without brain; failure only clears tutor line | widget test (BEHAVIORAL cutover pin) | `flutter test test/features/letter_unit/exercise_scaffold_cutover_test.dart` | ❌ W0 (new) | ⬜ pending |
| 17-08-01 | 08 | 7 | GROUND-04 | T-17-15/16/18 | strokeImage joins FORBIDDEN_KEYS (422 proves shrink); image_judge.py deleted | unit (server retirement) | `cd server && uv run pytest -m code -q && test ! -f app/image_judge.py` | ✓ shrink/extend | ⬜ pending |
| 17-08-02 | 08 | 7 | UAT F1 | — | N/A | widget test (English copy LTR under RTL ancestor) | `flutter test test/features/letter_unit/meet_section_ltr_test.dart` | ❌ W0 (new) | ⬜ pending |
| 17-09-01 | 09 | 4 | STRK-01 (D-A verdict) | T-17-19 | no real child strokes committed | fixtures (per-form baa + taa incl. F5 trap) | `flutter analyze test/core/scoring/calibration_fixtures/` | ❌ W0 (this task writes it) | ⬜ pending |
| 17-09-02 | 09 | 4 | STRK-01 (D-A verdict) | T-17-20 | fit report prints only; never mutates production values | calibration harness (letter × form confusion table; F5 cell == 0; PROVISIONAL fit report) | `flutter test test/core/scoring/calibration_harness_test.dart` | ✓ extend | ⬜ pending |
| 17-10-01 | 10 | 8 | GROUND-04 (ADR, SC-4) | T-17-23 | consent debt recorded | doc gate (ADR-017, owner-confirmed D-C amendment in §5) | `test -f docs/architecture/ADR-017-*.md && grep OWNER-CONFIRMED` | ❌ closing task | ⬜ pending |
| 17-10-02 | 10 | 8 | EVAL-03 (gates) | T-17-21/22 | zero `"signed": true` at close; deploy verified or explicit PENDING item | mixed (deploy + full sweep + HUMAN-UAT ledger) | `curl .../health` → 200 · `flutter test` vs baseline · `make eval` | ❌ closing task | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Human gates (mother / owner / device — tracked in 17-10's HUMAN-UAT ledger):** gold-set
re-sign (`"signed": true` flips only on her word), per-form signedOff queue (baa
initial/medial/final — demo scores them unsigned per OWNER-CONFIRMED A2, 2026-07-05),
calibration labelling on real child samples (D-D production gate), device F1–F6 re-walk,
consent copy for the derived-diff flow.

---

## Wave 0 Requirements

- [ ] `test/core/scoring/` — RED tests for `scoreStroke` soft-verdict via shapeDistance (inc 2): shaky-correct passes, flat-line fails, direction still a criterion — **17-01 T1**
- [ ] `test/core/scoring/letter_scorer_test.dart` (extend) — per-form scoring + `LetterScore` per-criterion structure + weakest-criterion selection (inc 3) — **17-01 T2**
- [ ] `test/core/scoring/calibration_fixtures/` — per-form baa fixtures incl. the F5 trap (isolated bowl offered for medial/final → FAIL) (inc 5) — **17-09 T1**
- [ ] `test/core/scoring/calibration_harness_test.dart` (extend) — per letter × form dimension + threshold-fit report (inc 5) — **17-09 T2**
- [ ] `test/tutor/payload_nonpii_test.dart` + mirror-set tests (extend) — `criteria` field (**17-06 T1**); strokeImage removal (**17-07 T1**)
- [ ] `test/features/` cutover tests: strokeImage grep-guard (**17-07 T1**) + behavioral D-A widget test (**17-07 T2**)
- [ ] `server/tests/` — `criteria` DTO tests (additive, defaults, 422 on extras) (inc 4) — **17-05 T1**
- [ ] `server/tests/test_eval/` — semantic faithfulness leg, no-false-geometry trap cases, duplicate/variety detector, two-arm specificity baseline (EVAL-03/STRK-01) — **17-04 T1+T2**
- [x] Framework install: none — all infrastructure exists

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Gold set re-signed | EVAL-03 | Pedagogy authority is the owner's mother | Mother reviews regrown stroke-level gold set; set `"signed": true` per case in `gold_set.jsonl` (17-10 ledger) |
| Threshold calibration on real child samples | D-D | Real child handwriting cannot be synthesized | Mother labels child samples; calibration harness fits soft-band thresholds; provisional synthetic values acceptable for demo only (17-10 ledger) |
| On-device UAT (F1–F6 regression) | UAT-FULL-2026-07-01 | Device rendering/latency not reproducible in CI | Re-run the F1–F6 punch-list on the tablet/iPad with the app running (17-10 ledger) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (every ❌ W0 row names the task that writes it)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-05 (plan-phase revision 1)
