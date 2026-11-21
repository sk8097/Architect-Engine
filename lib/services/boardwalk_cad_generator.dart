import 'dart:math' as math;

import '../data/boardwalk_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm, [int places = 3]) => (mm / 1000).toStringAsFixed(places);

class BoardwalkCadResult {
  const BoardwalkCadResult({this.plan, this.profile, this.issue, this.widthMm = 0, this.depthMm = 0, this.pairs = 0,
    this.pitchMm = 0, this.gapMm = 0, this.criticalMm = 0});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final int widthMm, depthMm, pairs, gapMm, criticalMm;
  final double pitchMm;
}

/// Level deck, geometric support set-out and a three-knot centreline ground profile.
class BoardwalkCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == boardwalkMode;

  BoardwalkCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    BoardwalkCadResult stop(String issue) => BoardwalkCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !boardwalkCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Public Park or Public Garden and save the current boardwalk brief.');
    }
    if (!const {null, 'public_open_space'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Public Open Space and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor boardwalk. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 150}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    int? rl(String key) => mm(a[key], min: -200, max: 10000);
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final length = mm(a['bw_length']), w = mm(a['bw_width']), top = rl('bw_top'), thick = mm(a['bw_thick'], max: 10);
    final z0 = rl('bw_z0'), zm = rl('bw_zm'), z1 = rl('bw_z1'), ch = mm(a['bw_ch']);
    final minClear = mm(a['bw_clear']), first = mm(a['bw_first']), last = mm(a['bw_last']);
    final overhang = mm(a['bw_overhang']), maxSpacing = mm(a['bw_spacing']), post = mm(a['bw_post'], max: 10);
    final inset = mm(a['bw_inset']), reserve = mm(a['bw_reserve']);
    final west = mm(a['bw_west'], min: 0, max: 2000), south = mm(a['bw_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || length == null || w == null || top == null ||
        thick == null || z0 == null || zm == null || z1 == null || ch == null || minClear == null || first == null || last == null ||
        overhang == null || maxSpacing == null || post == null || inset == null || reserve == null || west == null || south == null) {
      return stop('Enter valid plot, deck, ground elevations, support geometry and limits.');
    }
    if (ch >= length) return stop('Place the interior ground break strictly inside the deck length.');
    final soffit = top - thick, high = math.max(z0, math.max(zm, z1));
    final critical = high == z0 ? 0 : high == zm ? ch : length;
    final gap = soffit - high;
    if (gap < minClear) return stop('Soffit-to-ground gap at Ch ${_m(critical)} m is ${_m(gap)} m, below the submitted minimum.');
    if (math.max(first, last) > overhang) return stop('An end overhang exceeds the submitted centreline limit.');
    final between = length - first - last;
    if (between <= 0) return stop('Leave a positive interval between the first and last support pairs.');
    if (2 * math.min(first, last) < post || 2 * inset < post || w - 2 * inset <= post) {
      return stop('Fit both support footprints fully under the deck without touching across its width.');
    }
    final bays = (between + maxSpacing - 1) ~/ maxSpacing;
    if (bays >= 100) return stop('The layout exceeds 100 support pairs. Reduce the deck length or revise the submitted pitch limit.');
    if (between <= bays * post) return stop('The pitch limit places adjacent support footprints in contact or overlap.');
    final pitch = between / bays;
    final width = w + 2 * reserve, depth = length + 2 * reserve;
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The full boardwalk and reserve conflict with the $edge plot edge or supplied setback.');
    }

    final plan = _Sheet(), profile = _Sheet();
    final x0 = west + reserve, x1 = x0 + w, y0 = south + reserve;
    plan.box('BW_PLOT', 0, 0, pw, pd);
    plan.box('BW_RESERVE', west, south, west + width, south + depth);
    plan.box('BW_DECK', x0, y0, x1, y0 + length);
    final datum = math.min(z0, math.min(zm, z1)), half = post / 2;
    double ground(double x) => x <= ch
        ? (z0 - datum) + (zm - z0) * x / ch
        : (zm - datum) + (z1 - zm) * (x - ch) / (length - ch);
    for (var i = 0; i <= bays; i++) {
      final station = first + between * i / bays;
      for (final x in [x0 + inset, x1 - inset]) {
        plan.box('BW_POST', x - half, y0 + station - half, x + half, y0 + station + half);
      }
      // In profile the pair is represented by one centreline; below-grade supports are not modelled.
      profile.line('BW_POST', station, ground(station), station, soffit - datum);
    }
    profile.box('BW_DECK', 0, soffit - datum, length, top - datum);
    profile.line('BW_GROUND', 0, z0 - datum, ch, zm - datum);
    profile.line('BW_GROUND', ch, zm - datum, length, z1 - datum);
    profile.line('BW_GAP', critical, high - datum, critical, soffit - datum);
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED RAISED BOARDWALK / PLAN / LOCAL MM / SOUTH TO NORTH',
      '${bays + 1} SUPPORT PAIRS / PITCH ${_m(pitch)} M / FULL ENVELOPE ${_m(width)} x ${_m(depth)} M',
    ]);
    final st = (math.max(length, top - datum) / 95).clamp(20, 12000).toDouble();
    profile.heading(length / 2, top - datum, st, [
      'TRUE-SCALE CENTRELINE PROFILE / LOCAL MM / SECTION DATUM RL ${_m(datum)} M',
      'DECK TOP RL ${_m(top)} M / SOFFIT RL ${_m(soffit)} M',
      'MIN SOFFIT GAP ${_m(gap)} M AT CH ${_m(critical)} M / SUPPORT CENTRELINES ONLY',
    ]);
    return BoardwalkCadResult(plan: plan.drawing(t), profile: profile.drawing(st), widthMm: width, depthMm: depth,
      pairs: bays + 1, pitchMm: pitch, gapMm: gap, criticalMm: critical);
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
