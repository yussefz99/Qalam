# Stack Research

**Domain:** On-device, offline, RTL Arabic handwriting-learning tablet app for children (Flutter/Android, tablet-first)
**Researched:** 2026-05-30
**Confidence:** HIGH (versions verified against pub.dev / official docs on 2026-05-30; stroke-data gate confirmed against the Flutter package API and ML Kit docs)

> **Scope note.** This is the **v1 (Sprint 1)** stack: local-only, on-device, no auth, no Claude tutor, no Firebase. Firebase Auth / Firestore / Python Cloud Functions are a **v2** concern and are intentionally *not* part of this stack. They are listed once under "Deferred to v2" for traceability only.

---

## The gate question, answered first

**Does ML Kit Digital Ink expose per-stroke data usable for stroke-order validation, or only a text guess?**

**Answer: it returns ONLY a text guess (a `List<RecognitionCandidate>` of `{text, score}`). It does NOT return per-stroke output, geometry, or stroke-order information.** Confirmed against the `google_mlkit_digital_ink_recognition` 0.14.2 API and Google's ML Kit docs.

- **Input** to ML Kit is per-stroke: you build `StrokePoint(x, y, t)` → `Stroke` → `Ink`. So *you* already hold the full per-stroke geometry the child drew (you capture it yourself from pointer events).
- **Output** from ML Kit is just candidate strings + confidence scores. It tells you *"this looks like the letter ب"* — it does **not** tell you whether the child drew the strokes in the right order, in the right direction, or with the right shape.

**Implication for the roadmap (this gates the scoring approach):**
ML Kit Digital Ink is the right tool for **"is this the correct letter?"** (shape-class recognition), and it's validated by the owner. But **stroke-order and stroke-direction checking must be built on top, geometrically**, by comparing the child's captured `Stroke` list against the curriculum's reference stroke paths (from the owner's mother's spec). v1 scoring is therefore a **two-part deterministic pipeline**:

1. **Shape/identity** → ML Kit Digital Ink (`ar` model), on-device.
2. **Stroke order + direction + count + per-stroke shape fit** → your own geometric comparator over the captured strokes (point-count, start/end proximity, monotonic direction, DTW or resampled-path distance to the reference). No library does this for Arabic pedagogy; it is a build item.

This split should be an explicit phase in the roadmap. ML Kit alone does **not** satisfy S1-05 ("feedback on shape **and stroke order**").

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter (stable) | 3.44.x | App framework, RTL, rendering, Impeller | Current stable (2026-05-20). Strong built-in RTL (`Directionality`, `TextDirection.rtl`); Impeller is the default Android renderer and matters for stroke-drawing smoothness. |
| Dart | 3.12.x | Language | Ships with Flutter 3.44; null-safe, records/patterns available. |
| flutter_riverpod | 3.3.1 | State management (REQUIRED) | Project standard; BLoC/GetX rejected. v3 is current and stable. Compile-safe DI, testable providers, no `BuildContext` coupling for business logic — ideal for a service-heavy app (handwriting scoring, session repo, audio). |
| riverpod_annotation + riverpod_generator | 4.0.2 / 4.0.3 | Code-gen flavor of Riverpod | **Recommended flavor: code-generated (`@riverpod`)**, not hand-written. See rationale below. |
| google_mlkit_digital_ink_recognition | 0.14.2 | On-device Arabic letter **shape** recognition | Validated by owner. `ar` model (Arabic script) exists; ~20 MB, downloaded on demand via `RemoteModelManager`. Android minSdk 21, targetSdk 35. **Returns text+score only** (see gate above). |
| drift | 2.33.0 | Local persistence (curriculum + profiles + progress) | Recommended store. Typed, relational, code-generated SQL — the right fit for a structured curriculum graph (letters → words → sentences → grammar) with foreign keys and queries. See persistence section. |
| just_audio | 0.10.5 | Bundled Arabic pronunciation audio playback | Mature, supports asset playback on Android, gapless, precise control. Recommended over TTS for children's pronunciation (see audio section). |

### Riverpod flavor decision (code-gen vs hand-written)

**Recommend: code-generated Riverpod (`riverpod_generator` + `riverpod_annotation`), with `riverpod_lint`.**

- **Why code-gen:** It is the direction the Riverpod project itself steers new projects in v3. You write a plain annotated function/class and the generator picks the correct provider type, gives auto-dispose by default, and supports stateful hot-reload. For an owner **new to Dart**, this is the lower-magic path — you reason about functions, not about choosing between `Provider`/`StateNotifierProvider`/`FutureProvider` by hand.
- **Cost:** adds `build_runner` to the toolchain (a code-gen step). This is already needed for `drift` and JSON serialization, so the cost is shared, not new.
- **Lint:** `riverpod_lint` 3.1.3 catches misuse at analysis time. Note v3 `riverpod_lint` runs via `analysis_server_plugin` (configured in `analysis_options.yaml`), *not* via `custom_lint` as in older versions.

Hand-written Riverpod is acceptable and has zero build step, but for a multi-month project with a Dart-new owner, the generator's guardrails and reduced boilerplate win.

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| drift_dev | (matches drift 2.33.x) | Drift code generator | dev_dependency; runs under build_runner. |
| sqlite3_flutter_libs | 0.6.0+eol | Bundles the SQLite native lib with the app | Required by drift so you don't depend on the OS SQLite. (The `+eol` build tag is current on pub.dev — it's the published version, not a deprecation of drift.) |
| path_provider | ^2.x | Locate the app DB file + downloaded ML Kit models on device | Needed to place the drift DB in app documents dir. |
| build_runner | ^2.x | Runs all code generation (riverpod, drift, json) | dev_dependency; one command drives all generators. |
| rive | 0.14.7 | Stroke-order animations (S1-04) | **Recommended** for the "watch the correct stroke order" animation. See animation section. |
| google_fonts | 8.1.0 | Convenience font loader | **Use only to source the TTF, then BUNDLE it** — do NOT rely on its runtime HTTP fetch in an offline children's app. See font section. |
| just_audio_background | (companion, optional) | Only if audio must continue off-screen | Likely **not needed** in v1 (short in-lesson clips, foreground only). Skip unless a use case appears. |

### Stylus / ink capture (no package — use the framework primitive)

| Approach | Recommendation |
|----------|----------------|
| **`Listener` (raw `PointerEvent`) + `CustomPainter`** | **Recommended.** Capture `PointerDownEvent` / `PointerMoveEvent` / `PointerUpEvent` directly via `Listener`. Each event carries `position`, `pressure`, `tilt`, `kind` (`PointerDeviceKind.stylus`), and a timestamp — exactly the `(x, y, t)` ML Kit wants and the pressure/tilt you may want for stroke rendering. Render with a `CustomPainter` whose painter is *not* rebuilt mid-stroke (append points, call `notifyListeners` on a `Listenable` repaint). |
| `GestureDetector` | **Avoid for ink capture.** It coarsens and arbitrates gestures (drag/scale/tap), drops raw pointer fidelity, and isn't built for continuous high-rate sampling. Use it only for buttons/taps elsewhere. |
| Low-latency native libraries (Jetpack front-buffer / motion-prediction) | **Out of scope for v1.** These are Android-native (Views/Compose) techniques. Flutter on Impeller is smooth enough for letter tracing; revisit only if user testing shows perceptible lag. Document as a known future lever, not a v1 dependency. |

### Testing stack

| Tool | Version | Purpose |
|------|---------|---------|
| flutter_test | SDK | Unit + widget tests (already present). |
| mocktail | 1.0.5 | Mocking — **recommended over mockito** because it needs no code generation (no `@GenerateMocks`/build_runner round-trip just for mocks) and reads naturally in Dart. Pairs well with Riverpod `ProviderContainer` overrides. |
| integration_test | SDK | End-to-end on-device tests (trace a letter → score → unlock next lesson). Ships with Flutter; use for the core learning-loop happy path. |

Test priorities for this domain: (1) the **geometric stroke-order comparator** (pure-Dart, fully unit-testable — highest value), (2) the **curriculum/progress repository** over drift (use an in-memory drift DB), (3) widget tests for the tracing canvas state, (4) one integration test of the full lesson loop.

---

## Persistence: why drift (not sqflite / Isar / Hive / shared_preferences)

The v1 data is a **structured, relational curriculum** (letters → words → sentences → grammar exercises, each referencing audio assets and reference stroke paths) plus **profiles and progress/scores**. That shape wants relations, typed queries, and migrations.

| Option | Verdict | Reasoning |
|--------|---------|-----------|
| **drift** | **Recommended** | Typed, relational, compile-checked SQL with code-gen; clean migrations; in-memory mode for tests; foreign keys model the curriculum graph faithfully; query letters-by-grade, progress-by-child cleanly. Best fit for "a schema that faithfully holds her spec." |
| sqflite | Acceptable, lower-level | Same SQLite engine but raw strings, manual mapping, no type safety. drift is sqflite-done-right; choose drift unless you want zero code-gen. |
| Isar | **Avoid** | Fast NoSQL, but the original Isar has been effectively **unmaintained/stalled**; relying on it for a multi-month course project is a maintenance risk. Object model is also a weaker fit for relational curriculum. |
| Hive | Use only for tiny prefs | Key-value/document store; no relations or queries. Fine for "last opened lesson" flags, wrong for the curriculum graph. |
| shared_preferences | Use only for trivial flags | Single primitive values (e.g., "onboarding done", selected avatar id). Not a data store for curriculum or progress. |

**Recommended split:** drift for curriculum + profiles + progress/scores; `shared_preferences` for a handful of trivial UI flags only.

**Curriculum loading:** ship the owner's mother's spec as a **bundled asset** (a versioned JSON in `assets/curriculum/`), and **seed it into drift on first launch** (idempotent, version-checked). This keeps the spec human-reviewable in git while giving the app fast relational queries at runtime. Reference stroke paths and audio file names live in the spec and map to bundled assets.

---

## Audio: bundled assets, not TTS

**Recommend bundled, pre-recorded audio via `just_audio`** for every letter and word — **not** on-device TTS.

- **Pedagogical correctness:** Letter-name vs letter-sound, classical Arabic articulation, and child-appropriate clarity must be exact. Android TTS Arabic voices are inconsistent across devices, often Modern-Standard-with-accent, and cannot be guaranteed for a course demo. Pre-recorded clips (ideally in the curriculum owner's/teacher's voice) match the product's "real teacher" ethos.
- **Offline guarantee:** Bundled assets always work offline (satisfies the v1 local-only constraint); TTS quality/availability varies by device and language pack.
- **Control + warmth:** `just_audio` gives precise play/seek/preload of short clips and pairs with the calm, non-gamified tone.

Store clips as compressed assets (e.g., `.m4a`/AAC) under `assets/audio/letters/` and `assets/audio/words/`, referenced by name from the curriculum spec. `audioplayers` is a viable alternative; `just_audio` is recommended for its richer, more predictable API.

---

## RTL + Arabic font + the dotted guide letter

**RTL:** Flutter's RTL is built-in and solid — wrap the app (or screens) in `Directionality(textDirection: TextDirection.rtl)` and use direction-agnostic widgets (`EdgeInsetsDirectional`, `start/end`). Arabic contextual shaping (isolated/initial/medial/final) is handled by the text engine automatically when given a font with full glyph coverage; you do **not** hand-pick letter forms for display text.

**Font — recommend bundling Amiri or Noto Naskh Arabic (Naskh style):**

| Font | Recommendation |
|------|----------------|
| **Amiri** | **Recommended primary.** Classical Naskh with extensive OpenType coverage (contextual alternates, full positional forms, ligatures). Clear, traditional letterforms appropriate for teaching handwriting shape. |
| **Noto Naskh Arabic** | **Recommended alternative / fallback.** Google's Noto, designed for cross-device correctness and clarity; excellent positional coverage. Slightly more "screen-neutral" than Amiri. |
| Noto Sans Arabic | Avoid for the *teaching* glyph | Sans/geometric forms diverge from the Naskh handwriting children are being taught to form; fine for UI chrome, not for the model letter. |

**Bundling vs `google_fonts` runtime fetch:** `google_fonts` (8.1.0) fetches fonts over HTTP by default. For an **offline children's app**, do **not** rely on runtime fetch — **bundle the TTF** in `pubspec.yaml` `fonts:` (you may use `google_fonts` only to obtain/cache it, but ship the file). This guarantees rendering with no network.

**The dotted/guide letter behind the child's strokes:** This is the model letter the child traces over (S1-04/S1-05). Recommended approach — **render it as a vector path, not as font text**, so it stays crisp at tablet scale and so the "dotted" styling is controllable:

- Store each letter's outline/skeleton as an **SVG or a serialized `Path`** in the curriculum spec (this is the *same* reference geometry the stroke-order comparator uses — single source of truth).
- Draw it in a `CustomPainter` layer *beneath* the child's ink layer, using a dashed/dotted stroke style.
- The child's live strokes draw on the layer above via `Listener` + `CustomPainter`.

Using font text for the guide letter is acceptable for a quick prototype, but the vector-path approach is recommended because the guide and the scoring reference should be the same data.

---

## Stroke-order animation (S1-04): Rive

**Recommend `rive` (0.14.7)** for the "watch the correct stroke order before writing" animation.

| Option | Verdict | Reasoning |
|--------|---------|-----------|
| **Rive** | **Recommended** | Vector, tiny runtime payload, real state-machine control (play, pause, replay, per-stroke timing), interactive. Ideal for "draw stroke 1, then stroke 2" pacing tied to the lesson. Designer authors `.riv` files; app controls playback. |
| Lottie | Acceptable | After-Effects-exported JSON; great for decorative motion but **playback-only** (no interactive state machine) and heavier files. Use if the team already has AE assets; otherwise Rive is the better authoring loop for stroke-by-stroke teaching. |
| Custom `Path` animation in `CustomPainter` | **Strong free fallback** | You already store reference stroke paths for scoring; animating a drawing-on of those same paths (path-metric `extractPath` over time) gives a perfectly accurate, zero-extra-dependency stroke-order animation that is **guaranteed to match** the scored geometry. **Recommended starting point if no designer is producing `.riv` files** — reuses the single source of truth and adds nothing to the dependency tree. |

**Practical call:** if the curriculum already provides reference stroke paths (it must, for scoring), the **custom path-metric animation is the pragmatic v1 choice** — same data, no new tool, exactly matches what's scored. Reach for Rive when the owner wants richer, designer-authored motion. Both are valid; lead with custom-path, keep Rive as the upgrade.

---

## Installation

```yaml
# pubspec.yaml (dependencies)
dependencies:
  flutter:
    sdk: flutter

  # State management (REQUIRED: Riverpod, code-gen flavor)
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2

  # On-device Arabic letter shape recognition (validated)
  google_mlkit_digital_ink_recognition: ^0.14.2

  # Local persistence (curriculum + profiles + progress)
  drift: ^2.33.0
  sqlite3_flutter_libs: ^0.6.0
  path_provider: ^2.1.0
  shared_preferences: ^2.2.0   # trivial UI flags only

  # Audio (bundled pronunciation clips)
  just_audio: ^0.10.5

  # Stroke-order animation (optional; custom-path is the no-dep alternative)
  rive: ^0.14.7

  # Fonts: bundle the TTF (see assets:); google_fonts only to source it
  # google_fonts: ^8.1.0   # add only if you use it to fetch-then-bundle

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Code generation
  build_runner: ^2.4.0
  riverpod_generator: ^4.0.3
  riverpod_lint: ^3.1.3
  drift_dev: ^2.33.0

  # Testing
  mocktail: ^1.0.5
  flutter_lints: ^6.0.0
```

```yaml
# pubspec.yaml (assets + bundled font)
flutter:
  uses-material-design: true
  assets:
    - assets/curriculum/        # the owner's mother's spec (JSON) + reference paths
    - assets/audio/letters/
    - assets/audio/words/
    - assets/anim/              # .riv files if using Rive
  fonts:
    - family: Amiri
      fonts:
        - asset: assets/fonts/Amiri-Regular.ttf
        - asset: assets/fonts/Amiri-Bold.ttf
          weight: 700
```

ML Kit note: the `ar` model (~20 MB) downloads on demand via `DigitalInkRecognitionModelManager`. For a fully-offline-from-first-run demo, trigger the download during onboarding (with Wi-Fi) and check availability before the first tracing lesson; cache it thereafter.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Code-gen Riverpod | Hand-written Riverpod | If the team wants zero build_runner — but build_runner is already needed for drift, so little is saved. |
| drift | sqflite | If you want to avoid code generation entirely and are comfortable hand-mapping raw SQL. |
| drift | Isar | Only if a pure object store with no relations is genuinely wanted — but Isar maintenance status makes it a risk; not recommended. |
| just_audio | audioplayers | Equivalent for simple asset playback; choose audioplayers if you prefer its simpler API. |
| Custom path-metric stroke animation | Rive | When a designer is authoring rich, interactive `.riv` stroke animations beyond what reference paths give. |
| Listener + CustomPainter | (native low-latency) | Only if Flutter/Impeller tracing latency proves perceptible in user testing. |
| mocktail | mockito | If the team already standardizes on mockito's generated mocks. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| BLoC, GetX | Explicitly rejected by project decision | Riverpod (code-gen) |
| ML Kit Digital Ink **as the stroke-order scorer** | It returns text+score only, no stroke geometry/order output | ML Kit for shape/identity **+ a custom geometric comparator** for order/direction |
| `GestureDetector` for ink capture | Gesture arbitration drops raw pointer fidelity and sampling rate | `Listener` + raw `PointerEvent` |
| On-device TTS for pronunciation | Inconsistent Arabic voices across devices; not guaranteed offline; wrong articulation risk | Bundled pre-recorded clips (just_audio) |
| `google_fonts` runtime HTTP fetch | Breaks the offline guarantee for a children's app | Bundle the TTF in pubspec `fonts:` |
| Isar (NoSQL) | Maintenance-stalled; relational curriculum is a poor fit | drift |
| Noto Sans Arabic for the model letter | Geometric forms diverge from taught Naskh handwriting | Amiri / Noto Naskh Arabic |
| Firebase (Auth/Firestore/Functions) in v1 | v1 is local-only, no auth, no tutor | Defer to v2 (see below) |

## Stack Patterns by Variant

**If the curriculum ships reference stroke paths (expected):**
- Use the **custom path-metric animation** for S1-04 and the **same paths** as both the dotted guide and the scoring reference — one source of truth, no extra deps.

**If a designer produces interactive stroke animations:**
- Add **Rive** for S1-04 only; keep scoring on the reference paths regardless.

**If offline-from-first-launch is a hard demo requirement:**
- Pre-download the ML Kit `ar` model during onboarding and verify availability before the first lesson; never block a tracing lesson on a network call.

## Deferred to v2 (NOT part of this stack)

For traceability only — these enter with the AI tutor milestone, not v1:
`firebase_core`, `firebase_auth`, `cloud_firestore`, Python Cloud Functions (tutor server), and FCM. v1's offline-by-design satisfies NTH-05 without any of these.

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| flutter 3.44.x | Dart 3.12.x | Current stable bundle (2026-05-20). |
| flutter_riverpod 3.3.1 | riverpod_generator 4.0.3, riverpod_annotation 4.0.2, riverpod_lint 3.1.3 | v3 line; riverpod_lint v3 uses analysis_server_plugin, not custom_lint. |
| drift 2.33.0 | drift_dev 2.33.x, sqlite3_flutter_libs 0.6.0 | Keep drift and drift_dev versions aligned. |
| google_mlkit_digital_ink_recognition 0.14.2 | Android minSdk 21, target/compileSdk 35 | Raises minSdk above the old skeleton's "5.0+"; confirm `minSdkVersion 21` in `android/app/build.gradle.kts`. |
| build_runner | riverpod_generator + drift_dev | One generator run drives both. |

## Sources

- https://pub.dev/packages/google_mlkit_digital_ink_recognition — v0.14.2; input `StrokePoint(x,y,t)`→`Stroke`→`Ink`; **output = `List<RecognitionCandidate>{text,score}` only** (HIGH — gates scoring approach)
- https://developers.google.com/ml-kit/vision/digital-ink-recognition/base-models — Arabic model id `ar` (+`ar-x-gesture`), ~20 MB, on-demand download (HIGH)
- https://pub.dev/packages/flutter_riverpod — v3.3.1 (HIGH)
- https://pub.dev/packages/riverpod_generator — v4.0.3; riverpod_annotation 4.0.2 (HIGH)
- https://pub.dev/packages/riverpod_lint — v3.1.3, analysis_server_plugin based (HIGH)
- https://pub.dev/packages/drift — v2.33.0 (HIGH)
- https://pub.dev/packages/sqlite3_flutter_libs — v0.6.0+eol (HIGH)
- https://pub.dev/packages/just_audio — v0.10.5, Android asset playback (HIGH)
- https://pub.dev/packages/rive — v0.14.7, Android supported (HIGH)
- https://pub.dev/packages/mocktail — v1.0.5 (HIGH)
- https://pub.dev/packages/google_fonts — v8.1.0 (HIGH)
- https://docs.flutter.dev/release/release-notes + https://dart.dev/blog/announcing-dart-3-12 — Flutter 3.44.x / Dart 3.12.x current stable (HIGH)
- https://medium.com/androiddevelopers/stylus-low-latency-d4a140a9c982 + https://api.flutter.dev/flutter/gestures/PointerEvent-class.html — PointerEvent carries pressure/tilt/kind/time; native front-buffer low-latency is Android-View/Compose, out of v1 scope (MEDIUM)
- https://fonts.google.com/specimen/Amiri + https://fonts.google.com/noto/specimen/Noto+Naskh+Arabic — Naskh fonts with full positional/OpenType coverage (MEDIUM)

---
*Stack research for: on-device offline RTL Arabic handwriting-learning tablet app (Qalam v1)*
*Researched: 2026-05-30*
