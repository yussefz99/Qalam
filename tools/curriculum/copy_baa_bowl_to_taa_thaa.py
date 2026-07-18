"""Owner-directed data surgery — give taa and thaa isolated the baa bowl body.

Sets ``taa.contextualForms.isolated.referenceStrokes[0]`` and
``thaa.contextualForms.isolated.referenceStrokes[0]`` in the bundled
``assets/curriculum/letters.json`` to a DEEP COPY of
``baa.contextualForms.isolated.referenceStrokes[0]`` — the ~12-point bowl body.

Why: ب ت ث share the identical bowl; only the dots differ (baa one below,
taa two above, thaa three above). The owner's authored isolated bodies for
taa/thaa kept FAILING his on-device traces against the scorer, so on
2026-07-18 he directed that both isolated bodies be replaced with baa's
validated bowl. Only the body stroke crosses — every dot stroke, every other
positional form (initial/medial/final), and every other field (``signedOff``
included) is left byte-identical. This is a change to the mother's-domain
curriculum data; her review is noted in the plan SUMMARY and ``signedOff``
flags are deliberately untouched (taa.isolated stays ``false``,
thaa.isolated stays ``false``).

Stdlib-only (``json``, ``pathlib``, ``argparse``) so it runs with a bare
``python3``. Follows ``tools/curriculum/merge_contextual_forms.py`` conventions:
repo-root resolution via ``Path(__file__).resolve().parents[2]``, serialization
with ``json.dumps(indent=2, ensure_ascii=False)`` (2-space indent, non-ASCII
passthrough, no trailing newline) so the diff is MINIMAL and STABLE, and a
``--check`` self-verify affordance. Re-running on an already-changed bundle is a
no-op (idempotent).

Usage::

    python3 tools/curriculum/copy_baa_bowl_to_taa_thaa.py           # apply the copy
    python3 tools/curriculum/copy_baa_bowl_to_taa_thaa.py --check   # verify no-op (idempotent, exit 0)

NEVER modifies or stages the owner source drop ("letters (2).json"), and never
touches any letter other than taa/thaa (baa is read-only here).
"""

from __future__ import annotations

import argparse
import copy
import json
import sys
from pathlib import Path

# Repo root is two levels up from this file (tools/curriculum/copy_baa_bowl_to_taa_thaa.py).
_REPO_ROOT = Path(__file__).resolve().parents[2]
_BUNDLE = _REPO_ROOT / "assets" / "curriculum" / "letters.json"

# The donor (read-only) and the two recipients of the isolated bowl body.
_SOURCE_ID = "baa"
_TARGET_IDS = ("taa", "thaa")
# The single stroke that crosses: the isolated-form BODY stroke (index 0).
_BODY_STROKE_INDEX = 0


def _load_bundle():
    """Load the bundle into (raw_obj, {id: letter})."""
    data = json.loads(_BUNDLE.read_text(encoding="utf-8"))
    by_id = {letter["id"]: letter for letter in data["letters"]}
    return data, by_id


def _serialize(data) -> str:
    """Serialize matching the bundle's existing style (2-space indent, non-ASCII
    passthrough, no trailing newline) so the diff is minimal and idempotent."""
    return json.dumps(data, indent=2, ensure_ascii=False)


def _isolated_strokes(letter):
    """Return the isolated-form referenceStrokes list for a letter (raises if absent)."""
    return letter["contextualForms"]["isolated"]["referenceStrokes"]


def transform(data, by_id):
    """Mutate ``data`` in place: copy baa's isolated body stroke onto taa/thaa.

    Returns the list of target ids whose isolated body stroke actually changed.
    Only ``referenceStrokes[0]`` of each target's isolated form is replaced; the
    dot strokes (index 1..) and everything else stay put.
    """
    if _SOURCE_ID not in by_id:
        raise KeyError(f"donor letter '{_SOURCE_ID}' missing from the bundle {_BUNDLE}")
    donor_body = _isolated_strokes(by_id[_SOURCE_ID])[_BODY_STROKE_INDEX]

    changed = []
    for lid in _TARGET_IDS:
        if lid not in by_id:
            raise KeyError(f"target letter '{lid}' missing from the bundle {_BUNDLE}")
        target_strokes = _isolated_strokes(by_id[lid])
        if target_strokes[_BODY_STROKE_INDEX] != donor_body:
            changed.append(lid)
        # Deep copy so the three letters never share a mutable object, and so the
        # WHOLE stroke object (order/label/type/points/direction and any future
        # per-stroke metadata) crosses — dots at index 1.. are left untouched.
        target_strokes[_BODY_STROKE_INDEX] = copy.deepcopy(donor_body)
    return changed


def _compute():
    """Return (new_text, current_text, changed_ids) WITHOUT writing to disk."""
    data, by_id = _load_bundle()
    current_text = _BUNDLE.read_text(encoding="utf-8")
    changed_ids = transform(data, by_id)
    return _serialize(data), current_text, changed_ids


def apply() -> int:
    """Apply the copy to the bundle on disk. Idempotent: a no-op when already done."""
    new_text, current_text, changed_ids = _compute()
    if new_text == current_text:
        print("OK: taa/thaa isolated already carry baa's bowl body — no change (idempotent).")
        return 0
    _BUNDLE.write_text(new_text, encoding="utf-8")
    print(
        f"OK: copied baa's isolated bowl body onto {len(changed_ids)} letter(s): "
        f"{', '.join(changed_ids)}. Wrote {_BUNDLE.relative_to(_REPO_ROOT)}."
    )
    return 0


def check() -> int:
    """Self-verify the copy is a no-op on the current bundle (idempotency gate).

    Exit 0 when the bundle already equals the transformed result (already applied);
    exit 1 when applying the copy WOULD change the bundle (not yet applied).
    """
    new_text, current_text, changed_ids = _compute()
    if new_text == current_text:
        print("OK: --check passed — taa/thaa isolated already deep-equal baa's bowl (idempotent).")
        return 0
    print(
        "CHECK FAILED: applying the copy would still change the bundle for "
        f"{', '.join(changed_ids)}. Run without --check to apply it first.",
        file=sys.stderr,
    )
    return 1


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the copy is a no-op on the current bundle (idempotency gate); do not write",
    )
    args = parser.parse_args(argv)
    return check() if args.check else apply()


if __name__ == "__main__":
    sys.exit(main())
