# -*- coding: utf-8 -*-
"""Credit-aware, offline-first retake planning and explicitly gated execution."""
import argparse
import json
import os
import shutil
import subprocess
import time
import sys


def build_retake_plan(performance_report="VO.wav.performance.json",
                      line_ids=None, lines_path="LINES.tsv",
                      cache_dir="vo_parts", audio_path="VO.wav"):
    if not os.path.isfile(lines_path):
        raise FileNotFoundError(lines_path)
    import csv
    with open(lines_path, encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    if not rows:
        raise ValueError("LINES.tsv has no lines.")
    known = {str(row.get("id", "")): row for row in rows}
    selected = set(str(value) for value in (line_ids or []))
    reasons = {}
    if performance_report and os.path.isfile(performance_report):
        with open(performance_report, encoding="utf-8") as stream:
            report = json.load(stream)
        if report.get("schema") != "narration-performance-v1":
            raise ValueError("Unsupported performance report schema.")
        for item in report.get("review_recommendations", []):
            line_id = str(item.get("line_id", ""))
            if line_id in known:
                selected.add(line_id)
                reasons.setdefault(line_id, []).extend(item.get("recommendations", []))
    unknown = selected - set(known)
    if unknown:
        raise ValueError("Unknown line ID(s): " + ", ".join(sorted(unknown)))
    ordered = [str(row["id"]) for row in rows if str(row["id"]) in selected]
    cache_checks = []
    for line_id in ordered:
        audio_cache = os.path.join(cache_dir, line_id + ".f32")
        meta_cache = os.path.join(cache_dir, line_id + ".json")
        valid = os.path.isfile(audio_cache) and os.path.isfile(meta_cache)
        cache_checks.append({"line_id": line_id, "audio_cache_exists": os.path.isfile(audio_cache),
                             "metadata_cache_exists": os.path.isfile(meta_cache),
                             "cache_present": valid})
    return {
        "schema": "voice-retake-plan-v1",
        "status": "ready" if ordered else "no_candidates",
        "audio_exists": os.path.isfile(audio_path),
        "selected_line_count": len(ordered),
        "estimated_cartesia_requests": len(ordered),
        "selected_lines": [{"line_id": line_id, "text": known[line_id].get("text", ""),
                            "reasons": reasons.get(line_id, ["Manually selected for retake"])}
                           for line_id in ordered],
        "cache_checks": cache_checks,
        "execution": {"requires_explicit_execute_flag": True,
                      "preserves_source_lines_tsv": True,
                      "rebuilds_vo_wav_and_timing_files_from_line_cache": True,
                      "unselected_missing_or_stale_cache": "abort"},
        "limitations": [
            "Performance flags are heuristic; listen before deciding to retake.",
            "A retake consumes one provider synthesis request per selected line.",
            "This planner does not claim that regenerated audio is human-like or correct."
        ]
    }


def main():
    parser = argparse.ArgumentParser(description="Plan and explicitly execute targeted narration retakes.")
    parser.add_argument("--report", default="VO.wav.performance.json")
    parser.add_argument("--lines", default="LINES.tsv")
    parser.add_argument("--cache-dir", default="vo_parts")
    parser.add_argument("--audio", default="VO.wav")
    parser.add_argument("--ids", default="", help="Comma-separated line IDs to add to the report's flagged IDs")
    parser.add_argument("--voice-args", default="", help="Extra voice settings, e.g. --voice anuj --lang hi")
    parser.add_argument("--execute", action="store_true", help="Actually call Cartesia for selected lines")
    parser.add_argument("--out", default="retake-plan.json")
    args = parser.parse_args()
    manual_ids = [item.strip() for item in args.ids.split(",") if item.strip()]
    plan = build_retake_plan(args.report, manual_ids, args.lines, args.cache_dir, args.audio)
    with open(args.out, "w", encoding="utf-8") as stream:
        json.dump(plan, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print("Retake plan: {} | {} selected line(s) | estimated Cartesia requests: {}".format(
        plan["status"].upper(), plan["selected_line_count"], plan["estimated_cartesia_requests"]))
    print("Plan: " + os.path.abspath(args.out))
    for item in plan["selected_lines"]:
        print("  Line {}: {} | {}".format(item["line_id"], item["text"],
              "; ".join(item["reasons"])))
    if not args.execute:
        print("DRY RUN ONLY. No API call made. Add --execute after reviewing the plan.")
        return
    if not plan["selected_lines"]:
        raise SystemExit("No selected lines; refusing synthesis.")
    if not os.environ.get("CARTESIA_API_KEY"):
        raise SystemExit("CARTESIA_API_KEY is not set; no synthesis request was sent.")
    ids = ",".join(item["line_id"] for item in plan["selected_lines"])
    pending_path = "vo_parts/review_pending.json"
    if os.path.isfile(pending_path):
        with open(pending_path, encoding="utf-8") as stream:
            previous_review = json.load(stream)
        if previous_review.get("status") == "pending":
            raise SystemExit("A previous retake is awaiting review; run studio.py voice-review compare/approve/reject first.")
    backup_dir = os.path.join("vo_parts", "review_baseline_" + str(time.time_ns()))
    os.makedirs(backup_dir, exist_ok=False)
    backup_files = []
    for line_id in ids.split(","):
        for suffix in (".f32", ".json"):
            source = os.path.join(args.cache_dir, line_id + suffix)
            if not os.path.isfile(source):
                raise SystemExit("Cannot create review baseline; missing approved cache: " + source)
            target = os.path.join(backup_dir, line_id + suffix)
            shutil.copy2(source, target)
            backup_files.append({"source": source, "backup": target})
    for filename in ("VO.wav", "VO.tsv", "WORDS.tsv"):
        if os.path.isfile(filename):
            target = os.path.join(backup_dir, filename)
            shutil.copy2(filename, target)
            backup_files.append({"source": filename, "backup": target})
    with open(pending_path, "w", encoding="utf-8") as stream:
        json.dump({"schema": "voice-retake-review-v1", "status": "pending",
                   "line_ids": ids.split(","), "backup_dir": backup_dir,
                   "backup_files": backup_files, "plan_path": os.path.abspath(args.out)},
                  stream, ensure_ascii=False, indent=2)
        stream.write("\\n")
    voice_script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "voice.py")
    command = [sys.executable, voice_script, "--only-lines", ids]
    if args.voice_args:
        import shlex
        command.extend(shlex.split(args.voice_args))
    try:
        subprocess.run(command, check=True)
    except Exception:
        for item in backup_files:
            shutil.copy2(item["backup"], item["source"])
        if os.path.isfile(pending_path):
            os.remove(pending_path)
        raise


if __name__ == "__main__":
    main()
