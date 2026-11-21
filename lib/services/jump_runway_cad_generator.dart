import 'dart:math' as math;

import '../data/jump_runway_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class JumpTakeoff {
  const JumpTakeoff(this.event, this.approachMm, this.nearMm, this.farMm);
  final String event;
  final int approachMm, nearMm, farMm;
}

class JumpRunwayCadResult {
  const JumpRunwayCadResult({this.drawing, this.issue, this.takeoffs = const [], this.widthMm = 0, this.depthMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<JumpTakeoff> takeoffs;
  final int widthMm, depthMm;
  String? toCsv() => drawing == null ? null : [
    'event,approach_to_takeoff_m,takeoff_to_near_sand_edge_m,takeoff_to_far_sand_edge_m',
    for (final t in takeoffs) '${t.event},${_m(t.approachMm)},${_m(t.nearMm)},${_m(t.farMm)}',
    '',
  ].join('\r\n');
}

/// Measures two independent take-off lines against one runway and sand pit.
class JumpRunwayCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == jumpRunwayMode;

  JumpRunwayCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    JumpRunwayCadResult stop(String issue) => JumpRunwayCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !jumpRunwayCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select an eligible outdoor sports project and save the current measured jump runway brief.');
    }
    if (!const {null, 'outdoor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor runway without enclosed floors, separate parking or Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    int? mm(Object? v, {num min = .001, num max = 120}) =>
        v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    final a = req.answers;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final runL = mm(a['jr_run_l']), runW = mm(a['jr_run_w'], max: 20);
    final pitL = mm(a['jr_pit_l'], max: 30), pitW = mm(a['jr_pit_w'], max: 20);
    final long = mm(a['jr_long_offset'], max: 30), triple = mm(a['jr_triple_offset'], max: 30);
    final longMinRun = mm(a['jr_long_run_min']), tripleMinRun = mm(a['jr_triple_run_min']);
    final longMinFar = mm(a['jr_long_far_min']), tripleMinFar = mm(a['jr_triple_far_min']);
    final side = mm(a['jr_side'], max: 25), startReserve = mm(a['jr_south_reserve'], max: 25), endReserve = mm(a['jr_north_reserve'], max: 25);
    final west = mm(a['jr_west'], min: 0, max: 2000), south = mm(a['jr_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || runL == null || runW == null || pitL == null || pitW == null ||
        long == null || triple == null || longMinRun == null || tripleMinRun == null || longMinFar == null || tripleMinFar == null ||
        side == null || startReserve == null || endReserve == null || west == null || south == null) {
      return stop('Enter valid measured plot, runway, usable sand, take-off and reserve dimensions.');
    }
    if (pitW < runW) return stop('The centred usable sand pit must be at least as wide as the runway.');
    if (triple <= long) return stop('The triple-jump take-off line must be farther from the near sand edge than the long-jump line.');
    final takeoffs = [JumpTakeoff('long_jump', runL - long, long, long + pitL),
      JumpTakeoff('triple_jump', runL - triple, triple, triple + pitL)];
    for (final (t, name, minRun, minFar) in [(takeoffs[0], 'Long-jump', longMinRun, longMinFar), (takeoffs[1], 'Triple-jump', tripleMinRun, tripleMinFar)]) {
      if (t.approachMm <= 0) return stop('$name take-off line must lie inside the runway.');
      if (t.approachMm < minRun) return stop('$name has only ${_m(t.approachMm)} m of approach to its take-off line.');
      if (t.farMm < minFar) return stop('$name take-off line is only ${_m(t.farMm)} m from the far sand edge.');
    }
    final width = pitW + 2 * side, depth = startReserve + runL + pitL + endReserve;
    for (final (edge, gap) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || gap < min) return stop('The full runway and sand-pit envelope conflicts with the $edge plot edge or supplied setback.');
    }
    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    final cx = west + width / 2, start = south + startReserve, near = start + runL, far = near + pitL;
    final runLeft = cx - runW / 2, runRight = cx + runW / 2;
    box('JR_PLOT', 0, 0, pw, pd);
    box('JR_RESERVE', west, south, west + width, south + depth);
    line('JR_RUN', runLeft, start, runRight, start);
    line('JR_RUN', runLeft, start, runLeft, near);
    line('JR_RUN', runRight, start, runRight, near);
    // The near sand edge already closes the shared mouth across the runway.
    box('JR_SAND', cx - pitW / 2, near, cx + pitW / 2, far);
    final t = (math.max(pw, pd) / 94).clamp(18, 8000).toDouble();
    for (var i = 0; i < takeoffs.length; i++) {
      final v = takeoffs[i], label = i == 0 ? 'LJ' : 'TJ';
      final y = start + v.approachMm;
      line('JR_BOARD', runLeft, y, runRight, y);
      labels.add(CadLabel('JR_BOARD', CadPoint(runRight + 1.25 * t, y), label, .65 * t));
    }
    final nx = pw + 2.5 * t;
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    labels.addAll([CadLabel('ANNOTATIONS', CadPoint(nx, pd + t), 'N', .7 * t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 6 * t), 'MEASURED LONG AND TRIPLE JUMP RUNWAY / LOCAL MM', t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 4.6 * t), 'RUNWAY ${_m(runW)} x ${_m(runL)} M / USABLE SAND ${_m(pitW)} x ${_m(pitL)} M', .66 * t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 3.2 * t), 'LJ TO SAND: ${_m(long)}-${_m(long + pitL)} M / TJ TO SAND: ${_m(triple)}-${_m(triple + pitL)} M', .63 * t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 1.8 * t), 'TAKE-OFF LINES ONLY / NO SURFACING OR COMPETITION APPROVAL', .61 * t)]);
    final bounds = PlanRect(math.min(-2 * t, pw / 2 - 43 * t).floor(), (-2 * t).floor(),
      math.max(nx + 3 * t, pw / 2 + 43 * t).ceil(), (pd + 7.5 * t).ceil());
    return JumpRunwayCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels),
      takeoffs: List.unmodifiable(takeoffs), widthMm: width, depthMm: depth);
  }
}
