import os
import struct
import tempfile
import unittest
import wave

from core.narration_performance import analyze_performance


class NarrationPerformanceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.audio = os.path.join(self.temp.name, "VO.wav")
        self.tsv = os.path.join(self.temp.name, "VO.tsv")
        rate = 1000
        # First line has normal signal, second line is deliberately near-silent.
        samples = ([6000, -6000] * 1000) + ([0, 0] * 1000)
        with wave.open(self.audio, "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(rate)
            wav.writeframes(struct.pack("<{}h".format(len(samples)), *samples))
        with open(self.tsv, "w", encoding="utf-8") as stream:
            stream.write("id\tstart\tend\ttext\n")
            stream.write("1\t0\t1\tThis is a test line\n")
            stream.write("2\t3\t4\tThis is another test line\n")

    def tearDown(self):
        self.temp.cleanup()

    def test_flags_silent_line_and_reports_line_metrics(self):
        report = analyze_performance(self.audio, self.tsv)
        self.assertEqual(report["line_count"], 2)
        self.assertEqual(report["status"], "review")
        self.assertIsNotNone(report["lines"][0]["rms_dbfs"])
        self.assertIsNone(report["lines"][1]["rms_dbfs"])
        self.assertTrue(any("No measurable signal" in rec
                            for item in report["review_recommendations"]
                            for rec in item["recommendations"]))

    def test_inter_line_gap_is_reported_not_automatically_repaired(self):
        report = analyze_performance(self.audio, self.tsv)
        self.assertEqual(report["inter_line_gaps"][0]["status"], "long")
        self.assertIn("listen", report["inter_line_gaps"][0]["recommendation"])


if __name__ == "__main__":
    unittest.main()
