# Phase 3: Trace One Letter End-to-End - Research

**Researched:** 2026-06-01
**Domain:** On-device geometric stroke scoring + low-level stylus capture + path-driven stroke-order animation (Flutter / Android / RTL, Riverpod, pure-Dart scorer, fully offline, anti-gamification)
**Confidence:** HIGH on stylus capture, animation, persistence, and the Flutter stack (existing P1/P2 code + verified prior research); HIGH on the scorer *method survey*; **MEDIUM on the scorer's exact data semantics — see the single most important finding below.**

---

> ## ⚠️ THE SINGLE MOST IMPORTANT FINDING — READ FIRST
>
> **alif's `referenceStrokes[0].points` is a 64-point CLOSED OUTLINE CONTOUR of the glyph, NOT a top-to-bottom centerline skeleton.** [VERIFIED: inspected `assets/curriculum/letters.json`]
>
> The points start at the top (`[0.282, 0.0]`), descend the **left** edge to the bottom-right serif (max-y `[0.66, 1.0]` at index 31 of 64), then **ascend the right** edge back up, closing near the start (`[0.505, 0.006]`). It is the font *outline* extracted by the Phase-2 fonttools script — it traces **around** the letter, there and back.
>
> But the stroke is labelled `direction: "topToBottom"`, and the three authored `commonMistakes` checks describe **skeleton/centerline** semantics:
> - `strokeLengthBelowThreshold` ("too short" — assumes a single downward stroke length)
> - `strokeDirectionInverted` ("wrong direction" — assumes a top→bottom vs bottom→top axis)
> - `strokeCurvatureExceedsThreshold` ("too curved" — assumes alif should be a *straight* line)
>
> **A child writing alif draws ONE straight downward stroke (a centerline). The reference is a closed loop.** Comparing the child's single down-stroke directly against the 64-point loop with any path-distance metric (DTW / Fréchet / Procrustes / mean-nearest-point) will be **geometrically wrong**: the child's stroke length is ~half the contour perimeter, its direction never reverses, and it is straight while the contour is a loop. Scoring "too short / wrong direction / too curved" against the raw outline cannot work as authored.
>
> **This is the deepest-risk decision of the deepest-risk phase. It MUST be resolved before any scorer code is written.** Three options for the planner to put to the owner (see `## Open Questions` Q1 — this needs a decision, do not let the planner silently pick):
>
> 1. **Derive a centerline at load/build time** from the outline (medial-axis / midline of the two long edges), and score the child's stroke against that derived skeleton. The outline still drives the *visual dotted guide*; a derived centerline drives *scoring + the animated pen-tip*. (Recommended — preserves the single-source-of-truth spirit while giving the scorer the skeleton its checks assume.)
> 2. **Re-author alif's `referenceStrokes` as a true centerline** (a short ordered top→bottom point list) in `letters.json`, with the owner's sign-off, and keep the outline only as a display asset if wanted. Cleanest semantically; touches signed-off curriculum data (a Phase-2 sign-off boundary — flag to owner).
> 3. **Score on direction + extent + straightness derived from the child's stroke alone** (bounding-box height, net vertical travel sign, residual-from-fitted-line), comparing only against scalar thresholds — never against the outline point list. Simplest first-cut; still needs the outline excluded from the distance computation.
>
> All three keep "one source of truth for animation and scoring" intact *if the derived/re-authored centerline is what both consume*. **Do not feed the raw 64-point outline into a path-similarity metric against a single human down-stroke.** This is exactly Pitfall 1/3/4 territory made concrete.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Phase 3 builds **only the trace flow** (Watch → Trace → Celebrate), faithfully to the owner's Claude Design in `docs/design/kit/`. Home/Journey/Parent stay Phase-1 shells.
- **D-02:** Trace flow reachable from a **minimal entry point** (existing Home shell lesson card / dev route to `lesson_01`). Do NOT rebuild Home.
- **D-03:** Follow the Decided anti-gamification rules — **a star marks real mastery of a letter only**; NO running counter, NO "stars this week", NO weekly bar. Build the trace screens from the design but **omit the gamification chrome in the header**.
- **D-04:** **Per-stroke feedback.** Trace one stroke → lift → instant feedback on THAT stroke (good → advance; off → named fix + retry same stroke). For alif (one stroke) this is a single judgement; the model is built for multi-stroke letters.
- **D-05:** **On a miss: hold, show the fix, let them retry.** Failing stroke highlighted, named fix in the tutor's voice, ink clears, retry the SAME stroke. **Unlimited gentle retries — no fail state, no try-counter, no pressure.** (Optional "show me again" replay after repeated misses is nice-to-have only.)
- **D-06:** The **"Mark correct" button** is a design/dev placeholder — **drop it**. Pass/fail comes only from the geometric scorer.
- **D-07:** **3 clean reps → 1 mastery star.** Child traces alif cleanly 3 times (1/3, 2/3, 3/3); the single mastery star + celebration come after the 3rd clean rep. Uses alif's `cleanRepsToAdvance: 3`.
- **D-08:** **Dignified full-screen celebration:** calm full-screen — qalam mascot, the mastered alif, one gold star settling in, a warm line (e.g. "You learned alif. أحسنت."), then Done/Home. NO confetti spam, NO sound blast, NO running counter.
- **D-09:** **Persist alif mastery + clean-rep count to Drift now** (the Phase-1 persistence seam exists). Phase 6's journey map will read it.
- **D-10:** **Auto-play once, then Replay.** Demo plays once automatically on entering "Watch me write"; child can Replay / "Watch again" freely, then "I'll try" to start tracing.
- **D-11:** **Animated pen-tip traces the path on the guide**, starting at the numbered gold start-dot, in the correct direction — driven by the **SAME `referenceStrokes` used for scoring** (S1-04 one source of truth). Mascot beside as tutor persona.
- **D-12:** **Omit the audio / "Play sound" button in Phase 3.** No audio assets exist; pronunciation is Phase 7. No dead button now.
- **D-13:** **Stylus-only in production; finger allowed in a debug flag.** Real builds capture stylus only and ignore touch (palm rejection comes free). A debug/dev flag lets finger input through so the owner can develop on a finger-only tablet/emulator. The scorer treats both input sources identically.
- **D-14:** Because the owner tests with a **finger**, the debug-finger path must be easy to enable and the loop fully exercisable without a stylus. Do not let stylus-only filtering silently block all input during development.
- **D-15:** **Phase 3 wires the scorer; Phase 4 calibrates it.** Ship a deliberately **lenient first-cut** threshold so good-faith child attempts pass; real per-letter tuning is Phase 4.
- **D-16:** **ML Kit deferred to Phase 4.** Phase 3 is a **pure geometric scorer, fully offline, zero network**. Leave the `HandwritingRecognizer` interface seam ready but unimplemented-by-ML-Kit in Phase 3.

### Claude's Discretion
- Exact smoothing/resampling and shape-distance algorithm for the geometric scorer (Procrustes / Fréchet-style vs simpler resampled point distance) — researcher/planner choice; Phase 4 tunes it anyway.
- Exact Drift schema shape for recording mastery + clean-rep count (D-09).
- Precise visual treatment of the animated pen-tip and celebration motion (within the design's look) — UI designer's call.
- How the named `commonMistakes` checks (`strokeLengthBelowThreshold`, `strokeDirectionInverted`, `strokeCurvatureExceedsThreshold`) map to concrete scorer predicates and their first-cut thresholds (lenient default per D-15).
- Riverpod structure for the session (`practiceSessionController` family by lessonId, separate high-frequency stroke-capture provider).

### Deferred Ideas (OUT OF SCOPE)
- ML Kit identity check + model download-and-cache → Phase 4.
- Scorer calibration / per-letter tolerance tuning with the owner's mother → Phase 4.
- Rebuilt Home → Phase 5/6; Journey / alphabet map → Phase 6; pronunciation audio + "Play sound" → Phase 7; Parent dashboard → Phase 9.
- Updating design assets to drop the running star counter / weekly tallies → housekeeping, not Phase 3 code.
- Gentle "show me again" auto-replay after repeated misses → optional Phase 4 UX polish.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **S1-04** | Before writing, the child can watch (and replay) an animation of the correct stroke order, driven by the **same reference paths used for scoring**. | `## Pattern 2` (PathMetric pen-tip animation from `referenceStrokes`); `## Standard Stack` (no Rive needed — custom path animation reuses the one source of truth); animation + scorer must consume the **same derived/resolved path** (see THE FINDING — the resolved path, not necessarily the raw outline). |
| **S1-05** | Stylus capture + instant on-device per-stroke feedback on count, order, direction, shape; failing stroke highlighted; specific named fix from `commonMistakes`; < ~300 ms after stylus-up; fully offline; custom geometric scorer (ML Kit only secondary, deferred to P4). | `## Pattern 1` (low-level `Listener` capture, already in P1 spike); `## Architecture Patterns` (geometric scorer pipeline); `## Latency` (budget; runs on main isolate — sub-30 ms); `## Don't Hand-Roll` (resampling/normalization). |
| **S1-10** | Mastery star earned via the curriculum's clean-reps; dignified celebration; NO totals/tallies/streaks/badges. | `## Pattern 3` (clean-rep counting → mastery → Drift); `## Pattern 4` (Drift schema for mastery); design mockup `05-celebration-final.png`; anti-gamification rules in `## Common Pitfalls` P7. |
| **PLAT-03** | Stays not-points-chasing and on-brand; no totals/tallies/streaks/badges/confetti/timers/over-praise; feedback specific not generic; gold = rewards-only; coral not red; no emoji/pseudo-icons. | `## Project Constraints (from CLAUDE.md)`; `docs/design/kit/project/SKILL.md` brand hard-rules; D-03/D-06/D-08/D-12 omissions; `## Common Pitfalls` P7. |
</phase_requirements>

## Summary

Phase 3 assembles the core physical loop for **alif** out of pieces that mostly already exist in the codebase. The Phase-1 `practice_screen.dart` spike already captures strokes via low-level `Listener`/pointer events (not `GestureDetector`), already segments per-stroke point lists, and already renders smoothed ink with a `CustomPainter` — so **Pitfall 2 (lossy capture) is already avoided**, and the capture surface needs only three additions: `PointerDeviceKind` filtering (stylus-only in prod, debug-finger flag per D-13/D-14), a dotted guide layer beneath the ink, and a stylus-up hook that submits the completed stroke to the scorer.

The hard, novel work is the **geometric stroke scorer** (pure Dart) and resolving the data-semantics finding above. The scorer compares the child's resampled, normalized stroke against alif's reference to judge count, order, direction, and shape, then maps a failure to exactly one of alif's three authored `commonMistakes` feedback strings. Because the reference data is a glyph *outline* and the checks assume a *centerline*, the planner must first resolve how the reference path is interpreted (the three options above). Everything else — the PathMetric-driven stroke-order animation (no Rive needed; reuse the same reference path), clean-rep counting to mastery, Drift persistence, and the dignified celebration — is standard Flutter/Riverpod work with strong prior art in P1/P2.

**Primary recommendation:** Resolve THE FINDING (Q1) with the owner first. Then build a **deliberately lenient first-cut scorer** (D-15) that judges direction + vertical extent + straightness of the child's single stroke against scalar thresholds (option 3 is the safest first-cut; option 1 the best-aligned with "one source of truth"), wired behind a pure-Dart `GeometricStrokeScorer` with a `HandwritingRecognizer` interface seam left empty (D-16). Capture stays on the existing `Listener` pattern with stylus filtering + debug-finger flag. Animation and dotted guide both render from the **resolved** reference path. No new packages required.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stylus/finger point capture | Presentation (`StrokeCanvas` widget, `Listener`) | — | Raw pointer events are a Flutter-framework concern; must stay in the widget layer to read `PointerDeviceKind`, timestamps, per-stroke segmentation. |
| Live ink rendering | Presentation (`CustomPainter`) | — | High-frequency repaint, canvas-local; must not touch session state (Anti-Pattern 3). |
| Dotted guide + animated pen-tip | Presentation (`CustomPainter` + `AnimationController`) | Domain (reads resolved reference path) | Rendering is presentation; the *path data* is domain/curriculum (one source of truth). |
| Stroke scoring (count/order/direction/shape) | Domain (`GeometricStrokeScorer`, pure Dart) | — | Pure math, zero Flutter imports → unit-testable; the pedagogy lives here, not in ML Kit (Pitfall 1). |
| Mistake→message mapping | Domain (scorer emits mistake id) → Presentation (l10n string) | Data (`commonMistakes` from `letters.json`) | Scorer names the mistake; the warm string is curriculum data surfaced via l10n. |
| Session orchestration (Watch/Trace/Celebrate, clean-rep count, retry vs advance) | Application (`practiceSessionController`, Riverpod Notifier) | Domain (scorer), Data (progress repo) | Once-per-stylus-up state; scoped `.family` by lessonId, autoDispose. |
| Mastery persistence | Data (`ProgressRepository` + Drift) | — | Local SQLite write; the only thing persisted (stroke points are in-memory only — T-01-05). |
| Letter identity sanity check | Domain (`HandwritingRecognizer` interface) | — | **Interface only in P3** — empty seam; ML Kit impl is Phase 4 (D-16). |

## Standard Stack

### Core (all already installed — see `pubspec.yaml` / `pubspec.lock`)
| Library | Version (locked) | Purpose | Why Standard |
|---------|------------------|---------|--------------|
| flutter (stable) | **3.41.9** | App framework, RTL, Impeller renderer | [VERIFIED: `flutter --version`] — current installed channel. (Note: prior STACK.md cited 3.44; the *actual installed* SDK is 3.41.9 — plan against this.) |
| flutter_riverpod | ^3.3.1 | State management (session controller, capture provider) | [VERIFIED: pubspec.lock] Project standard (Riverpod-only, D-11). |
| riverpod_annotation / riverpod_generator | ^4.0.2 / ^4.0.3 | Codegen `@riverpod` / `@Riverpod` | [VERIFIED: pubspec.lock] Established pattern (P1). |
| drift | ^2.31.0 | Local SQLite persistence (mastery + clean-reps, D-09) | [VERIFIED: pubspec.lock] Note: pinned to 2.31 line (not 2.33) to resolve against Flutter 3.41.9 / analyzer ^9 / riverpod_lint 3.1.3 — see STATE.md decision. **Do not bump.** |
| flutter_svg | ^2.3.0 | Render brand glyph SVGs (mascot states, star icon) | [VERIFIED: pubspec.lock] Already used P1. |
| vector_math | (transitive) | 2D vector ops for the scorer (dot products, distances) | [VERIFIED: pubspec.lock present transitively] Use for direction/projection math; no new dependency. |

### Supporting (framework primitives — NO new packages)
| Capability | Approach | When to Use |
|------------|----------|-------------|
| Stroke capture | `Listener` + raw `PointerEvent` (NOT `GestureDetector`) | Already the P1 pattern — extend it. Read `event.kind` (`PointerDeviceKind.stylus`), `event.timeStamp`, per-pointer-id segmentation. [CITED: Flutter `Listener`/`PointerEvent` docs] |
| Live ink | `CustomPainter` with a `Listenable` repaint scope | Already in P1 `_InkPainter`. |
| Dotted guide + pen-tip animation | `CustomPainter` + `Path` + `PathMetric` + `AnimationController` | Reuse the resolved reference path; `PathMetric.extractPath(0, length*t)` draws the stroke progressively. [CITED: Flutter `dart:ui` `PathMetric`] **No Rive needed** (see Alternatives). |
| Mastery write | Drift table (new) behind a `ProgressRepository` | D-09; the P1 `AppDatabase` seam exists. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom `PathMetric` pen-tip animation | `rive` ^0.14.7 | Rive needs a designer-authored `.riv` and would NOT be driven by the scoring reference path → **violates S1-04's one-source-of-truth requirement** and adds a dependency. Custom path animation reuses the exact scored geometry. **Reject Rive for Phase 3.** [ASSUMED: rive version from prior STACK.md] |
| Scalar-threshold first-cut scorer (option 3) | DTW / discrete Fréchet / Procrustes path matching | Path-distance metrics are the *right* tool once a true centerline exists (option 1/2), but against the raw outline they are wrong (THE FINDING). For a lenient first-cut on a single straight stroke, scalar features (extent, direction sign, straightness residual) are simpler, faster, and easier to calibrate in Phase 4. Reach for DTW/Fréchet in Phase 4 if a centerline is adopted. |
| `mocktail` for repo mocks in tests | Hand-rolled fakes / Riverpod `ProviderContainer` overrides | `mocktail` is **not currently installed**. The P1/P2 tests use real in-memory Drift + `CurriculumRepository.fromStrings`. Prefer that existing pattern; add `mocktail` only if a genuine mock is needed (it is a dev-only, codegen-free add). |

**Installation:** **None required for the core loop.** All needed libraries are already in `pubspec.yaml`. If the planner chooses to add test-mocking convenience: `flutter pub add --dev mocktail` (verify version at plan time; see Package Legitimacy Audit).

## Package Legitimacy Audit

> Phase 3 installs **no new runtime packages** — the entire loop is built on already-installed, already-verified libraries (Riverpod, Drift, flutter_svg, vector_math) plus Flutter framework primitives (`Listener`, `CustomPainter`, `PathMetric`, `AnimationController`).

| Package | Registry | Status | Disposition |
|---------|----------|--------|-------------|
| flutter_riverpod, riverpod_annotation, drift, flutter_svg, vector_math | pub.dev | Already installed & locked (P1/P2) | Approved — no install action |
| mocktail (OPTIONAL, dev-only) | pub.dev | Not installed; well-known mature mocking lib | `[ASSUMED]` — if the planner adds it, gate behind a `checkpoint:human-verify` and confirm version via `flutter pub add --dev mocktail` / pub.dev at plan time |
| rive | pub.dev | **REMOVED** — rejected for Phase 3 (violates S1-04 one-source-of-truth; adds dependency) | REMOVED |

**Packages removed:** rive (architectural reject, not a slop verdict).
**Packages flagged suspicious:** none.
*slopcheck was not run because no new runtime package is being introduced. If `mocktail` is added later, treat it as `[ASSUMED]` and verify at plan time.*

## Architecture Patterns

### System Architecture Diagram

```
                          ┌─────────────────────────────────────────────┐
   child finger/stylus    │  PracticeScreen  (Watch → Trace → Celebrate) │
   ───────────────────►   │  reachable via dev route / Home lesson card  │
                          └───────────────┬─────────────────────────────┘
                                          │ phase = state machine (D-10/D-04/D-07)
        ┌─────────────────────────────────┼──────────────────────────────────┐
        ▼ WATCH                            ▼ TRACE                             ▼ CELEBRATE
 ┌───────────────┐              ┌──────────────────────┐            ┌──────────────────┐
 │ StrokeOrder    │              │ StrokeCanvas (Listener)│           │ MasteryCelebration│
 │ Animation       │             │  • PointerDeviceKind   │           │  mascot + alif +  │
 │ (PathMetric +   │             │    filter (D-13)       │           │  ONE gold star +  │
 │  AnimationCtrl) │             │  • per-stroke points   │           │  "أحسنت" (D-08)   │
 │  ← resolved ref │             │    + timestamps        │           └──────────────────┘
 │    path (D-11)  │             │  • debug-finger flag   │
 └───────────────┘              └──────────┬────────────┘
        ▲ same resolved path                │ on POINTER-UP: submit stroke
        │ (one source of truth, S1-04)      ▼
        │                       ┌──────────────────────────────────────┐
        │                       │ practiceSessionController (Riverpod)   │
        │                       │  Notifier, autoDispose, .family(lesson)│
        │                       │  • holds attempts, current rep (n/3)   │
        │                       │  • retry-vs-advance, clean-rep count   │
        │                       └────────┬───────────────────┬──────────┘
        │                                │ score(stroke, ref) │ on 3rd clean rep
        │                                ▼                    ▼
        │              ┌──────────────────────────────┐  ┌──────────────────────┐
        │              │ GeometricStrokeScorer (Dart)  │  │ ProgressRepository    │
        │              │  1. resample child stroke      │  │  → Drift (D-09)       │
        │              │  2. normalize to 0..1 bbox     │  │  record alif mastery  │
        │              │  3. count / order / direction  │  │  + clean-rep count    │
        │              │  4. shape/extent/straightness  │  └──────────────────────┘
        │              │  5. → StrokeResult{pass, mistakeId?}
        │              └──────────┬───────────────────┘
        └─────── resolves ────────┘ reads alif via CurriculumRepository.getLetter("alif")
                                      mistakeId → commonMistakes[].feedback → l10n string

  ┌─ HandwritingRecognizer (interface) ── EMPTY SEAM in P3, ML Kit impl = Phase 4 (D-16) ─┐
  └──────────────────────────────────────────────────────────────────────────────────────┘

  Stroke points: IN-MEMORY ONLY (T-01-05). Only the mastery result is persisted.
```

### Recommended Project Structure (additive — follows existing `lib/` layout + research ARCHITECTURE.md)
```
lib/
├── core/scoring/
│   ├── geometric_stroke_scorer.dart   # pure Dart: count/order/direction/shape → StrokeResult
│   ├── stroke_resampler.dart          # resample to N points + normalize to 0..1 bbox
│   ├── reference_path.dart            # resolves letter.referenceStrokes → scored/animated path
│   │                                  #   (THE FINDING lives here: outline→centerline decision)
│   └── scoring_models.dart            # StrokeResult, MistakeId enum  (pure, no Flutter)
├── core/recognition/
│   └── handwriting_recognizer.dart    # abstract interface ONLY (D-16; no impl in P3)
├── data/
│   ├── progress_repository.dart       # interface
│   └── drift_progress_repository.dart # Drift impl (mastery + clean-reps, D-09)
├── features/practice/
│   ├── practice_screen.dart           # the Watch→Trace→Celebrate flow (evolve P1 spike OR new)
│   ├── widgets/stroke_canvas.dart     # Listener capture + stylus filter + dotted guide + ink
│   ├── widgets/stroke_order_animation.dart  # PathMetric pen-tip on the guide (D-11)
│   ├── widgets/feedback_panel.dart    # named fix / progress "Stroke X of N" (D-04)
│   └── widgets/mastery_celebration.dart     # dignified full-screen (D-08)
├── providers/
│   └── practice_providers.dart        # practiceSessionController + strokeCaptureProvider
└── config/debug_flags.dart            # allowFingerInput flag (D-13/D-14)
```
The existing `lib/screens/practice_screen.dart` is the **P1 spike** — the planner may evolve it in place or supersede it with `features/practice/`. Keep its proven `Listener` + smoothed-`CustomPainter` ink as the foundation.

### Pattern 1: Low-level stroke capture with stylus filtering (extends the P1 spike)
**What:** Capture each pen-down→pen-up as one ordered point list with timestamps, filtering by `PointerDeviceKind`. The P1 spike already does the capture; add the kind filter + debug flag.
**When to use:** The trace canvas. Never `GestureDetector` (Pitfall 2).
```dart
// Source: pattern derived from existing lib/screens/practice_screen.dart (P1)
//         + Flutter PointerEvent docs [CITED: api.flutter.dev PointerEvent]
Listener(
  behavior: HitTestBehavior.opaque,
  onPointerDown: (e) {
    if (!_accept(e.kind)) return;          // stylus-only in prod (D-13)
    _begin(StrokePoint(_local(e.position), e.timeStamp)); // capture t (D-04/order)
  },
  onPointerMove: (e) { if (_accept(e.kind)) _extend(...); },
  onPointerUp:   (e) { if (_accept(e.kind)) _submitStroke(); }, // → scorer
  onPointerCancel: (e) => _cancelStroke(),  // honor cancel = palm/lift
  child: CustomPaint(painter: _GuideAndInkPainter(...)),
);

// D-13/D-14: prod accepts only stylus; debug flag opens finger so the owner
// (finger-only test hardware) can run the whole loop.
bool _accept(PointerDeviceKind k) =>
    k == PointerDeviceKind.stylus ||
    (kDebugMode && DebugFlags.allowFingerInput && k == PointerDeviceKind.touch);
```
**Palm rejection (D-13):** comes free in production — a resting palm is `PointerDeviceKind.touch`, which the prod filter drops. Also honor `onPointerCancel`. No size-based heuristic needed.

### Pattern 2: Stroke-order animation from the SAME reference path (S1-04, D-11)
**What:** Build a `Path` from the **resolved** reference points, then animate a pen-tip + progressive dotted draw along it using `PathMetric`. Reuses the exact geometry the scorer uses → one source of truth.
**When to use:** The "Watch me write" step; auto-play once then Replay (D-10).
```dart
// Source: Flutter dart:ui PathMetric [CITED: api.flutter.dev/flutter/dart-ui/PathMetric-class.html]
final Path ref = ReferencePath.resolve(letter.referenceStrokes); // SAME as scorer
final PathMetric metric = ref.computeMetrics().first;
// in CustomPainter.paint, with t = AnimationController.value (0..1):
final Path drawn = metric.extractPath(0, metric.length * t);
canvas.drawPath(drawn, _inkPaint);
final Tangent? tip = metric.getTangentForOffset(metric.length * t);
if (tip != null) canvas.drawCircle(tip.position, penTipR, _tipPaint); // moving pen-tip
// gold start-dot at metric.getTangentForOffset(0).position  (the numbered "1", D-11)
```
> Note (ties to THE FINDING): if `ReferencePath.resolve` returns the raw outline, the pen-tip will trace *around* the alif (down one side, across, up the other) — visually wrong for "watch me write alif as one downstroke." The resolved path for the animation should be the **centerline** for a single-stroke letter. Resolving Q1 fixes both scorer and animation at once.

### Pattern 3: Clean-rep counting → mastery (D-07, S1-10)
**What:** `practiceSessionController` tracks consecutive clean reps for alif; on the 3rd clean rep (`letter.cleanRepsToAdvance`), transition to Celebrate and persist mastery. Misses do not consume a rep (D-05 — unlimited gentle retries); reps count only clean passes.
```dart
// Source: pattern from research ARCHITECTURE.md §practiceSessionController + D-07
void onStrokeResult(StrokeResult r) {
  if (r.passed) {
    _cleanReps++;
    if (_cleanReps >= letter.cleanRepsToAdvance) {   // 3 for alif
      _progressRepo.recordMastery(letterId: 'alif', cleanReps: _cleanReps); // D-09
      _phase = Phase.celebrate;                       // dignified full-screen (D-08)
    } else {
      _phase = Phase.traceNextRep;                    // "2 of 3", clear ink
    }
  } else {
    _lastMistakeId = r.mistakeId;                     // highlight stroke + named fix (D-05)
    _phase = Phase.showFix;                           // hold; retry SAME stroke; no counter
  }
}
```

### Pattern 4: Drift schema for mastery + clean-reps (D-09)
**What:** A small table recording per-letter mastery; survives restart (P1 proved persist/read). The P1 `AppDatabase` has `schemaVersion = 1` and one `AppSettings` table — Phase 3 adds a table and **must bump `schemaVersion` to 2 + add a migration** (Drift requires it; P1 used v1).
```dart
// Source: pattern from research ARCHITECTURE.md §ProgressRepository + Drift docs
class LetterMastery extends Table {
  TextColumn get letterId => text()();           // "alif"
  IntColumn  get cleanReps => integer()();        // 3
  DateTimeColumn get masteredAt => dateTime()();
  @override Set<Column> get primaryKey => {letterId};
}
// In AppDatabase: @DriftDatabase(tables: [AppSettings, LetterMastery]);
//   schemaVersion => 2;  + MigrationStrategy.onUpgrade { m.createTable(letterMastery) }
```
**Security (T-01-05):** persist ONLY the mastery result (letterId, cleanReps, timestamp). **Never** persist, log, or transmit the captured stroke points — they stay in memory and are discarded on dispose (the P1 spike already enforces this).

### Pattern 5: Mistake → named fix (S1-05, Pitfall 7)
**What:** The scorer emits a `MistakeId` (enum mirroring alif's three `commonMistakes[].id`/`.check`). The presentation layer looks up the warm `feedback` string. A generic fallback covers a miss with no matching named mistake — but the fallback must still be specific-ish, never "Oops, try again."
```dart
// alif's authored mistakes [VERIFIED: assets/curriculum/letters.json]:
//   too_short      / strokeLengthBelowThreshold       → "Your alif needs to be taller — draw it from the top all the way down."
//   wrong_direction/ strokeDirectionInverted          → "Start your alif at the top and come down — not from the bottom up."
//   too_curved     / strokeCurvatureExceedsThreshold  → "Alif is a straight line — try to keep it as straight as you can."
// Fallback (l10n, NOT generic): "Something looks off — try again, slower this time."
```
> The `check` strings are the contract between data and code. The scorer's predicates must be named to match (`strokeLengthBelowThreshold`, `strokeDirectionInverted`, `strokeCurvatureExceedsThreshold`). These are **scalar-feature checks on the child's stroke** (extent, direction sign, straightness residual) — they do NOT require comparing against the outline point list (which is why option 3 works as a first-cut). Map `check` → predicate in `reference_path.dart` / scorer.

### Anti-Patterns to Avoid
- **Feeding the raw 64-point outline into a path-distance metric against the child's single down-stroke** (THE FINDING). Resolve the centerline first.
- **`GestureDetector` for the trace canvas** — drops stroke order/count/kind (Pitfall 2). The P1 spike correctly uses `Listener`; keep it.
- **One mega-provider holding live points + session + lesson** — ~60 repaints/sec thrash the tree (Anti-Pattern 3). Split `strokeCaptureProvider` (canvas-local, high-frequency) from `practiceSessionController` (once per stylus-up). The P1 spike kept points in widget `State`; that is acceptable too — just do NOT lift them into the session controller.
- **Generic "Oops, try again!" feedback** — violates the tutor voice + PLAT-03 (Pitfall 7). Always name the fix.
- **Any running star total / weekly tally / "+3 today" / "See journey" / confetti** — present in the design mockups (`05-celebration-final.png` shows "TOTAL 42 stars +3 today" and 3 stars at top) but **omitted per D-03/D-08**. Build the dignified core only.
- **Rendering the guide letter as `Text('ا')`** — use the reference path in a `CustomPainter` (Pitfall 5 / Anti-Pattern 2). One source of truth.
- **Strict pixel-perfect scoring** — children's motor control can't meet it (Pitfall 3). Ship lenient (D-15).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Progressive draw of a stroke / pen-tip position along a path | A custom arc-length parameterizer | `Path.computeMetrics()` → `PathMetric.extractPath` + `getTangentForOffset` | dart:ui gives arc-length sampling + tangent (pen-tip direction) for free. [CITED: dart:ui PathMetric] |
| Smooth ink rendering | Raw polyline | Quadratic-midpoint smoothing — **already implemented** in P1 `_InkPainter._paintStroke` | Reuse the proven P1 path. |
| 2D vector math (dot product, projection, distance) | Hand-rolled trig | `vector_math` (`Vector2`) — already a transitive dep | Direction sign + straightness residual are vector ops. |
| Local persistence with migrations | SharedPreferences blobs | Drift table + `schemaVersion` bump + migration | Typed, migratable; P1 seam exists. |
| Stylus vs finger distinction + palm rejection | Touch-size heuristics | `PointerDeviceKind` filter (prod = stylus only) | Palm rejection is free when filtering to stylus (D-13). |
| Letter identity check | Custom classifier | Leave the `HandwritingRecognizer` interface empty; ML Kit fills it in Phase 4 | D-16 — not in scope; do not build. |

**Key insight:** The scorer's *geometry primitives* (resampling, normalization, vector projection, path metrics) are all available; what is genuinely custom is the **pedagogical logic** — which scalar features map to which named mistake, and the lenient thresholds. That logic is small and belongs in pure Dart so the owner's mother can validate it via tests in Phase 4 (Pitfall 6: pedagogy as data + tested predicates, not magic constants).

## Runtime State Inventory

> Phase 3 is **mostly greenfield code** (new scorer, new widgets, new Drift table) — but it touches one piece of existing runtime state: the on-device Drift DB.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Existing `qalam.db` (Drift) with `app_settings` table + `skeletonProof` sentinel row (P1). Adding `LetterMastery` requires `schemaVersion` 1→2 + an `onUpgrade` migration so existing installs don't crash. | Code edit (schema + migration); existing rows preserved. |
| Live service config | None — no external services in v1 (local-only, D-16, no Firebase). | None — verified by CLAUDE.md "v1 local-only" + ARCHITECTURE.md. |
| OS-registered state | None — no background tasks, no notifications (NTH-03 out of scope). | None. |
| Secrets/env vars | None — no API keys (tutor is v2; key never client-side). | None — verified by CLAUDE.md Decided. |
| Build artifacts | `*.g.dart` codegen (riverpod_generator, drift_dev) will regenerate for new providers/tables. Stale `.g.dart` after adding the table → run `dart run build_runner build`. | Re-run build_runner after schema/provider changes. |

## Common Pitfalls

### Pitfall 1: Scoring the outline contour as if it were a centerline (THE FINDING)
**What goes wrong:** Comparing the child's single straight down-stroke against the 64-point closed outline with DTW/Fréchet/Procrustes yields nonsense — wrong length ratio, no direction reversal in the child stroke, "curvature" of a loop vs a line.
**Why it happens:** The reference *looks* like a usable path (`StrokeSpec.points`), the label says `topToBottom`, and the checks have skeleton names — easy to assume it's a centerline.
**How to avoid:** Resolve Q1 first. Derive/re-author a centerline; score the child's stroke against scalar features (extent, direction sign, straightness) or against the derived centerline — never the raw outline.
**Warning signs:** Pass rate ~0% on clearly-correct alif; "too curved" firing on a straight line; scorer comparing `child.points` to `letter.referenceStrokes[0].points` directly.

### Pitfall 2: Scoring too strict → child quits (Pitfall 3 in project research)
**What goes wrong:** Tolerances tuned on adult strokes reject good-faith child attempts.
**How to avoid:** Normalize (scale/translate child stroke into the reference bbox) before any comparison; resample to fixed N; ship **lenient** thresholds (D-15); calibration is Phase 4 with the owner's mother. Keep direction/order firm, shape generous (Pitfall 4).
**Warning signs:** Hardcoded tight tolerance; tested only on adult input.

### Pitfall 3: Anti-gamification erosion (Pitfall 7 in project research, PLAT-03)
**What goes wrong:** The design mockups *contain* a star counter ("⭐ 39/42"), "stars this week", weekly bar, "+3 today", "See journey", and three stars on the mastery screen. Building them faithfully would re-introduce the rejected gamification.
**How to avoid:** D-03/D-08 — omit the header counter, weekly tally, totals, "+N today". Celebration = mascot + mastered alif + **ONE** settling gold star + warm line + Back home. No confetti, no sound blast, no Journey button (Phase 6).
**Warning signs:** Any number that accumulates; a star that means "score" not "mastery"; generic praise.

### Pitfall 4: Drift migration omitted
**What goes wrong:** Adding `LetterMastery` without bumping `schemaVersion`/migration → schema mismatch crash on existing installs (P1 shipped v1).
**How to avoid:** `schemaVersion => 2` + `MigrationStrategy(onUpgrade: ...createTable(letterMastery))`. The P1 test pattern (inject `NativeDatabase.memory()`, simulate restart) extends to verify the migration + mastery round-trip.

### Pitfall 5: Stylus filter blocks the owner's finger-only testing (D-14)
**What goes wrong:** Stylus-only filter silently drops all input on the owner's finger-only hardware → the loop is untestable.
**How to avoid:** The debug-finger flag (D-13/D-14) must be **on by default in debug builds** or trivially toggled, and the loop fully exercisable with a finger. Make this explicit in the plan; verify in a widget test that synthesized `touch` pointers drive the canvas when the flag is set.

## Code Examples

### Resample + normalize a captured stroke (the pre-comparison step)
```dart
// Source: standard $-recognizer family preprocessing [ASSUMED: training knowledge of
//   $1/$P gesture recognizers] — resample to N equidistant points, then scale/translate
//   into the unit box so a small-but-correct stroke isn't penalized for size/position.
List<Offset> resample(List<Offset> pts, int n) { /* arc-length equidistant sampling */ }
List<Offset> normalizeToUnitBox(List<Offset> pts) { /* translate min→0, scale max→1 */ }
// Then features for alif's first-cut checks:
//   extent   = normalized vertical span               → strokeLengthBelowThreshold
//   dirSign  = sign(endY - startY)                     → strokeDirectionInverted
//   straight = max perpendicular distance from the     → strokeCurvatureExceedsThreshold
//              best-fit line through the points
```

### Drift mastery round-trip test (extends P1 pattern)
```dart
// Source: existing test/data/app_database_test.dart pattern (inject memory executor,
//   close first instance, reopen to prove persistence). [VERIFIED: P1 test file exists]
test('alif mastery survives restart', () async {
  final exec = NativeDatabase.memory();
  final db1 = AppDatabase(exec);
  await ProgressRepository(db1).recordMastery(letterId: 'alif', cleanReps: 3);
  await db1.close();                       // injected executor survives (P1 behavior)
  final db2 = AppDatabase(exec);
  expect(await ProgressRepository(db2).isMastered('alif'), isTrue);
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `GestureDetector.onPanUpdate` for drawing | `Listener` + raw `PointerEvent` (kind/pressure/timestamp) | Long-standing Flutter guidance | Already adopted in P1 — keep. |
| ML Kit `score` as the pass gate | Custom geometric scorer is the gate; ML Kit (P4) is identity-only | Project decision (ARCHITECTURE.md, PITFALLS.md) | P3 ships scorer-only; ML Kit deferred (D-16). |
| Rive/Lottie for stroke-order demos | Custom `PathMetric` animation from the scoring path | This phase's S1-04 constraint | One source of truth; no extra dep. |

**Deprecated/outdated:**
- STACK.md's "Flutter 3.44.x" — the **installed** SDK is **3.41.9**; plan against 3.41.9 and the 2.31-line Drift pins (per STATE.md compatibility decision). Do not bump versions to match stale research.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Scalar-feature first-cut scoring (extent/direction/straightness) is sufficient for a *lenient* alif gate without a path-distance metric | Standard Stack / Pattern 5 | If insufficient, Phase 4 adds DTW/Fréchet against a centerline — low risk since P4 owns calibration. |
| A2 | The `$1/$P`-style resample+normalize preprocessing applies cleanly to single-stroke Arabic letters | Code Examples | Standard technique; risk low for a straight stroke; revisit for multi-stroke/curved letters in later phases. |
| A3 | rive ^0.14.7 (rejected anyway) — version from prior STACK.md, not re-verified | Alternatives | None — Rive is rejected for P3. |
| A4 | The three design "stars" at the top of `05-celebration-final.png` represent the 3 clean reps, not 3 separate awards | Common Pitfalls P3 / Q2 | If misread, celebration may show the wrong star semantics — flagged as Q2 for owner. |
| A5 | Drift `onUpgrade` migration is required (P1 shipped schemaVersion 1) | Pattern 4 / Pitfall 4 | Verified P1 `schemaVersion => 1` in code; risk low. |

## Open Questions

1. **How should alif's reference path be interpreted for scoring AND the animation? (THE FINDING — blocking)**
   - What we know: `referenceStrokes[0].points` is a 64-point closed glyph **outline**; the `direction` and three `commonMistakes` checks assume a **centerline**. [VERIFIED: letters.json inspection]
   - What's unclear: which of the three resolution options the owner wants (derive centerline / re-author data / score on scalar features only).
   - Recommendation: Put the three options to the owner in `/gsd-discuss` or as the first planning decision. **Recommended:** option 3 (scalar-feature scoring) for the lenient P3 first-cut, plus a derived-centerline (option 1) `ReferencePath.resolve` for the *animation* so the pen-tip draws a single downstroke not a loop. Phase 4 can upgrade to a true centerline + path-distance metric. This is a curriculum-data-semantics question — it may also touch the Phase-2 sign-off boundary, so loop in the owner (and possibly his mother).

2. **One settling star vs three stars in the celebration design.**
   - What we know: D-07/D-08 say "3 clean reps → **1** mastery star ... one gold star settling in." The mockup `05-celebration-final.png` shows **three** gold stars across the top + a running total.
   - What's unclear: whether the three design stars are the 3 reps (visual) or 3 awards (semantic).
   - Recommendation: Follow D-08 literally — **one** mastery star = "you mastered alif." If the owner wants the three reps visualized (1/3, 2/3, 3/3 ticking up during tracing), that is a progress indicator during Trace, distinct from the single mastery star at Celebrate. Confirm with owner; default to one star.

3. **Should `practiceSessionController` keep live stroke points, or stay widget-local State?**
   - What we know: ARCHITECTURE.md prescribes a separate `strokeCaptureProvider`; the P1 spike kept points in widget `State` and it worked.
   - Recommendation: Either is acceptable (Claude's Discretion). For a Dart-newcomer owner, keeping high-frequency points in widget `State` (as P1 does) and submitting only the completed stroke to the controller is the lower-magic path. Do NOT put live points in the session controller.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | everything | ✓ | 3.41.9 stable | — |
| Dart | everything | ✓ | (bundled w/ 3.41.9) | — |
| flutter_riverpod / drift / flutter_svg / vector_math | scorer, session, persistence, glyph | ✓ | locked in pubspec.lock | — |
| build_runner + generators | `.g.dart` for new providers/table | ✓ | ^2.15.0 / 4.0.3 / drift_dev 2.31 | — |
| ML Kit Arabic model | identity check | n/a | — | **Not needed in P3** (D-16 defers to P4) |
| adb / Android emulator | on-device manual stylus UAT | ✗ (`adb MISSING`) | — | Owner runs on **finger-only** device (D-13/D-14); manual UAT uses the debug-finger flag. Automated widget/golden tests cover the rest without a device. |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `adb`/emulator absent → rely on the debug-finger flag + widget/golden tests; final stylus behavior is a Phase-4/UAT concern, not a P3 blocker. If on-device verification is wanted, the planner should add an "install Android SDK platform-tools / start emulator" prep step or defer device UAT to the owner.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + golden tests; `test/flutter_test_config.dart` loads bundled Arabic TTFs into the headless engine (P1 pattern — required so Arabic goldens don't render tofu) |
| Config file | `analysis_options.yaml`; `test/flutter_test_config.dart` (font loading) |
| Quick run command | `flutter test test/core/scoring/` (pure-Dart scorer — fast, no widget harness) |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| S1-05 | Scorer passes a clean synthetic alif down-stroke | unit | `flutter test test/core/scoring/geometric_stroke_scorer_test.dart` | ❌ Wave 0 |
| S1-05 | Scorer fails too-short stroke → `too_short` mistake id | unit | same file | ❌ Wave 0 |
| S1-05 | Scorer fails bottom-up stroke → `wrong_direction` | unit | same file | ❌ Wave 0 |
| S1-05 | Scorer fails very-curved stroke → `too_curved` | unit | same file | ❌ Wave 0 |
| S1-05 | Resample+normalize: small correct stroke still passes (size-invariant) | unit | `test/core/scoring/stroke_resampler_test.dart` | ❌ Wave 0 |
| S1-05 | Each `MistakeId` maps to the authored `commonMistakes[].feedback` (no generic "try again") | unit | `test/core/scoring/mistake_mapping_test.dart` | ❌ Wave 0 |
| S1-05/D-13 | Canvas accepts stylus; rejects touch in prod; accepts touch when debug-finger flag set | widget | `test/features/practice/stroke_canvas_test.dart` (synthesize pointer events) | ❌ Wave 0 |
| S1-04 | Animation path == resolved scoring path (one source of truth) | unit | `test/core/scoring/reference_path_test.dart` | ❌ Wave 0 |
| S1-04 | "Watch me write" auto-plays once then offers Replay (D-10) | widget | `test/features/practice/stroke_order_animation_test.dart` | ❌ Wave 0 |
| S1-10/D-07 | 3 clean reps → mastery; misses don't consume a rep | unit | `test/features/practice/session_controller_test.dart` (ProviderContainer) | ❌ Wave 0 |
| S1-10/D-09 | Mastery persists to Drift and survives a simulated restart | integration (in-memory Drift) | `test/data/progress_repository_test.dart` | ❌ Wave 0 |
| S1-10/D-08/PLAT-03 | Celebration shows ONE star, mascot, alif, warm line; NO counter/confetti/Journey button | golden + widget | `test/features/practice/mastery_celebration_golden_test.dart` | ❌ Wave 0 |
| PLAT-03 | Trace screen omits header star counter, "Play sound", "Mark correct" | widget | `test/features/practice/practice_screen_test.dart` | ❌ Wave 0 |
| S1-05 (latency) | Scorer completes well under budget on representative input | unit (timed) | within `geometric_stroke_scorer_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/core/scoring/` (the pure-Dart crown jewel — fast).
- **Per wave merge:** `flutter test` (full suite incl. goldens).
- **Phase gate:** Full suite green + manual finger UAT of the whole loop (Watch→Trace→miss→fix→retry→3 clean reps→celebration→restart→mastery remembered) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/core/scoring/geometric_stroke_scorer_test.dart` — S1-05 scorer behavior (pass + 3 mistake cases)
- [ ] `test/core/scoring/stroke_resampler_test.dart` — size/position invariance
- [ ] `test/core/scoring/reference_path_test.dart` — animation/scorer path identity + the Q1 resolution
- [ ] `test/core/scoring/mistake_mapping_test.dart` — named-fix mapping
- [ ] `test/features/practice/stroke_canvas_test.dart` — stylus filter + debug-finger flag
- [ ] `test/features/practice/session_controller_test.dart` — clean-rep → mastery
- [ ] `test/data/progress_repository_test.dart` — Drift mastery round-trip + migration
- [ ] `test/features/practice/mastery_celebration_golden_test.dart` — dignified celebration golden (loads TTFs via flutter_test_config.dart)
- [ ] Synthetic stroke fixtures (clean alif, too-short, inverted, curved) — shared test helper
- [ ] No framework install needed (flutter_test present); add `mocktail` dev-dep ONLY if a real mock is required.

## Security Domain

> `security_enforcement: true`, ASVS level 1. Phase 3 is local-only, no network, no auth, no new external input surface — most ASVS categories don't apply. The live concern is **children's data sensitivity** (CLAUDE.md, threat T-01-05).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth in v1 (local single child). |
| V3 Session Management | no | No sessions/accounts. |
| V4 Access Control | no | No remote resources; parent area is Phase 9. |
| V5 Input Validation | partial | Pointer input is geometric, not parsed/executed; curriculum JSON is validated by typed models (P2). No untrusted external input in P3. |
| V6 Cryptography | no | Nothing to encrypt in P3 (no secrets; mastery row is non-sensitive). |
| (Child-data privacy) | **yes** | T-01-05: captured stroke points **in-memory only** — never persisted, logged, or transmitted; discarded on dispose. Only the non-sensitive mastery result (letterId, cleanReps, timestamp) is written to app-private Drift. No analytics, no telemetry, no network. |

### Known Threat Patterns for {Flutter on-device child app}
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stroke points logged/persisted for debugging then shipped | Information Disclosure | Keep stroke points in memory only; no `print`/`debugPrint` of points; strip any dev logging from release (P1 already enforces in the spike). |
| Mastery data treated as non-sensitive PII leak | Information Disclosure | Store only letterId/cleanReps/timestamp in app-private storage; no child name in P3 (profiles are Phase 5). |
| Accidental network call in a "local-only" phase | — | No HTTP client, no Firebase, no ML Kit network in P3 (D-16). The `HandwritingRecognizer` seam is an empty interface — it makes no calls. |

## Project Constraints (from CLAUDE.md)

- **Flutter + Dart, Android-only.** No iOS work (no PencilKit). RTL, tablet-first.
- **v1 is local-only, on-device:** no Firebase, no Claude tutor, no network in the scoring path. The tutor **never** runs client-side.
- **Handwriting recognition = ML Kit Digital Ink (validated)** — but **deferred to Phase 4** here (D-16); P3 is a pure geometric scorer.
- **Riverpod only** — reject any BLoC/GetX. Codegen `@riverpod` is the established pattern.
- **Python over TypeScript** for backend/tooling (n/a this phase — all Dart). Explain Dart choices plainly; keep the magic low (owner is new to Dart).
- **Anti-gamification (binding):** mascot = the tutor's persona (pedagogical), not a game character. Stars = mastery markers only — NO running totals, NO weekly tallies, NO streaks, NO badges, NO "+N keep going", NO leaderboards, NO confetti spam, NO timers. Feedback is specific, never generic.
- **Brand hard-rules** (`docs/design/kit/project/SKILL.md`): Gold (`#F2A60C`) = rewards only (never a button/heading). **No red** — errors are coral (`#FF8A6B`), framed warmly. **No emoji, no unicode pseudo-icons** (⭐ ✓ ✗) — use brand glyphs in `assets/icons/`. Western numerals everywhere. Touch targets ≥64px. Arabic in Noto Naskh Arabic, RTL islands, fully vocalized.
- **Child safety:** minimum child data, private by default, treat children's data as sensitive (T-01-05).
- **Curriculum is the owner's mother's domain** — do not invent pedagogy; structure it. The Q1 reference-path resolution may touch signed-off data → loop in the owner.
- **Domain agents:** delegate to (or adopt the role of) `flutter-expert` (stylus/ML Kit seam), `flutter-state-management` (Riverpod), `flutter-ui-implementer`/`flutter-ui-designer` (the trace flow from mockups), `flutter-testing` (tests), `code-reviewer` (gate). Project agents outrank global. The **Decided section overrides any specialist default** — flag contradictions (BLoC, iOS, client-side key, gamification chrome).
- **GSD workflow:** all file changes go through a GSD command; planning artifacts stay in sync.

## Sources

### Primary (HIGH confidence)
- `assets/curriculum/letters.json` — alif entry: 1 referenceStroke (64-point **outline contour**, `topToBottom`), `cleanRepsToAdvance: 3`, 3 authored `commonMistakes`, `signedOff: true`, `mistakesStatus: authored` — **inspected directly** (THE FINDING).
- `lib/screens/practice_screen.dart` — P1 stylus spike: `Listener` capture, per-stroke point lists, quadratic-smoothed `CustomPainter` ink, in-memory-only strokes (T-01-05) — read directly.
- `lib/data/app_database.dart` — Drift `schemaVersion = 1`, `AppSettings`, injected-executor restart pattern — read directly.
- `lib/models/letter.dart`, `lib/data/curriculum_repository.dart` — typed models + `getLetter("alif")` loader — read directly.
- `.planning/research/ARCHITECTURE.md`, `PITFALLS.md`, `STACK.md` — prior project research (scoring pipeline, two-judge model, ML Kit limits, stack) — read directly.
- `docs/design/kit/project/screenshots/{02,03}-flow.png`, `05-celebration-final.png`, `SKILL.md`, `colors_and_type.css` — design source of truth + brand rules — viewed/read directly.
- `pubspec.lock`, `pubspec.yaml`, `flutter --version` — installed versions (Flutter 3.41.9, Drift 2.31 line) — verified.

### Secondary (MEDIUM confidence)
- Flutter `Listener`/`PointerEvent`, `dart:ui` `PathMetric`/`Tangent` — framework APIs [CITED: api.flutter.dev] cross-referenced with the working P1 spike.

### Tertiary (LOW confidence)
- `$1/$P`-family resample+normalize preprocessing — training knowledge [ASSUMED]; standard for single-stroke gesture scoring, to be calibrated in Phase 4.
- rive ^0.14.7 version — from prior STACK.md, not re-verified (Rive rejected for P3 anyway).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already installed and version-verified against pubspec.lock; no new packages.
- Architecture / capture / animation / persistence: HIGH — strong prior art in P1/P2 code; framework primitives verified.
- Scorer *method*: HIGH (survey) / MEDIUM (exact data semantics) — blocked on Q1 (outline-vs-centerline); resolved options provided.
- Pitfalls: HIGH — derived from project research + direct data/code inspection.

**Research date:** 2026-06-01
**Valid until:** ~2026-07-01 (stable stack; the only volatile item is the Q1 owner decision, which gates planning regardless of date).
