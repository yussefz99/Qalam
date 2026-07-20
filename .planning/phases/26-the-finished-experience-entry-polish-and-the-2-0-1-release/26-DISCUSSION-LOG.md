# Phase 26: The finished experience — entry, polish, and the 2.0.1 release - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-20
**Phase:** 26-the-finished-experience-entry-polish-and-the-2-0-1-release
**Areas discussed:** Entry / identity model, Scorer re-tighten approach
**Areas planned directly (not discussed):** Launcher icon, two tutor-feedback bugs, release sequencing

---

## Area selection

| Option | Selected |
|--------|----------|
| Entry / identity model | ✓ |
| Launcher icon source | (deselected — owner: "there is a launcher icon and all of that") |
| Scorer re-tighten approach | ✓ |

**Note:** Owner deselected the launcher-icon discussion. Ground-truth check found the
Android on-device launcher is still the stock Flutter default (git: untouched since
commit e9fc86c, 2026-05-30); the Play store mark + iOS iconset exist. Recorded as a
known-fix (D-05), verified on device — not treated as a discussion item.

---

## Entry / identity model

| Option | Description | Selected |
|--------|-------------|----------|
| Optional — anonymous-first | App opens into child experience, no login wall, accounts only behind PIN gate; matches locked architecture | |
| Account-first — ratify as-built | Parent account = mandatory front door; contradicts a Decided item, needs Decided amendment + Play declarations | ✓ |
| Hybrid — anonymous entry + optional prompt | Anonymous entry with a dismissible parent-sign-in on-ramp | |

**User's choice:** "whatever is already built lets do it" → Account-first.

**Flag raised (per CLAUDE.md 'flag loudly if anything contradicts Decided'):** Claude
flagged that account-first contradicts two locked Decided lines (accounts reachable ONLY
behind the PIN gate; account does not yet gate data) and changes the Play data-safety
posture (must declare account-gating + parent-email collection). Also flagged that
"ship exactly as-built" is impossible because the sign-out strand is itself a bug.

**Confirmation:** Presented as an explicit second question. User confirmed
**"Yes — account-first, amend Decided"** with full awareness of consequences.

**Notes:** Children still never get their own login (D-09b intact — the parent signs in).
Sign-out must be fixed to route cleanly to /auth, never strand (D-01b). Decided section
amendment (D-02) and Play/legal alignment (D-03) are required execution work.

---

## Scorer re-tighten approach

| Option | Description | Selected |
|--------|-------------|----------|
| Revert to originals, validate on device | Restore original tcc/tcw; confirm feel on the scoped Android device pass; re-affirm widened with reason only if originals false-fail on-device | ✓ |
| Recalibrate on a mother-labelled set | Build a labelled set and tune against it — most rigorous, adds a dependency + a task for the bottlenecked mother | |
| Keep widened, record the reason | Leave 0.12/0.16, document why — fastest but leaves the scorer looser than designed | |

**User's choice:** Revert to originals, validate on device.

**Notes:** The widening only existed to work around the painter-stretch bug, now fixed
(972427e). Explicitly NOT gated on a mother-labelled calibration set. On-device fallback:
re-affirm widened WITH a recorded reason if the originals false-fail real clean strokes.

---

## Claude's Discretion

- Icon generation tooling (flutter_launcher_icons vs manual adaptive drawables).
- Router refactor shape and the exact sign-out routing implementation (constrained by
  D-01/D-01b).

## Deferred Ideas

- Mother-labelled scorer calibration set — revisit only if the D-04 on-device fallback fires.
- Account data SYNC (backup/restore) — stays future scope; D-02 changes only the gating clause.
- Anonymous-first / hybrid entry models — rejected by D-01; recorded so they are not re-proposed.
