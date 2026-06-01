# Stroke Reference Paths — Correct Representation & Fix Plan

**Researched:** 2026-06-01
**Domain:** Teaching-stroke reference path representation for all 28 Arabic letters (Flutter/Dart, on-device geometric scorer + pen-tip animation, RTL, offline) — and the fix for the currently-broken Phase-2 extraction.
**Confidence:** HIGH on the failure diagnosis (numerically verified against the live data) and on the recommended pipeline shape; MEDIUM on skeletonization fidelity for Arabic glyphs (verified library APIs; pedagogical adequacy is the weak point — which is *why* the recommendation is owner-authoring); the per-letter stroke breakdown is an explicit **CANDIDATE for the owner's mother**, not authoritative pedagogy.

> This doc builds on `.planning/phases/03-trace-one-letter-end-to-end/03-RESEARCH.md` "THE SINGLE MOST IMPORTANT FINDING" and Q1. It does not repeat the Phase-3 scorer survey — it goes deeper on *where the reference path comes from and how we fix it*.

---

## 1. Problem Statement

`tools/extract_reference_paths.py` extracts each letter's glyph **outline contour(s)** from `NotoNaskhArabic-Regular.ttf` — the closed boundary of the filled letter shape — normalized to 64-point closed polylines, and writes them to `tools/candidate_paths.json`. The Phase-2 owner-mapping step then copied alif's single outline contour verbatim into `assets/curriculum/letters.json` as `referenceStrokes[0]`, labelled `vertical_stroke` / `direction: "topToBottom"`, and the letter was marked `signedOff: true`.

But the outline is the letter's **silhouette**, not the **centerline/skeleton** a pen tip travels when writing. The other 27 letters have `referenceStrokes: []` (empty), so this is also the moment to define how they get authored correctly — before the Phase-3 scorer and the S1-04 "watch me write" animation are built on top of bad data.

**Canonical question being answered:** *What is the correct representation and pipeline for teaching-stroke reference paths across all 28 letters, and exactly how do we fix the data and tooling — while keeping stroke order/direction/count in the owner's mother's hands, not guessed?*

### What the extractor actually produces (verified)

The script's `contour_count` = the number of **visually-disconnected filled regions** in the glyph, NOT the number of pen strokes. Confirmed by running against `candidate_paths.json` [VERIFIED: ran `python3` over the file]:

| Letter | `contour_count` | What the contours are | Pen strokes a child makes (candidate) |
|--------|-----------------|------------------------|----------------------------------------|
| alif (ا) | 1 | body outline loop | 1 |
| baa (ب) | 2 | body outline + dot outline | 2 (body, then dot) |
| taa (ت) | 3 | body outline + 2 dot outlines | 2 (body, then a 2-dot mark) |
| thaa (ث) | — | body + 3 dots (expected) | 2 (body, then a 3-dot mark) |
| seen (س) | 1 | **one** outline loop around all three teeth + tail | 1 |
| sheen (ش) | 4 | body outline + 3 dot outlines | 2 (body, then 3-dot mark) |
| jeem (ج) | 2 | body outline + dot outline | 2 (body, then dot) |
| saad/daad (ص/ض) | 1 / 3 | loop+tail outline (+dots for daad) | 1–2 |
| meem (م) | 1 | head-loop + tail, **one** outline | 1 |
| waaw (و) | 2 | head-loop outline + ... | 1 |
| haa_f (ه) | 3 | nested outlines (the loop has an inner hole) | 1 |
| qaaf (ق) | 4 | body + 2 dots + inner counter | 2 |

Two failure modes are visible here:
- **A single pen stroke yields a closed outline LOOP** (alif, seen, meem) — the perimeter is ~2–3× the pen path length and reverses direction at the turnaround.
- **`contour_count` ≠ stroke count**: dots come out as *separate* contours (useful — they are separable), but the letter *body* is always one outline regardless of how many real pen strokes form it (seen's three teeth are one contour); and counters/holes (haa, qaaf inner ring) inflate the count with non-stroke geometry.

The script does correctly separate **dots from body** (baa=2, taa=3, sheen=4) — which is the one genuinely reusable signal. It is the **body outline** that is wrong.

---

## 2. Why an Outline Contour Is Wrong (made undeniable)

Numerically verified for alif's live `referenceStrokes[0].points` (the 64-point contour, identical to `candidate_paths.json` alif contour_0) [VERIFIED: computed directly]:

| Property of alif's reference path | Value measured | What a correct top→bottom centerline would be |
|-----------------------------------|----------------|------------------------------------------------|
| First point → last point distance | **0.2234** (not ~0, but the path loops: down the left edge, across the bottom serif, up the right edge, back across the top) | ~1.0 apart vertically (start at top, end at bottom) |
| x-range spanned | **0.018 → 1.000** (the full serif width — both edges) | a thin band (a near-constant x) |
| y-range spanned | 0.0 → 1.0 | 0.0 → 1.0 (same — this is the only thing that coincidentally matches) |
| vertical-direction sign changes along the path | **1** (descends, then a turnaround at the bottom serif, then ascends) | ~0 (monotonic descent) |
| total path length (normalized perimeter) | **3.27** | ~1.0 (a single downstroke) |

So the reference path the scorer/animation would consume is **3.27× too long, reverses vertical direction once, and sweeps the full glyph width**. A child writing alif draws **one straight downward stroke of length ~1.0 with no reversal**.

### (a) Why it breaks the geometric scorer

The Phase-3 scorer's three authored checks assume a centerline (`03-RESEARCH.md` Pattern 5):
- `strokeLengthBelowThreshold` ("too short") — the reference "length" is the 3.27 perimeter, so *every* correct child stroke (~1.0) reads as <⅓ of reference → permanently "too short."
- `strokeDirectionInverted` ("wrong direction") — the reference has *both* a down phase and an up phase, so "is the child's net direction the same as the reference's?" is ill-defined; net travel of a loop is ~0.
- `strokeCurvatureExceedsThreshold` ("too curved") — the reference loop is maximally curved (it bends 360°), so a perfectly straight child stroke looks *less* curved than the reference, inverting the test.

Any path-similarity metric (DTW / discrete Fréchet / Procrustes / mean-nearest-point) between the child's single open down-stroke and the closed 64-point loop is geometrically meaningless: the cardinalities, endpoints, and topology don't correspond. This is exactly Pitfalls P1/P3/P4 made concrete. [VERIFIED: numeric analysis above + `03-RESEARCH.md` Pitfall 1]

### (b) Why it breaks the "watch me write" animation (S1-04)

S1-04 requires the **same** reference path to drive both scoring and the pen-tip animation (one source of truth, D-11). Feeding the outline into `Path.computeMetrics()` → `PathMetric.extractPath` animates a pen tip that traces *around* the alif — down the left side, across the bottom, up the right side, and back across the top — instead of demonstrating the single top-to-bottom downstroke a child must learn. The demo would teach the wrong motor pattern. [CITED: api.flutter.dev `PathMetric`; `03-RESEARCH.md` Pattern 2 note]

### What "correct" looks like

A teaching-stroke reference is an **ordered, directed, OPEN centerline polyline per pen stroke** — the path the pen *tip* travels, in the sequence the strokes are made, each running from its true start to its true end. For alif: one open polyline from `[~0.5, 0.0]` (top) to `[~0.5, 1.0]` (bottom), length ~1.0, monotonic, straight. For baa: stroke 1 = the bowl centerline (right→left curve), stroke 2 = the dot (a point/tap below). Dots are their own ordered strokes drawn after the body (verified Arabic convention: body first, dots after — see §4). [CITED: Arabic handwriting stroke-order guides; KanjiVG's directed per-stroke SVG model as the proven design]

---

## 3. Method Survey — How to Obtain Correct Centerlines for 28 Letters

> Installed tooling check [VERIFIED: ran on this machine]: Python 3.11; `numpy` 2.4.0 and `Pillow` 12.2.0 present; **`fonttools`, `scikit-image`, `opencv` NOT installed**. Flutter 3.41.9 stable.

### (a) Skeletonization / medial-axis transform of the rasterized glyph

Rasterize each glyph to a bitmap, then thin it to a 1-px skeleton (`skimage.morphology.skeletonize` / `medial_axis`, or OpenCV thinning, or potrace→centerline). [CITED: scikit-image skeletonize/medial_axis docs]

| Aspect | Assessment |
|--------|------------|
| Produces a centerline? | Yes — a 1-px-wide topological skeleton with the same connectivity as the shape. [CITED: skimage medial_axis docs] |
| **Recovers stroke ORDER?** | **NO.** A skeleton is an unordered pixel set / undirected graph. It has no notion of which stroke is drawn first or in which direction. This is the disqualifying gap for a *teaching* app. [VERIFIED: definitional — medial axis is "the set of points with >1 closest boundary point," order-free] |
| Recovers stroke DIRECTION? | NO (same reason). |
| Junctions (seen/sheen teeth, kaaf, ayn) | Produces spurious branches and Y/T junctions that need graph pruning; the three teeth of seen become one branchy skeleton, not three directed strokes. MEDIUM-HIGH risk. |
| Loops (waaw, meem, ha, the qaaf/ha counters) | A closed loop skeletonizes to a *ring* (a cycle), which must be cut at the pen start point — and the cut location is a pedagogical choice the algorithm cannot make. |
| **Dots (i'jam)** | A dot rasterizes to a small blob whose skeleton is a single point or a tiny cross — usable as a centroid, but the body-vs-dot separation is better obtained from the **font contour count** (which already works) than from skeletonizing the merged raster. |
| Tech risk | MEDIUM-HIGH. New deps (scikit-image + numpy + Pillow + a rasterizer). Heavy per-letter tuning (pruning thresholds, ring-cutting). |
| Pedagogical fidelity | LOW — even a perfect skeleton is silent on order/direction, which is the entire pedagogy the owner's mother owns. |

**Verdict:** Skeletonization can produce a *shape* centerline but **fundamentally cannot recover stroke order or direction**, which are the pedagogically load-bearing properties. At best it is a drawing aid *under* a human who imposes order. Not a standalone solution. [VERIFIED: medial-axis definition is order-free; CITED: skimage docs]

### (b) Existing stroke-order datasets / "skeleton" Arabic fonts (a KanjiVG analogue?)

KanjiVG is the gold standard for CJK: every character is an SVG where **each stroke is a directed `<path>` in draw order** on a 109×109 box. [CITED: kanjivg.tagaini.net] The question is whether an Arabic analogue exists.

| Resource | What it is | Usable for per-letter teaching centerlines? |
|----------|-----------|----------------------------------------------|
| **KanjiVG** | Ordered, directed per-stroke SVG paths (CJK only) | No (wrong script) — but it is the **design template** we should copy: directed per-stroke paths in draw order. [CITED] |
| **Calliar** (arXiv 2106.10745) | Online (stroke-ordered) Arabic *calligraphy*: 2,500 sentences, 40k strokes, QuickDraw-like (x,y) JSON | **No** — full artistic sentences (Diwani/Thuluth styles), not standardized isolated letters; prioritizes artistic variation over pedagogy. [VERIFIED: paper abstract via WebFetch] |
| **Online-KHATT, AHCD** | Online/offline Arabic *recognition* datasets | No — built for recognition, no canonical teaching stroke order, licensing/style mismatch. [CITED: search results] |
| Arabic stroke-order worksheets (Kalimah, Sakkal, Busuu) | Human-authored directional arrows per letter | Reference material for the owner's mother to confirm against — **not** machine-ingestible coordinate data. [CITED] |

**Verdict:** **No Arabic KanjiVG exists.** [VERIFIED: web search returned none] No off-the-shelf dataset gives standardized, ordered, isolated-letter teaching centerlines with a usable license. Do not block on finding one. (Adopt KanjiVG's *data model*, not its data.)

### (c) Hand-authoring by the owner — trace each letter (RECOMMENDED PRIMARY)

The owner (with his mother present, or from her marked-up worksheet) traces each letter's strokes — in her prescribed order and direction — and we capture ordered normalized point lists. Lowest tech risk, highest pedagogical fidelity, and it directly satisfies CLAUDE.md's binding rule: *"Curriculum is the owner's mother's domain… do not invent the pedagogy; structure it."* The font outline becomes a **backdrop the owner traces over**, not the source of the stroke.

| Aspect | Assessment |
|--------|------------|
| Stroke order/direction | Authored by the human in the correct order/direction — **the pedagogy is the input, not a guess.** Perfect fidelity. |
| Tech risk | LOW. Two viable capture surfaces (see below); reuses code already in the repo. |
| Junctions/loops/dots | A non-issue — the human draws each stroke as a separate pen-down→pen-up; dots are taps; loops are drawn open from their true start. |
| Scaling to 28 (then more) | One short authoring session per letter; ~28 letters is an afternoon. Re-usable for the medial/initial/final forms later. |
| Cost | A small in-repo authoring tool/screen (one-time). |

Two sub-options for the capture surface:
- **(c1) In-app authoring screen (RECOMMENDED).** A tiny dev-only Flutter route that renders the Noto Naskh glyph faintly as a backdrop and lets the owner trace each stroke with finger/stylus, tags it (order, label, dot-vs-line), and exports the normalized point list as JSON ready to paste into `letters.json`. **This reuses the exact Phase-1 `Listener` capture + `CustomPainter` ink that already exists** (`lib/screens/practice_screen.dart`), so the captured data is in *precisely the same coordinate space and format the scorer will consume* — guaranteeing animation-path == scoring-path == authored-path. The owner's test hardware is finger-only (D-13/D-14) and this works with a finger.
- **(c2) Offline tablet capture** — owner draws on any tablet drawing app and we import — rejected: format/normalization mismatch, more glue code than (c1).

**Verdict:** **PRIMARY recommendation — (c1) in-app authoring screen.** It is the lowest-risk path that puts the pedagogy in the right hands and produces data in the right format by construction.

### (d) Manual vector authoring (SVG centerlines over each glyph) — RECOMMENDED FALLBACK

The owner or a designer draws an SVG `<path>` centerline per stroke over each glyph in a vector editor (Figma/Illustrator/Inkscape), one path per pen stroke in draw order; a small Python script ingests the SVG `<path>` d-attributes, samples them to normalized point lists, and emits `letters.json` fragments.

| Aspect | Assessment |
|--------|------------|
| Order/direction | Encoded by path order in the SVG + the path's own start→end direction. Faithful if the author follows mom's order. |
| Tech risk | LOW-MEDIUM. `svg.path`/`svgpathtools` (Python) parse `<path>` cleanly; one ingestion script. |
| Precision | Higher than freehand tracing (Bezier control) — good for the smooth curves of waaw/meem/ha. |
| Downside | Requires a vector tool + the author thinking in paths; data lands in a *different* pipeline than the runtime capture format (needs a normalization/validation pass to match (c1)'s coordinate space). |

**Verdict:** **FALLBACK** — best if the owner prefers precise curves over freehand, or for the looped letters (waaw/meem/ha) where a freehand trace is wobbly. Both (c) and (d) put a human in charge of order/direction; that is the non-negotiable property.

### Comparison summary

| Method | Order/Direction | Pedagogical fidelity | Tech risk | New deps | Format matches runtime? | Recommendation |
|--------|-----------------|----------------------|-----------|----------|--------------------------|----------------|
| (a) Skeletonization | **Cannot recover** | LOW | MED-HIGH | scikit-image, numpy, Pillow, rasterizer | needs conversion | Reject as primary; optional backdrop aid only |
| (b) Existing dataset/font | varies | n/a (none exist) | — | — | — | **None usable** — adopt KanjiVG's *model* |
| **(c1) In-app authoring trace** | Human-authored | **HIGHEST** | **LOW** | none (reuses P1 capture) | **Yes, by construction** | **PRIMARY** |
| (d) SVG vector authoring | Human-authored | HIGH | LOW-MED | `svgpathtools` (Python tooling only) | needs normalization pass | **FALLBACK** |

---

## 4. Arabic-Script Structural Reality → Per-Letter CANDIDATE Stroke Breakdown

> **THIS TABLE IS A CANDIDATE FOR THE OWNER'S MOTHER TO CONFIRM — NOT AUTHORITATIVE PEDAGOGY.** It is a *starting point* to make the authoring session efficient (so she confirms/corrects rather than starts blank). Stroke order, direction, count, and dot timing are HER domain (CLAUDE.md, binding). Confidence on the *structure* (how many body strokes, dots vs body) is MEDIUM (corroborated by multiple stroke-order guides); confidence on *exact order/direction* is LOW until she signs off.

**Verified general conventions** [CITED: Busuu, Sakkal, Kalimah, Quranytime stroke-order guides; corroborated across sources]:
- **Body first, dots after.** Letters with dots (ب ت ث ن ي ج خ ذ ز ض ظ غ ف ق ش) draw the main body as one motion, then add the dot(s). Each dot is a separate pen-down (a tap or tiny mark).
- **Pen lifts between strokes** — each stroke is a clean pen-down→pen-up (matches our per-stroke capture model, D-04).
- **Alif** is a single straight vertical stroke, top→bottom, no dots. [CITED — and matches D-08/Phase-3]
- Dots above vs below and dot-count are **letter-identity-critical** (baa=1 below, taa=2 above, thaa=3 above) — the scorer must treat dot position/count as pedagogically firm (`03-RESEARCH.md` P1/P4: keep count/order firm).

**Candidate breakdown for the 28 isolated forms** (body strokes + dot strokes). "Dots" = one logical mark the child makes after the body; the owner's mother decides whether a 2- or 3-dot mark is one stroke or several.

| # | Letter | Char | Candidate body strokes | Dots (after body) | Notes / what to confirm with mom |
|---|--------|------|------------------------|--------------------|-----------------------------------|
| 1 | alif | ا | 1 (straight, top→bottom) | 0 | Signed-off today but with WRONG data — must re-author + re-sign (§6). |
| 2 | baa | ب | 1 (bowl, right→left) | 1 below | dot below = identity. |
| 3 | taa | ت | 1 (bowl) | 2 above | 2 dots above. |
| 4 | thaa | ث | 1 (bowl) | 3 above | 3 dots above. |
| 5 | jeem | ج | 1 (head+curve) | 1 below (inside) | curve shape; dot inside the belly. |
| 6 | haa_c | ح | 1 (head+curve) | 0 | no dots. |
| 7 | khaa | خ | 1 (head+curve) | 1 above | dot above. |
| 8 | daal | د | 1 | 0 | non-connecting. |
| 9 | dhaal | ذ | 1 | 1 above | dot above. |
| 10 | raa | ر | 1 (downward curve) | 0 | sits below baseline. |
| 11 | zaay | ز | 1 (downward curve) | 1 above | dot above. |
| 12 | seen | س | 1 (three teeth + tail, one motion?) | 0 | **Confirm: one continuous stroke or teeth separately?** Outline is 1 contour but pen motion is mom's call. |
| 13 | sheen | ش | 1 (three teeth + tail) | 3 above | teeth like seen + 3 dots. |
| 14 | saad | ص | 1 (loop + tail) | 0 | open the loop at its true start. |
| 15 | daad | ض | 1 (loop + tail) | 1 above | dot above. |
| 16 | taa_h | ط | 1 (loop+body) + 1 vertical? | 0 | **Confirm: is the upright a separate stroke?** |
| 17 | zhaa | ظ | 1 (loop+body) + upright? | 1 above | as taa_h + dot. |
| 18 | ayn | ع | 1 (open curve) | 0 | distinctive open top. |
| 19 | ghayn | غ | 1 (open curve) | 1 above | dot above. |
| 20 | faa | ف | 1 (head loop + tail) | 1 above | head loop opened at start. |
| 21 | qaaf | ق | 1 (head loop + tail) | 2 above | inner counter is NOT a stroke (font artifact). |
| 22 | kaaf | ك | 1 (body) + 1 (inner hamza/stroke)? | 0 | **Confirm: the inner mark — separate stroke?** |
| 23 | laam | ل | 1 (tall vertical + curve) | 0 | like alif with a hook. |
| 24 | meem | م | 1 (head loop + tail) | 0 | loop opened at start; tail down. |
| 25 | noon | ن | 1 (bowl) | 1 above | bowl deeper than baa. |
| 26 | haa_f | ه | 1 (loop) | 0 | inner hole is a font counter, NOT a stroke. |
| 27 | waaw | و | 1 (head loop + tail) | 0 | loop opened at start. |
| 28 | yaa | ي | 1 (bowl + tail) | 2 below | 2 dots below. |

**Key structural takeaways for the data model and scorer:**
- Most isolated letters are **1 body stroke + 0–3 dots.** A few (taa_h/zhaa, kaaf) *may* be multi-body-stroke — flagged for mom.
- **Dots are separate, order-after-body strokes** and are pedagogically firm (position + count = identity).
- **Counters/holes** (ha, qaaf inner ring) are font artifacts, NOT pen strokes — the outline extractor's extra contours for these must be discarded.
- The font-contour **dot separation already works** (baa=2, taa=3, sheen=4 contours) — reuse it as a hint for "how many dot marks," even though the body outline itself is discarded.

---

## 5. Data Model Assessment

Current model (`lib/models/letter.dart`):
```dart
class StrokeSpec {
  final int order;
  final String label;
  final List<List<double>> points; // normalized 0..1
  final String direction;          // e.g. "topToBottom"
}
```

### Does it suffice? Mostly yes — minimal additions recommended.

| Question | Finding | Recommendation |
|----------|---------|----------------|
| Is `points` (normalized 0..1) the right shape? | Yes — both the scorer and the `CustomPainter` consume normalized points and scale at render time (Phase-2 D-02, `03-RESEARCH.md`). Keep it. | **Keep** `points` as `List<List<double>>` normalized 0..1. |
| Should there be an explicit stroke `type`? | Yes — the scorer and animation treat a **dot/tap** very differently from a **line/curve** (a dot is ~1 point; a line has length/direction/curvature checks). Inferring "is this a dot?" from `points.length` is fragile magic. | **ADD** `type: "line" \| "curve" \| "dot"` (String enum). Low-magic, owner-readable in JSON. |
| Is `direction` (a separate string) redundant with point order? | **Largely yes** — for an *open* centerline, direction is fully determined by `points.first → points.last`. The separate string risks contradicting the points (exactly today's bug: `topToBottom` label on a loop). | **KEEP `direction` as a human-readable, validated hint**, but make it **derived-and-checked**: a validation step asserts the string agrees with the actual point order (e.g. `topToBottom` ⇒ `points.last.y > points.first.y`). Treat the *points* as the source of truth; `direction` is documentation the validator enforces. (Renaming/removing it touches the signed-off schema — keep it, validate it.) |
| Dots as zero-length / tap strokes? | A dot's `points` can be a single `[x,y]` (its centroid) with `type: "dot"`. The scorer checks dot *presence + position + count*, not a path. | **Use** `type: "dot"`, `points: [[x,y]]` (one point), `direction: "tap"`. |
| Per-letter vs shared normalization box? | Phase-2 normalizes to a **per-letter** 0..1 bounding box (D-02). The child's captured stroke is normalized the same way before scoring. Per-letter is correct (size/position invariance per `03-RESEARCH.md` P3). | **Keep per-letter** 0..1 box. Document it. For multi-stroke letters, normalize **all strokes together** against the letter's overall bbox so relative stroke positions (e.g. dot-below-body) are preserved. |
| Open vs closed enforcement? | Today's data is a *closed* loop; correct data is *open*. Nothing in the model or load path forbids a closed loop. | **ADD a load/validation guard:** reject (or warn loudly on) any non-dot stroke whose `points.first ≈ points.last` (closed loop) — see §7. Could be a `closed: false` invariant rather than a field. |

### Recommended minimal model change (keep the magic low — owner is new to Dart)

```dart
class StrokeSpec {
  final int order;                 // unchanged — draw sequence
  final String label;              // unchanged — human label ("bowl", "dot")
  final String type;               // NEW: "line" | "curve" | "dot"
  final List<List<double>> points; // unchanged — normalized 0..1; dot = single point
  final String direction;          // unchanged — but now VALIDATED against point order
                                   //   ("topToBottom"|"bottomToTop"|"rightToLeft"
                                   //    |"leftToRight"|"tap")
}
```
One new field (`type`), default-safe (`json['type'] as String? ?? 'line'` so existing data still parses), plus a validation rule on load. No structural rewrite. This keeps `letters.json` legible to the owner and his mother and is a tiny, explainable Dart change.

---

## 6. Scoring + Animation Alignment

A correct **open centerline** makes the Phase-3 scorer's three named checks valid and consistent (`03-RESEARCH.md` Pattern 5, Claude's-discretion mapping):

| Named check (`commonMistakes[].check`) | With a correct alif centerline (open, length≈1.0, monotonic, straight) |
|----------------------------------------|--------------------------------------------------------------------------|
| `strokeLengthBelowThreshold` ("too short") | Reference length ≈ child's expected ≈ 1.0 (after normalization). A genuinely short stroke (e.g. 0.5) now correctly trips the check. Was previously always-true vs the 3.27 perimeter. |
| `strokeDirectionInverted` ("wrong direction") | Reference net travel is unambiguously top→bottom (`points.first.y < points.last.y`). `sign(child.end.y − child.start.y)` vs the reference sign is well-defined. Was previously undefined (loop nets ~0). |
| `strokeCurvatureExceedsThreshold` ("too curved") | Reference is straight (max perpendicular deviation ≈ 0); child curvature is measured against ~0. Was previously inverted (loop is maximally curved). |

**One source of truth (S1-04, D-11):** Resolve the reference path **once** (`ReferencePath.resolve(letter.referenceStrokes)` in `lib/core/scoring/reference_path.dart`, per `03-RESEARCH.md` structure) and feed the *same* resolved path object to:
1. the dotted guide `CustomPainter`,
2. the `PathMetric`-driven pen-tip animation, and
3. the geometric scorer's reference.

With a correct authored centerline, **resolve becomes the identity function** (it just returns the authored points) — no derive-from-outline step needed. That is the cleanest possible realization of S1-04: the authored path *is* the animated path *is* the scored path. This **supersedes** `03-RESEARCH.md`'s Q1 option 1 (derive-centerline-from-outline): authoring the centerline directly (this doc's recommendation) removes the need for any runtime derivation and removes the outline from the pipeline entirely.

Resample/normalize approach is unchanged from `03-RESEARCH.md` (resample child + reference to N equidistant points, normalize to unit box, then compare) — it just finally has a *correct* reference to compare against.

---

## 7. The Fix — Concrete & Staged

### 7.0 Where this work belongs (Phase-2 amendment vs Phase 3) — DECISION FOR THE OWNER

This is fundamentally a **Phase-2 data + tooling defect** (the extraction produced the wrong representation; the schema/sign-off let it through). But Phase 3 is blocked by it *right now*. Three options:

- **Option A (RECOMMENDED): Small Phase-2 amendment / "Phase 2.5" sub-phase** that (1) re-tools extraction-or-authoring, (2) re-authors alif correctly with owner re-sign-off, (3) adds the validation guard. Phase 3 then proceeds on correct data with no scope creep into the deepest-risk phase. Keeps the "pedagogy is data, signed off per-letter" boundary clean.
- **Option B: Fold the alif fix into Phase 3** (just fix the one letter alif needs, defer the other 27's authoring + tooling to Phase 7's sign-off gate). Smallest immediate footprint, but mixes a data/tooling fix into the scorer phase and re-opens signed-off data mid-phase.
- **Option C: Full re-author of all 28 now.** Highest upfront cost; not needed for the alif MVP (the 27 are `signedOff:false` placeholders anyway, gated at Phase 7).

**Recommendation:** **Option A** — a focused amendment that fixes the *tooling + alif + validation* now (unblocking Phase 3 correctly), and leaves the other 27's full authoring to Phase 7's existing sign-off gate (Phase-2 D-12, D-07). This respects the existing per-letter `signedOff` gate and keeps Phase 3 about the loop.

### 7.1 What to do with `tools/extract_reference_paths.py`

**Repurpose, don't trust for bodies.** The script's value is (a) dot-vs-body **separation** (works) and (b) producing a faint **backdrop** to trace over. It must **not** emit body outlines as `referenceStrokes`.

Two concrete paths (pick per §3 primary/fallback):
- **If PRIMARY (c1 in-app authoring):** Keep the script only as an optional helper that emits dot **centroids** (from the dot contours) and the glyph bbox, as authoring hints. The body stroke comes from the owner's in-app trace. Rename its output to `tools/authoring_hints.json` to stop anyone pasting outlines into curriculum again. Add a header comment: *"Outlines are NOT teaching strokes — see .planning/research/STROKE-REFERENCE.md."*
- **If FALLBACK (d SVG authoring):** Replace the contour-extraction core with an SVG `<path>` ingester (`svgpathtools`) that samples authored centerline paths to normalized point lists. Keep the dot-separation logic.

Either way: **deprecate the current "outline → referenceStrokes" behavior** with a loud comment, and never let an outline reach `letters.json` again (the validation guard in §7.4 enforces this).

### 7.2 The candidate → owner-review → `signedOff: true` workflow

The per-letter gate already exists (`signedOff: bool`, Phase-2 D-11/D-12). The corrected workflow:

1. **Generate candidate** — owner traces the letter in the in-app authoring screen (PRIMARY) or draws SVG centerlines (FALLBACK), in mom's prescribed order/direction, tagging each stroke's `order`, `label`, `type`.
2. **Export** normalized `referenceStrokes` JSON fragment.
3. **Validate** automatically (§7.4) — open-not-closed, direction-matches-points, dot=single-point, stroke count sane.
4. **Visual QA overlay** (§7.5) — render the authored strokes as an animated/overlaid pen path on the faint glyph; owner + mom watch the pen draw it and confirm it matches how she teaches it.
5. **Sign off** — set `signedOff: true` only after that visual confirmation.

This makes the *trace + visual confirmation* the sign-off artifact (the natural successor to Phase-2 D-03's "mapping IS the sign-off contribution," now that mapping-from-outline is dead).

### 7.3 Fix alif correctly NOW (the proven exemplar) — REQUIRES OWNER RE-SIGN-OFF

⚠️ **alif is `signedOff: true` today with wrong data.** Fixing it **re-opens signed-off curriculum** — a Phase-2 sign-off boundary. This must be an explicit owner action, not a silent dev edit (CLAUDE.md: pedagogy is mom's domain; D-11 sign-off semantics).

Correct alif `referenceStrokes` (an open, straight, top→bottom centerline; the owner confirms exact start x with mom — alif is essentially vertical with a slight Naskh lean):
```jsonc
"referenceStrokes": [
  {
    "order": 1,
    "label": "vertical_stroke",
    "type": "line",
    "points": [[0.5, 0.0], [0.5, 0.25], [0.5, 0.5], [0.5, 0.75], [0.5, 1.0]],
    "direction": "topToBottom"
  }
]
```
(A handful of points is enough for a straight line; the scorer resamples anyway.) This replaces the 64-point loop. The three `commonMistakes` then become valid as-is (§6). After the owner confirms via the visual overlay (§7.5), re-set `signedOff: true`.

### 7.4 Validation / QA — automated guard (runs in tests + at authoring time)

A pure-Dart validator (and/or a Python check in the authoring tool) that asserts, per `StrokeSpec`:
- **Not a closed loop** (for `type != "dot"`): `distance(points.first, points.last)` > a small epsilon, AND total path length is not ~2–3× the bbox diagonal (catches an outline that sneaks back in). [This single check would have caught today's bug.]
- **Direction agrees with points:** the `direction` string matches the actual `points.first → points.last` ordering.
- **Dot sanity:** `type == "dot"` ⇒ exactly one point.
- **Order sanity:** `order` values are 1..N contiguous; dots come after body strokes.
- **In-range:** all coordinates in [0, 1].

### 7.5 Visual QA overlay (golden) — owner-facing confirmation

Render each letter's authored `referenceStrokes` as a **pen path overlaid on the faint Noto Naskh glyph**, with the pen-tip animating in draw order (reuse the Phase-3 `PathMetric` animation, `03-RESEARCH.md` Pattern 2). The owner + mom watch it draw the letter the way she teaches it. Capture as a **golden image test** per letter so regressions (e.g. an outline creeping back in, a reversed stroke) fail CI. This is the human-in-the-loop gate that no automated metric can replace, and it doubles as a regression guard.

---

## 8. Validation Architecture

> `workflow.nyquist_validation` assumed enabled (not explicitly false). Tests are pure-Dart where possible (the `core/scoring` crown jewel) plus goldens for the visual overlay.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + golden tests; `test/flutter_test_config.dart` loads bundled Arabic TTFs (P1 pattern — required so Arabic goldens don't render tofu) |
| Quick run | `flutter test test/core/scoring/reference_path_test.dart test/curriculum/stroke_spec_validation_test.dart` |
| Full suite | `flutter test` |
| Authoring-tool check | Python validator in the extraction/authoring tool (if SVG-fallback) + the Dart load-time guard |

### Requirements → Test Map
| Behavior | Test type | Command | Exists? |
|----------|-----------|---------|---------|
| A `referenceStrokes` stroke is an **open** centerline, never a closed loop (catches the original bug) | unit | `flutter test test/curriculum/stroke_spec_validation_test.dart` | ❌ Wave 0 |
| `direction` string agrees with `points.first→last` order | unit | same | ❌ Wave 0 |
| `type == "dot"` ⇒ single point; dots ordered after body | unit | same | ❌ Wave 0 |
| All coords in [0,1]; `order` 1..N contiguous | unit | same | ❌ Wave 0 |
| **Animation path == scoring path == authored path** (one source of truth, S1-04) | unit | `flutter test test/core/scoring/reference_path_test.dart` | ❌ Wave 0 |
| alif's corrected stroke: length≈1.0, monotonic-y, straight (perp-deviation≈0) | unit | `test/curriculum/alif_reference_test.dart` | ❌ Wave 0 |
| Each authored letter renders a sensible pen path over its glyph (owner-confirmable) | golden | `test/curriculum/reference_overlay_golden_test.dart` (loads TTFs) | ❌ Wave 0 |
| `StrokeSpec.fromJson` parses new `type` field with safe default | unit | `test/models/letter_test.dart` (extend P2 tests) | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/curriculum/stroke_spec_validation_test.dart` — the open-not-closed + direction + dot + range guard (this is the single most valuable test — it makes the original bug impossible to reintroduce).
- [ ] `test/core/scoring/reference_path_test.dart` — path identity across animation/scorer.
- [ ] `test/curriculum/alif_reference_test.dart` — alif centerline properties.
- [ ] `test/curriculum/reference_overlay_golden_test.dart` — per-letter visual overlay golden (owner QA artifact).
- [ ] Extend `test/models/letter_test.dart` for the `type` field default.
- [ ] No new test framework needed (flutter_test present).

### Sampling Rate
- **Per task commit:** `flutter test test/curriculum/ test/core/scoring/` (fast, pure-Dart + small goldens).
- **Per wave merge / phase gate:** `flutter test` (full suite incl. overlay goldens) green + owner visual confirmation of the overlay before re-setting `signedOff: true`.

---

## 9. Open Questions for the Owner (and his mother)

1. **Phasing (blocking, §7.0):** Fix as a focused Phase-2 amendment / "Phase 2.5" (Option A, recommended), fold the alif-only fix into Phase 3 (Option B), or re-author all 28 now (Option C)?
2. **Authoring method (§3):** In-app trace screen (c1, recommended) or SVG vector authoring (d, fallback)? (Owner's hardware is finger-only — c1 works with a finger.)
3. **alif re-sign-off (§7.3):** Confirm the corrected open top→bottom centerline with mom, then re-set `signedOff: true`. Confirm the slight Naskh lean / exact start-x she wants. **This re-opens signed-off data — explicit owner action required.**
4. **Per-letter pen motion (§4, mom's domain):** For seen/sheen — three teeth as one continuous stroke or separate? For taa_h/zhaa and kaaf — is the upright / inner mark a separate stroke? Dot marks (taa=2, thaa=3, etc.) — one stroke per mark or one combined mark?
5. **Data model (§5):** OK to add the single `type` field ("line"/"curve"/"dot") and the load-time validation guard, keeping everything else as-is?
6. **Backdrop source:** Trace over the Noto Naskh glyph (consistent with the rendered guide), or over mom's own worksheet arrows? (Recommend Noto Naskh so the traced path aligns with what the child later sees.)

---

## 10. Sources

### Primary (HIGH confidence)
- `assets/curriculum/letters.json` — alif's 64-point closed-outline `referenceStrokes`, the 27 empty arrays, `signedOff:true` on alif — inspected directly.
- `tools/extract_reference_paths.py` + `tools/candidate_paths.json` — outline-extraction logic and per-letter `contour_count` (alif=1, baa=2, taa=3, sheen=4, seen=1, meem=1, …) — read + executed directly.
- **Numeric proof** that alif's path is a closed loop (perimeter 3.27 vs ~1.0; 1 vertical sign-change; x-range 0.018→1.0) — computed this session [VERIFIED].
- `.planning/phases/03-trace-one-letter-end-to-end/03-RESEARCH.md` — THE FINDING, scorer survey, Pattern 2/5, Pitfalls — built upon, not duplicated.
- `.planning/phases/02-…/02-CONTEXT.md`, `02-DISCUSSION-LOG.md` — original D-01..D-12 extraction + owner-mapping + per-letter sign-off intent (note D-02 *intended* "discrete contour components, e.g. baa = bowl + dot" — the script over-delivered outlines).
- `.planning/research/ARCHITECTURE.md`, `PITFALLS.md` — scoring pipeline, "one source of truth," P1/P3/P4/P6 (don't invent pedagogy), `core/scoring` structure.
- `CLAUDE.md` — binding: curriculum is the owner's mother's domain; Riverpod-only; Python tooling; brand rules.
- `lib/models/letter.dart`, `lib/data/curriculum_repository.dart` — current `StrokeSpec` model + loader — read directly.
- Installed-tooling probe (Python 3.11; numpy/Pillow present; fonttools/scikit-image/opencv absent; Flutter 3.41.9) [VERIFIED: ran on this machine].

### Secondary (MEDIUM confidence)
- [KanjiVG](https://kanjivg.tagaini.net/) — ordered, directed per-stroke SVG paths; the design model to copy. [CITED]
- [scikit-image skeletonize / medial_axis docs](https://scikit-image.org/docs/stable/auto_examples/edges/plot_skeleton.html) — skeleton is an order-free 1-px topological set. [CITED]
- [Calliar (arXiv 2106.10745)](https://ar5iv.labs.arxiv.org/html/2106.10745) — online Arabic *calligraphy*, not isolated-letter pedagogy; unsuitable as a source [VERIFIED via WebFetch].
- Arabic stroke-order guides: [Busuu](https://www.busuu.com/en/arabic/alphabet), [Sakkal](https://www.sakkal.com/articles/sakkal_arabic_alphabet.pdf), [Kalimah tracing worksheets](https://kalimah-center.com/arabic-alphabet-handwriting-and-tracing/), [Quranytime](https://quranytime.com/arabic-alphabets/) — body-first/dots-after, alif single straight stroke, dot count/position = identity. [CITED]

### Tertiary (LOW confidence)
- The per-letter stroke breakdown in §4 — structure corroborated across guides (MEDIUM on counts), but **exact order/direction/dot-timing is a CANDIDATE for the owner's mother**, not verified pedagogy [ASSUMED until she signs off].
- No Arabic KanjiVG-analogue dataset found [VERIFIED-negative via web search: none with usable license/standardized isolated letters].

---

## Metadata

**Confidence breakdown:**
- Failure diagnosis (outline ≠ centerline): HIGH — numerically verified against the live data.
- Method recommendation (human authoring): HIGH — the only approach that recovers order/direction, and it's mandated by the "pedagogy is mom's" rule.
- Skeletonization assessment: HIGH on the order-recovery limitation (definitional); MEDIUM on raster-fidelity details.
- Per-letter stroke breakdown: MEDIUM on structure / LOW on exact order — explicitly a candidate for mom.
- Data-model change: HIGH — minimal, additive, validated.

**Research date:** 2026-06-01
**Valid until:** ~2026-09-01 (stable — the only volatile items are the owner/mom decisions, which gate the work regardless of date).
