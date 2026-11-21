import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/street_light_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class StreetLightPole {
  const StreetLightPole(this.id, this.stationMm, this.point);
  final String id;
  final double stationMm;
  final CadPoint point;
}

class StreetLightCadResult {
  const StreetLightCadResult({this.drawing, this.issue, this.poles = const [], this.spacingMm = 0, this.lengthMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<StreetLightPole> poles;
  final double spacingMm;
  final int lengthMm;

  String? toCsv() {
    if (drawing == null) return null;
    String metres(num mm) => (mm / 1000).toStringAsFixed(6);
    return [
      'pole_id,chainage_m,easting_m,northing_m',
      for (final p in poles) '${p.id},${metres(p.stationMm)},${metres(p.point.x)},${metres(p.point.y)}',
      '',
    ].join('\r\n');
  }
}

/// Searches fixed-end equal subdivisions; these locations are not a lighting design.
class StreetLightCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['street_light_mode'] == streetLightMode;

  StreetLightCadResult generate(ProjectBrief brief) {
    StreetLightCadResult stop(String issue) => StreetLightCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !streetLightCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Street Lighting Network and save the current surveyed pole layout brief.');
    }
    if (!const {null, 'outdoor_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one surveyed outdoor row without buildings, parking or separate Space selections.');
    }
    final a = req.answers;
    final ref = a['sl_grid'];
    final grid = ref is String ? ref.trim().replaceAll(RegExp(r'\s+'), ' ') : '';
    if (grid.isEmpty || grid.length > 100) return stop('Enter the projected metre grid, up to 100 characters.');
    List<String> rows(String s) => s.split(RegExp(r'[;\r\n]+')).map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    final decimal = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? survey(String text, num min, num max) {
      final v = double.tryParse(text);
      return decimal.hasMatch(text.trim()) && v != null && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    }
    int? mm(String key, {num min = .001, num max = 2000}) {
      final v = a[key];
      return v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    }
    final rawAxis = a['sl_axis'];
    final axis = rawAxis is String && rawAxis.length <= 280 ? rows(rawAxis) : const <String>[];
    if (axis.length != 2) return stop('Enter exactly two straight roadside controls, A then B.');
    final controls = <(int, int)>[];
    for (final row in axis) {
      final v = row.split(',');
      if (v.length != 2) return stop('Each projected baseline control needs Easting,Northing.');
      final x = survey(v[0], -10000000, 10000000), y = survey(v[1], -10000000, 10000000);
      if (x == null || y == null) return stop('Enter valid projected metre coordinates with up to three decimals.');
      controls.add((x, y));
    }
    final (ax, ay) = controls.first;
    final (bx, by) = controls.last;
    final dx = (bx - ax).toDouble(), dy = (by - ay).toDouble(), baseline = math.sqrt(dx * dx + dy * dy);
    if (baseline < 1 || baseline > 2000000) return stop('Use a positive A–B baseline of at most 2 km.');
    final side = a['sl_side'];
    final offset = mm('sl_offset', max: 100), start = mm('sl_start', min: 0), end = mm('sl_end', min: 0);
    final min = mm('sl_min', max: 500), max = mm('sl_max', max: 500);
    if (!const {'left', 'right'}.contains(side) || offset == null || start == null || end == null || min == null || max == null) {
      return stop('Enter pole side, offset, fixed end chainages and both spacing limits.');
    }
    if (end <= start || end > baseline + 1e-7) return stop('Fixed end poles must be ordered within the surveyed A–B span.');
    if (max < min) return stop('Maximum spacing cannot be smaller than minimum spacing.');
    final raw = a['sl_exclusions'];
    if (raw != null && (raw is! String || raw.length > 5000)) return stop('Enter valid no-pole windows.');
    final exclusionRows = raw is String ? rows(raw) : const <String>[];
    if (exclusionRows.length > 60) return stop('Enter at most 60 no-pole windows.');
    final rawWindows = <(int, int)>[];
    for (var i = 0; i < exclusionRows.length; i++) {
      final v = exclusionRows[i].split(',');
      if (v.length != 2) return stop('No-pole window ${i + 1} needs start and end chainages.');
      final s = survey(v[0], 0, 2000), e = survey(v[1], 0, 2000);
      if (s == null || e == null || e <= s || e > baseline + 1e-7) {
        return stop('No-pole window ${i + 1} must have positive length within the surveyed A–B span.');
      }
      for (final (label, station) in [('first', start), ('last', end)]) {
        if (station >= s && station <= e) return stop('The fixed $label pole falls inside or on the boundary of no-pole window ${i + 1}.');
      }
      if (s > start && e < end) rawWindows.add((s, e));
    }
    rawWindows.sort((a, b) => a.$1.compareTo(b.$1));
    final windows = <(int, int)>[];
    for (final (s, e) in rawWindows) {
      if (windows.isEmpty || s > windows.last.$2) {
        windows.add((s, e));
      } else if (e > windows.last.$2) {
        windows[windows.length - 1] = (windows.last.$1, e);
      }
    }
    final length = end - start;
    final firstN = (length + max - 1) ~/ max;
    final lastN = length ~/ min;
    if (lastN < firstN) return stop('No equal subdivision of the fixed span meets both spacing limits.');
    if (firstN > 199) return stop('The spacing limits require more than 200 poles. Shorten the layout or revise the submitted spacing range.');
    int? spans;
    for (var n = firstN; n <= lastN && n <= 199; n++) {
      var blocked = false, w = 0;
      for (var i = 1; i < n && w < windows.length; i++) {
        // Chainage is a rational. Test against closed intervals before rounding
        // station or coordinates, so a pole exactly on a boundary is blocked.
        final stationN = start * n + i * length;
        while (w < windows.length && stationN > windows[w].$2 * n) {
          w++;
        }
        if (w < windows.length && stationN >= windows[w].$1 * n) {
          blocked = true;
          break;
        }
      }
      if (!blocked) {
        spans = n;
        break;
      }
    }
    if (spans == null) return stop('No equal-spacing layout of up to 200 poles avoids the no-pole windows with these fixed ends and spacing limits.');
    final sign = side == 'left' ? 1 : -1;
    CadPoint p(num ch, num out) => CadPoint(ax + (dx * ch - sign * dy * out) / baseline,
      ay + (dy * ch + sign * dx * out) / baseline);
    final lines = <CadLine>[], labels = <CadLabel>[], poles = <StreetLightPole>[];
    void line(String layer, num ch, num out, num dst, num next) => lines.add(CadLine(layer, p(ch, out), p(dst, next)));
    line('SL_AXIS', 0, 0, baseline, 0);
    var previous = start;
    for (final (s, e) in windows) {
      line('SL_ROW', previous, offset, s, offset);
      line('SL_EXCLUDE', s, offset, e, offset);
      previous = e;
    }
    line('SL_ROW', previous, offset, end, offset);
    final extent = [p(0, 0), p(baseline, 0), p(start, offset), p(end, offset)];
    final x0 = extent.map((p) => p.x).reduce(math.min), x1 = extent.map((p) => p.x).reduce(math.max);
    final y0 = extent.map((p) => p.y).reduce(math.min), y1 = extent.map((p) => p.y).reduce(math.max);
    final cx = (x0 + x1) / 2, t = (math.max(x1 - x0, y1 - y0) / 90).clamp(20, 16000).toDouble();
    final spacing = length / spans, symbol = math.min(t, spacing / 6);
    for (var i = 0; i <= spans; i++) {
      final station = (start * spans + i * length) / spans, id = 'P${(i + 1).toString().padLeft(2, '0')}';
      poles.add(StreetLightPole(id, station, p(station, offset)));
      line('SL_POLE', station - symbol / 2, offset - symbol / 2, station + symbol / 2, offset + symbol / 2);
      line('SL_POLE', station - symbol / 2, offset + symbol / 2, station + symbol / 2, offset - symbol / 2);
      labels.add(CadLabel('SL_POLE', p(station, offset + symbol), id, .58 * symbol));
    }
    final nx = math.max(cx + 46 * t, x1) + 3 * t;
    final tip = CadPoint(nx, y1);
    lines.addAll([CadLine('ANNOTATIONS', CadPoint(nx, y1 - 2 * t), tip),
      CadLine('ANNOTATIONS', CadPoint(nx - .5 * t, y1 - t), tip), CadLine('ANNOTATIONS', CadPoint(nx + .5 * t, y1 - t), tip)]);
    labels.addAll([CadLabel('SL_AXIS', p(-1.5 * t, 0), 'A', .7 * t), CadLabel('SL_AXIS', p(baseline + 1.5 * t, 0), 'B', .7 * t),
      CadLabel('ANNOTATIONS', CadPoint(nx, y1 + t), 'GRID N', .65 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 6 * t), 'SURVEYED STREET LIGHT POLE ROW / PROJECTED MM', t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 4.7 * t), '${poles.length} POLE(S) / ${_m(spacing)} M EQUAL SPACING / CH ${_m(start)} TO ${_m(end)} M', .64 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 3.4 * t), 'OFFSET ${_m(offset)} M ${side.toString().toUpperCase()} OF A-B / GRID: $grid', .58 * t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 2.1 * t), 'CENTRE POINTS ONLY / NO PHOTOMETRICS OR INSTALLATION APPROVAL', .6 * t)]);
    final bounds = PlanRect(math.min(x0 - 4 * t, cx - 46 * t).floor(), (y0 - 4 * t).floor(), (nx + 4 * t).ceil(), (y1 + 7.4 * t).ceil());
    return StreetLightCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels),
      poles: List.unmodifiable(poles), spacingMm: spacing, lengthMm: length);
  }
}
