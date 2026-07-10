---
phase: 18
slug: build-the-living-tutor-dynamic-exercise-selection
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-11
updated: 2026-07-11 (post-planning sync — 11 plans, checker passed 0 blockers)
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `18-RESEARCH.md` → Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Dart `flutter_test` (client) + Python `pytest` (server) |
| **Config file** | `pubspec.yaml` (dev_dependencies), `server/pyproject.toml` (`[tool.pytest.ini_options]`, `markers = ["code"]`) |
| **Quick run command** | `flutter test <changed test>` (client) · `cd server && uv run pytest -m code -q` (server, model-free) |
| **Full suite command** | `flutter test` + `cd server && uv run pytest -m code`; phase gate adds `cd server && make eval` |
| **Estimated runtime** | ~60–120 seconds (model-free legs); `make eval` longer (Vertex judge) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test <changed test>` and/or `cd server && uv run pytest -m code -q` (model-free, no network)
- **After every plan wave:** Run full `flutter test` + `cd server && uv run pytest -m code`
- **Before `/gsd-verify-work`:** Full suite must be green AND `cd server && make eval` green (includes the new selection-policy dimension)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

> RED stubs authored by 18-01 (Wave 1, tasks T1–T3); "Plan" = plan(s) that turn the test GREEN.
> "File Exists" = ✅ W0 scheduled: 18-01 creates the file as a failing stub before any implementation task runs.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-01-T1 | 04, 07, 10 | 3→6 | SPEC-18-R1 anti-boredom + WHY line | — | N/A | unit + widget | `flutter test test/tutor/selection_policy_test.dart` | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T1 | 05, 06 | 3→4 | SPEC-18-R2 across-session memory | GROUND-04 | profile fields fixed-vocabulary, non-PII | fixture | `flutter test test/tutor/across_session_memory_test.dart` | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T1 | 02, 04, 07 | 2→5 | SPEC-18-R3 micro-drill selection | — | N/A | calibration-harness style | `flutter test test/tutor/microdrill_selection_test.dart` | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T1 | 04, 07 | 3→5 | SPEC-18-R4 remediation arc win-within-N | — | N/A | scenario/unit | `flutter test test/tutor/remediation_arc_test.dart` | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T1 | 07 | 5 | SPEC-18-R5 rails hold | agent untrusted | illegal proposals always degrade to walker | seeded-random property ≥200 iter (plain flutter_test) | `flutter test test/tutor/selection_rails_property_test.dart` | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T1 | 06, 07 | 4→5 | SPEC-18-R6 offline floor | — | practice path never blocks on network | integration | `flutter test test/tutor/offline_floor_test.dart` | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T3 | 02, 05 | 2→3 | SPEC-18-R7 word→per-letter×criterion evidence | D-13 | client never writes Firestore | fixture | `cd server && uv run pytest tests/test_evidence.py -m code` | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T3 | 09 | 4 | SPEC-18-R8 compiler + second-letter + PII guard | GROUND-04 | profile doc derived-only, non-PII (guard test) | unit | `cd server && uv run pytest tests/test_compile_profiles.py -m code` | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T2 | 03 | 2 | SPEC-18-R8 EMA Dart↔Python parity | — | N/A | unit ×2 | `flutter test test/core/scoring/criterion_ema_test.dart` + `cd server && uv run pytest tests/test_criterion_ema.py -m code` | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T3 | 08, 11 | 4→7 | SPEC-18-R9 selection-policy eval dimension | — | N/A | eval | `cd server && make eval` (+ `uv run pytest tests/test_eval/test_selection_dimension.py -m code`) | ✅ W0 scheduled (18-01) | ⬜ pending |
| 18-01-T2 | 05, 06 | 3→4 | D-14 wire digest guards | GROUND-04 / 422 lockstep | KEY-name guard + extra=forbid both sides | guard | `flutter test test/tutor/payload_nonpii_test.dart` + `cd server && uv run pytest tests/test_schema_forbid.py -m code` | partial (18-01 extends) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/tutor/selection_policy_test.dart` — Req 1 anti-boredom + WHY line
- [ ] `test/tutor/across_session_memory_test.dart` — Req 2 profile-in-facts + referencing pick
- [ ] `test/tutor/microdrill_selection_test.dart` — Req 3 calibration-harness-style drill selection
- [ ] `test/tutor/remediation_arc_test.dart` — Req 4 arc state machine + win-within-N
- [ ] `test/tutor/selection_rails_property_test.dart` — Req 5 seeded-random rails property
- [ ] `test/tutor/offline_floor_test.dart` — Req 6 airplane-mode coherence
- [ ] `test/core/scoring/criterion_ema_test.dart` + `server/tests/test_criterion_ema.py` — EMA parity
- [ ] `server/tests/test_evidence.py` — Req 7 word→per-letter×criterion evidence
- [ ] `server/tests/test_compile_profiles.py` — Req 8 compile + second-letter + PII guard
- [ ] `server/tests/test_eval/test_selection_dimension.py` + `selection_gold_set.jsonl` — Req 9
- [ ] Extend `test/tutor/payload_nonpii_test.dart` + `server/tests/test_schema_forbid.py` — D-14 guards

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Micro-drill content sign-off (D-07) | Req 3 | Curriculum is the mother's domain — content ships `signed:false` until she flips it | Present baa's 3-criterion drill set (~3–5 drills); record HUMAN-UAT; flip `signed:true` as the only content change |
| Arc-N threshold sign-off (D-02/D-04) | Req 4 | Pedagogy parameter is the mother's number | Present provisional N; record HUMAN-UAT; flip flag |
| α / EMA parameter sign-off (D-15) | Req 8 | Pedagogy parameter | Present provisional α with one-sentence explanation ("recent attempts count more"); record HUMAN-UAT |
| Selection eval threshold + gold set sign-off | Req 9 | Gate bar agreed with the mother; gold scenarios mother-signed | Review fail-streak / returning-child / boredom-trap scenarios; agree threshold; flip flag |
| Deploy gates (17-10 pattern) | Reqs 2/7/8 | Human-run infra steps | Server re-deploy (new wire fields, server ships FIRST) · Cloud Run Job + Scheduler creation · `child_models` owner-read rule deploy |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (checker verified across 18-01…18-11)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (checker Dimension-8 checks 8a–8d pass)
- [x] Wave 0 covers all MISSING references (18-01 authors every Wave-0 file; all consumers depend on 18-01)
- [x] No watch-mode flags
- [x] Feedback latency < 120s (model-free legs)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-11 (gsd-plan-checker: 0 blockers; Nyquist checks pass on plan content)
