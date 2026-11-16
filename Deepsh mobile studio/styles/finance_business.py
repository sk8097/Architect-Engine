# -*- coding: utf-8 -*-
"""Finance & Business Motion Graphics — Growth Story Studio & Finance Explainer Engine.

Inspired by Growth Story Studio, Ali Abdaal, Bloomberg Originals, and Modern Finance Shorts.
Focuses on recurring revenue models, financial mechanics, cashflow architecture,
and business valuation breakdowns.

WHAT MAKES IT WORK
  * Professional Data Hierarchy: Clean dark slate canvas (#0A0E17) with electric Emerald (#10B981) for profit/growth,
    Royal Gold (#F59E0B) for valuation/capital, and Slate Blue (#3B82F6) for systems.
  * Pacing: High visual retention cuts every 1.5 - 2.5 seconds synced directly to spoken words.
  * Visual Assets: Vector cashflow streams, 3D isometric business models, floating profit badges,
    metric counters ($10K/mo, +340% ROI), clean graph grids.
  * Motion Graphics: Smooth spring entry, card sliding on a consistent axis, counter count-ups,
    and HUD highlight pills.
"""

NAME = "finance"
ALIASES = ["business", "growth", "money", "finance_business"]

_NEG = ("no text, no letters, no captions, no watermark, no logo, no signature, no UI, "
        "no borders, no frames, no low quality, no blur, no generic clipart")

STYLE = {
    "look": {
        "bg": (10, 14, 23),             # deep premium slate navy
        "ink": (248, 250, 252),         # crisp near-white typography
        "muted": (148, 163, 184),       # slate muted labels & source tags
        "accent": (16, 185, 129),       # electric emerald green (revenue/growth)
        "accent2": (245, 158, 11),      # royal gold (capital/money/valuation)
        "accent3": (59, 130, 246),      # cobalt blue (infrastructure/contracts)
        "panel": (19, 26, 42, 245),     # dark translucent glassmorphic card fill
        "stamp_color": (16, 185, 129),
        "string_color": (245, 158, 11),
        "caption": "box",
        "asset_frame": "card",
        "photo_frame": "card",
        "letterbox": 0.0, "grade": "", "grain": 0, "vignette": False,
        "transition": "slide",
        "camera": "drift",
        "grid": True,
        "kicker_prefix": "BUSINESS BREAKDOWN // ",
        "title_font": "headline",
        "boxes": ["pill", "label", "outline", "neon"],
    },
    "prompt": {
        "clarity": (
            "clean commercial business subject, minimalist modern composition, sleek dark slate studio environment, "
            "vibrant emerald green and gold accents, isometric financial growth graphs, cashflow streams, "
            "ample negative space on one side reserved for high-impact typography, 8K ultra clean"
        ),
        "medium": "commercial 3D vector and high-end editorial product visualization, Octane render aesthetic, 8K",
        "lighting": "subtle neon rim lighting, soft directional studio softbox, clean controlled reflections",
        "palette": "deep slate navy background, brushed platinum, emerald green growth accent, warm metallic gold",
        "camera": {"shot": "medium close-up", "lens": "50mm", "angle": "isometric 30-degree high angle", "movement": "slow drift"},
        "mood": "lucrative, analytical, inevitable, institutional, premium",
        "quality": "pin-sharp vector clarity, zero visual clutter, immaculate glass and matte surfaces",
        "negative": _NEG,
        "asset_medium": "isometric 3D asset on isolated transparent backdrop with soft contact shadow",
    },
}

LAYOUTS_16_9 = {
    "stat_hero": {
        "tag": (0.10, 0.12, 0.80, 0.05),
        "label": (0.10, 0.18, 0.80, 0.06),
        "title": (0.10, 0.26, 0.80, 0.38),
        "lower": (0.10, 0.66, 0.80, 0.08),
    },
    "cashflow_split": {
        "tag": (0.06, 0.08, 0.88, 0.05),
        "title": (0.06, 0.14, 0.45, 0.20),
        "asset": (0.54, 0.16, 0.40, 0.70),
        "counter": (0.06, 0.38, 0.45, 0.25),
        "lower": (0.06, 0.66, 0.45, 0.18),
    },
    "kpi_row": {
        "tag": (0.06, 0.09, 0.88, 0.045),
        "title": (0.06, 0.14, 0.88, 0.09),
        "a": (0.06, 0.26, 0.27, 0.42),
        "b": (0.365, 0.26, 0.27, 0.42),
        "c": (0.68, 0.26, 0.27, 0.42),
        "la": (0.06, 0.69, 0.27, 0.055),
        "lb": (0.365, 0.69, 0.27, 0.055),
        "lc": (0.68, 0.69, 0.27, 0.055),
    },
}

LAYOUTS_9_16 = {
    "stat_hero": {
        "tag": (0.08, 0.14, 0.84, 0.04),
        "label": (0.08, 0.20, 0.84, 0.05),
        "title": (0.08, 0.27, 0.84, 0.22),
        "asset": (0.12, 0.51, 0.76, 0.26),
        "lower": (0.08, 0.79, 0.84, 0.06),
    },
    "card_vertical": {
        "tag": (0.08, 0.14, 0.84, 0.04),
        "title": (0.08, 0.19, 0.84, 0.14),
        "asset": (0.10, 0.35, 0.80, 0.34),
        "counter": (0.08, 0.71, 0.84, 0.10),
    },
}


# ---- Asset Plan Parameters (Condition 3: visual change every 2 to 3 seconds) ----
BEAT_S = 2.4
MIX = {"scene": 0.38, "asset": 0.45, "reuse": 0.07, "text": 0.10}
MENU = {
    "scene": ["wide establishing", "geometric aerial", "interior narrative", "facility wide", "industrial epic", "transit interior", "epic aerial", "clinical interior"],
    "asset": ["hero prop", "data viz", "conceptual 3d"]
}
ACCENTS = ["one emerald accent", "one gold accent", "one cobalt accent"]
DESIGN = __doc__
