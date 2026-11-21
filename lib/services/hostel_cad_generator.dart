import '../data/hostel_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import '../models/project_requirements_snapshot.dart';
import 'enclosed_cad_generator.dart';

class HostelCadResult {
  const HostelCadResult(this.plan, this.issue, {this.fixtures = const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> fixtures;
}

/// Identical ground-floor shared bedrooms, two banks of single beds per room.
class HostelCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == 'hostel_shared_rooms';

  HostelCadResult generate(ProjectBrief brief, {required double widthFt,
    required double depthFt, required String facing}) {
    HostelCadResult stop(String issue) => HostelCadResult(null, issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || !hostelCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select a residential Student Hostel, Working-Person Hostel or Dormitory with a measured brief.');
    }
    if (!const {null, 'shared_rooms'}.contains(sel.configurationId)) {
      return stop('Choose Shared Rooms. This layout uses identical bedrooms, not single, mixed or family units.');
    }
    final counts = sel.spaceQuantities, rooms = counts['bedroom'];
    if (rooms == null || rooms < 1 || rooms > 6 || counts['warden_room'] != 1 || counts['toilets_baths'] != 1 ||
        counts.keys.any((id) => !hostelCadRoomIds.contains(id))) {
      return stop('Include 1–6 identical Bedrooms, one Warden Room and one Toilets/Baths reserve. Other room types are not drawn.');
    }
    final a = snap.answers, perRoom = snap.answers['beds_per_room'];
    if (perRoom is! int || !const {2, 4, 6, 8}.contains(perRoom)) {
      return stop('Enter 2, 4, 6 or 8 single beds per shared bedroom. Bunks and odd bed counts are not drawn.');
    }
    if (a['room_count'] != rooms || a['resident_capacity'] != rooms * perRoom) {
      return stop('Facility sleeping room count and resident capacity must match the measured bedrooms and beds per room.');
    }
    final warden = snap.spaceDetails['warden_room'] ?? const <String, Object>{};
    if (!const {null, 'any', 'front'}.contains(warden['zone_edge'])) return stop('Place the warden room at the front of the hostel.');
    for (final id in ['bedroom', 'toilets_baths']) {
      if (snap.spaceDetails[id]?['access'] == 'public') return stop('Bedrooms and shared washrooms are for residents, not public space.');
    }
    int? mm(String key) {
      final raw = a[key];
      if (raw is! num || !raw.isFinite || raw <= 0 || raw > 300) return null;
      final value = (raw * 1000).round();
      return value > 0 ? value : null;
    }
    final bw = mm('hostel_bed_width'), bl = mm('hostel_bed_length'), side = mm('hostel_bed_side');
    final cross = mm('hostel_cross_aisle'), lw = mm('hostel_locker_width'), ld = mm('hostel_locker_depth');
    final walk = mm('hostel_locker_aisle'), door = mm('cad_door');
    if (bw == null || bl == null || side == null || cross == null || lw == null || ld == null || walk == null || door == null) {
      return stop('Enter all measured bed, side clearance, aisle, locker and door dimensions.');
    }
    if (cross < door) return stop('The bedroom cross-aisle must be at least as wide as the measured door opening.');
    // Keep fixed measured room dimensions and the supplied setback, area,
    // window and adjacency constraints in the common enclosure solver.
    final measured = ProjectBrief(floorCount: brief.floorCount, parking: brief.parking, features: brief.features,
      taxonomy: sel, requirements: ProjectRequirementsSnapshot(version: snap.version,
        answers: {...a, 'cad_width_mode': 'exact'}, customSpaces: const {}, spaceDetails: {
          ...snap.spaceDetails, 'warden_room': {...warden, 'zone_edge': 'front'},
        }));
    HostelCadResult? fitted;
    var triedFixtures = false;
    final result = EnclosedCadGenerator().generate(measured, widthFt: widthFt, depthFt: depthFt, facing: facing,
      roomOrder: (id) => id == 'warden_room' ? -1 : id == 'toilets_baths' ? 0 : 1,
      roomTypeAcceptance: (plan, types) {
        triedFixtures = true;
        final zones = <MeasuredZone>[];
        for (final bedroom in plan.rooms.where((room) => types[room.id] == 'bedroom')) {
          final opening = plan.openings.singleWhere((o) => o.kind == PlanOpeningKind.door && o.to == bedroom.id);
          final frame = _BedroomFrame.fromDoor(bedroom.bounds, opening.bounds);
          if (frame == null) return false;
          final (start, end) = frame.along(opening.bounds);
          // Position the measured aisle so it spans the full doorway and
          // leaves a full bed/locker bank on both sides. The door swing lies
          // inside the cross-aisle and clear of all furniture.
          final bankCount = perRoom ~/ 2;
          final bankDepth = bl > bankCount * lw ? bl : bankCount * lw;
          final minStart = (end - cross).clamp(bankDepth, frame.depth).toInt();
          final maxStart = start < frame.depth - cross - bankDepth ? start : frame.depth - cross - bankDepth;
          if (minStart > maxStart || frame.width - ld - walk < door ||
              bankCount * (bw + side) + walk + ld > frame.width) return false;
          final y = minStart + (maxStart - minStart) ~/ 2;
          final lockerX = frame.width - ld, walkX = lockerX - walk;
          final prefix = bedroom.id;
          // The enclosure solver puts a bedroom window opposite its door.
          // Do not place lockers across that opening.
          for (final window in plan.openings.where((o) => o.kind == PlanOpeningKind.window && o.to == bedroom.id)) {
            final (first, last) = frame.along(window.bounds);
            final lockerRun = bankCount * lw;
            if ((first < y && last > y - lockerRun) ||
                (first < y + cross + lockerRun && last > y + cross)) return false;
          }
          zones.addAll([
            MeasuredZone('${prefix}_cross', 'Bedroom cross-aisle', frame.rect(0, y, frame.width, y + cross), 'HOSTEL_AISLES'),
            MeasuredZone('${prefix}_lock_walk_front', 'Locker retrieval aisle',
              frame.rect(walkX, y - bankDepth, lockerX, y), 'HOSTEL_AISLES'),
            MeasuredZone('${prefix}_lock_walk_rear', 'Locker retrieval aisle',
              frame.rect(walkX, y + cross, lockerX, y + cross + bankDepth), 'HOSTEL_AISLES'),
          ]);
          for (var i = 0; i < bankCount; i++) {
            final x = i * (bw + side);
            for (final (bank, bedY, lockerY) in [('front', y - bl, y - (i + 1) * lw), ('rear', y + cross, y + cross + i * lw)]) {
              final id = '${prefix}_${bank}_$i';
              zones.addAll([
                MeasuredZone('${id}_bed', 'Single bed', frame.rect(x, bedY, x + bw, bedY + bl), 'HOSTEL_BEDS'),
                MeasuredZone('${id}_side', 'Bedside clearance', frame.rect(x + bw, bedY, x + bw + side, bedY + bl), 'HOSTEL_BED_CLEAR'),
                MeasuredZone('${id}_locker', 'Individual locker', frame.rect(lockerX, lockerY, frame.width, lockerY + lw), 'HOSTEL_LOCKERS'),
              ]);
            }
          }
        }
        fitted = HostelCadResult(AutomaticFloorPlan(plot: plan.plot, footprint: plan.footprint, facing: plan.facing,
          sheetTitle: 'HOSTEL / SHARED ROOMS AND LOCKERS', rooms: plan.rooms, walls: plan.walls, openings: plan.openings),
          null, fixtures: List.unmodifiable(zones));
        return true;
      });
    return result.sheets.isNotEmpty && fitted != null ? fitted! : stop(triedFixtures
      ? 'The two bed banks, door-aligned aisle, lockers and their clearances cannot fit all measured bedrooms without blocking a window.'
      : result.issues.join(' '));
  }
}

/// Local X points from the corridor door toward the outside room wall;
/// local Y follows the span of that door. This works on either corridor bank.
class _BedroomFrame {
  const _BedroomFrame(this.bounds, this.horizontal, this.reverse);
  final PlanRect bounds;
  final bool horizontal, reverse;
  static _BedroomFrame? fromDoor(PlanRect room, PlanRect door) {
    if (door.right == room.left) return _BedroomFrame(room, true, false);
    if (door.left == room.right) return _BedroomFrame(room, true, true);
    if (door.top == room.bottom) return _BedroomFrame(room, false, false);
    if (door.bottom == room.top) return _BedroomFrame(room, false, true);
    return null;
  }
  int get width => horizontal ? bounds.width : bounds.depth;
  int get depth => horizontal ? bounds.depth : bounds.width;
  (int, int) along(PlanRect r) => horizontal ? (r.bottom - bounds.bottom, r.top - bounds.bottom)
      : (r.left - bounds.left, r.right - bounds.left);
  PlanRect rect(int x, int y, int right, int top) {
    final l = reverse ? width - right : x, r = reverse ? width - x : right;
    return horizontal ? PlanRect(bounds.left + l, bounds.bottom + y, bounds.left + r, bounds.bottom + top)
      : PlanRect(bounds.left + y, bounds.bottom + l, bounds.left + top, bounds.bottom + r);
  }
}
