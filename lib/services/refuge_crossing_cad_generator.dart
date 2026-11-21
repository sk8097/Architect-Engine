import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/refuge_crossing_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class RefugeCrossingCadResult {
  const RefugeCrossingCadResult({this.drawing, this.issue, this.crossingMm = 0, this.walkMm = 0,
    this.staggerMm = 0, this.openingGapMm = 0, this.reserveMm = 0, this.routeMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final int crossingMm, walkMm, staggerMm, openingGapMm, routeMm;
  final double reserveMm;
}

/// Horizontal layout from a straight median centreline and constant surveyed widths.
class RefugeCrossingCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['corridor_cad_mode'] == refugeCrossingMode;

  RefugeCrossingCadResult generate(ProjectBrief brief) {
    RefugeCrossingCadResult stop(String issue) => RefugeCrossingCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !refugeCrossingCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Street and save the current surveyed pedestrian refuge brief.');
    }
    if (!const {null, 'linear_corridor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one surveyed street corridor without buildings, parking or separate Space selections.');
    }
    final a = req.answers;
    final raw = a['ref_grid'];
    final grid = raw is String ? raw.trim().replaceAll(RegExp(r'\s+'), ' ') : '';
    if (grid.isEmpty || grid.length > 100) return stop('Enter the projected metre grid, up to 100 characters.');
    final axis = a['ref_axis'];
    final rows = axis is String && axis.length <= 280
      ? axis.split(RegExp(r'[;\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : const <String>[];
    if (rows.length != 2) return stop('Enter exactly two straight median centreline controls, A then B.');
    final decimal = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? coordinate(String text) {
      final v = double.tryParse(text);
      return decimal.hasMatch(text.trim()) && v != null && v.isFinite && v.abs() <= 10000000 ? (v * 1000).round() : null;
    }
    final points = <(int, int)>[];
    for (final row in rows) {
      final v = row.split(',');
      if (v.length != 2) return stop('Use Easting,Northing for each projected control.');
      final x = coordinate(v[0]), y = coordinate(v[1]);
      if (x == null || y == null) return stop('Enter valid projected metre coordinates with up to three decimals.');
      points.add((x, y));
    }
    final (ax, ay) = points.first;
    final (bx, by) = points.last;
    final dx = (bx - ax).toDouble(), dy = (by - ay).toDouble(), length = math.sqrt(dx * dx + dy * dy);
    if (length < 1 || length > 2000000) return stop('Use a positive median baseline no longer than 2 km.');
    int? mm(String key, {num min = .001, num max = 100}) {
      final v = a[key];
      return v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    }
    final left = mm('ref_ch_l', min: 0, max: 2000), right = mm('ref_ch_r', min: 0, max: 2000);
    final roadL = mm('ref_road_l'), roadR = mm('ref_road_r'), median = mm('ref_median');
    final crossing = mm('ref_cross_w'), walk = mm('ref_walk_w'), minW = mm('ref_min_w');
    final reserve = mm('ref_reserve', min: 0), minStagger = mm('ref_stagger');
    final landingL = mm('ref_land_l'), landingR = mm('ref_land_r'), minLanding = mm('ref_min_land');
    if (left == null || right == null || roadL == null || roadR == null || median == null || crossing == null || walk == null ||
        minW == null || reserve == null || minStagger == null || landingL == null || landingR == null || minLanding == null) {
      return stop('Enter measured crossing stations, widths, reserves and both roadside landings.');
    }
    if (crossing < minW) return stop('The crossing openings are narrower than the submitted minimum clear width.');
    if (walk < minW) return stop('The longitudinal median walk is narrower than the submitted minimum clear width.');
    if (walk + 2 * reserve > median) return stop('The connecting walk and both side reserves do not fit inside the measured median.');
    if (landingL < minLanding) return stop('The left roadside landing is shallower than the submitted minimum.');
    if (landingR < minLanding) return stop('The right roadside landing is shallower than the submitted minimum.');
    final half = crossing / 2, halfMedian = median / 2, halfWalk = walk / 2;
    for (final (side, ch) in [('left', left), ('right', right)]) {
      if (ch - half < 0 || ch + half > length + 1e-7) return stop('The full $side crossing opening must fit within the surveyed A–B span.');
    }
    final step = (right - left).abs(), openingGap = step - crossing;
    if (openingGap < minStagger) return stop('The crossing windows overlap or leave less than the submitted longitudinal gap.');
    final route = landingL + roadL + median + roadR + landingR + step;
    final direction = right > left ? 1 : -1;
    final shift = step.toDouble();
    final rl = halfMedian + roadL, rr = -halfMedian - roadR;
    final ll = rl + landingL, lr = rr - landingR;
    CadPoint p(num ch, num off) => CadPoint(ax + (dx * ch - dy * off) / length, ay + (dy * ch + dx * off) / length);
    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num ch, num off, num end, num other) {
      if (ch != end || off != other) lines.add(CadLine(layer, p(ch, off), p(end, other)));
    }
    // Preserve the surveyed edges outside the openings; leave all four mouths open.
    for (final (ch, edge, road, landing) in [(left, halfMedian, rl, ll), (right, -halfMedian, rr, lr)]) {
      final lo = ch - half, hi = ch + half;
      for (final (layer, off) in [('REF_MEDIAN', edge), ('REF_ROAD', road)]) {
        line(layer, 0, off, lo, off);
        line(layer, hi, off, length, off);
      }
      for (final s in [lo, hi]) {
        line('REF_CROSS', s, edge, s, road);
        line('REF_LAND', s, road, s, landing);
      }
      line('REF_LAND', lo, landing, hi, landing);
    }
    // Outline the union of the two short median approaches and the connector.
    // Work from the left window toward the right, then reflect in chainage if needed.
    final outline = <(double, double)>[
      (-half, halfMedian), (half, halfMedian), (half, halfWalk), (shift + half, halfWalk),
      (shift + half, -halfMedian), (shift - half, -halfMedian), (shift - half, -halfWalk), (-half, -halfWalk),
    ];
    for (var i = 0; i < outline.length; i++) {
      if (i == 0 || i == 4) continue; // Open ends to the carriageway crossings.
      final (s, o) = outline[i];
      final (e, q) = outline[(i + 1) % outline.length];
      // If the walk uses the whole median width, the corresponding outer
      // edge already exists on the median layer outside the opening.
      if (walk == median && (i == 2 || i == 6)) continue;
      line('REF_WALK', left + direction * s, o, left + direction * e, q);
    }
    line('REF_ROUTE', left, ll, left, 0);
    line('REF_ROUTE', left, 0, right, 0);
    line('REF_ROUTE', right, 0, right, lr);
    final ext = [for (final ch in [0, length]) ...[p(ch, ll), p(ch, lr)]];
    final x0 = ext.map((p) => p.x).reduce(math.min), x1 = ext.map((p) => p.x).reduce(math.max);
    final y0 = ext.map((p) => p.y).reduce(math.min), y1 = ext.map((p) => p.y).reduce(math.max);
    final cx = (x0 + x1) / 2, t = (math.max(x1 - x0, y1 - y0) / 90).clamp(25, 10000).toDouble();
    labels.addAll([CadLabel('REF_CROSS', p(left, ll + t), 'LEFT / CH ${_m(left)}', .6 * t),
      CadLabel('REF_CROSS', p(right, lr - t), 'RIGHT / CH ${_m(right)}', .6 * t),
      CadLabel('REF_MEDIAN', p(-1.5 * t, 0), 'A', .7 * t), CadLabel('REF_MEDIAN', p(length + 1.5 * t, 0), 'B', .7 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 6 * t), 'SURVEYED STAGGERED PEDESTRIAN REFUGE / PROJECTED MM', t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 4.7 * t), 'OPENING GAP ${_m(openingGap)} M / CLEAR WALK ${_m(walk)} M / SIDE RESERVES ${_m(halfMedian - halfWalk)} M EACH', .65 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 3.4 * t), 'CENTRELINE ROUTE ${_m(route)} M / GRID: $grid', .58 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 2.1 * t), 'HORIZONTAL ENVELOPES ONLY / NO MARKINGS OR TRAFFIC APPROVAL', .58 * t)]);
    final nx = math.max(x1, cx + 49 * t) + 2 * t;
    final tip = CadPoint(nx, y1);
    lines.addAll([CadLine('ANNOTATIONS', CadPoint(nx, y1 - 2 * t), tip),
      CadLine('ANNOTATIONS', CadPoint(nx - .5 * t, y1 - t), tip), CadLine('ANNOTATIONS', CadPoint(nx + .5 * t, y1 - t), tip)]);
    labels.add(CadLabel('ANNOTATIONS', CadPoint(nx, y1 + t), 'GRID N', .65 * t));
    final bounds = PlanRect(math.min(x0 - 5 * t, cx - 49 * t).floor(), (y0 - 5 * t).floor(), (nx + 5 * t).ceil(), (y1 + 7.5 * t).ceil());
    return RefugeCrossingCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels),
      crossingMm: crossing, walkMm: walk, staggerMm: step, openingGapMm: openingGap, reserveMm: halfMedian - halfWalk, routeMm: route);
  }
}
