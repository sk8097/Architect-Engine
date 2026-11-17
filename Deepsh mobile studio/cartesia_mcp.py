#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MCP tools for credit-aware Cartesia voice generation."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from core.cartesia_tts import (
    generate_voiceover, list_voices, DEFAULT_API_KEY, resolve_voice_id,
    POPULAR_VOICES, EMOTION_MAP, API_VERSION, DEFAULT_MODEL
)
from core.voice_direction_engine import load_profiles, build_direction_plan, generate_directed_voiceover
from core.audio_quality import analyze_wav
from core.pronunciation_normalizer import normalize_for_speech
from mcp.server.mcpserver import MCPServer

app = MCPServer(name="cartesia-mcp", version="2.0.0",
    description="Credit-aware Cartesia TTS with configurable voice direction profiles")

@app.tool()
def cartesia_generate_voice(transcript: str, voice: str = "rohan",
    emotion: str = "neutral", language: str = "hi", output_path: str = "VO.wav",
    model: str = DEFAULT_MODEL, use_cache: bool = True, force: bool = False,
    speed: float = 1.0, volume: float = 1.0) -> str:
    """Generate speech. Cache hits reuse audio without a Cartesia synthesis request."""
    try:
        result = generate_voiceover(transcript, voice, language, emotion,
            output_path, model, use_cache=use_cache, force=force,
            speed=speed, volume=volume)
        return json.dumps(result, ensure_ascii=False, indent=2)
    except Exception as exc:
        return json.dumps({"status": "error", "error": str(exc)}, ensure_ascii=False, indent=2)

@app.tool()
def cartesia_list_voices(query: str = "", language: str = "") -> str:
    """List local presets without API access, or filter provider voices when configured."""
    try:
        voices = list_voices(query=query, language=language)
        return json.dumps({"status": "success",
            "recommended_voices": list(POPULAR_VOICES),
            "available_emotions": list(EMOTION_MAP),
            "total_matching": len(voices), "voices": voices[:50]},
            ensure_ascii=False, indent=2)
    except Exception as exc:
        return json.dumps({"status": "error", "error": str(exc)}, ensure_ascii=False, indent=2)

@app.tool()
def cartesia_voice_direction_catalog() -> str:
    """Return all local delivery modes and personality presets; makes no API calls."""
    try:
        return json.dumps(load_profiles(), ensure_ascii=False, indent=2)
    except Exception as exc:
        return json.dumps({"status": "error", "error": str(exc)}, ensure_ascii=False, indent=2)

@app.tool()
def cartesia_plan_voice_direction(transcript: str, delivery_mode: str = "documentary",
    personality: str = "documentary_host", language: str = "auto", voice: str = "rohan") -> str:
    """Build a zero-credit direction plan. Does not synthesize audio."""
    try:
        return json.dumps(build_direction_plan(transcript, delivery_mode, personality,
            language, voice), ensure_ascii=False, indent=2)
    except Exception as exc:
        return json.dumps({"status": "error", "error": str(exc)}, ensure_ascii=False, indent=2)

@app.tool()
def cartesia_generate_directed_voice(transcript: str, delivery_mode: str = "documentary",
    personality: str = "documentary_host", voice: str = "rohan", language: str = "hi",
    output_path: str = "VO.wav", force: bool = False) -> str:
    """Auto-direct a complete script and synthesize it in one credit-aware request."""
    try:
        result = generate_directed_voiceover(transcript, output_path=output_path,
            delivery_mode=delivery_mode, personality=personality, voice=voice,
            language=language, force=force)
        return json.dumps(result, ensure_ascii=False, indent=2)
    except Exception as exc:
        return json.dumps({"status": "error", "error": str(exc)}, ensure_ascii=False, indent=2)

@app.tool()
def cartesia_normalize_pronunciation(transcript: str, language: str = "auto",
    glossary_path: str = "pronunciation_glossary.json", expand_digits: bool = False) -> str:
    """Preview deterministic pronunciation normalization locally; makes no API calls."""
    try:
        return json.dumps(normalize_for_speech(transcript, language, glossary_path, expand_digits),
            ensure_ascii=False, indent=2)
    except Exception as exc:
        return json.dumps({"status": "error", "error": str(exc)}, ensure_ascii=False, indent=2)

@app.tool()
def cartesia_status() -> str:
    """Report local readiness without pretending to verify remote connectivity."""
    return json.dumps({
        "status": "configured" if DEFAULT_API_KEY else "missing_api_key",
        "message": "API key is configured; remote connectivity is not tested by this local status check."
                   if DEFAULT_API_KEY else "Set CARTESIA_API_KEY to enable synthesis.",
        "recommended_voices": list(POPULAR_VOICES),
        "supported_emotions": list(EMOTION_MAP),
        "delivery_modes": len(load_profiles()["delivery_modes"]),
        "personalities": len(load_profiles()["personalities"]),
        "default_model": DEFAULT_MODEL, "api_version": API_VERSION,
        "cache_directory": os.path.expanduser(os.environ.get("CARTESIA_CACHE_DIR", "~/.cache/deepsh-cartesia"))
    }, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    app.run(transport="stdio")
