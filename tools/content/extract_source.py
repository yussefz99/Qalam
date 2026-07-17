"""Extract the owner's-mother's teaching materials into a per-letter source digest.

Reads the raw worksheet drop (``.docx`` text natively; ``.pdf`` attempted, but most
are scanned images and yield nothing). For every file it maps to a letter (by the
Arabic letter name in the filename / body), pulls the activity text and candidate
vocabulary (tokens containing the focus letter), and writes:

  * ``docs/curriculum/drafts/source-digest/<letterId>.md`` — readable per letter;
  * ``docs/curriculum/drafts/source-digest/index.json`` — machine-readable, so the
    exercise generator can cite HER words and flag image-only letters.

We never guess: a file whose text won't extract is recorded as ``imageOnly`` so the
exercise generator knows to fall back to flagged draft-bank vocab, not invent hers.

Run from ``tools/``:  ``python -m content.extract_source [<raw_folder>]``
"""

from __future__ import annotations

import html
import json
import re
import sys
import unicodedata
import zipfile
from pathlib import Path

from .arabic import BASE_LETTERS, strip_harakat

REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = REPO_ROOT / "docs" / "curriculum" / "drafts" / "source-digest"

# Arabic letter name (as it appears in filenames) -> letterId.
NAME_TO_ID = {
    "الالف": "alif", "الألف": "alif", "الهمزة": "alif",
    "الباء": "baa", "التاء": "taa", "الثاء": "thaa",
    "الجيم": "jeem", "الحاء": "haa_c", "الخاء": "khaa",
    "الدال": "daal", "الذال": "dhaal", "الراء": "raa", "الزاي": "zaay",
    "السين": "seen", "الشين": "sheen", "الصاد": "saad", "الضاد": "daad",
    "الطاء": "taa_h", "الظاء": "zhaa", "العين": "ayn", "الغين": "ghayn",
    "الفاء": "faa", "القاف": "qaaf", "الكاف": "kaaf", "اللام": "laam",
    "الميم": "meem", "النون": "noon", "الهاء": "haa_f", "الواو": "waaw",
    "الياء": "yaa",
}
# Single-letter fallbacks (e.g. file just named "ن.docx").
CHAR_TO_ID = dict(BASE_LETTERS)


def docx_text(path: Path) -> str:
    """Extract paragraph text from a .docx (no external deps)."""
    try:
        with zipfile.ZipFile(path) as z:
            xml = z.read("word/document.xml").decode("utf-8", "ignore")
    except Exception:
        return ""
    xml = re.sub(r"</w:p>", "\n", xml)
    xml = re.sub(r"<[^>]+>", "", xml)
    text = html.unescape(xml)
    # Drop the drawing-position integers docx leaves in the stream.
    lines = []
    for line in text.splitlines():
        stripped = re.sub(r"[-\d]+", "", line).strip()
        if stripped:
            lines.append(stripped)
    # De-duplicate consecutive repeats (docx often doubles paragraph text).
    out: list[str] = []
    for line in lines:
        if not out or out[-1] != line:
            out.append(line)
    return "\n".join(out)


def pdf_text(path: Path) -> str:
    """Best-effort PDF text (scanned worksheets yield nothing; that's expected)."""
    try:
        from pdfminer.high_level import extract_text  # type: ignore
    except Exception:
        return ""
    try:
        return extract_text(str(path)) or ""
    except Exception:
        return ""


def letter_for(path: Path, text: str) -> str | None:
    name = strip_harakat(path.stem)
    for key, lid in NAME_TO_ID.items():
        if strip_harakat(key) in name:
            return lid
    # Single Arabic char filename.
    for ch in name:
        if ch in CHAR_TO_ID:
            return CHAR_TO_ID[ch]
    return None


def candidate_words(text: str, letter_char: str) -> list[str]:
    """Arabic tokens (>=2 letters) that contain the focus letter char."""
    words: list[str] = []
    seen: set[str] = set()
    for token in re.findall(r"[؀-ۿ]+", text):
        bare = strip_harakat(token)
        if len(bare) < 2 or letter_char not in bare:
            continue
        # Skip pure instruction words we can detect crudely (keep it permissive).
        if token not in seen:
            seen.add(token)
            words.append(token)
    return words


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    if argv:
        raw = Path(argv[0])
    else:
        candidates = sorted(REPO_ROOT.glob("رنو*")) + sorted(REPO_ROOT.glob("*source*"))
        raw = next((c for c in candidates if c.is_dir()), None)
    if not raw or not raw.exists():
        print("Raw source folder not found. Pass its path as an argument.")
        return 1

    char_for_id = {v: k for k, v in BASE_LETTERS.items()}
    per_letter: dict[str, dict] = {}
    unmapped: list[str] = []

    for f in sorted(p for p in raw.rglob("*") if p.is_file()):
        suffix = f.suffix.lower()
        if suffix == ".docx":
            text = docx_text(f)
        elif suffix == ".pdf":
            text = pdf_text(f)
        else:
            continue
        lid = letter_for(f, text)
        rec = {"file": f.name, "type": suffix.lstrip("."), "chars": len(text),
               "imageOnly": len(text.strip()) < 15}
        if lid is None:
            unmapped.append(f.name)
            rec["letter"] = None
        entry = per_letter.setdefault(lid or "_unmapped", {"files": [], "words": []})
        entry["files"].append(rec)
        if lid and not rec["imageOnly"]:
            ch = char_for_id.get(lid, "")
            for w in candidate_words(text, ch):
                if w not in entry["words"]:
                    entry["words"].append(w)
        rec["text"] = text

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Machine-readable index (no full text — just files, flags, candidate words).
    index = {
        "_meta": {
            "source": raw.name,
            "note": "Extracted from the owner's-mother's worksheets. imageOnly=true means "
                    "the file is a scanned/tracing image with no extractable text — the "
                    "exercise generator falls back to flagged draft-bank vocab for that letter.",
        },
        "letters": {
            lid: {
                "files": [{k: v for k, v in r.items() if k != "text"} for r in e["files"]],
                "candidateWords": e["words"],
                "anyTextExtracted": any(not r["imageOnly"] for r in e["files"]),
            }
            for lid, e in sorted(per_letter.items())
        },
    }
    (OUT_DIR / "index.json").write_text(
        json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n"
    )

    # Per-letter readable digests.
    for lid, e in sorted(per_letter.items()):
        lines = [f"# Source digest — {lid}", ""]
        for r in e["files"]:
            flag = " · **image-only (no text)**" if r["imageOnly"] else ""
            lines.append(f"## {r['file']} ({r['type']}, {r['chars']} chars){flag}")
            if r.get("text", "").strip():
                lines.append("")
                lines.append("```")
                lines.append(r["text"].strip())
                lines.append("```")
            lines.append("")
        if e["words"]:
            lines.append(f"**Candidate words (contain {lid}):** " + " · ".join(e["words"]))
            lines.append("")
        (OUT_DIR / f"{lid}.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    # Console coverage report.
    mapped = {k: v for k, v in per_letter.items() if k != "_unmapped"}
    with_text = [k for k, v in mapped.items() if any(not r["imageOnly"] for r in v["files"])]
    image_only = [k for k in mapped if k not in with_text]
    print(f"Extracted {sum(len(v['files']) for v in per_letter.values())} file(s) "
          f"from {raw.name} -> {OUT_DIR.relative_to(REPO_ROOT)}")
    print(f"  letters with extractable text ({len(with_text)}): {', '.join(sorted(with_text))}")
    print(f"  letters image-only ({len(image_only)}): {', '.join(sorted(image_only))}")
    if unmapped:
        print(f"  unmapped files ({len(unmapped)}): {', '.join(unmapped)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
