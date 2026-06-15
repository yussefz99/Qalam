#!/usr/bin/env python3
"""Generate full Letter Units for taa (ت) and alif (ا), modeled on signed-off baa.

Phase 8 (demo-rescoped 2026-06-15): bring the first three letters to baa's bar so
the Technion demo shows a real, scaling product. taa ≈ baa (boat body + TWO dots
ABOVE); alif is a non-connector (single vertical stroke, isolated+final only).

This DERIVES taa's per-form reference strokes from baa's (so the trace/forms
actually score) and authors the exercises / vocab / unit as Schema v2 data. The
owner refines the strokes via the Stroke Studio / DB and owns the final sign-off.
Idempotent: removes any existing taa/alif entries before re-adding.

Run:  python3 tools/curriculum/generate_demo_letters.py
"""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CUR = ROOT / "assets" / "curriculum"
LETTERS, EXERCISES, WORDS, UNITS = (CUR / f for f in
    ("letters.json", "exercises.json", "words.json", "units.json"))


def load(p):
    return json.loads(p.read_text(encoding="utf-8"))


def save(p, data):
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# Stroke derivation
# ---------------------------------------------------------------------------
def _body_strokes(form):
    """Non-dot strokes (the boat/body) of a baa form."""
    return [s for s in form.get("referenceStrokes", []) if s.get("type") != "dot"]


def _two_dots_above(body):
    """Two dot strokes placed just ABOVE the body's bounding box (taa)."""
    pts = [p for s in body for p in s["points"]]
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    cx = (min(xs) + max(xs)) / 2
    top = min(ys)
    y = round(max(0.06, top - 0.12), 3)
    return [
        {"order": len(body) + 1, "label": "dot1", "type": "dot",
         "points": [[round(cx - 0.06, 3), y]], "direction": "tap"},
        {"order": len(body) + 2, "label": "dot2", "type": "dot",
         "points": [[round(cx + 0.06, 3), y]], "direction": "tap"},
    ]


def taa_forms_from_baa(baa):
    """Derive taa's 4 contextual forms: baa's boat body + two dots above."""
    out = {}
    mistakes = [
        {"id": "shallow_bowl", "check": "bowlTooShallow",
         "feedback": "Your taa needs a deeper boat at the bottom — try again, slower."},
        {"id": "one_dot", "check": "dotCountWrong",
         "feedback": "Taa has TWO dots, not one — add the second dot on top."},
        {"id": "dots_below", "check": "dotPositionWrong",
         "feedback": "Taa's two dots go ABOVE the boat, not below. Move them up."},
        {"id": "wrong_stroke_order", "check": "strokeOrderWrong",
         "feedback": "Draw the boat first, then add the two dots on top."},
    ]
    for name, form in (baa.get("contextualForms") or {}).items():
        if not form:
            out[name] = None
            continue
        body = _body_strokes(form)
        out[name] = {
            "referenceStrokes": body + _two_dots_above(body),
            "commonMistakes": [dict(m) for m in mistakes],
            "tolerances": {"preset": "normal"},
        }
    return out


def alif_forms(alif):
    """alif is a non-connector: isolated + final only, one vertical stroke."""
    base = alif.get("referenceStrokes") or [
        {"order": 1, "label": "stem", "type": "line",
         "points": [[0.5, 0.08], [0.5, 0.5], [0.5, 0.92]], "direction": "topToBottom"}
    ]
    mistakes = [
        {"id": "not_straight", "check": "notStraight",
         "feedback": "Keep alif straight and tall — one clean line down. Try again."},
        {"id": "too_short", "check": "tooShort",
         "feedback": "Make it taller — alif reaches from the top line to the bottom."},
        {"id": "leaning", "check": "leaning",
         "feedback": "A little straighter — alif stands up tall, it doesn't lean."},
    ]
    form = {
        "referenceStrokes": [dict(s) for s in base],
        "commonMistakes": [dict(m) for m in mistakes],
        "tolerances": {"preset": "normal"},
    }
    return {"isolated": dict(form), "initial": None, "medial": None, "final": dict(form)}


# ---------------------------------------------------------------------------
# Exercise / word / unit authoring (modeled on baa)
# ---------------------------------------------------------------------------
def say(line):
    return {"kind": "say", "line": line}


def audio(aid):
    return {"kind": "audio", "audioId": aid}


def trace_ex(lid, char, form, line, snd):
    return {"id": f"{lid}.traceLetter.{form}", "type": "traceLetter", "skill": "formation",
            "prompt": [say(line), audio(snd)],
            "surface": {"mode": "trace", "unit": "glyph", "guideForm": form, "demo": True},
            "expected": {"glyph": {"char": char, "form": form}}, "check": "glyph",
            "feedback": {"pass": "Beautiful — smooth and clean. أحسنت!",
                         "shallowBowl": "A little more curve — try again, slower.",
                         "noDot": "Good shape — now the dots."}, "signedOff": True}


def write_letter_ex(lid, char, sub, line, prompt_extra):
    return {"id": f"{lid}.writeLetter.{sub}", "type": "writeLetter", "skill": "recall",
            "prompt": [say(line)] + prompt_extra,
            "surface": {"mode": "write", "unit": "glyph"},
            "expected": {"glyph": {"char": char, "form": "isolated"}},
            "check": "glyph+positionalForm",
            "feedback": {"pass": "Yes — that's it. أحسنت!",
                         "wrongLetter": "Listen again — which letter makes that sound?"},
            "signedOff": True}


def write_word_ex(lid, sub, word, line, prompt_extra):
    return {"id": f"{lid}.writeWord.{sub}", "type": "writeWord", "skill": "spelling",
            "prompt": [say(line)] + prompt_extra,
            "surface": {"mode": "write", "unit": "word"},
            "expected": {"word": {"text": word}}, "check": "sequence",
            "feedback": {"pass": f"{word} — from memory. Real writing! أحسنت!",
                         "incomplete": "Look again and write all of its letters.",
                         "wrongWord": "That's a different word — look at the picture and try again."},
            "signedOff": True}


def connect_word_ex(lid, sub, word, spaced):
    return {"id": f"{lid}.connectWord.{sub}", "type": "connectWord", "skill": "spelling",
            "prompt": [say("Join the letters into one connected word."),
                       {"kind": "text", "text": spaced}],
            "surface": {"mode": "write", "unit": "word"},
            "expected": {"word": {"text": word}}, "check": "sequence+joinContinuity",
            "feedback": {"pass": f"{word} — joined beautifully. أحسنت!",
                         "lifted": "Keep the letters joined — one flowing word, no lifts."},
            "signedOff": True}


def complete_word_ex(lid, word, line):
    return {"id": f"{lid}.completeWord.middle", "type": "completeWord", "skill": "spelling",
            "prompt": [say(line), {"kind": "text", "text": word}],
            "surface": {"mode": "write", "unit": "glyph"},
            "expected": {"word": {"text": word}}, "check": "sequence",
            "feedback": {"pass": "Complete! أحسنت!",
                         "incomplete": "Fill in the missing letter to finish the word."},
            "signedOff": True}


def transform_ex(lid, sub, base, answer, rule, line):
    return {"id": f"{lid}.transformWord.{sub}", "type": "transformWord", "skill": "grammar",
            "prompt": [say(line), {"kind": "rule", "label": rule}, {"kind": "text", "text": base}],
            "surface": {"mode": "write", "unit": "word"},
            "expected": {"word": {"text": answer}}, "check": "sequence+transformRule",
            "feedback": {"pass": f"{answer} — أحسنت!",
                         "missingEnding": f"Add the ending: {answer}."},
            "signedOff": True}


def fill_blank_ex(lid, word, line):
    return {"id": f"{lid}.fillBlank.adjective", "type": "fillBlank", "skill": "vocabulary",
            "prompt": [say(line), {"kind": "text", "text": word}],
            "surface": {"mode": "write", "unit": "word"},
            "expected": {"word": {"text": word}}, "check": "sequence",
            "feedback": {"pass": "Yes! أحسنت!",
                         "wrongWord": "Read the sentence again and pick the word that fits."},
            "signedOff": True}


def build_sentence_ex(lid, sub, words, prompt_extra, line):
    return {"id": f"{lid}.buildSentence.{sub}", "type": "buildSentence", "skill": "syntax",
            "prompt": [say(line)] + prompt_extra,
            "surface": {"mode": "write", "unit": "sentence"},
            "expected": {"words": words}, "check": "order+sequence",
            "feedback": {"pass": f"{' '.join(words)} — a whole sentence! أحسنت!",
                         "wrongOrder": f"Keep the words in order: {' '.join(words)}."},
            "signedOff": True}


def teach_card(lid, char, snd, img, caption):
    return {"id": f"{lid}.teachCard.meet", "type": "teachCard", "skill": "comprehension",
            "_note": "SUPPORT section: PromptHeader only, no WriteSurface.",
            "prompt": [say("This card just teaches — the sound and the shapes."),
                       audio(snd), {"kind": "image", "imageId": img, "caption": caption},
                       {"kind": "forms", "char": char,
                        "forms": ["isolated", "initial", "medial", "final"]}],
            "surface": None, "expected": None, "check": None, "feedback": None,
            "signedOff": True}


def unit(lid, sections):
    return {"letterId": lid, "sections": [{"id": k, "exercises": v} for k, v in sections]}


# ---- taa content (ت) -------------------------------------------------------
def build_taa():
    L = "taa"
    char = "ت"
    ex = [
        teach_card(L, char, "snd.taa", "img.crown", "تاج · taaj"),
        trace_ex(L, char, "isolated", "Sweep the boat, then two dots on top.", "snd.taa"),
        trace_ex(L, char, "initial", "The starting taa — flat and low, two dots on top.", "snd.taa"),
        trace_ex(L, char, "medial", "A little tooth in the middle, two dots above.", "snd.taa"),
        write_letter_ex(L, char, "fromSound", "Listen, then write the letter the word starts with.",
                        [audio("word.taaj")]),
        write_letter_ex(L, char, "fromPicture", "Write the letter this picture's word starts with.",
                        [{"kind": "image", "imageId": "img.crown", "caption": "تاج"}]),
        write_letter_ex(L, char, "writeForm", "Write taa in its isolated form.", []),
        write_word_ex(L, "dictation", "تاج", "Listen and write the whole word.", [audio("word.taaj")]),
        write_word_ex(L, "copy", "توت", "Copy the word.", [{"kind": "text", "text": "توت"}]),
        write_word_ex(L, "picture", "بيت", "Write the word for the picture.",
                      [{"kind": "image", "imageId": "img.house", "caption": "بيت"}]),
        connect_word_ex(L, "taaj", "تاج", "ت  ا  ج"),
        connect_word_ex(L, "bayt", "بيت", "ب  ي  ت"),
        complete_word_ex(L, "توت", "Fill in the missing taa to finish the word."),
        transform_ex(L, "dual", "تاج", "تاجان", "Dual · مثنى", "One becomes two. Write the dual of تاج."),
        transform_ex(L, "plural", "بيت", "بيوت", "Plural · جمع", "Write the plural of بيت."),
        transform_ex(L, "opposite", "تحت", "فوق", "Opposite · ضد", "Write the opposite of تحت."),
        fill_blank_ex(L, "تاج", "Write the word that completes the sentence."),
        build_sentence_ex(L, "hear", ["التاجُ", "جميل"], [audio("sentence.attaaj-jamiil")],
                          "Listen to the sentence, then write it in order."),
        build_sentence_ex(L, "picture", ["البيتُ", "كبير"],
                          [{"kind": "image", "imageId": "img.house", "caption": "بيت"}],
                          "Write the sentence for the picture, word by word."),
    ]
    words = [
        {"id": "taaj", "text": "تاج", "audio": "word.taaj", "image": "img.crown",
         "gloss": {"en": "crown"}, "letters": ["taa", "alif", "jeem"]},
        {"id": "tuut", "text": "توت", "audio": "word.tuut", "image": "img.berries",
         "gloss": {"en": "berries"}, "letters": ["taa", "waw", "taa"]},
        {"id": "bayt", "text": "بيت", "audio": "word.bayt", "image": "img.house",
         "gloss": {"en": "house"}, "letters": ["baa", "yaa", "taa"]},
    ]
    u = unit(L, [
        ("meet", ["taa.teachCard.meet"]),
        ("watchTrace", ["taa.traceLetter.isolated", "taa.traceLetter.initial", "taa.traceLetter.medial"]),
        ("forms", ["taa.writeLetter.fromSound", "taa.writeLetter.fromPicture", "taa.writeLetter.writeForm"]),
        ("words", ["taa.writeWord.dictation", "taa.writeWord.copy", "taa.writeWord.picture",
                   "taa.connectWord.taaj", "taa.connectWord.bayt", "taa.completeWord.middle"]),
        ("listenWrite", ["taa.transformWord.dual", "taa.transformWord.plural", "taa.transformWord.opposite",
                         "taa.fillBlank.adjective", "taa.buildSentence.hear", "taa.buildSentence.picture"]),
        ("mastery", []),
    ])
    return ex, words, u


# ---- alif content (ا) — leaner, non-connector ------------------------------
def build_alif():
    L = "alif"
    char = "ا"
    ex = [
        teach_card(L, char, "snd.alif", "img.lion", "أسد · asad"),
        trace_ex(L, char, "isolated", "One clean line down — top to bottom.", "snd.alif"),
        write_letter_ex(L, char, "fromSound", "Listen, then write the letter the word starts with.",
                        [audio("word.asad")]),
        write_letter_ex(L, char, "writeForm", "Write alif — one tall, straight line.", []),
        write_word_ex(L, "dictation", "أسد", "Listen and write the whole word.", [audio("word.asad")]),
        write_word_ex(L, "copy", "أم", "Copy the word.", [{"kind": "text", "text": "أم"}]),
        write_word_ex(L, "picture", "باب", "Write the word for the picture.",
                      [{"kind": "image", "imageId": "img.door", "caption": "باب"}]),
        connect_word_ex(L, "baab", "باب", "ب  ا  ب"),
        transform_ex(L, "dual", "أسد", "أسدان", "Dual · مثنى", "One becomes two. Write the dual of أسد."),
        build_sentence_ex(L, "hear", ["الأسدُ", "كبير"], [audio("sentence.alasad-kabiir")],
                          "Listen to the sentence, then write it in order."),
    ]
    words = [
        {"id": "asad", "text": "أسد", "audio": "word.asad", "image": "img.lion",
         "gloss": {"en": "lion"}, "letters": ["alif", "seen", "daal"]},
        {"id": "umm", "text": "أم", "audio": "word.umm", "image": "img.mother",
         "gloss": {"en": "mother"}, "letters": ["alif", "meem"]},
        {"id": "baab", "text": "باب", "audio": "word.baab", "image": "img.door",
         "gloss": {"en": "door"}, "letters": ["baa", "alif", "baa"]},
    ]
    u = unit(L, [
        ("meet", ["alif.teachCard.meet"]),
        ("watchTrace", ["alif.traceLetter.isolated"]),
        ("forms", ["alif.writeLetter.fromSound", "alif.writeLetter.writeForm"]),
        ("words", ["alif.writeWord.dictation", "alif.writeWord.copy", "alif.writeWord.picture",
                   "alif.connectWord.baab"]),
        ("listenWrite", ["alif.transformWord.dual", "alif.buildSentence.hear"]),
        ("mastery", []),
    ])
    return ex, words, u


# ---------------------------------------------------------------------------
def main():
    letters = load(LETTERS)
    llist = letters if isinstance(letters, list) else letters["letters"]
    by_id = {L["id"]: L for L in llist}
    baa = by_id["baa"]

    # 1) letters.json — taa + alif contextualForms, signedOff:true
    by_id["taa"]["contextualForms"] = taa_forms_from_baa(baa)
    by_id["taa"]["signedOff"] = True
    by_id["alif"]["contextualForms"] = alif_forms(by_id["alif"])
    by_id["alif"]["signedOff"] = True
    save(LETTERS, letters)

    # 2) exercises.json
    exj = load(EXERCISES)
    elist = exj if isinstance(exj, list) else exj["exercises"]
    elist[:] = [e for e in elist if not e["id"].split(".")[0] in ("taa", "alif")]
    taa_ex, taa_words, taa_unit = build_taa()
    alif_ex, alif_words, alif_unit = build_alif()
    elist.extend(taa_ex + alif_ex)
    save(EXERCISES, exj)

    # 3) words.json
    wj = load(WORDS)
    wlist = wj if isinstance(wj, list) else wj["words"]
    have = {w["id"] for w in wlist}
    for w in taa_words + alif_words:
        if w["id"] not in have:
            wlist.append(w); have.add(w["id"])
    save(WORDS, wj)

    # 4) units.json
    uj = load(UNITS)
    ulist = uj if isinstance(uj, list) else uj["units"]
    ulist[:] = [u for u in ulist if u.get("letterId") not in ("taa", "alif")]
    ulist.extend([taa_unit, alif_unit])
    save(UNITS, uj)

    print(f"OK: taa={len(taa_ex)} exercises, alif={len(alif_ex)} exercises; "
          f"words +{len(taa_words)+len(alif_words)}; units now {[u['letterId'] for u in ulist]}")


if __name__ == "__main__":
    main()
