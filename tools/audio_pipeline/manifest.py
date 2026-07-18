"""Load and validate ``audio_manifest.json`` — the single source of truth.

Pure data layer: no ffmpeg, no file mutation. Everything else in the package
consumes :func:`load_manifest`.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

# tools/audio_pipeline/manifest.py -> parents[2] == repo root.
PKG_DIR = Path(__file__).resolve().parent
REPO_ROOT = PKG_DIR.parents[1]

MANIFEST_PATH = PKG_DIR / "audio_manifest.json"
AUDIO_DIR = REPO_ROOT / "assets" / "audio"
STAGING_DIR = PKG_DIR / "staging"

VALID_STATUSES = ("real", "placeholder", "draft-tts")

# Where the app declares its bundled audio directory (must match _audioDir in
# asset_audio_player.dart and the flutter.assets entry in pubspec.yaml).
ASSET_AUDIO_PREFIX = "assets/audio/"


@dataclass(frozen=True)
class AudioEntry:
    """One bundled clip: its id, asset path, description, usage and status."""

    audio_id: str
    asset_path: str  # repo-relative, forward slashes, under assets/audio/
    description: str
    used_by: str
    status: str

    @property
    def filename(self) -> str:
        """Basename under assets/audio/ (e.g. ``snd.baa.mp3``)."""
        return self.asset_path.rsplit("/", 1)[-1]

    @property
    def absolute_path(self) -> Path:
        return REPO_ROOT / self.asset_path


class ManifestError(ValueError):
    """Raised when the manifest is structurally invalid (fail loud, never guess)."""


def load_manifest(path: Path = MANIFEST_PATH) -> list[AudioEntry]:
    """Read + validate the manifest, returning entries in file order.

    Validates structure aggressively — a malformed manifest is a build error,
    not something to paper over. Checked: required fields present and non-empty,
    ``assetPath`` lives under ``assets/audio/``, ``status`` is in the allowed set,
    and no duplicate ``audioId`` or ``assetPath``.
    """
    if not path.exists():
        raise ManifestError(f"Manifest not found: {path}")

    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict) or "entries" not in raw:
        raise ManifestError("Manifest must be an object with an 'entries' array.")

    entries: list[AudioEntry] = []
    seen_ids: set[str] = set()
    seen_paths: set[str] = set()

    for i, item in enumerate(raw["entries"]):
        where = f"entries[{i}]"
        for field in ("audioId", "assetPath", "description", "usedBy", "status"):
            if field not in item or not str(item[field]).strip():
                raise ManifestError(f"{where}: missing/empty required field '{field}'.")

        audio_id = item["audioId"].strip()
        asset_path = item["assetPath"].strip()
        status = item["status"].strip()

        if status not in VALID_STATUSES:
            raise ManifestError(
                f"{where}: status '{status}' not one of {VALID_STATUSES}."
            )
        if not asset_path.startswith(ASSET_AUDIO_PREFIX):
            raise ManifestError(
                f"{where}: assetPath '{asset_path}' must start with '{ASSET_AUDIO_PREFIX}'."
            )
        if audio_id in seen_ids:
            raise ManifestError(f"{where}: duplicate audioId '{audio_id}'.")
        if asset_path in seen_paths:
            raise ManifestError(f"{where}: duplicate assetPath '{asset_path}'.")
        seen_ids.add(audio_id)
        seen_paths.add(asset_path)

        entries.append(
            AudioEntry(
                audio_id=audio_id,
                asset_path=asset_path,
                description=item["description"].strip(),
                used_by=item["usedBy"].strip(),
                status=status,
            )
        )

    if not entries:
        raise ManifestError("Manifest has no entries.")
    return entries
