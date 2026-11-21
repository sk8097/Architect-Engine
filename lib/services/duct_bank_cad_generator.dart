import 'dart:math' as math;

import '../data/duct_bank_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

typedef _Levels = ({int station, int ground, int top});

class _Crossing {
  const _Crossing(this.id, this.station, this.low, this.high, this.gap, this.bankFace, this.utilityFace);
  final String id;
  final int station, low, high, utilityFace;
  final double gap, bankFace;
}

class DuctBankCadResult {
  const DuctBankCadResult({this.plan, this.profile, this.issue, this.lengthMm = 0, this.widthMm = 0,
    this.coverMm = 0, this.coverStationMm = 0, this.crossings = 0, this.crossingGapMm = 0, this.crossingId = ''});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final int lengthMm, widthMm, coverMm, coverStationMm, crossings;
  final double crossingGapMm;
  final String crossingId;
}

/// Centreline cover and station-only vertical crossing checks, not utility design.
class DuctBankCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['duct_bank_mode'] == ductBankModeId;

  DuctBankCadResult generate(ProjectBrief brief) {
    DuctBankCadResult stop(String issue) => DuctBankCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !ductBankCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Telecom Network and save the current surveyed duct-bank brief.');
    }
    if (!const {null, 'outdoor_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one straight network run without buildings, parking or separate Space selections.');
    }
    final a = req.answers;
    String? ref(String key) {
      final raw = a[key];
      if (raw is! String) return null;
      final v = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      return v.isNotEmpty && v.length <= 100 ? v : null;
    }
    final grid = ref('db_grid'), datum = ref('db_datum');
    if (grid == null || datum == null) return stop('Enter a projected metre grid and common elevation datum, each up to 100 characters.');
    List<String> rows(String key, int max) {
      final raw = a[key];
      return raw is String && raw.length <= max
        ? raw.split(RegExp(r'[;\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : const [];
    }
    final decimal = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? survey(String s, num min, num max) {
      final v = double.tryParse(s);
      return decimal.hasMatch(s.trim()) && v != null && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    }
    int? mm(String key, {int max = 20}) {
      final v = a[key];
      return v is num && v.isFinite && v >= .001 && v <= max ? (v * 1000).round() : null;
    }
    final axis = rows('db_axis', 280);
    if (axis.length != 2) return stop('Enter exactly two duct-bank centreline controls A then B.');
    final controls = <(int, int)>[];
    for (final row in axis) {
      final v = row.split(',');
      if (v.length != 2) return stop('Each centreline control needs Easting,Northing.');
      final x = survey(v[0], -10000000, 10000000), y = survey(v[1], -10000000, 10000000);
      if (x == null || y == null) return stop('Enter valid projected metre coordinates with up to three decimal places.');
      controls.add((x, y));
    }
    final (ax, ay) = controls.first;
    final (bx, by) = controls.last;
    final dx = (bx - ax).toDouble(), dy = (by - ay).toDouble(), baseline = math.sqrt(dx * dx + dy * dy);
    if (baseline < 1 || baseline > 2000000) return stop('The straight A–B baseline must be positive and at most 2 km.');
    final width = mm('db_width'), depth = mm('db_depth', max: 10), cover = mm('db_cover'), gap = mm('db_gap');
    if (width == null || depth == null || cover == null || gap == null) return stop('Enter valid positive bank width, bank depth, cover and crossing clearance.');
    final rawLevels = rows('db_levels', 7500);
    if (rawLevels.length < 2 || rawLevels.length > 80) return stop('Enter 2–80 ordered level samples spanning the bank.');
    final levels = <_Levels>[];
    var governingCover = 20000001, coverStation = 0;
    for (var i = 0; i < rawLevels.length; i++) {
      final v = rawLevels[i].split(',');
      if (v.length != 3) return stop('Sample ${i + 1} needs chainage, ground level and proposed bank top level.');
      final ch = survey(v[0], 0, 2000), ground = survey(v[1], -10000, 10000), top = survey(v[2], -10000, 10000);
      if (ch == null || ground == null || top == null) return stop('Sample ${i + 1} needs measured metres with up to three decimals.');
      if (ch > baseline + 1e-7 || (levels.isNotEmpty && ch <= levels.last.station)) {
        return stop('Level sample chainages must strictly increase within the surveyed A–B limits.');
      }
      final c = ground - top;
      if (c < cover) return stop('Cover at Ch ${_m(ch)} m is ${_m(c)} m, below the submitted minimum.');
      if (c < governingCover) {
        governingCover = c;
        coverStation = ch;
      }
      levels.add((station: ch, ground: ground, top: top));
    }
    final start = levels.first.station, end = levels.last.station;
    final rawCrossings = rows('db_crossings', 4000);
    if (rawCrossings.isEmpty || rawCrossings.length > 30) return stop('Enter 1–30 ordered measured utility crossings.');
    final crossings = <_Crossing>[], ids = <String>{};
    var segment = 0;
    for (var i = 0; i < rawCrossings.length; i++) {
      final v = rawCrossings[i].split(',');
      if (v.length != 4) return stop('Crossing ${i + 1} needs ID, chainage, existing lower level and existing upper level.');
      final id = v[0].trim();
      if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,15}$').hasMatch(id)) return stop('Use a 1–16 character crossing ID starting with a letter or number.');
      if (!ids.add(id.toUpperCase())) return stop('Crossing ID $id is repeated.');
      final ch = survey(v[1], 0, 2000), low = survey(v[2], -10000, 10000), high = survey(v[3], -10000, 10000);
      if (ch == null || ch < start || ch > end || (crossings.isNotEmpty && ch <= crossings.last.station)) {
        return stop('Crossing $id must be at an increasing chainage within the surveyed bank span.');
      }
      if (low == null || high == null || low >= high) return stop('Crossing $id needs measured lower and upper levels with positive envelope depth.');
      while (ch > levels[segment + 1].station) {
        segment++;
      }
      final l = levels[segment], r = levels[segment + 1];
      // Evaluate the linearly interpolated level as a rational in mm to avoid
      // rejecting an exactly compliant gap due to floating-point rounding.
      final span = r.station - l.station, advance = ch - l.station;
      final topN = l.top * span + (r.top - l.top) * advance;
      final bottomN = topN - depth * span;
      final above = low * span >= topN;
      final below = high * span <= bottomN;
      if (!above && !below) return stop('Crossing $id overlaps the proposed duct bank at Ch ${_m(ch)} m.');
      final gapN = above ? low * span - topN : bottomN - high * span;
      if (gapN < gap * span) return stop('Crossing $id leaves only ${_m(gapN / span)} m of vertical clearance at Ch ${_m(ch)} m.');
      crossings.add(_Crossing(id, ch, low, high, gapN / span, (above ? topN : bottomN) / span, above ? low : high));
    }
    final tightest = crossings.reduce((a, b) => b.gap < a.gap ? b : a);
    final coverLevel = levels.firstWhere((l) => l.station == coverStation);

    CadPoint p(num ch, num off) => CadPoint(ax + (dx * ch - dy * off) / baseline, ay + (dy * ch + dx * off) / baseline);
    final plan = _Sheet(), profile = _Sheet();
    final half = width / 2;
    plan.segment('DUCT_AXIS', p(0, 0), p(baseline, 0));
    final corners = [p(start, -half), p(end, -half), p(end, half), p(start, half)];
    for (var i = 0; i < corners.length; i++) {
      plan.segment('DUCT_BANK', corners[i], corners[(i + 1) % corners.length]);
    }
    final extent = [...corners, p(0, 0), p(baseline, 0)];
    final xmin = extent.map((p) => p.x).reduce(math.min), xmax = extent.map((p) => p.x).reduce(math.max);
    final ymin = extent.map((p) => p.y).reduce(math.min), ymax = extent.map((p) => p.y).reduce(math.max);
    final t = (math.max(xmax - xmin, ymax - ymin) / 91).clamp(20, 16000).toDouble();
    plan.labels.addAll([CadLabel('DUCT_AXIS', p(-1.5 * t, 0), 'A', .7 * t),
      CadLabel('DUCT_AXIS', p(baseline + 1.5 * t, 0), 'B', .7 * t)]);
    for (final c in crossings) {
      plan.segment('DUCT_CROSS', p(c.station, -half - t), p(c.station, half + t));
      plan.labels.add(CadLabel('DUCT_CROSS', p(c.station, half + 1.65 * t), c.id, .58 * t));
    }
    final nx = math.max(xmax, (xmin + xmax) / 2 + 42 * t) + 4 * t;
    final tip = CadPoint(nx, ymax);
    plan.segment('ANNOTATIONS', CadPoint(nx, ymax - 2 * t), tip);
    plan.segment('ANNOTATIONS', CadPoint(nx - .5 * t, ymax - t), tip);
    plan.segment('ANNOTATIONS', CadPoint(nx + .5 * t, ymax - t), tip);
    plan.labels.add(CadLabel('ANNOTATIONS', CadPoint(nx, ymax + t), 'GRID N', .65 * t));
    plan.heading((xmin + xmax) / 2, ymax + 3.5 * t, t, [
      'SURVEYED TELECOM DUCT BANK / PLAN / PROJECTED MM',
      'CH ${_m(start)} TO ${_m(end)} M / ${_m(width)} M WIDE / ${crossings.length} CROSSING(S)',
      'GRID: $grid / CROSSING TICKS ARE STATIONS, NOT UTILITY ALIGNMENTS',
    ]);
    final planDxf = plan.drawing(xmin - 3 * t, ymin - 6 * t, nx + t, ymax + 3 * t, t);

    final minLevel = [for (final l in levels) l.top - depth, for (final c in crossings) c.low].reduce(math.min);
    final maxLevel = [for (final l in levels) l.ground, for (final c in crossings) c.high].reduce(math.max);
    final zero = (minLevel / 1000).floor() * 1000;
    CadPoint q(num ch, num rl) => CadPoint(ch, rl - zero);
    for (var i = 1; i < levels.length; i++) {
      final a = levels[i - 1], b = levels[i];
      profile.segment('DUCT_GROUND', q(a.station, a.ground), q(b.station, b.ground));
      profile.segment('DUCT_BANK', q(a.station, a.top), q(b.station, b.top));
      profile.segment('DUCT_BANK', q(a.station, a.top - depth), q(b.station, b.top - depth));
    }
    for (final l in [levels.first, levels.last]) {
      profile.segment('DUCT_BANK', q(l.station, l.top - depth), q(l.station, l.top));
    }
    profile.segment('DUCT_COVER', q(coverStation, coverLevel.top), q(coverStation, coverLevel.ground));
    final st = (math.max(end - start, maxLevel - minLevel) / 96).clamp(15, 14000).toDouble();
    for (final c in crossings) {
      profile.segment('DUCT_CROSS', q(c.station, c.low), q(c.station, c.high));
      profile.segment('DUCT_GAP', q(c.station, c.bankFace), q(c.station, c.utilityFace));
      profile.labels.add(CadLabel('DUCT_CROSS', q(c.station, c.high + st), c.id, .58 * st));
    }
    profile.segment('DUCT_AXIS', q(start, zero), q(end, zero));
    profile.labels.addAll([CadLabel('DUCT_AXIS', q(start, zero - 1.3 * st), 'CH ${_m(start)}', .6 * st),
      CadLabel('DUCT_AXIS', q(end, zero - 1.3 * st), 'CH ${_m(end)}', .6 * st)]);
    profile.heading((start + end) / 2, maxLevel - zero + 2 * st, st, [
      'LONGITUDINAL PROFILE / TRUE SCALE MM',
      'X = CHAINAGE / Y ZERO AT RL ${_m(zero)} M / DATUM: $datum',
      'MIN COVER ${_m(governingCover)} M AT CH ${_m(coverStation)} / MIN CROSSING GAP ${_m(tightest.gap)} M AT ${tightest.id}',
      'CENTRELINE COVER AND STATION-ONLY CROSSING CHECKS',
    ]);
    final profileDxf = profile.drawing(start, -2 * st, end, maxLevel - zero + 2 * st, st);
    return DuctBankCadResult(plan: planDxf, profile: profileDxf, lengthMm: end - start, widthMm: width,
      coverMm: governingCover, coverStationMm: coverStation, crossings: crossings.length,
      crossingGapMm: tightest.gap, crossingId: tightest.id);
  }
}

class _Sheet {
  final lines = <CadLine>[], labels = <CadLabel>[];
  void segment(String layer, CadPoint a, CadPoint b) => lines.add(CadLine(layer, a, b));
  void heading(num x, num y, double t, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      labels.add(CadLabel('ANNOTATIONS', CadPoint(x, y + (rows.length - i) * 1.35 * t), rows[i], i == 0 ? t : .59 * t));
    }
  }
  FloorPlanCad drawing(num left, num low, num right, num top, double t) {
    final points = [for (final l in lines) ...[l.start, l.end]];
    for (final p in points) {
      left = math.min(left, p.x);
      low = math.min(low, p.y);
      right = math.max(right, p.x);
      top = math.max(top, p.y);
    }
    for (final l in labels) {
      final half = l.text.length * l.height * .42;
      left = math.min(left, l.at.x - half);
      right = math.max(right, l.at.x + half);
      low = math.min(low, l.at.y - l.height);
      top = math.max(top, l.at.y + l.height);
    }
    return FloorPlanCad.fromEntities(bounds: PlanRect((left - 3 * t).floor(), (low - 3 * t).floor(),
      (right + 3 * t).ceil(), (top + 3 * t).ceil()), lines: lines, labels: labels);
  }
}
