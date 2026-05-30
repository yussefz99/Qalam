# Architecture Research

**Domain:** On-device children's handwriting-learning tablet app (Flutter / Android / RTL, Riverpod, ML Kit Digital Ink, local-only v1)
**Researched:** 2026-05-30
**Confidence:** HIGH on Flutter/Riverpod/persistence structure; MEDIUM-HIGH on the scoring pipeline (ML Kit capabilities verified; the geometric scorer is a design we specify, not an off-the-shelf component)

---

## Executive Take (read first)

Three architectural decisions drive everything below:

1. **ML Kit Digital Ink does NOT score handwriting quality or stroke order.** Verified: it
   takes an `Ink` (list of `Stroke`, each a list of `StrokePoint{x, y, t}`) and returns
   `RecognitionCandidate{text, score}` — i.e. *"which letter did this look like?"*, not
   *"was this baa's bowl deep enough?"* and not *"did they start at the right place?"*.
   Therefore v1 needs **two** judges working on the same captured `Ink`: ML Kit for
   **letter-identity confirmation**, and a **geometric stroke-order/shape comparator we
   build** for the per-stroke, child-friendly feedback that is the actual product. The
   curriculum's "3–4 common mistakes per letter" are encoded as checks in *that* comparator,
   not in ML Kit.

2. **The whole loop is on-device and synchronous-feeling.** No network in the scoring path.
   Target latency from stylus-up to feedback is **< 300 ms** (see budget below). This is
   easily achievable because the geometric scorer is cheap math and ML Kit recognition
   runs in tens of ms once the model is downloaded.

3. **The v1→v2 seam is a repository interface, not a feature flag.** Persistence and the
   "where does feedback come from" boundary are defined as abstract interfaces in v1 with
   local implementations. v2 swaps in Firestore-backed repos and an HTTP-backed tutor
   feedback source behind the *same* interfaces. No premature Firebase, no rework.

---

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│  PRESENTATION  (lib/features/*/presentation — widgets + screens)           │
│  ┌────────────────┐ ┌──────────────┐ ┌───────────┐ ┌──────────────────┐   │
│  │ StrokeCanvas    │ │ GuideLetter  │ │ Feedback  │ │ ParentDashboard  │   │
│  │ (captures Ink)  │ │ (dotted RTL) │ │ Panel     │ │ (PIN-gated)      │   │
│  └───────┬─────────┘ └──────────────┘ └─────┬─────┘ └────────┬─────────┘   │
├──────────┼──────────────────────────────────┼────────────────┼────────────┤
│  APPLICATION  (Riverpod providers/notifiers — orchestration + state)       │
│  ┌────────────────────┐ ┌────────────────────┐ ┌────────────────────────┐ │
│  │ practiceSession     │ │ todaysLesson        │ │ currentChild           │ │
│  │ Controller (Notifier)│ │ Provider            │ │ Provider               │ │
│  └─────────┬───────────┘ └─────────┬──────────┘ └───────────┬────────────┘ │
├────────────┼───────────────────────┼──────────────────────┼───────────────┤
│  DOMAIN  (lib/features/*/domain + lib/core/scoring — pure Dart, no Flutter) │
│  ┌──────────────────┐ ┌─────────────────────────┐ ┌──────────────────────┐ │
│  │ ScoringService   │ │ LessonProgressionService│ │ Models: Letter,      │ │
│  │ (orchestrates ↓) │ │ (pass? unlock next?)    │ │ Lesson, Session,     │ │
│  └───┬──────────┬───┘ └─────────────────────────┘ │ Stroke, ChildProfile │ │
│      │          │                                  └──────────────────────┘ │
│  ┌───▼──────┐ ┌─▼────────────────────┐                                      │
│  │ Geometric│ │ HandwritingRecognizer │  ← interfaces (abstract)            │
│  │ Stroke   │ │ (interface)           │                                      │
│  │ Scorer   │ └───────────────────────┘                                      │
│  └──────────┘                                                                │
├──────────────────────────────────────────────────────────────────────────┤
│  DATA  (lib/features/*/data — repositories + sources)                       │
│  ┌────────────────────────┐ ┌──────────────────┐ ┌───────────────────────┐ │
│  │ CurriculumRepository   │ │ ProgressRepository│ │ MlKitRecognizer       │ │
│  │ (loads bundled JSON)   │ │ (interface)       │ │ (impl of interface)   │ │
│  └────────┬───────────────┘ └────────┬─────────┘ └──────────┬────────────┘ │
├───────────┼─────────────────────────┼────────────────────────┼─────────────┤
│  PLATFORM / STORAGE                                                          │
│  ┌─────────────────┐ ┌──────────────────────┐ ┌────────────────────────┐   │
│  │ assets/          │ │ Drift (SQLite)        │ │ google_mlkit_digital_  │   │
│  │ curriculum/*.json│ │ local profiles+progress│ │ ink_recognition + audio│   │
│  │ + audio/*.mp3    │ │                       │ │ player (audioplayers)  │   │
│  └─────────────────┘ └──────────────────────┘ └────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **StrokeCanvas** | Capture stylus input as a `List<Stroke>`; render the child's ink live; emit completed `Ink` on stylus-up. Knows nothing about scoring. | `Listener`/`GestureDetector` + `CustomPainter`; pointer events → `StrokePoint{x,y,t}` |
| **GuideLetter** | Render the dotted reference glyph (correct positional form: isolated/initial/medial/final) behind the canvas. | `CustomPainter` drawing the reference vector path; NOT a `Text` widget (see Anti-Patterns) |
| **FeedbackPanel** | Display deterministic feedback (the star, the specific fix, replay-stroke-order button). Renders; never computes. | Stateless widget bound to session state |
| **practiceSessionController** | The session aggregate: holds attempts, current letter index, accumulated score; calls `ScoringService` on each stylus-up; decides "retry vs advance". | Riverpod `Notifier` (autoDispose, scoped to a lesson) |
| **todaysLessonProvider** | Resolve "what is today's lesson" for the current child (next unlocked lesson). | Riverpod `FutureProvider` reading `CurriculumRepository` + `ProgressRepository` |
| **currentChildProvider** | Hold the active child profile (id, nickname, avatar, grade). | Riverpod `Notifier`, app-scoped |
| **ScoringService** | Orchestrate scoring: run geometric scorer + ML Kit recognizer on the same `Ink`, fuse into one child-friendly `StrokeFeedback`. Pure domain. | Plain Dart class, injected via provider |
| **GeometricStrokeScorer** | The real feedback engine: compare captured strokes to the letter's reference path — stroke count, order, direction, shape deviation, the curriculum's named common mistakes. | Pure Dart math (resampling + Procrustes/Fréchet-style distance) |
| **HandwritingRecognizer** (interface) | Abstract "what letter is this ink?". v1 impl wraps ML Kit. | `abstract interface class` + `MlKitRecognizer` |
| **LessonProgressionService** | "Did they pass? unlock the next lesson?" using curriculum's clean-reps-to-advance rule. | Pure Dart |
| **CurriculumRepository** | Load + parse bundled curriculum JSON into typed models; cache in memory. | Reads `rootBundle`, decodes JSON |
| **ProgressRepository** (interface) | Persist/query child profiles, lesson completion, scores, mistake tallies. | Interface + `DriftProgressRepository` (v1) |
| **Drift DB** | Local SQLite storage for profiles + progress. | `drift` package |

---

## Recommended Project Structure

Use a **light feature-first layout** with a shared `core/`. This is the Flutter community
default for Riverpod apps of this size, and it keeps the v1→v2 seam visible (repositories
live behind interfaces in `domain/`, implementations in `data/`).

```
lib/
├── main.dart                       # bootstrap: ProviderScope, DB init, model warm-up
├── app.dart                        # MaterialApp.router, RTL Directionality, theme
│
├── core/                           # cross-feature, no feature owns these
│   ├── scoring/                    # THE on-device feedback engine (pure Dart)
│   │   ├── geometric_stroke_scorer.dart
│   │   ├── stroke_resampler.dart   # normalize point density before comparison
│   │   ├── shape_distance.dart     # Procrustes / mean-point distance
│   │   └── scoring_service.dart    # fuses geometric + recognizer → StrokeFeedback
│   ├── recognition/
│   │   ├── handwriting_recognizer.dart    # abstract interface
│   │   └── mlkit_recognizer.dart          # ML Kit impl (v1)
│   ├── persistence/
│   │   ├── app_database.dart        # Drift DB definition
│   │   └── tables.dart
│   ├── audio/audio_service.dart     # pronunciation playback
│   ├── routing/app_router.dart      # go_router config
│   └── theme/                       # colors, text styles, Arabic font setup
│
├── models/                         # immutable domain models (pure, no Flutter)
│   ├── letter.dart                 # + LetterForm, StrokeSpec, CommonMistake
│   ├── lesson.dart
│   ├── exercise.dart               # sentence-building + grammar exercise types
│   ├── session.dart                # + Attempt, StrokeFeedback
│   ├── stroke.dart                 # Stroke, StrokePoint (mirrors ML Kit Ink)
│   └── child_profile.dart
│
├── data/
│   ├── curriculum_repository.dart  # loads assets/curriculum/*.json
│   ├── progress_repository.dart    # abstract interface
│   └── drift_progress_repository.dart  # v1 local impl  ← v2 swaps behind interface
│
├── providers/                      # Riverpod wiring (or co-locate per feature)
│   ├── child_providers.dart        # currentChildProvider
│   ├── curriculum_providers.dart   # todaysLessonProvider, letterProvider
│   ├── practice_providers.dart     # practiceSessionController, strokeCaptureProvider
│   └── progress_providers.dart
│
├── features/
│   ├── onboarding/                 # S1-02, S1-03 (create child, avatar, nickname)
│   ├── home/                       # S1-01 (today's lesson ready)
│   ├── practice/                   # S1-04..S1-06, S1-10 (trace, animate, audio, star)
│   │   └── widgets/                # stroke_canvas.dart, guide_letter.dart, feedback_panel.dart
│   ├── exercises/                  # S1-07, S1-08 (sentence-building, grammar)
│   └── parent/                     # S1-11 (PIN-gated dashboard)
│
└── utils/                          # constants, extensions, RTL helpers

assets/
├── curriculum/
│   ├── letters.json                # 28 letters + forms + stroke specs + mistakes
│   ├── lessons.json                # ordering + unlock rules + clean-reps thresholds
│   └── exercises.json              # sentences + grammar items
├── audio/                          # letter + word pronunciation (the mother's recordings)
└── fonts/                          # Arabic font with full glyph coverage (see R3)

test/
├── core/scoring/                   # pure-Dart unit tests — fast, no widgets (HIGH value)
├── data/                           # repository tests against in-memory Drift
└── features/                       # widget tests
```

### Structure Rationale

- **`core/scoring/` is the crown jewel and is pure Dart.** It has zero Flutter imports, so
  it is unit-testable without a widget harness. This matters because the curriculum's
  named mistakes ("baa's bowl too shallow") become **regression tests** the mother can
  validate against — the pedagogy gets locked in by tests, not prose.
- **`recognition/` and `data/progress_repository.dart` are interfaces.** This is the
  v1→v2 seam, made physical. v1 ships `MlKitRecognizer` and `DriftProgressRepository`;
  v2 adds `FirestoreProgressRepository` and (for the tutor) a `TutorFeedbackSource`
  implementing a feedback interface — no caller changes.
- **`models/` imports nothing from `data/` or `features/`.** Enforces the dependency rule
  (UI → providers → domain → data; never backwards). Matches the existing CONVENTIONS.md
  constraint "models must not import from services or repositories".
- **Feature folders own their widgets and screens.** Keeps the practice flow's many
  widgets (canvas, guide, feedback, animation) together without polluting a global
  `widgets/`.

---

## Riverpod: codegen vs manual, and provider map

**Recommendation: use `riverpod_generator` (annotation-based codegen) as the default.**
Verified against Riverpod v3 (current `flutter_riverpod` 3.3.0). The owner is new to Dart;
codegen is the lower-magic, lower-footgun path because:

- One annotation (`@riverpod`) instead of choosing between `Provider`/`FutureProvider`/
  `StateNotifierProvider`/etc. — the generator picks the right provider type. Fewer
  concepts for a Dart newcomer to hold.
- Dependency declaration and `autoDispose` become defaults, avoiding the classic
  "stale provider" bugs.
- Trade-off: a `build_runner` watch step. Acceptable; it is the documented modern path.

Use **manual providers** only for trivial constants (e.g. a `Provider` exposing the DB
instance) where codegen is overkill.

### Provider organization (the five the question asks about)

| State | Provider | Type | Scope / lifetime | Why |
|-------|----------|------|------------------|-----|
| **Current child profile** | `currentChildProvider` | `@riverpod` Notifier | App-scoped (kept alive) | One active child per device in v1; everything keys off it |
| **Today's lesson** | `todaysLessonProvider` | `@riverpod` Future (derived) | Auto-dispose, rebuilds when child/progress change | Pure derivation: read curriculum + progress → next unlocked lesson |
| **Active practice session** | `practiceSessionControllerProvider` | `@riverpod` Notifier | Auto-dispose, **scoped to a lesson** (`.family` by lessonId) | Holds attempts/score; dies when the child leaves the lesson so state never leaks across sessions |
| **Stroke capture state** | `strokeCaptureProvider` | `@riverpod` Notifier | Auto-dispose, scoped under the canvas | Holds the in-progress `List<Stroke>` while drawing; high-frequency, must NOT live above the canvas or it rebuilds the world |
| **Progress / mastery** | `progressRepositoryProvider` + `letterMasteryProvider(letterId)` | Provider (repo) + `@riverpod` Future (derived) | Repo app-scoped; mastery derived/auto-dispose | Repo is the seam; mastery is computed from stored attempts |

**Key boundary rule:** `strokeCaptureProvider` is *separate* from
`practiceSessionController`. The canvas updates capture state ~60×/sec while drawing;
the session controller is touched only **once per stylus-up**. Mixing them would rebuild
the session UI on every pointer move. Keep them apart.

---

## Data Flow

### The core loop: "child lifts stylus" → "feedback shown + progress saved"

```
1. Pointer events (move)         StrokeCanvas → strokeCaptureProvider
   ───────────────────────────►  appends StrokePoint{x,y,t}; CustomPainter repaints live
                                  (session controller NOT touched — perf boundary)

2. Stylus UP (pointer up)        StrokeCanvas → practiceSessionController.submitStroke(ink)
   ───────────────────────────►  passes the completed Ink (all strokes so far)

3. Score (pure, on-device)       practiceSessionController → ScoringService.score(
   ───────────────────────────►      ink, letter.referenceStrokes, letter.commonMistakes)
                                      ├─ GeometricStrokeScorer:
                                      │    • stroke count match?
                                      │    • per-stroke order + direction correct?
                                      │    • resample + shape distance vs reference
                                      │    • match against named CommonMistakes
                                      └─ HandwritingRecognizer (ML Kit): is this 'باء'?
                                      → fuse → StrokeFeedback{passed, star?, fixMessage}

4. Update session state          ScoringService result → practiceSessionController
   ───────────────────────────►  appends Attempt; decides retry vs advance
                                  ProgressRepository.recordAttempt(childId, letterId, result)

5. Feedback shown                practiceSessionController state → FeedbackPanel rebuilds
   ───────────────────────────►  shows specific fix OR quiet star (S1-10); offers audio (S1-06)

6. Lesson pass check             LessonProgressionService.evaluate(session, lesson rule)
   ───────────────────────────►  if clean-reps threshold met → unlock next lesson
                                  ProgressRepository.markLessonComplete(...)  → next lesson
                                  appears as todaysLesson (S1-09)
```

Steps 3–5 must complete in the **latency budget** below. Step 4's persistence write is
fire-and-forget relative to showing feedback (await it, but it is a single local row insert
— sub-millisecond with Drift; never blocks the visible feedback).

### On-device scoring pipeline (detail)

ML Kit alone is insufficient (it returns *what letter*, not *how well / what order*).
The pipeline fuses two signals:

```
captured Ink ──┬─► GeometricStrokeScorer (deterministic, the feedback source)
               │     1. normalize: scale captured ink to reference bounding box
               │     2. align stroke list to reference stroke list (count, order)
               │     3. per stroke: resample to N points, compare direction +
               │        shape distance (mean-nearest-point / discrete Fréchet)
               │     4. test the letter's CommonMistake predicates
               │        (e.g. mistake "dot above instead of below" = dot-stroke
               │         centroid is above baseline)
               │     5. emit deterministic StrokeFeedback + which named mistake hit
               │
               └─► MlKitRecognizer (sanity/confirmation)
                     • recognize Ink with Arabic model, restricted candidate set
                       (writingArea + preContext can bias toward the target letter)
                     • use top candidate to CONFIRM the geometric verdict and to
                       catch "they wrote a completely different letter"

FUSION (ScoringService):
  pass  = geometric shape OK AND order OK AND ML Kit top candidate == target letter
  fail  = pick the highest-priority failed CommonMistake → its child-friendly message
  star  = pass on a clean attempt (S1-10), no over-praise on sloppy passes
```

**Why ML Kit is the secondary judge, not primary:** verified that the package returns
`RecognitionCandidate{text, score}` and exposes raw `Ink`/`Stroke`/`StrokePoint` —
perfect as an identity check, but it carries no notion of "correct stroke order" or
"shape quality vs a reference". The pedagogy (stroke order, the 3–4 named mistakes) lives
entirely in the **geometric scorer**, which is exactly where the curriculum spec maps in.

### Latency budget (stylus-up → feedback, no network)

| Stage | Budget | Notes |
|-------|--------|-------|
| Collect final Ink | ~0 ms | already in memory |
| Geometric scoring | 5–30 ms | resampling + distance over a handful of strokes; pure Dart, can isolate if needed |
| ML Kit recognition | 30–150 ms | native, on-device; model pre-downloaded at first run / bundled-trigger at app start |
| Fusion + state update | < 5 ms | |
| Local persist (Drift insert) | < 5 ms | awaited but trivial |
| Repaint feedback | one frame (~16 ms) | |
| **Total target** | **< 300 ms** | Feels instant to a child. **Mandatory: download the Arabic ML Kit model on first launch** (`DigitalInkRecognizerModelManager`) so the scoring path never waits on a download. |

If geometric scoring ever grows expensive, move it to an isolate — but at v1 stroke
counts it will not need to.

---

## v1 → v2 Seam (no premature backend)

| Concern | v1 (build now) | v2 (drop in later) | Seam |
|---------|----------------|--------------------|------|
| Progress + profiles | `DriftProgressRepository` (local SQLite) | `FirestoreProgressRepository` (+ offline persistence, sync reconciliation — R2) | `abstract ProgressRepository`; swap the provider override only |
| Feedback source | Deterministic `ScoringService` (geometric + ML Kit) | Claude tutor via Cloud Function, **layered on top** of deterministic scoring | Introduce `FeedbackSource` interface in v1 with the on-device impl; v2 adds a remote impl. Deterministic scoring **stays** as the offline fallback |
| Auth | none (single local child) | Firebase Auth | `currentChildProvider` already abstracts "who is active"; back it with auth later |
| Curriculum content | bundled JSON in `assets/` | optionally remote-config'd | `CurriculumRepository` interface; local asset impl is the default forever |

**Rule for v1:** do NOT add `firebase_core`, Firestore, or any HTTP client. The interfaces
are enough to prove the seam. Adding Firebase now would violate the Decided "v1 is
local-only" constraint and create dead config.

---

## Curriculum Data Model (faithful to the mother's spec)

Ships as **bundled JSON in `assets/curriculum/`**, decoded at startup by
`CurriculumRepository` into immutable Dart models. JSON (not Dart literals) so the mother's
spec can be reviewed/edited as data, validated against a schema, and later remote-config'd
without code changes. Audio is referenced by asset path, files live in `assets/audio/`.

```jsonc
// letters.json — one entry per letter (28), in intro order
{
  "letters": [
    {
      "id": "baa",
      "char": "ب",
      "name": { "ar": "باء", "display": "Baa" },
      "introOrder": 2,                    // the mother's teaching sequence
      "forms": {                          // R3: positional shaping
        "isolated": "ب", "initial": "بـ", "medial": "ـبـ", "final": "ـب"
      },
      "referenceStrokes": [               // the geometric scorer's ground truth
        {
          "order": 1,
          "label": "bowl",
          "points": [[x,y], ...],         // normalized 0..1 reference path
          "direction": "rightToLeft"      // RTL stroke
        },
        { "order": 2, "label": "dot", "points": [[x,y]], "direction": "tap" }
      ],
      "cleanRepsToAdvance": 3,            // the mother's mastery rule
      "commonMistakes": [                 // the 3–4 named mistakes → scorer predicates
        { "id": "shallow_bowl", "check": "bowlDepthBelowThreshold",
          "feedback": "Your baa needs a deeper curve at the bottom — try again, slower." },
        { "id": "dot_above", "check": "dotAboveBaseline",
          "feedback": "The dot for baa goes below the line, not above." },
        { "id": "too_many_strokes", "check": "strokeCountExceeds",
          "feedback": "Baa is just two strokes: the bowl, then one dot." }
      ],
      "audio": { "letter": "audio/baa.mp3", "examples": ["audio/baab.mp3"] }
    }
  ]
}
```

```jsonc
// lessons.json — ordering + unlock rules; references letters/exercises by id
{
  "lessons": [
    {
      "id": "lesson_01", "order": 1, "title": { "display": "Your first letters" },
      "items": [
        { "type": "letter", "ref": "alif" },
        { "type": "letter", "ref": "baa" },
        { "type": "exercise", "ref": "ex_sentence_01" }
      ],
      "unlock": { "requires": [], "passRule": "allItemsPassed" }
    }
  ]
}
```

```jsonc
// exercises.json — sentence-building (S1-07) + grammar (S1-08)
{
  "exercises": [
    {
      "id": "ex_sentence_01", "type": "sentenceBuilding", "grade": 1,
      "prompt": { "ar": "...", "display": "Build: the cat" },
      "tokens": ["القطة", "..."], "answer": ["...", "..."],
      "audio": "audio/ex_sentence_01.mp3"
    },
    {
      "id": "ex_grammar_01", "type": "grammar", "grade": 1,
      "rule": "definiteArticle",
      "prompt": { "display": "Pick the word with 'the'" },
      "options": ["..."], "answerIndex": 0
    }
  ]
}
```

Dart models mirror this: `Letter`, `LetterForm`, `StrokeSpec`, `CommonMistake`, `Lesson`,
`LessonItem`, `Exercise` (sealed subtypes `SentenceBuildingExercise`, `GrammarExercise`),
`AudioRef`. The `commonMistakes[].check` strings map 1:1 to named predicates in the
geometric scorer — adding a mistake is data + one predicate, no UI change.

**Open question for the mother (flag to roadmap):** `referenceStrokes.points` must come
from her stroke specification (digitized reference paths). If she provides stroke *order
and description* but not coordinate paths, a content-authoring step (tracing reference
glyphs to capture paths) becomes a Phase-0 task before the scorer can run.

---

## Navigation Structure

Use **go_router** (current Flutter-team-recommended declarative router; integrates cleanly
with Riverpod redirects). Two zones:

```
/                         → HomeScreen (today's lesson, S1-01)   [child zone]
/onboarding               → create child / avatar / nickname (S1-02, S1-03)
/practice/:lessonId       → PracticeScreen (trace + animate + audio + star)
/practice/:lessonId/exercise/:exId → ExerciseScreen (sentence / grammar)
/parent                   → PIN gate (redirect)                  [parent zone]
/parent/dashboard         → ProgressDashboard (S1-11)
```

- **PIN gate** is a `go_router` redirect: navigating to `/parent/*` redirects to a PIN
  entry unless an in-memory `parentUnlockedProvider` is true (resets when the app
  backgrounds). This keeps the child out of the parent area without auth/accounts —
  appropriate for v1's local, single-device, child-safety stance (minimum data, parent
  control). The PIN is stored hashed in the local DB; it is not an account.
- Child zone is large-touch, few affordances, no text navigation chrome — child UX is a
  distinct craft (delegate to the UI designer specialists).

---

## Suggested Build Order (dependency-driven)

This becomes the roadmap's phase backbone. Ordered so each phase produces something
runnable and unblocks the next.

1. **Foundations & shell** — `ProviderScope`, `MaterialApp.router` with RTL
   `Directionality`, theme, Arabic font (resolve R3 here), go_router skeleton, Drift DB
   set up. *Unblocks everything.*
2. **Curriculum schema + repository** — define models, author/validate `letters.json`
   (with the mother), `CurriculumRepository` loads it. *Unblocks lessons, practice,
   scoring — and surfaces the reference-path content question early.*
3. **Profiles & onboarding (local)** — `ChildProfile`, `currentChildProvider`,
   `DriftProgressRepository`, onboarding flow (S1-02, S1-03). *Unblocks "today's lesson".*
4. **Stroke capture canvas** — `StrokeCanvas` + `strokeCaptureProvider`, `GuideLetter`
   dotted rendering, stroke-order animation (S1-04). *Pure capture, no scoring yet — can
   be validated visually.*
5. **On-device scoring engine** — `GeometricStrokeScorer`, `MlKitRecognizer` (download
   Arabic model), `ScoringService`; unit tests against curriculum mistakes. *The hardest,
   highest-risk phase — flag for deep research/iteration with the mother. Delivers S1-05.*
6. **Practice session loop** — `practiceSessionController`, feedback panel, quiet star,
   pronunciation audio (S1-06, S1-10); wire the full stylus-up→feedback→persist flow.
7. **Lesson progression & home** — `LessonProgressionService`, unlocking (S1-09),
   `todaysLessonProvider`, HomeScreen (S1-01).
8. **Exercises** — sentence-building (S1-07) + grammar (S1-08) screens + models.
9. **Parent dashboard** — PIN gate + progress view (S1-11).

**Phases 5 (scoring) and 2 (curriculum content with the mother) carry the most
uncertainty** and should be flagged for deeper phase-level research. Everything else is
standard Flutter/Riverpod work.

---

## Anti-Patterns

### Anti-Pattern 1: Letting ML Kit's text guess BE the feedback
**What people do:** "ML Kit recognized it as 'ب' with score 0.9 → say good job."
**Why it's wrong:** A child can draw a recognizable-but-wrong-order, wrong-shape baa.
ML Kit confirms identity, not pedagogy. The mother's named mistakes never get caught.
**Do this instead:** Geometric scorer owns the verdict and the message; ML Kit only
confirms identity and catches "wrote a totally different letter".

### Anti-Pattern 2: Rendering the guide letter as a `Text` widget
**What people do:** `Text('ب')` with a faded color for the dotted guide.
**Why it's wrong:** You can't get a reliable dotted *stroke path*, correct positional form
control, or alignment with the scorer's reference coordinates from glyph rendering; RTL
shaping fights you (R3).
**Do this instead:** Render the guide from the same `referenceStrokes` the scorer uses
(`CustomPainter`, dashed path). One source of truth for "what correct looks like".

### Anti-Pattern 3: One mega-provider for the whole practice screen
**What people do:** A single notifier holding live stroke points + session + lesson.
**Why it's wrong:** ~60 rebuilds/sec during drawing thrash the whole subtree; jank on a
tablet.
**Do this instead:** Split `strokeCaptureProvider` (high-frequency, canvas-local) from
`practiceSessionController` (touched once per stroke). Already in the provider map above.

### Anti-Pattern 4: Adding Firebase "to be ready for v2"
**What people do:** Wire `firebase_core`/Firestore now behind a flag.
**Why it's wrong:** Violates Decided "v1 local-only", adds dead config + child-data
surface area with no v1 benefit.
**Do this instead:** Ship the *interfaces* (`ProgressRepository`, `FeedbackSource`). They
are the entire seam. v2 adds implementations.

---

## Integration Points

### External / Platform

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| `google_mlkit_digital_ink_recognition` (v0.14.x, updated Feb 2026) | Behind `HandwritingRecognizer` interface | Android-only is fine (ML Kit is mobile-only). **Must download Arabic model on first run** via `DigitalInkRecognizerModelManager`; gate first practice on download-complete |
| Audio playback (`audioplayers`) | Behind `AudioService` | Plays bundled pronunciation MP3s (S1-06); files are assets |
| Drift (SQLite) | Behind `ProgressRepository` interface | Recommended local DB for 2025/26 (type-safe, migration support, well-maintained). Hive is the lighter alternative but Drift's schema migrations matter once progress data evolves into v2 |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Canvas ↔ ScoringService | one-shot call on stylus-up, passes immutable `Ink` | Canvas never imports scoring; goes through the session controller |
| ScoringService ↔ Recognizer | sync call to interface | Swappable; v1 = ML Kit |
| Providers ↔ Repositories | provider holds repo instance; repos are interfaces | The v1→v2 swap point |
| Models ↔ everything | one-way: everyone imports models; models import nothing | Enforces the dependency rule (matches CONVENTIONS.md) |

---

## Scaling Considerations

Not a "users" scaling story (single device, single child in v1). The real scaling axes:

| Axis | v1 reality | What to watch |
|------|-----------|---------------|
| Curriculum size (28 letters → words/sentences/grammar) | bundled JSON, loaded once into memory | Trivial; JSON is small. Keep audio as separate assets so app size stays sane |
| Attempts/progress rows over months | local Drift rows | Fine for years on one device; index by (childId, letterId) |
| Scoring cost | a few strokes per attempt | Cheap; isolate only if profiling shows jank |
| v2 sync | deferred | The reconciliation design is R2 — out of scope for v1, but the `ProgressRepository` seam keeps it clean |

---

## Sources

- [google_mlkit_digital_ink_recognition (pub.dev) — Ink/Stroke/StrokePoint API, RecognitionCandidate, v0.14.x, model manager](https://pub.dev/packages/google_mlkit_digital_ink_recognition) — HIGH
- [ML Kit Digital Ink base models / language support — Arabic supported (300+ languages, 25+ scripts incl. Arabic)](https://developers.google.com/ml-kit/vision/digital-ink-recognition/base-models) — HIGH (Arabic 'ar' support confirmed)
- [DigitalInkRecognitionModelIdentifier reference — model identifiers / BCP-47](https://developers.google.com/android/reference/com/google/mlkit/vision/digitalink/recognition/DigitalInkRecognitionModelIdentifier) — HIGH
- [Recognizing digital ink with ML Kit on Android — Ink building, writing area / pre-context biasing](https://developers.google.com/ml-kit/vision/digital-ink-recognition/android) — HIGH
- Riverpod (flutter_riverpod 3.3.0) via Context7 `/websites/pub_dev_flutter_riverpod_3_3_0` — codegen `@riverpod`, Notifier/AsyncNotifier — HIGH
- [Flutter local database comparison 2025 — Drift recommended default, Isar maintenance concerns](https://greenrobot.org/database/flutter-databases-overview/) — MEDIUM (multiple sources agree on Drift)
- Project context: `.planning/PROJECT.md`, `docs/USER_STORIES.md`, `docs/RESEARCH_BRIEF.md`, `.planning/codebase/*.md` — HIGH (authoritative for scope/constraints)

---
*Architecture research for: Qalam v1 on-device handwriting-learning app*
*Researched: 2026-05-30*
