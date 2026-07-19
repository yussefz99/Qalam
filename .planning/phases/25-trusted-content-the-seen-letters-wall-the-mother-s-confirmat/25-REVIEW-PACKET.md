# Phase 25 — The Mother's Re-Confirmation Packet

**For:** the owner's mother (the curriculum authority — CUR-01)
**Read by:** the owner, aloud, sitting next to her (D-11 — live walkthrough)
**Assembled:** 2026-07-19 · non-blocking (D-12)

**Purpose.** Since you last signed off on baa (the tier-level graph sign-off, 2026-06-28
— 15-HUMAN-UAT), the owner made a set of content changes to get the app ready for the
Technion submission and demo. **Every one of those changes is listed below, one row at a
time, with a place to mark your verdict on the spot.** Nothing here decides the pedagogy
— *you* do. The owner reads each item, you say **confirm**, **reject**, or **rework** (with
your correction), and he writes it down. That is the whole sitting.

---

## Read this first — it is NON-BLOCKING (D-12)

- **Nothing here blocks the deadline.** The app already ships in a safe, honest state.
  The "seen-letters wall" (built this phase) guarantees a child is *never shown* a question
  that demands a letter they have not met yet — at four independent layers (the build check,
  the lint, the Firestore seeder, and the live app itself). So even the questions you have
  **not** yet approved cannot reach a child who hasn't learned their letters.
- **Your verdicts land as edits + a sign-off flip.** When you **confirm** an item, the owner
  flips that content's `signedOff` flag from `false` → `true` — the same 15-07 / 17-10
  pattern your baa tier sign-off used. **Only you** set `signedOff: true` on curriculum
  content; no automated step ever does. When you **reject** or **rework**, the owner restores
  or changes the content to your instruction (that ingestion is the next plan, 25-07).
- **"Kept live as an exception" means:** a question uses a letter that comes *later* in the
  intro order, but the owner chose to keep it in the unit because **the app is for children
  who already know Arabic by ear** — they can say the word even before they can write every
  letter in it. Every such question is waiting on **your** yes/no. This is your call to make.
- **Honest flags during this sitting.** While assembling this packet, baa's sign-off flag was
  set back to `false` (and so were baa's four exception questions) — because baa's *live*
  content drifted from what you signed (see Group A and Group F). This is deliberate: the flag
  should never claim "the mother confirmed this" while the content is different from what you
  saw. As you confirm each item, it flips back to `true`. The "false" window is just this
  sitting.

**How each question looks to the child now (context for the notes below):** every graded
question shows a short **instruction bar** at the top (with a speaker to tap and hear it
again), a **big clear stimulus** (a picture, a replayable audio card, or the word to copy),
and — for tracing — a dotted letter to follow. The spoken line is a reminder, never the only
clue.

**Your verdict, every row, is one of:** **confirm / reject / rework: ______**
(confirm = keep as shown · reject = remove it · rework = change it, tell the owner how).

---

## Group A — Clean reps per skill (how many good tries before a skill is "done")

You signed this rule for baa on 2026-06-28: **"Writing & tracing = 3 clean reps; lighter
exercises stay at 1."** So the tracing and writing skills required **3** clean repetitions
before they counted as cleared, and the lighter questions (meet-the-letter, fill-in-the-blank,
the grammar transforms) required **1**.

**What changed:** for the demo build, **every** baa skill was set to **1 clean rep** — including
the tracing and writing skills you signed at **3**. This made the demo shorter. The other three
units built since (alif, taa, thaa) were authored at **1** across the board and have never been
signed by you at all.

| Unit | Your signed spec | Live in the app today | Divergence |
|---|---|---|---|
| baa | writing/tracing = **3**, lighter = **1** | **all skills = 1** | writing & tracing dropped 3 → 1 |
| alif | (not yet signed) | all = 1 | your call |
| taa | (not yet signed) | all = 1 | your call |
| thaa | (not yet signed) | all = 1 | your call |

- **The owner's recommendation:** decide the number you want. If you want baa's writing/tracing
  back at **3** (as you signed), say so and the owner restores it. If **1** is fine for now (a
  gentler demo), confirm it. Whatever you set for alif/taa/thaa becomes their first signed spec.
- **Note (server):** if you restore baa's writing/tracing to **3**, that baa graph change also
  needs the tutor server's copy re-generated and re-deployed — a separate owner-authorized step,
  not automatic.

> **A1 — baa writing/tracing clean-reps (signed 3 → live 1).**
> **Your verdict:** confirm 1 / restore to 3 / rework: __________________________________

> **A2 — alif / taa / thaa clean-reps (currently 1 each, never signed).**
> **Your verdict:** confirm 1 / set a number / rework: ____________________________________

---

## Group B — Sentence-building questions removed from the live units

Six "build the whole sentence" questions were taken **out** of the live units for the demo
(baa ×2, taa ×2, thaa ×2). They still exist in the content file but are **dormant** — not shown
to any child. A sentence needs many letters at once, so most of these reach far past the unit's
own letter.

| Removed question | Unit | Sentence | Why removed |
|---|---|---|---|
| `baa.buildSentence.hear` | baa | البابُ كبير ("the door is big") | needs laam, kaaf, yaa, raa |
| `baa.buildSentence.picture` | baa | البابُ كبير | same |
| `taa.buildSentence.hear` | taa | التاجُ جميل ("the crown is pretty") | needs jeem, laam, meem, yaa |
| `taa.buildSentence.picture` | taa | التفاحُ جميل ("the apple is pretty") | needs faa, haa_c, jeem, laam, meem, yaa |
| `thaa.buildSentence.hear` | thaa | الثعلبُ كبير ("the fox is big") | needs ayn, laam, kaaf, yaa, raa |
| `thaa.buildSentence.picture` | thaa | الثعلبُ جميل ("the fox is pretty") | needs ayn, laam, jeem, meem, yaa |

- **The owner's recommendation:** keep these removed for these early units (a whole sentence is a
  lot for a child on their 2nd–4th letter), and re-introduce sentence work later once more letters
  are known. But if you want any of them back in, say which.

> **B1 — the two baa sentence questions removed** (`baa.buildSentence.hear`, `baa.buildSentence.picture`).
> **Your verdict:** confirm removal / bring back / rework: ________________________________

> **B2 — the taa & thaa sentence questions removed** (`taa.buildSentence.hear`, `taa.buildSentence.picture`; `thaa.buildSentence.hear`, `thaa.buildSentence.picture`).
> **Your verdict:** confirm removal / bring back / rework: ________________________________

---

## Group C — alif is now letter-level only + a new alif picture question

**The shrink.** alif is a child's **first** letter. The owner narrowed the alif unit to
letter-level work only — hear it, trace it, write its form, and name what a word **starts with**
— with **no** word-copying, sentence, or grammar questions. (alif still has copy/dictation
practice questions; see Group D for their wording.)

**The new question — `alif.writeLetter.fromPicture`** (a **draft**, `signedOff:false`, awaiting you).
This is a real, new card modeled on the taa version. Here is exactly what the child sees:

- **Instruction (spoken + shown):** "Write the letter this picture's word starts with."
- **Picture:** a **lion** (`img.lion.webp`), captioned **أسد**.
- **The child writes:** the letter **ا** (alif).
- **If right:** "Yes — أسد starts with ا. أحسنت!"
- **If wrong letter:** "Listen: أَسَد — ah… it starts with alif. Write ا."
- **If unclear:** "Almost — draw alif tall and straight, top to bottom."

- **The owner's recommendation:** confirm the wording and the لion → أسد pairing, or rework the
  word/art (e.g. if you'd rather the picture be أرنب "rabbit" to match the meet-the-letter card in
  Group D). This card is a draft until you approve it — only then does it go live-signed.

> **C1 — alif narrowed to letter-level only (no word/sentence/grammar in the alif unit).**
> **Your verdict:** confirm / reject / rework: __________________________________________

> **C2 — the new `alif.writeLetter.fromPicture` draft (lion → أسد → write ا).**
> **Your verdict:** confirm / reject / rework: __________________________________________

---

## Group D — Picture swaps and feedback wording fixes (the "Lane-B" changes)

These changes did **not** alter which letter a child writes — they fixed a **picture** (we only
have certain illustrations drawn) or **reworded feedback** that didn't match what's on screen.
Each carries a note in the content file; they are listed here verbatim so you can confirm the
example word, the art, and the wording.

| # | Question | Change | What to confirm |
|---|---|---|---|
| D-a | `taa.teachCard.meet` | example word **تاج → تفاح** (no crown art exists; the apple art does; تفاح also starts with taa) | example word + apple art |
| D-b | `taa.writeLetter.fromPicture` | picture word **تاج → تفاح** (letter written is unchanged) | apple art + word |
| D-c | `taa.writeWord.picture` | word **بيت → تفاح** (no house art; apple art exists; تفاح needs fewer far-off letters) | word + art (بيت still practiced in `taa.connectWord.bayt`) |
| D-d | `taa.buildSentence.picture` | sentence **البيتُ كبير → التفاحُ جميل** (no house art; apple art exists) — *this question is currently removed (Group B)* | sentence + art, if reinstated |
| D-e | `taa.writeWord.dictation` | feedback reworded — it said "look at the picture" but dictation shows **no** picture (it's listening) | corrected wording |
| D-f | `taa.writeWord.copy` | feedback reworded — it said "from memory / look at the picture" but copy **shows** the word | corrected wording |
| D-g | `alif.teachCard.meet` | example word **أسد → أرنب** (no lion art in the meet card; the rabbit art exists; أرنب starts with alif) | example word + rabbit art |
| D-h | `alif.writeWord.dictation` | feedback reworded to listening (same fix as D-e) | corrected wording |
| D-i | `alif.writeWord.copy` | feedback reworded to the copy-card house style (same fix as D-f) | corrected wording |

> **D1 — the picture swaps** (`taa.teachCard.meet`, `taa.writeLetter.fromPicture`, `taa.writeWord.picture`, `taa.buildSentence.picture`, `alif.teachCard.meet`).
> Note: `alif.teachCard.meet` uses **أرنب** (rabbit) while the new C2 card uses **أسد** (lion) — confirm you're happy with the two different alif example words, or align them.
> **Your verdict:** confirm / reject / rework: __________________________________________

> **D2 — the feedback rewordings** (`taa.writeWord.dictation`, `taa.writeWord.copy`, `alif.writeWord.dictation`, `alif.writeWord.copy`).
> **Your verdict:** confirm / reject / rework: __________________________________________

---

## Group E — The full word/label diff (every word that changed, old → new)

For completeness, here is every question whose **word** or **letter-label** was changed since your
last sign-off, in one place — so you can scan the before/after at a glance. (These are the same
changes detailed in Group D, plus one label correction, gathered into a single diff table.)

| Question | Old | New | Kind of change |
|---|---|---|---|
| `taa.teachCard.meet` | تاج | تفاح | example word (art) |
| `taa.writeLetter.fromPicture` | تاج | تفاح | picture word (letter unchanged) |
| `taa.writeWord.picture` | بيت | تفاح | word swap (art) |
| `taa.buildSentence.picture` | البيتُ كبير | التفاحُ جميل | sentence swap (art) |
| `taa.completeWord.middle` | letters `[taa]` | letters `[taa, waaw]` | **label fix** — توت truly contains waaw; the label had dropped it. No word change; the truthful spelling is now recorded. |

- **On `taa.completeWord.middle`:** this was only a *bookkeeping* correction — the word توت ("berries")
  was always the same on screen; its letter list was simply completed to include **waaw**. Because
  توت contains waaw (a much later letter), this question then correctly shows up as a "reaches ahead"
  question — see Group F, where you rule on it.

> **E1 — the word/label diff above (old → new).**
> **Your verdict:** confirm / reject / rework: __________________________________________

---

## Group F — Questions kept live that use a letter from later in the order

This is the heart of the sitting. The owner chose to keep **22 questions** live even though each
uses at least one letter that comes **later** than its unit — **because the app is built for
children who already know these words by ear** ("I don't want each unit to have only a few
questions"). None of these can reach a child who hasn't learned the letters (the wall handles
that), but **each one needs your yes/no** to become truly mother-approved. They split into two
groups by where the decision came from.

### F-1 · The 4 baa questions (from the device test, 2026-07-18 — **not yet mother-approved**, D-09)

These four were kept live after the owner's own device testing, but **you have not seen them**. Per
the rule, each must become **mother-approved, or be re-pointed to an easier word, or removed.**

| # | Question | On screen | Reaches ahead to |
|---|---|---|---|
| F1-a | `baa.fillBlank.adjective` | البابُ ___ → fill in **كبير** ("big") | raa, kaaf, yaa |
| F1-b | `baa.transformWord.dual` | باب → **بابان** ("two doors") | noon |
| F1-c | `baa.transformWord.plural` | باب → **أبواب** ("many doors") | waaw |
| F1-d | `baa.transformWord.opposite` | كبير → **صغير** ("small") | raa, saad, ghayn, yaa |

- Each needs **mother approval, OR a re-point to a learned-letter word, OR removal.** There is no
  alif+baa-only dual, plural, opposite, or describing word — so if you don't approve one, it would
  be **removed** from the baa unit until its letters are taught. The owner's lean: these teach real
  grade-1 grammar a heritage child hears at home; keep them if you're comfortable.

> **F1-a — `baa.fillBlank.adjective`** (البابُ ___ / كبير). needs mother approval or re-point/remove.
> **Your verdict:** confirm / reject / rework: __________________________________________
>
> **F1-b — `baa.transformWord.dual`** (باب → بابان). needs mother approval or re-point/remove.
> **Your verdict:** confirm / reject / rework: __________________________________________
>
> **F1-c — `baa.transformWord.plural`** (باب → أبواب). needs mother approval or re-point/remove.
> **Your verdict:** confirm / reject / rework: __________________________________________
>
> **F1-d — `baa.transformWord.opposite`** (كبير → صغير). needs mother approval or re-point/remove.
> **Your verdict:** confirm / reject / rework: __________________________________________

### F-2 · The 18 taa & thaa questions (owner decision, 2026-07-19 — D-16)

The owner kept these live because re-pointing them was impossible — **no** word exists that
contains taa (or thaa) and uses only letters taught by that unit. Removing them all would gut the
taa and thaa units down to almost nothing. Each still needs **your** confirmation.

| # | Question | Word | Reaches ahead to |
|---|---|---|---|
| F2-a | `taa.writeWord.dictation` | تاج ("crown") | jeem |
| F2-b | `taa.writeWord.copy` | توت ("berries") | waaw |
| F2-c | `taa.writeWord.picture` | تفاح ("apple") | haa_c, faa |
| F2-d | `taa.connectWord.taaj` | تاج | jeem |
| F2-e | `taa.connectWord.bayt` | بيت ("house") | yaa |
| F2-f | `taa.completeWord.middle` | توت | waaw |
| F2-g | `taa.fillBlank.adjective` | تاج | jeem |
| F2-h | `taa.transformWord.dual` | تاجان ("two crowns") | jeem, noon |
| F2-i | `taa.transformWord.plural` | بيوت ("houses") | waaw, yaa |
| F2-j | `taa.transformWord.opposite` | فوق ("above") | faa, qaaf, waaw |
| F2-k | `thaa.writeWord.dictation` | ثعلب ("fox") | ayn, laam |
| F2-l | `thaa.writeWord.copy` | ثلج ("snow") | jeem, laam |
| F2-m | `thaa.writeWord.picture` | ثعلب | ayn, laam |
| F2-n | `thaa.connectWord.thalab` | ثعلب | ayn, laam |
| F2-o | `thaa.connectWord.thalj` | ثلج | jeem, laam |
| F2-p | `thaa.completeWord.middle` | ثوم ("garlic") | meem, waaw |
| F2-q | `thaa.fillBlank.adjective` | ثعلب | ayn, laam |
| F2-r | `thaa.transformWord.dual` | ثعلبان ("two foxes") | ayn, laam, noon |

- **The owner's recommendation:** confirm the whole taa/thaa set (they're real, common words a
  heritage child knows aloud), or mark any single one to reject/rework. You can rule on them as a
  block ("all taa fine", "all thaa fine") or one at a time.

> **F2 (taa) — the 10 taa questions above** (`taa.writeWord.dictation/.copy/.picture`, `taa.connectWord.taaj/.bayt`, `taa.completeWord.middle`, `taa.fillBlank.adjective`, `taa.transformWord.dual/.plural/.opposite`).
> **Your verdict (block or per-row):** confirm / reject / rework: ________________________
>
> **F2 (thaa) — the 8 thaa questions above** (`thaa.writeWord.dictation/.copy/.picture`, `thaa.connectWord.thalab/.thalj`, `thaa.completeWord.middle`, `thaa.fillBlank.adjective`, `thaa.transformWord.dual`).
> **Your verdict (block or per-row):** confirm / reject / rework: ________________________

---

## Group G — thaa questions still waiting on YOUR word choice (placeholders)

Three thaa questions were left as **placeholders on purpose** because they need a native speaker's
judgment the owner would not guess at. They are marked "NEEDS THE MOTHER" in the content file.

| Question | What it needs from you |
|---|---|
| `thaa.transformWord.dual` | the regular sound-dual (+ان) → **ثعلبان** is a best-effort **draft** — confirm it's the right dual, or give the correct one |
| `thaa.transformWord.plural` | **no word yet** — broken plurals are irregular; please give the right plural for the base word |
| `thaa.transformWord.opposite` | **no word yet** — please choose an age-appropriate opposite pair |
| `thaa.buildSentence.hear` | adjective is a **draft placeholder** (كبير) — confirm the sentence + audio (this question is currently removed, Group B) |
| `thaa.buildSentence.picture` | adjective is a **draft placeholder** — confirm the sentence (currently removed, Group B) |

> **G1 — `thaa.transformWord.dual`** (draft ثعلبان). **Your verdict:** confirm / reject / rework: ____________
>
> **G2 — `thaa.transformWord.plural`** (needs your word). **Your verdict:** confirm / reject / rework: ____________
>
> **G3 — `thaa.transformWord.opposite`** (needs your pair). **Your verdict:** confirm / reject / rework: ____________
>
> **G4 — `thaa.buildSentence.hear` / `thaa.buildSentence.picture`** (draft adjective). **Your verdict:** confirm / reject / rework: ____________

---

## Summary table — every item, one line, mark as you go

| Row | Item | What to confirm | Verdict (confirm / reject / rework) |
|---|---|---|---|
| A1 | baa writing/tracing clean-reps | signed 3 → live 1 | |
| A2 | alif/taa/thaa clean-reps | currently 1 (unsigned) | |
| B1 | baa sentence questions removed | keep removed? | |
| B2 | taa/thaa sentence questions removed | keep removed? | |
| C1 | alif letter-level shrink | narrowed unit | |
| C2 | `alif.writeLetter.fromPicture` (new draft) | lion → أسد → ا | |
| D1 | picture swaps (taa ×4, alif ×1) | words + art | |
| D2 | feedback rewordings (taa ×2, alif ×2) | corrected lines | |
| E1 | word/label diff (old → new) | the diff table | |
| F1-a | `baa.fillBlank.adjective` | approve / re-point / remove | |
| F1-b | `baa.transformWord.dual` | approve / re-point / remove | |
| F1-c | `baa.transformWord.plural` | approve / re-point / remove | |
| F1-d | `baa.transformWord.opposite` | approve / re-point / remove | |
| F2·taa | 10 taa reach-ahead questions | approve / rework | |
| F2·thaa | 8 thaa reach-ahead questions | approve / rework | |
| G1 | `thaa.transformWord.dual` (draft) | confirm dual | |
| G2 | `thaa.transformWord.plural` | give the word | |
| G3 | `thaa.transformWord.opposite` | give the pair | |
| G4 | `thaa.buildSentence.hear/.picture` | confirm sentence | |

**Tally (fill in at the end):** total items: 19 rows · confirmed: ___ · rejected: ___ · reworked: ___ · left open: ___

---

## What you sign

- **Confirm each row** above (or reject / rework, with your correction). The owner marks the
  verdict inline as you speak.
- For every item you **confirm**, the owner later flips its `signedOff` from `false` → `true` — so
  the flag finally says the truth: *the mother reviewed this exact content.* baa's unit flag flips
  back to `true` once all its rows are confirmed.
- For every item you **reject or rework**, the owner removes or changes the content to your
  instruction, and it stays `signedOff:false` until you see the corrected version.
- **This is documentation only** — **no `signedOff` flag flips without you.** The wall keeps every
  child safe in the meantime, approved or not.

---

*Phase 25 · the seen-letters wall + the mother's confirmation · packet assembled 2026-07-19 (non-blocking, D-12) · ingestion is Plan 25-07.*
