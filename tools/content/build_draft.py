"""Build ``words_draft.json`` — the DRAFT vocabulary bank covering all 28 letters.

Every word's ``letters[]`` is COMPUTED by :mod:`content.arabic` (never hand-typed),
so the bank is internally consistent and dogfoods the decomposer. Output schema
matches the live ``assets/curriculum/words.json`` exactly, plus two draft fields:
``source`` (where the word came from) and ``signedOff: false``.

**Nothing here is signed pedagogy.** Sourced words are lifted from the owner's
mother's materials (cited); the rest are model-suggested common grade-1 vocabulary
and are explicitly flagged as awaiting her review. The owner promotes words into
the live file only after she signs.

Run from ``tools/``:  ``python -m content.build_draft``
"""

from __future__ import annotations

import json
from pathlib import Path

from .arabic import DecompFlag, decompose

REPO_ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "words_draft.json"

# Source tags — provenance is part of the deliverable.
HER = "owner-mother worksheet (أ-ب-ت-ث.docx, via docs/curriculum/baa-family-authoring-sketch.md)"
DRAFT = "docs/curriculum/drafts/thaa-jeem-haa-DRAFT.md (drafted, awaiting mother)"
LIVE = "existing in assets/curriculum/words.json"
MODEL = "model-suggested (common grade-1 near-environment vocabulary) — awaiting mother's review"

# Curated candidate words, grouped by the FOCUS letter they teach. Each row:
#   (word_id, arabic_text, english_gloss, source_tag)
# Arabic is written WITHOUT harakat (the child writes the skeleton); the
# decomposer strips harakat anyway. Focus letter is the section key, so every
# one of the 28 letterIds is represented as a focus at least once.
WORDS: dict[str, list[tuple[str, str, str, str]]] = {
    "alif": [
        ("asad", "أسد", "lion", LIVE),
        ("umm", "أم", "mother", LIVE),
        ("arnab", "أرنب", "rabbit", MODEL),
    ],
    "baa": [
        ("baab", "باب", "door", LIVE),
        ("bayt", "بيت", "house", LIVE),
        ("kalb", "كلب", "dog", HER),
        ("dubb", "دب", "bear", HER),
    ],
    "taa": [
        ("taaj", "تاج", "crown", LIVE),
        ("tuut", "توت", "berries", LIVE),
        ("bint", "بنت", "girl", HER),
        ("tuffah", "تفاح", "apple", DRAFT),
    ],
    "thaa": [
        ("thalab", "ثعلب", "fox", HER),
        ("thalj", "ثلج", "snow", HER),
        ("thawm", "ثوم", "garlic", HER),
        ("muthallath", "مثلث", "triangle", HER),
    ],
    "jeem": [
        ("jamal", "جمل", "camel", DRAFT),
        ("jabal", "جبل", "mountain", DRAFT),
        ("jazar", "جزر", "carrots", DRAFT),
        ("dajaja", "دجاجة", "hen", DRAFT),
    ],
    "haa_c": [
        ("hisaan", "حصان", "horse", DRAFT),
        ("hoot", "حوت", "whale", DRAFT),
        ("haliib", "حليب", "milk", LIVE),
        ("miftaah", "مفتاح", "key", DRAFT),
    ],
    "khaa": [
        ("khubz", "خبز", "bread", MODEL),
        ("kharuuf", "خروف", "sheep", MODEL),
        ("khaymat", "خيمة", "tent", MODEL),
    ],
    "daal": [
        ("diik", "ديك", "rooster", MODEL),
        ("dulaab", "دولاب", "cupboard", MODEL),
        ("daftar", "دفتر", "notebook", MODEL),
    ],
    "dhaal": [
        ("dhib", "ذئب", "wolf", MODEL),
        ("dhurat", "ذرة", "corn", MODEL),
        ("dhahab", "ذهب", "gold", MODEL),
    ],
    "raa": [
        ("rummaan", "رمان", "pomegranate", MODEL),
        ("riishat", "ريشة", "feather", MODEL),
        ("ward", "ورد", "roses", MODEL),
    ],
    "zaay": [
        ("zahrat", "زهرة", "flower", MODEL),
        ("zaraafat", "زرافة", "giraffe", MODEL),
        ("mawz", "موز", "banana", MODEL),
    ],
    "seen": [
        ("samak", "سمك", "fish", MODEL),
        ("sayyaarat", "سيارة", "car", MODEL),
        ("sullam", "سلم", "ladder", MODEL),
    ],
    "sheen": [
        ("shams", "شمس", "sun", MODEL),
        ("shajarat", "شجرة", "tree", MODEL),
        ("shamaa", "شمعة", "candle", MODEL),
    ],
    "saad": [
        ("saqr", "صقر", "falcon", MODEL),
        ("sahn", "صحن", "plate", MODEL),
        ("usfuur", "عصفور", "sparrow", MODEL),
    ],
    "daad": [
        ("difdaa", "ضفدع", "frog", MODEL),
        ("baydat", "بيضة", "egg", MODEL),
        ("dabaab", "ضباب", "fog", MODEL),
    ],
    "taa_h": [
        ("tabl", "طبل", "drum", MODEL),
        ("qitt", "قط", "cat", MODEL),
        ("batiikh", "بطيخ", "watermelon", MODEL),
    ],
    "zhaa": [
        ("zharf", "ظرف", "envelope", MODEL),
        ("zhufr", "ظفر", "fingernail", MODEL),
        ("nazhaarat", "نظارة", "glasses", MODEL),
    ],
    "ayn": [
        ("ayn", "عين", "eye", MODEL),
        ("inab", "عنب", "grapes", MODEL),
        ("asal", "عسل", "honey", MODEL),
    ],
    "ghayn": [
        ("ghazaal", "غزال", "gazelle", MODEL),
        ("ghuraab", "غراب", "crow", MODEL),
        ("ghaymat", "غيمة", "cloud", MODEL),
    ],
    "faa": [
        ("fiil", "فيل", "elephant", MODEL),
        ("faraashat", "فراشة", "butterfly", MODEL),
        ("fam", "فم", "mouth", MODEL),
    ],
    "qaaf": [
        ("qalam", "قلم", "pen", MODEL),
        ("qamar", "قمر", "moon", MODEL),
        ("qittat", "قطة", "cat", MODEL),
    ],
    "kaaf": [
        ("kitaab", "كتاب", "book", HER),
        ("kuub", "كوب", "cup", HER),
        ("kursii", "كرسي", "chair", MODEL),
    ],
    "laam": [
        ("laymuun", "ليمون", "lemon", MODEL),
        ("luaba", "لعبة", "toy", MODEL),
        ("laban", "لبن", "yoghurt", MODEL),
    ],
    "meem": [
        ("malik", "ملك", "king", MODEL),
        ("madrasat", "مدرسة", "school", MODEL),
        ("markib", "مركب", "boat", MODEL),
    ],
    "noon": [
        ("najmat", "نجمة", "star", MODEL),
        ("nimr", "نمر", "tiger", MODEL),
        ("nahlat", "نحلة", "bee", MODEL),
    ],
    "haa_f": [
        ("hilaal", "هلال", "crescent", MODEL),
        ("hudhud", "هدهد", "hoopoe", MODEL),
        ("haram", "هرم", "pyramid", MODEL),
    ],
    "waaw": [
        ("wardat", "وردة", "rose", MODEL),
        ("walad", "ولد", "boy", MODEL),
        ("wajh", "وجه", "face", MODEL),
    ],
    "yaa": [
        ("yad", "يد", "hand", MODEL),
        ("yamaamat", "يمامة", "dove", MODEL),
        ("yaasamiin", "ياسمين", "jasmine", MODEL),
    ],
}


def build() -> tuple[list[dict], list[dict]]:
    """Return (word entries, decomposition report rows)."""
    entries: list[dict] = []
    report: list[dict] = []
    seen_ids: set[str] = set()

    for focus, rows in WORDS.items():
        for word_id, text, gloss_en, source in rows:
            if word_id in seen_ids:
                raise SystemExit(f"Duplicate word id '{word_id}' (focus {focus}).")
            seen_ids.add(word_id)

            d = decompose(text)
            entry = {
                "id": word_id,
                "text": text,
                "audio": f"word.{word_id}",
                "image": f"img.{word_id}",
                "gloss": {"en": gloss_en},
                "letters": d.letters,
                "source": source,
                "focusLetter": focus,
                "signedOff": False,
            }
            entries.append(entry)

            if d.flags:
                report.append(
                    {
                        "id": word_id,
                        "text": text,
                        "letters": d.letters,
                        "flags": [
                            {"char": ch, "flag": flag.value, "index": idx}
                            for idx, ch, flag in d.flags
                        ],
                        "hasBlocking": d.has_blocking,
                    }
                )

    return entries, report


def main() -> int:
    entries, report = build()

    doc = {
        "_meta": {
            "title": "Qalam DRAFT vocabulary bank — all 28 letters",
            "status": "DRAFT — signedOff:false on every word. Nothing reaches a child until the owner's mother signs it.",
            "schemaNote": "Matches assets/curriculum/words.json (id/text/audio/image/gloss/letters) plus draft-only fields: source, focusLetter, signedOff.",
            "doNotEdit": "Do NOT edit assets/curriculum/words.json from here — the owner promotes signed words there. Regenerate this file with `python -m content.build_draft`.",
            "decompositionNote": "letters[] is computed by tools/content/arabic.py (written skeleton: harakat/shadda stripped, one id per written letter). Words with special characters are listed in decompositionReport for the mother's placement decision.",
            "letterCount": 28,
            "wordCount": len(entries),
            "flaggedWordCount": len(report),
        },
        "decompositionReport": report,
        "words": entries,
    }

    OUT.write_text(
        json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n"
    )

    covered = {e["focusLetter"] for e in entries}
    print(f"Wrote {OUT.name}: {len(entries)} words across {len(covered)}/28 focus letters.")
    if report:
        print(f"{len(report)} word(s) contain special characters (see decompositionReport):")
        for r in report:
            kinds = ", ".join(sorted({f['flag'] for f in r['flags']}))
            print(f"  {r['text']:10} ({r['id']}): {kinds}")
    missing = set(WORDS) - covered
    if missing:
        print(f"WARNING: focus letters with no words: {sorted(missing)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
