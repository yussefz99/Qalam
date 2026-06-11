# Phase 6: Lesson Progression & Home - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 06-lesson-progression-home
**Areas discussed:** Lesson catalog & draft-letter policy, Grade entry point & skipped lessons, Home today-card states, Pass → unlock moment, Free discussion: creative additions

---

## Lesson catalog & draft-letter policy

| Option | Description | Selected |
|--------|-------------|----------|
| Expand lessons.json to 28 | One lesson per letter in curriculum order, unlock.requires=[previous]; data not code | ✓ |
| Derive lessons in code | Walk letters.json order directly; hardcodes one-lesson-one-letter | |
| Hybrid: generate at build time | Script generates lessons.json; extra tooling | |

**User's choice:** Expand lessons.json to 28 (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Progress freely through drafts | Unlock ignores signedOff; sign-off is a content milestone (04-06), not a code gate | ✓ |
| Stop at signed-off frontier | "Next lesson coming soon" after alif; untestable beyond one lesson | |
| Gate by build flag | Drafts playable in debug only | |

**User's choice:** Progress freely through drafts (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Evaluate unlock.requires[] | Generic engine; linear today, supports future grouping as data change | ✓ |
| Linear index order | Lesson N unlocks on N-1 passed; requires[] becomes dead weight | |

**User's choice:** Evaluate unlock.requires[] (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Invisible to the child | Draft status is internal pipeline state | ✓ |
| Subtle dev-build marker | Debug-only draft tag on lessons | |

**User's choice:** Invisible to the child (recommended)

---

## Grade entry point & skipped lessons

| Option | Description | Selected |
|--------|-------------|----------|
| Unlocked but not mastered | Revisitable from Journey; no fake mastery; honest stars | ✓ |
| Marked as passed | Simpler unlock math but fake mastery conflicts with stars-as-genuine-markers | |
| Stay locked | Blocks revisiting earlier letters — bad for heritage learners with gaps | |

**User's choice:** Unlocked but not mastered (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| March forward from entry point | Today = first non-passed at/after startingLessonId | ✓ |
| First non-mastered overall | Keeps 03.1 rule globally; defeats grade entry points | |
| Forward, then wrap to gaps | Wraps back to skipped lessons after the last lesson | |

**User's choice:** March forward from entry point (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Like future, but tappable | Reuse existing visual; navigation is the availability signal | ✓ |
| New 'available' state | Distinct fourth look; one more visual state to design | |

**User's choice:** Like future, but tappable (recommended)

---

## Home today-card states

| Option | Description | Selected |
|--------|-------------|----------|
| Same layout, live data | Swap in live glyph/name only | |
| Add progress context | Card also shows clean-reps progress | ✓ |
| Add mascot prompt | Qalam-voice line; risks placeholder tutor copy | |

**User's choice:** Add progress context
**Notes:** Later superseded in rendering by the ink-fill metaphor (creative round) — same data, the letter itself fills with ink.

| Option | Description | Selected |
|--------|-------------|----------|
| Calm completion + review | Dignified "mastered all your letters"; Start offers review via Journey | ✓ |
| Point to the Journey | CTA navigates to Journey to pick replays | |
| Tease Level 2 | Promises Phase 7+ content that doesn't exist | |

**User's choice:** Calm completion + review (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Persist across sessions | Per-letter rep count in DB; same-sitting pedagogy flagged for owner's mother | ✓ |
| Session-only, Home shows 0 | No schema change but progress context useless | |
| Persist same-day only | Daily reset; stronger pedagogical assumption without sign-off | |

**User's choice:** Persist across sessions (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Journey only | Home stays single-purpose one-clear-Start (S1-01) | ✓ |
| Small replay link on Home | Adds navigation to the screen S1-01 wants navigation-free | |

**User's choice:** Journey only (recommended)

---

## Pass → unlock moment

| Option | Description | Selected |
|--------|-------------|----------|
| Celebration offers 'Next lesson' | Primary button straight into the new letter; momentum | ✓ |
| Return Home | Card shows new lesson; one extra tap; Home-as-anchor | |
| See journey as primary | Most visual progress, two taps from practicing | |

**User's choice:** Celebration offers 'Next lesson' (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, fold it in | Just-mastered node emphasis on arrival from celebration | ✓ |
| Keep deferred | Journey just shows updated states | |

**User's choice:** Yes, fold it in (recommended) — folds the 03.1-deferred /journey?highlight idea into Phase 6.

| Option | Description | Selected |
|--------|-------------|----------|
| Becomes 'See journey' | No next lesson exists; Home shows completion state | ✓ |
| Special completion moment | Distinct all-letters celebration; new design surface | |

**User's choice:** Becomes 'See journey' (recommended)

---

## Free discussion: creative additions

User requested open creative ideation ("get creative with me… do some research and come back with a final list"). Claude researched traditional Arabic calligraphy pedagogy (nuqta/mashq/ijaza), Kumon method principles, the protégé effect (teachable agents), haptics-in-handwriting research, and heritage-language-learner motivation research, then presented an 18-item themed list (A1–E4).

**Folded into Phase 6 (user-approved):**
- **D1 Prepared desk** — Home card entrance like a teacher laying out today's worksheet (user picked from list)
- **D2 Ink-fill progress** — the day's letter fills with ink per clean rep; replaces rep dots (user picked from list)
- **C3 "Show someone at home"** — one warm tutor line in the mastery celebration (Claude recommended; user accepted)
- **B1 Scaffolding fade** — rep→preset ramp [loose, normal, strict] as data; flagged for owner's mother sign-off (user explicitly requested in)
- **B2 Slow-motion ghost comparison** — child's wobbly stroke replayed beside reference at half speed, in-memory only (user explicitly requested in)

**Kept out of Phase 6 deliberately:** warm-up rep (needs multi-item lesson support — Phase 7), ijaza and name-capstone (deserve their own phases), and the rest → Deferred Ideas in CONTEXT.md.

## Claude's Discretion

- Route parameterization mechanics for /practice and /journey
- Lesson-pass derivation (LetterMastery rows as the pass record)
- Live journey provider replacement strategy (screen unchanged per 03.1 D-08)
- Placeholder lesson titles for lessons 2–28
- Ink-fill rendering technique; prepared-desk animation timing/curve

## Deferred Ideas

A1 Ijaza ★ · A2 Nuqta ruler · A3 Mashq sheets · B3 Pressure-sensitive ink · B4 Haptic ink · B5 Mirror-writing check · C1 Write your own name ★ · C2 First words are family words · C4 Teach Qalam (protégé effect) · C5 Mom's voice audio · D3 Warm-up rep · D4 Qalam closes the notebook · E1 Fridge page · E2 My-handwriting notebook (T-03-01-gated) · E3 Teacher insight loop · E4 Left-handed mode

(Full descriptions in 06-CONTEXT.md `<deferred>`.)
