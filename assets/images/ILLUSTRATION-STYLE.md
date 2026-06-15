# Qalam Illustration Style — `assets/images/`

The **one** visual identity for every vocab picture in Qalam. The whole value of
this set is that ~220 pictures read as **one calm, hand-made world**, not 220
clip-art styles. Generate every image with the *same* style prompt (below),
anchored to a locked reference, so a child flipping from باب (door) to أرنب
(rabbit) to تفاح (apple) never feels the art "jump."

> **Source of truth for feel:** `docs/design/kit/project/colors_and_type.css`
> (tokens) and `docs/design/kit/project/screenshots/`. This guide just restates
> them for the image model. If they ever disagree, the design kit wins.

---

## The feel in one line

**Soft flat illustration on warm parchment — a patient teacher's hand-drawn flash
card. Real Arabic, not a game.** Warm, rounded, calm, dignified. Friendly, never
hyper; clear, never busy; childlike, never babyish.

This is the same world as the **Qalam pencil mascot** (`assets/mascot/`): flat
teal shapes, gentle rounded forms, soft shadow, a quiet smile. The vocab pictures
are the props in *his* classroom.

---

## Locked visual rules (every image obeys all of these)

**Palette — ink & parchment (from the design tokens):**
- Background: parchment `#FAF6EE` *(never stark white)*, or transparent.
- Primary ink / line: deep teal-ink `#0E5B5F`.
- Accent fills, drawn from the kit only:
  `--ink-teal #168A8F`, `--leaf #3FB984`, `--coral #FF8A6B`, `--slate #5C6B70`.
- **`--gold-ink #F2A60C` is reserved for rewards — do NOT use it in vocab art.**
- 1–2 accent colours per picture, max. Subject may use its natural local colour
  (a red apple, a yellow banana) but **muted and slightly desaturated** to sit in
  the parchment world — no neon, no pure primaries.

**Line & shape:**
- One consistent line weight: a soft, rounded ink outline (`#0E5B5F`), medium
  thickness, **same weight on every image**. No hairlines, no variable calligraphy.
- Rounded corners and soft curves everywhere; nothing sharp or spiky.
- Flat fills with at most a single soft shade for gentle volume. **No gradients,
  no glossy highlights, no drop shadows on the object**, no 3D, no photo-realism.

**Composition:**
- **One subject, centered**, filling ~70–80% of the frame. Generous parchment
  margin. Nothing cropped at the edges.
- **Plain background only** — flat parchment or transparent. No scenes, no
  patterns, no horizon, no text, **no letters or words in the image** (the app
  draws the Arabic; the picture must never pre-spell the answer).
- Square canvas, **768×768**, exported to optimized **`.webp`**.

**Tone:**
- Friendly and concrete: a child instantly reads "that's a duck." Faces (animals,
  people) get a small calm smile — warm, not zany.
- Culturally neutral and gentle. No scary, sad, or violent depictions even when
  the word allows it (e.g. ذئب wolf, ثعبان snake → friendly, rounded, harmless).

---

## The reusable style prompt (feed this for EVERY word)

Paste verbatim; swap only the bracketed subject line. Same prompt, same palette,
same canvas, same background — that sameness *is* the deliverable.

```
A single [SUBJECT — e.g. "wooden door", "rabbit", "red apple"], centered, filling
about three-quarters of a square frame, for a children's Arabic handwriting app.

Style: soft flat illustration, hand-drawn children's flash-card look. One
consistent medium-weight rounded ink outline in deep teal (#0E5B5F). Flat fills
with at most one soft shade for gentle volume — no gradients, no gloss, no 3D, no
drop shadow, no photorealism. Warm, rounded, calm, dignified; friendly but not
hyper or cartoonish.

Palette: warm parchment background #FAF6EE; ink/lines #0E5B5F; accents chosen only
from teal #168A8F, green #3FB984, coral #FF8A6B, slate #5C6B70. The subject may use
its natural colour but muted and slightly desaturated to match this warm palette.
Use at most two accent colours. Do NOT use gold/yellow as a theme colour.

Composition: one subject only, centered, plain flat parchment background, no scene,
no pattern, no border, generous margin, nothing cropped. Absolutely NO text, NO
letters, NO words, NO numbers anywhere in the image. If the subject is an animal or
person, give it a small calm friendly smile; keep it gentle and never scary.

Square 768x768.
```

---

## Consistency procedure (do this in order — it is what makes the set ONE set)

1. **Reference round.** Generate **2–3 candidates** for a single anchor word —
   use **`باب` (door)** — with the prompt above. Pick the one whose line weight,
   parchment tone, and softness you like best. **Lock it.** Save it as
   `assets/images/_reference/anchor-door.webp` (the `_reference/` folder is the
   style yardstick, not shipped art).
2. **Anchor everything to it.** Generate every other word with the **same prompt**,
   same palette, same background, same 768×768 canvas, visually matched to the
   locked anchor (same line weight, same parchment, same softness). If your tool
   supports a style/reference image, pass the anchor every time.
3. **Spot-check in threes.** After each batch, view 3 unrelated images side by side
   (e.g. door / rabbit / apple). If one "jumps" — different line weight, brighter
   colour, busier background — regenerate it against the anchor before continuing.
4. **Name & place.** Save each as `assets/images/<imageId>.webp` using the
   `imageId` from `manifest.json`. Flip that entry's `status` from `"pending"` to
   `"generated"`.
5. **Skip the flagged words.** Anything `needsReview: true` in the manifest
   (colours, verbs, abstract/ambiguous words) — **do not draw**. Leave it pending;
   the owner's mother decides whether and how to depict it.
6. **Optimize.** Export small `.webp` (target < ~40 KB each). If raw generations
   are heavy, gitignore them and commit only optimized finals + `manifest.json`.

---

## Placeholder → final art (same pattern as `assets/audio/`)

These are **interim** pictures, swappable by `imageId`. Final art (commissioned or
owner-approved) drops in by **replacing `assets/images/<imageId>.webp` with the
same filename** — no code change, exactly like replacing a placeholder audio clip.
Keep `manifest.json` and the on-disk files in lockstep.

## Guardrails (from `TASK-illustrations.md`)

- **One style** across all images — that is the entire point.
- Additive only: this work touches **`assets/images/*` + this guide + the
  manifest**. It must not touch `lib/`, the schema, the engine, or content drafts.
- Match existing `imageId`s where they exist; see the **id-scheme conflict** note
  in `manifest.json._meta` (`img.door`/`img.duck`/`img.milk` vs `img.<translit>`)
  — an open owner decision.
