/* =============================================================================
   Qalam — Arabic letter stroke-order data
   28 letters in isolated form, with stroke paths, start-dots, and identifying
   marks (the diacritic dots that distinguish ب ت ث / ج ح خ / etc).

   Coordinates are in a 600×600 viewBox with the writing baseline ≈ y=400.
   Each letter has:
     glyph     - the Unicode glyph (for the faint reference layer)
     name      - English name (e.g. "Baa")
     romanized - simple transliteration for child-facing copy
     strokes   - array of SVG path commands, IN ORDER. Each entry is one stroke
                 (lift-the-pen between strokes). Animate them sequentially.
     starts    - array of {x, y, n} dots for numbered start markers
     marks     - array of {x, y, kind: 'dot' | 'tashdid'} for identifying marks
                 ('dot' renders as a small filled circle; for dot trios we list 3)

   NOTE: These paths are approximations of Naskh letterforms suitable for
   demonstrating stroke order. For production rendering of the *trace target*,
   replace with calligrapher-authored SVGs or a licensed dotted Arabic tracing
   font (e.g. Namela "Alif Baa Taa").
   ========================================================================= */

const LETTERS = {
  alif:  { glyph: 'ا', name: 'Alif',   romanized: 'alif',  strokes: ['M 300 100 L 300 500'], starts: [{ x: 300, y: 100, n: 1 }], marks: [] },
  baa:   { glyph: 'ب', name: 'Baa',    romanized: 'baa',   strokes: ['M 130 280 Q 300 480 470 280'], starts: [{ x: 130, y: 280, n: 1 }], marks: [{ x: 300, y: 530, kind: 'dot' }] },
  taa:   { glyph: 'ت', name: 'Taa',    romanized: 'taa',   strokes: ['M 130 320 Q 300 510 470 320'], starts: [{ x: 130, y: 320, n: 1 }], marks: [{ x: 260, y: 220, kind: 'dot' }, { x: 340, y: 220, kind: 'dot' }] },
  thaa:  { glyph: 'ث', name: 'Thaa',   romanized: 'thaa',  strokes: ['M 130 320 Q 300 510 470 320'], starts: [{ x: 130, y: 320, n: 1 }], marks: [{ x: 250, y: 220, kind: 'dot' }, { x: 300, y: 170, kind: 'dot' }, { x: 350, y: 220, kind: 'dot' }] },
  jeem:  { glyph: 'ج', name: 'Jeem',   romanized: 'jeem',  strokes: ['M 130 280 Q 280 380 420 280', 'M 420 280 Q 470 380 380 480 Q 250 540 160 480'], starts: [{ x: 130, y: 280, n: 1 }, { x: 420, y: 280, n: 2 }], marks: [{ x: 300, y: 430, kind: 'dot' }] },
  haa:   { glyph: 'ح', name: 'Haa',    romanized: 'haa',   strokes: ['M 130 280 Q 280 380 420 280', 'M 420 280 Q 470 380 380 480 Q 250 540 160 480'], starts: [{ x: 130, y: 280, n: 1 }, { x: 420, y: 280, n: 2 }], marks: [] },
  khaa:  { glyph: 'خ', name: 'Khaa',   romanized: 'khaa',  strokes: ['M 130 280 Q 280 380 420 280', 'M 420 280 Q 470 380 380 480 Q 250 540 160 480'], starts: [{ x: 130, y: 280, n: 1 }, { x: 420, y: 280, n: 2 }], marks: [{ x: 280, y: 200, kind: 'dot' }] },
  dal:   { glyph: 'د', name: 'Dal',    romanized: 'dal',   strokes: ['M 200 250 Q 470 250 470 380 Q 400 460 260 460'], starts: [{ x: 200, y: 250, n: 1 }], marks: [] },
  dhal:  { glyph: 'ذ', name: 'Dhal',   romanized: 'dhal',  strokes: ['M 200 250 Q 470 250 470 380 Q 400 460 260 460'], starts: [{ x: 200, y: 250, n: 1 }], marks: [{ x: 320, y: 170, kind: 'dot' }] },
  raa:   { glyph: 'ر', name: 'Raa',    romanized: 'raa',   strokes: ['M 460 280 Q 360 360 240 540'], starts: [{ x: 460, y: 280, n: 1 }], marks: [] },
  zay:   { glyph: 'ز', name: 'Zay',    romanized: 'zay',   strokes: ['M 460 280 Q 360 360 240 540'], starts: [{ x: 460, y: 280, n: 1 }], marks: [{ x: 380, y: 200, kind: 'dot' }] },
  seen:  { glyph: 'س', name: 'Seen',   romanized: 'seen',  strokes: ['M 70 360 L 110 280 L 150 360 L 190 280 L 230 360 L 270 280 L 310 360 Q 350 460 470 460'], starts: [{ x: 70, y: 360, n: 1 }], marks: [] },
  sheen: { glyph: 'ش', name: 'Sheen',  romanized: 'sheen', strokes: ['M 70 360 L 110 280 L 150 360 L 190 280 L 230 360 L 270 280 L 310 360 Q 350 460 470 460'], starts: [{ x: 70, y: 360, n: 1 }], marks: [{ x: 145, y: 200, kind: 'dot' }, { x: 195, y: 160, kind: 'dot' }, { x: 245, y: 200, kind: 'dot' }] },
  sad:   { glyph: 'ص', name: 'Sad',    romanized: 'saad',  strokes: ['M 90 320 Q 80 420 200 420 Q 260 420 260 360 Q 260 320 300 320 Q 380 320 410 350 Q 470 400 470 460'], starts: [{ x: 90, y: 320, n: 1 }], marks: [] },
  dad:   { glyph: 'ض', name: 'Dad',    romanized: 'daad',  strokes: ['M 90 320 Q 80 420 200 420 Q 260 420 260 360 Q 260 320 300 320 Q 380 320 410 350 Q 470 400 470 460'], starts: [{ x: 90, y: 320, n: 1 }], marks: [{ x: 270, y: 200, kind: 'dot' }] },
  tah:   { glyph: 'ط', name: 'Tah',    romanized: 'taah',  strokes: ['M 90 360 Q 80 420 200 420 Q 280 420 280 360 Q 280 340 320 340 L 420 340', 'M 210 120 L 210 380'], starts: [{ x: 90, y: 360, n: 1 }, { x: 210, y: 120, n: 2 }], marks: [] },
  zah:   { glyph: 'ظ', name: 'Zah',    romanized: 'zaah',  strokes: ['M 90 360 Q 80 420 200 420 Q 280 420 280 360 Q 280 340 320 340 L 420 340', 'M 210 120 L 210 380'], starts: [{ x: 90, y: 360, n: 1 }, { x: 210, y: 120, n: 2 }], marks: [{ x: 360, y: 240, kind: 'dot' }] },
  ain:   { glyph: 'ع', name: 'Ain',    romanized: 'ain',   strokes: ['M 320 280 Q 220 280 220 360 Q 220 420 320 420 L 460 420', 'M 460 420 Q 480 500 380 540 Q 240 560 160 460'], starts: [{ x: 320, y: 280, n: 1 }, { x: 460, y: 420, n: 2 }], marks: [] },
  ghain: { glyph: 'غ', name: 'Ghain',  romanized: 'ghain', strokes: ['M 320 280 Q 220 280 220 360 Q 220 420 320 420 L 460 420', 'M 460 420 Q 480 500 380 540 Q 240 560 160 460'], starts: [{ x: 320, y: 280, n: 1 }, { x: 460, y: 420, n: 2 }], marks: [{ x: 280, y: 200, kind: 'dot' }] },
  faa:   { glyph: 'ف', name: 'Faa',    romanized: 'faa',   strokes: ['M 280 300 Q 220 300 220 360 Q 220 420 280 420 Q 340 420 340 380 Q 340 360 380 360 L 470 360'], starts: [{ x: 280, y: 300, n: 1 }], marks: [{ x: 280, y: 200, kind: 'dot' }] },
  qaf:   { glyph: 'ق', name: 'Qaf',    romanized: 'qaaf',  strokes: ['M 280 300 Q 220 300 220 360 Q 220 420 280 420 Q 340 420 340 380', 'M 340 380 Q 360 480 280 540 Q 180 560 100 460'], starts: [{ x: 280, y: 300, n: 1 }, { x: 340, y: 380, n: 2 }], marks: [{ x: 250, y: 200, kind: 'dot' }, { x: 320, y: 200, kind: 'dot' }] },
  kaf:   { glyph: 'ك', name: 'Kaf',    romanized: 'kaaf',  strokes: ['M 200 120 L 200 460 L 380 460', 'M 230 280 L 290 200'], starts: [{ x: 200, y: 120, n: 1 }, { x: 230, y: 280, n: 2 }], marks: [] },
  lam:   { glyph: 'ل', name: 'Lam',    romanized: 'laam',  strokes: ['M 300 100 L 300 380 Q 300 480 200 540 Q 100 540 80 460'], starts: [{ x: 300, y: 100, n: 1 }], marks: [] },
  meem:  { glyph: 'م', name: 'Meem',   romanized: 'meem',  strokes: ['M 280 320 Q 200 320 200 380 Q 200 440 280 440 Q 340 440 340 400 Q 340 380 320 380', 'M 320 380 L 320 540'], starts: [{ x: 280, y: 320, n: 1 }, { x: 320, y: 380, n: 2 }], marks: [] },
  noon:  { glyph: 'ن', name: 'Noon',   romanized: 'noon',  strokes: ['M 130 320 Q 180 540 300 540 Q 420 540 470 320'], starts: [{ x: 130, y: 320, n: 1 }], marks: [{ x: 300, y: 200, kind: 'dot' }] },
  haa_e: { glyph: 'ه', name: 'Haa',    romanized: 'haa',   strokes: ['M 280 300 Q 200 300 200 380 Q 200 460 280 460 Q 360 460 360 380 Q 360 300 280 300'], starts: [{ x: 280, y: 300, n: 1 }], marks: [] },
  waw:   { glyph: 'و', name: 'Waw',    romanized: 'waw',   strokes: ['M 280 280 Q 200 280 200 340 Q 200 400 280 400 Q 340 400 340 340 Q 340 320 360 320 Q 380 360 320 480 Q 220 560 130 480'], starts: [{ x: 280, y: 280, n: 1 }], marks: [] },
  yaa:   { glyph: 'ي', name: 'Yaa',    romanized: 'yaa',   strokes: ['M 80 360 Q 130 500 270 500 Q 410 500 470 360'], starts: [{ x: 80, y: 360, n: 1 }], marks: [{ x: 250, y: 560, kind: 'dot' }, { x: 320, y: 560, kind: 'dot' }] },
};

// Ordered list for the journey-map and lesson sequencing.
const LETTER_ORDER = [
  'alif','baa','taa','thaa','jeem','haa','khaa','dal','dhal','raa','zay',
  'seen','sheen','sad','dad','tah','zah','ain','ghain','faa','qaf','kaf',
  'lam','meem','noon','haa_e','waw','yaa',
];

Object.assign(window, { LETTERS, LETTER_ORDER });
