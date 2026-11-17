# -*- coding: utf-8 -*-
import json
import os
import sys
import tempfile
import unittest

STUDIO = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if STUDIO not in sys.path:
    sys.path.insert(0, STUDIO)

from core.pronunciation_normalizer import normalize_for_speech, load_glossary, RULESET_VERSION

class PronunciationNormalizerTests(unittest.TestCase):
    def test_source_is_preserved_and_default_does_not_guess(self):
        source = "आज EMI का भुगतान 12/11/2026 को होगा."
        result = normalize_for_speech(source, "hi")
        self.assertEqual(result["source_text"], source)
        self.assertEqual(result["normalized_text"], source)
        self.assertTrue(result["manual_review_recommended"])
        self.assertEqual(result["ruleset_version"], RULESET_VERSION)

    def test_digit_expansion_is_explicit_and_language_aware(self):
        hi = normalize_for_speech("₹25", "hi", expand_digits=True)
        mr = normalize_for_speech("2026", "mr", expand_digits=True)
        en = normalize_for_speech("3.5", "en", expand_digits=True)
        self.assertEqual(hi["normalized_text"], "रुपये दो पाँच")
        self.assertEqual(mr["normalized_text"], "दोन शून्य दोन सहा")
        self.assertEqual(en["normalized_text"], "three point five")
        date = normalize_for_speech("12/11/2026", "mr", expand_digits=True)
        self.assertEqual(date["normalized_text"], "एक दोन स्लॅश एक एक स्लॅश दोन शून्य दोन सहा")
        self.assertEqual(hi["numeric_expansion"], "digit_by_digit")

    def test_glossary_longest_match_and_case_insensitive(self):
        with tempfile.TemporaryDirectory() as temp:
            path = os.path.join(temp, "glossary.json")
            with open(path, "w", encoding="utf-8") as stream:
                json.dump({"version":"test-1","entries":{
                    "EMI": "ई एम आई", "Zero Cost EMI": "ज़ीरो कॉस्ट ई एम आई"
                }}, stream, ensure_ascii=False)
            result = normalize_for_speech("Zero Cost EMI and emi", "hinglish", path)
            self.assertEqual(result["normalized_text"], "ज़ीरो कॉस्ट ई एम आई and ई एम आई")
            self.assertEqual(len(result["glossary_applied"]), 2)

    def test_missing_glossary_is_safe(self):
        with tempfile.TemporaryDirectory() as temp:
            result = normalize_for_speech("Hello", "en", os.path.join(temp, "missing.json"))
            self.assertEqual(result["normalized_text"], "Hello")

    def test_invalid_glossary_fails_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            path = os.path.join(temp, "bad.json")
            with open(path, "w", encoding="utf-8") as stream:
                stream.write('{"entries": []}')
            with self.assertRaises(ValueError):
                load_glossary(path)

if __name__ == "__main__":
    unittest.main()
