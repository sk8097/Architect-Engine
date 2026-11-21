import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class TJunctionCadResult {
  const TJunctionCadResult(this.drawing, this.issue);
  final FloorPlanCad? drawing;
  final String? issue;
}

/// Plan-only three-arm T. Main A and B lie along a common tangent; branch C
/// is on either handed side. Curb returns are exact circular arcs, not meshes.
class TJunctionCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['junction_cad_mode'] == 'survey_t';

  TJunctionCadResult generate(ProjectBrief brief) {
    TJunctionCadResult stop(String issue) => TJunctionCadResult(null, issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        sel.categoryId != 'infrastructure' || sel.subcategoryId != 'transport' || sel.typeId != 'intersection') {
      return stop('Select Transport → Intersection and save the current surveyed junction brief.');
    }
    if (!const {null, 'node_interchange'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a new plan-view Node / Interchange with no structures, parking or separate Space selections.');
    }
    final a = snap.answers;
    String? description(Object? value) => value is String && value.trim().isNotEmpty && value.trim().length <= 120
        ? value.trim().replaceAll(RegExp(r'\s+'), ' ') : null;
    final grid = description(a['junction_grid']), reference = description(a['junction_reference']);
    if (grid == null || reference == null) return stop('Enter the projected survey grid and source reference (up to 120 characters each).');
    final raw = a['junction_controls'];
    if (raw is! String || raw.length > 250) return stop('Enter four projected metre coordinate pairs in A; J; B; C order.');
    final rows = raw.trim().split(RegExp(r'[;\r\n]+')).where((r) => r.trim().isNotEmpty).toList();
    if (rows.length != 4) return stop('Enter exactly four projected coordinate pairs: main A, junction J, main B, branch C.');
    final format = RegExp(r'^[+-]?\d+(?:\.\d{1,3})?$');
    final points = <CadPoint>[];
    for (var i = 0; i < rows.length; i++) {
      final pair = rows[i].split(',').map((v) => v.trim()).toList();
      if (pair.length != 2 || pair.any((v) => !format.hasMatch(v))) return stop('Control ${'AJBC'[i]}: use Easting,Northing in metres to three decimal places, not latitude/longitude.');
      final x = double.tryParse(pair[0]), y = double.tryParse(pair[1]);
      if (x == null || y == null || !x.isFinite || !y.isFinite || x.abs() > 10000000 || y.abs() > 10000000) {
        return stop('Projected coordinates must be within ±10,000,000 m.');
      }
      points.add(CadPoint((x * 1000).round(), (y * 1000).round()));
    }
    final origin = points[1], b = points[2];
    final ux = (b.x - origin.x).toDouble(), uy = (b.y - origin.y).toDouble();
    final east = math.sqrt(ux * ux + uy * uy);
    if (east < 1) return stop('Controls J and B must be distinct.');
    final ex = ux / east, ey = uy / east;
    (double, double) local(CadPoint p) {
      final px = (p.x - origin.x).toDouble(), py = (p.y - origin.y).toDouble();
      return (px * ex + py * ey, -px * ey + py * ex);
    }
    final (ax, ay) = local(points[0]);
    final (cx, cy) = local(points[3]);
    final west = -ax, branch = cy.abs(), handedness = cy < 0 ? -1 : 1;
    const tolerance = .00087266485; // tan(0.05 degrees), in addition to 50 mm.
    if (west < 1 || ay.abs() > math.min(50, west * tolerance)) return stop('Main A and B must lie on opposite sides of J on one tangent (0.05 m and 0.05° tolerance).');
    if (branch < 1 || cx.abs() > math.min(50, branch * tolerance)) return stop('Branch C must be perpendicular to the main tangent at J (0.05 m and 0.05° tolerance).');
    if ([west, east, branch].any((arm) => arm > 2000000)) return stop('Limit each surveyed junction arm to 2 km in this local node drawing.');
    int? mm(String key) {
      final v = a[key];
      if (v is! num || !v.isFinite || v <= 0 || v > 1000) return null;
      final n = (v * 1000).round();
      return n > 0 ? n : null;
    }
    final mw = mm('junction_main_width'), bw = mm('junction_branch_width'), mr = mm('junction_main_row');
    final br = mm('junction_branch_row'), rA = mm('junction_a_radius'), rB = mm('junction_b_radius');
    if (mw == null || bw == null || mr == null || br == null || rA == null || rB == null) {
      return stop('Enter both carriageway widths, both full right-of-way widths, and both curb-return radii.');
    }
    if (mr < mw || br < bw) return stop('Each right-of-way must be at least as wide as its carriageway.');
    final m = mw / 2, s = bw / 2, rowM = mr / 2, rowS = br / 2;
    if (west <= rowS || east <= rowS || branch <= rowM || west <= s + rA || east <= s + rB || branch <= m + math.max(rA, rB)) {
      return stop('All three survey arms must extend past the right-of-way corners and their curb-return tangent points.');
    }
    // Inside the arc's quadrant, the ROW notch nearest the road must be
    // on or inside the circle (the road is on the outside of this circle).
    bool fits(num radius) {
      final dx = radius - (rowS - s), dy = radius - (rowM - m);
      return dx <= 0 || dy <= 0 || dx * dx + dy * dy <= radius * radius;
    }
    if (!fits(rA) || !fits(rB)) return stop('A curb return extends outside the supplied T-shaped right-of-way. Reconcile the measured widths or radii.');

    CadPoint p(num x, num y) => CadPoint(origin.x + ex * x - ey * y * handedness, origin.y + ey * x + ex * y * handedness);
    final lines = <CadLine>[], arcs = <CadArc>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num xx, num yy) => lines.add(CadLine(layer, p(x, y), p(xx, yy)));
    void trace(String layer, List<(num, num)> pts) {
      for (var i = 1; i < pts.length; i++) { line(layer, pts[i - 1].$1, pts[i - 1].$2, pts[i].$1, pts[i].$2); }
    }
    final bearing = math.atan2(ey, ex) * 180 / math.pi;
    double angle(num v) => (bearing + v * handedness) % 360;
    void arc(num x, num y, int r, int start, int end) => arcs.add(CadArc('JUNCTION_CURB', p(x, y), r,
      angle(handedness == 1 ? start : end), angle(handedness == 1 ? end : start)));
    final rightOfWay = <(num, num)>[(-west, -rowM), (east, -rowM), (east, rowM), (rowS, rowM),
      (rowS, branch), (-rowS, branch), (-rowS, rowM), (-west, rowM), (-west, -rowM)];
    trace('JUNCTION_ROW', rightOfWay);
    trace('JUNCTION_EDGE', [(-west, m), (-s - rA, m)]);
    trace('JUNCTION_EDGE', [(s + rB, m), (east, m), (east, -m), (-west, -m), (-west, m)]);
    trace('JUNCTION_EDGE', [(-s, m + rA), (-s, branch), (s, branch), (s, m + rB)]);
    arc(-s - rA, m + rA, rA, 270, 360);
    arc(s + rB, m + rB, rB, 180, 270);
    trace('JUNCTION_AXIS', [(-west, 0), (0, 0), (east, 0)]);
    trace('JUNCTION_AXIS', [(0, 0), (0, branch)]);
    final size = (math.min(mw, bw) / 12).clamp(150, 900).toDouble();
    for (var i = 0; i < points.length; i++) {
      final point = points[i], d = size * .25;
      lines.addAll([
        CadLine('JUNCTION_CONTROLS', CadPoint(point.x - d, point.y), CadPoint(point.x + d, point.y)),
        CadLine('JUNCTION_CONTROLS', CadPoint(point.x, point.y - d), CadPoint(point.x, point.y + d)),
      ]);
      labels.add(CadLabel('JUNCTION_CONTROLS', CadPoint(point.x, point.y + size * .7), 'AJBC'[i], size * .65));
    }
    labels.addAll([
      CadLabel('JUNCTION_CURB', p(-s - rA, m + rA), 'A R${(rA / 1000).toStringAsFixed(3)} m', size * .7),
      CadLabel('JUNCTION_CURB', p(s + rB, m + rB), 'B R${(rB / 1000).toStringAsFixed(3)} m', size * .7),
    ]);
    final outline = rightOfWay.map((v) => p(v.$1, v.$2)).toList();
    final minX = outline.map((v) => v.x).reduce(math.min), maxX = outline.map((v) => v.x).reduce(math.max);
    final minY = outline.map((v) => v.y).reduce(math.min), maxY = outline.map((v) => v.y).reduce(math.max);
    final titleX = (minX + maxX) / 2, titleY = maxY + size * 3.5;
    final source = '$grid / $reference';
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(titleX, titleY), 'SURVEY T-JUNCTION / CONCEPT ONLY', size),
      CadLabel('ANNOTATIONS', CadPoint(titleX, titleY - size * 1.15), source, size * .65),
      CadLabel('ANNOTATIONS', CadPoint(titleX, titleY - size * 2.1), 'PROJECTED COORDINATES IN MM - NOT FOR CONSTRUCTION', size * .65),
    ]);
    final arrowX = maxX + size * 2, arrowY = maxY;
    final tip = CadPoint(arrowX, arrowY + size * 1.4);
    lines.addAll([
      CadLine('ANNOTATIONS', CadPoint(arrowX, arrowY - size * .4), tip),
      CadLine('ANNOTATIONS', CadPoint(arrowX - size * .35, arrowY + size * .65), tip),
      CadLine('ANNOTATIONS', CadPoint(arrowX + size * .35, arrowY + size * .65), tip),
    ]);
    labels.add(CadLabel('ANNOTATIONS', CadPoint(arrowX, arrowY + size * 2), 'GRID N', size * .65));
    final titleHalf = math.max(17, source.length * .24) * size;
    final bounds = PlanRect(math.min(minX - size * 5, titleX - titleHalf).floor(), (minY - size * 2).floor(),
      math.max(arrowX + size * 3, titleX + titleHalf).ceil(), (titleY + size * 1.2).ceil());
    return TJunctionCadResult(FloorPlanCad.fromEntities(bounds: bounds, lines: lines, arcs: arcs, labels: labels), null);
  }
}
