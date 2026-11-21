import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/underpass_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);
typedef _Level = ({int ch, int rl});

class UnderpassCadResult {
  const UnderpassCadResult({this.plan, this.profile, this.issue, this.lengthMm = 0, this.coveredMm = 0,
    this.clearMm = 0, this.minHeadMm = 0, this.headStationMm = 0, this.maxGrade = 0});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final int lengthMm, coveredMm, clearMm, headStationMm;
  final double minHeadMm, maxGrade;
}

/// Horizontal envelope and centreline vertical reference, not accessibility design.
class UnderpassCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['underpass_mode'] == underpassMode;

  UnderpassCadResult generate(ProjectBrief brief) {
    UnderpassCadResult stop(String issue) => UnderpassCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !underpassCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Underpass and save the current pedestrian survey brief.');
    }
    if (!const {null, 'linear_corridor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one straight pedestrian corridor without buildings, parking or separate Space selections.');
    }
    final a = req.answers;
    String? ref(String key) {
      final raw = a[key];
      final text = raw is String ? raw.trim().replaceAll(RegExp(r'\s+'), ' ') : '';
      return text.isNotEmpty && text.length <= 100 ? text : null;
    }
    final grid = ref('up_grid'), datum = ref('up_datum');
    if (grid == null || datum == null) return stop('Enter the projected metre grid and elevation datum, each up to 100 characters.');
    List<String> rows(String key, int max) {
      final raw = a[key];
      return raw is String && raw.length <= max
        ? raw.split(RegExp(r'[;\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : const [];
    }
    final decimal = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? survey(String text, num min, num max) {
      final v = double.tryParse(text);
      return decimal.hasMatch(text.trim()) && v != null && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    }
    double? number(String key, num min, num max) {
      final v = a[key];
      return v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    }
    int? mm(String key, num max) {
      final v = number(key, .001, max);
      return v == null ? null : (1000 * v).round();
    }
    final axis = rows('up_axis', 280);
    if (axis.length != 2) return stop('Enter exactly two walkway centreline controls, A then B.');
    final controls = <(int, int)>[];
    for (final row in axis) {
      final values = row.split(',');
      if (values.length != 2) return stop('Enter Easting,Northing for each projected control.');
      final x = survey(values[0], -10000000, 10000000), y = survey(values[1], -10000000, 10000000);
      if (x == null || y == null) return stop('Enter valid projected controls with up to three decimals.');
      controls.add((x, y));
    }
    final (ax, ay) = controls.first;
    final (bx, by) = controls.last;
    final dx = (bx - ax).toDouble(), dy = (by - ay).toDouble(), baseline = math.sqrt(dx * dx + dy * dy);
    if (baseline < 1 || baseline > 2000000) return stop('Use a positive A–B baseline of at most 2 km.');
    final clear = mm('up_clear', 100), minWidth = mm('up_min_width', 100), wall = mm('up_wall', 10), corridor = mm('up_corridor', 200);
    final requiredHead = mm('up_head', 20), gradeLimit = number('up_grade', 0, 100);
    if (clear == null || minWidth == null || wall == null || corridor == null || requiredHead == null || gradeLimit == null) {
      return stop('Enter valid corridor width, wall and walkway dimensions, minimum headroom and maximum grade.');
    }
    if (clear < minWidth) return stop('The clear walkway is narrower than the submitted minimum.');
    if (clear + 2 * wall > corridor) return stop('The walkway plus both wall envelopes do not fit the submitted corridor width.');
    final traces = <List<_Level>>[];
    for (final (key, label) in [('up_walk', 'Walkway'), ('up_soffit', 'Soffit')]) {
      final input = rows(key, 7500);
      if (input.length < 2 || input.length > 80) return stop('$label needs 2–80 ordered chainage and level samples.');
      final samples = <_Level>[];
      for (var i = 0; i < input.length; i++) {
        final v = input[i].split(',');
        if (v.length != 2) return stop('$label sample ${i + 1} needs chainage and elevation.');
        final ch = survey(v[0], 0, 2000), rl = survey(v[1], -10000, 10000);
        if (ch == null || rl == null) return stop('$label sample ${i + 1} needs measured metres with up to three decimals.');
        if (ch > baseline + 1e-7 || (samples.isNotEmpty && ch <= samples.last.ch)) {
          return stop('$label chainages must strictly increase within the surveyed A–B span.');
        }
        samples.add((ch: ch, rl: rl));
      }
      traces.add(samples);
    }
    final walk = traces[0], soffit = traces[1];
    final start = walk.first.ch, end = walk.last.ch, entry = soffit.first.ch, exit = soffit.last.ch;
    if (entry <= start || exit >= end) return stop('Both covered-span portals must be strictly inside the walkway, with an uncovered approach at each end.');
    var grade = 0.0;
    for (var i = 1; i < walk.length; i++) {
      final l = walk[i - 1], r = walk[i];
      final slope = (r.rl - l.rl).abs() * 100 / (r.ch - l.ch);
      if (slope > gradeLimit + 1e-10) return stop('Walkway grade from Ch ${_m(l.ch)} to ${_m(r.ch)} m is ${slope.toStringAsFixed(3)}%, above the submitted maximum.');
      grade = math.max(grade, slope);
    }
    double levelAt(List<_Level> trace, int ch) {
      for (var i = 1; i < trace.length; i++) {
        final l = trace[i - 1], r = trace[i];
        if (ch <= r.ch) return l.rl.toDouble() + (r.rl - l.rl) * (ch - l.ch) / (r.ch - l.ch);
      }
      return trace.last.rl.toDouble(); // Exact final point; no caller extrapolates.
    }
    final stations = {for (final l in soffit) l.ch, for (final l in walk) if (l.ch > entry && l.ch < exit) l.ch}.toList()..sort();
    var minHead = double.infinity, cut = entry;
    // A difference of piecewise-linear profiles is linear between their combined knots.
    for (final ch in stations) {
      final h = levelAt(soffit, ch) - levelAt(walk, ch);
      if (h < minHead - 1e-8) {
        minHead = h;
        cut = ch;
      }
    }
    if (minHead < requiredHead - 1e-8) return stop('Vertical headroom at Ch ${_m(cut)} m is ${_m(minHead)} m, below the submitted minimum.');

    final plan = _Sheet(), profile = _Sheet();
    CadPoint p(num ch, num offset) => CadPoint(ax + (dx * ch - dy * offset) / baseline, ay + (dy * ch + dx * offset) / baseline);
    void planLine(String layer, num s, num o, num e, num q) => plan.line(layer, p(s, o), p(e, q));
    final halved = clear / 2, edge = halved + wall, limit = corridor / 2;
    planLine('UP_AXIS', 0, 0, baseline, 0);
    for (final sign in [-1, 1]) {
      // At zero lateral reserve the outside wall coincides with the corridor edge
      // for the covered span, so divide that shared run instead of drawing it twice.
      if (edge == limit) {
        planLine('UP_LIMIT', 0, sign * limit, entry, sign * limit);
        planLine('UP_LIMIT', exit, sign * limit, baseline, sign * limit);
      } else {
        planLine('UP_LIMIT', 0, sign * limit, baseline, sign * limit);
      }
      planLine('UP_WALK', start, sign * halved, end, sign * halved);
      planLine('UP_WALL', entry, sign * edge, exit, sign * edge);
      planLine('UP_WALL', entry, sign * halved, entry, sign * edge);
      planLine('UP_WALL', exit, sign * halved, exit, sign * edge);
    }
    planLine('UP_PORTAL', entry, -halved, entry, halved);
    planLine('UP_PORTAL', exit, -halved, exit, halved);
    final ext = [for (final ch in [0, baseline]) ...[p(ch, limit), p(ch, -limit)]];
    final x0 = ext.map((p) => p.x).reduce(math.min), x1 = ext.map((p) => p.x).reduce(math.max);
    final y0 = ext.map((p) => p.y).reduce(math.min), y1 = ext.map((p) => p.y).reduce(math.max);
    final t = (math.max(x1 - x0, y1 - y0) / 92).clamp(20, 15000).toDouble(), nx = x1 + 3 * t;
    plan.labels.addAll([CadLabel('UP_AXIS', p(-1.5 * t, 0), 'A', .65 * t), CadLabel('UP_AXIS', p(baseline + 1.5 * t, 0), 'B', .65 * t),
      CadLabel('UP_PORTAL', p(entry, edge + t), 'P1', .6 * t), CadLabel('UP_PORTAL', p(exit, edge + t), 'P2', .6 * t),
      CadLabel('ANNOTATIONS', CadPoint(nx, y1 + t), 'GRID N', .65 * t)]);
    final tip = CadPoint(nx, y1);
    plan.line('ANNOTATIONS', CadPoint(nx, y1 - 2 * t), tip);
    plan.line('ANNOTATIONS', CadPoint(nx - .5 * t, y1 - t), tip);
    plan.line('ANNOTATIONS', CadPoint(nx + .5 * t, y1 - t), tip);
    plan.heading((x0 + x1) / 2, y1 + 2 * t, t, [
      'SURVEYED PEDESTRIAN UNDERPASS / PROJECTED MM',
      'PORTALS CH ${_m(entry)} AND ${_m(exit)} M / WALK ${_m(clear)} M CLEAR',
      'GRID: $grid / WALL ENVELOPES ONLY',
    ]);
    final low = walk.map((x) => x.rl).reduce(math.min);
    final high = [...walk, ...soffit].map((x) => x.rl).reduce(math.max);
    final zero = (low / 1000).floor() * 1000;
    CadPoint q(num ch, num rl) => CadPoint(ch, rl - zero);
    for (final (layer, trace) in [('UP_WALK', walk), ('UP_SOFFIT', soffit)]) {
      for (var i = 1; i < trace.length; i++) {
        final a = trace[i - 1], b = trace[i];
        profile.line(layer, q(a.ch, a.rl), q(b.ch, b.rl));
      }
    }
    for (final ch in [entry, exit]) {
      profile.line('UP_PORTAL', q(ch, levelAt(walk, ch)), q(ch, levelAt(soffit, ch)));
    }
    if (cut != entry && cut != exit) profile.line('UP_HEAD', q(cut, levelAt(walk, cut)), q(cut, levelAt(soffit, cut)));
    final st = (math.max(end - start, high - low) / 90).clamp(20, 15000).toDouble();
    profile.labels.addAll([CadLabel('UP_AXIS', q(start, zero - st), 'CH ${_m(start)}', .6 * st),
      CadLabel('UP_AXIS', q(end, zero - st), 'CH ${_m(end)}', .6 * st),
      CadLabel('UP_HEAD', q(cut, levelAt(soffit, cut) + st), 'LOW HEADROOM', .6 * st)]);
    profile.heading((start + end) / 2, high - zero + 2 * st, st, [
      'LONGITUDINAL PROFILE / TRUE SCALE MM / RL ZERO AT ${_m(zero)} M',
      'DATUM: $datum / MAX ABSOLUTE WALKWAY GRADE ${grade.toStringAsFixed(3)}%',
      'MIN VERTICAL HEADROOM ${_m(minHead)} M AT CH ${_m(cut)} M / CENTRELINE ONLY',
    ]);
    return UnderpassCadResult(plan: plan.drawing(t), profile: profile.drawing(st), lengthMm: end - start,
      coveredMm: exit - entry, clearMm: clear, minHeadMm: minHead, headStationMm: cut, maxGrade: grade);
  }
}

class _Sheet {
  final lines = <CadLine>[], labels = <CadLabel>[];
  void line(String layer, CadPoint a, CadPoint b) => lines.add(CadLine(layer, a, b));
  void heading(num x, num y, double t, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      labels.add(CadLabel('ANNOTATIONS', CadPoint(x, y + (rows.length - i) * 1.35 * t), rows[i], i == 0 ? t : .62 * t));
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
