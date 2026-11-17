import csv
import os
import struct
import tempfile
import unittest
import wave

from core.narration_audit import audit_narration


def write_wav(path, seconds=4, sample_rate=1000):
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(struct.pack("<{}h".format(seconds * sample_rate),
                                    *([5000, -5000] * (seconds * sample_rate // 2))))


def write_tsv(path, headers, rows):
    with open(path, "w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=headers, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)


class NarrationAuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = self.temp.name
        self.audio = os.path.join(self.root, "VO.wav")
        self.lines = os.path.join(self.root, "LINES.tsv")
        self.vo = os.path.join(self.root, "VO.tsv")
        self.words = os.path.join(self.root, "WORDS.tsv")
        write_wav(self.audio)
        write_tsv(self.lines, ["id", "text"], [
            {"id": "01", "text": "नमस्ते दुनिया"},
            {"id": "02", "text": "Hello India"},
        ])
        write_tsv(self.vo, ["id", "start", "end", "text"], [
            {"id": "01", "start": "0", "end": "2", "text": "नमस्ते दुनिया"},
            {"id": "02", "start": "2", "end": "4", "text": "Hello India"},
        ])
        write_tsv(self.words, ["line", "word_idx", "start", "end", "word", "src"], [
            {"line": "01", "word_idx": 0, "start": "0", "end": "1", "word": "नमस्ते", "src": "cartesia"},
            {"line": "01", "word_idx": 1, "start": "1", "end": "2", "word": "दुनिया", "src": "cartesia"},
            {"line": "02", "word_idx": 0, "start": "2", "end": "3", "word": "Hello", "src": "cartesia"},
            {"line": "02", "word_idx": 1, "start": "3", "end": "4", "word": "India", "src": "cartesia"},
        ])

    def tearDown(self):
        self.temp.cleanup()

    def run_audit(self):
        return audit_narration(self.lines, self.audio, self.words, self.vo)

    def test_script_and_provider_timing_rows_pass(self):
        report = self.run_audit()
        self.assertEqual(report["status"], "pass")
        self.assertEqual(report["asr"]["status"], "not_run")
        self.assertTrue(any(x["name"] == "word_timing_provenance" and x["status"] == "pass"
                            for x in report["checks"]))

    def test_estimated_timestamps_are_explicitly_flagged(self):
        rows = []
        with open(self.words, encoding="utf-8") as stream:
            rows = list(csv.DictReader(stream, delimiter="\t"))
        rows[0]["src"] = "estimate"
        write_tsv(self.words, ["line", "word_idx", "start", "end", "word", "src"], rows)
        report = self.run_audit()
        self.assertEqual(report["status"], "warning")
        self.assertTrue(any("estimated" in warning for warning in report["warnings"]))

    def test_stale_vo_tsv_is_flagged(self):
        write_tsv(self.vo, ["id", "start", "end", "text"], [
            {"id": "01", "start": "0", "end": "4", "text": "wrong transcript"},
        ])
        report = self.run_audit()
        self.assertEqual(report["status"], "warning")
        self.assertTrue(any("differs" in warning for warning in report["warnings"]))

    def test_missing_timing_files_do_not_claim_verification(self):
        os.remove(self.vo)
        os.remove(self.words)
        report = self.run_audit()
        self.assertEqual(report["status"], "warning")
        self.assertEqual(report["asr"]["status"], "not_run")
        self.assertTrue(any("does not determine" in item for item in report["limitations"]))


if __name__ == "__main__":
    unittest.main()
