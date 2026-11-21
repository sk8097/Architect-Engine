import 'dart:math' as math;

import '../data/inpatient_ward_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;

class InpatientWardResult {
  const InpatientWardResult(this.plan, this.issue, {this.zones = const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
}

/// Measured general ward, not a hospital design or clinical assessment.
class InpatientWardCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'inpatient_ward';

  InpatientWardResult generate(ProjectBrief brief, {required double widthFt,
    required double depthFt, required String facing}) {
    InpatientWardResult stop(String issue) => InpatientWardResult(null, issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !inpatientWardEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Hospital, General Hospital or Nursing Home and save the current general ward brief.');
    }
    final a = snap.answers;
    bool positive(String key) => a[key] is num && (a[key] as num) > 0;
    if (brief.floorCount != 1 || (a['building_count'] ?? 1) != 1 || positive('basements') || positive('mezzanines') ||
        !const {null, 'inpatient'}.contains(sel.configurationId)) {
      return stop('Use one ground-floor inpatient ward only, not an outpatient, mixed-care or multi-building program.');
    }
    if (!const {null, 'concept_design', 'new_design', 'feasibility'}.contains(sel.actionId) ||
        const {'existing', 'brownfield', 'partial_demolition'}.contains(a['build_status']) ||
        const {'existing', 'partial', 'renovation', 'demolish'}.contains(a['construction_status'])) {
      return stop('This general ward is a new plan-view concept, not a surveyed retrofit or approval drawing.');
    }
    if (sel.spaceQuantities.isNotEmpty || positive('consult_rooms') || positive('procedure_rooms') ||
        !const {null, ProjectParking.none}.contains(brief.parking) || a['parking_sqft'] != null || a['terrace_needed'] == 'yes') {
      return stop('The template already draws the ward, nursing counter and washroom reserve. Remove other Space selections, consultation/procedure rooms, parking and terrace requests.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId) || !const {'North', 'East', 'South', 'West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and a cardinal public approach.');
    }
    final count = a['beds'];
    if (count is! int || count < 2 || count > 20 || count.isOdd) return stop('Enter an even ward bed count from 2 to 20, split evenly between the two banks.');
    int? mm(Object? raw, {bool zero = false}) {
      if (raw is! num || !raw.isFinite || raw < 0 || raw > 300) return null;
      final n = (raw * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final plotW = mm(widthFt * .3048), plotD = mm(depthFt * .3048), w = mm(a['cad_plate_width']), d = mm(a['cad_plate_depth']);
    final x = mm(a['cad_offset_left'], zero: true), y = mm(a['cad_offset_front'], zero: true), t = mm(a['cad_wall']);
    final door = mm(a['cad_door']), main = mm(a['iw_central']), lobbyD = mm(a['iw_lobby_depth']);
    if (plotW == null || plotD == null || w == null || d == null || x == null || y == null || t == null ||
        door == null || main == null || lobbyD == null || (sel.plotShapeId == 'square' && plotW != plotD)) {
      return stop('Enter the measured envelope, plot, offsets, wall, door, central aisle and front lobby.');
    }
    for (final (side, available) in [('left', x), ('right', plotW - x - w), ('front', y), ('rear', plotD - y - d)]) {
      final supplied = a['${side}_setback'], setback = supplied == null ? 0 : mm(supplied, zero: true);
      if (setback == null || available < setback) return stop('The ward conflicts with the plot boundary or supplied $side setback.');
    }
    final fsi = a['fsi_limit'], coverage = a['coverage_limit'];
    if (fsi is num && w * d > plotW * plotD * fsi) return stop('The ward exceeds the supplied FAR/FSI allowance.');
    if (coverage is num && w * d > plotW * plotD * coverage / 100) return stop('The ward exceeds the supplied site coverage.');
    final bw = mm(a['iw_bed_width']), bl = mm(a['iw_bed_length']), side = mm(a['iw_bed_side']), foot = mm(a['iw_bed_foot']);
    final endPad = mm(a['iw_end_clear']), deskL = mm(a['iw_counter_length']), deskD = mm(a['iw_counter_depth']), work = mm(a['iw_counter_work']);
    if (bw == null || bl == null || side == null || foot == null || endPad == null || deskL == null || deskD == null || work == null) {
      return stop('Enter all measured bed footprints, clearances, end pads and nursing counter dimensions.');
    }
    if (y <= 0 || door <= t || main < door || lobbyD - door < 2) {
      return stop('The approach and centre aisle must span the door, and the lobby must have room for the full swing.');
    }
    final iw = w - 2 * t, id = d - 2 * t;
    final left = (iw - main) ~/ 2, right = left + main, washLeft = right + t;
    if (left < bl + foot || iw - right < bl + foot) return stop('Both bed banks require enough clear width for the bed lengths and foot clearances outside the aisle.');
    if (iw - washLeft < door) return stop('The walled washroom reserve is too narrow for the supplied door swing.');
    // The counter faces the main aisle. Keep a clear approach around one end
    // so its working pocket is connected to the lobby, not boxed in by walls.
    if (deskD + work > left || deskL + work > lobbyD) {
      return stop('The nursing counter and connected working pocket do not fit beside the front aisle.');
    }
    final firstPad = math.max(door, endPad), depth = bw + 2 * side, n = count ~/ 2;
    final wardStart = lobbyD + t, need = firstPad + n * depth + endPad;
    if (id - wardStart < need) return stop('Both bed banks and their side access and end pads require ${(need / 1000).toStringAsFixed(3)} m of clear depth behind the lobby.');
    final bedStart = wardStart + firstPad + (id - wardStart - need) ~/ 2, bedEnd = bedStart + n * depth;
    final dx = left + (main - door) ~/ 2, wy = (lobbyD - door) ~/ 2;
    final rotated = facing == 'East' || facing == 'West';
    PlanRect orient(PlanRect b) => switch (facing) {
      'North' => PlanRect(plotW - b.right, plotD - b.top, plotW - b.left, plotD - b.bottom),
      'East' => PlanRect(plotD - b.top, b.left, plotD - b.bottom, b.right),
      'West' => PlanRect(b.bottom, plotW - b.right, b.top, plotW - b.left),
      _ => b,
    };
    PlanRect rect(int l, int b, int r, int top) => orient(PlanRect(x + t + l, y + t + b, x + t + r, y + t + top));
    const lobby = 'ward_lobby', ward = 'ward_room', wash = 'ward_wash';
    final plan = AutomaticFloorPlan(plot: PlanRect(0, 0, rotated ? plotD : plotW, rotated ? plotW : plotD),
      footprint: orient(PlanRect(x, y, x + w, y + d)), facing: facing, sheetTitle: 'GENERAL WARD / BEDS & NURSING ACCESS', rooms: [
        PlanRoom(lobby, 'Nursing lobby', rect(0, 0, right, lobbyD)),
        PlanRoom(wash, 'Enclosed washroom reserve', rect(washLeft, 0, iw, lobbyD)),
        PlanRoom(ward, 'General inpatient ward', rect(0, wardStart, iw, id)),
      ], walls: [
        rect(-t, -t, 0, id + t), rect(iw, -t, iw + t, id + t), rect(0, id, iw, id + t),
        rect(0, -t, dx, 0), rect(dx + door, -t, iw, 0),
        rect(0, lobbyD, dx, wardStart), rect(dx + door, lobbyD, iw, wardStart),
        rect(right, 0, washLeft, wy), rect(right, wy + door, washLeft, lobbyD),
      ], openings: [
        PlanOpening(PlanOpeningKind.door, rect(dx, -t, dx + door, 0), AutomaticFloorPlan.entry, lobby),
        PlanOpening(PlanOpeningKind.door, rect(dx, lobbyD, dx + door, wardStart), lobby, ward),
        PlanOpening(PlanOpeningKind.door, rect(right, wy, washLeft, wy + door), lobby, wash),
      ]);
    final issue = validatePlanGeometry(plan);
    if (issue != null) return stop('Ward partition failed geometry validation: $issue');
    const route = 'WARD_ROUTE', counter = 'WARD_COUNTER', clear = 'WARD_CLEAR', bed = 'WARD_BEDS';
    final deskX = left - deskD, workX = deskX - work;
    final zones = [
      MeasuredZone('iw_approach', 'Front approach', rect(left, -y - t, right, -t), route),
      MeasuredZone('iw_lobby_aisle', 'Clear lobby aisle', rect(left, 0, right, lobbyD), route),
      MeasuredZone('iw_front_pad', 'Ward entry clearance', rect(0, wardStart, iw, bedStart), route),
      MeasuredZone('iw_main_aisle', 'Clear centre aisle', rect(left, bedStart, right, bedEnd), route),
      MeasuredZone('iw_rear_pad', 'Ward rear clearance', rect(0, bedEnd, iw, id), route),
      MeasuredZone('iw_nursing_counter', 'Nursing counter', rect(deskX, 0, left, deskL), counter),
      MeasuredZone('iw_nursing_work', 'Nursing work pocket', rect(workX, 0, deskX, deskL), clear),
      MeasuredZone('iw_nursing_return', 'Access to nursing pocket', rect(workX, deskL, left, deskL + work), clear),
    ];
    for (var i = 0; i < n; i++) {
      final start = bedStart + i * depth, b = start + side, top = b + bw;
      for (final (name, inner, outer) in [('left', left, left - foot), ('right', right, right + foot)]) {
        final l = name == 'left' ? outer - bl : outer, r = l + bl;
        final prefix = 'iw_${name}_$i';
        zones.addAll([
          MeasuredZone('${prefix}_bed', 'Patient bed', rect(l, b, r, top), bed),
          MeasuredZone('${prefix}_side_a', 'Bedside clearance', rect(l, start, r, b), clear),
          MeasuredZone('${prefix}_side_b', 'Bedside clearance', rect(l, top, r, start + depth), clear),
          MeasuredZone('${prefix}_foot', 'Bed access from aisle', rect(math.min(inner, outer), start, math.max(inner, outer), start + depth), clear),
        ]);
      }
    }
    return InpatientWardResult(plan, null, zones: List.unmodifiable(zones));
  }
}
