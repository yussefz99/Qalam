# Qalam Vocab Illustration Generation Progress

## What I Was Asked To Do

Generate placeholder vocab illustrations for Qalam using the existing locked sources:

- `assets/images/ILLUSTRATION-STYLE.md`
- `assets/images/manifest.json`

The task required one consistent illustration style, generated from the English `gloss` in the manifest, saved as optimized `.webp` files under `assets/images/`, with `manifest.json` kept in sync.

## Files I Read First

- `assets/images/ILLUSTRATION-STYLE.md`
  - Used as the source of truth for the visual style.
  - I did not redesign the style.
  - I used the reusable style prompt from this file.

- `assets/images/manifest.json`
  - Used as the source of truth for the image list.
  - It contains 221 total image entries.
  - 18 entries are marked `needsReview:true` and should stay pending.

- `C:\Users\yusse\.codex\skills\.system\imagegen\SKILL.md`
  - Confirmed that the default image generation path is the built-in `image_gen` tool.
  - Confirmed that project-bound generated images must be copied into the workspace.

## Anchor / Reference Image

The task said to lock a reference image first using the word `باب` / "door".

I generated a door candidate with the locked Qalam style prompt:

- Subject: `wooden door`
- Style: soft flat illustration
- Background: parchment
- Outline: deep teal
- No text, letters, numbers, or words

I inspected the generated door and accepted it as the anchor because it matched the intended style closely enough:

- centered subject
- warm parchment background
- teal outline
- calm flash-card feel
- no text

I saved it here:

- `assets/images/_reference/anchor-door.webp`

I also saved the same generated door as the actual vocab image for `img.baab`:

- `assets/images/img.baab.webp`

Both were optimized to small `.webp` files.

## Spot-Check Images

After the anchor, I generated two unrelated vocab subjects to check consistency:

- `rabbit`
- `red apple`

These were generated with the same locked style prompt, visually matching the anchor.

I saved them as:

- `assets/images/img.arnab.webp`
- `assets/images/img.tuffaah.webp`
- `assets/images/img.tuffaaha.webp`

The apple image was reused for both apple manifest entries:

- `img.tuffaah`
- `img.tuffaaha`

## Manifest Updates

I updated `assets/images/manifest.json` so these entries now have:

```json
"status": "generated"
```

Updated entries:

- `img.baab`
- `img.arnab`
- `img.tuffaah`
- `img.tuffaaha`

I did not change entries marked `needsReview:true`.

## Current Counts

After this partial generation pass:

- Total manifest entries: 221
- Generated entries: 4
- Pending drawable entries: 199
- Pending `needsReview:true` entries: 18
- `.webp` image files currently saved under `assets/images/`: 4
- Reference files saved under `assets/images/_reference/`: 1

## Files Added Or Edited

Added:

- `assets/images/_reference/anchor-door.webp`
- `assets/images/img.baab.webp`
- `assets/images/img.arnab.webp`
- `assets/images/img.tuffaah.webp`
- `assets/images/img.tuffaaha.webp`
- `assets/images/GENERATION-PROGRESS.md`

Edited:

- `assets/images/manifest.json`

No files outside `assets/images/` were changed for the illustration task.

## Important Limitation

The built-in image generation tool available in this environment generates one distinct prompt at a time.

That means the remaining 199 drawable vocab images cannot be produced as a true automated batch through the built-in tool alone. They can still be generated, but it would require many individual image generation calls.

The practical options are:

1. Continue generating images in smaller manual batches with the built-in image tool.
2. Use the CLI/API batch fallback, which requires `OPENAI_API_KEY` to be set locally.

## Confidence Notes

The generated door, rabbit, and apple are suitable as initial placeholders and visually consistent enough to establish the art direction.

The door has slightly more wood texture than the strictest interpretation of "flat fills", but it still matches the parchment/teal Qalam style and works as the current locked anchor unless the owner wants a flatter replacement.

No abstract or `needsReview:true` words were forced into images.

## Baa Unit Placeholder Batch

Updated after the baa-only generation request:

- Replaced `assets/images/_reference/anchor-door.webp` with the existing rabbit image (`assets/images/img.arnab.webp`) because the rabbit is the strongest current style reference: bold deep-teal outline, flat warm fills, parchment background, gentle face.
- Generated `assets/images/img.door.webp`: simple flat wooden door, bold teal outline, no wood-grain texture.
- Generated `assets/images/img.duck.webp`: cute friendly duck, muted palette, gentle expression.
- Generated `assets/images/img.big-door.webp`: noticeably tall/large door as a single centered subject for "the door is big."

All three generated files are 768x768 optimized WebP images, saved directly under `assets/images/`, with no text, letters, words, or numbers in the artwork.
