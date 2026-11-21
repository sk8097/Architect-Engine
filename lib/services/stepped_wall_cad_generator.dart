import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/stepped_wall_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);
typedef _Ground = ({int ch, int front, int back});

class SteppedWallRun {
  const SteppedWallRun(this.start, this.end, this.base, this.top, this.width);
  final int start, end, base, top, width;
  double get grossM3 => (end - start) * width * (top - base) / 1e9;
}

class SteppedWallCadResult {
  const SteppedWallCadResult({this.plan, this.profile, this.issue, this.runs = const [], this.widthMm = 0,
    this.maxVisibleMm = 0, this.minEmbedMm = 0, this.minTopMarginMm = 0});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final List<SteppedWallRun> runs;
  final int widthMm;
  final double maxVisibleMm, minEmbedMm, minTopMarginMm;
  int get lengthMm => runs.isEmpty ? 0 : runs.last.end - runs.first.start;
  double get grossM3 => runs.fold(0.0, (sum, r) => sum + r.grossM3);
  String? toCsv() => plan == null ? null : [
    'run,start_chainage_m,end_chainage_m,base_rl_m,top_rl_m,thickness_m,gross_wall_m3',
    for (var i = 0; i < runs.length; i++)
      '${i + 1},${_m(runs[i].start)},${_m(runs[i].end)},${_m(runs[i].base)},${_m(runs[i].top)},${_m(widthMm)},${runs[i].grossM3.toStringAsFixed(6)}',
    '',
  ].join('\r\n');
}

/// Geometric envelope and quantity, not a footing or retaining structure design.
class SteppedWallCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['stepped_wall_mode'] == steppedWallMode;

  SteppedWallCadResult generate(ProjectBrief brief) {
    SteppedWallCadResult stop(String issue) => SteppedWallCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !steppedWallCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Streetscape and save the current surveyed landscape wall brief.');
    }
    if (!const {null, 'linear_corridor', 'public_open_space'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one straight landscape wall without buildings, parking or separate Space selections.');
    }
    final a = req.answers;
    String? ref(String key) {
      final v = a[key];
      final text = v is String ? v.trim().replaceAll(RegExp(r'\s+'), ' ') : '';
      return text.isNotEmpty && text.length <= 100 ? text : null;
    }
    final grid = ref('sw_grid'), datum = ref('sw_datum');
    if (grid == null || datum == null) return stop('Enter a projected metre grid and elevation datum, each up to 100 characters.');
    List<String> rows(String key, int max) {
      final v = a[key];
      return v is String && v.length <= max
        ? v.split(RegExp(r'[;\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : const [];
    }
    final decimal = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? survey(String text, num min, num max) {
      final v = double.tryParse(text);
      return decimal.hasMatch(text.trim()) && v != null && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    }
    int? mm(String key, {num min = .001, num max = 20}) {
      final v = a[key];
      return v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    }
    final axis = rows('sw_axis', 280);
    if (axis.length != 2) return stop('Enter exactly two centreline controls, A then B.');
    final controls = <(int, int)>[];
    for (final row in axis) {
      final v = row.split(',');
      if (v.length != 2) return stop('Each centreline control needs Easting,Northing.');
      final x = survey(v[0], -10000000, 10000000), y = survey(v[1], -10000000, 10000000);
      if (x == null || y == null) return stop('Enter valid projected metre coordinates with up to three decimals.');
      controls.add((x, y));
    }
    final (ax, ay) = controls.first;
    final (bx, by) = controls.last;
    final dx = (bx - ax).toDouble(), dy = (by - ay).toDouble(), baseline = math.sqrt(dx * dx + dy * dy);
    if (baseline < 1 || baseline > 2000000) return stop('The straight A–B baseline must be positive and at most 2 km.');
    final side = a['sw_back_side'];
    final width = mm('sw_width', max: 10), embed = mm('sw_embed'), cap = mm('sw_top_margin', min: 0), visible = mm('sw_visible_max');
    if (!const {'left', 'right'}.contains(side) || width == null || embed == null || cap == null || visible == null) {
      return stop('Enter the back side, wall thickness, minimum base depth and top margin, and maximum exposed height.');
    }
    final inputs = rows('sw_ground', 7500);
    if (inputs.length < 2 || inputs.length > 80) return stop('Enter 2–80 ground samples spanning the wall.');
    final ground = <_Ground>[];
    for (var i = 0; i < inputs.length; i++) {
      final f = inputs[i].split(',');
      if (f.length != 3) return stop('Ground sample ${i + 1} needs chainage, front level and back level.');
      final ch = survey(f[0], 0, 2000), front = survey(f[1], -10000, 10000), back = survey(f[2], -10000, 10000);
      if (ch == null || front == null || back == null) return stop('Use measured metres with up to three decimals in ground sample ${i + 1}.');
      if (ch > baseline + 1e-7 || (ground.isNotEmpty && ch <= ground.last.ch)) {
        return stop('Ground sample chainages must increase within the surveyed A–B span.');
      }
      if (back < front) return stop('Back ground is lower than front ground at Ch ${_m(ch)} m. This template uses one back side throughout.');
      ground.add((ch: ch, front: front, back: back));
    }
    final lo = ground.first.ch, hi = ground.last.ch;
    final steps = rows('sw_steps', 4500);
    if (steps.isEmpty || steps.length > 40) return stop('Enter 1–40 wall steps ending at the last ground sample.');
    final runs = <SteppedWallRun>[];
    var start = lo;
    var maxVisible = 0.0, minEmbed = double.infinity, minCap = double.infinity;
    for (var i = 0; i < steps.length; i++) {
      final f = steps[i].split(',');
      if (f.length != 3) return stop('Run ${i + 1} needs end chainage, base level and top level.');
      final end = survey(f[0], 0, 2000), base = survey(f[1], -10000, 10000), top = survey(f[2], -10000, 10000);
      if (end == null || end <= start || end > hi) return stop('Run ${i + 1} must end at an increasing chainage within the ground samples.');
      if (base == null || top == null || base >= top) return stop('Run ${i + 1} needs a valid top level above its base level.');
      final checkpoints = [start, for (final g in ground) if (g.ch > start && g.ch < end) g.ch, end];
      var segment = 0;
      for (final ch in checkpoints) {
        while (ch > ground[segment + 1].ch) {
          segment++;
        }
        final a = ground[segment], b = ground[segment + 1];
        final span = b.ch - a.ch, advance = ch - a.ch;
        // Work with scaled integers at interpolated endpoints for exact threshold comparisons.
        final frontN = a.front * span + (b.front - a.front) * advance;
        final backN = a.back * span + (b.back - a.back) * advance;
        final embedN = frontN - base * span, capN = top * span - backN, visibleN = top * span - frontN;
        final where = 'Run ${i + 1} at Ch ${_m(ch)} m';
        if (embedN < embed * span) return stop('$where has insufficient base depth below front ground.');
        if (capN < cap * span) return stop('$where has insufficient top margin above back ground.');
        if (visibleN > visible * span) return stop('$where exceeds the submitted exposed wall height above front ground.');
        minEmbed = math.min(minEmbed, embedN / span);
        minCap = math.min(minCap, capN / span);
        maxVisible = math.max(maxVisible, visibleN / span);
      }
      runs.add(SteppedWallRun(start, end, base, top, width));
      start = end;
    }
    if (start != hi) return stop('The last run must end at the last ground sample, Ch ${_m(hi)} m.');

    final sign = side == 'left' ? 1 : -1;
    CadPoint p(num ch, num off) => CadPoint(ax + (dx * ch - sign * dy * off) / baseline,
      ay + (dy * ch + sign * dx * off) / baseline);
    final plan = _WallSheet(), profile = _WallSheet(), half = width / 2;
    void planLine(String layer, num ch, num off, num next, num out) => plan.line(layer, p(ch, off), p(next, out));
    planLine('SW_AXIS', 0, 0, baseline, 0);
    planLine('SW_BACK', lo, half, hi, half);
    planLine('SW_FRONT', lo, -half, hi, -half);
    for (final ch in [lo, for (final r in runs) r.end]) {
      planLine('SW_STEP', ch, -half, ch, half);
    }
    final ext = [p(0, 0), p(baseline, 0), for (final ch in [lo, hi]) ...[p(ch, half), p(ch, -half)]];
    final x0 = ext.map((p) => p.x).reduce(math.min), x1 = ext.map((p) => p.x).reduce(math.max);
    final y0 = ext.map((p) => p.y).reduce(math.min), y1 = ext.map((p) => p.y).reduce(math.max);
    final t = (math.max(x1 - x0, y1 - y0) / 89).clamp(20, 15000).toDouble();
    for (var i = 0; i < runs.length; i++) {
      final r = runs[i];
      plan.labels.add(CadLabel('SW_STEP', p((r.start + r.end) / 2, half + t), 'R${i + 1}', .65 * t));
    }
    final cx = (x0 + x1) / 2, nx = x1 + 3 * t;
    final tip = CadPoint(nx, y1);
    plan.line('ANNOTATIONS', CadPoint(nx, y1 - 2 * t), tip);
    plan.line('ANNOTATIONS', CadPoint(nx - .5 * t, y1 - t), tip);
    plan.line('ANNOTATIONS', CadPoint(nx + .5 * t, y1 - t), tip);
    plan.labels.addAll([CadLabel('ANNOTATIONS', CadPoint(nx, y1 + t), 'GRID N', .65 * t),
      CadLabel('SW_AXIS', p(-1.5 * t, 0), 'A', .65 * t), CadLabel('SW_AXIS', p(baseline + 1.5 * t, 0), 'B', .65 * t)]);
    plan.heading(cx, y1 + 2.5 * t, t, [
      'SURVEYED STEPPED LANDSCAPE WALL / PLAN / PROJECTED MM',
      'CH ${_m(lo)} TO ${_m(hi)} M / THICKNESS ${_m(width)} M / ${runs.length} RUN(S)',
      'GRID: $grid / BACK: ${side.toString().toUpperCase()} OF A-B / ENVELOPE ONLY',
    ]);
    final minRl = runs.map((r) => r.base).reduce(math.min), maxRl = runs.map((r) => r.top).reduce(math.max);
    final zero = (minRl / 1000).floor() * 1000;
    CadPoint q(num ch, num level) => CadPoint(ch, level - zero);
    void plot(String layer, int ch, int level, int next, int endLevel) {
      if (ch != next || level != endLevel) profile.line(layer, q(ch, level), q(next, endLevel));
    }
    for (var i = 1; i < ground.length; i++) {
      final a = ground[i - 1], b = ground[i];
      plot('SW_FRONT', a.ch, a.front, b.ch, b.front);
      plot('SW_BACK', a.ch, a.back, b.ch, b.back);
    }
    for (var i = 0; i < runs.length; i++) {
      final r = runs[i];
      plot('SW_ENVELOPE', r.start, r.top, r.end, r.top);
      plot('SW_ENVELOPE', r.start, r.base, r.end, r.base);
      if (i == 0) {
        plot('SW_ENVELOPE', r.start, r.base, r.start, r.top);
      } else {
        final previous = runs[i - 1];
        // Draw only the exposed top/base level changes, not the shared interior face.
        plot('SW_STEP', r.start, previous.top, r.start, r.top);
        plot('SW_STEP', r.start, previous.base, r.start, r.base);
      }
      if (i == runs.length - 1) plot('SW_ENVELOPE', r.end, r.base, r.end, r.top);
    }
    final gross = runs.fold(0.0, (sum, r) => sum + r.grossM3);
    final st = (math.max(hi - lo, maxRl - minRl) / 89).clamp(20, 15000).toDouble();
    profile.labels.addAll([CadLabel('SW_AXIS', q(lo, zero - st), 'CH ${_m(lo)}', .65 * st),
      CadLabel('SW_AXIS', q(hi, zero - st), 'CH ${_m(hi)}', .65 * st)]);
    profile.heading((lo + hi) / 2, maxRl - zero + st, st, [
      'LONGITUDINAL PROFILE / TRUE SCALE MM / RL ZERO AT ${_m(zero)} M',
      'DATUM: $datum / GROSS WALL VOLUME ${gross.toStringAsFixed(3)} M3',
      'MAX EXPOSED ${_m(maxVisible)} M / MIN BASE DEPTH ${_m(minEmbed)} M / MIN TOP MARGIN ${_m(minCap)} M',
      'NO FOOTING, DRAINAGE, MATERIAL DESIGN OR STABILITY CHECK',
    ]);
    return SteppedWallCadResult(plan: plan.drawing(t), profile: profile.drawing(st), runs: List.unmodifiable(runs), widthMm: width,
      maxVisibleMm: maxVisible, minEmbedMm: minEmbed, minTopMarginMm: minCap);
  }
}

class _WallSheet {
  final lines = <CadLine>[], labels = <CadLabel>[];
  void line(String layer, CadPoint a, CadPoint b) => lines.add(CadLine(layer, a, b));
  void heading(num x, num y, double size, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      labels.add(CadLabel('ANNOTATIONS', CadPoint(x, y + (rows.length - i) * 1.35 * size), rows[i], i == 0 ? size : .61 * size));
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
