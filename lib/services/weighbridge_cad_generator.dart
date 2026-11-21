import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/weighbridge_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm, [int decimals = 3]) => (mm / 1000).toStringAsFixed(decimals);

class WeighbridgeCadResult {
  const WeighbridgeCadResult({this.drawing, this.issue, this.widthMm = 0, this.depthMm = 0, this.fromMm = 0, this.toMm = 0,
    this.tandemMm = 0, this.spanMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final int widthMm, depthMm, fromMm, toMm, tandemMm, spanMm;
  double get stopMm => (fromMm + toMm) / 2;

  String? toCsv() => drawing == null ? null : [
    'axle,earliest_chainage_m,midpoint_chainage_m,latest_chainage_m',
    for (final (id, delta) in [('rearmost', 0), ('forward_rear', tandemMm), ('front', spanMm)])
      '$id,${_m(fromMm + delta, 4)},${_m(stopMm + delta, 4)},${_m(toMm + delta, 4)}',
    '',
  ].join('\r\n');
}

/// Static three-axle fit for a straight, level corridor. No weigh accuracy, traffic or structural design.
class WeighbridgeCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == weighbridgeMode;

  WeighbridgeCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    WeighbridgeCadResult stop(String issue) => WeighbridgeCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !weighbridgeCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Freight Terminal and save the current weighbridge brief.');
    }
    if (!const {null, 'terminal_depot', 'linear_corridor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement, Terminal / Depot or Linear Corridor and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor weighbridge corridor only. Remove floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 200}) =>
        v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final plateL = mm(a['wb_plate_l']), plateW = mm(a['wb_plate_w']), leadS = mm(a['wb_approach_s']), leadN = mm(a['wb_approach_n']);
    final lane = mm(a['wb_lane']), separator = mm(a['wb_split']), bypass = mm(a['wb_bypass']);
    final axleEdge = mm(a['wb_axle_edge'], min: 0), sideClear = mm(a['wb_side_clear'], min: 0);
    final body = mm(a['wb_body']), tyre = mm(a['wb_tyre']), wheelbase = mm(a['wb_wheelbase']), tandem = mm(a['wb_tandem']);
    final frontOH = mm(a['wb_front_oh'], min: 0), rearOH = mm(a['wb_rear_oh'], min: 0);
    final west = mm(a['wb_west'], min: 0, max: 2000), south = mm(a['wb_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || plateL == null || plateW == null || leadS == null ||
        leadN == null || lane == null || separator == null || bypass == null || axleEdge == null || sideClear == null || body == null ||
        tyre == null || wheelbase == null || tandem == null || frontOH == null || rearOH == null || west == null || south == null) {
      return stop('Enter valid measured plot, platform, approaches, clear widths and truck dimensions.');
    }
    if (plateW > lane) return stop('The platform must fit inside the weighing corridor.');
    if (tyre > body) return stop('The declared tyre envelope cannot exceed the vehicle body width in this template.');
    if (plateW < tyre + 2 * sideClear) return stop('The tyre envelope and both side clearances do not fit the platform.');
    if (lane < body + 2 * sideClear) return stop('The body envelope and both side clearances do not fit the weighing corridor.');
    final width = lane + separator + bypass, depth = leadS + plateL + leadN;
    final span = wheelbase + tandem;
    final loAxle = leadS + axleEdge, hiAxle = leadS + plateL - axleEdge - span;
    if (hiAxle < loAxle) return stop('The full axle span and both end margins do not fit the weighing platform.');
    final low = math.max(loAxle, rearOH), high = math.min(hiAxle, depth - span - frontOH);
    if (high < low) return stop('All axles can fit on the platform, but the body overhangs leave no common stopping position within the clear approaches.');
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The complete weighing and bypass envelope conflicts with the $edge plot edge or supplied setback.');
    }
    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void mark(String layer, num x, num y, String text, num size) => labels.add(CadLabel(layer, CadPoint(x, y), text, size));
    final north = south + depth, xMid = west + lane / 2, yPlate = south + leadS, yPlateEnd = yPlate + plateL;
    box('WB_PLOT', 0, 0, pw, pd);
    box('WB_BYPASS', west + lane + separator, south, west + width, north);
    box('WB_PLATE', xMid - plateW / 2, yPlate, xMid + plateW / 2, yPlateEnd);
    if (plateW == lane) {
      for (final x in [west, west + lane]) {
        line('WB_LANE', x, south, x, yPlate);
        line('WB_LANE', x, yPlateEnd, x, north);
      }
      for (final y in [south, north]) {
        line('WB_LANE', west, y, west + lane, y);
      }
    } else {
      box('WB_LANE', west, south, west + lane, north);
    }
    final chosen = (low + high) / 2;
    box('WB_BODY', xMid - body / 2, south + chosen - rearOH, xMid + body / 2, south + chosen + span + frontOH);
    for (final delta in [0, tandem, span]) {
      final y = south + chosen + delta;
      line('WB_AXLE', xMid - tyre / 2, y, xMid + tyre / 2, y);
    }
    final rx = west + lane + separator / 2;
    if (high > low) line('WB_RANGE', rx, south + low, rx, south + high);
    final tick = separator / 3;
    for (final ch in {low, high}) {
      line('WB_RANGE', rx - tick, south + ch, rx + tick, south + ch);
    }
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    mark('WB_BYPASS', west + width - bypass / 2, (south + north) / 2, 'BYPASS', math.min(.65 * t, bypass / 7));
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    mark('ANNOTATIONS', pw / 2, pd + 4 * t, 'MEASURED FREIGHT WEIGHBRIDGE / PLAN / LOCAL MM', t);
    mark('ANNOTATIONS', pw / 2, pd + 2.5 * t,
      'REARMOST AXLE CH ${_m(low)} TO ${_m(high)} M / ENVELOPE ${_m(width)} x ${_m(depth)} M', .64 * t);
    num minX = 0, maxX = nx, maxY = pd;
    for (final label in labels) {
      final half = label.height * label.text.length * .43;
      minX = math.min(minX, label.at.x - half);
      maxX = math.max(maxX, label.at.x + half);
      maxY = math.max(maxY, label.at.y + label.height);
    }
    final drawing = FloorPlanCad.fromEntities(bounds: PlanRect((minX - 2 * t).floor(), (-2 * t).floor(),
      (maxX + 2 * t).ceil(), (maxY + 2 * t).ceil()), lines: lines, labels: labels);
    return WeighbridgeCadResult(drawing: drawing, widthMm: width, depthMm: depth, fromMm: low, toMm: high, tandemMm: tandem, spanMm: span);
  }
}
