import 'dart:math' as math;

import '../data/park_fence_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm, [int digits = 3]) => (mm / 1000).toStringAsFixed(digits);

class FenceRun {
  const FenceRun(this.id, this.centresMm, this.panels, this.clearPanelMm);
  final String id;
  final double centresMm, clearPanelMm;
  final int panels;
}

class ParkFenceCadResult {
  const ParkFenceCadResult({this.drawing, this.issue, this.runs = const [], this.posts = 0, this.gateMm = 0,
    this.widthMm = 0, this.depthMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<FenceRun> runs;
  final int posts, gateMm, widthMm, depthMm;
  int get panels => runs.fold(0, (sum, run) => sum + run.panels);

  String? toCsv() => drawing == null ? null : [
    'run,centre_span_m,panel_count,equal_clear_span_m,intermediate_posts,unique_posts',
    for (final r in runs) '${r.id},${_m(r.centresMm, 6)},${r.panels},${_m(r.clearPanelMm, 6)},${r.panels - 1},',
    'total,,${panels},,${posts - 6},$posts',
    '',
  ].join('\r\n');
}

/// Square posts and straight panel set-out only, without gate swing or footing design.
class ParkFenceCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == parkFenceMode;

  ParkFenceCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    ParkFenceCadResult stop(String issue) => ParkFenceCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !parkFenceCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Public Park, Public Garden or Playground and save the current fence brief.');
    }
    if (!const {null, 'public_open_space'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Public Open Space and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one fence only. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 500}) =>
        v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final w = mm(a['pf_w']), d = mm(a['pf_d']), post = mm(a['pf_post'], max: 5);
    final gateX = mm(a['pf_gate_x']), gateW = mm(a['pf_gate_w']), gateMin = mm(a['pf_gate_min']);
    final spanMin = mm(a['pf_min']), spanMax = mm(a['pf_max']);
    final west = mm(a['pf_west'], min: 0, max: 2000), south = mm(a['pf_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || w == null || d == null || post == null ||
        gateX == null || gateW == null || gateMin == null || spanMin == null || spanMax == null || west == null || south == null) {
      return stop('Enter valid plot, post, gate, panel span and offset dimensions.');
    }
    if (gateW < gateMin) return stop('Increase the clear gate width to meet its submitted minimum.');
    if (spanMin > spanMax) return stop('The minimum clear panel span exceeds the maximum.');
    final width = w + post, depth = d + post;
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The fence including full corner posts conflicts with the $edge plot edge or supplied setback.');
    }
    // Double-mm axes preserve odd post sizes exactly in both integer count inequalities.
    final x0 = 2 * west + post, x1 = x0 + 2 * w, y0 = 2 * south + post, y1 = y0 + 2 * d;
    final g0 = x0 + 2 * gateX - post, g1 = x0 + 2 * (gateX + gateW) + post;
    if (g0 <= x0 || g1 >= x1) return stop('Place both gate post centres strictly between the south corner posts.');
    final edges = [
      ('south_west', x0, y0, g0, y0), ('south_east', g1, y0, x1, y0),
      ('east', x1, y0, x1, y1), ('north', x0, y1, x1, y1), ('west', x0, y0, x0, y1),
    ];
    final runs = <FenceRun>[];
    final maxPitch2 = 2 * (post + spanMax), minPitch2 = 2 * (post + spanMin);
    var panelCount = 0;
    for (final (id, x, y, ex, ey) in edges) {
      final length2 = (ex - x) + (ey - y); // Edges are traversed in their increasing coordinate.
      final count = (length2 + maxPitch2 - 1) ~/ maxPitch2;
      if (length2 < count * minPitch2) return stop('No equal panel count fits the clear span limits on the ${id.replaceAll('_', ' ')} run.');
      panelCount += count;
      if (panelCount > 500) return stop('This layout exceeds 500 panels. Increase the maximum span or reduce the fence size.');
      runs.add(FenceRun(id, length2 / 2, count, length2 / (2 * count) - post));
    }

    final lines = <CadLine>[], labels = <CadLabel>[];
    final postPoints = <(double, double)>{};
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void mark(String layer, num x, num y, String text, num size) => labels.add(CadLabel(layer, CadPoint(x, y), text, size));
    box('PF_PLOT', 0, 0, pw, pd);
    final half = post / 2;
    for (var run = 0; run < edges.length; run++) {
      final (_, x, y, ex, ey) = edges[run];
      final count = runs[run].panels;
      final axisX = x != ex;
      double pos(int from, int to, int i) => (from + (to - from) * i / count) / 2;
      for (var i = 0; i <= count; i++) {
        final px = pos(x, ex, i), py = pos(y, ey, i);
        postPoints.add((px, py));
        if (i == count) continue;
        if (axisX) {
          line('PF_PANEL', px + half, py, pos(x, ex, i + 1) - half, py);
        } else {
          line('PF_PANEL', px, py + half, px, pos(y, ey, i + 1) - half);
        }
      }
    }
    for (final (x, y) in postPoints) {
      final gate = (x == g0 / 2 || x == g1 / 2) && y == y0 / 2;
      box(gate ? 'PF_GATE_POST' : 'PF_POST', x - half, y - half, x + half, y + half);
    }
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    mark('PF_GATE_POST', (g0 + g1) / 4, south - t, 'GATE ${_m(gateW)} M CLEAR', .65 * t);
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    mark('ANNOTATIONS', pw / 2, pd + 4 * t, 'MEASURED PARK FENCE / PLAN / LOCAL MM', t);
    mark('ANNOTATIONS', pw / 2, pd + 2.5 * t, '$panelCount PANELS / ${postPoints.length} POSTS / 1 SOUTH GATE', .64 * t);
    num minX = 0, maxX = nx, minY = 0, maxY = pd;
    for (final label in labels) {
      final half = label.height * label.text.length * .43;
      minX = math.min(minX, label.at.x - half);
      maxX = math.max(maxX, label.at.x + half);
      minY = math.min(minY, label.at.y - label.height);
      maxY = math.max(maxY, label.at.y + label.height);
    }
    final drawing = FloorPlanCad.fromEntities(bounds: PlanRect((minX - 2 * t).floor(), (minY - 2 * t).floor(),
      (maxX + 2 * t).ceil(), (maxY + 2 * t).ceil()), lines: lines, labels: labels);
    return ParkFenceCadResult(drawing: drawing, runs: List.unmodifiable(runs), posts: postPoints.length,
      gateMm: gateW, widthMm: width, depthMm: depth);
  }
}
