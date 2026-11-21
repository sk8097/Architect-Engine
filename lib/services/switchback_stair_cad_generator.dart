import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/switchback_stair_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class SwitchbackStairCadResult {
  const SwitchbackStairCadResult({this.plan, this.elevation, this.issue, this.risers = 0, this.riserMm = 0,
    this.runMm = 0, this.widthMm = 0, this.depthMm = 0, this.turnRlMm = 0});
  final FloorPlanCad? plan, elevation;
  final String? issue;
  final int risers, runMm, widthMm, depthMm;
  final double riserMm, turnRlMm;
}

/// Open-air horizontal layout and superposed side elevation, not stair code design.
class SwitchbackStairCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == switchbackStairMode;

  SwitchbackStairCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    SwitchbackStairCadResult stop(String issue) => SwitchbackStairCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !switchbackStairCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Public Park or Urban Plaza and save the current measured outdoor stair brief.');
    }
    if (!const {null, 'public_open_space'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one open-air stair without enclosed floors, parking or separate Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers, raw = req.answers['ss_datum'];
    final datum = raw is String ? raw.trim().replaceAll(RegExp(r'\s+'), ' ') : '';
    if (datum.isEmpty || datum.length > 100) return stop('Enter one common elevation datum, up to 100 characters.');
    int? mm(Object? v, {num min = .001, num max = 25}) =>
        v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final lower = mm(a['ss_lower'], min: -10000, max: 10000), upper = mm(a['ss_upper'], min: -10000, max: 10000);
    final minR = mm(a['ss_min_riser'], max: 1), maxR = mm(a['ss_max_riser'], max: 1), going = mm(a['ss_going'], max: 5);
    final flight = mm(a['ss_width']), gap = mm(a['ss_gap'], min: 0), end = mm(a['ss_end']), turn = mm(a['ss_turn']);
    final west = mm(a['ss_west'], min: 0, max: 2000), south = mm(a['ss_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || lower == null || upper == null ||
        minR == null || maxR == null || going == null || flight == null || gap == null || end == null || turn == null || west == null || south == null) {
      return stop('Enter valid plot, landing levels, riser range, going and stair envelope dimensions.');
    }
    if (upper <= lower) return stop('The upper landing level must be higher than the lower landing level.');
    if (minR > maxR) return stop('The submitted minimum riser height cannot exceed the maximum.');
    if (end < flight || turn < flight) return stop('For this template, south and turn landing depths must each be at least the clear flight width.');
    final rise = upper - lower;
    // Find the fewest risers per flight whose shared height is at most maxR.
    // With more risers the height can only shrink and the plan can only get longer.
    final perFlight = math.max(2, (rise + 2 * maxR - 1) ~/ (2 * maxR));
    if (perFlight > 24) return stop('The upper level and maximum riser require more than 24 risers per flight.');
    if (rise < 2 * perFlight * minR) return stop('No equal two-flight stair meets both submitted riser limits.');
    final riser = rise / (2 * perFlight), run = (perFlight - 1) * going;
    final width = 2 * flight + gap, depth = end + run + turn;
    for (final (edge, room) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || room < min) return stop('The full stair envelope conflicts with the $edge plot edge or supplied setback.');
    }
    final plan = _Sheet(), elevation = _Sheet();
    final start = south + end, mid = start + run, right = west + width, eastFlight = right - flight;
    plan.box('SS_PLOT', 0, 0, pw, pd);
    // Each riser, including first and last, is one plan line; landing edges
    // share the first/last risers without overpainting them.
    for (final (layer, l, r) in [('SS_UP_W', west, west + flight), ('SS_UP_E', eastFlight, right)]) {
      plan.line('SS_LAND', l, south, r, south);
      plan.line('SS_LAND', l, south, l, start);
      if (gap > 0 || layer == 'SS_UP_E') plan.line('SS_LAND', r, south, r, start);
      plan.line(layer, l, start, l, mid);
      if (gap > 0 || layer == 'SS_UP_E') plan.line(layer, r, start, r, mid);
      for (var i = 0; i < perFlight; i++) {
        final y = start + going * i;
        plan.line(layer, l, y, r, y);
      }
    }
    if (gap > 0) plan.line('SS_LAND', west + flight, mid, eastFlight, mid);
    plan.line('SS_LAND', west, mid, west, mid + turn);
    plan.line('SS_LAND', right, mid, right, mid + turn);
    plan.line('SS_LAND', west, mid + turn, right, mid + turn);
    final t = (math.max(pw, pd) / 88).clamp(15, 10000).toDouble();
    for (final (layer, x, sign) in [('SS_UP_W', west + flight / 2, 1), ('SS_UP_E', right - flight / 2, -1)]) {
      final tail = start + run * (sign == 1 ? .18 : .82), tip = start + run * (sign == 1 ? .82 : .18);
      final size = math.min(run / 8, flight / 4);
      plan.line('SS_ARROW', x, tail, x, tip);
      plan.line('SS_ARROW', x - size / 2, tip - sign * size, x, tip);
      plan.line('SS_ARROW', x + size / 2, tip - sign * size, x, tip);
      plan.labels.add(CadLabel(layer, CadPoint(x, south + end / 2), sign == 1 ? 'LOWER' : 'UPPER', math.min(.7 * t, flight / 6)));
    }
    final nx = pw + 2.5 * t;
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.labels.add(CadLabel('ANNOTATIONS', CadPoint(nx, pd + t), 'N', .65 * t));
    plan.heading(pw / 2, pd, t, [
      'MEASURED OUTDOOR SWITCHBACK STAIR / PLAN / LOCAL MM',
      '$perFlight RISERS PER FLIGHT / ${perFlight - 1} GOINGS / ${_m(run)} M RUN EACH',
      'NORTH TURN LANDING / WEST FLIGHT UP NORTH / EAST FLIGHT UP SOUTH',
    ]);

    final halfRise = rise / 2;
    elevation.line('SS_LAND', 0, 0, end, 0);
    elevation.line('SS_LAND', end + run, halfRise, depth, halfRise);
    elevation.line('SS_LAND', end, rise, 0, rise);
    for (var i = 0; i < perFlight; i++) {
      final xWest = end + i * going, xEast = end + run - i * going;
      // Derive both elevations from the whole integer rise instead of accumulating rounded risers.
      final z0 = i * rise / (2 * perFlight), z1 = (i + 1) * rise / (2 * perFlight);
      elevation.line('SS_UP_W', xWest, z0, xWest, z1);
      elevation.line('SS_UP_E', xEast, halfRise + z0, xEast, halfRise + z1);
      if (i < perFlight - 1) {
        elevation.line('SS_UP_W', xWest, z1, xWest + going, z1);
        elevation.line('SS_UP_E', xEast, halfRise + z1, xEast - going, halfRise + z1);
      }
    }
    final st = (math.max(depth, rise) / 76).clamp(15, 9000).toDouble();
    elevation.heading(depth / 2, rise, st, [
      'SIDE ELEVATION / TRUE SCALE MM / BOTH PARALLEL FLIGHTS',
      'BASE RL ${_m(lower)} M = ZERO / TURN RL ${_m(lower + halfRise)} M / DATUM: $datum',
      'RISER ${(riser).toStringAsFixed(3)} MM / GOING ${_m(going)} M / SURFACE GEOMETRY ONLY',
    ]);
    return SwitchbackStairCadResult(plan: plan.drawing(t), elevation: elevation.drawing(st), risers: perFlight,
      riserMm: riser, runMm: run, widthMm: width, depthMm: depth, turnRlMm: lower.toDouble() + halfRise);
  }
}

class _Sheet {
  final lines = <CadLine>[], labels = <CadLabel>[];
  void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
  void box(String layer, num x, num y, num ex, num ey) {
    line(layer, x, y, ex, y);
    line(layer, ex, y, ex, ey);
    line(layer, ex, ey, x, ey);
    line(layer, x, ey, x, y);
  }
  void heading(num x, num y, double size, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      labels.add(CadLabel('ANNOTATIONS', CadPoint(x, y + (rows.length - i + .5) * 1.3 * size), rows[i], i == 0 ? size : .62 * size));
    }
  }
  FloorPlanCad drawing(double t) {
    final pts = [for (final l in lines) ...[l.start, l.end], for (final l in labels) ...[
      CadPoint(l.at.x - l.height * l.text.length * .42, l.at.y - l.height),
      CadPoint(l.at.x + l.height * l.text.length * .42, l.at.y + l.height),
    ]];
    return FloorPlanCad.fromEntities(bounds: PlanRect((pts.map((p) => p.x).reduce(math.min) - 3 * t).floor(),
      (pts.map((p) => p.y).reduce(math.min) - 3 * t).floor(), (pts.map((p) => p.x).reduce(math.max) + 3 * t).ceil(),
      (pts.map((p) => p.y).reduce(math.max) + 3 * t).ceil()), lines: lines, labels: labels);
  }
}
