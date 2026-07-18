"""Generate DRAFT 19-question sets per letter, mirroring the signed taa/baa template.

For each letter (intro order 4..28 — baa/taa/alif already have live exercises), emits
``docs/curriculum/drafts/exercises/<order>-<letterId>.exercises.json``: the same
19-exercise shape as the signed taa unit, with vocab pulled from the Track B draft
bank (``words_draft.json``) and cited source. **DRAFT only** — every exercise is
``signedOff: false`` and never written into the live ``assets/curriculum/exercises.json``.

Pedagogy we cannot settle without the mother is flagged, not faked:
  * grammar transforms (dual / plural / opposite) carry ``_review`` + ``_todo`` and a
    conservative best-effort value (regular sound dual; plural/opposite left for her);
  * sentence adjectives are a placeholder marked ``_review``;
  * letters whose source worksheet was image-only use flagged draft-bank vocab.

Run from ``tools/``:  ``python -m content.build_exercises_draft``
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LETTERS_JSON = REPO_ROOT / "assets" / "curriculum" / "letters.json"
WORDS_DRAFT = Path(__file__).resolve().parent / "words_draft.json"
DIGEST_INDEX = REPO_ROOT / "docs" / "curriculum" / "drafts" / "source-digest" / "index.json"
OUT_DIR = REPO_ROOT / "docs" / "curriculum" / "drafts" / "exercises"

# Letters that already have real/authored exercises elsewhere — skip drafting.
SKIP_LETTERS = {"alif", "baa", "taa"}
# thaa/jeem/haa also have the richer hand-authored md draft; we still emit a
# machine-readable set for graphing, noting the md takes precedence for wording.
MD_DRAFTED = {"thaa", "jeem", "haa_c"}


def _spaced(text: str) -> str:
    return "  ".join(list(text))


def _sentence_word(text: str) -> str:
    """Naive definite form الـ…ُ for a draft sentence (flagged for the mother)."""
    return "الْ" + text


def make_exercises(letter: dict, words: list[dict], image_only: bool) -> list[dict]:
    lid = letter["id"]
    char = letter["char"]
    forms = ["isolated", "initial", "medial", "final"]

    # Defensive vocab picks (letters have >=3 draft words).
    w = words + words  # pad so indexing never fails
    w0, w1, w2 = w[0], w[1], w[2]

    def trace(form: str) -> dict:
        return {
            "id": f"{lid}.traceLetter.{form}", "type": "traceLetter", "skill": "formation",
            "prompt": [{"kind": "say", "line": f"Trace {letter['name']['display']} — {form} form."},
                       {"kind": "audio", "audioId": f"snd.{lid}"}],
            "surface": {"mode": "trace", "unit": "glyph", "guideForm": form, "demo": form == "isolated"},
            "expected": {"glyph": {"char": char, "form": form}},
            "check": "glyph", "feedback": {"pass": "أحسنت — nicely traced."}, "signedOff": False,
        }

    exercises = [
        {"id": f"{lid}.teachCard.meet", "type": "teachCard", "skill": "comprehension",
         "_note": "SUPPORT section: teaches only, no write surface.",
         "prompt": [{"kind": "say", "line": "This card just teaches — the sound and the shapes."},
                    {"kind": "audio", "audioId": f"snd.{lid}"},
                    {"kind": "image", "imageId": w0["image"], "caption": f"{w0['text']} · {w0['gloss']['en']}"},
                    {"kind": "forms", "char": char, "forms": forms}],
         "surface": None, "expected": None, "check": None, "feedback": None, "signedOff": False},
        trace("isolated"), trace("initial"), trace("medial"),
        {"id": f"{lid}.writeLetter.fromSound", "type": "writeLetter", "skill": "recall",
         "prompt": [{"kind": "say", "line": "Listen, then write the letter the word starts with."},
                    {"kind": "audio", "audioId": w0["audio"]}],
         "surface": {"mode": "write", "unit": "glyph"},
         "expected": {"glyph": {"char": char, "form": "isolated"}},
         "check": "glyph+positionalForm",
         "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "Listen again — which letter makes that sound?"},
         "signedOff": False},
        {"id": f"{lid}.writeLetter.fromPicture", "type": "writeLetter", "skill": "recall",
         "prompt": [{"kind": "say", "line": "Write the letter this picture's word starts with."},
                    {"kind": "image", "imageId": w1["image"], "caption": w1["text"]}],
         "surface": {"mode": "write", "unit": "glyph"},
         "expected": {"glyph": {"char": char, "form": "isolated"}},
         "check": "glyph+positionalForm",
         "feedback": {"pass": "Yes — that's it. أحسنت!", "wrongLetter": "Listen again — which letter makes that sound?"},
         "signedOff": False},
        {"id": f"{lid}.writeLetter.writeForm", "type": "writeLetter", "skill": "recall",
         "prompt": [{"kind": "say", "line": f"Write {letter['name']['display']} in its isolated form."}],
         "surface": {"mode": "write", "unit": "glyph"},
         "expected": {"glyph": {"char": char, "form": "isolated"}},
         "check": "glyph+positionalForm",
         "feedback": {"pass": "Yes — that's it. أحسنت!"}, "signedOff": False},
        {"id": f"{lid}.writeWord.dictation", "type": "writeWord", "skill": "spelling",
         "prompt": [{"kind": "say", "line": "Listen and write the whole word."},
                    {"kind": "audio", "audioId": w0["audio"]}],
         "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": w0["text"]}},
         "check": "sequence",
         "feedback": {"pass": f"{w0['text']} — from memory. Real writing! أحسنت!",
                      "incomplete": "Look again and write all of its letters."},
         "signedOff": False},
        {"id": f"{lid}.writeWord.copy", "type": "writeWord", "skill": "spelling",
         "prompt": [{"kind": "say", "line": "Copy the word."}, {"kind": "text", "text": w1["text"]}],
         "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": w1["text"]}},
         "check": "sequence", "feedback": {"pass": f"{w1['text']} — neatly done. أحسنت!"}, "signedOff": False},
        {"id": f"{lid}.writeWord.picture", "type": "writeWord", "skill": "spelling",
         "prompt": [{"kind": "say", "line": "Write the word for the picture."},
                    {"kind": "image", "imageId": w0["image"], "caption": w0["text"]}],
         "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": w0["text"]}},
         "check": "sequence", "feedback": {"pass": f"{w0['text']} — from memory. أحسنت!"}, "signedOff": False},
        {"id": f"{lid}.connectWord.{w0['id']}", "type": "connectWord", "skill": "spelling",
         "prompt": [{"kind": "say", "line": "Join the letters into one connected word."},
                    {"kind": "text", "text": _spaced(w0["text"])}],
         "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": w0["text"]}},
         "check": "sequence+joinContinuity",
         "feedback": {"pass": f"{w0['text']} — joined beautifully. أحسنت!",
                      "lifted": "Keep the letters joined — one flowing word, no lifts."},
         "signedOff": False},
        {"id": f"{lid}.connectWord.{w1['id']}", "type": "connectWord", "skill": "spelling",
         "prompt": [{"kind": "say", "line": "Join the letters into one connected word."},
                    {"kind": "text", "text": _spaced(w1["text"])}],
         "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": w1["text"]}},
         "check": "sequence+joinContinuity",
         "feedback": {"pass": f"{w1['text']} — joined beautifully. أحسنت!"}, "signedOff": False},
        {"id": f"{lid}.completeWord.middle", "type": "completeWord", "skill": "spelling",
         "prompt": [{"kind": "say", "line": f"Fill in the missing {letter['name']['display']} to finish the word."},
                    {"kind": "text", "text": w2["text"]}],
         "surface": {"mode": "write", "unit": "glyph"}, "expected": {"word": {"text": w2["text"]}},
         "check": "sequence", "feedback": {"pass": f"Complete! {w2['text']}. أحسنت!"}, "signedOff": False},
        {"id": f"{lid}.transformWord.dual", "type": "transformWord", "skill": "grammar",
         "_review": "DUAL — regular sound dual (+ان) is a best-effort DRAFT; confirm with the mother.",
         "prompt": [{"kind": "say", "line": f"One becomes two. Write the dual of {w0['text']}."},
                    {"kind": "rule", "label": "Dual · مثنى"}, {"kind": "text", "text": w0["text"]}],
         "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": w0["text"] + "ان"}},
         "check": "sequence+transformRule",
         "feedback": {"pass": f"{w0['text']}ان — أحسنت!"}, "signedOff": False},
        {"id": f"{lid}.transformWord.plural", "type": "transformWord", "skill": "grammar",
         "_review": "PLURAL — NEEDS THE MOTHER (broken plurals are irregular). Placeholder expected.",
         "_todo": "owner-mother: correct plural form",
         "prompt": [{"kind": "say", "line": f"Write the plural of {w0['text']}."},
                    {"kind": "rule", "label": "Plural · جمع"}, {"kind": "text", "text": w0["text"]}],
         "surface": {"mode": "write", "unit": "word"}, "expected": None,
         "check": "sequence+transformRule", "feedback": None, "signedOff": False},
        {"id": f"{lid}.transformWord.opposite", "type": "transformWord", "skill": "grammar",
         "_review": "OPPOSITE — NEEDS THE MOTHER (choose an age-right antonym pair).",
         "_todo": "owner-mother: choose opposite pair",
         "prompt": [{"kind": "say", "line": "Write the opposite."},
                    {"kind": "rule", "label": "Opposite · ضد"}],
         "surface": {"mode": "write", "unit": "word"}, "expected": None,
         "check": "sequence+transformRule", "feedback": None, "signedOff": False},
        {"id": f"{lid}.fillBlank.adjective", "type": "fillBlank", "skill": "vocabulary",
         "prompt": [{"kind": "say", "line": "Write the word that completes the sentence."},
                    {"kind": "text", "text": w0["text"]}],
         "surface": {"mode": "write", "unit": "word"}, "expected": {"word": {"text": w0["text"]}},
         "check": "sequence", "feedback": {"pass": "Yes! أحسنت!"}, "signedOff": False},
        {"id": f"{lid}.buildSentence.hear", "type": "buildSentence", "skill": "syntax",
         "_review": "SENTENCE — adjective is a DRAFT placeholder (كبير). Confirm sentence + audio with the mother.",
         "prompt": [{"kind": "say", "line": "Listen to the sentence, then write it in order."},
                    {"kind": "audio", "audioId": f"sentence.{lid}-draft"}],
         "surface": {"mode": "write", "unit": "sentence"},
         "expected": {"words": [_sentence_word(w0["text"]), "كَبير"]},
         "check": "order+sequence",
         "feedback": {"pass": f"{_sentence_word(w0['text'])} كَبير — a whole sentence! أحسنت!"},
         "signedOff": False},
        {"id": f"{lid}.buildSentence.picture", "type": "buildSentence", "skill": "syntax",
         "_review": "SENTENCE — adjective is a DRAFT placeholder. Confirm with the mother.",
         "prompt": [{"kind": "say", "line": "Write the sentence for the picture, word by word."},
                    {"kind": "image", "imageId": w0["image"], "caption": w0["text"]}],
         "surface": {"mode": "write", "unit": "sentence"},
         "expected": {"words": [_sentence_word(w0["text"]), "جَميل"]},
         "check": "order+sequence",
         "feedback": {"pass": f"{_sentence_word(w0['text'])} جَميل — أحسنت!"}, "signedOff": False},
    ]
    return exercises


def main() -> int:
    letters = json.loads(LETTERS_JSON.read_text(encoding="utf-8"))["letters"]
    words = json.loads(WORDS_DRAFT.read_text(encoding="utf-8"))["words"]
    digest = (json.loads(DIGEST_INDEX.read_text(encoding="utf-8"))["letters"]
              if DIGEST_INDEX.exists() else {})

    by_focus: dict[str, list[dict]] = {}
    for wd in words:
        by_focus.setdefault(wd["focusLetter"], []).append(wd)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    written = 0
    summary: list[str] = []
    for letter in sorted(letters, key=lambda l: int(l["introOrder"])):
        lid = letter["id"]
        if lid in SKIP_LETTERS:
            continue
        lwords = by_focus.get(lid, [])
        if len(lwords) < 3:
            summary.append(f"  SKIP {lid}: only {len(lwords)} draft words")
            continue
        d = digest.get(lid, {})
        image_only = not d.get("anyTextExtracted", False)
        source = ("owner-mother worksheet (extracted)" if d.get("anyTextExtracted")
                  else "draft-bank vocab (source image-only / not found — NEEDS MOTHER)")
        exercises = make_exercises(letter, lwords, image_only)
        doc = {
            "_meta": {
                "title": f"DRAFT exercises — {letter['name']['display']} ({lid})",
                "status": "DRAFT — signedOff:false on every item. Owner's mother signs; owner promotes into exercises.json.",
                "letterId": lid, "introOrder": letter["introOrder"],
                "template": "mirrors the signed taa 19-exercise set",
                "vocabSource": source,
                "alsoSee": ("docs/curriculum/drafts/thaa-jeem-haa-DRAFT.md (richer hand-authored draft — precedence for wording)"
                            if lid in MD_DRAFTED else None),
                "reviewFlags": "transformWord.plural/opposite need the mother; sentence adjectives are placeholders; grammar transforms are best-effort.",
            },
            "letterId": lid, "signedOff": False, "exercises": exercises,
        }
        out = OUT_DIR / f"{int(letter['introOrder']):02d}-{lid}.exercises.json"
        out.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n",
                       encoding="utf-8", newline="\n")
        written += 1
        summary.append(f"  {lid}: 19 exercises · {source.split(' (')[0]}")

    print(f"Wrote {written} draft exercise set(s) to {OUT_DIR.relative_to(REPO_ROOT)}")
    print("\n".join(summary))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
