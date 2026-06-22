---
phase: 11-spike-genui-catalog-native-stylus-canvas-kill-shot
plan: 03
status: complete
completed: 2026-06-22
---

# Summary — 11-03: On-device A/B + the GATE

## Outcome

**`GATE: drop`** — recorded at the canonical spike path and handed to Phase 14.

The spike's whole reason to exist was a confident architecture GATE. We have one, evidence-backed:
GenUI *can* host the native canvas (it renders, takes pen input, and preserves the canvas across
a realistic model coaching-update), but we **drop** it on product/risk grounds — pre-1.0 alpha,
a reactive layer near the sacred canvas, an ecosystem that is server+React-shaped, and a v2 design
(4 ACTION tools) that is function-calling, not A2UI surface-streaming. Phase 14 builds the raw
`firebase_ai` function-calling + native dispatcher architecture.

## How the human-verify checkpoint was resolved

Task 1 (real-Pixel-Tablet pen-feel A/B) is **superseded by the GATE**: under `drop`, the canvas is
not hosted in GenUI — it stays the v1 native `StrokeCanvas` already validated in Phases 1–7, so
there is no GenUI-hosting feel question left. The on-device A/B was instead exercised on the Pixel
Tablet **emulator**, which was sufficient to (a) confirm Firebase AI Logic + the mixed-tree render,
(b) clear Pitfall 2, and (c) show the realistic update preserves the canvas — enough to decide.

## Deliverables

- `.planning/spikes/11-genui-native-canvas/SPIKE-FINDINGS.md` — verdict, observations, the single
  `GATE: drop` line, the version/App-Check-posture hand-off, SC-4 confirmation.
- [ADR-014](../../../docs/architecture/ADR-014-v2-tutor-agent-architecture.md) — the full v2 tutor
  architecture this GATE feeds (accepted by owner 2026-06-22).
- Spike harness (`lib/spike_genui/`, `test/spike_genui/`) — additive, deletable; SC-4 green.

## Notes / deviations

- Decided via the exhaustive v2-architecture research workflow + ADR-014 rather than a real-device
  feel test, because the GATE turned on architecture/topology, not pen feel (the latter only mattered
  under a "keep" lean).
- App Check stayed unenforced in the throwaway spike (D-13); Phase 14 must enforce it (TUTOR-03).

## Self-Check: PASSED

- SPIKE-FINDINGS.md exists at the canonical path with exactly one `GATE: (keep|drop)` line. ✓
- Explicit verdict + observed A/B behavior + state-survival result recorded. ✓
- Resolved versions + App-Check-unenforced flag recorded for Phase 14. ✓
- SC-4 durable-diff guard green; spike deletable. ✓
