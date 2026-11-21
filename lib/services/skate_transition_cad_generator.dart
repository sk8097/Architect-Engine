import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/skate_transition_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class SkateTransitionCadResult {
  const SkateTransitionCadResult({this.plan, this.profile, this.issue, this.widthMm = 0, this.depthMm = 0,
    this.riseMm = 0, this.curveRunMm = 0, this.curveLengthMm = 0, this.lipAngle = 0});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final int widthMm, riseMm;
  final double depthMm, curveRunMm, curveLengthMm, lipAngle;
}

/// One circular transition tangent at the toe. Not a skate facility design or safety check.
class SkateTransitionCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == skateTransitionMode;

  SkateTransitionCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    SkateTransitionCadResult stop(String issue) => SkateTransitionCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !skateTransitionCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Public Park or Playground and save the current skate transition brief.');
    }
    if (!const {null, 'public_open_space'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Public Open Space and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor transition only. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 100}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final r = mm(a['st_r'], max: 50), h = mm(a['st_rise'], max: 50), maxAngle = a['st_angle'];
    final surface = mm(a['st_width']), approach = mm(a['st_runin']), minApproach = mm(a['st_min_runin']);
    final deck = mm(a['st_deck']), minDeck = mm(a['st_min_deck']);
    final side = mm(a['st_side']), end = mm(a['st_end']);
    final west = mm(a['st_west'], min: 0, max: 2000), south = mm(a['st_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || r == null || h == null ||
        maxAngle is! num || !maxAngle.isFinite || maxAngle < .001 || maxAngle > 90 || surface == null || approach == null ||
        minApproach == null || deck == null || minDeck == null || side == null || end == null || west == null || south == null) {
      return stop('Enter valid plot, transition, run-in, deck, reserve and limit dimensions.');
    }
    if (h > r) return stop('Lip rise cannot exceed the radius in this non-overhanging transition.');
    if (approach < minApproach || deck < minDeck) return stop('Increase the flat run-in or deck length to meet its submitted minimum.');
    final run = math.sqrt(h * (2 * r - h));
    final theta = math.atan2(run, r - h);
    final angle = theta * 180 / math.pi, length = r * theta;
    if (angle > maxAngle + 1e-10) return stop('The lip tangent angle is ${angle.toStringAsFixed(6)} degrees, above the submitted limit.');
    final fullWidth = surface + 2 * side, fullDepth = approach + run + deck + 2 * end;
    for (final (edge, available) in [('left', west), ('right', pw - west - fullWidth), ('front', south), ('rear', pd - south - fullDepth)]) {
      final raw = a['${edge}_setback'];
      final minimum = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (minimum == null || available < minimum - 1e-8) return stop('The full transition and reserve envelope conflict with the $edge plot edge or supplied setback.');
    }

    final plan = _Sheet(), profile = _Sheet();
    final x0 = west + side, x1 = x0 + surface, y0 = south + end, yToe = y0 + approach, yLip = yToe + run;
    final y1 = yLip + deck, cx = (x0 + x1) / 2;
    plan.box('ST_PLOT', 0, 0, pw, pd);
    plan.box('ST_RESERVE', west, south, west + fullWidth, south + fullDepth);
    plan.line('ST_FLAT', x0, y0, x1, y0);
    plan.line('ST_DECK', x0, y1, x1, y1);
    for (final x in [x0, x1]) {
      plan.line('ST_FLAT', x, y0, x, yToe);
      plan.line('ST_CURVE', x, yToe, x, yLip);
      plan.line('ST_DECK', x, yLip, x, y1);
    }
    plan.line('ST_BREAK', x0, yToe, x1, yToe);
    plan.line('ST_BREAK', x0, yLip, x1, yLip);
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    plan.mark('ST_FLAT', cx, (y0 + yToe) / 2, 'RUN-IN', math.min(.65 * t, surface / 8));
    plan.mark('ST_CURVE', cx, (yToe + yLip) / 2, 'TRANSITION', math.min(.65 * t, surface / 12));
    plan.mark('ST_DECK', cx, (yLip + y1) / 2, 'DECK', math.min(.65 * t, surface / 6));
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED SKATE TRANSITION / PLAN / LOCAL MM / SOUTH RUN-IN TO NORTH DECK',
      'FULL RESERVE ENVELOPE ${_m(fullWidth)} x ${_m(fullDepth)} M / CLEAR SURFACE ${_m(surface)} M WIDE',
    ]);

    final lip = approach + run, fullRun = lip + deck;
    profile.line('ST_FLAT', 0, 0, approach, 0);
    final arc = CadArc('ST_CURVE', CadPoint(approach, r), r, 270, 270 + angle);
    profile.line('ST_DECK', lip, h, fullRun, h);
    final st = (math.max(fullRun, h) / 90).clamp(20, 12000).toDouble();
    profile.heading(fullRun / 2, h, st, [
      'TRUE-SCALE LONGITUDINAL PROFILE / LOCAL MM / FLAT RUN-IN = ZERO',
      'RADIUS ${_m(r)} M / RISE ${_m(h)} M / LIP TANGENT ${angle.toStringAsFixed(3)} DEG',
      'HORIZONTAL CURVE RUN ${_m(run)} M / ARC LENGTH ${_m(length)} M / NO COPING DETAIL',
    ]);
    return SkateTransitionCadResult(plan: plan.drawing(t), profile: profile.drawing(st, arcs: [arc]), widthMm: fullWidth,
      depthMm: fullDepth, riseMm: h, curveRunMm: run, curveLengthMm: length, lipAngle: angle);
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
  void mark(String layer, num x, num y, String text, num height) => labels.add(CadLabel(layer, CadPoint(x, y), text, height));
  void heading(num x, num y, double t, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      labels.add(CadLabel('ANNOTATIONS', CadPoint(x, y + (rows.length - i + .5) * 1.3 * t), rows[i], i == 0 ? t : .62 * t));
    }
  }
  FloorPlanCad drawing(double t, {List<CadArc> arcs = const []}) {
    final pts = [for (final l in lines) ...[l.start, l.end], for (final l in labels) ...[
      CadPoint(l.at.x - l.height * l.text.length * .42, l.at.y - l.height),
      CadPoint(l.at.x + l.height * l.text.length * .42, l.at.y + l.height),
    ]];
    return FloorPlanCad.fromEntities(bounds: PlanRect((pts.map((p) => p.x).reduce(math.min) - 3 * t).floor(),
      (pts.map((p) => p.y).reduce(math.min) - 3 * t).floor(), (pts.map((p) => p.x).reduce(math.max) + 3 * t).ceil(),
      (pts.map((p) => p.y).reduce(math.max) + 3 * t).ceil()), lines: lines, labels: labels, arcs: arcs);
  }
}
