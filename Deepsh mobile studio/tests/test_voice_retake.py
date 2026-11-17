import json
import os
import tempfile
import unittest

from core.voice_retake import build_retake_plan


class VoiceRetakePlanTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.lines = os.path.join(self.temp.name, "LINES.tsv")
        self.report = os.path.join(self.temp.name, "performance.json")
        self.cache = os.path.join(self.temp.name, "vo_parts")
        os.makedirs(self.cache)
        with open(self.lines, "w", encoding="utf-8") as stream:
            stream.write("id\\ttext\\tgap\\n1\\tपहिली ओळ\\t0.3\\n2\\tSecond line\\t0.3\\n")
        with open(self.report, "w", encoding="utf-8") as stream:
            json.dump({"schema": "narration-performance-v1",
                       "review_recommendations": [{"line_id": "2", "recommendations": ["Silent segment"]}]}, stream)

    def tearDown(self):
        self.temp.cleanup()

    def test_selects_only_flagged_lines_and_estimates_requests(self):
        plan = build_retake_plan(self.report, [], self.lines, self.cache)
        self.assertEqual([row["line_id"] for row in plan["selected_lines"]], ["2"])
        self.assertEqual(plan["estimated_cartesia_requests"], 1)
        self.assertEqual(plan["status"], "ready")

    def test_manual_ids_are_supported_and_unknown_ids_rejected(self):
        plan = build_retake_plan(None, ["1"], self.lines, self.cache)
        self.assertEqual(plan["selected_lines"][0]["line_id"], "1")
        with self.assertRaises(ValueError):
            build_retake_plan(None, ["404"], self.lines, self.cache)


if __name__ == "__main__":
    unittest.main()
