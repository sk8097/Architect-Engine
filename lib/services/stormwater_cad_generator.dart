import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/stormwater_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class DrainNode {
  const DrainNode(this.id, this.x, this.y, this.ground, this.invert, this.chainage);
  final String id;
  final int x, y, ground, invert;
  final double chainage;
}

class DrainReach {
  const DrainReach(this.upstream, this.downstream, this.length, this.minimumCover, this.minimumCoverAt);
  final DrainNode upstream, downstream;
  final double length, minimumCover, minimumCoverAt;
  int get fall => upstream.invert - downstream.invert;
  double get gradePercent => fall / length * 100;
}

class StormwaterCadResult {
  const StormwaterCadResult(this.plan, this.profile, this.issue, {this.reaches = const [], this.exaggeration = 10});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final List<DrainReach> reaches;
  final int exaggeration;
}

/// One unbranched, buried gravity run, measured at control structures. No
/// hydraulic sizing, utility coordination or validation against design codes.
class StormwaterCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['drain_cad_mode'] == 'survey_gravity';

  StormwaterCadResult generate(ProjectBrief brief) {
    StormwaterCadResult stop(String issue) => StormwaterCadResult(null, null, issue);
    final sel = brief.taxonomy, truth = brief.requirements;
    if (sel == null || truth == null || sel.version != projectTaxonomyVersion || truth.version != requirementsSchemaVersion ||
        sel.categoryId != 'infrastructure' || sel.subcategoryId != 'water' || !stormwaterCadTypes.contains(sel.typeId)) {
      return stop('Select Stormwater Drain or Drainage Network and save the surveyed brief.');
    }
    if (!const {null, 'drainage_system', 'network'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one unbranched gravity pipe concept. Pumps, plants, parking and separate Space selections are not drawn.');
    }
    final a = truth.answers;
    String? description(String key) {
      final v = a[key];
      return v is String && v.trim().isNotEmpty && v.trim().length <= 120 ? v.trim().replaceAll(RegExp(r'\s+'), ' ') : null;
    }
    final grid = description('dr_grid'), ref = description('dr_reference');
    if (grid == null || ref == null) return stop('Enter a projected survey grid and common level datum reference (up to 120 characters each).');
    final ve = switch (a['dr_exaggeration']) {'1' => 1, '5' => 5, null || '10' => 10, _ => null};
    final rawRise = a['dr_crown_rise'], rawCover = a['dr_cover'], minGrade = a['dr_min_grade'];
    bool inRange(Object? v, num min, num max) => v is num && v.isFinite && v >= min && v <= max;
    if (ve == null || !inRange(rawRise, .001, 20) || !inRange(rawCover, 0, 100) || minGrade is! num || !inRange(minGrade, 0, 100)) {
      return stop('Enter the measured crown rise, minimum cover and minimum percentage fall, and a supported vertical scale.');
    }
    final rise = ((rawRise as num) * 1000).round(), requiredCover = ((rawCover as num) * 1000).round();
    final decimal = RegExp(r'^[+-]?\d+(?:\.\d{1,3})?$'), idPattern = RegExp(r'^[A-Za-z][A-Za-z0-9_-]{0,15}$');
    int? metres(String token, int limit) {
      final n = decimal.hasMatch(token) ? double.tryParse(token) : null;
      return n != null && n.isFinite && n.abs() <= limit ? (n * 1000).round() : null;
    }
    List<String>? rows(Object? raw, int maxChars) => raw is String && raw.length <= maxChars
      ? raw.trim().split(RegExp(r'[;\r\n]+')).where((r) => r.trim().isNotEmpty).toList() : null;
    final entries = rows(a['dr_nodes'], 8000);
    if (entries == null || entries.length < 2 || entries.length > 60) return stop('Enter 2–60 ordered drainage nodes, upstream to downstream.');
    final nodes = <DrainNode>[], lengths = <double>[], ids = <String>{}, coordinates = <(int, int)>{};
    for (var i = 0; i < entries.length; i++) {
      final values = entries[i].split(',').map((s) => s.trim()).toList();
      if (values.length != 5 || !idPattern.hasMatch(values.first)) return stop('Node ${i + 1}: use ID,Easting,Northing,ground,invert in metres to three decimals. IDs start with a letter.');
      final id = values[0].toUpperCase(), x = metres(values[1], 10000000), y = metres(values[2], 10000000);
      final ground = metres(values[3], 10000), invert = metres(values[4], 10000);
      if (x == null || y == null || ground == null || invert == null) return stop('Node $id has invalid metre coordinates or levels.');
      if (!ids.add(id) || !coordinates.add((x, y))) return stop('Node $id repeats an ID or projected coordinate.');
      var chainage = 0.0;
      if (nodes.isNotEmpty) {
        final prev = nodes.last, dx = (x - nodes.last.x).toDouble(), dy = (y - nodes.last.y).toDouble();
        final length = math.sqrt(dx * dx + dy * dy);
        if (length < 1) return stop('Nodes ${prev.id} and $id are too close to define a reach.');
        chainage = prev.chainage + length;
        if (chainage > 20000000) return stop('One gravity run is limited to 20 km.');
        lengths.add(length);
      }
      nodes.add(DrainNode(id, x, y, ground, invert, chainage));
    }
    int turn(DrainNode a, DrainNode b, DrainNode c) => (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    bool on(DrainNode p, DrainNode a, DrainNode b) => math.min(a.x, b.x) <= p.x && p.x <= math.max(a.x, b.x) &&
        math.min(a.y, b.y) <= p.y && p.y <= math.max(a.y, b.y);
    bool crosses(DrainNode a, DrainNode b, DrainNode c, DrainNode d) {
      final ac = turn(a, b, c), ad = turn(a, b, d), ca = turn(c, d, a), cb = turn(c, d, b);
      return (ac.sign * ad.sign < 0 && ca.sign * cb.sign < 0) || ac == 0 && on(c, a, b) || ad == 0 && on(d, a, b) ||
          ca == 0 && on(a, c, d) || cb == 0 && on(b, c, d);
    }
    for (var i = 1; i < nodes.length; i++) {
      final start = nodes[i - 1], end = nodes[i];
      if (i >= 2 && turn(nodes[i - 2], start, end) == 0 &&
          (on(end, nodes[i - 2], start) || on(nodes[i - 2], start, end))) {
        return stop('The run doubles back onto itself at ${start.id}.');
      }
      for (var j = 1; j < i - 1; j++) {
        if (crosses(start, end, nodes[j - 1], nodes[j])) return stop('Reach ${start.id}–${end.id} crosses or overlaps an earlier reach.');
      }
    }
    final extra = <(int, int)>[];
    final checkpoints = a['dr_ground'];
    if (checkpoints != null) {
      final list = rows(checkpoints, 12000);
      if (list == null || list.length > 150) return stop('Enter up to 150 extra surveyed chainage,ground-level pairs.');
      final seen = nodes.map((n) => n.chainage.round()).toSet();
      for (final entry in list) {
        final fields = entry.split(',').map((s) => s.trim()).toList();
        final ch = fields.length == 2 ? metres(fields[0], 20000) : null, z = fields.length == 2 ? metres(fields[1], 10000) : null;
        if (ch == null || z == null || ch <= 0 || ch >= nodes.last.chainage || !seen.add(ch)) {
          return stop('Intervening ground points need unique in-range chainages, distinct from all node stations to the nearest millimetre.');
        }
        extra.add((ch, z));
      }
      extra.sort((a, b) => a.$1.compareTo(b.$1));
    }
    final reaches = <DrainReach>[];
    final surface = <(double, int)>[(0, nodes.first.ground)];
    var next = 0;
    for (var i = 1; i < nodes.length; i++) {
      final u = nodes[i - 1], v = nodes[i], len = lengths[i - 1], fall = u.invert - v.invert;
      if (fall <= 0 || fall / len * 100 + 1e-9 < minGrade) {
        return stop('Reach ${u.id}–${v.id} must fall downstream and meet the supplied minimum percentage.');
      }
      var cover = (u.ground - u.invert - rise).toDouble(), at = u.chainage;
      void measure(double chainage, int ground, double invert) {
        final current = ground - invert - rise;
        if (current < cover) { cover = current; at = chainage; }
      }
      while (next < extra.length && extra[next].$1 < v.chainage) {
        final (ch, z) = extra[next++];
        measure(ch.toDouble(), z, u.invert - fall * (ch - u.chainage) / len);
        surface.add((ch.toDouble(), z));
      }
      measure(v.chainage, v.ground, v.invert.toDouble());
      surface.add((v.chainage, v.ground));
      if (cover + .000001 < requiredCover) {
        return stop('Reach ${u.id}–${v.id}: cover ${(cover / 1000).toStringAsFixed(3)} m at chainage ${(at / 1000).toStringAsFixed(3)} m is below the supplied minimum.');
      }
      reaches.add(DrainReach(u, v, len, cover, at));
    }
    return StormwaterCadResult(_plan(nodes, reaches, grid, ref), _profile(nodes, reaches, surface, rise, ref, ve), null,
      reaches: List.unmodifiable(reaches), exaggeration: ve);
  }

  FloorPlanCad _plan(List<DrainNode> nodes, List<DrainReach> reaches, String grid, String ref) {
    final l = nodes.map((n) => n.x).reduce(math.min), r = nodes.map((n) => n.x).reduce(math.max);
    final b = nodes.map((n) => n.y).reduce(math.min), t = nodes.map((n) => n.y).reduce(math.max);
    final text = (math.max(r - l, t - b) / 65).clamp(120, 25000).toDouble();
    final lines = <CadLine>[], arcs = <CadArc>[], labels = <CadLabel>[];
    for (final reach in reaches) {
      final u = reach.upstream, v = reach.downstream, dx = (v.x - u.x) / reach.length, dy = (v.y - u.y) / reach.length;
      final mid = CadPoint((u.x + v.x) / 2, (u.y + v.y) / 2), head = math.min(text * .65, reach.length / 9);
      lines.add(CadLine('DRAIN_PLAN_AXIS', CadPoint(u.x, u.y), CadPoint(v.x, v.y)));
      for (final s in [-1, 1]) {
        lines.add(CadLine('DRAIN_FLOW', CadPoint(mid.x - head * dx - s * head * .45 * dy,
          mid.y - head * dy + s * head * .45 * dx), mid));
      }
    }
    for (final node in nodes) {
      final p = CadPoint(node.x, node.y);
      arcs.addAll([CadArc('DRAIN_NODES', p, text * .30, 0, 180), CadArc('DRAIN_NODES', p, text * .30, 180, 360)]);
      labels.add(CadLabel('DRAIN_NODES', CadPoint(node.x, node.y + text), node.id, text * .7));
    }
    final mid = (l + r) / 2, nx = r + text * 3, ny = t + text;
    final tip = CadPoint(nx, ny + text * 1.5);
    lines.addAll([CadLine('ANNOTATIONS', CadPoint(nx, ny - text * .5), tip),
      CadLine('ANNOTATIONS', CadPoint(nx - text * .35, ny + text * .6), tip),
      CadLine('ANNOTATIONS', CadPoint(nx + text * .35, ny + text * .6), tip)]);
    final source = '$grid / $ref';
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(nx, ny + text * 2.1), 'GRID N', text * .6),
      CadLabel('ANNOTATIONS', CadPoint(mid, t + text * 5), 'STORMWATER GRAVITY RUN / SURVEY PLAN', text),
      CadLabel('ANNOTATIONS', CadPoint(mid, t + text * 3.75), source, text * .65),
      CadLabel('ANNOTATIONS', CadPoint(mid, t + text * 2.55), 'PROJECTED COORDINATES IN MM / NODE SYMBOLS NOT TO SCALE', text * .59),
    ]);
    final half = math.max(19, source.length * .26) * text;
    return FloorPlanCad.fromEntities(bounds: PlanRect(math.min(l - text * 6, mid - half).floor(), (b - text * 3).floor(),
      math.max(r + text * 7, mid + half).ceil(), (t + text * 6.5).ceil()), lines: lines, arcs: arcs, labels: labels);
  }

  FloorPlanCad _profile(List<DrainNode> nodes, List<DrainReach> reaches, List<(double, int)> surface, int rise, String ref, int ve) {
    final span = nodes.last.chainage, datum = (nodes.last.invert / 1000).floor() * 1000 - 1000;
    final high = (surface.map((v) => v.$2).reduce(math.max) - datum) * ve;
    final text = (math.max(span, high) / 90).clamp(120, 25000).toDouble();
    CadPoint p(num ch, num z) => CadPoint(ch, (z - datum) * ve);
    final lines = <CadLine>[CadLine('DRAIN_PROFILE_NODES', const CadPoint(0, 0), CadPoint(span, 0))];
    final labels = <CadLabel>[];
    for (var i = 1; i < surface.length; i++) {
      final a = surface[i - 1], b = surface[i];
      lines.add(CadLine('DRAIN_GROUND', p(a.$1, a.$2), p(b.$1, b.$2)));
    }
    for (final reach in reaches) {
      final u = reach.upstream, v = reach.downstream;
      lines.add(CadLine('DRAIN_INVERT', p(u.chainage, u.invert), p(v.chainage, v.invert)));
      lines.add(CadLine('DRAIN_CROWN', p(u.chainage, u.invert + rise), p(v.chainage, v.invert + rise)));
      if (reach.length > 11 * text) {
        labels.add(CadLabel('DRAIN_INVERT', p((u.chainage + v.chainage) / 2, (u.invert + v.invert) / 2 - text / ve),
          '${reach.gradePercent.toStringAsFixed(3)}% fall', text * .62));
      }
    }
    for (final node in nodes) {
      lines.add(CadLine('DRAIN_PROFILE_NODES', CadPoint(node.chainage, 0), p(node.chainage, node.ground)));
      labels.add(CadLabel('DRAIN_PROFILE_NODES', CadPoint(node.chainage, -text), node.id, text * .68));
      labels.add(CadLabel('DRAIN_PROFILE_NODES', CadPoint(node.chainage, -text * 1.85),
        'CH ${(node.chainage / 1000).toStringAsFixed(3)}', text * .52));
    }
    final mid = span / 2;
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(mid, high + text * 4.65), 'STORMWATER GRAVITY RUN / LONGITUDINAL PROFILE', text),
      CadLabel('ANNOTATIONS', CadPoint(mid, high + text * 3.3), ref, text * .68),
      CadLabel('ANNOTATIONS', CadPoint(mid, high + text * 2),
        'X = CHAINAGE MM / Y = (LEVEL - ${(datum / 1000).toStringAsFixed(3)} M) x $ve IN MM', text * .65),
    ]);
    final half = math.max(23, ref.length * .25) * text;
    return FloorPlanCad.fromEntities(bounds: PlanRect(math.min(-text * 6, mid - half).floor(), (-text * 3).floor(),
      math.max(span + text * 6, mid + half).ceil(), (high + text * 6.0).ceil()), lines: lines, labels: labels);
  }
}
