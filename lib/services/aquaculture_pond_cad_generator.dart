import 'dart:math' as math;

import '../data/aquaculture_pond_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class AquaculturePondCadResult {
  const AquaculturePondCadResult({this.plan, this.section, this.issue, this.widthMm = 0,
    this.depthMm = 0, this.freeMm = 0, this.volumeM3 = 0, this.surfaceM2 = 0, this.slopeH = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int widthMm, depthMm, freeMm;
  final double volumeM3, surfaceM2, slopeH;
}

/// A level-bottom pond with rectangular slices and identical straight slopes on all sides.
class AquaculturePondCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == aquaculturePondMode;

  AquaculturePondCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    AquaculturePondCadResult stop(String issue) => AquaculturePondCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion ||
        req.version != requirementsSchemaVersion || !aquaculturePondCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Fish Farm/Aquaculture and save the current measured pond brief.');
    }
    if (!const {null, 'production_site'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Production Site and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one open pond only. Remove floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    double? scalar(Object? v, {num min = .001, num max = 150}) =>
        v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    int? mm(Object? v, {num min = .001, num max = 150}) {
      final value = scalar(v, min: min, max: max);
      return value == null ? null : (value * 1000).round();
    }
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final w = mm(a['aqp_w']), l = mm(a['aqp_l']), run = mm(a['aqp_run']);
    final rise = mm(a['aqp_rise'], max: 30), water = mm(a['aqp_water'], max: 30);
    final minSlope = scalar(a['aqp_min_slope'], max: 100), minFree = mm(a['aqp_free'], max: 30);
    final reserve = mm(a['aqp_reserve']);
    final west = mm(a['aqp_west'], min: 0, max: 2000), south = mm(a['aqp_south'], min: 0, max: 2000);
    final target = scalar(a['aqp_min_vol'], max: 6075000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || w == null || l == null ||
        run == null || rise == null || water == null || minSlope == null || minFree == null || reserve == null ||
        west == null || south == null || target == null) {
      return stop('Enter valid plot, pond, water level, service reserve and limit dimensions.');
    }
    final free = rise - water;
    if (free <= 0) return stop('The water level must be strictly below the pond rim.');
    if (free < minFree) return stop('The water level leaves less than the submitted freeboard.');
    final slope = run / rise;
    if (slope + 1e-12 < minSlope) return stop('The side slope is steeper than the submitted minimum horizontal run per metre of rise.');
    final width = w + 2 * (run + reserve), depth = l + 2 * (run + reserve);
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The full pond and service envelope conflicts with the $edge plot edge or supplied setback.');
    }

    // Each rectangular slice grows by the same horizontal offset on all sides;
    // area is quadratic in height, so the prismoidal rule integrates it exactly.
    final spread = run * water / rise;
    final surface = (w + 2 * spread) * (l + 2 * spread);
    final middle = (w + spread) * (l + spread);
    final volume = water * (w * l + 4 * middle + surface) / 6e9;
    if (volume + math.max(1e-9, volume * 1e-15) < target) {
      return stop('Geometric water volume is ${volume.toStringAsFixed(6)} m³, below the submitted minimum.');
    }

    final plan = _Sheet(), section = _Sheet();
    final inset = reserve + run;
    void rectangleAt(String layer, num margin) =>
        plan.box(layer, west + margin, south + margin, west + width - margin, south + depth - margin);
    plan.box('AQP_PLOT', 0, 0, pw, pd);
    rectangleAt('AQP_RESERVE', 0);
    rectangleAt('AQP_RIM', reserve);
    rectangleAt('AQP_WATER', inset - spread);
    rectangleAt('AQP_TOE', inset);
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t, cy = south + depth / 2;
    plan.line('AQP_CUT', west, cy, west + width, cy);
    plan.mark('AQP_CUT', west - t, cy, 'A', .65 * t);
    plan.mark('AQP_CUT', west + width + t, cy, 'A', .65 * t);
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED AQUACULTURE POND / PLAN / LOCAL MM',
      'FULL ENVELOPE ${_m(width)} x ${_m(depth)} M / WATER SURFACE ${(surface / 1e6).toStringAsFixed(3)} M2',
    ]);

    section.line('AQP_RESERVE', 0, rise, reserve, rise);
    section.line('AQP_RIM', reserve, rise, inset, 0);
    section.line('AQP_TOE', inset, 0, width - inset, 0);
    section.line('AQP_RIM', width - inset, 0, width - reserve, rise);
    section.line('AQP_RESERVE', width - reserve, rise, width, rise);
    section.line('AQP_WATER', inset - spread, water, width - inset + spread, water);
    final st = (math.max(width, rise) / 95).clamp(20, 12000).toDouble();
    section.heading(width / 2, rise, st, [
      'TRUE-SCALE SECTION A-A / WEST TO EAST / POND BOTTOM = ZERO / MM',
      'SLOPE ${slope.toStringAsFixed(3)}H:1V / WATER DEPTH ${_m(water)} M / FREEBOARD ${_m(free)} M',
      'GEOMETRIC WATER VOLUME ${volume.toStringAsFixed(3)} M3 / NO HYDRAULIC MODEL',
    ]);
    return AquaculturePondCadResult(plan: plan.drawing(t), section: section.drawing(st), widthMm: width,
      depthMm: depth, freeMm: free, volumeM3: volume, surfaceM2: surface / 1e6, slopeH: slope);
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
