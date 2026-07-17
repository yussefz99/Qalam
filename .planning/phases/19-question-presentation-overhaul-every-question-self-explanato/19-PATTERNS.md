# Phase 19: Question presentation overhaul — Pattern Map

**Mapped:** 2026-07-17
**Files analyzed:** 26 (10 modified source + 3 new source/doc + 2 content assets + 1 l10n + 1 tooling re-run + 9 test files new/extended)
**Analogs found:** 24 / 26 (2 have no direct analog — see § No Analog Found)

> This phase is almost entirely *extend-in-place*: every capability already has a live
> seam in this repo. The analog for most modified files is the **file itself** (an
> existing block to copy the shape of). New files (`copy_stimulus.dart`, `ADR-018`,
> the Wave-0 tests) copy patterns from named siblings. Concrete line ranges below.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|-------------------|------|-----------|----------------|-------|
| `lib/features/letter_unit/widgets/exercise_scaffold.dart` | component (widget) | request-response | *itself* — `_HearAgainCta` + `_mainColumn` + `_speakInstructionThenRelease` | exact |
| `lib/features/letter_unit/widgets/prompt_header.dart` | component (widget) | transform / render | *itself* — `_AudioPart` / `_TextPart` / `_GapWord` / responsive `_ImagePart` | exact |
| `lib/features/letter_unit/widgets/copy_stimulus.dart` **(NEW)** | component (StatefulWidget) | event-driven (local UI state) | `_TextPart` (card shell) + `_ExerciseScaffoldState` (setState hold) | role-match |
| `lib/data/app_database.dart` | model (Drift DB) | CRUD + migration | *itself* — version-guarded `onUpgrade` blocks (v3→v4, v5→v6) | exact |
| `lib/data/graph_position_repository.dart` | repository | CRUD | *itself* + `drift_progress_repository.dart` | exact |
| `lib/data/arc_state_repository.dart` | repository | CRUD | `graph_position_repository.dart` | exact |
| `lib/data/drift_progress_repository.dart` | repository | CRUD | *itself* (retired/folded for `LetterReps`) | exact |
| `lib/data/evidence_repository.dart` | repository | CRUD (queue) | *itself* + `arc_state_repository.dart` | exact |
| `lib/features/letter_unit/letter_unit_controller.dart` | controller | CRUD / orchestration | *itself* — `start()` / `_persist()` write hub | exact |
| `lib/providers/parent_providers.dart` | provider | request-response (aggregate read) | `app_database.dart` `exerciseCleanRepsFor` | role-match |
| `lib/providers/progression_providers.dart` | provider | streaming / pub-sub | *itself* — `_bindDriftStream` + `_CleanRepsNotifier` | exact |
| `lib/providers/practice_providers.dart` | provider (AsyncNotifier) | CRUD | *itself* — `_persistCleanReps` / `_loadLetter` | exact |
| `assets/curriculum/exercises.json` | config (content) | static | *itself* — `baa.microDrill.dot` block + `letters` field | exact |
| `assets/curriculum/curriculum_graph.json` | config (graph) | static | *itself* — competency + node blocks; `_meta.microDrills` note | exact |
| `docs/architecture/ADR-018-child-identity-keying.md` **(NEW)** | doc | — | `ADR-017-scorer-owns-verdict-derived-facts.md` | exact |
| `lib/l10n/app_en.arb` | config (l10n) | static | *itself* — existing `@key` entries + `ExerciseScaffoldStrings` defaults | exact |
| `server/app/curriculum_data/generate.py` **(re-run, not edit)** | tooling | batch (re-derive) | *itself* — `regenerate()` | exact |
| `test/features/letter_unit/exercise_scaffold_instruction_bar_test.dart` **(NEW)** | test (live-path widget) | request-response | `agent_pick_live_path_test.dart` | exact |
| `test/features/letter_unit/copy_stimulus_test.dart` **(NEW)** | test (widget) | event-driven | `prompt_header_test.dart` | role-match |
| `test/features/letter_unit/prompt_header_slot_audio_test.dart` **(NEW/extend)** | test (widget) | render | `prompt_header_test.dart` | exact |
| `test/curriculum/learned_letters_lint_test.dart` **(NEW)** | test (data/lint) | batch | `baa_signoff_test.dart` (raw-JSON load + assert) | exact |
| `test/data/app_database_test.dart` **(extend)** | test (migration) | migration | *itself* — v3→v4 temp-file test | exact |
| `test/curriculum/baa_signoff_test.dart` **(extend)** | test (data) | batch | *itself* — carve-out block | exact |
| `test/providers/progression_providers_test.dart` **(update)** | test (provider) | streaming | *itself* (LetterReps fold) | exact |
| `test/tutor/microdrill_selection_test.dart` **(stays green)** | test (data) | batch | *itself* — `loadGraph()` fixture-augment | exact |

---

## Pattern Assignments

### `lib/features/letter_unit/widgets/exercise_scaffold.dart` (component, request-response)

**Analog:** itself. The instruction bar is a NEW strip in `_mainColumn` that reuses the
existing say-line seam and REPLACES the `_HearAgainCta` block. Do NOT invent new TTS
plumbing (RESEARCH "Don't Hand-Roll").

**Say-line replay seam to re-invoke verbatim** (lines 276-299): tap handler for the bar.
```dart
void _speakInstructionThenRelease() {
  final speaker = ref.read(ttsCoachSpeakerProvider);
  final sayLine = widget.exercise.prompt.whereType<SayPart>()
      .map((p) => p.line.trim()).firstWhere((l) => l.isNotEmpty, orElse: () => '');
  if (sayLine.isEmpty || _isTeachCard) { unawaited(speaker.stop()); return; }
  setState(() => _instructionHold = true);
  // ... speak with 8s timeout, then release the hold in finally ...
}
```

**Guard getter to gate the bar** (lines 234-238) — reuse `_hasInstruction`; it already
excludes `teachCard` + empty say-lines (matches UI-SPEC "hidden on teachCard"):
```dart
bool get _hasInstruction =>
    !_isTeachCard &&
    widget.exercise.prompt.whereType<SayPart>().any((p) => p.line.trim().isNotEmpty);
```

**Landing site + the `_HearAgainCta` block to DELETE** (lines 690-739): the bar goes
between the ribbon `Row` (696-715) and `PromptHeader` (717-721); the current pill block
(730-739) is removed and its `onTap: _speakInstructionThenRelease` moves onto the bar.
```dart
// _mainColumn: ribbon Row (696-715) → PromptHeader (717-721) → [DELETE 730-739] →
if (_hasInstruction) ...[
  const SizedBox(height: 10),
  Align(alignment: AlignmentDirectional.centerStart,
    child: _HearAgainCta(label: s.hearAgain, onTap: _speakInstructionThenRelease)),
],
```

**Widget-shape to copy for the new bar** (`_HearAgainCta`, lines 1089-1133) — the same
`Semantics(button:true) → Material → InkWell → Container(BoxDecoration + Row[Icon,Text])`
skeleton; UI-SPEC upsizes it to min-height 64, `--teal-tint` fill, `--aqua-edge` 1.5px
border, leading per-type icon + trailing speaker glyph.

**Per-type string source** (`ExerciseScaffoldStrings`, lines 52-83): the class already
carries English defaults (`hearAgain = 'Hear again'`, line 66) with call-site l10n — add
the ~10 D-02 template strings here so widget tests stay l10n-independent (RESEARCH
"Alternatives Considered"). Content map (`exercise.type → icon + text`) is in UI-SPEC
§Copywriting.

**Anti-patterns:** (a) do NOT render the persistent instruction in the mascot speech
bubble (reserved for coaching voice, D-01); (b) do NOT keep two replay controls — the
Phase-07 double-Hear-button device bug is why `_HearAgainCta` folds into the bar (D-03).

---

### `lib/features/letter_unit/widgets/prompt_header.dart` (component, transform/render)

**Analog:** itself. Three part-renderers change; all are private leaf widgets in this file.

**The say-filter to PRESERVE** (lines 63-64) — Pitfall 6: the bar must NOT reintroduce
`SayPart` here.
```dart
List<PromptPart> get _visuals => parts.where((p) => p is! SayPart).toList(growable: false);
```

**Audio card (D-07)** — hero variant of `_AudioPart` (lines 140-188). The teal-button
skeleton (`Semantics(button) → Material(inkTeal) → InkWell → Container` with the
`BoxShadow(deepInk, Offset(0,4))` sticker shadow, lines 152-186) is the exact shape;
UI-SPEC upsizes to min-height 96 (`--target-large`), 40px speaker icon, radius 28,
"Listen" label. Auto-play once on mount mirrors the scaffold's initState auto-speak
(exercise_scaffold.dart:272); silent-degrade to the TTS say-line seam when a clip is
absent (mirror the `_ImagePart` errorBuilder posture, lines 310-321).

**Slot box (D-06)** — enlarge `_GapWord` (lines 426-444) / `_GapLetter` (447-461). Keep
the teal-ring `Container(BoxDecoration(border: inkTeal width 2))` rendering (Flutter draws
a solid ring, not CSS-dashed — note at line 438); UI-SPEC raises height to ~64 to match the
40px glyph line and adds the gentle pulse. The `__blank__`/`_letter_` marker split stays in
`_TextPart._tokens()` (lines 390-412) — the marker string still never leaks to screen.
```dart
final pattern = RegExp(r'(__blank__|_letter_)');   // line 393 — keep the split
widgets.add(m.group(0) == '__blank__' ? const _GapWord() : const _GapLetter());
```

**Copy hide+peek (D-05)** — the current static dim (lines 359, 372-373) is REPLACED by the
new `copy_stimulus.dart` widget:
```dart
final bool dim = part.reveal == 'thenHide';   // line 359 — static opacity 0.18 today
child: Opacity(opacity: dim ? 0.18 : 1.0, ...) // line 372 — becomes child-controlled state
```
The Arabic card shell to reuse inside the new widget = `_TextPart`'s `Container` (lines
361-371: `surfaceRaised`, radius 16, `aquaEdge` border, the `Color(0x1A0E5B5F)` shadow) +
`_arabic()` glyph style (lines 414-422: 40px `arBody`, w600, `deepInk`).

---

### `lib/features/letter_unit/widgets/copy_stimulus.dart` (NEW — StatefulWidget, event-driven)

**Analog (shell):** `_TextPart` (prompt_header.dart:351-423) for the card + Arabic glyph.
**Analog (state):** `_ExerciseScaffoldState` (exercise_scaffold.dart:204-311) for the
`setState`-driven reveal/hide toggle — the only StatefulWidget pattern in this feature
(all `prompt_header.dart` parts are Stateless, so there is no in-file precedent for local
UI state; the scaffold's `_instructionHold` toggle at 226/286/296 is the closest analog).
Three states per UI-SPEC §4: `revealed` / `hidden` / `peeking`; "I'm Ready" hides,
first-stroke also hides (needs a hook from the WriteSurface stroke start), "Peek"/"Hide"
toggle. Nothing on a timer (D-05).

---

### `lib/data/app_database.dart` (model, CRUD + migration)

**Analog:** itself. Two edits: (1) add `childProfileId` to five table PKs; (2) a v6→v7
`onUpgrade` block that recreates + backfills, and drops `LetterReps`.

**Current PKs to change** (verified):
```
LetterMastery         {letterId}              (39-46)   → {childProfileId, letterId}
LetterReps            {letterId}              (73-80)   → RETIRE (D-15); fold 3 readers first
LetterGraphPosition   {letterId}              (98-107)  → {childProfileId, letterId}
LetterExerciseReps    {letterId, exerciseId}  (122-130) → {childProfileId, letterId, exerciseId}
ArcStateRows          {letterId}              (161-174) → {childProfileId, letterId}
LetterCriterionEvidence {id autoInc}          (143-150) → keep surrogate PK; add childProfileId column + filter (A3)
ChildProfileMirror    {uid}                   (189-198) → UNCHANGED (D-17)
```

**Migration precedent to copy** (the version-guarded `onUpgrade`, lines 239-277). Every
block is `if (from < N) { ... }` and idempotent. The v3→v4 block (245-255) is the one that
does a data rewrite (`customStatement UPDATE ...`) — the closest precedent for the v7
backfill. Bump `schemaVersion` 6 → 7 (line 236). The new block:
```dart
if (from < 7) {
  // read the single adopted profile id (D-16), backfill via Constant<int>(...),
  // recreate each PK-changed table with Migrator.alterTable(TableMigration(...)),
  // then DROP letter_reps AFTER its readers are folded (D-15).
}
```
> **Verify at plan time (A4):** confirm the drift 2.31 `TableMigration(newColumns:,
> columnTransformer:)` signature before writing the plan — RESEARCH Pattern 3 cites the
> API but flags version-specificity.

**Accessors that gain a `childProfileId` param** (all keyed reads/writes): `getPosition`/
`setPosition` (439-460), `getExerciseCleanReps`/`setExerciseCleanReps`/`incrementExercise
CleanReps`/`exerciseCleanRepsFor` (485-522), `getArcStateRow`/`setArcStateRow` (573-594),
`recordMastery`/`isMastered`/`cleanRepsFor` (311-332), `appendEvidence`/`unsyncedEvidence`
(534-555). **RETIRED** (fold, then delete): `setCleanReps`/`getCleanReps`/`watchCleanReps`
(392-423) and `allInProgress` (644-646) — all read `letterReps`.

**Account-isolation seam to preserve** (lines 224-231, 679-696): the db file is already
per-account (`sha256(uid)`); `childProfileId` is the *in-file* dimension. The
`appDatabaseProvider` rebuilds on account switch — so a cached childProfileId is re-read on
the fresh controller (Pitfall 4). Do NOT touch this seam.

---

### `lib/data/graph_position_repository.dart` (repository, CRUD)  ·  representative of the repo layer

**Analog:** itself + `drift_progress_repository.dart`. Thin delegation — thread
`childProfileId` through the value type + both methods.
```dart
// getPosition/setPosition delegate straight to the DB (lines 71-89):
Future<GraphPosition?> getPosition(String letterId) async { final row = await _db.getPosition(letterId); ... }
Future<void> setPosition(GraphPosition p) => _db.setPosition(letterId: p.letterId, ...);
// provider is keepAlive over appDatabaseProvider (103-105) — pattern unchanged.
```
Add `childProfileId` to the `GraphPosition` value type (30-50) and to both DB calls. Apply
the SAME edit shape to `arc_state_repository.dart` (getArc/setArc, 32-51), `evidence_
repository.dart` (its rows carry `letterId`; add the column, 48-81), and
`drift_progress_repository.dart` (whichever methods survive the LetterReps retirement).

---

### `lib/features/letter_unit/letter_unit_controller.dart` (controller, CRUD/orchestration)

**Analog:** itself — the 6-table read/write hub. **Cache `childProfileId` once in `start()`
and pass it to every DB call** (Pitfall 4: never `ref.read(childProfileProvider.future)`
inline on the scored-feedback path).

**Where to cache** (`start()`, lines 205-262) — it is already async and already does a
`getPosition` read at line 214; add `final id = await ref.read(childProfileProvider.future)`
near the top and store it in a field.

**Write sites that must pass the cached id:** `_persist()` (577-591, `setPosition`);
`markNodeCleared` (450-488, `getExerciseCleanReps` at 465); `recordMasteryIfMet` (504-541,
`exerciseCleanRepsFor` at 510 + `recordMastery` at 530); `_persistArc` (433-435, `setArc`);
`_loadSelectionContext` (268-282, `getArc` at 270). Each currently keys on `_letterId` only.

---

### `lib/providers/progression_providers.dart` (provider, streaming/pub-sub)

**Analog:** itself. `watchCleanReps` (line 95) is one of the 3 LetterReps readers (D-15).
Fold it to a per-letter aggregate over `LetterExerciseReps`. **Use the `_bindDriftStream`
bridge — never a bare `StreamProvider.future`** (Pitfall 5).
```dart
// The bridge to reuse verbatim (lines 43-64) + the family notifier shape (86-98):
Future<int> build() => _bindDriftStream(
      ref, ref.watch(progressRepositoryProvider).watchCleanReps(letterId),
      (value) => state = value);
```
New reader = `watchLetterCleanReps(letterId)` derived from the per-exercise rows (e.g. an
essential-floor or max across the letter's `LetterExerciseReps`). `test/providers/
progression_providers_test.dart` must update in lockstep.

---

### `lib/providers/parent_providers.dart` (provider, aggregate read)  &  `lib/providers/practice_providers.dart` (provider, CRUD)

**Analogs:** `parent_providers.dart` line 119 (`allInProgress()`) and `practice_providers.dart`
lines 164/199-200 (`getCleanReps`/`setCleanReps`) — the other two LetterReps readers.
Fold each to a `LetterExerciseReps` aggregate (RESEARCH suggests `allInProgressBy
ExerciseReps()`). The `parentProgressProvider` assembly (113-135) stays hand-written
(Pitfall 3 — it reads Drift row types). `practice_providers` write-through (`_persistClean
Reps`, 194-204) becomes a per-exercise write or is retired with the counter.

---

### `assets/curriculum/exercises.json` (config, static content)

**Analog:** itself. Card shape to copy for rewrites = any signed baa card; the `letters`
field is the lint substrate (present on every exercise, e.g. `"letters": [...]` at
lines 42, 84, 126...). Rewrites edit `text`/`expected`/`letters`/`feedback` and ship
`signedOff: false` (verified on the microDrill block, exercises.json:2114). The 7 offending
cards all exist and are graph-reachable (`baa.connectWord.kitaab`, `baa.transformWord.
{dual,plural,opposite}`, `baa.fillBlank.adjective`, `baa.buildSentence.{hear,picture}`).
The microDrill exercise configs already exist (`baa.microDrill.dot` at 2080-2123, with
`criteria:["dot"]` + `spotlightZone:"dot"`) — D-18 only re-adds the *graph nodes*, not the
configs.

---

### `assets/curriculum/curriculum_graph.json` (config, graph)

**Analog:** itself. Node shape (lines 60-64): `{exerciseId, competency, tier, minCleanReps}`.
Competency shape (lines 37-58): `{id, essential, prerequisites[]}`. Two edits:
- **D-18 re-add** the `microDrill` competency (`{"id":"microDrill","essential":false,
  "prerequisites":[]}`) + the 3 drill nodes (mirror the fixture in
  `microdrill_selection_test.dart:60-81`). The `_meta.microDrills` + `owner_amendment_
  2026_07_12` notes (graph head) document that they were parked — update them.
- **D-19 remove** the offending nodes from the reachable set (drop from `nodes[]`); file
  for Phase 20/21. No cross-unit-prerequisite schema field (A6 confirmed by D-19).

**After ANY edit, re-run `generate.py` — never hand-edit the server copy** (see below).

---

### `docs/architecture/ADR-018-child-identity-keying.md` (NEW — doc)

**Analog:** `ADR-017-scorer-owns-verdict-derived-facts.md` (lines 1-22). Copy the header
block structure: `# ADR-NNN: <one-line rule>` → `**Status:** ACCEPTED (owner, <date>)` →
`**Supersedes/Amends/Affects:**` bold refs → `---` → `## Context` → `## Decision`. Record
the D-13 rule (account uid = db file; childProfileId = child within it; every progress
table carries childProfileId in its key) and the D-17 deferral (cloud model stays
uid-keyed).

---

### `lib/l10n/app_en.arb` (config, l10n)

**Analog:** itself — existing `@key` metadata entries (lines 2-28). Add the ~10 D-02
instruction template keys; mirror defaults into `ExerciseScaffoldStrings`
(exercise_scaffold.dart:52-83). Run `flutter gen-l10n` after (generated files are
gitignored — memory: l10n-generated-gitignored).

---

### `server/app/curriculum_data/generate.py` (tooling — RE-RUN, do not edit)

**Analog:** itself — `regenerate()` (line 38) reads the two client assets and writes the
server `curriculum_data/*.json` filtered to `baa.*`. Run `cd server && uv run python -m
app.curriculum_data.generate` after the D-09/D-18/D-19 content edits so the stateless
server rail matches. Never hand-edit the server copy.

---

## Shared Patterns

### Never-throw / silent-degrade on local I/O
**Source:** `letter_unit_controller.dart` `_persist` (577-591), `start` try/catch (213-217);
`prompt_header.dart` `_ImagePart` errorBuilder (310-321).
**Apply to:** every new DB call (migration reads, childProfileId reads) and the audio card's
missing-clip path — a failed local read/write degrades to a clean default, never crashes the
loop (UI-SPEC "silent-degrade, no error copy").

### Cache-the-async-id, never read it on the hot path
**Source:** `letter_unit_controller.start()` already awaits `getPosition` (214); `childProfile
Provider` is a non-keepAlive `FutureProvider` (profile_providers.dart:46-48).
**Apply to:** all six-table write paths — resolve `childProfileId` once at `start()` (Pitfall 4).

### Drift stream reads go through `_bindDriftStream`, not `StreamProvider.future`
**Source:** `progression_providers.dart:43-64`.
**Apply to:** any new live Drift read introduced by the LetterReps fold (Pitfall 5;
memory: riverpod3-streamprovider-future-hangs).

### Fresh-mount-per-presentation key
**Source:** `exercise_presenter.dart` `presentGraphExercise` + `presentEpoch` (48-98, key at 71).
**Apply to:** all new presentation chrome (instruction bar, audio card, copy widget) — it
mounts through `presentGraphExercise`, so new UI runs in `initState`, never around it
(RESEARCH anti-pattern; Phase-15 dead-wire lesson).

### Design tokens only — no hard-coded hex/px/font
**Source:** every widget here pulls `QalamTokens.*` / `QalamTextStyles.*`
(prompt_header.dart:153, 365, 417).
**Apply to:** all new surfaces; gold is rewards-only and must NOT appear (anti-gamification,
CLAUDE.md Decided + UI-SPEC §Color).

### Provisional content ships `signedOff:false`; only the mother flips it
**Source:** exercises.json microDrill block (2114); `baa_signoff_test.dart` carve-out (137-172).
**Apply to:** all D-09 card rewrites and the re-added drill nodes (15-07/17-10 pattern).

### Migration tests need a temp-FILE db (not shared in-memory)
**Source:** `test/data/app_database_test.dart` v3→v4 test (118-185): temp dir (122-124),
seed with current schema, `DROP TABLE` + `PRAGMA user_version = N` to rewind (137-139),
fresh `NativeDatabase` executor per "restart" (145-172), idempotence restart (174-185).
**Apply to:** the v6→v7 + two-profile isolation test (Pitfall 2). A shared in-memory
executor cannot exercise `onUpgrade` — the delegate stays open across instances.

### Live-path widget tests mount the real scaffold via the presenter/controller
**Source:** `agent_pick_live_path_test.dart` `_pumpStarted` (150-192): `ProviderScope`
overrides (`appDatabaseProvider`, `graphPositionRepositoryProvider`, `curriculumGraph
Provider`, `childModelProvider`, `ttsCoachSpeakerProvider` = `NoopTtsCoachSpeaker`)
160-171; mount `ExerciseScaffold` 174-178; drive `controller.start(...)` 187-189; the
epoch-tolerant `_graphNode` finder 264-268.
**Apply to:** `exercise_scaffold_instruction_bar_test.dart` (QP-01/02) — MANDATORY to mount
through this path, never a bare scaffold (Phase-15 dead-wire lesson; memory:
phase15-dynamic-selection-was-dead-code).

### Content lint = load raw JSON + assert (no runtime, no model parse)
**Source:** `baa_signoff_test.dart` `_loadExercisesRaw()` + the carve-out filter (139-159).
**Apply to:** `learned_letters_lint_test.dart` (QP-07) — read `exercises.json` +
`letters.json` raw, assert every baa exercise's `letters ⊆ {alif, baa}` by `introOrder`
(A2: `introOrder` is the canonical rank, alif=1 baa=2), with the same carve-out shape for
gated cards.

### Micro-drill graph re-add keeps `microdrill_selection_test` green
**Source:** `microdrill_selection_test.dart` `loadGraph()` (50-83) — the fixture ONLY adds
the drill nodes `if absent`. Re-adding them to the live asset keeps the test green with zero
edits.

---

## No Analog Found

| File | Role | Data Flow | Reason / fallback |
|------|------|-----------|-------------------|
| `lib/features/letter_unit/widgets/copy_stimulus.dart` | component (StatefulWidget) | event-driven | No StatefulWidget exists in `prompt_header.dart` (all parts are Stateless). The card *shell* copies `_TextPart` (prompt_header.dart:351-423) and the *setState toggle* copies `_ExerciseScaffoldState._instructionHold` (exercise_scaffold.dart:226/286/296), but there is no single widget that is both a prompt-part AND stateful — this is the one genuinely new widget shape. |
| Audio-card **auto-play-once + placeholder** behavior (inside `prompt_header.dart` `_AudioPart` hero) | component | streaming (playback) | The card *visual* copies `_AudioPart` (140-188) exactly, but no existing prompt part **auto-plays on mount**; the closest auto-fire precedent is the scaffold's `initState` auto-speak (exercise_scaffold.dart:254-273). Wire the mount-time play from that pattern + the existing audio seam (`onAudioTap` / TTS fallback). |

---

## Metadata

**Analog search scope:** `lib/features/letter_unit/{widgets,}/`, `lib/data/`,
`lib/providers/`, `assets/curriculum/`, `docs/architecture/`, `server/app/curriculum_data/`,
`test/{data,curriculum,tutor,features/letter_unit}/`.
**Files scanned (read this session):** 20 source/test/asset files + 3 phase docs.
**Pattern extraction date:** 2026-07-17
**Confidence:** HIGH — every line reference confirmed by direct read this session.
