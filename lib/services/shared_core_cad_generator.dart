import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/shared_core_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;
import 'tower_plan_generator.dart';

/// Two identical gross plates: a retail wing below an office wing and one
/// shared entrance/core strip. A shaft is only an aligned physical reserve.
class SharedCoreCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'shared_core_shop_office';

  TowerResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    TowerResult stop(String issue) => TowerResult(const [], [issue]);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !sharedCoreCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Office + Retail or Shop-Cum-Office and save the current measured brief.');
    }
    final a = snap.answers;
    bool positive(String key) => a[key] is num && (a[key] as num) > 0;
    if (brief.floorCount != 2 || (a['building_count'] ?? 1) != 1 || positive('basements') || positive('mezzanines') ||
        !const {null, 'vertical_mixed_use'}.contains(sel.configurationId) || !const {null, 'g1'}.contains(a['sco_layout'])) {
      return stop('Use a single vertical G+1 building with retail at ground and office on the first floor.');
    }
    if (!const {null, 'concept_design', 'new_design', 'feasibility'}.contains(sel.actionId) ||
        const {'existing', 'brownfield', 'partial_demolition'}.contains(a['build_status']) ||
        const {'existing', 'partial', 'renovation', 'demolish'}.contains(a['construction_status'])) {
      return stop('This shared-core template is a new concept, not an alteration or approval drawing.');
    }
    if (!const {null, ProjectParking.none}.contains(brief.parking) || a['parking_sqft'] != null || a['terrace_needed'] == 'yes' ||
        !const {null, 'none'}.contains(a['lift_plan']) || !const {null, 'straight'}.contains(a['stair_form']) ||
        !const {null, 'lobby', 'inside'}.contains(a['stair_access']) ||
        !const {null, 'common'}.contains(a['upper_use']) || sel.spaceQuantities.isNotEmpty) {
      return stop('This layout draws only the measured shared lobby, straight stair, shaft and two wings. No lifts, parking, terraces or separate Space selections.');
    }
    bool matches(String key, Set<String> allowed, {bool complete = false}) {
      final set = a[key];
      return set == null || (set is Iterable && (set.isEmpty ||
        set.every(allowed.contains) && (!complete || set.toSet().length == allowed.length)));
    }
    if (!matches('mixed_components', {'office', 'retail'}, complete: true) ||
        !matches('mixed_levels', {'ground', 'office'}, complete: true) || !matches('mixed_separation', {'fire', 'acoustics', 'metering'})) {
      return stop('Use only ground retail and upper office with one shared lobby. Separate entries, lift banks, loading and exhaust routes are not drawn.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId) || !const {'North', 'East', 'South', 'West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and cardinal shared frontage.');
    }
    int? mm(Object? raw, {bool zero = false}) {
      if (raw is! num || !raw.isFinite || raw < 0 || raw > 300) return null;
      final n = (raw * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final plotW = mm(widthFt * .3048), plotD = mm(depthFt * .3048), w = mm(a['cad_plate_width']), d = mm(a['cad_plate_depth']);
    final x = mm(a['cad_offset_left'], zero: true), y = mm(a['cad_offset_front'], zero: true), t = mm(a['cad_wall']);
    final door = mm(a['cad_door']), walk = mm(a['sc_approach']);
    if (plotW == null || plotD == null || w == null || d == null || x == null || y == null || t == null ||
        door == null || walk == null || (sel.plotShapeId == 'square' && plotW != plotD)) {
      return stop('Enter the measured plot, both plate dimensions, walls, shared door, offsets and approach widths.');
    }
    for (final (side, available) in [('left', x), ('right', plotW - x - w), ('front', y), ('rear', plotD - y - d)]) {
      final raw = a['${side}_setback'], setback = raw == null ? 0 : mm(raw, zero: true);
      if (setback == null || available < setback) return stop('Both plates must fit the plot and supplied $side setback.');
    }
    final fsi = a['fsi_limit'], coverage = a['coverage_limit'];
    if (fsi is num && 2 * w * d > plotW * plotD * fsi) return stop('Both gross floors exceed the supplied FAR/FSI allowance.');
    if (coverage is num && w * d > plotW * plotD * coverage / 100) return stop('The shared plate exceeds the supplied coverage allowance.');

    final coreW = mm(a['g1_width']), rise = mm(a['g1_height']), going = mm(a['g1_going']), landing = mm(a['g1_landing']);
    final lobbyD = mm(a['sc_front_lobby']), upperMin = mm(a['sc_upper_lobby']), shaftD = mm(a['sc_shaft']);
    final salesD = mm(a['sc_sales_depth']), meetD = mm(a['sc_meeting_depth']), risers = a['g1_risers'];
    if (coreW == null || rise == null || going == null || landing == null || lobbyD == null || upperMin == null ||
        shaftD == null || salesD == null || meetD == null || risers is! int || risers < 2 || risers > 50) {
      return stop('Enter measured stair, both lobby sizes, shaft, shop and meeting depths, plus 2–50 risers.');
    }
    final iw = w - 2 * t, id = d - 2 * t, cx = iw - coreW, wingW = cx - t;
    if (door <= t || coreW <= door || wingW <= door || walk < door || walk > coreW || y <= 0) {
      return stop('The shared approach must fit the core and span the door. The core and occupied wing must fit the door swing.');
    }
    if (landing < door || lobbyD < door) return stop('The shared lobby and both stair end landings must fit a full door swing.');
    final spec = StraightStairSpec(risers: risers, going: going, landing: landing, height: rise);
    final floorCut = lobbyD + t, stairEnd = floorCut + spec.depth, upperStart = stairEnd + t;
    final shaftStart = id - shaftD, upperEnd = shaftStart - t;
    if (upperEnd - upperStart < math.max(upperMin, door)) {
      return stop('The shared stair, end landings, upper lobby and service shaft do not fit together in the measured depth.');
    }
    if (salesD <= door || id - salesD - t < door || meetD < door || id - meetD - t <= door) {
      return stop('The sales, stock, workspace and meeting room partitions must leave room for their door swings.');
    }
    final netWingSqm = wingW * (id - t) / 1000000;
    for (final (key, label) in [('shop_area', 'retail'), ('office_area', 'office')]) {
      final target = a[key];
      if (target is num && netWingSqm < target) return stop('The measured $label wing is smaller than the supplied target area.');
    }
    final groundAccess = math.min(salesD, lobbyD), meetingEnd = meetD + t, officeStart = math.max(meetingEnd, upperStart);
    if (groundAccess <= door || upperEnd - officeStart <= door) {
      return stop('The shared lobby must overlap the shop, and the upper lobby must overlap the workspace, by enough for each doorway.');
    }
    final shopX = (wingW - door) ~/ 2, coreDoorX = cx + (coreW - door) ~/ 2;
    final walkX = coreDoorX - (walk - door) ~/ 2;
    final shopDoorY = (groundAccess - door) ~/ 2, officeDoorY = officeStart + (upperEnd - officeStart - door) ~/ 2;
    final rotated = facing == 'East' || facing == 'West';
    PlanRect orient(PlanRect b) => switch (facing) {
      'North' => PlanRect(plotW - b.right, plotD - b.top, plotW - b.left, plotD - b.bottom),
      'East' => PlanRect(plotD - b.top, b.left, plotD - b.bottom, b.right),
      'West' => PlanRect(b.bottom, plotW - b.right, b.top, plotW - b.left),
      _ => b,
    };
    PlanRect rect(int l, int b, int r, int top) => orient(PlanRect(x + t + l, y + t + b, x + t + r, y + t + top));
    (int, int) point(int l, int b) { final p = rect(l, b, l, b); return (p.left, p.bottom); }
    const stairId = 'shared_stair', shaft = 'shared_shaft', lobby = 'shared_lobby', upLobby = 'upper_core_lobby';
    const sales = 'shared_sales', stock = 'shared_stock', meeting = 'shared_meeting', office = 'shared_office';
    const outside = AutomaticFloorPlan.entry;
    final plot = PlanRect(0, 0, rotated ? plotD : plotW, rotated ? plotW : plotD), footprint = orient(PlanRect(x, y, x + w, y + d));
    final sheets = <TowerSheet>[];
    for (final upper in [false, true]) {
      final rooms = <PlanRoom>[], walls = <PlanRect>[], openings = <PlanOpening>[];
      void room(String key, String label, int l, int b, int r, int top) => rooms.add(PlanRoom(key, label, rect(l, b, r, top)));
      void wall(int l, int b, int r, int top) { if (l < r && b < top) walls.add(rect(l, b, r, top)); }
      void opening(String from, String to, int l, int b, int r, int top) =>
        openings.add(PlanOpening(PlanOpeningKind.door, rect(l, b, r, top), from, to));
      wall(-t, -t, 0, id + t);
      wall(iw, -t, iw + t, id + t);
      wall(0, id, iw, id + t);
      if (upper) {
        wall(0, -t, iw, 0);
        room('reserve_core_front', 'Sealed core reserve', cx, 0, iw, lobbyD);
        wall(cx, lobbyD, iw, floorCut);
        room(upLobby, 'Upper landing lobby', cx, upperStart, iw, upperEnd);
        wall(cx, stairEnd, coreDoorX, upperStart);
        opening(stairId, upLobby, coreDoorX, stairEnd, coreDoorX + door, upperStart);
        wall(coreDoorX + door, stairEnd, iw, upperStart);
      } else {
        wall(0, -t, coreDoorX, 0);
        opening(outside, lobby, coreDoorX, -t, coreDoorX + door, 0);
        wall(coreDoorX + door, -t, iw, 0);
        room(lobby, 'Shared ground lobby', cx, 0, iw, lobbyD);
        wall(cx, lobbyD, coreDoorX, floorCut);
        opening(lobby, stairId, coreDoorX, lobbyD, coreDoorX + door, floorCut);
        wall(coreDoorX + door, lobbyD, iw, floorCut);
        wall(cx, stairEnd, iw, upperStart);
        room('reserve_core_rear', 'Sealed core reserve', cx, upperStart, iw, upperEnd);
      }
      room(stairId, 'Shared straight stair', cx, floorCut, iw, stairEnd);
      wall(cx, upperEnd, iw, shaftStart);
      room(shaft, 'Sealed aligned service shaft reserve', cx, shaftStart, iw, id);
      final sideDoorY = upper ? officeDoorY : shopDoorY, split = upper ? meetD : salesD;
      wall(wingW, 0, cx, sideDoorY);
      opening(upper ? upLobby : lobby, upper ? office : sales, wingW, sideDoorY, cx, sideDoorY + door);
      wall(wingW, sideDoorY + door, cx, id);
      room(upper ? meeting : sales, upper ? 'Meeting room' : 'Retail sales floor', 0, 0, wingW, split);
      room(upper ? office : stock, upper ? 'Office workspace' : 'Back stock room', 0, split + t, wingW, id);
      wall(0, split, shopX, split + t);
      opening(upper ? office : sales, upper ? meeting : stock, shopX, split, shopX + door, split + t);
      wall(shopX + door, split, wingW, split + t);
      final plan = AutomaticFloorPlan(plot: plot, footprint: footprint, facing: facing,
        sheetTitle: upper ? 'FIRST FLOOR / OFFICE AND SHARED CORE' : 'GROUND FLOOR / SHOP AND SHARED CORE',
        rooms: rooms, walls: walls, openings: openings,
        stairs: [spec.drawing(stairId, PlanRect(cx, floorCut, iw, stairEnd), !upper, point)]);
      final sealed = rooms.where((r) => r.id == shaft || r.id.startsWith('reserve_core_')).toList();
      final issue = validatePlanGeometry(plan, indoorSeed: upper ? stairId : null, sealedRooms: sealed.map((r) => r.id).toSet());
      if (issue != null) return stop('The ${upper ? 'upper' : 'ground'} floor failed geometry validation: $issue');
      sheets.add(TowerSheet(upper ? 'Office and meeting' : 'Retail and stock', upper ? 'First floor' : 'Ground floor',
        upper ? 2 : 1, upper ? 2 : 1, plan, sealed.where((r) => r.id != shaft).fold(0, (sum, r) => sum + r.bounds.area), siteZones: [
          if (!upper) MeasuredZone('sc_walk', 'Shared front approach', rect(walkX, -y - t, walkX + walk, -t), 'SHARED_CORE_APPROACH'),
          MeasuredZone('sc_lobby', upper ? 'Upper landing lobby' : 'Common entry lobby',
            upper ? rect(cx, upperStart, iw, upperEnd) : rect(cx, 0, iw, lobbyD), 'SHARED_CORE_LOBBY'),
          MeasuredZone('sc_shaft', 'Aligned shaft reserve', rect(cx, shaftStart, iw, id), 'SHARED_CORE_SHAFT'),
        ]));
    }
    return TowerResult(List.unmodifiable(sheets), const []);
  }
}
