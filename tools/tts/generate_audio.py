#!/usr/bin/env python3
"""Interim AI-voice generator for Qalam pronunciation audio.

PLACEHOLDER ONLY. The owner's mother's real recordings are the product's signature
and will replace these later — audio is keyed by `audioId`, so a real recording
drops in by replacing the file of the same name, NO code change.

Engine: ElevenLabs (eleven_multilingual_v2, Arabic). Uses `curl` for all HTTP so it
works on any machine without Python TLS/cert setup. macOS `say -v Majed` is a last-
resort fallback when no API key is present.

Setup:
    tools/tts/.env  (gitignored):
        ELEVENLABS_API_KEY=sk_...
        ELEVENLABS_VOICE_ID=<pick one — run --list-voices>

Usage:
    python3 tools/tts/generate_audio.py [manifest.json] [out_dir]
    python3 tools/tts/generate_audio.py --list-voices
"""
import json, os, pathlib, subprocess, sys, tempfile

ENV_FILE = pathlib.Path(__file__).with_name(".env")
MODEL = "eleven_multilingual_v2"
API = "https://api.elevenlabs.io/v1"


def _load_env():
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())


def _curl(args):
    r = subprocess.run(["curl", "-sS", *args], capture_output=True)
    return r.stdout, r.stderr


def list_voices():
    key = os.environ["ELEVENLABS_API_KEY"]
    out, err = _curl(["-H", f"xi-api-key: {key}", f"{API}/voices"])
    try:
        data = json.loads(out)
    except Exception:
        print("Could not list voices:", (out[:200] or err[:200]).decode("utf-8", "ignore"))
        return
    print("ElevenLabs voices (pick one for ELEVENLABS_VOICE_ID):\n")
    for v in data.get("voices", []):
        lb = v.get("labels", {})
        print(f"  {v['voice_id']}  {v['name']:<26} {lb.get('language','')} {lb.get('accent','')} {lb.get('description','')}")


def synth_eleven(text, voice_id, out: pathlib.Path):
    key = os.environ["ELEVENLABS_API_KEY"]
    body = json.dumps({"text": text, "model_id": MODEL,
                       "voice_settings": {"stability": 0.5, "similarity_boost": 0.8}})
    _curl(["-X", "POST", f"{API}/text-to-speech/{voice_id}?output_format=mp3_44100_128",
           "-H", f"xi-api-key: {key}", "-H", "Content-Type: application/json",
           "-d", body, "--output", str(out)])
    # ElevenLabs returns JSON (not audio) on error — detect a tiny/text payload
    if out.stat().st_size < 800 or out.read_bytes()[:1] in (b"{", b"<"):
        msg = out.read_text("utf-8", "ignore")[:200]
        out.unlink(missing_ok=True)
        raise RuntimeError(f"TTS failed for {out.name}: {msg}")


def synth_say(text, out: pathlib.Path):
    aiff = tempfile.mktemp(suffix=".aiff")
    subprocess.run(["say", "-v", "Majed", "-o", aiff, text], check=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", aiff, str(out)], check=True)
    os.remove(aiff)


def main() -> int:
    _load_env()
    if "--list-voices" in sys.argv:
        list_voices(); return 0

    manifest = sys.argv[1] if len(sys.argv) > 1 else "tools/tts/manifest.baa.json"
    out_dir = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else "assets/audio")
    out_dir.mkdir(parents=True, exist_ok=True)

    key = os.environ.get("ELEVENLABS_API_KEY")
    voice = os.environ.get("ELEVENLABS_VOICE_ID", "")
    engine = "elevenlabs" if key else "macos-say"
    if engine == "elevenlabs" and not voice:
        print("ELEVENLABS_API_KEY set but no ELEVENLABS_VOICE_ID — run --list-voices and pick one."); return 2
    print(f"engine: {engine}{' ('+voice+')' if engine=='elevenlabs' else ' (Majed PLACEHOLDER)'}\n")

    ok = 0
    for e in json.load(open(manifest, encoding="utf-8")):
        aid, text = e["id"], e["text"]
        out = out_dir / f"{aid}.mp3"
        try:
            synth_eleven(text, voice, out) if engine == "elevenlabs" else synth_say(text, out)
            print(f"  ✓ {out.name}  ({text})"); ok += 1
        except Exception as ex:
            print(f"  ✗ {aid}: {ex}")
    print(f"\n{engine}: {ok} clips → {out_dir}  (interim — swap per audioId for her real voice later)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
