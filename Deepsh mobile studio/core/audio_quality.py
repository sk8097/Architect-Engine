#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Local WAV integrity and signal-quality inspection; no network/API calls."""
import argparse
import json
import math
import os
import statistics
import wave


def _decode_pcm(raw, sample_width):
    if sample_width == 1:
        return [(value - 128) / 128.0 for value in raw]
    if sample_width == 2:
        count = len(raw) // 2
        values = __import__("struct").unpack("<{}h".format(count), raw) if count else ()
        return [value / 32768.0 for value in values]
    if sample_width == 3:
        values = []
        for offset in range(0, len(raw) - 2, 3):
            value = raw[offset] | (raw[offset + 1] << 8) | (raw[offset + 2] << 16)
            if value & 0x800000:
                value -= 0x1000000
            values.append(value / 8388608.0)
        return values
    if sample_width == 4:
        count = len(raw) // 4
        values = __import__("struct").unpack("<{}i".format(count), raw) if count else ()
        return [value / 2147483648.0 for value in values]
    raise ValueError("Unsupported PCM sample width: {} bytes".format(sample_width))


def analyze_wav(path, silence_threshold=0.001, clipping_threshold=0.999):
    """Return measured PCM metrics. Loudness is RMS-derived, not LUFS/EBU R128."""
    absolute_path = os.path.abspath(path)
    if not os.path.isfile(absolute_path):
        raise FileNotFoundError(absolute_path)
    with wave.open(absolute_path, "rb") as wav:
        channels = wav.getnchannels()
        sample_width = wav.getsampwidth()
        sample_rate = wav.getframerate()
        frames = wav.getnframes()
        compression = wav.getcomptype()
        if compression != "NONE":
            raise ValueError("Only uncompressed PCM WAV is supported.")
        if channels < 1 or sample_rate < 1 or frames < 1:
            raise ValueError("WAV has invalid or empty audio dimensions.")
        raw = wav.readframes(frames)
    samples = _decode_pcm(raw, sample_width)
    if not samples or len(samples) % channels:
        raise ValueError("WAV PCM payload is empty or misaligned.")
    frame_count = len(samples) // channels
    frame_peaks, frame_squares, frame_means = [], [], []
    clipped_frames = silent_frames = 0
    peak = 0.0
    sum_squares = 0.0
    sum_samples = 0.0
    for index in range(0, len(samples), channels):
        frame = samples[index:index + channels]
        frame_peak = max(abs(value) for value in frame)
        frame_mean = sum(frame) / channels
        frame_peaks.append(frame_peak)
        frame_means.append(frame_mean)
        frame_squares.append(sum(value * value for value in frame) / channels)
        peak = max(peak, frame_peak)
        sum_squares += frame_squares[-1]
        sum_samples += sum(frame)
        if frame_peak >= clipping_threshold:
            clipped_frames += 1
        if frame_peak <= silence_threshold:
            silent_frames += 1
    rms = math.sqrt(sum_squares / frame_count)
    dc_offset = sum_samples / (frame_count * channels)
    leading = 0
    while leading < frame_count and frame_peaks[leading] <= silence_threshold:
        leading += 1
    trailing = 0
    while trailing < frame_count and frame_peaks[frame_count - 1 - trailing] <= silence_threshold:
        trailing += 1
    duration = frame_count / sample_rate
    peak_dbfs = 20 * math.log10(peak) if peak > 0 else None
    rms_dbfs = 20 * math.log10(rms) if rms > 0 else None
    warnings = []
    if rms <= 1e-8:
        warnings.append("Audio is silent or effectively empty.")
    if clipped_frames:
        warnings.append("Clipping detected in {:.3f}% of frames.".format(100 * clipped_frames / frame_count))
    if abs(dc_offset) > 0.02:
        warnings.append("DC offset exceeds 0.02 full scale.")
    if silent_frames / frame_count > 0.25:
        warnings.append("More than 25% of frames are below the configured silence threshold.")
    if leading / sample_rate > 0.5:
        warnings.append("Leading silence exceeds 0.5 seconds.")
    if trailing / sample_rate > 0.5:
        warnings.append("Trailing silence exceeds 0.5 seconds.")
    return {
        "schema_version": "audio-quality-v1",
        "file": absolute_path,
        "status": "warning" if warnings else "pass",
        "format": {"container": "wav", "codec": "pcm", "sample_rate_hz": sample_rate,
                   "channels": channels, "bit_depth": sample_width * 8,
                   "frames": frame_count, "duration_seconds": round(duration, 4)},
        "signal": {
            "peak": round(peak, 6), "peak_dbfs": round(peak_dbfs, 2) if peak_dbfs is not None else None,
            "rms": round(rms, 6), "rms_dbfs": round(rms_dbfs, 2) if rms_dbfs is not None else None,
            "dc_offset": round(dc_offset, 6),
            "clipped_frames": clipped_frames,
            "clipped_frame_ratio": round(clipped_frames / frame_count, 6),
            "silent_frames": silent_frames,
            "silence_frame_ratio": round(silent_frames / frame_count, 6),
            "leading_silence_seconds": round(leading / sample_rate, 4),
            "trailing_silence_seconds": round(trailing / sample_rate, 4),
        },
        "thresholds": {"silence_amplitude": silence_threshold,
                       "clipping_amplitude": clipping_threshold},
        "warnings": warnings,
        "limitations": [
            "RMS dBFS is not LUFS and is not EBU R128 loudness measurement.",
            "Signal metrics cannot determine whether a voice sounds human or natural.",
            "No speech recognition, pronunciation, intelligibility, or perceptual listening test is performed."
        ]
    }


def main():
    parser = argparse.ArgumentParser(description="Offline WAV quality analyzer")
    parser.add_argument("audio")
    parser.add_argument("--json", dest="json_path", help="Optional JSON report output path")
    parser.add_argument("--silence-threshold", type=float, default=0.001)
    parser.add_argument("--clipping-threshold", type=float, default=0.999)
    args = parser.parse_args()
    report = analyze_wav(args.audio, args.silence_threshold, args.clipping_threshold)
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    if args.json_path:
        os.makedirs(os.path.dirname(os.path.abspath(args.json_path)), exist_ok=True)
        with open(args.json_path, "w", encoding="utf-8") as stream:
            stream.write(rendered + "\\n")
    print(rendered)
    if report["status"] != "pass":
        raise SystemExit(2)


if __name__ == "__main__":
    main()
