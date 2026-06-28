---
phase: 16
slug: build-presence-voice-eval-gate-demo-harden
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-29
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from 16-RESEARCH.md "Validation Architecture". Per-task IDs are assigned by the planner;
> this draft fixes the framework, commands, sampling rate, Wave 0 gaps, and per-requirement test map.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (server)** | `pytest` 8.x + `pytest-asyncio` 0.24 (`asyncio_mode=auto`); marker `code` registered |
| **Framework (client)** | `flutter test` (widget/unit) |
| **Config file** | `server/pyproject.toml` (`[tool.pytest.ini_options]`) |
| **Quick run command** | `cd server && uv run pytest -m code -q` (model-free, offline) + `flutter test` for touched client files |
| **Full suite command** | `cd server && uv run pytest -q` ; `flutter test` ; `make eval` (LLM-judge, calibrated) |
| **Estimated runtime** | quick ~30s ; full + `make eval` ~minutes (LLM-judge calls Vertex) |

---

## Sampling Rate

- **After every task commit:** Run `cd server && uv run pytest -m code -q` (faithfulness + grounding, model-free, <30s) + `flutter test` for touched client files
- **After every plan wave:** Run full `cd server && uv run pytest -q` + `make eval` + `flutter test`
- **Before `/gsd-verify-work`:** `make eval` green (D1 faithfulness = 100%; D5 register / D2 specific-fix ≥ threshold) + full suites green + PRES-01 latency budget measured & recorded on the Pixel Tablet
- **Max feedback latency:** ~30 seconds for the model-free quick gate

---

## Per-Task Verification Map

> Requirement-granularity seed (plans not yet written). The planner assigns concrete Task IDs and
> maps each to one of these commands; the nyquist-auditor confirms no 3 consecutive tasks lack an
> automated verify.

| Req | Behavior | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-----|----------|------------|-----------------|-----------|-------------------|-------------|--------|
| EVAL-01 | Faithfulness rate over labeled set (zero-tolerance, model-free) | grounding (ADR-014) | praise-on-fail / wrong-fix fails the build | unit/code | `cd server && uv run pytest tests/test_faithfulness.py -m code -x` | ✅ grow seed | ⬜ pending |
| EVAL-01 | Register + correct-Arabic scored by Vertex LLM-judge vs rubric | privacy (D-10) | no training on child transcripts; synthetic gold set | integration | `make eval` → `uv run python tests/test_eval/run_judge.py` | ❌ W0 | ⬜ pending |
| EVAL-02 | Gate fails the build below threshold (documented pre-merge) | — | gate exits non-zero on D1<100% or D5/D2 below threshold | gate | `make eval` (exit code) | ❌ W0 | ⬜ pending |
| EVAL-02 / D-13 | Coach bake-off Gemini-vs-Claude on the same labeled set | — | eval picks the winner (no self-grading) | integration | `COACH_MODEL_PROVIDER=anthropic_vertex COACH_LOCATION=global make eval` vs Gemini | ❌ W0 | ⬜ pending |
| PRES-02 | Mixed-script segmentation + Arabic-voice-availability graceful degrade | info-disclosure | voices non-PII coach text on-device only | unit (no device) | `flutter test test/tutor/tts_coach_speaker_test.dart` | ❌ W0 | ⬜ pending |
| PRES-01 / DEMO-01 | Warm-up `/health` ping + timeout → AuthoredFallback (no dead end) | access-control | unauthenticated `/health` carries no data | code/fault-injection | `cd server && uv run pytest tests/test_endpoint.py -m code` (503→fallback) + a `/health` test | ✅ partial | ⬜ pending |
| D-02 | All nodes route keyless Vertex (no Anthropic key in deploy contract) | cred-exposure | keyless ADC; leftover key refs removed | code/config | `cd server && uv run pytest -m code -q` + grep deploy contract has no `ANTHROPIC_API_KEY` | ✅ partial | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `server/tests/test_eval/` — labeled (verdict, learner-state) cases (grow from `faithfulness_set.jsonl`) + the Vertex LLM-judge runner (D-09/D-10)
- [ ] `server/Makefile` (or `server/tests/test_eval/run_eval.py`) — the `make eval` gate that exits non-zero below threshold (D-07/D-08)
- [ ] The **mom-signed gold set** file (Claude drafts → mother reviews + signs) — D-09; JSONL mirroring the existing fixture is the lowest-friction format
- [ ] `test/tutor/tts_coach_speaker_test.dart` — pure-Dart segmentation + availability-degrade unit tests
- [ ] LLM-judge calibration record (≥0.7 correlation vs mom labels) before the judge is trusted

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First-TTS latency + full stroke→…→first-TTS budget on real hardware | PRES-01 | Device timing can't be unit-tested; ROADMAP hint=no (measured in-phase) | Run the seeded demo on the Pixel Tablet; record timestamps at scorer-verdict, /coach send, /coach receive, render, first-TTS audio; compare to the written budget (warm vs cold-start) |
| Arabic Google-TTS voice presence on the stock Pixel Tablet | PRES-02 | Device voice-data availability is environment-specific | On the Pixel Tablet, confirm `isLanguageAvailable('ar')`; verify the Arabic token speaks, or that it degrades to English-only without a gap |
| Mom sign-off on the gold-set coaching examples | EVAL-01 / D-09 | Register authority is the owner's mother (human sign-off gate) | Owner's mother reviews + signs the Claude-drafted (verdict → ideal-coaching) examples before the judge is calibrated against them |
| Model-Garden **Enable** for Claude Haiku 4.5 (if adopting the Claude coach) | D-03 / SC#4 | One-time human console click (terms acceptance); separate from IAM | Owner opens Model Garden → Claude Haiku 4.5 card → Enable; verify with a `rawPredict` 200 probe before the bake-off |
| Seeded demo state fires backward-remediation on cue | DEMO-01 / D-12 | Repeatable on-stage behavior judged by observation | Launch the seeded state; confirm the wobble → easier-exercise re-surface → spoken fix → one quiet star runs with no dead ends, repeatably |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (model-free quick gate)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-29 (plan-checker VERIFICATION PASSED — Nyquist PASS, no 3-consecutive gap)
