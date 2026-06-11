---
phase: 6
slug: lesson-progression-home
status: planned
nyquist_compliant: true
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
| 06-01-T1/T3 | 06-01 | 1 | S1-01, S1-09 | T-06-05 | refs/requires integrity | unit | `flutter test test/models/lesson_progression_test.dart` | ❌ W0 (T1 creates) | ⬜ pending |
| 06-01-T2 | 06-01 | 1 | S1-01, S1-09 | T-06-05 | every items[].ref + requires[] resolves | unit | `flutter test test/data/curriculum_repository_test.dart` | ✅ extend | ⬜ pending |
| 06-02-T1/T2 | 06-02 | 1 | S1-09, D-10 migration | T-06-01, T-06-02 | LetterReps = letterId+count+timestamp only; reps persist; startingLessonId normalized; idempotent | unit (drift in-memory) | `flutter test test/data/app_database_test.dart` | ✅ extend | ⬜ pending |
| 06-02-T3 | 06-02 | 1 | S1-01 | T-06-02 | lesson-id namespace in resolver + tests | unit | `flutter test test/data/ test/features/onboarding/` | ✅ extend | ⬜ pending |
| 06-03-T1/T2 | 06-03 | 2 | S1-09 | — | recordMastery → stream → today recomputes, zero invalidate | provider | `flutter test test/providers/progression_providers_test.dart` | ❌ W0 (T1 creates) | ⬜ pending |
| 06-03-T3 | 06-03 | 2 | S1-01, S1-09 | T-06-03, T-06-06 | ?lesson= allowlist degrade; gate unaffected by query params | widget/router | `flutter test test/router/ test/features/practice/practice_screen_test.dart` | ✅ extend | ⬜ pending |
| 06-04-T1 | 06-04 | 3 | S1-09 (D-18) | T-06-07 | unknown preset → normal; override default-preserving | unit | `flutter test test/core/scoring/` | ✅ extend | ⬜ pending |
| 06-04-T2 | 06-04 | 3 | S1-09 (D-10/D-20) | T-06-01 | write-through incl. reset-to-0; ramp by persisted index; List<Offset> guard = 0 | unit | `flutter test test/features/practice/session_controller_test.dart` | ✅ extend | ⬜ pending |
| 06-05-T1 | 06-05 | 3 | S1-01 | T-06-08, T-06-09 | error degrades to startingLessonId; no gold ink-fill, no rep numerals; Test 4 reconciled | widget | `flutter test test/screens/home_screen_test.dart` | ✅ extend + reconcile | ⬜ pending |
| 06-05-T2 | 06-05 | 3 | S1-01 (D-13) | — | reduced-motion renders settled | widget | `flutter test test/screens/home_screen_test.dart` | ✅ extend | ⬜ pending |
| 06-06-T1/T2/T3 | 06-06 | 3 | S1-09 | T-06-03, T-06-09 | locked nodes inert; unknown ?highlight= no-op; canonical IDs | widget | `flutter test test/features/journey/journey_screen_test.dart` | ❌ W0 (T1 creates) | ⬜ pending |
| 06-07-T1/T2 | 06-07 | 4 | S1-09 (D-14/16/17) | T-06-03, T-06-09 | Next Lesson route from catalog-internal provider only; stale 167/220/74 reconciled; deliberate golden re-bake | widget + golden | `flutter test test/features/practice/practice_screen_test.dart test/features/practice/mastery_celebration_golden_test.dart` | ✅ extend/reconcile | ⬜ pending |
| 06-08-T1 | 06-08 | 5 | S1-09 (D-21) | — | normalization extraction default-preserving | widget/unit | `flutter test test/features/practice/stroke_order_animation_test.dart` | ✅ extend | ⬜ pending |
| 06-08-T2 | 06-08 | 5 | S1-09 (D-21) | T-06-04 | strokes in widget State only; practice_providers List<Offset> count = 0 | widget | `flutter test test/features/practice/ghost_comparison_test.dart` | ❌ new | ⬜ pending |

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
