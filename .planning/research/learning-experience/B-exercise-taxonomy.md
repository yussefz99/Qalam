# B — Exercise Taxonomy: Handwriting-First Redesign of Early-Arabic Exercise Families

**Topic:** Take the mother's paper worksheet families and redesign each so the child
*writes* the answer with a stylus — never taps a choice. Output is an implementation-ready
typed exercise schema where each `type` = one Flutter interaction widget + one validator.

**Hard rule (the anti-product):** multiple-choice / tap-the-answer is forbidden. Every
exercise resolves to a *written stroke* checked by the existing geometric stroke scorer
(count/order/direction/shape vs reference paths) or a thin rule check on top of it.

**Pedagogy grounding (web):** Integrating phoneme awareness with letter *formation*
out-performs oral-only or recognition-only work; active self-production of a letter recruits
the sensori-motor network and improves later recognition where passive viewing does not; and
generative retrieval (writing the answer) beats multiple-choice recognition. This is direct
evidence that converting recognition tasks into *writing* tasks is pedagogically superior, not
just on-brand. (Sources at end.)

---

## The seven families → handwriting-first redesigns

### 1. Phonological awareness (وعي صوتي)
- **Skill:** map a heard sound to its grapheme; isolate the initial (then final, then medial)
  phoneme of a word.
- **Paper form:** "circle the first letter you hear," "color the pictures that start with ت."
- **Handwriting-first redesign:** mascot says a word aloud (audio id) + shows its picture; the
  child **writes the letter the word starts with** in the trace pane. The expected grapheme is
  known, so the scorer runs against that letter's reference paths exactly as in normal tracing.
  Mascot reacts on the *letter the child actually formed*: if shape matches but is the wrong
  letter (e.g. wrote ب for a ت word) feedback is phonological ("That's *baa* — listen again,
  *tuffaaha*… **t**, **t** — which letter makes that sound?"); if right letter but messy, normal
  stroke feedback. Progression of difficulty = initial → final → medial position, per the
  pedagogy sequence.
- **Verdict:** needs real redesign (recognition→production), but mechanically reuses the scorer.

### 2. Letter ↔ picture
- **Skill:** bind a letter form to a concrete referent (vocabulary anchoring).
- **Paper form:** "match the letter to the right picture" / "choose the image for the letter."
- **Handwriting-first redesign:** invert it. Show **one picture**, child writes the letter it
  begins with (effectively the same interaction as #1 but cued by image, not audio). Or show a
  **letter**, mascot names three things that start with it, child writes the letter again from
  memory after the audio (recall, not match). No grid of pictures to tap.
- **Verdict:** matching is the *most* anti-product form on paper; fully redesigned into a
  picture-cued write. Reuses the scorer.

### 3. Dictation (إملاء)
- **Skill:** sound→symbol production under recall, no visual model.
- **Paper form:** teacher says it, child writes it.
- **Handwriting-first redesign:** mascot says a letter / short word (audio id); child writes it
  with **no dotted guide** (or a faded guide for early levels). Scorer checks each written letter
  against its reference; for a word, segment the canvas by pen-lifts / x-position and validate the
  sequence. This is the purest expression of the product.
- **Verdict:** converts **almost directly** — already handwriting-first.

### 4. Letter connection (ربط / إعادة كتابة)
- **Skill:** join letters into connected script; choose correct positional form
  (isolated/initial/medial/final).
- **Paper form:** isolated letters given; child rewrites the word connected.
- **Handwriting-first redesign:** show the word as separated forms (or as audio + meaning); child
  **writes it connected** in one pane. Validator = scorer over the word's connected reference path
  **plus a connection rule check**: verify expected join points exist (pen stayed down across the
  ligature, baseline continuity) and that each glyph used its correct positional form. Mistake
  feedback is specific: "*siin* sits at the start, so it reaches forward to *miim* — don't lift
  your pen between them."
- **Verdict:** needs redesign of *checking* (positional-form + join logic on top of the scorer),
  but the interaction is native writing.

### 5. Vocabulary (الحروف مع صور وكلمات)
- **Skill:** letter + sound + word + image, bound together.
- **Paper form:** chart of letter, picture, word to read.
- **Handwriting-first redesign:** not a quiz type — it's a **presentation/teach card** the mascot
  narrates, then it *feeds* the other writing types (it supplies the audio id + image + expected
  word that #1, #2, #3 consume). Modeled as content, with an optional "write the word you just
  learned" capstone (a dictation instance).
- **Verdict:** content layer, not an interaction; its capstone reuses dictation.

### 6. Grammar (مفرد/مثنى/جمع، الكلمة والعكس)
- **Skill:** morphology — form the dual/plural; produce the opposite word.
- **Paper form:** fill-in / match singular→plural, word→opposite.
- **Handwriting-first redesign:** mascot shows/says the singular ("قلم — one pen"), shows two/many
  pens, and the child **writes the dual/plural form** ("قلمان" / "أقلام"). For opposites: mascot
  says "كبير," child writes "صغير." Validator = scorer over the target word's reference path (the
  expected answer is a fixed known string, so it's a constrained dictation). This keeps grammar
  *productive* and writing-based instead of a tap-match.
- **Verdict:** needs redesign (match→produce); mechanically a constrained dictation. Hardest
  content authoring (need a small lexicon of answer words with reference paths).

### 7. Mazes / coloring enrichment (متاهة الحروف، لون واكتشف)
- **Skill:** letter discrimination, fine-motor warm-up, motivation/pacing.
- **Paper form:** trace a path through letters; color regions.
- **Handwriting-first redesign:** keep as **stroke-based fine-motor play** that still produces
  ink. *Letter maze* = drag the pen along a winding path that *is the letter's stroke order* (the
  maze walls are the letter outline; "escaping" = forming the letter) — validated as a low-
  threshold trace. *Color-and-discover* → "trace every ت you find" rather than color/tap; the
  scorer confirms each traced glyph. These are the low-stakes, no-fail palette-cleanser between
  graded reps (anti-gamification: no points, just a warm "you found them all").
- **Verdict:** needs redesign to stay handwriting-first; runs at a relaxed scorer threshold.

---

## Convert-directly vs need-redesign (decision table)

| Family | Conversion effort | Why |
|---|---|---|
| Dictation (إملاء) | **Direct** | Already write-what-you-hear |
| Vocabulary | **Direct (as content)** | Teach card; capstone = dictation |
| Phonological awareness | Redesign (light) | recognition→write-the-letter; scorer unchanged |
| Letter↔picture | Redesign (light) | match→picture-cued write; scorer unchanged |
| Grammar | Redesign (medium) | match→produce; needs answer-word lexicon |
| Letter connection | Redesign (medium) | needs join/positional-form rule check |
| Maze/coloring | Redesign (medium) | reframe as fine-motor trace at low threshold |

**One reusable core:** every family above collapses to "the expected written answer is a known
letter or word; run the geometric scorer against its reference path." The differences are only in
(a) how the prompt is *cued* (audio / image / morphology stem) and (b) what *extra rule check*
runs after the scorer (positional form, join continuity, sequence segmentation).

---

## Typed exercise schema (discriminated union by `type`)

Every type is handwriting-first. Each `type` = one Flutter interaction widget + one validator.
`expectedGlyphIds` resolves to reference stroke paths the scorer already owns.

```jsonc
// Shared base — every exercise carries these
{
  "id": "ex_0142",
  "type": "...",                  // discriminant (see below)
  "promptText": "اكتب الحرف الأول", // mascot caption (child's working language for guidance)
  "promptAudioId": "aud_tuffaaha",  // required where the cue is a sound
  "imageAssetId": "img_apple",      // optional picture cue
  "scorerThreshold": "graded",      // graded | relaxed (maze/warm-up)
  "showGuide": true,                // dotted guide on/off (off = harder/dictation)
  "mistakeFeedback": [              // authored, mascot voice; keyed to scorer fault codes
    { "fault": "wrong_letter", "say": "That's baa — listen: t, t…" },
    { "fault": "shape_curve",  "say": "Your taa needs a flatter bowl — slower this time." }
  ]
}
```

```jsonc
// 1. traceLetter        — guided tracing (the existing core loop)
{ "type": "traceLetter", "expectedGlyphIds": ["taa_isolated"], "showGuide": true }

// 2. writeFromSound     — phonological awareness + dictation-of-one-letter
{ "type": "writeFromSound", "promptAudioId": "aud_tuffaaha",
  "expectedGlyphIds": ["taa_initial"], "phonemePosition": "initial", "showGuide": false }

// 3. writeFromPicture   — letter↔picture, inverted to production
{ "type": "writeFromPicture", "imageAssetId": "img_apple",
  "expectedGlyphIds": ["taa_initial"] }

// 4. dictateWord        — إملاء of a full word (sequence)
{ "type": "dictateWord", "promptAudioId": "aud_qalam",
  "expectedWord": "قلم", "expectedGlyphSequence": ["qaaf_i","laam_m","miim_f"],
  "showGuide": false }

// 5. connectWord        — ربط: write connected, with join + positional-form check
{ "type": "connectWord", "expectedWord": "سمك",
  "expectedGlyphSequence": ["siin_i","miim_m","kaaf_f"],
  "requireConnected": true, "checkPositionalForms": true }

// 6. produceForm        — grammar: dual/plural/opposite, constrained dictation
{ "type": "produceForm", "stemWord": "قلم", "operation": "plural",
  "expectedWord": "أقلام", "expectedGlyphSequence": ["alif","qaaf_i","laam_m","alif","miim_f"] }

// 7. teachCard          — vocabulary presentation (no scoring; feeds others)
{ "type": "teachCard", "letterId": "taa", "imageAssetId": "img_apple",
  "wordAudioId": "aud_tuffaaha", "exampleWords": ["تفاحة","تمر"] }

// 8. letterMaze         — fine-motor enrichment, relaxed trace
{ "type": "letterMaze", "expectedGlyphIds": ["taa_isolated"],
  "scorerThreshold": "relaxed", "noFail": true }
```

**Validator map (1:1 with widgets):**
- `traceLetter`, `writeFromSound`, `writeFromPicture`, `letterMaze` → **single-glyph scorer**
  against `expectedGlyphIds` (just different cue widgets + threshold). `writeFromSound` adds the
  `wrong_letter` fault when shape is clean but matches a *different* known glyph.
- `dictateWord`, `connectWord`, `produceForm` → **sequence validator**: segment canvas by
  pen-lift / baseline x-runs, score each segment against `expectedGlyphSequence`, report the first
  failing index. `connectWord` adds join-continuity + positional-form rule checks; `produceForm`
  derives `expectedWord` from `stemWord`+`operation` at authoring time (owner's mother supplies the
  answer words).
- `teachCard` → no validator (content).

**Why this shape:** eight types, but only **two validators** (single-glyph, sequence) plus a small
rule-check layer. The owner's mother authors content (audio ids, images, answer words, mistake
lines); engineering reuses the one scorer everywhere. Nothing here is tappable.

---

## Sources
- [Collaborative Classroom — Phonological Awareness Pt.2 (integrate with letter formation)](https://www.collaborativeclassroom.org/blog/early-literacy-phonological-awareness-updated-part-2/)
- [Keys to Literacy — Developing Phonemic Awareness Using Letters](https://keystoliteracy.com/blog/developing-phonemic-awareness-using-letters/)
- [MA DOE Mass Literacy — Phonological Awareness (initial→final→medial sequence)](https://www.doe.mass.edu/massliteracy/skilled-reading/fluent-word-reading/phonological-awareness.html)
- [PMC — Brain activation: learning letters via active self-production vs passive observation](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3780305/)
- [PMC — Graphomotor knowledge & letter-like shape recognition in preschoolers](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8888515/)
- [ALT — Writing modality affects recollection in children (handwriting > typing)](https://journal.alt.ac.uk/index.php/rlt/article/view/2239)
- [Fazio et al. 2010 — Memorial consequences of multiple-choice testing (recognition limits)](http://psychnet.wustl.edu/memory/wp-content/uploads/2018/04/Fazio-et-al-2010_MemCog.pdf)
