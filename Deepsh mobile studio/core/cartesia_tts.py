#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Cartesia TTS adapter with deterministic voice resolution and local cache.

Cache hits do not call Cartesia and therefore do not consume synthesis credits.
The provider payload intentionally preserves the repository's existing API
contract until a separately verified migration is performed.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request

BASE_URL = "https://api.cartesia.ai"
API_VERSION = os.environ.get("CARTESIA_API_VERSION", "2024-06-10")
DEFAULT_MODEL = os.environ.get("CARTESIA_MODEL", "sonic-3.6")

def get_cartesia_api_keys():
    keys = []
    for value in (os.environ.get("CARTESIA_API_KEY", ""),
                  os.environ.get("CARTESIA_KEYS_POOL", "")):
        for key in value.split(","):
            key = key.strip()
            if key and key not in keys:
                keys.append(key)
    key_file = os.path.expanduser("~/.cartesia_keys")
    if os.path.isfile(key_file):
        try:
            with open(key_file, encoding="utf-8") as stream:
                for line in stream:
                    key = line.strip()
                    if key and not key.startswith("#") and key not in keys:
                        keys.append(key)
        except OSError:
            pass
    return keys

DEFAULT_API_KEY = next(iter(get_cartesia_api_keys()), "")

POPULAR_VOICES = {
    "rohan": "4877b818-c7fe-4c89-b1cf-eadf8e23da72",
    "dev": "910fb75e-1d20-4840-ac63-ac6b26a71bdc",
    "neha": "47f3bbb1-e98f-4e0c-92c5-5f0325e1e206",
    "anuj": "7e8cb11d-37af-476b-ab8f-25da99b18644",
    "skylar": "db6b0ed5-d5d3-463d-ae85-518a07d3c2b4",
    "mariana": "ae823354-f9be-4aef-8543-f569644136b4",
    "siya": "4459a9a5-69d6-4680-b970-e13dc51845b6",
    "sana": "e6b71342-48f1-4c70-a13a-d197b176ff24",
    "varun": "4cd9f881-58f7-4969-876a-00983214c362",
    "sneha": "6b02ffe5-e3cb-48c0-a023-c72f85953375",
    "kavya": "ce45ddca-5f4b-4047-ada3-3fce2bc78acd",
    "barbershop": "a0e99841-438c-4a64-b679-ae501e7d6091",
    "british": "79a125e8-cd45-4c13-8a67-188112f4dd22",
}
_custom_voice = os.environ.get("CARTESIA_CUSTOM_VOICE_ID", "").strip()
if _custom_voice:
    POPULAR_VOICES["custom"] = _custom_voice

EMOTION_MAP = {
    "neutral": [], "calm": ["curiosity:low", "positivity:low"],
    "content": ["positivity:high"], "excited": ["surprise:high", "positivity:high"],
    "sad": ["sadness:high"], "angry": ["anger:high"],
    "curious": ["curiosity:high"], "dramatic": ["surprise:high"],
    "urgent": ["anger:medium", "surprise:medium"],
    "serious": ["curiosity:low"], "confident": ["positivity:medium"],
    "empathetic": ["positivity:medium"], "mysterious": ["curiosity:medium"],
}

def resolve_voice_id(name_or_id, api_key=None):
    if not isinstance(name_or_id, str) or not name_or_id.strip():
        raise ValueError("Voice must be a non-empty preset name or Cartesia voice ID.")
    value = name_or_id.strip()
    key = value.lower()
    if key in POPULAR_VOICES:
        return POPULAR_VOICES[key]
    # UUID-shaped IDs are accepted as explicit IDs; Cartesia validates existence.
    if re.fullmatch(r"[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}", value):
        return value
    if not api_key:
        raise ValueError("Unknown voice preset. Use a configured preset or provide an explicit voice UUID; API lookup requires a key.")
    matches = list_voices(query=value, api_key=api_key)
    exact = [v for v in matches if v.get("name", "").strip().lower() == key]
    if exact:
        return exact[0]["id"]
    if matches:
        return matches[0]["id"]
    raise ValueError("No Cartesia voice matched {!r}; refusing silent fallback to another narrator.".format(value))

def list_voices(query="", language="", api_key=None, limit=100):
    key = api_key or DEFAULT_API_KEY
    if not key:
        # Return only locally known presets without spending credits or requiring a key.
        return [{"id": voice_id, "name": name, "source": "local_preset"}
                for name, voice_id in POPULAR_VOICES.items()
                if query.lower() in name.lower()]
    params = "?limit={}".format(max(1, min(int(limit), 100)))
    request = urllib.request.Request(BASE_URL + "/voices" + params, headers={
        "X-API-Key": key, "Cartesia-Version": API_VERSION
    })
    try:
        with urllib.request.urlopen(request, timeout=12) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError) as exc:
        raise RuntimeError("Cartesia voice listing failed: {}".format(exc)) from exc
    voices = payload.get("data", payload) if isinstance(payload, dict) else payload
    if not isinstance(voices, list):
        raise RuntimeError("Unexpected Cartesia voices response format.")
    q = (query or "").strip().lower()
    lang = (language or "").strip().lower()
    result = []
    for voice in voices:
        if not isinstance(voice, dict):
            continue
        name = str(voice.get("name", ""))
        langs = voice.get("languages", voice.get("language", []))
        lang_text = " ".join(langs) if isinstance(langs, list) else str(langs)
        if q and q not in name.lower():
            continue
        if lang and lang not in lang_text.lower():
            continue
        result.append(voice)
    return result

def resolve_emotions(emotion):
    if not emotion:
        return []
    clean = str(emotion).strip().lower()
    if clean in EMOTION_MAP:
        return list(EMOTION_MAP[clean])
    if re.fullmatch(r"(anger|sadness|positivity|surprise|curiosity):(low|medium|high)", clean):
        return [clean]
    raise ValueError("Unsupported emotion {!r}. Available: {}".format(clean, ", ".join(EMOTION_MAP)))

def _cache_path(cache_key):
    root = os.path.expanduser(os.environ.get(
        "CARTESIA_CACHE_DIR", "~/.cache/deepsh-cartesia"))
    os.makedirs(root, exist_ok=True)
    return os.path.join(root, cache_key + ".wav")

def _probe_duration(path):
    try:
        result = subprocess.run([
            "ffprobe", "-v", "error", "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1", path
        ], capture_output=True, text=True, timeout=8, check=False)
        return round(float(result.stdout.strip()), 2) if result.returncode == 0 else 0.0
    except (OSError, ValueError, subprocess.SubprocessError):
        return 0.0

def generate_voiceover(transcript, voice="rohan", language="hi", emotion="neutral",
                       output_path="VO.wav", model=DEFAULT_MODEL, sample_rate=44100,
                       api_key=None, use_cache=True, force=False):
    text = (transcript or "").strip()
    if not text:
        raise ValueError("Transcript is empty; no API request was made.")
    if len(text) > 100000:
        raise ValueError("Transcript exceeds the local 100,000-character safety limit.")
    key = api_key or DEFAULT_API_KEY
    if not key:
        raise ValueError("Missing Cartesia API key. Set CARTESIA_API_KEY.")
    voice_id = resolve_voice_id(voice, api_key=key)
    emotion_tags = resolve_emotions(emotion)
    voice_dict = {"mode": "id", "id": voice_id}
    if emotion_tags:
        voice_dict["__experimental_controls"] = {"emotion": emotion_tags}
    payload = {
        "model_id": model, "transcript": text, "voice": voice_dict,
        "output_format": {"container": "wav", "encoding": "pcm_s16le",
                          "sample_rate": int(sample_rate)}
    }
    if language:
        payload["language"] = language
    # Cache key includes every synthesis-affecting input, never the API key.
    fingerprint = json.dumps(payload, sort_keys=True, ensure_ascii=False,
                              separators=(",", ":")).encode("utf-8")
    cache_key = hashlib.sha256(fingerprint).hexdigest()
    cached = _cache_path(cache_key) if use_cache else None
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    start = time.time()
    cache_hit = bool(cached and os.path.isfile(cached) and os.path.getsize(cached) > 44 and not force)
    if cache_hit:
        shutil.copy2(cached, output_path)
        audio_size = os.path.getsize(output_path)
        generation_time = 0.0
    else:
        request = urllib.request.Request(BASE_URL + "/tts/bytes",
            data=json.dumps(payload).encode("utf-8"),
            headers={"X-API-Key": key, "Cartesia-Version": API_VERSION,
                     "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                audio_bytes = response.read()
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", "replace")[:1500]
            raise RuntimeError("Cartesia HTTP {}: {}".format(exc.code, detail)) from exc
        except urllib.error.URLError as exc:
            raise RuntimeError("Cartesia network error: {}".format(exc.reason)) from exc
        if not audio_bytes or len(audio_bytes) < 44:
            raise RuntimeError("Cartesia returned an empty or invalid WAV response.")
        with open(output_path, "wb") as stream:
            stream.write(audio_bytes)
        if cached:
            temp = cached + ".tmp"
            with open(temp, "wb") as stream:
                stream.write(audio_bytes)
            os.replace(temp, cached)
        audio_size = len(audio_bytes)
        generation_time = round(time.time() - start, 2)
    return {
        "status": "success", "output_path": os.path.abspath(output_path),
        "duration_seconds": _probe_duration(output_path),
        "generation_time_seconds": generation_time, "voice_id": voice_id,
        "voice_name": voice, "emotion": emotion, "applied_emotion_tags": emotion_tags,
        "model": model, "bytes": audio_size, "cache_hit": cache_hit,
        "cache_key": cache_key, "api_requests": 0 if cache_hit else 1,
        "characters_submitted": 0 if cache_hit else len(text),
        "characters_cached": len(text) if cache_hit else 0,
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Credit-aware Cartesia TTS")
    parser.add_argument("--text")
    parser.add_argument("--file")
    parser.add_argument("--out", default="VO.wav")
    parser.add_argument("--voice", default="rohan")
    parser.add_argument("--lang", default="hi")
    parser.add_argument("--emotion", default="neutral", choices=sorted(EMOTION_MAP))
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--no-cache", action="store_true")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    text = args.text
    if args.file:
        with open(args.file, encoding="utf-8") as stream:
            text = stream.read()
    if not text:
        parser.error("Provide --text or --file.")
    result = generate_voiceover(text, voice=args.voice, language=args.lang,
        emotion=args.emotion, output_path=args.out, model=args.model,
        use_cache=not args.no_cache, force=args.force)
    print("Saved: {}".format(result["output_path"]))
    print("Duration: {}s | cache_hit={} | API requests={}".format(
        result["duration_seconds"], result["cache_hit"], result["api_requests"]))
