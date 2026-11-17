# -*- coding: utf-8 -*-
"""Credit-free narration consistency audit.

Checks source/script agreement, timing provenance and coverage. Optional faster-whisper
ASR can flag possible transcript mismatches; it is not a pronunciation or naturalness
certification and is deliberately opt-in because it is compute-heavy on mobile.
"""
import argparse
import csv
import json
import os
import re
import wave
import unicodedata


def _read_tsv(path):
    if not os.path.isfile(path):
        return []
    with open(path, encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def _tokens(text):
    return re.findall(r"[^\W_]+", (text or "").casefold(), flags=re.UNICODE)


def _edit_distance(a, b):
    prev = list(range(len(b) + 1))
    for i, left in enumerate(a, 1):
        cur = [i]
        for j, right in enumerate(b, 1):
            cur.append(min(cur[-1] + 1, prev[j] + 1,
                           prev[j - 1] + (left != right)))
        prev = cur
    return prev[-1]


def _asr_transcribe(audio_path, model_name):
    try:
        from faster_whisper import WhisperModel
    except ImportError as exc:
        raise RuntimeError("Optional ASR requires faster-whisper; install it separately, then retry.") from exc
    model = WhisperModel(model_name, device="cpu", compute_type="int8",
                         cpu_threads=max(1, min(4, os.cpu_count() or 2)))
    segments, info = model.transcribe(audio_path, beam_size=1, word_timestamps=False)
    text = " ".join(segment.text.strip() for segment in segments if segment.text.strip())
    return text, getattr(info, "language", None)


def audit_narration(lines_path="LINES.tsv", audio_path="VO.wav",
                    words_path="WORDS.tsv", vo_lines_path="VO.tsv",
                    use_asr=False, asr_model="tiny"):
    expected_rows = _read_tsv(lines_path)
    if not expected_rows:
        raise ValueError("LINES.tsv is missing or has no rows.")
    expected = " ".join(row.get("text", "") for row in expected_rows)
    expected_tokens = _tokens(expected)
    if not expected_tokens:
        raise ValueError("LINES.tsv contains no readable words.")

    if not os.path.isfile(audio_path):
        raise FileNotFoundError("Audio file not found: " + audio_path)
    with wave.open(audio_path, "rb") as wav:
        frame_count = wav.getnframes()
        sample_rate = wav.getframerate()
        channels = wav.getnchannels()
        duration = frame_count / float(sample_rate) if sample_rate else 0.0
    if duration <= 0:
        raise ValueError("Audio file has zero duration.")

    timing_rows = _read_tsv(vo_lines_path)
    word_rows = _read_tsv(words_path)
    warnings, checks = [], []
    checks.append({"name": "audio_readable", "status": "pass",
                   "duration_seconds": round(duration, 3),
                   "sample_rate_hz": sample_rate, "channels": channels})

    if timing_rows:
        timed_text = " ".join(row.get("text", "") for row in timing_rows)
        if _tokens(timed_text) != _tokens(expected):
            warnings.append("VO.tsv text differs from LINES.tsv; check stale or mismatched timing files.")
            text_status = "warning"
        else:
            text_status = "pass"
        checks.append({"name": "script_to_vo_tsv_text", "status": text_status})
        invalid = []
        for row in timing_rows:
            try:
                start, end = float(row["start"]), float(row["end"])
                if start < 0 or end <= start or end > duration + 0.25:
                    invalid.append(row.get("id", "?"))
            except (KeyError, TypeError, ValueError):
                invalid.append(row.get("id", "?"))
        checks.append({"name": "line_timestamps", "status": "warning" if invalid else "pass",
                       "invalid_line_ids": invalid})
        if invalid:
            warnings.append("VO.tsv contains invalid or out-of-range line timestamps.")
        duration_rates = []
        for row in timing_rows:
            try:
                secs = float(row["end"]) - float(row["start"])
                count = len(_tokens(row.get("text", "")))
                if secs > 0 and count:
                    duration_rates.append(round(count * 60.0 / secs, 1))
            except (KeyError, TypeError, ValueError):
                pass
        unusual = [rate for rate in duration_rates if rate < 55 or rate > 230]
        checks.append({"name": "line_pacing_heuristic", "status": "warning" if unusual else "pass",
                       "lines_checked": len(duration_rates), "words_per_minute": duration_rates,
                       "outlier_threshold": "below 55 or above 230; heuristic only"})
        if unusual:
            warnings.append("One or more line speaking-rate estimates are unusual; listen before editing.")
    else:
        warnings.append("VO.tsv missing; line-level pacing and script/timing consistency were not checked.")
        checks.append({"name": "script_to_vo_tsv_text", "status": "not_checked"})

    if word_rows:
        sources = {}
        bad_times = []
        for row in word_rows:
            source = (row.get("src") or "unspecified").lower()
            sources[source] = sources.get(source, 0) + 1
            try:
                start, end = float(row["start"]), float(row["end"])
                if start < 0 or end <= start or end > duration + 0.25:
                    bad_times.append(row.get("word", "?"))
            except (KeyError, TypeError, ValueError):
                bad_times.append(row.get("word", "?"))
        estimated = sources.get("estimate", 0)
        checks.append({"name": "word_timing_provenance", "status": "warning" if estimated or bad_times else "pass",
                       "word_count": len(word_rows), "source_counts": sources,
                       "invalid_timing_count": len(bad_times)})
        if estimated:
            warnings.append("{} word timestamps are estimated, not provider-measured.".format(estimated))
        if bad_times:
            warnings.append("WORDS.tsv contains invalid or out-of-range word timestamps.")
        coverage = len(word_rows) / float(len(expected_tokens))
        checks.append({"name": "word_row_coverage", "status": "pass" if 0.9 <= coverage <= 1.1 else "warning",
                       "expected_script_tokens": len(expected_tokens),
                       "timed_word_rows": len(word_rows), "ratio": round(coverage, 3)})
        if not 0.9 <= coverage <= 1.1:
            warnings.append("Timed word count differs materially from the script token count.")
    else:
        warnings.append("WORDS.tsv missing; word timing provenance was not checked.")
        checks.append({"name": "word_timing_provenance", "status": "not_checked"})

    asr_result = {"enabled": False, "status": "not_run"}
    if use_asr:
        recognized, language = _asr_transcribe(audio_path, asr_model)
        recognized_tokens = _tokens(recognized)
        distance = _edit_distance(expected_tokens, recognized_tokens)
        wer = distance / float(max(1, len(expected_tokens)))
        asr_result = {"enabled": True, "status": "completed", "model": asr_model,
                      "detected_language": language, "recognized_text": recognized,
                      "reference_token_count": len(expected_tokens),
                      "recognized_token_count": len(recognized_tokens),
                      "edit_distance": distance, "wer": round(wer, 4),
                      "metric_note": "WER is a screening signal; multilingual tokenization and code-switching can distort it."}
        checks.append({"name": "optional_asr_transcript_match",
                       "status": "warning" if wer > 0.25 else "pass", "wer": round(wer, 4)})
        if wer > 0.25:
            warnings.append("ASR transcript differs substantially from the script; review flagged words by listening.")
    else:
        asr_result["note"] = "Disabled by default; no ASR model download, network request or API credit used."

    limitations = [
        "This audit does not determine whether pronunciation is correct; optional ASR only flags transcript differences.",
        "ASR word error rate can be misleading for Hindi, Marathi, Hinglish, names, numerals and code-switching.",
        "Waveform timing and speaking-rate heuristics cannot certify emotion, prosody, intelligibility or human-likeness.",
        "Final approval still requires listening to the rendered voiceover."
    ]
    status = "warning" if warnings else "pass"
    return {"schema": "narration-audit-v1", "status": status,
            "inputs": {"lines": lines_path, "audio": audio_path,
                       "words": words_path, "vo_lines": vo_lines_path},
            "checks": checks, "warnings": warnings, "asr": asr_result,
            "limitations": limitations}


def main():
    parser = argparse.ArgumentParser(description="Credit-free narration consistency audit")
    parser.add_argument("--lines", default="LINES.tsv")
    parser.add_argument("--audio", default="VO.wav")
    parser.add_argument("--words", default="WORDS.tsv")
    parser.add_argument("--vo-lines", default="VO.tsv")
    parser.add_argument("--asr", action="store_true", help="Opt in to local faster-whisper CPU ASR")
    parser.add_argument("--asr-model", default="tiny")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--out", default=None)
    args = parser.parse_args()
    report = audit_narration(args.lines, args.audio, args.words, args.vo_lines,
                             use_asr=args.asr, asr_model=args.asr_model)
    out = args.out or args.audio + ".narration-audit.json"
    with open(out, "w", encoding="utf-8") as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print("Narration audit: {} | {} checks | {} warning(s)".format(
        report["status"].upper(), len(report["checks"]), len(report["warnings"])))
    print("Report: " + os.path.abspath(out))
    for warning in report["warnings"]:
        print("  WARNING: " + warning)
    if args.strict and report["status"] != "pass":
        raise SystemExit("Narration audit failed (strict mode).")


if __name__ == "__main__":
    main()
