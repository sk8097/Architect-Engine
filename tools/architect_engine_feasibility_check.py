#!/usr/bin/env python3
"""Architect Engine pre-render feasibility screening with automatic report saving.

Usage:
  python tools/architect_engine_feasibility_check.py path/to/plan.json

Writes:
  reports/architect_engine_feasibility_report.txt          (latest snapshot)
  reports/history/feasibility_YYYYMMDD_HHMMSS.txt          (run history)

This is a screening aid, not a building-code or construction approval.
"""
from __future__ import annotations
import json
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT / "reports"

def overlaps(a, b):
    return max(a[0], b[0]) < min(a[2], b[2]) and max(a[1], b[1]) < min(a[3], b[3])

def validate(plan, source_name):
    errors, warnings = [], []
    plot = plan.get("plot", {})
    width, depth = plot.get("width"), plot.get("depth")
    if not isinstance(width, (int, float)) or not isinstance(depth, (int, float)) or width <= 0 or depth <= 0:
        return ["plot.width and plot.depth must be positive numbers in millimetres"], [], 0, 0, None

    rooms = plan.get("rooms", [])
    walls = plan.get("walls", [])
    wall_by_id = {w.get("id"): w for w in walls}

    for room in rooms:
        rid = room.get("id", "UNKNOWN")
        bounds = room.get("clear_bounds")
        if not isinstance(bounds, list) or len(bounds) != 4:
            errors.append(f"{rid}: missing/invalid clear_bounds")
            continue
        x1, y1, x2, y2 = bounds
        if x2 <= x1 or y2 <= y1:
            errors.append(f"{rid}: non-positive clear dimensions")
            continue
        if x1 < 0 or y1 < 0 or x2 > width or y2 > depth:
            errors.append(f"{rid}: room bounds outside plot")
        expected = room.get("expected_dimensions", {})
        if expected and (expected.get("width") != x2-x1 or expected.get("depth") != y2-y1):
            errors.append(f"{rid}: expected_dimensions do not match clear_bounds")
        if min(x2-x1, y2-y1) < 900:
            warnings.append(f"{rid}: clear dimension below 900 mm; check applicable room minimums")

    for i, first in enumerate(rooms):
        a = first.get("clear_bounds")
        if not isinstance(a, list) or len(a) != 4:
            continue
        for second in rooms[i+1:]:
            b = second.get("clear_bounds")
            if isinstance(b, list) and len(b) == 4 and overlaps(a, b):
                errors.append(f"ROOM OVERLAP: {first.get('id')} intersects {second.get('id')}")

    seen = set()
    for wall in walls:
        wid = wall.get("id", "UNKNOWN")
        if wid in seen:
            errors.append(f"duplicate wall id: {wid}")
        seen.add(wid)
        rect = wall.get("rect")
        # Support both current rect form and older footprint_rectangles form.
        rects = [rect] if isinstance(rect, list) and len(rect) == 4 else wall.get("footprint_rectangles", [])
        if not rects:
            warnings.append(f"{wid}: no supported rect/footprint_rectangles geometry found")
            continue
        for r in rects:
            if not isinstance(r, list) or len(r) != 4:
                errors.append(f"{wid}: malformed wall rectangle")
                continue
            x1, y1, x2, y2 = r
            if x2 <= x1 or y2 <= y1 or x1 < 0 or y1 < 0 or x2 > width or y2 > depth:
                errors.append(f"{wid}: invalid/out-of-plot wall rectangle {r}")

    for item in plan.get("furniture", []):
        iid, kind = item.get("id", "UNKNOWN"), item.get("type", "UNKNOWN")
        bounds = item.get("bounds")
        if isinstance(bounds, list) and len(bounds) == 4:
            x1, y1, x2, y2 = bounds
            if x2 <= x1 or y2 <= y1 or x1 < 0 or y1 < 0 or x2 > width or y2 > depth:
                errors.append(f"{iid} ({kind}): invalid/out-of-plot furniture bounds")
            elif not any(
                isinstance(room.get("clear_bounds"), list)
                and len(room["clear_bounds"]) == 4
                and room["clear_bounds"][0] <= x1 and room["clear_bounds"][1] <= y1
                and room["clear_bounds"][2] >= x2 and room["clear_bounds"][3] >= y2
                for room in rooms
            ):
                warnings.append(f"{iid} ({kind}): not fully inside any one room; verify placement")
        elif "polygon" in item:
            points = item.get("polygon", [])
            if not points or any(
                not isinstance(pt, list) or len(pt) != 2 or pt[0] < 0 or pt[1] < 0 or pt[0] > width or pt[1] > depth
                for pt in points
            ):
                errors.append(f"{iid} ({kind}): polygon has malformed/out-of-plot points")

    openings = plan.get("openings", {})
    for group in ("doors", "windows"):
        for opening in openings.get(group, []):
            oid, wall_id = opening.get("id", "UNKNOWN"), opening.get("wall_id")
            if wall_id not in wall_by_id:
                errors.append(f"{oid}: references unknown wall {wall_id}")
                continue
            if group == "doors":
                hinge = opening.get("hinge_xy")
                if not isinstance(hinge, list) or len(hinge) != 2:
                    errors.append(f"{oid}: invalid hinge_xy")
            else:
                interval = opening.get("absolute_interval")
                if not isinstance(interval, list) or len(interval) != 2 or interval[1] <= interval[0]:
                    errors.append(f"{oid}: invalid absolute_interval")

    warnings.extend([
        "ROOM CONNECTIVITY NOT PROVEN: verify every room has a usable door/path to the entry.",
        "WALL OPENINGS NOT GEOMETRICALLY CUT: confirm renderer does not leave solid wall behind door/window symbols.",
        "LOCAL BUILDING CODE NOT CHECKED: setbacks, ventilation, room minimums, parking access and structure require local review.",
        "VASTU IS ADVISORY; it does not replace building-code or structural review."
    ])
    return errors, warnings, len(rooms), len(walls), (width, depth)

def main():
    if len(sys.argv) < 2:
        print("Usage: python tools/architect_engine_feasibility_check.py path/to/plan.json")
        return 2
    source = Path(sys.argv[1]).expanduser()
    if not source.is_absolute():
        source = Path.cwd() / source
    if not source.is_file():
        print(f"ERROR: JSON file not found: {source}")
        return 2
    try:
        plan = json.loads(source.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"ERROR: invalid JSON: {exc}")
        return 2

    errors, warnings, room_count, wall_count, dims = validate(plan, source.name)
    now = datetime.now().astimezone()
    lines = [
        "ARCHITECT ENGINE — PRE-RENDER FEASIBILITY REPORT",
        f"Run time: {now.isoformat(timespec='seconds')}",
        f"Input: {source.name}",
    ]
    if dims:
        w, d = dims
        lines += [f"Plot: {w} × {d} mm ({w/304.8:.2f} × {d/304.8:.2f} ft)",
                  f"Rooms checked: {room_count} | Walls checked: {wall_count}"]
    if errors:
        lines += ["", f"BLOCKERS ({len(errors)}):"] + [f"  [FAIL] {e}" for e in errors]
    else:
        lines += ["", "No basic schema/bounds/room-overlap blockers found."]
    if warnings:
        lines += ["", f"WARNINGS / UNVERIFIED ({len(warnings)}):"] + [f"  [CHECK] {w}" for w in warnings]
    status = "REJECTED_INFEASIBLE_OR_INVALID" if errors else "NOT_APPROVED_NEEDS_ARCHITECTURAL_REVIEW"
    lines += ["", f"STATUS: {status}",
              "This report is a screening aid only, not construction approval."]
    report = "\n".join(lines) + "\n"

    latest = REPORTS / "architect_engine_feasibility_report.txt"
    history_dir = REPORTS / "history"
    history = history_dir / f"feasibility_{now.strftime('%Y%m%d_%H%M%S')}.txt"
    REPORTS.mkdir(parents=True, exist_ok=True)
    history_dir.mkdir(parents=True, exist_ok=True)
    latest.write_text(report, encoding="utf-8")
    history.write_text(report, encoding="utf-8")

    print(report)
    print(f"Saved latest report: {latest.relative_to(ROOT) if latest.is_relative_to(ROOT) else latest}")
    print(f"Saved history copy: {history.relative_to(ROOT) if history.is_relative_to(ROOT) else history}")
    return 1 if errors else 0

if __name__ == "__main__":
    raise SystemExit(main())
