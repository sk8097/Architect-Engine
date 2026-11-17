# -*- coding: utf-8 -*-
"""Offline adaptive performance direction for Cartesia Sonic narration.

All decisions are deterministic and local. The planner never calls a model or
provider; a complete directed script remains one synthesis request.
"""
import json
import os
import re
from xml.sax.saxutils import escape

_HERE = os.path.dirname(os.path.abspath(__file__))
_PROFILE_PATH = os.path.join(_HERE, "profiles", "voice_direction_profiles.json")

def load_profiles(path=None):
    with open(path or _PROFILE_PATH, encoding="utf-8") as stream:
        return json.load(stream)

def _split_segments(text):
    parts = re.split(r"(?<=[.!?।॥])\s+|\n+", text.strip())
    return [part.strip() for part in parts if part.strip()]

def _infer_intent(sentence):
    s = sentence.lower()
    if "?" in sentence or any(x in s for x in ("क्यों", "कैसे", "क्या", "what if", "why ", "how ")):
        return "question"
    if any(x in s for x in ("लेकिन", "असल", "सच", "खुलासा", "however", "reveals", "hidden", "but ")):
        return "revelation"
    if any(x in s for x in ("₹", "रुपये", "लाख", "करोड़", "interest", "fee", "emi", "%", "percent")):
        return "financial_fact"
    if any(x in s for x in ("दुख", "परिवार", "माँ", "पिता", "पीड़ा", "loss", "victim", "mother", "father")):
        return "human_interest"
    return "explanation"

def _language_settings(language):
    raw = (language or "auto").strip().lower()
    if raw in ("auto", ""):
        return None, "auto"
    if raw == "hinglish":
        return "hi", "en-IN"
    if raw in ("hi", "hi-in"):
        return ("hi" if raw == "hi" else "hi-IN"), "hi-IN"
    if raw in ("mr", "mr-in"):
        return ("mr" if raw == "mr" else "mr-IN"), "mr-IN"
    if raw in ("en", "en-in"):
        return ("en" if raw == "en" else "en-IN"), "en-IN"
    return raw, "auto"

def _clamp(value, low=0.6, high=1.5):
    return round(max(low, min(high, float(value))), 3)

def _sentence_signals(sentence):
    words = re.findall(r"[^\W_]+", sentence, flags=re.UNICODE)
    count = len(words)
    numeric = bool(re.search(r"\d|₹|%|\b(?:rupees|percent|emi|interest|fee)\b", sentence, re.I))
    commas = len(re.findall(r"[,،;；]", sentence))
    quoted = bool(re.search(r'["“”‘’]', sentence))
    exclamatory = "!" in sentence
    return {
        "word_count": count,
        "numeric_density": round(len(re.findall(r"\d+", sentence)) / max(count, 1), 3),
        "has_numeric_content": numeric,
        "comma_count": commas,
        "has_quoted_phrase": quoted,
        "is_exclamatory": exclamatory,
        "is_short_sentence": count <= 7,
        "is_long_sentence": count >= 24,
    }

def _adaptive_controls(intent, signals, mode, person, adaptive=True):
    base_speed = float(mode.get("target_speed", 1.0)) * float(person.get("speed_multiplier", 1.0))
    speed_factor = {
        "question": 0.98, "revelation": 0.91, "financial_fact": 0.96,
        "human_interest": 0.94, "explanation": 1.0,
    }[intent]
    pause = {"question": 440, "revelation": 520, "financial_fact": 300,
             "human_interest": 360, "explanation": 220}[intent]
    volume_ratio = 1.0
    if adaptive:
        if signals["is_long_sentence"]:
            speed_factor *= 0.96
            pause += 70
        elif signals["is_short_sentence"] and intent == "explanation":
            speed_factor *= 1.025
        if signals["has_numeric_content"]:
            speed_factor *= 0.97
            pause += 70
        if signals["comma_count"] >= 2:
            speed_factor *= 0.98
            pause += min(100, signals["comma_count"] * 20)
        if signals["is_exclamatory"]:
            speed_factor *= 0.97
            volume_ratio = 1.06
            pause += 60
        if signals["has_quoted_phrase"]:
            volume_ratio = max(volume_ratio, 1.025)
    speed = _clamp(base_speed * speed_factor, 0.78, 1.18)
    volume_ratio = round(max(0.9, min(1.12, volume_ratio)), 3)
    pause = max(160, min(720, int(pause)))
    return speed, volume_ratio, pause

def build_direction_plan(text, delivery_mode=None, personality=None, language="auto",
                         voice="rohan", profiles=None, adaptive=True):
    if not isinstance(text, str) or not text.strip():
        raise ValueError("Script text is empty.")
    cfg = profiles or load_profiles()
    modes = {x["id"]: x for x in cfg["delivery_modes"]}
    people = {x["id"]: x for x in cfg["personalities"]}
    mode_id = delivery_mode or cfg["defaults"]["delivery_mode"]
    person_id = personality or cfg["defaults"]["personality"]
    if mode_id not in modes:
        raise ValueError("Unknown delivery mode: " + mode_id)
    if person_id not in people:
        raise ValueError("Unknown personality: " + person_id)
    mode, person = modes[mode_id], people[person_id]
    provider_language, normalization = _language_settings(language)
    segments = []
    for index, sentence in enumerate(_split_segments(text), 1):
        intent = _infer_intent(sentence)
        signals = _sentence_signals(sentence)
        suggested_emotion = {
            "question": "curious", "revelation": "mysterious",
            "financial_fact": "skeptical", "human_interest": "sympathetic",
            "explanation": mode["default_emotion"],
        }[intent]
        speed, volume_ratio, pause_after = _adaptive_controls(
            intent, signals, mode, person, adaptive=adaptive)
        segments.append({
            "segment_id": "{:04d}".format(index), "text": sentence,
            "intent": intent, "suggested_emotion": suggested_emotion,
            "signals": signals,
            "intensity": 0.55 if intent in ("financial_fact", "explanation") else 0.68,
            "speed": speed, "volume": float(person.get("volume_multiplier", 1.0)),
            "volume_ratio": volume_ratio,
            "pause_before_ms": 0, "pause_after_ms": pause_after,
        })
    return {
        "schema_version": cfg["schema_version"], "delivery_mode": mode_id,
        "personality": person_id, "language": language, "voice": voice,
        "provider_language": provider_language, "normalization": normalization,
        "adaptive_performance": bool(adaptive),
        "segments": segments,
        "performance": {
            "speed_control": "inline_ssml",
            "volume_control": "request_generation_config_plus_inline_ssml",
            "emotion_control": "model_inferred_by_default",
            "explicit_pause_policy": "adaptive_sparse_break_tags",
            "adaptive_signals": ["sentence_length", "numeric_content", "list_punctuation",
                                 "question", "revelation", "human_interest", "exclamation", "quoted_phrase"],
            "synthesis_strategy": "one_full_script_request",
        },
        "credit_estimate": {
            "analysis_api_calls": 0, "tts_requests_if_synthesized": 1,
            "note": "Adaptive analysis and SSML rendering use no API. A cache hit uses zero synthesis requests."
        },
    }

def render_directed_transcript(plan, profiles=None, emotion_tags_enabled=None):
    cfg = profiles or load_profiles()
    ssml_cfg = cfg.get("ssml", {})
    enabled = ssml_cfg.get("emotion_tags_enabled", False) if emotion_tags_enabled is None else bool(emotion_tags_enabled)
    language = (plan.get("provider_language") or "").split("-")[0]
    allow_emotion = enabled and language == "en"
    minimum_break = int(ssml_cfg.get("minimum_break_ms", 350))
    max_breaks = int(ssml_cfg.get("max_explicit_breaks_per_script", 12))
    rendered, break_count, volume_count = [], 0, 0
    for index, segment in enumerate(plan["segments"]):
        sentence = escape(segment["text"], {'"': "&quot;", "'": "&apos;"})
        speed = _clamp(segment.get("speed", 1.0), 0.78, 1.18)
        volume_ratio = max(0.9, min(1.12, float(segment.get("volume_ratio", 1.0))))
        chunk = '<speed ratio="{:.3f}"/>'.format(speed)
        if abs(volume_ratio - 1.0) >= 0.01:
            chunk += '<volume ratio="{:.3f}"/>'.format(volume_ratio)
            volume_count += 1
        chunk += sentence
        if allow_emotion:
            from .cartesia_tts import resolve_emotion
            emotion = resolve_emotion(segment.get("suggested_emotion"))
            if emotion:
                chunk = '<emotion value="{}"/>'.format(emotion) + chunk
        rendered.append(chunk)
        pause_ms = int(segment.get("pause_after_ms", 0))
        if index < len(plan["segments"]) - 1 and pause_ms >= minimum_break and break_count < max_breaks:
            rendered.append('<break time="{}ms"/>'.format(pause_ms))
            break_count += 1
    return "".join(rendered), {
        "explicit_breaks": break_count, "emotion_tags_enabled": allow_emotion,
        "ssml_speed_tags": len(plan["segments"]), "ssml_volume_tags": volume_count,
        "adaptive_performance": bool(plan.get("adaptive_performance", True)),
    }

def generate_directed_voiceover(text, output_path="VO.wav", delivery_mode=None,
                                personality=None, language="hi", voice="rohan",
                                emotion=None, model=None, api_key=None, force=False,
                                emotion_tags_enabled=None, adaptive=True):
    from .cartesia_tts import generate_voiceover
    cfg = load_profiles()
    plan = build_direction_plan(text, delivery_mode, personality, language, voice, cfg, adaptive)
    rendered_text, ssml_stats = render_directed_transcript(plan, cfg, emotion_tags_enabled)
    person = {x["id"]: x for x in cfg["personalities"]}[plan["personality"]]
    selected_emotion = emotion or cfg["delivery_modes"][[x["id"] for x in cfg["delivery_modes"]].index(plan["delivery_mode"])]["default_emotion"]
    result = generate_voiceover(
        rendered_text, voice=voice, language=plan["provider_language"],
        emotion=selected_emotion, output_path=output_path,
        model=model or cfg["defaults"]["model"],
        speed=1.0, volume=float(person.get("volume_multiplier", 1.0)),
        normalization=plan["normalization"], api_key=api_key,
        use_cache=cfg["defaults"]["cache_enabled"], force=force,
    )
    result["direction_plan"] = plan
    result["rendered_transcript"] = rendered_text
    result["ssml_stats"] = ssml_stats
    result["delivery_mode"] = plan["delivery_mode"]
    result["personality"] = plan["personality"]
    result["characters_original"] = len(text)
    result["characters_sent"] = len(rendered_text)
    return result
