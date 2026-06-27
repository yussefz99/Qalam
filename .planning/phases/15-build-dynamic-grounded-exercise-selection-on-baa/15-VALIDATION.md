---
phase: 15
slug: build-dynamic-grounded-exercise-selection-on-baa
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-27
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `15-RESEARCH.md` § Validation Architecture. Dual-stack: Python server (pytest) + Flutter client (flutter_test).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (server)** | `pytest` 9.1.1 + `pytest-asyncio` 1.4.0 (`pytest.mark.code` for model-free CI-gating checks) |
| **Framework (client)** | `flutter_test` (Dart) — unit + widget |
| **Config file (server)** | `server/pyproject.toml` (`[tool.pytest.ini_options]`, `asyncio_mode=auto`) |
| **Config file (client)** | `test/flutter_test_config.dart` (loads bundled fonts for Arabic goldens) |
| **Quick run command (server)** | `cd server && uv run pytest tests/test_plan_graph.py tests/test_faithfulness.py -q` |
| **Quick run command (client)** | `flutter test test/curriculum/ test/tutor/` |
| **Full suite command (server)** | `cd server && uv run pytest -q` |
| **Full suite command (client)** | `flutter test` |
| **Estimated runtime** | server ~20s · client ~60s |

---

## Sampling Rate

- **After every task commit:** Run the relevant quick command (`uv run pytest tests/test_plan_graph.py -q` for server graph-rail tasks, or `flutter test test/curriculum/` for Dart graph/walker/mastery tasks).
- **After every plan wave:** Run both full suites (`uv run pytest -q` + `flutter test`).
- **Before `/gsd-verify-work`:** Both suites must be green.
- **Max feedback latency:** ~60 seconds (client full suite).

---

## Per-Task Verification Map

> Task IDs are assigned at plan time. The rows below are keyed by requirement + observable behavior (from RESEARCH.md § Phase Requirements → Test Map); the planner binds each to a concrete `{15-PP-TT}` task ID and wave.

| Requirement | Behavior (observable) | Test Type | Automated Command | File Exists | Status |
|-------------|-----------------------|-----------|-------------------|-------------|--------|
| DYN-01 | Plan node, given a repeated `shallowBowl` struggle, selects a trace-drill within the reachable tier (not a forward jump) | server unit | `uv run pytest tests/test_plan_graph.py::test_struggle_selects_within_tier -q` | ❌ W0 | ⬜ pending |
| DYN-01 | G5 rejects an exercise in an unreached tier → degrade | server unit | `uv run pytest tests/test_plan_graph.py::test_unreached_tier_rejected -q` | ❌ W0 | ⬜ pending |
| DYN-01 | G6 rejects an exercise whose prerequisite competency is uncleared | server unit | `uv run pytest tests/test_plan_graph.py::test_prereq_unmet_rejected -q` | ❌ W0 | ⬜ pending |
| DYN-01 | Backward remediation (ghayrManzur fail → manzur) is graph-LEGAL (NOT rejected) | server unit | `uv run pytest tests/test_plan_graph.py::test_backward_remediation_allowed -q` | ❌ W0 | ⬜ pending |
| DYN-01 | An unauthored/unsigned id is still rejected (G4 unchanged) | server unit | extend `tests/test_grounding.py` | ✅ | ⬜ pending |
| DYN-01 | Offline walker: pass → next forward node; fail → one tier down | client unit | `flutter test test/curriculum/curriculum_graph_walker_test.dart` | ❌ W0 | ⬜ pending |
| DYN-02 | Re-entering the baa unit restores persisted graph position across a simulated restart | client unit | `flutter test test/data/graph_position_repository_test.dart` | ❌ W0 | ⬜ pending |
| DYN-02 | The dynamic flow (not the fixed section switch) drives the unit; a fail re-surfaces a remediation exercise | client widget | `flutter test test/features/letter_unit/dynamic_selection_test.dart` | ❌ W0 | ⬜ pending |
| DYN-02 | One quiet star fires ONLY when `isMasteryMet` (essential core at mom's reps); NOT on navigation | client unit | `flutter test test/curriculum/mastery_condition_test.dart` | ❌ W0 | ⬜ pending |
| DYN-02 | `recordMastery` is NOT called for a clicked-through unit with unmet reps | client widget | extend `test/features/letter_unit/letter_unit_screen_test.dart` | ✅ | ⬜ pending |
| GROUND-03 | The check flags coaching that praises a failed stroke | server unit | `uv run pytest tests/test_faithfulness.py::test_flags_praise_on_fail -q` | ❌ W0 | ⬜ pending |
| GROUND-03 | The check flags coaching that names the wrong fix | server unit | `uv run pytest tests/test_faithfulness.py::test_flags_wrong_fix -q` | ❌ W0 | ⬜ pending |
| GROUND-03 | The check reports a faithfulness RATE (printed/asserted) | server unit | `uv run pytest tests/test_faithfulness.py::test_faithfulness_rate_reported -s -q` | ❌ W0 | ⬜ pending |
| GROUND-02 (regression) | Enlarged FACTS (clearedTiers/clearedCompetencies) carry no PII/strokes | client + server | extend `test/tutor/payload_nonpii_test.dart` + `server/tests/test_payload_nonpii.py` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `server/tests/test_plan_graph.py` — DYN-01 graph rail (G5/G6/remediation), monkeypatching the plan model like `test_grounding.py`
- [ ] `server/tests/test_faithfulness.py` + `server/tests/fixtures/faithfulness_set.jsonl` — GROUND-03
- [ ] `test/curriculum/curriculum_graph_test.dart`, `curriculum_graph_walker_test.dart`, `mastery_condition_test.dart` — the pure-Dart graph/walker/mastery
- [ ] `test/data/graph_position_repository_test.dart` — D-08 resume (simulated-restart shape, mirrors Phase 09's persisted-cooldown test)
- [ ] `test/features/letter_unit/dynamic_selection_test.dart` — DYN-02 end-to-end dynamic flow
- [ ] Extend `payload_nonpii_test.dart` / `test_payload_nonpii.py` for the two new FACTS fields
- [ ] Framework install: none (pytest + flutter_test both present)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Deployed-server online path: live `/coach` selects + coaches on a real device | DYN-01, DYN-02 | Live `/coach` needs App Check + a real model; can't run in CI (mirrors Phase-14 UAT gate) | Run on device with `--dart-define=TUTOR_BASE_URL=<cloud-run>`; trace baa, fail a stroke, confirm a remediation exercise re-surfaces |
| Curriculum-graph pedagogy (tier mapping, clean-rep counts, 70/30 split) | DYN-01, DYN-02 | New curriculum data → owner-mother's domain; provisional until signed (D-05) | Owner-mother reviews the drafted 19-config sign-off sheet at tier level and signs; flip `signedOff:true` only after sign-off |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
