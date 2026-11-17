# -*- coding: utf-8 -*-
"""Line-level narration performance diagnostics; offline, no provider calls."""
import argparse
import csv
import json
import math
import os
import statistics
import wave

try:
    from .audio_quality import _decode_pcm
except ImportError:
    from audio_quality import _decode_pcm


def _read_rows(path):
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    with open(path, encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def _db(value):
    return round(20.0 * math.log10(value), 2) if value > 0 else None


def analyze_performance(audio_path="VO.wav", vo_lines_path="VO.tsv",
                        quiet_threshold=0.001, level_deviation_db=6.0,
                        short_pause_seconds=0.08, long_pause_seconds=1.5):
    rows = _read_rows(vo_lines_path)
    if not rows:
        raise ValueError("VO.tsv has no line rows.")
    results, warnings, gaps = [], [], []
    with wave.open(audio_path, "rb") as wav:
        if wav.getcomptype() != "NONE":
            raise ValueError("Only PCM WAV is supported.")
        channels, width, rate, total_frames = (
            wav.getnchannels(), wav.getsampwidth(), wav.getframerate(), wav.getnframes())
        if rate <= 0 or total_frames <= 0:
            raise ValueError("Audio has invalid or empty dimensions.")
        previous_end = None
        for row in rows:
            try:
                start, end = float(row["start"]), float(row["end"])
            except (KeyError, TypeError, ValueError) as exc:
                raise ValueError("VO.tsv rows require numeric start/end fields.") from exc
            if start < 0 or end <= start or end > total_frames / rate + 0.25:
                raise ValueError("Invalid VO.tsv timestamp for line {}".format(row.get("id", "?")))
            if previous_end is not None:
                gap = start - previous_end
                gap_item = {"after_line_id": results[-1]["line_id"],
                            "before_line_id": row.get("id", "?"),
                            "gap_seconds": round(gap, 3)}
                if gap < 0:
                    gap_item["status"] = "overlap"
                    gap_item["recommendation"] = "Check overlapping line timestamps and edit boundaries."
                elif gap < short_pause_seconds:
                    gap_item["status"] = "tight"
                    gap_item["recommendation"] = "Listen for a rushed transition; add a pause only if the sentence boundary needs it."
                elif gap > long_pause_seconds:
                    gap_item["status"] = "long"
                    gap_item["recommendation"] = "Check whether this gap is intentional or unintended dead air."
                else:
                    gap_item["status"] = "normal"
                gaps.append(gap_item)
            previous_end = end

            first = max(0, int(start * rate))
            last = min(total_frames, int(end * rate))
            wav.setpos(first)
            raw = wav.readframes(max(0, last - first))
            samples = _decode_pcm(raw, width)
            if not samples or len(samples) % channels:
                raise ValueError("Could not decode audio for line {}".format(row.get("id", "?")))
            frames = len(samples) // channels
            peak = 0.0
            square_sum = 0.0
            quiet = 0
            for index in range(0, len(samples), channels):
                frame = samples[index:index + channels]
                frame_peak = max(abs(sample) for sample in frame)
                peak = max(peak, frame_peak)
                square_sum += sum(sample * sample for sample in frame) / channels
                if frame_peak <= quiet_threshold:
                    quiet += 1
            rms = math.sqrt(square_sum / frames) if frames else 0.0
            duration = frames / float(rate)
            token_count = len((row.get("text") or "").split())
            wpm = token_count * 60.0 / duration if duration > 0 else 0.0
            results.append({
                "line_id": row.get("id", str(len(results) + 1)),
                "text": row.get("text", ""),
                "start_seconds": round(start, 3), "end_seconds": round(end, 3),
                "duration_seconds": round(duration, 3),
                "approx_words_per_minute": round(wpm, 1),
                "peak_dbfs": _db(peak), "rms_dbfs": _db(rms),
                "quiet_frame_ratio": round(quiet / float(frames), 4),
                "recommendations": []
            })

    valid_levels = [item["rms_dbfs"] for item in results if item["rms_dbfs"] is not None]
    median_level = statistics.median(valid_levels) if valid_levels else None
    for item in results:
        recs = item["recommendations"]
        level = item["rms_dbfs"]
        if level is None:
            recs.append("No measurable signal in this line; inspect the audio segment.")
        elif median_level is not None and abs(level - median_level) > level_deviation_db:
            recs.append("Line RMS differs from the median by more than {:.1f} dB; compare perceived loudness and check gain.".format(level_deviation_db))
        if item["quiet_frame_ratio"] > 0.20:
            recs.append("More than 20% of this line window is near-silent; check clipping, pauses, or inaccurate line timestamps.")
        if item["approx_words_per_minute"] < 55 or item["approx_words_per_minute"] > 230:
            recs.append("Estimated line pace is outside 55–230 words/min; listen before changing delivery speed.")
        if recs:
            warnings.append({"line_id": item["line_id"], "recommendations": list(recs)})
    for gap in gaps:
        if gap["status"] != "normal":
            warnings.append({"line_id": gap["before_line_id"], "recommendations": [gap["recommendation"]]})

    return {
        "schema": "narration-performance-v1",
        "status": "review" if warnings else "no_heuristic_flags",
        "audio": os.path.abspath(audio_path),
        "line_count": len(results),
        "reference_median_rms_dbfs": round(median_level, 2) if median_level is not None else None,
        "lines": results, "inter_line_gaps": gaps,
        "review_recommendations": warnings,
        "limitations": [
            "This is a signal-and-timing heuristic, not an emotion, acting, pronunciation or naturalness detector.",
            "Word counts use whitespace splitting and can misestimate Hindi, Marathi and code-switched speech rates.",
            "RMS differences may be intentional emphasis; do not normalize automatically without listening.",
            "Line windows depend on VO.tsv timestamps; incorrect timestamps can create false silence and level flags."
        ]
    }


def main():
    parser = argparse.ArgumentParser(description="Offline line-level narration performance audit")
    parser.add_argument("--audio", default="VO.wav")
    parser.add_argument("--vo-lines", default="VO.tsv")
    parser.add_argument("--out", default=None)
    parser.add_argument("--level-deviation-db", type=float, default=6.0)
    parser.add_argument("--short-pause", type=float, default=0.08)
    parser.add_argument("--long-pause", type=float, default=1.5)
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    report = analyze_performance(args.audio, args.vo_lines,
                                  level_deviation_db=args.level_deviation_db,
                                  short_pause_seconds=args.short_pause,
                                  long_pause_seconds=args.long_pause)
    out = args.out or args.audio + ".performance.json"
    with open(out, "w", encoding="utf-8") as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print("Performance audit: {} | {} lines | {} review flags".format(
        report["status"].upper(), report["line_count"], len(report["review_recommendations"])))
    print("Report: " + os.path.abspath(out))
    for item in report["review_recommendations"]:
        print("  Line {}: {}".format(item["line_id"], "; ".join(item["recommendations"])))
    if args.strict and report["review_recommendations"]:
        raise SystemExit("Narration performance audit flagged segments (strict mode).")


if __name__ == "__main__":
    main()
