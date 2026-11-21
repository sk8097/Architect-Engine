import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/silage_bunker_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class SilageBunkerCadResult {
  const SilageBunkerCadResult({this.plan, this.section, this.issue, this.widthMm = 0, this.depthMm = 0,
    this.freeMm = 0, this.volumeM3 = 0, this.floorGrade = 0, this.faceGrade = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int widthMm, depthMm, freeMm;
  final double volumeM3, floorGrade, faceGrade;
}

/// A geometric fill envelope above a sloping floor, not a silage or structure design.
class SilageBunkerCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == silageBunkerMode;

  SilageBunkerCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    SilageBunkerCadResult stop(String issue) => SilageBunkerCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !silageBunkerCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Dairy Farm or Cattle Farm and save the current silage bunker brief.');
    }
    if (!const {null, 'production_site'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Production Site and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one open bunker only. Remove floors, separate parking and Space selections.');
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
    final w = mm(a['sb_w']), l = mm(a['sb_l']), wall = mm(a['sb_wall'], max: 10);
    final rise = mm(a['sb_rise'], max: 30), fill = mm(a['sb_fill'], max: 30), face = mm(a['sb_face']);
    final maxFloor = scalar(a['sb_floor_max'], max: 100), maxFace = scalar(a['sb_face_max'], max: 500);
    final rim = mm(a['sb_rim'], max: 30), minFree = mm(a['sb_free'], max: 30);
    final apron = mm(a['sb_apron']), reserve = mm(a['sb_reserve']);
    final west = mm(a['sb_west'], min: 0, max: 2000), south = mm(a['sb_south'], min: 0, max: 2000);
    final target = scalar(a['sb_min_vol'], max: 700000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || w == null || l == null || wall == null ||
        rise == null || fill == null || face == null || maxFloor == null || maxFace == null || rim == null || minFree == null ||
        apron == null || reserve == null || west == null || south == null || target == null) {
      return stop('Enter valid plot, bunker, floor, fill face, apron and limit dimensions.');
    }
    if (face >= l) return stop('The rising fill face must end before the rear wall to leave a level crest.');
    if (fill <= rise) return stop('The fill crest elevation must be above the rear floor.');
    final free = rim - fill;
    if (free < minFree) return stop('The fill crest leaves less than the submitted freeboard to the wall top.');
    final floorGrade = 100 * rise / l, faceGrade = 100 * fill / face;
    if (floorGrade > maxFloor + 1e-10) return stop('The floor grade exceeds its submitted maximum.');
    if (faceGrade > maxFace + 1e-10) return stop('The fill-face grade exceeds its submitted maximum.');
    final width = w + 2 * (wall + reserve), depth = apron + l + wall + reserve;
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The full bunker and apron envelope conflicts with the $edge plot edge or supplied setback.');
    }
    // Integrate the top ramp and plateau, then subtract the triangular floor rise.
    final volume = w * (fill * (2 * l - face) - rise * l) / 2e9;
    if (volume < target - 1e-9) return stop('Geometric fill volume is ${volume.toStringAsFixed(6)} m³, below the submitted minimum.');

    final plan = _Sheet(), section = _Sheet();
    final left = west + reserve, right = west + width - reserve, opening = south + apron, back = opening + l;
    plan.box('SB_PLOT', 0, 0, pw, pd);
    plan.box('SB_RESERVE', west, south, west + width, south + depth);
    // The open-front wall outline contains no line across the opening.
    for (final (x, inner) in [(left, left + wall), (right, right - wall)]) {
      plan.line('SB_WALL', x, opening, x, back + wall);
      plan.line('SB_WALL', x, opening, inner, opening);
      plan.line('SB_WALL', inner, opening, inner, back);
    }
    plan.line('SB_WALL', left, back + wall, right, back + wall);
    plan.line('SB_WALL', left + wall, back, right - wall, back);
    plan.line('SB_FACE', left + wall, opening + face, right - wall, opening + face);
    plan.line('SB_APRON', west, opening, left, opening);
    plan.line('SB_APRON', right, opening, west + width, opening);
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t, cx = (left + right) / 2;
    plan.line('SB_CUT', cx, south, cx, south + depth);
    plan.mark('SB_CUT', cx, south - t, 'A', .65 * t);
    plan.mark('SB_CUT', cx, south + depth + t, 'A', .65 * t);
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED SILAGE BUNKER / PLAN / LOCAL MM / SOUTH OPENING',
      'FULL ENVELOPE ${_m(width)} x ${_m(depth)} M / GEOMETRIC FILL ${volume.toStringAsFixed(3)} M3',
    ]);

    section.line('SB_APRON', -apron, 0, 0, 0);
    section.line('SB_FLOOR', 0, 0, l, rise);
    section.line('SB_FACE', 0, 0, face, fill);
    section.line('SB_FILL', face, fill, l, fill);
    section.line('SB_WALL', l, rise, l, rim);
    section.line('SB_WALL', l, rim, l + wall, rim);
    section.line('SB_WALL', l + wall, rim, l + wall, rise);
    section.line('SB_RESERVE', l + wall, rise, l + wall + reserve, rise);
    final st = (math.max(depth, rim) / 95).clamp(20, 12000).toDouble();
    section.heading(l / 2, rim, st, [
      'TRUE-SCALE SECTION A-A / LOCAL MM / SOUTH THRESHOLD = ZERO',
      'FLOOR ${floorGrade.toStringAsFixed(3)}% / FILL FACE ${faceGrade.toStringAsFixed(3)}% / FREEBOARD ${_m(free)} M',
      'GEOMETRIC FILL ${volume.toStringAsFixed(3)} M3 / NO MATERIAL OR OPERATING MODEL',
    ]);
    return SilageBunkerCadResult(plan: plan.drawing(t), section: section.drawing(st), widthMm: width, depthMm: depth,
      freeMm: free, volumeM3: volume, floorGrade: floorGrade, faceGrade: faceGrade);
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
