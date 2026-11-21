import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';
import 't_junction_cad_generator.dart' show TJunctionCadResult;

const _turn = 2 * math.pi;

class _Vec {
  const _Vec(this.x, this.y);
  final double x, y;
  _Vec operator +(_Vec b) => _Vec(x + b.x, y + b.y);
  _Vec operator -(_Vec b) => _Vec(x - b.x, y - b.y);
  _Vec operator *(double factor) => _Vec(x * factor, y * factor);
  double dot(_Vec b) => x * b.x + y * b.y;
  double get length => math.sqrt(dot(this));
  double get angle => math.atan2(y, x) % _turn;
  _Vec get left => _Vec(-y, x);
}

class _Arm {
  const _Arm(this.id, this.axis, this.length, this.edge, this.row);
  final String id;
  final _Vec axis;
  final double length, edge, row;
}

/// Surveyed cross with two straight axes and independent circular curb returns.
class CrossJunctionCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['junction_cad_mode'] == 'survey_cross';

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
    final raw = a['cross_controls'];
    if (raw is! String || raw.length > 300) return stop('Enter five projected metre coordinate pairs in A; J; B; C; D order.');
    final rows = raw.trim().split(RegExp(r'[;\r\n]+')).where((r) => r.trim().isNotEmpty).toList();
    if (rows.length != 5) return stop('Enter exactly five projected coordinate pairs in A; J; B; C; D order.');
    final format = RegExp(r'^[+-]?\d+(?:\.\d{1,3})?$');
    final points = <_Vec>[];
    for (var i = 0; i < rows.length; i++) {
      final pair = rows[i].split(',').map((v) => v.trim()).toList();
      if (pair.length != 2 || pair.any((v) => !format.hasMatch(v))) {
        return stop('Control ${'AJBCD'[i]}: use Easting,Northing in metres to three decimal places, not latitude/longitude.');
      }
      final x = double.tryParse(pair[0]), y = double.tryParse(pair[1]);
      if (x == null || y == null || !x.isFinite || !y.isFinite || x.abs() > 10000000 || y.abs() > 10000000) {
        return stop('Projected coordinates must be within ±10,000,000 m.');
      }
      points.add(_Vec((x * 1000).roundToDouble(), (y * 1000).roundToDouble()));
    }
    final origin = points[1], b = points[2] - origin, c = points[3] - origin;
    if (b.length < 1 || c.length < 1) return stop('Controls B and C must be distinct from J.');
    final main = b * (1 / b.length), cross = c * (1 / c.length);
    final aa = points[0] - origin, dd = points[4] - origin;
    final lenA = -aa.dot(main), lenD = -dd.dot(cross);
    const tolerance = .00087266485; // tan(0.05 degrees)
    if (lenA < 1 || lenD < 1 || aa.dot(main.left).abs() > math.min(50, lenA * tolerance) ||
        dd.dot(cross.left).abs() > math.min(50, lenD * tolerance)) {
      return stop('A/B and C/D must each lie on opposite sides of J on a straight tangent (0.05 m and 0.05° tolerance).');
    }
    if ([lenA, b.length, c.length, lenD].any((length) => length > 2000000)) {
      return stop('Limit each surveyed junction arm to 2 km in this local node drawing.');
    }
    if (main.dot(cross).abs() > math.sqrt(3) / 2 + 1e-12) {
      return stop('All four angles between adjacent arms must be between 30° and 150°.');
    }

    double? mm(String key) {
      final v = a[key];
      if (v is! num || !v.isFinite || v <= 0 || v > 1000) return null;
      final n = (v * 1000).roundToDouble();
      return n > 0 ? n : null;
    }
    final mw = mm('junction_main_width'), cw = mm('junction_branch_width');
    final mr = mm('junction_main_row'), cr = mm('junction_branch_row');
    final radii = {for (final id in ['AC', 'AD', 'BC', 'BD']) id: mm('cross_radius_${id.toLowerCase()}')};
    if (mw == null || cw == null || mr == null || cr == null || radii.values.contains(null)) {
      return stop('Enter both carriageway widths, both full right-of-way widths, and all four curb-return radii.');
    }
    if (mr < mw || cr < cw) return stop('Each right-of-way must be at least as wide as its carriageway.');
    final arms = [
      _Arm('A', main * -1, lenA, mw / 2, mr / 2),
      _Arm('B', main, b.length, mw / 2, mr / 2),
      _Arm('C', cross, c.length, cw / 2, cr / 2),
      _Arm('D', cross * -1, lenD, cw / 2, cr / 2),
    ]..sort((a, b) => a.axis.angle.compareTo(b.axis.angle));

    final lines = <CadLine>[], arcs = <CadArc>[], labels = <CadLabel>[];
    final rowOutline = <_Vec>[];
    CadPoint p(_Vec local) => CadPoint(origin.x + local.x, origin.y + local.y);
    void line(String layer, _Vec start, _Vec end) => lines.add(CadLine(layer, p(start), p(end)));
    final size = (math.min(mw, cw) / 12).clamp(150, 900).toDouble();
    const zero = _Vec(0, 0);
    for (var i = 0; i < arms.length; i++) {
      final u = arms[i], v = arms[(i + 1) % arms.length];
      final first = u.axis.left, second = v.axis.left * -1;
      final id = ([u.id, v.id]..sort()).join();
      final r = radii[id]!;
      final sine = first.dot(v.axis), cosine = u.axis.dot(v.axis);
      // Intersect the two parallel offsets toward this sector. For an arc
      // centre both signed distances are carriageway half-width plus R.
      _Vec intersect(double f, double s) => first * f + u.axis * ((s + f * cosine) / sine);
      final notch = intersect(u.row, v.row), centre = intersect(u.edge + r, v.edge + r);
      final tu = centre - first * r, tv = centre - second * r;
      if (u.length <= math.max(tu.dot(u.axis), notch.dot(u.axis)) ||
          v.length <= math.max(tv.dot(v.axis), notch.dot(v.axis))) {
        return stop('Survey arms $id must extend past their right-of-way corner and curb-return tangent points.');
      }
      if (!_arcFits(centre, r, first, second, u.row, v.row)) {
        return stop('The $id curb return extends outside the supplied right-of-way. Reconcile the measured widths or radius.');
      }
      final pu = u.axis * u.length, pv = v.axis * v.length;
      final ru = pu + first * u.row, rv = pv + second * v.row;
      line('JUNCTION_ROW', ru, notch);
      line('JUNCTION_ROW', notch, rv);
      line('JUNCTION_ROW', pu - first * u.row, ru);
      rowOutline.addAll([ru, notch, rv]);
      final eu = pu + first * u.edge, ev = pv + second * v.edge;
      line('JUNCTION_EDGE', eu, tu);
      line('JUNCTION_EDGE', tv, ev);
      line('JUNCTION_EDGE', pu - first * u.edge, eu);
      line('JUNCTION_AXIS', zero, pu);
      arcs.add(CadArc('JUNCTION_CURB', p(centre), r, (second * -1).angle * 180 / math.pi, (first * -1).angle * 180 / math.pi));
      labels.add(CadLabel('JUNCTION_CURB', p(centre), '$id R${(r / 1000).toStringAsFixed(3)} m', size * .7));
    }

    for (var i = 0; i < points.length; i++) {
      final point = points[i] - origin, d = size * .25;
      line('JUNCTION_CONTROLS', point - _Vec(d, 0), point + _Vec(d, 0));
      line('JUNCTION_CONTROLS', point - _Vec(0, d), point + _Vec(0, d));
      labels.add(CadLabel('JUNCTION_CONTROLS', p(point + _Vec(0, size * .7)), 'AJBCD'[i], size * .65));
    }
    final minX = rowOutline.map((v) => v.x).reduce(math.min), maxX = rowOutline.map((v) => v.x).reduce(math.max);
    final minY = rowOutline.map((v) => v.y).reduce(math.min), maxY = rowOutline.map((v) => v.y).reduce(math.max);
    final titleX = (minX + maxX) / 2, titleY = maxY + size * 3.5;
    final source = '$grid / $reference';
    labels.addAll([
      CadLabel('ANNOTATIONS', p(_Vec(titleX, titleY)), 'SURVEY FOUR-ARM INTERSECTION / CONCEPT ONLY', size),
      CadLabel('ANNOTATIONS', p(_Vec(titleX, titleY - size * 1.15)), source, size * .65),
      CadLabel('ANNOTATIONS', p(_Vec(titleX, titleY - size * 2.1)), 'PROJECTED COORDINATES IN MM - NOT FOR CONSTRUCTION', size * .65),
    ]);
    final arrowX = maxX + size * 2, tip = _Vec(arrowX, maxY + size * 1.4);
    line('ANNOTATIONS', _Vec(arrowX, maxY - size * .4), tip);
    for (final side in [-1, 1]) {
      line('ANNOTATIONS', _Vec(arrowX + side * size * .35, maxY + size * .65), tip);
    }
    labels.add(CadLabel('ANNOTATIONS', p(_Vec(arrowX, maxY + size * 2)), 'GRID N', size * .65));
    final titleHalf = math.max(20, source.length * .24) * size;
    // An arc centre can lie outside the ROW even when the arc itself fits.
    final labelPoints = labels.map((label) => label.at);
    final bounds = PlanRect(
      math.min(origin.x + math.min(minX - size * 5, titleX - titleHalf), labelPoints.map((pt) => pt.x).reduce(math.min) - size).floor(),
      math.min(origin.y + minY - size * 2, labelPoints.map((pt) => pt.y).reduce(math.min) - size).floor(),
      math.max(origin.x + math.max(arrowX + size * 3, titleX + titleHalf), labelPoints.map((pt) => pt.x).reduce(math.max) + size * 8).ceil(),
      math.max(origin.y + titleY + size * 1.2, labelPoints.map((pt) => pt.y).reduce(math.max) + size).ceil(),
    );
    return TJunctionCadResult(FloorPlanCad.fromEntities(bounds: bounds, lines: lines, arcs: arcs, labels: labels), null);
  }

  bool _arcFits(_Vec centre, double r, _Vec first, _Vec second, double rowU, double rowV) {
    final start = (second * -1).angle, end = (first * -1).angle;
    final sweep = (end - start) % _turn;
    final candidates = [start, end];
    void add(double angle) {
      if ((angle - start) % _turn <= sweep + 1e-12) candidates.add(angle);
    }
    // In this sector the arc exits the union of the two ROW strips only
    // where both signed offsets exceed their limits. Maximize the lesser
    // excess: it can peak at an endpoint, stationary point or equality.
    for (final normal in [first, second]) {
      add(normal.angle);
      add(normal.angle + math.pi);
    }
    final diff = first - second;
    final equal = (rowU - rowV - centre.dot(diff)) / (r * diff.length);
    if (equal.abs() <= 1) {
      final delta = math.acos(equal);
      add(diff.angle + delta);
      add(diff.angle - delta);
    }
    for (final theta in candidates) {
      final point = centre + _Vec(math.cos(theta), math.sin(theta)) * r;
      if (math.min(point.dot(first) - rowU, point.dot(second) - rowV) > 1e-6) return false;
    }
    return true;
  }
}
