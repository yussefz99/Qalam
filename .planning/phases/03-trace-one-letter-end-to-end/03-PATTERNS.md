# Phase 3: Trace One Letter End-to-End - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 19 (new/modified)
**Analogs found:** 18 / 19 (1 cross-cutting interface seam has no in-repo analog)

> Planner note: every new file has a strong existing analog in this codebase. Phase 3 is
> almost entirely "extend a proven P1/P2 pattern," not greenfield. The two genuinely
> novel pieces are the **pure-Dart geometric scorer** (analog: `stroke_validation.dart`,
> same shape — pure Dart, named checks, tuned-threshold constants, returns a result list)
> and the **`HandwritingRecognizer` interface seam** (no analog; deliberately empty per
> D-16). Reuse, do not reinvent: the `Listener`+`_InkPainter` capture, the
> `ReferencePath.resolve` one-source-of-truth, the Drift injected-executor persistence,
> the `@Riverpod(keepAlive)` provider style, the `QalamColors`/`QalamSpace`/`QalamTextStyles`
> token discipline, and the gen-l10n copy rule are all already established and tested.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/core/scoring/geometric_stroke_scorer.dart` (new) | service (domain, pure Dart) | transform | `lib/core/scoring/stroke_validation.dart` | exact (pure-Dart checks + tuned thresholds + result list) |
| `lib/core/scoring/stroke_resampler.dart` (new) | utility (pure Dart) | transform | `lib/dev/authoring_export.dart` (normalize-to-unit-box) + `stroke_validation.dart` (math helpers) | role-match |
| `lib/core/scoring/scoring_models.dart` (new) | model (pure Dart) | — | `lib/models/letter.dart` (`StrokeSpec`/`CommonMistake` plain classes) | role-match |
| `lib/core/scoring/reference_path.dart` (MODIFY/reuse as-is) | utility (pure Dart) | transform | itself — already exists (`ReferencePath.resolve`) | exact (already built; consume it) |
| `lib/core/recognition/handwriting_recognizer.dart` (new) | service interface (seam) | request-response | — | **no analog** (empty seam, D-16) |
| `lib/data/app_database.dart` (MODIFY) | data / migration | CRUD | itself (schemaVersion 1→2 + migration) | exact |
| `lib/data/progress_repository.dart` (new) | repository interface | CRUD | `lib/data/curriculum_repository.dart` (repo class + provider) | exact |
| `lib/data/drift_progress_repository.dart` (new, or fold into repo) | repository impl | CRUD | `lib/data/app_database.dart` (`setSetting`/`getSetting` Drift access) | exact |
| `lib/features/practice/practice_screen.dart` (new, supersedes P1 spike) | screen (state machine) | event-driven | `lib/screens/home_screen.dart` (Scaffold + token layout + Consumer) + P1 `practice_screen.dart` | role-match |
| `lib/features/practice/widgets/stroke_canvas.dart` (new) | widget (capture) | streaming (pointer) | `lib/screens/practice_screen.dart` `_InkSurface`+`_InkPainter` / `authoring_screen.dart` `_CaptureSurface` | exact |
| `lib/features/practice/widgets/stroke_order_animation.dart` (new) | widget (CustomPainter + AnimationController) | event-driven | `_InkPainter` (CustomPainter) + `ReferencePath.resolve` consumer | role-match |
| `lib/features/practice/widgets/feedback_panel.dart` (new) | widget (presentation) | request-response | `home_screen.dart` `_PlaceholderCard` (token card + l10n copy) | role-match |
| `lib/features/practice/widgets/mastery_celebration.dart` (new) | widget (full-screen) | event-driven | `home_screen.dart` (Scaffold + `ArabicText` island + SVG + tokens) | role-match |
| `lib/providers/practice_providers.dart` (new) | provider (Riverpod Notifier) | event-driven | `lib/data/app_database.dart` / `curriculum_repository.dart` (`@Riverpod` providers) | role-match |
| `lib/config/debug_flags.dart` (new) | config | — | `lib/theme/dimens.dart` (`abstract final class` of const tokens) | role-match |
| `lib/router/app_router.dart` (MODIFY) | route | — | itself (add `/practice` real route / dev route) | exact |
| `lib/l10n/app_localizations*.dart` + `.arb` (MODIFY) | config (copy) | — | existing l10n getters (`writeHere`, `clearConfirmHeading`) | exact |
| `test/core/scoring/geometric_stroke_scorer_test.dart` (new) | test (unit) | — | `test/core/scoring/reference_path_test.dart` + `stroke_spec_validation_test.dart` | exact |
| `test/features/practice/stroke_canvas_test.dart` (new) | test (widget) | — | `test/features/authoring/authoring_screen_test.dart` (`startGesture`/`moveTo`/`up`) | exact |
| `test/data/progress_repository_test.dart` (new) | test (integration) | — | `test/data/app_database_test.dart` (shared in-memory executor restart) | exact |

---

## Pattern Assignments

### `lib/core/scoring/geometric_stroke_scorer.dart` (service, transform) — THE CROWN JEWEL

**Analog:** `lib/core/scoring/stroke_validation.dart` (same directory, same shape: pure
Dart, no Flutter import, named checks, tuned-threshold constants in one place, returns a
result). The scorer is structurally a sibling of the validator.

**Imports pattern** (from `stroke_validation.dart` lines 1-3) — pure Dart only, `math`
for geometry, the model for `StrokeSpec`:
```dart
import 'dart:math' as math;
import '../../models/letter.dart';
```
> Add `package:vector_math/vector_math.dart` (`Vector2`) for dot-product/projection if
> needed — it is already a transitive dep (RESEARCH §Standard Stack). NO `dart:ui`, NO
> Flutter.

**Tuned-threshold-constants pattern** (from `stroke_validation.dart` lines 23-43) — every
magic number lives in ONE documented place at the top of the file, with a doc comment
explaining the value (Phase 4 calibrates these; ship lenient per D-15):
```dart
// --- Tuned thresholds (documented; this is the ONLY place they live) ----------
/// Endpoint-coincidence epsilon. ... Chosen generously (0.30) because ...
const double kClosedLoopEpsilon = 0.30;
```

**Named-check pattern** (from `stroke_validation.dart` lines 83-209) — one predicate per
authored `commonMistakes[].check`. The scorer's predicate names MUST equal the `check`
strings (the data↔code contract per `letter.dart` line 75 and UI-SPEC feedback table):
`strokeLengthBelowThreshold`, `strokeDirectionInverted`, `strokeCurvatureExceedsThreshold`.
The validator's existing direction logic is the literal template for `strokeDirectionInverted`:
```dart
// stroke_validation.dart lines 163-175 — first→last delta + direction sign:
final dx = last[0] - first[0];
final dy = last[1] - first[1];
switch (stroke.direction) {
  case 'topToBottom':
    if (!(dy > 0)) { violations.add('... disagrees ...'); }
```
Reuse `_distance`, `_polylineLength`, `_bboxDiagonal` (lines 53-79) verbatim as private
helpers; the straightness check = max perpendicular distance from the best-fit line.

**Result-shape pattern** (from `stroke_validation.dart` line 83 `List<String> validateStroke`)
— return a typed `StrokeResult{passed, mistakeId?}` (defined in `scoring_models.dart`) the
same way the validator returns its violation list: a single pure function over inputs, no
side effects, deterministic.

---

### `lib/core/scoring/scoring_models.dart` (model, pure Dart)

**Analog:** `lib/models/letter.dart` — plain Dart classes, no Flutter, `factory.fromJson`
where parsing is needed (not needed here — these are produced in-memory).

**Pattern** (from `letter.dart` lines 73-89, `CommonMistake`) — small immutable class with
`final` fields and a `const` constructor; an enum for `MistakeId` mirroring the three
authored `commonMistakes[].id` (`too_short` / `wrong_direction` / `too_curved`) plus a
`fallback`. Keep it pure — no `dart:ui`, no Flutter.

---

### `lib/core/scoring/stroke_resampler.dart` (utility, transform)

**Analog:** `lib/dev/authoring_export.dart` (`normalizeToStrokeSpecs` — combined-bbox
normalize to 0..1, proven in `test/features/authoring/authoring_screen_test.dart` lines
20-50). Reuse its translate-min→0 / scale-max→1 approach for `normalizeToUnitBox`, then
add arc-length equidistant `resample(pts, n)`.

**Why this analog:** the authoring export already normalizes captured pixel strokes into
the exact 0..1 space the scorer compares in — the child-stroke normalizer is the same
operation applied at score time. Test invariance the same way: "small correct stroke still
passes" (RESEARCH Test Map S1-05).

---

### `lib/core/scoring/reference_path.dart` (utility) — ALREADY EXISTS, CONSUME AS-IS

**Analog:** itself. `ReferencePath.resolve(List<StrokeSpec>)` (lines 38-44) is already the
single source of truth (S1-04) and already supersedes RESEARCH Q1 (its doc comment lines
16-27 explicitly abandons the derive-from-outline path — Phase 02.1 re-authored alif as a
true centerline, gated by `stroke_validation.dart`).

> Planner: do NOT re-resolve or re-derive. The scorer AND the animation both call this one
> function. For the animation, wrap the returned `List<List<List<double>>>` into a
> `dart:ui` `Path` for `PathMetric` (that UI concern stays OUT of this pure layer — see the
> file's closing doc note, lines 26-27). Q1 is closed.

---

### `lib/core/recognition/handwriting_recognizer.dart` (service interface) — EMPTY SEAM

**Analog:** none in-repo. Define an `abstract interface class HandwritingRecognizer` with
the method signature the Phase-4 ML Kit impl will satisfy — but NO implementation, NO ML
Kit import, NO network (D-16, RESEARCH Security §"empty interface ... makes no calls").
Follow the repository-interface convention used for `ProgressRepository` (interface + later
impl), and the dartdoc `///` style from `reference_path.dart`. Leave a `// Phase 4:` marker
exactly like the `/parent` seam comment in `app_router.dart` lines 51-60.

---

### `lib/data/app_database.dart` (MODIFY — schema migration)

**Analog:** itself. Add a `LetterMastery` table beside `AppSettings`, bump `schemaVersion`,
add an `onUpgrade` migration. The existing injected-executor `close()` contract (lines
39-54) MUST be preserved — the restart test depends on it.

**Table pattern** (from lines 22-28, `AppSettings`):
```dart
class LetterMastery extends Table {
  TextColumn get letterId => text()();        // "alif"
  IntColumn get cleanReps => integer()();     // 3
  DateTimeColumn get masteredAt => dateTime()();
  @override
  Set<Column> get primaryKey => {letterId};
}
```

**Schema/migration change** (modify lines 30, 46):
```dart
@DriftDatabase(tables: [AppSettings, LetterMastery])   // add table
// ...
@override
int get schemaVersion => 2;                            // was 1 (Pitfall 4 — required)
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) await m.createTable(letterMastery);
  },
);
```
> After editing: re-run `dart run build_runner build` (regenerates `app_database.g.dart`).

**Access pattern** (from `setSetting`/`getSetting`, lines 57-68) — `into(...).insertOnConflictUpdate`
for write, `select(...)..where(...).getSingleOrNull()` for read. Mirror these for
`recordMastery` / `isMastered`.

---

### `lib/data/progress_repository.dart` + `drift_progress_repository.dart` (repository, CRUD)

**Analog:** `lib/data/curriculum_repository.dart` (repository class + `@Riverpod(keepAlive)`
provider, lines 12-120) and `app_database.dart`'s settings accessors.

**Provider pattern** (from `curriculum_repository.dart` lines 117-120):
```dart
@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) {
  return DriftProgressRepository(ref.watch(appDatabaseProvider));
}
```
> The repo takes the `AppDatabase` (read via `appDatabaseProvider`, see
> `app_database.dart` lines 80-85) and exposes `recordMastery(letterId, cleanReps)` /
> `isMastered(letterId)`. SECURITY (T-01-05): persist ONLY letterId/cleanReps/timestamp —
> never the stroke points (RESEARCH Security §Child-data privacy).

---

### `lib/features/practice/widgets/stroke_canvas.dart` (widget, streaming pointer)

**Analog:** `lib/screens/practice_screen.dart` `_InkSurface` + `_InkPainter` (lines 181-326)
— the PROVEN P1 capture surface. Also `authoring_screen.dart` `_CaptureSurface` (lines
250-320), which already re-used it once. Pitfall 2 (no `GestureDetector`) is already
respected.

**Capture pattern** (from `practice_screen.dart` lines 207-228) — `Listener` + `globalToLocal`,
per-stroke `List<Offset>`:
```dart
Offset _local(BuildContext context, Offset global) =>
    (context.findRenderObject()! as RenderBox).globalToLocal(global);
// ...
Listener(
  behavior: HitTestBehavior.opaque,
  onPointerDown: (e) => onStrokeStart(_local(context, e.position)),
  onPointerMove: (e) => onStrokeUpdate(_local(context, e.position)),
  onPointerUp: (e) => onStrokeEnd(),
  onPointerCancel: (e) => onStrokeEnd(),
  child: CustomPaint(painter: _InkPainter(...), child: const SizedBox.expand()),
);
```

**THREE additions on top of the analog (the only new work here):**
1. **Stylus filter (D-13/D-14)** — gate each handler on `event.kind`. The P1 analog
   captures ALL pointers (see its comment, lines 179-180: "stylus-only rejection is P3").
   Add per RESEARCH Pattern 1:
   ```dart
   bool _accept(PointerDeviceKind k) =>
       k == PointerDeviceKind.stylus ||
       (kDebugMode && DebugFlags.allowFingerInput && k == PointerDeviceKind.touch);
   ```
   The debug-finger flag MUST be on-by-default in debug (Pitfall 5 — owner's hardware is
   finger-only).
2. **Dotted guide layer** — render the resolved reference path UNDER the ink. Use the
   `IgnorePointer` faint-backdrop pattern from `authoring_screen.dart` lines 201-218, but
   paint the path from `ReferencePath.resolve` in a `CustomPainter` (NOT `Text('ا')` —
   Pitfall 5 / UI-SPEC line 137).
3. **Stylus-up hook** — `onPointerUp` submits the completed stroke to the session
   controller (the scorer entry point).

**Ink-painter pattern** (REUSE VERBATIM from `practice_screen.dart` lines 298-321) — the
quadratic-midpoint smoothing `_paintStroke` is the proven path; copy it. Tokens:
`QalamColors.inkStroke`, `QalamInk.strokeWidth` (6), round caps/joins (lines 279-285).

---

### `lib/features/practice/widgets/stroke_order_animation.dart` (widget, event-driven)

**Analog:** `_InkPainter` (CustomPainter shape) + `ReferencePath.resolve` consumer +
`QalamMotion` tokens.

**Path-animation pattern** (RESEARCH Pattern 2 — `PathMetric`, no Rive): build a
`dart:ui` `Path` from `ReferencePath.resolve(letter.referenceStrokes)` (one source of
truth, S1-04/D-11), then drive it with an `AnimationController`:
```dart
final metric = refPath.computeMetrics().first;
final drawn = metric.extractPath(0, metric.length * t);   // t = controller.value
canvas.drawPath(drawn, _inkPaint);
final tip = metric.getTangentForOffset(metric.length * t);
if (tip != null) canvas.drawCircle(tip.position, penTipR, _tipPaint);
// gold start-dot at metric.getTangentForOffset(0).position
```
**Tokens (UI-SPEC Interaction & Motion table):** gold start-dot = `QalamColors.reward`;
ink = `QalamColors.inkStroke`; pacing = `QalamMotion.durSlow` (420ms) with
`QalamMotion.easeOutQuart` (`dimens.dart` lines 77, 83). Auto-play once then Replay (D-10).

---

### `lib/features/practice/widgets/feedback_panel.dart` (widget, request-response)

**Analog:** `home_screen.dart` `_PlaceholderCard` (lines 119-161) — soft-aqua token card,
heading/body from l10n.

**Mistake→named-fix pattern** (RESEARCH Pattern 5, UI-SPEC feedback table): the scorer
emits a `MistakeId`; this panel surfaces the matching `commonMistakes[].feedback` via l10n.
NEVER a generic "Oops" (Pitfall 7). Failing stroke + frame in `QalamColors.warnSoft`
(coral, never red) + soft wiggle via `QalamMotion.easeSoftBack` (`dimens.dart` line 79).
"Stroke X of N" uses `QalamTextStyles.label` (16px). All strings via gen-l10n.

---

### `lib/features/practice/widgets/mastery_celebration.dart` (widget, full-screen)

**Analog:** `home_screen.dart` (full Scaffold + `ArabicText` RTL island lines 102-113 +
`SvgPicture.asset` lines 96-100 + token layout).

**Dignified-celebration pattern (D-08, UI-SPEC):** mascot SVG (`flutter_svg`, like the
wordmark) + mastered alif (Arabic display 96px via `ArabicText`, UI-SPEC Arabic scale) +
**ONE** gold star (`QalamColors.reward`, the ONLY gold use) settling in over
`QalamMotion.durCheer` (700ms, `dimens.dart` line 84) + "You learned alif. أحسنت." +
Back Home. **OMIT** counter / "+N" / three stars / "See journey" / confetti (D-03/D-08,
Pitfall 3). Arabic "أحسنت" goes through `ArabicText` (Noto Naskh, RTL island) exactly like
`home_screen.dart` line 144.

---

### `lib/providers/practice_providers.dart` (provider, Riverpod Notifier)

**Analog:** `app_database.dart` and `curriculum_repository.dart` `@Riverpod` providers
(the established Riverpod-codegen pattern; `part 'x.g.dart'` + `@Riverpod`).

**Clean-rep → mastery state-machine pattern** (RESEARCH Pattern 3, D-07): a
`@riverpod`-codegen Notifier `family` by lessonId, autoDispose. Reads alif via
`ref.watch(curriculumRepositoryProvider).getLesson("lesson_01")` →
`getLetter("alif")` (existing API, `curriculum_repository.dart` lines 77-98). Tracks
Watch/Trace/Celebrate phase + clean-rep count; on the 3rd clean rep calls
`progressRepository.recordMastery(...)`. Misses do NOT consume a rep (D-05).

> Provider split (RESEARCH Anti-Pattern 3 / Q3): keep high-frequency live points in widget
> `State` (the P1 approach, proven), submit only the COMPLETED stroke to this controller.
> Do NOT lift live points into the session controller. `part`/`@riverpod` codegen → re-run
> `build_runner`.

---

### `lib/config/debug_flags.dart` (config)

**Analog:** `lib/theme/dimens.dart` `abstract final class QalamSpace` (lines 11-23) — a
holder of `static const` values.
```dart
abstract final class DebugFlags {
  /// D-13/D-14: allow finger input in debug builds (owner's test hardware has
  /// no stylus). Read only behind kDebugMode at the call site.
  static const bool allowFingerInput = true;
}
```

---

### `lib/router/app_router.dart` (MODIFY — entry point)

**Analog:** itself. The `/practice` route already exists (lines 30-33) pointing at the P1
screen. Repoint it (or add a `lesson_01` dev route) at the new
`features/practice/practice_screen.dart` per D-02 — a MINIMAL entry point, NOT a rebuilt
Home. Follow the existing `GoRoute` block + dev-seam comment style (lines 36-50).

---

## Shared Patterns

### Design tokens (NEVER raw hex / magic numbers)
**Source:** `lib/theme/colors.dart` (`QalamColors`), `lib/theme/dimens.dart`
(`QalamSpace`/`QalamTargets`/`QalamRadii`/`QalamMotion`/`QalamInk`), `lib/theme/text_styles.dart`
(`QalamTextStyles`/`QalamFonts`/`QalamFontSizes`).
**Apply to:** ALL Phase-3 widgets.
- Reward gold is `QalamColors.reward` and is used ONLY for: start-dot, the single mastery
  star, the celebration alif glow (UI-SPEC Color §gold list). Nothing else.
- Errors are `QalamColors.warnSoft` (coral) — there is no red (`colors.dart` lines 17, 59-60).
- Touch targets ≥ `QalamTargets.targetComfy` (72) / `targetLarge` (96) (UI-SPEC Spacing).
```dart
// home_screen.dart lines 178-189 — the canonical CTA (token shadow + InkWell + min height):
Material(
  color: QalamColors.primary,
  child: InkWell(onTap: onPressed, child: Container(
    constraints: const BoxConstraints(minHeight: QalamTargets.targetComfy),
    child: Text(label, style: QalamTextStyles.button.copyWith(color: QalamColors.fgOnPrimary)),
  )),
)
```

### All user-facing copy via gen-l10n
**Source:** `lib/l10n/app_localizations.dart` (getters like `writeHere`, `clearConfirmHeading`).
**Apply to:** every string in the trace flow (headings, eyebrows, buttons, the named-fix
feedback, celebration line). Add new getters; never hardcode (CLAUDE.md, UI-SPEC
Copywriting). The authored `commonMistakes[].feedback` strings are the contract — verify
against live `letters.json` at implement time (UI-SPEC feedback table).

### In-memory-only stroke data (security T-01-05)
**Source:** `practice_screen.dart` lines 15-17, 38-43; `authoring_screen.dart` lines 11-14, 54.
**Apply to:** `stroke_canvas.dart` + the session controller. Captured points live in
widget `State`, discarded on dispose/retry; only the derived mastery result is persisted.
NO `print`/`debugPrint` of points, no network.

### Riverpod-codegen provider style
**Source:** `app_database.dart` lines 80-85, `curriculum_repository.dart` lines 117-120.
**Apply to:** all new providers — `part 'x.g.dart'`, `@Riverpod(keepAlive: true)` for
long-lived repos, `@riverpod` (autoDispose, `.family`) for the session controller.
`ref.onDispose(...)` for resources. Re-run `build_runner` after.

### Pure-Dart domain layer (no Flutter import)
**Source:** `stroke_validation.dart`, `reference_path.dart` (both `lib/core/scoring/`,
zero `dart:ui`/Flutter imports).
**Apply to:** `geometric_stroke_scorer.dart`, `stroke_resampler.dart`, `scoring_models.dart`,
`handwriting_recognizer.dart`. Keeps the pedagogy unit-testable without a widget harness
(the owner's mother validates it via tests in Phase 4 — RESEARCH §Don't Hand-Roll).

### Drift restart-proof test harness
**Source:** `test/data/app_database_test.dart` lines 21-36 — shared `NativeDatabase.memory()`,
close db1, reopen db2 over the same executor, assert survival.
**Apply to:** `test/data/progress_repository_test.dart` (mastery round-trip + the 1→2
migration). The injected-executor `close()` contract (`app_database.dart` lines 39-54)
makes this work.

### Widget pointer-synthesis test harness
**Source:** `test/features/authoring/authoring_screen_test.dart` lines 119-143 —
`tester.getRect(canvas)`, `startGesture(top) → moveTo(mid) → moveTo(bottom) → up()`,
`pumpAndSettle`, assert on a keyed widget.
**Apply to:** `test/features/practice/stroke_canvas_test.dart` (drive the canvas with a
synthetic stroke; verify the debug-finger flag lets `touch` through and prod rejects it —
RESEARCH Pitfall 5).

### Pure-Dart unit-test style
**Source:** `test/core/scoring/reference_path_test.dart` lines 11-106 — `group`/`test`,
construct `StrokeSpec` fixtures inline, assert on the pure function's output.
**Apply to:** `geometric_stroke_scorer_test.dart`, `stroke_resampler_test.dart`,
`mistake_mapping_test.dart`. Synthetic alif fixtures (clean / too-short / inverted /
curved) as shared helpers (RESEARCH Wave-0 Gaps).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/core/recognition/handwriting_recognizer.dart` | service interface | request-response | No recognizer/ML-Kit seam exists yet. Intentionally an EMPTY abstract interface in Phase 3 (D-16); the ML Kit impl lands in Phase 4. Follow the repository-interface + dev-seam-comment conventions, but there is no behavior to copy. |

---

## Metadata

**Analog search scope:** `lib/` (all subdirs: core/scoring, core/recognition, data, dev,
features, models, providers, router, screens, theme, widgets, l10n), `test/` (core/scoring,
data, features, curriculum, models).
**Files scanned:** 26 lib Dart files + 16 test Dart files (read 12 in full as analogs).
**Pattern extraction date:** 2026-06-01
