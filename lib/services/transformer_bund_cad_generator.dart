import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/transformer_bund_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);
String _v(double volume) => volume.toStringAsFixed(3);

class TransformerBundCadResult {
  const TransformerBundCadResult({this.plan, this.section, this.issue, this.widthMm = 0, this.depthMm = 0,
    this.freeboardMm = 0, this.grossM3 = 0, this.displacedM3 = 0, this.netM3 = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int widthMm, depthMm, freeboardMm;
  final double grossM3, displacedM3, netM3;
}

/// Level, rectangular geometric containment with two solid plinths; no spill analysis.
class TransformerBundCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == transformerBundMode;

  TransformerBundCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    TransformerBundCadResult stop(String issue) => TransformerBundCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !transformerBundCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Transformer Yard and save the current bund brief.');
    }
    if (!const {null, 'outdoor_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Outdoor Yard and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor bund. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    double? scalar(Object? v, {num min = .001, num max = 100}) =>
        v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    int? mm(Object? v, {num min = .001, num max = 100}) {
      final value = scalar(v, min: min, max: max);
      return value == null ? null : (1000 * value).round();
    }
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final w = mm(a['tb_w']), l = mm(a['tb_l']), wall = mm(a['tb_wall'], max: 10);
    final rim = mm(a['tb_rim'], max: 30), fill = mm(a['tb_fill'], max: 30), minFree = mm(a['tb_free_min'], max: 30);
    final pW = mm(a['tb_p_w']), pL = mm(a['tb_p_l']), hW = mm(a['tb_h_w'], max: 30), hE = mm(a['tb_h_e'], max: 30);
    final gap = mm(a['tb_gap']), clear = mm(a['tb_clear']), reserve = mm(a['tb_reserve']);
    final west = mm(a['tb_west'], min: 0, max: 2000), south = mm(a['tb_south'], min: 0, max: 2000);
    final target = scalar(a['tb_volume'], max: 300000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || w == null || l == null || wall == null ||
        rim == null || fill == null || minFree == null || pW == null || pL == null || hW == null || hE == null || gap == null ||
        clear == null || reserve == null || west == null || south == null || target == null) {
      return stop('Enter valid measured plot, bund, plinth and service dimensions and a containment target.');
    }
    final free = rim - fill;
    if (free < minFree) return stop('The design fill level leaves insufficient freeboard to the wall rim.');
    if (gap < clear) return stop('The gap between plinths is below the submitted minimum.');
    final remainingX = w - 2 * pW - gap, remainingY = l - pL;
    if (remainingX < 2 * clear || remainingY < 2 * clear) return stop('The centred plinths do not leave the submitted clearance to every inner wall.');
    final width = w + 2 * (wall + reserve), depth = l + 2 * (wall + reserve);
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The full bund and service envelope conflict with the $edge plot edge or supplied setback.');
    }
    final grossMm3 = w * l * fill;
    final displacedMm3 = pW * pL * (math.min(fill, hW) + math.min(fill, hE));
    final gross = grossMm3 / 1e9, displaced = displacedMm3 / 1e9, net = (grossMm3 - displacedMm3) / 1e9;
    if (net < target - 1e-9) return stop('Net geometric containment is ${net.toStringAsFixed(6)} m³, below the submitted target.');

    final plan = _Sheet(), section = _Sheet();
    final xIn = reserve + wall, xFar = xIn + w;
    final xW = xIn + remainingX / 2, xE = xW + pW + gap;
    final yIn = south + xIn, yP = yIn + remainingY / 2, cy = yIn + l / 2;
    plan.box('TB_PLOT', 0, 0, pw, pd);
    plan.box('TB_RESERVE', west, south, west + width, south + depth);
    plan.box('TB_WALL', west + reserve, south + reserve, west + width - reserve, south + depth - reserve);
    plan.box('TB_WALL', west + xIn, yIn, west + xFar, yIn + l);
    for (final x in [xW, xE]) {
      plan.box('TB_PLINTH', west + x, yP, west + x + pW, yP + pL);
    }
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    plan.line('TB_CUT', west, cy, west + width, cy);
    plan.mark('TB_CUT', west - t, cy, 'A', .65 * t);
    plan.mark('TB_CUT', west + width + t, cy, 'A', .65 * t);
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED TRANSFORMER BUND / PLAN / LOCAL MM / SECTION A-A WEST-EAST',
      'TWO PLINTHS / FULL SERVICE ENVELOPE ${_m(width)} x ${_m(depth)} M / NET ${_v(net)} M3',
    ]);

    // Floor and water lines stop at solid faces. A submerged plinth does not interrupt the fill surface.
    for (final (from, to) in [(xIn, xW), (xW + pW, xE), (xE + pW, xFar)]) {
      section.line('TB_FLOOR', from, 0, to, 0);
    }
    for (final (x, side, edge) in [(reserve, xIn, 0), (width - reserve, xFar, width)]) {
      section.line('TB_RESERVE', edge, 0, x, 0);
      section.line('TB_WALL', x, 0, x, rim);
      section.line('TB_WALL', x, rim, side, rim);
      section.line('TB_WALL', side, rim, side, 0);
    }
    num waterStart = xIn;
    for (final (x, h) in [(xW, hW), (xE, hE)]) {
      section.line('TB_PLINTH', x, 0, x, h);
      section.line('TB_PLINTH', x, h, x + pW, h);
      section.line('TB_PLINTH', x + pW, h, x + pW, 0);
      if (h >= fill) {
        section.line('TB_LEVEL', waterStart, fill, x, fill);
        waterStart = x + pW;
      }
    }
    section.line('TB_LEVEL', waterStart, fill, xFar, fill);
    final tallest = math.max(rim, math.max(hW, hE));
    final st = (math.max(width, tallest) / 90).clamp(20, 12000).toDouble();
    section.heading(width / 2, tallest, st, [
      'BUND SECTION A-A / TRUE SCALE MM / LEVEL FLOOR = ZERO',
      'DESIGN FILL ${_m(fill)} M / FREEBOARD ${_m(free)} M / NET ${_v(net)} M3',
      'GROSS ${_v(gross)} M3 - SOLID PLINTH DISPLACEMENT ${_v(displaced)} M3',
    ]);
    return TransformerBundCadResult(plan: plan.drawing(t), section: section.drawing(st), widthMm: width, depthMm: depth,
      freeboardMm: free, grossM3: gross, displacedM3: displaced, netM3: net);
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
