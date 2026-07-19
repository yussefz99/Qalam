# Phase 25: Trusted content — the seen-letters wall + the mother's confirmation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-19
**Phase:** 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
**Areas discussed:** L3 degradation strategy, 34-card disposition, mother's packet flow, stale-signed baa + new alif card

---

## Area selection

All four surfaced gray areas selected for discussion (user: "all").

---

## L3 runtime-guard degradation

| Option | Description | Selected |
|--------|-------------|----------|
| Substitute (tier-down) | Replace the illegal card with the nearest legal card in the same competency (reuses walker's nextForward + remediateOneTier); star provably reachable. | |
| Skip | Drop the illegal card, advance to the next legal node; simplest, but needs an essential-node backstop so the star isn't stranded. | ✓ |
| Substitute (any legal) | Always swap in any legal card of a matching type to preserve session length. | |

**User's choice:** "the simplest option" → Skip.
**Notes:** Recorded as Skip PLUS a mandatory star-reachability backstop — the roadmap +
Decided rules make "star must stay reachable" non-waivable, so the simplicity preference
governs the common case while the guard still preserves a route to mastery when an illegal
card sits on an essential node with no other legal path. Every firing logged loudly.
Criterion 3's live-path test proves the star stays reachable.

---

## 34-card disposition (Q1 — default policy)

| Option | Description | Selected |
|--------|-------------|----------|
| Re-point, else remove | Prefer relabeling to learned-letter words; remove if a re-point loses the teaching point; except only with mother approval. | ✓ |
| Remove by default | Drop every violating card unless there's a strong reason to keep it. | |
| Case-by-case, no default | Decide each of the 34 individually with no standing rule. | |

**User's choice:** Re-point, else remove.

## 34-card disposition (Q2 — who decides)

| Option | Description | Selected |
|--------|-------------|----------|
| I triage, mom reviews diff | Owner triages re-points/removes now (clean build); mother reviews the full re-point diff and approves every exception. | ✓ |
| I triage, mom sees exceptions only | Re-points ship without her review; she sees only exceptions. | |
| Mom decides every card | All 34 go to the mother; blocks the clean-audit criterion on her turnaround. | |

**User's choice:** I triage, mom reviews the full diff.
**Notes:** Decouples the mechanical wall (criteria 1–3) from her async turnaround while
keeping her the curriculum authority.

---

## Mother's packet flow (Q1 — delivery)

| Option | Description | Selected |
|--------|-------------|----------|
| Google Doc in her Drive | Async structured doc in her existing Drive folder, inline verdict per row. | |
| Live walkthrough, you capture | Owner walks each item with her and records verdicts in-session. | ✓ |
| PDF she marks up | Printed/PDF packet she annotates; owner transcribes. | |

**User's choice:** "the fastest option" → Live walkthrough.

## Mother's packet flow (Q2 — blocking)

| Option | Description | Selected |
|--------|-------------|----------|
| Land wall now, ingest async | L0–L3 + audit + packet assembly don't wait; verdict ingestion runs when she replies. | ✓ |
| Block phase on verdicts | Phase 25 not done until every verdict is in; her turnaround gates 25–29. | |

**User's choice:** Land wall now, ingest async.

## Mother's packet flow (Q3 — timing)

| Option | Description | Selected |
|--------|-------------|----------|
| Within a few days | — | |
| About a week or more | — | |
| Unsure right now | — | |

**User's choice:** "immediately when it's done she is next to me" (free text).
**Notes:** Reconciles with "ingest async" — the async path is still built for robustness,
but the happy path is same-session because she's physically present. So criterion 4
(verdicts recorded, signedOff matches) can be satisfied in-phase.

---

## Stale-signed baa + new alif card (Q1 — baa flag)

| Option | Description | Selected |
|--------|-------------|----------|
| Flip false, reconfirm live → true | Set baa signedOff:false during packet assembly (honest state), reconfirm per item live → true. | ✓ (Claude's discretion) |
| Keep true, flip only on reject | Leave true, list divergences, flip only if she rejects. | |

**User's choice:** "do what you think is best" → delegated to Claude → Flip false,
reconfirm live → true.
**Notes:** Chosen for mechanical truthfulness (the flag never claims "confirmed" while the
content isn't) — the phase's whole thesis. Safe because enforcement is decoupled from the
flag (draft exemption removed).

## Stale-signed baa + new alif card (Q2 — new alif card)

| Option | Description | Selected |
|--------|-------------|----------|
| Author as draft, show her live | Build alif.writeLetter.fromPicture as signedOff:false; she sees the real card in the walkthrough; promote on approval. | ✓ |
| Proposal-only, build after approval | Describe it in the packet; build only after she approves the concept. | |

**User's choice:** Author as draft, show her live.

---

## Claude's Discretion

- baa `signedOff` flag behavior (Q1 above) — owner delegated with "do what you think is
  best"; resolved to flip-false → reconfirm-live → true.
- The packet checklist's exact file/columns.
- The precise L3 seam (filter-in-selector vs guard-in-walker), constrained by the skip +
  backstop + loud-logging decisions.

## Deferred Ideas

- Server un-fencing + promoting the remaining 24 letters in mother-signed batches → Phase 27.
- Entry-model decision, launcher icon, scorer re-tighten, tutor-feedback debts, Android
  device pass, 2.0.1 release cut → Phase 26.
- Cross-letter selection, next-day planner, parent dashboard → Phase 28.
- Offline hardening + release audit + debt ledger to zero → Phase 29.
- A possible baa-graph server redeploy if the mother restores minCleanReps to 3 (needs
  fresh owner authorization) — flagged for the planner, not silently absorbed.
