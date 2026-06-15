"""Shared Firestore point codec — the Python half of the {x,y} <-> [x,y] transform.

This mirrors the Dart codec (lib/data/firestore_curriculum_codec.dart) field-for-field
so the seed (Plan 03), the export (Plan 03), and the app read path (Plan 04) all agree.

THE landmine (Pitfall 1, D-06): ``StrokeSpec.points`` is an array of ``[x, y]`` pairs,
and Firestore forbids arrays whose elements are themselves arrays. So a point pair is
stored as a ``{"x": x, "y": y}`` map on write and rebuilt to ``[x, y]`` on read — the
exact same transform the Dart codec applies.

Stdlib-only (``json``) so it runs with a bare ``python3`` — no firebase-admin here (that
lands in Plan 03). Run directly to self-verify lossless round-trip over the real
curriculum::

    python3 tools/firebase/point_codec.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Repo root is two levels up from this file (tools/firebase/point_codec.py).
_REPO_ROOT = Path(__file__).resolve().parents[2]
_LETTERS_JSON = _REPO_ROOT / "assets" / "curriculum" / "letters.json"


# ---------------------------------------------------------------------------
# Point codec — the {x,y} <-> [x,y] transform (Pitfall 1)
# ---------------------------------------------------------------------------

def encode_points(pairs):
    """``[[x, y], ...]`` -> ``[{"x": x, "y": y}, ...]`` (JSON shape -> Firestore shape)."""
    return [{"x": float(p[0]), "y": float(p[1])} for p in pairs]


def decode_points(maps):
    """``[{"x": x, "y": y}, ...]`` -> ``[[x, y], ...]`` (Firestore shape -> JSON shape)."""
    return [[float(m["x"]), float(m["y"])] for m in maps]


# ---------------------------------------------------------------------------
# Letter codec — walk referenceStrokes[].points and apply the transform
# ---------------------------------------------------------------------------

def _map_form_strokes(form, point_fn):
    """Apply ``point_fn`` (encode_points/decode_points) to every stroke's points in
    one contextual Form dict. ``None`` (a missing positional slot) passes through."""
    if form is None:
        return None
    return {
        **form,
        "referenceStrokes": [
            {**stroke, "points": point_fn(stroke.get("points", []))}
            for stroke in form.get("referenceStrokes", [])
        ],
    }


def _map_contextual_forms(cf, point_fn):
    """Apply ``point_fn`` to every form's strokes in a ``contextualForms`` map
    ({formName -> Form|null}). Schema v2 §2 — the per-positional pen paths that
    07-07 authored onto baa. Mirrors the Dart codec so seed/export/read agree."""
    return {name: _map_form_strokes(form, point_fn) for name, form in cf.items()}


def encode_letter(letter):
    """Copy a JSON-shaped letter dict, rewriting every stroke's points to {x,y} maps —
    both the top-level referenceStrokes AND the nested contextualForms strokes (so
    Firestore's no-nested-arrays rule is satisfied for the per-positional forms)."""
    out = dict(letter)
    out["referenceStrokes"] = [
        {**stroke, "points": encode_points(stroke.get("points", []))}
        for stroke in letter.get("referenceStrokes", [])
    ]
    if letter.get("contextualForms") is not None:
        out["contextualForms"] = _map_contextual_forms(
            letter["contextualForms"], encode_points
        )
    return out


def decode_letter(doc):
    """Copy a Firestore-shaped letter dict, rebuilding every stroke's points to [x,y] —
    both top-level referenceStrokes AND nested contextualForms strokes."""
    out = dict(doc)
    out["referenceStrokes"] = [
        {**stroke, "points": decode_points(stroke.get("points", []))}
        for stroke in doc.get("referenceStrokes", [])
    ]
    if doc.get("contextualForms") is not None:
        out["contextualForms"] = _map_contextual_forms(
            doc["contextualForms"], decode_points
        )
    return out


# ---------------------------------------------------------------------------
# Self-check: decode(encode(letter)) == letter over the real curriculum
# ---------------------------------------------------------------------------

def _normalize_points(letter):
    """Coerce every point coordinate to float so an int y (e.g. 1) compares equal
    to its 1.0 round-trip — the transform is lossless in VALUE, not in JSON int/float
    spelling. Mirrors the Dart codec's num->double cast."""
    def _norm_strokes(strokes):
        return [
            {**stroke, "points": [[float(x), float(y)] for x, y in stroke.get("points", [])]}
            for stroke in strokes
        ]

    out = dict(letter)
    out["referenceStrokes"] = _norm_strokes(letter.get("referenceStrokes", []))
    if letter.get("contextualForms") is not None:
        out["contextualForms"] = {
            name: (None if form is None else {**form, "referenceStrokes": _norm_strokes(form.get("referenceStrokes", []))})
            for name, form in letter["contextualForms"].items()
        }
    return out


def _self_check():
    data = json.loads(_LETTERS_JSON.read_text(encoding="utf-8"))
    letters = data["letters"]
    for letter in letters:
        round_tripped = decode_letter(encode_letter(letter))
        if round_tripped != _normalize_points(letter):
            print(
                f"MISMATCH: letter '{letter.get('id')}' did not round-trip losslessly",
                file=sys.stderr,
            )
            return 1
    print(f"OK: {len(letters)} letters round-tripped losslessly (decode(encode(x)) == x)")
    return 0


if __name__ == "__main__":
    sys.exit(_self_check())
