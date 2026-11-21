import 'dart:math' as math;

import '../data/bicycle_rack_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class BicycleRackCadResult {
  const BicycleRackCadResult({this.drawing, this.issue, this.stands = 0, this.positions = 0,
    this.widthMm = 0, this.depthMm = 0, this.aisleMm = 0, this.loadedGapMm});

  final FloorPlanCad? drawing;
  final String? issue;
  final int stands, positions, widthMm, depthMm, aisleMm;
  final int? loadedGapMm;
}

/// Static plan with two measured, non-overlapping bicycle envelopes per stand.
class BicycleRackCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == 'bicycle_measured_racks';

  BicycleRackCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    BicycleRackCadResult stop(String issue) => BicycleRackCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !bicycleRackCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Public Parking or a supported station/interchange and save the measured bicycle brief.');
    }
    final configurations = sel.categoryId == 'institutional' ? const {null, 'outdoor'} : const {null, 'node_interchange', 'terminal_depot'};
    if (!configurations.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a ground-level bicycle layout only, without building floors, other parking or separate Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) {
      return stop('Use a cardinally aligned rectangular or square plot.');
    }
    final a = snap.answers;
    int? mm(Object? v, {bool zero = false, int max = 50}) =>
        v is num && v.isFinite && v >= (zero ? 0 : .001) && v <= max ? (v * 1000).round() : null;
    int? whole(String id, int min, int max) {
      final v = a[id];
      return v is num && v.isFinite && v >= min && v <= max && v == v.toInt() ? v.toInt() : null;
    }
    final banks = switch (a['br_banks']) {'1' => 1, '2' => 2, _ => null};
    final count = whole('br_stands', 1, 30), target = whole('br_target', 0, 120);
    if (banks == null || count == null || target == null) {
      return stop('Select one or two rows and enter valid stand and target counts.');
    }
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final bikeL = mm(a['br_cycle_l'], max: 8), bikeW = mm(a['br_cycle_w'], max: 4);
    final standL = mm(a['br_stand_l'], max: 8), standW = mm(a['br_stand_w'], max: 4), flank = mm(a['br_flank'], zero: true, max: 4);
    final pitch = mm(a['br_pitch'], zero: true), gap = mm(a['br_pair_gap'], zero: true);
    final aisle = mm(a['br_aisle']), outer = mm(a['br_outer']), headS = mm(a['br_head_s']), headN = mm(a['br_head_n']);
    final west = mm(a['br_west'], zero: true, max: 2000), south = mm(a['br_south'], zero: true, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || bikeL == null || bikeW == null ||
        standL == null || standW == null || flank == null || pitch == null || gap == null || aisle == null ||
        outer == null || headS == null || headN == null || west == null || south == null) {
      return stop('Enter measured plot, bicycle, stand, clearance and offset dimensions.');
    }
    if (standL > bikeL) return stop('Stand footprint length must fit inside the depth of the parked bicycle row.');
    final loaded = 2 * (bikeW + flank) + standW;
    final loadedGap = count > 1 ? pitch - loaded : null;
    if (loadedGap != null && loadedGap < gap) {
      return stop('Stand pitch is too small for two parked bicycles, the stand, its flank gaps and the requested gap between loaded stands.');
    }
    if (count == 1 && (pitch != 0 || gap != 0)) return stop('Use zero pitch and inter-stand gap for a single stand per row.');
    final width = 2 * outer + banks * bikeL + aisle;
    final depth = headS + loaded + (count - 1) * pitch + headN;
    for (final (edge, clear) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, zero: true, max: 2000);
      if (min == null || clear < min) return stop('The loaded rack layout conflicts with the $edge plot edge or supplied setback.');
    }
    final stands = count * banks, positions = stands * 2;
    if (positions < target) return stop('The layout holds $positions nominal bicycle positions, below the supplied target of $target.');

    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    final east = west + width, north = south + depth;
    final rackStart = south + headS, rackEnd = north - headN;
    final xWest = west + outer, aisleWest = xWest + bikeL, aisleEast = aisleWest + aisle;
    box('BIKE_PLOT', 0, 0, pw, pd);
    box('BIKE_LAYOUT', west, south, east, north);
    box('BIKE_MANOEUVRE', aisleWest, rackStart, aisleEast, rackEnd);
    box('BIKE_MANOEUVRE', west + outer, south, east - outer, rackStart);
    box('BIKE_MANOEUVRE', west + outer, rackEnd, east - outer, north);
    final text = (math.max(pw, pd) / 88).clamp(25, 6500).toDouble();
    for (var row = 0; row < banks; row++) {
      final x = row == 0 ? xWest : aisleEast;
      final standX = x + (bikeL - standL) / 2;
      for (var i = 0; i < count; i++) {
        final y = rackStart + i * pitch, yStand = y + bikeW + flank;
        box('BIKE_PARKED', x, y, x + bikeL, y + bikeW);
        box('BIKE_STAND', standX, yStand, standX + standL, yStand + standW);
        box('BIKE_PARKED', x, y + loaded - bikeW, x + bikeL, y + loaded);
        labels.add(CadLabel('BIKE_IDS', CadPoint(x + bikeL / 2, y + bikeW / 2), '${row == 0 ? 'W' : 'E'}${i + 1}',
          math.min(text * .9, math.min(bikeW / 3, bikeL / 6))));
      }
    }
    final ax = pw + 2 * text;
    line('ANNOTATIONS', ax, pd - 2 * text, ax, pd);
    line('ANNOTATIONS', ax - text / 2, pd - text, ax, pd);
    line('ANNOTATIONS', ax + text / 2, pd - text, ax, pd);
    String m(int v) => (v / 1000).toStringAsFixed(3);
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(ax, pd + text), 'N', text * .7),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 5 * text), 'MEASURED BICYCLE PARKING / LOCAL MM', text),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 3.5 * text), '$stands STANDS / $positions NOMINAL BICYCLE POSITIONS', text * .68),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 2 * text),
        'LAYOUT ${m(width)} x ${m(depth)} M / AISLE ${m(aisle)} M / STATIC FIT ONLY', text * .65),
    ]);
    final bounds = PlanRect(math.min(-text * 2, pw / 2 - text * 29).floor(), (-text * 2).floor(),
      math.max(ax + text * 3, pw / 2 + text * 29).ceil(), (pd + text * 7).ceil());
    return BicycleRackCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels),
      stands: stands, positions: positions, widthMm: width, depthMm: depth, aisleMm: aisle, loadedGapMm: loadedGap);
  }
}
