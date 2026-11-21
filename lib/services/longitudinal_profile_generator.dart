import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/survey_corridor_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

/// Coordinates are true survey millimetres, before the optional display scale.
class ProfileStation {
  const ProfileStation(this.chainageMm, this.groundMm, this.designMm);
  final int chainageMm, groundMm;
  final double designMm;
  double get differenceMm => designMm - groundMm;
}

class VerticalProfileCurve {
  const VerticalProfileCurve(this.startMm, this.endMm, this.startLevelMm, this.inSlope, this.outSlope);
  final double startMm, endMm, startLevelMm, inSlope, outSlope;
  double get lengthMm => endMm - startMm;
  double levelAt(double chainageMm) {
    final delta = chainageMm - startMm;
    return startLevelMm + inSlope * delta + (outSlope - inSlope) * delta * delta / (2 * lengthMm);
  }
  double? get extremumMm {
    final dx = -inSlope * lengthMm / (outSlope - inSlope);
    return dx > 0 && dx < lengthMm ? startMm + dx : null;
  }
}

class LongitudinalProfileResult {
  const LongitudinalProfileResult(this.drawing, this.issue, {this.stations = const [], this.curves = const [],
    this.slopes = const [], this.exaggeration = 1, this.datumMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<ProfileStation> stations;
  final List<VerticalProfileCurve> curves;
  final List<double> slopes;
  final int exaggeration, datumMm;
}

/// Station/elevation sheet only, using supplied levels and symmetric curve lengths.
class LongitudinalProfileGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['corridor_cad_mode'] == 'survey_profile';

  LongitudinalProfileResult generate(ProjectBrief brief) {
    LongitudinalProfileResult stop(String issue) => LongitudinalProfileResult(null, issue);
    final sel = brief.taxonomy, snapshot = brief.requirements;
    if (sel == null || snapshot == null || sel.version != projectTaxonomyVersion || snapshot.version != requirementsSchemaVersion ||
        sel.categoryId != 'infrastructure' || sel.subcategoryId != 'transport' || !surveyCorridorTypes.contains(sel.typeId)) {
      return stop('Select a Road, Street, Footpath or Cycle Track and save the current profile brief.');
    }
    if (!const {null, 'linear_corridor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a linear profile without structures, parking, junctions or separate Space selections.');
    }
    final a = snapshot.answers, ref = snapshot.answers['profile_reference'];
    if (ref is! String || ref.trim().isEmpty || ref.trim().length > 120) return stop('Enter the benchmark datum and source reference (up to 120 characters).');
    final scale = switch (a['profile_exaggeration']) {null || '1' => 1, '5' => 5, '10' => 10, _ => null};
    if (scale == null) return stop('Select an available vertical exaggeration.');
    final pattern = RegExp(r'^[+-]?\d+(?:\.\d{1,3})?$');
    List<List<int>>? read(Object? raw, int columns, int maxRows) {
      if (raw is! String || raw.length > 12000) return null;
      final rows = raw.trim().split(RegExp(r'[;\r\n]+')).where((r) => r.trim().isNotEmpty).toList();
      if (rows.length < 2 || rows.length > maxRows) return null;
      final values = <List<int>>[];
      for (final row in rows) {
        final pieces = row.split(',').map((p) => p.trim()).toList();
        if (pieces.length != columns || pieces.any((p) => !pattern.hasMatch(p))) return null;
        final v = pieces.map(double.tryParse).toList();
        if (v.any((n) => n == null || !n.isFinite || n.abs() > 1000000)) return null;
        final data = v.map((n) => (n! * 1000).round()).toList();
        if (data[0] < 0 || data[1].abs() > 10000000 || (columns == 3 && (data[2] < 0 || data[2] > 20000000))) return null;
        values.add(data);
      }
      return values;
    }
    final ground = read(a['profile_ground'], 2, 150), grade = read(a['profile_grade'], 3, 50);
    if (ground == null) return stop('Enter 2–150 valid surveyed chainage,level pairs in metres to three decimals.');
    if (grade == null) return stop('Enter 2–50 proposed chainage,level,curve length triples in metres to three decimals. Use zero length for a straight grade break.');
    bool increasing(List<List<int>> rows) {
      for (var i = 1; i < rows.length; i++) { if (rows[i][0] <= rows[i - 1][0]) return false; }
      return true;
    }
    if (!increasing(ground) || !increasing(grade)) return stop('Surveyed and proposed chainages must each be strictly increasing with no duplicates.');
    final start = ground.first[0], end = ground.last[0], span = end - start;
    if (span > 20000000) return stop('The profile span is limited to 20 km.');
    if (grade.first[0] != start || grade.last[0] != end || grade.first[2] != 0 || grade.last[2] != 0) {
      return stop('First and last proposed chainages must match the survey limits exactly and use zero curve length.');
    }
    final slopes = [for (var i = 1; i < grade.length; i++) (grade[i][1] - grade[i - 1][1]) / (grade[i][0] - grade[i - 1][0])];
    final indexed = <int, VerticalProfileCurve>{};
    var previousEnd = start.toDouble();
    for (var i = 1; i < grade.length - 1; i++) {
      final row = grade[i], half = grade[i][2] / 2;
      final bvc = row[0] - half, evc = row[0] + half;
      if (bvc < previousEnd || evc > grade[i + 1][0]) {
        return stop('Curve at ${(row[0] / 1000).toStringAsFixed(3)} m overlaps a previous curve/control or passes the next grade intersection.');
      }
      previousEnd = evc;
      if (half == 0) continue;
      if (slopes[i - 1] == slopes[i]) return stop('A positive curve length needs different entering and leaving grades.');
      indexed[i] = VerticalProfileCurve(bvc, evc, row[1] - slopes[i - 1] * half, slopes[i - 1], slopes[i]);
    }
    final curves = indexed.values.toList();
    final design = <(double, double)>[(start.toDouble(), grade.first[1].toDouble())];
    void append(double x, double y) {
      // Two adjacent curves can share one tangent point. Avoid a tiny
      // vertical segment from the two floating-point evaluations there.
      if ((x - design.last.$1).abs() > .0001) design.add((x, y));
    }
    // A parabola is approximated in R12 by editable chords, with no more
    // than 5 mm true vertical error; calculated station levels stay analytic.
    for (var i = 1; i < grade.length; i++) {
      final c = indexed[i];
      if (c == null) {
        append(grade[i][0].toDouble(), grade[i][1].toDouble());
      } else {
        final steps = math.max(8, math.sqrt((c.outSlope - c.inSlope).abs() * c.lengthMm / 40).ceil());
        if (design.length + steps + 2 > 12000) return stop('This curve set exceeds the profile drawing complexity limit. Split the input into shorter sections.');
        final xs = <double>{
          for (var k = 0; k <= steps; k++) c.startMm + c.lengthMm * k / steps,
          if (c.extremumMm case final peak?) peak,
        }.toList()..sort();
        for (final x in xs) { append(x, c.levelAt(x)); }
      }
    }
    double levelAt(int chainage) {
      for (final c in curves) {
        if (chainage >= c.startMm && chainage <= c.endMm) return c.levelAt(chainage.toDouble());
      }
      for (var i = 1; i < grade.length; i++) {
        if (chainage <= grade[i][0]) return grade[i - 1][1] + (chainage - grade[i - 1][0]) * slopes[i - 1];
      }
      return grade.last[1].toDouble();
    }
    final stations = [for (final row in ground) ProfileStation(row[0], row[1], levelAt(row[0]))];
    final minLevel = [...ground.map((p) => p[1].toDouble()), ...design.map((p) => p.$2)].reduce(math.min);
    final datum = (minLevel / 1000).floor() * 1000 - 1000;
    final lines = <CadLine>[], labels = <CadLabel>[];
    CadPoint p(num x, num y) => CadPoint(x, (y - datum) * scale);
    void line(String layer, CadPoint a, CadPoint b) {
      if (a.x != b.x || a.y != b.y) lines.add(CadLine(layer, a, b));
    }
    void trace(String layer, List<CadPoint> path) {
      for (var i = 1; i < path.length; i++) { line(layer, path[i - 1], path[i]); }
    }
    final existing = [for (final g in ground) p(g[0], g[1])];
    final proposed = [for (final v in design) p(v.$1, v.$2)];
    trace('PROFILE_GROUND', existing);
    trace('PROFILE_DESIGN', proposed);
    final high = [...existing, ...proposed].map((v) => v.y).reduce(math.max);
    final text = (math.max(span, high) / 95).clamp(100, 25000).toDouble();
    line('PROFILE_STATIONS', CadPoint(start, 0), CadPoint(end, 0));
    double lastStation = -double.infinity;
    for (var i = 0; i < stations.length; i++) {
      final s = stations[i], px = s.chainageMm;
      line('PROFILE_STATIONS', CadPoint(px, 0), p(px, math.min(s.groundMm, s.designMm)));
      if (s.differenceMm.abs() > .001) line(s.differenceMm > 0 ? 'PROFILE_FILL' : 'PROFILE_CUT', p(px, s.groundMm), p(px, s.designMm));
      if (i == 0 || i == stations.length - 1 || (px - lastStation > text * 6 && end - px > text * 6)) {
        labels.add(CadLabel('PROFILE_STATIONS', CadPoint(px, -text * .85), (px / 1000).toStringAsFixed(3), text * .65));
        lastStation = px.toDouble();
      }
    }
    void curveMarker(String label, double x, double z) {
      final q = p(x, z);
      line('PROFILE_CURVE_POINTS', CadPoint(q.x, q.y - text * .2), CadPoint(q.x, q.y + text * .2));
      labels.add(CadLabel('PROFILE_CURVE_POINTS', CadPoint(q.x, q.y + text * .65), label, text * .5));
    }
    for (final c in curves) {
      curveMarker('BVC', c.startMm, c.startLevelMm);
      curveMarker('EVC', c.endMm, c.levelAt(c.endMm));
      if (c.extremumMm case final x?) curveMarker(c.outSlope > c.inSlope ? 'LOW' : 'HIGH', x, c.levelAt(x));
    }
    for (var i = 1; i < grade.length; i++) {
      final x1 = indexed[i - 1]?.endMm ?? grade[i - 1][0].toDouble();
      final x2 = indexed[i]?.startMm ?? grade[i][0].toDouble();
      if (x2 - x1 <= text * 8) continue;
      final x = (x1 + x2) / 2, z = grade[i - 1][1] + (x - grade[i - 1][0]) * slopes[i - 1];
      final y = p(x, z).y;
      labels.add(CadLabel('PROFILE_DESIGN', CadPoint(x, y + text * .75), '${(slopes[i - 1] * 100).toStringAsFixed(2)}%', text * .6));
    }
    final source = ref.trim().replaceAll(RegExp(r'\s+'), ' ');
    final mid = (start + end) / 2;
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(mid, high + text * 4.7), 'SURVEYED LONGITUDINAL PROFILE / CONCEPT', text),
      CadLabel('ANNOTATIONS', CadPoint(mid, high + text * 3.35), source, text * .7),
      CadLabel('ANNOTATIONS', CadPoint(mid, high + text * 2),
        'X = CHAINAGE MM / Y = (LEVEL - ${(datum / 1000).toStringAsFixed(3)} M) x $scale IN MM', text * .65),
      CadLabel('ANNOTATIONS', CadPoint(mid, -text * 2.25), 'STATION LABELS IN METRES / DRAWING IN MILLIMETRES', text * .6),
    ]);
    final titleHalf = math.max(21, source.length * .25) * text;
    final bounds = PlanRect(math.min(start - text * 5, mid - titleHalf).floor(), (-text * 3.5).floor(),
      math.max(end + text * 5, mid + titleHalf).ceil(), (high + text * 6).ceil());
    return LongitudinalProfileResult(FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels), null,
      stations: List.unmodifiable(stations), curves: List.unmodifiable(curves), slopes: List.unmodifiable(slopes),
      exaggeration: scale, datumMm: datum);
  }
}
