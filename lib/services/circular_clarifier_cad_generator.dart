import 'dart:math' as math;

import '../data/circular_clarifier_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class CircularClarifierCadResult {
  const CircularClarifierCadResult({this.plan, this.section, this.issue, this.diameterMm = 0, this.freeboardMm = 0,
    this.radialClearMm = 0, this.settlingM2 = 0, this.weirM = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int diameterMm, freeboardMm;
  final double radialClearMm, settlingM2, weirM;
}

/// Concentric reference geometry, not a process, weir detail or structure design.
class CircularClarifierCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == circularClarifierMode;

  CircularClarifierCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    CircularClarifierCadResult stop(String issue) => CircularClarifierCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !circularClarifierCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Sewage Treatment Plant and save the current circular clarifier brief.');
    }
    if (!const {null, 'plant'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Plant and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor clarifier only. Remove floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 150}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final inner = mm(a['cc_inside']), wall = mm(a['cc_wall'], max: 10), trough = mm(a['cc_launder']), feed = mm(a['cc_feed']);
    final minClear = mm(a['cc_min_clear']), reserve = mm(a['cc_reserve']);
    final rim = mm(a['cc_rim'], max: 30), water = mm(a['cc_water'], max: 30), freeMin = mm(a['cc_free'], max: 30);
    final troughZ = mm(a['cc_trough_z'], max: 30), lower = mm(a['cc_feed_lower'], max: 30), upper = mm(a['cc_feed_upper'], max: 30);
    final west = mm(a['cc_west'], min: 0, max: 2000), south = mm(a['cc_south'], min: 0, max: 2000);
    final target = a['cc_min_area'];
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || inner == null || wall == null || trough == null ||
        feed == null || minClear == null || reserve == null || rim == null || water == null || freeMin == null || troughZ == null ||
        lower == null || upper == null || west == null || south == null || target is! num || !target.isFinite || target < .001 || target > 20000) {
      return stop('Enter valid plot, basin, launder, feedwell, level and area dimensions.');
    }
    final free = rim - water;
    if (free < freeMin) return stop('The submitted water elevation leaves insufficient freeboard to the basin rim.');
    if (troughZ >= water) return stop('Place the launder bottom below the nominal inner weir elevation.');
    if (lower >= water || upper <= water) return stop('The feedwell lower edge must be below water and its upper edge above water.');
    final insideR = inner / 2, weirR = insideR - trough, feedR = feed / 2;
    final clear = weirR - feedR;
    if (clear < minClear) return stop('The launder and feedwell leave less than the submitted clear radial settling width.');
    final diameter = inner + 2 * (wall + reserve);
    for (final (edge, available) in [('left', west), ('right', pw - west - diameter), ('front', south), ('rear', pd - south - diameter)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The full clarifier service envelope conflicts with the $edge plot edge or supplied setback.');
    }
    final area = math.pi * clear * (weirR + feedR) / 1e6;
    if (area < target - 1e-9) return stop('Annular settling area is ${area.toStringAsFixed(6)} m², below the submitted minimum.');
    final weir = 2 * math.pi * weirR / 1000;
    final plan = _Sheet(), section = _Sheet();
    final middle = diameter / 2, cx = west + middle, cy = south + middle;
    plan.box('CC_PLOT', 0, 0, pw, pd);
    final rings = <CadArc>[];
    for (final (layer, radius) in [('CC_RESERVE', middle), ('CC_WALL', insideR + wall), ('CC_WALL', insideR), ('CC_WEIR', weirR), ('CC_FEED', feedR)]) {
      rings.add(CadArc(layer, CadPoint(cx, cy), radius, 0, 180));
      rings.add(CadArc(layer, CadPoint(cx, cy), radius, 180, 360));
    }
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    plan.line('CC_CUT', west, cy, west + diameter, cy);
    plan.mark('CC_CUT', west - t, cy, 'A', .65 * t);
    plan.mark('CC_CUT', west + diameter + t, cy, 'A', .65 * t);
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED CIRCULAR CLARIFIER / PLAN / LOCAL MM / DIAMETRAL SECTION A-A',
      'SETTLING RING ${area.toStringAsFixed(3)} M2 / NOMINAL WEIR ${weir.toStringAsFixed(3)} M / ENVELOPE DIA ${_m(diameter)} M',
    ]);

    for (final sign in [-1, 1]) {
      final wallIn = middle + sign * insideR, wallOut = middle + sign * (insideR + wall);
      final weirX = middle + sign * weirR, feedX = middle + sign * feedR;
      section.line('CC_WALL', wallOut, 0, wallOut, rim);
      section.line('CC_WALL', wallOut, rim, wallIn, rim);
      section.line('CC_WALL', wallIn, rim, wallIn, 0);
      section.line('CC_RESERVE', middle + sign * middle, 0, wallOut, 0);
      section.line('CC_WEIR', wallIn, troughZ, weirX, troughZ);
      section.line('CC_WEIR', weirX, troughZ, weirX, water);
      section.line('CC_WATER', weirX, water, feedX, water);
      section.line('CC_FEED', feedX, lower, feedX, upper);
    }
    section.line('CC_FLOOR', middle - insideR, 0, middle + insideR, 0);
    final highest = math.max(rim, upper), st = (math.max(diameter, highest) / 90).clamp(20, 12000).toDouble();
    section.heading(middle, highest, st, [
      'SECTION A-A / TRUE SCALE MM / LEVEL BASIN FLOOR = ZERO',
      'WATER AND NOMINAL WEIR +${_m(water)} M / FREEBOARD ${_m(free)} M / CLEAR RING ${_m(clear)} M',
      'FEEDWELL OUTSIDE LIMITS AND LAUNDER SHOWN SCHEMATICALLY / NO CONSTRUCTION DETAIL',
    ]);
    return CircularClarifierCadResult(plan: plan.drawing(t, arcs: rings), section: section.drawing(st), diameterMm: diameter,
      freeboardMm: free, radialClearMm: clear, settlingM2: area, weirM: weir);
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
