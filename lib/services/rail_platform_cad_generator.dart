import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/rail_platform_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class RailPlatformCadResult {
  const RailPlatformCadResult({this.plan, this.section, this.issue, this.lengthMm = 0, this.walkMm = 0,
    this.offsetMm = 0, this.cutMm = 0, this.minRiseMm = 0, this.maxRiseMm = 0, this.maxGrade = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int lengthMm, walkMm, offsetMm, cutMm, minRiseMm, maxRiseMm;
  final double maxGrade;
}

/// Constant-offset reference geometry, not a train swept-envelope or boarding-gap check.
class RailPlatformCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['rail_platform_mode'] == 'survey_side_platform';

  RailPlatformCadResult generate(ProjectBrief brief) {
    RailPlatformCadResult stop(String issue) => RailPlatformCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !railPlatformCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Railway Station or Metro Station and save the surveyed side-platform brief.');
    }
    if (!const {null, 'linear_corridor', 'node_interchange', 'terminal_depot'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a single surveyed platform without buildings, parking or separate Space selections.');
    }
    final a = snap.answers;
    String? ref(String key) {
      final raw = a[key];
      if (raw is! String) return null;
      final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      return text.isNotEmpty && text.length <= 100 ? text : null;
    }
    final grid = ref('rp_grid'), datum = ref('rp_datum');
    if (grid == null || datum == null) return stop('Enter a projected metre grid and common elevation datum, each up to 100 characters.');
    List<String> rows(String key, int maxLength) {
      final raw = a[key];
      return raw is String && raw.length <= maxLength
          ? raw.split(RegExp(r'[;\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : [];
    }
    final decimal = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? surveyed(String raw, num min, num max) {
      final text = raw.trim(), value = double.tryParse(raw);
      return decimal.hasMatch(text) && value != null && value.isFinite && value >= min && value <= max ? (value * 1000).round() : null;
    }
    final axis = rows('rp_axis', 280);
    if (axis.length != 2) return stop('Enter exactly two track centreline controls, A then B: Easting,Northing.');
    final controls = <(int, int)>[];
    for (final row in axis) {
      final v = row.split(',');
      if (v.length != 2) return stop('Enter Easting,Northing for each track control.');
      final x = surveyed(v[0], -10000000, 10000000), y = surveyed(v[1], -10000000, 10000000);
      if (x == null || y == null) return stop('Enter valid projected metre controls with at most three decimal places.');
      controls.add((x, y));
    }
    final (ax, ay) = controls.first;
    final (bx, by) = controls.last;
    final dx = (bx - ax).toDouble(), dy = (by - ay).toDouble(), length = math.sqrt(dx * dx + dy * dy);
    if (length < 1 || length > 2000000) return stop('The straight track control length must be positive and at most 2 km.');
    double? number(String key, num min, num max) {
      final value = a[key];
      return value is num && value.isFinite && value >= min && value <= max ? value.toDouble() : null;
    }
    int? mm(String key, num min, num max) {
      final value = number(key, min, max);
      return value == null ? null : (value * 1000).round();
    }
    final side = a['rp_side'];
    final offset = mm('rp_offset', .001, 100), minOffset = mm('rp_min_offset', .001, 100);
    final width = mm('rp_width', .001, 100), band = mm('rp_edge_band', .001, 100), back = mm('rp_back_band', 0, 100);
    final needWalk = mm('rp_walk_min', .001, 100), fall = number('rp_crossfall', 0, 20);
    final low = mm('rp_rise_min', -10, 10), high = mm('rp_rise_max', -10, 10), gradeLimit = number('rp_grade_max', 0, 25);
    if (!const {'left', 'right'}.contains(side) || offset == null || minOffset == null || width == null || band == null || back == null ||
        needWalk == null || fall == null || low == null || high == null || gradeLimit == null) {
      return stop('Enter platform side, offset, widths, crossfall, edge-level band and grade limit.');
    }
    if (offset < minOffset) return stop('The platform edge is inside the supplied minimum static track offset.');
    final walk = width - band - back;
    if (walk < needWalk) return stop('The clear width between the two reserves is below the supplied minimum.');
    if (low > high) return stop('The minimum signed edge level difference cannot exceed its maximum.');

    final rawLevels = rows('rp_levels', 8000);
    if (rawLevels.length < 2 || rawLevels.length > 60) return stop('Enter 2–60 ordered level samples, starting and ending at the platform ends.');
    final levels = <({int ch, int rail, int edge})>[];
    String m(num v) => (v / 1000).toStringAsFixed(3);
    var maxGrade = 0.0;
    for (var i = 0; i < rawLevels.length; i++) {
      final v = rawLevels[i].split(',');
      if (v.length != 3) return stop('Use chainage, reference rail level and platform edge level in sample ${i + 1}.');
      final ch = surveyed(v[0], 0, 2000), rail = surveyed(v[1], -10000, 10000), edge = surveyed(v[2], -10000, 10000);
      if (ch == null || rail == null || edge == null) return stop('Use valid surveyed metres with at most three decimal places in sample ${i + 1}.');
      if (ch > length + 1e-6 || (levels.isNotEmpty && ch <= levels.last.ch)) {
        return stop('Sample chainages must strictly increase within the A–B track limits.');
      }
      final rise = edge - rail;
      if (rise < low || rise > high) return stop('At Ch ${m(ch)} m, edge minus rail is ${m(rise)} m, outside the supplied band.');
      if (levels.isNotEmpty) {
        final previous = levels.last;
        final grade = 100 * (edge - previous.edge).abs() / (ch - previous.ch);
        if (grade > gradeLimit + 1e-10) {
          return stop('Between Ch ${m(previous.ch)} and ${m(ch)} m, the platform-edge grade exceeds the supplied limit.');
        }
        if (grade > maxGrade) maxGrade = grade;
      }
      levels.add((ch: ch, rail: rail, edge: edge));
    }
    final start = levels.first.ch, end = levels.last.ch;
    var cut = levels.first, maxRise = cut.edge - cut.rail;
    for (final l in levels.skip(1)) {
      final rise = l.edge - l.rail;
      if (rise < cut.edge - cut.rail) cut = l;
      if (rise > maxRise) maxRise = rise;
    }
    final rise = cut.edge - cut.rail, outer = offset + width;
    final sign = side == 'left' ? 1 : -1;
    CadPoint p(num ch, num off) => CadPoint(ax + (dx * ch - sign * dy * off) / length, ay + (dy * ch + sign * dx * off) / length);
    final pLines = <CadLine>[], pLabels = <CadLabel>[];
    void plan(String layer, num ch, num off, num next, num out) => pLines.add(CadLine(layer, p(ch, off), p(next, out)));
    plan('RAIL_AXIS', 0, 0, length, 0);
    plan('RAIL_EDGE', start, offset, end, offset);
    plan('RAIL_EDGE', start, outer, end, outer);
    plan('RAIL_EDGE', start, offset, start, outer);
    plan('RAIL_EDGE', end, offset, end, outer);
    plan('RAIL_WALK', start, offset + band, end, offset + band);
    if (back > 0) plan('RAIL_WALK', start, outer - back, end, outer - back);
    plan('RAIL_CUT', cut.ch, 0, cut.ch, outer);
    final corners = [p(0, 0), p(length, 0), p(start, outer), p(end, outer), p(start, offset), p(end, offset)];
    final xmin = corners.map((p) => p.x).reduce(math.min), xmax = corners.map((p) => p.x).reduce(math.max);
    final ymin = corners.map((p) => p.y).reduce(math.min), ymax = corners.map((p) => p.y).reduce(math.max), center = (xmin + xmax) / 2;
    final t = (math.max(xmax - xmin, ymax - ymin) / 92).clamp(40, 16000).toDouble();
    final nx = math.max(center + 42 * t, xmax + 4 * t);
    pLabels.addAll([
      CadLabel('RAIL_AXIS', p(-1.7 * t, 0), 'A', t * .7),
      CadLabel('RAIL_AXIS', p(length + 1.7 * t, 0), 'B', t * .7),
      CadLabel('ANNOTATIONS', CadPoint(nx, ymax + t), 'GRID N', t * .65),
      CadLabel('ANNOTATIONS', CadPoint(center, ymax + 6.6 * t), 'SURVEYED SIDE PLATFORM / PLAN / PROJECTED MM', t),
      CadLabel('ANNOTATIONS', CadPoint(center, ymax + 5.2 * t), 'CH ${m(start)} TO ${m(end)} M / ${side.toString().toUpperCase()} OF A-B', t * .68),
      CadLabel('ANNOTATIONS', CadPoint(center, ymax + 3.8 * t), 'OFFSET ${m(offset)} M / CLEAR BAND ${m(walk)} M / SECTION CH ${m(cut.ch)} M', t * .64),
      CadLabel('ANNOTATIONS', CadPoint(center, ymax + 2.4 * t), 'GRID: $grid', t * .58),
      CadLabel('ANNOTATIONS', CadPoint(center, ymax + t), 'STATIC REFERENCE GEOMETRY ONLY / NO TRAIN OR BOARDING CLEARANCE', t * .58),
    ]);
    final head = CadPoint(nx, ymax);
    pLines.addAll([CadLine('ANNOTATIONS', CadPoint(nx, ymax - 2 * t), head),
      CadLine('ANNOTATIONS', CadPoint(nx - .5 * t, ymax - t), head), CadLine('ANNOTATIONS', CadPoint(nx + .5 * t, ymax - t), head)]);
    final planDxf = FloorPlanCad.fromEntities(bounds: PlanRect(math.min(xmin - 4 * t, center - 42 * t).floor(),
      (ymin - 4 * t).floor(), (nx + 4 * t).ceil(), (ymax + 8 * t).ceil()), lines: pLines, labels: pLabels);

    final crossLines = <CadLine>[], crossLabels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => crossLines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    double surface(num x) => rise.toDouble() - (x - offset) * fall / 100;
    line('RAIL_EDGE', offset, rise, offset + band, surface(offset + band));
    line('RAIL_WALK', offset + band, surface(offset + band), outer - back, surface(outer - back));
    if (back > 0) line('RAIL_EDGE', outer - back, surface(outer - back), outer, surface(outer));
    final crossMax = math.max(0, rise), crossMin = math.min(0, surface(outer));
    final st = (math.max(outer, crossMax - crossMin) / 57).clamp(14, 4500).toDouble();
    line('RAIL_AXIS', -st, 0, st, 0);
    line('RAIL_AXIS', 0, -.7 * st, 0, .7 * st);
    crossLabels.addAll([
      CadLabel('RAIL_AXIS', CadPoint(0, -2.2 * st), 'RAIL REF', .65 * st),
      CadLabel('ANNOTATIONS', CadPoint(outer / 2, crossMax + 7.1 * st), 'TRANSVERSE SECTION / TRUE SCALE MM', st),
      CadLabel('ANNOTATIONS', CadPoint(outer / 2, crossMax + 5.7 * st), 'CH ${m(cut.ch)} M / MINIMUM EDGE MINUS RAIL ${m(rise)} M', .69 * st),
      CadLabel('ANNOTATIONS', CadPoint(outer / 2, crossMax + 4.3 * st), 'RAIL REF RL ${m(cut.rail)} M = ZERO / EDGE RL ${m(cut.edge)} M', .65 * st),
      CadLabel('ANNOTATIONS', CadPoint(outer / 2, crossMax + 2.9 * st), 'CLEAR BAND ${m(walk)} M / FALL AWAY ${fall.toStringAsFixed(3)}%', .62 * st),
      CadLabel('ANNOTATIONS', CadPoint(outer / 2, crossMax + 1.5 * st), 'DATUM: $datum', .56 * st),
    ]);
    final section = FloorPlanCad.fromEntities(bounds: PlanRect(math.min(-4 * st, outer / 2 - 42 * st).floor(),
      (crossMin - 4 * st).floor(), math.max(outer + 4 * st, outer / 2 + 42 * st).ceil(), (crossMax + 8.5 * st).ceil()),
      lines: crossLines, labels: crossLabels);
    return RailPlatformCadResult(plan: planDxf, section: section, lengthMm: end - start, walkMm: walk, offsetMm: offset,
      cutMm: cut.ch, minRiseMm: rise, maxRiseMm: maxRise, maxGrade: maxGrade);
  }
}
