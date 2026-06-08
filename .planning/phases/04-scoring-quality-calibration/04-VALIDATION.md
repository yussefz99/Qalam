---
phase: 04
slug: scoring-quality-calibration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source of truth for validation design: the **Validation Architecture** section of `04-RESEARCH.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test (Dart) |
| **Config file** | none — uses existing `test/` tree + `flutter_test` |
| **Quick run command** | `flutter test test/features/practice/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~{N} seconds (planner to confirm) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/practice/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** {N} seconds (planner to confirm)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {N}-01-01 | 01 | 1 | S1-05 / PLAT-03 | — | {expected behavior or "N/A"} | unit | `{command}` | ❌ W0 | ⬜ pending |

*Planner fills this map from the RESEARCH Validation Architecture (one row per task). Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Regression fixtures encoding the named common mistakes per letter (reject known-bad, accept known-good)
- [ ] Shared scorer test fixtures / labeled-sample loader

*Planner to finalize against the multi-stroke accumulation + LetterScorer work.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Per-letter tolerance calibration against real child samples (FP/FN tuning with the owner's mother) | SC#4 | Requires a real Android tablet + real child handwriting; cannot be emulator-captured | Capture labeled samples via authoring screen, run scorer over fixtures, tune per-letter tolerances with the mother |
| ML Kit `ar` single-letter recognition quality on target tablet | SC#2 | On-device model behavior; needs hardware spike | Run identity gate over a labeled set on the tablet, confirm confidently-different letters are caught without false rejects |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < {N}s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
