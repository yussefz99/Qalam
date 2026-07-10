---
phase: 18
slug: build-the-living-tutor-dynamic-exercise-selection
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-11
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

> Task IDs filled by the planner; requirement-level map from RESEARCH.md below.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | — | — | Req 1 anti-boredom + WHY line | — | N/A | unit + widget | `flutter test test/tutor/selection_policy_test.dart` | ❌ W0 | ⬜ pending |
| TBD | — | — | Req 2 across-session memory | GROUND-04 | profile fields fixed-vocabulary, non-PII | fixture | `flutter test test/tutor/across_session_memory_test.dart` | ❌ W0 | ⬜ pending |
| TBD | — | — | Req 3 micro-drill selection | — | N/A | calibration-harness style | `flutter test test/tutor/microdrill_selection_test.dart` | ❌ W0 | ⬜ pending |
| TBD | — | — | Req 4 remediation arc win-within-N | — | N/A | scenario/unit | `flutter test test/tutor/remediation_arc_test.dart` | ❌ W0 | ⬜ pending |
| TBD | — | — | Req 5 rails hold | agent untrusted | illegal proposals always degrade to walker | seeded-random property (plain flutter_test) | `flutter test test/tutor/selection_rails_property_test.dart` | ❌ W0 | ⬜ pending |
| TBD | — | — | Req 6 offline floor | — | practice path never blocks on network | integration | `flutter test test/tutor/offline_floor_test.dart` | ❌ W0 | ⬜ pending |
| TBD | — | — | Req 7 word→per-letter×criterion evidence | D-13 | client never writes Firestore | fixture | `cd server && uv run pytest tests/test_evidence.py -m code` | ❌ W0 | ⬜ pending |
| TBD | — | — | Req 8 compiler + second-letter + PII guard | GROUND-04 | profile doc derived-only, non-PII (guard test) | unit | `cd server && uv run pytest tests/test_compile_profiles.py -m code` | ❌ W0 | ⬜ pending |
| TBD | — | — | Req 8 EMA Dart↔Python parity | — | N/A | unit ×2 | `flutter test test/core/scoring/criterion_ema_test.dart` + `cd server && uv run pytest tests/test_criterion_ema.py -m code` | ❌ W0 | ⬜ pending |
| TBD | — | — | Req 9 selection-policy eval dimension | — | N/A | eval | `cd server && make eval` (+ `uv run pytest tests/test_eval/test_selection_dimension.py -m code`) | ❌ W0 | ⬜ pending |
| TBD | — | — | D-14 wire digest guards | GROUND-04 / 422 lockstep | KEY-name guard + extra=forbid both sides | guard | `flutter test test/tutor/payload_nonpii_test.dart` + `cd server && uv run pytest tests/test_schema_forbid.py -m code` | partial (extend) | ⬜ pending |

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
