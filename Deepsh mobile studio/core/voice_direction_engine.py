# -*- coding: utf-8 -*-
"""Local, zero-LLM-call voice direction planner for Cartesia narration.

It prepares a reviewable segment plan but synthesizes the complete script in one
provider request by default. This avoids multiplying API requests/credit usage.
"""
import json
import os
import re

_HERE = os.path.dirname(os.path.abspath(__file__))
_PROFILE_PATH = os.path.join(_HERE, "profiles", "voice_direction_profiles.json")

def load_profiles(path=None):
    with open(path or _PROFILE_PATH, encoding="utf-8") as stream:
        return json.load(stream)

def _split_segments(text):
    # Split on sentence punctuation/newlines while retaining readable units.
    pieces = re.split(r"(?<=[.!?।॥])\s+|\n+", text.strip())
    return [p.strip() for p in pieces if p.strip()]

def _infer_intent(sentence):
    s = sentence.lower()
    if "?" in sentence or any(x in s for x in ("क्यों", "कैसे", "what if", "why ", "how ")):
        return "question"
    if any(x in s for x in ("लेकिन", "असल", "सच", "खुलासा", "however", "reveals", "hidden")):
        return "revelation"
    if any(x in s for x in ("₹", "रुपये", "लाख", "करोड़", "interest", "fee", "emi", "%")):
        return "financial_fact"
    if any(x in s for x in ("दुख", "परिवार", "माँ", "पिता", "पीड़ा", "loss", "victim")):
        return "human_interest"
    return "explanation"

def build_direction_plan(text, delivery_mode=None, personality=None, language="auto", voice="rohan", profiles=None):
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
    segments = []
    for index, sentence in enumerate(_split_segments(text), 1):
        intent = _infer_intent(sentence)
        emotion = modes[mode_id]["default_emotion"]
        if intent == "question":
            emotion = "curious"
        elif intent == "revelation":
            emotion = "dramatic"
        elif intent == "financial_fact":
            emotion = "serious"
        elif intent == "human_interest":
            emotion = "empathetic"
        segments.append({
            "segment_id": "{:04d}".format(index), "text": sentence,
            "intent": intent, "suggested_emotion": emotion,
            "intensity": 0.55 if intent in ("financial_fact", "explanation") else 0.68,
            "pause_before_ms": 180 if intent == "revelation" else 0,
            "pause_after_ms": 420 if intent in ("question", "revelation") else 220,
            "synthesis_strategy": "whole_script_single_request"
        })
    return {
        "schema_version": cfg["schema_version"], "delivery_mode": mode_id,
        "personality": person_id, "language": language, "voice": voice,
        "segments": segments,
        "credit_estimate": {"analysis_api_calls": 0, "tts_requests_if_synthesized": 1,
                            "note": "Segment directions are metadata; initial synthesis uses one request to avoid credit-heavy sentence calls."}
    }

def generate_directed_voiceover(text, output_path="VO.wav", delivery_mode=None,
                                personality=None, language="hi", voice="rohan",
                                emotion=None, model=None, api_key=None, force=False):
    from .cartesia_tts import generate_voiceover
    cfg = load_profiles()
    plan = build_direction_plan(text, delivery_mode, personality, language, voice, cfg)
    selected_emotion = emotion or cfg["delivery_modes"][[x["id"] for x in cfg["delivery_modes"]].index(plan["delivery_mode"])]["default_emotion"]
    # Hinglish is a script/content mix, not a provider language code. Let the
    # selected Cartesia model infer it rather than sending an unsupported label.
    provider_language = None if (language or "").lower() in ("auto", "hinglish") else language
    result = generate_voiceover(text, voice=voice, language=provider_language,
        emotion=selected_emotion, output_path=output_path,
        model=model or cfg["defaults"]["model"], api_key=api_key,
        use_cache=cfg["defaults"]["cache_enabled"], force=force)
    result["direction_plan"] = plan
    result["delivery_mode"] = plan["delivery_mode"]
    result["personality"] = plan["personality"]
    return result
