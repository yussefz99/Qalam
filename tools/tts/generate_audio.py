#!/usr/bin/env python3
"""Interim AI-voice generator for Qalam pronunciation audio.

PLACEHOLDER ONLY. The owner's mother's real recordings are the product's signature
and will replace these later — audio is keyed by `audioId`, so a real recording
drops in by replacing the file of the same name, NO code change.

Engines:
  - ElevenLabs (preferred): set ELEVENLABS_API_KEY (+ optional ELEVENLABS_VOICE_ID).
    Reads tools/tts/.env if present (gitignored). Model: eleven_multilingual_v2 (Arabic).
  - macOS `say -v Majed` fallback when no API key is set.

Usage:
    python3 tools/tts/generate_audio.py [manifest.json] [out_dir]
    python3 tools/tts/generate_audio.py --list-voices      # ElevenLabs voices (pick one)

Manifest: a JSON list of { "id": "<audioId>", "text": "<arabic>" }.
Output:   <out_dir>/<audioId>.mp3   (default out_dir = assets/audio)
"""
import json, os, pathlib, subprocess, sys, tempfile, urllib.request, urllib.error

ENV_FILE = pathlib.Path(__file__).with_name(".env")
MODEL = "eleven_multilingual_v2"
DEFAULT_VOICE = os.environ.get("ELEVENLABS_VOICE_ID", "")  # set after we pick one


def _load_env():
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())


def _eleven_request(path, method="GET", body=None):
    key = os.environ["ELEVENLABS_API_KEY"]
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1{path}",
        data=json.dumps(body).encode() if body else None,
        method=method,
        headers={"xi-api-key": key, "Content-Type": "application/json"},
    )
    return urllib.request.urlopen(req)


def list_voices():
    data = json.load(_eleven_request("/voices"))
    print("ElevenLabs voices on this account (pick one for ELEVENLABS_VOICE_ID):\n")
    for v in data.get("voices", []):
        labels = v.get("labels", {})
        lang = labels.get("language") or labels.get("accent") or ""
        print(f"  {v['voice_id']}  {v['name']:<22} {lang}  {labels.get('description','')}")


def synth_eleven(text, voice_id, out: pathlib.Path):
    body = {"text": text, "model_id": MODEL,
            "voice_settings": {"stability": 0.5, "similarity_boost": 0.8}}
    resp = _eleven_request(
        f"/text-to-speech/{voice_id}?output_format=mp3_44100_128",
        method="POST", body=body)
    out.write_bytes(resp.read())


def synth_say(text, out: pathlib.Path):
    aiff = tempfile.mktemp(suffix=".aiff")
    subprocess.run(["say", "-v", "Majed", "-o", aiff, text], check=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", aiff, str(out)], check=True)
    os.remove(aiff)


def main() -> int:
    _load_env()
    if "--list-voices" in sys.argv:
        list_voices()
        return 0

    manifest = sys.argv[1] if len(sys.argv) > 1 else "tools/tts/manifest.baa.json"
    out_dir = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else "assets/audio")
    out_dir.mkdir(parents=True, exist_ok=True)

    key = os.environ.get("ELEVENLABS_API_KEY")
    voice = os.environ.get("ELEVENLABS_VOICE_ID", DEFAULT_VOICE)
    engine = "elevenlabs" if key else "macos-say"
    if engine == "elevenlabs" and not voice:
        print("ELEVENLABS_API_KEY set but no ELEVENLABS_VOICE_ID — run --list-voices and pick one.")
        return 2
    print(f"engine: {engine}{' ('+voice+')' if engine=='elevenlabs' else ' (Majed, PLACEHOLDER)'}\n")

    for e in json.load(open(manifest, encoding="utf-8")):
        aid, text = e["id"], e["text"]
        out = out_dir / f"{aid}.mp3"
        if engine == "elevenlabs":
            synth_eleven(text, voice, out)
        else:
            synth_say(text, out)
        print(f"  ✓ {out.name}  ({text})")
    print(f"\n{engine}: clips → {out_dir}  (interim — swap per audioId for her real voice later)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
