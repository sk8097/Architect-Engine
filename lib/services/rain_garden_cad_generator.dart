import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/rain_garden_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class RainGardenCadResult {
  const RainGardenCadResult({this.plan, this.section, this.issue, this.widthMm = 0, this.depthMm = 0,
    this.pondMm = 0, this.freeboardMm = 0, this.storageM3 = 0, this.mediaM3 = 0, this.aggregateM3 = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final double widthMm, depthMm, storageM3, mediaM3, aggregateM3;
  final int pondMm, freeboardMm;
}

/// Surface ponding and gross horizontal layer quantities. No hydrology.
class RainGardenCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == rainGardenMode;

  RainGardenCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    RainGardenCadResult stop(String issue) => RainGardenCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !rainGardenCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Public Garden and save the current measured rain-garden brief.');
    }
    if (!const {null, 'public_open_space'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor rain garden without enclosed floors, parking or separate Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    double? n(Object? v, {num min = .001, num max = 100}) =>
        v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    int? mm(Object? v, {num min = .001, num max = 100}) {
      final a = n(v, min: min, max: max);
      return a == null ? null : (1000 * a).round();
    }
    final a = req.answers;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final w = mm(a['rg_bed_w']), l = mm(a['rg_bed_l']);
    final sx = n(a['rg_slope_we'], min: 1, max: 20), sy = n(a['rg_slope_sn'], min: 1, max: 20);
    final pond = mm(a['rg_pond'], max: 5), free = mm(a['rg_free'], max: 5);
    final media = mm(a['rg_media'], max: 5), aggregate = mm(a['rg_agg'], max: 5);
    final reserve = mm(a['rg_reserve'], max: 25), minReserve = mm(a['rg_reserve_min'], max: 25);
    final minStorage = n(a['rg_storage_min'], max: 1000000);
    final west = mm(a['rg_west'], min: 0, max: 2000), south = mm(a['rg_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || w == null || l == null || sx == null || sy == null ||
        pond == null || free == null || media == null || aggregate == null || reserve == null || minReserve == null ||
        minStorage == null || west == null || south == null) {
      return stop('Enter valid measured plot, bed, slopes, depths, reserves and minimum surface storage.');
    }
    if (reserve < minReserve) return stop('The maintenance reserve beyond the rim is below the submitted minimum.');
    final rim = pond + free;
    double across(num height) => w.toDouble() + 2 * sx * height;
    double along(num height) => l.toDouble() + 2 * sy * height;
    final rimW = across(rim), rimL = along(rim);
    final fullW = rimW + 2 * reserve, fullL = rimL + 2 * reserve;
    for (final (edge, gap) in [('left', west), ('right', pw - west - fullW), ('front', south), ('rear', pd - south - fullL)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || gap < min - 1e-8) return stop('The rim and maintenance envelope conflict with the $edge plot edge or supplied setback.');
    }
    double area(num h) => across(h) * along(h);
    // Width and length grow linearly, so area is quadratic. The prismoidal
    // formula integrates it exactly, also with different slopes on the two axes.
    final storage = pond * (area(0) + 4 * area(pond / 2) + area(pond)) / 6e9;
    if (storage < minStorage - 1e-9) {
      return stop('Surface ponding volume is ${storage.toStringAsFixed(6)} m³, below the submitted target.');
    }
    final mediaM3 = w * l * media / 1e9, aggM3 = w * l * aggregate / 1e9;
    final plan = _GardenSheet(), section = _GardenSheet();
    plan.box('RG_PLOT', 0, 0, pw, pd);
    plan.box('RG_RESERVE', west, south, west + fullW, south + fullL);
    final cx = west + fullW / 2, cy = south + fullL / 2;
    for (final (layer, h) in [('RG_BED', 0), ('RG_WATER', pond), ('RG_RIM', rim)]) {
      final halfW = across(h) / 2, halfL = along(h) / 2;
      plan.box(layer, cx - halfW, cy - halfL, cx + halfW, cy + halfL);
    }
    plan.line('RG_CUT', west, cy, west + fullW, cy);
    final t = (math.max(pw, pd) / 90).clamp(20, 8000).toDouble(), nx = pw + 2.5 * t;
    plan.line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    plan.line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    plan.line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    plan.mark('ANNOTATIONS', nx, pd + t, 'N', .7 * t);
    plan.mark('RG_CUT', west - t, cy, 'A', .6 * t);
    plan.mark('RG_CUT', west + fullW + t, cy, 'A', .6 * t);
    plan.heading(pw / 2, pd, t, [
      'MEASURED PUBLIC RAIN GARDEN / PLAN / LOCAL MM',
      'RIM ${_m(rimW)} x ${_m(rimL)} M / FULL ENVELOPE ${_m(fullW)} x ${_m(fullL)} M',
      'DESIGN WATER OUTLINE / WEST-EAST SECTION A-A / NO HYDROLOGY',
    ]);

    final middle = fullW / 2, bedL = middle - w / 2, bedR = middle + w / 2;
    section.line('RG_RESERVE', 0, rim, reserve, rim);
    section.line('RG_RESERVE', fullW - reserve, rim, fullW, rim);
    section.line('RG_RIM', reserve, rim, bedL, 0);
    section.line('RG_RIM', bedR, 0, fullW - reserve, rim);
    section.line('RG_WATER', middle - across(pond) / 2, pond, middle + across(pond) / 2, pond);
    section.line('RG_BED', bedL, 0, bedR, 0);
    // The two prisms share a single interface, with no coincident lines.
    section.line('RG_MEDIA', bedL, 0, bedL, -media);
    section.line('RG_MEDIA', bedL, -media, bedR, -media);
    section.line('RG_MEDIA', bedR, -media, bedR, 0);
    section.line('RG_AGG', bedL, -media, bedL, -media - aggregate);
    section.line('RG_AGG', bedL, -media - aggregate, bedR, -media - aggregate);
    section.line('RG_AGG', bedR, -media - aggregate, bedR, -media);
    final st = (math.max(fullW, rim + media + aggregate) / 75).clamp(12, 8000).toDouble();
    section.heading(middle, rim, st, [
      'SECTION A-A / WEST-EAST / TRUE SCALE MM / BED = ZERO',
      'PONDING ${_m(pond)} M / FREEBOARD ${_m(free)} M / SURFACE STORAGE ${storage.toStringAsFixed(3)} M3',
      'PLANTING MEDIA ${mediaM3.toStringAsFixed(3)} M3 / AGGREGATE ${aggM3.toStringAsFixed(3)} M3 GROSS',
      'NO VOID STORAGE, INFILTRATION OR DRAINAGE CAPACITY CREDIT',
    ]);
    return RainGardenCadResult(plan: plan.drawing(0, 0, nx, pd, t), section: section.drawing(0, -media - aggregate, fullW, rim, st),
      widthMm: fullW, depthMm: fullL, pondMm: pond, freeboardMm: free, storageM3: storage, mediaM3: mediaM3, aggregateM3: aggM3);
  }
}

class _GardenSheet {
  final lines = <CadLine>[], labels = <CadLabel>[];
  void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
  void box(String layer, num x, num y, num ex, num ey) {
    line(layer, x, y, ex, y);
    line(layer, ex, y, ex, ey);
    line(layer, ex, ey, x, ey);
    line(layer, x, ey, x, y);
  }
  void mark(String layer, num x, num y, String text, num height) => labels.add(CadLabel(layer, CadPoint(x, y), text, height));
  void heading(num x, num y, double size, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      mark('ANNOTATIONS', x, y + (rows.length - i + .5) * 1.25 * size, rows[i], i == 0 ? size : size * .64);
    }
  }
  FloorPlanCad drawing(num left, num low, num right, num high, double size) {
    for (final label in labels) {
      final half = label.text.length * label.height * .41;
      left = math.min(left, label.at.x - half);
      right = math.max(right, label.at.x + half);
      low = math.min(low, label.at.y - label.height);
      high = math.max(high, label.at.y + label.height);
    }
    return FloorPlanCad.fromEntities(bounds: PlanRect((left - 2 * size).floor(), (low - 2 * size).floor(),
      (right + 2 * size).ceil(), (high + 2 * size).ceil()), lines: lines, labels: labels);
  }
}
