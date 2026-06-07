---
phase: 3
reviewers: [claude]
reviewer_models:
  claude: claude-sonnet-4-6
reviewed_at: 2026-06-07T13:44:09Z
plans_reviewed: [03-00-PLAN.md, 03-01-PLAN.md, 03-02-PLAN.md, 03-03-PLAN.md, 03-04-PLAN.md, 03-05-PLAN.md]
note: >
  Only one external CLI (claude) was installed on this machine, run from inside Claude Code.
  No independent cross-AI reviewer (Gemini/Codex/OpenCode/Qwen/Cursor) or local model server was
  available. The review below is a single fresh-session claude (Sonnet 4.6) pass — useful, but NOT
  the multi-model adversarial review this command normally produces. Install a second CLI and
  re-run /gsd:review for true independence. This review is also retrospective: Phase 3 is already
  executed (151 tests pass), so each concern should be checked against the implemented code rather
  than treated as a pre-execution gate.
---

# Cross-AI Plan Review — Phase 3: Trace One Letter End-to-End

## Claude Review  (model: claude-sonnet-4-6, separate session)

## Plan Review: Phase 3 — Trace One Letter End-to-End

### Summary

The Phase 3 plan set is architecturally sound and methodically decomposes the deepest-risk phase into five sequenced waves. The critical Q1 risk (reference-path semantics — outline vs. centerline) is cleanly resolved upstream in Phase 02.1, which the plans correctly assume; `ReferencePath.resolve` as an identity pass-through is the right call. TDD is applied to the highest-value artifact (the pure-Dart geometric scorer), anti-gamification invariants are enforced through both positive goldens and explicit absence assertions, and the child-data safety constraint (stroke points in-memory only) is respected and grep-verified throughout. Wave ordering is clean; the dependency graph has one potentially unnecessary sequential constraint (noted below). One structural gap — async loading in the Riverpod session controller — is the primary execution risk.

---

### Strengths

- **Predicate-name contract is explicit**: Requiring scorer predicate names to equal `commonMistakes[].check` strings is the correct way to tie curriculum content to code. A grep-based acceptance criterion enforces it at review time, not just at authoring time.
- **TDD applied to the crown jewel**: RED-GREEN-REFACTOR on the scorer, with synthetic fixtures covering all three named mistakes plus the critical size/position invariance case. The latency assertion (well under 300 ms) is included inline rather than deferred.
- **Anti-gamification enforced bidirectionally**: Plan 04 uses both a golden (proves ONE star, mascot, warm line) and negative text/widget assertions (`expect(find.textContaining('THIS WEEK'), findsNothing)` etc.). Plan 05 mirrors this for the home screen. Negative testing for gamification chrome is unusual and exactly right for this project's values.
- **Debug-finger flag as injectable constructor parameter**: Making `acceptTouch` injectable on `StrokeCanvas` for tests — while the `const` `DebugFlags.allowFingerInput` provides the default — cleanly solves D-14 without polluting the production code path.
- **Drift migration identified and tested**: Plan 02 correctly identifies `schemaVersion` 1→2, cross-references Pitfall 4, and includes a test that an existing `app_settings` row survives the upgrade.
- **Child-data safety grep-gated**: The acceptance criterion `grep -ci "List<Offset>" lib/providers/practice_providers.dart` returns 0 is an unusually concrete safety guarantee that live stroke points never enter the session controller.
- **Graceful asset fallback required everywhere**: Every `SvgPicture.asset` call must degrade to `SizedBox` rather than crashing. For a demo scenario this is especially important.
- **No new runtime packages**: The Package Legitimacy Audit is complete; Rive rejection is explicit and justified (violates S1-04 one-source-of-truth).
- **`read_first` gates are specific**: Each task names exact file paths and line numbers. This prevents the common failure mode of an executor "knowing" what's in a file without reading it and introducing drift.

---

### Concerns

**MEDIUM-HIGH**

- **Async loading in `practiceSessionController` (Plan 04, Task 1)**: `CurriculumRepository.getLesson('lesson_01')` and `.getLetter('alif')` both return `Future<T?>`. A Riverpod `Notifier.build()` is synchronous — it cannot `await` a Future. The plan says the controller "reads alif via `ref.watch(curriculumRepositoryProvider).getLesson('lesson_01')`" without specifying how the async result is handled. If implemented naively, this either won't compile (build_runner will reject an `async build()` on a `Notifier`) or the controller will crash on cold start when `requireValue` is called on a loading `AsyncValue`. The options are: (a) an upstream `@Riverpod FutureOr<Letter> alifLetterProvider(Ref ref)` that the Notifier watches and calls `.requireValue`, or (b) promote the controller to an `AsyncNotifier<PracticeState>`. Neither is specified, leaving the implementor to discover the issue at codegen time.

**MEDIUM**

- **`List<Offset>` → `List<List<double>>` conversion site is unspecified (Plans 01/03/04)**: Plan 01's scorer takes `List<List<double>>` (pure Dart, no `dart:ui`). Plan 03's `StrokeCanvas.onStrokeSubmitted` emits `List<Offset>` (Flutter type). The conversion must happen somewhere — presumably in `practice_screen.dart` before calling `scoreStroke`. No plan's `<action>` block mentions this conversion, and no acceptance criterion tests it. A swapped `dx`/`dy` or a missed normalization here would produce systematically wrong scoring that passes all unit tests.

- **Migration test may not exercise the actual upgrade path (Plan 02, Task 1)**: `NativeDatabase.memory()` creates a database at the *current* `schemaVersion`. The behavior description mentions "opening over an executor seeded at the pre-migration shape," but doesn't specify the mechanism. Without explicitly opening a schema-v1 `AppDatabase` first (with only `AppSettings`, `schemaVersion = 1`), inserting a row, closing, and then reopening with the v2 code, the test may only verify fresh-database creation — not the migration path that runs on real production upgrades.

- **`practiceSessionController` family argument ignored in implementation (Plan 04, Task 1)**: The controller is `.family` by `lessonId: String`, but the action loads `getLesson('lesson_01')` directly. For Phase 3 this is correct (one letter), but the family parameter signals to callers that different lessons can be loaded — which won't be true. Phase 6 will need to refactor the controller to actually use the argument, making this a predictable design debt. The plan should either use the argument or explicitly acknowledge and document the hardcoding.

- **`StrokeOrderAnimation` widget API is ambiguous (Plan 03, Task 2)**: The action says "taking the alif `List<StrokeSpec>` (or the resolved points)." The "or" leaves the widget's constructor signature undetermined. `reference_path.dart`'s own closing note says "Phase 3 wraps the returned points into a `dart:ui` `Path` for `PathMetric`; that UI concern stays out of this pure-Dart layer" — implying the widget takes `List<StrokeSpec>` and does the wrapping internally. The plan should commit to one API; ambiguity here is how two plans silently agree on different signatures.

- **Degenerate stroke handling not specified (Plan 01)**: The scorer's `resample` and `normalizeToUnitBox` may receive degenerate input: a single-point accidental tap, two identical points, or a stroke with no measurable vertical extent. `normalizeToUnitBox` dividing by a zero bounding-box dimension produces NaN or Infinity. The plan's behavioral spec covers the four named fixture cases but not these edge cases. A crash on a tapped-but-not-drawn stroke is user-visible on a child's tablet.

**LOW**

- **Golden test first run requires `--update-goldens` (Plan 04, Task 2)**: No baseline exists before the test runs the first time. This is standard Flutter practice but should be noted in the `<action>` block so the executor doesn't hit an unexpected failure.

- **`alif.referenceStrokes.first` without empty guard (Plan 04, Task 3)**: The validator enforces that signed-off letters have at least one stroke, but calling `.first` on an empty list throws an uncaught exception. A guard (`if (alif.referenceStrokes.isEmpty) return;`) makes the failure explicit and recoverable.

- **`diff` acceptance criteria is platform-fragile (Plan 00)**: `diff assets/mascot/qalam-idle.svg docs/design/kit/project/assets/mascot/qalam-idle.svg` will report differences on CRLF/LF mismatches or if `cp` changes file metadata. `cmp -s` or a checksum comparison (`md5` / `shasum`) is more portable.

- **Plan 03 may have an unnecessary sequential dependency on Plan 01**: If `StrokeCanvas.onStrokeSubmitted` emits raw `List<Offset>` (no reference to `StrokeResult`/`MistakeId`), Plan 03 has no compile-time dependency on Plan 01's scorer types. Moving Plan 03 to Wave 1 alongside Plans 01 and 02 shortens the critical path. If the canvas callback does reference `StrokeResult`, the dependency is correct — but the plan doesn't make this explicit.

- **One-source-of-truth animation test is marked "e.g." (Plan 03, Task 2)**: "Assert the animation consumes ReferencePath.resolve output (e.g., via a test that the drawn path length matches the resolved-path length)" — the "e.g." makes this suggestive rather than required. S1-04's one-source-of-truth requirement is the phase's second-most important invariant after the scorer. The path-identity assertion should be mandatory.

- **`ArabicText('ا')` on the home card vs. the trace canvas (Plan 05)**: Using `ArabicText` for the decorative alif glyph on the lesson card is fine; the UI-SPEC's "not `Text('ا')`" rule applies specifically to the trace canvas guide (which must use the reference path). The distinction isn't noted in Plan 05, which could mislead a future reviewer into thinking Plan 03's path-painted guide is also incorrect.

---

### Suggestions

1. **Resolve the async Riverpod pattern explicitly in Plan 04 Task 1**: Specify either (a) a `@Riverpod FutureOr<Letter> alifLetterProvider(Ref ref)` loaded from `curriculumRepositoryProvider`, watched with `.requireValue` in the Notifier, or (b) an `AsyncNotifier<PracticeState>` whose `build()` awaits the letter. The choice affects whether `practice_screen.dart` needs to handle an `AsyncValue` loading state and whether the golden test requires a `pumpAndSettle` before asserting state. This is the single highest-priority suggestion.

2. **Commit `onStrokeSubmitted` to `List<List<double>>` in Plan 03**: Convert `List<Offset>` to `List<List<double>>` once, inside `StrokeCanvas._onPointerUp`, at the point where pixel coordinates are already available. This enforces the scorer's pure-Dart contract at the widget boundary, eliminates the unspecified conversion site in `practice_screen.dart`, and makes the data pipeline explicit. Add one acceptance criterion: `grep -c "List<List<double>>" lib/features/practice/widgets/stroke_canvas.dart` returns >= 1.

3. **Strengthen the migration test in Plan 02 Task 1**: Open a schema-v1 `AppDatabase` (override `schemaVersion => 1` and `tables: [AppSettings]`), insert a sentinel `AppSettings` row, close, reopen with the production v2 `AppDatabase`, and assert both the sentinel row and the `LetterMastery` table are accessible. Drift's `DatabaseConnection.fromExecutor` with a shared `NativeDatabase.memory()` makes this feasible in-process.

4. **Use the `lessonId` family argument in Plan 04 Task 1**: Implement `practiceSessionController.build(String lessonId)` to call `curriculumRepository.getLesson(lessonId)`. Add a test asserting `practiceSessionController('lesson_01')` loads alif specifically. Phase 6 can then pass any lessonId without controller refactoring.

5. **Add a degenerate-stroke fixture to Plan 01**: Add a `singlePoint` fixture to `scoring_fixtures.dart` and assert `scoreStroke(singlePoint, alifRefStroke)` returns `StrokeResult(passed: false, mistakeId: MistakeId.fallback)` rather than throwing. This also forces `normalizeToUnitBox` to guard against zero bounding-box dimensions.

6. **Make the animation path-identity test mandatory in Plan 03 Task 2**: Change the acceptance criterion from a suggestion to a requirement: assert `animationPathLength ≈ resolvedPathLength` (within a small epsilon) to prove one source of truth for S1-04.

7. **Note `--update-goldens` in Plan 04 Task 2**: Add to the action block: "Run `flutter test --update-goldens test/features/practice/mastery_celebration_golden_test.dart` on first execution to generate the baseline, then commit the golden file alongside the implementation."

8. **Evaluate moving Plan 03 to Wave 1**: If the canvas API emits `List<Offset>` (no `StrokeResult` reference), remove `"03-01"` from Plan 03's `depends_on`. This reduces the critical path from 3 sequential waves (Wave 1 scorer → Wave 2 canvas → Wave 3 flow) to 2 (Waves 1+2 parallel → Wave 3 flow).

---

### Risk Assessment

**Overall: MEDIUM**

The plans are detailed, the testing strategy is comprehensive, and the phase goal is clearly achievable from these artifacts. The anti-gamification and child-data safety constraints are the most rigorously tested aspects — exactly appropriate for this project.

The primary execution risk is the **async Riverpod loading pattern** in the session controller. If implemented as a synchronous `Notifier.build()` calling async `getLesson()`, the controller will fail at codegen or exhibit an unhandled loading state that none of the planned tests catch. This is the one structural gap that could block Phase 3 delivery or produce a subtly broken controller that passes all tests but crashes in the widget layer.

All other concerns are lower-severity implementation details. If the async loading pattern is resolved (either by plan amendment or by an experienced executor who recognizes the issue), the risk profile drops to **LOW**.

---

## Consensus Summary

Only one reviewer was available (claude / Sonnet 4.6), so there is no cross-model consensus to
synthesize. The single-reviewer verdict is **MEDIUM risk**, dominated by one structural concern.
Because Phase 3 is already implemented and green (151 tests pass), the actionable move is to
**verify each concern against the shipped code** rather than re-plan:

### Highest-priority item to verify in code
- **Async Riverpod loading in `practiceSessionController`** — confirm the implementation handled
  the `Future<Letter?>` load correctly (an `alifLetterProvider`/`.requireValue` pattern or an
  `AsyncNotifier`), and that it doesn't crash on cold start. The review flags this as the one issue
  capable of producing a controller that passes tests but breaks in the widget layer. The 151
  passing tests make a hard crash unlikely, but an unhandled loading state may still be untested.

### Worth a quick code check
- **`List<Offset>` → `List<List<double>>` conversion site** — is there a single, tested conversion
  point, with correct dx/dy order and normalization? A silent swap here would pass unit tests yet
  systematically mis-score real strokes.
- **Migration test actually exercises v1→v2** — confirm the test seeds a schema-v1 DB and reopens
  with v2, not just a fresh v2 DB.
- **Degenerate stroke input** — confirm a single-point / zero-extent tap doesn't yield NaN/Infinity
  or crash on a child's tablet.

### Confirmed strengths (no action)
Predicate-name↔`commonMistakes[].check` contract, TDD on the scorer with a latency assertion,
bidirectional anti-gamification testing (positive golden + negative absence asserts), grep-gated
child-data safety, and graceful SVG asset fallback. These align tightly with the project's Decided
constraints and the tutor/anti-game values in CLAUDE.md.

### Divergent views
N/A — single reviewer.
