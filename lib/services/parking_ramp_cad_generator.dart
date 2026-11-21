import 'dart:math' as math;

import '../data/parking_ramp_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class ParkingRampCadResult {
  const ParkingRampCadResult({this.plan, this.profile, this.issue, this.widthMm = 0, this.depthMm = 0,
    this.grade = 0, this.change = 0, this.headMm = 0, this.stationMm = 0});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final int widthMm, depthMm, stationMm;
  final double grade, change, headMm;
}

/// Straight floor envelope and centreline overhead clearance, not a vehicle swept test.
class ParkingRampCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == parkingRampMode;

  ParkingRampCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    ParkingRampCadResult stop(String issue) => ParkingRampCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !parkingRampCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Parking Structure and save the current measured ramp brief.');
    }
    if (!const {null, 'linear_corridor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use no arrangement or Linear Corridor and choose New Design, Concept Design or Feasibility Study.');
    }
    if (brief.floorCount != null || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one ramp strip only. Leave building floors, separate parking and Space selections empty.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    double? n(Object? v, {num min = .001, num max = 200}) => v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    int? mm(Object? v, {num min = .001, num max = 200}) {
      final numV = n(v, min: min, max: max);
      return numV == null ? null : (1000 * numV).round();
    }
    final a = req.answers;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final rise = mm(a['vk_rise'], max: 50), run = mm(a['vk_run']), trans = mm(a['vk_trans']);
    final lower = mm(a['vk_lower']), upper = mm(a['vk_upper']), clear = mm(a['vk_width'], max: 30), edge = mm(a['vk_edge'], min: 0, max: 20);
    final maxGrade = n(a['vk_max_grade'], max: 100), maxChange = n(a['vk_max_break'], max: 100);
    final s = mm(a['vk_oh_start'], min: 0, max: 600), e = mm(a['vk_oh_end'], max: 600);
    final z0 = mm(a['vk_oh_z0'], max: 100), z1 = mm(a['vk_oh_z1'], max: 100), head = mm(a['vk_head'], max: 30);
    final west = mm(a['vk_west'], min: 0, max: 2000), south = mm(a['vk_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || rise == null || run == null || trans == null || lower == null ||
        upper == null || clear == null || edge == null || maxGrade == null || maxChange == null || s == null || e == null || z0 == null ||
        z1 == null || head == null || west == null || south == null) {
      return stop('Enter valid plot, ramp, landing, grade limit and soffit dimensions.');
    }
    if (2 * trans >= run) return stop('The two transitions must leave a positive length of main ramp.');
    final width = clear + edge * 2, depth = lower + run + upper;
    if (e <= s || e > depth) return stop('The soffit interval must have positive length and fit within the ramp and landings.');
    // Both transitions run at half of the main grade, therefore total rise = grade * (run - trans).
    final effectiveRun = run - trans;
    final grade = 100 * rise / effectiveRun;
    final change = grade / 2;
    if (grade > maxGrade + 1e-10) return stop('Main ramp grade is ${grade.toStringAsFixed(3)}%, above the submitted limit.');
    if (change > maxChange + 1e-10) return stop('Grade changes by ${change.toStringAsFixed(3)} percentage points at each break, above the submitted limit.');
    for (final (side, gap) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${side}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || gap < min) return stop('The full ramp envelope conflicts with the $side plot edge or supplied setback.');
    }
    final p1 = lower, p2 = lower + trans, p3 = lower + run - trans, p4 = lower + run;
    final z2 = rise * trans / (2 * effectiveRun), z3 = rise - z2;
    double floor(int ch) {
      if (ch <= p1) return 0;
      if (ch <= p2) return rise * (ch - p1) / (2 * effectiveRun);
      if (ch <= p3) return z2 + rise * (ch - p2) / effectiveRun;
      if (ch < p4) return rise.toDouble() - rise * (p4 - ch) / (2 * effectiveRun);
      return rise.toDouble();
    }
    double soffit(int ch) => z0.toDouble() + (z1 - z0) * (ch - s) / (e - s);
    final checkpoints = [s, for (final ch in [p1, p2, p3, p4]) if (ch > s && ch < e) ch, e];
    var station = s, minHead = double.infinity;
    for (final ch in checkpoints) {
      final gap = soffit(ch) - floor(ch);
      if (gap < minHead - 1e-8) {
        minHead = gap;
        station = ch;
      }
    }
    if (minHead < head - 1e-8) return stop('Vertical headroom at Ch ${_m(station)} m is ${_m(minHead)} m, below the submitted minimum.');
    final plan = _Sheet(), profile = _Sheet();
    plan.box('VK_PLOT', 0, 0, pw, pd);
    plan.box('VK_DRIVE', west, south, west + width, south + depth);
    if (edge > 0) {
      for (final offset in [edge, width - edge]) {
        plan.line('VK_EDGE', west + offset, south, west + offset, south + depth);
      }
    }
    for (final ch in [p1, p2, p3, p4]) {
      plan.line('VK_BREAK', west + edge, south + ch, west + width - edge, south + ch);
    }
    final t = (math.max(pw, pd) / 93).clamp(20, 12000).toDouble(), cx = west + width / 2;
    // The overhead interval is drawn outside the ramp strip, to keep its grade breaks readable.
    final ox = west + width + .65 * t;
    plan.line('VK_SOFFIT', ox, south + s, ox, south + e);
    for (final ch in [s, e]) {
      plan.line('VK_SOFFIT', ox - .25 * t, south + ch, ox + .25 * t, south + ch);
    }
    final size = math.min(clear / 4, (p3 - p2) / 6);
    final arrowY = south + (p2 + p3) / 2 + (p3 - p2) / 4;
    plan.line('VK_ARROW', cx, south + (p2 + p3) / 2 - (p3 - p2) / 4, cx, arrowY);
    plan.line('VK_ARROW', cx - size / 2, arrowY - size, cx, arrowY);
    plan.line('VK_ARROW', cx + size / 2, arrowY - size, cx, arrowY);
    final nx = math.max(pw + 2.5 * t, ox + 2 * t);
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.labels.add(CadLabel('ANNOTATIONS', CadPoint(nx, pd + t), 'N', .65 * t));
    plan.labels.add(CadLabel('VK_SOFFIT', CadPoint(ox + .8 * t, south + (s + e) / 2), 'SOFFIT SPAN', .55 * t));
    plan.heading(pw / 2, pd, t, [
      'MEASURED STRAIGHT PARKING RAMP / PLAN / LOCAL MM',
      'SOUTH LOWER LANDING TO NORTH UPPER LANDING / ${_m(clear)} M CLEAR',
      'TOTAL ENVELOPE ${_m(width)} x ${_m(depth)} M / RAMP STRIP ONLY',
    ]);
    final knots = [(0, 0), (p1, 0), (p2, z2), (p3, z3), (p4, rise), (depth, rise)];
    for (var i = 1; i < knots.length; i++) {
      final (x, y) = knots[i - 1];
      final (ex, ey) = knots[i];
      profile.line('VK_DRIVE', x, y, ex, ey);
    }
    profile.line('VK_SOFFIT', s, z0, e, z1);
    profile.line('VK_HEAD', station, floor(station), station, soffit(station));
    final high = math.max(rise, math.max(z0, z1));
    final st = (math.max(depth, high) / 90).clamp(20, 12000).toDouble();
    profile.heading(depth / 2, high, st, [
      'TRUE-SCALE LONGITUDINAL PROFILE / LOCAL MM / LOWER LANDING = ZERO',
      'MAIN ${grade.toStringAsFixed(3)}% / TRANSITIONS ${change.toStringAsFixed(3)}% / GRADE BREAKS ${change.toStringAsFixed(3)} PP',
      'MIN HEADROOM ${_m(minHead)} M AT CH ${_m(station)} M / VERTICAL CENTRELINE ONLY',
    ]);
    return ParkingRampCadResult(plan: plan.drawing(t), profile: profile.drawing(st), widthMm: width, depthMm: depth,
      grade: grade, change: change, headMm: minHead, stationMm: station);
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
