---
phase: 02-curriculum-schema-first-letter-seed
plan: 01
status: complete
completed_at: "2026-05-31"
---

# Plan 02-01 Summary — Extraction Script & Curriculum JSON

## What was built

- `tools/extract_reference_paths.py` — standalone fonttools script that reads `assets/fonts/NotoNaskhArabic-Regular.ttf`, extracts per-letter glyph contours as normalized 0..1 polylines (N=64 points/contour), and writes `tools/candidate_paths.json` for all 28 Arabic letters.
- `tools/candidate_paths.json` — generated output; alif has 1 contour, baa 2, etc.
- `assets/curriculum/letters.json` — 28 letter entries with all required fields (id, char, name, introOrder, forms ×4, referenceStrokes, cleanRepsToAdvance, commonMistakes, mistakesStatus, signedOff, audio). Alif is `signedOff: true` with 1 referenceStroke (64 normalized points from contour 0) and 3 authored commonMistakes.
- `assets/curriculum/lessons.json` — minimal lesson_01 skeleton with alif as sole item.
- `pubspec.yaml` — added `- assets/curriculum/` to the flutter assets section.

## Key decisions made

- fonttools package name is `fontTools` (capital T) on Python 3.14 / Windows — import uses `from fontTools.ttLib import TTFont`.
- Alif contour 0 maps directly to teaching stroke 1 (topToBottom) — 1 contour in the font, classical single vertical stroke.
- All 28 letters authored in one pass; only alif carries `signedOff: true` per D-07/D-12.

## Verification

- `python tools/extract_reference_paths.py` exits 0, produces 28-letter candidate_paths.json.
- `python -c "..."` validation script confirms 28 letters, all fields, alif signedOff: true.
- `grep -c "assets/curriculum/" pubspec.yaml` → 1.
