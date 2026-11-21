import 'dart:math' as math;

import '../data/guyed_mast_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);
String _d(num degrees) => degrees.toStringAsFixed(3);

class GuyedMastAnchor {
  const GuyedMastAnchor(this.id, this.xMm, this.yMm, this.levelMm, this.runMm, this.azimuth, this.angle, this.chordMm);
  final String id;
  final int xMm, yMm, levelMm;
  final double runMm, azimuth, angle, chordMm;

  String _row() => '$id,${_m(xMm)},${_m(yMm)},${_m(levelMm)},${_m(runMm)},${_d(azimuth)},${_d(angle)},${_m(chordMm)}';
}

class GuyedMastCadResult {
  const GuyedMastCadResult({this.drawing, this.issue, this.anchors = const [], this.maxGap = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<GuyedMastAnchor> anchors;
  final double maxGap;

  String? toCsv() => drawing == null ? null : [
    'anchor_id,x_m,y_m,level_m,plan_run_m,azimuth_deg,upward_angle_deg,straight_chord_m',
    for (final anchor in anchors) anchor._row(),
    '',
  ].join('\r\n');
}

typedef _Reserve = ({String name, int x, int y, int side});

/// One guy level and three measured anchors; not a structural or installation model.
class GuyedMastCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == guyedMastMode;

  GuyedMastCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    GuyedMastCadResult stop(String issue) => GuyedMastCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !guyedMastCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Telecom Tower and save the current guyed mast brief.');
    }
    if (!const {null, 'outdoor_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Outdoor Yard and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor mast only. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    double? n(Object? v, {num min = .001, num max = 2000}) =>
        v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    int? mm(Object? v, {num min = .001, num max = 2000}) {
      final value = n(v, min: min, max: max);
      return value == null ? null : (1000 * value).round();
    }
    int? setback(String side) => a['${side}_setback'] == null ? 0 : mm(a['${side}_setback'], min: 0);
    final left = setback('left'), right = setback('right'), front = setback('front'), rear = setback('rear');
    final pw = mm(widthFt * .3048), pd = mm(depthFt * .3048), cx = mm(a['gm_x']), cy = mm(a['gm_y']);
    final pad = mm(a['gm_pad'], max: 100), reserve = mm(a['gm_anchor'], max: 100), height = mm(a['gm_attach'], max: 300);
    final minAngle = n(a['gm_min_angle'], max: 89.999), maxAngle = n(a['gm_max_angle'], max: 89.999);
    final gapLimit = n(a['gm_max_gap'], min: 120, max: 179.999);
    if (left == null || right == null || front == null || rear == null || pw == null || pd == null ||
        (sel.plotShapeId == 'square' && pw != pd) || cx == null || cy == null || pad == null || reserve == null ||
        height == null || minAngle == null || maxAngle == null || gapLimit == null) {
      return stop('Enter valid plot dimensions, setbacks, mast centre, reserves, attachment height and angular limits.');
    }
    if (minAngle > maxAngle) return stop('The minimum upward guy angle exceeds the maximum.');
    final reserves = <_Reserve>[(name: 'Mast pad', x: cx, y: cy, side: pad)];
    final anchors = <GuyedMastAnchor>[];
    for (final id in ['a', 'b', 'c']) {
      final name = id.toUpperCase();
      final x = mm(a['gm_${id}_x']), y = mm(a['gm_${id}_y']), z = mm(a['gm_${id}_z'], min: -300, max: 300);
      if (x == null || y == null || z == null) return stop('Enter valid plan coordinates and level for anchor $name.');
      final dx = x - cx, dy = y - cy, rise = height - z;
      final run = math.sqrt(dx * dx + dy * dy);
      if (run == 0 || rise <= 0) return stop('Place anchor $name away from the mast and below the common guy attachment.');
      final angle = math.atan2(rise, run) * 180 / math.pi;
      if (angle < minAngle - 1e-9 || angle > maxAngle + 1e-9) {
        return stop('Anchor $name gives an upward angle of ${_d(angle)} degrees, outside the submitted range.');
      }
      final azimuth = (math.atan2(dx, dy) * 180 / math.pi + 360) % 360;
      anchors.add(GuyedMastAnchor(name, x, y, z, run, azimuth, angle, math.sqrt(run * run + rise * rise)));
      reserves.add((name: 'Anchor $name reserve', x: x, y: y, side: reserve));
    }
    for (var i = 0; i < reserves.length; i++) {
      final r = reserves[i];
      if (2 * (r.x - left) < r.side || 2 * (pw - right - r.x) < r.side ||
          2 * (r.y - front) < r.side || 2 * (pd - rear - r.y) < r.side) {
        return stop('${r.name} conflicts with the plot edge or supplied setback.');
      }
      for (final q in reserves.take(i)) {
        if (2 * (r.x - q.x).abs() < r.side + q.side && 2 * (r.y - q.y).abs() < r.side + q.side) {
          return stop('${r.name} overlaps the ${q.name.toLowerCase()}.');
        }
      }
    }
    final azimuths = anchors.map((e) => e.azimuth).toList()..sort();
    final gap = [azimuths[1] - azimuths[0], azimuths[2] - azimuths[1], azimuths[0] + 360 - azimuths[2]].reduce(math.max);
    if (gap > gapLimit + 1e-9) return stop('Largest consecutive azimuth gap is ${_d(gap)} degrees, above the submitted limit.');

    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void mark(String layer, num x, num y, String text, num size) => labels.add(CadLabel(layer, CadPoint(x, y), text, size));
    box('GM_PLOT', 0, 0, pw, pd);
    if (left + right + front + rear > 0) box('GM_SETBACK', left, front, pw - right, pd - rear);
    for (var i = 0; i < reserves.length; i++) {
      final r = reserves[i], layer = i == 0 ? 'GM_PAD' : 'GM_ANCHOR';
      final half = r.side / 2;
      box(layer, r.x - half, r.y - half, r.x + half, r.y + half);
      mark(layer, r.x, r.y, i == 0 ? 'MAST' : anchors[i - 1].id, r.side * (i == 0 ? .24 : .45));
    }
    for (final anchor in anchors) {
      line('GM_GUY', cx, cy, anchor.xMm, anchor.yMm);
    }
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    mark('ANNOTATIONS', nx, pd + t, 'N', .7 * t);
    mark('ANNOTATIONS', pw / 2, pd + 4 * t, 'MEASURED GUYED MAST SITING / PLAN / LOCAL MM', t);
    mark('ANNOTATIONS', pw / 2, pd + 2.5 * t, 'COMMON ATTACHMENT +${_m(height)} M / MAX AZIMUTH GAP ${_d(gap)} DEG / GEOMETRY ONLY', .64 * t);
    num minX = 0, maxX = nx, maxY = pd;
    for (final label in labels) {
      final half = label.height * label.text.length * .43;
      minX = math.min(minX, label.at.x - half);
      maxX = math.max(maxX, label.at.x + half);
      maxY = math.max(maxY, label.at.y + label.height);
    }
    final drawing = FloorPlanCad.fromEntities(bounds: PlanRect((minX - 2 * t).floor(), (-2 * t).floor(),
      (maxX + 2 * t).ceil(), (maxY + 2 * t).ceil()), lines: lines, labels: labels);
    return GuyedMastCadResult(drawing: drawing, anchors: List.unmodifiable(anchors), maxGap: gap);
  }
}
