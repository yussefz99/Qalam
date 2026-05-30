# Pitfalls Research

**Domain:** Handwriting-first Arabic-literacy tablet app for heritage-learner children (ages 5–10) — Flutter/Android, RTL, on-device ML Kit Digital Ink, anti-gamification, local-only v1
**Researched:** 2026-05-30
**Confidence:** HIGH on ML Kit capability limits and Flutter RTL behavior (official docs + package source verified); MEDIUM on stylus latency specifics and child-scoring tuning (Android docs verified, but exact thresholds are device- and curriculum-dependent and must be measured); MEDIUM on pedagogy/UX (synthesized from competitor apps + PROJECT.md constraints).

> **The single most important finding, read this first.** ML Kit Digital Ink is a **text recognizer**, not a stroke-order/pedagogy engine. The Flutter package `google_mlkit_digital_ink_recognition` returns only `List<RecognitionCandidate>`, where each candidate has `text` and a `score` (confidence) — **there is no per-stroke output, no stroke-order validation, and no shape-deviation data.** (Verified against the pub.dev package docs and ML Kit official docs.) Every pedagogical judgement the app makes — "you drew the baa's curve too shallow", "you started from the wrong end", "stroke 2 is missing" — must come from a **separate, home-grown geometric stroke-comparison layer**, not from ML Kit. ML Kit at best answers "does this blob of ink look like the letter baa at all?" This reframes R1: ML Kit is validated as a *coarse letter-identity check*, but it does **not** deliver the stroke-order pedagogy the curriculum (the owner's mother's spec) requires. **This does not contradict the Decided ML Kit choice — but it strongly qualifies what ML Kit is for. Flag this to the owner before any scoring code is written.**

---

## Critical Pitfalls

### Pitfall 1: Over-trusting ML Kit as the scoring engine (using a text recognizer for stroke-order pedagogy)

**What goes wrong:**
The team wires ML Kit's `RecognitionCandidate.score` straight into "pass/fail this letter." But ML Kit's score is a *text-recognition confidence* over a finished ink blob — it is high if the final shape resembles the letter, regardless of stroke order, direction, or number of strokes. A child can draw a baa bottom-to-top, in one scribble, in the wrong direction, and ML Kit may still confidently return "ب". Conversely a perfectly-formed letter with one wobble may score low. The curriculum's core teaching units — **stroke order, stroke count, common per-letter mistakes** — are exactly the things ML Kit cannot see.

**Why it happens:**
The R1 "validated by our own testing" note almost certainly validated *letter identification* ("ML Kit recognizes Arabic letters drawn on the tablet"), which is real and works. The leap to "therefore ML Kit scores handwriting for our pedagogy" is the trap. The package's clean `recognize(ink) → candidates` API hides the fact that all stroke structure is discarded.

**How to avoid:**
- Architect two distinct layers from day one: (a) a **geometric stroke-comparison scorer** owned by us — compares captured strokes to the curriculum's reference path per letter (order, direction, count, shape proximity), and (b) ML Kit as an optional **coarse identity sanity check** ("is this even the right letter?"). The pedagogy lives in (a).
- The reference strokes, the tolerance per letter, and the named common mistakes come from the **owner's mother's spec** — model the schema to hold an ordered list of reference strokes per letter plus the 3–4 common-mistake signatures.
- Treat ML Kit's `score` as one weak signal among several, never the gate.

**Warning signs:**
A scoring function whose only input is `candidates.first.score`. A child passing a letter they drew backwards. A "scoring" ticket that has no reference-path data structure behind it.

**Phase to address:** The handwriting-capture-and-scoring phase, at design time — before any scoring code. Re-confirm R1's actual scope with the owner first.

---

### Pitfall 2: Capturing strokes from a high-level GestureDetector (losing stroke structure, pressure, and order)

**What goes wrong:**
Stroke capture is built on `GestureDetector` / `onPanUpdate`. This coalesces and smooths input, drops the stylus-vs-finger distinction, gives no pressure/tilt, and — critically — provides no clean per-stroke segmentation (pen-down → pen-up). Stroke *order and count*, the heart of the pedagogy, become guesswork, and palm touches get merged into the drawing.

**Why it happens:**
`GestureDetector` is the first thing a Flutter beginner reaches for, and the owner is new to Dart/Flutter. It looks like it "works" for drawing in a demo.

**How to avoid:**
- Use the low-level `Listener` widget with `onPointerDown/Move/Up` and read `PointerEvent.kind` (filter to `PointerDeviceKind.stylus`), `pressure`, `tilt`, and `pointer` id. Each down→up sequence is one stroke; store strokes as an ordered list of `(x, y, t, pressure)` points — which is exactly the shape ML Kit's `Ink`/`Stroke`/`StrokePoint` wants anyway.
- Implement **palm rejection**: ignore `PointerDeviceKind.touch` while a stylus is active, and honor pointer-cancel events. (Android surfaces palm detection via MotionEvent; verify it propagates through Flutter on target tablets.)
- Version the stored stroke format from the start (the codebase concerns doc already flags this).

**Warning signs:**
`onPanUpdate` in the capture widget. No `PointerDeviceKind` filtering. Stray dots appearing when a child rests their hand. Inability to answer "how many strokes did the child make?"

**Phase to address:** Handwriting-capture phase (capture sub-component), before scoring.

---

### Pitfall 3: Stroke scoring too strict (false negatives that make a 5-year-old quit)

**What goes wrong:**
The geometric scorer demands near-pixel-perfect overlap with the reference path. A 5-year-old's motor control cannot meet it, so good-faith correct attempts are rejected. The child retries, fails again, and disengages — the exact opposite of the "patient teacher" goal. Anti-gamification removes the dopamine cushion, so frustration has nothing to mask it.

**Why it happens:**
Geometric distance metrics are easy to write strictly and hard to tune loosely. Developers test on their own adult handwriting, which is far cleaner than a child's. Tolerances get set by feel, not by the domain expert.

**How to avoid:**
- **Normalize before comparing:** scale, translate, and (carefully) align the captured strokes into the reference letter's bounding box before computing deviation, so a small-but-correct letter isn't penalized for size/position. Resample strokes to a fixed point count before distance comparison.
- Score on **forgiving, age-appropriate dimensions**: did strokes go roughly the right *direction* and *order*, in roughly the right region, with roughly the right count — not exact path overlap.
- The **pass threshold per letter and per age/grade is curriculum data from the owner's mother**, not a constant in code. Make tolerance a tunable field in the curriculum schema so she can set "what passing looks like for a 5-year-old" without a code change.
- Test against real child handwriting samples, not the developer's, before calling scoring done.

**Warning signs:**
A hardcoded tolerance constant. Testing only on adult strokes. A child failing a letter an adult would call clearly correct. Pass rates near 0% in playtesting.

**Phase to address:** Scoring phase; tolerance-tuning is a dedicated calibration step with the owner's mother.

---

### Pitfall 4: Stroke scoring too lenient (false positives that pass sloppy work)

**What goes wrong:**
Over-correcting Pitfall 3, the scorer passes almost anything. Children advance through lessons without forming letters correctly, undermining the entire premise ("real Arabic, not a game"). Because there are no points/streaks to inflate, the *only* signal of quality is the gate — so a broken gate quietly hollows out the product.

**Why it happens:**
After fighting false negatives, teams loosen tolerances globally until "it stops complaining." Lenient scoring also makes demos look smooth.

**How to avoid:**
- Tune false-negative and false-positive rates **separately and per letter** against labeled child samples, with the owner's mother defining what is genuinely "good enough to advance."
- Keep stroke *order* and *count* as relatively firm requirements even when *shape* tolerance is generous — order/count are unambiguous and pedagogically central.
- Distinguish "good enough to advance the lesson" (S1-09 unlock) from "perfect"; the gentle star (S1-10) acknowledges completion, it should not reward sloppiness.

**Warning signs:**
Scribbles passing. Letters drawn in the wrong order passing. A single global tolerance for all 28 letters. The owner's mother saying "that wouldn't pass in my class."

**Phase to address:** Scoring phase; same calibration step as Pitfall 3 (the two are one tuning problem with two failure directions).

---

### Pitfall 5: Rendering the dotted guide letter with a UI font (wrong contextual form / broken connection)

**What goes wrong:**
The dotted guide letter the child traces is rendered as a `Text` widget using a Material/UI font. The letter shows in the wrong contextual form (an isolated baa when the lesson is teaching the medial form inside a word), or connected letters break apart, or the glyph is missing entirely. The child then traces — and is scored against — the *wrong shape*. The pedagogical core silently corrupts.

**Why it happens:**
Arabic letters have four contextual forms (isolated / initial / medial / final) and connection is mandatory, not cosmetic. Flutter's default fonts have incomplete Arabic coverage, and several documented Flutter bugs break Arabic joining with custom fonts and letter spacing. The reference *path* the child traces must match the *displayed* glyph form — a mismatch is easy to introduce.

**How to avoid:**
- Bundle a strong Arabic font with full glyph coverage and verified joining (Noto Naskh Arabic / Amiri / Scheherazade New are common choices; **test the exact glyphs in your curriculum** — there are known per-letter/ligature rendering bugs even in good fonts).
- Never set a non-zero `letterSpacing` on Arabic text (documented to break joining); wrap Arabic UI in `Directionality(textDirection: TextDirection.rtl)`.
- For the **traceable guide letter specifically, do not rely on live text shaping** — author or generate the reference glyph and its dotted stroke path as a vetted asset (vector/path) per *form* the curriculum teaches, so the displayed dots and the scored reference path are the same source of truth. This sidesteps font-shaping bugs entirely for the tracing surface.
- Render the dotted guide and the child's ink as separate layers (guide beneath, live ink above) in the same normalized coordinate space the scorer uses.

**Warning signs:**
Guide letters rendered via `Text(...)` with a system font. Isolated forms appearing where connected forms belong. Disconnected letters. Boxes/tofu glyphs. The reference path and the displayed glyph coming from different sources.

**Phase to address:** RTL/letter-display phase (R3), before scoring — the scorer depends on the reference path being correct.

---

### Pitfall 6: Curriculum invented in code instead of held faithfully from the domain expert's spec

**What goes wrong:**
Under semester time pressure, developers fill in stroke orders, reps-to-advance, letter-introduction order, and "common mistakes" with guesses or generic web sources. This directly violates PROJECT.md ("Do not invent the pedagogy; structure it") and produces a product that teaches Arabic *wrong* — the worst possible failure for a literacy app.

**Why it happens:**
The spec may arrive incrementally; code needs *something* to run; guessing feels harmless ("we'll fix the data later"). But pedagogy baked into code (hardcoded stroke arrays, magic thresholds) is hard to correct later and easy to forget is fake.

**How to avoid:**
- Build the **curriculum schema first** as pure data (assets/JSON), separate from logic: per letter — ordered reference strokes, stroke directions, stroke count, intro order, reps-to-advance, pass tolerance, and the 3–4 named common mistakes. The owner's mother fills the data; code only reads it.
- Where her spec is not yet available, use **clearly-marked placeholder data** (a `placeholder: true` flag) that the app can refuse to ship or visibly mark — never silently-plausible fake pedagogy.
- No pedagogical constant in Dart code. If a number affects how a child learns, it lives in the curriculum data.

**Warning signs:**
Stroke orders or thresholds hardcoded in `.dart` files. "Common mistakes" sourced from a web search. No `placeholder`/provenance marking on curriculum data. The owner's mother has not reviewed the loaded content.

**Phase to address:** Curriculum-schema phase (early — it gates letter teaching), with a sign-off gate by the owner's mother.

---

### Pitfall 7: Anti-gamification eroded by accident (generic feedback + creeping pressure mechanics)

**What goes wrong:**
The product's identity ("warm, calm, specific... never a chatbot's cheerfulness", "no streaks, no badges, no points-chasing") is undermined by small, well-meaning defaults: a generic "Oops, try again!" toast on failure; a progress bar that becomes a streak; a "you missed today" nudge; celebratory confetti on every tap. Each feels like good UX in isolation; together they rebuild the gamified, pressuring product the project explicitly rejects.

**Why it happens:**
v1 has **no AI tutor** to deliver the specific warm feedback (that is v2). The temptation is to fill the feedback gap with stock encouragement. UI specialists' defaults lean cheerful/gamified. The single allowed "gentle star" (S1-10) can quietly grow into a reward economy.

**How to avoid:**
- v1 feedback must be **specific and deterministic from the scorer**, not generic: name the concrete fix ("start the baa from the right side", "your curve is too shallow") using the curriculum's named common-mistake signatures — short sentences pitched to a 5–10-year-old. This is the v1 stand-in for the v2 tutor's voice and must honor the same tone rules in PROJECT.md.
- Hard-rule the exclusions: **only** the gentle per-lesson star (S1-10). No streaks (NTH-01), badges (NTH-02), or reminder nudges (NTH-03). Add these as explicit "do not build" notes on the relevant tickets so a UI agent doesn't add them by default.
- No timers, countdowns, or "you're behind" messaging anywhere in the child UI.

**Warning signs:**
A "try again" string with no specific guidance. Any streak counter, badge, daily-goal pressure, or loss-aversion copy. Confetti/celebration on routine actions. Feedback tone that sounds like a chatbot, not a teacher.

**Phase to address:** UX/feedback phase, with the scorer feeding specific messages; review against PROJECT.md tone rules at the quality gate.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Score on ML Kit `score` only, skip geometric scorer | Fast "working" demo | Pedagogy is fake; passes wrong-order/sloppy work; full rewrite of the core loop | Never — this is the product's core |
| Hardcode stroke orders / thresholds in Dart | Unblocks coding before spec arrives | Violates "don't invent pedagogy"; correcting later touches code not data; fake pedagogy ships unnoticed | Only as `placeholder:true` data, never as code constants |
| Render guide letters with live `Text` + system font | No asset pipeline | Wrong contextual forms / broken joining silently corrupt what the child traces | Only after verifying exact glyphs render correctly; prefer vetted path assets for the tracing surface |
| Capture strokes via `GestureDetector`/`onPanUpdate` | Familiar to a Flutter beginner | Loses stroke order/count/pressure and palm rejection; no clean ML Kit `Ink` | Never for the tracing surface |
| One global tolerance for all 28 letters | Simple to tune | Some letters too strict (frustration), others too loose (sloppy passes) | Never — tolerance is per-letter curriculum data |
| Store progress in raw SharedPreferences blobs | Quick local persistence | Schema drift, no migration path, hard to evolve toward v2 sync | Acceptable for v1 *if* wrapped behind a repository interface and versioned |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| ML Kit Digital Ink model | Assuming the model is bundled / works offline on first launch | Model must be **downloaded** via `DigitalInkRecognizerModelManager` before first use — this needs network once. For a "works offline anywhere" v1 (NTH-05), download and cache the `ar` model at setup/onboarding and verify `isModelDownloaded` before any recognition; handle the no-network-on-first-run case explicitly. |
| ML Kit locale for Arabic | Guessing the language tag | Use the BCP-47 tag ML Kit expects for Arabic script; confirm the exact identifier against `DigitalInkRecognitionModelIdentifier` and that it covers letter-level (not just word) input. Verify on the target tablet, not just an emulator. |
| Flutter intl / numerals | Assuming `ar` locale renders the digit system you want | `intl` shows Eastern-Arabic digits (٠١٢٣) for dates but Western (0123) for numbers in `ar` — inconsistent. Decide deliberately which numerals a *child learning Arabic* should see and force it (e.g. locale `ar-u-nu-arab` or an explicit converter); don't leave it to defaults. |
| Android stylus → Flutter | Expecting pressure/palm-rejection "just works" | `PointerEvent` exposes `kind`, `pressure`, `tilt`; palm rejection relies on filtering `touch` while stylus active + honoring cancel. **Measure on the actual target tablet** — behavior varies by device/digitizer. |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| High stroke-to-feedback latency | Ink lags the stylus; feedback feels sluggish; child loses the action→result link | Render live ink on a dedicated layer (CustomPainter), keep the capture path light, run scoring off the frame-critical path; target a perceptibly-instant feedback budget and measure it on-device | Immediately on a real child + stylus, even at single-user scale — this is a UX correctness issue, not a scale one |
| Re-running ML Kit recognition on every pointer move | Frame drops, battery drain, jank | Recognize only on stroke/letter completion, never per-move; geometric scoring is cheap and can run incrementally | As soon as recognition is called too often |
| Rebuilding the whole tracing widget on each point | Jittery ink, dropped points | Isolate the drawing layer; use a `CustomPainter` with a repaint-scoped listenable, not `setState` on the parent | Quickly during real tracing |
| Loading all curriculum assets eagerly | Slow cold start | Lazy-load per-lesson curriculum/audio assets | At full 28-letter + words/sentences content size |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Treating "local-only" as "privacy handled" | Child data (name, grade, avatar, nickname, possibly stroke recordings) sits in plain local storage; lost/shared tablet leaks it; violates "treat children's data as sensitive" | Collect the minimum (PROJECT.md): prefer nickname/avatar over real name where possible; keep child data in app-private storage; if stroke recordings are logged for debugging, gate behind an explicit, off-by-default dev flag and never ship them on |
| Logging child strokes/PII for debugging and shipping it | Sensitive child data in logs/crash reports | Strip PII and stroke logging from release builds; no analytics on children by default in v1 |
| Building v2 sync hooks into v1 that quietly collect/transmit | Premature data flow off-device for children before consent/auth exists | v1 is local-only by decision — add **no** network telemetry for child data; leave a clean seam (repository interface) but no live wires |
| Anticipated v2: API key client-side | Tutor key leaks from the app | Already a Decided rule — key only in the Function secret, tutor never client-side; keep v1 free of any such key so it can't regress |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Generic "Oops, try again!" feedback | Child doesn't know what to fix; frustration; violates the tutor-voice spirit | Specific, short, named fix from the scorer ("start from the right side") even in v1's deterministic feedback |
| Over-praising sloppy work | Erodes "real Arabic, not a game"; child learns wrong forms | Gentle star only on genuine completion; praise calibrated to real quality per the owner's mother |
| Too-strict tracing | Capable child fails repeatedly, disengages | Age-appropriate, normalized tolerance set by the domain expert (Pitfall 3) |
| RTL layout not mirrored | Back/next, progress, reading direction feel wrong for an Arabic learner | Use `Directionality`/`EdgeInsetsDirectional`/`Align` with directional values; mirror navigation; do **not** mirror intrinsically-LTR things (e.g. media play controls) or the Arabic glyphs themselves |
| Adult-style dense UI | 5-year-old can't navigate; needs parent for every tap | Child-first targets, minimal text, audio cues; route through the child-UX specialists |
| Stylus assumed; finger ignored | Child without a stylus is locked out, or palm touches draw | Decide finger-vs-stylus policy explicitly; if stylus-required, detect and guide gently; keep palm rejection regardless |

## "Looks Done But Isn't" Checklist

- [ ] **Letter scoring:** Looks done because letters "pass" — verify it rejects correct-shape-but-wrong-stroke-order and wrong-stroke-count, and that order/count come from the curriculum spec, not ML Kit.
- [ ] **Guide letter rendering:** Looks done because a letter appears — verify it shows the correct *contextual form* for the lesson, joins correctly, and that its dotted path is the same source as the scored reference path.
- [ ] **Stroke capture:** Looks done because drawing works — verify per-stroke segmentation, stylus-vs-touch filtering, and palm rejection on the real tablet.
- [ ] **Offline/first-run:** Looks done in dev (model already cached) — verify behavior on a fresh install with no network: is the `ar` model present, or does first launch fail?
- [ ] **Feedback tone:** Looks done because messages appear — verify each failure message names a specific fix and matches the PROJECT.md tutor-voice rules; no generic "try again".
- [ ] **Anti-gamification:** Looks done because there are no badges — verify no streaks, no nudges, no timers, no loss-aversion copy crept in via UI defaults.
- [ ] **Curriculum data:** Looks done because lessons load — verify content is the owner's mother's spec (or clearly marked placeholder), not invented stroke orders.
- [ ] **Child data:** Looks done because it's local — verify minimum collection, app-private storage, no stroke/PII logging in release.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Built scoring on ML Kit score only (P1) | HIGH | Add the geometric scorer as the gate; demote ML Kit to a sanity check; re-tune with the domain expert. Cheaper if capture already stores ordered strokes. |
| Captured via GestureDetector (P2) | MEDIUM | Swap the capture surface to `Listener`/pointer events; re-shape stored data; cheaper if stroke storage was abstracted behind an interface. |
| Tolerance wrong direction (P3/P4) | LOW | Tolerances are curriculum data, not code — re-tune values with the owner's mother; no code change if schema was built right. |
| Guide rendered with bad font/form (P5) | MEDIUM | Switch to vetted path assets per form; resync reference paths; re-verify each letter renders. |
| Invented curriculum shipped (P6) | MEDIUM–HIGH | Replace placeholder data with the real spec; low if pedagogy was data not code, high if hardcoded. |
| Gamification/pressure crept in (P7) | LOW | Remove the offending widgets/strings; cheap if isolated, since v1 deliberately has little of it. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| P1 ML Kit over-trust | Scoring-architecture design (pre-code) + re-confirm R1 scope with owner | Scorer gates on geometric order/count/shape; ML Kit is advisory only |
| P2 Lossy stroke capture | Handwriting-capture phase | `Listener`+pointer events; per-stroke data; palm rejection tested on tablet |
| P3 Too-strict scoring | Scoring + calibration with domain expert | Real child samples pass at expert-approved rates |
| P4 Too-lenient scoring | Same calibration step | Wrong-order/scribble samples reject; per-letter tolerances |
| P5 Wrong guide rendering | RTL/letter-display phase (R3) | Each lesson shows correct contextual form; path == displayed glyph |
| P6 Invented curriculum | Curriculum-schema phase (early) | Owner's-mother sign-off gate; no pedagogy in Dart code |
| P7 Anti-gamification erosion | UX/feedback phase | Tone review vs PROJECT.md; explicit "do not build" on streak/badge/nudge tickets |
| Offline model availability | Capture/setup phase | Fresh-install no-network test |
| Child-data privacy | Profile/persistence phase | Min-collection + private storage + no release-build PII logging |
| Flutter-beginner maintainability | All phases (cross-cutting) | Low-magic Riverpod, data-not-code pedagogy, clean repository seams, code-reviewer gate |

## Cross-cutting: Flutter-beginner maintainability (process pitfall)

The owner is fluent in Python, new to Dart. Choices that keep the codebase reviewable:
- **Low-magic Riverpod** (the Decided state choice) — prefer plain, explicitly-typed providers over heavy codegen indirection where a beginner must reason about it; explain each Dart idiom in comments/ADRs.
- **Pedagogy as data, not code** (P6) — lets the owner and his mother change teaching behavior without reading Dart.
- **Clean seams, not abstractions for their own sake** — a `CurriculumRepository`, a `ProgressRepository`, a `StrokeScorer` interface. Enough to swap local→Firebase in v2, not a speculative framework. Over-engineering v1 for v2 is itself a pitfall: build the *interface* now, the Firebase *implementation* in v2.
- **Code-reviewer gate** on agent-written Dart before merge (per the routing map), with a watch for the Decided-section violations (BLoC, iOS work, client-side keys, gamification).

## v1→v2 seam (avoid over-engineering)

- Keep child data behind repository interfaces so v2 can add a Firebase-backed implementation — but ship **no Firebase, no auth, no network for child data** in v1.
- Version the stored stroke and progress formats now (cheap, already flagged) so v2 sync has a known schema.
- Do **not** pre-build sync/conflict-resolution, profile-compilation, or tutor-call plumbing in v1; those are v2 (R2/R4) and add risk and surface area to a course-deadline milestone.
- Resist adding Firestore "just for storage" in v1 — local storage satisfies the local-only decision and avoids dragging child data online prematurely.

## Sources

- [Digital ink recognition | ML Kit | Google for Developers](https://developers.google.com/ml-kit/vision/digital-ink-recognition) — recognizer returns ranked text candidates with confidence; ink = sequence of strokes of timed touch points (input format, not pedagogy output). HIGH.
- [google_mlkit_digital_ink_recognition | pub.dev](https://pub.dev/packages/google_mlkit_digital_ink_recognition) — `recognize(ink)` returns `List<RecognitionCandidate>` (`text` + `score`) only; no per-stroke scoring; model must be downloaded via `DigitalInkRecognizerModelManager` before use. HIGH.
- [DigitalInkRecognitionModelIdentifier | ML Kit](https://developers.google.com/android/reference/com/google/mlkit/vision/digitalink/DigitalInkRecognitionModelIdentifier) — language/script identifiers incl. Arabic. HIGH.
- [Advanced stylus features | Android Developers](https://developer.android.com/develop/ui/views/touch-and-input/stylus-input/advanced-stylus-features) — pressure/tilt/orientation/palm detection via MotionEvent; motion prediction for latency. HIGH.
- [PointerData class — Flutter API](https://api.flutter.dev/flutter/dart-ui/PointerData-class.html) — pressure/tilt/kind exposed to Flutter. HIGH.
- [Taps, drags, and other gestures | Flutter docs](https://docs.flutter.dev/ui/interactivity/gestures) — gesture vs raw pointer (`Listener`) distinction. HIGH.
- [Flutter issue #160841 — custom Arabic font rendered incorrectly](https://github.com/flutter/flutter/issues/160841) and [#143975 — specific Arabic letter rendering](https://github.com/flutter/flutter/issues/143975), [#71220 — letter spacing breaks Arabic](https://github.com/flutter/flutter/issues/71220) — documented Arabic joining/spacing bugs. MEDIUM–HIGH.
- [Right-to-Left in Flutter — LeanCode](https://leancode.co/blog/right-to-left-in-flutter-app) and [Arabic Ligatures — Kitab/NoorUI](https://kitab.noorui.com/en/blog/arabic-ligatures) — contextual forms (isolated/initial/medial/final), mandatory ligatures, RTL layout guidance. MEDIUM.
- [dart-lang/i18n issue #477 — Indian vs Arabic numbers](https://github.com/dart-lang/i18n/issues/477) and [Using intl with hindi and arabic numbers](https://willcodefor.beer/posts/intlu) — `intl` numeral-system inconsistency in `ar`; `ar-u-nu-arab` fix. MEDIUM.
- [iTrace](https://apps.apple.com/us/app/itrace-handwriting-practice/id645416621) and [EducationalAppStore — letter tracing apps](https://www.educationalappstore.com/best-apps/5-best-letter-tracing-apps-for-kids) — competitor handling of stroke-order feedback and adjustable sensitivity (false-negative/positive tradeoff). LOW–MEDIUM.
- Qalam `.planning/PROJECT.md`, `docs/USER_STORIES.md`, `docs/RESEARCH_BRIEF.md`, `.planning/codebase/CONCERNS.md` — project constraints, anti-gamification, curriculum ownership, R1–R4. HIGH (authoritative for this project).

---
*Pitfalls research for: handwriting-first Arabic-literacy children's tablet app (Flutter/Android, on-device ML Kit, RTL, anti-gamification)*
*Researched: 2026-05-30*
