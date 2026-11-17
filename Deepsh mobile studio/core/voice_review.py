# -*- coding: utf-8 -*-
"""Offline comparison and approval/rollback for a completed targeted voice retake."""
import argparse
import json
import math
import os
import shutil
import struct

PENDING = "vo_parts/review_pending.json"

def _metrics(path, sample_rate=44100):
    if not os.path.isfile(path):
        return None
    count = 0
    peak = 0.0
    square_sum = 0.0
    with open(path, "rb") as stream:
        while True:
            chunk = stream.read(4 * 65536)
            if not chunk:
                break
            chunk = chunk[:len(chunk) - (len(chunk) % 4)]
            for (value,) in struct.iter_unpack("<f", chunk):
                value = max(-1.0, min(1.0, value))
                magnitude = abs(value)
                peak = max(peak, magnitude)
                square_sum += value * value
                count += 1
    rms = math.sqrt(square_sum / count) if count else 0.0
    return {"samples": count, "duration_seconds": round(count / float(sample_rate), 4),
            "peak": round(peak, 6), "rms": round(rms, 6),
            "peak_dbfs": round(20 * math.log10(peak), 2) if peak else None,
            "rms_dbfs": round(20 * math.log10(rms), 2) if rms else None}

def compare_review(pending_path=PENDING):
    if not os.path.isfile(pending_path):
        raise FileNotFoundError("No pending voice retake review found.")
    with open(pending_path, encoding="utf-8") as stream:
        pending = json.load(stream)
    if pending.get("schema") != "voice-retake-review-v1" or pending.get("status") != "pending":
        raise ValueError("No pending review is available for comparison.")
    backup_dir = pending["backup_dir"]
    results = []
    for line_id in pending.get("line_ids", []):
        old_path = os.path.join(backup_dir, line_id + ".f32")
        new_path = os.path.join("vo_parts", line_id + ".f32")
        old_meta_path = os.path.join(backup_dir, line_id + ".json")
        new_meta_path = os.path.join("vo_parts", line_id + ".json")
        with open(old_meta_path, encoding="utf-8") as stream:
            old_meta = json.load(stream)
        with open(new_meta_path, encoding="utf-8") as stream:
            new_meta = json.load(stream)
        if old_meta.get("text") != new_meta.get("text"):
            raise ValueError("Text changed for line {}; review cannot compare unlike scripts.".format(line_id))
        old_metrics, new_metrics = _metrics(old_path), _metrics(new_path)
        results.append({"line_id": line_id, "text": new_meta.get("text", ""),
                        "before": old_metrics, "after": new_metrics,
                        "duration_delta_seconds": round(new_metrics["duration_seconds"] - old_metrics["duration_seconds"], 4),
                        "rms_delta_db": round(new_metrics["rms_dbfs"] - old_metrics["rms_dbfs"], 2)
                        if old_metrics["rms_dbfs"] is not None and new_metrics["rms_dbfs"] is not None else None})
    report = {"schema": "voice-retake-comparison-v1", "status": "pending_human_approval",
              "line_count": len(results), "lines": results,
              "limitations": ["Signal metrics compare duration and level only; they do not assess pronunciation, acting, emotion, intelligibility or naturalness.",
                              "Listen to before/after audio before approving a retake.",
                              "A numeric improvement is not proof of better narration."]}
    out = "voice-retake-comparison.json"
    with open(out, "w", encoding="utf-8") as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write("\\n")
    print("Comparison report: " + os.path.abspath(out))
    for item in results:
        print("Line {} | duration {:+.3f}s | RMS delta {} dB".format(
            item["line_id"], item["duration_delta_seconds"], item["rms_delta_db"]))
    print("Human listening and explicit approve/reject are still required.")
    return report

def decide(action, pending_path=PENDING):
    if not os.path.isfile(pending_path):
        raise FileNotFoundError("No pending voice retake review found.")
    with open(pending_path, encoding="utf-8") as stream:
        pending = json.load(stream)
    if pending.get("schema") != "voice-retake-review-v1" or pending.get("status") != "pending":
        raise ValueError("No pending review is available.")
    if action == "approve":
        comparison_path = "voice-retake-comparison.json"
        if not os.path.isfile(comparison_path):
            raise FileNotFoundError("Run studio.py voice-review compare before approval.")
        with open(comparison_path, encoding="utf-8") as stream:
            comparison = json.load(stream)
        if comparison.get("schema") != "voice-retake-comparison-v1" or comparison.get("status") != "pending_human_approval":
            raise ValueError("A valid comparison report is required before approval.")
        if {str(item.get("line_id")) for item in comparison.get("lines", [])} != set(pending.get("line_ids", [])):
            raise ValueError("Comparison report does not match the pending retake line IDs.")
    if action == "reject":
        for item in pending.get("backup_files", []):
            if not os.path.isfile(item["backup"]):
                raise FileNotFoundError("Review baseline is incomplete: " + item["backup"])
        for item in pending.get("backup_files", []):
            os.makedirs(os.path.dirname(os.path.abspath(item["source"])), exist_ok=True)
            shutil.copy2(item["backup"], item["source"])
    pending["status"] = "approved" if action == "approve" else "rejected_restored"
    with open(pending_path, "w", encoding="utf-8") as stream:
        json.dump(pending, stream, ensure_ascii=False, indent=2)
        stream.write("\\n")
    print("Retake review decision: " + pending["status"])
    if action == "reject":
        print("Original approved audio and line caches restored.")
    else:
        print("Retake accepted; current audio and cache remain active.")

def main():
    parser = argparse.ArgumentParser(description="Compare and approve/reject voice retakes offline.")
    parser.add_argument("action", choices=("compare", "approve", "reject"))
    args = parser.parse_args()
    if args.action == "compare":
        compare_review()
    else:
        decide(args.action)

if __name__ == "__main__":
    main()
