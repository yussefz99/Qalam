# Phase 9: Parent Dashboard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 9-parent-dashboard
**Areas discussed:** PIN setup & recovery, What the dashboard shows, Parent-area entry & exit, PIN hardening

---

## PIN setup & recovery

| Option | Description | Selected |
|--------|-------------|----------|
| First-access setup; forgot = clear data | Parent creates a 4-digit PIN on first access (enter + confirm); only reset is clearing app data | ✓ |
| Set during child onboarding | PIN set as a first-launch onboarding step | |
| PIN + local recovery question | PIN plus a locally-stored recovery question/answer | |

**User's choice:** First-access setup; forgot = clear data
**Notes:** No cloud means no recovery; the tradeoff must be stated honestly in PIN-creation copy.

---

## What the dashboard shows

| Option | Description | Selected |
|--------|-------------|----------|
| Summary + per-letter list | "N of 28 mastered" line above a per-letter list (status, clean-reps, date); calm empty state | ✓ |
| Per-letter list only | List without the summary line | |
| Two groups: Mastered / In progress | Same data split into two sections | |

**User's choice:** Summary + per-letter list
**Notes:** "Score" = clean-reps + mastered/in-progress (LetterMastery/LetterReps); no 0–100 score exists.

---

## Parent-area entry & exit

| Option | Description | Selected |
|--------|-------------|----------|
| Full screen, PIN every time | Locked Home "Parent" entry → PIN prompt → full-screen dashboard; "Done" returns to child Home; re-prompts each entry | ✓ |
| Full screen, unlock until backgrounded | Same, but no re-prompt within a session | |
| Modal sheet over Home | Sheet/overlay rather than full screen | |

**User's choice:** Full screen, PIN every time
**Notes:** Child-safe (no session unlock); reads as a distinct adult space.

---

## PIN hardening (child-safety)

| Option | Description | Selected |
|--------|-------------|----------|
| 4-digit + short lockout | 4 digits; ~30s cooldown after ~5 wrong tries; no permanent lockout | ✓ |
| 4-digit, no lockout | Just the gate, no throttling | |
| 6-digit + lockout | Stronger: 6 digits + cooldown | |

**User's choice:** 4-digit + short lockout

---

## Claude's Discretion

- PIN must be stored hashed + salted (never plaintext), never logged — exact hashing approach left to planner / security-auditor.
- Read-only enforcement (no edit/delete of progress) — implementation detail.

## Deferred Ideas

- S2-06 (struggle/topic analysis), S2-10 (weekly report), S2-07 (daily goal) — stretch, future phases.
- Multi-child profiles — v1 is single-profile.
- Editing/resetting progress from the dashboard — out of scope (read-only).
