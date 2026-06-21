# Phase 11: SPIKE — GenUI catalog + native stylus canvas (kill-shot) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-21
**Phase:** 11-spike-genui-catalog-native-stylus-canvas-kill-shot
**Areas discussed:** GenUI substrate, Hosting seam, GATE pass bar, Harness isolation

---

## GenUI substrate under test

| Option | Description | Selected |
|--------|-------------|----------|
| Official flutter_genui SDK | Google's flutter_genui + firebase_ai — the real thing we'd ship; young/experimental, which is why it's the kill-shot | ✓ |
| Hand-rolled catalog | Tiny home-grown registry driven by firebase_ai calls — but this IS the fallback arm; blurs the two GATE arms | |
| Both, side by side | Build a slice on each arm and compare — ~2x throwaway effort for one decision | |

**User's choice:** Official flutter_genui SDK.
**Notes:** The "drop GenUI" arm (raw firebase_ai + small native dispatcher) is the assumed-safe
fallback — not built in this spike; it's the known-good destination if the SDK arm fails.

---

## Hosting seam (the crux)

| Option | Description | Selected |
|--------|-------------|----------|
| Embedded in the tree | Native StrokeCanvas registered as a catalog widget, lives INSIDE GenUI's generated tree; tests whether a fast stylus stays native under model-generated parent UI | ✓ |
| Adjacent / signalled | present_activity triggers a native route GenUI only signals; canvas renders outside the tree — barely tests "hosting", risks a falsely-rosy GATE | |
| Try embedded, fall back to adjacent | Attempt embedded, document fallback as in-spike workaround — more work | |

**Follow-up — richness of the mixed tree:**

| Option | Description | Selected |
|--------|-------------|----------|
| Canvas + one coaching line | GenUI generates one coaching text line above the embedded native canvas — minimal but genuinely mixed | ✓ |
| Bare canvas only | GenUI tree is just the canvas — under-tests the mixed-tree point of GenUI | |
| Coaching line + hint + retry | Fuller activity — starts rebuilding the real exercise UI inside a throwaway | |

**User's choice:** Embedded in the tree, with one model-generated coaching line above the canvas.
**Notes:** "Hosting" is really about a mixed tree — model-generated chrome wrapping a native
real-time child. One coaching line proves coexistence without scope creep.

---

## GATE pass bar

| Option | Description | Selected |
|--------|-------------|----------|
| Feel + A/B capture on device | Trace baa on embedded AND standalone canvas on a real Pixel Tablet; confirm indistinguishable by feel; record video. Matches "presence is felt" | ✓ |
| Measured input-to-ink frames | Instrument both canvases, numeric frame-timing bar — rigorous but real instrumentation overlaps Phase 12 and is overkill for a throwaway | |
| Feel-primary + rough frame sanity | Feel/A-B is the verdict + lightweight jank-count backstop — middle ground | |

**Follow-up — time-boxing the kill-shot:**

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed time-box → GATE either way | Hard iteration budget (~2–3 days); if embedded-native isn't clean by then, that difficulty IS the "drop GenUI" evidence | ✓ |
| Push until it works | Iterate until flutter_genui hosts the canvas, however long — unbounded effort on the riskiest phase | |
| Escalate at first hard wall | Stop at first API limitation and bring to user — keeps user in loop but may stop short of a full verdict | |

**User's choice:** Feel + A/B capture on a real Pixel Tablet; fixed time-box → GATE either way.
**Notes:** This spike judges only the canvas's own responsiveness under GenUI; full-path latency
is Phase 12. A kill-shot must be allowed to kill — difficulty embedding is itself a verdict.

---

## Harness isolation

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated spike entrypoint | Self-contained lib/spike_genui/ + main_spike_genui.dart; imports real canvas read-only; production main.dart + durable layers untouched; trivially deletable | ✓ |
| Dev-flagged hidden route | Debug-only route behind a dev flag in the real app — fastest onto device but lingers in prod tree | |
| Throwaway branch, edit in place | Disposable branch, rely on git — weakest guarantee durable files stayed unchanged | |

**User's choice:** Dedicated spike entrypoint (lib/spike_genui/ + main_spike_genui.dart).
**Notes:** Criterion 4 (durable layers unchanged) proven by construction — additive, imports-only;
a git diff on canvas/scorer/curriculum paths must be empty.

---

## Claude's Discretion

- Wire only the `present_activity` tool in the spike (not the full 4-tool ACTION set — those land in Phase 14).
- Use a Gemini Flash model via Firebase AI Logic to drive the function-calling loop (model comparison is Phase 12/13).
- Exact time-box length, App Check posture in throwaway scope, and the SPIKE-FINDINGS verdict-doc shape left to research/planning; findings to be packaged via /gsd:spike-wrap-up.

## Deferred Ideas

- Full-path latency / presence budget + model & transport choice → Phase 12.
- Grounding-faithfulness + Arabic-register bake-off (Authored vs Gemini vs Gemma) → Phase 13.
- Production TutorBrain spine, full 4-tool ACTION set, FACTS injection, non-PII network guard → Phase 14.
- Building the raw-firebase_ai fallback dispatcher → only if the GATE says "drop GenUI" (Phase 14 build work).
