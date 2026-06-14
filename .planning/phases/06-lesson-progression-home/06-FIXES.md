# Phase 06 — Device-UAT Fixes (pickup next session)

**Found:** 2026-06-13 device UAT on Pixel Tablet, after merging the owner's refined
reference strokes for 21/28 letters into `assets/curriculum/letters.json`.

## Working-tree state at handoff (READ FIRST)

- `assets/curriculum/letters.json` — **MODIFIED, uncommitted, not pushed.** Holds the
  owner's refined `referenceStrokes` for 21 letters (Arabic + commonMistakes preserved
  from disk; only stroke points swapped in). Durable on disk; survives reboot.
- `lib/core/scoring/stroke_validation.dart` — **restored to `kClosedLoopEpsilon = 0.30`**
  (a temporary preview bypass of 0.08 was reverted). With the gate at 0.30 the 9 curl
  letters below FAIL to load, so the app will crash on those letters until Fix A lands.
- Nothing committed/pushed this session. `origin/main` is at the Phase 6 close (`98ff0e6`).
- These strokes are **unsigned drafts** (`signedOff: false`). Per the project rule, the
  owner's mother reviews + signs off; do not flip `signedOff` here.

---

## Fix A — Validator false-positives on legitimate curl letters

**Symptom:** Load throws `Invalid referenceStrokes for letter "jeem": ... looks like a
closed outline loop`. Cascades to the curriculum integrity tests.

**Root cause:** The D-04 closed-loop guard in `lib/core/scoring/stroke_validation.dart`
flags a stroke as an outline when BOTH (1) first≈last endpoint distance `< kClosedLoopEpsilon`
(0.30) AND (2) path-length / bbox-diagonal ratio `>= kLoopLengthRatio` (1.8). It was built
to catch the Phase-2 bug where alif was authored as a *closed glyph outline* (returns to
~0.0 from start). But legitimate **curl letters** (the pen genuinely loops back near the
start) return 0.12–0.29 from start over a winding path, so they trip the same heuristic.
These are **false positives** — the strokes are correct centerlines, not outlines.

**The 9 affected letters** (first≈last distance / ratio):
jeem 0.289/2.10 · haa_c 0.270/2.17 · khaa 0.272/2.14 · saad 0.193/2.08 ·
daad 0.189/2.08 · taa_h 0.121/2.66 · ayn 0.268/2.04 · ghayn 0.258/2.19 · faa 0.265/2.15.

**Fix (with owner sign-off on the threshold):**
- Lower `kClosedLoopEpsilon` from `0.30` to `0.10`. A true closed outline returns to
  ~0.0 from its start; every curl above ends ≥0.12 away, so 0.10 admits all 9 while still
  catching a genuine closed loop. (taa_h at 0.121 is the tightest — 0.10 clears it with margin.)
- Update the doc-comment in `stroke_validation.dart` to explain the curl-vs-outline
  distinction (so this isn't "re-loosened by mistake" later).
- **Confirm-before-shipping:** verify each of the 9 is a **centerline** (pen-tip path down
  the middle), not an **edge-trace** (around the letter's outline). jeem's numbers look like
  a centerline. If any was traced around the edge, that ONE needs re-authoring (it would also
  confuse the scorer) — don't mask it with the threshold.
- Alternative if 0.10 proves too blunt later: a smarter discriminator (enclosed-area, or
  detecting two near-parallel passes that signal an outline). Not needed now.

**Verify:** `flutter test test/data/curriculum_repository_test.dart` (the "SHIPPED
letters.json passes the validator at load" + integrity tests go green).

---

## Fix B — Dots are invisible in the Watch animation AND the trace guide

**Symptom:** Every dotted letter's dot(s) don't appear in the stroke-order animation. Likely
also absent from the dotted guide the child traces over. Affects **15 letters**: baa, taa,
thaa, jeem, khaa, dhaal, zaay, sheen, daad, zhaa, ghayn, faa, qaaf, noon, yaa.

**Root cause (two compounding):**
1. `lib/core/scoring/reference_path.dart` — `ReferencePath.resolve()` returns **only point
   lists and discards the `type` field**. So downstream painters can't tell a `dot` from a
   1-point line.
2. `lib/features/practice/widgets/stroke_order_animation.dart` — `_buildScaledPath()` does
   `path.moveTo(point)` for a single-point dot stroke with no `lineTo`. A moveTo-only subpath
   has **zero length**, so `computeMetrics()` yields nothing to draw → the dot never paints.
   `stroke_canvas.dart` resolves the same way for its dotted guide → same gap.

**Fix:**
- The animation painter already receives the full `List<StrokeSpec> referenceStrokes` (which
  HAS `type`). Iterate those (not just the flattened points) so the painter knows which
  strokes are dots. For `type == "dot"`, paint a **filled ink circle** at the scaled point
  (ink color, ~stroke-width radius), sequenced at the right point in the animation timeline
  (a dot stroke "draws" instantly after the body stroke it follows, in `order`).
- Apply the same dot-rendering to `stroke_canvas.dart`'s dotted guide so the child sees where
  the dot goes while tracing.
- Keep dot strokes out of the polyline path-metric length math (they have no length); advance
  the animation a small fixed beat for each dot instead, so the timing stays natural.
- Decide (owner UX call): does the gold pen-tip "tap" onto the dot, or does the dot just
  appear? Matches the celebration/anti-gamification tone — a calm tap, no bounce.

**Verify:** add/extend `test/features/practice/stroke_order_animation_test.dart` to assert a
dotted letter (e.g. baa) paints a circle for its dot stroke; manual device check that baa/taa/
thaa dots render in both Watch and Trace.

---

## How to pick this up

These are device-UAT defects against Phase 6's human-verification gate (`06-HUMAN-UAT.md`).
Options next session:
- `/gsd:plan-phase 6 --gaps` → gap-closure plan covering Fix A + Fix B, then
  `/gsd:execute-phase 6 --gaps-only`; OR
- two quick fixes via `/gsd:quick` if you'd rather not formalize.

Re-run the full suite after both; the only expected residual failure is the `glyph_audit`
golden (environmental font drift — never re-bake).
