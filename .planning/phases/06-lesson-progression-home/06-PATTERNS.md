# Phase 6: Lesson Progression & Home - Pattern Map

**Mapped:** 2026-06-11
**Files analyzed:** 19 new/modified files
**Analogs found:** 18 / 19 (drift `.watch()` streams have no in-repo analog — see No Analog Found)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/models/lesson_progression.dart` (NEW) | model (pure-Dart domain engine) | transform | `lib/models/journey_progress.dart` | exact |
| `lib/providers/progression_providers.dart` (NEW) | provider | streaming (drift watch → derived) | `lib/providers/profile_providers.dart` | role-match |
| `lib/features/practice/widgets/ghost_comparison.dart` (NEW) | component (animated replay) | transform (path animation) | `lib/features/practice/widgets/stroke_order_animation.dart` | exact |
| `lib/data/app_database.dart` (MOD: v4 + LetterReps + watch) | data/config | CRUD + streaming | itself — `LetterMastery` table + v2→v3 migration | exact |
| `lib/data/progress_repository.dart` (MOD) | data interface | CRUD | itself | exact |
| `lib/data/drift_progress_repository.dart` (MOD) | data impl | CRUD | itself (thin delegation) | exact |
| `lib/screens/home_screen.dart` (MOD: live today-card, ink-fill, prepared desk) | component/screen | request-response (provider read) | own `_GreetingHeader` 3-layer split | exact |
| `lib/features/journey/journey_screen.dart` (MOD: live provider, canonical IDs, highlight) | component/screen | request-response | itself + `mastery_celebration.dart` `_SettlingStar` (D-15 anim) | exact |
| `lib/providers/journey_providers.dart` (MOD: retire mock) | provider | streaming | `mockJourneyProgress` (being replaced) | role-match |
| `lib/features/practice/practice_screen.dart` (MOD: lessonId param) | component/screen | request-response | own family-key wiring | exact |
| `lib/features/practice/widgets/mastery_celebration.dart` (MOD: Next Lesson, tutor line) | component | request-response | own `_BackHomeButton` + ghost-link pattern | exact |
| `lib/providers/practice_providers.dart` (MOD: persisted reps, ramp) | provider (Notifier) | event-driven | own `_loadLetter` async prime + `_recordMastery` | exact |
| `lib/router/app_router.dart` (MOD: query params) | route/config | request-response | own `GoRoute` builders + redirect gate | exact |
| `lib/core/scoring/letter_scorer.dart` (MOD: tolerances override) | utility (pure Dart) | transform | own `scoreLetter` signature | exact |
| `lib/core/scoring/tolerances.dart` (MOD: `preset()` accessor) | utility (pure Dart) | transform | own `_presets` map + `fromJson` | exact |
| `lib/models/lesson.dart` (MOD: toleranceRamp parse) | model | transform | `Tolerances.fromJson` defensive idiom | exact |
| `assets/curriculum/lessons.json` (MOD: 1→28 + ramp) | config (data) | — | existing `lesson_01` entry shape | exact |
| `lib/l10n/app_en.arb` (MOD: new keys) | config | — | existing keys + null-safe access idiom | exact |
| Tests: `test/models/lesson_progression_test.dart`, `test/providers/progression_providers_test.dart`, `test/features/journey/journey_screen_test.dart` (NEW); `test/data/app_database_test.dart`, `test/screens/home_screen_test.dart`, practice tests (MOD) | test | — | `test/data/app_database_test.dart` (RED-contract Wave 0 + migration), `test/models/lesson_test.dart` | exact |

## Pattern Assignments

### `lib/models/lesson_progression.dart` (model, pure-Dart transform)

**Analog:** `lib/models/journey_progress.dart` — the project's canonical pure-Dart domain file.

**File-header + purity pattern** (`journey_progress.dart` lines 1-11):
```dart
// JourneyProgress model + JourneyNodeState enum (Phase 03.1, plan 01).
//
// Pure-Dart file — no Flutter import. Follows the plain-class pattern from
// lib/models/letter.dart (final fields, const constructor, no dart:ui).
```
Rule (enforced by convention): `lib/models/*.dart` must not import from `lib/data/` or `lib/features/` — no Flutter, no dart:ui. The progression engine takes plain inputs (`List<Lesson>`, `Set<String>`, `String startingLessonId`) and returns plain outputs.

**Static-compute pattern** (`journey_progress.dart` lines 27-36) — copy this shape for `lessonPassed` / `lessonUnlocked` / `todayLesson`:
```dart
static JourneyNodeState compute(
  String letterId,
  Set<String> masteredIds,
  String currentId,
) {
  if (letterId.isEmpty) return JourneyNodeState.locked;
  if (masteredIds.contains(letterId)) return JourneyNodeState.complete;
  if (letterId == currentId) return JourneyNodeState.current;
  return JourneyNodeState.future;
}
```

**Immutable snapshot pattern** (`journey_progress.dart` lines 45-56):
```dart
class JourneyProgress {
  final Set<String> masteredIds;
  final String currentId;

  const JourneyProgress({
    required this.masteredIds,
    required this.currentId,
  });

  factory JourneyProgress.empty() =>
      const JourneyProgress(masteredIds: {}, currentId: '');
}
```
The engine's output type should keep `JourneyProgress` compatible (or wrap it) — the journey screen consumes `masteredIds` + `currentId` via `JourneyNodeState.compute` and `progress.masteredIds.length`.

---

### `lib/providers/progression_providers.dart` (provider, streaming)

**Analog:** `lib/providers/profile_providers.dart` — the Phase-5 precedent for hand-written providers around Drift data.

**Hand-written-provider deviation pattern** (`profile_providers.dart` lines 21-29, 45-47) — MUST follow for anything touching Drift row classes (riverpod_generator 4.0.3 `InvalidTypeException`):
```dart
// NOTE (deviation, Rule 3): `childProfileProvider` is a HAND-WRITTEN
// `FutureProvider`, not `@riverpod` codegen. riverpod_generator 4.0.3 throws
// `InvalidTypeException: The type is invalid and cannot be converted to code.`
// when a functional provider's return type is a Drift-generated data class
// ...
final childProfileProvider = FutureProvider<ChildProfile?>(
  (ref) => ref.watch(childProfileRepositoryProvider).getProfile(),
);
```
Streams of raw IDs (`Set<String>`) and the engine's own domain types are NOT Drift classes — codegen is safe for those; hand-write only where a Drift row type appears in the provider's type.

**Imports pattern** (`profile_providers.dart` lines 31-38):
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/app_database.dart';
import '../data/child_profile_repository.dart';

part 'profile_providers.g.dart';
```

**Anti-pattern to avoid** (`journey_providers.dart` lines 23-29): `mockJourneyProgress` is `@Riverpod(keepAlive: true)` returning a static value. A LIVE progression provider must NOT be keepAlive (stale "today" after a pass — RESEARCH Pitfall 4). Use `StreamProvider` (auto-updating) or autoDispose codegen. The mock's doc comment already promises this swap: "Phase 6 swaps this provider for a live ProgressRepository integration; the screen itself does not change — only this provider."

---

### `lib/data/app_database.dart` (data, CRUD + streaming) — schema v4

**Analog:** itself — copy the `LetterMastery`/`ChildProfiles` shapes exactly.

**Table-definition pattern with security comment** (lines 30-42):
```dart
/// Per-letter mastery record — Phase 3 (D-09, Plan 03-02).
///
/// SECURITY (T-03-01/T-01-05): only letterId, cleanReps, and masteredAt are
/// stored. Captured stroke points are NEVER persisted here or anywhere else —
/// they stay in-memory only and are discarded on dispose.
class LetterMastery extends Table {
  TextColumn get letterId => text()();
  IntColumn get cleanReps => integer()();
  DateTimeColumn get masteredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {letterId};
}
```
The new `LetterReps` table copies this exactly: `letterId` PK + int count + timestamp, same SECURITY header (only letterId/count/timestamp — never coordinates).

**Idempotent migration pattern** (lines 74-85) — extend, don't restructure:
```dart
@override
int get schemaVersion => 3;   // → bump to 4

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        // Pitfall 4: guard by version to make the migration idempotent.
        if (from < 2) await m.createTable(letterMastery);
        if (from < 3) await m.createTable(childProfiles);
        // v4 adds: if (from < 4) { createTable(letterReps); + the
        // startingLessonId 'alif' → 'lesson_01' customStatement rewrite }
      },
    );
```
Check generated snake_case table/column names against `app_database.g.dart` before writing the `customStatement` SQL.

**Accessor pattern** (lines 115-139) — new rep accessors mirror this insertOnConflictUpdate/getSingleOrNull shape:
```dart
Future<void> recordMastery({
  required String letterId,
  required int cleanReps,
}) =>
    into(letterMastery).insertOnConflictUpdate(
      LetterMasteryCompanion.insert(
        letterId: letterId,
        cleanReps: cleanReps,
        masteredAt: DateTime.now(),
      ),
    );

Future<bool> isMastered(String letterId) async =>
    (await (select(letterMastery)
              ..where((t) => t.letterId.equals(letterId)))
            .getSingleOrNull()) !=
    null;
```
New watch method (no in-repo analog — see No Analog Found): `select(letterMastery).watch().map((rows) => rows.map((r) => r.letterId).toSet())` per RESEARCH Pattern 1.

---

### `lib/data/progress_repository.dart` + `drift_progress_repository.dart` (data, CRUD)

**Analog:** themselves — extend the interface + thin delegation, keep the security framing.

**Interface pattern** (`progress_repository.dart` lines 11-23):
```dart
abstract interface class ProgressRepository {
  /// SECURITY: only [letterId] and [cleanReps] are persisted — never stroke
  /// points (T-03-01/T-01-05).
  Future<void> recordMastery({
    required String letterId,
    required int cleanReps,
  });

  Future<bool> isMastered(String letterId);
}
```

**Thin-delegation + provider pattern** (`drift_progress_repository.dart` lines 18-37):
```dart
class DriftProgressRepository implements ProgressRepository {
  const DriftProgressRepository(this._db);
  final AppDatabase _db;

  @override
  Future<void> recordMastery({...}) =>
      _db.recordMastery(letterId: letterId, cleanReps: cleanReps);
  ...
}

@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) =>
    DriftProgressRepository(ref.watch(appDatabaseProvider));
```
All SQL stays in `AppDatabase`; the repository never composes queries. New methods (rep read/write/reset, watch streams) follow the same one-line delegation.

---

### `lib/screens/home_screen.dart` (screen) — live today-card, ink-fill, prepared desk

**Analog:** own `_GreetingHeader` three-layer split — this IS the prescribed pattern for making `_TodaysLessonCard` live.

**Scope-aware split pattern** (lines 238-300). Layer 1 — scope guard (lines 244-257):
```dart
@override
Widget build(BuildContext context) {
  final bool hasScope =
      context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() !=
          null;
  if (!hasScope) {
    // No-scope fallback (bare harness): static greeting, no avatar.
    return _GreetingLayout(l10n: l10n, avatarId: null, nicknameLabel: null);
  }
  return _GreetingHeaderReader(l10n: l10n);
}
```
Layer 2 — `ConsumerWidget` reader with full `.when` degradation (lines 271-298):
```dart
return ref.watch(childProfileProvider).when(
      data: (ChildProfile? profile) {
        if (profile == null) {
          return _GreetingLayout(l10n: l10n, avatarId: null, nicknameLabel: null);
        }
        return _GreetingLayout(
          l10n: l10n,
          avatarId: profile.avatarId,
          nicknameLabel: resolveNicknameLabel(profile.nicknameId),
        );
      },
      loading: () => _GreetingLayout(l10n: l10n, avatarId: null, nicknameLabel: null),
      error: (_, _) => _GreetingLayout(l10n: l10n, avatarId: null, nicknameLabel: null),
    );
```
Layer 3 — pure presentation layout taking nullable params. Apply the same split to `_TodaysLessonCard`: guard → reader (watches the today-lesson provider) → pure layout (letter glyph, title, ink-fill opacity, all-mastered variant). Loading/error degrade per UI-SPEC: empty glyph container / fall back to `startingLessonId`, never a raw error.

**Existing card layout to keep** (lines 429-457) — D-08 says keep the layout, swap the data:
```dart
return GestureDetector(
  key: const Key('todaysLessonCard'),
  onTap: () => context.go('/practice'),   // → '/practice?lesson=$todayLessonId'
  ...
  child: Row(
    children: <Widget>[
      Container(
        width: QalamSpace.space16,
        height: QalamSpace.space16,
        decoration: BoxDecoration(
          color: QalamColors.primaryTint,
          borderRadius: BorderRadius.circular(QalamRadii.lg),
        ),
        alignment: Alignment.center,
        child: const ArabicText('ا', display: true),  // → live glyph + ink-fill color
      ),
      ...
```
Ink-fill = the glyph's text color at `QalamColors.inkStroke.withValues(alpha: 0.25 + 0.75 * t)` (UI-SPEC prescriptive). Prepared-desk entrance: copy the AnimationController recipe from `mastery_celebration.dart` (below) with `QalamMotion.easeOutQuart`/`durSlow`, plus `MediaQuery.of(context).disableAnimations` short-circuit.

---

### `lib/features/journey/journey_screen.dart` (screen) — live data + canonical IDs + highlight

**Analog:** itself (provider swap point) + `mastery_celebration.dart` `_SettlingStar` for the D-15 arrival animation.

**Provider swap point** (lines 108-113) — one line changes:
```dart
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});   // gains: this.highlightId

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(mockJourneyProgressProvider);  // → live provider
```

**MANDATORY data fix** (lines 37-66): `_kLetters` hardcodes 28 IDs of which 19 diverge from `letters.json` canonical IDs (`haa`→`haa_c`, `dal`→`daal`, `dhal`→`dhaal`, `ra`→`raa`, `zay`→`zaay`, `tah`→`taa_h`, `dhah`→`zhaa`, `ain`→`ayn`, `ghain`→`ghayn`, `fa`→`faa`, `qaf`→`qaaf`, `kaf`→`kaaf`, `lam`→`laam`, `ha`→`haa_f`, `waw`→`waaw`, `ya`→`yaa`). Live mastered IDs will never light those nodes. Reconcile to canonical IDs (or derive from `CurriculumRepository.getLetters()`).

**Node tap pattern to extend** (lines 309-321) — add `JourneyNodeState.future`-but-unlocked (D-07 skipped letters) and pass the lesson param:
```dart
return Positioned(
  left: pos.dx - 34,
  top: pos.dy - 34,
  child: JourneyNodeWidget(
    glyph: letter.glyph,
    name: letter.name,
    state: state,
    onTap: (state == JourneyNodeState.complete ||
            state == JourneyNodeState.current)
        ? () => context.go('/practice')   // → '/practice?lesson=$lessonId'
        : null,
  ),
);
```

**D-15 highlight-arrival animation** — copy the settling-star recipe from `mastery_celebration.dart` lines 56-79 (same tokens UI-SPEC binds: `easeSoftBack`, `durCheer`):
```dart
_starController = AnimationController(
  vsync: this,
  duration: QalamMotion.durCheer, // 700ms — gentle, never slapstick
);
_starScale = Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(parent: _starController, curve: QalamMotion.easeSoftBack),
);
_starOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(
    parent: _starController,
    curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
  ),
);
_starController.forward();   // one-shot on appear
```

---

### `lib/router/app_router.dart` (route) — query parameterization

**Analog:** own `GoRoute` builders + the synchronous redirect gate that must NOT break.

**Redirect gate — do not disturb** (lines 41-50). It compares `state.matchedLocation` (path only), so query params are safe:
```dart
// SYNCHRONOUS redirect — NEVER await Drift here (Pitfall 2). ...
redirect: (context, state) {
  if (kDemoMode) return null;
  final onOnboarding = state.matchedLocation == '/onboarding';
  if (!gate.hasProfile && !onOnboarding) return '/onboarding';
  if (gate.hasProfile && onOnboarding) return '/';
  return null;
},
```

**Route builder pattern to parameterize** (lines 62-72). Note: hand-written `GoRoute` builders, NOT go_router codegen (only the *provider* is codegen):
```dart
GoRoute(
  path: '/practice',
  builder: (context, state) => const PracticeScreen(),
),
// becomes (RESEARCH Pattern 3):
GoRoute(
  path: '/practice',
  builder: (context, state) {
    final lessonId = state.uri.queryParameters['lesson'];
    return PracticeScreen(
      key: ValueKey(lessonId),  // fresh State per lesson — Pitfall 5
      lessonId: lessonId,        // null/invalid → degrade to today's lesson
    );
  },
),
```
Validate `?lesson=`/`?highlight=` against loaded curriculum IDs (allowlist); unknown → degrade silently (V5 input validation, never a raw error to the child).

---

### `lib/features/practice/practice_screen.dart` (screen) — lessonId parameterization

**Analog:** own family-key wiring — every `PracticeScreen._lessonId` reference becomes the instance field.

**Current hardwiring** (lines 57-65):
```dart
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  /// The lesson this screen teaches. Hardwired to lesson_01 (alif) for Phase 3.
  static const String _lessonId = 'lesson_01';
```

**Family-key consumption pattern** (lines 124-133) — the controller is already family-keyed; only the key source changes:
```dart
final state = ref.watch(
  practiceSessionControllerProvider(PracticeScreen._lessonId),
);

if (state.phase == PracticePhase.celebrate) {
  return MasteryCelebration(
    onBackHome: () => context.go('/'),
    // gains: letter glyph/name, onNextLesson, isLastLesson (D-14/16/17)
  );
}
```

**In-memory stroke seam for the ghost comparison** (lines 88-116) — strokes exist here and are currently discarded after scoring; retain the last FAILING letter's strokes in widget State only:
```dart
Future<void> _onLetterComplete(
  List<List<Offset>> strokes,
  Letter letter,
) async {
  // Convert Offsets → List<List<List<double>>> for the pure-Dart scorer.
  final childStrokes = strokes
      .map((List<Offset> stroke) => stroke
          .map((Offset o) => <double>[o.dx, o.dy])
          .toList(growable: false))
      .toList(growable: false);
  ...
  final LetterResult result = await scoreLetter(childStrokes, letter,
      recognizer: recognizer);
  // Only the LetterResult (not raw points) enters the controller.
```

**Ghost trigger placement** — `_ActionRow` showFix case (lines 970-990): "Watch the Difference" ghost button sits beside `Show Me Again`, reusing the existing `_GhostButton`/`_PrimaryButton` widgets:
```dart
case PracticePhase.showFix:
  return Container(
    constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
    alignment: Alignment.centerRight,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _GhostButton(label: showMeAgain, onPressed: onCast),
        const SizedBox(width: QalamSpace.space4),
        _PrimaryButton(label: tryAgain, onPressed: onRetry),
      ],
    ),
  );
```

---

### `lib/features/practice/widgets/ghost_comparison.dart` (NEW component)

**Analog:** `lib/features/practice/widgets/stroke_order_animation.dart` — the battle-tested path-replay machinery. Parameterize rather than fork.

**Controller + replay pattern** (lines 49-77) — same shape, but `duration` and ink `color` become widget params (child stroke: `QalamColors.warnSoft`, `durWrite × 2` = 2800ms, `Curves.linear`):
```dart
class StrokeOrderAnimationState extends State<StrokeOrderAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: QalamMotion.durWrite, // ← parameterize for half-speed
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
    _controller.forward();
  }

  void replay() => _controller.forward(from: 0);
```

**Progressive-reveal painter pattern** (lines 122-162) — `ReferencePath.resolve` → scaled `Path` → `PathMetric.extractPath(0, length * t)`; ink paint at line 145-151 is where the color param lands:
```dart
final Paint inkPaint = Paint()
  ..color = QalamColors.inkStroke        // ← parameterize (coral for child stroke)
  ..style = PaintingStyle.stroke
  ..strokeWidth = QalamInk.strokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;
```

**Normalization to reuse, not re-derive** (`lib/dev/authoring_export.dart`, `normalizeToStrokeSpecs` ~line 90) — combined-bbox normalization of all strokes together (the dot-position pitfall is already solved here). Extract/share this logic for converting the child's in-memory `List<List<Offset>>` into 0..1 `StrokeSpec`s:
```dart
List<StrokeSpec> normalizeToStrokeSpecs(List<CapturedStroke> strokes) {
  if (strokes.isEmpty) return const <StrokeSpec>[];
  final b = _combinedBounds(strokes);
  final ordered = [...strokes]..sort((a, c) => a.order.compareTo(c.order));
  return ordered.map((s) {
    final points = s.points
        .map((p) => <double>[
              _round(_norm(p[0], b.minX, b.width)),
              _round(_norm(p[1], b.minY, b.height)),
            ])
        .toList();
    ...
```
T-03-01: strokes live in widget State only — never in providers (grep guard: `List<Offset>` count in `practice_providers.dart` must stay 0), never in the DB.

---

### `lib/features/practice/widgets/mastery_celebration.dart` (component) — D-14/16/17

**Analog:** itself — copy its own button treatments; the widget gains params instead of new patterns.

**Widget-param + l10n pattern** (lines 35-46, 89-94) — gains `letter` (glyph + name), `onNextLesson`, `isLastLesson`:
```dart
class MasteryCelebration extends StatefulWidget {
  const MasteryCelebration({
    super.key,
    required this.onBackHome,
  });
  final VoidCallback onBackHome;
  ...
  final celebLine = l10n?.practiceCelebrationLine ?? 'You learned alif.';
```
Pitfall 6: `practiceCelebrationLine` and `_MasteredGlyph`'s hardcoded `'ا'` (lines 266-277) must template on the mastered letter — lessons 2-28 otherwise celebrate alif.

**Primary CTA pattern** (lines 366-397, `_BackHomeButton`) — "Next Lesson" copies this exactly (filled teal, `targetComfy`, button shadow); "Back Home" demotes to the ghost treatment below:
```dart
return DecoratedBox(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(QalamRadii.lg),
    boxShadow: QalamShadows.buttonShadow,
  ),
  child: Material(
    color: QalamColors.primary,
    borderRadius: BorderRadius.circular(QalamRadii.lg),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: QalamTargets.targetComfy),
        ...
        child: Text(label,
            style: QalamTextStyles.button.copyWith(color: QalamColors.fgOnPrimary)),
```

**Ghost/tertiary link pattern** (lines 158-175) — "See journey" already exists; navigates `/journey` → gains `?highlight={masteredId}`:
```dart
ConstrainedBox(
  constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
  child: TextButton(
    onPressed: () => context.go('/journey'),
    style: TextButton.styleFrom(
      foregroundColor: QalamColors.fgMuted,
      backgroundColor: Colors.transparent,
    ),
    child: Text(l10n?.journeySeeJourney ?? 'See journey', ...),
```
D-17 tutor line: one new `Text` at body scale under the Arabic praise — `l10n?.celebrationShowSomeone(letterName) ?? 'Go show your $letterName to someone at home.'`.

---

### `lib/providers/practice_providers.dart` (Notifier) — persisted reps + tolerance ramp

**Analog:** itself — two of its own patterns extend cleanly.

**Async-prime pattern** (lines 93-103) — seeding `cleanReps` from `LetterReps` (D-20) copies `_loadLetter`'s prime-then-update shape:
```dart
@override
PracticeState build(String lessonId) {
  // We prime state immediately with defaults and update after the async load.
  _loadLetter(lessonId);
  return const PracticeState(
    phase: PracticePhase.watch,
    cleanReps: 0,
    cleanRepsToAdvance: 3, // sensible default; overwritten by _loadLetter
  );
}
```

**Best-effort write pattern** (lines 160-181) — per-rep persistence writes (including reset-to-0 on a miss, Pitfall 7 write-through) follow `_recordMastery`'s try/swallow:
```dart
Future<void> _registerCleanRep() async {
  final newReps = state.cleanReps + 1;
  if (newReps >= state.cleanRepsToAdvance) {
    // DB write is best-effort: a storage failure must not block the celebration.
    try {
      await _recordMastery(newReps);
    } catch (_) {
      // Swallow — celebrate regardless.
    }
    state = state.copyWith(cleanReps: newReps, phase: PracticePhase.celebrate);
  } else {
    state = state.copyWith(cleanReps: newReps, phase: PracticePhase.showPraise);
  }
}
```

**Anti-Pattern 3 guard** (file header lines 5-9) — preserve verbatim; the ramp/rep changes must not introduce `List<Offset>`:
```dart
// ANTI-PATTERN 3 GUARD: this controller NEVER holds List<Offset> live stroke
// points. ... grep for "List<Offset>" in this file must return 0.
```

---

### `lib/core/scoring/letter_scorer.dart` + `tolerances.dart` (utility) — ramp override

**Analog:** own `scoreLetter` signature + `Tolerances` preset machinery.

**Current signature + internal resolution** (`letter_scorer.dart` lines 54-61) — add an optional `Tolerances? tolerances` param, default preserves Phase-4 behavior:
```dart
Future<LetterResult> scoreLetter(
  List<List<List<double>>> childStrokes,
  Letter letter, {
  HandwritingRecognizer? recognizer,
}) async {
  final reference = [...letter.referenceStrokes]
    ..sort((a, b) => a.order.compareTo(b.order));
  final tolerances = letter.tolerances ?? Tolerances.normal;
  // → final tolerances = override ?? letter.tolerances ?? Tolerances.normal;
```

**Preset lookup + defensive fallback** (`tolerances.dart` lines 44-79) — `_presets` is private; expose `static Tolerances preset(String name) => _presets[name] ?? normal;` mirroring the existing `fromJson` idiom:
```dart
static const Map<String, Tolerances> _presets = {
  'loose':  Tolerances(minRawPoints: 10, resampleN: 32, maxCurvature: 0.35),
  'normal': Tolerances(minRawPoints: 10, resampleN: 32, maxCurvature: 0.25),
  'strict': Tolerances(minRawPoints: 10, resampleN: 32, maxCurvature: 0.18),
};
...
factory Tolerances.fromJson(Map<String, dynamic> json) {
  final presetName = json['preset'] as String?;
  final base = _presets[presetName] ?? normal;   // unknown → normal, never throws
```

---

### `lib/models/lesson.dart` (model) — toleranceRamp parse

**Analog:** own `LessonUnlock.fromJson` (lines 26-32) + the `Tolerances.fromJson` defensive idiom — optional list, default on absence, never throw:
```dart
factory LessonUnlock.fromJson(Map<String, dynamic> json) {
  final raw = json['requires'] as List<dynamic>? ?? [];
  return LessonUnlock(
    requires: raw.map((r) => r as String).toList(),
    passRule: json['passRule'] as String,
  );
}
```
`toleranceRamp` parses the same way: `json['toleranceRamp'] as List<dynamic>? ?? null` → `List<String>?`, with the file-level `defaultToleranceRamp` read in `CurriculumRepository`.

---

### `assets/curriculum/lessons.json` (config data) — 1 → 28 lessons

**Analog:** the existing `lesson_01` entry, parsed by `CurriculumRepository._ensureLoaded` (`curriculum_repository.dart` lines 64-69):
```dart
final lessonsDecoded =
    (json.decode(lessonsRaw) as Map<String, dynamic>)['lessons']
        as List<dynamic>;
_lessons = lessonsDecoded
    .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
    .toList();
```
Entry shape (RESEARCH, matching `Lesson.fromJson`):
```json
{ "id": "lesson_02", "order": 2, "title": { "display": "Lesson 2 — Baa" },
  "items": [{ "type": "letter", "ref": "baa" }],
  "unlock": { "requires": ["lesson_01"], "passRule": "allItemsPassed" } }
```
CRITICAL: `items[].ref` must use canonical `letters.json` IDs (`haa_c`, `daal`, `dhaal`, `raa`, `zaay`, `taa_h`, `zhaa`, `ayn`, `ghayn`, `faa`, `qaaf`, `kaaf`, `laam`, `haa_f`, `waaw`, `yaa`). Refs are NOT validated at load (Pitfall 10) — add a test asserting every ref/requires resolves.

---

### Tests (new + reconciled)

**Analog:** `test/data/app_database_test.dart` — the Wave-0 RED-contract + migration-survival pattern.

**Drift test imports** (lines 12-18) — mandatory in any test mixing flutter_test matchers with Drift:
```dart
// Hide the Drift query-builder matchers that collide with flutter_test's
// `isNull`/`isNotNull` expectation matchers (used by the v2→v3 migration test).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
```

**Simulated-restart pattern** (lines 23-37) — the v3→v4 migration test copies this shape (write v3-era rows, insert into the v4 table, restart, assert all survive + the `startingLessonId` rewrite happened):
```dart
final shared = DatabaseConnection(NativeDatabase.memory());

final db1 = AppDatabase(shared.executor);
await db1.setSetting('last_letter', 'baa');
expect(await db1.getSetting('last_letter'), 'baa');
await db1.close();

// "Restart": a fresh AppDatabase over the same underlying store.
final db2 = AppDatabase(shared.executor);
expect(await db2.getSetting('last_letter'), 'baa');
await db2.close();
```

**Wave-0 RED-contract header pattern** (lines 1-5) — new Wave-0 tests (`lesson_progression_test.dart`, `progression_providers_test.dart`, `journey_screen_test.dart`) carry this header:
```dart
// Wave-0 validation scaffold — D-09 (Drift persistence survives a restart).
//
// INTENTIONALLY RED at Wave 0: imports package:qalam/data/app_database.dart,
// which does not yet exist. ... Do NOT add a lib/ stub here.
```

**Pure-model test pattern:** `test/models/lesson_test.dart` (inline JSON map → fromJson → field asserts) is the analog for `lesson_progression_test.dart` (plain inputs → engine functions → asserts; no Flutter binding needed).

**Reconciliation list (rewrite, don't regress against):** `test/screens/home_screen_test.dart:204` (asserts Journey is "Coming soon" — stale since 03.1), `test/features/practice/mastery_celebration_golden_test.dart:74` and `test/features/practice/practice_screen_test.dart:167,220` (assert NO "See journey" button — triply stale after D-14). Golden font drift (`glyph_audit`, `mastery_celebration`) is environmental — do not re-bake for drift; the celebration golden DOES need one deliberate re-bake for the legitimate D-14/D-17 layout change.

## Shared Patterns

### Null-safe l10n access
**Source:** used everywhere — e.g. `home_screen.dart:464`, `mastery_celebration.dart:91-94`
**Apply to:** every new user-facing string (all surfaces this phase)
```dart
final l10n = AppLocalizations.of(context);
Text(l10n?.homeLessonEyebrow ?? 'TODAY\'S LESSON', style: QalamTextStyles.label)
```
New keys go in `lib/l10n/app_en.arb`; run `flutter gen-l10n` after ARB edits (generated files are gitignored — builds/tests fail with missing getters otherwise).

### Provider lifetime rules
**Source:** `app_database.dart:185-190`, `curriculum_repository.dart:117-120`, `profile_providers.dart:45-47`
**Apply to:** all new providers
```dart
// Repositories/DB: codegen + keepAlive
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) { ... }

// Drift row types in the provider's type: HAND-WRITTEN (riverpod_generator 4.0.3 bug)
final childProfileProvider = FutureProvider<ChildProfile?>(
  (ref) => ref.watch(childProfileRepositoryProvider).getProfile(),
);
```
Live progression state: NEVER keepAlive (stale "today" — Pitfall 4); StreamProvider or autoDispose.

### Design tokens only — never raw values
**Source:** every widget file; tokens in `lib/theme/` (`QalamColors`, `QalamSpace`, `QalamTargets`, `QalamRadii`, `QalamShadows`, `QalamMotion`, `QalamInk`, `QalamFonts`, `QalamTextStyles`)
**Apply to:** Home card, journey highlight, celebration buttons, ghost comparison
Color contracts (UI-SPEC, binding): gold (`QalamColors.reward`) = rewards only (stars); ink-fill = `inkStroke` opacity ramp, NOT gold; child's wobbly stroke = `warnSoft` coral, never red; teal = the single primary CTA per screen.

### Graceful asset/data degradation
**Source:** `home_screen.dart:216-225` (`_SafeSvgIcon` placeholderBuilder), `mastery_celebration.dart:227-244` (`_MascotCheer` try/catch), `curriculum_repository.dart:102-114` (`getExercises` returns empty, never throws)
**Apply to:** today-card loading/error states, route-param validation, lessons.json edge cases
Never show a raw error to the child; always degrade to a working default.

### SECURITY comment convention (T-03-01 / child data)
**Source:** table + repository + controller headers (`app_database.dart:30-34`, `progress_repository.dart:1-5`, `practice_providers.dart:5-12`)
**Apply to:** `LetterReps` table, rep repository methods, ghost-comparison widget
Every persistence surface states explicitly what is stored and that stroke points never are. The ghost comparison retains strokes in widget State only.

### RTL islands via ArabicText
**Source:** `home_screen.dart:388-391, 456`, `mastery_celebration.dart:139-145, 266-277`
**Apply to:** live today-card glyph, celebration glyph parameterization
```dart
const ArabicText('ا', display: true)   // display: true → Cairo 96px arDisplay role
```
App chrome stays LTR; Arabic only inside `ArabicText` islands; never bold/italic/letterSpacing on Arabic.

## No Analog Found

Files/patterns with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File / Pattern | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| drift `.watch()` → `StreamProvider` (in `app_database.dart` + `progression_providers.dart`) | data → state | streaming | Zero existing `.watch()` or `StreamProvider` usage anywhere in `lib/` (verified by grep). All current reads are one-shot Futures. Use RESEARCH.md Pattern 1 (`select(letterMastery).watch().map(...)` → hand-written `StreamProvider<Set<String>>`); drift 2.31.0 `.watch()` verified in installed source. First stream test in `progression_providers_test.dart` is also precedent-setting — model on Riverpod container tests with `ProviderContainer` + injected in-memory `AppDatabase`. |

## Metadata

**Analog search scope:** `lib/models/`, `lib/providers/`, `lib/data/`, `lib/screens/`, `lib/features/journey/`, `lib/features/practice/`, `lib/core/scoring/`, `lib/router/`, `lib/dev/`, `test/data/`, `test/models/`, `test/screens/`
**Files scanned:** 22 read in full or targeted (4,100+ lines), plus grep sweeps for `.watch()`/`StreamProvider`/`_ActionRow`/`_lessonId`
**Pattern extraction date:** 2026-06-11
