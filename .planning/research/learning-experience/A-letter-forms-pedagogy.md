# A — Letter Forms Pedagogy: teaching the four contextual forms of Arabic letters

**Topic:** How children are taught to *handwrite* the four contextual forms of Arabic
letters (isolated / initial / medial / final), and how Qalam should model and teach them.
**Audience:** feeds a data-model schema + a teaching-flow design. **Status:** research,
decision-oriented. Date 2026-06-14.

> Reminder for the owner's mother (curriculum authority): everything below is **structure**,
> not pedagogy. Stroke counts, which form a letter is introduced in, and the per-letter
> mistakes are hers to confirm. We are proposing *slots and flow*, not the spec.

---

## 1. The four contextual forms — how the pen path differs

Arabic is cursive: within a word, letters join. So most letters have up to **four**
positional shapes, and the **pen path differs** mainly at the *connectors* (the joining
strokes), while the letter's *core body* stays recognizable.

- **Isolated** — letter alone. The full body plus its natural tail/flourish. This is the
  shape Qalam already authored.
- **Initial** — start of a connected run. Body is written, the right side is *open/free*,
  and the tail is replaced by a short **left-going connector** at the baseline so the next
  letter can attach.
- **Medial** — middle of a run. A **right connector comes in**, the body is often
  *compressed*, and a **left connector goes out**. Tail/flourish is dropped.
- **Final** — end of a run. A **right connector comes in**, and the natural **tail/flourish
  returns** on the left (it is free to the left).

**Worked example — baa ب.** Isolated: a wide shallow bowl/boat with the dot below, ending
in an upturned tail. Initial (بـ, e.g. بـيت): the bowl is shortened to a small toothed
stroke sitting on the baseline, no tail, exits left. Medial (ـبـ): a small "tooth" bump
between two baseline connectors — the bowl almost disappears into a hump. Final (ـب): the
right connector enters, then the full upturned tail returns. The **dot stays below in all
four**; the body shrinks toward the middle of the word and the tail only exists at the ends.

**Worked example — ‘ayn ع.** Isolated: open "C/hook" on top, big curved tail below. Initial
(عـ): the open-top hook only, exits left, no tail. Medial (ـعـ): when entered from a previous
letter the top **closes into a loop** (a visibly different shape from isolated) and exits left
— this is the classic "ayn changes a lot" case. Final (ـع): right connector + the big tail
returns. ‘ayn is the headline example that the medial/final shape can look *quite different*
from the isolated one, not just "isolated minus tail."

**Takeaway for the model:** a form differs from isolated by (a) which connectors are present
(right-in, left-out), (b) whether the tail/flourish is kept or dropped, and (c) for a few
letters (‘ayn, ghayn, haa, kaaf, jiim-family) a genuine body reshape. The schema must allow a
form to be a *distinct authored path*, not just "isolated + a stub."

## 2. Non-connecting letters — confirmed, and which slots are null

Six letters **connect to the letter before them but never to the letter after**:

**ا (alif) · د (daal) · ذ (dhaal) · ر (raa) · ز (zaay) · و (waaw).**

Consequence: they have **only two visual shapes** — **isolated** and **final** (the "final"
is just isolated + an incoming right connector). They have **no initial and no medial form**.
So in the schema, for these six letters:

- `isolated` = present
- `final` = present (isolated body with a right-entry connector)
- `initial` = **null**
- `medial` = **null**

(Reason it matters beyond data: because they don't join forward, the *next* letter must start
fresh in its **initial** form. Alif specifically can't join forward or it would look like laam.)

**Special cases to slot now:**

- **لا (laam-alif) ligature** — a mandatory single glyph, not laam-then-alif drawn separately.
  Has an **isolated** form (لا) and a **final/joined** form (ـلا) when a letter precedes it. The
  pen path is its own thing (laam up-left, alif sweeps back). Treat laam-alif as a **letter-like
  unit with its own form slots**, not as two letters — children are taught it as one shape.
- **hamza ء** — sits as a small standalone mark or rides a carrier (أ إ ؤ ئ ا as seat). The bare
  hamza ء doesn't connect at all. The *carrier* (alif/waaw/yaa-seat) follows that carrier's
  joining rules; hamza is an add-on mark on top/below. Model hamza as a **diacritic-like
  attachment + a seat letter**, not a connecting letter of its own.
- **taa marbuuta ة** and **alif maqsuura ى** — final-position-only letters; effectively
  isolated + final slots, no initial/medial. Flag for the owner's mother to confirm scope.

## 3. Recommended teaching SEQUENCE

The consensus across Arabic-literacy guidance and Kumon-style structured practice is
**isolated-first, then forms, then in a word** — a strict readiness gate, not "words from day one":

1. **Isolated form, traced** with large guided dotted lines, correct stroke order.
2. **The positional forms** (initial → medial → final) for that same letter, as separate
   tracing targets.
3. **Connection in a real word** with dotted guides, then copying short words independently.

Readiness signals cited for moving a child from isolated to connected work: can write the
isolated letters from memory with correct proportion, recognizes the forms, and can read simple
2-letter joins. This matches Qalam's Kumon spirit: **master the unit clean before advancing**,
one new thing at a time. Words-from-the-start is *not* recommended for ages 5–10 beginners; it
overloads directionality + joining + shape at once.

## 4. Stroke-order consistency across forms

**The core stroke order stays the same; connectors are added, not relearned.** The dominant
principle in the sources: the letter's fundamental stroke pattern is preserved across positions,
and the **connecting tails/teeth adjust** by position (toothed letters like seen س keep their
three teeth in every form; only the tail is swapped for a connector or returns at the end).

So pedagogically you **don't teach four unrelated motions** — you teach **one body stroke** plus
the rule "drop the tail and exit left here / enter from the right there." The exceptions are the
few **body-reshape letters** (‘ayn/ghayn closing into a loop, haa, kaaf, the jiim family) where
the medial body genuinely differs and is worth teaching as a near-fresh shape. The schema should
therefore mark each form as either *"core + connector deltas"* or *"distinct path"* so authoring
and the scorer know which letters need full re-authoring vs. connector overlays.

## 5. Most common child mistakes, per form (→ named scorer checks + authored feedback)

These are the failure modes to turn into named checks and warm, specific feedback:

- **Disconnecting a connector** — leaving a gap where the form should join (most common). *Check:*
  connector endpoint not within join tolerance of the adjacent letter / baseline.
- **Using the wrong form** — writing the isolated shape where a medial/final was needed (e.g.
  drawing the full tail mid-word). *Check:* tail present in a no-tail position.
- **Wrong proportion / size** — medial body too big (child writes a near-isolated letter), or
  initial too tall. *Check:* body bounding-box ratio vs. reference per form.
- **Mirror / wrong direction** — writing left-to-right, or reversing a hook. *Check:* stroke
  direction and start point.
- **Dot/diacritic placement** — right count, wrong side or position (ب vs ت vs ث; dot drifting
  above when it belongs below). *Check:* dot count + region.
- **Connector at wrong height** — joining stroke not on the baseline so the run looks broken.
- **Confusing same-skeleton siblings** — ب/ت/ث, ج/ح/خ, ص/ض, س/ش — same body, differ only by dots;
  worth a per-family note.

Feedback stays in the tutor's voice: *"Your baa is joined too far up — bring the join down to the
line so it links to the next letter,"* never *"wrong, try again."*

## 6. Concrete recommendation for Qalam

**Model a "letter unit" with up to four explicitly-authored form slots, nullable.**

- Schema per letter: `forms = { isolated, initial?, medial?, final? }`, each form holding its own
  ordered stroke path, stroke count, connector-entry/exit metadata, and per-form mistake list.
  For the six non-connectors, `initial`/`medial` are **null** by design — the schema, scorer, and
  journey map must all treat null as "this form does not exist," not "missing/TODO."
- Tag each form `reuses_core: true` (connector overlay on the isolated body) **or** `distinct: true`
  (‘ayn-style reshape needs full authoring). Lets authoring reuse the isolated path for most forms
  and only re-author the hard ones.
- Treat **laam-alif** as its own letter-like unit (isolated + final); treat **hamza** as a
  seat-letter + attached mark, not a connecting letter.

**Teaching flow (Kumon-style, one new thing at a time):** within a letter unit, present forms as
**separate practice targets in sequence** — isolated → initial → medial → final — each gated by
clean reps, **skipping null slots automatically** (so a non-connector unit is just isolated →
final). Then add a **single connection-in-a-word target** at the end of the unit: a short, already-
taught 2–3 letter word with dotted guides, where the child practices the *join itself*. Award the
quiet mastery star for the **whole letter unit** (all its real forms + the word join), not per form
— consistent with the anti-gamification rule (a star = "you truly write this letter," not a tally).
Introduce the in-word target only with letters the child has already mastered in isolation, so the
word join is the *only* new variable.

---

### Sources
- Arab Academy — different forms of Arabic letters: https://www.arabacademy.com/the-different-forms-of-arabic-letters-and-how-they-come-together/
- KALIMAH — non-connecting letters: https://kalimah-center.com/non-connecting-letters/
- KALIMAH — how to teach the Arabic alphabet (sequence): https://kalimah-center.com/how-to-teach-the-arabic-alphabet/
- KALIMAH — handwriting & tracing worksheets: https://kalimah-center.com/arabic-alphabet-handwriting-and-tracing/
- Sahlah Academy — connected forms & tracing techniques: https://sahlahacademy.net/arabic-alphabet-writing/
- Riwaq Al Quran — letter seen (toothed letters): https://riwaqalquran.com/blog/the-arabic-letter-seen/
- KALIMAH — letter ‘ayn forms: https://kalimah-center.com/arabic-letter-ain/
- arabic.fi — ‘ayn forms (loop closing in medial/final): https://arabic.fi/letters/57
- Wikibooks — laam-alif ligature: https://en.wikibooks.org/wiki/Arabic/LearnRW/laam-alif
- Wikipedia — Hamza: https://en.wikipedia.org/wiki/Hamza
- Al-dirassa — common mistakes writing Arabic letters: https://al-dirassa.com/en/common-mistakes-when-writing-arabic-letters-and-how-to-avoid-them/
- A Toolkit for Teaching Arabic Handwriting (PDF): https://www.academia.edu/17265540/A_Toolkit_for_Teaching_Arabic_Handwriting
