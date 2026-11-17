# -*- coding: utf-8 -*-
"""Automatic, language-aware Cartesia Sonic 3.6 performance direction.

Direction analysis is local and free. One complete script is synthesized in one
Cartesia request; inline speed and sparse break tags provide controlled variation
without paying for a separate request per sentence.
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
        # Cartesia's guide: romanized Hindi and mixed Hindi-English use hi;
        # en-IN normalization reads Latin-script English numerals naturally.
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

def build_direction_plan(text, delivery_mode=None, personality=None, language="auto",
                         voice="rohan", profiles=None):
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
    intent_speed = {
        "question": 0.98, "revelation": 0.91, "financial_fact": 0.96,
        "human_interest": 0.94, "explanation": 1.0,
    }
    segments = []
    for index, sentence in enumerate(_split_segments(text), 1):
        intent = _infer_intent(sentence)
        suggested_emotion = {
            "question": "curious", "revelation": "mysterious",
            "financial_fact": "skeptical", "human_interest": "sympathetic",
            "explanation": mode["default_emotion"],
        }[intent]
        speed = _clamp(float(mode.get("target_speed", 1.0))
                       * float(person.get("speed_multiplier", 1.0))
                       * intent_speed[intent], 0.75, 1.25)
        pause_after = 420 if intent in ("question", "revelation") else 220
        if intent == "human_interest":
            pause_after = 300
        segments.append({
            "segment_id": "{:04d}".format(index), "text": sentence,
            "intent": intent, "suggested_emotion": suggested_emotion,
            "intensity": 0.55 if intent in ("financial_fact", "explanation") else 0.68,
            "speed": speed, "volume": float(person.get("volume_multiplier", 1.0)),
            "pause_before_ms": 0, "pause_after_ms": pause_after,
        })
    return {
        "schema_version": cfg["schema_version"], "delivery_mode": mode_id,
        "personality": person_id, "language": language, "voice": voice,
        "provider_language": provider_language, "normalization": normalization,
        "segments": segments,
        "performance": {
            "speed_control": "inline_ssml", "volume_control": "request_generation_config",
            "emotion_control": "model_inferred_by_default",
            "explicit_pause_policy": "sparse_break_tags",
            "synthesis_strategy": "one_full_script_request",
        },
        "credit_estimate": {
            "analysis_api_calls": 0, "tts_requests_if_synthesized": 1,
            "note": "Local analysis and SSML rendering use no API. A cache hit uses zero synthesis requests."
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
    rendered, break_count = [], 0
    for segment in plan["segments"]:
        sentence = escape(segment["text"], {'"': "&quot;", "'": "&apos;"})
        speed = _clamp(segment.get("speed", 1.0))
        chunk = '<speed ratio="{:.3f}"/>'.format(speed) + sentence
        # Emotion tags are opt-in: Cartesia documents mid-transcript emotion
        # shifts as experimental and limits emotion tags to English.
        if allow_emotion:
            from .cartesia_tts import resolve_emotion
            emotion = resolve_emotion(segment.get("suggested_emotion"))
            if emotion:
                chunk = '<emotion value="{}"/>'.format(emotion) + chunk
        rendered.append(chunk)
        pause_ms = int(segment.get("pause_after_ms", 0))
        if pause_ms >= minimum_break and break_count < max_breaks:
            rendered.append('<break time="{}ms"/>'.format(pause_ms))
            break_count += 1
    return "".join(rendered), {"explicit_breaks": break_count,
        "emotion_tags_enabled": allow_emotion, "ssml_speed_tags": len(plan["segments"])}

def generate_directed_voiceover(text, output_path="VO.wav", delivery_mode=None,
                                personality=None, language="hi", voice="rohan",
                                emotion=None, model=None, api_key=None, force=False,
                                emotion_tags_enabled=None):
    from .cartesia_tts import generate_voiceover
    cfg = load_profiles()
    plan = build_direction_plan(text, delivery_mode, personality, language, voice, cfg)
    rendered_text, ssml_stats = render_directed_transcript(plan, cfg, emotion_tags_enabled)
    person = {x["id"]: x for x in cfg["personalities"]}[plan["personality"]]
    # Sonic infers emotion from transcript semantics by default. Explicit request
    # emotion is passed only for English; the adapter omits it for Hindi/Marathi.
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
