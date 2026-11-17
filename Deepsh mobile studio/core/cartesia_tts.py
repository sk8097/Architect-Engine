#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Cartesia Sonic 3.6 adapter: deterministic voices, directed prosody and caching."""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import time
import urllib.error
import urllib.request

BASE_URL = "https://api.cartesia.ai"
API_VERSION = os.environ.get("CARTESIA_API_VERSION", "2026-08-14")
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

# Sonic 3.6 emotion guidance is documented for English only.
# Aliases are mapped to documented Cartesia emotion values, never invented tags.
EMOTION_MAP = {
    "neutral": "neutral", "calm": "calm", "content": "content",
    "excited": "excited", "sad": "sad", "angry": "angry",
    "curious": "curious", "dramatic": "determined", "urgent": "alarmed",
    "serious": "skeptical", "confident": "confident",
    "empathetic": "sympathetic", "mysterious": "mysterious",
    "happy": "happy", "scared": "scared", "anxious": "anxious",
    "surprised": "surprised", "peaceful": "peaceful",
}
SUPPORTED_EMOTIONS = {
    "neutral", "happy", "excited", "enthusiastic", "elated", "euphoric",
    "triumphant", "amazed", "surprised", "flirtatious", "curious", "content",
    "peaceful", "serene", "calm", "grateful", "affectionate", "trust",
    "sympathetic", "anticipation", "mysterious", "angry", "mad", "outraged",
    "frustrated", "agitated", "threatened", "disgusted", "contempt", "envious",
    "sarcastic", "ironic", "sad", "dejected", "melancholic", "disappointed",
    "hurt", "guilty", "bored", "tired", "rejected", "nostalgic", "wistful",
    "apologetic", "hesitant", "insecure", "confused", "resigned", "anxious",
    "panicked", "alarmed", "scared", "proud", "confident", "distant",
    "skeptical", "contemplative", "determined",
}

def resolve_voice_id(name_or_id, api_key=None):
    if not isinstance(name_or_id, str) or not name_or_id.strip():
        raise ValueError("Voice must be a non-empty preset name or Cartesia voice ID.")
    value = name_or_id.strip()
    key = value.lower()
    if key in POPULAR_VOICES:
        return POPULAR_VOICES[key]
    if re.fullmatch(r"[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}", value):
        return value
    if not api_key:
        raise ValueError("Unknown voice preset. Use a configured preset or explicit voice UUID.")
    matches = list_voices(query=value, api_key=api_key)
    exact = [v for v in matches if v.get("name", "").strip().lower() == key]
    if exact:
        return exact[0]["id"]
    if matches:
        return matches[0]["id"]
    raise ValueError("No Cartesia voice matched {!r}; refusing silent narrator fallback.".format(value))

def list_voices(query="", language="", api_key=None, limit=100):
    key = api_key or DEFAULT_API_KEY
    if not key:
        return [{"id": voice_id, "name": name, "source": "local_preset"}
                for name, voice_id in POPULAR_VOICES.items()
                if query.lower() in name.lower()]
    params = "?limit={}".format(max(1, min(int(limit), 100)))
    request = urllib.request.Request(BASE_URL + "/voices" + params, headers={
        "Authorization": "Bearer " + key, "Cartesia-Version": API_VERSION
    })
    try:
        with urllib.request.urlopen(request, timeout=12) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError) as exc:
        raise RuntimeError("Cartesia voice listing failed: {}".format(exc)) from exc
    voices = payload.get("data", payload) if isinstance(payload, dict) else payload
    if not isinstance(voices, list):
        raise RuntimeError("Unexpected Cartesia voices response format.")
    q, lang = (query or "").strip().lower(), (language or "").strip().lower()
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

def resolve_emotion(emotion):
    if not emotion:
        return None
    clean = str(emotion).strip().lower()
    resolved = EMOTION_MAP.get(clean, clean)
    if resolved not in SUPPORTED_EMOTIONS:
        raise ValueError("Unsupported Cartesia emotion {!r}.".format(emotion))
    return resolved

def resolve_emotions(emotion):
    """Backward-compatible list form for older internal callers."""
    value = resolve_emotion(emotion)
    return [value] if value and value != "neutral" else []

def normalize_language(language):
    value = (language or '').strip()
    lower = value.lower()
    if lower in ('', 'auto'):
        return None
    if lower == 'hinglish':
        return 'hi'
    if '-' in lower:
        base, region = lower.split('-', 1)
        return base + '-' + region.upper()
    return lower

def _cache_path(cache_key):
    root = os.path.expanduser(os.environ.get("CARTESIA_CACHE_DIR", "~/.cache/deepsh-cartesia"))
    os.makedirs(root, exist_ok=True)
    return os.path.join(root, cache_key + ".wav")

def _probe_duration(path):
    try:
        result = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1", path],
            capture_output=True, text=True, timeout=8, check=False)
        return round(float(result.stdout.strip()), 2) if result.returncode == 0 else 0.0
    except (OSError, ValueError, subprocess.SubprocessError):
        return 0.0

def build_generation_config(speed=1.0, volume=1.0, emotion=None, language="auto", model=DEFAULT_MODEL):
    if not isinstance(speed, (int, float)) or isinstance(speed, bool) or not 0.6 <= float(speed) <= 1.5:
        raise ValueError("Cartesia speed must be between 0.6 and 1.5.")
    if not isinstance(volume, (int, float)) or isinstance(volume, bool) or not 0.5 <= float(volume) <= 2.0:
        raise ValueError("Cartesia volume must be between 0.5 and 2.0.")
    if not str(model).startswith("sonic-3"):
        raise ValueError("generation_config controls in this adapter require a Sonic 3+ model.")
    config = {"speed": round(float(speed), 3), "volume": round(float(volume), 3)}
    language_code = normalize_language(language)
    if emotion and language_code and language_code.split("-")[0] == "en":
        config["emotion"] = resolve_emotion(emotion)
    return config

def generate_voiceover(transcript, voice="rohan", language="hi", emotion="neutral",
                       output_path="VO.wav", model=DEFAULT_MODEL, sample_rate=44100,
                       api_key=None, use_cache=True, force=False, speed=1.0,
                       volume=1.0, locale=None, normalization="auto",
                       pronunciation_dict_id=None):
    text = (transcript or "").strip()
    if not text:
        raise ValueError("Transcript is empty; no API request was made.")
    if len(text) > 100000:
        raise ValueError("Transcript exceeds the local 100,000-character safety limit.")
    key = api_key or DEFAULT_API_KEY
    if not key:
        raise ValueError("Missing Cartesia API key. Set CARTESIA_API_KEY.")
    voice_id = resolve_voice_id(voice, api_key=key)
    lang = normalize_language(language)
    loc = locale or (lang if lang and "-" in lang else None)
    if lang and not loc:
        loc = lang
    generation_config = build_generation_config(speed, volume, emotion, loc or lang or "auto", model)
    payload = {
        "model_id": model, "transcript": text, "voice": voice_id,
        "output_format": {"container": "wav", "encoding": "pcm_s16le",
                          "sample_rate": int(sample_rate)},
        "generation_config": generation_config,
    }
    if loc:
        payload["locale"] = loc
    if normalization:
        payload["normalization"] = normalization
    if pronunciation_dict_id:
        payload["pronunciation_dict_id"] = pronunciation_dict_id
    fingerprint = json.dumps(payload, sort_keys=True, ensure_ascii=False,
                              separators=(",", ":")).encode("utf-8")
    cache_key = hashlib.sha256(fingerprint).hexdigest()
    cached = _cache_path(cache_key) if use_cache else None
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    start = time.time()
    cache_hit = bool(cached and os.path.isfile(cached) and os.path.getsize(cached) > 44 and not force)
    if cache_hit:
        shutil.copy2(cached, output_path)
        audio_size, generation_time = os.path.getsize(output_path), 0.0
    else:
        request = urllib.request.Request(BASE_URL + "/tts/bytes",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Authorization": "Bearer " + key, "Cartesia-Version": API_VERSION,
                     "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                audio_bytes = response.read()
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", "replace")[:1500]
            raise RuntimeError("Cartesia HTTP {}: {}".format(exc.code, detail)) from exc
        except urllib.error.URLError as exc:
            raise RuntimeError("Cartesia network error: {}".format(exc.reason)) from exc
        if not audio_bytes or len(audio_bytes) < 44 or not audio_bytes.startswith(b"RIFF"):
            raise RuntimeError("Cartesia returned an empty or invalid WAV response.")
        with open(output_path, "wb") as stream:
            stream.write(audio_bytes)
        if cached:
            temp = cached + ".tmp"
            with open(temp, "wb") as stream:
                stream.write(audio_bytes)
            os.replace(temp, cached)
        audio_size, generation_time = len(audio_bytes), round(time.time() - start, 2)
    effective_language = loc or lang or "auto"
    return {
        "status": "success", "output_path": os.path.abspath(output_path),
        "duration_seconds": _probe_duration(output_path),
        "generation_time_seconds": generation_time, "voice_id": voice_id,
        "voice_name": voice, "emotion_requested": emotion,
        "emotion_applied": bool(generation_config.get("emotion")),
        "generation_config": generation_config, "language": effective_language,
        "model": model, "api_version": API_VERSION, "bytes": audio_size,
        "cache_hit": cache_hit, "cache_key": cache_key,
        "api_requests": 0 if cache_hit else 1,
        "characters_submitted": 0 if cache_hit else len(text),
        "characters_cached": len(text) if cache_hit else 0,
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Credit-aware Cartesia Sonic 3.6 TTS")
    parser.add_argument("--text")
    parser.add_argument("--file")
    parser.add_argument("--out", default="VO.wav")
    parser.add_argument("--voice", default="rohan")
    parser.add_argument("--lang", default="hi")
    parser.add_argument("--emotion", default="neutral", choices=sorted(EMOTION_MAP))
    parser.add_argument("--speed", type=float, default=1.0)
    parser.add_argument("--volume", type=float, default=1.0)
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
        speed=args.speed, volume=args.volume, use_cache=not args.no_cache, force=args.force)
    print("Saved: {}".format(result["output_path"]))
    print("Duration: {}s | cache_hit={} | API requests={} | generation_config={}".format(
        result["duration_seconds"], result["cache_hit"], result["api_requests"],
        result["generation_config"]))
