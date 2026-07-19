"""Letter-legality validator — the report the owner takes into the mother's sessions.

Two jobs, both read-only against the curriculum:

  1. DRAFT bank (``words_draft.json``): for every word, the earliest intro-order
     unit at which it becomes legal (all its letters already introduced), and —
     per focus letter — which candidate words are on-time vs. which reach ahead
     for letters not yet taught.

  2. LIVE content (``assets/curriculum/words.json`` + ``exercises.json``): any
     existing content that demands unlearned letters, plus a consistency check
     of each live word's stored ``letters[]`` against the computed decomposition
     (this is where the بطة / توت drift shows up). Goes straight into the Phase 19
     card-rewrite session.

Writes a markdown report and prints a summary. Exits non-zero only if OUR OWN
draft bank has a blocking (unmappable) decomposition — live findings are report
content, not build failures (the live files are the owner's to fix).

Run from ``tools/``:  ``python -m content.validate``
"""

from __future__ import annotations

import json
from pathlib import Path

from .arabic import BASE_LETTERS, decompose

REPO_ROOT = Path(__file__).resolve().parents[2]
PKG_DIR = Path(__file__).resolve().parent

LETTERS_JSON = REPO_ROOT / "assets" / "curriculum" / "letters.json"
LIVE_WORDS_JSON = REPO_ROOT / "assets" / "curriculum" / "words.json"
EXERCISES_JSON = REPO_ROOT / "assets" / "curriculum" / "exercises.json"
GRAPHS_DIR = REPO_ROOT / "assets" / "curriculum" / "graphs"
CURRICULUM_GRAPH_JSON = REPO_ROOT / "assets" / "curriculum" / "curriculum_graph.json"
DRAFT_JSON = PKG_DIR / "words_draft.json"
REPORT_MD = PKG_DIR / "validation_report.md"

# taa_marbuta is used by the app's letters[] but is NOT one of the 28 taught
# letters, so it can't be gated on an introOrder. We surface it, never guess.
SPECIAL_NON_TAUGHT = {"taa_marbuta"}

# --------------------------------------------------------------------------- #
# The seen-letters wall (Phase 25, D-04..D-09) — the ONE definition L0/L1/L2 share
# --------------------------------------------------------------------------- #
#
# The wall's thesis: all four layers (L0 audit here, L1 Dart lint, L2 seeder, L3
# runtime guard) must refuse the SAME thing. This module is L0 AND the parity
# source of truth — L2 (``seed_curriculum_v2.py``) imports the predicate + the two
# scoping helpers below so the seeder and the audit cannot drift apart.

# Owner-approved (device UAT, 2026-07-18), mother-approval-PENDING baa exceptions
# (D-09). Mirror of the Dart lint's ``baaOwnerApprovedExceptions``
# (learned_letters_lint_test.dart). These 4 reach-ahead baa cards are exempt from
# the build gate + the seeder refusal until the mother confirms / re-points them in
# the Phase-25 packet — exactly the set L1 exempts, so L0/L1/L2 fail on the SAME
# cards.
OWNER_APPROVED_EXCEPTIONS: frozenset[str] = frozenset(
    {
        "baa.fillBlank.adjective",
        "baa.transformWord.dual",
        "baa.transformWord.plural",
        "baa.transformWord.opposite",
    }
)

# A stored letter absent from letters.json ``introOrder`` (e.g. taa_marbuta, a
# non-taught special form) is treated as reaching ahead — the same sentinel the
# Dart lint uses (``introOrder[l] ?? 1 << 30``), so the two predicates agree.
_UNLEARNED_SENTINEL = 1 << 30


def _load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_intro_order() -> dict[str, int]:
    """letterId -> introOrder for the 28 taught letters."""
    data = _load(LETTERS_JSON)
    return {l["id"]: int(l["introOrder"]) for l in data["letters"]}


def _base_members(letters: list[str]) -> list[str]:
    """The subset of a decomposition that are taught (28-letter) ids."""
    taught = set(BASE_LETTERS.values())
    return [l for l in letters if l in taught]


def earliest_legal_unit(letters: list[str], order: dict[str, int]) -> int | None:
    """Intro-order at which every taught letter in the word is introduced.

    Returns None when the word has no taught letters at all (pure special forms).
    """
    members = _base_members(letters)
    if not members:
        return None
    return max(order[l] for l in members)


def _specials_in(letters: list[str]) -> list[str]:
    taught = set(BASE_LETTERS.values())
    return [l for l in letters if l not in taught]


# --------------------------------------------------------------------------- #
# Report sections
# --------------------------------------------------------------------------- #

def report_draft(order: dict[str, int]) -> tuple[list[str], int]:
    """Draft-bank legality. Returns (markdown lines, blocking_count)."""
    doc = _load(DRAFT_JSON)
    words = doc["words"]
    id_to_order = order
    order_to_letter = {v: k for k, v in order.items()}

    lines = ["## 1 · Draft bank — letter legality", ""]
    lines.append(
        f"{len(words)} candidate words. A word is *legal at unit N* when every "
        "taught letter it uses has been introduced by intro-order N. Words that "
        "reach past their focus letter are candidates to teach later (or to swap)."
    )
    lines.append("")

    # Per focus letter, on-time vs reaches-ahead.
    by_focus: dict[str, list[dict]] = {}
    for w in words:
        by_focus.setdefault(w["focusLetter"], []).append(w)

    blocking = 0
    lines.append("| focus (order) | word | gloss | legal at unit | verdict | notes |")
    lines.append("|---|---|---|---|---|---|")
    for focus in sorted(by_focus, key=lambda f: id_to_order.get(f, 99)):
        f_order = id_to_order.get(focus, 99)
        for w in by_focus[focus]:
            legal = earliest_legal_unit(w["letters"], id_to_order)
            specials = _specials_in(w["letters"])
            note_bits = []
            if specials:
                note_bits.append("contains " + ", ".join(sorted(set(specials))))
            d = decompose(w["text"])
            if d.has_blocking:
                blocking += 1
                note_bits.append("**BLOCKING decomposition**")
            if legal is None:
                verdict = "n/a"
                legal_txt = "—"
            elif legal <= f_order:
                verdict = "on-time"
                legal_txt = f"{legal} ({order_to_letter.get(legal,'?')})"
            else:
                verdict = "reaches ahead"
                legal_txt = f"{legal} ({order_to_letter.get(legal,'?')})"
            lines.append(
                f"| {focus} ({f_order}) | {w['text']} | {w['gloss']['en']} | "
                f"{legal_txt} | {verdict} | {'; '.join(note_bits)} |"
            )
    lines.append("")

    # Which words unlock at each unit (cumulative legality view).
    lines.append("### Words unlocked at each intro-order unit")
    lines.append("")
    lines.append("| unit | letter | newly-legal draft words |")
    lines.append("|---|---|---|")
    for n in sorted(order.values()):
        letter = order_to_letter[n]
        newly = [
            w["text"]
            for w in words
            if earliest_legal_unit(w["letters"], id_to_order) == n
        ]
        lines.append(f"| {n} | {letter} | {' · '.join(newly) if newly else '—'} |")
    lines.append("")
    return lines, blocking


def report_live_words(order: dict[str, int]) -> list[str]:
    """Consistency of live words.json stored letters[] vs computed decomposition."""
    doc = _load(LIVE_WORDS_JSON)
    words = doc["words"]
    lines = ["## 2 · Live `words.json` — stored vs computed `letters[]`", ""]
    lines.append(
        "Recomputes each live word's decomposition and compares it to the stored "
        "`letters[]`. Mismatches are data bugs to fix in the Phase 19 session."
    )
    lines.append("")
    lines.append("| word | gloss | stored letters[] | computed letters[] | match |")
    lines.append("|---|---|---|---|---|")
    mismatches = 0
    for w in words:
        stored = w.get("letters", [])
        computed = decompose(w["text"]).letters
        ok = stored == computed
        if not ok:
            mismatches += 1
        lines.append(
            f"| {w['text']} | {w.get('gloss',{}).get('en','')} | "
            f"`{stored}` | `{computed}` | {'✓' if ok else '**✗**'} |"
        )
    lines.append("")
    lines.append(f"**{mismatches} mismatch(es).**")
    lines.append("")
    return lines


def _arabic_strings_in_exercise(ex: dict) -> list[str]:
    """Collect the Arabic a child must read/write in an exercise (skip English)."""
    out: list[str] = []
    for item in ex.get("prompt") or []:
        if item.get("kind") == "text" and item.get("text"):
            out.append(item["text"])
    expected = ex.get("expected") or {}
    if isinstance(expected, dict):
        word = expected.get("word")
        if isinstance(word, dict) and word.get("text"):
            out.append(word["text"])
        for token in expected.get("words") or []:
            if isinstance(token, str):
                out.append(token)
    return out


# --------------------------------------------------------------------------- #
# The seen-letters wall — shared predicate + scoping helpers (imported by L2)
# --------------------------------------------------------------------------- #

def unlearned_letters_for_exercise(
    ex: dict, order: dict[str, int]
) -> list[tuple[str, int]]:
    """Reach-ahead letters in a card's STORED ``letters[]`` — the parity predicate.

    Behavioural mirror of the Dart lint's ``unlearnedFor``
    (learned_letters_lint_test.dart L127–135): it reads the card's stored
    ``letters[]`` (NOT a re-decomposition of the display text), so L0/L1/L2 all
    judge the same input. A letter is *unlearned* for this card's unit when its
    ``introOrder`` exceeds the unit's ``introOrder`` (unit = the id prefix, e.g.
    ``baa.x`` → ``baa``). A letter absent from ``order`` (e.g. taa_marbuta, a
    non-taught special form) is treated as reaching ahead via ``_UNLEARNED_SENTINEL``
    — the same ``?? 1 << 30`` fallback the Dart lint uses.

    Returns ``[(letter, introOrder), …]`` for every reach-ahead entry; an empty
    list means the card is legal.
    """
    unit = str(ex.get("id", "")).split(".", 1)[0]
    unit_order = order.get(unit)
    if unit_order is None:
        return []
    out: list[tuple[str, int]] = []
    for letter in ex.get("letters", []) or []:
        o = order.get(letter, _UNLEARNED_SENTINEL)
        if o > unit_order:
            out.append((letter, o))
    return out


def live_graph_node_ids() -> set[str]:
    """The set of exercise ids referenced by a LIVE graph node.

    Union of every ``node["exerciseId"]`` across the canonical baa
    ``curriculum_graph.json`` (the server's source) + every per-letter
    ``graphs/*.json``. Mirrors the Dart lint's ``_discoverUnitGraphs`` /
    ``liveNodeIds``; ``graphs/baa.json`` is byte-parity with
    ``curriculum_graph.json`` so ids naturally dedup through the set.

    The gate + the seeder scope to THIS set only, so the dormant reach-ahead
    configs in ``exercises.json`` (cards referenced by NO live node — e.g.
    ``alif.buildSentence.hear``, the buildSentence pairs) never trip the wall,
    exactly as L1's ``liveNodeIds`` scoping does.
    """
    ids: set[str] = set()
    sources: list[Path] = [CURRICULUM_GRAPH_JSON]
    if GRAPHS_DIR.is_dir():
        sources += sorted(GRAPHS_DIR.glob("*.json"))
    for path in sources:
        if not path.exists():
            continue
        for node in _load(path).get("nodes", []) or []:
            eid = node.get("exerciseId")
            if isinstance(eid, str):
                ids.add(eid)
    return ids


def _text_for_display(ex: dict) -> str | None:
    """The written text a card's ``letters[]`` should decompose from.

    Mirror of ``promote_letter._text_for`` (the authoring source of truth):
    ``expected.glyph.char`` → ``expected.word.text`` → ``' '.join(expected.words)``.
    Returns None for a card with no expected text (teachCard / placeholder).
    """
    expected = ex.get("expected")
    if not isinstance(expected, dict):
        return None
    glyph = expected.get("glyph")
    if isinstance(glyph, dict) and glyph.get("char"):
        return str(glyph["char"])
    word = expected.get("word")
    if isinstance(word, dict) and word.get("text"):
        return str(word["text"])
    words = expected.get("words")
    if isinstance(words, list) and words:
        return " ".join(str(w) for w in words)
    return None


def _dedup_preserve(items: list[str]) -> list[str]:
    """First-seen-wins dedup — mirror of ``promote_letter._dedup_preserve``."""
    seen: set[str] = set()
    out: list[str] = []
    for x in items:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return out


def unlabeled_cards(exercises: list[dict], live_ids: set[str]) -> dict[str, str]:
    """LIVE-node cards that are unlabeled or whose label drifted — criterion 1's
    "ZERO unlabeled words" leg, scoped to live nodes only.

    A live-node card is flagged when its stored ``letters[]`` is missing/empty, OR
    (when the card has display text) it diverges from the deduped decomposition of
    that text — the بطة / توت label-drift the module docstring names. The expected
    label mirrors ``promote_letter.enrich_exercise``, which stores the *deduped*
    written skeleton (باب → ``[baa, alif]``); comparing against the deduped form is
    what separates genuine drift from the normal repeated-letter case. Cards with no
    display text (teachCard / placeholder) only need a non-empty ``letters[]``.

    Returns ``{exerciseId: reason}``; empty means every live card is labeled.
    """
    flagged: dict[str, str] = {}
    for ex in exercises:
        ex_id = str(ex.get("id", ""))
        if ex_id not in live_ids:
            continue
        stored = list(ex.get("letters") or [])
        if not stored:
            flagged[ex_id] = "letters[] missing/empty"
            continue
        text = _text_for_display(ex)
        if text is None:
            continue
        expected = _dedup_preserve(decompose(text).letters)
        if not expected:
            continue
        if stored != expected:
            flagged[ex_id] = (
                f"letters[] {stored} != decomposed {expected} (from {text!r})"
            )
    return flagged


def report_live_exercises(order: dict[str, int]) -> list[str]:
    """Existing exercises whose content demands letters not yet introduced.

    NOTE: this section stays a SEPARATE *label-drift* signal — it decomposes the
    card's DISPLAY text (not the stored ``letters[]``), reproducing the worklist the
    owner triages from. The build gate (``--gate``) uses the stored-``letters[]``
    predicate ``unlearned_letters_for_exercise`` + ``unlabeled_cards`` instead.
    """
    data = _load(EXERCISES_JSON)
    exercises = data.get("exercises", [])
    lines = ["## 3 · Live `exercises.json` — content demanding unlearned letters", ""]
    lines.append(
        "For each exercise, the unit letter is the id prefix (e.g. `baa.…` → baa, "
        "intro-order 2). Any Arabic the child reads/writes that uses a letter with "
        "a *later* intro-order is reaching ahead of the curriculum. Copy-style "
        "exercises may do this deliberately — the mother decides; this only surfaces it."
    )
    lines.append("")
    lines.append("| exercise | unit (order) | word | unlearned letters (order) |")
    lines.append("|---|---|---|---|")
    findings = 0
    for ex in exercises:
        ex_id = ex.get("id", "")
        unit = ex_id.split(".", 1)[0]
        u_order = order.get(unit)
        if u_order is None:
            continue
        for text in _arabic_strings_in_exercise(ex):
            d = decompose(text)
            ahead = [
                (l, order[l])
                for l in _base_members(d.letters)
                if order[l] > u_order
            ]
            if ahead:
                findings += 1
                ahead_txt = ", ".join(f"{l}({o})" for l, o in sorted(ahead, key=lambda x: x[1]))
                lines.append(f"| `{ex_id}` | {unit} ({u_order}) | {text} | {ahead_txt} |")
    lines.append("")
    lines.append(f"**{findings} exercise/word finding(s).**")
    lines.append("")
    return lines


def main() -> int:
    order = load_intro_order()

    header = [
        "# Qalam letter-legality validation report",
        "",
        "_Generated by `python -m content.validate` (read-only). Informational — "
        "the curriculum is the owner's mother's domain; this only surfaces where "
        "content and the intro order disagree._",
        "",
    ]

    draft_lines, blocking = report_draft(order)
    live_word_lines = report_live_words(order)
    live_ex_lines = report_live_exercises(order)

    report = "\n".join(header + draft_lines + live_word_lines + live_ex_lines) + "\n"
    REPORT_MD.write_text(report, encoding="utf-8", newline="\n")

    # Console summary.
    print(f"Wrote {REPORT_MD.relative_to(REPO_ROOT)}")
    print(f"  intro order: {len(order)} taught letters")
    # quick counts for the summary line
    draft = _load(DRAFT_JSON)["words"]
    ahead = sum(
        1
        for w in draft
        if (e := earliest_legal_unit(w["letters"], order)) is not None
        and e > order.get(w["focusLetter"], 99)
    )
    live = _load(LIVE_WORDS_JSON)["words"]
    mismatches = sum(1 for w in live if w.get("letters", []) != decompose(w["text"]).letters)
    print(f"  draft bank: {len(draft)} words, {ahead} reach ahead of their focus letter")
    print(f"  live words.json: {mismatches} stored-vs-computed letters[] mismatch(es)")
    if blocking:
        print(f"  ERROR: {blocking} draft word(s) have a BLOCKING decomposition — fix the bank.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
