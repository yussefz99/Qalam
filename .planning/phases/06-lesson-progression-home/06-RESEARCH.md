# Phase 6: Lesson Progression & Home - Research

**Researched:** 2026-06-11
**Domain:** Internal codebase — Flutter/Riverpod/drift/go_router lesson progression, live data wiring (no new external technology)
**Confidence:** HIGH (nearly every claim verified by direct codebase reads this session)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Lesson catalog & draft-letter policy
- **D-01:** Expand `lessons.json` from 1 to 28 lessons — one lesson per letter in
  curriculum order, each with `unlock.requires = [previous lesson id]`. Curriculum
  stays data, not code; the owner's mother can reorder/regroup by editing JSON.
- **D-02:** The unlock engine evaluates `unlock.requires[]` generically: a lesson is
  unlocked when every lesson in its `requires[]` is passed. Behaves linearly with
  today's data but supports future grouping/branching as a data-only change.
- **D-03:** Progression flows freely through DRAFT (`signedOff: false`) letters.
  Sign-off is a content milestone (tracked via 04-06), enforced before real release —
  NOT a code gate in the unlock engine.
- **D-04:** Draft status is invisible to the child — no markers on Home or Journey.
  The /dev authoring tools remain the adults' view of sign-off state.

#### Grade entry point & skipped lessons
- **D-05:** Lessons earlier than the profile's `startingLessonId` are **unlocked but
  not mastered** — revisitable anytime from the Journey, no fake mastery rows, stars
  appear only when actually passed.
- **D-06:** Today's lesson = first non-passed lesson **at or after** `startingLessonId`
  (marches forward; supersedes 03.1 D-07's "first non-mastered overall" once an entry
  point exists). Skipped earlier letters never become "today" on their own.
- **D-07:** On the Journey map, skipped-but-unlocked letters reuse the existing
  "future" visual (white, dashed border) but are tappable → practice. No new visual
  state in this phase.

#### Home today-card
- **D-08:** Card keeps its existing layout with live data (letter glyph, name) PLUS
  progress context for the current letter's clean reps.
- **D-09:** Progress context renders as **ink-fill**: the day's letter itself fills
  with ink — one clean rep = one shade deeper, fully inked = mastered. This REPLACES
  plain rep-dots. Pure design-system rendering (parchment/ink), no gamification.
- **D-10:** Partial clean reps **persist across sessions** in the DB (new per-letter
  rep count, updated as reps accrue; new schema migration). Home and practice both
  read it. ⚠️ **Flagged for the owner's mother:** whether reps must be same-sitting/
  consecutive is her pedagogy call — persisting across sessions is the shipped default
  until she rules.
- **D-11:** End state when every available lesson is passed: a calm, dignified
  "you've mastered all your letters" card; Start offers review practice via the
  Journey. Factual, no hype, no Level-2 teasing.
- **D-12:** Replay of mastered lessons happens via Journey green nodes only. Home
  stays single-purpose: one clear Start (S1-01).
- **D-13:** "Prepared desk" entrance: when Home opens, the lesson card settles in like
  a teacher laying out today's worksheet (paper slides in, dotted letter fades up).
  One small entrance animation; respects reduced-motion if the platform requests it.

#### Pass → unlock moment
- **D-14:** The mastery celebration gains a primary **"Next lesson"** button that goes
  straight into the newly unlocked letter's practice, alongside the existing
  "See journey". Returning Home also shows the new lesson.
- **D-15:** Fold in the 03.1-deferred journey highlight: arriving from the celebration
  (`/journey?highlight=<id>` or equivalent), the just-mastered node gets a brief
  emphasis (star badge settles in) before the pulse moves to the new current node.
- **D-16:** When the child passes the LAST lesson, the "Next lesson" slot becomes
  "See journey"; Home then shows the D-11 completion state. No special capstone screen
  in this phase.
- **D-17:** "Show someone at home": after a mastery, the celebration includes one warm
  tutor line — e.g. *"Go show your baa to someone at home."* One l10n string, tutor
  voice rules apply (warm, specific, never chatbot-cheerful).

#### Scaffolding fade (rep → tolerance ramp)
- **D-18:** Within a lesson, rep N scores against a tolerance preset from a
  **data-driven ramp**, default `[loose, normal, strict]` (Phase 4 presets, already
  data). Rep 1 = loose, rep 2 = normal, final rep = strict.
- **D-19:** The ramp lives as data (per-lesson with a global default), NOT hardcoded —
  the owner's mother can flatten it to all-`normal` or reorder it without code change.
  ⚠️ **Flagged for her sign-off:** this changes what "clean rep" means; the mechanism
  ships, the rule is hers.
- **D-20:** The ramp follows the **persisted rep index** (D-10), not the sitting — a
  child resuming at rep 2 scores at rep 2's preset.

#### Slow-motion ghost comparison
- **D-21:** When a stroke is wobbly (fails shape checks), the feedback zone can replay
  the child's stroke beside the reference at half speed — "Watch the difference."
  Uses **in-memory strokes only**; stroke points are NEVER persisted (T-03-01 holds).

### Claude's Discretion
- Route parameterization mechanics (`/practice?lesson=X` vs path param vs extra) —
  pick what fits the existing GoRouter codegen pattern.
- How "lesson passed" is derived (existing `LetterMastery` rows are the pass record
  for single-letter lessons; no separate lesson-pass table needed unless planning
  finds otherwise).
- Whether the live journey provider replaces `mockJourneyProgress` in place or is a
  new provider the screen switches to (03.1 D-08 says screen doesn't change).
- Lesson title strings for lessons 2–28 (placeholder "Lesson N — <Letter>" pattern;
  final wording is content, not code).
- Exact ink-fill rendering technique and the prepared-desk animation curve/timing —
  follow design-system tokens.

### Deferred Ideas (OUT OF SCOPE)
A1 Ijaza certificate · A2 Nuqta ruler · A3 Mashq printable sheets · B4 Haptic ink ·
B3 Pressure-sensitive ink · B5 Mirror-writing check · C1 Write your own name ·
C2 First words are family words · C4 Teach Qalam (protégé effect) · C5 Mom's voice
audio · D3 Warm-up rep · D4 Qalam closes the notebook · E1 Fridge page ·
E2 My-handwriting notebook · E3 Teacher insight loop · E4 Left-handed mode.
(See CONTEXT.md `<deferred>` for full text — do not plan any of these.)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| S1-01 | On opening the app, the child immediately sees today's lesson already prepared, with one clear way to start. *Accept:* landing shows the next unlocked lesson for the current child; a single prominent Start; no navigation required | Home `_TodaysLessonCard` already exists with the right layout (verified); needs a live "today's lesson" provider computed from `CurriculumRepository.getLessons()` + mastered-letter set + `profile.startingLessonId` (D-06 rule). Drift `.watch()` streams (verified in drift 2.31.0) make the card reactive without manual invalidation. Route `/` already lands on Home behind the Phase-5 onboarding gate. |
| S1-09 | The next lesson unlocks only after the child passes the current one. *Accept:* "pass" = the curriculum's clean-reps-to-advance for that item; locked lessons are visibly unavailable; unlock is immediate on pass | Pass record = existing `LetterMastery` row (written by `_recordMastery` on the Nth in-a-row clean rep, verified in practice_providers.dart). Generic unlock engine over `lesson.unlock.requires[]` (model already parses this, verified in lesson.dart). "Immediate on pass" falls out of stream-driven providers: the mastery INSERT triggers the watch, today/journey recompute. Locked lessons visible only on Journey (existing locked/future node visuals from 03.1). |
</phase_requirements>

## Summary

This is an internal-codebase wiring phase, not a new-technology phase. Every building
block already exists and was verified this session: the curriculum repository parses
`lessons.json` with a generic `unlock.requires[]`/`passRule` schema (only 1 of 28
lessons authored); the practice loop counts in-a-row clean reps and writes a
`LetterMastery` row on mastery; Phase 5 delivers the active child with a
`startingLessonId`; the Journey screen renders 28 nodes from a mock provider; the
Phase-4 `Tolerances` presets (loose/normal/strict) are pure data. Phase 6 connects
them: a pure-Dart progression engine (unlocked/passed/today computation), a drift
stream so unlock is immediate on pass, a schema-v4 table for persisted partial reps,
route parameterization of `/practice` and `/journey`, and the five approved
ride-alongs (prepared desk, ink-fill, tutor line, tolerance ramp, ghost comparison).

Two landmines were found that the CONTEXT does not mention. **First, a letter-ID
mismatch:** `journey_screen.dart` hardcodes its own 28-letter list whose IDs diverge
from `letters.json` canonical IDs in 19 of 28 cases (`haa` vs `haa_c`, `dal` vs
`daal`, `ra` vs `raa`, `tah` vs `taa_h`, `dhah` vs `zhaa`, `ha` vs `haa_f`, etc.).
The moment the live provider returns real mastered IDs, those nodes would silently
never light up. The journey letter list MUST be reconciled to canonical IDs (or
loaded from the curriculum), which slightly amends 03.1 D-08's "screen doesn't
change." **Second, the `startingLessonId` namespace:** the Phase-5 resolver stores a
LETTER id (`'alif'`), not a lesson id, with an explicit "Phase 6 decides" flag in
`onboarding_data.dart`. The v4 migration is the natural place to normalize stored
values to lesson ids.

**Primary recommendation:** Build a pure-Dart progression engine fed by a drift
`.watch()` stream of mastered letter IDs; add one new `LetterReps` table at schema v4
(keeping `LetterMastery` row-exists-equals-passed semantics intact); parameterize
existing routes with query parameters; fix the journey ID drift; introduce **zero new
packages**.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Unlock/passed/today computation (D-02, D-06) | Domain (pure Dart, `lib/models` or `lib/core`) | — | Pure function of (ordered lessons, mastered set, startingLessonId); unit-testable with no Flutter/DB |
| Pass record + persisted partial reps (D-10) | Data (drift `AppDatabase` + repositories) | — | Schema v4; only letterId/repCount/timestamps — never stroke points (T-03-01) |
| Reactive "unlock is immediate" (S1-09) | Data → State (drift `.watch()` → Riverpod StreamProvider) | — | Drift streams re-emit on the mastery INSERT; no manual invalidation web |
| Lesson catalog incl. tolerance ramp (D-01, D-19) | Data (assets/curriculum/lessons.json + `CurriculumRepository`) | Domain (Lesson model parse) | Curriculum is data, not code — the owner's mother edits JSON |
| Today-card, ink-fill, prepared desk (D-08/09/13) | UI (`home_screen.dart`) | State (today provider) | Pure design-system rendering; reads tokens only |
| Journey live data + highlight arrival (D-15) | UI (`journey_screen.dart`) | State (live journey provider) | Provider swap per 03.1 D-08 + mandatory canonical-ID fix |
| Route parameterization | Router (`app_router.dart`) | — | Query params on existing routes; redirect gate untouched |
| Rep-indexed tolerance ramp (D-18/D-20) | State (session controller resolves preset) | Core scoring (`scoreLetter` gains optional override) | Scoring policy stays in `scoreLetter`; controller picks the preset from persisted rep index |
| Ghost comparison (D-21) | UI (practice ShowFix zone, widget-local state) | Core (reuse normalization + `StrokeOrderAnimation`) | Strokes stay in widget State — in-memory only |
| Celebration Next-lesson / tutor line (D-14/16/17) | UI (`mastery_celebration.dart`) | State (next-lesson lookup) | Widget gains params; copy in ARB |

## Standard Stack

### Core (all already installed — no additions)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | State management | Project-decided (Riverpod only, D-11) `[VERIFIED: pubspec.yaml]` |
| riverpod_annotation / riverpod_generator | ^4.0.2 / ^4.0.3 | Provider codegen | Existing pattern; known Drift-return-type bug (see Pitfalls) `[VERIFIED: pubspec.yaml + profile_providers.dart]` |
| drift / drift_dev | ^2.31.0 | Local SQLite, schema v3→v4 migration, `.watch()` streams | `.watch()` verified present in installed drift 2.31.0 source (`select.dart:68`) `[VERIFIED: pub-cache source read]` |
| go_router | ^17.2.3 | Routing; query params via `state.uri.queryParameters` | Existing router; plain `GoRoute` builders (NOT route codegen, despite CONTEXT wording — verified `app_router.dart` uses hand-written routes with a Riverpod-codegen *provider*) `[VERIFIED: app_router.dart]` |
| flutter_svg | ^2.3.0 | Brand glyphs/mascot | Existing `[VERIFIED: pubspec.yaml]` |
| flutter_test (SDK) | bundled | Widget/unit/golden tests | Existing harness with `test/flutter_test_config.dart` font loading `[VERIFIED: test/ tree]` |

**Installation:** none — this phase introduces no new packages (also a binding statement in 06-UI-SPEC Registry Safety).

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| drift `.watch()` stream for unlock reactivity | `ref.invalidate(...)` calls sprinkled at every mastery write/navigation | Invalidation is fragile (any missed call = stale Home, violating S1-09 "immediate"); streams are the drift-idiomatic push model |
| New `LetterReps` table | Adding a nullable `masteredAt` + rep column to `LetterMastery` | Existing call sites assume "row exists = mastered" (`isMastered`); changing that invariant risks regressions across practice + future journey/parent code |
| Query parameters (`/practice?lesson=X`) | Path param (`/practice/:lessonId`) or `extra` | Query keeps `matchedLocation` identical so the Phase-5 onboarding redirect (`state.matchedLocation == '/onboarding'`) is untouched; `extra` doesn't survive deep links/restoration |

## Package Legitimacy Audit

No packages are installed by this phase (UI-SPEC: "No new runtime packages are
introduced by this phase"). slopcheck run: not applicable.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                                   ┌────────────────────────────────────┐
                                   │ assets/curriculum/                 │
                                   │  lessons.json (1 → 28 entries,     │
                                   │   unlock.requires[], toleranceRamp)│
                                   │  letters.json (28, canonical ids)  │
                                   └───────────────┬────────────────────┘
                                                   │ rootBundle (cached, keepAlive)
                                                   ▼
 ┌──────────────┐   getProfile()   ┌──────────────────────────┐
 │ ChildProfile │─────────────────▶│   PROGRESSION ENGINE     │
 │ Repository   │ startingLessonId │ (pure Dart, new)         │
 └──────────────┘                  │ inputs: ordered lessons, │
 ┌──────────────────────────┐      │  mastered letter ids,    │
 │ AppDatabase (drift v4)   │      │  startingLessonId        │
 │  LetterMastery (passed)  │──┐   │ outputs: per-lesson      │
 │  LetterReps (D-10, NEW)  │  │   │  unlocked/passed/today,  │
 │  ChildProfiles           │  │   │  allMastered flag        │
 └──────────────────────────┘  │   └───────────┬──────────────┘
        ▲          │ .watch() streams          │
        │          └──────────────►────────────┤ recompute on every mastery/rep write
        │ writes                               ▼
 ┌──────┴───────────────────┐      ┌──────────────────────────┐
 │ PracticeSessionController│      │ Riverpod providers (new) │
 │  (family by lessonId)    │      │  todayLesson / journey   │
 │  seeds reps from         │      │  progress (live)         │
 │  LetterReps (D-20),      │      └───┬───────────┬──────────┘
 │  resolves ramp preset    │          ▼           ▼
 │  per rep (D-18),         │   ┌───────────┐ ┌───────────────┐
 │  writes rep + mastery    │   │ HomeScreen│ │ JourneyScreen │
 └──────┬───────────────────┘   │ today-card│ │ live nodes,   │
        │ celebrate             │ ink-fill, │ │ canonical ids,│
        ▼                       │ prepared  │ │ ?highlight=   │
 ┌──────────────────────────┐   │ desk      │ │ arrival anim  │
 │ MasteryCelebration       │   └─────┬─────┘ └──────┬────────┘
 │  Next Lesson / See       │         │ tap          │ node tap
 │  Journey (D-14/16),      │         ▼              ▼
 │  tutor line (D-17)       │──▶ /practice?lesson=<id>  (go_router query param;
 └──────────────────────────┘    onboarding redirect gate unaffected)
```

Primary use case trace (S1-01 + S1-09): app opens → router lands `/` (gate passes) →
todayLesson provider reads profile + lessons + mastered stream → Home renders today's
card → tap → `/practice?lesson=X` → clean reps accrue (writes LetterReps per rep) →
Nth rep writes LetterMastery → drift stream emits → today/journey recompute → child
taps "Next lesson" straight into the unlocked letter, or returns Home which now shows
the new lesson.

### Recommended Project Structure (additions only — follow existing layout)

```
lib/
├── models/
│   └── lesson_progression.dart   # NEW: pure-Dart engine (LessonStatus, computeToday,
│                                 #      isUnlocked, allMastered) — no Flutter imports
├── providers/
│   ├── progression_providers.dart # NEW: masteredLetterIds stream, todayLesson,
│   │                              #      liveJourneyProgress
│   └── journey_providers.dart     # mockJourneyProgress retired/swapped here
├── data/
│   ├── app_database.dart          # schema v4: LetterReps table + watch/rep accessors
│   ├── progress_repository.dart   # interface gains rep persistence + watch
│   └── drift_progress_repository.dart
├── features/practice/widgets/
│   ├── mastery_celebration.dart   # gains letter, onNextLesson, isLast, tutor line
│   └── ghost_comparison.dart      # NEW (D-21): side-by-side half-speed replay
└── screens/home_screen.dart       # live _TodaysLessonCard, ink-fill, prepared desk
assets/curriculum/lessons.json     # 1 → 28 lessons + defaultToleranceRamp
```

### Pattern 1: Drift stream → StreamProvider for "immediate on pass" (S1-09)

**What:** Expose mastered letter IDs as a `Stream<Set<String>>` from drift; today's
lesson and journey progress are providers derived from it.
**When to use:** Any read that must update the instant `recordMastery`/rep writes land.
**Example:**
```dart
// AppDatabase (drift .watch() verified in installed 2.31.0)
Stream<Set<String>> watchMasteredLetterIds() =>
    select(letterMastery).watch().map(
      (rows) => rows.map((r) => r.letterId).toSet(),
    );

// providers — keep hand-written where Drift data classes are returned
// (riverpod_generator 4.0.3 bug, see Pitfalls)
final masteredLetterIdsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(appDatabaseProvider).watchMasteredLetterIds(),
);
```
Source: drift 2.31.0 `select.dart:68` `[VERIFIED: pub-cache source]`; provider shape
mirrors `childProfileProvider` precedent `[VERIFIED: profile_providers.dart]`.

### Pattern 2: Pure-Dart progression engine (D-02 / D-05 / D-06)

**What:** All progression rules as a pure function over immutable inputs — generic
`requires[]` evaluation, the D-06 today rule, D-05 skipped-but-unlocked.
**Example (the exact decided semantics):**
```dart
// lib/models/lesson_progression.dart — pure Dart, no Flutter (models rule:
// "lib/models/*.dart must not import from lib/data/ or lib/features/")
bool lessonPassed(Lesson lesson, Set<String> masteredLetterIds) =>
    // passRule "allItemsPassed": every letter item mastered (CONTEXT discretion
    // confirmed viable — LetterMastery rows ARE the pass record).
    lesson.items
        .where((i) => i.type == 'letter')
        .every((i) => masteredLetterIds.contains(i.ref));

bool lessonUnlocked(Lesson lesson, Map<String, Lesson> byId, Set<String> mastered) =>
    lesson.unlock.requires.every((id) {
      final req = byId[id];
      return req != null && lessonPassed(req, mastered);
    });

/// D-06: first non-passed lesson AT OR AFTER startingLessonId (lessons sorted
/// by order). Returns null when all available lessons are passed (D-11 state).
Lesson? todayLesson(List<Lesson> ordered, String startingLessonId, Set<String> mastered) {
  final startIdx = ordered.indexWhere((l) => l.id == startingLessonId);
  final from = startIdx < 0 ? 0 : startIdx; // defensive: unknown id → first lesson
  for (final l in ordered.skip(from)) {
    if (!lessonPassed(l, mastered)) return l;
  }
  return null;
}
```
D-05 falls out for free: lessons before `startingLessonId` whose `requires[]` are
passed are *not* "today" but are unlocked for Journey taps; with a grade entry point
beyond lesson 1, earlier lessons should be treated as unlocked regardless of
`requires[]` (they're "skipped-but-unlocked" per D-05/D-07) — planner should encode
`index < startIndex → unlocked` explicitly.

### Pattern 3: Query-parameter routes that don't disturb the onboarding gate

**What:** Parameterize existing routes via `state.uri.queryParameters`. The Phase-5
redirect compares `state.matchedLocation` (path only), so query strings cannot break
the gate `[VERIFIED: app_router.dart:46-49]`.
```dart
GoRoute(
  path: '/practice',
  builder: (context, state) {
    final lessonId = state.uri.queryParameters['lesson'];
    // null/invalid → screen-level degradation to today's/starting lesson
    return PracticeScreen(
      key: ValueKey(lessonId),       // fresh State when lesson changes (see Pitfalls)
      lessonId: lessonId,
    );
  },
),
GoRoute(
  path: '/journey',
  builder: (context, state) => JourneyScreen(
    highlightId: state.uri.queryParameters['highlight'],
  ),
),
```

### Pattern 4: Idempotent schema v4 migration (copy the v2→v3 shape)

```dart
@override
int get schemaVersion => 4;

onUpgrade: (m, from, to) async {
  if (from < 2) await m.createTable(letterMastery);
  if (from < 3) await m.createTable(childProfiles);
  if (from < 4) {
    await m.createTable(letterReps); // D-10 persisted partial reps
    // Namespace normalization (Open-Q resolved this phase): legacy profiles
    // store a LETTER id ('alif'); rewrite to the lesson id.
    await customStatement(
      "UPDATE child_profiles SET starting_lesson_id = 'lesson_01' "
      "WHERE starting_lesson_id = 'alif'",
    );
  }
},
```
Pattern source: existing `app_database.dart:78-85` `[VERIFIED: codebase]`. (Exact
generated column/table names for the customStatement must be checked against
`app_database.g.dart` during implementation.)

### Pattern 5: Rep-indexed tolerance ramp (D-18/D-20) with policy in scoreLetter

**What:** `scoreLetter` currently resolves `letter.tolerances ?? Tolerances.normal`
internally `[VERIFIED: letter_scorer.dart:61]`. Add an optional override so the
session controller can pass the ramp preset for the current persisted rep index.
```dart
// letter_scorer.dart — optional override, default preserves Phase-4 behavior
Future<LetterResult> scoreLetter(
  List<List<List<double>>> childStrokes,
  Letter letter, {
  HandwritingRecognizer? recognizer,
  Tolerances? tolerances,            // NEW: ramp override (null = letter's own)
}) async {
  final t = tolerances ?? letter.tolerances ?? Tolerances.normal;
  ...
}

// Ramp resolution (controller side): preset name from data, clamped
final ramp = lesson.toleranceRamp ?? defaultRamp; // ["loose","normal","strict"]
final presetName = ramp[min(persistedRepIndex, ramp.length - 1)];
```
`Tolerances._presets` is private `[VERIFIED: tolerances.dart:44]` — expose a static
`Tolerances.preset(String name)` (unknown → `normal`, matching the existing
defensive-parse idiom). The ramp is invisible to the child (UI-SPEC: scoring
contract, not UI contract).

### Pattern 6: Ghost comparison reuses StrokeOrderAnimation machinery (D-21)

`StrokeOrderAnimation` takes `List<StrokeSpec>` (normalized 0..1 points) with
hardcoded `QalamMotion.durWrite` and `QalamColors.inkStroke`
`[VERIFIED: stroke_order_animation.dart:36-43,60,146]`. For the side-by-side replay it
needs optional `duration` and ink-`color` parameters (child stroke: `warnSoft` coral,
`durWrite × 2` = 2800ms, linear curve per UI-SPEC). The child's strokes exist as
`List<List<Offset>>` in `practice_screen._onLetterComplete` and are currently
discarded after scoring `[VERIFIED: practice_screen.dart:88-116]` — retain the last
*failing* letter's strokes in widget State (in-memory only; T-03-01 forbids
persistence, not retention in State). Normalization to 0..1 StrokeSpecs exists as
`normalizeToStrokeSpecs` but lives in `lib/dev/authoring_export.dart` operating on
`CapturedStroke` `[VERIFIED: authoring_export.dart:90]` — extract/share the
combined-bbox normalization rather than re-deriving it.

### Anti-Patterns to Avoid

- **Lifting raw `List<Offset>` into provider state:** Anti-Pattern 3 guard — the
  session controller file must keep zero `List<Offset>` references (grep-enforced
  comment, practice_providers.dart:6-9). Ghost-comparison strokes stay in widget State.
- **keepAlive for progression providers:** `mockJourneyProgress` is keepAlive — a
  *live* keepAlive FutureProvider would cache a stale "today." Use StreamProvider
  (auto-updating) or autoDispose.
- **Gating the unlock engine on `signedOff`:** D-03 explicitly forbids it.
- **Gold ink-fill:** the ink-fill ramp is `QalamColors.inkStroke` opacity
  `0.25 + 0.75 × (reps/N)` — gold is rewards-only (UI-SPEC Color contract, exhaustive list).
- **A second source of truth for the 28 letters:** the journey's hardcoded
  `_kLetters` already diverged from letters.json (19/28 IDs wrong). Fix to canonical
  IDs; prefer deriving glyph/name from `CurriculumRepository` long-term.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reactive unlock propagation | Manual `ref.invalidate` choreography across screens | drift `select().watch()` → StreamProvider | One missed invalidation = stale Home; drift streams re-emit on any table write `[VERIFIED: drift 2.31.0 source]` |
| Route param parsing | String-splitting `state.uri.toString()` | `state.uri.queryParameters` | go_router's supported API; survives redirects |
| Lesson-pass bookkeeping | A new lesson-pass table + write path | Derive from `LetterMastery` rows via `passRule: allItemsPassed` | CONTEXT discretion confirms; one source of truth; works for future multi-item lessons |
| Stroke replay animation | A new replay painter | `StrokeOrderAnimation` + duration/color params | Same path-resolve/animation machinery already battle-tested for Watch/ghost-cast |
| Stroke normalization for ghost replay | New bbox math | Shared combined-bbox `normalizeToStrokeSpecs` logic | Pitfall-2 (dot position) normalization already solved in Phase 4 |
| Entrance/celebration motion curves | Custom curves/durations | `QalamMotion` tokens (easeOutQuart/easeSoftBack, durBase/durSlow/durCheer/durWrite) | UI-SPEC binds exact tokens `[VERIFIED: dimens.dart:76-90]` |

**Key insight:** every hard sub-problem in this phase (scoring tolerance, path
animation, normalization, migration idempotence, redirect gating) was already solved
in Phases 1–5 — the phase's risk is *integration drift* (IDs, namespaces, stale
caches), not new algorithms.

## Runtime State Inventory

This phase performs a schema migration and a stored-value namespace change; the
relevant runtime state on devices/emulators:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `qalam.db` (app-private): `ChildProfiles.startingLessonId` rows contain the LETTER id `'alif'` (Phase-5 resolver, all grades) `[VERIFIED: onboarding_data.dart:53-59 + app_database.dart]` | **Data migration** in v4 (`UPDATE ... 'alif' → 'lesson_01'`) **plus code edit** (map values in `gradeToStartingLessonId` become lesson ids) — both are needed; doing only one leaves mixed namespaces |
| Stored data | `LetterMastery` rows on dev devices (e.g., alif mastered during Phase-3/4 testing) | None — schema unchanged; semantics preserved (row = passed) |
| Live service config | None — app is local-only, no services | None — verified by PROJECT decisions (v1 no Firebase) |
| OS-registered state | None beyond the installed APK | None |
| Secrets/env vars | None — no secrets in v1 | None |
| Build artifacts | `lib/l10n/app_localizations*.dart` are generated and gitignored; new ARB keys require regeneration | Run `flutter gen-l10n` after ARB edits (and on any fresh checkout) `[VERIFIED: project memory + l10n dir]` |

## Common Pitfalls

### Pitfall 1: Journey letter-ID drift (HIGH severity — will silently break live data)
**What goes wrong:** `journey_screen.dart` `_kLetters` IDs disagree with
`letters.json` for 19 of 28 letters (`haa`≠`haa_c`, `dal`≠`daal`, `dhal`≠`dhaal`,
`ra`≠`raa`, `zay`≠`zaay`, `tah`≠`taa_h`, `dhah`≠`zhaa`, `ain`≠`ayn`, `ghain`≠`ghayn`,
`fa`≠`faa`, `qaf`≠`qaaf`, `kaf`≠`kaaf`, `lam`≠`laam`, `ha`≠`haa_f`, `waw`≠`waaw`,
`ya`≠`yaa`, `khaa` matches, etc.) `[VERIFIED: diff of journey_screen.dart:37-66 vs letters.json ids]`.
**Why it happens:** 03.1 built the screen against the mock provider, which only used
`alif/baa/taa/thaa` — the four IDs that happen to match.
**How to avoid:** Reconcile the node list to canonical curriculum IDs as part of the
live-provider swap. This slightly amends 03.1 D-08 ("screen doesn't change") — the
change is data-only within the screen, or better, derive the list from
`curriculumRepository.getLetters()`.
**Warning signs:** A mastered ح/د/ر node stays white on the Journey after celebration.

### Pitfall 2: `startingLessonId` namespace (letter id vs lesson id)
**What goes wrong:** D-06 logic comparing `startingLessonId` against lesson ids never
matches because stored values are letter ids (`'alif'`).
**Why it happens:** Phase 5 shipped the resolver with an explicit "Phase 6 decides"
flag `[VERIFIED: onboarding_data.dart:48-52]`.
**How to avoid:** Decide lesson-id namespace; v4 migration rewrites stored rows; map
values updated in one place; `todayLesson` defensively treats an unknown id as index 0.
**Warning signs:** Today's lesson computes from lesson 1 for a grade-3 child.

### Pitfall 3: riverpod_generator 4.0.3 InvalidTypeException on Drift data classes
**What goes wrong:** `@riverpod` functional providers returning Drift-generated
classes (`ChildProfile`, and any new `LetterRep` row class) fail codegen.
**How to avoid:** Hand-write those providers as `FutureProvider`/`StreamProvider`
(established Phase-5 deviation, documented in profile_providers.dart) `[VERIFIED: profile_providers.dart:21-29]`.
Providers returning plain domain types (the progression engine's own classes) can use codegen.

### Pitfall 4: Stale caches defeating "immediate on pass"
**What goes wrong:** keepAlive FutureProviders (the `mockJourneyProgress` pattern) or
`childProfileProvider`-style one-shot reads cache yesterday's progress; Home shows the
old lesson after a pass.
**How to avoid:** drift `.watch()` streams for mastery/reps. Note `childProfileProvider`
is already invalidatable and NOT keepAlive — fine to reuse for `startingLessonId`.
**Warning signs:** Celebration's "Back Home" shows the just-mastered letter as today.

### Pitfall 5: PracticeScreen reuse across lesson changes
**What goes wrong:** `go('/practice?lesson=lesson_02')` from the celebration of
lesson_01 keeps the same `PracticeScreen` State (same route path), so `_animKey`,
canvas epoch, and any retained ghost strokes leak across lessons; the controller
family key changes but local widget state doesn't.
**How to avoid:** `key: ValueKey(lessonId)` on `PracticeScreen` in the route builder.
**Warning signs:** New lesson opens mid-phase or shows the previous letter's ghost.

### Pitfall 6: Letter-specific copy hardcoded to alif becomes wrong for lessons 2–28
**What goes wrong:** `practiceCelebrationLine` = "You learned alif.",
`practicePraiseLine` = "That's a clean alif...", `_MasteredGlyph` hardcodes `'ا'`,
Watch heading/tip strings are alif-specific `[VERIFIED: app_en.arb + mastery_celebration.dart:266-277]`.
Phase 6 makes baa+ reachable, so the celebration would praise the wrong letter.
**Why it happens:** Phase 3 built the loop for exactly one lesson.
**How to avoid:** Parameterize at minimum the celebration (glyph + `{letterName}`
template) — note this tension with UI-SPEC's "celebration heading unchanged" line
(the type role is unchanged; the copy must template). Per-letter *coaching* wording
(tips) is curriculum content — keep generic phrasing, flag specifics for the owner's
mother (Phase 7).
**Warning signs:** "You learned alif." after mastering baa.

### Pitfall 7: Persisted reps vs the in-a-row reset rule
**What goes wrong:** The session rule is N clean reps IN A ROW (`cleanReps: 0` on any
miss `[VERIFIED: practice_providers.dart:148-156]`). If the persisted count (D-10)
only increments, the ramp index (D-20) and ink-fill disagree with the streak.
**How to avoid:** Write-through: persisted count mirrors controller state, including
resets to 0 on a miss. The controller's `build()` seeds `cleanReps` from `LetterReps`
(async prime, like `_loadLetter`). This makes ink-fill able to go *lighter* after a
miss — acceptable default; the same-sitting/consecutive question is explicitly the
owner's mother's call (D-10 flag).
**Warning signs:** Ramp scores rep 3 at `strict` right after a miss reset.

### Pitfall 8: Stale Phase-03.1 test debt — reconcile, don't "fix" goldens
**What goes wrong:** Treating known-failing tests as Phase-6 regressions, or
re-baking goldens to absorb local font drift.
**The debt (verified locations):**
- `test/screens/home_screen_test.dart:204` Test 4 — asserts Journey nav is locked/"Coming soon"; Journey nav has been live since 03.1. Phase 6 should rewrite it (Journey navigates; Parent stays "Coming soon").
- `test/features/practice/mastery_celebration_golden_test.dart:74` and `test/features/practice/practice_screen_test.dart:167,220` — assert NO "See journey" button; the button exists. D-14 makes these triply stale; reconcile.
- Golden font drift: `glyph_audit` + `mastery_celebration` goldens fail locally from font rendering, NOT regressions — do not re-bake to silence drift. Note: D-14/D-17 legitimately change the celebration layout, so its golden needs a deliberate re-bake; separate that intentional re-bake from drift noise in the plan.

### Pitfall 9: l10n null-safe access pattern + gen-l10n
All new strings go through ARB keys with the `l10n?.key ?? 'fallback'` idiom used
everywhere; generated `app_localizations*.dart` is gitignored — `flutter gen-l10n`
must run after ARB changes or builds/tests fail with missing getters.

### Pitfall 10: CurriculumRepository load-time validation throws on bad lessons.json
`_ensureLoaded` hard-throws on invalid referenceStrokes and will parse all 28 new
lesson entries at first load `[VERIFIED: curriculum_repository.dart:50-69]`. A typo'd
`ref` in lessons.json (e.g., `haa` instead of `haa_c`) won't throw at load (refs
aren't validated) but breaks practice silently. Add a test asserting every
`lesson.items[].ref` resolves to a letter id and every `unlock.requires[]` resolves
to a lesson id.

## Code Examples

### Ink-fill rendering (D-09, UI-SPEC prescriptive contract)
```dart
// Today-card glyph: deep-ink opacity ramp; the ink IS the progress.
final t = (persistedCleanReps / cleanRepsToAdvance).clamp(0.0, 1.0);
final inkColor = QalamColors.inkStroke.withValues(alpha: 0.25 + 0.75 * t);
Semantics(
  label: l10n?.homeInkFillSemantics(persistedCleanReps, cleanRepsToAdvance)
      ?? '$persistedCleanReps of $cleanRepsToAdvance clean reps',
  child: ArabicText(letter.char, display: true,
      style: /* arDisplay role with color: inkColor */),
)
// NO visible numeric rep text on the card (UI-SPEC). NOT gold.
```

### Prepared-desk entrance (D-13, UI-SPEC tokens)
```dart
// Once per arrival; respect reduced motion.
final reduced = MediaQuery.of(context).disableAnimations;
// card: slide up ~24px + fade, QalamMotion.easeOutQuart over durSlow (420ms)
// glyph: fade up over durBase (220ms), after the card settles
// if (reduced) → render settled immediately (skip controllers)
```

### lessons.json expansion shape (D-01/D-19) — data the owner's mother can edit
```json
{
  "defaultToleranceRamp": ["loose", "normal", "strict"],
  "lessons": [
    { "id": "lesson_01", "order": 1, "title": { "display": "Lesson 1 — Alif" },
      "items": [{ "type": "letter", "ref": "alif" }],
      "unlock": { "requires": [], "passRule": "allItemsPassed" } },
    { "id": "lesson_02", "order": 2, "title": { "display": "Lesson 2 — Baa" },
      "items": [{ "type": "letter", "ref": "baa" }],
      "unlock": { "requires": ["lesson_01"], "passRule": "allItemsPassed" } }
  ]
}
```
Letter refs MUST use the canonical letters.json ids (`haa_c`, `daal`, `dhaal`, `raa`,
`zaay`, `taa_h`, `zhaa`, `ayn`, `ghayn`, `faa`, `qaaf`, `kaaf`, `laam`, `haa_f`,
`waaw`, `yaa` — verified list). `Lesson.fromJson` needs an optional `toleranceRamp`
field (defensive parse, mirroring `Tolerances.fromJson`).

### New ARB keys (from the approved UI-SPEC Copywriting Contract)
```
homeLessonTitleFor        = "The Letter {letterName}"
celebrationNextLesson     = "Next Lesson"
celebrationShowSomeone    = "Go show your {letterName} to someone at home."
ghostCompareButton        = "Watch the Difference"
ghostCompareTitle         = "Watch the difference."
ghostCompareYours         = "Yours"
ghostCompareQalams        = "Qalam's"
homeAllMasteredEyebrow    = "YOUR LETTERS"
homeAllMasteredTitle      = "You've mastered all your letters."
homeAllMasteredBody       = "Visit your journey to practice any letter again."
homeInkFillSemantics      = "{n} of {total} clean reps"   (a11y only — not in UI-SPEC, minor addition)
```
Plus a parameterized celebration line (Pitfall 6) — flag the UI-SPEC tension to the
planner rather than silently reusing "You learned alif."

## State of the Art

| Old Approach (current code) | Current Approach (this phase) | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `mockJourneyProgress` keepAlive static provider | Live stream-derived journey progress | Phase 6 | 03.1 D-08 fulfilled; mock retired |
| `PracticeScreen._lessonId = 'lesson_01'` hardwired | Route-parameterized lessonId | Phase 6 | All 28 lessons reachable |
| Clean reps in-session only | `LetterReps` persisted (schema v4) | Phase 6 | D-10/D-20; ink-fill + resume |
| `scoreLetter` reads only `letter.tolerances` | Optional ramp override param | Phase 6 | D-18 scaffolding fade |
| Journey nav "Coming soon" tests | Reconciled tests | Phase 6 | Clears 03.1 debt |

**Deprecated/outdated:** demo ARB keys (`demoHomeStarCount`, `demoHomeThisWeek`,
`demoCelebrationStarsDelta`, …) predate anti-gamification — demo-only, never on real
surfaces (binding UI-SPEC omission table).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Persisted rep count should write-through (reset on miss) to keep D-20 ramp consistent with the in-a-row rule | Pitfall 7 | Ink-fill/ramp semantics change; explicitly the owner's mother's call (D-10 flag) — ship default, surface in verification notes |
| A2 | `startingLessonId` namespace resolves to lesson ids (`lesson_NN`) with a v4 data migration | Pitfall 2 / Runtime State | If planner prefers letter-id + lookup instead, migration is dropped but every comparison site needs the letter→lesson mapping |
| A3 | go_router `state.uri.queryParameters` available in 17.x and `matchedLocation` excludes query strings | Pattern 3 | Redirect-gate breakage; mitigated — `matchedLocation` path-only behavior is observable in the existing gate test (`test/router/onboarding_gate_test.dart`); verify in Wave 0 |
| A4 | Parameterizing the celebration line/glyph is in scope despite UI-SPEC "celebration heading unchanged" | Pitfall 6 | If owner wants UI-SPEC literal, lessons 2–28 celebrate with alif copy — clearly worse; flag at plan review |
| A5 | The journey ID fix is an acceptable amendment to 03.1 D-08 "screen doesn't change" | Pitfall 1 | Without it, live data cannot light 19 nodes — there is no alternative that keeps both D-08 literal and S1-09 true |

## Open Questions

1. **Mastery celebration golden re-bake environment (RESOLVED)**
   - What we know: the celebration legitimately changes (D-14/D-16/D-17) so its golden must be re-baked; but goldens currently fail locally from font drift (environmental).
   - What's unclear: which machine produced the canonical baseline.
   - Recommendation: re-bake on the same environment that baked Phase-3 goldens, or accept the golden as locally-failing-by-font-drift and gate on widget assertions instead; planner should make this explicit in the test task.
   - RESOLVED: 06-07 Task 2 step 4 re-bakes the celebration golden ONCE, deliberately, with provenance documented in the SUMMARY (local font-drift caveat carried; glyph_audit golden untouched) (see 06-07-PLAN).

2. **Where the D-21 ghost trigger appears given the practice-redesign ShowFix zone (RESOLVED)**
   - What we know: docs/design/practice-redesign/ contains PROMPT.md + mockup.html (a UI-only redesign already applied 2026-06-07); the ghost button sits "beside Show Me Again" per UI-SPEC; `Show Me Again` lives in `_ActionRow` showFix case `[VERIFIED: practice_screen.dart:970-990]`.
   - What's unclear: whether the replay panel overlays the canvas or replaces the tutor bubble area.
   - Recommendation: side-by-side panel within the canvas card stack (same Stack that hosts the ghost-cast overlay); executor discretion within UI-SPEC labels/colors.
   - RESOLVED: 06-08 Task 2 adopts the canvas-Stack recommendation — the side-by-side replay panels live inside the canvas card Stack that hosts the ghost-cast overlay (see 06-08-PLAN).

3. **`practicePraiseLine` / Watch-phase copy for letters 2–28 (RESOLVED)**
   - What we know: alif-specific strings; per-letter coaching is curriculum content (the mother's domain, Phase 7).
   - Recommendation: generic `{letterName}` templates this phase; per-letter tips deferred to Phase 7 content authoring.
   - RESOLVED: 06-07 ships generic `{letterName}` templates; per-letter wording deferred to Phase 7 content authoring (the owner's mother's domain) (see 06-07-PLAN).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | build/test everything | ✓ | 3.41.9 stable `[VERIFIED: flutter --version]` | — |
| Dart | pure-Dart engine tests | ✓ | bundled with Flutter | — |
| flutter gen-l10n | new ARB keys | ✓ | bundled | — |
| Android tablet/emulator | device UAT only (end-of-phase human verify) | not probed | — | widget/golden tests cover automated verification |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) + golden tests with bundled-font loading via `test/flutter_test_config.dart` |
| Config file | `test/flutter_test_config.dart` `[VERIFIED]` |
| Quick run command | `flutter test test/<touched_file>.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| S1-01 | Today's lesson computation (D-06 incl. start-offset, skipped, all-mastered) | unit (pure Dart) | `flutter test test/models/lesson_progression_test.dart` | ❌ Wave 0 |
| S1-01 | Home renders live today-card (glyph/title from provider), one Start, no nav needed | widget | `flutter test test/screens/home_screen_test.dart` | ✅ extend (+ reconcile stale Test 4) |
| S1-09 | Unlock engine: generic `requires[]`, locked until prerequisite passed | unit | `flutter test test/models/lesson_progression_test.dart` | ❌ Wave 0 |
| S1-09 | recordMastery → stream emits → today/journey recompute (immediate) | provider/integration | `flutter test test/providers/progression_providers_test.dart` | ❌ Wave 0 |
| S1-09 | Locked lessons visibly unavailable on Journey; skipped nodes tappable (D-07) | widget | `flutter test test/features/journey/journey_screen_test.dart` | ❌ Wave 0 (no journey screen test exists) |
| D-10 | v3→v4 migration idempotent; reps persist across simulated restart; startingLessonId normalized | unit (drift in-memory) | `flutter test test/data/app_database_test.dart` | ✅ extend |
| D-18/D-20 | Ramp preset by persisted rep index; `scoreLetter` override default-preserving | unit | `flutter test test/core/...` + `test/features/practice/session_controller_test.dart` | ✅ extend |
| D-14/16/17 | Celebration: Next Lesson primary, last-lesson variant, tutor line; reconcile stale "no See journey" asserts | widget | `flutter test test/features/practice/practice_screen_test.dart test/features/practice/mastery_celebration_golden_test.dart` | ✅ extend/reconcile |
| D-21 | Ghost comparison: in-memory only (no persistence), coral/ink colors, replayable | widget | `flutter test test/features/practice/` (new ghost test) | ❌ Wave 0 |
| Data integrity | All 28 lessons parse; every `items[].ref` and `requires[]` resolves; canonical IDs | unit | `flutter test test/data/curriculum_repository_test.dart` | ✅ extend |

Note (drift+flutter_test): `import 'package:drift/drift.dart' hide isNull, isNotNull;` in mixed tests (established pattern).

### Sampling Rate
- **Per task commit:** `flutter test <touched test files>` (< 30s each)
- **Per wave merge:** `flutter test` (full suite; known-failing set must not grow beyond the documented font-drift goldens)
- **Phase gate:** full suite green except documented environmental golden drift, before `/gsd-verify-work`; device UAT human-gated end-of-phase

### Wave 0 Gaps
- [ ] `test/models/lesson_progression_test.dart` — covers S1-01/S1-09 pure logic (D-02/D-05/D-06/D-11 states)
- [ ] `test/providers/progression_providers_test.dart` — stream-driven immediacy (S1-09)
- [ ] `test/features/journey/journey_screen_test.dart` — live nodes, canonical IDs, D-07 taps, D-15 highlight
- [ ] Reconciliation list: `home_screen_test.dart:204` (Test 4), `mastery_celebration_golden_test.dart:74`, `practice_screen_test.dart:167,220` — stale 03.1 assertions Phase 6 must rewrite, not regress against
- [ ] Framework install: none needed

## Security Domain

Project posture: local-only, on-device, no network, child-data minimal (CLAUDE.md
Decided; PLAT-01). ASVS Level 1, `security_block_on: high`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | local-only, no accounts (v1 by design) |
| V3 Session Management | no | — |
| V4 Access Control | no (parent PIN is Phase 9) | keep `/parent` seam inert |
| V5 Input Validation | yes | Validate `?lesson=` / `?highlight=` query params against curriculum IDs; unknown/missing → degrade to startingLessonId/today (UI-SPEC error contract: never a raw error to the child). lessons.json parsed with the existing defensive `fromJson` idiom; repo load-guard throws on invalid stroke data |
| V6 Cryptography | no | nothing sensitive stored; app-private SQLite |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stroke-point persistence creep via D-21 ghost replay | Information disclosure (T-03-01) | Strokes retained in widget State ONLY; never in providers/DB; keep the grep-guard convention (`List<Offset>` count in practice_providers.dart = 0); add an explicit test that `LetterReps`/no table stores coordinates |
| New child data in `LetterReps` | Privacy minimization | Only letterId + int count + timestamp — same class as existing LetterMastery (non-sensitive); never logged (existing no-log convention) |
| Malformed deep link `?lesson=../../x` | Tampering | ID-allowlist validation (must match a lesson id from the loaded catalog) before use; no filesystem/SQL surface from the param anyway (drift parameterized queries) |
| Migration data loss (v3→v4) | Integrity | Idempotent `if (from < 4)` guard (established pattern); migration test simulating v3 DB with existing profile + mastery rows |

## Project Constraints (from CLAUDE.md)

- **GSD loop enforced** — this research feeds `/gsd-plan-phase`; execution via `/gsd-execute-phase`.
- **Decided section is binding:** Flutter+Dart Android-only; Riverpod only (reject BLoC/GetX); anti-gamification invariants (stars = mastery markers only; NO running totals/weekly tallies/streaks/badges/"+N" hype/leaderboards); design source of truth `docs/design/kit/`; child data minimal/private.
- **Curriculum is the owner's mother's domain** — D-10 (rep consecutiveness) and D-19 (ramp = what "clean rep" means) ship as mechanisms with her sign-off flagged; lesson titles 2–28 are placeholders; never invent pedagogy.
- **Python over TypeScript for tooling** — no tooling needed this phase (note: the calibration harness precedent is deliberately Dart).
- **Propose, don't decide** on anything pedagogical; **when unsure, ask**.
- **Routing map:** state management → Riverpod patterns; UI implementation per existing mockups; note project memory: most `flutter-*` specialist agents are NOT installed — route Flutter work to `flutter-expert` or adopt the role in place.
- **Tutor voice** (D-17 line): warm, calm, specific; never chatbot-cheerful; a little Arabic welcome; guidance in English.

## Sources

### Primary (HIGH confidence — direct codebase reads this session)
- `lib/screens/home_screen.dart`, `lib/features/journey/journey_screen.dart`, `lib/features/practice/practice_screen.dart`, `lib/features/practice/widgets/mastery_celebration.dart`, `lib/features/practice/widgets/stroke_order_animation.dart`, `lib/features/practice/widgets/stroke_canvas.dart`
- `lib/providers/practice_providers.dart`, `lib/providers/journey_providers.dart`, `lib/providers/profile_providers.dart`
- `lib/data/app_database.dart` (schema v3, migration pattern), `lib/data/curriculum_repository.dart`, `lib/data/progress_repository.dart`, `lib/data/drift_progress_repository.dart`, `lib/data/child_profile_repository.dart`
- `lib/models/lesson.dart`, `lib/models/letter.dart`, `lib/models/journey_progress.dart`
- `lib/core/scoring/tolerances.dart`, `lib/core/scoring/letter_scorer.dart` (scoreLetter signature), `lib/router/app_router.dart`, `lib/theme/dimens.dart`, `lib/features/onboarding/onboarding_data.dart`, `lib/dev/authoring_export.dart`
- `assets/curriculum/lessons.json`, `assets/curriculum/letters.json` (full ID list extracted), `lib/l10n/app_en.arb` (full key list)
- drift 2.31.0 installed source: `~/.pub-cache/.../select.dart:68` (`Stream watch()`)
- `.planning/phases/06-lesson-progression-home/06-CONTEXT.md`, `06-UI-SPEC.md` (approved), `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `03.1-CONTEXT.md` D-07/D-08
- Test debt locations: `test/screens/home_screen_test.dart:204`, `test/features/practice/mastery_celebration_golden_test.dart:74`, `test/features/practice/practice_screen_test.dart:167,220`

### Secondary (MEDIUM confidence)
- Project memory (MEMORY.md): golden font drift, stale 03.1 nav tests, gen-l10n gitignored, missing flutter-* agents — each corroborated by direct file evidence above where possible.

### Tertiary (LOW confidence / flagged)
- go_router `matchedLocation` excludes query strings (A3) — training knowledge, consistent with the existing gate design; verify with a Wave-0 router test.
- Knowledge graph queried but stale (98h / 71 commits behind, returned no nodes for progression terms) — not relied upon.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new packages; all versions read from pubspec/pub-cache
- Architecture: HIGH — every integration point read directly; patterns mirror established Phase 1–5 precedents
- Pitfalls: HIGH — the two biggest (ID drift, namespace) were discovered by tool-verified diffs, not inference
- Pedagogy-adjacent defaults (A1 rep write-through): MEDIUM — mechanism sound, rule is the owner's mother's

**Research date:** 2026-06-11
**Valid until:** 2026-07-11 (internal codebase; invalidated earlier if Phase 04-06 or other branches change scoring/curriculum files)
