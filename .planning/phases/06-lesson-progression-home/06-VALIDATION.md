---
phase: 6
slug: lesson-progression-home
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-11
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK) + golden tests with bundled-font loading via `test/flutter_test_config.dart` |
| **Config file** | `test/flutter_test_config.dart` |
| **Quick run command** | `flutter test test/<touched_file>.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~90 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test <touched test files>` (< 30s each)
- **After every plan wave:** Run `flutter test` (full suite; known-failing set must not grow beyond documented font-drift goldens)
- **Before `/gsd-verify-work`:** Full suite green except documented environmental golden drift; device UAT human-gated end-of-phase
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| *(filled by planner)* | | | S1-01 | — | N/A | unit | `flutter test test/models/lesson_progression_test.dart` | ❌ W0 | ⬜ pending |
| *(filled by planner)* | | | S1-01 | — | N/A | widget | `flutter test test/screens/home_screen_test.dart` | ✅ extend | ⬜ pending |
| *(filled by planner)* | | | S1-09 | — | N/A | unit | `flutter test test/models/lesson_progression_test.dart` | ❌ W0 | ⬜ pending |
| *(filled by planner)* | | | S1-09 | — | N/A | provider | `flutter test test/providers/progression_providers_test.dart` | ❌ W0 | ⬜ pending |
| *(filled by planner)* | | | S1-09 | — | N/A | widget | `flutter test test/features/journey/journey_screen_test.dart` | ❌ W0 | ⬜ pending |
| *(filled by planner)* | | | D-10 migration | — | reps persist; startingLessonId normalized | unit | `flutter test test/data/app_database_test.dart` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/models/lesson_progression_test.dart` — covers S1-01/S1-09 pure logic (D-02/D-05/D-06/D-11 states)
- [ ] `test/providers/progression_providers_test.dart` — stream-driven immediacy (S1-09)
- [ ] `test/features/journey/journey_screen_test.dart` — live nodes, canonical IDs, D-07 taps, D-15 highlight
- [ ] Reconciliation list: `home_screen_test.dart:204` (Test 4), `mastery_celebration_golden_test.dart:74`, `practice_screen_test.dart:167,220` — stale 03.1 assertions Phase 6 must rewrite, not regress against
- [ ] Framework install: none needed — existing infrastructure covers all phase requirements

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Device UAT: launch-to-today's-lesson flow on real tablet | S1-01 | Stylus + real device behavior not emulatable | Fresh launch → land on today's lesson card → single Start → trace → pass → next lesson unlocks |
| Golden re-bake for legitimately-changed celebration screen | D-14 | Local font drift muddies baselines (environmental, see memory) | Re-bake only on the canonical baking environment; keep separate from font-drift failures |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
