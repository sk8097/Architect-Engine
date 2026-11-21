import 'dart:math' as math;

import '../data/playground_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class PlaygroundZone {
  const PlaygroundZone(this.id, this.equipment, this.zone);
  final String id;
  final PlanRect equipment, zone;
  double get areaM2 => zone.width * zone.depth / 1e6;
}

class PlaygroundCadResult {
  const PlaygroundCadResult({this.drawing, this.issue, this.zones = const [], this.pathAreaM2 = 0, this.zoneAreaM2 = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<PlaygroundZone> zones;
  final double pathAreaM2, zoneAreaM2;

  String? toCsv() {
    if (drawing == null) return null;
    String m(int value) => (value / 1000).toStringAsFixed(3);
    return [
      'id,equipment_west_m,equipment_south_m,equipment_width_m,equipment_depth_m,zone_west_m,zone_south_m,zone_east_m,zone_north_m,zone_area_m2',
      for (final item in zones)
        [item.id, m(item.equipment.left), m(item.equipment.bottom), m(item.equipment.width), m(item.equipment.depth),
          m(item.zone.left), m(item.zone.bottom), m(item.zone.right), m(item.zone.top), item.areaM2.toStringAsFixed(6)].join(','),
      '',
    ].join('\r\n');
  }
}

/// Checks submitted rectangular extents; it does not derive or approve fall zones.
class PlaygroundCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == 'playground_measured_zones';

  PlaygroundCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    PlaygroundCadResult stop(String issue) => PlaygroundCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !playgroundCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Playground and save the measured equipment brief.');
    }
    final configs = sel.categoryId == 'institutional' ? const {null, 'outdoor'} : const {null, 'public_open_space'};
    if (!configs.contains(sel.configurationId) || !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use an outdoor playground without building floors, parking or separate Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = snap.answers;
    int? mm(Object? v, {bool zero = false, int max = 2000}) =>
        v is num && v.isFinite && v >= (zero ? 0 : .001) && v <= max ? (v * 1000).round() : null;
    final pw = mm(widthFt * .3048), pd = mm(depthFt * .3048);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd)) return stop('Enter the measured plot dimensions.');
    int? setback(String edge) {
      final v = a['${edge}_setback'];
      return v == null ? 0 : mm(v, zero: true);
    }
    final left = setback('left'), right = setback('right'), front = setback('front'), rear = setback('rear');
    if (left == null || right == null || front == null || rear == null || left + right >= pw || front + rear >= pd) {
      return stop('Supplied setbacks must leave a positive rectangular layout area.');
    }
    final field = PlanRect(left, front, pw - right, pd - rear);
    final pathX = mm(a['py_path_west'], zero: true), pathW = mm(a['py_path_width'], max: 100);
    final gap = mm(a['py_gap'], zero: true, max: 100);
    if (pathX == null || pathW == null || gap == null) return stop('Enter the measured path offset, path width and minimum separation.');
    final path = PlanRect(pathX, field.bottom, pathX + pathW, field.top);
    if (!field.contains(path)) return stop('The path crosses a side setback or the plot edge.');

    final raw = a['py_equipment'];
    if (raw is! String || raw.length > 5000) return stop('Enter 1–24 measured equipment records.');
    final rows = raw.split(RegExp(r'[;\r\n]+')).where((s) => s.trim().isNotEmpty).toList();
    if (rows.isEmpty || rows.length > 24) return stop('Enter 1–24 measured equipment records.');
    final ids = <String>{}, zones = <PlaygroundZone>[];
    final idPattern = RegExp(r'^[A-Za-z][A-Za-z0-9_-]{0,15}$');
    // Separations are true edge-to-edge distances, including diagonally separated corners.
    bool conflicts(PlanRect r, PlanRect s) {
      if (r.overlaps(s)) return true;
      final dx = math.max(r.left - s.right, s.left - r.right), dy = math.max(r.bottom - s.top, s.bottom - r.top);
      final x = math.max(0, dx), y = math.max(0, dy);
      return x * x + y * y < gap * gap;
    }
    for (var i = 0; i < rows.length; i++) {
      final parts = rows[i].split(',').map((s) => s.trim()).toList();
      if (parts.length != 9 || !idPattern.hasMatch(parts.first)) {
        return stop('Equipment record ${i + 1} needs a letter-led ID (up to 16 characters) and exactly eight dimensions.');
      }
      final id = parts.first;
      if (!ids.add(id.toUpperCase())) return stop('Equipment IDs must be unique: $id is repeated.');
      int? value(int column, {bool zero = false, int max = 100}) => mm(double.tryParse(parts[column]), zero: zero, max: max);
      final x = value(1, zero: true, max: 2000), y = value(2, zero: true, max: 2000);
      final w = value(3), d = value(4), wGap = value(5, zero: true), eGap = value(6, zero: true);
      final sGap = value(7, zero: true), nGap = value(8, zero: true);
      if (x == null || y == null || w == null || d == null || wGap == null || eGap == null || sGap == null || nGap == null) {
        return stop('Equipment $id needs finite nonnegative offsets/clearances and positive measured width/depth within input limits.');
      }
      final equipment = PlanRect(x, y, x + w, y + d);
      final zone = PlanRect(x - wGap, y - sGap, x + w + eGap, y + d + nGap);
      if (!field.contains(zone)) return stop('The zone for $id crosses the plot edge or a supplied setback.');
      if (conflicts(zone, path)) return stop('The zone for $id overlaps the path or misses the supplied path separation.');
      for (final other in zones) {
        if (conflicts(zone, other.zone)) return stop('The zones for ${other.id} and $id overlap or miss the supplied separation.');
      }
      zones.add(PlaygroundZone(id, equipment, zone));
    }

    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, PlanRect r) {
      line(layer, r.left, r.bottom, r.right, r.bottom);
      line(layer, r.right, r.bottom, r.right, r.top);
      line(layer, r.right, r.top, r.left, r.top);
      line(layer, r.left, r.top, r.left, r.bottom);
    }
    box('PLAY_PLOT', PlanRect(0, 0, pw, pd));
    if (left + right + front + rear > 0) box('PLAY_SETBACK', field);
    box('PLAY_PATH', path);
    final t = (math.max(pw, pd) / 90).clamp(30, 6500).toDouble();
    for (final item in zones) {
      box('PLAY_CLEARANCE', item.zone);
      final r = item.equipment;
      box('PLAY_EQUIPMENT', r);
      labels.add(CadLabel('PLAY_IDS', CadPoint(r.left + r.width / 2, r.bottom + r.depth / 2), item.id,
        math.min(t, math.min(r.depth / 3, r.width / (item.id.length + 1)))));
    }
    final zoneArea = zones.fold(0.0, (sum, z) => sum + z.areaM2), pathArea = path.width * path.depth / 1e6;
    final ax = pw + 2 * t;
    line('ANNOTATIONS', ax, pd - 2 * t, ax, pd);
    line('ANNOTATIONS', ax - t / 2, pd - t, ax, pd);
    line('ANNOTATIONS', ax + t / 2, pd - t, ax, pd);
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(ax, pd + t), 'N', t * .7),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 5 * t), 'MEASURED PLAYGROUND / LOCAL MM', t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 3.5 * t),
        '${zones.length} ZONES / ${zoneArea.toStringAsFixed(3)} M2 GROSS / ${pathArea.toStringAsFixed(3)} M2 PATH', t * .67),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 2 * t), 'SUBMITTED EXTENTS ONLY / NO SAFETY OR ACCESS CERTIFICATION', t * .65),
    ]);
    final bounds = PlanRect(math.min(-2 * t, pw / 2 - 30 * t).floor(), (-2 * t).floor(),
      math.max(ax + 3 * t, pw / 2 + 30 * t).ceil(), (pd + 7 * t).ceil());
    return PlaygroundCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels),
      zones: List.unmodifiable(zones), pathAreaM2: pathArea, zoneAreaM2: zoneArea);
  }
}
