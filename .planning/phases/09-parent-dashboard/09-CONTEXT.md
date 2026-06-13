# Phase 9: Parent Dashboard - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

A **PIN-gated, read-only, local** Parent Dashboard: the parent enters a PIN to reach
an area showing the (single) child's completed lessons and their scores, sourced
entirely from on-device storage. **No cloud, no account** (requirement S1-11).

In scope: PIN setup + entry gate, a read-only progress view, wiring the existing
(currently locked) Home "Parent" nav entry.

Out of scope (do NOT build here): struggle/topic analysis (S2-06), weekly progress
report (S2-10), daily practice-duration goals (S2-07), multi-child support, and any
editing/resetting of progress from the dashboard.

</domain>

<decisions>
## Implementation Decisions

### PIN setup & recovery
- **D-01:** The parent creates a **4-digit PIN on first access** to the parent area
  (enter + confirm). No PIN exists until then; first tap into the area is a "create
  PIN" flow, subsequent taps are "enter PIN".
- **D-02:** **No cloud/account recovery.** A forgotten PIN can only be reset by
  clearing app data — which also wipes the child profile and progress. This tradeoff
  must be stated honestly in the UI copy at PIN creation.

### Dashboard contents
- **D-03:** Layout = a **top summary line** (e.g., "5 of 28 letters mastered") above a
  **scrollable per-letter list**. Each row: the letter, mastered ✓ / in-progress
  status, clean-reps count, and the mastered date (when applicable).
- **D-04:** **Empty state** (no lessons done yet): a calm "No lessons completed yet."
  message — never an error or an empty void.
- **D-05:** **"Score" = clean-reps count + mastered/in-progress status** read from
  `LetterMastery` (passed) and `LetterReps` (in-progress). There is **no 0–100 score**
  in the data model — do NOT invent one.

### Parent-area entry & exit
- **D-06:** Wire the **existing locked Home nav-rail "Parent" entry** → PIN prompt →
  full-screen dashboard. Remove the "Coming soon" lock/sublabel on that entry.
- **D-07:** The PIN is prompted on **every entry** (no session-long unlock). A clear
  "Done"/back control returns to the child's Home. The area should read as a distinct
  adult space (calm, no child-game chrome).

### PIN hardening (child-safety)
- **D-08:** **4-digit PIN.** After ~5 wrong attempts, impose a **short cooldown**
  (e.g., 30s) before more tries, so a child cannot brute-force in. No permanent lockout.

### Claude's Discretion (flag for research + planning)
- **PIN storage:** the PIN MUST be stored **hashed + salted, never plaintext**, and
  **never logged** (child-safety / threat model). `AppSettings` key/value table is a
  candidate store (e.g., `parentPinHash`). Exact hashing approach is the planner's /
  security-auditor's call.
- The dashboard is strictly **read-only** — it must expose no edit/delete of progress.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §S1-11 — "A parent can see the child's completed lessons
  and scores." Accept: PIN-gated parent area; read-only local progress; no cloud, no account.

### Roadmap
- `.planning/ROADMAP.md` "Phase 9: Parent Dashboard" — goal + the two success criteria
  (PIN-gated entry; read-only completed-lessons/scores list from local storage).

### Project decisions / brand
- `CLAUDE.md` — child-data minimalism (collect the minimum, private by default, parent
  control); "no points-chasing" (the parent view is *information*, not score-hype).
- `.planning/PROJECT.md` — child-safety key decisions (local-only, on-device, no Firebase).

### Prior phase context
- `.planning/phases/05-profiles-onboarding/05-CONTEXT.md` — single child profile, fixed-set
  IDs, no real name; the profile the dashboard reports on.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/settings_screen.dart` (+ `/settings` GoRoute) — closest pattern for a new
  top-level screen and route to model `/parent` on.
- `lib/data/app_database.dart` — `LetterMastery` (letterId, cleanReps, masteredAt = passed),
  `LetterReps` (in-progress reps), accessors `recordMastery`/`isMastered`/`cleanRepsFor`,
  and `ChildProfiles` (single profile). Will need new read accessors (e.g., all mastered
  letters, all in-progress) for the dashboard.
- `AppSettings` key/value table — candidate store for the hashed PIN (e.g., `parentPinHash`).
- `lib/router/app_router.dart` — go_router; add a PIN-gated `/parent` route.
- `lib/screens/home_screen.dart` — the locked "Parent" nav entry (`navParent` / `comingSoon`
  l10n) to unlock and wire.
- `ArabicText` island for letter labels; theme tokens; PLAT-03 (no gamification chrome) applies.

### Established Patterns
- Riverpod-only providers; Drift accessors exposed via providers; l10n strings via ARB.
- Child-data security convention: store only IDs/counts, never stroke points; never log values.

### Integration Points
- Home nav-rail "Parent" entry → new `/parent` route (PIN gate in between).
- Dashboard reads `LetterMastery` / `LetterReps` (and curriculum letter order for the
  "N of 28" summary) via a provider/repository.

</code_context>

<specifics>
## Specific Ideas

- Read-only, calm, adult-feeling presentation — distinct from the child's playful Home.
- Honest copy at PIN creation: forgetting the PIN means clearing app data (no recovery).
- "Scores" framed as mastery/clean-reps information, not a competitive number.

</specifics>

<deferred>
## Deferred Ideas

- **S2-06** — parent sees which specific topics/letters the child struggles with (stretch).
- **S2-10** — weekly progress report (stretch).
- **S2-07** — parent sets a daily practice-duration goal (stretch).
- **Multi-child profiles** — v1 is single-profile (Phase 5); multi-child is future.
- **Editing/resetting individual progress from the dashboard** — out of scope; read-only.

</deferred>

---

*Phase: 9-parent-dashboard*
*Context gathered: 2026-06-13*
