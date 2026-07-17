# Phase 19: Question presentation overhaul — every question self-explanatory on screen - Research

**Researched:** 2026-07-17
**Domain:** Flutter/Dart exercise-presentation UI (RTL tablet) + Drift schema migration (per-child keying) + curriculum content authoring
**Confidence:** HIGH (every claim below is from direct source reads of this repo, not training data)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Instruction area**
- **D-01: Fixed instruction bar in `ExerciseScaffold`.** A dedicated strip at the top — icon + short text — same place on every question type. One landing covers all 10 types. The mascot speech bubble stays reserved for the tutor's coaching voice. (Revises the prototype contract that pulled `say` out of the header with no persistent replacement.)
- **D-02: Per-type template + icon.** ~10 authored strings, one per question type ("Trace the letter", "Write the missing letter", "Copy the word") in the child's working language (English, per the design system rule). The authored `say` line stays the spoken/bubble layer — the bar is not a transcript of it.
- **D-03: Bar is tappable to re-hear, and ABSORBS the 18-12 "Hear again" pill.** The `say` line still auto-speaks once on question start (the 18 instruction-hold — canvas held while speaking, 8s cap — stays as-is); tapping the bar replays it any time. ONE replay affordance on screen, not two (Phase-07 double-Hear-button device bug is the cautionary precedent). `_HearAgainCta` folds into the bar.
- **D-04: Instruction strings = draft + OWNER signs.** Instruction copy is product UX, not pedagogy — no mother gate on the ~10 templates.

**Stimulus & per-type affordances**
- **D-05: `writeWord.copy` = child-controlled hide + peek.** The word shows large in the stimulus zone; the child taps "I'm ready" (or starts writing) to hide it; a peek button brings it back. Memory-training intent preserved; nothing vanishes on a timer.
- **D-06: Gap marker = big slot in the word.** `completeWord`/`fillBlank` render the word at full stimulus size with an empty highlighted slot box (dotted outline / gentle pulse per design kit) exactly where the missing piece goes, RTL-correct. The literal `__blank__` marker is gone.
- **D-07: Audio stimulus = big replayable audio card.** Listen-and-write questions fill the stimulus zone with a large tappable speaker card — auto-plays once, tap to replay. Visually distinct from the instruction bar's replay (bar = what to do; card = the sound to write). Consumes 18.1 partner pronunciation clips as they land; placeholder clips until then.
- **D-08: No visual model on write-from-memory types.** `writeLetter`/`writeWord` recall questions show no letter model — the Phase 18 remediation arc IS the hint path (same-criterion fail streak steps down to trace). One hint mechanism, not two; recall stays honest.

**Card rewrite logistics (mother session — non-blocking for the deadline)**
- **D-09: Rewrite OR gate, per card — her call.** Each offending card either gets a baa+alif-only rewrite (where honest words exist) or its node GATES to a later letter's unit (where the type fundamentally needs more letters, e.g. sentences/grammar).
- **D-10: Review packet, one sitting.** Per-card: current content, its on-screen rendering, a drafted rewrite, and a rewrite-vs-gate recommendation. She edits, decides, signs; changes land as `exercises.json` edits + `signedOff` flips (15-07/17-10 pattern).
- **D-11: Start drafting NOW — never wait on the 18.1 partner track.** Owner's words: "do not wait start now." Fold partner baa+alif vocab in opportunistically if it exists at packet time; Phase 19 never blocks on it.
- **D-12: Learned-letters rule = cumulative intro order.** A unit's cards may use only letters introduced up to and including that unit (baa's unit = alif + baa). Static, authorable, enforceable by a lint over `exercises.json`. This is THE authoring rule Phases 20–21 inherit.

**Child identity & keying migration**
- **D-13: Identity-model ADR (new, this phase).** One written rule: account uid = which family's database file; `childProfileId` = which child inside it; EVERY table that records a child's progress MUST carry `childProfileId` in its key. Future tables start correct instead of repeating the leak.
- **D-14: ALL six progress tables re-keyed in ONE migration.** `LetterMastery`, `LetterReps`, `LetterGraphPosition`, `LetterExerciseReps`, `ArcStateRows`, `LetterCriterionEvidence` gain `childProfileId` in the primary key. No half-keyed state — the owner explicitly rejected the patch framing.
- **D-15: Legacy `LetterReps` retired in the same migration.** One way to count reps (`LetterExerciseReps`), not two. Migrate/fold any live reads before dropping.
- **D-16: Migration adopts existing rows into the current profile.** Whoever was practicing keeps every bit of progress; new profiles start fresh at the opening. No reset, no parent prompt, no more delete-and-reinstall workaround.
- **D-17: Cloud model stays ACCOUNT-level by the same written rule.** `child_models/{uid}` and `ChildProfileMirror` keep their uid key; the per-child cloud dimension is documented in the ADR as deferred until multi-profile is a real feature.

**Micro-drill return (mostly mechanical — Phase 18 decided the design)**
- **D-18: Re-add the 3 authored baa micro-drill nodes to the live graph** behind the reworked presentation (instruction bar + Spotlight chrome from 18-10). Selection logic is already pinned by `test/tutor/microdrill_selection_test.dart`; D-05/D-06/D-08 from 18-CONTEXT (Spotlight variant, real graph nodes, target-criterion-owns-verdict) carry forward unchanged.

**Hard constraint — deadline:** owner needs the app ready by 2026-07-18. All CODE work is planned to be built and on-device by then; the mother's card-rewrite sitting is explicitly NON-BLOCKING — rewrites ship drafted `signedOff:false` and her session lands whenever she is available.

### Claude's Discretion
- Instruction-bar visual treatment, icon set, and exact template wording (owner signs the strings; drafting + design-kit fit is Claude's).
- Peek-button and "I'm ready" affordance styling; slot-box rendering details (dotted vs pulse) within the design kit.
- Migration mechanics: Drift schema-version bump, adoption query shape, how `LetterReps` reads are folded before retirement.
- Card-to-exercise-id mapping for № 10, 15–20 (resolve from the baa ladder during research/planning). **Resolved below — see Card Rewrite Content Model.**
- Test depth per surface (widget tests for the bar/affordances; migration tests for the re-key — live-path widget tests are MANDATORY per the Phase-15 dead-wire lesson).

### Deferred Ideas (OUT OF SCOPE)
- Per-child cloud model dimension (`child_models` keyed by child, wire field, rules, compiler change) — deferred until multi-profile is a real feature; recorded in the identity-model ADR (D-17).
- Mouth-shape/articulation imagery for audio stimulus — needs new art assets not in the 18.1 brief.
- In-question fade-in hints for recall types — rejected (D-08); the remediation arc owns hinting.
- Profile-switching UI — keying makes multiple profiles SAFE, but no new UI for creating/switching profiles this phase (multi-profile deprioritized by owner).
</user_constraints>

<phase_requirements>
## Phase Requirements

The phase description marks requirement IDs as "TBD (derive from the owner UAT findings at plan time)." Below is a concrete, proposed ID set derived from the six folded UAT findings + the CONTEXT decisions, so the planner can map plans to requirements. **The IDs themselves are a proposal `[ASSUMED]` — the owner/planner may rename; the behaviors are locked by CONTEXT.**

| ID (proposed) | Behavior | Source decisions | Research support |
|----|----------|------------------|------------------|
| QP-01 | Every non-trace question shows a persistent instruction area (icon + short child-readable text), never TTS-only | D-01, D-02 | `ExerciseScaffold._mainColumn` is the single landing; `_hasInstruction`/`_speakInstructionThenRelease` already isolate the say-line seam |
| QP-02 | The instruction area is tappable to replay the spoken line; the 18-12 `_HearAgainCta` pill is absorbed into it (one replay affordance) | D-03 | `_HearAgainCta` + `_speakInstructionThenRelease()` already exist in `exercise_scaffold.dart:730-739, 1089` |
| QP-03 | `writeWord.copy` reveals the word large, then hides on child action ("I'm ready" / first stroke) with a peek button | D-05 | Today: `reveal:"thenHide"` dims the `TextPart` to opacity 0.18 statically (`prompt_header.dart:372`); needs child-controlled state |
| QP-04 | `completeWord`/`fillBlank` render a big highlighted slot box at the gap, RTL-correct; literal `__blank__` gone | D-06 | Today: `_GapWord`/`_GapLetter` render small 46px inline chips (`prompt_header.dart:426-461`); `TextPart._tokens()` splits on `__blank__`/`_letter_` |
| QP-05 | Listen-and-write questions show a large replayable audio card as the stimulus, auto-play once | D-07 | Today: audio is a small `_AudioPart` teal button inside the header row (`prompt_header.dart:140`) |
| QP-06 | Recall write types show no letter model; the remediation arc is the only hint path | D-08 | Arc already wired (`LetterUnitController._sessionArc`, 18-07); ensure no model part is authored on recall nodes |
| QP-07 | The first (baa) unit's cards use only learned letters (alif+baa); offending cards rewritten or gated | D-09..D-12 | `letters` field on every exercise (`exercises.json`) + `introOrder` (`letters.json`) are the lint substrate |
| QP-08 | Micro-drills return to the live curriculum graph | D-18 | `microdrill_selection_test.dart` pins selection; nodes/configs already authored `signedOff:false` |
| QP-09 | Six per-child progress tables re-keyed `(childProfileId, letterId)` in one migration; existing rows adopted; a fresh profile starts at the opening | D-13..D-17 | Drift schema v6 → v7; `TableMigration` recreate path; `ChildProfiles.id` is the adopt key |
| QP-10 | Identity-model ADR written (account uid = db file; childProfileId = child in it; every progress table carries childProfileId) | D-13 | New `docs/architecture/ADR-018-*.md` (follows ADR-017 pattern) |

**Success criteria (from ROADMAP, must be TRUE):**
1. Any question type read cold from the screen alone tells the child what to do — instruction + stimulus + affordance — spoken line as reinforcement, never the only carrier. (QP-01..06)
2. The first unit's language cards use only letters the child has learned; sentences/grammar gate to later letters. (QP-07)
3. Micro-drills are back in the live graph behind the reworked presentation. (QP-08)
4. Two child profiles on one device keep separate graph cursors/arc state (a fresh profile starts at the opening). (QP-09)
</phase_requirements>

## Summary

This is a three-track phase over an already-mature Flutter codebase, all client-local (no new network, no new packages). **Track A (presentation):** every one of the ~10 question types renders through a single widget — `ExerciseScaffold` (1133 lines) with its `PromptHeader` composition engine (563 lines). The instruction bar (D-01) lands once in `ExerciseScaffold._mainColumn`; the stimulus/affordance changes (D-05/06/07) land in or beside `PromptHeader`'s part renderers. The spoken-line-only assumption is concentrated in exactly two places: `PromptHeader` deliberately *filters out* the `say` part (`components.js` rule, prompt_header.dart:14-16, 63-64), and `ExerciseScaffold._speakInstructionThenRelease()` speaks it once with no persistent on-screen echo. That is the whole gap the UAT flagged.

**Track B (content):** the "learned-letters-only" rule (D-12) already has its enforcement substrate — every exercise in `exercises.json` carries a `letters` array (the cross-family label added in 18-02) and every letter carries an `introOrder` in `letters.json` (alif=1, baa=2). A lint that asserts `every letter in exercise.letters has introOrder <= the unit's introOrder` is a small pure-Dart test. Seven baa cards violate it today (enumerated below). D-09 rewrites or gates each; drafts ship `signedOff:false`.

**Track C (keying migration):** the six progress tables are keyed by `letterId` only. Drift is at 2.31.0 (sqlite3 2.9.4). SQLite cannot alter a primary key in place, so the migration uses Drift's `TableMigration`/`alterTable` recreate path (v6 → v7), backfilling `childProfileId` from the single `ChildProfiles.id` row (D-16 adoption). The riskiest sub-item is **D-15 (retire `LetterReps`)** — it has three live reader sites (parent dashboard, practice provider, journey progression ribbon) that must be folded to `LetterExerciseReps` before the drop.

**Primary recommendation:** Split into ~5 plans — (1) instruction bar + replay-fold in `ExerciseScaffold`; (2) stimulus/affordance renderers in `PromptHeader` (slot box, audio card, copy hide+peek); (3) the keying migration + repository/controller threading + `LetterReps` fold + ADR; (4) micro-drill live-graph re-add + `generate.py` re-derive; (5) content lint + card rewrite drafts + review packet. Live-path widget tests are mandatory on Tracks A and C (Phase-15 dead-wire lesson). Front-load Tracks A and C (device-visible by the deadline); the mother's sitting (Track B sign-off) is decoupled.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persistent instruction area (D-01/02/03) | Flutter widget (`ExerciseScaffold`) | — | Pure presentation over an existing `Exercise` config; one landing covers all types |
| Stimulus zone: slot box / audio card / copy hide+peek (D-05/06/07) | Flutter widget (`PromptHeader` + a small `StatefulWidget` for copy state) | — | Per-part rendering; `writeWord.copy`'s hide/peek needs local widget state |
| Learned-letters lint (D-12) | Curriculum data + a pure-Dart test | — | Static, authorable; runs over `exercises.json` + `letters.json`, no runtime |
| Card rewrite / gate (D-09) | Curriculum data (`exercises.json`, `curriculum_graph.json`) | Server re-derive (`generate.py`) | Content is the mother's domain; server copy is derived, never hand-edited |
| Micro-drill re-add (D-18) | Curriculum graph asset | Server re-derive; selection policy (already drill-aware) | Mechanical node re-add; policy/tests already built |
| Per-child keying migration (D-14..17) | Drift DB (`AppDatabase` + repositories) | Riverpod providers reading `childProfileId` | On-device persistence; server stays stateless (COPPA/ADR-017) |
| Identity-model ADR (D-13) | Docs (`docs/architecture/`) | — | Written rule that governs future table design |

## Standard Stack

No new external packages. Every capability is served by dependencies already resolved in `pubspec.lock`.

### Core
| Library | Version (locked) | Purpose | Why standard (here) |
|---------|------------------|---------|---------------------|
| `drift` | 2.31.0 | Local SQLite persistence + schema migration | Already the DB layer; `TableMigration` is Drift's supported PK-change path `[VERIFIED: pubspec.lock]` |
| `sqlite3` | 2.9.4 | SQLite engine under Drift | Pinned to the 2.x line (see 01-RESEARCH caveat re: sqlite3_flutter_libs) `[VERIFIED: pubspec.lock]` |
| `flutter_riverpod` | 3.3.1 | State management (Riverpod-only, D-11) | All providers already Riverpod; the Riverpod-3 stream-pause caveat applies (see Pitfalls) `[VERIFIED: pubspec.yaml]` |
| `flutter_tts` | 4.2.5 | The replay-tap voice (D-03) | `TtsCoachSpeaker`/`ttsCoachSpeakerProvider` already wrap it; the bar re-invokes the existing seam `[VERIFIED: pubspec.yaml + exercise_scaffold.dart:277]` |
| `go_router` | 17.2.3 | Routing (unchanged this phase) | No routing change needed `[VERIFIED: pubspec.yaml]` |
| `flutter_test` | (SDK) | Widget + migration + lint tests | The whole test suite is `flutter_test`; migration tests use a temp-file `NativeDatabase` `[VERIFIED: test/data/app_database_test.dart]` |

### Supporting (build-time, already present)
| Tool | Purpose | When to use |
|------|---------|-------------|
| `drift_dev` 2.31.0 + `build_runner` | Regenerate `app_database.g.dart` after the schema change | After editing the six table classes + bumping `schemaVersion` |
| `flutter gen-l10n` | Regenerate `app_localizations*.dart` after adding instruction-string ARB keys | After adding the ~10 D-02 template strings to `lib/l10n/app_en.arb` (generated files are gitignored) |
| `server/app/curriculum_data/generate.py` | Re-derive the server copies of `exercises.json` + `curriculum_graph.json` | After ANY content edit (D-09 rewrites, D-18 node re-add) — never hand-edit the server copy |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Drift `TableMigration` recreate | Raw `customStatement` DDL (`CREATE TABLE new … ; INSERT … SELECT … ; DROP; RENAME`) | Works but hand-rolls what `TableMigration` does safely; more error-prone under SQLite's PK-immutability. Prefer `TableMigration`. |
| Keying `LetterReps` too (literal D-14) | Retire it (D-15) | D-14 lists six tables; D-15 says retire `LetterReps`. Reconcile: 5 tables gain the key; `LetterReps` is DROPPED after folding its 3 readers (see Migration section). |
| A new l10n key per instruction string | Hardcoded English defaults in `ExerciseScaffoldStrings` | Precedent: `ExerciseScaffoldStrings` already carries English defaults + call-site l10n. Add ARB keys for consistency, but defaults keep widget tests l10n-independent. |

**Installation:** none — no `flutter pub add`.

## Package Legitimacy Audit

**No external packages are introduced by this phase.** Every library used (`drift`, `sqlite3`, `flutter_riverpod`, `flutter_tts`, `go_router`, `flutter_test`, `drift_dev`, `build_runner`) is already in `pubspec.lock` and was legitimacy-gated in its introducing phase (drift Phase 1, flutter_tts 16-02, riverpod Phase 1). slopcheck / registry verification is therefore **not applicable** — there is nothing to install.

**Packages removed due to slopcheck [SLOP] verdict:** none (nothing installed).
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```
                        assets/curriculum/exercises.json  (Exercise config, per type)
                                        │  Exercise.fromJson  (models/exercise.dart)
                                        ▼
   graph node id ──► exercise_presenter.presentGraphExercise()  ─── key = graph:<id>#<epoch>
                                        │        (fresh mount per presentation — 18-12; DO NOT break)
                                        ▼
   ┌──────────────────────────  ExerciseScaffold  (the ONE render path, all ~10 types) ──────────────────┐
   │  LEFT: _TutorColumn (mascot + speech bubble = COACHING voice only)                                   │
   │  RIGHT: _mainColumn                                                                                  │
   │     ├─ kick eyebrow + ProgressRibbon                                                                 │
   │     ├─ [NEW D-01] INSTRUCTION BAR  ← icon + per-type template text  (tappable → replay say line)     │
   │     │        └─ absorbs _HearAgainCta (D-03); re-invokes _speakInstructionThenRelease()              │
   │     ├─ PromptHeader (visual parts only; `say` is FILTERED OUT here — prompt_header.dart:14,63)       │
   │     │        ├─ AudioPart  → [NEW D-07] large replayable audio CARD                                  │
   │     │        ├─ TextPart   → [NEW D-06] big RTL slot box  / [NEW D-05] copy hide+peek                │
   │     │        ├─ ImagePart  → responsive stimulus (already shipped 18 UAT T2)                         │
   │     │        └─ RulePart / FormsPart                                                                 │
   │     ├─ WriteSurface (held/dimmed while _instructionHold; SpotlightOverlay for microDrill)            │
   │     └─ FeedbackPanelV2 + CTA                                                                         │
   └─────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                        │  on PASS → onGraphNodePassed(id)
                                        ▼
   LetterUnitController (per letterId)  ── reads/writes 6 progress tables ──►  AppDatabase (Drift)
        beginSelection → SelectionPolicy.narrow → selectNext (RouterExerciseSelector)   [ALL keyed by
        markNodeCleared / recordMasteryIfMet / _persist                                  letterId TODAY →
                                                                                          (childProfileId, letterId)
                                                                                          AFTER D-14 migration]
```

### Recommended structure (where new/changed code lives)
```
lib/features/letter_unit/widgets/
  exercise_scaffold.dart      # D-01 instruction bar lands in _mainColumn; D-03 folds _HearAgainCta
  prompt_header.dart          # D-06 slot box (_GapWord/_GapLetter), D-07 audio card (_AudioPart)
  <new> copy_stimulus.dart    # D-05 writeWord.copy child-controlled hide+peek (small StatefulWidget)
lib/data/
  app_database.dart           # D-14 six-table re-key + v7 migration; D-15 drop LetterReps
  graph_position_repository.dart, arc_state_repository.dart,
  drift_progress_repository.dart, evidence_repository.dart   # thread childProfileId
lib/features/letter_unit/letter_unit_controller.dart   # cache childProfileId at start(); pass to all writes
lib/l10n/app_en.arb           # ~10 D-02 instruction template strings + icon mapping in code
assets/curriculum/exercises.json      # D-09 rewrites; D-18 microDrill configs already present
assets/curriculum/curriculum_graph.json  # D-18 re-add microDrill competency + 3 nodes
docs/architecture/ADR-018-child-identity-keying.md   # D-13
server/app/curriculum_data/generate.py  # re-run to re-derive server copies (do not hand-edit)
```

### Pattern 1: The instruction bar reuses the existing say-line seam (D-01/D-03)
**What:** Add a persistent strip in `_mainColumn` (between the ribbon row and `PromptHeader`). Text = a per-type template resolved from `exercise.type` (D-02), not the `say` line. Tapping it calls the already-present `_speakInstructionThenRelease()` (which stops in-flight voice, arms the 8s-capped hold, no-ops on teachCard/empty). The existing `_HearAgainCta` block (exercise_scaffold.dart:730-739) is removed and its behavior merged into the bar.
**When to use:** Every graded (non-teachCard) surface. Guard with the existing `_hasInstruction` getter.
```dart
// Source: exercise_scaffold.dart (existing seam the bar re-invokes)
void _speakInstructionThenRelease() {
  final speaker = ref.read(ttsCoachSpeakerProvider);
  final sayLine = widget.exercise.prompt.whereType<SayPart>()
      .map((p) => p.line.trim()).firstWhere((l) => l.isNotEmpty, orElse: () => '');
  if (sayLine.isEmpty || _isTeachCard) { unawaited(speaker.stop()); return; }
  setState(() => _instructionHold = true);
  // ... speak with 8s timeout, then release hold ...
}
```
**Anti-pattern avoided:** Do NOT put the persistent instruction into the mascot speech bubble — the bubble is reserved for the coaching voice (D-01), and `_TutorColumn` already hides it when empty.

### Pattern 2: Per-type instruction template resolution (D-02)
**What:** A pure map `exercise.type → (IconData, l10n template string)`. Types observed in `exercises.json`: `traceLetter`, `writeLetter`, `writeWord`, `connectWord`, `completeWord`, `fillBlank`, `transformWord`, `buildSentence`, `teachCard`, `microDrill` — exactly ~10. `exercise.type` is already parsed (`Exercise.type`, exercise.dart:22-24).
**When to use:** In the instruction-bar widget; fall back to a generic "Look and write" for an unknown/null type.

### Pattern 3: Drift PK change via `TableMigration` recreate (D-14)
**What:** SQLite cannot `ALTER TABLE … change primary key`. Drift's `Migrator.alterTable(TableMigration(...))` creates a new table from the *current* (post-edit) Dart schema, copies rows through a `columnTransformer`, and swaps it in. The new non-null `childProfileId` is backfilled from the adopted profile id.
**When to use:** For each of the five tables gaining `childProfileId` in the PK.
```dart
// Source: Drift docs (drift.simonbinder.eu/migrations) — canonical PK-change idiom
if (from < 7) {
  final profileId = await _currentProfileIdOrNull(); // SELECT id FROM child_profiles LIMIT 1
  final backfill = Constant<int>(profileId ?? 0);    // 0 = orphan sentinel if no profile yet
  await m.alterTable(TableMigration(
    letterGraphPosition,
    newColumns: [letterGraphPosition.childProfileId],
    columnTransformer: { letterGraphPosition.childProfileId: backfill },
  ));
  // …repeat for letterMastery, letterExerciseReps, arcStateRows, letterCriterionEvidence…
  // then drop legacy letterReps AFTER folding its readers (D-15):
  // await customStatement('DROP TABLE letter_reps');
}
```
**Verify against Drift's exact API at plan time** — `TableMigration`, `newColumns`, and `columnTransformer` are the documented fields, but confirm the signature for drift 2.31 before writing the plan `[CITED: drift.simonbinder.eu/migrations]`.

### Anti-Patterns to Avoid
- **Rendering a new widget tree per question type.** The whole engine is "one scaffold fed a different config." Adding a bespoke widget per type breaks the invariant and the `presentGraphExercise` epoch-key mount contract.
- **Breaking the `graph:<id>#<epoch>` fresh-mount key.** `presentEpoch` is why retry-in-place and active-arc re-present work (18-12). Any new chrome must run through `initState`, not around it.
- **Reading a Drift stream with a bare `StreamProvider.future`.** Riverpod 3 pauses unlistened streams and the read hangs — use the project's `_bindDriftStream` AsyncNotifier bridge (see Pitfalls).
- **Hand-editing the server `curriculum_data/*.json`.** Always re-derive via `generate.py`.
- **Setting `signedOff:true` on rewritten cards.** Only the mother flips content sign-off; rewrites ship `signedOff:false`.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Change a Drift table's primary key | Manual `CREATE/INSERT SELECT/DROP/RENAME` DDL | `Migrator.alterTable(TableMigration(...))` | Drift handles FK/index/ordering edge cases; SQLite PK-immutability makes hand DDL fragile |
| The replay-instruction voice | New TTS plumbing | Existing `TtsCoachSpeaker` / `_speakInstructionThenRelease()` | Already handles script-splitting, availability, the 8s hold, silent-degrade |
| Fresh-mount per presentation | Manual key juggling | `presentGraphExercise(presentEpoch:)` | The 18-12 mechanism already forces `initState` re-run on every advance |
| Micro-drill selection | New selection logic | `SelectionPolicy` (drill-aware, test-pinned) | `microdrill_selection_test.dart` pins the criterion→drill mapping; just re-add the graph nodes |
| Learned-letters check | Parse Arabic strings for letters | The existing `letters` field per exercise + `introOrder` per letter | 18-02 already computed `letters` deterministically from the expected words |
| Micro-drill spotlight chrome | New overlay | `SpotlightOverlay` (18-10) | Already lights dot/bowl/start zones, `IgnorePointer`-safe |

**Key insight:** Almost every mechanism this phase needs already exists from Phases 15–18 — this phase is mostly *presentation polish + one schema migration*, not new systems. The failure mode to guard against is re-inventing (a new widget per type, new TTS, hand DDL) instead of extending the single scaffold and using Drift's migration API.

## Runtime State Inventory

This is a schema-migration + content-edit phase, so the runtime-state audit is mandatory.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | On-device Drift DB, one file per account (`qalam_account_<sha256(uid)>.db`, `AppDatabase.forAccount`). Six progress tables keyed by `letterId` only: `LetterMastery`, `LetterReps`, `LetterGraphPosition`, `LetterExerciseReps`, `ArcStateRows`, `LetterCriterionEvidence`. | **Data migration** (backfill `childProfileId` from `ChildProfiles.id`, D-16) **+ code edit** (all reads/writes gain the key). Existing single-child rows are adopted into the current profile. |
| **Live service config** | The tutor server (Cloud Run `qalam-tutor`) is **stateless** (COPPA/ADR-017) — no per-child state to migrate. Firestore `child_models/{uid}` stays uid-keyed (D-17, deferred). The nightly compile Cloud Run Job + Scheduler cron are server-side and unaffected by client keying. | **None for the keying migration.** The keying is client-local and must NOT add wire fields (ADR-017). For content: after D-09/D-18 edits, **re-run `generate.py`** to re-derive the server `curriculum_data/*.json` and re-deploy so the server rail matches. |
| **OS-registered state** | None. This is the Flutter client — no Task Scheduler / pm2 / systemd / launchd registration carries `letterId` keys. | None. |
| **Secrets / env vars** | None renamed. `GOOGLE_SERVER_CLIENT_ID`, Firebase config, SOPS keys unchanged. The db filename derives from `sha256(uid)` (unchanged). | None. |
| **Build artifacts / generated files** | `lib/data/app_database.g.dart` (Drift codegen) — stale after the table-class edits. `lib/l10n/app_localizations*.dart` (gitignored) — stale after new ARB keys. Server `curriculum_data/exercises.json` + `curriculum_graph.json` — stale after content edits. | **Regenerate all three:** `dart run build_runner build`; `flutter gen-l10n`; `python -m app.curriculum_data.generate` (from `server/`). |

**The canonical question — after every file is updated, what runtime state still carries the old shape?** Only the **on-device Drift rows** of existing installs (the owner's own device). The v6→v7 migration's backfill (D-16) is precisely the mechanism that adopts them; a fresh install runs `onCreate` (createAll) with the new schema and needs no migration.

## Common Pitfalls

### Pitfall 1: The "new profile resumes at the old cursor" bug is caused by profile-agnostic keys, not multiple rows
**What goes wrong:** `createProfile()` does `delete(childProfiles).go()` then inserts a NEW row (autoincrement id). Only ONE profile row ever exists. But the six progress tables are keyed by `letterId` only, so `LetterGraphPosition('baa')` survives the profile delete/recreate — the "new" profile reads the old child's cursor.
**Why it happens:** Keying by `letterId` with no `childProfileId` dimension. `[VERIFIED: app_database.dart:98-107, 353-371]`
**How to avoid:** After the migration, a new profile gets a new autoincrement `id`; with `(childProfileId, letterId)` keys it reads no rows → fresh start (success criterion 4). Old rows stay keyed to the deleted profile id (orphaned, harmless).
**Warning signs:** A migration test with two profiles must assert profile B reads null position while profile A's rows survive.

### Pitfall 2: SQLite cannot change a primary key in place
**What goes wrong:** `ALTER TABLE … ADD PRIMARY KEY` and PK redefinition are unsupported in SQLite; a naive `addColumn` leaves the PK wrong.
**Why it happens:** SQLite limitation. `[CITED: sqlite.org/lang_altertable]`
**How to avoid:** Use `TableMigration`/`alterTable` (Pattern 3), which recreates the table from the current Dart schema. Test the migration against a **temp FILE database** (not shared in-memory) — the existing v3→v4 test proves this is the only way to exercise the real `onUpgrade` path. `[VERIFIED: test/data/app_database_test.dart:107-176]`

### Pitfall 3: Retiring `LetterReps` (D-15) touches three live reader sites
**What goes wrong:** Dropping `LetterReps` before folding its readers breaks the parent dashboard and the journey ribbon.
**Why it happens:** `LetterReps` (per-letter cleanReps) is read by: `parent_providers.dart` (`allInProgress()` → dashboard "in progress"), `practice_providers.dart` (`getCleanReps`/`setCleanReps`, D-10/D-20), `progression_providers.dart` (`watchCleanReps` → journey progression ribbon). `[VERIFIED: grep across lib/]`
**How to avoid:** Before the drop, fold each reader to a per-letter aggregate over `LetterExerciseReps` (e.g. an essential-floor or max across the letter's exercises). Provide replacement accessors (`allInProgressByExerciseReps()`, `watchLetterCleanReps(letterId)` derived from the per-exercise rows). This is the **highest-risk sub-item for the deadline** — see Open Questions.
**Warning signs:** `progression_providers_test.dart` and parent-dashboard tests reference `setCleanReps`/`allInProgress` — they must be updated in lockstep.

### Pitfall 4: `childProfileId` is async, but per-attempt writes are synchronous-ish
**What goes wrong:** `childProfileProvider` is a `FutureProvider<ChildProfile?>` and is NOT keepAlive (invalidated after onboarding). Reading it per write adds latency/races on the feedback path.
**Why it happens:** The controller's write paths (`_persist`, `markNodeCleared`, `selectNext`, `recordMasteryIfMet`) run inside the scored-feedback moment. `[VERIFIED: profile_providers.dart:46, letter_unit_controller.dart]`
**How to avoid:** Cache `childProfileId` once in `LetterUnitController.start()` (already async — `await ref.read(childProfileProvider.future)`), store it in a field, and pass it to every DB call. On account switch the account-scoped `appDatabaseProvider` rebuilds anyway (new db file), so the cached id is re-read on the fresh controller.
**Warning signs:** A write path that calls `ref.read(childProfileProvider.future)` inline instead of using the cached field.

### Pitfall 5: Riverpod 3 pauses unlistened Drift streams
**What goes wrong:** A bare `StreamProvider.future` read of a Drift `.watch()` hangs because Riverpod 3 pauses streams with no active listener.
**Why it happens:** Documented project gotcha (memory: riverpod3-streamprovider-future-hangs). `[VERIFIED: app_database.dart:426-435 note; project memory]`
**How to avoid:** Use the project's `_bindDriftStream` AsyncNotifier bridge for any new live Drift read (e.g. if the folded per-letter cleanReps becomes a stream for the ribbon). Prefer `Future` one-shot reads where a stream isn't required (the `getPosition` precedent).

### Pitfall 6: The `say` line is filtered out of the header by design — the bar must NOT reintroduce it there
**What goes wrong:** Rendering the `say` line inside `PromptHeader` (undoing `components.js`'s deliberate filter) double-shows it.
**Why it happens:** `PromptHeader._visuals` explicitly excludes `SayPart`; the bar is a *separate* per-type template (D-02), not a say-line transcript. `[VERIFIED: prompt_header.dart:14-16, 63-64]`
**How to avoid:** The instruction bar reads `exercise.type` → template; it never renders `SayPart`. The say line stays the spoken/bubble layer.

### Pitfall 7: Golden tests drift on Arabic fonts locally — do not re-bake to "fix"
**What goes wrong:** New RTL slot-box / audio-card visuals may be tempting to golden-test, but Arabic glyph rendering drifts locally (known issue).
**Why it happens:** Font rendering differs headless vs device (memory: golden-tests-font-drift). `[VERIFIED: project memory + STATE.md]`
**How to avoid:** Prefer behavioral widget tests (finder + semantics + tap) over goldens for the new stimulus surfaces. If a golden is unavoidable, load bundled TTFs via `test/flutter_test_config.dart` and expect local drift.

### Pitfall 8: `baa_signoff_test` asserts "every core baa exercise is signed off" — rewrites will turn it RED
**What goes wrong:** D-09 rewrites edit card content and ship `signedOff:false`. The invariant test `every baa exercise is signed off (except microDrills + traceLetter.final)` then fails. `[VERIFIED: test/curriculum/baa_signoff_test.dart:137-172]`
**How to avoid:** Extend the carve-out list (exactly as microDrills + `baa.traceLetter.final` are already carved out) to include the newly-drafted/rewritten cards, OR gate offending nodes out of the baa unit. This is a deliberate, documented pattern — not a test regression.

## Code Examples

### The six tables and their CURRENT keys (the migration's starting point)
```dart
// Source: lib/data/app_database.dart  [VERIFIED]
LetterMastery          primaryKey => {letterId}              // → add childProfileId
LetterReps             primaryKey => {letterId}              // → RETIRE (D-15), fold readers
LetterGraphPosition    primaryKey => {letterId}              // → add childProfileId
LetterExerciseReps     primaryKey => {letterId, exerciseId}  // → add childProfileId
ArcStateRows           primaryKey => {letterId}              // → add childProfileId
LetterCriterionEvidence  primaryKey => {id autoIncrement}    // has letterId column; carry+filter childProfileId
ChildProfileMirror     primaryKey => {uid}                   // STAYS uid-keyed (D-17)
// schemaVersion => 6  (bump to 7); onUpgrade already guards from<2..from<6 idempotently
```

### The learned-letters lint substrate (D-12) — already present per exercise
```jsonc
// Source: assets/curriculum/exercises.json  [VERIFIED]
{ "id": "baa.connectWord.kitaab", "letters": ["kaaf","taa","alif","baa"], ... }  // VIOLATES (kaaf,taa unlearned)
{ "id": "baa.connectWord.baab",  "letters": ["baa","alif"], ... }                 // OK
// letters.json introOrder: alif=1, baa=2, taa=3, thaa=4  → baa unit learned-set = {alif, baa}
```
Lint (pure Dart test): for each exercise in a unit, assert every `id` in `letters` has `introOrder <= unitIntroOrder`.

### The micro-drill nodes to re-add to `curriculum_graph.json` (D-18)
```jsonc
// competencies[] += { "id":"microDrill", "essential":false, "prerequisites":[] }
// nodes[] += three, mirroring the test fixture in microdrill_selection_test.dart:60-81
{ "exerciseId":"baa.microDrill.dot",   "competency":"microDrill", "tier":null, "minCleanReps":1, "criterion":"dot",        "essential":false }
{ "exerciseId":"baa.microDrill.bowl",  "competency":"microDrill", "tier":null, "minCleanReps":1, "criterion":"shape",      "essential":false }
{ "exerciseId":"baa.microDrill.start", "competency":"microDrill", "tier":null, "minCleanReps":1, "criterion":"strokeOrder","essential":false }
// The exercise configs already exist in exercises.json:2080-2199 (signedOff:false, spotlightZone dot/bowl/start).
// microdrill_selection_test's loadGraph() only adds them IF absent — re-adding to the live graph keeps it green.
```

## Card Rewrite Content Model (resolves the D-14-discretion card→id mapping)

The "№ 10, 15–20" numbering is the owner's card-order shorthand; the enforceable mapping is the `letters` field. Running the intro-order rule (learned = alif+baa) over every baa exercise yields **exactly seven offending cards**:

| # (file order) | Exercise id | `letters` | Unlearned letters | Likely disposition (D-09, mother decides) |
|----|-------------|-----------|-------------------|-------------------------------------------|
| 12 | `baa.connectWord.kitaab` | kaaf,taa,alif,baa | kaaf, taa | Rewrite to an alif+baa word (e.g. باب) OR gate to taa/kaaf unit |
| 14 | `baa.transformWord.dual` | baa,alif,noon | noon (بابان) | Gate to grammar unit (dual needs ن) — grammarTransform is already `essential:false` |
| 15 | `baa.transformWord.plural` | alif,baa,waaw | waaw (أبواب) | Gate to grammar unit (needs و + hamza) |
| 16 | `baa.transformWord.opposite` | saad,ghayn,yaa,raa | saad,ghayn,yaa,raa | Gate — no honest alif+baa "opposite" pair exists |
| 17 | `baa.fillBlank.adjective` | kaaf,baa,yaa,raa | kaaf,yaa,raa (كبير) | Gate to later letter (adjective needs unlearned letters) |
| 18 | `baa.buildSentence.hear` | alif,laam,baa,kaaf,yaa,raa | laam,kaaf,yaa,raa | Gate — sentences fundamentally need more letters |
| 19 | `baa.buildSentence.picture` | alif,laam,baa,kaaf,yaa,raa | laam,kaaf,yaa,raa | Gate — same |

`[VERIFIED: python enumeration over exercises.json letters field]` All other baa cards (traces, writeLetter, writeWord.*, connectWord.baab, completeWord.middle) already use only alif+baa. **Gating** = move the node's `prerequisites`/tier so it activates only in a later letter's unit (mechanically: it should not be reachable in the baa unit's cleared state). **Rewriting** = edit `text`/`expected`/`letters`/`feedback` in `exercises.json` and ship `signedOff:false`. The mother's packet (D-10) should present each of these seven with current content + rendering + a drafted rewrite + a rewrite-vs-gate recommendation.

**Intro-order source note `[ASSUMED → confirm]`:** the lint's ordering source is `letters.json`'s `introOrder` (alif=1, baa=2), which is the app's pedagogical lesson order — NOT the classical ابجد-style list in `docs/curriculum/baa-family-authoring-sketch.md` (which places alif near the end). CONTEXT D-12 explicitly says "baa's unit = alif + baa," which matches `introOrder`. Confirm the planner uses `introOrder` as the canonical rank.

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| Instruction only in spoken `say` line (TTS once) | Persistent instruction bar + tappable replay | This phase (D-01/03) | Fixes the 2026-07-12 UAT "questions don't show what's asked" |
| `writeWord.copy` static dim to opacity 0.18 (`reveal:"thenHide"`) | Child-controlled hide + peek | This phase (D-05) | Preserves recall intent, removes timing ambiguity |
| Small inline `_GapWord`/`_GapLetter` chips + literal `__blank__` | Big RTL slot box at the gap | This phase (D-06) | Gap is legible; `__blank__` marker retired |
| Small teal audio button in header row | Large replayable audio stimulus card | This phase (D-07) | Audio-write questions have a clear stimulus zone |
| Progress keyed by `letterId` only | `(childProfileId, letterId)` keys | This phase (D-14) | Per-child cursors; fresh profile starts clean |
| Two rep counters (`LetterReps` + `LetterExerciseReps`) | One (`LetterExerciseReps`) | This phase (D-15) | Removes the fragile dual-source |
| Micro-drills parked out of the live graph (2026-07-12) | Micro-drills back in the graph | This phase (D-18) | Just-this-part drilling returns behind reworked presentation |

**Deprecated/outdated:**
- The prototype `components.js` "say is speech-only, no persistent instruction" rule — deliberately revised by D-01.
- The literal `__blank__` / `_letter_` in-string markers rendered as small chips — replaced by the D-06 slot box.

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | Proposed requirement IDs (QP-01..QP-10) | Phase Requirements | Cosmetic — behaviors are locked by CONTEXT; only the labels are proposed |
| A2 | Lint ordering source = `letters.json` `introOrder` (alif=1, baa=2), not the classical list in the authoring sketch | Card Rewrite Content Model | Wrong rank set would mis-flag cards; CONTEXT D-12 ("alif + baa") strongly supports introOrder |
| A3 | `LetterCriterionEvidence` carries `childProfileId` as a filtered column (its PK stays the autoincrement surrogate) rather than literally adding it to the PK | Migration | D-13 says "carry childProfileId in its key"; for a surrogate-key table the meaningful action is the column + query filter — confirm intent with owner |
| A4 | Drift 2.31 `TableMigration(newColumns:, columnTransformer:)` signature is as documented | Pattern 3 / Don't Hand-Roll | Verify exact API before writing the migration plan (version-specific) |
| A5 | The 7 enumerated cards are the full offending set; card "№ 10" in the owner's numbering maps into this set | Card Rewrite Content Model | If the owner's numbering includes a card the `letters` field marks clean, reconcile in the review packet |
| A6 | Gating a node = making it unreachable in the baa unit's cleared state via prerequisites/tier (no new schema field) | Card Rewrite / Architecture | If gating needs a new "requires-letters" field, that's a small schema addition to scope |

**Cross-check:** claims tagged `[VERIFIED: ...]` were confirmed by reading the cited file this session. `[ASSUMED]`/`[CITED]` items above need confirmation (A2, A3, A4, A6 especially) before they become locked plan decisions.

## Open Questions (RESOLVED — owner, 2026-07-17; see CONTEXT.md "Planning-time resolutions")

> Resolution index: Q1 → D-15 confirmed (retire now, fold-then-drop). Q2 → D-19 (remove gated
> nodes from the baa graph; file for Phase 20/21). Q3 → D-20 (leave orphans). Q4 → D-21 (the
> lint flag set is the enforceable identity; №↔id reconciled in the mother's review packet).

1. **D-14 vs D-15 reconciliation — key `LetterReps` or retire it?**
   - What we know: D-14 lists `LetterReps` among the six to re-key; D-15 says retire it entirely.
   - What's unclear: whether the deadline permits folding its 3 readers (parent dashboard, practice, progression) into `LetterExerciseReps` aggregates within one plan.
   - Recommendation: Treat as: 5 tables gain the key; `LetterReps` is dropped after folding. **Fallback if the fold is too risky for 2026-07-18:** key `LetterReps` by `childProfileId` too (satisfies D-14/D-16, defers D-15's cleanup) — but this contradicts D-15, so it needs an explicit owner OK. Flag prominently to the planner.

2. **Gate mechanics for the 4–5 gated cards.**
   - What we know: `curriculum_graph.json` uses `prerequisites` + `tier`. grammarTransform/wordBuilding are already `essential:false`.
   - What's unclear: whether "gate to a later letter's unit" means removing the node from the baa graph entirely, or a cross-unit prerequisite the current graph schema doesn't yet express.
   - Recommendation: Simplest deadline-safe path — remove gated nodes from the baa unit's reachable set (or drop them from `curriculum_graph.json`) and file them for the target letter's unit in Phase 20/21. Confirm with the mother in the packet.

3. **Does the migration also clear orphaned rows, or leave them?**
   - What we know: D-16 adopts existing rows into the current profile; orphaned rows (from a deleted profile id) are harmless.
   - Recommendation: Leave orphans (simpler, zero risk). Optionally add a `createProfile` cleanup later; not required this phase.

4. **Card "№ 10" identity.** The owner's numbering (№ 10, 15–20) is shorthand; the enforceable set is the 7 `letters`-violating cards above. Confirm in the review packet that the owner's № list and the lint's flag set agree (A5).

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK (Dart ^3.11.5) | All code | ✓ | per `pubspec.yaml` | — |
| drift + drift_dev | Migration + codegen | ✓ | 2.31.0 | — |
| build_runner | `app_database.g.dart` regen | ✓ (dev dep) | resolved | — |
| flutter gen-l10n | Instruction ARB keys | ✓ | SDK | English defaults in `ExerciseScaffoldStrings` keep tests l10n-free |
| flutter_tts | Replay-tap voice | ✓ | 4.2.5 | `NoopTtsCoachSpeaker` in tests; silent-degrade on device |
| Python + `generate.py` (server) | Server curriculum re-derive | ✓ (repo) | — | Only needed for the server rail; client works from bundled assets offline |
| Physical tablet / iPad | Device UAT of the new presentation | (owner-side) | — | Widget tests cover logic; device retest is the human gate |

**Missing dependencies with no fallback:** none — this is a code/content/schema phase over existing tooling.
**Missing dependencies with fallback:** l10n regen and server re-derive are build steps, both scriptable; TTS degrades silently.

## Validation Architecture

nyquist_validation is enabled (`workflow.nyquist_validation: true`). `[VERIFIED: .planning/config.json]`

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Dart) + Python `pytest` for any server re-derive check |
| Config file | none for Flutter (convention); server has `pytest` markers |
| Quick run command | `flutter test test/features/letter_unit/ test/data/app_database_test.dart test/curriculum/ test/tutor/microdrill_selection_test.dart` |
| Full suite command | `flutter test` (client) + `cd server && make eval` only if server content re-derived |

### Phase Requirements → Test Map
| Req | Behavior | Test type | Automated command | File exists? |
|-----|----------|-----------|-------------------|--------------|
| QP-01/02 | Instruction bar renders per type + tap replays (live path via `presentGraphExercise`) | widget | `flutter test test/features/letter_unit/` | ❌ Wave 0 — new `exercise_scaffold_instruction_bar_test.dart` (MUST mount via the presenter, not a bare scaffold — Phase-15 lesson) |
| QP-03 | `writeWord.copy` shows word → hides on action → peek restores | widget | `flutter test test/features/letter_unit/` | ❌ Wave 0 |
| QP-04 | `completeWord`/`fillBlank` render a big RTL slot box; no `__blank__` text leaks | widget | `flutter test test/features/letter_unit/` | ❌ Wave 0 (extend a prompt_header test) |
| QP-05 | Audio stimulus renders as a large card, auto-plays once, tap replays | widget | `flutter test test/features/letter_unit/` | ❌ Wave 0 |
| QP-06 | Recall write types render no letter model | widget/data | assert no model part on `writeLetter`/`writeWord` recall configs | ❌ Wave 0 |
| QP-07 | Learned-letters lint: every baa exercise's `letters` ⊆ {alif,baa} unless gated | data/lint | `flutter test test/curriculum/` | ❌ Wave 0 — new `learned_letters_lint_test.dart` |
| QP-08 | `curriculum_graph.json` contains the 3 microDrill nodes; selection stays green | data | `flutter test test/tutor/microdrill_selection_test.dart` | ✅ exists (stays green after re-add) |
| QP-09 | v6→v7 migration backfills `childProfileId`; profile A rows survive, profile B reads clean | migration | `flutter test test/data/app_database_test.dart` | ✅ exists (extend with a v6→v7 + two-profile case, temp-file DB) |
| QP-09 | `baa_signoff` invariant still holds with rewritten cards carved out | data | `flutter test test/curriculum/baa_signoff_test.dart` | ✅ exists (extend carve-out list) |
| QP-10 | ADR-018 file present | doc | manual / file-exists check | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the quick run command above (letter_unit widgets + app_database + curriculum + microdrill).
- **Per wave merge:** `flutter test` (full client suite) — watch the known pre-existing failures (alif_reference, mastery/glyph goldens per STATE.md; do not "fix" via re-bake).
- **Phase gate:** full client suite green (minus documented pre-existing goldens) before `/gsd-verify-work`; device UAT of the new presentation is the human gate.

### Wave 0 Gaps
- [ ] `test/features/letter_unit/exercise_scaffold_instruction_bar_test.dart` — QP-01/02, mounted through `presentGraphExercise` (live path)
- [ ] `test/features/letter_unit/copy_stimulus_test.dart` — QP-03 hide+peek state
- [ ] `test/features/letter_unit/prompt_header_slot_audio_test.dart` — QP-04/05 (extend the existing prompt_header coverage)
- [ ] `test/curriculum/learned_letters_lint_test.dart` — QP-07 (`letters` ⊆ cumulative introOrder set)
- [ ] Extend `test/data/app_database_test.dart` — v6→v7 migration + two-profile isolation (temp-file DB per the v3→v4 precedent)
- [ ] Extend `test/curriculum/baa_signoff_test.dart` — carve out rewritten/gated cards
- [ ] Update `test/providers/progression_providers_test.dart` + parent-dashboard tests — for the `LetterReps` fold (D-15)

## Security Domain

`security_enforcement: true`, ASVS level 1. `[VERIFIED: .planning/config.json]` This phase is client-local Flutter + on-device SQLite; it adds no network surface and no new wire fields (ADR-017 boundary — the keying migration must stay client-local).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard control (here) |
|---------------|---------|-------------------------|
| V2 Authentication | no | No auth change; account/db-file mapping unchanged (`accountDatabaseId`) |
| V3 Session Management | no | No sessions touched |
| V4 Access Control | yes (minimal) | Per-account DB isolation already via `sha256(uid)` filename; per-child keying strengthens in-file isolation |
| V5 Input Validation | yes | Curriculum content is load-time validated (`validateLetter`/`validateReferenceStrokes`); the learned-letters lint is an additional static gate |
| V6 Cryptography | no new | `sha256(uid)` db naming unchanged; never hand-roll — uses `package:crypto` |
| V8/Privacy (child data) | yes | The six tables persist ONLY ids/counts/timestamps — never stroke points/PII (documented per table). The migration must preserve this: `childProfileId` is a local integer id, non-PII. No new field crosses the network. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Cross-profile data leak (the bug this phase fixes) | Information disclosure | `(childProfileId, letterId)` keys + fresh-profile clean read (D-14/16) |
| Migration data loss | Denial of service (progress loss) | `TableMigration` recreate + backfill + a temp-file migration test proving rows survive (D-16) |
| PII reaching the wire via the keying change | Information disclosure | ADR-017 boundary: keying is client-local; `childProfileId` is a local int, never added to `TutorFacts`/the coach payload — assert with the existing non-PII payload guard tests |
| Content demanding unlearned letters (pedagogical, not security) | — | The D-12 lint (out-of-band correctness gate) |

## Sources

### Primary (HIGH confidence — direct source reads this session)
- `lib/features/letter_unit/widgets/exercise_scaffold.dart` (1133 lines) — the single render path; `_speakInstructionThenRelease`, `_HearAgainCta`, `_hasInstruction`, `_mainColumn`, `_isAgentPath`
- `lib/features/letter_unit/widgets/prompt_header.dart` (563 lines) — `say`-filter, `_AudioPart`, `_TextPart` + `_GapWord`/`_GapLetter`, responsive image path, `reveal:"thenHide"` dim
- `lib/features/letter_unit/exercise_presenter.dart` — `presentGraphExercise` + `presentEpoch` fresh-mount key
- `lib/features/letter_unit/letter_unit_controller.dart` (613 lines) — the 6-table read/write hub; `start`, `beginSelection`, `selectNext`, `markNodeCleared`, `recordMasteryIfMet`, `_persist`
- `lib/data/app_database.dart` (711 lines) — schema v6, all nine tables + PKs, migration `onUpgrade`, `forAccount`/`accountDatabaseId`
- `lib/data/graph_position_repository.dart`, `arc_state_repository.dart`, `drift_progress_repository.dart`, `evidence_repository.dart`, `child_profile_repository.dart`, `lib/providers/profile_providers.dart` — the repository/provider layer to thread `childProfileId`
- `lib/models/exercise.dart` — `Exercise`/`PromptPart`/`TextPart`/`Surface`/`Gap` config shapes; `exercise.type`
- `assets/curriculum/exercises.json` (2201 lines) + `curriculum_graph.json` (181 lines) — card content, `letters` field, microDrill configs (2080-2199), the parked microDrill graph note
- `assets/curriculum/letters.json` — `introOrder` (alif=1, baa=2, taa=3, thaa=4)
- `test/tutor/microdrill_selection_test.dart` — the pinned selection contract + fixture-augment pattern
- `test/data/app_database_test.dart` — the temp-file migration test pattern (v2→v3, v3→v4)
- `test/curriculum/baa_signoff_test.dart` — the content sign-off invariant (carve-out pattern)
- `pubspec.yaml` / `pubspec.lock` — drift 2.31.0, sqlite3 2.9.4, flutter_tts 4.2.5, riverpod 3.3.1
- `.planning/phases/19-.../19-CONTEXT.md` + `19-DISCUSSION-LOG.md` — locked decisions
- `.planning/todos/pending/2026-07-12-question-presentation-overhaul.md` — the source UAT findings
- `.planning/config.json`, `.planning/STATE.md`, `.planning/REQUIREMENTS.md` — workflow flags + accumulated decisions

### Secondary (MEDIUM — official docs, verify API at plan time)
- Drift migrations guide (`TableMigration`/`alterTable` for PK changes) — `[CITED: drift.simonbinder.eu/migrations]` (confirm the 2.31 signature)
- SQLite ALTER TABLE limitations — `[CITED: sqlite.org/lang_altertable.html]`

### Tertiary (LOW — none)
- No unverified web claims were relied upon; every load-bearing fact came from the repo.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all deps present and version-locked; nothing new to install
- Architecture (presentation): HIGH — read the full scaffold + header; the say-line gap is precisely located
- Migration: HIGH on the current schema/keys and the temp-file test pattern; MEDIUM on the exact Drift 2.31 `TableMigration` API (verify before writing the plan) and on the D-14/D-15 reconciliation (owner call)
- Content/lint: HIGH — the `letters` field + `introOrder` substrate exists; the 7 offending cards enumerated deterministically
- Pitfalls: HIGH — each is grounded in a specific file/line or a recorded project memory

**Research date:** 2026-07-17
**Valid until:** ~2026-08-16 for the code/schema findings (stable repo); the card content set is valid until the mother's rewrite session lands (then re-enumerate the lint over the edited `exercises.json`).
