# -*- coding: utf-8 -*-
"""Deterministic, offline pronunciation normalization for multilingual narration.

Source scripts are never modified. Only explicitly configured glossary entries are
rewritten; numeric tokens can optionally be spoken digit-by-digit. This deliberately
avoids guessing transliterations for names and code-switched words.
"""
import json
import os
import re

RULESET_VERSION = "pronunciation-normalizer-v1"
DEFAULT_GLOSSARY = "pronunciation_glossary.json"

DIGITS = {
    "en": ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"],
    "hi": ["शून्य", "एक", "दो", "तीन", "चार", "पाँच", "छह", "सात", "आठ", "नौ"],
    "mr": ["शून्य", "एक", "दोन", "तीन", "चार", "पाच", "सहा", "सात", "आठ", "नऊ"],
}
CURRENCY = {"en": "rupees", "hi": "रुपये", "mr": "रुपये"}
PERCENT = {"en": "percent", "hi": "प्रतिशत", "mr": "टक्के"}
DECIMAL = {"en": "point", "hi": "दशमलव", "mr": "दशांश"}

def _base_language(language):
    value = (language or "auto").strip().lower()
    if value in ("hinglish", "hi", "hi-in"):
        return "hi"
    if value in ("mr", "mr-in", "marathi"):
        return "mr"
    if value in ("en", "en-in", "english"):
        return "en"
    return None

def load_glossary(path=None):
    path = path or DEFAULT_GLOSSARY
    if not os.path.isfile(path):
        return {"schema_version": RULESET_VERSION, "entries": {}}
    with open(path, encoding="utf-8") as stream:
        data = json.load(stream)
    if not isinstance(data, dict) or not isinstance(data.get("entries", {}), dict):
        raise ValueError("Pronunciation glossary must contain an 'entries' object.")
    return data

def _replace_glossary(text, entries):
    result, applied = text, []
    # Longest-first avoids a short phrase consuming part of a longer phrase.
    for source in sorted(entries, key=len, reverse=True):
        target = entries[source]
        if not isinstance(source, str) or not source.strip() or not isinstance(target, str) or not target.strip():
            raise ValueError("Glossary keys and replacements must be non-empty strings.")
        pattern = re.compile(r"(?<!\w)" + re.escape(source) + r"(?!\w)", re.IGNORECASE)
        result, count = pattern.subn(lambda _: target, result)
        if count:
            applied.append({"source": source, "replacement": target, "count": count})
    return result, applied

def normalize_for_speech(text, language="auto", glossary_path=None, expand_digits=False):
    if not isinstance(text, str):
        raise TypeError("Narration text must be a string.")
    glossary = load_glossary(glossary_path)
    entries = glossary.get("entries", {})
    lang = _base_language(language)
    normalized, applied = _replace_glossary(text, entries)
    numeric_tokens = re.findall(r"(?<!\w)\d+(?:[.,/]\d+)*(?!\w)", normalized)
    if expand_digits and lang:
        normalized = re.sub(r"₹\\s*(?=\\d)", CURRENCY[lang] + " ", normalized)
        normalized = re.sub(r"(?<=\\d)\\s*%", " " + PERCENT[lang], normalized)
        digit_words = DIGITS[lang]
        def speak_number(match):
            raw = match.group(0)
            out = []
            for char in raw:
                if char.isdigit():
                    out.append(digit_words[int(char)])
                elif char == "." or char == ",":
                    out.append(DECIMAL[lang] if char == "." else "")
                elif char == "/":
                    out.append(" ")
            return " ".join(x for x in out if x)
        normalized = re.sub(r"(?<!\w)\d+(?:[.,/]\d+)*(?!\w)", speak_number, normalized)
        normalized = re.sub(r"\s+", " ", normalized).strip()
    return {
        "source_text": text,
        "normalized_text": normalized,
        "language": language,
        "ruleset_version": RULESET_VERSION,
        "glossary_version": glossary.get("version", "unversioned"),
        "glossary_applied": applied,
        "numeric_tokens_detected": numeric_tokens,
        "numeric_expansion": "digit_by_digit" if expand_digits and lang else "provider_default",
        "manual_review_recommended": bool(numeric_tokens) and not (expand_digits and lang),
    }
