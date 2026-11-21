import 'dart:math' as math;

import '../data/football_pitch_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class FootballPitchCadResult {
  const FootballPitchCadResult({this.drawing, this.issue, this.widthMm = 0, this.depthMm = 0, this.markingMm = const {}});
  final FloorPlanCad? drawing;
  final String? issue;
  final int widthMm, depthMm;
  final Map<String, double> markingMm;
  double get totalMarkingMm => markingMm.values.fold(0.0, (sum, length) => sum + length);

  String? toCsv() => drawing == null ? null : [
    'marking,centreline_length_m',
    for (final entry in markingMm.entries) '${entry.key},${_m(entry.value)}',
    'total,${_m(totalMarkingMm)}',
    '',
  ].join('\r\n');
}

/// Geometric centreline marks and run-off envelope; not a rules or safety check.
class FootballPitchCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == footballPitchMode;

  FootballPitchCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    FootballPitchCadResult stop(String issue) => FootballPitchCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !footballPitchCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select an eligible sports facility and save the measured football pitch brief.');
    }
    if (!const {null, 'outdoor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank setting or Outdoor and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor pitch only. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 200}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final w = mm(a['fp_w']), l = mm(a['fp_l']), mouth = mm(a['fp_mouth']);
    final gw = mm(a['fp_goal_w']), gd = mm(a['fp_goal_d']), bw = mm(a['fp_pen_w']), bd = mm(a['fp_pen_d']);
    final spot = mm(a['fp_spot']), r = mm(a['fp_arc']), centreR = mm(a['fp_centre']), cornerR = mm(a['fp_corner']);
    final side = mm(a['fp_side_run']), end = mm(a['fp_end_run']), sideMin = mm(a['fp_side_min']), endMin = mm(a['fp_end_min']);
    final west = mm(a['fp_west'], min: 0, max: 2000), south = mm(a['fp_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || w == null || l == null || mouth == null ||
        gw == null || gd == null || bw == null || bd == null || spot == null || r == null || centreR == null || cornerR == null ||
        side == null || end == null || sideMin == null || endMin == null || west == null || south == null) {
      return stop('Enter valid plot, marking dimensions, run-offs and offsets.');
    }
    if (!(mouth < gw && gw < bw && bw < w)) return stop('Require goal-mouth width < goal-area width < penalty-area width < pitch width.');
    if (!(gd < spot && spot < bd)) return stop('Locate each penalty spot beyond the goal area and inside the penalty area.');
    final delta = bd - spot;
    if (r <= delta) return stop('Increase the penalty arc radius so it extends beyond the front of the penalty area.');
    if (4 * (r * r - delta * delta) >= bw * bw) return stop('The penalty arc must meet the front line strictly between the penalty-area sides.');
    if (2 * (spot + r + centreR) >= l || 2 * centreR >= w) return stop('The centre circle must fit inside the pitch and stay clear of both penalty arcs.');
    if (2 * cornerR >= w - bw || 2 * cornerR >= l) return stop('The corner arcs must stay clear of the penalty-area sides and each other.');
    final combinedRadii = centreR + cornerR;
    if (4 * combinedRadii * combinedRadii >= w * w + l * l) return stop('The centre circle must stay clear of the corner arcs.');
    if (side < sideMin || end < endMin) return stop('Increase the touchline or end-line run-off to meet the submitted minimum.');
    final width = w + 2 * side, depth = l + 2 * end;
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The full pitch and run-off envelope conflict with the $edge plot edge or supplied setback.');
    }

    final lines = <CadLine>[], arcs = <CadArc>[], labels = <CadLabel>[];
    final totals = <String, double>{};
    void measure(String? marking, double length) {
      if (marking != null) totals.update(marking, (old) => old + length, ifAbsent: () => length);
    }
    void line(String layer, num x, num y, num ex, num ey, [String? marking]) {
      lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
      measure(marking, math.sqrt((ex - x) * (ex - x) + (ey - y) * (ey - y)));
    }
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void arc(String layer, num x, num y, int rad, num start, num finish, String marking) {
      arcs.add(CadArc(layer, CadPoint(x, y), rad, start, finish));
      measure(marking, rad * (finish - start) * math.pi / 180);
    }
    void mark(String layer, num x, num y, String text, num size) => labels.add(CadLabel(layer, CadPoint(x, y), text, size));
    final x0 = west + side, x1 = x0 + w, y0 = south + end, y1 = y0 + l;
    final cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
    box('FP_PLOT', 0, 0, pw, pd);
    box('FP_RUNOFF', west, south, west + width, south + depth);
    line('FP_FIELD', x0, y0, x0, y1, 'perimeter');
    line('FP_FIELD', x1, y0, x1, y1, 'perimeter');
    for (final y in [y0, y1]) {
      final left = cx - mouth / 2, right = cx + mouth / 2;
      line('FP_FIELD', x0, y, left, y, 'perimeter');
      line('FP_MOUTH', left, y, right, y, 'perimeter');
      line('FP_FIELD', right, y, x1, y, 'perimeter');
    }
    line('FP_CENTRE', x0, cy, x1, cy, 'halfway_line');
    for (final (boxW, boxD, layer, id) in [(gw, gd, 'FP_GOAL', 'goal_areas'), (bw, bd, 'FP_PENALTY', 'penalty_areas')]) {
      final left = cx - boxW / 2, right = cx + boxW / 2;
      for (final (y, direction) in [(y0, 1), (y1, -1)]) {
        final outer = y + direction * boxD;
        line(layer, left, y, left, outer, id);
        line(layer, left, outer, right, outer, id);
        line(layer, right, outer, right, y, id);
      }
    }
    arc('FP_CENTRE', cx, cy, centreR, 0, 180, 'centre_circle');
    arc('FP_CENTRE', cx, cy, centreR, 180, 360, 'centre_circle');
    final alpha = math.asin(delta / r) * 180 / math.pi;
    arc('FP_PENALTY', cx, y0 + spot, r, alpha, 180 - alpha, 'penalty_arcs');
    arc('FP_PENALTY', cx, y1 - spot, r, 180 + alpha, 360 - alpha, 'penalty_arcs');
    for (final (x, y, start) in [(x0, y0, 0), (x1, y0, 90), (x1, y1, 180), (x0, y1, 270)]) {
      arc('FP_CORNER', x, y, cornerR, start, start + 90, 'corner_arcs');
    }
    // Spot symbols are drafting references, not paint quantities. The halfway line already crosses the centre spot.
    final spotSize = math.min(80.0, math.min(centreR, math.min(r, math.min(spot - gd, bd - spot))) / 4);
    for (final y in [y0 + spot, cy, y1 - spot]) {
      if (y != cy) line('FP_SPOT', cx - spotSize, y, cx + spotSize, y);
      line('FP_SPOT', cx, y - spotSize, cx, y + spotSize);
    }
    final t = (math.max(pw, pd) / 98).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    mark('ANNOTATIONS', pw / 2, pd + 4 * t, 'MEASURED FOOTBALL PITCH / PLAN / LOCAL MM', t);
    mark('ANNOTATIONS', pw / 2, pd + 2.5 * t, 'PITCH ${_m(w)} x ${_m(l)} M / RUN-OFF ENVELOPE ${_m(width)} x ${_m(depth)} M', .64 * t);
    num minX = 0, maxX = nx, maxY = pd;
    for (final label in labels) {
      final half = label.height * label.text.length * .43;
      minX = math.min(minX, label.at.x - half);
      maxX = math.max(maxX, label.at.x + half);
      maxY = math.max(maxY, label.at.y + label.height);
    }
    final drawing = FloorPlanCad.fromEntities(bounds: PlanRect((minX - 2 * t).floor(), (-2 * t).floor(),
      (maxX + 2 * t).ceil(), (maxY + 2 * t).ceil()), lines: lines, arcs: arcs, labels: labels);
    return FootballPitchCadResult(drawing: drawing, widthMm: width, depthMm: depth, markingMm: Map.unmodifiable(totals));
  }
}
