# Phase 11: SPIKE — GenUI catalog + native stylus canvas (kill-shot) - Context

**Gathered:** 2026-06-21
**Status:** Ready for planning

<domain>
## Phase Boundary

A **throwaway spike** that answers ONE architecture question and records a GATE — it
ships no production feature and owns no requirement.

**The question:** Can a GenUI **core catalog**, driven by a local `firebase_ai`
function-calling loop, **cleanly host the existing real-time native stylus canvas**
(StrokeCanvas/WriteSurface) via a `present_activity` tool — with the pen staying native
and lag-free (no per-stroke network round-trip, no rendering lag)?

**The output:** a written, evidence-backed verdict and a recorded **GATE** —
*keep GenUI* OR *drop GenUI and have raw `firebase_ai` function-calling drive our native
widgets directly* — so Phase 14 is told which architecture to build.

**Hard boundary:** the spike touches NO production canvas/scorer/curriculum code. It may
*import* the real canvas widgets read-only to host them, but modifies none of them. The
durable layers (canvas, geometric scorer, Schema-v2 curriculum) must be confirmed
unchanged at the end (Success Criterion 4 / TUTOR-01 invariant).

**Not in this phase** (owned elsewhere): full-path stroke→agent→TTS latency and the
model/transport choice (Phase 12); grounding/Arabic-register bake-off across brains
(Phase 13); the production TutorBrain spine, the full 4-tool ACTION set, and the grounding
invariant in code (Phase 14).

</domain>

<decisions>
## Implementation Decisions

### GenUI substrate under test
- **D-01:** The substrate under test is the **official `flutter_genui` SDK + `firebase_ai`** —
  the actual thing we'd ship if the GATE says "keep". This is the kill-shot precisely
  because the SDK is young/experimental.
- **D-02:** The "drop GenUI" arm of the GATE — **raw `firebase_ai` function-calling driving
  our native widgets directly via a small hand-rolled dispatcher** — is treated as the
  **assumed-safe fallback**. The spike does NOT build it; it is the known-good destination
  if the SDK arm fails. (Reason: that fallback is essentially a tiny native dispatcher we
  already know is buildable; building it would just blur the two GATE arms.)

### The hosting seam (the crux)
- **D-03:** The native StrokeCanvas is registered as a **GenUI catalog widget and embedded
  INSIDE GenUI's model-generated widget tree** — GenUI owns the surrounding layout. This is
  the strongest test of "hosting": does a fast stylus stay native and lag-free when its
  parent is model-generated UI? (The "adjacent/signalled" approach — a native route GenUI
  only triggers — was rejected as too close to the fallback arm; it would risk a falsely-rosy
  GATE.)
- **D-04:** The test must exercise a **genuinely MIXED tree**: GenUI generates **one coaching
  text line** (e.g. "trace the baa, slow at the curve") **above** the embedded native canvas.
  Proves model-generated text and native real-time ink coexist in one tree, without rebuilding
  the real exercise UI. (Bare-canvas-only rejected as under-testing; full coaching+hint+retry
  rejected as spike-scope creep.)

### The GATE pass bar
- **D-05:** The sharp test is **embedded-vs-standalone**: trace baa on the embedded canvas AND
  on the same canvas standalone, and judge whether GenUI hosting degrades it.
- **D-06:** Evidence = **feel + A/B capture on a real Pixel Tablet** (not emulator/dev host):
  confirm by feel the two are indistinguishable, recorded as screen-capture/video. Matches the
  v2.0 "presence is felt, not specified" philosophy. Frame-timing instrumentation was
  deliberately NOT required here — that rig overlaps Phase 12 and is overkill for a throwaway.
- **D-07:** This spike judges only the **canvas's own responsiveness under GenUI**. Full-path
  stroke→scorer→agent→render→first-TTS latency is **Phase 12's** job — do not build that
  measurement rig here.
- **D-08:** **Fixed time-box → GATE either way.** Set a hard iteration budget (~2–3 focused
  days; planner to confirm). If clean embedded-native hosting isn't working by then, that
  difficulty **IS the evidence** — record "drop GenUI" and tell Phase 14 to build the raw
  `firebase_ai` fallback. A kill-shot must be allowed to kill; do not iterate unbounded.

### Harness isolation
- **D-09:** The throwaway lives in a **dedicated `lib/spike_genui/` folder with its own
  `main_spike_genui.dart` app target**, importing the real canvas widgets read-only.
  Production `main.dart` and the durable layers stay untouched, and the whole spike is
  trivially deletable after the GATE. (Dev-flagged route rejected: lingering throwaway in the
  prod tree. Edit-in-place-on-branch rejected: weakest guarantee that durable files stayed
  unchanged.)
- **D-10:** Criterion 4 (durable layers unchanged) is proven by construction — the spike folder
  is additive and imports-only; a `git diff` on canvas/scorer/curriculum paths must be empty.

### Claude's Discretion (defaults — researcher/planner may adjust)
- **D-11:** Wire only the **`present_activity`** tool in the spike — not the full 4-tool ACTION
  set (`say`/`give_hint`/`advance` come in Phase 14). The spike only needs the agent to call
  one tool that renders the activity.
- **D-12:** Use a **Gemini Flash** model via Firebase AI Logic to drive the function-calling
  loop. Model comparison (Flash vs Flash-Lite vs Live API vs Gemma) is Phase 12/13's job, not
  this spike's — any Gemini model that supports function-calling is fine here.
- **D-13:** Exact time-box length, App Check posture in throwaway scope, and the precise shape
  of the SPIKE-FINDINGS verdict doc are left to research/planning. Findings should be packaged
  via `/gsd:spike-wrap-up` so downstream phases can consume them.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase definition & milestone framing
- `.planning/ROADMAP.md` §"Phase 11" (lines ~592–609) — the goal, 4 success criteria, and the
  GATE the spike must record; also the v2.0 milestone overview (lines ~559–589) for why
  spikes-first.
- `.planning/PROJECT.md` §"Current Milestone: v2.0 AI Tutor" — the grounding invariant, the
  "API key never in the client via Firebase AI Logic + App Check" rule, and the reversal
  notes (tutor now client-side, on Gemini/Gemma not Claude).
- `.planning/REQUIREMENTS.md` §"v2.0 Requirements" + §"v2.0 Traceability" — TUTOR-01 (durable
  layers carry zero GenUI/A2UI/firebase_ai imports), TUTOR-05 (agent acts only through ACTION
  tools incl. `present_activity`); note Phase 11 owns NO requirement by design and feeds the
  Phase 14 GATE.

### Durable layers the spike must host (read-only, do not modify)
- `lib/features/letter_unit/widgets/write_surface.dart` — the WriteSurface this spike embeds.
- `lib/features/practice/widgets/stroke_canvas.dart` — the StrokeCanvas (real-time native ink)
  whose responsiveness is the thing under test.
- `lib/features/letter_unit/exercise_controller.dart` and
  `lib/features/letter_unit/letter_unit_controller.dart` — the ExerciseController seam Phase 14
  will wire to; the spike should respect (not rewire) it.
- `lib/core/scoring/geometric_stroke_scorer.dart` — the scorer that owns the verdict (grounding
  invariant); not exercised here but must remain untouched.

### Build/runtime context
- `pubspec.yaml` — `firebase_core`/`firebase_auth` already wired; `firebase_ai` and
  `flutter_genui` are NOT yet present and are added in throwaway scope only.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **StrokeCanvas** (`lib/features/practice/widgets/stroke_canvas.dart`) and **WriteSurface**
  (`lib/features/letter_unit/widgets/write_surface.dart`): the real-time native ink widgets the
  spike registers as a GenUI catalog widget and embeds — imported read-only.
- **Firebase already initialized**: `firebase_core` (init in `main.dart`) and `firebase_auth`
  (anonymous-at-launch) are wired, so `firebase_ai` can attach to the existing Firebase app
  without new project setup.

### Established Patterns
- **Durable-layers-are-sacred (TUTOR-01):** durable canvas/scorer/curriculum carry zero
  GenUI/A2UI/firebase_ai imports. The spike enforces this structurally by living entirely in
  `lib/spike_genui/` and importing the durable widgets, never editing them.
- **Scorer owns the verdict, agent owns the words** (grounding invariant): not under test here,
  but the present_activity seam the spike prototypes must not let the model fabricate write
  quality — kept in mind so the spike doesn't model a seam Phase 14 would have to undo.

### Integration Points
- **`present_activity` → embedded native canvas**: the one seam this spike proves. The
  function-calling loop (`firebase_ai`) calls `present_activity`; the GenUI catalog resolves it
  to a tree containing one coaching line + the embedded native StrokeCanvas.
- **Separate entrypoint**: `main_spike_genui.dart` is its own `flutter run -t` target so the
  production app boot path is untouched.

</code_context>

<specifics>
## Specific Ideas

- The decisive demo is **A/B on a real Pixel Tablet**: the same child tracing baa on the
  embedded canvas vs the standalone canvas, captured on video, judged indistinguishable by
  feel. The video IS the evidence attached to the GATE.
- The GATE has exactly two destinations and both are pre-named: **keep `flutter_genui`** or
  **drop to raw `firebase_ai` + tiny native dispatcher**. Phase 14 reads whichever is recorded.

</specifics>

<deferred>
## Deferred Ideas

- **Full latency / presence budget + model & transport choice** → Phase 12 (this spike only
  judges canvas responsiveness, by feel, on device).
- **Grounding-faithfulness + Arabic-register bake-off (Authored vs Gemini vs Gemma)** →
  Phase 13.
- **Production TutorBrain spine, full 4-tool ACTION set (`say`/`give_hint`/`advance`), FACTS
  injection, and the non-PII network guard** → Phase 14 (which also consumes this spike's GATE).
- **Building the raw-`firebase_ai` fallback dispatcher** → only if the GATE says "drop GenUI";
  it is Phase 14 build work, not spike work.

</deferred>

---

*Phase: 11-spike-genui-catalog-native-stylus-canvas-kill-shot*
*Context gathered: 2026-06-21*
