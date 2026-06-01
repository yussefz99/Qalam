# Phase 3: Trace One Letter End-to-End - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 3-Trace One Letter End-to-End
**Areas discussed:** UI scope & fidelity, Star display (anti-gamification flag), Feedback & retry flow, Star & clean-reps, Animation & demo style, Input & palm rejection, ML Kit scope

---

## UI scope & fidelity (raised by owner: "why aren't you building the full UI?")

| Option | Description | Selected |
|--------|-------------|----------|
| Just the trace flow | Build Watch + Trace + celebration faithfully; Home/Journey/Parent stay Phase-1 shells | ✓ |
| Trace flow + a faithful Home | Also build Home now with a hardcoded placeholder child/lesson | |
| Let me explain what I want | Owner describes scope | |

**User's choice:** Just the trace flow (recommended).
**Notes:** Owner asked why the full UI (covered by their Claude Design) isn't being built now. Explained the vertical-slice strategy: Home/Journey/Parent have no real data behind them yet (profiles=P5, progression=P6, curriculum=P7, dashboard=P9), so building them now produces facades that get reworked. Owner's design remains the canonical source of truth; Phase 3 builds its screens pixel-faithfully. Each later phase lights up more of the design with real data.

---

## Star display — anti-gamification contradiction (FLAGGED)

| Option | Description | Selected |
|--------|-------------|----------|
| Quiet mastery star only | No running counter / weekly tally; star = real mastery; dignified per-mastery moment | ✓ |
| Keep the design's star counter | Build the running total + weekly tally (would override a Decided rule) | |
| Decide with mom / revisit | Defer the gamification question | |

**User's choice:** Quiet mastery star only (recommended).
**Notes:** Flagged that the design screenshots (2026-05-24) show "⭐ 39", "stars this week", and a weekly bar — contradicting CLAUDE.md's Decided anti-gamification rules. Design predates the 2026-05-30 reconciliation. Owner chose to follow the Decided rules and omit the gamification chrome; design assets may be updated to match.

---

## Feedback & retry flow

| Option | Description | Selected |
|--------|-------------|----------|
| Per stroke | Feedback after each stroke; advance or retry that stroke | ✓ |
| Whole letter at once | One combined judgement after all strokes | |

| Option | Description | Selected |
|--------|-------------|----------|
| Hold + show fix, retry | Highlight failing stroke, show named fix, clear ink, retry same stroke, unlimited gentle retries | ✓ |
| Show fix but let them move on | Allow Next even on a miss | |
| Hold, with quiet escape after N tries | Hold-and-retry + gentle "show me again" / skip after repeated misses | |

| Option | Description | Selected |
|--------|-------------|----------|
| 'Mark correct' = placeholder, drop it | Pass/fail from the scorer only | ✓ |
| Real — a deliberate manual-advance | Keep as a safety valve while scorer is first-cut | |
| Let me explain what I meant | Owner clarifies | |

**User's choice:** Per stroke · Hold + show fix and retry (unlimited, no fail state) · "Mark correct" dropped.
**Notes:** Per-stroke matches the design's "Stroke X of N" UI; alif is one stroke. No try-counter, no pressure.

---

## Star & clean-reps

| Option | Description | Selected |
|--------|-------------|----------|
| 3 clean reps → 1 mastery star | Honour curriculum; star after the 3rd clean rep | ✓ |
| 1 clean pass = star (thinnest) | One clean trace earns the star | |
| Reps tracked, star deferred to P6 | Count reps, defer the star artifact | |

| Option | Description | Selected |
|--------|-------------|----------|
| Full-screen dignified moment | Qalam + alif + one gold star + warm line, then Done/Home | ✓ |
| Small inline star + warm line | Quieter, non-full-screen | |
| Minimal placeholder for now | Just enough to confirm mastery | |

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — record mastery to Drift | Persist clean-reps + mastery now; P6 reads it | ✓ |
| No — keep it ephemeral | In-session only | |
| You decide | Planner chooses | |

**User's choice:** 3 clean reps → 1 mastery star · full-screen dignified celebration · persist to Drift.
**Notes:** Uses alif's cleanRepsToAdvance: 3. Celebration is calm, no confetti/counter. Persistence proves "it remembers" across restarts.

---

## Animation & demo style

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-play once, then Replay | Demo plays once on entry; Replay/"I'll try" | ✓ |
| Child taps to play | Nothing auto-plays | |

| Option | Description | Selected |
|--------|-------------|----------|
| Animated tip traces path on guide | Moving pen-tip draws the stroke along the reference path from the gold dot; mascot beside | ✓ |
| Mascot-led demonstration | Mascot physically "writes" it (heavier) | |
| You decide the exact treatment | Capture principle, UI designer chooses look | |

| Option | Description | Selected |
|--------|-------------|----------|
| Omit audio in Phase 3 | No audio assets; button returns in P7 | ✓ |
| Show it, disabled/"coming soon" | Visible but inert | |
| You decide | Planner chooses | |

**User's choice:** Auto-play once · animated pen-tip on the guide (same paths as scoring) · audio omitted.
**Notes:** S1-04 requires the animation be driven by the same reference paths used for scoring. Mascot = tutor persona, not a game character.

---

## Input & palm rejection

| Option | Description | Selected |
|--------|-------------|----------|
| Android tablet WITH stylus | True stylus-only from day one | |
| Tablet/emulator WITHOUT stylus (finger) | Develop with a finger | ✓ |
| Both / not sure | Build to work either way | |

| Option | Description | Selected |
|--------|-------------|----------|
| Stylus-only in prod, finger in debug | Prod filters to stylus (palm rejection free); debug flag allows finger | ✓ |
| Strict stylus-only always | No finger fallback (needs a stylus to test) | |
| Accept finger or stylus, reject palm by size | More forgiving but fiddly | |

**User's choice:** Finger-only test device · stylus-only in prod with a debug finger flag.
**Notes:** The debug-finger path is required for the owner to run Phase 3 (no active stylus). Scorer treats both inputs identically.

---

## ML Kit scope

| Option | Description | Selected |
|--------|-------------|----------|
| Defer ML Kit to Phase 4 | Phase 3 = pure geometric scorer, fully offline; ML Kit identity check + model download land in P4 | ✓ |
| Include ML Kit identity check now | Wire ML Kit + model download in P3 | |
| You decide | Researcher/planner chooses | |

**User's choice:** Defer ML Kit to Phase 4 (recommended).
**Notes:** Keeps the deepest-risk phase fully offline with zero network; isolates the flagged model-download risk. HandwritingRecognizer seam left ready.

---

## Claude's Discretion

- Geometric scorer algorithm (resampling + shape-distance method) and first-cut lenient thresholds.
- Exact Drift schema for mastery + clean-rep persistence.
- Precise visual/motion treatment of the animated pen-tip and celebration (within the design's look).
- Mapping of named commonMistakes checks to scorer predicates.
- Riverpod session structure (controller family + separate high-frequency stroke-capture provider).

## Deferred Ideas

- ML Kit identity check + model download-and-cache → Phase 4.
- Scorer calibration / per-letter tolerance tuning with the owner's mother → Phase 4.
- Rebuilt Home → Phase 5/6; Journey/alphabet map → Phase 6; audio + Play sound → Phase 7; Parent dashboard → Phase 9.
- Updating design assets to drop the running star counter / weekly tallies → housekeeping.
- Gentle "show me again" auto-replay after repeated misses → optional Phase 4 UX polish.
