import io
import os
import sys
import tempfile
import unittest
from unittest import mock

STUDIO = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if STUDIO not in sys.path:
    sys.path.insert(0, STUDIO)

from core import cartesia_tts
from core.voice_direction_engine import build_direction_plan, load_profiles


class VoiceDirectionTests(unittest.TestCase):
    def test_catalog_has_twenty_modes_and_thirty_personalities(self):
        catalog = load_profiles()
        self.assertEqual(len(catalog["delivery_modes"]), 20)
        self.assertEqual(len(catalog["personalities"]), 30)

    def test_plan_is_local_and_splits_sentences(self):
        plan = build_direction_plan(
            "यह एक सवाल है? लेकिन असली तथ्य यहाँ है।",
            delivery_mode="investigative",
            personality="skeptical_investigator",
            language="hi",
        )
        self.assertEqual(len(plan["segments"]), 2)
        self.assertEqual(plan["credit_estimate"]["analysis_api_calls"], 0)
        self.assertEqual(plan["credit_estimate"]["tts_requests_if_synthesized"], 1)
        self.assertEqual(plan["segments"][0]["intent"], "question")
        self.assertEqual(plan["segments"][1]["intent"], "revelation")

    def test_unknown_voice_does_not_silently_switch_to_rohan(self):
        with mock.patch.object(cartesia_tts, "DEFAULT_API_KEY", ""):
            with self.assertRaises(ValueError):
                cartesia_tts.resolve_voice_id("definitely-not-a-real-preset")

    def test_unknown_emotion_is_rejected(self):
        with self.assertRaises(ValueError):
            cartesia_tts.resolve_emotions("made_up_emotion")

    def test_cache_hit_skips_second_provider_request(self):
        wav = b"RIFF" + (36).to_bytes(4, "little") + b"WAVE" + (b"\x00" * 36)
        with tempfile.TemporaryDirectory() as temp:
            with mock.patch.dict(os.environ, {"CARTESIA_CACHE_DIR": temp}):
                response = mock.MagicMock()
                response.__enter__.return_value.read.return_value = wav
                with mock.patch.object(cartesia_tts.urllib.request, "urlopen",
                                       return_value=response) as urlopen:
                    first_path = os.path.join(temp, "first.wav")
                    second_path = os.path.join(temp, "second.wav")
                    first = cartesia_tts.generate_voiceover(
                        "Cache test sentence.", output_path=first_path,
                        api_key="test-key", use_cache=True)
                    second = cartesia_tts.generate_voiceover(
                        "Cache test sentence.", output_path=second_path,
                        api_key="test-key", use_cache=True)
                    self.assertFalse(first["cache_hit"])
                    self.assertTrue(second["cache_hit"])
                    self.assertEqual(first["cache_key"], second["cache_key"])
                    self.assertEqual(second["api_requests"], 0)
                    self.assertEqual(urlopen.call_count, 1)
                    self.assertTrue(os.path.isfile(second_path))


if __name__ == "__main__":
    unittest.main()
