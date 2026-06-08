---
phase: 5
slug: profiles-onboarding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 05-RESEARCH.md "Validation Architecture". Per-task IDs are assigned by the planner.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK) + `ProviderScope` for Riverpod; goldens via `test/flutter_test_config.dart` |
| **Config file** | `test/flutter_test_config.dart` (loads bundled TTFs for Arabic goldens) |
| **Quick run command** | `flutter test test/data/child_profile_repository_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30–60 seconds (full suite) |

**Precedents to mirror:** `test/data/app_database_test.dart` and `test/data/progress_repository_test.dart`
(use `NativeDatabase.memory()` injected into `AppDatabase` via its `QueryExecutor` constructor arg),
`test/router/demo_routes_test.dart` (router/route tests), `test/screens/home_screen_test.dart` (screen widget tests).

---

## Sampling Rate

- **After every task commit:** Run the touched test file (e.g. `flutter test test/data/child_profile_repository_test.dart`)
- **After every plan wave:** Run `flutter test test/data/ test/features/onboarding/ test/router/`
- **Before `/gsd-verify-work`:** `flutter test` (full suite green) + `flutter analyze` (exit 0)
- **Max feedback latency:** ~60 seconds

---

## Per-Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| S1-02 | Profile persists locally across restarts; grade resolves to `startingLessonId` (default `alif`) | unit (in-memory Drift) | `flutter test test/data/child_profile_repository_test.dart` | ❌ W0 | ⬜ pending |
| S1-02 | `gradeToStartingLessonId` maps every grade option; default = `alif` | unit | `flutter test test/features/onboarding/onboarding_data_test.dart` | ❌ W0 | ⬜ pending |
| S1-02 | v2→v3 migration creates `ChildProfiles`, preserves `LetterMastery` rows | unit (migration) | `flutter test test/data/app_database_test.dart` | ✅ extend | ⬜ pending |
| S1-03 | Avatar + nickname are fixed-set IDs; **no free-text widget present** | widget | `flutter test test/features/onboarding/onboarding_screen_test.dart` | ❌ W0 | ⬜ pending |
| S1-03 | Selected nickname/avatar render on Home greeting | widget | `flutter test test/screens/home_screen_test.dart` | ✅ extend | ⬜ pending |
| gate | No profile → redirect to `/onboarding`; profile → Home; **no redirect loop** | widget/router | `flutter test test/router/onboarding_gate_test.dart` | ❌ W0 | ⬜ pending |
| gate | `PopScope(canPop: false)` blocks back on onboarding | widget | (within `onboarding_screen_test.dart`) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/data/child_profile_repository_test.dart` — covers S1-02 (persist + grade resolve)
- [ ] `test/features/onboarding/onboarding_data_test.dart` — covers S1-02 (grade→lesson map)
- [ ] `test/features/onboarding/onboarding_screen_test.dart` — covers S1-03 (fixed-set, no free-text, PopScope)
- [ ] `test/router/onboarding_gate_test.dart` — covers the redirect gate (no loop)
- [ ] Extend `test/data/app_database_test.dart` — v2→v3 migration
- [ ] Extend `test/screens/home_screen_test.dart` — greeting reads profile
- [ ] Framework install: none — `flutter_test` already present

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Onboarding screen matches Qalam visual feel (parchment/teal, fixed-set pickers, RTL) | S1-03 | Visual fidelity is human-judged | Run on tablet/emulator; confirm against `onboarding_preview.html` mockup + design kit |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
