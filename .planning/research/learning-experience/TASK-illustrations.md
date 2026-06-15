# CREATIVE TASK (for the partner + agent): Qalam vocab illustration system + interim art

**Owner of this task:** Partner (running an agent).
**Why now:** the curriculum inventory you just produced holds the full vocab list. Illustrations
are the other long-lead Phase 8 asset (like audio) and **block nothing** on the engine or
content-authoring tracks — so this is the ideal creative work to run in parallel.

**Goal:** Design a consistent, child-friendly **illustration identity** for Qalam, then generate a
**placeholder image for every vocab word** in the inventory — named by `imageId`, **swappable**
later for final art (same pattern as the interim audio). Interim AI art now; real art drops in by
replacing the file, no code change.

---

## The creative part (do this first — it's the point)
Define Qalam's **art style**, aligned to the design system, and write it down as a short
`ILLUSTRATION-STYLE.md`:
- Read `docs/design/kit/project/colors_and_type.css` + `docs/design/kit/project/screenshots/` —
  match the **parchment/ink palette**, warm, rounded, calm, dignified ("Real Arabic. Not a game.").
- Decide a single coherent look (e.g. soft flat illustration, limited palette, consistent line
  weight, no busy backgrounds, friendly but not cartoonish-hyper). One style, applied to all words,
  so the app feels unified.
- Capture it as a reusable **style prompt** (the exact text you feed the image model for every word)
  so all ~150 images look like one set, not 150 random styles.

## Then generate
1. **Build the word→imageId list** from `CONTENT-INVENTORY.json` — every `vocab` word across all
   letters (dedupe; e.g. باب, أرنب, تفاح, …). `imageId` convention: `img.<translit>` (e.g.
   `img.baab`, `img.arnab`) — match the ids already used in `EXERCISE-CONFIGS.json` where they exist.
2. **Generate one image per word** using **Codex's built-in image generation** + your style prompt +
   the word's meaning (use the English gloss so "باب" → a door, "أرنب" → a rabbit).
   **Consistency technique (critical):** generate **2–3 reference images first**, lock the one whose
   style you like, then generate every other word **anchored to that style/reference** (reuse the
   exact style prompt, same palette/line-weight/background) so all ~150 read as ONE set — not 150
   different styles. Fixed canvas size + a plain parchment or transparent background for all.
3. **Output:** `assets/images/<imageId>.webp` (small, optimized) + a manifest
   `assets/images/manifest.json` (`imageId → {word, gloss, file}`).
4. **Flag** abstract/hard-to-draw words (colors, prepositions, grammar words) in the manifest as
   `needsReview:true` — don't force a bad picture; the mother decides those.

---

## Canonical refs (read first)
- `.planning/research/learning-experience/CONTENT-INVENTORY.json` — the vocab source (your own output).
- `docs/design/kit/project/colors_and_type.css` + `screenshots/` — the palette/feel to match.
- `.planning/research/learning-experience/SCHEMA-V2.md` — the `imageId` field these map to (`prompt.image`).
- `docs/design/prototypes/letter-unit-baa/EXERCISE-CONFIGS.json` — existing `imageId`s (e.g. `img.duck`, `img.door`) to stay consistent with.

## Guardrails
- **One consistent style** across all images (that's the whole value — a unified set).
- **Placeholders, swappable by `imageId`** — same pattern as audio; final art replaces files later.
- **Don't touch** `lib/`, the schema, the engine, or the content drafts — this task only adds
  `assets/images/*` + the style guide + manifest.
- Commit **optimized small webp** (not multi-MB PNGs); if the set is heavy, gitignore the raw
  generations and commit only the optimized finals + manifest.
- Match `imageId`s to those already in `EXERCISE-CONFIGS.json`; for new words, use `img.<translit>`.

## Acceptance criteria
- `ILLUSTRATION-STYLE.md` defines one coherent style + the reusable style prompt.
- Every vocab word in the inventory has an `assets/images/<imageId>.webp` (or is flagged `needsReview`).
- `assets/images/manifest.json` maps `imageId → word → file` for all of them.
- The set looks like **one unified style**, matches the parchment/ink palette, and is child-friendly.

---

## Paste-ready agent prompt (partner runs this)

> Read `.planning/research/learning-experience/TASK-illustrations.md` and do it. First define
> Qalam's illustration style aligned to `docs/design/kit/project/colors_and_type.css` and the
> screenshots (parchment/ink, warm, rounded, calm — "Real Arabic. Not a game."), and write it as
> `ILLUSTRATION-STYLE.md` with one reusable style prompt. Using **your built-in image generation**,
> generate **2–3 reference images first**, lock the best style, then extract every vocab word from
> `CONTENT-INVENTORY.json` and generate one placeholder image per word **anchored to that locked
> style** (same prompt/palette/background/canvas), named `assets/images/img.<translit>.webp`, plus
> `assets/images/manifest.json`. Match existing `imageId`s in
> `docs/design/prototypes/letter-unit-baa/EXERCISE-CONFIGS.json`. Keep ONE consistent style across
> all images, optimize file sizes, flag abstract words `needsReview`, and don't touch engine code,
> the schema, or the content drafts.
