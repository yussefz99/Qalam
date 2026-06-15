#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build assets/images/manifest.json from the curriculum CONTENT-INVENTORY.

This is the generation SPEC for Qalam's vocab illustrations. It does NOT make
pixels — it produces the authoritative imageId -> {word, gloss, file, status}
map that an image-generation step (Codex / any image model) consumes, one word
per entry, anchored to ILLUSTRATION-STYLE.md.

Pure additive tooling: reads the inventory, writes the manifest. Touches no
engine code, no schema, no content drafts. Re-run whenever the inventory grows.

    python tools/illustrations/build_manifest.py
"""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INVENTORY = ROOT / ".planning/research/learning-experience/CONTENT-INVENTORY.json"
OUT = ROOT / "assets/images/manifest.json"

ARABIC = re.compile(r"[؀-ۿ]")
TASHKEEL = re.compile(r"[ً-ْٰـ]")  # harakat + superscript alef + tatweel


def norm(s: str) -> str:
    return TASHKEEL.sub("", s).strip()


def is_word(s) -> bool:
    """Real single-word Arabic vocab — rejects extraction artifacts."""
    if not isinstance(s, str) or not ARABIC.search(s):
        return False
    if any(sep in s for sep in (",", "/", "،")):  # joined lists in a word field
        return False
    n = norm(s)
    if len(n) <= 1:  # bare letters / form glyphs
        return False
    if " " in n:  # our vocab is single words; multiword = not a vocab item
        return False
    return True


# --- Canonical id + gloss for every vocab word (normalized, tashkeel-stripped).
# translit -> the img.<translit> slug (readable, phonetic, matches img.baab/img.arnab).
# gloss    -> English meaning for the image model ("door", "rabbit", ...).
# review   -> True when abstract/verb/color/number/ambiguous: don't force a picture,
#             the owner's mother decides (TASK-illustrations guardrail).
CURATED = {
    # --- concrete nouns that already carry a gloss/pictureShows in the inventory
    "أرنب": ("arnab", "rabbit"), "أفعى": ("afaa", "snake"), "أناناس": ("ananaas", "pineapple"),
    "إبريق": ("ibreeq", "jug"), "إصبع": ("isbaa", "finger"), "بئر": ("biar", "water well"),
    "باب": ("baab", "door"), "ببغاء": ("babbaghaa", "parrot"), "برتقال": ("burtuqaal", "orange"),
    "بط": ("batt", "ducks"), "بطيخ": ("bitteekh", "watermelon"), "بعوض": ("baoud", "mosquito"),
    "بقرة": ("baqara", "cow"), "بنطلون": ("bantaloon", "trousers"), "بيت": ("bait", "house"),
    "بيض": ("baid", "eggs"), "تفاح": ("tuffaah", "apple"), "ثعلب": ("thalab", "fox"),
    "ثلج": ("thalj", "snow"), "جبل": ("jabal", "mountain"), "جرذ": ("juradh", "rat"),
    "جرو": ("jarw", "puppy"), "جزر": ("jazar", "carrot"), "جمل": ("jamal", "camel"),
    "جندي": ("jundi", "soldier"), "جنزير": ("janzeer", "chain"), "حذاء": ("hidhaa", "shoes"),
    "حصان": ("hisaan", "horse"), "حلزون": ("halazoon", "snail"), "حمار": ("himaar", "donkey"),
    "حوت": ("hoot", "whale"), "خروف": ("kharoof", "sheep"), "خوخ": ("khookh", "peach"),
    "دار": ("daar", "house"), "درج": ("daraj", "stairs"), "دف": ("daff", "tambourine"),
    "دلو": ("dalw", "bucket"), "دماغ": ("dimaagh", "brain"), "دودة": ("dooda", "worm"),
    "دور": ("door", "houses"), "ديك": ("deek", "rooster"), "ذئب": ("dhiab", "wolf"),
    "رأس": ("raas", "head"), "رمان": ("rummaan", "pomegranate"), "ريش": ("reesh", "feathers"),
    "زورق": ("zawraq", "boat"), "زيتون": ("zaitoon", "olives"), "ساعة": ("saaa", "clock"),
    "سرير": ("sareer", "bed"), "سفينة": ("safeena", "ship"), "سلحفاة": ("sulhufaa", "turtle"),
    "سيارة": ("sayyaara", "car"), "شباك": ("shubbaak", "window"), "شجرة": ("shajara", "tree"),
    "شمس": ("shams", "sun"), "شموع": ("shumoo", "candles"), "صبر": ("sabr", "cactus"),
    "صحن": ("sahn", "plate"), "صمغ": ("samgh", "glue"), "صوص": ("sows", "chick"),
    "ضفدع": ("difda", "frog"), "طائرة": ("taaira", "airplane"), "ظبي": ("dhabi", "gazelle"),
    "عصا": ("asaa", "walking stick"), "عصفور": ("usfoor", "sparrow"), "عنب": ("inab", "grapes"),
    "غيمة": ("ghaima", "cloud"), "فأر": ("far", "mouse"), "فار": ("faar", "mouse"),
    "فراش": ("firaash", "butterflies"), "فراشة": ("faraasha", "butterfly"),
    "فنجان": ("finjaan", "cup"), "فيل": ("feel", "elephant"), "قرد": ("qird", "monkey"),
    "قفص": ("qafas", "cage"), "قلم": ("qalam", "pen"), "قمر": ("qamar", "moon"),
    "قن": ("qann", "chicken coop"), "قنفذ": ("qunfudh", "hedgehog"), "كرز": ("karaz", "cherry"),
    "كرسي": ("kursi", "chair"), "كلب": ("kalb", "dog"), "كنغر": ("kangar", "kangaroo"),
    "ليمون": ("laimoon", "lemon"), "ماعز": ("maaiz", "goat"), "مثلث": ("muthallath", "triangle"),
    "مثمن": ("muthamman", "octagon"), "محراث": ("mihraath", "plough"), "مشط": ("musht", "comb"),
    "مظلة": ("midhalla", "umbrella"), "معلم": ("muallim", "teacher"), "مفتاح": ("miftaah", "key"),
    "مقص": ("miqass", "scissors"), "مكتوب": ("maktoob", "envelope / letter"),
    "ملح": ("milh", "salt"), "مهرج": ("muharrij", "clown"), "موز": ("mooz", "banana"),
    "نار": ("naar", "fire"), "نجوم": ("nujoom", "stars"), "نحلة": ("nahla", "bee"),
    "نخلة": ("nakhla", "palm tree"), "نمر": ("nimr", "tiger"), "هاتف": ("haatif", "telephone"),
    "هلال": ("hilaal", "crescent moon"), "وردة": ("warda", "rose"), "وطواط": ("watwaat", "bat"),
    "ولد": ("walad", "boy"), "يد": ("yad", "hand"),
    # --- concrete nouns that had no gloss in the inventory (curated here)
    "أثاث": ("athaath", "furniture"), "أسد": ("asad", "lion"), "باذنجان": ("baadhinjaan", "eggplant"),
    "بحر": ("bahr", "sea"), "برج": ("burj", "tower"), "بصل": ("basal", "onion"),
    "بطاطا": ("bataata", "potato"), "بطة": ("batta", "duck"), "بطريق": ("batreeq", "penguin"),
    "بلح": ("balah", "dates"), "بنت": ("bint", "girl"), "بومة": ("booma", "owl"),
    "بيضة": ("baida", "egg"), "تاج": ("taaj", "crown"), "تفاحة": ("tuffaaha", "apple"),
    "تلفاز": ("tilfaaz", "television"), "تمر": ("tamr", "dates"), "تمساح": ("timsaah", "crocodile"),
    "توت": ("toot", "berries"), "تين": ("teen", "fig"), "ثعبان": ("thuabaan", "snake"),
    "ثمر": ("thamar", "fruit"), "ثوب": ("thawb", "garment"), "ثور": ("thawr", "bull"),
    "ثوم": ("thoom", "garlic"), "جريدة": ("jareeda", "newspaper"), "جوز": ("jawz", "walnut"),
    "حافلة": ("haafila", "bus"), "حقيبة": ("haqeeba", "bag"), "حلوى": ("halwa", "sweets"),
    "حليب": ("haleeb", "milk"), "حمامة": ("hamaama", "dove"), "خبز": ("khubz", "bread"),
    "خيمة": ("khaima", "tent"), "دائرة": ("daaira", "circle"), "دب": ("dubb", "bear"),
    "دجاج": ("dajaaj", "chickens"), "دجاجة": ("dajaaja", "hen"), "دخان": ("dukhaan", "smoke"),
    "دراجة": ("darraaja", "bicycle"), "دكان": ("dukkaan", "shop"), "ديناصور": ("deenaasoor", "dinosaur"),
    "ذبابة": ("dhubaaba", "fly"), "ذرة": ("dhura", "corn"), "رجل": ("rajul", "man"),
    "رسالة": ("risaala", "letter / message"), "رغيف": ("ragheef", "loaf of bread"),
    "ريشة": ("reesha", "feather"), "زهرة": ("zahra", "flower"), "زيت": ("zait", "oil"),
    "سمكة": ("samaka", "fish"), "سهم": ("sahm", "arrow"), "صاروخ": ("saarookh", "rocket"),
    "صخرة": ("sakhra", "rock"), "صندوق": ("sundooq", "box"), "صياد": ("sayyaad", "fisherman"),
    "طبيب": ("tabeeb", "doctor"), "طماطم": ("tamaatim", "tomato"), "ظرف": ("dharf", "envelope"),
    "ظفر": ("dhufr", "fingernail"), "عجين": ("ajeen", "dough"), "عش": ("ushsh", "nest"),
    "غسالة": ("ghassaala", "washing machine"), "فراولة": ("faraawla", "strawberry"),
    "فستان": ("fustaan", "dress"), "فهد": ("fahd", "cheetah"), "فواكه": ("fawaakih", "fruits"),
    "قطة": ("qitta", "cat"), "قفاز": ("quffaaz", "glove"), "قلب": ("qalb", "heart"),
    "كأس": ("kaas", "cup"), "كتاب": ("kitaab", "book"), "كرة": ("kura", "ball"),
    "كعكة": ("kaka", "cake"), "كمامة": ("kimaama", "face mask"), "كمثرى": ("kummathra", "pear"),
    "كنز": ("kanz", "treasure"), "كهف": ("kahf", "cave"), "كوخ": ("kookh", "hut"),
    "كوسا": ("koosa", "zucchini"), "لحم": ("lahm", "meat"), "لسان": ("lisaan", "tongue"),
    "ليث": ("laith", "lion"), "مسجد": ("masjid", "mosque"), "مصباح": ("misbaah", "lamp"),
    "مكنسة": ("miknasa", "broom"), "مكواة": ("mikwaa", "iron"), "مهر": ("muhr", "foal"),
    "نبات": ("nabaat", "plant"), "نجمة": ("najma", "star"), "نهر": ("nahr", "river"),
    "هدية": ("hadiyya", "gift"), "هرة": ("hirra", "cat"), "وجه": ("wajh", "face"),
    "ورقة": ("waraqa", "paper / leaf"),
    # --- abstract / verb / color / number / ambiguous: keep id+gloss but FLAG for the mother
    "أخضر": ("akhdar", "green (colour)"), "أزرق": ("azraq", "blue (colour)"),
    "أسود": ("aswad", "black (colour)"), "استيقظ": ("istaiqadh", "woke up (verb)"),
    "محظوظ": ("mahdhoodh", "lucky (adjective)"), "اثنان": ("ithnaan", "two (number)"),
    "خطأ": ("khataa", "mistake / wrong"), "قرأ": ("qaraa", "read (verb)"),
    "خرج": ("kharaj", "went out (verb)"), "ضحك": ("dahk", "laughter"),
    "فرح": ("farah", "joy"), "حديث": ("hadeeth", "modern / speech"),
    "مثل": ("mathal", "proverb / like"), "مهدد": ("muhaddad", "threatened (uncertain word)"),
    "هدى": ("huda", "guidance / a name"), "يضحك": ("yadhak", "he laughs (verb)"),
    "يكتب": ("yaktub", "he writes (verb)"), "علم": ("alam", "flag — or 'knowledge' (ambiguous)"),
}

REVIEW = {
    "أخضر", "أزرق", "أسود", "استيقظ", "محظوظ", "اثنان", "خطأ", "قرأ", "خرج",
    "ضحك", "فرح", "حديث", "مثل", "مهدد", "هدى", "يضحك", "يكتب", "علم",
}

# Existing image ids already referenced in the prototype's EXERCISE-CONFIGS.json.
# The convention is img.<translit>, but a few words were wired with english-gloss
# ids. We keep translit as the canonical id and record the existing id as an alias
# so those references keep resolving. See _meta.idSchemeConflict.
EXISTING_ALIASES = {
    "باب": ["img.door"],   # baa.writeWord.picture, baa.teachCard.meet
    "بطة": ["img.duck"],   # baa.writeLetter.fromPicture
    "حليب": ["img.milk"],  # named in the baa word-set tooling
}


def main() -> int:
    data = json.loads(INVENTORY.read_text(encoding="utf-8"))

    found: dict[str, dict] = {}  # normalized word -> {gloss}
    for f in data.get("perFile", []):
        for v in f.get("vocab", []):
            w = v.get("word") if isinstance(v, dict) else v
            g = v.get("gloss") if isinstance(v, dict) else None
            if is_word(w):
                n = norm(w)
                found.setdefault(n, {"gloss": None})
                if g and not found[n]["gloss"]:
                    found[n]["gloss"] = g
        for it in f.get("items", []):
            w, g = it.get("word"), it.get("pictureShows")
            if is_word(w):
                n = norm(w)
                found.setdefault(n, {"gloss": None})
                if g and not found[n]["gloss"]:
                    found[n]["gloss"] = g

    entries = {}
    uncurated, id_collisions = [], {}
    for word in sorted(found):
        if word in CURATED:
            translit, gloss = CURATED[word]
        else:
            # Fallback: should not happen while the curated map covers the inventory.
            uncurated.append(word)
            translit = re.sub(r"[^a-z]", "", word.encode("ascii", "ignore").decode()) or "x"
            gloss = found[word]["gloss"]
        image_id = f"img.{translit}"
        id_collisions.setdefault(image_id, []).append(word)
        entry = {
            "imageId": image_id,
            "word": word,
            "gloss": gloss,
            "file": f"{image_id}.webp",
            "status": "pending",  # no pixels yet — image-generation step fills these
        }
        if word in REVIEW:
            entry["needsReview"] = True
        if word in EXISTING_ALIASES:
            entry["aliases"] = EXISTING_ALIASES[word]
        entries[image_id] = entry

    collisions = {k: v for k, v in id_collisions.items() if len(v) > 1}
    review_count = sum(1 for e in entries.values() if e.get("needsReview"))

    manifest = {
        "_meta": {
            "purpose": "Generation spec for Qalam vocab illustrations. imageId -> word/gloss/file. "
                       "Placeholders are swappable by imageId (same pattern as assets/audio/). "
                       "status:'pending' = pixels not yet generated.",
            "source": ".planning/research/learning-experience/CONTENT-INVENTORY.json",
            "styleGuide": "assets/images/ILLUSTRATION-STYLE.md",
            "builtBy": "tools/illustrations/build_manifest.py (re-run when the inventory changes)",
            "wordCount": len(entries),
            "needsReviewCount": review_count,
            "idScheme": "img.<translit> (phonetic slug), matching img.baab / img.arnab.",
            "idSchemeConflict": "EXERCISE-CONFIGS.json wired a few words with english-gloss ids "
                                "(img.door=باب, img.duck=بطة, img.milk=حليب). "
                                "Canonical id here is the translit; the existing id is kept under 'aliases'. "
                                "OWNER DECISION NEEDED: pick one scheme, then drop the alias or rename the file.",
            "needsReviewMeaning": "Abstract / verb / colour / number / ambiguous word — do NOT force a "
                                  "picture; the owner's mother decides whether & how to depict it.",
            "signedOff": False,
        },
        "images": [entries[k] for k in sorted(entries)],
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    sys.stdout.reconfigure(encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")
    print(f"  {len(entries)} images  ({review_count} flagged needsReview)")
    if uncurated:
        print(f"  WARNING uncurated words (algorithmic translit/gloss): {uncurated}")
    if collisions:
        print(f"  WARNING imageId collisions: {collisions}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
