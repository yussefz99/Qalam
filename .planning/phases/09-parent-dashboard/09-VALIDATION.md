---
phase: 9
slug: parent-dashboard
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart) |
| **Config file** | test/flutter_test_config.dart (loads bundled TTFs for Arabic goldens) |
| **Quick run command** | `flutter test test/data/ test/services/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30–60 seconds (full suite) |

> Note: `flutter` is not on PATH in this environment — use the bundled SDK at
> `C:\Users\yusse\.vscode\flutter\bin\flutter.bat`.

---

## Sampling Rate

- **After every task commit:** Run the quick command for the touched area.
- **After every plan wave:** Run `flutter test` (full suite).
- **Before `/gsd-verify-work`:** Full suite must be green (modulo the documented
  pre-existing stale Phase 03.1 nav/golden failures).
- **Max feedback latency:** ~60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-xx | 01 | 0 | S1-11 | T-09-* | RED contract for PIN hash/verify, persisted cooldown, route gate, read-only dashboard | unit/widget | `flutter test test/` | ❌ W0 | ⬜ pending |
| 09-02-xx | 02 | 1 | S1-11 | T-09-01 | PIN hashed+salted (PBKDF2), never plaintext, never logged; verify() constant-ish | unit | `flutter test test/services/pin_service_test.dart` | ❌ W0 | ⬜ pending |
| 09-02-xx | 02 | 1 | S1-11 | T-09-02 | Failed-attempt cooldown PERSISTS across app restart (Drift, not in-memory) | unit | `flutter test test/services/pin_service_test.dart` | ❌ W0 | ⬜ pending |
| 09-0x-xx | 0x | 2 | S1-11 | T-09-03 | `/parent` route reachable only after PIN; child cannot reach without it | widget | `flutter test test/router/parent_gate_test.dart` | ❌ W0 | ⬜ pending |
| 09-0x-xx | 0x | 2 | S1-11 | T-09-04 | Dashboard renders summary + per-letter list read-only; empty state; no edit/delete | widget | `flutter test test/screens/parent_dashboard_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · exact IDs assigned by the planner.*

---

## Wave 0 Requirements

- [ ] `test/services/pin_service_test.dart` — PIN hash/verify + persisted cooldown stubs (S1-11, T-09-01/02)
- [ ] `test/router/parent_gate_test.dart` — PIN-gate redirect, no-loop, child-cannot-bypass (S1-11, T-09-03)
- [ ] `test/screens/parent_dashboard_test.dart` — summary + per-letter list, empty state, read-only (S1-11, T-09-04)
- [ ] `test/data/app_database_test.dart` (extend) — aggregate progress accessors (all mastered / in-progress)

*Existing flutter_test infrastructure covers the framework; only the new test files above are Wave 0.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PIN entry on a real tablet (obscured numeric, no soft-keyboard leak, cooldown felt) | S1-11 | Stylus/touch + soft-keyboard behavior not emulatable in flutter_test | On device: open Parent nav → create PIN → exit → re-enter wrong PIN 5× → confirm cooldown → enter correct PIN → see dashboard |
| Dashboard visual fidelity (parchment/ink, adult-calm, PLAT-03 no game chrome) | S1-11 | Design-system fidelity needs visual inspection | On device: inspect dashboard against docs/design/kit tokens |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
