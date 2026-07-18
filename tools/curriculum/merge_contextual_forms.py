"""Surgical contextualForms merge — the owner drop -> the bundle, ONE field only.

Copies ONLY the ``contextualForms`` field for exactly the four letters
``alif``, ``baa``, ``taa`` and ``thaa`` from the owner's source drop into the
bundled ``assets/curriculum/letters.json``. NOTHING else crosses: not
``signedOff``, not ``commonMistakes``, not ``referenceStrokes``, not
``tolerances`` — so the app keeps its own signed-off values (baa/taa stay
``true``) and the owner's alif ``commonMistakes`` change is deliberately NOT
taken (flagged for the mother's review instead). The other 24 letters are left
byte-identical.

Why: the device reads letters Firestore-first, and neither prod Firestore nor
the bundle carried per-form ``contextualForms`` for thaa — so the on-device
scorer had no per-form reference to score a thaa attempt against and thaa was
"always wrong". This merge gives thaa (and refreshes alif/baa/taa) real
per-form references.

Stdlib-only (``json``, ``pathlib``, ``argparse``) so it runs with a bare
``python3``. Follows the ``tools/firebase/point_codec.py`` conventions:
repo-root resolution via ``Path(__file__).resolve().parents[N]`` and a
``--check`` self-verify affordance.

The serialization matches the bundle's existing 2-space indentation and
non-ASCII passthrough EXACTLY (``json.dumps(indent=2, ensure_ascii=False)``
round-trips the current bundle byte-for-byte, no trailing newline), so a merge
produces a MINIMAL, STABLE diff and a re-run on an already-merged bundle is a
no-op (idempotent).

Usage::

    python3 tools/curriculum/merge_contextual_forms.py           # apply the merge
    python3 tools/curriculum/merge_contextual_forms.py --check    # verify no-op (idempotent)

NEVER modifies or stages the owner source drop ("letters (2).json").
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Repo root is two levels up from this file (tools/curriculum/merge_contextual_forms.py).
_REPO_ROOT = Path(__file__).resolve().parents[2]
_BUNDLE = _REPO_ROOT / "assets" / "curriculum" / "letters.json"
# The owner's untracked drop lives at the repo root; the filename has a space.
_DEFAULT_SOURCE = _REPO_ROOT / "letters (2).json"

# The ONLY letters whose contextualForms may cross, and the ONLY field that may.
_MERGE_IDS = ("alif", "baa", "taa", "thaa")
_MERGE_FIELD = "contextualForms"


def _load_letters(path: Path):
    """Load a ``{"letters": [...]}`` curriculum file into (raw_obj, {id: letter})."""
    data = json.loads(path.read_text(encoding="utf-8"))
    by_id = {letter["id"]: letter for letter in data["letters"]}
    return data, by_id


def _serialize(data) -> str:
    """Serialize matching the bundle's existing style (2-space indent, non-ASCII
    passthrough, no trailing newline) so the merge diff is minimal + idempotent."""
    return json.dumps(data, indent=2, ensure_ascii=False)


def merge(source_path: Path = _DEFAULT_SOURCE):
    """Compute the merged bundle text WITHOUT writing it.

    Returns ``(merged_text, current_text, changed_ids)``: the merged bundle
    serialization, the bundle's current on-disk serialization, and the list of
    ids whose ``contextualForms`` actually changed. Copies ONLY the
    ``contextualForms`` field for the four merge ids; every other field and
    every other letter is untouched.
    """
    if not source_path.exists():
        raise FileNotFoundError(
            f"owner source drop not found: {source_path} "
            "(expected the repo-root 'letters (2).json'; it is untracked and "
            "NEVER committed)"
        )

    data, bundle_by_id = _load_letters(_BUNDLE)
    _, source_by_id = _load_letters(source_path)
    current_text = _BUNDLE.read_text(encoding="utf-8")

    changed_ids = []
    for lid in _MERGE_IDS:
        if lid not in bundle_by_id:
            raise KeyError(f"letter '{lid}' missing from the bundle {_BUNDLE}")
        if lid not in source_by_id:
            raise KeyError(f"letter '{lid}' missing from the source {source_path}")

        source_cf = source_by_id[lid].get(_MERGE_FIELD)
        if source_cf is None:
            # Per the verified diff all four have non-null forms, so this should
            # not fire — but skip (never overwrite with null) and warn if it does.
            print(
                f"WARNING: source '{lid}' has null {_MERGE_FIELD}; skipping it "
                "(bundle left unchanged for this letter).",
                file=sys.stderr,
            )
            continue

        if bundle_by_id[lid].get(_MERGE_FIELD) != source_cf:
            changed_ids.append(lid)
        # Copy ONLY this one field. Assignment replaces it in place when the key
        # already exists (alif/baa/taa) and appends it as the last field when it
        # does not (thaa) — matching where contextualForms sits on alif.
        bundle_by_id[lid][_MERGE_FIELD] = source_cf

    return _serialize(data), current_text, changed_ids


def apply(source_path: Path = _DEFAULT_SOURCE) -> int:
    """Apply the merge to the bundle on disk. Idempotent: a no-op when already merged."""
    merged_text, current_text, changed_ids = merge(source_path)
    if merged_text == current_text:
        print("OK: bundle already carries the merged contextualForms — no change (idempotent).")
        return 0
    _BUNDLE.write_text(merged_text, encoding="utf-8")
    print(
        f"OK: merged contextualForms into {len(changed_ids)} letter(s): "
        f"{', '.join(changed_ids)}. Wrote {_BUNDLE.relative_to(_REPO_ROOT)}."
    )
    return 0


def check(source_path: Path = _DEFAULT_SOURCE) -> int:
    """Self-verify the merge is a no-op on the current bundle (idempotency gate).

    Exit 0 when the bundle already equals the merged result (already applied);
    exit 1 when applying the merge WOULD change the bundle (not yet applied).
    """
    merged_text, current_text, changed_ids = merge(source_path)
    if merged_text == current_text:
        print("OK: --check passed — merge is a no-op on the current bundle (idempotent).")
        return 0
    print(
        "CHECK FAILED: applying the merge would still change the bundle for "
        f"{', '.join(changed_ids)}. Run without --check to apply it first.",
        file=sys.stderr,
    )
    return 1


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        type=Path,
        default=_DEFAULT_SOURCE,
        help="the owner source drop (default: repo-root 'letters (2).json')",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the merge is a no-op on the current bundle (idempotency gate); do not write",
    )
    args = parser.parse_args(argv)
    return check(args.source) if args.check else apply(args.source)


if __name__ == "__main__":
    sys.exit(main())
