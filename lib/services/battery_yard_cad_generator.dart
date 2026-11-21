import 'dart:math' as math;

import '../data/battery_yard_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class BatteryYardUnit {
  const BatteryYardUnit(this.id, this.row, this.group, this.westMm, this.southMm, this.eastMm, this.northMm);
  final String id, row;
  final int group, westMm, southMm, eastMm, northMm;

  String _csvRow() => '$id,$row,$group,${_m(westMm)},${_m(southMm)},${_m(eastMm)},${_m(northMm)},${row == 'west' ? 'east' : 'west'}';
}

class BatteryYardCadResult {
  const BatteryYardCadResult({this.drawing, this.issue, this.units = const [], this.widthMm = 0, this.depthMm = 0,
    this.groups = 0, this.aisleMm = 0, this.crossMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<BatteryYardUnit> units;
  final int widthMm, depthMm, groups, aisleMm, crossMm;
  int get crossAisles => groups > 0 ? groups - 1 : 0;

  String? toCsv() => drawing == null ? null : [
    'unit_id,row,group,x_min_m,y_min_m,x_max_m,y_max_m,facing',
    for (final unit in units) unit._csvRow(),
    '',
  ].join('\r\n');
}

/// Static equipment rectangles and clear strips only. No electrical or fire design.
class BatteryYardCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == batteryYardMode;

  BatteryYardCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    BatteryYardCadResult stop(String issue) => BatteryYardCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !batteryYardCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Battery Energy Storage and save the current measured yard brief.');
    }
    if (!const {null, 'outdoor_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use the Outdoor Yard arrangement and choose New Design, Concept Design, Site Development or Feasibility Study.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one standalone outdoor equipment yard. Remove enclosed floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 100}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    int? count(Object? v, int min) =>
        v is num && v.isFinite && v >= min && v <= 100 && v == v.toInt() ? v.toInt() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final n = count(a['by_pairs'], 2), k = count(a['by_group'], 1);
    final w = mm(a['by_w']), d = mm(a['by_d']), gap = mm(a['by_gap']), gapMin = mm(a['by_gap_min']);
    final aisle = mm(a['by_aisle']), aisleMin = mm(a['by_aisle_min']), cross = mm(a['by_cross']), crossMin = mm(a['by_cross_min']);
    final rear = mm(a['by_rear']), rearMin = mm(a['by_rear_min']), end = mm(a['by_end']), endMin = mm(a['by_end_min']);
    final west = mm(a['by_west'], min: 0, max: 2000), south = mm(a['by_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || n == null || k == null || w == null || d == null ||
        gap == null || gapMin == null || aisle == null || aisleMin == null || cross == null || crossMin == null ||
        rear == null || rearMin == null || end == null || endMin == null || west == null || south == null) {
      return stop('Enter valid plot dimensions, whole unit counts and measured clearances and limits.');
    }
    if (k >= n) return stop('Set the maximum consecutive positions below the row count to leave at least one cross-aisle.');
    if (k > 1 && gap < gapMin) return stop('The gap between neighbouring units within a group is below the submitted minimum.');
    if (cross < math.max(crossMin, gapMin)) return stop('The cross-aisle must meet both the cross-aisle and the unit separation minimum.');
    if (aisle < aisleMin) return stop('The central lane is below the submitted minimum clear width.');
    if (rear < rearMin || end < endMin) return stop('Increase the outside-row or row-end reserve to meet its submitted minimum.');
    final crossCount = (n - 1) ~/ k;
    final width = 2 * (rear + d) + aisle;
    final length = 2 * end + n * w + (n - 1 - crossCount) * gap + crossCount * cross;
    for (final (side, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - length)]) {
      final raw = a['${side}_setback'];
      final minimum = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (minimum == null || available < minimum) return stop('The full yard conflicts with the $side plot edge or supplied setback.');
    }

    final lines = <CadLine>[], labels = <CadLabel>[], units = <BatteryYardUnit>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void mark(String layer, num x, num y, String text, num size) => labels.add(CadLabel(layer, CadPoint(x, y), text, size));
    final laneW = west + rear + d, laneE = laneW + aisle, east = west + width, north = south + length;
    box('BY_PLOT', 0, 0, pw, pd);
    box('BY_LIMIT', west, south, east, north);
    // Mark lane sections without drawing across cross-aisles or the open end reserves.
    var y = south + end;
    var groupStart = y;
    for (var i = 0; i < n; i++) {
      final group = i ~/ k + 1, id = '${i + 1}'.padLeft(3, '0');
      for (final (prefix, row, x) in [('W', 'west', west + rear), ('E', 'east', laneE)]) {
        final unit = BatteryYardUnit('$prefix$id', row, group, x, y, x + d, y + w);
        units.add(unit);
        box('BY_UNIT', unit.westMm, unit.southMm, unit.eastMm, unit.northMm);
        mark('BY_UNIT', x + d / 2, y + w / 2, unit.id, math.min(w * .20, d * .20));
      }
      y += w;
      final isLast = i == n - 1;
      if (isLast || (i + 1) % k == 0) {
        // Unit faces already mark these lane edges; add a lane axis only in the regular segments.
        final cx = (laneW + laneE) / 2;
        line('BY_LANE', cx, groupStart, cx, y);
        if (!isLast) {
          // Outline the cross-aisle in the two reserve strips; adjacent unit ends already show its limits in the rows.
          for (final (x, ex) in [(west, west + rear), (east - rear, east)]) {
            line('BY_CROSS', x, y, ex, y);
            line('BY_CROSS', x, y + cross, ex, y + cross);
          }
          line('BY_CROSS', west + rear, y + cross / 2, east - rear, y + cross / 2);
          y += cross;
          groupStart = y;
        }
      } else {
        y += gap;
      }
    }
    final t = (math.max(pw, pd) / 93).clamp(15, 12000).toDouble(), nx = pw + 2.5 * t;
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    mark('ANNOTATIONS', nx, pd + t, 'N', .7 * t);
    final headings = [
      'MEASURED BATTERY STORAGE YARD / PLAN / LOCAL MM',
      '${units.length} UNITS / ${crossCount + 1} GROUPS / $crossCount CROSS-AISLES / ENVELOPE ${_m(width)} x ${_m(length)} M',
      'NAMING: W FACES EAST / E FACES WEST / CLEAR CENTRAL LANE ${_m(aisle)} M',
    ];
    for (var i = 0; i < headings.length; i++) {
      mark('ANNOTATIONS', pw / 2, pd + (headings.length - i + .5) * 1.3 * t, headings[i], i == 0 ? t : .64 * t);
    }
    num left = 0, right = nx, high = pd;
    for (final l in labels) {
      final half = l.height * l.text.length * .43;
      left = math.min(left, l.at.x - half);
      right = math.max(right, l.at.x + half);
      high = math.max(high, l.at.y + l.height);
    }
    final drawing = FloorPlanCad.fromEntities(bounds: PlanRect((left - 2 * t).floor(), (-2 * t).floor(),
      (right + 2 * t).ceil(), (high + 2 * t).ceil()), lines: lines, labels: labels);
    return BatteryYardCadResult(drawing: drawing, units: List.unmodifiable(units), widthMm: width, depthMm: length,
      groups: crossCount + 1, aisleMm: aisle, crossMm: cross);
  }
}
