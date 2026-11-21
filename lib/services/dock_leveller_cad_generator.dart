import 'dart:math' as math;

import '../data/dock_leveller_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class DockLevellerCadResult {
  const DockLevellerCadResult({this.plan, this.section, this.issue, this.widthMm = 0, this.depthMm = 0,
    this.minOverlapMm = 0, this.maxOverlapMm = 0, this.jointGapMm = 0, this.maxGrade = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int widthMm, depthMm;
  final double minOverlapMm, maxOverlapMm, jointGapMm, maxGrade;
}

/// Static, zero-thickness geometry: hinged main deck plus a horizontal articulated lip.
class DockLevellerCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == dockLevellerMode;

  DockLevellerCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    DockLevellerCadResult stop(String issue) => DockLevellerCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion ||
        req.version != requirementsSchemaVersion || !dockLevellerCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select General Warehouse or Distribution Centre and save the current dock leveller brief.');
    }
    if (!const {null, 'open_storage', 'rack_storage'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement, Open Storage or Rack Storage with an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) > 1 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one dock bay only. Remove extra floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    double? scalar(Object? v, {num min = .001, num max = 100}) =>
        v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    int? mm(Object? v, {num min = .001, num max = 100}) {
      final value = scalar(v, min: min, max: max);
      return value == null ? null : (value * 1000).round();
    }
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final hinge = mm(a['dl_hinge'], max: 20), low = mm(a['dl_low'], min: 0, max: 20), high = mm(a['dl_high'], min: 0, max: 20);
    final deck = mm(a['dl_deck'], max: 30), lip = mm(a['dl_lip'], max: 10), gap = mm(a['dl_gap']), landing = mm(a['dl_landing']);
    final minOverlap = mm(a['dl_overlap'], max: 10), minJointGap = mm(a['dl_joint']), gradeCap = scalar(a['dl_grade'], max: 200);
    final deckW = mm(a['dl_deck_w']), bedW = mm(a['dl_bed_w']), side = mm(a['dl_side']), inside = mm(a['dl_inside']);
    final west = mm(a['dl_west'], min: 0, max: 2000), south = mm(a['dl_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || hinge == null || low == null || high == null ||
        deck == null || lip == null || gap == null || landing == null || minOverlap == null || minJointGap == null || gradeCap == null ||
        deckW == null || bedW == null || side == null || inside == null || west == null || south == null) {
      return stop('Enter valid plot, deck, truck landing, service reserve and limit dimensions.');
    }
    if (low > high) return stop('The lowest truck-bed elevation must not exceed the highest.');
    if (deckW > bedW) return stop('The usable centred truck landing is narrower than the deck and lip.');
    final farDelta = math.max((low - hinge).abs(), (high - hinge).abs());
    if (farDelta >= deck) return stop('The main deck cannot have a positive horizontal run at every submitted truck-bed height.');
    double reach(int elev) => math.sqrt(deck * deck - (elev - hinge) * (elev - hinge));
    final nearestElev = hinge.clamp(low, high).toInt();
    final shortRun = math.min(reach(low), reach(high)), longRun = reach(nearestElev);
    final grade = 100 * farDelta / shortRun;
    final overlapLo = shortRun + lip - gap, overlapHi = longRun + lip - gap, jointGap = gap - longRun;
    const eps = 1e-8;
    if (grade > gradeCap + eps) return stop('The main-deck grade exceeds its submitted maximum at a truck-bed height limit.');
    if (jointGap + eps < minJointGap) return stop('The lip joint comes too close to the truck rear edge at maximum reach.');
    if (overlapLo + eps < minOverlap) return stop('The lip has less than the submitted minimum overlap at a truck-bed height limit.');
    if (overlapHi > landing + eps) return stop('The lip tip exceeds the usable truck-bed landing depth at maximum reach.');
    final width = bedW + 2 * side, depth = inside + gap + landing;
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The full dock-bay envelope conflicts with the $edge plot edge or supplied setback.');
    }

    final plan = _Sheet(), section = _Sheet();
    final centre = west + width / 2, pinY = south + gap + landing, bedRearY = south + landing;
    final deckL = centre - deckW / 2, deckR = centre + deckW / 2;
    final bedL = west + side, bedR = west + width - side;
    plan.box('DL_PLOT', 0, 0, pw, pd);
    plan.box('DL_RESERVE', west, south, west + width, south + depth);
    // The landing's far edge is on the envelope boundary; don't overdraw it.
    plan.line('DL_LANDING', bedL, south, bedL, bedRearY);
    plan.line('DL_LANDING', bedL, bedRearY, bedR, bedRearY);
    plan.line('DL_LANDING', bedR, bedRearY, bedR, south);
    plan.box('DL_DECK', deckL, pinY - longRun, deckR, pinY);
    final tipHiY = pinY - longRun - lip, tipLoY = pinY - shortRun - lip;
    for (final x in [deckL, deckR]) {
      // If widths match, the overlap edges already belong to the landing outline.
      plan.line('DL_LIP', x, deckW == bedW ? bedRearY : tipHiY, x, pinY - longRun);
    }
    if (overlapHi < landing - eps) plan.line('DL_LIP', deckL, tipHiY, deckR, tipHiY);
    if (longRun - shortRun > eps) plan.line('DL_SHORT', deckL, tipLoY, deckR, tipLoY);
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    plan.line('DL_CUT', centre, south, centre, south + depth);
    plan.mark('DL_CUT', centre, south - t, 'A', .65 * t);
    plan.mark('DL_CUT', centre, south + depth + t, 'A', .65 * t);
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED SOUTH-FACING DOCK LEVELLER / PLAN / LOCAL MM',
      'FULL ENVELOPE ${_m(width)} x ${_m(depth)} M / LIP OVERLAP ${_m(overlapLo)} TO ${_m(overlapHi)} M',
    ]);

    section.line('DL_RESERVE', -inside, hinge, 0, hinge);
    final st = (math.max(depth, math.max(hinge, high)) / 95).clamp(20, 12000).toDouble();
    for (final elev in <int>{low, nearestElev, high}) {
      final run = reach(elev), tip = run + lip;
      section.line('DL_DECK', 0, hinge, run, elev);
      section.line('DL_LIP', run, elev, tip, elev);
      // The lip itself covers the shared bed segment from the rear edge to its tip.
      if (gap + landing - tip > eps) section.line('DL_LANDING', tip, elev, gap + landing, elev);
      section.line('DL_LANDING', gap, elev, gap, elev - st / 2);
    }
    section.heading(depth / 2 - inside, math.max(hinge, high), st, [
      'TRUE-SCALE SECTION A-A / NORTH TO SOUTH / HINGE AT X = 0 / MM',
      'BED LEVELS ${_m(low)} TO ${_m(high)} M / MAX GRADE ${grade.toStringAsFixed(3)}%',
      'LIP OVERLAP ${_m(overlapLo)} TO ${_m(overlapHi)} M / MIN JOINT GAP ${_m(jointGap)} M',
    ]);
    return DockLevellerCadResult(plan: plan.drawing(t), section: section.drawing(st), widthMm: width, depthMm: depth,
      minOverlapMm: overlapLo, maxOverlapMm: overlapHi, jointGapMm: jointGap, maxGrade: grade);
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
