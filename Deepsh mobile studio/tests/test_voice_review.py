import json
import os
import struct
import tempfile
import unittest

from core.voice_review import compare_review, decide

class VoiceReviewTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.old = os.getcwd()
        os.chdir(self.temp.name)
        os.makedirs("vo_parts/review_baseline", exist_ok=True)
        with open("vo_parts/1.f32", "wb") as stream:
            stream.write(struct.pack("<4f", 0.1, -0.1, 0.2, -0.2))
        with open("vo_parts/1.json", "w", encoding="utf-8") as stream:
            json.dump({"text": "hello"}, stream)
        with open("vo_parts/review_baseline/1.f32", "wb") as stream:
            stream.write(struct.pack("<4f", 0.05, -0.05, 0.1, -0.1))
        with open("vo_parts/review_baseline/1.json", "w", encoding="utf-8") as stream:
            json.dump({"text": "hello"}, stream)
        for name in ("VO.wav", "VO.tsv", "WORDS.tsv"):
            with open("vo_parts/review_baseline/" + name, "w", encoding="utf-8") as stream:
                stream.write("original")
        with open("vo_parts/review_pending.json", "w", encoding="utf-8") as stream:
            json.dump({"schema": "voice-retake-review-v1", "status": "pending",
                       "line_ids": ["1"], "backup_dir": "vo_parts/review_baseline",
                       "backup_files": [{"source": "VO.tsv", "backup": "vo_parts/review_baseline/VO.tsv"}]}, stream)

    def tearDown(self):
        os.chdir(self.old)
        self.temp.cleanup()

    def test_compare_reports_signal_deltas_without_deciding(self):
        report = compare_review()
        self.assertEqual(report["status"], "pending_human_approval")
        self.assertGreater(report["lines"][0]["after"]["rms"], report["lines"][0]["before"]["rms"])

    def test_reject_restores_baseline_file(self):
        with open("VO.tsv", "w", encoding="utf-8") as stream:
            stream.write("candidate")
        decide("reject")
        with open("VO.tsv", encoding="utf-8") as stream:
            self.assertEqual(stream.read(), "original")

    def test_approve_marks_review_without_overwriting_audio(self):
        compare_review()
        decide("approve")
        with open("vo_parts/review_pending.json", encoding="utf-8") as stream:
            self.assertEqual(json.load(stream)["status"], "approved")

if __name__ == "__main__":
    unittest.main()
