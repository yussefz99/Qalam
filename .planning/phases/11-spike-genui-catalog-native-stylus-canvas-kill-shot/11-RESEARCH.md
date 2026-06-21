# Phase 11: SPIKE — GenUI catalog + native stylus canvas (kill-shot) - Research

**Researched:** 2026-06-21
**Domain:** Flutter generative-UI SDK (`genui`) + Firebase AI Logic (`firebase_ai`) function-calling, hosting a real-time native CustomPaint/Listener stylus canvas
**Confidence:** MEDIUM-HIGH (package facts VERIFIED via pub.dev + official flutter.dev/firebase.google.com docs; native-widget-hosting behavior is the genuine unknown the spike exists to settle — MEDIUM, by design)

---

## Summary

This is a throwaway architecture-decision spike whose only deliverable is a confident **GATE**: keep the official GenUI SDK, or drop it in favor of raw `firebase_ai` function-calling driving native widgets via a tiny hand-rolled dispatcher (Phase 14 builds whichever arm is recorded). The research surfaced **one large correction to the phase's mental model** that the planner must absorb before writing tasks:

**The package named in CONTEXT.md as `flutter_genui` is discontinued.** `flutter_genui` 0.5.0 is marked `isDiscontinued: true` on pub.dev and explicitly `replacedBy: genui`. The live, first-party package is **`genui`** (publisher `labs.flutter.dev`), currently **0.9.2** (published 2026-06-04). The spike must depend on `genui`, not `flutter_genui`. `[VERIFIED: pub.dev]`

The second correction is architectural. GenUI does **not** drive UI through `firebase_ai` *function-calling tools* the way D-01/D-11 imply. GenUI uses its own **A2UI streaming protocol**: the model emits structured A2UI messages (`createSurface` / `surfaceUpdate` / `dataModelUpdate`), and a `A2uiTransportAdapter` you wire parses the model's streamed text into UI commands. `firebase_ai`'s function-calling is a *separate* mechanism — it is exactly what the **fallback arm** (D-02) would use. This sharpens the GATE rather than blurring it: the two arms genuinely use two different model-interaction paradigms (A2UI surface-streaming vs. tool-calling), so a clean comparison is meaningful. The planner should frame the `present_activity` "tool" in the GenUI arm as **a custom `CatalogItem` the model selects/populates via A2UI**, and reserve true `FunctionDeclaration` tool-calling for the fallback arm's description only (the fallback is not built here — D-02).

The third finding is the kill-shot itself, and it remains an honest unknown: GenUI's `CatalogItem.widgetBuilder` is "just a Flutter builder," so it *can* return a `StrokeCanvas`. But GenUI's reactive model rebuilds surfaces on `dataModelUpdate`, and the official docs are **silent on stateful-widget identity preservation across surface updates** — no mention of `GlobalKey`, `AnimationController` lifecycles, or state caching. That silence is the risk: a stylus canvas whose `_StrokeCanvasState` (holding the in-progress `List<Offset>`) gets torn down and rebuilt mid-stroke would visibly lag or drop ink. This is precisely what the A/B test (D-05/D-06) and the time-box (D-08) exist to expose.

**Primary recommendation:** Build the spike against `genui ^0.9.2` + `firebase_ai ^3.13.0` in an additive `lib/spike_genui/` target. Register `StrokeCanvas` as a custom `CatalogItem` whose `widgetBuilder` returns it under a **stable `ValueKey`/`GlobalKey`** so GenUI surface rebuilds cannot reset its stroke state. Drive it with a Gemini Flash model via `FirebaseAI.googleAI().generativeModel(...)` over the existing Firebase app, **App Check left unenforced in throwaway scope** (acceptable per D-13; the prod grounding/App-Check posture is Phase 14's). Time-box hard (recommend **3 focused days**); if a stable, lag-free embedded canvas is not working by then, the difficulty *is* the "drop GenUI" evidence.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Substrate under test is the **official GenUI SDK + `firebase_ai`** — the real thing we'd ship if GATE says "keep". (NOTE: the package is `genui`, not the discontinued `flutter_genui` — see Standard Stack.)
- **D-02:** The "drop GenUI" arm — **raw `firebase_ai` function-calling driving native widgets via a small hand-rolled dispatcher** — is the **assumed-safe fallback**. The spike does NOT build it; it is the known-good destination if the SDK arm fails.
- **D-03:** Register the native `StrokeCanvas` as a **GenUI catalog widget embedded INSIDE GenUI's model-generated tree** — GenUI owns the surrounding layout. (Adjacent/signalled approach rejected — too close to the fallback arm.)
- **D-04:** Exercise a **genuinely MIXED tree**: GenUI generates **one coaching text line above** the embedded native canvas. (Bare-canvas rejected as under-testing; full coaching+hint+retry rejected as scope creep.)
- **D-05:** Sharp test = **embedded-vs-standalone**: trace baa on the embedded canvas AND on the same canvas standalone; judge whether GenUI hosting degrades it.
- **D-06:** Evidence = **feel + A/B capture on a real Pixel Tablet** (not emulator), recorded as screen-capture/video. Frame-timing instrumentation deliberately NOT required (overlaps Phase 12).
- **D-07:** Judge only the **canvas's own responsiveness under GenUI**. Full-path stroke→scorer→agent→render→first-TTS latency is Phase 12 — do not build that rig here.
- **D-08:** **Fixed time-box → GATE either way.** Hard iteration budget (~2–3 focused days; planner to confirm). If clean embedded-native hosting isn't working by then, that difficulty IS the "drop GenUI" evidence. A kill-shot must be allowed to kill.
- **D-09:** Throwaway lives in a dedicated **`lib/spike_genui/` folder with its own `main_spike_genui.dart`** target, importing real canvas widgets read-only. Production `main.dart` + durable layers untouched.
- **D-10:** Criterion 4 (durable layers unchanged) proven by construction — spike folder is additive + imports-only; `git diff` on canvas/scorer/curriculum paths must be empty.

### Claude's Discretion (defaults — researcher/planner may adjust)
- **D-11:** Wire only the **`present_activity`** tool/catalog-item — not the full 4-tool ACTION set.
- **D-12:** Use a **Gemini Flash** model via Firebase AI Logic to drive the loop. Any Gemini model that supports the interaction is fine; model comparison is Phase 12/13.
- **D-13:** Exact time-box length, **App Check posture in throwaway scope**, and the precise SPIKE-FINDINGS verdict shape are left to research/planning. Findings packaged via `/gsd:spike-wrap-up`.

### Deferred Ideas (OUT OF SCOPE)
- Full latency/presence budget + model & transport choice → **Phase 12**.
- Grounding-faithfulness + Arabic-register bake-off (Authored vs Gemini vs Gemma) → **Phase 13**.
- Production TutorBrain spine, full 4-tool ACTION set, FACTS injection, non-PII network guard → **Phase 14**.
- Building the raw-`firebase_ai` fallback dispatcher → only if GATE says "drop GenUI"; it is Phase 14 build work, not spike work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| (none) | Architecture-decision spike — owns NO requirement by design | Research serves the **GATE decision** and the **Phase 14 hand-off**. It feeds the TUTOR-01 invariant check (durable layers carry zero `genui`/`firebase_ai` imports — proven by the `lib/spike_genui/`-only construction, D-10) and prototypes the `present_activity` seam that TUTOR-05 will productionize. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Real-time stroke capture + ink render (StrokeCanvas) | Client / Native Flutter | — | Millisecond pointer→paint loop; MUST stay on-device, never route through the model (the "two clocks" reflex). This is the thing under test. |
| Model-generated layout + coaching text line | Client (GenUI SurfaceController) ← Model (Gemini) | — | GenUI parses model A2UI stream into a widget tree on-device; the model only emits *structure + text*, not pixels. |
| `present_activity` selection (which activity to show) | Model (Gemini Flash via firebase_ai) | Client (GenUI catalog resolves it) | The agent *chooses*; the catalog *renders*. Mirrors the Phase 14 TUTOR-05 seam. |
| Function-calling / A2UI transport | Client (`A2uiTransportAdapter` you wire) ↔ Firebase AI Logic | — | Network round-trip for *agent decisions only* — explicitly NOT per-stroke (D-07). |
| API-key custody | Firebase AI Logic backend | App Check (prod only) | Key never in client (PROJECT.md invariant). In throwaway scope App Check stays unenforced (D-13). |

**Tier-correctness note for the planner:** the kill-shot is precisely whether the *first row* (native real-time canvas) survives being **a child of the second row** (model-generated layout) without losing its native responsiveness. If GenUI's surface-rebuild touches the canvas's State, the tiers leak into each other and the GATE fails.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `genui` | `^0.9.2` | The GenUI SDK under test — Catalog/CatalogItem/SurfaceController/GenUiSurface + A2UI transport. **Replaces the discontinued `flutter_genui`.** | First-party Flutter package (publisher `labs.flutter.dev`); the actual SDK we'd ship if GATE = keep. `[VERIFIED: pub.dev]` |
| `firebase_ai` | `^3.13.0` | Firebase AI Logic SDK — Gemini Flash model client, streaming, and `FunctionDeclaration`/`Tool` for the fallback arm. | First-party FlutterFire (publisher `firebase.google.com`); attaches to the existing Firebase app. Replaced the old `firebase_vertex_ai`. `[VERIFIED: pub.dev]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `firebase_core` | already `^4.10.0` → **bump to `^4.11.0`** | Firebase app init | `firebase_ai 3.13.0` declares `firebase_core ^4.11.0`; the project pins `^4.10.0`. A minor bump (same major) is required for resolution. `[VERIFIED: pub.dev firebase_ai pubspec]` |
| `firebase_auth` | already `^6.5.2` → may resolve to `^6.5.3` | Existing anonymous identity | `firebase_ai 3.13.0` declares `firebase_auth ^6.5.3`; let pub resolve within the 6.x line. `[VERIFIED: pub.dev]` |
| `firebase_app_check` | **NOT added in throwaway scope** | API-key abuse protection | `firebase_ai` depends on it transitively, but enforcement is a console/registration step. Throwaway scope leaves it **unenforced** (D-13); prod posture is Phase 14. `[ASSUMED]` (see Assumptions A3) |
| `genui_catalog` | `^` (latest) | The prebuilt `CoreCatalogItems` (text, column, etc.) to compose with the custom canvas item | Provides the model-generated coaching-text line (D-04) without hand-authoring a text CatalogItem. Optional but reduces spike code. `[VERIFIED: pub.dev — exists, same publisher]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `genui` (A2UI surface-streaming) | Raw `firebase_ai` `FunctionDeclaration` tool-calling | This **IS the fallback arm (D-02)** — do not build it in this spike. It is the known-good destination if GenUI fails. |
| `firebase_ai` | `google_generative_ai` (direct Gemini, key in client) | Rejected by PROJECT.md invariant — key must never ship in client. `firebase_ai` proxies via Firebase AI Logic. |
| `FirebaseAI.googleAI()` (Gemini Developer API) | `FirebaseAI.vertexAI()` (Vertex backend) | Either supports Flash + the spike's needs; `googleAI()` is the simpler dev path. Backend choice is not load-bearing for the GATE (D-12). |

**Installation:**
```bash
# in the project root, run from the spike target's perspective (all repo-level deps)
flutter pub add genui firebase_ai
flutter pub add genui_catalog        # optional — for the CoreCatalogItems text widget
# bump firebase_core to satisfy firebase_ai 3.13.0:
flutter pub add firebase_core:^4.11.0
```
Let `flutter pub add` resolve the FlutterFire lockstep set (do NOT hand-pin mismatched majors — same rule as the existing pubspec note on FlutterFire).

**Version verification (run at plan time — versions move weekly):**
```bash
flutter pub outdated | grep -E "genui|firebase_ai|firebase_core"
# confirm genui is still NOT discontinued and flutter_genui still IS:
curl -s https://pub.dev/api/packages/genui | python3 -c "import sys,json;d=json.load(sys.stdin);print('genui', d['latest']['version'],'discontinued=',d.get('isDiscontinued'))"
```

## Package Legitimacy Audit

> slopcheck was unavailable in this session. Both packages were verified first-party via their pub.dev `publisher` endpoint (a stronger signal than slopcheck for these two), so they are treated as VERIFIED rather than blanket-ASSUMED. The planner should still confirm versions at plan time.

| Package | Registry | Age | Downloads | Source Repo | Publisher | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `genui` | pub.dev | first release 2025-11-12 (0.5.0); 0.9.2 on 2026-06-04 | n/a (young, first-party) | github.com/flutter/genui | **labs.flutter.dev** (Flutter team) | Approved — first-party |
| `firebase_ai` | pub.dev | mature FlutterFire line; 3.13.0 on 2026-06-17 | high | github.com/firebase/flutterfire | **firebase.google.com** (Firebase) | Approved — first-party |
| `genui_catalog` | pub.dev | tracks `genui` | n/a | github.com/flutter/genui | labs.flutter.dev | Approved — first-party (optional) |
| `flutter_genui` | pub.dev | **DISCONTINUED** (0.5.0) | n/a | github.com/flutter/genui | labs.flutter.dev | **REMOVED — replacedBy `genui`. Do NOT install.** |

**Packages removed:** `flutter_genui` (discontinued; replaced by `genui`).
**Packages flagged [SUS]:** none.
**Note:** `genui` is genuinely young (first release Nov 2025) and pre-1.0 (0.9.x). That immaturity is *itself part of what the kill-shot tests* (D-01: "the kill-shot precisely because the SDK is young/experimental"). It is not a slopcheck risk — it is first-party — but its API may shift between 0.9.x releases; pin an exact resolved version in the spike's pubspec and record it in SPIKE-FINDINGS.

## Architecture Patterns

### System Architecture Diagram

```
                          lib/spike_genui/main_spike_genui.dart
                                      │ flutter run -t
                                      ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │  Spike app  (additive — production main.dart untouched, D-09)     │
   │                                                                    │
   │   [A] EMBEDDED arm                    [B] STANDALONE arm           │
   │   ┌───────────────────────────┐       ┌────────────────────────┐  │
   │   │ GenUiSurface              │       │ Scaffold               │  │
   │   │  (SurfaceController owns  │       │   StrokeCanvas         │  │
   │   │   the model-gen tree)     │       │   (imported read-only) │  │
   │   │  ┌─────────────────────┐  │       └────────────────────────┘  │
   │   │  │ model-gen Column    │  │              ▲                     │
   │   │  │  • coaching text    │  │              │ same widget,        │
   │   │  │    (CoreCatalog)    │  │              │ no GenUI parent     │
   │   │  │  • StrokeCanvas  ◄──┼──┼── present_activity CatalogItem    │
   │   │  │    (custom Catalog  │  │     widgetBuilder → StrokeCanvas   │
   │   │  │     item, D-03/D-04)│  │     under a STABLE key             │
   │   │  └─────────────────────┘  │                                    │
   │   └───────────┬───────────────┘                                    │
   └───────────────┼────────────────────────────────────────────────────┘
                   │ A2uiTransportAdapter.onSend
                   ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │  firebase_ai : FirebaseAI.googleAI().generativeModel('gemini-..-flash')│
   │   • systemInstruction = PromptBuilder(catalog).systemPromptJoined()    │
   │   • model emits A2UI stream → addChunk() → SurfaceController            │
   └───────────────────────┬──────────────────────────────────────────┘
                           │ (App Check UNENFORCED in throwaway scope, D-13)
                           ▼
              Firebase AI Logic backend  →  Gemini Flash
              (existing Firebase app: qalam-app-bd7d0; key never in client)

   NOTE: the per-stroke pointer→paint loop NEVER leaves [A]/[B] — no arrow
   crosses to the model. The model round-trip is for present_activity ONLY.
```

### Recommended Project Structure
```
lib/
└── spike_genui/                       # additive, deletable, imports-only (D-09/D-10)
    ├── main_spike_genui.dart          # its own runApp + Firebase.initializeApp
    ├── spike_app.dart                 # the A/B scaffold: [A] embedded | [B] standalone toggle
    ├── catalog/
    │   ├── stroke_canvas_item.dart     # the custom CatalogItem wrapping StrokeCanvas
    │   └── spike_catalog.dart          # CoreCatalogItems + stroke_canvas_item composed
    ├── agent/
    │   ├── present_activity_tool.dart   # the present_activity schema + system prompt fragment
    │   └── gemini_transport.dart        # A2uiTransportAdapter onSend → generateContentStream
    └── fixtures/
        └── baa_reference.dart           # how the spike OBTAINS baa's referenceStrokes read-only
```
**Imports allowed (read-only):** `lib/features/practice/widgets/stroke_canvas.dart`. Obtaining baa's `referenceStrokes` (a `List<StrokeSpec>`) without rewiring the curriculum is an open question — see Open Questions Q1.

### Pattern 1: Custom CatalogItem hosting a native stateful widget
**What:** Register `StrokeCanvas` as a `CatalogItem` whose `widgetBuilder` returns the real widget.
**When to use:** This is the D-03 hosting seam — the entire point of the embedded arm.
**Example (shape — confirm exact API against installed `genui 0.9.x`):**
```dart
// Source: https://docs.flutter.dev/ai/genui/components (CatalogItem shape)
// + https://pub.dev/packages/genui  — confirm signatures against the resolved version.
final presentActivityItem = CatalogItem(
  name: 'present_activity',                    // the model selects this by name (D-11)
  dataSchema: S.object(properties: {
    'coachingLine': S.string(description: 'one short coaching sentence for the child'),
    'letterId': S.string(description: 'the letter to trace, e.g. "baa"'),
  }, required: ['coachingLine', 'letterId']),
  widgetBuilder: (context) {
    final coaching = context.value<String>('coachingLine');   // bind model text (D-04)
    final letterId = context.value<String>('letterId');
    return Column(children: [
      Text(coaching),                                          // model-generated line
      Expanded(
        child: StrokeCanvas(
          key: const ValueKey('spike-embedded-canvas'),        // STABLE key — see Pitfall 1
          referenceStrokes: baaReferenceStrokes(letterId),     // read-only fixture (Q1)
        ),
      ),
    ]);
  },
);
```
> The exact `widgetBuilder` signature and the data-binding accessor (`context.value` vs `context.dataContext.subscribeToString` + `ValueListenableBuilder`) differ across genui 0.9.x docs/examples. **The planner must include a Wave-0 "read the installed genui source/example" task** before authoring the catalog item, because the docs are version-drifting (the get-started page still references the dead `firebase_vertex_ai`).

### Pattern 2: A2UI transport over a Gemini Flash model
**What:** `A2uiTransportAdapter.onSend` streams the model's output into the SurfaceController.
**Example (shape):**
```dart
// Source: docs.flutter.dev/ai/genui/get-started (updated for firebase_ai, not firebase_vertex_ai)
final model = FirebaseAI.googleAI().generativeModel(
  model: 'gemini-2.5-flash',                  // any Flash that supports the loop (D-12)
  systemInstruction: Content.system(promptBuilder.systemPromptJoined()),
);
late final A2uiTransportAdapter transport;
transport = A2uiTransportAdapter(onSend: (message) async {
  final content = /* convert GenUI message envelope → firebase_ai Content */;
  await for (final chunk in model.generateContentStream([content])) {
    transport.addChunk(chunk.text ?? '');
  }
});
final conversation = Conversation(controller: surfaceController, transport: transport);
```

### Anti-Patterns to Avoid
- **Using `flutter_genui`:** discontinued. Use `genui`.
- **Treating `present_activity` as a `firebase_ai` `FunctionDeclaration` in the GenUI arm:** in GenUI it is a **CatalogItem** selected via A2UI. True tool-calling belongs to the *fallback* arm (D-02), which this spike does not build.
- **Rebuilding the exercise UI inside the spike:** D-04 says generate ONE coaching line above the canvas — not the FeedbackPanel/hint/retry chrome. Anything beyond one line is scope creep.
- **Routing pointer events through the model:** the per-stroke loop must stay local (D-07). The model call is for `present_activity` only.
- **Editing any durable file to "make hosting easier":** violates D-09/D-10/TUTOR-01. If hosting requires a durable-file change, that is a *finding* (lean toward "drop GenUI"), not a task.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Model→UI structured protocol | A custom JSON-to-widget interpreter | `genui` A2UI + SurfaceController | That interpreter IS GenUI; hand-rolling it pre-decides the GATE. |
| Gemini client + key custody | Direct HTTPS to Gemini with key in app | `firebase_ai` (Firebase AI Logic) | Key-never-in-client invariant; proxied + App-Check-capable. |
| The stylus canvas | A new ink widget for the spike | Import `StrokeCanvas` read-only | The whole test is whether the REAL canvas survives hosting (D-03). |
| The "drop GenUI" dispatcher | A native tool-dispatcher now | Nothing — it's the assumed-safe fallback (D-02) | Building it blurs the two GATE arms; it's Phase 14 work iff GATE=drop. |

**Key insight:** Every piece of "infrastructure" you might hand-roll here is either (a) the thing under test, or (b) the fallback you must NOT build. The spike's job is to wire two first-party SDKs together and *watch the pen*, not to build framework.

## Runtime State Inventory

> This spike is additive and imports-only — it stores nothing and registers nothing. Included for completeness because it touches the build/dependency surface.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — the spike persists nothing; strokes stay in-memory in StrokeCanvas State (T-03-01) and are discarded. | None |
| Live service config | **Firebase AI Logic must be enabled** on the existing project `qalam-app-bd7d0` (Gemini API / AI Logic toggle in the Firebase console) — this is console state, not in git. | One-time console enablement (Wave 0 / human checkpoint) |
| OS-registered state | None. | None — verified: no scheduler/daemon/plist touched. |
| Secrets/env vars | None new. The Gemini key lives in Firebase AI Logic backend, never in the client (existing invariant). No `.env` change. | None |
| Build artifacts | New transitive native deps from `firebase_ai`/`firebase_app_check` will be pulled into the Android build; a `flutter clean` + rebuild may be needed. The spike's own `main_spike_genui.dart` is a second entrypoint, not a second build artifact. | `flutter pub get`; rebuild the Android app once |

**The canonical question — what runtime state still references the old thing after files change?** Nothing. The spike is purely additive; deleting `lib/spike_genui/` + reverting pubspec returns the repo to baseline (this deletability is Success Criterion 4 by construction, D-10).

## Common Pitfalls

### Pitfall 1: GenUI surface rebuild tears down the canvas's State (THE kill-shot risk)
**What goes wrong:** GenUI rebuilds surfaces on `dataModelUpdate`/`surfaceUpdate`. If the embedded `StrokeCanvas` is rebuilt without a stable identity, Flutter creates a *new* `_StrokeCanvasState`, discarding `_activePoints`/`_completedStrokes` — ink flickers, drops, or resets mid-stroke. Standalone won't do this; embedded will → the A/B test fails *for GenUI's reasons*, which is a legitimate "drop GenUI" signal.
**Why it happens:** The official docs are **silent** on stateful-widget identity across surface updates (no GlobalKey/state-caching guidance — VERIFIED gap in flutter.dev/ai/genui/components). GenUI's model is reactive/functional; long-lived imperative State is outside its happy path.
**How to avoid (to give GenUI its fairest shot):** give the embedded `StrokeCanvas` a **stable `ValueKey`/`GlobalKey`** so it survives rebuilds; verify the model is NOT instructed to re-emit `present_activity` mid-trace (a fresh `present_activity` SHOULD legitimately reset the canvas — that's a new activity). If even a stable key can't keep state across GenUI's rebuilds, **that is the finding** → drop GenUI.
**Warning signs:** ink stutters/vanishes only in the embedded arm; `initState`/`dispose` of `_StrokeCanvasState` firing during a trace (add a debug print in the spike copy's call site, never in the durable file).

### Pitfall 2: Gesture-arena / pointer conflict with GenUI's layout
**What goes wrong:** `StrokeCanvas` uses a raw `Listener` (not `GestureDetector`) with `HitTestBehavior.opaque` — deliberately, to win pointer events. If GenUI wraps surfaces in scroll views or gesture-claiming widgets, a stylus drag could be stolen by a parent (treated as a scroll), and strokes break only when embedded.
**Why it happens:** `Listener` competes differently from `GestureDetector`; a `ScrollView`/`Dismissible` ancestor can claim the drag.
**How to avoid:** keep the embedded canvas in a non-scrolling region; if GenUI forces a scrollable surface, that constraint is itself a finding. The `Listener`-not-`GestureDetector` choice (documented in `stroke_canvas.dart` header as "Pitfall 2 from research") is the project's existing palm-rejection design — do not change it.
**Warning signs:** the first pointer-move is captured but the drag is lost; strokes only register as taps in the embedded arm.

### Pitfall 3: Building the wrong package (`flutter_genui`)
**What goes wrong:** CONTEXT.md names `flutter_genui`; pub.dev still serves it (discontinued tombstone at 0.5.0). A task that runs `flutter pub add flutter_genui` installs a dead, year-old API and the whole spike measures the wrong thing.
**How to avoid:** the planner's install task MUST use `genui`. Add a Wave-0 assertion: `grep -q "genui:" pubspec.yaml && ! grep -q "flutter_genui:" pubspec.yaml`.

### Pitfall 4: `firebase_core` version floor blocks resolution
**What goes wrong:** `firebase_ai 3.13.0` needs `firebase_core ^4.11.0`; the project pins `^4.10.0`. `flutter pub add firebase_ai` may either bump it (fine) or surface a resolution conflict with the existing pinned FlutterFire set.
**How to avoid:** bump `firebase_core` to `^4.11.0` in the same `pub add`; let pub resolve `cloud_firestore`/`firebase_auth` within their majors. Record the resolved lockfile delta in SPIKE-FINDINGS so Phase 14 inherits a known-good set.

### Pitfall 5: Docs reference the dead `firebase_vertex_ai`
**What goes wrong:** the official get-started page still shows `firebase_vertex_ai` + `FirebaseVertexAI.instance` (a package that no longer exists under that name). Copy-pasting fails to resolve.
**How to avoid:** use `firebase_ai` + `FirebaseAI.googleAI().generativeModel(...)`. Treat the docs' API *shape* as correct but the *package/class names* as stale.

### Pitfall 6: Emulator "passes," device fails (or vice-versa)
**What goes wrong:** the canvas accepts touch only in debug (`acceptTouch`/`kDebugMode`); on the Pixel Tablet the real stylus path (`PointerDeviceKind.stylus`) is what matters. A finger-on-emulator A/B is not the test (D-06 requires a real Pixel Tablet).
**How to avoid:** run the A/B on-device with the actual stylus; the spike build can leave `acceptTouch` at its debug default but the *judged* evidence is the stylus trace on hardware.

## Code Examples

> Both snippets are SHAPE-level (the genui 0.9.x API is pre-1.0 and version-drifting). Treat them as scaffolding to verify against the installed source, not as copy-paste-final. Sources are cited inline.

### Wiring a Gemini Flash model into GenUI's transport
```dart
// Source: https://docs.flutter.dev/ai/genui/get-started (names updated: firebase_ai, not firebase_vertex_ai)
import 'package:genui/genui.dart';
import 'package:firebase_ai/firebase_ai.dart';

final catalog = Catalog(/* CoreCatalogItems + presentActivityItem */);
final surfaceController = SurfaceController(catalogs: [catalog]);
final promptBuilder = PromptBuilder.chat(
  catalog: catalog,
  systemPromptFragments: const [
    'You are a calm Arabic-writing tutor. When the child should trace a letter, '
    'call present_activity with one short coaching line and the letterId.',
  ],
);
final model = FirebaseAI.googleAI().generativeModel(
  model: 'gemini-2.5-flash',
  systemInstruction: Content.system(promptBuilder.systemPromptJoined()),
);
```

### Fallback-arm tool shape (for the verdict doc only — NOT built here)
```dart
// Source: docs.flutter.dev/ai/best-practices/tool-calls + firebase_ai FunctionDeclaration
// This is what the "drop GenUI" arm (D-02) would use; documented so the GATE describes both arms.
final presentActivity = FunctionDeclaration(
  'present_activity',
  'Show the child an activity to trace',
  parameters: {
    'coachingLine': Schema.string(description: 'one short coaching sentence'),
    'letterId': Schema.string(description: 'letter to trace, e.g. baa'),
  },
);
// model.generateContent(history, tools: [Tool.functionDeclarations([presentActivity])])
// → a native dispatcher maps the function call to `Navigator/setState(StrokeCanvas(...))`.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `flutter_genui` package | **`genui`** package | discontinued; `genui` is live, 0.9.2 (2026-06-04) | Spike MUST depend on `genui`. CONTEXT.md's name is stale. |
| `firebase_vertex_ai` + `FirebaseVertexAI.instance` | **`firebase_ai`** + `FirebaseAI.googleAI()` / `.vertexAI()` | FlutterFire consolidation; `firebase_ai` at 3.13.0 (2026-06-17) | Official get-started docs are stale on names; use `firebase_ai`. |
| Structured-outputs (JSON-schema response) GenUI | A2UI streaming-surface protocol | mid-2026 (the migration the Medium "From Structured Outputs to A2UI Surfaces" article describes) | GenUI is A2UI-message-driven, not function-call-driven; this reframes the `present_activity` seam as a CatalogItem. |

**Deprecated/outdated:**
- `flutter_genui` — discontinued, `replacedBy: genui`. Do not install.
- `firebase_vertex_ai` — folded into `firebase_ai`. Do not install.

## Validation Architecture

> `workflow.nyquist_validation: true` in config — section included. **But this is a feel-based architecture spike (D-06), not a feature with automatable behavioral tests.** The "validation" here is the GATE-evidence protocol, plus two cheap automatable guards.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (already in the project) — used ONLY for the two structural guards below, not for the canvas feel |
| Config file | none beyond the default; the spike adds no test config |
| Quick run command | `flutter analyze lib/spike_genui` (the spike must compile + lint clean) |
| Full suite command | `flutter test test/spike_genui/` (only the two guard tests below) |

### Phase Requirements → Test Map
| Criterion | Behavior | Test Type | Automated Command | File Exists? |
|-----------|----------|-----------|-------------------|-------------|
| SC-1 (canvas hosted, real-time) | Embedded canvas traces baa with no per-stroke lag | **manual / feel A/B on Pixel Tablet (D-06)** — NOT automatable | (video capture, judged by feel) | ❌ device + human |
| SC-2 (written verdict) | A SPIKE-FINDINGS doc states pass/fail + observations | doc-existence check | `test -f .planning/spikes/.../SPIKE-FINDINGS.md` | ❌ Wave-end |
| SC-3 (GATE recorded) | GATE = keep \| drop is written + handed to Phase 14 | doc-content check | `grep -E "GATE: (keep\|drop)" SPIKE-FINDINGS.md` | ❌ Wave-end |
| SC-4 (durable layers unchanged) | git diff on durable paths is empty | **automatable guard** | `git diff --quiet HEAD -- lib/features/practice/widgets/stroke_canvas.dart lib/features/letter_unit/ lib/core/scoring/ lib/core/exercise_engine/ assets/curriculum/` | ✅ make Wave 0 |
| (build sanity) | spike compiles + no `flutter_genui` import | automatable guard | `flutter analyze lib/spike_genui && grep -q "genui:" pubspec.yaml && ! grep -q "flutter_genui:" pubspec.yaml` | ✅ make Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter analyze lib/spike_genui` (compiles + lints).
- **Per wave merge:** the SC-4 `git diff --quiet` durable-layers guard (must stay green the entire spike).
- **Phase gate:** the on-device A/B video captured + judged + the SPIKE-FINDINGS verdict written with a recorded GATE.

### What constitutes defensible PASS vs FAIL evidence (the feel-based core, D-05/D-06)

**PASS evidence (GATE = keep GenUI):**
- Side-by-side video on a real Pixel Tablet of the SAME baa trace, embedded-arm vs standalone-arm, in which a viewer **cannot tell which is which by ink responsiveness** — ink follows the stylus tip with no visible stutter, drop, or lag in either.
- The embedded canvas keeps its stroke state across at least one GenUI surface update (e.g. the coaching line re-renders without resetting in-progress/complete ink).
- The mixed tree (model coaching line + native canvas, D-04) renders in one surface, proving coexistence.
- Achieved **within the time-box** without editing any durable file (SC-4 guard stays green).

**FAIL evidence (GATE = drop GenUI → raw firebase_ai fallback):**
- In the embedded arm, ink visibly **stutters, drops points, or resets** mid-trace where the standalone arm is smooth (Pitfall 1/2 manifesting).
- Hosting the canvas required (or only worked by) touching a durable file — the SC-4 guard would have gone red.
- The genui 0.9.x API cannot express "host an arbitrary stateful widget under a stable key" without fighting the framework.
- **Time-box exhausted (D-08):** clean embedded-native hosting is not working by the budget's end. *Difficulty itself is FAIL evidence* — record "drop GenUI," do not iterate further.

### How the hard time-box forces a GATE either way (D-08)
The spike CANNOT end "inconclusive." Recommend a **3 focused-day** budget (Day 1: wire genui+firebase_ai + custom CatalogItem + present_activity; Day 2: embedded vs standalone A/B harness on device; Day 3: capture + judge + write verdict, buffer for a single key/gesture fix attempt). At the budget's edge there are exactly two outcomes: a clean indistinguishable A/B (→ keep) OR anything short of that (→ drop). Both write a SPIKE-FINDINGS verdict + a `GATE: keep|drop` line consumed by Phase 14. Time spent fighting the SDK is recorded as the cost-of-keep, which informs the drop decision. *(Planner confirms the exact number; 2 is aggressive, 3 is the recommended default, beyond 3 contradicts "a kill-shot must be allowed to kill.")*

## Security Domain

> `security_enforcement: true`, ASVS L1. This is a throwaway spike that ships nothing and persists nothing — the security surface is narrow but real (it makes network calls to a generative model from a child's app).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | partial | Existing anonymous `firebase_auth`; no new auth. |
| V6 Cryptography | no | Spike adds no crypto; never hand-roll. |
| V7 Error handling / logging | yes | Strokes are in-memory only (existing StrokeCanvas T-03-01 invariant) — the spike must NOT log stroke coordinates or send them to the model. The model call carries only `present_activity` text, never raw ink. |
| V9 Communication | yes | All model traffic via `firebase_ai` (TLS, Firebase backend) — key never in client (PROJECT.md invariant). |
| V14 Config | yes | **App Check unenforced in throwaway scope (D-13)** — acceptable ONLY because the spike is local/dev, time-boxed, and deleted. Flag explicitly in SPIKE-FINDINGS that prod (Phase 14) MUST enforce App Check (TUTOR-03). |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Gemini API-key abuse (no App Check) | Spoofing / DoS / cost | Firebase AI Logic proxies the key; **enforce App Check before any non-throwaway use** (deferred to Phase 14 per D-13 — but the spike must not be promoted to prod as-is). |
| Child stroke data exfiltration via the model call | Information disclosure | Send only `present_activity` text + `letterId`; NEVER raw `List<Offset>` strokes (prefigures GROUND-02). The spike has no reason to send ink — keep it that way. |
| PII to the model | Information disclosure | No nickname/name/PII in any model payload; the spike uses a hardcoded `letterId: "baa"`, no child fields. |

**Security verdict for the spike:** acceptable to run with App Check unenforced **because** (a) it's local + time-boxed + deletable, (b) it sends no strokes and no PII, (c) the key is still never in the client. Record this posture explicitly so it does NOT silently carry into Phase 14.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | everything | ✓ | 3.41.9 (stable) | — (genui needs ≥3.35.7; firebase_ai needs ≥3.16.0 — both satisfied) |
| Dart SDK | everything | ✓ | 3.11.5 | — (genui needs ≥3.10.0; satisfied) |
| `genui` package | the SDK under test | ✗ not yet added | target `^0.9.2` | none — it IS the subject; if it can't resolve, that's a finding |
| `firebase_ai` package | the agent loop | ✗ not yet added | target `^3.13.0` | none — required for the model call |
| Existing Firebase app | model backend | ✓ | `qalam-app-bd7d0`, firebase_core ^4.10.0 wired | bump firebase_core → ^4.11.0 |
| Firebase AI Logic enabled (console) | the actual Gemini call | ✗ unknown — must verify | — | **blocking** if not enabled; one-time console toggle (human) |
| Real Pixel Tablet + stylus | the D-06 A/B evidence | ✗ not verifiable from here | — | **blocking for PASS evidence** — emulator/finger does NOT satisfy D-06 |
| `adb` on PATH | flashing + screen-record to the tablet | ✗ not on PATH in this shell | — | available via Android Studio / Flutter toolchain; planner should confirm device-deploy path |

**Missing dependencies with no fallback (planner MUST address):**
- **Firebase AI Logic enablement** on `qalam-app-bd7d0` — a console step; make it a Wave-0 human checkpoint.
- **Real Pixel Tablet with a stylus** for the A/B capture — without it, SC-1's PASS evidence (D-06) cannot be produced. If unavailable inside the time-box, that itself pushes toward a conservative GATE.

**Missing dependencies with fallback:**
- `genui`/`firebase_ai`/`firebase_core` bump — resolved by `flutter pub add` (the spike's first task).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | genui's `widgetBuilder` can return an arbitrary stateful native widget (`StrokeCanvas`) and, with a stable key, preserve its State across surface rebuilds | Patterns / Pitfall 1 | **This is the kill-shot.** If false, GATE = drop. The spike exists to verify exactly this — treat as the central hypothesis, not a fact. |
| A2 | The exact genui 0.9.x `CatalogItem`/`widgetBuilder`/data-binding signatures match the doc shapes shown | Code Examples | Code won't compile as-pasted; planner's Wave-0 "read installed source" task de-risks this. Pre-1.0 API drift is expected. |
| A3 | App Check can be left unenforced for a throwaway local spike and a Gemini Flash call will still succeed | Security / D-13 | If the project enforces App Check at the backend, calls fail until a debug provider is registered — add a fallback task to register the App Check **debug** provider if calls are rejected. |
| A4 | A Gemini Flash model via `FirebaseAI.googleAI()` reliably emits valid A2UI for a `present_activity`-style catalog | Patterns | If Flash A2UI compliance is shaky, more prompt-engineering is needed (or a bigger model) — but D-12 says any Gemini that supports the loop is fine; not GATE-deciding. |
| A5 | 3 focused days is the right time-box | Validation / D-08 | Planner owns the final number; 2–3 is the CONTEXT range. Over-budgeting defeats "a kill-shot must be allowed to kill." |
| A6 | baa's `referenceStrokes` can be obtained read-only without rewiring curriculum | Project Structure / Q1 | If not, a tiny read-only fixture (hardcoded baa strokes copied into `lib/spike_genui/fixtures/`) satisfies it without touching durable curriculum — see Q1. |

## Open Questions

1. **How does the spike obtain baa's `referenceStrokes` (a `List<StrokeSpec>`) read-only, without rewiring the curriculum loader?**
   - What we know: `StrokeCanvas` needs `referenceStrokes`; the durable curriculum lives in `assets/curriculum/` + a loader; the spike must not modify it (D-10).
   - What's unclear: whether reading the live curriculum from the spike pulls in heavy providers (Firestore/Drift) that complicate a throwaway target.
   - Recommendation: for a throwaway, **copy baa's reference strokes into a tiny `lib/spike_genui/fixtures/baa_reference.dart`** (a hardcoded `List<StrokeSpec>`). This keeps the spike self-contained and additive; the *canvas widget* under test is still the real one (which is what D-03 cares about). Reading the real curriculum is allowed if cheap, but the fixture is the safe default.

2. **Does genui's `SurfaceController` wrap surfaces in a scrollable/gesture-claiming ancestor by default?**
   - What we know: GenUI surfaces rebuild reactively; layout ancestry isn't documented at the pointer level.
   - What's unclear: whether a default `GenUiSurface` introduces a `ScrollView` that competes with the canvas's `Listener` (Pitfall 2).
   - Recommendation: a Day-1 spike sub-task — drop a bare `Listener` into a GenUI surface and confirm it receives `onPointerMove`. If a parent steals the drag, that's an early, cheap "drop" signal.

3. **Exact time-box length (D-08/D-13).**
   - Recommendation: 3 focused days (default). Planner confirms.

## Sources

### Primary (HIGH confidence)
- pub.dev API — `genui` (0.9.2, publisher `labs.flutter.dev`, env flutter ≥3.35.7, NOT discontinued); `flutter_genui` (0.5.0, **isDiscontinued: true, replacedBy: genui**); `firebase_ai` (3.13.0, publisher `firebase.google.com`, deps firebase_core ^4.11.0 / firebase_auth ^6.5.3 / firebase_app_check ^0.4.5). Verified via `https://pub.dev/api/packages/{genui,flutter_genui,firebase_ai}` and `.../publisher`.
- https://docs.flutter.dev/ai/genui/components — Catalog/CatalogItem/SurfaceController/DataModel/A2uiTransportAdapter/A2uiMessage; A2UI protocol (not function-calling); selective-rebuild model.
- https://docs.flutter.dev/ai/genui/get-started — SurfaceController + PromptBuilder + transport wiring (names stale: shows `firebase_vertex_ai`; corrected to `firebase_ai` here).
- https://firebase.google.com/docs/ai-logic/get-started — `FirebaseAI.googleAI().generativeModel(...)`, App Check "as early as possible" (optional in dev), `flutter pub add firebase_core firebase_ai`.
- Local: `lib/features/practice/widgets/stroke_canvas.dart` (Listener-not-GestureDetector, in-memory-only strokes, accumulating State, stable-key reset pattern); `pubspec.yaml` (firebase_core ^4.10.0, flutter sdk ^3.11.5); `flutter --version` (3.41.9 / Dart 3.11.5).

### Secondary (MEDIUM confidence)
- https://docs.flutter.dev/ai/best-practices/tool-calls — `FunctionDeclaration`/`Tool` chat-loop shape for the fallback-arm description.
- WebSearch (verified against the official docs above): A2uiTransportAdapter `onSend`→`addChunk` over `model.generateContentStream`; genui is backend-agnostic.

### Tertiary (LOW confidence — flagged, not load-bearing)
- Medium "From Structured Outputs to A2UI Surfaces" (Ulusoy, Jun 2026) and assorted 2026 GenUI tutorials — corroborate the A2UI migration narrative; not used for any API claim.

## Metadata

**Confidence breakdown:**
- Standard stack (which packages/versions): **HIGH** — pub.dev publisher + discontinuation status verified directly.
- Architecture (A2UI vs function-calling, transport wiring): **HIGH** — official flutter.dev + firebase.google.com docs.
- The kill-shot itself (native stateful canvas survives GenUI rebuilds): **MEDIUM by design** — docs are silent; this is the unknown the spike exists to settle.
- Pitfalls: **MEDIUM-HIGH** — Pitfalls 3/4/5 verified from registry/docs; Pitfalls 1/2 are reasoned from GenUI's reactive model + the canvas's Listener design (HIGH plausibility, confirm on-device).

**Research date:** 2026-06-21
**Valid until:** ~2026-07-05 (14 days — `genui` is pre-1.0 and shipping ~monthly; `firebase_ai` ships ~monthly. Re-verify versions + that `genui` is still the live package at plan time.)
