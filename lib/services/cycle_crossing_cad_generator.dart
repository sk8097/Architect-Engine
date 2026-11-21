import 'dart:math' as math;

import '../data/cycle_crossing_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class CycleDriveway {
  const CycleDriveway(this.id, this.startMm, this.endMm);
  final String id;
  final int startMm, endMm;
  int get lengthMm => endMm - startMm;
}

class CycleCrossingCadResult {
  const CycleCrossingCadResult({this.drawing, this.issue, this.driveways = const [], this.lengthMm = 0,
    this.widthMm = 0, this.separatorMm = 0, this.minGapMm = 0, this.minGapStationMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<CycleDriveway> driveways;
  final int lengthMm, widthMm, separatorMm, minGapMm, minGapStationMm;
  double get crossingAreaM2 => (lengthMm - separatorMm) * widthMm / 1e6;

  String? toCsv() => drawing == null ? null : [
    'id,start_chainage_m,end_chainage_m,span_along_track_m,cycle_track_overlap_area_m2',
    for (final d in driveways)
      '${d.id},${_m(d.startMm)},${_m(d.endMm)},${_m(d.lengthMm)},${(d.lengthMm * widthMm / 1e6).toStringAsFixed(6)}',
    '',
  ].join('\r\n');
}

/// A constant-width strip normal to one straight surveyed road edge.
class CycleCrossingCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['corridor_cad_mode'] == cycleCrossingMode;

  CycleCrossingCadResult generate(ProjectBrief brief) {
    CycleCrossingCadResult stop(String issue) => CycleCrossingCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !cycleCrossingCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Cycle Track and save the current surveyed driveway brief.');
    }
    if (!const {null, 'linear_corridor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one surveyed linear corridor without buildings, parking or separate Space selections.');
    }
    final answers = req.answers;
    final rawGrid = answers['cyc_grid'];
    final grid = rawGrid is String ? rawGrid.trim().replaceAll(RegExp(r'\s+'), ' ') : '';
    if (grid.isEmpty || grid.length > 100) return stop('Enter a projected metre grid, up to 100 characters.');
    List<String> rows(String key, int max) {
      final raw = answers[key];
      return raw is! String || raw.length > max ? const [] : raw.split(RegExp(r'[;\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    final decimal = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? survey(String text, num min, num max) {
      final v = double.tryParse(text);
      return decimal.hasMatch(text.trim()) && v != null && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    }
    int? dimension(String key, {num min = .001}) {
      final v = answers[key];
      return v is num && v.isFinite && v >= min && v <= 50 ? (v * 1000).round() : null;
    }
    final axis = rows('cyc_axis', 280);
    if (axis.length != 2) return stop('Enter exactly two road edge controls, A then B.');
    final points = <(int, int)>[];
    for (final row in axis) {
      final v = row.split(',');
      if (v.length != 2) return stop('Each road edge control must be Easting,Northing.');
      final x = survey(v[0], -10000000, 10000000), y = survey(v[1], -10000000, 10000000);
      if (x == null || y == null) return stop('Enter valid projected coordinates with up to three decimals.');
      points.add((x, y));
    }
    final (ax, ay) = points.first;
    final (bx, by) = points.last;
    final dx = (bx - ax).toDouble(), dy = (by - ay).toDouble();
    final baseline = math.sqrt(dx * dx + dy * dy);
    if (baseline < 1 || baseline > 2000000) return stop('Use a positive A–B road edge at most 2 km long.');
    final side = answers['cyc_side'];
    final buffer = dimension('cyc_buffer'), width = dimension('cyc_width');
    final margin = dimension('cyc_margin', min: 0), minIsland = dimension('cyc_island');
    if (!const {'left', 'right'}.contains(side) || buffer == null || width == null || margin == null || minIsland == null) {
      return stop('Enter track side, separator width, track width, roadside gap and minimum separator between driveways.');
    }
    final farEdge = buffer + width;
    final samples = rows('cyc_limits', 5000);
    if (samples.length < 2 || samples.length > 80) return stop('Enter 2–80 roadside limit samples spanning the track.');
    final limits = <(int, int)>[];
    var minGap = 500001;
    var minStation = 0;
    for (var i = 0; i < samples.length; i++) {
      final v = samples[i].split(',');
      if (v.length != 2) return stop('Roadside limit sample ${i + 1} needs chainage and outward offset.');
      final ch = survey(v[0], 0, 2000), off = survey(v[1], .001, 500);
      if (ch == null || off == null) return stop('Roadside limit sample ${i + 1} needs measured metres with up to three decimals and a positive outward offset.');
      if (ch > baseline + 1e-7) return stop('Roadside limit samples must be within the surveyed A–B length.');
      if (limits.isNotEmpty && ch <= limits.last.$1) return stop('Roadside limit chainages must strictly increase.');
      final gap = off - farEdge;
      if (gap < margin) return stop('Track does not leave the submitted roadside gap at Ch ${_m(ch)} m.');
      if (gap < minGap) {
        minGap = gap;
        minStation = ch;
      }
      limits.add((ch, off));
    }
    final start = limits.first.$1, end = limits.last.$1;
    final rawDriveways = rows('cyc_driveways', 3000);
    if (rawDriveways.isEmpty || rawDriveways.length > 20) return stop('Enter 1–20 measured driveway windows.');
    final driveways = <CycleDriveway>[], ids = <String>{};
    for (var i = 0; i < rawDriveways.length; i++) {
      final v = rawDriveways[i].split(',');
      if (v.length != 3) return stop('Driveway ${i + 1} needs an ID, start chainage and end chainage.');
      final id = v[0].trim();
      if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,15}$').hasMatch(id)) {
        return stop('Use a 1–16 character driveway ID starting with a letter or number.');
      }
      if (!ids.add(id.toUpperCase())) return stop('Driveway ID $id is repeated.');
      final lo = survey(v[1], 0, 2000), hi = survey(v[2], 0, 2000);
      if (lo == null || hi == null || lo < start || hi > end || hi <= lo) {
        return stop('Driveway $id must have positive length within the surveyed track chainages.');
      }
      if (driveways.isNotEmpty) {
        final separation = lo - driveways.last.endMm;
        if (separation < 0) return stop('Driveway $id overlaps or is out of order.');
        if (separation < minIsland) return stop('Driveway $id leaves only ${_m(separation)} m of separator after ${driveways.last.id}.');
      }
      driveways.add(CycleDriveway(id, lo, hi));
    }

    final sign = side == 'left' ? 1 : -1;
    CadPoint p(num ch, num off) => CadPoint(ax + (dx * ch - sign * dy * off) / baseline,
      ay + (dy * ch + sign * dx * off) / baseline);
    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num s, num o, num e, num q) {
      if (s != e || o != q) lines.add(CadLine(layer, p(s, o), p(e, q)));
    }
    line('CYCLE_ROAD', 0, 0, baseline, 0);
    for (var i = 1; i < limits.length; i++) {
      final (s, o) = limits[i - 1];
      final (e, q) = limits[i];
      line('CYCLE_LIMIT', s, o, e, q);
    }
    line('CYCLE_TRACK', start, buffer, end, buffer);
    line('CYCLE_TRACK', start, farEdge, end, farEdge);
    // Only close the track at its ends if no crossing boundary already draws that edge.
    if (driveways.first.startMm != start) line('CYCLE_TRACK', start, buffer, start, farEdge);
    if (driveways.last.endMm != end) line('CYCLE_TRACK', end, buffer, end, farEdge);
    final extent = [p(0, 0), p(baseline, 0), for (final (ch, off) in limits) p(ch, off)];
    final x0 = extent.map((p) => p.x).reduce(math.min), x1 = extent.map((p) => p.x).reduce(math.max);
    final y0 = extent.map((p) => p.y).reduce(math.min), y1 = extent.map((p) => p.y).reduce(math.max);
    final cx = (x0 + x1) / 2, t = (math.max(x1 - x0, y1 - y0) / 90).clamp(40, 16000).toDouble();
    var previousEnd = start, totalCrossing = 0;
    for (final d in driveways) {
      line('CYCLE_SEPARATOR', previousEnd, buffer / 2, d.startMm, buffer / 2);
      line('CYCLE_DRIVEWAY', d.startMm, 0, d.startMm, farEdge);
      line('CYCLE_DRIVEWAY', d.endMm, 0, d.endMm, farEdge);
      labels.add(CadLabel('CYCLE_DRIVEWAY', p((d.startMm + d.endMm) / 2, buffer + width / 2), d.id,
        math.min(t, math.min(width / 3, d.lengthMm / (d.id.length + 1)))));
      previousEnd = d.endMm;
      totalCrossing += d.lengthMm;
    }
    line('CYCLE_SEPARATOR', previousEnd, buffer / 2, end, buffer / 2);
    final nx = math.max(x1, cx + 43 * t) + 3 * t;
    final tip = CadPoint(nx, y1);
    lines.addAll([CadLine('ANNOTATIONS', CadPoint(nx, y1 - 2 * t), tip),
      CadLine('ANNOTATIONS', CadPoint(nx - .5 * t, y1 - t), tip), CadLine('ANNOTATIONS', CadPoint(nx + .5 * t, y1 - t), tip)]);
    labels.addAll([
      CadLabel('CYCLE_ROAD', p(-1.5 * t, 0), 'A', .7 * t), CadLabel('CYCLE_ROAD', p(baseline + 1.5 * t, 0), 'B', .7 * t),
      CadLabel('ANNOTATIONS', CadPoint(nx, y1 + t), 'GRID N', .65 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 6 * t), 'SURVEYED SEPARATED CYCLE TRACK / PROJECTED MM', t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 4.6 * t), 'CH ${_m(start)} TO ${_m(end)} M / WIDTH ${_m(width)} M / ${driveways.length} DRIVEWAY(S)', .65 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 3.3 * t), 'MIN ROADSIDE GAP ${_m(minGap)} M AT CH ${_m(minStation)} M / NORMAL TO A-B', .62 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 2 * t), 'GRID: $grid / ${side.toString().toUpperCase()} OF A-B', .58 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + .8 * t), 'DRIVEWAY WINDOWS ONLY / NO SIGHT DISTANCE OR TRAFFIC APPROVAL', .6 * t),
    ]);
    final bounds = PlanRect(math.min(x0 - 4 * t, cx - 43 * t).floor(), (y0 - 4 * t).floor(), (nx + 4 * t).ceil(), (y1 + 7.4 * t).ceil());
    return CycleCrossingCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels),
      driveways: List.unmodifiable(driveways), lengthMm: end - start, widthMm: width,
      separatorMm: end - start - totalCrossing, minGapMm: minGap, minGapStationMm: minStation);
  }
}
