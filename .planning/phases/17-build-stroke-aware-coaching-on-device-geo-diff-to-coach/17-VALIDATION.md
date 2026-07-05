---
phase: 17
slug: build-stroke-aware-coaching-on-device-geo-diff-to-coach
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-05
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `17-RESEARCH.md` § Validation Architecture.

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
`write_surface` is IN this phase's touch set — its pre-existing failure must be reconciled or
explicitly re-baselined in the plan, not silently absorbed.

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/core/scoring/ test/tutor/` + `cd server && uv run pytest -m code -q`
- **After every plan wave:** Run `flutter test` (against the 9-failure baseline) + `cd server && make eval` (when ADC available; else `-m code` + defer judge legs to the phase gate)
- **Before `/gsd-verify-work`:** Full suite reconciled to baseline + `make eval` green + on-device HUMAN-UAT items + mom sign-off gates recorded (some may remain open as documented production gates per D-D)
- **Max feedback latency:** 30 seconds (quick commands)

---

## Per-Task Verification Map

*Plan/Wave/Task IDs to be filled by the planner; rows below are the requirement-level contract from RESEARCH.md.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | STRK-01 | — | N/A | eval (two-arm baseline: variety/duplicate model-free leg + Vertex-judge specificity leg) | `cd server && uv run pytest tests/test_eval -m code -q` · `make eval` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | STRK-01 (transport) | — | no exemplar parroting | unit (server) | `cd server && uv run pytest tests/test_grounding.py tests/test_endpoint.py -m code -q` | ✅ partial / ❌ criteria W0 | ⬜ pending |
| TBD | TBD | TBD | GROUND-04 | T: PII exfil | no raw stroke coords/PII in any payload; extras 422 | unit (both sides) | `flutter test test/tutor/payload_nonpii_test.dart` · `cd server && uv run pytest tests/test_payload_nonpii.py -m code -q` | ✅ extend | ⬜ pending |
| TBD | TBD | TBD | GROUND-04 (contract) | T: 422 window | client/server field sets match byte-for-byte | unit (mirror-set) | `flutter test test/tutor/` | ✅ extend | ⬜ pending |
| TBD | TBD | TBD | GROUND-04 (ADR) | — | N/A | human/doc gate | file exists at `docs/architecture/ADR-0XX-*.md` (checklist in VERIFICATION.md) | ❌ closing task | ⬜ pending |
| TBD | TBD | TBD | EVAL-03 | — | N/A | eval (Vertex judge + trap fixtures) | `cd server && make eval` (incl. `adv_broken_but_pass` false-geometry trap + paraphrase FAITHFUL cases) | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | EVAL-03 (floor intact) | — | N/A | unit (model-free) | `cd server && uv run pytest tests/test_faithfulness.py tests/test_eval/test_eval_harness.py -m code -q` | ✅ keep green | ⬜ pending |
| TBD | TBD | TBD | EVAL-03 (gold set) | — | N/A | human gate (mother) | grep `"signed": true` in `gold_set.jsonl` behind human-verify checkpoint | ❌ human gate | ⬜ pending |
| TBD | TBD | TBD | D-A scorer (verdict correctness) | — | N/A | unit + calibration harness (Dart) | `flutter test test/core/scoring/` — per letter × form confusion table; F5 cell == 0 | ◐ fixtures W0 | ⬜ pending |
| TBD | TBD | TBD | D-A cutover | — | `strokeImage` absent from payload construction | unit + grep-guard | `flutter test test/features/` + payload grep-guard test | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | UAT F1–F6 | — | N/A | mixed | E4/register leg under `make eval`; F1 widget test; F6 server test on word facts | ◐ partial | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/core/scoring/` — RED tests for `scoreStroke` soft-verdict via shapeDistance (inc 2): shaky-correct passes, flat-line fails, direction still a criterion
- [ ] `test/core/scoring/letter_scorer_test.dart` (extend) — per-form scoring + `LetterScore` per-criterion structure + weakest-criterion selection (inc 3)
- [ ] `test/core/scoring/calibration_fixtures/` — per-form baa fixtures incl. the F5 trap (isolated bowl offered for medial/final → FAIL) (inc 5)
- [ ] `test/core/scoring/calibration_harness_test.dart` (extend) — per letter × form dimension + threshold-fit report (inc 5)
- [ ] `test/tutor/payload_nonpii_test.dart` + mirror-set tests (extend) — `criteria` field; strokeImage removal (inc 4/6)
- [ ] `test/features/` cutover tests + strokeImage grep-guard (inc 6)
- [ ] `server/tests/` — `criteria` DTO tests (additive, defaults, 422 on extras) (inc 4)
- [ ] `server/tests/test_eval/` — semantic faithfulness leg, no-false-geometry trap cases, duplicate/variety detector, two-arm specificity baseline (EVAL-03/STRK-01)
- [ ] Framework install: none — all infrastructure exists

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Gold set re-signed | EVAL-03 | Pedagogy authority is the owner's mother | Mother reviews regrown stroke-level gold set; set `"signed": true` per case in `gold_set.jsonl` |
| Threshold calibration on real child samples | D-D | Real child handwriting cannot be synthesized | Mother labels child samples; calibration harness fits soft-band thresholds; provisional synthetic values acceptable for demo only |
| On-device UAT (F1–F6 regression) | UAT-FULL-2026-07-01 | Device rendering/latency not reproducible in CI | Re-run the F1–F6 punch-list on the tablet/iPad with the app running |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
