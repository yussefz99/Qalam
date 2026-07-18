"""Reusable, letter-parameterized draft → live curriculum promoter (Stage 1 of
all-letters-live, quick task 260718-il4).

Promotes ONE drafted letter (from ``docs/curriculum/drafts/``) into the live app
assets so its Letter Unit runs end-to-end exactly like the signed baa unit:

  python -m content.promote_letter --letter thaa

What it does (all IDEMPOTENT — re-running produces a byte-identical result):

  (a) LOCATE the drafts for the letter by glob (the ``NN-`` prefix is introOrder;
      match on the ``<letter>`` suffix). Assert the draft ``letterId`` == --letter.
  (b) ENRICH every draft exercise with the two fields the live baa configs carry
      but the drafts lack — ``letters`` and ``criteria`` (see the enrichment rule
      below, verified against every live baa config). Force ``signedOff:false`` on
      each promoted exercise AND on the file-level flag. Every other authored
      field is preserved byte-for-byte (placeholder ``expected:null`` exercises
      are kept — they are real draft-graph nodes the mother will complete later).
  (c) APPEND the enriched exercises into ``assets/curriculum/exercises.json`` under
      ``exercises[]`` (id-keyed REPLACE, never a blind duplicate append).
  (d) DERIVE + APPEND a ``<letter>`` unit into ``assets/curriculum/units.json``,
      GENERATED from the letter's exercise types via the documented type→section
      map (owner amendment 2 — units are never hand-authored).
  (e) WRITE the per-letter graph asset ``assets/curriculum/graphs/<letter>.json``
      from the draft graph verbatim (keeps ``signedOff:false``).

And a one-shot ``--migrate-baa`` mode:

  python -m content.promote_letter --migrate-baa

  (f) MIGRATE baa into the new per-letter scheme: writes
      ``assets/curriculum/graphs/baa.json`` as a byte-parity copy of the existing
      ``assets/curriculum/curriculum_graph.json`` (the server's generate.py + the
      baa lint still read curriculum_graph.json this stage; graphs/baa.json is the
      provider's per-letter copy, kept in sync by the parity test in Task 3).
      curriculum_graph.json is NEVER deleted or edited.

And a ``--graph-only`` mode (finalization Lane A):

  python -m content.promote_letter --graph-only taa

  (g) PROMOTE ONLY the draft GRAPH for a letter whose exercises/unit are already
      live and must NOT be replaced. taa is the motivating case: its 19 live
      exercises are AUTHORED AND SIGNED (signedOff:true, the mother's content),
      while 18.1 shipped a draft graph (03-taa.graph.json) whose node ids match
      those live exercise ids exactly — so the graph promotes verbatim (forced
      signedOff:false, same as every promoted artifact) and the signed exercise
      content stays byte-identical. Idempotent like every other mode.

Content posture (owner-locked): ALL promoted content ships ``signedOff:false`` —
the owner's mother reviews it via the 18.1 review packets before it is trusted.
Micro-drills NEVER enter any graph (the drafts carry none — kept that way).

stdlib-only (reuses ``content.arabic.decompose``); no new pip deps.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import sys
from typing import Any

from content.arabic import decompose

# ── Repo layout ──────────────────────────────────────────────────────────────
# This module lives at tools/content/promote_letter.py; the repo root is two
# levels up. Every path below is repo-root-relative so the script is invocable
# from `tools/` (its documented cwd) regardless of the process cwd.
_HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(_HERE, os.pardir, os.pardir))

DRAFT_EXERCISES_GLOB = "docs/curriculum/drafts/exercises/*-{letter}.exercises.json"
DRAFT_GRAPH_GLOB = "docs/curriculum/drafts/graphs/*-{letter}.graph.json"

LIVE_EXERCISES = "assets/curriculum/exercises.json"
LIVE_UNITS = "assets/curriculum/units.json"
GRAPHS_DIR = "assets/curriculum/graphs"
LIVE_BAA_GRAPH = "assets/curriculum/curriculum_graph.json"

# ── The enrichment rule (verified against EVERY live baa config) ──────────────
# criteria is a FIXED per-type map mirroring the live baa per-type values EXACTLY:
#   teachCard                                            -> []
#   traceLetter / writeLetter / completeWord             -> the 5-criterion stroke set
#   writeWord / connectWord / transformWord /
#     fillBlank / buildSentence                          -> present/correct/dot
# (completeWord scores a single missing glyph, so it carries the stroke set — the
#  live baa.completeWord.middle confirms this.)
_STROKE_CRITERIA = ["strokeCount", "strokeOrder", "shape", "direction", "dot"]
_WORD_CRITERIA = ["present", "correct", "dot"]
CRITERIA_BY_TYPE: dict[str, list[str]] = {
    "teachCard": [],
    "traceLetter": _STROKE_CRITERIA,
    "writeLetter": _STROKE_CRITERIA,
    "completeWord": _STROKE_CRITERIA,
    "writeWord": _WORD_CRITERIA,
    "connectWord": _WORD_CRITERIA,
    "transformWord": _WORD_CRITERIA,
    "fillBlank": _WORD_CRITERIA,
    "buildSentence": _WORD_CRITERIA,
}

# ── units.json GENERATION: type -> section id (owner amendment 2) ─────────────
# The unit is GENERATED from the letter's exercise types (never hand-authored),
# grouping ids by type into baa's 6-section shape, declaration order preserved,
# plus an empty trailing `mastery` section (the quiet unit star).
SECTION_BY_TYPE: dict[str, str] = {
    "teachCard": "meet",
    "traceLetter": "watchTrace",
    "writeLetter": "forms",
    "writeWord": "words",
    "connectWord": "words",
    "completeWord": "words",
    "transformWord": "listenWrite",
    "fillBlank": "listenWrite",
    "buildSentence": "listenWrite",
}
# The fixed section order the unit shell walks (mirrors baa).
SECTION_ORDER = ["meet", "watchTrace", "forms", "words", "listenWrite", "mastery"]


def _abs(rel: str) -> str:
    return os.path.join(REPO_ROOT, rel)


def _load_json(rel: str) -> Any:
    with open(_abs(rel), encoding="utf-8") as fh:
        return json.load(fh)


def _write_json(rel: str, data: Any) -> None:
    """Write with ensure_ascii=False, 2-space indent, trailing newline — the
    canonical shape the live assets use (idempotent round-trip)."""
    path = _abs(rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\n")


def _dedup_preserve(seq: list[str]) -> list[str]:
    out: list[str] = []
    for x in seq:
        if x not in out:
            out.append(x)
    return out


def _locate_one(pattern_rel: str, letter: str, kind: str) -> str:
    matches = sorted(glob.glob(_abs(pattern_rel.format(letter=letter))))
    if not matches:
        raise SystemExit(
            f"promote_letter: no {kind} draft found for '{letter}' "
            f"(looked for {pattern_rel.format(letter=letter)})"
        )
    if len(matches) > 1:
        raise SystemExit(
            f"promote_letter: ambiguous {kind} drafts for '{letter}': {matches}"
        )
    return matches[0]


def _text_for(exercise: dict[str, Any]) -> str | None:
    """The written text a `letters` list decomposes from, per the exercise's
    `expected` shape:
      glyph units    -> expected.glyph.char
      word units     -> expected.word.text
      sentence units -> ' '.join(expected.words)
    Returns None when there is no expected text (teachCard, or a placeholder
    exercise with expected:null) — the caller defaults `letters` to [letterId].
    """
    expected = exercise.get("expected")
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


def enrich_exercise(exercise: dict[str, Any], letter: str) -> dict[str, Any]:
    """Return a copy of [exercise] with `letters` + `criteria` added and
    `signedOff` forced false. Every other authored field is preserved."""
    out = dict(exercise)  # preserve prompt/surface/expected/check/feedback/_note/...

    text = _text_for(exercise)
    if text is None:
        # teachCard / placeholder (expected:null) -> the letter itself.
        letters = [letter]
    else:
        letters = _dedup_preserve(decompose(text).letters)
        if not letters:  # decompose yielded nothing usable -> fall back to letter.
            letters = [letter]
    out["letters"] = letters

    ex_type = str(exercise.get("type", ""))
    if ex_type not in CRITERIA_BY_TYPE:
        raise SystemExit(
            f"promote_letter: exercise {exercise.get('id')} has unknown type "
            f"'{ex_type}' — no criteria mapping. Extend CRITERIA_BY_TYPE."
        )
    out["criteria"] = list(CRITERIA_BY_TYPE[ex_type])

    out["signedOff"] = False  # content posture: every promoted exercise unsigned.
    return out


def derive_unit(letter: str, exercises: list[dict[str, Any]]) -> dict[str, Any]:
    """GENERATE the letter's units.json entry from its exercise types (owner
    amendment 2 — never hand-authored). Groups ids by type into the 6-section
    shape, declaration order preserved, plus an empty trailing `mastery`."""
    grouped: dict[str, list[str]] = {sid: [] for sid in SECTION_ORDER}
    for ex in exercises:
        ex_type = str(ex.get("type", ""))
        if ex_type not in SECTION_BY_TYPE:
            raise SystemExit(
                f"promote_letter: exercise {ex.get('id')} has type '{ex_type}' "
                f"with no section mapping. Extend SECTION_BY_TYPE."
            )
        grouped[SECTION_BY_TYPE[ex_type]].append(str(ex["id"]))
    return {
        "letterId": letter,
        "sections": [
            {"id": sid, "exercises": grouped[sid]} for sid in SECTION_ORDER
        ],
    }


def _replace_or_append(items: list[dict[str, Any]], new: list[dict[str, Any]],
                       key: str) -> list[dict[str, Any]]:
    """Idempotent id-keyed merge: replace an item whose [key] already exists in
    place; append genuinely-new items in draft order. Never duplicates."""
    index_by_id = {item[key]: i for i, item in enumerate(items)}
    merged = list(items)
    for item in new:
        ident = item[key]
        if ident in index_by_id:
            merged[index_by_id[ident]] = item  # replace in place
        else:
            index_by_id[ident] = len(merged)
            merged.append(item)  # append new
    return merged


def promote_letter(letter: str) -> None:
    """Promote one drafted letter into all live assets (steps a–e)."""
    # (a) LOCATE.
    ex_draft_path = _locate_one(DRAFT_EXERCISES_GLOB, letter, "exercises")
    gr_draft_path = _locate_one(DRAFT_GRAPH_GLOB, letter, "graph")
    with open(ex_draft_path, encoding="utf-8") as fh:
        ex_draft = json.load(fh)
    with open(gr_draft_path, encoding="utf-8") as fh:
        gr_draft = json.load(fh)
    if ex_draft.get("letterId") != letter:
        raise SystemExit(
            f"promote_letter: exercises draft letterId "
            f"{ex_draft.get('letterId')!r} != --letter {letter!r}"
        )
    if gr_draft.get("letterId") != letter:
        raise SystemExit(
            f"promote_letter: graph draft letterId "
            f"{gr_draft.get('letterId')!r} != --letter {letter!r}"
        )

    # (b) ENRICH.
    enriched = [enrich_exercise(ex, letter) for ex in ex_draft["exercises"]]

    # (c) APPEND into exercises.json (idempotent id-keyed replace).
    live_ex = _load_json(LIVE_EXERCISES)
    live_ex["exercises"] = _replace_or_append(
        live_ex["exercises"], enriched, key="id"
    )
    _write_json(LIVE_EXERCISES, live_ex)

    # (d) DERIVE + APPEND the unit (idempotent replace).
    unit = derive_unit(letter, enriched)
    live_units = _load_json(LIVE_UNITS)
    live_units["units"] = _replace_or_append(
        live_units["units"], [unit], key="letterId"
    )
    _write_json(LIVE_UNITS, live_units)

    # (e) WRITE the per-letter graph asset verbatim (signedOff stays false).
    graph = dict(gr_draft)
    graph["signedOff"] = False  # content posture: the graph is unsigned too.
    _write_json(os.path.join(GRAPHS_DIR, f"{letter}.json"), graph)

    print(
        f"promote_letter: promoted {letter} — "
        f"{len(enriched)} exercises, 6-section unit, graphs/{letter}.json"
    )


def migrate_baa() -> None:
    """(f) Write graphs/baa.json as a byte-parity copy of curriculum_graph.json.
    curriculum_graph.json is never deleted or edited."""
    baa_graph = _load_json(LIVE_BAA_GRAPH)
    _write_json(os.path.join(GRAPHS_DIR, "baa.json"), baa_graph)
    print("promote_letter: migrated baa -> graphs/baa.json (parity copy)")


def promote_graph_only(letter: str) -> None:
    """(g) Promote ONLY the draft graph for [letter] — exercises.json and
    units.json are NOT touched. For letters whose exercise content is already
    live (and possibly signed) but whose per-letter graph asset is missing.
    Forces signedOff:false on the graph (content posture), verbatim otherwise.
    Guards that every graph node id has a live exercise config, so the
    presenter can always resolve what the walker selects."""
    gr_draft_path = _locate_one(DRAFT_GRAPH_GLOB, letter, "graph")
    with open(gr_draft_path, encoding="utf-8") as fh:
        gr_draft = json.load(fh)
    if gr_draft.get("letterId") != letter:
        raise SystemExit(
            f"promote_letter: graph draft letterId "
            f"{gr_draft.get('letterId')!r} != --graph-only {letter!r}"
        )

    # Node-id ↔ live-exercise guard: every graph node must resolve to a LIVE
    # exercise config (this mode exists precisely because the exercises are
    # already live — a dangling node id would present as a fallback card).
    live_ids = {e["id"] for e in _load_json(LIVE_EXERCISES)["exercises"]}
    dangling = [
        n["exerciseId"] for n in gr_draft.get("nodes", [])
        if n.get("exerciseId") not in live_ids
    ]
    if dangling:
        raise SystemExit(
            f"promote_letter: --graph-only {letter}: graph nodes with NO live "
            f"exercise config: {dangling}. Promote the exercises first (full "
            f"--letter mode) or fix the draft graph."
        )

    graph = dict(gr_draft)
    graph["signedOff"] = False  # content posture: the graph is unsigned.
    _write_json(os.path.join(GRAPHS_DIR, f"{letter}.json"), graph)
    print(
        f"promote_letter: promoted GRAPH ONLY for {letter} -> "
        f"graphs/{letter}.json ({len(gr_draft.get('nodes', []))} nodes, "
        f"exercises/units untouched)"
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="promote_letter",
        description="Promote a drafted letter into the live curriculum assets.",
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--letter", help="letterId to promote (e.g. thaa) from its drafts"
    )
    group.add_argument(
        "--migrate-baa", action="store_true",
        help="write graphs/baa.json as a parity copy of curriculum_graph.json",
    )
    group.add_argument(
        "--graph-only",
        metavar="LETTER",
        help="promote ONLY the draft graph for LETTER (exercises/units already "
             "live and untouched — e.g. taa, whose 19 signed exercises must "
             "not be replaced)",
    )
    args = parser.parse_args(argv)

    if args.migrate_baa:
        migrate_baa()
    elif args.graph_only:
        promote_graph_only(args.graph_only)
    else:
        promote_letter(args.letter)
    return 0


if __name__ == "__main__":
    sys.exit(main())
