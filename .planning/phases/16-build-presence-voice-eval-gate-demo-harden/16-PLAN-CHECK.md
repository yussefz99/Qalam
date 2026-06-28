# Phase 16 — Pre-Execution Plan Check

**Verdict:** PASS (with 4 non-blocking WARNINGS)
**Checked:** 2026-06-29
**Plans verified:** 6 (16-01 … 16-06)
**Requirements:** PRES-01, PRES-02, EVAL-01, EVAL-02, DEMO-01 — all covered

## VERIFICATION PASSED

All 5 phase requirement IDs are present in at least one plan's `requirements`
frontmatter AND have covering tasks + user-observable must_haves. SC#4 (per-node
model verdict) is covered by plan 06 (Enable checkpoint + bake-off + ADR-016).

### Coverage

| Req | Plans (frontmatter) | Covering tasks | Status |
|-----|--------------------|----------------|--------|
| PRES-01 | 04 | 04-T1 (reflex stays local), 04-T3 (device latency budget) | Covered |
| PRES-02 | 01,02,04 | 01-T2 RED, 02-T3 TtsCoachSpeaker, 04-T1 speak hook | Covered |
| EVAL-01 | 01,03,05 | 01-T2 RED, 03-T2 harness+judge+gold draft, 05 mom-sign+calibrate | Covered |
| EVAL-02 | 01,03 | 01-T2 RED, 03-T3 `make eval` gate | Covered |
| DEMO-01 | 06 | 06-T1 seed, 06-T2 device-harden | Covered |
| SC#4 | 06 | 06-T3 Enable, 06-T4 bake-off + ADR-016 | Covered |

### Plan / dependency / scope summary

| Plan | Tasks | Files | Wave | depends_on | autonomous | Status |
|------|-------|-------|------|------------|-----------|--------|
| 01 | 2 | 7 | 1 | [] | true | Valid |
| 02 | 3 | 5 | 2 | [01] | false | Valid |
| 03 | 3 | 10 | 2 | [01] | true | Valid (files borderline) |
| 04 | 3 | 5 | 3 | [02] | false | Valid |
| 05 | 2 | 4 | 3 | [03] | false | Valid |
| 06 | 4 | 5 | 4 | [04,05] | false | Valid (tasks borderline) |

Dependency graph: acyclic; all references exist; wave = max(deps)+1 consistent;
no forward references.

### Dimension results

- **D1 Requirement coverage:** PASS — all 5 IDs + SC#4 covered.
- **D2 Task completeness:** PASS — every task has read_first + acceptance_criteria;
  every plan has exactly one threat_model; auto/tdd tasks have files/action/verify;
  checkpoints use human-check correctly. Zero fenced code blocks in any action.
- **D3 Dependency correctness:** PASS — acyclic, valid, wave-consistent.
- **D4 Key links planned:** PASS — TTS→exercise_scaffold, warm-up→/health,
  faithfulness→make eval, gold→judge calibration→bake-off all wired with concrete hooks.
- **D5 Scope sanity:** PASS with WARNINGS — 06 has 4 tasks (2 are human-checks),
  03 touches 10 files (mostly small new test_eval files). Borderline, not blocking.
- **D6 Verification derivation:** PASS — truths are user-observable
  (speaks in airplane mode, floor takes over invisibly, hero moment on cue).
- **D7 Context compliance:** PASS — D-01..D-13 all honored; deferred ideas
  (cloud TTS, CI, Gemma-shipping, STT, other letters) all correctly EXCLUDED.
- **D7b Scope reduction:** PASS — NO reduction of any locked decision. Plans deliver
  full scope (faithfulness grown to every-mistake, real LLM-judge, on-device latency
  measured, real mom sign-off). "optional/nice-to-have" matches are D-05-sanctioned only.
- **D7c Architectural tier compliance:** PASS — every capability assigned to the tier
  the Responsibility Map specifies; scorer/star stays local-authoritative, coach stays
  server-side, TTS on-device, auth at /coach API tier.
- **D8 Nyquist:** PASS — VALIDATION.md exists (8e gate); Wave-0 RED contract in 01-T2;
  every implementation task has an automated verify; no watch-mode; no 3-consecutive
  tasks without automated verify; MISSING test files created in Wave 1 before dependents.
- **D9 Cross-plan data contracts:** PASS — RED-symbol contract, gold-set signed-flag
  chain, env-swap routing, faithfulness_set grow — all clean grow/flip/consume, no
  conflicting transforms.
- **D10 CLAUDE.md compliance:** PASS — keyless Vertex (no Anthropic key; only removal),
  Riverpod-only (explicit), anti-gamification (one quiet star, scorer owns it,
  never pre-awarded), Python backend, Android-only (no iOS), grounding invariant
  (ADR-014: applyResult first/unchanged, TTS display-only, seed never pre-awards).
- **D11 Research resolution:** WARNING — see below.
- **D12 Pattern compliance:** PASS — PATTERNS.md exists; plans reference the named
  analogs (asset_audio_player/audio_providers for TTS; faithfulness_set/test_faithfulness
  for eval; ChatAnthropicVertex pattern) and verified-existing seams.

### Seam verification (all confirmed to exist with referenced symbols/lines)

- server/app/models.py — build_coach_model (83-97), COACH_MODEL_PROVIDER (39),
  COACH_TIMEOUT_SECONDS, _provider_kwargs, env defaults (28-41). Confirmed.
- server/app/faithfulness.py — evaluate_faithfulness, _contradicts, _PRAISE (incl. أحسنت). Confirmed.
- server/tests/fixtures/faithfulness_set.jsonl — keys passed/mistakeId/expectedFix/coaching/label. Confirmed.
- server/app/main.py — GET /health (61-68), documents /health-not-/healthz. Confirmed.
- lib/features/letter_unit/widgets/exercise_scaffold.dart — _onResult (169), applyResult first (171),
  brain.next().then (206), set() (212), if(!mounted) (207), _clear (229-234), _lineOf (221). Confirmed.
- lib/services/asset_audio_player.dart, lib/providers/audio_providers.dart — analogs exist. Confirmed.
- lib/tutor/tutor_providers.dart — tutorBaseUrlProvider (28-29), tutorHttpClientProvider (34),
  tutorBrainFactoryProvider (71). Confirmed.
- lib/data/graph_position_repository.dart — GraphPosition, getPosition/setPosition,
  GraphPositionRepository. Confirmed.
- lib/curriculum/curriculum_graph_walker.dart — remediateOneTier. Confirmed.
- lib/tutor/exercise_selector_provider.dart — RouterExerciseSelector, nextForward, remediateOneTier. Confirmed.
- lib/curriculum/mastery_condition.dart — isMasteryMet, isMasteryMetForPresented. Confirmed.

## WARNINGS (non-blocking; recommended before/at execution, do not gate)

```yaml
issues:
  - dimension: research_resolution
    severity: warning
    description: >
      16-RESEARCH.md "## Open Questions" lacks the (RESOLVED) heading suffix and the
      three questions carry no inline RESOLVED marker (#1602 expects them). In substance
      all three ARE resolved by a Recommendation that the plans implement:
      Q1 (Claude Enable) -> 06-T3 human-Enable checkpoint + all-Gemini default;
      Q2 (judge model) -> gemini-2.5-flash judge in 03/05;
      Q3 (first-TTS latency) -> measured on-device in 04-T3.
    file: "16-RESEARCH.md"
    fix: >
      Rename to "## Open Questions (RESOLVED)" and append "— RESOLVED: <pointer>" to each
      of Q1/Q2/Q3. Cosmetic; the plans already deliver the resolutions.

  - dimension: validation_derivation
    severity: warning
    description: >
      16-VALIDATION.md frontmatter is stale vs the plans: nyquist_compliant: false,
      wave_0_complete: false, and "Approval: pending". The 6 plans satisfy the Nyquist
      contract (Wave-0 RED in 01-T2; automated verifies throughout; no 3-consecutive gap).
    file: "16-VALIDATION.md"
    fix: >
      Flip nyquist_compliant: true and wave_0_complete: true and set Approval once the
      Wave-0 RED files are created in 01-T2 (or pre-flip now since the contract is met).

  - dimension: scope_sanity
    severity: warning
    plan: "06"
    description: >
      Plan 06 has 4 tasks (warning threshold). Mitigated: 2 of the 4 are human-check
      checkpoints (device-harden, Model-Garden Enable) with no implementation burden;
      only seedDemoState (small) + the ADR/bake-off carry code/doc work.
    fix: >
      Acceptable as-is. If desired, split the bake-off+ADR (T4) into its own wave-4 plan
      to keep each plan at <=3 tasks.

  - dimension: scope_sanity
    plan: "03"
    severity: warning
    description: >
      Plan 03 touches 10 files (warning threshold). Mitigated: 7 are new, small,
      cohesive test_eval/ files (gold_set.jsonl, JUDGE_RUBRIC.md, run_judge.py,
      run_eval.py, test_eval_harness.py, __init__.py, Makefile) + 3 grown existing.
      The work is one cohesive deliverable (the eval gate).
    fix: >
      Acceptable as-is. If context pressure appears at execution, the gold-set DRAFT +
      JUDGE_RUBRIC could be split from the harness runner.
```

## Recommendation

**Proceed to execution.** Zero blockers. The 4 warnings are cosmetic/borderline and
do not threaten goal achievement. The plans are exceptionally well-grounded: every code
seam was verified to exist with the exact symbols and line numbers referenced; the
grounding invariant (ADR-014) is preserved at every voice/seed touchpoint; the keyless-
Vertex / no-Anthropic-key posture (D-02) is enforced by a grep gate; the eval gate grows
the existing faithfulness seed (no new engine) with zero-tolerance D1 + a calibrated
Gemini judge (!= coach); and all-Gemini-keyless is the demonstrable shippable default so
every Success Criterion holds even if the Claude Enable never happens.

Optionally apply WARNING fixes 1 and 2 (cosmetic marker/frontmatter flips) before
execution; warnings 3 and 4 need no action.
