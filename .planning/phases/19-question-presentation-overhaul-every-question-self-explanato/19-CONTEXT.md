# Phase 19: Question presentation overhaul — every question self-explanatory on screen - Context

**Gathered:** 2026-07-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Every non-trace question tells the child what to do from the screen alone — a persistent
instruction bar (icon + short per-type text, tappable to re-hear), a large stimulus zone
(image / replayable audio card / word-to-copy), and a per-type "what to do" affordance —
with the spoken line as reinforcement, never the only carrier. The language cards
(№ 10, 15–20) are rewritten with the owner's mother so the first unit demands only
learned letters (cumulative intro-order rule — this becomes the template Phases 20–21
follow). Micro-drills return to the live graph behind the reworked presentation. Child
identity becomes a first-class schema rule: an identity-model ADR + ALL six per-child
progress tables re-keyed by (childProfileId, letterId) in one migration, legacy rep
counter retired.

**Hard constraint — deadline:** the owner needs the app ready by 2026-07-18 ("tomorrow").
**Sequencing rule:** all CODE work (instruction bar, stimulus/affordances, keying
migration, micro-drill return) is planned to be built and on-device by then; the mother's
card-rewrite sitting is explicitly NON-BLOCKING — rewrites ship drafted `signed:false`
(established provisional pattern) and her session lands whenever she is available.

</domain>

<decisions>
## Implementation Decisions

### Instruction area
- **D-01: Fixed instruction bar in `ExerciseScaffold`.** A dedicated strip at the top —
  icon + short text — same place on every question type. One landing covers all 10 types.
  The mascot speech bubble stays reserved for the tutor's coaching voice. (This revises
  the prototype contract that pulled `say` out of the header with no persistent
  replacement.)
- **D-02: Per-type template + icon.** ~10 authored strings, one per question type
  ("Trace the letter", "Write the missing letter", "Copy the word") in the child's
  working language (English, per the design system rule). The authored `say` line stays
  the spoken/bubble layer — the bar is not a transcript of it.
- **D-03: Bar is tappable to re-hear, and ABSORBS the 18-12 "Hear again" pill.** The say
  line still auto-speaks once on question start (the 18 instruction-hold — canvas held
  while speaking, 8s cap — stays as-is); tapping the bar replays it any time. ONE replay
  affordance on screen, not two (the Phase-07 double-Hear-button device bug is the
  cautionary precedent). `_HearAgainCta` folds into the bar.
- **D-04: Instruction strings = draft + OWNER signs.** Instruction copy is product UX,
  not pedagogy — no mother gate on the ~10 templates.

### Stimulus & per-type affordances
- **D-05: `writeWord.copy` = child-controlled hide + peek.** The word shows large in the
  stimulus zone; the child taps "I'm ready" (or starts writing) to hide it; a peek button
  brings it back. Memory-training intent preserved; nothing vanishes on a timer.
- **D-06: Gap marker = big slot in the word.** `completeWord`/`fillBlank` render the word
  at full stimulus size with an empty highlighted slot box (dotted outline / gentle pulse
  per design kit) exactly where the missing piece goes, RTL-correct. The literal
  `__blank__` marker is gone.
- **D-07: Audio stimulus = big replayable audio card.** Listen-and-write questions fill
  the stimulus zone with a large tappable speaker card — auto-plays once, tap to replay.
  Visually distinct from the instruction bar's replay (bar = what to do; card = the sound
  to write). Consumes 18.1 partner pronunciation clips as they land; placeholder clips
  until then.
- **D-08: No visual model on write-from-memory types.** `writeLetter`/`writeWord` recall
  questions show no letter model — the Phase 18 remediation arc IS the hint path
  (same-criterion fail streak steps down to trace). One hint mechanism, not two; recall
  stays honest.

### Card rewrite logistics (mother session — non-blocking for the deadline)
- **D-09: Rewrite OR gate, per card — her call.** Each offending card either gets a
  baa+alif-only rewrite (where honest words exist) or its node GATES to a later letter's
  unit (where the type fundamentally needs more letters, e.g. sentences/grammar).
- **D-10: Review packet, one sitting.** Prepare per-card: current content, its on-screen
  rendering, a drafted rewrite, and a rewrite-vs-gate recommendation. She edits, decides,
  signs; changes land as `exercises.json` edits + `signedOff` flips (15-07/17-10 pattern).
- **D-11: Start drafting NOW — never wait on the 18.1 partner track.** Owner's words:
  "do not wait start now." Fold partner baa+alif vocab in opportunistically if it exists
  at packet time; Phase 19 never blocks on it.
- **D-12: Learned-letters rule = cumulative intro order.** A unit's cards may use only
  letters introduced up to and including that unit (baa's unit = alif + baa). Static,
  authorable, enforceable by a lint over `exercises.json`. This is THE authoring rule
  Phases 20–21 inherit.

### Child identity & keying migration
- **D-13: Identity-model ADR (new, this phase).** One written rule: account uid = which
  family's database file; `childProfileId` = which child inside it; EVERY table that
  records a child's progress MUST carry `childProfileId` in its key. Future tables start
  correct instead of repeating the leak.
- **D-14: ALL six progress tables re-keyed in ONE migration.** `LetterMastery`,
  `LetterReps`, `LetterGraphPosition`, `LetterExerciseReps`, `ArcStateRows`,
  `LetterCriterionEvidence` gain `childProfileId` in the primary key. No half-keyed
  state — the owner explicitly rejected the patch framing ("the schema feels fragile" →
  resolved into the structural fix).
- **D-15: Legacy `LetterReps` retired in the same migration.** One way to count reps
  (`LetterExerciseReps`), not two. Migrate/fold any live reads before dropping.
- **D-16: Migration adopts existing rows into the current profile.** Whoever was
  practicing keeps every bit of progress; new profiles start fresh at the opening. No
  reset, no parent prompt, no more delete-and-reinstall workaround.
- **D-17: Cloud model stays ACCOUNT-level by the same written rule.** `child_models/{uid}`
  and `ChildProfileMirror` keep their uid key; the per-child cloud dimension is
  documented in the ADR as deferred until multi-profile is a real feature (owner has
  deprioritized multi-profile).

### Micro-drill return (mostly mechanical — Phase 18 decided the design)
- **D-18: Re-add the 3 authored baa micro-drill nodes to the live graph** behind the
  reworked presentation (instruction bar + Spotlight chrome from 18-10). Selection logic
  is already pinned by `test/tutor/microdrill_selection_test.dart`; D-05/D-06/D-08 from
  18-CONTEXT (Spotlight variant, real graph nodes, target-criterion-owns-verdict) carry
  forward unchanged.

### Claude's Discretion
- Instruction-bar visual treatment, icon set, and exact template wording (owner signs the
  strings; drafting + design-kit fit is Claude's).
- Peek-button and "I'm ready" affordance styling; slot-box rendering details (dotted vs
  pulse) within the design kit.
- Migration mechanics: Drift schema-version bump, adoption query shape, how `LetterReps`
  reads are folded before retirement.
- Card-to-exercise-id mapping for № 10, 15–20 (resolve from the baa ladder during
  research/planning).
- Test depth per surface (widget tests for the bar/affordances; migration tests for the
  re-key — live-path widget tests are MANDATORY per the Phase-15 dead-wire lesson).

### Folded Todos
- **`.planning/todos/pending/2026-07-12-question-presentation-overhaul.md`** — the
  phase's named source (owner device-UAT findings, 2026-07-12). All six of its findings
  are absorbed: persistent instruction (D-01..04), stimulus zone (D-05..07), per-type
  affordance (D-05..08), card rewrite (D-09..12), micro-drill return (D-18), per-child
  keying (D-13..17). The pending todo is closed by this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase source & intent
- `.planning/todos/pending/2026-07-12-question-presentation-overhaul.md` — the owner's
  device-UAT findings this phase exists to fix (folded; see D-01..D-18).
- `.planning/ROADMAP.md` §Phase 19 — goal + success criteria (self-explanatory questions,
  learned-letters-only first unit, micro-drills back, per-child cursors).

### Design & presentation sources of truth
- `docs/design/kit/` — the Qalam Design System (tokens, brand rules, tablet UI kit) —
  canonical for the bar/card/slot visual language.
- `docs/design/prototypes/letter-unit-baa/prototype/exercise-components/components.js` +
  `components.css` + `docs/design/prototypes/letter-unit-baa/COMPONENTS.md` — the
  prototype contract PromptHeader/ExerciseScaffold are pixel-faithful to today; D-01
  deliberately revises its "say is speech-only" rule.

### The locked tutor spine (do NOT relitigate)
- `docs/architecture/ADR-017-scorer-owns-verdict-derived-facts.md` — scorer owns
  pass/fail; only derived non-PII facts cross the wire. The keying migration is
  client-local and must not add wire fields.
- `.planning/phases/18-build-the-living-tutor-dynamic-exercise-selection/18-CONTEXT.md` —
  micro-drill design (D-05 Spotlight, D-06 real graph nodes, D-08 target-criterion
  verdict), remediation-arc decisions this phase's D-08 leans on.

### Code seams this phase touches
- `lib/features/letter_unit/widgets/exercise_scaffold.dart` — the ONE scaffold all 10
  types render through; home of the instruction bar (D-01), the 18-12 `_HearAgainCta` to
  absorb (D-03), and the 18 instruction-hold to preserve.
- `lib/features/letter_unit/widgets/prompt_header.dart` — the PromptPart composition
  engine (say/audio/image/text/rule); stimulus-zone changes (D-05..07) land here/beside it.
- `lib/features/letter_unit/exercise_presenter.dart` — the graph-node → surface resolver
  (18-07/18-12 presentEpoch fresh-mount mechanism — do not break it).
- `lib/data/app_database.dart` — schema v6, all nine tables; the migration home
  (D-13..17). Precedents: v2→v3, v4→v5 idempotent migrations.
- `assets/curriculum/exercises.json` + `assets/curriculum/curriculum_graph.json` — card
  rewrites/gating (D-09) + micro-drill node re-add (D-18); server copy re-derived via
  `server/app/curriculum_data/generate.py` (never hand-edit the server copy).
- `test/tutor/microdrill_selection_test.dart` — micro-drill selection behavior, pinned;
  must stay green through the re-add.

### Parallel partner track (coordination, not dependency)
- `.planning/PARTNER-BRIEF.md` (Phase 18.1) — partner is producing pronunciation clips +
  a draft vocab bank in parallel; D-07 consumes clips as they land, D-11 says never wait.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`ExerciseScaffold`** (1133 lines): the single render path for all 10 question types —
  the instruction bar lands once here and covers everything. Already hosts the 18-12
  "Hear again" pill (`_HearAgainCta`, to be absorbed) and the 18 instruction-hold
  (`_instructionHold`, canvas dimmed+ignored while the say line speaks, 8s cap — keep).
- **`PromptHeader`**: ordered PromptPart composition (audio/image/text/rule) with the
  lone-image responsive path already shipped for pictures (18 UAT T2) — the pattern the
  big audio card (D-07) and slot-word rendering (D-06) follow.
- **`presentGraphExercise` + presentEpoch**: fresh-mount-per-presentation mechanism
  (18-12) — new presentation chrome must run through it, not around it.
- **`TtsCoachSpeaker` / always-speak rail (16-02, 17.2)**: the speech seam the bar's
  replay tap re-invokes — no new audio plumbing needed.
- **Drift migration precedents**: v2→v3 (profiles) and v4→v5 (graph position) idempotent
  version-guarded `onUpgrade` blocks — the shape D-14's v6→v7 migration follows.
- **`SpotlightOverlay` (18-10)**: micro-drill chrome already built; D-18's re-add lights
  it on the live path.

### Established Patterns
- **Provisional → sign-off (`signed:false`)**: card rewrites and any gated-node change
  ship provisional; the mother's flip is the only content change (15-07/17-10). This is
  what makes the deadline sequencing (code now, sitting later) safe.
- **Anti-gamification**: no new reward surfaces in the bar/cards/affordances; stars
  untouched.
- **Live-path widget tests mandatory** for anything claiming "wired into the live path"
  (Phase-15 dead-wire lesson; 18-07 precedent).
- **`isMasteryMet` over essential nodes** must keep working through the re-key — mastery
  reads `LetterExerciseReps` (now per-child).

### Integration Points
- Instruction bar ↔ `ExerciseScaffold` build + the say-line/TTS seam (replay tap).
- Stimulus zone ↔ `PromptHeader` part rendering per type.
- Keying migration ↔ every repository over the six progress tables
  (`GraphPositionRepository`, mastery/reps accessors, arc-state, evidence queue) + the
  providers that read them; `childProfileId` comes from `ChildProfiles.id` via
  `childProfileProvider`.
- Micro-drill re-add ↔ `curriculum_graph.json` asset + `generate.py` server re-derive +
  selection policy (already drill-aware, test-pinned).

</code_context>

<specifics>
## Specific Ideas

- The owner reviewed the 18-12 "Hear again" control on device and endorsed folding it
  into the tappable instruction bar: one replay affordance, always in the same place.
- The owner's fragility concern about the schema was resolved by REFRAMING the keying fix
  from "patch the resume bug" to "make child identity a first-class rule" — the ADR
  (D-13) is part of the deliverable, not documentation garnish.
- Deadline framing: "I can't afford to delay things, I need the app ready by tomorrow"
  (2026-07-17). The plan must front-load device-visible code work; human gates
  (mother sitting) are explicitly decoupled.

</specifics>

<deferred>
## Deferred Ideas

- **Per-child cloud model dimension** (`child_models` keyed by child, wire field, rules,
  compiler change) — deferred until multi-profile is a real feature; recorded in the
  identity-model ADR (D-17).
- **Mouth-shape/articulation imagery for audio stimulus** — needs new art assets not in
  the 18.1 brief; revisit with the partner track if phonics support deepens.
- **In-question fade-in hints for recall types** — rejected for now (D-08); the
  remediation arc owns hinting. Revisit only if arc data shows children stuck pre-arc.
- **Profile-switching UI** — keying makes multiple profiles SAFE, but no new UI for
  creating/switching profiles this phase (multi-profile deprioritized by owner,
  2026-07-16).

</deferred>

---

*Phase: 19-question-presentation-overhaul-every-question-self-explanato*
*Context gathered: 2026-07-17*
