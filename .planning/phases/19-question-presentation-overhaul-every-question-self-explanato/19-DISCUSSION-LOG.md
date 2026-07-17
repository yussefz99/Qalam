# Phase 19: Question presentation overhaul - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-17
**Phase:** 19-question-presentation-overhaul-every-question-self-explanato
**Areas discussed:** Instruction area, Stimulus & affordances, Card rewrite logistics, Keying migration

---

## Source todo

| Option | Description | Selected |
|--------|-------------|----------|
| Fold it | Findings become locked decisions in CONTEXT.md; pending todo absorbed by Phase 19 | ✓ |
| Keep separate | Reference as canonical doc, leave todo pending | |

**User's choice:** Fold it.

---

## Instruction area

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed bar in scaffold | Dedicated strip at top of ExerciseScaffold, icon + short text, same place every type | ✓ |
| Persistent speech bubble | Say line stays in mascot bubble for the whole question | |
| Card next to the canvas | Instruction adjacent to the write surface | |

| Option | Description | Selected |
|--------|-------------|----------|
| Per-type template + icon | ~10 authored strings, one per question type | ✓ |
| Show the authored say line | Render each exercise's say line as the persistent text | |
| Template headline + say detail | Both, two registers | |

| Option | Description | Selected |
|--------|-------------|----------|
| Bar is tappable to re-hear | Auto-speak once + bar tap replays any time | ✓ (via freeform) |
| Auto-speak only, no replay | Speak-once behavior kept, bar purely visual | |
| Speak the template too | TTS reads the short template instead of the say line | |

**User's choice (freeform):** "but check the last things i implemented in verify work for
phase 18 i added a button for replaying but i like your approach" → verified 18-12's
"Hear again" pill (`_HearAgainCta`); decision: bar-tap replay ABSORBS the pill (one
replay affordance; phase-07 double-Hear-button precedent).

| Option | Description | Selected |
|--------|-------------|----------|
| Draft + mother signs | Provisional pattern, she reviews in the card session | |
| Mother authors from scratch | She writes each type's instruction | |
| Draft + owner signs | Owner approves; instruction copy is product UX, not pedagogy | ✓ |

---

## Stimulus & affordances

| Option | Description | Selected |
|--------|-------------|----------|
| Child-controlled hide | Word shows large; child taps "I'm ready"/starts writing to hide; peek button | ✓ |
| Word stays visible | Pure transcription, drops the recall element | |
| Timed hide + peek | Keep auto-hide, add peek | |

| Option | Description | Selected |
|--------|-------------|----------|
| Big slot in the word | Full-size word with highlighted empty slot box, RTL-correct | ✓ |
| Underline + arrow cue | Lighter, reads less like "put it here" | |
| Gap + ghost hint | Slot + faint expected letter — gives the answer away | |

| Option | Description | Selected |
|--------|-------------|----------|
| Big replayable audio card | Large tappable speaker card fills stimulus zone; auto-plays once | ✓ |
| Keep small play button, enlarge | Header accessory sized up | |
| Audio card + mouth-shape image | Needs art assets that don't exist | |

| Option | Description | Selected |
|--------|-------------|----------|
| No model — arc is the hint path | Phase 18 remediation arc owns hinting | ✓ |
| Faint hint after 2 fails | Overlaps the arc's job | |
| Small model always visible | Recall becomes copying | |

---

## Card rewrite logistics

| Option | Description | Selected |
|--------|-------------|----------|
| Both, per card | Rewrite to baa+alif OR gate node to a later letter — mother's call per card | ✓ |
| Rewrite only | Force all 19 nodes down to baa+alif | |
| Gate only | Move every offending node out | |

| Option | Description | Selected |
|--------|-------------|----------|
| Review packet, one sitting | Per-card packet: current content, rendering, drafted rewrite, recommendation | ✓ |
| Live working session | Real-time rewrite together | |
| Async drafts, she marks up | Slowest loop | |

| Option | Description | Selected |
|--------|-------------|----------|
| Use it if ready, don't wait | Seed from 18.1 vocab if it exists at packet time | ✓ (via freeform) |
| Wait for the vocab bank | Couples critical path to partner | |
| Fully independent | Risks two competing word lists | |

**User's choice (freeform):** "do not wait start now."

| Option | Description | Selected |
|--------|-------------|----------|
| Cumulative intro order | Unit's cards use only letters introduced up to that unit; lintable; the 20–21 rule | ✓ |
| baa+alif for now, rule later | Defers the template Phase 20 inherits | |
| Learned = mastered by the child | Dynamic per-child content — much bigger change | |

---

## Keying migration

| Option | Description | Selected |
|--------|-------------|----------|
| Adopt into existing profile | Existing rows get the current profile id; new profiles start fresh | ✓ |
| Reset all progress | Wipe on migrate | |
| Ask the parent on first boot | One-time prompt UI | |

**Table-scope question — resolved via extended freeform discussion.** The owner asked to
see the full schema ("i dont want to rush the decision"), then asked how a child's
profile/attempts/strengths actually work, then paused ("i feel lost wtf") → plain-words
re-explanation → owner raised the real concern: "that feels like the architecture and
the schema are fragile" → reframed from "patch the resume bug" to "make child identity a
first-class rule": identity-model ADR + all six progress tables in one migration + legacy
LetterReps retired + cloud stays account-level by written rule. **Owner: "yes and add it
to this phase i cant afford to delay things i need the app ready by tomorrow."**

| Option | Description | Selected |
|--------|-------------|----------|
| Code live, mother session follows | Bar/affordances/migration on-device by tomorrow; rewrites ship signed:false; her sitting non-blocking | ✓ |
| Everything incl. her sign-off | Requires her sitting tonight | |
| Stable demo build only | No Phase 19 work in tomorrow's build | |

---

## Claude's Discretion

- Instruction-bar visuals, icon set, template wording drafts (owner signs strings)
- Peek/"I'm ready" affordance styling; slot-box rendering details within the design kit
- Migration mechanics (schema bump, adoption query, LetterReps read-fold before retirement)
- Card№ → exercise-id mapping for № 10, 15–20 (resolve during research/planning)
- Test depth per surface (live-path widget tests mandatory per the Phase-15 lesson)

## Deferred Ideas

- Per-child cloud model dimension (recorded in the identity ADR as deferred)
- Mouth-shape/articulation imagery for audio stimulus
- In-question fade-in hints for recall types (arc owns hinting)
- Profile-switching UI (multi-profile deprioritized by owner 2026-07-16)
