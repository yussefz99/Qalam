# Baa-family Authoring Sketch — for sign-off with the owner's mother

**Status:** DRAFT / PROVISIONAL — nothing here is signed off.
**Purpose:** Pre-fill Phase 4 / Plan 04-06 (`baa ب`, `taa ت`, `thaa ث`) from the mother's
curriculum materials so the in-person session with her is a *review-and-correct*, not a
*start-from-blank*. Alif (already signed off in Phase 02.1) is shown as the exemplar.

> **The rule this respects (CLAUDE.md):** *"Stroke order, how many clean reps advance a
> child, the 3–4 most common mistakes per letter… come from her — not from research or
> guesswork. Do not invent the pedagogy; structure it."* So below, every value is tagged:
>
> - **[HER]** = grounded in her Drive materials (cited).
> - **[DRAFT]** = my proposal from standard Arabic letterforms + the app's alif pattern — **she confirms or corrects.**
> - **[DEVICE]** = cannot be finalized on paper; must be traced/tuned on a tablet with her.

---

## Source materials (her Google Drive, owner `fedaa065@gmail.com`)

| File | What it gave us |
|------|-----------------|
| `أ - ب - ت - ث.docx` | Letter-intro order, example words per letter, her teaching activities |
| `املاء ء ا ب ت ث ج ح خ.docx` | Dictation set confirming baa-family is the first written group |
| `تاء وعي صوتي.docx` | Taa phonemic-awareness framing |
| `تنقيط جميع الحروف.pdf` | Tracing practice rows (confirms sequence; stroke shapes are images) |
| `كراسة حروف مرحلة 1.pdf`, `منهاج محتلن.pdf` | Stage-1 scope / sequence |

**What the text gave us (reliable):** the letter sequence and the example vocabulary.
**What it did NOT give us (images / in her head):** exact stroke order, stroke direction,
and her real list of the mistakes she sees children make. Those are the **[DRAFT]/[DEVICE]**
rows below — the heart of the review with her.

### Her letter-introduction order **[HER]**
From the "حُروفُ لُغَتي" table: **ء · ب · ت · ث · ج · ح · خ · د · ذ · ر · ز · س · ش · ص · ض · ط · ظ · ع · غ · ف · ق · ك · ل · م · ن · ه · و · ا · ي**
→ This matches the app's current `introOrder` for the baa-family (baa=2, taa=3, thaa=4). ✓ No change needed.

---

## How the app stores a letter (so the review maps 1:1 to the data)

Each letter in `assets/curriculum/letters.json` carries:
- `referenceStrokes[]` — ordered strokes, each a list of normalized `[x, y]` points in a
  `0..1` box (x: 0=left→1=right; y: 0=top→1=bottom), a `type` (`line` or `dot`), and a
  `direction`. **Dots are their own stroke: `type:"dot"`, one point, `direction:"tap"`,
  and come AFTER the body stroke.**
- `commonMistakes[]` — each has an `id`, a `check` (must match a scorer predicate name,
  table below), and `feedback` (the tutor's warm, specific voice).
- `tolerances` — `{"preset": "loose|normal|strict"}` + optional numeric overrides. **Data,
  not code** — tuning these is exactly Plan 04-06 Task 3.
- `signedOff` — flips to `true` ONLY after she signs off.

### The mistake `check` strings the scorer understands
| `check` value | Fires when | Maps to |
|---|---|---|
| `strokeLengthBelowThreshold` | body stroke too short | tooShort |
| `strokeDirectionInverted` | drawn the wrong way along its path | wrongDirection |
| `strokeCurvatureExceedsThreshold` | too curvy / not curvy enough vs reference | tooCurved |
| `strokeCountMismatch` | wrong number of strokes (e.g. body with no dot) | wrongStrokeCount |
| `strokeOrderWrong` | dot drawn before body, etc. | wrongStrokeOrder |
| `dotPositionWrong` / `dotCountWrong` | dot on wrong side / wrong number of dots | dotMisplaced |
| `letterIdentityMismatch` | ML Kit says it's a different letter (advisory) | wrongLetterIdentity |

---

## Alif — the signed-off exemplar (reference only, do not re-author)

- 1 stroke, `type:line`, top→bottom, straight. Mistakes: too short / wrong direction / too curved.
- This is the shape and tone every baa-family entry below is modelled on.

---

## ب — Baa

| Field | Value | Tag |
|---|---|---|
| Example words | باب (door), كلب (dog), دب (bear), كوب (cup) | **[HER]** (from `أ-ب-ت-ث.docx`) |
| Stroke count | 2 — one body, one dot | **[DRAFT]** |
| Stroke 1 (body) | shallow bowl/"boat", drawn **right → left**, dips low in the middle and lifts slightly at the left end | **[DRAFT]** |
| Stroke 2 (dot) | **one** dot **below** the body, near centre — the defining mark vs taa/thaa | **[DRAFT]** |
| Reference coordinates | body ≈ `[[0.80,0.42],[0.62,0.55],[0.50,0.60],[0.34,0.55],[0.20,0.44]]`; dot ≈ `[[0.50,0.82]]` | **[DEVICE]** — approximate; she traces the real path on the authoring screen |
| Tolerance preset | `normal` (start), lean → `loose` if good-faith kids get rejected | **[DEVICE]** (tuned on real samples) |
| Clean reps to advance | 3 (current default) | **[HER?]** confirm |

**Draft common mistakes (her voice — confirm wording & whether these are the *real* top ones):**
1. `dotCountWrong` / `dotPositionWrong` — *"Baa has just one dot, and it sits **under** the boat. Put a single dot below."* **[DRAFT]**
2. `strokeCountMismatch` — *"Don't forget the dot — baa is the boat **and** one dot underneath."* **[DRAFT]**
3. `strokeOrderWrong` — *"Draw the boat first, then add the dot underneath."* **[DRAFT]**
4. (body shape) `strokeCurvatureExceedsThreshold` — *"Make the boat a gentle, shallow curve — not too deep."* **[DRAFT]**

---

## ت — Taa

| Field | Value | Tag |
|---|---|---|
| Example words | بنت (girl), حوت (whale), توت (berry), تمساح (crocodile) | **[HER]** |
| Stroke count | 3 — one body, **two** dots | **[DRAFT]** |
| Stroke 1 (body) | same boat as baa, right → left | **[DRAFT]** |
| Strokes 2–3 (dots) | **two** dots **above** the body, side by side | **[DRAFT]** |
| Reference coordinates | body same as baa; dots ≈ `[[0.40,0.16]]` and `[[0.60,0.16]]` | **[DEVICE]** |
| Tolerance preset | `normal` (start) | **[DEVICE]** |

**Draft common mistakes:**
1. `dotPositionWrong` — *"Taa's two dots go **above** the boat, not below — that below-dot is baa."* **[DRAFT]** *(this is the baa↔taa confusion the scorer must hold firm on)*
2. `dotCountWrong` — *"Taa has **two** dots on top. Count them: one, two."* **[DRAFT]**
3. `strokeOrderWrong` — *"Boat first, then the two dots on top."* **[DRAFT]**
4. `strokeCurvatureExceedsThreshold` — *"Keep the boat shallow and smooth."* **[DRAFT]**

---

## ث — Thaa

| Field | Value | Tag |
|---|---|---|
| Example words | ثعلب (fox), مثلث (triangle), ثلج (snow), ثوم (garlic) | **[HER]** |
| Stroke count | 4 — one body, **three** dots | **[DRAFT]** |
| Stroke 1 (body) | same boat, right → left | **[DRAFT]** |
| Strokes 2–4 (dots) | **three** dots **above**, in a little triangle (two below, one above the pair) | **[DRAFT]** |
| Reference coordinates | body same; dots ≈ `[[0.40,0.18]]`, `[[0.60,0.18]]`, `[[0.50,0.07]]` | **[DEVICE]** |
| Tolerance preset | `normal` (start) | **[DEVICE]** |

**Draft common mistakes:**
1. `dotCountWrong` — *"Thaa has **three** dots on top, like a little triangle. Count: one, two, three."* **[DRAFT]**
2. `dotPositionWrong` — *"All three dots go **above** the boat."* **[DRAFT]**
3. `strokeOrderWrong` — *"Boat first, then the three dots."* **[DRAFT]**
4. `strokeCurvatureExceedsThreshold` — *"Shallow, smooth boat — same as baa and taa."* **[DRAFT]**

---

## The baa ↔ taa ↔ thaa distinction (why the scorer cares)

All three share the **same body**; only the **dots** differ (below×1 / above×2 / above×3).
The scorer already normalizes the whole letter together (combined bounding box) so it can
tell a below-dot from an above-dot. The calibration must keep **"wrote taa when shown baa"
firmly rejected** while accepting good-faith size/wobble variation — that's the SC#1/SC#3
tension Plan 04-06 tunes on real samples.

---

## ✅ Sign-off checklist — to do **with her** (and on a tablet)

For **each** of baa / taa / thaa:

1. **Stroke order & direction** — does she draw the body right→left? Does she add dots
   after the body, or some other order? **[confirm/correct the [DRAFT] above]**
2. **Trace the real reference stroke** on `/dev/authoring` on the tablet (replaces my
   approximate **[DEVICE]** coordinates). Mirror the alif overlay sign-off from Phase 02.1.
3. **Her real top 3–4 mistakes** — are my **[DRAFT]** mistakes the ones she actually sees?
   Reword the feedback in her voice. (A little Arabic welcome, e.g. أحسنت.)
4. **Dots:** confirm count + side (baa 1 below, taa 2 above, thaa 3 above).
5. **Capture labeled child samples** (good / wrong-order / wrong-count / scribble /
   wrong-letter / taa-when-shown-baa) — ~15–20 per category, on the tablet. **[DEVICE]**
6. **Tune tolerances** with her against those samples (lean encouraging) — **[DEVICE]**.
7. **`signedOff: true`** only after 1–6 are done and she's happy.

**Anything not on a tablet** (1, 3, 4) we can settle on paper at the meeting; **2, 5, 6**
need the device. A phone works if no tablet — finger strokes from real kids still beat the
emulator (which tunes the scorer too strict).

---

## What I can wire up *now* (provisional, before the meeting), if you want

I can pre-populate `letters.json` for baa/taa/thaa with the **[DRAFT]** strokes + mistakes,
set `mistakesStatus:"authored"` but keep **`signedOff:false`** and `tolerances:"loose"`
(encouraging), so:
- the rest of the app (Phase 5/6 work) stops being blocked on empty letters, and
- the meeting becomes "trace over my draft and correct it," which is faster.

This would run through the GSD Plan 04-06 path (Task 2) so tests + tracking stay in sync —
it does **not** fake her sign-off (that stays `false` until she signs).
