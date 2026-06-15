# TASK (for the partner + agent): Process the mother's curriculum Drive folder → structured content inventory

**Owner of this task:** Partner (running an agent).
**Goal:** Turn the owner's-mother's ~42 worksheet files (Google Drive) into a **structured,
per-letter content inventory** that feeds Curriculum Schema v2 — the vocab, the exercise/question
types she uses, grammar sets, and sentences. This becomes the raw material the content drafts
(and `EXERCISE-CONFIGS.json`) are built from.

**This is extraction, not authoring.** Transcribe faithfully; do not invent Arabic. Everything
produced is `signedOff:false` and gets verified by the owner's mother later.

---

## ⚠ The two walls I already hit (do NOT repeat them)

1. **The files are image-based worksheets.** Most content lives inside *pictures*, not text.
2. **Text/PDF extraction returns GARBLED, REVERSED Arabic** (e.g. `ﺎﻐﺑﺑ ء`). Do **NOT** rely on
   `read_file_content` text extraction — it produces unusable Arabic.

**→ The only reliable method is VISION.** Get the files locally, render them to images, and have
a multimodal agent **read the worksheet images visually** (the `Read` tool shows images to the
model) and transcribe the Arabic by *seeing* it. This is the core instruction.

---

## Inputs

- **Drive folder:** `1jGf4A2nyqG0yCzXLFMk4e1wkKn_Mq7Ag` (owner `fedaa065@gmail.com`).
  Partner needs it **shared to his account** OR downloaded as a zip.
- **Recommended:** download the folder, put files under `tools/curriculum/source/`, convert PDFs
  to page PNGs (`pdftoppm -png file.pdf out` or ImageMagick), then read the PNGs with vision.
  (Vision on rendered pages >> any text extraction for Arabic worksheets.)

### File manifest (42 files — process every one)
| Type cluster | Files (title) |
|---|---|
| Per-letter packets | `أ-ب-ت-ث`, `حرف الحاء والخاء والجيم`, `حرف الدال`, `حرف الكاف`, `حرف اللام`, `ن`, `حرف الهاء`(×2), `الحرف هـ` |
| Dotted tracing (تنقيط) | `تنقيط جميع الحروف`, `تنقيط حرف` الطاء/العين/الغين/الظاء/الفاء |
| Vocab (letter+image+word) | `الحروف مع صور وكلمات`, `اختر الصورة المناسبة للحرف`, `صل الحرف بالصورة المناسبة`, `لون الصور التي تبدأ بحرف القاف`, `لون الصورة الملائمة للحرف` |
| Phonological awareness (وعي صوتي) | `وعي صوتي لجميع الحروف`, `كراس وعي صوتي`, `وعي صوتي سجع`, `تاء/راء/ج وعي صوتي`, `لعبة وعي صوتي (دائرة حول الحرف الأول)`, `دائرة تميز صور الحروف` |
| Grammar | `مفرد مثنى جمع`, `الكلمة والعكس` |
| Spelling/joining | `املاء ء ا ب ت ث ج ح خ`, `حرف ربط اعادة كتابة` |
| Enrichment | `متاهة الحروف`, `لون واكتشف`, `تلوين حروف مرحلة 1` |
| Readiness/workbooks | `الاستعداد للصف الأوّل`, `استعداد للأول`, `منهاج`, `كراسة حروف الهجاء`, `كراسة حروف مرحلة 1`, `كراس عمل للصف الأول مرحلة متقدمة`, `ملف أنا الحرف` |

*(Full Drive file IDs are listed at the bottom.)*

---

## What to produce

For **each file**, a record; then **roll up per letter**. Write to
`.planning/research/learning-experience/CONTENT-INVENTORY.md` (+ a machine-readable
`CONTENT-INVENTORY.json`):

```
perFile:   { fileId, title, letters:[...], worksheetType, instruction_ar, instruction_en,
             vocab:[words], items:[...], grammar:[{singular,dual,plural}|{word,opposite}],
             sentences:[...], notes, confidence }
perLetter: { letter, vocab:[words], exerciseTypesSeen:[...], grammar:[...], sentences:[...],
             introOrderHint }
```

**Classify each worksheet into the question taxonomy** (so it maps to Schema v2 — see
`COMPONENT-SYSTEM.md`): `traceLetter · writeLetter · writeWord · connectWord · completeWord ·
transformWord · fillBlank · buildSentence · teachCard`. Recognition/coloring/matching worksheets
map to their **handwriting-first** equivalent (e.g. "color images starting with ت" → `writeLetter`
from sound), per `B-exercise-taxonomy.md`.

---

## Canonical refs (the agent MUST read first — these are the target shape + rules)
- `.planning/research/learning-experience/SCHEMA-V2.md` — the data shape to feed.
- `.planning/research/learning-experience/COMPONENT-SYSTEM.md` — the question taxonomy to classify into.
- `.planning/research/learning-experience/B-exercise-taxonomy.md` — worksheet → handwriting-first mapping.
- `CLAUDE.md` — Arabic-literacy product rules; the mother is the curriculum authority.

## Guardrails
- **Vision, not text extraction.** If a value is unclear in the image, mark `confidence: low` and
  flag it — never guess Arabic.
- **Faithful transcription only.** No inventing words/sentences. Everything `signedOff:false`.
- Output in the inventory shape above; one record per file; roll up per letter.
- Don't touch `lib/`, the schema, or any engine code — this task only **reads** Drive + **writes**
  the inventory docs.

## Acceptance criteria
- Every one of the 42 files has a record (or is explicitly marked unreadable + why).
- A per-letter rollup exists for all 28 letters with vocab + exercise types seen.
- The grammar file (`مفرد مثنى جمع`) yields singular→dual→plural triples; `الكلمة والعكس` yields opposite pairs.
- Low-confidence / unreadable items are flagged for the owner's mother, not silently filled.

---

## Paste-ready agent prompt (partner runs this)

> Read `.planning/research/learning-experience/TASK-process-drive-folder.md` and do exactly what
> it says. The mother's curriculum worksheets are image-based and Arabic text-extraction comes out
> garbled — so **download the Drive folder locally, render PDFs/docs to page images, and transcribe
> the Arabic by reading the images with vision**, never by text extraction. Produce
> `CONTENT-INVENTORY.md` + `.json` per the shape in the task. Read `SCHEMA-V2.md`,
> `COMPONENT-SYSTEM.md`, and `B-exercise-taxonomy.md` first. Transcribe faithfully, mark anything
> uncertain `confidence: low` for the mother, invent nothing, and don't touch engine code.

---

## Appendix — full Drive file IDs
1zBenOxTEEywWhma4g0adCLyaKU7L7e4j · 1cPL_ohG-PXDD8wCHlhJ6SGafVoUyiHBf · 1LQk_O2Tu79aLl8cUi3Q5FtsgEMQVuQXI ·
1neIYD0uQzA9hLrtaU17cqwmnhWyukfo1 · 16275mFsaXSCEM5HyNkKYRTiIrLVkQFqH · 1a_dAUclhu911830OX__EEcND68lCOmJP ·
1rM1fIhafoGO-iIorPPASKXisnmlOSK3q · 1mdI78jCeNilkXbC7E4zrFrxTwa_Io0X6 · 1KQsqY9uhYaFZToA4R3IiTp2kJuU2U4Dg ·
1_ezTrLMOUju4xL8rwV7iWM0VnphEksQA · 169o1EhzHXM1UWduPYX4G6QmVVQT3IdeV · 1c_qL-AmYK8VlXACk6ZsGnYRFXNf1ANh8 ·
1A9DMtY2VkgV1cMO1TFuQRQiG1xlCdtPW · 1Sdb0UtppQZc_wL63O70befsaaSCRsj1U · 1m6DaA43TucIojBeR3T8VjoSikQ2KpX__ ·
1lcKZcrxqul1igGTJqW9dzwj1AKp4X1jQ · 1LM8PNRGTBfzpMGlETCfCIr9ba_qkrJd5 · 1OIVWG1DUio5_AUrLo7hlZ5xH05Gpv84f ·
1weNt28M1ufc-CGslc_AArdIQucIJK0H_ · 1OrPS_ESsbN_ayCym4wPW4I4OX3i5nzgg · 1vRyuQbgPWzwtQrtufK0y3ijV0f5U3nfB ·
1DrnPfDe2QjIEO0n4W7MRlORn0gfYIpG3 · 1s9Bgd8cu8bGRa6e1tMq30a6Dhh0v3UEC · 11G6n7S99yGrGXRM4nrMhpBlgNgu3uyAG ·
1hWppSfJ-16Rkrx98J00cNvVCl3cFOR1u · 1q0ndGl1E5EoR75d0dx1dpVlXQDakcRH_ · 1L_bX_ET0d_5vS5oMg_4U9b0LcJfRu54M ·
1s2GKvKFBEn8NUAaGYgszu-eG4UILcAnL · 1deXDntLcHp5AYbFQJRL7FySsvRPkqWKP · 17JZ5p1CnxsKg1F-INQ8JgPdsn2A-rzn1 ·
1VjXokz056ZXdUsI4JnHZoklqLx8egWWq · 11RN3U6AYYnsO7TQLoAgZoznQjWPb1LFk · 1JWRogjzQiG8c1C-ex5Rh9S6Nwuh8ZtMV ·
1QfPrd-6ubMK8SjiAEzk5J_7HWtdn8YnH · 17FZLvugiiMZVeNpyNNgTg5egH9D20lLY · 1boGr7bj3Yx-sGfeslyUOgOdFHcreBF9V ·
1ZwCbgrXKA0WIW7z5WqS0-iUlUGQIn9aN · 1Jg4jCZyyWu3FU0dZnVV4qJVVCc5nz3sh · 1JyvGijYOY61CgPhaxwqfKbHK9vM1N3Dg ·
1Iym-nLMZtwrpmVFQqM1zS40RQdlgoDhB · 1DFlnLNYEyrELqdvU6_mW3mYBJaOUA1Ir · 1qyUSsp_dQuo8HfW4sDur825cbWLjhrlx
