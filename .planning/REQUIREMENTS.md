# Requirements: Qalam — v1 Core Learning Loop

**Defined:** 2026-05-30
**Core Value:** A child traces an Arabic letter, gets immediate specific feedback on their actual strokes, and advances through a real teacher's curriculum — so the language sticks through the hand.

v1 = the owner's **Sprint 1** (`docs/USER_STORIES.md`), built as written. Local-only,
on-device, no auth, **no Claude AI tutor** (the tutor is the v2 milestone). Story IDs
(S1-xx) are preserved as canonical requirement IDs; derived technical requirements use
CUR-/PLAT- IDs.

## v1 Requirements

### Onboarding & Profiles

- [ ] **S1-02**: A parent can create a child profile with name and grade, and the grade selects the curriculum entry point
  - *Accept:* profile persists locally; grade maps to a starting lesson; no real-name exposure beyond the device (minimum child data)
- [ ] **S1-03**: A child can pick an avatar and nickname on first open
  - *Accept:* selection persists; choices are from a fixed set (no free-text that leaks identity); shown on the home screen

### Daily Lesson & Progression

- [ ] **S1-01**: On opening the app, the child immediately sees today's lesson already prepared, with one clear way to start
  - *Accept:* landing shows the next unlocked lesson for the current child; a single prominent Start; no navigation required
- [ ] **S1-09**: The next lesson unlocks only after the child passes the current one
  - *Accept:* "pass" = the curriculum's clean-reps-to-advance for that item; locked lessons are visibly unavailable; unlock is immediate on pass

### Handwriting Practice (the core loop)

- [ ] **S1-04**: Before writing a letter, the child can watch (and replay) an animation of the correct stroke order
  - *Accept:* animation is driven by the same reference stroke paths used for scoring; replayable; plays per letter and per contextual form
- [ ] **S1-05**: The child traces letters with a stylus and receives instant on-device feedback on shape and stroke order
  - *Accept:* feedback evaluates stroke count, order, direction, and shape match; the failing stroke is highlighted; the message names the specific fix using the letter's curriculum "common mistakes"; feedback appears < ~300 ms after stylus-up, fully offline; built on a custom geometric scorer (ML Kit used only as a secondary letter-identity check)
- [ ] **S1-10**: The child earns a mastery star when they complete a lesson
  - *Accept:* a star marks **real mastery** (earned via the curriculum's clean-reps), shown on the journey map as progress; a single dignified celebration at mastery; NO running totals, NO weekly tallies, NO streaks/badges, no "+N keep going" hype

### Audio

- [ ] **S1-06**: The child can hear the correct pronunciation of each letter and word
  - *Accept:* tappable audio per letter and per word; bundled pre-recorded clips (works offline); no TTS

### Exercises

- [ ] **S1-07**: The child can complete sentence-building exercises that show how Arabic words connect to form meaning
  - *Accept:* handwriting-first interaction (never reduces to tap-one-of-four); content comes from the curriculum schema
- [ ] **S1-08**: The child can complete grammar exercises at their level
  - *Accept:* level-appropriate per the child's progression; handwriting-first; content authored in the curriculum, not invented

### Parent View

- [ ] **S1-11**: A parent can see the child's completed lessons and scores
  - *Accept:* PIN-gated parent area; read-only local progress (lessons completed, scores); no cloud, no account

### Curriculum Content & Platform (derived from research)

- [ ] **CUR-01**: The full curriculum (28 letters + words + sentences + grammar) authored by the owner's mother is held in a faithful data schema that the code only reads
  - *Accept:* schema holds, per letter: contextual forms, ordered reference stroke paths (coordinates), stroke order, intro order, clean-reps-to-advance, per-letter pass tolerances, 3–4 common mistakes (each with a child-friendly fix message), and audio references; words/sentences/grammar content modeled; placeholder entries (if any) are explicitly marked; owner's-mother sign-off gate before lessons ship
- [ ] **PLAT-01**: The app runs fully offline, local-only, with no account or login (satisfies NTH-05 by design)
  - *Accept:* every v1 flow works airplane-mode; the ML Kit Arabic model is fetched once at onboarding then cached; verified on a fresh install with no network
- [ ] **PLAT-02**: Arabic renders correctly RTL with connected-script shaping
  - *Accept:* correct isolated/initial/medial/final forms; the dotted guide letter is drawn from reference paths (not a Text widget); chosen font glyph-audited across all curriculum letters and forms; numeral system chosen explicitly
- [ ] **PLAT-03**: The experience stays not-points-chasing and on-brand (per `docs/design/kit/`)
  - *Accept:* no running star totals, no weekly tallies, no streaks, no badges, no confetti spam, no timed tests, no over-praise of sloppy work; feedback is specific, not generic "Oops, try again". The **Qalam mascot is the tutor's persona** (in), and **mastery stars** + a dignified per-mastery celebration + the journey map are in. Visuals follow the design system tokens (gold = rewards-only, coral not red, no emoji/unicode pseudo-icons)

## v2 Requirements

Deferred to the next milestone (owner's **Sprint 2 — Qalam AI Tutor**). Tracked, not in this roadmap.

### AI Tutor & Adaptation

- **S2-01**: Placement exam on first join to set the correct level across subjects
- **S2-02**: The Qalam character gives specific spoken feedback (in English) on exactly what was wrong
- **S2-03**: The child can press a button and ask Qalam a question out loud
- **S2-04**: Qalam gives extra practice on the topics/letters the child keeps getting wrong
- **S2-05**: The app adjusts the daily lesson based on recent performance
- **S2-06**: A parent can see which specific topics and letters the child struggles with
- **S2-07**: A parent can set a daily practice-duration goal
- **S2-08**: Vocabulary flashcards with pictures
- **S2-09**: Short Arabic reading passages with comprehension questions
- **S2-10**: A parent receives a weekly progress report

*(These bring in Firebase Auth, Firestore cloud sync, and Python Cloud Functions, plus the across-session nightly profile compiler.)*

## Out of Scope

Explicitly excluded for v1. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Daily streaks (NTH-01) | Pressure mechanic — contradicts anti-gamification |
| Badges (NTH-02) | Pressure mechanic — contradicts anti-gamification; only the gentle star (S1-10) is allowed |
| Reminder notifications (NTH-03) | Pressure mechanic; backlog |
| Multiple children under one account (NTH-04) | Needs auth; revisit after v2 introduces accounts |
| Teacher dashboards / lesson assignment (NTH-06, NTH-07) | Backlog; not a near-term goal |
| Tap-the-answer / multiple-choice foreign-language drills | The anti-product Qalam positions against |
| Cartoon mascot, confetti, timed tests | Anti-gamification |
| iOS (deployment, PencilKit) | Android-only for now |
| Any backend (Firebase Auth/Firestore/Functions), Claude tutor | Deferred to v2 |

## Traceability

Which phase covers which requirement. Each v1 requirement maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLAT-02 | Phase 1 — Foundations & RTL Shell | Pending |
| CUR-01 | Phase 7 — Full Curriculum & Pronunciation Audio (seeded in Phase 2) | Pending |
| S1-04 | Phase 3 — Trace One Letter End-to-End | Pending |
| S1-05 | Phase 3 — Trace One Letter End-to-End (deepened in Phase 4) | Pending |
| S1-10 | Phase 3 — Trace One Letter End-to-End | Pending |
| PLAT-03 | Phase 3 — Trace One Letter End-to-End | Pending |
| S1-02 | Phase 5 — Profiles & Onboarding | Pending |
| S1-03 | Phase 5 — Profiles & Onboarding | Pending |
| S1-01 | Phase 6 — Lesson Progression & Home | Pending |
| S1-09 | Phase 6 — Lesson Progression & Home | Pending |
| S1-06 | Phase 7 — Full Curriculum & Pronunciation Audio | Pending |
| S1-07 | Phase 8 — Sentence-Building & Grammar Exercises | Pending |
| S1-08 | Phase 8 — Sentence-Building & Grammar Exercises | Pending |
| S1-11 | Phase 9 — Parent Dashboard | Pending |
| PLAT-01 | Phase 10 — Offline Hardening & Release | Pending |

**Notes:**
- **CUR-01** is *seeded* in Phase 2 (small signed-off subset that unblocks the end-to-end slice) and *fully satisfied* in Phase 7 (all 28 letters + words). It maps to Phase 7 for coverage.
- **S1-05 / PLAT-03** are first delivered in Phase 3 and *deepened* in Phase 4 (scorer calibration) — counted under Phase 3 for coverage.
- **PLAT-03 (anti-gamification)** is cross-cutting; its acceptance is folded into Phase 3 (feedback tone, quiet star) and re-checked in every UI phase rather than owning a standalone phase.

**Coverage:**
- v1 requirements: 15 total (11 stories + 4 derived)
- Mapped to phases: 15 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-30*
*Last updated: 2026-05-30 after roadmap creation (traceability populated)*
