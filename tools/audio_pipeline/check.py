"""Drift check — the CI-friendly guard the hand-maintained lockstep never had.

``python -m audio_pipeline check`` exits non-zero if any of these drift:

  1. a manifest entry points at a file that does not exist;
  2. a clip file in ``assets/audio/`` has no manifest entry;
  3. the README table is stale (regenerating would change it);
  4. the Dart ``_audioIdToAsset`` map is stale.

It mutates nothing. Run it in CI and after any manifest edit.
"""

from __future__ import annotations

from pathlib import Path

from . import generators
from .manifest import AUDIO_DIR, AudioEntry, load_manifest


def _find_audio_files() -> set[str]:
    """All bundled clip basenames under assets/audio/ (mp3 only)."""
    if not AUDIO_DIR.exists():
        return set()
    return {p.name for p in AUDIO_DIR.glob("*.mp3")}


def run_check() -> int:
    """Return 0 when everything is in lockstep, 1 otherwise (printing why)."""
    problems: list[str] = []

    entries: list[AudioEntry] = load_manifest()

    # (1) every manifest entry must have a real file.
    manifest_files = {e.filename for e in entries}
    for e in entries:
        if not e.absolute_path.exists():
            problems.append(f"  [missing file]   {e.audio_id} -> {e.asset_path} (no file on disk)")

    # (2) every clip file must be represented in the manifest.
    for name in sorted(_find_audio_files()):
        if name not in manifest_files:
            problems.append(
                f"  [orphan file]    assets/audio/{name} (no manifest entry — add one or delete the file)"
            )

    # (3) + (4) generated blocks must be current.
    for path, builder in (
        (generators.README_PATH, generators.build_readme),
        (generators.DART_PATH, generators.build_dart),
    ):
        try:
            current = path.read_text(encoding="utf-8")
        except FileNotFoundError:
            problems.append(f"  [missing target] {path} not found")
            continue
        try:
            rebuilt = builder(entries, current)
        except generators.MarkerError as exc:
            problems.append(f"  [markers]        {exc}")
            continue
        if rebuilt != current:
            rel = path.relative_to(generators.REPO_ROOT)
            problems.append(
                f"  [stale block]    {rel} is out of date — run `python -m audio_pipeline generate`"
            )

    if problems:
        print("AUDIO PIPELINE CHECK: FAIL")
        print(f"{len(problems)} problem(s):")
        print("\n".join(problems))
        return 1

    print(f"AUDIO PIPELINE CHECK: OK — {len(entries)} entries in lockstep with files + README + Dart map.")
    return 0
