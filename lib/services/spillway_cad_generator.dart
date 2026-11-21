import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/spillway_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);
String _p(double rate) => '${rate.toStringAsFixed(3)}%';

class SpillwayCadResult {
  const SpillwayCadResult({this.plan, this.profile, this.issue, this.widthMm = 0, this.depthMm = 0,
    this.toeMm = 0, this.inletGrade = 0, this.chuteGrade = 0, this.inletTaper = 0, this.chuteTaper = 0});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final int widthMm, depthMm, toeMm;
  final double inletGrade, chuteGrade, inletTaper, chuteTaper;
}

/// Symmetric centreline and clear plan outline only, without hydraulic sizing.
class SpillwayCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == spillwayMode;

  SpillwayCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    SpillwayCadResult stop(String issue) => SpillwayCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !spillwayCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Flood-Control Structure and save the current spillway brief.');
    }
    if (!const {null, 'drainage_system'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Drainage System and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use an open spillway only. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    double? n(Object? v, {num min = .001, num max = 200}) =>
        v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    int? mm(Object? v, {num min = .001, num max = 200}) {
      final value = n(v, min: min, max: max);
      return value == null ? null : (1000 * value).round();
    }
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final inlet = mm(a['sp_in_w']), throat = mm(a['sp_throat']), outlet = mm(a['sp_out_w']);
    final approach = mm(a['sp_in_l']), crest = mm(a['sp_crest_l']), minCrest = mm(a['sp_min_crest']);
    final chute = mm(a['sp_chute_l']), apron = mm(a['sp_apron_l']);
    final rise = mm(a['sp_rise'], max: 50), drop = mm(a['sp_drop'], max: 50);
    final maxInlet = n(a['sp_in_max']), maxChute = n(a['sp_chute_max']), maxTaper = n(a['sp_taper_max'], min: 0);
    final reserve = mm(a['sp_reserve'], min: 0, max: 50);
    final west = mm(a['sp_west'], min: 0, max: 2000), south = mm(a['sp_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || inlet == null || throat == null || outlet == null ||
        approach == null || crest == null || minCrest == null || chute == null || apron == null || rise == null || drop == null ||
        maxInlet == null || maxChute == null || maxTaper == null || reserve == null || west == null || south == null) {
      return stop('Enter valid plot, spillway widths, horizontal runs, bed levels and geometric limits.');
    }
    if (inlet < throat || outlet < throat) return stop('The inlet and outlet must each be at least as wide as the crest throat.');
    if (crest < minCrest) return stop('The flat crest is shorter than the submitted minimum.');
    final inGrade = 100 * rise / approach, chuteGrade = 100 * drop / chute;
    final inTaper = 50 * (inlet - throat) / approach, outTaper = 50 * (outlet - throat) / chute;
    if (inGrade > maxInlet + 1e-10) return stop('Inlet bed grade ${_p(inGrade)} exceeds its submitted limit.');
    if (chuteGrade > maxChute + 1e-10) return stop('Chute bed grade ${_p(chuteGrade)} exceeds its submitted magnitude limit.');
    if (inTaper > maxTaper + 1e-10) return stop('Inlet edge taper ${_p(inTaper)} exceeds the submitted limit.');
    if (outTaper > maxTaper + 1e-10) return stop('Chute edge taper ${_p(outTaper)} exceeds the submitted limit.');
    final endCrest = approach + crest, toeCh = endCrest + chute, length = toeCh + apron;
    final width = math.max(inlet, outlet) + 2 * reserve, depth = length + 2 * reserve;
    for (final (side, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${side}_setback'];
      final minimum = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (minimum == null || available < minimum) return stop('The full spillway envelope conflicts with the $side plot edge or supplied setback.');
    }

    final plan = _Sheet(), profile = _Sheet();
    plan.box('SP_PLOT', 0, 0, pw, pd);
    plan.box('SP_RESERVE', west, south, west + width, south + depth);
    final cx = west + width / 2, planStart = south + reserve, zToe = rise - drop;
    final knots = [(0, inlet, 0), (approach, throat, rise), (endCrest, throat, rise), (toeCh, outlet, zToe), (length, outlet, zToe)];
    final layers = ['SP_INLET', 'SP_CREST', 'SP_CHUTE', 'SP_APRON'];
    for (var i = 1; i < knots.length; i++) {
      final (ch, w, z) = knots[i - 1];
      final (next, nextW, nextZ) = knots[i];
      final layer = layers[i - 1];
      for (final side in [-1, 1]) {
        plan.line(layer, cx + side * w / 2, planStart + ch, cx + side * nextW / 2, planStart + next);
      }
      profile.line(layer, ch, z, next, nextZ);
    }
    for (final (ch, w, _) in knots) {
      plan.line('SP_STATION', cx - w / 2, planStart + ch, cx + w / 2, planStart + ch);
    }
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - .5 * t, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + .5 * t, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED FLOOD SPILLWAY / PLAN / LOCAL MM / SOUTH INLET TO NORTH APRON',
      'CLEAR WIDTHS ${_m(inlet)} / ${_m(throat)} / ${_m(outlet)} M / ENVELOPE ${_m(width)} x ${_m(depth)} M',
      'EDGE TAPERS: INLET ${_p(inTaper)} / CHUTE ${_p(outTaper)} / NO HYDRAULIC SIZING',
    ]);
    final st = (math.max(length, math.max(rise, drop)) / 93).clamp(20, 12000).toDouble();
    profile.heading(length / 2, rise, st, [
      'TRUE-SCALE LONGITUDINAL BED PROFILE / LOCAL MM / INLET DATUM = ZERO',
      'INLET +${_p(inGrade)} / CREST ${_m(crest)} M LEVEL / CHUTE -${_p(chuteGrade)} / APRON LEVEL',
      'CREST LEVEL +${_m(rise)} M / TOE AND APRON LEVEL ${_m(zToe)} M RELATIVE TO INLET',
    ]);
    return SpillwayCadResult(plan: plan.drawing(t), profile: profile.drawing(st), widthMm: width, depthMm: depth,
      toeMm: zToe, inletGrade: inGrade, chuteGrade: chuteGrade, inletTaper: inTaper, chuteTaper: outTaper);
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
