# Phase 09 — Deferred Device UAT (Parent Dashboard)

**Status:** DEFERRED — pending human device verification.
**Mode:** `human_verify_mode = end-of-phase` (autonomous progress is NOT blocked on this).
**Source:** Plan 09-03 Task 4 (`checkpoint:human-verify`, gate=blocking) + 09-VALIDATION.md "Manual-Only Verifications".

All automated tests for the parent-dashboard slice are GREEN
(`test/router/parent_gate_test.dart`, `test/screens/parent_dashboard_test.dart`,
plus the reconciled `test/screens/home_screen_test.dart`). The items below are the
behaviors that flutter_test cannot exercise — they must be checked once on a real
Android tablet before the phase is signed off.

## What was built

The full `/parent` slice: unlocked Home "Parent" nav → PIN create/enter gate
(obscured numeric, persisted cooldown, soft wrong-PIN feedback) → read-only
dashboard (summary + per-letter list + empty state) → "Done" relocks.

## Device UAT checklist

1. **Nav unlocked.** On a tablet, tap the Home "Parent" nav item — confirm it is
   NO LONGER "Coming soon" and shows a non-lock icon (ink-drop glyph).
2. **Create PIN.** First entry → create a 4-digit PIN; confirm the honest
   no-recovery line is shown; enter + confirm the PIN.
3. **Per-entry relock.** Exit via "Done", re-tap "Parent" → confirm it RE-PROMPTS
   the PIN (per-entry, no session unlock — D-07).
4. **Persisted cooldown.** Enter a wrong PIN 5× → confirm a calm cooldown countdown
   (no red, no lockout language); FORCE-QUIT the app and reopen → confirm the
   cooldown is STILL in effect (persisted, not reset). *(Highest-value check —
   verifies the persisted-cooldown source of truth survives a process kill.)*
5. **Read-only dashboard.** Enter the correct PIN → confirm the dashboard shows
   "N of M letters mastered" + the per-letter list; verify it is read-only (no
   edit/delete) and has no gold/star/streak/mascot chrome (PLAT-03). With a fresh
   profile, confirm the calm empty state instead.
6. **Visual fidelity.** Inspect against `docs/design/kit` tokens (parchment bg,
   soft-aqua rows, ink-teal accents only).

## Sign-off

- [ ] Device UAT completed — outcome: __________ (approved / issues: ______)
- [ ] Step 4 (force-quit-persisted-cooldown) explicitly verified on device.

**Resume signal:** Type "approved" or describe issues. The phase may complete
pending this device check (end-of-phase mode).
