"""Arabic word → letterId decomposition for Qalam.

Turns an Arabic string into the **written skeleton**: the ordered list of the
letters a child actually writes, mapped to the 28 curriculum letterIds in
`assets/curriculum/letters.json`. This is deliberately the *written* form, not
the *pronounced* one — a shadda geminates the sound but the letter is written
once (مُثَلّث → م ث ل ث, not …ل ل…).

Design rule from the brief: **handle the traps explicitly, never guess.** Every
character that isn't one of the 28 base letters is routed through an explicit
table and tagged with a `DecompFlag` so a report can surface it for the owner's
mother — we never silently invent a mapping.

The traps, and how they're handled (all flagged for review visibility):
  * harakat / shadda / sukun / tanwin / superscript alef / tatweel → stripped
  * أ إ آ ٱ (hamza/madda on alif)  → alif        (established: words.json أسد→alif)
  * ة (taa marbuta)               → taa_marbuta  (special: not a taught letter;
                                                  the app's own letters[] use this id)
  * ى (alif maqsura)              → alif   (PROVISIONAL — written like yaa, sounds
                                            like alif; the mother confirms placement)
  * ؤ (hamza on waw)              → waaw   (PROVISIONAL)
  * ئ (hamza on yaa)              → yaa    (PROVISIONAL)
  * ء (standalone hamza)          → UNMAPPABLE — omitted from letters[], word flagged
  * لا and its ligatures          → laam + alif
"""

from __future__ import annotations

import unicodedata
from dataclasses import dataclass, field
from enum import Enum

# --- the 28 taught base letters: Arabic char -> curriculum letterId ----------
BASE_LETTERS: dict[str, str] = {
    "ا": "alif",
    "ب": "baa",
    "ت": "taa",
    "ث": "thaa",
    "ج": "jeem",
    "ح": "haa_c",
    "خ": "khaa",
    "د": "daal",
    "ذ": "dhaal",
    "ر": "raa",
    "ز": "zaay",
    "س": "seen",
    "ش": "sheen",
    "ص": "saad",
    "ض": "daad",
    "ط": "taa_h",
    "ظ": "zhaa",
    "ع": "ayn",
    "غ": "ghayn",
    "ف": "faa",
    "ق": "qaaf",
    "ك": "kaaf",
    "ل": "laam",
    "م": "meem",
    "ن": "noon",
    "ه": "haa_f",
    "و": "waaw",
    "ي": "yaa",
}

# Non-letter marks to strip before decomposing (harakat, shadda, sukun, tanwin,
# superscript alef, tatweel/kashida, zero-width joiners).
_STRIP = {
    "ً",  # tanwin fath
    "ٌ",  # tanwin damm
    "ٍ",  # tanwin kasr
    "َ",  # fatha
    "ُ",  # damma
    "ِ",  # kasra
    "ّ",  # shadda
    "ْ",  # sukun
    "ٓ",  # madda above (combining)
    "ٔ",  # hamza above (combining)
    "ٕ",  # hamza below (combining)
    "ٰ",  # superscript alef
    "ـ",  # tatweel / kashida
    "‌",  # zero-width non-joiner
    "‍",  # zero-width joiner
    "‎",  # LRM
    "‏",  # RLM
}


class DecompFlag(Enum):
    """Why a character needed special handling (for the review report)."""

    HAMZA_ALIF = "hamza_alif"          # أ إ آ ٱ -> alif (established convention)
    TAA_MARBUTA = "taa_marbuta"        # ة -> taa_marbuta (special, not a taught letter)
    ALIF_MAQSURA = "alif_maqsura"      # ى -> alif (provisional)
    HAMZA_WAW = "hamza_waw"            # ؤ -> waaw (provisional)
    HAMZA_YAA = "hamza_yaa"            # ئ -> yaa (provisional)
    HAMZA_STANDALONE = "hamza_standalone"  # ء -> unmappable, omitted
    UNMAPPABLE = "unmappable"          # any other non-space char we can't place


# Explicit special-form table: char -> (letterId or None, flag).
_SPECIAL: dict[str, tuple[str | None, DecompFlag]] = {
    "أ": ("alif", DecompFlag.HAMZA_ALIF),
    "إ": ("alif", DecompFlag.HAMZA_ALIF),
    "آ": ("alif", DecompFlag.HAMZA_ALIF),
    "ٱ": ("alif", DecompFlag.HAMZA_ALIF),
    "ة": ("taa_marbuta", DecompFlag.TAA_MARBUTA),
    "ى": ("alif", DecompFlag.ALIF_MAQSURA),
    "ؤ": ("waaw", DecompFlag.HAMZA_WAW),
    "ئ": ("yaa", DecompFlag.HAMZA_YAA),
    "ء": (None, DecompFlag.HAMZA_STANDALONE),
}

# Lam-alif ligatures decompose to laam + alif.
_LAM_ALIF = {"ﻻ", "ﻼ", "ﻷ", "ﻸ", "ﻹ", "ﻺ", "ﻵ", "ﻶ"}

# Letters whose decomposition is confident enough to gate legality on (the 28
# base ids plus the app's own taa_marbuta convention). ALIF_MAQSURA / HAMZA_WAW
# / HAMZA_YAA stay provisional; HAMZA_STANDALONE / UNMAPPABLE block a verdict.
CONFIDENT_FLAGS = {DecompFlag.HAMZA_ALIF, DecompFlag.TAA_MARBUTA}
PROVISIONAL_FLAGS = {DecompFlag.ALIF_MAQSURA, DecompFlag.HAMZA_WAW, DecompFlag.HAMZA_YAA}
BLOCKING_FLAGS = {DecompFlag.HAMZA_STANDALONE, DecompFlag.UNMAPPABLE}


@dataclass
class Decomposition:
    """Result of decomposing one Arabic string."""

    text: str
    letters: list[str] = field(default_factory=list)
    # (index_in_letters_or_-1, char, flag) for every special/flagged char.
    flags: list[tuple[int, str, DecompFlag]] = field(default_factory=list)

    @property
    def is_clean(self) -> bool:
        """True when every character mapped confidently to a base letter."""
        return not self.flags

    @property
    def has_blocking(self) -> bool:
        """True when a character could not be placed (report, never guess)."""
        return any(f in BLOCKING_FLAGS for _, _, f in self.flags)

    @property
    def has_provisional(self) -> bool:
        return any(f in PROVISIONAL_FLAGS for _, _, f in self.flags)


def strip_harakat(text: str) -> str:
    """Remove harakat, shadda, tatweel and bidi marks; keep letters + spaces."""
    normalized = unicodedata.normalize("NFC", text)
    return "".join(ch for ch in normalized if ch not in _STRIP)


def decompose(text: str) -> Decomposition:
    """Decompose an Arabic word/phrase into curriculum letterIds.

    Spaces are treated as word separators and skipped (a multi-word phrase
    decomposes to the concatenation of its letters). Every non-base character is
    recorded in ``flags`` with its :class:`DecompFlag`.
    """
    cleaned = strip_harakat(text)
    result = Decomposition(text=text)

    for ch in cleaned:
        if ch.isspace():
            continue
        if ch in BASE_LETTERS:
            result.letters.append(BASE_LETTERS[ch])
            continue
        if ch in _LAM_ALIF:
            result.letters.extend(["laam", "alif"])
            continue
        if ch in _SPECIAL:
            letter_id, flag = _SPECIAL[ch]
            if letter_id is not None:
                result.letters.append(letter_id)
                result.flags.append((len(result.letters) - 1, ch, flag))
            else:
                result.flags.append((-1, ch, flag))
            continue
        # Anything else: try NFKD to peel a presentation form back to a base
        # letter; otherwise it is genuinely unmappable — flag, don't guess.
        decomposed = unicodedata.normalize("NFKD", ch)
        base = next((c for c in decomposed if c in BASE_LETTERS), None)
        if base is not None:
            result.letters.append(BASE_LETTERS[base])
        else:
            result.flags.append((-1, ch, DecompFlag.UNMAPPABLE))

    return result
