---
phase: 11-spike-genui-catalog-native-stylus-canvas-kill-shot
plan: 02
subsystem: ai-ui
tags: [genui, firebase_ai, a2ui, stroke-canvas, spike, present-activity, gemini-flash]

# Dependency graph
requires:
  - phase: 11-01
    provides: "installed genui 0.9.2 + firebase_ai 3.13.0; baaReferenceStrokes read-only fixture; SC-4 + package guards"
  - phase: 06.1-firebase-curriculum-backend
    provides: "wired Firebase app qalam-app-bd7d0 + firebase_options.dart reused read-only"
provides:
  - "Runnable spike target lib/spike_genui/main_spike_genui.dart with both A/B arms wired"
  - "present_activity custom GenUI CatalogItem hosting the REAL StrokeCanvas under a stable ValueKey inside a model-generated mixed tree (D-03/D-04) — the seam the Phase 14 GATE turns on"
  - "Gemini Flash A2UI transport (FirebaseAI.googleAI, generateContentStream -> addChunk) sending only present_activity text + letterId (T-11-03)"
  - "Verified genui 0.9.2 + firebase_ai 3.13.0 API forms recorded for Phase 14 inheritance (data accessor + transport symbols)"
affects: [11-03, phase-14-tutor]

# Tech tracking
tech-stack:
  added: [json_schema_builder 0.1.5 (promoted transitive -> direct for the spike)]
  patterns:
    - "Custom GenUI CatalogItem: CatalogItem(name:, dataSchema: S.object, widgetBuilder: (CatalogItemContext) => Widget); data via itemContext.data as JsonMap + extension type"
    - "Model-bound string via A2uiSchemas.stringReference schema + BoundString(dataContext: itemContext.dataContext, value:, builder: (ctx, val))"
    - "A2UI transport: A2uiTransportAdapter(onSend) + addChunk; Conversation(controller, transport); render via Surface(surfaceContext: controller.contextFor(surfaceId))"
    - "genui imported with `hide TextPart` + alias — both genui and firebase_ai export TextPart"

key-files:
  created:
    - lib/spike_genui/agent/present_activity_tool.dart
    - lib/spike_genui/catalog/stroke_canvas_item.dart
    - lib/spike_genui/catalog/spike_catalog.dart
    - lib/spike_genui/agent/gemini_transport.dart
    - lib/spike_genui/main_spike_genui.dart
    - lib/spike_genui/spike_app.dart
  modified:
    - pubspec.yaml
    - pubspec.lock

key-decisions:
  - "Render widget is `Surface` (Surface(surfaceContext:)), NOT 'GenUiSurface' — the latter does not exist in genui 0.9.2"
  - "Data-binding accessor is itemContext.data as JsonMap + extension type, and BoundString for model-bound strings (NOT context.value<String>() nor subscribeToString+ValueListenableBuilder)"
  - "Promoted json_schema_builder to a direct dep so the spike can author S.object schemas; pinned to the already-resolved 0.1.5 (no other package moved)"
  - "Used streaming generateContentStream -> addChunk (the plan key_link), not the SKILL.md non-streaming startChat().sendMessage"

patterns-established:
  - "GenUI custom-catalog hosting seam for a native real-time widget (stable ValueKey preserves widget State across surface rebuilds)"
  - "Spike-local instrumentation wrapper prints canvas State init/dispose — Pitfall-1 teardown visible WITHOUT editing the durable canvas"

requirements-completed: []

# Metrics
duration: 9min
completed: 2026-06-21
---

# Phase 11 Plan 02: GenUI Catalog + Native Canvas A/B Harness Summary

**Built the throwaway A/B kill-shot harness — the real native StrokeCanvas registered as a custom GenUI `present_activity` CatalogItem and embedded under a stable ValueKey inside a model-generated mixed tree (coaching line above), driven by Gemini Flash over GenUI's A2UI streaming transport, with a SegmentedButton toggle between the GenUI-embedded arm and the identical standalone canvas — all authored against the VERIFIED installed genui 0.9.2 / firebase_ai 3.13.0 source, analyze-clean, and the spike target builds a debug APK.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-06-21T15:23:12Z
- **Completed:** 2026-06-21T15:32:45Z
- **Tasks:** 3 of 3 done (all type=auto)
- **Files:** 6 created, 2 modified (pubspec)

## Installed genui 0.9.2 / firebase_ai 3.13.0 API — AS ACTUALLY USED (the source of truth, not the drifting docs)

The plan mandated reading the INSTALLED package source first. Resolved at
`~/.pub-cache/hosted/pub.dev/genui-0.9.2` and `firebase_ai-3.13.0`. The authoritative
wiring reference turned out to be a bundled skill:
`genui-0.9.2/skills/integrate-genui-firebase/SKILL.md`.

**Data-binding accessor (Task 1 — what genui 0.9.2 actually uses):**
- `widgetBuilder: (CatalogItemContext itemContext) => Widget`.
- The component data is `itemContext.data as JsonMap` (`JsonMap = Map<String, Object?>`),
  parsed via an `extension type` (mirrors genui's own `basic_catalog_widgets/text.dart`
  `_TextData`).
- A **model-bound string** is declared in the schema as `A2uiSchemas.stringReference(...)`
  (a `oneOf` of literal / data-binding / functionCall) and rendered with
  **`BoundString(dataContext: itemContext.dataContext, value: <ref>, builder: (ctx, val) {...})`**.
  - So the accessor form is **NOT** `context.value<String>(...)` and **NOT**
    `subscribeToString + ValueListenableBuilder` (the two RESEARCH hypotheses) — it is
    `BoundString` over `itemContext.dataContext` (a `ValueListenableBuilder` *internally*).
- Custom CatalogItem: `CatalogItem(name:, dataSchema: S.object(...), widgetBuilder:)`. The
  `component` discriminator is injected automatically from `name` (do NOT declare it).
- Schema builder: `S` is `json_schema_builder`'s `Schema` (`typedef S = Schema`);
  `S.object(...)` returns `Schema` (factory delegates to `ObjectSchema`).

**Transport symbols (Task 2 — confirmed to exist):**
- `FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash', systemInstruction: Content.system(...))`
  — `FirebaseVertexAI` / `firebase_vertex_ai` are **dead** and absent (Pitfall 5). ✅
- `A2uiTransportAdapter({ManualSendCallback? onSend})` with `void addChunk(String text)`
  — both exist exactly as named. ✅
- `model.generateContentStream(Iterable<Content>)` → `Stream<GenerateContentResponse>`;
  each `response.text` chunk fed to `_transport.addChunk(...)`. ✅
- `SurfaceController(catalogs: [...])` + `Conversation(controller:, transport:)`;
  events are `ConversationSurfaceAdded` / `ConversationError` (sealed).
- The `onSend` callback receives a **genui `ChatMessage`** (from `genai_primitives`); its
  parts are read via `part.isUiInteractionPart` / `part.asUiInteractionPart!.interaction`
  and `part is genui.TextPart` / `part.text`.

**Render widget (Task 3):**
- It is **`Surface(surfaceContext: controller.contextFor(surfaceId))`** — there is **no**
  `GenUiSurface` type in genui 0.9.2 (the RESEARCH/PATTERNS shorthand name). Recorded for
  Phase 14.

**TextPart conflict:** both `genui` and `firebase_ai` export `TextPart`. Per the bundled
skill, `gemini_transport.dart` does `import 'package:genui/genui.dart' hide TextPart;` +
`import 'package:genui/genui.dart' as genui;` so the firebase_ai `TextPart`/`Content` are
bare and the genui one is `genui.TextPart`.

## Accomplishments

- **Task 1** — `present_activity` is a custom GenUI `CatalogItem` (D-11, the spike's only
  tool): a `Column` with the model-bound `coachingLine` as `BoundString`-driven `Text` on
  top (D-04) and an `Expanded` real `StrokeCanvas` below under a **stable
  `ValueKey('spike-embedded-canvas')`** (D-03, Pitfall-1 mitigation). A spike-local
  `_InstrumentedCanvas` wrapper prints canvas State init/dispose so a torn-down State
  mid-trace is visible during the A/B — the print lives ONLY in spike code, never in
  durable `stroke_canvas.dart`. No scoring callbacks wired (D-07). The catalog merges the
  basic GenUI catalog + present_activity via `copyWith`.
- **Task 2** — `GeminiTransport` wires `FirebaseAI.googleAI()` Flash into the A2UI
  transport: `onSend` collects text/interaction parts, calls `generateContentStream`, and
  feeds each chunk to `addChunk`; `start()` kicks the loop sending only the kickoff text +
  `letterId:"baa"`. Model/transport errors are caught and surfaced via `onDrop` (a visible
  DROP finding — GATE data, not a crash). No `Offset`/PII path exists (T-11-03).
- **Task 3** — `main_spike_genui.dart` is its own `flutter run -t` target (lockOrientation
  verbatim + `Firebase.initializeApp(DefaultFirebaseOptions.currentPlatform)` +
  `configureLogging` + bare `runApp(SpikeApp())`, no ProviderScope — StrokeCanvas is a
  plain StatefulWidget). `spike_app.dart` is a plain `MaterialApp` whose home toggles via
  `SegmentedButton` between **[A]** a GenUI `Surface` (present_activity tree) and **[B]**
  the same standalone `StrokeCanvas` under `ValueKey('spike-standalone-canvas')` on the
  same baa fixture (D-05).
- `flutter analyze lib/spike_genui` exits 0; **`flutter build apk --debug -t
  lib/spike_genui/main_spike_genui.dart` built successfully** (the strongest acceptance
  gate — the spike target compiles for Android, beyond analyze-clean).
- Both Plan-01 guards stay green (package-correctness + SC-4 durable-diff); production
  `lib/main.dart` untouched.

## Task Commits

1. **Task 1: present_activity catalog item hosting native StrokeCanvas** — `c318f31` (feat)
2. **Task 2: Gemini Flash A2UI transport + present_activity loop** — `b52a07f` (feat)
3. **Task 3: A/B harness scaffold + main_spike_genui.dart entrypoint** — `446f9e7` (feat)

Plan metadata committed separately with this SUMMARY + STATE.md + ROADMAP.md.

## Gesture / scroll-ancestor observations (Pitfall 2 / Open Q2)

- The embedded canvas is placed in a **non-scrolling** `Column` (Task 1) and the embedded
  arm body is the bare `Surface` with no `ScrollView` ancestor (Task 3) — the deliberate
  mitigation for Pitfall 2 (the `Listener`-based `StrokeCanvas` loses stylus drags inside
  a scroll view). `PromptBuilder.chat` uses `SurfaceOperations.createOnly` so the model
  emits new surfaces rather than wrapping content in scrollables.
- **Caveat — static-analysis stage only.** This plan's gates are `flutter analyze` + the
  APK build; no stylus/scroll behaviour was exercised at runtime. Whether GenUI's own
  surface rebuild path preserves `_StrokeCanvasState` (Pitfall 1) and whether any GenUI
  ancestor steals the drag (Pitfall 2) is the **on-device** question Plan 03 answers with
  a real Pixel Tablet + stylus. The `_InstrumentedCanvas` init/dispose prints are wired
  precisely so that A/B run can SEE a mid-trace teardown.

## App Check DEBUG fallback

- **Not exercised in this plan.** App Check stays unenforced in the throwaway scope (D-13).
  No live model call is made here (all gates are analyze + build), so no backend rejection
  could occur. If Plan 03's on-device `present_activity` call is rejected for missing App
  Check, the transport already routes the failure to a visible DROP finding, and the A3
  fallback (register the App Check **DEBUG** provider) applies there. This unenforced
  posture MUST NOT carry into Phase 14 (TUTOR-03 enforces App Check).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Promoted json_schema_builder to a direct dependency**
- **Found during:** Task 1
- **Issue:** the present_activity CatalogItem must author its `dataSchema` via `S.object`
  (json_schema_builder), but that package was only a transitive dep of genui — the IDE
  flagged an "isn't a dependency" import. genui does not re-export the schema builder.
- **Fix:** added `json_schema_builder: ^0.1.5` to `pubspec.yaml` dependencies (pinned to
  the already-resolved transitive version so no other package moved) and ran `flutter pub
  get`. This is the same package genui's own catalog items import directly.
- **Files modified:** `pubspec.yaml`, `pubspec.lock`
- **Commit:** `c318f31`

### Authored-API corrections vs RESEARCH/PATTERNS shape snippets (expected — the plan mandated reading the installed source)

- Render widget is **`Surface`**, not the RESEARCH shorthand "GenUiSurface".
- Data accessor is **`itemContext.data as JsonMap` + `BoundString`**, not
  `context.value<String>()` nor `subscribeToString + ValueListenableBuilder`.
- Used **streaming** `generateContentStream -> addChunk` (the plan's `key_link`), not the
  bundled skill's non-streaming `startChat().sendMessage`.

These are not deviations from intent — the plan explicitly required authoring against the
verified installed API rather than the drifting docs.

## Issues Encountered

- IDE flagged `S.object` returning `Schema` (not `ObjectSchema`) — fixed the function
  return type to `Schema` (the static type of `S.object`; CatalogItem re-wraps internally).
- macOS `bash` has no `timeout` binary (irrelevant — the APK build was run directly and
  succeeded in ~110s). No other issues; every gate passed on the first run after fixes.

## Known Stubs

None that block the plan's goal. The embedded arm [A] shows a "Waiting for the model…"
placeholder until a surface arrives — this is intentional: the live model call needs
Firebase AI Logic enabled (Plan 11-01 Task 3, still pending human console action) and runs
on-device in Plan 03. The standalone arm [B] is fully live with the real canvas + fixture.

## Threat Flags

None. This plan introduces no network surface beyond the already-registered (and
unenforced-by-design, D-13) Firebase AI Logic call in the threat register (T-11-02/03).
The transport sends only present_activity text + letterId; the grep acceptance check
(no `Offset`/`nickname`/`childName` in code) is green.

## Next Phase Readiness

- **Plan 03 (on-device A/B capture) is unblocked code-wise:** the runnable spike target
  exists, both arms are wired, and the debug APK builds. It remains gated on (a) Firebase
  AI Logic enabled on qalam-app-bd7d0 (Plan 11-01 Task 3 pending human action) and (b) a
  real Pixel Tablet + stylus (D-06) — both are runtime prerequisites, not code.
- **Phase 14 inherits** the verified API forms recorded above (Surface, BoundString data
  accessor, A2uiTransportAdapter/generateContentStream/addChunk, the TextPart hide+alias).
- Both Wave-0 guards must stay green for the rest of the spike: re-run
  `flutter test test/spike_genui/` after any spike change.

## Self-Check: PASSED

All 6 created files exist on disk and all 3 task commits exist in git history
(c318f31, b52a07f, 446f9e7). `flutter analyze lib/spike_genui` exits 0; the debug APK
built; SC-4 durable-diff guard green; production lib/main.dart untouched.

---
*Phase: 11-spike-genui-catalog-native-stylus-canvas-kill-shot*
*Completed: 2026-06-21*
