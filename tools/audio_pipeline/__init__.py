"""Qalam audio pipeline — manifest-driven ingest/normalize + generators + drift check.

One manifest (``audio_manifest.json``) is the single source of truth for the
bundled pronunciation clips. From it we:

  * ``normalize`` raw recordings from ``staging/`` into ``assets/audio/`` (ffmpeg:
    trim silence, EBU R128 loudness ~ -16 LUFS mono, resample 44.1 kHz, mp3);
  * ``generate`` the audioId table in ``assets/audio/README.md`` and the
    ``_audioIdToAsset`` map in ``lib/services/asset_audio_player.dart`` (only ever
    between the ``BEGIN GENERATED (audio_manifest)`` / ``END GENERATED`` markers);
  * ``check`` for drift — every manifest entry has a file, every file has an entry,
    and the generated blocks are current. Exits non-zero on any drift (CI-friendly).

Run from the ``tools/`` directory:  ``python -m audio_pipeline <command>``.
"""

from __future__ import annotations

__all__ = ["manifest", "generators", "normalize", "check"]
