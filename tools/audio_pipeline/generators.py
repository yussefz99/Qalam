"""Generate the README audioId table and the Dart ``_audioIdToAsset`` map.

Both outputs are derived from the manifest and written **only** between the
``BEGIN GENERATED (audio_manifest)`` / ``END GENERATED`` markers. Everything
outside the markers is hand-authored and never touched. This is the fix for the
hand-maintained lockstep the README + Dart map used to require.
"""

from __future__ import annotations

from pathlib import Path

from .manifest import AudioEntry, REPO_ROOT

README_PATH = REPO_ROOT / "assets" / "audio" / "README.md"
DART_PATH = REPO_ROOT / "lib" / "services" / "asset_audio_player.dart"

# Marker text is shared; the comment syntax differs per file type.
MARKER_TAG = "audio_manifest"
README_BEGIN = f"<!-- BEGIN GENERATED ({MARKER_TAG}) -->"
README_END = "<!-- END GENERATED -->"
DART_BEGIN = f"  // BEGIN GENERATED ({MARKER_TAG})"
DART_END = "  // END GENERATED"

# Human labels for the status enum, shown in the README table.
_STATUS_LABEL = {
    "real": "**REAL** (human recording)",
    "draft-tts": "draft-tts (interim AI voice)",
    "placeholder": "PLACEHOLDER",
}


class MarkerError(RuntimeError):
    """Raised when the begin/end markers are missing or malformed in a target."""


def _md_escape(text: str) -> str:
    """Escape pipe characters so table cells never break the markdown grid."""
    return text.replace("|", "\\|")


def render_readme_block(entries: list[AudioEntry]) -> str:
    """Return the markdown table body (without markers) for the README."""
    lines = [
        "<!-- Generated from tools/audio_pipeline/audio_manifest.json — do not edit by hand. -->",
        "<!-- Regenerate: `python -m audio_pipeline generate` (from tools/). -->",
        "",
        "| audioId | asset path | used by | status |",
        "|---------|-----------|---------|--------|",
    ]
    for e in entries:
        label = _STATUS_LABEL.get(e.status, e.status)
        lines.append(
            f"| `{e.audio_id}` | `{e.asset_path}` | {_md_escape(e.used_by)} | {label} |"
        )
    return "\n".join(lines)


def render_dart_block(entries: list[AudioEntry]) -> str:
    """Return the Dart map declaration body (without markers).

    Emits the same shape the file already used: keys are audioIds, values are
    ``'$_audioDir/<filename>'`` so the single ``_audioDir`` constant stays the one
    place the directory is named.
    """
    lines = [
        "  // Generated from tools/audio_pipeline/audio_manifest.json — do not edit by hand.",
        "  // Regenerate: `python -m audio_pipeline generate` (from tools/).",
        "  static const Map<String, String> _audioIdToAsset = <String, String>{",
    ]
    for e in entries:
        lines.append(f"    '{e.audio_id}': '$_audioDir/{e.filename}',")
    lines.append("  };")
    return "\n".join(lines)


def _replace_between_markers(
    text: str, begin: str, end: str, new_block: str, *, target: Path
) -> str:
    """Swap the content between ``begin`` and ``end`` markers for ``new_block``.

    The markers themselves are preserved. Raises :class:`MarkerError` if either
    marker is missing or they are out of order — we never guess where generated
    content belongs.
    """
    bi = text.find(begin)
    ei = text.find(end)
    if bi == -1 or ei == -1:
        raise MarkerError(
            f"{target}: missing generated markers. Expected both:\n"
            f"  {begin}\n  {end}\n"
            "Add them once around the region to be generated (see the pipeline README)."
        )
    if ei < bi:
        raise MarkerError(f"{target}: END marker appears before BEGIN marker.")

    before = text[: bi + len(begin)]
    after = text[ei:]
    return f"{before}\n{new_block}\n{after}"


def build_readme(entries: list[AudioEntry], current: str) -> str:
    """Return the full README text with its generated table refreshed."""
    return _replace_between_markers(
        current, README_BEGIN, README_END, render_readme_block(entries), target=README_PATH
    )


def build_dart(entries: list[AudioEntry], current: str) -> str:
    """Return the full Dart file text with its generated map refreshed."""
    return _replace_between_markers(
        current, DART_BEGIN, DART_END, render_dart_block(entries), target=DART_PATH
    )


def write_generated(entries: list[AudioEntry]) -> list[Path]:
    """Regenerate both targets in place. Returns the paths that changed."""
    changed: list[Path] = []
    for path, builder in ((README_PATH, build_readme), (DART_PATH, build_dart)):
        current = path.read_text(encoding="utf-8")
        updated = builder(entries, current)
        if updated != current:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed.append(path)
    return changed
