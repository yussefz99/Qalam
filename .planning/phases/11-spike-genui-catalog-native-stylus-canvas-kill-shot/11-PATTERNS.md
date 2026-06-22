# Phase 11: SPIKE — GenUI catalog + native stylus canvas (kill-shot) - Pattern Map

**Mapped:** 2026-06-21
**Files analyzed:** 7 new spike files (all under `lib/spike_genui/`, additive + imports-only)
**Analogs found:** 6 / 7 (the GenUI catalog/transport wiring has NO codebase analog — first-party SDK, see "No Analog Found")

> **Hard boundary (D-09/D-10/TUTOR-01):** every file below is NEW and lives only under `lib/spike_genui/`. The spike *imports* the durable canvas widget read-only and *copies* baa's stroke data into a fixture. It MODIFIES no durable file. A `git diff` on `lib/features/practice/widgets/stroke_canvas.dart`, `lib/features/letter_unit/`, `lib/core/scoring/`, `lib/core/exercise_engine/`, and `assets/curriculum/` MUST stay empty for the entire spike (Success Criterion 4).

---

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `lib/spike_genui/main_spike_genui.dart` | entrypoint / bootstrap | request-response (boot) | `lib/main.dart` + `lib/app.dart` | exact (role + flow) |
| `lib/spike_genui/spike_app.dart` | screen / A-B harness scaffold | event-driven (toggle) | `lib/app.dart` (root) + `lib/dev/glyph_audit_screen.dart` (dev harness scaffold) | role-match |
| `lib/spike_genui/catalog/stroke_canvas_item.dart` | catalog adapter (hosts native widget) | transform (model data → widget) | `lib/features/letter_unit/widgets/write_surface.dart` (the existing thin wrapper that instantiates `StrokeCanvas`) | role-match (best available) |
| `lib/spike_genui/catalog/spike_catalog.dart` | config / catalog registry | n/a (static registration) | — (GenUI `Catalog`/`CoreCatalogItems` — no analog) | no analog |
| `lib/spike_genui/agent/present_activity_tool.dart` | schema + prompt fragment | request-response (model decision) | — (GenUI `CatalogItem` schema — no analog) | no analog |
| `lib/spike_genui/agent/gemini_transport.dart` | service (model client + A2UI transport) | streaming (model → surface) | `lib/services/auth_service.dart` (existing Firebase service-init shape) + `lib/main.dart` Firebase init | partial (Firebase wiring only) |
| `lib/spike_genui/fixtures/baa_reference.dart` | fixture / data | n/a (static data) | `assets/curriculum/letters.json` (`baa.referenceStrokes`) + `lib/models/letter.dart` `StrokeSpec` | exact (data shape) |

---

## Pattern Assignments

### `lib/spike_genui/main_spike_genui.dart` (entrypoint, boot)

**Analog:** `lib/main.dart` (lines 26–69) + `lib/app.dart` (lines 15–30)

This is a separate `flutter run -t lib/spike_genui/main_spike_genui.dart` target. The spike's boot is a **stripped-down copy** of production `main()` — it needs Firebase init (so `firebase_ai` can attach to the existing app `qalam-app-bd7d0`) but does NOT need the AppDatabase boot read, the onboarding/parent gates, or the router. Anonymous auth is optional (the model call works under the existing anonymous identity; keep it for parity with prod, drop it if it complicates the throwaway).

**Production boot pattern to copy from** (`lib/main.dart` lines 26–39):
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await lockOrientation();                 // landscape lock — keep (tablet-first)

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,   // from lib/firebase_options.dart
  );
  await AuthService().ensureSignedIn();     // optional for the spike; keep for parity
  // ... prod reads AppDatabase + seeds gates here — SPIKE OMITS ALL OF THAT ...
}
```

**Landscape-lock helper to copy verbatim** (`lib/main.dart` lines 19–24):
```dart
Future<void> lockOrientation() {
  return SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}
```

**runApp / ProviderScope root** — production wraps in `ProviderScope` (`lib/main.dart` lines 49–68) because durable widgets use Riverpod. **Note:** `StrokeCanvas` itself is a plain `StatefulWidget` (NOT a `ConsumerStatefulWidget`) so it needs no ProviderScope. But `WriteSurface` IS a `ConsumerStatefulWidget`. Since the spike embeds `StrokeCanvas` directly (not `WriteSurface` — simpler, fewer deps), a bare `runApp(const SpikeApp())` is sufficient. If the planner instead chooses to embed `WriteSurface`, wrap in `ProviderScope` and provide `modelDownloadServiceProvider`.

**Imports the spike copies** (from `lib/main.dart` lines 5–7, 12):
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qalam/firebase_options.dart';   // reuse the SAME options — read-only
```

---

### `lib/spike_genui/spike_app.dart` (A/B harness scaffold)

**Analog:** `lib/app.dart` (MaterialApp root shape, lines 15–30) + `lib/dev/glyph_audit_screen.dart` (dev-harness scaffold pattern)

The harness is a `MaterialApp` whose home is an A/B toggle: arm **[A]** = the GenUI-embedded canvas (`GenUiSurface` hosting the `present_activity` tree), arm **[B]** = the same `StrokeCanvas` standalone in a plain `Scaffold`. A toggle (SegmentedButton / two tabs) flips between them so the same baa trace can be felt side-by-side (D-05).

**MaterialApp root shape to copy** (`lib/app.dart` lines 21–28) — but the spike does NOT need the router, l10n delegates, or theme provider; a plain `MaterialApp` with `home:` is enough:
```dart
return MaterialApp(
  title: 'Qalam GenUI Spike',
  debugShowCheckedModeBanner: false,
  home: const SpikeHarnessScreen(),   // the A/B toggle scaffold
);
```

**Dev-harness scaffold precedent:** `lib/dev/glyph_audit_screen.dart` is the project's established pattern for a throwaway/dev-only screen that is "NOT surfaced in user-facing nav" (its header comment, line 29–31). The spike screen follows the same posture: a bare `Scaffold` with a body that lays out the test surface(s), no production chrome. Copy its discipline (explicit "this is a debug seam" header comment), not its glyph-audit body.

**Standalone arm [B]** is the simplest possible host — the kill-shot reference:
```dart
Scaffold(
  body: SafeArea(
    child: StrokeCanvas(
      key: const ValueKey('spike-standalone-canvas'),
      referenceStrokes: baaReferenceStrokes,   // from the fixture
    ),
  ),
)
```

---

### `lib/spike_genui/catalog/stroke_canvas_item.dart` (catalog adapter — THE hosting seam, D-03)

**Analog:** `lib/features/letter_unit/widgets/write_surface.dart` (lines 248–260) — the existing, proven pattern for *instantiating `StrokeCanvas` from a wrapper without rebuilding it*. This is the closest thing in the codebase to "host the native canvas inside a parent that owns layout," which is exactly the D-03 seam.

**StrokeCanvas constructor contract** (the props the catalog item MUST supply — from `stroke_canvas.dart` lines 84–123):
```dart
StrokeCanvas({
  super.key,                                 // STABLE key is load-bearing (Pitfall 1)
  required List<StrokeSpec> referenceStrokes, // the ONLY required prop
  void Function(List<Offset> points)? onStrokeSubmitted,        // optional
  void Function(List<List<Offset>> strokes)? onLetterComplete,  // optional
  StrokeCanvasController? controller,         // optional imperative clear/submit
  bool acceptTouch = DebugFlags.allowFingerInput,  // leave default; stylus always accepted
});
```
For the spike, only `referenceStrokes` + a stable `key` are needed. Scoring callbacks are NOT wired (D-07: this spike judges canvas responsiveness only, not the scorer path).

**The exact "host StrokeCanvas inside a parent that owns layout" pattern to copy** (`write_surface.dart` lines 249–260) — note the deliberate **stable `ValueKey`** so the canvas resets cleanly between reference sets but never mid-stroke:
```dart
Positioned.fill(
  child: StrokeCanvas(
    // A fresh key per reference set so the canvas resets cleanly between
    // exercises (it never clears strokes on pointer-down).
    key: ValueKey<String>('${widget.exercise.id}:${widget.surface.mode}:...'),
    referenceStrokes: _referenceStrokes,
    onLetterComplete: _onLetterComplete,
    controller: widget.canvasController,
  ),
),
```

**Adapted for the GenUI catalog item** (D-03/D-04 — coaching line above, canvas below; the `widgetBuilder` signature MUST be confirmed against the installed `genui 0.9.x` source — see "No Analog Found" + RESEARCH Pattern 1):
```dart
// SHAPE — confirm widgetBuilder signature + data accessor against installed genui.
widgetBuilder: (context) {
  final coaching = /* bind model 'coachingLine' string via genui's data accessor */;
  return Column(children: [
    Text(coaching),                                  // D-04: model-generated line
    Expanded(
      child: StrokeCanvas(
        key: const ValueKey('spike-embedded-canvas'),  // STABLE — Pitfall 1 mitigation
        referenceStrokes: baaReferenceStrokes,          // from fixtures/baa_reference.dart
      ),
    ),
  ]);
},
```

**CRITICAL — the kill-shot risk (RESEARCH Pitfall 1):** `_StrokeCanvasState` holds the in-progress `_activePoints` and accumulated `_completedStrokes` *in widget State* (`stroke_canvas.dart` lines 126–136). If a GenUI surface rebuild creates a NEW `_StrokeCanvasState`, that ink is discarded mid-trace. The stable `key` is the mitigation. To detect a torn-down State during the A/B, the planner may add a debug `print` in the **spike's call site / a thin spike-local subclass** — NEVER in the durable `stroke_canvas.dart` (`initState` line 141 / `dispose` line 286 are the lifecycle hooks to watch).

**Gesture note (RESEARCH Pitfall 2):** `StrokeCanvas` uses a raw `Listener` with `HitTestBehavior.opaque` (`stroke_canvas.dart` lines 268–273), NOT a `GestureDetector` — a deliberate palm-rejection choice. If a GenUI surface ancestor is a `ScrollView`, it can steal the stylus drag. Keep the embedded canvas in a non-scrolling region; if GenUI forces a scrollable surface, that is itself a "drop" finding.

---

### `lib/spike_genui/fixtures/baa_reference.dart` (fixture — read-only baa strokes)

**Analog:** `assets/curriculum/letters.json` → the `baa` entry's `referenceStrokes` (the exact authored, signed-off data) + `lib/models/letter.dart` `StrokeSpec` (lines 34–73) for the Dart shape.

**Resolution of Open Question Q1:** Do NOT import the durable curriculum loader (it pulls Firestore/Drift providers into the throwaway). Instead **hardcode a `const List<StrokeSpec>`** copied from the live `letters.json` baa entry. The *canvas widget* under test is still the real one (which is all D-03 cares about), and the spike stays self-contained and additive.

**`StrokeSpec` constructor to construct against** (`lib/models/letter.dart` lines 49–55):
```dart
const StrokeSpec({
  required int order,
  required String label,
  required List<List<double>> points,   // normalized 0..1 coordinate pairs
  required String direction,
  String type = 'line',                 // "line" | "curve" | "dot"
});
```

**The exact baa data to hardcode** (verbatim from the current signed-off `assets/curriculum/letters.json` `baa.referenceStrokes` — boat + dot, normalized 0..1, body sweeps rightToLeft):
```dart
// Source: assets/curriculum/letters.json -> id:"baa".referenceStrokes (signedOff:true).
// Copied read-only into the spike; the durable curriculum is NOT imported (Q1/D-10).
const List<StrokeSpec> baaReferenceStrokes = <StrokeSpec>[
  StrokeSpec(
    order: 1,
    label: 'body',
    type: 'curve',
    direction: 'rightToLeft',
    points: <List<double>>[
      [0.608, 0.447], [0.619, 0.486], [0.620, 0.524], [0.594, 0.552],
      [0.551, 0.565], [0.511, 0.569], [0.474, 0.570], [0.436, 0.566],
      [0.407, 0.559], [0.386, 0.530], [0.381, 0.498], [0.382, 0.460],
    ],
  ),
  StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    direction: 'tap',
    points: <List<double>>[ [0.498, 0.644] ],
  ),
];
```
> The painter sorts by `order`, draws `type != 'dot'` strokes as the dotted guide, and draws the `type == 'dot'` stroke as a calm ink circle (`stroke_canvas.dart` lines 331–360). Two strokes here means `referenceStrokes.length == 2`, so the canvas's count-reached auto-complete (line 242) fires after boat + dot — irrelevant to the spike (no `onLetterComplete` wired) but confirms the data is well-formed.

---

### `lib/spike_genui/agent/gemini_transport.dart` (model client + A2UI transport)

**Analog (Firebase wiring only):** `lib/main.dart` (Firebase init, lines 36–39) + `lib/services/auth_service.dart` (the project's service-class shape). The A2UI transport itself has **no codebase analog** — see "No Analog Found."

**Firebase attach pattern** — the existing app is already initialized in the spike's `main()`, so `firebase_ai` attaches to it with no new project setup:
```dart
// firebase_ai attaches to the existing Firebase app (qalam-app-bd7d0) initialized
// in main_spike_genui.dart via Firebase.initializeApp (copied from lib/main.dart).
final model = FirebaseAI.googleAI().generativeModel(
  model: 'gemini-2.5-flash',         // any Flash that supports the loop (D-12)
  systemInstruction: Content.system(promptBuilder.systemPromptJoined()),
);
```

**Service-class shape precedent** (`lib/services/auth_service.dart` — a thin class wrapping a Firebase SDK with a single async entrypoint and a try/catch that degrades gracefully rather than throwing out of boot). Mirror that posture: the transport class owns the model + the `A2uiTransportAdapter`, exposes a `start()` that kicks the `present_activity` loop, and catches model errors so a failed call surfaces as a visible "drop" finding, not a crash.

> **Security (RESEARCH §Security):** the transport sends ONLY `present_activity` text + `letterId: "baa"` — NEVER raw `List<Offset>` strokes and NEVER any PII. The per-stroke pointer→paint loop stays entirely local (D-07). App Check is left unenforced in throwaway scope (D-13) — record this explicitly in SPIKE-FINDINGS.

---

## Shared Patterns

### Stable-key state preservation (THE pattern the whole spike turns on)
**Source:** `lib/features/letter_unit/widgets/write_surface.dart` lines 252–255 (the `ValueKey` per reference set) + `lib/features/practice/widgets/stroke_canvas.dart` lines 126–136 (State that the key protects).
**Apply to:** every place the spike instantiates `StrokeCanvas` (embedded arm AND standalone arm).
```dart
StrokeCanvas(
  key: const ValueKey('spike-embedded-canvas'),  // identity that survives rebuilds
  referenceStrokes: baaReferenceStrokes,
);
```
A *stable* key across GenUI surface rebuilds keeps `_StrokeCanvasState` alive; a *changing/absent* key resets it. The spike must give the embedded canvas its fairest shot with a stable key — if even that can't survive GenUI's rebuilds, that IS the "drop GenUI" finding.

### Firebase-attach-to-existing-app
**Source:** `lib/main.dart` lines 36–39 (`Firebase.initializeApp` with `DefaultFirebaseOptions.currentPlatform`).
**Apply to:** `main_spike_genui.dart` boot; `gemini_transport.dart` then calls `FirebaseAI.googleAI()` against that already-initialized app. Reuse the project's `lib/firebase_options.dart` read-only — do not regenerate it.

### Read-only durable import (the TUTOR-01 invariant in practice)
**Source:** `lib/features/letter_unit/widgets/write_surface.dart` line 41 (`import '../../practice/widgets/stroke_canvas.dart';`).
**Apply to:** `stroke_canvas_item.dart` and `spike_app.dart` import `package:qalam/features/practice/widgets/stroke_canvas.dart` to obtain the REAL widget. No durable file is edited; `StrokeSpec` comes from `package:qalam/models/letter.dart` (or is copied into the fixture). Keep the import surface minimal — the more durable files the spike imports, the more transitive providers it drags in (Q1 caution).

### Dev-harness posture
**Source:** `lib/dev/glyph_audit_screen.dart` lines 1–31 (explicit "DEBUG SEAM … NOT surfaced in user-facing nav" header).
**Apply to:** every spike file gets a header comment stating it is throwaway spike code, the GATE it serves, and that it imports durable widgets read-only and modifies none.

---

## No Analog Found

These have NO codebase precedent — the planner must lean on RESEARCH.md (Pattern 1, Pattern 2, Code Examples) and the **installed `genui 0.9.x` source/examples**, NOT on existing Qalam code:

| File / concern | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/spike_genui/catalog/spike_catalog.dart` | catalog registry | static | `genui` `Catalog`/`CoreCatalogItems`/`SurfaceController` are brand-new first-party SDK constructs; the repo has never used GenUI. |
| `lib/spike_genui/agent/present_activity_tool.dart` | schema + prompt | request-response | `CatalogItem.dataSchema` (`S.object(...)`) + A2UI prompt-fragment shape is GenUI-specific; no analog. |
| `lib/spike_genui/agent/gemini_transport.dart` (the A2UI part) | streaming transport | streaming | `A2uiTransportAdapter.onSend` → `addChunk` over `model.generateContentStream` is GenUI/firebase_ai-specific; only the Firebase-attach half has a (`lib/main.dart`) analog. |

**Mandatory Wave-0 task for the planner (RESEARCH A2/Pattern 1):** before authoring `stroke_canvas_item.dart`, READ the installed `genui` package source/example to confirm the exact `widgetBuilder` signature and the data-binding accessor (`context.value<String>(...)` vs `subscribeToString` + `ValueListenableBuilder`). The official docs are version-drifting (they still reference the dead `firebase_vertex_ai`), so the installed source is the source of truth — not the SHAPE snippets in RESEARCH.

---

## Metadata

**Analog search scope:** `lib/main.dart`, `lib/app.dart`, `lib/features/practice/widgets/stroke_canvas.dart`, `lib/features/letter_unit/widgets/write_surface.dart`, `lib/models/letter.dart`, `lib/dev/glyph_audit_screen.dart`, `lib/services/auth_service.dart`, `assets/curriculum/letters.json`, `pubspec.yaml`.
**Files scanned:** 9 (plus a glob of `lib/**/*screen*.dart` to pick the smallest scaffold analog).
**Pattern extraction date:** 2026-06-21
**Durable-files-touched:** NONE (read-only). SC-4 `git diff` guard precondition satisfied by construction.
