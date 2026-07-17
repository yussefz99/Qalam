"""Ingest + normalize raw recordings into bundled clips (ffmpeg).

Drop raw files into ``tools/audio_pipeline/staging/`` named after their audioId
(e.g. ``snd.baa.wav``, ``word.thalj.m4a``). ``normalize`` then, per clip:

  * trims leading/trailing silence,
  * loudness-normalizes to EBU R128 (~ -16 LUFS), mono,
  * resamples to 44.1 kHz,
  * encodes mp3,
  * writes to the manifest ``assetPath`` for that audioId.

Voice-agnostic by design — it doesn't care who recorded the clip. It never
guesses: a staging file whose stem is not a known audioId is reported and
skipped. It also never flips a clip's ``status`` for you — a normalized clip is
only ``"real"`` once a human confirms it's the real recording (edit the manifest,
then re-run ``generate`` + ``check``).
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from .manifest import STAGING_DIR, AudioEntry, load_manifest

# Formats we accept in staging. Output is always mp3.
RAW_SUFFIXES = (".wav", ".m4a", ".mp3", ".flac", ".ogg", ".aac", ".aiff")

# EBU R128 loudness target — matches the brief (~ -16 LUFS), true-peak headroom.
LUFS_TARGET = -16.0
TRUE_PEAK = -1.5
LOUDNESS_RANGE = 11.0
SAMPLE_RATE = 44100

# Trim silence quieter than this at both ends, keeping a small pad.
_SILENCE_THRESHOLD_DB = -50
_SILENCE_PAD_S = 0.1


def ffmpeg_available() -> bool:
    return shutil.which("ffmpeg") is not None


def _filter_chain() -> str:
    trim_head = (
        f"silenceremove=start_periods=1:start_silence={_SILENCE_PAD_S}:"
        f"start_threshold={_SILENCE_THRESHOLD_DB}dB"
    )
    # Trailing silence: reverse, trim the (now-leading) tail, reverse back.
    loudnorm = f"loudnorm=I={LUFS_TARGET}:TP={TRUE_PEAK}:LRA={LOUDNESS_RANGE}"
    resample = f"aresample={SAMPLE_RATE}"
    return f"{trim_head},areverse,{trim_head},areverse,{loudnorm},{resample}"


def _staging_files() -> list[Path]:
    if not STAGING_DIR.exists():
        return []
    return sorted(
        p for p in STAGING_DIR.iterdir()
        if p.is_file() and p.suffix.lower() in RAW_SUFFIXES
    )


def normalize_one(raw: Path, entry: AudioEntry) -> None:
    """Run ffmpeg to normalize ``raw`` into ``entry``'s bundled asset path."""
    out = entry.absolute_path
    out.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
        "-i", str(raw),
        "-af", _filter_chain(),
        "-ac", "1",
        "-ar", str(SAMPLE_RATE),
        "-c:a", "libmp3lame", "-q:a", "2",
        str(out),
    ]
    subprocess.run(cmd, check=True)


def run_normalize() -> int:
    """Normalize every recognized staging file. Returns a process exit code."""
    entries_by_id = {e.audio_id: e for e in load_manifest()}
    raws = _staging_files()

    if not raws:
        print(
            f"No raw recordings in {STAGING_DIR.relative_to(STAGING_DIR.parents[2])}.\n"
            "Drop files named <audioId>.<ext> (e.g. snd.baa.wav) there, then re-run."
        )
        return 0

    if not ffmpeg_available():
        print(
            "ERROR: ffmpeg not found on PATH — required to normalize audio.\n"
            "Install it (https://ffmpeg.org/download.html) and re-run.\n"
            f"{len(raws)} staged file(s) were left untouched."
        )
        return 1

    processed, skipped = 0, []
    for raw in raws:
        audio_id = raw.stem  # e.g. snd.baa.wav -> "snd.baa"
        entry = entries_by_id.get(audio_id)
        if entry is None:
            skipped.append(raw.name)
            continue
        print(f"  normalize {raw.name} -> {entry.asset_path}")
        normalize_one(raw, entry)
        processed += 1

    print(f"\nNormalized {processed} clip(s).")
    if skipped:
        print(
            f"Skipped {len(skipped)} file(s) with no matching audioId (not guessing): "
            + ", ".join(skipped)
        )
    if processed:
        print(
            "\nNext: if a normalized clip is a REAL human recording, set its status to "
            "'real' in audio_manifest.json, then run `python -m audio_pipeline generate` "
            "and `python -m audio_pipeline check`."
        )
    return 0
