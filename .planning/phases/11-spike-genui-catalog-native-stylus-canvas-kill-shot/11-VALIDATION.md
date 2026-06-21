---
phase: 11
slug: spike-genui-catalog-native-stylus-canvas-kill-shot
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-21
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
>
> **This is a feel-based architecture spike (D-06), not a feature with automatable
> behavioral tests.** The "validation" here is the GATE-evidence protocol plus two
> cheap automatable structural guards. The decisive evidence is an on-device A/B
> video judged by feel — it cannot be reduced to a passing test, and pretending
> otherwise would defeat the kill-shot.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (already in the project) — used ONLY for the two structural guards below, not for canvas feel |
| **Config file** | none beyond default; the spike adds no test config |
| **Quick run command** | `flutter analyze lib/spike_genui` (spike must compile + lint clean) |
| **Full suite command** | `flutter test test/spike_genui/` (only the guard tests below) |
| **Estimated runtime** | ~15 seconds (analyze) / ~10 seconds (guard tests) |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze lib/spike_genui` (compiles + lints).
- **After every plan wave:** Run the SC-4 durable-layers guard — `git diff --quiet HEAD -- <durable paths>` must stay green the entire spike.
- **Before the GATE:** On-device A/B video captured + judged by feel + SPIKE-FINDINGS verdict written with a recorded `GATE: keep|drop`.
- **Max feedback latency:** ~15 seconds (analyze) for code; device-loop for feel evidence.

---

## Per-Task Verification Map

| Criterion | Behavior | Test Type | Automated Command | File Exists |
|-----------|----------|-----------|-------------------|-------------|
| SC-1 (canvas hosted, real-time) | Embedded canvas traces baa with no per-stroke lag | **manual / feel A/B on Pixel Tablet (D-06)** — NOT automatable | (video capture, judged by feel) | ❌ device + human |
| SC-2 (written verdict) | A SPIKE-FINDINGS doc states pass/fail + observations | doc-existence check | `test -f <spike-findings path>` | ❌ Wave-end |
| SC-3 (GATE recorded) | `GATE: keep\|drop` written + handed to Phase 14 | doc-content check | `grep -E "GATE: (keep\|drop)" <spike-findings path>` | ❌ Wave-end |
| SC-4 (durable layers unchanged) | git diff on durable paths is empty | **automatable guard** | `git diff --quiet HEAD -- lib/features/practice/widgets/stroke_canvas.dart lib/features/letter_unit/ lib/core/scoring/ lib/core/exercise_engine/ assets/curriculum/` | ✅ Wave 0 |
| (build sanity) | spike compiles + uses `genui`, never `flutter_genui` | automatable guard | `flutter analyze lib/spike_genui && grep -q "genui:" pubspec.yaml && ! grep -q "flutter_genui:" pubspec.yaml` | ✅ Wave 0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/spike_genui/durable_layers_unchanged_test.dart` (or a Bash guard task) — asserts the SC-4 `git diff --quiet` on durable paths is empty.
- [ ] `test/spike_genui/correct_package_test.dart` (or a Bash guard task) — asserts `pubspec.yaml` declares `genui` and NOT `flutter_genui`.
- [ ] No new test framework needed — `flutter_test` already present.

---

## Manual-Only Verifications (the feel-based core, D-05/D-06)

| Behavior | Why Manual | Test Instructions |
|----------|------------|-------------------|
| Embedded vs standalone baa trace is indistinguishable by feel | Responsiveness "is felt, not specified" (D-06); frame-timing instrumentation is Phase 12 scope | On a **real Pixel Tablet + stylus** (not emulator/finger), trace baa on the GenUI-embedded canvas and on the same canvas standalone; record both; a viewer must not be able to tell which is which by ink responsiveness |
| Stroke state survives a GenUI surface update | GenUI docs are silent on stateful-widget identity across surface rebuilds — this is the documented gap the spike settles | Trigger at least one surface update (coaching line re-render) mid/after a trace; confirm in-progress/complete ink is NOT reset; host canvas under a stable `ValueKey`/`GlobalKey` |
| Mixed tree coexistence (D-04) | Visual confirmation that model text + native ink share one surface | Confirm GenUI renders one coaching line above the embedded native canvas in a single surface |

**PASS evidence (GATE = keep GenUI):** indistinguishable on-device A/B video; embedded canvas keeps stroke state across a surface update; mixed tree renders in one surface; achieved within the time-box with the SC-4 durable-diff guard green.

**FAIL evidence (GATE = drop GenUI → raw `firebase_ai` fallback):** embedded arm stutters/drops/resets where standalone is smooth; hosting required touching a durable file (SC-4 guard would go red); genui 0.9.x cannot host an arbitrary stateful widget under a stable key without fighting the framework; **or the time-box is exhausted (D-08) — difficulty itself is the FAIL verdict, do not iterate further.**

**Time-box → GATE either way (D-08):** the spike CANNOT end "inconclusive." At the budget's edge there are exactly two outcomes — a clean indistinguishable A/B (→ keep) or anything short of that (→ drop). Both write a SPIKE-FINDINGS verdict and a `GATE: keep|drop` line consumed by Phase 14.

---

## Validation Sign-Off

- [ ] SC-4 durable-layers guard and correct-package guard exist and run green from Wave 0.
- [ ] Sampling continuity: every code task gated by `flutter analyze lib/spike_genui`.
- [ ] Wave 0 covers the two automatable guards.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 15s for code guards.
- [ ] Feel-based A/B explicitly listed as manual-only (not faked as automated).
- [ ] `nyquist_compliant: true` set in frontmatter once guards are wired.

**Approval:** pending
