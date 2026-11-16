# -*- coding: utf-8 -*-
"""Fitness & Science Anatomy Explainer — Science-Based Training & Biomechanics Engine.

Inspired by science-based fitness channels (Jeff Nippard, PictureFit, Jeremy Ethier).
Focuses on muscular hypertrophy, anatomical fiber activation, rep cadence,
biomechanical angles, and exercise physiology.

WHAT MAKES IT WORK
  * Anatomical Precision: Dark athletic carbon background (#0B0F19) with glowing crimson red (#EF4444)
    and electric cyan (#06B6D4) for muscle activation zones and biomechanical force vectors.
  * Research & Data: Built-in scientific research citation chips ("EMG STUDY // N=42", "TENSION PEAK").
  * Pacing: Dynamic, high-energy 1.5 - 2.5 second cuts synced to rep cadences and coaching cues.
  * Motion Graphics: Glowing muscle fiber pulse, HUD rep/second counters, range-of-motion arcs,
    and side-by-side exercise comparison cards.
"""

NAME = "fitness"
ALIASES = ["anatomy", "workout", "gym", "fitness_science"]

_NEG = ("no text, no letters, no captions, no watermark, no logo, no signature, no UI, "
        "no borders, no frames, no low quality, no blur, no generic clipart")

STYLE = {
    "look": {
        "bg": (11, 15, 25),             # deep athletic carbon slate
        "ink": (248, 250, 252),         # crisp white clinical typography
        "muted": (148, 163, 184),       # slate muted labels & source tags
        "accent": (239, 68, 68),        # glowing crimson red (muscle contraction / peak tension)
        "accent2": (6, 182, 212),       # electric cyan (biomechanical force / joint angles)
        "accent3": (234, 179, 8),       # warning amber (hypertrophy threshold / caution)
        "panel": (18, 24, 38, 245),     # dark carbon fiber panel fill
        "stamp_color": (239, 68, 68),
        "string_color": (6, 182, 212),
        "caption": "box",
        "asset_frame": "card",
        "photo_frame": "card",
        "letterbox": 0.0, "grade": "", "grain": 0, "vignette": False,
        "transition": "slide",
        "camera": "drift",
        "grid": True,
        "kicker_prefix": "EXERCISE SCIENCE // ",
        "title_font": "headline",
        "boxes": ["pill", "label", "outline", "neon"],
    },
    "prompt": {
        "clarity": (
            "athletic anatomical human figure performing exercise with highlighted muscle fiber activation, "
            "detailed biomechanics, dark carbon gym environment with subtle cyan rim lighting, "
            "clear anatomical isolation, generous negative space on one side for headline, 8K medical illustration standard"
        ),
        "medium": "medical 3D anatomical visualization and athletic sports science photograph, 8K standard",
        "lighting": "moody dark studio, rim light highlighting muscle striations and posture, glowing red tension field",
        "palette": "deep dark carbon slate, metallic graphite, glowing crimson red muscle highlight, electric cyan angle lines",
        "camera": {"shot": "medium full shot", "lens": "70mm sports lens", "angle": "eye level profile", "movement": "slow zoom in"},
        "mood": "scientific, intense, clinical, powerful, authoritative",
        "quality": "ultra realistic anatomy, true medical accuracy, pin-sharp muscle striations, zero distortion",
        "negative": _NEG,
        "asset_medium": "isolated 3D anatomical muscle cutout on pure transparent background with soft shadow",
    },
}

LAYOUTS_16_9 = {
    "anatomy_hero": {
        "tag": (0.06, 0.08, 0.88, 0.05),
        "title": (0.06, 0.14, 0.45, 0.22),
        "asset": (0.52, 0.12, 0.44, 0.78),
        "counter": (0.06, 0.38, 0.45, 0.25),
        "lower": (0.06, 0.65, 0.45, 0.20),
    },
    "exercise_compare": {
        "tag": (0.06, 0.08, 0.88, 0.05),
        "title": (0.06, 0.14, 0.88, 0.10),
        "a": (0.06, 0.26, 0.42, 0.55),
        "b": (0.52, 0.26, 0.42, 0.55),
        "la": (0.06, 0.83, 0.42, 0.08),
        "lb": (0.52, 0.83, 0.42, 0.08),
    },
}

LAYOUTS_9_16 = {
    "anatomy_vertical": {
        "tag": (0.08, 0.14, 0.84, 0.04),
        "title": (0.08, 0.19, 0.84, 0.14),
        "asset": (0.10, 0.35, 0.80, 0.38),
        "counter": (0.08, 0.75, 0.84, 0.10),
    },
    "stat_hero": {
        "tag": (0.08, 0.14, 0.84, 0.04),
        "label": (0.08, 0.20, 0.84, 0.05),
        "title": (0.08, 0.27, 0.84, 0.22),
        "asset": (0.12, 0.51, 0.76, 0.26),
        "lower": (0.08, 0.79, 0.84, 0.06),
    },
}
