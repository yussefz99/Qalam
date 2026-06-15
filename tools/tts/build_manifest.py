#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build tools/tts/manifest.full.json — the {id, text} list generate_audio.py
synthesizes into assets/audio/<audioId>.mp3.

SOURCE OF TRUTH = the curriculum CONTENT (not a translit guess), so every
generated clip's id is exactly the audioId the app resolves. With the Phase 8
convention fallback (asset_audio_player.dart: an unmapped dotted audioId →
assets/audio/<id>.mp3), a clip named after its content audioId just plays.

Covers the authored content (currently the alif/baa/taa demo letters):
  • letter SOUNDS  — `snd.<id>` for all 28 in assets/curriculum/letters.json,
    spoken as the letter + fatha (the /Ca/ sound, like snd.baa = "بَ").
  • VOCAB          — each word in assets/curriculum/words.json, using its own
    `audio` id and `text` (so word.bayt / word.tuut match content, not a guess).
  • SENTENCES      — every `sentence.*` audioId in assets/curriculum/exercises.json,
    text = its expected words joined.

Re-runnable; re-run as content grows. Writes only tools/tts/manifest.full.json.

    python tools/tts/build_manifest.py
"""
from __future__ import annotations
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
LETTERS = ROOT / "assets/curriculum/letters.json"
WORDS = ROOT / "assets/curriculum/words.json"
EXERCISES = ROOT / "assets/curriculum/exercises.json"
OUT = ROOT / "tools/tts/manifest.full.json"
FATHA = "َ"  # ـَ — gives the letter its /Ca/ sound, like snd.baa = "بَ"


def _load(p: pathlib.Path):
    return json.loads(p.read_text(encoding="utf-8"))


def main() -> int:
    for s in (sys.stdout, sys.stderr):
        try:
            s.reconfigure(encoding="utf-8")
        except Exception:
            pass

    entries: list[dict[str, str]] = []
    seen: set[str] = set()

    def add(aid: str, text: str) -> None:
        if aid and text and aid not in seen:
            seen.add(aid)
            entries.append({"id": aid, "text": text})

    # 1) Letter sounds — snd.<id>, char + fatha (all 28 defined letters).
    letters = _load(LETTERS)
    letter_list = letters if isinstance(letters, list) else letters["letters"]
    for L in letter_list:
        add(f"snd.{L['id']}", f"{L['char']}{FATHA}")
    n_letters = len(seen)

    # 2) Vocab — each word's own audio id + Arabic text (content's scheme).
    words = _load(WORDS)
    word_list = words if isinstance(words, list) else words["words"]
    for w in word_list:
        aid = w.get("audio") or f"word.{w.get('id', '')}"
        add(aid, w.get("text", ""))
    n_vocab = len(seen) - n_letters

    # 3) Sentences — every sentence.* audioId in exercises.json, text = expected
    #    words joined (the buildSentence exercises carry both).
    ex = _load(EXERCISES)
    ex_list = ex if isinstance(ex, list) else ex.get("exercises", [])
    for e in ex_list:
        blob = json.dumps(e, ensure_ascii=False)
        for sid in set(re.findall(r"sentence\.[A-Za-z0-9_-]+", blob)):
            exp = e.get("expected") if isinstance(e, dict) else None
            words_arr = exp.get("words") if isinstance(exp, dict) else None
            if words_arr:
                add(sid, " ".join(words_arr))
    n_sent = len(seen) - n_letters - n_vocab

    OUT.write_text(
        json.dumps(entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {OUT.relative_to(ROOT)}")
    print(f"  {len(entries)} clips: {n_letters} letter sounds + {n_vocab} vocab + {n_sent} sentences")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
