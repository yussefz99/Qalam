# Phase 19 — baa Card Review Packet (for the owner's mother)

**Purpose (D-10):** one sitting to review the 7 baa cards that asked the child to
write letters they have **not learned yet**. The baa unit teaches only **alif (ا)
and baa (ب)** — every card in it should use only those two letters (the learned-
letters rule, D-12). Seven cards broke that rule. This packet shows each one, how
it looks on screen, what we did in code for now, and a recommendation. **You
decide** — keep our draft, change the word, or gate the card to a later letter.

---

## Read this first — it is NON-BLOCKING (D-11)

- **Nothing here blocks the deadline.** The code already ships a safe state: the
  6 hard cards are **gated** (removed from the baa unit until their letters are
  taught) and the 1 rewritable card (`kitaab`) ships a **draft** marked
  `signedOff: false`. A child never sees an unlearned-letter card today.
- **Your changes land later, whenever you are free.** When you sign off, your
  edits go in as `assets/curriculum/exercises.json` changes plus a `signedOff`
  flip from `false` → `true` (the same 15-07 / 17-10 pattern the graph tier
  sign-off used). Only **you** set `signedOff: true` on curriculum content — no
  executor ever does.
- **"Gate" means:** the card's node was removed from the baa unit's graph so it
  is unreachable now. Its content is kept, dormant, and filed for the unit of the
  letter it needs (Phase 20/21). No content was deleted.
- **"Rewrite" means:** we changed the card's word to an alif+baa-only word so it
  fits the baa unit. It ships provisional (`signedOff: false`) until you approve.

**How the new presentation looks (context for the "on screen" notes below):** every
graded question now shows a fixed **instruction bar** at the top (a short line +
a speaker you can tap to hear it again — 19-02), plus a **self-explanatory
stimulus** (19-03): a gap shows a big highlighted **slot box** in the word, a
listen-and-write question shows a big replayable **audio card**, and a copy
question reveals the word then lets the child hide/peek it. The spoken line is
now reinforcement, never the only clue.

---

## The 7 cards

### 1. `baa.connectWord.kitaab` — **REWRITE applied** (your call to confirm)

- **Current content (as flagged):**
  - text (letters apart): `ك  ت  ا  ب`
  - expected word: `كتاب` ("book")
  - letters: `kaaf, taa, alif, baa`
  - feedback (pass): "كتاب — "book," joined. أحسنت!"
  - **Unlearned letters:** **kaaf (ك), taa (ت)** — not taught in the baa unit.
- **On screen (new presentation):** the instruction bar says to join the letters;
  the stimulus zone shows the separated letters large; the child writes them as
  one connected word on the canvas. The teaching point is **baa's final shape at
  the end of a word**.
- **What we did (draft, `signedOff: false`):** rewrote the word to the alif+baa
  word **`باب`** ("door"):
  - text: `ب  ا  ب` · expected: `باب` · letters: `baa, alif`
  - feedback (pass): "باب — joined, and baa returns in its final shape at the end.
    أحسنت!"
  - The teaching angle is preserved — `باب` ends in a **final baa**, so the
    "final shape at the end" lesson still holds.
- **Recommendation — REWRITE to an alif+baa word, but please pick between two
  honest options:**
  1. **Keep `باب`** (our draft). Clean and honest, but note it **duplicates the
     existing `baa.connectWord.baab` card** (also `باب`, "door"). If you keep it,
     we suggest differentiating the framing: `baab` teaches *the join across the
     word*, this one *spotlights baa's final form returning at the end*. (The card
     id still reads `kitaab` internally — harmless, but we can rename it once you
     decide.)
  2. **Use a different alif+baa word** — e.g. **`بابا`** ("daddy"), a warm word a
     heritage child knows, distinct from `باب`. It teaches baa in the initial and
     medial positions (loses the "final baa" angle).
  3. **Gate it** — file `كتاب` ("book") for the **kaaf/taa** unit, where the child
     will have learned both letters, and drop it from the baa unit now.
  - Our lean: option 1 or 2 keeps a live connect-word card in the baa unit; option
    3 is cleanest if you feel `باب` is already well covered by `baab`.

---

### 2. `baa.transformWord.dual` — **GATED** (node removed)

- **Current content:**
  - rule chip: "Dual · مثنى" · base word shown: `باب`
  - expected word: `بابان` ("two doors")
  - letters: `baa, alif, noon` · **Unlearned: noon (ن)**
  - feedback (pass): "بابان — two doors. أحسنت!"
- **On screen (new presentation):** instruction bar "Change the word"; a rule chip
  "Dual · مثنى"; the base word `باب` large; the child writes the dual form.
- **What we did:** **gated** — the dual ending `ـان` needs **noon**, which the
  child has not learned. Node removed from the baa graph; content filed for the
  grammar/noon unit.
- **Recommendation — GATE.** The dual form structurally needs noon; there is no
  honest alif+baa dual. Re-introduce it once **noon** is taught. (Confirm.)

---

### 3. `baa.transformWord.plural` — **GATED** (node removed)

- **Current content:**
  - rule chip: "Plural · جمع" · base word shown: `باب`
  - expected word: `أبواب` ("many doors")
  - letters: `alif, baa, waaw` · **Unlearned: waaw (و)** (plus the hamza أ)
  - feedback (pass): "أبواب — many doors. أحسنت!"
- **On screen:** instruction bar "Change the word"; rule chip "Plural · جمع"; base
  word `باب`; the child writes the plural.
- **What we did:** **gated** — `أبواب` needs **waaw** (and hamza). Node removed;
  filed for the waaw unit.
- **Recommendation — GATE.** No honest alif+baa broken plural exists. Re-introduce
  once **waaw** is taught. (Confirm.)

---

### 4. `baa.transformWord.opposite` — **GATED** (node removed)

- **Current content:**
  - rule chip: "Opposite · عكس" · base word shown: `كبير` ("big")
  - expected word: `صغير` ("small")
  - letters: `saad, ghayn, yaa, raa` · **Unlearned: all four (ص، غ، ي، ر)**
  - feedback (pass): "صغير — "small." أحسنت!"
- **On screen:** instruction bar "Change the word"; rule chip "Opposite · عكس"; the
  word `كبير`; the child writes its opposite.
- **What we did:** **gated** — both `كبير` and `صغير` are entirely unlearned
  letters. Node removed; filed for a much later unit.
- **Recommendation — GATE.** There is no honest alif+baa "opposite" pair to teach
  here. Re-introduce far later, once these letters are known. (Confirm.)

---

### 5. `baa.fillBlank.adjective` — **GATED** (node removed)

- **Current content:**
  - sentence with a gap: `البابُ __blank__`
  - expected word (fills the gap): `كبير` ("big")
  - letters: `kaaf, baa, yaa, raa` · **Unlearned: kaaf, yaa, raa (ك، ي، ر)**
  - feedback (pass): "البابُ كبير — you filled it in. أحسنت!"
- **On screen (new presentation):** instruction bar "Write the missing part"; the
  sentence renders with a big highlighted **slot box** (RTL) where the missing
  word goes; the child writes the adjective into the slot.
- **What we did:** **gated** — the adjective `كبير` needs unlearned letters. Node
  removed; filed for a later unit.
- **Recommendation — GATE.** A describing word that uses only alif+baa is not
  available here. Re-introduce once its letters are taught. (Confirm — or, if you
  know an alif+baa adjective that fits `البابُ ___`, we can rewrite instead.)

---

### 6. `baa.buildSentence.hear` — **GATED** (node removed)

- **Current content:**
  - a **listen-and-write** sentence (audio: `sentence.albaab-kabiir`)
  - expected words: `البابُ` , `كبير` ("the door is big")
  - letters: `alif, laam, baa, kaaf, yaa, raa` · **Unlearned: laam, kaaf, yaa, raa**
  - feedback (pass): "البابُ كبير — "the door is big." A whole sentence! أحسنت!"
- **On screen (new presentation):** instruction bar "Build the sentence"; a large
  replayable **audio card** auto-plays the sentence once; the child writes it word
  by word.
- **What we did:** **gated** — a full sentence needs several unlearned letters
  (laam, kaaf, yaa, raa). Node removed; filed for a later unit.
- **Recommendation — GATE.** Sentence-building fundamentally needs more of the
  alphabet. Re-introduce when the letters land. (Confirm.)

---

### 7. `baa.buildSentence.picture` — **GATED** (node removed)

- **Current content:**
  - a picture prompt (`img.big-door`)
  - expected words: `البابُ` , `كبير` ("the door is big")
  - letters: `alif, laam, baa, kaaf, yaa, raa` · **Unlearned: laam, kaaf, yaa, raa**
  - feedback (pass): "البابُ كبير — you wrote a sentence. أحسنت!"
- **On screen:** instruction bar "Build the sentence"; the picture as the stimulus;
  the child writes a describing sentence.
- **What we did:** **gated** — same as card 6, the sentence needs unlearned
  letters. Node removed; filed for a later unit.
- **Recommendation — GATE.** Same reasoning as card 6. (Confirm.)

---

## Summary table

| # | Card | Unlearned letters | Applied now | Recommendation |
|---|------|-------------------|-------------|----------------|
| 1 | `baa.connectWord.kitaab` | kaaf, taa | **Rewrite → `باب`** (`signedOff:false`) | Rewrite (pick `باب` / `بابا`), or gate |
| 2 | `baa.transformWord.dual` | noon | **Gated** | Gate (needs noon) |
| 3 | `baa.transformWord.plural` | waaw | **Gated** | Gate (needs waaw) |
| 4 | `baa.transformWord.opposite` | saad, ghayn, yaa, raa | **Gated** | Gate (all unlearned) |
| 5 | `baa.fillBlank.adjective` | kaaf, yaa, raa | **Gated** | Gate (or rewrite if an alif+baa adjective fits) |
| 6 | `baa.buildSentence.hear` | laam, kaaf, yaa, raa | **Gated** | Gate (needs many letters) |
| 7 | `baa.buildSentence.picture` | laam, kaaf, yaa, raa | **Gated** | Gate (needs many letters) |

**Result:** the baa unit now uses only **alif + baa**, enforced automatically by a
build test (the learned-letters lint, QP-07) so a card demanding an unlearned
letter can never quietly slip back in.

---

## Numbering reconciliation (A5 / D-21)

The owner referred to these cards by a hand-count shorthand — **"№ 10, 15–20."**
The **enforceable identity is the `letters` field**, not the numbering: a build
test reads each card's `letters` and flags any that exceed the learned set. That
lint flags **exactly these 7 cards** — no more, no fewer. Please confirm during
the sitting that your "№ 10, 15–20" list matches the 7 cards above.

| Owner's № (shorthand) | Best-guess card (by baa question order) | In the lint's 7-card flag set? |
|---|---|---|
| № 10 | `baa.connectWord.kitaab` (the "book" join) | ✅ yes (card 1) |
| № 15 | `baa.transformWord.dual` | ✅ yes (card 2) |
| № 16 | `baa.transformWord.plural` | ✅ yes (card 3) |
| № 17 | `baa.transformWord.opposite` | ✅ yes (card 4) |
| № 18 | `baa.fillBlank.adjective` | ✅ yes (card 5) |
| № 19 | `baa.buildSentence.hear` | ✅ yes (card 6) |
| № 20 | `baa.buildSentence.picture` | ✅ yes (card 7) |

- The № column is a best-effort mapping of the owner's shorthand onto the baa
  question order; the letters-field lint is the source of truth.
- **If any card you flagged is NOT in this list** (i.e. the lint marks its
  `letters` as clean alif+baa), please point it out — we will re-check that card's
  `letters` field with you. And **if a card here is one you consider fine**, say
  so and we will reconsider its disposition.

---

## What you sign

- **Confirm each disposition** above (rewrite vs gate), edit any word you want.
- For any card you approve as final baa content, we flip its `signedOff` to `true`
  (today only `baa.connectWord.kitaab` is a live baa card awaiting your sign-off;
  the 6 gated cards stay dormant until their own letters' units).
- This is documentation only — **no `signedOff` flips happen without you.**
