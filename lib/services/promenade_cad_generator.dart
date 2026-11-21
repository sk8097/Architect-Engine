import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/promenade_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class PromenadePad {
  const PromenadePad(this.id, this.startMm, this.endMm, this.projectionMm, this.minShoreMm);
  final String id;
  final int startMm, endMm, projectionMm;
  final double minShoreMm;
  double get areaM2 => (endMm - startMm) * projectionMm / 1e6;
}

class PromenadeCadResult {
  const PromenadeCadResult({this.drawing, this.issue, this.pads = const [], this.lengthMm = 0, this.widthMm = 0,
    this.minShoreMm = 0, this.minInlandMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<PromenadePad> pads;
  final int lengthMm, widthMm;
  final double minShoreMm;
  final int minInlandMm;
  double get pathAreaM2 => lengthMm * widthMm / 1e6;
  double get padAreaM2 => pads.fold(0.0, (sum, p) => sum + p.areaM2);

  String? toCsv() {
    if (drawing == null) return null;
    String m(num v) => (v / 1000).toStringAsFixed(6);
    return [
      'id,start_chainage_m,end_chainage_m,shoreward_projection_m,minimum_baseline_normal_shore_gap_m,pad_area_m2',
      for (final p in pads) [p.id, m(p.startMm), m(p.endMm), m(p.projectionMm), m(p.minShoreMm), p.areaM2.toStringAsFixed(6)].join(','),
      '',
    ].join('\r\n');
  }
}

/// Plan only. All gaps are measured at equal chainage, normal to a straight baseline.
class PromenadeCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['promenade_mode'] == 'survey_promenade';

  PromenadeCadResult generate(ProjectBrief brief) {
    PromenadeCadResult stop(String issue) => PromenadeCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !promenadeCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Waterfront Promenade and save the current surveyed brief.');
    }
    if (!const {null, 'linear_corridor', 'public_open_space'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one surveyed outdoor corridor without buildings, parking or separate Space selections.');
    }
    final a = req.answers;
    final rawGrid = a['pmr_grid'];
    final grid = rawGrid is String ? rawGrid.trim().replaceAll(RegExp(r'\s+'), ' ') : '';
    if (grid.isEmpty || grid.length > 100) return stop('Enter a projected metre grid, up to 100 characters.');
    List<String> rows(String key, int limit) {
      final raw = a[key];
      return raw is String && raw.length <= limit
        ? raw.split(RegExp(r'[;\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : const [];
    }
    final decimal = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? survey(String text, num min, num max) {
      final v = double.tryParse(text);
      return decimal.hasMatch(text.trim()) && v != null && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    }
    int? mm(String key, num min, num max) {
      final v = a[key];
      return v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    }
    final axis = rows('pmr_axis', 280);
    if (axis.length != 2) return stop('Enter two baseline controls, A then B.');
    final points = <(int, int)>[];
    for (final row in axis) {
      final v = row.split(',');
      if (v.length != 2) return stop('Use Easting,Northing for each projected baseline control.');
      final x = survey(v[0], -10000000, 10000000), y = survey(v[1], -10000000, 10000000);
      if (x == null || y == null) return stop('Use valid projected metre controls with up to three decimals.');
      points.add((x, y));
    }
    final (ax, ay) = points.first;
    final (bx, by) = points.last;
    final dx = (bx - ax).toDouble(), dy = (by - ay).toDouble(), length = math.sqrt(dx * dx + dy * dy);
    if (length < 1 || length > 2000000) return stop('Use a positive straight A–B baseline of at most 2 km.');
    final side = a['pmr_land_side'];
    final path = mm('pmr_path', -500, 500), width = mm('pmr_width', .001, 200);
    final shoreGap = mm('pmr_shore_gap', 0, 200), inlandGap = mm('pmr_inland_gap', 0, 200);
    if (!const {'left', 'right'}.contains(side) || path == null || width == null || shoreGap == null || inlandGap == null) {
      return stop('Enter landward side, path offset, width and both minimum gaps.');
    }
    final rawLimits = rows('pmr_limits', 7000);
    if (rawLimits.length < 2 || rawLimits.length > 80) return stop('Enter 2–80 survey limit samples spanning the path.');
    final limits = <({int ch, int shore, int inland})>[];
    final landEdge = path + width;
    String m(num mm) => (mm / 1000).toStringAsFixed(3);
    int? minShore, minLand;
    for (var i = 0; i < rawLimits.length; i++) {
      final v = rawLimits[i].split(',');
      if (v.length != 3) return stop('Limit sample ${i + 1} needs chainage, shoreline offset and inland offset.');
      final ch = survey(v[0], 0, 2000), shore = survey(v[1], -500, 500), inland = survey(v[2], -500, 500);
      if (ch == null || shore == null || inland == null) return stop('Limit sample ${i + 1} needs valid surveyed metres with up to three decimals.');
      if (ch > length + 1e-6 || (limits.isNotEmpty && ch <= limits.last.ch)) {
        return stop('Limit chainages must strictly increase within the A–B baseline.');
      }
      if (shore >= inland) return stop('At Ch ${m(ch)} m, the shoreline must be shoreward of the inland limit.');
      final s = path - shore, l = inland - landEdge;
      if (s < shoreGap) return stop('At Ch ${m(ch)} m, the path does not leave the supplied baseline-normal shoreline gap.');
      if (l < inlandGap) return stop('At Ch ${m(ch)} m, the path does not leave the supplied inland gap.');
      if (minShore == null || s < minShore) minShore = s;
      if (minLand == null || l < minLand) minLand = l;
      limits.add((ch: ch, shore: shore, inland: inland));
    }
    final lo = limits.first.ch, hi = limits.last.ch;
    double shoreAt(int ch) {
      for (var i = 1; i < limits.length; i++) {
        final next = limits[i];
        if (ch <= next.ch) {
          final prev = limits[i - 1];
          return prev.shore.toDouble() + (next.shore - prev.shore) * (ch - prev.ch) / (next.ch - prev.ch);
        }
      }
      return limits.last.shore.toDouble();
    }
    final rawPads = rows('pmr_pads', 2200);
    if (rawPads.isEmpty || rawPads.length > 12) return stop('Enter 1–12 lookout pad records.');
    final id = RegExp(r'^[A-Za-z][A-Za-z0-9_-]{0,15}$');
    final ids = <String>{}, pads = <PromenadePad>[];
    final minInland = minLand!;
    var minOverall = minShore!.toDouble();
    for (var i = 0; i < rawPads.length; i++) {
      final v = rawPads[i].split(',').map((s) => s.trim()).toList();
      if (v.length != 4 || !id.hasMatch(v[0])) return stop('Pad record ${i + 1} needs a letter-led ID and start, end and projection dimensions.');
      final name = v[0];
      if (!ids.add(name.toUpperCase())) return stop('Lookout pad ID $name is repeated.');
      final start = survey(v[1], 0, 2000), end = survey(v[2], 0, 2000), depth = survey(v[3], .001, 200);
      if (start == null || end == null || depth == null || start < lo || end > hi || start >= end) {
        return stop('Pad $name needs positive length and projection, within the surveyed path chainages.');
      }
      if (pads.isNotEmpty && start < pads.last.endMm) {
        return stop('Pad $name must be in increasing order without overlap with the preceding pad.');
      }
      // The shoreline is piecewise linear. Each pad edge is constant in offset,
      // so the minimum gap occurs at an end or an intervening survey breakpoint.
      final stations = [start, for (final s in limits) if (s.ch > start && s.ch < end) s.ch, end];
      var padGap = double.infinity;
      for (final ch in stations) {
        final g = (path - depth).toDouble() - shoreAt(ch);
        if (g < shoreGap - 1e-8) return stop('Pad $name does not leave the supplied shoreline gap at Ch ${m(ch)} m.');
        if (g < padGap) padGap = g;
      }
      if (padGap < minOverall) minOverall = padGap;
      pads.add(PromenadePad(name, start, end, depth, padGap));
    }

    final sign = side == 'left' ? 1 : -1;
    CadPoint p(num ch, num offset) => CadPoint(ax + (dx * ch - sign * dy * offset) / length, ay + (dy * ch + sign * dx * offset) / length);
    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num s, num o, num e, num q) {
      if (s != e || o != q) lines.add(CadLine(layer, p(s, o), p(e, q)));
    }
    for (var i = 1; i < limits.length; i++) {
      final a = limits[i - 1], b = limits[i];
      line('PROM_SHORE', a.ch, a.shore, b.ch, b.shore);
      line('PROM_LIMIT', a.ch, a.inland, b.ch, b.inland);
    }
    line('PROM_AXIS', 0, 0, length, 0);
    line('PROM_PATH', lo, landEdge, hi, landEdge);
    line('PROM_PATH', lo, path, lo, landEdge);
    line('PROM_PATH', hi, path, hi, landEdge);
    final corners = [p(0, 0), p(length, 0), for (final l in limits) ...[p(l.ch, l.shore), p(l.ch, l.inland)]];
    final x0 = corners.map((p) => p.x).reduce(math.min), x1 = corners.map((p) => p.x).reduce(math.max);
    final y0 = corners.map((p) => p.y).reduce(math.min), y1 = corners.map((p) => p.y).reduce(math.max);
    final cx = (x0 + x1) / 2, t = (math.max(x1 - x0, y1 - y0) / 92).clamp(40, 16000).toDouble();
    // Pad mouths stay open to the path. Where two pads touch, combine the shared side and draw only the exposed step.
    var previousEnd = lo, previousDepth = 0;
    for (final pad in pads) {
      final start = pad.startMm, end = pad.endMm, depth = pad.projectionMm;
      if (start > previousEnd) {
        if (previousDepth > 0) line('PROM_PAD', previousEnd, path - previousDepth, previousEnd, path);
        line('PROM_PATH', previousEnd, path, start, path);
        line('PROM_PAD', start, path, start, path - depth);
      } else {
        line('PROM_PAD', start, path - previousDepth, start, path - depth);
      }
      line('PROM_PAD', start, path - depth, end, path - depth);
      labels.add(CadLabel('PROM_PAD', p((start + end) / 2, path - depth / 2), pad.id,
        math.min(t, math.min(depth / 3, (end - start) / (pad.id.length + 1)))));
      previousEnd = end;
      previousDepth = depth;
    }
    line('PROM_PAD', previousEnd, path - previousDepth, previousEnd, path);
    line('PROM_PATH', previousEnd, path, hi, path);
    final nx = math.max(cx + 42 * t, x1 + 4 * t);
    final tip = CadPoint(nx, y1);
    lines.addAll([CadLine('ANNOTATIONS', CadPoint(nx, y1 - 2 * t), tip),
      CadLine('ANNOTATIONS', CadPoint(nx - .5 * t, y1 - t), tip), CadLine('ANNOTATIONS', CadPoint(nx + .5 * t, y1 - t), tip)]);
    labels.addAll([
      CadLabel('PROM_AXIS', p(-1.7 * t, 0), 'A', t * .7), CadLabel('PROM_AXIS', p(length + 1.7 * t, 0), 'B', t * .7),
      CadLabel('ANNOTATIONS', CadPoint(nx, y1 + t), 'GRID N', t * .65),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 6.7 * t), 'SURVEYED WATERFRONT PROMENADE / PROJECTED MM', t),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 5.3 * t), 'PATH CH ${m(lo)} TO ${m(hi)} M / ${m(width)} M WIDE / ${pads.length} PAD(S)', t * .66),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 3.9 * t), 'MIN SHORE GAP ${m(minOverall)} M / MIN INLAND GAP ${m(minInland)} M / BASELINE-NORMAL', t * .61),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 2.5 * t), 'GRID: $grid / LANDWARD ${side.toString().toUpperCase()} OF A-B', t * .57),
      CadLabel('ANNOTATIONS', CadPoint(cx, y1 + 1.1 * t), 'HORIZONTAL GEOMETRY ONLY / NO FLOOD OR COASTAL APPROVAL', t * .62),
    ]);
    final bounds = PlanRect(math.min(x0 - 4 * t, cx - 42 * t).floor(), (y0 - 4 * t).floor(), (nx + 4 * t).ceil(), (y1 + 8.2 * t).ceil());
    return PromenadeCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels),
      pads: List.unmodifiable(pads), lengthMm: hi - lo, widthMm: width, minShoreMm: minOverall, minInlandMm: minInland);
  }
}
