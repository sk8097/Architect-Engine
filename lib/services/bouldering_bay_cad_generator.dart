import 'dart:math' as math;

import '../data/bouldering_bay_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class BoulderingBayCadResult {
  const BoulderingBayCadResult({this.plan, this.section, this.issue, this.heightMm = 0, this.lipGapMm = 0,
    this.matBeyondMm = 0, this.angle = 0, this.panelM2 = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int heightMm, lipGapMm, matBeyondMm;
  final double angle, panelM2;
}

/// One measured climbing surface and reserved clear rectangles, not a safety or construction model.
class BoulderingBayCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == boulderingBayMode;

  BoulderingBayCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    BoulderingBayCadResult stop(String issue) => BoulderingBayCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !boulderingBayCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select an eligible indoor sports facility and save the current bouldering bay brief.');
    }
    if (!const {null, 'indoor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank setting or Indoor and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 1) != 1 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one ground-floor hall only. Remove separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 100}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final hw = mm(a['bb_hall_w']), hl = mm(a['bb_hall_l']), hh = mm(a['bb_hall_h'], max: 30);
    final wall = mm(a['bb_wall_w']), lower = mm(a['bb_lower'], max: 30), upper = mm(a['bb_upper'], max: 30);
    final projection = mm(a['bb_throw']), maxAngle = a['bb_max_angle'], minAbove = mm(a['bb_above']);
    final mat = mm(a['bb_mat']), minBeyond = mm(a['bb_beyond']), side = mm(a['bb_side']);
    final access = mm(a['bb_access']), rear = mm(a['bb_rear']);
    final west = mm(a['bb_west'], min: 0, max: 2000), south = mm(a['bb_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || hw == null || hl == null || hh == null ||
        wall == null || lower == null || upper == null || projection == null || maxAngle is! num || !maxAngle.isFinite ||
        maxAngle < .001 || maxAngle > 89.999 || minAbove == null || mat == null || minBeyond == null || side == null ||
        access == null || rear == null || west == null || south == null) {
      return stop('Enter valid clear hall, panel, mat, reserve and geometric limit dimensions.');
    }
    final height = lower + upper, lipGap = hh - height, matBeyond = mat - projection;
    final angle = math.atan2(projection, upper) * 180 / math.pi;
    if (angle > maxAngle + 1e-10) return stop('Upper panel angle is ${angle.toStringAsFixed(6)} degrees from vertical, above the submitted limit.');
    if (lipGap < minAbove) return stop('The lip leaves less than the submitted overhead clearance.');
    if (matBeyond < minBeyond) return stop('The mat extension beyond the projected lip is below the submitted minimum.');
    final matWidth = wall + 2 * side;
    if (matWidth > hw) return stop('The mat with both side extensions is wider than the clear hall.');
    if (rear + mat + access > hl) return stop('The rear reserve, mat and south access strip do not fit the clear hall depth.');
    for (final (edge, available) in [('left', west), ('right', pw - west - hw), ('front', south), ('rear', pd - south - hl)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The clear hall footprint conflicts with the $edge plot edge or supplied setback.');
    }
    final panelArea = wall * (lower + math.sqrt(upper * upper + projection * projection)) / 1e6;
    final plan = _Sheet(), section = _Sheet();
    final cx = west + hw / 2, xMat0 = cx - matWidth / 2, xMat1 = cx + matWidth / 2;
    final north = south + hl, foot = north - rear, matEnd = foot - mat, lip = foot - projection;
    plan.box('BB_PLOT', 0, 0, pw, pd);
    plan.box('BB_HALL', west, south, west + hw, north);
    // Draw shared boundaries once when the clear dimensions fit exactly.
    for (final y in [matEnd, foot]) {
      plan.line('BB_MAT', xMat0, y, xMat1, y);
    }
    if (matWidth < hw) {
      for (final x in [xMat0, xMat1]) {
        plan.line('BB_MAT', x, matEnd, x, foot);
        plan.line('BB_ACCESS', x, matEnd, x, matEnd - access);
      }
    }
    if (matEnd - access > south) plan.line('BB_ACCESS', xMat0, matEnd - access, xMat1, matEnd - access);
    final xL = cx - wall / 2, xR = cx + wall / 2;
    for (final x in [xL, xR]) {
      plan.line('BB_PANEL', x, foot, x, lip);
    }
    plan.line('BB_PANEL', xL, lip, xR, lip);
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    plan.line('BB_CUT', cx, south, cx, north);
    plan.mark('BB_CUT', cx, south - t, 'A', .65 * t);
    plan.mark('BB_CUT', cx, north + t, 'A', .65 * t);
    plan.mark('BB_PANEL', cx + wall * .18, (foot + lip) / 2, 'UPPER PANEL PROJECTION', math.min(.6 * t, wall / 25));
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED INDOOR BOULDERING BAY / PLAN / LOCAL MM',
      'CLEAR HALL ${_m(hw)} x ${_m(hl)} M / MAT ${_m(matWidth)} x ${_m(mat)} M / SOUTH FRONT',
    ]);

    final southFace = hl - rear;
    section.box('BB_HALL', -rear, 0, southFace, hh);
    section.line('BB_PANEL', 0, 0, 0, lower);
    section.line('BB_PANEL', 0, lower, projection, height);
    section.line('BB_GAP', projection, height, projection, hh);
    final st = (math.max(hl, hh) / 95).clamp(20, 12000).toDouble();
    // These annotations identify plan lengths without implying mat thickness.
    section.line('BB_MAT', 0, -st, mat, -st);
    section.line('BB_ACCESS', mat, -st, mat + access, -st);
    section.mark('BB_MAT', mat / 2, -2 * st, 'MAT PLAN EXTENT', .6 * st);
    section.mark('BB_ACCESS', mat + access / 2, -2 * st, 'ACCESS', .6 * st);
    section.heading((southFace - rear) / 2, hh, st, [
      'TRUE-SCALE NORTH-SOUTH SECTION A-A / LOCAL MM / FINISHED MAT = ZERO',
      'LIP HEIGHT ${_m(height)} M / OVERHEAD GAP ${_m(lipGap)} M / ANGLE ${angle.toStringAsFixed(3)} DEG FROM VERTICAL',
      'BEYOND LIP ${_m(matBeyond)} M / PANEL SURFACE ${panelArea.toStringAsFixed(3)} M2 / NO MAT THICKNESS DETAIL',
    ]);
    return BoulderingBayCadResult(plan: plan.drawing(t), section: section.drawing(st), heightMm: height,
      lipGapMm: lipGap, matBeyondMm: matBeyond, angle: angle, panelM2: panelArea);
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
