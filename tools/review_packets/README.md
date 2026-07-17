# `tools/review_packets/` — sign-off review packets

Makes the owner's-mother's letter review take **minutes, not half an hour**. For
every letter still `signedOff: false` in `assets/curriculum/letters.json`, it
generates one self-contained, printable, RTL-correct HTML page.

## What each packet shows

- the letter char + name and its **four positional forms** (isolated / initial /
  medial / final);
- the drafted `referenceStrokes` as **SVG**, with **stroke-order numbers and
  direction arrows**, plus a plain-language stroke legend (order · part · type ·
  direction), auto-fitted so it's legible;
- the `commonMistakes` in the tutor's voice, and `cleanRepsToAdvance`;
- a per-section **review checklist** (approve / needs-correction + notes), and a
  reviewer name/date line.

Every page is stamped **DRAFT — model-authored, awaiting review**.

## Run

From the `tools/` directory:

```bash
python -m review_packets
```

Writes `docs/curriculum/review-packets/<introOrder>-<letterId>.html` (e.g.
`04-thaa.html`) plus `index.html`, ordered by intro order. Regenerable any time
from `letters.json`; signed letters (currently baa, taa) are skipped.

## Notes

- **Self-contained**: inline CSS, inline SVG, no external assets or scripts —
  open the file directly or print it. Arabic uses the reviewer's system Arabic
  font (Noto Naskh / Amiri / …).
- The SVG stroke geometry is a **model draft**. As the baa-family sketch notes,
  the visible glyph a child traces comes from the app font — these strokes only
  drive the stroke-order animation and the scoring centerline. The reviewer's
  job is to fix the stroke *order / direction / count* and the *mistakes*, then
  sign off.
- Read-only against the curriculum; it never modifies `letters.json`.
