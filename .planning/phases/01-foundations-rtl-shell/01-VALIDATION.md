---
phase: 1
slug: foundations-rtl-shell
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `01-RESEARCH.md` §Validation Architecture. Task IDs are filled in by the planner.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter SDK) + golden (screenshot) tests |
| **Config file** | none yet — Wave 0 installs `test/` + golden infrastructure |
| **Quick run command** | `flutter test test/theme_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30–60 seconds (cold; faster warm) |

---

## Sampling Rate

- **After every task commit:** Run the relevant single test file (e.g. `flutter test test/data/app_database_test.dart`)
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite green **AND** the glyph-audit golden reviewed by a human (visual PASS — the D-12 risk gate)
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Decision | Behavior | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|----------|----------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| D-12 | Noto Naskh shapes all 4 contextual forms; no tofu; لا renders as ﻻ ligature; tashkeel placed correctly | 1 | PLAT-02 | — | N/A | golden / widget | `flutter test test/glyph_audit_golden_test.dart` | ❌ W0 | ⬜ pending |
| D-06 | Western digits 0–9 render, LTR-isolated, inside an RTL Arabic island | 1 | PLAT-02 | — | N/A | golden / widget | `flutter test test/numeral_isolation_test.dart` | ❌ W0 | ⬜ pending |
| D-05 | App default direction is LTR; only the Arabic content island is RTL | 1 | PLAT-02 | — | N/A | widget | `flutter test test/direction_test.dart` | ❌ W0 | ⬜ pending |
| D-09 | A trivial value persisted to Drift survives a simulated restart (new DB instance reads it back) | 1 | PLAT-02 | — | DB lives in app-private storage; nothing sensitive persisted | unit | `flutter test test/data/app_database_test.dart` | ❌ W0 | ⬜ pending |
| D-01/D-02 | Theme exposes semantic tokens (primary `#168A8F`, bg `#FAF6EE`, reward `#F2A60C`); no raw hex in widgets | 1 | PLAT-02 | — | N/A | unit | `flutter test test/theme_test.dart` | ❌ W0 | ⬜ pending |
| D-10 | Landscape orientations set (manifest + `SystemChrome`) | 1 | PLAT-02 | — | N/A | widget + manual | `flutter test test/direction_test.dart` (orientation assertion) + manual launch | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/theme_test.dart` — D-01/D-02 (semantic theme tokens exposed)
- [ ] `test/data/app_database_test.dart` — D-09 (in-memory Drift persist/read proof)
- [ ] `test/direction_test.dart` — D-05/D-10 (LTR app default, RTL island, landscape lock)
- [ ] `test/numeral_isolation_test.dart` — D-06 (Western digits LTR-isolated in RTL)
- [ ] `test/glyph_audit_golden_test.dart` — D-12 (four-form shaping; the risk gate)
- [ ] Golden infrastructure (reference images for the glyph-audit grid)
- [ ] `flutter_test` is bundled with the SDK — no separate install

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Glyph-audit visual PASS at 96px on a real/emulated tablet | PLAT-02 (D-12) | Correct contextual shaping is a perceptual judgment vs a known-good reference; the golden test gates regressions but a human confirms the *first* baseline is genuinely correct | Open the debug `GlyphAuditScreen`, compare each letter's four forms against the design-kit specimen / browser reference; confirm no tofu, لا is a single ﻻ, joins connect, tashkeel unclipped. Record PASS/FAIL in verification notes. On FAIL, switch bundled Arabic font to Amiri (documented fallback) and re-run. |
| Landscape lock has no portrait flash on cold start | PLAT-02 (D-10) | Cold-start orientation flash occurs before Dart runs and is not observable in widget tests | Launch on tablet from cold; confirm no momentary portrait frame before landscape. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
