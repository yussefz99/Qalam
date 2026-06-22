# Spike Findings — GenUI catalog + native stylus canvas (Phase 11 kill-shot)

**Date:** 2026-06-22
**Decision authority:** owner, on the evidence below + [ADR-014](../../../docs/architecture/ADR-014-v2-tutor-agent-architecture.md)

## GATE: drop

Drop GenUI (A2UI) as the v2 tutor's UI/agent layer. Phase 14 builds the **raw `firebase_ai`
function-calling + native dispatcher** architecture instead (the D-02 fallback). The full
architecture is recorded in **ADR-014**.

## Verdict

**Can the GenUI core catalog cleanly host the real-time native `StrokeCanvas`?** On the
evidence, *technically yes* — but we are **dropping it anyway** on product/risk grounds, not
because it failed. This is a confident GATE, not an inconclusive one.

## What was observed (on-device, Pixel Tablet emulator, 2026-06-21)

The on-device A/B ran on the **Pixel Tablet emulator** (a real device was not required once the
decision turned on architecture rather than pen-feel — see "Why the real-device test is moot"):

- ✅ **Firebase AI Logic works** — Gemini Flash returned a `present_activity` tree (the owner
  enabled AI Logic on `qalam-app-bd7d0`; the model call round-tripped).
- ✅ **The mixed tree renders** — a model-authored coaching line above the **real native
  `StrokeCanvas`**, in one GenUI surface (D-03/D-04 satisfied).
- ✅ **Pitfall 2 clear** — the embedded canvas receives stylus/pointer drags and renders ink;
  no GenUI ancestor steals the gesture.
- ✅ **State survives the realistic update** — when the model pushed a *new* coaching line
  (a genuine `UpdateComponents` surface update, triggered deliberately), the canvas State and
  the in-progress ink were **preserved** (0 disposes). Idle for 160s: also preserved.
- ⚠️ **Pitfall 1 (intermittent):** in 2 of 4 runs an *unprompted* GenUI surface rebuild
  disposed the canvas State (under both a `ValueKey` and a `GlobalKey`); it could **not** be
  reproduced under direct testing (neither idle nor a model update triggered it). Trigger
  uncharacterized — a residual risk, not a proven failure.
- 🐞 **One real bug found + fixed:** the spike registered its catalog under a custom id while
  the model emits the canonical A2UI `basicCatalogId`; keeping the canonical id made it render.
  (Exactly the kind of pre-1.0 API-drift this spike existed to flush out.)

## Why we drop it anyway (summary; full reasoning in ADR-014)

The exhaustive v2-architecture research (8 clusters, 11 claims verified) showed the entire 2026
protocol stack (AG-UI / A2UI / MCP) is built for a **server + React** topology we don't have;
`genui`/A2UI is still **0.9.2 alpha** with the canvas-teardown risk unfixed, and its core design
(stream widget state back to the LLM) is the architectural opposite of Qalam's *scorer-owns-the-
verdict* grounding invariant and two-clocks reflex. The v2 design (4 ACTION tools) is a
**function-calling** shape, not an A2UI surface-streaming shape. Keeping the proven v1 native
canvas out of any reactive framework is lower-risk and what real Flutter apps ship.

## Why the real-device pen-feel test is moot

Plan 11-03 reserved a real-Pixel-Tablet feel test. Under this drop decision, the canvas is **not**
hosted in GenUI — it stays the exact v1 native `StrokeCanvas` already validated in Phases 1–7.
There is no GenUI-hosting feel question left to answer, so the test is superseded by the GATE.

## Hand-off to Phase 14 (known-good versions + posture)

- **Resolved package set** (re-pin at Phase 14 plan time — these ship ~monthly):
  `firebase_ai 3.13.0`, `firebase_core 4.11.0`, `firebase_auth 6.5.3`,
  `firebase_app_check 0.4.5` (transitive), `flutter_gemma 1.0.2` (on-device, experimental).
  `genui 0.9.2` / `json_schema_builder 0.1.5` were spike-only and are **removed** with the spike.
- **Installed genui 0.9.2 API note** (for the record, now unused): data-binding via
  `BoundString` + `A2uiSchemas.stringReference`; render widget is `Surface` (not `GenUiSurface`).
- **App Check was left UNENFORCED in the throwaway spike (D-13).** Phase 14 **MUST** enforce
  App Check (limited-use / replay-protection tokens) — TUTOR-03. This posture must NOT carry
  into prod.
- **firebase_ai function-calling caveats verified for Phase 14:** structured-output +
  function-calling throws (inject FACTS as text, not `responseSchema`); streaming + tool-calls
  is undocumented on Dart (run ACTION turns non-streamed). See ADR-014 §Decision.

## SC-4 — durable layers confirmed unchanged

The spike was fully additive under `lib/spike_genui/` + `test/spike_genui/`. The SC-4 git-diff
guard (`test/spike_genui/durable_layers_unchanged_test.dart`) stayed green for the whole spike;
no durable file (`stroke_canvas.dart`, `letter_unit/`, `core/scoring/`, `core/exercise_engine/`,
`assets/curriculum/`) was touched. The spike is deletable (revert pubspec + remove
`lib/spike_genui/`) to return the repo to baseline.
