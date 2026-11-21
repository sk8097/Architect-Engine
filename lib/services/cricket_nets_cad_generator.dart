import 'dart:math' as math;

import '../data/cricket_nets_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm, [int places = 3]) => (mm / 1000).toStringAsFixed(places);

class CricketNetLane {
  const CricketNetLane(this.id, this.centerMm, this.bowlerMm, this.batterMm, this.bowlerPopMm, this.batterPopMm);
  final String id;
  final double centerMm;
  final int bowlerMm, batterMm, bowlerPopMm, batterPopMm;

  String _row() => '$id,${_m(centerMm, 4)},${_m(bowlerMm, 4)},${_m(batterMm, 4)},${_m(bowlerPopMm, 4)},${_m(batterPopMm, 4)}';
}

class CricketNetsCadResult {
  const CricketNetsCadResult({this.drawing, this.issue, this.lanes = const [], this.widthMm = 0, this.depthMm = 0,
    this.pitchMm = 0, this.runupMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<CricketNetLane> lanes;
  final int widthMm, depthMm, pitchMm, runupMm;

  String? toCsv() => drawing == null ? null : [
    'lane,centre_x_m,bowler_wicket_y_m,batter_wicket_y_m,bowler_popping_y_m,batter_popping_y_m',
    for (final lane in lanes) lane._row(),
    '',
  ].join('\r\n');
}

/// Plan set-out only; lane edges are not a net, support or ball-containment design.
class CricketNetsCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == cricketNetsMode;

  CricketNetsCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    CricketNetsCadResult stop(String issue) => CricketNetsCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !cricketNetsCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select an eligible sports facility and save the measured cricket nets brief.');
    }
    if (!const {null, 'outdoor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank setting or Outdoor and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor lane bank. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 150}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    final rawCount = a['cn_count'];
    final count = rawCount is num && rawCount.isFinite && rawCount >= 1 && rawCount <= 12 && rawCount == rawCount.toInt() ? rawCount.toInt() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final w = mm(a['cn_w']), gap = mm(a['cn_gap'], min: 0), pitch = mm(a['cn_pitch']);
    final runup = mm(a['cn_runup']), minRunup = mm(a['cn_min_runup']), rear = mm(a['cn_rear']), minRear = mm(a['cn_min_rear']);
    final crease = mm(a['cn_crease']), pop = mm(a['cn_pop']), returnW = mm(a['cn_return_w']), returnL = mm(a['cn_return_l']);
    final side = mm(a['cn_side']), end = mm(a['cn_end']);
    final west = mm(a['cn_west'], min: 0, max: 2000), south = mm(a['cn_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || count == null || w == null || gap == null ||
        pitch == null || runup == null || minRunup == null || rear == null || minRear == null || crease == null || pop == null ||
        returnW == null || returnL == null || side == null || end == null || west == null || south == null) {
      return stop('Enter valid plot, whole lane count, distances, crease and reserve dimensions.');
    }
    if (runup < minRunup || rear < minRear) return stop('Increase the run-up or batter rear clearance to meet its submitted minimum.');
    if (returnW >= crease || crease >= w) return stop('Return crease separation must be narrower than the transverse crease, which must be narrower than the lane.');
    if (2 * pop >= pitch) return stop('The two infield popping creases must stay separate.');
    if (returnL <= pop || returnL > pop + math.min(runup, rear)) {
      return stop('Each return crease must reach behind its wicket line without going beyond the lane end.');
    }
    final width = count * w + (count - 1) * gap + 2 * side, depth = runup + pitch + rear + 2 * end;
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final minimum = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (minimum == null || available < minimum) return stop('The full lane bank and reserve conflict with the $edge plot edge or supplied setback.');
    }

    final lines = <CadLine>[], labels = <CadLabel>[], lanes = <CricketNetLane>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void mark(String layer, num x, num y, String text, num size) => labels.add(CadLabel(layer, CadPoint(x, y), text, size));
    box('CN_PLOT', 0, 0, pw, pd);
    box('CN_RESERVE', west, south, west + width, south + depth);
    final y0 = south + end, yBowler = y0 + runup, yBatter = yBowler + pitch, y1 = yBatter + rear;
    final yPB = yBowler + pop, yPT = yBatter - pop;
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    for (var i = 0; i < count; i++) {
      final x = west + side + i * (w + gap), x1 = x + w, cx = x + w / 2;
      final id = 'N${(i + 1).toString().padLeft(2, '0')}';
      lanes.add(CricketNetLane(id, cx, yBowler, yBatter, yPB, yPT));
      if (i == 0 || gap > 0) line('CN_LANE', x, y0, x, y1);
      line('CN_LANE', x1, y0, x1, y1);
      line('CN_LANE', x, y0, x1, y0);
      line('CN_LANE', x, y1, x1, y1);
      for (final (yW, yP, direction) in [(yBowler, yPB, -1), (yBatter, yPT, 1)]) {
        line('CN_WICKET', cx - crease / 2, yW, cx + crease / 2, yW);
        line('CN_POP', cx - crease / 2, yP, cx + crease / 2, yP);
        for (final s in [-1, 1]) {
          final rx = cx + s * returnW / 2;
          line('CN_RETURN', rx, yP, rx, yP + direction * returnL);
        }
      }
      mark('CN_LANE', cx, (y0 + yBowler) / 2, id, math.min(.65 * t, math.min(w, runup) / 4));
    }
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    mark('ANNOTATIONS', pw / 2, pd + 4 * t, 'MEASURED CRICKET PRACTICE NETS / PLAN / LOCAL MM', t);
    mark('ANNOTATIONS', pw / 2, pd + 2.5 * t, '$count LANES / WICKETS ${_m(pitch)} M APART / ENVELOPE ${_m(width)} x ${_m(depth)} M', .64 * t);
    num minX = 0, maxX = nx, maxY = pd;
    for (final label in labels) {
      final half = label.height * label.text.length * .43;
      minX = math.min(minX, label.at.x - half);
      maxX = math.max(maxX, label.at.x + half);
      maxY = math.max(maxY, label.at.y + label.height);
    }
    final drawing = FloorPlanCad.fromEntities(bounds: PlanRect((minX - 2 * t).floor(), (-2 * t).floor(),
      (maxX + 2 * t).ceil(), (maxY + 2 * t).ceil()), lines: lines, labels: labels);
    return CricketNetsCadResult(drawing: drawing, lanes: List.unmodifiable(lanes), widthMm: width, depthMm: depth, pitchMm: pitch, runupMm: runup);
  }
}
