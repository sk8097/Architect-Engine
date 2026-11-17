import os
import struct
import sys
import tempfile
import unittest
import wave

STUDIO = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if STUDIO not in sys.path:
    sys.path.insert(0, STUDIO)

from core.audio_quality import analyze_wav


def write_pcm(path, samples, sample_rate=1000):
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(struct.pack("<{}h".format(len(samples)), *samples))


class AudioQualityTests(unittest.TestCase):
    def test_reports_clean_pcm_format_and_duration(self):
        with tempfile.TemporaryDirectory() as temp:
            path = os.path.join(temp, "clean.wav")
            write_pcm(path, [10000, -10000] * 500)
            report = analyze_wav(path)
            self.assertEqual(report["status"], "pass")
            self.assertEqual(report["format"]["sample_rate_hz"], 1000)
            self.assertEqual(report["format"]["bit_depth"], 16)
            self.assertEqual(report["format"]["channels"], 1)
            self.assertEqual(report["format"]["duration_seconds"], 1.0)
            self.assertLess(report["signal"]["rms_dbfs"], 0)

    def test_detects_silence_clipping_and_dc_offset(self):
        with tempfile.TemporaryDirectory() as temp:
            path = os.path.join(temp, "bad.wav")
            write_pcm(path, [0] * 600 + [32767] * 200 + [5000] * 200)
            report = analyze_wav(path)
            self.assertEqual(report["status"], "warning")
            self.assertGreater(report["signal"]["clipped_frame_ratio"], 0)
            self.assertGreater(report["signal"]["silence_frame_ratio"], 0.5)
            self.assertGreater(report["signal"]["leading_silence_seconds"], 0.5)
            self.assertIn("DC offset exceeds 0.02 full scale.", report["warnings"])

    def test_rejects_empty_wav(self):
        with tempfile.TemporaryDirectory() as temp:
            path = os.path.join(temp, "empty.wav")
            with wave.open(path, "wb") as wav:
                wav.setnchannels(1)
                wav.setsampwidth(2)
                wav.setframerate(1000)
            with self.assertRaises(ValueError):
                analyze_wav(path)

    def test_report_disclaims_lufs_and_human_likeness(self):
        with tempfile.TemporaryDirectory() as temp:
            path = os.path.join(temp, "audio.wav")
            write_pcm(path, [8000, -8000] * 100)
            report = analyze_wav(path)
            self.assertTrue(any("not LUFS" in item for item in report["limitations"]))
            self.assertTrue(any("human or natural" in item for item in report["limitations"]))


if __name__ == "__main__":
    unittest.main()
