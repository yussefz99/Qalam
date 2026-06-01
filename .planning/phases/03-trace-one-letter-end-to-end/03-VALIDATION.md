---
phase: 3
slug: trace-one-letter-end-to-end
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `03-RESEARCH.md` § Validation Architecture. Planner fleshes out the
> Per-Task Verification Map (task IDs / waves) during planning.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (SDK) + golden tests |
| **Config file** | `analysis_options.yaml`; `test/flutter_test_config.dart` (loads bundled Arabic TTFs into the headless engine — P1 pattern; required so Arabic goldens don't render tofu) |
| **Quick run command** | `flutter test test/core/scoring/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~quick: <10s scorer-only; full: dominated by goldens |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/core/scoring/` (the pure-Dart scorer — fast)
- **After every plan wave:** Run `flutter test` (full suite incl. goldens)
- **Before `/gsd-verify-work`:** Full suite green + manual finger UAT of the whole loop (Watch→Trace→miss→fix→retry→3 clean reps→celebration→restart→mastery remembered)
- **Max feedback latency:** ~300 ms stylus-up → on-screen feedback (success criterion 3)

---

## Per-Task Verification Map

> Task IDs / waves assigned by the planner. Requirement → behavior → test mapping
> below is from research and is the source contract.

| Req | Behavior | Test Type | Automated Command | File Exists |
|-----|----------|-----------|-------------------|-------------|
| S1-05 | Scorer passes a clean synthetic alif down-stroke | unit | `flutter test test/core/scoring/geometric_stroke_scorer_test.dart` | ❌ W0 |
| S1-05 | Scorer fails too-short stroke → `too_short` mistake id | unit | same file | ❌ W0 |
| S1-05 | Scorer fails bottom-up stroke → `wrong_direction` | unit | same file | ❌ W0 |
| S1-05 | Scorer fails very-curved stroke → `too_curved` | unit | same file | ❌ W0 |
| S1-05 | Resample+normalize: small correct stroke still passes (size-invariant) | unit | `test/core/scoring/stroke_resampler_test.dart` | ❌ W0 |
| S1-05 | Each `MistakeId` maps to authored `commonMistakes[].feedback` (no generic "try again") | unit | `test/core/scoring/mistake_mapping_test.dart` | ❌ W0 |
| S1-05/D-13 | Canvas accepts stylus; rejects touch in prod; accepts touch when debug-finger flag set | widget | `test/features/practice/stroke_canvas_test.dart` | ❌ W0 |
| S1-04 | Animation path == resolved scoring path (one source of truth) | unit | `test/core/scoring/reference_path_test.dart` | ❌ W0 |
| S1-04 | "Watch me write" auto-plays once then offers Replay (D-10) | widget | `test/features/practice/stroke_order_animation_test.dart` | ❌ W0 |
| S1-10/D-07 | 3 clean reps → mastery; misses don't consume a rep | unit | `test/features/practice/session_controller_test.dart` | ❌ W0 |
| S1-10/D-09 | Mastery persists to Drift and survives a simulated restart | integration (in-memory Drift) | `test/data/progress_repository_test.dart` | ❌ W0 |
| S1-10/D-08/PLAT-03 | Celebration shows ONE star, mascot, alif, warm line; NO counter/confetti/Journey button | golden + widget | `test/features/practice/mastery_celebration_golden_test.dart` | ❌ W0 |
| PLAT-03 | Trace screen omits header star counter, "Play sound", "Mark correct" | widget | `test/features/practice/practice_screen_test.dart` | ❌ W0 |
| S1-05 | Scorer completes well under latency budget on representative input | unit (timed) | within `geometric_stroke_scorer_test.dart` | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/core/scoring/geometric_stroke_scorer_test.dart` — S1-05 scorer behavior (pass + 3 mistake cases + timing)
- [ ] `test/core/scoring/stroke_resampler_test.dart` — size/position invariance
- [ ] `test/core/scoring/reference_path_test.dart` — animation/scorer path identity + Q1 resolution
- [ ] `test/core/scoring/mistake_mapping_test.dart` — named-fix mapping (no generic "try again")
- [ ] `test/features/practice/stroke_canvas_test.dart` — stylus filter + debug-finger flag
- [ ] `test/features/practice/stroke_order_animation_test.dart` — auto-play once + Replay
- [ ] `test/features/practice/session_controller_test.dart` — clean-rep → mastery
- [ ] `test/data/progress_repository_test.dart` — Drift mastery round-trip + v1→v2 migration
- [ ] `test/features/practice/mastery_celebration_golden_test.dart` — dignified celebration golden (loads TTFs via flutter_test_config.dart)
- [ ] `test/features/practice/practice_screen_test.dart` — anti-gamification omissions (PLAT-03)
- [ ] Synthetic stroke fixtures (clean alif, too-short, inverted, curved) — shared test helper
- [ ] No framework install needed (flutter_test present); add `mocktail` dev-dep ONLY if a real mock is required

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live ink renders smoothly under a real stylus; palm/finger filtered | S1-04/D-13 | Pointer hardware behavior + render smoothness can't be asserted from synthetic events alone | On an Android tablet with stylus: trace alif; confirm smooth ink, no palm marks. Toggle debug-finger flag and confirm finger works for dev. |
| Sub-300 ms felt latency stylus-up → feedback | S1-05 | Wall-clock perception on-device; timed unit test approximates only | On-device: complete a stroke, confirm feedback feels instant (<~300 ms). |
| Full loop UAT | all | End-to-end human flow | Watch→Trace→deliberate miss→read specific fix→retry→3 clean reps→celebration (one star)→kill app→relaunch→mastery remembered. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300 ms (success criterion 3)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
