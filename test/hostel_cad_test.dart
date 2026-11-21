import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/hostel_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/hostel_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/hostel_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief hostel({Map<String, Object> edits = const {}, Map<String, Map<String, Object>> details = const {},
  Map<String, int> rooms = const {}, int floors = 1, int beds = 4, String config = 'shared_rooms'}) => ProjectBrief(
  floorCount: floors, parking: ProjectParking.none, features: const [], taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: 'residential', subcategoryId: 'hostels', typeId: 'student_hostel', configurationId: config,
    plotShapeId: 'rectangular', spaceQuantities: {'bedroom': 2, 'warden_room': 1, 'toilets_baths': 1, ...rooms}),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'hostel_shared_rooms', 'cad_plate_width': 13.6, 'cad_plate_depth': 14,
    'cad_offset_front': 3, 'cad_offset_left': 2, 'cad_wall': .2, 'cad_corridor': 1.8, 'cad_door': 1,
    'room_count': 2, 'resident_capacity': 2 * beds, 'beds_per_room': beds,
    'hostel_bed_width': .9, 'hostel_bed_length': 2, 'hostel_bed_side': .6, 'hostel_cross_aisle': 1.4,
    'hostel_locker_width': .45, 'hostel_locker_depth': .55, 'hostel_locker_aisle': 1.1, ...edits,
  }, spaceDetails: {
    'bedroom': {'width': 5.5, 'length': 6.4, 'cad_window': 1.2},
    'warden_room': {'width': 3, 'length': 3.2}, 'toilets_baths': {'width': 4, 'length': 4}, ...details,
  }));

void main() {
  HostelCadResult run(ProjectBrief brief, [String facing = 'South']) =>
    HostelCadGenerator().generate(brief, widthFt: 90, depthFt: 110, facing: facing);
  bool touches(PlanRect a, PlanRect b) =>
    ((a.left == b.right || a.right == b.left) && a.bottom < b.top && b.bottom < a.top) ||
    ((a.bottom == b.top || a.top == b.bottom) && a.left < b.right && b.left < a.right);

  test('only supported hostel types are eligible and the selector registers the template', () {
    expect(hostelCadEligible('residential', 'hostels', 'student_hostel'), isTrue);
    expect(hostelCadEligible('residential', 'staff_quarters', 'dormitory'), isFalse);
    expect(hostelCadEligible('commercial', 'hospitality', 'hostel'), isFalse);
    expect(cadOutputOptions(warehouseLoading: false, hostel: true).options.map((option) => option.id), contains('hostel_shared_rooms'));
    expect(cadOutputOptions(warehouseLoading: false).options.map((option) => option.id), isNot(contains('hostel_shared_rooms')));
  });

  test('reopened brief fits door-connected bed and locker banks on all frontages', () {
    final brief = ProjectBrief.fromMap(hostel().toMap())!;
    expect(HostelCadGenerator.requested(brief), isTrue);
    for (final facing in ['South', 'North', 'East', 'West']) {
      final result = run(brief, facing);
      expect(result.issue, isNull, reason: '$facing: ${result.issue}');
      final plan = result.plan!;
      final reserves = plan.rooms.where((r) => r.id.startsWith('reserve_')).map((r) => r.id).toSet();
      expect(validatePlanGeometry(plan, sealedRooms: reserves), isNull);
      final warden = plan.rooms.singleWhere((r) => r.label == 'Warden Room').bounds;
      expect(switch (facing) {
        'North' => plan.footprint.top - warden.top,
        'East' => plan.footprint.right - warden.right,
        'West' => warden.left - plan.footprint.left,
        _ => warden.bottom - plan.footprint.bottom,
      }, 200);
      final baths = plan.rooms.singleWhere((r) => r.label == 'Toilets/Baths');
      expect(plan.openings.singleWhere((o) => o.kind == PlanOpeningKind.door && o.to == baths.id).from, 'internal_passage');
      final bedrooms = plan.rooms.where((r) => r.label.startsWith('Bedroom')).toList();
      expect(bedrooms.length, 2);
      for (final room in bedrooms) {
        final opening = plan.openings.singleWhere((o) => o.kind == PlanOpeningKind.door && o.to == room.id);
        expect(opening.from, 'internal_passage');
        final window = plan.openings.singleWhere((o) => o.kind == PlanOpeningKind.window && o.to == room.id);
        final zones = result.fixtures.where((z) => z.id.startsWith('${room.id}_')).toList();
        final cross = zones.singleWhere((z) => z.id.endsWith('_cross')).bounds;
        expect(touches(cross, opening.bounds) && touches(cross, window.bounds), isTrue);
        final rotated = facing == 'East' || facing == 'West';
        expect(rotated ? cross.width : cross.depth, 1400);
        expect(rotated ? cross.depth : cross.width, 5500);
        final retrieval = zones.where((z) => z.id.contains('_lock_walk_')).toList();
        expect(retrieval.length, 2);
        for (final z in retrieval) { expect(touches(z.bounds, cross), isTrue); }
        for (final (layer, area) in [('HOSTEL_BEDS', 1800000), ('HOSTEL_LOCKERS', 247500), ('HOSTEL_BED_CLEAR', 1200000)]) {
          final matching = zones.where((z) => z.layer == layer).toList();
          expect(matching.length, 4);
          for (final z in matching) {
            expect(z.bounds.area, area);
            expect(layer == 'HOSTEL_LOCKERS' ? retrieval.any((aisle) => touches(aisle.bounds, z.bounds)) : touches(cross, z.bounds), isTrue);
            if (layer == 'HOSTEL_LOCKERS') expect(touches(z.bounds, window.bounds), isFalse);
          }
        }
        for (var i = 0; i < zones.length; i++) {
          expect(room.bounds.contains(zones[i].bounds), isTrue);
          for (var j = 0; j < i; j++) { expect(zones[i].bounds.overlaps(zones[j].bounds), isFalse); }
        }
      }
      final dxf = FloorPlanCad.fromPlan(plan, siteZones: result.fixtures).toDxf();
      for (final layer in ['HOSTEL_BEDS', 'HOSTEL_LOCKERS', 'HOSTEL_BED_CLEAR', 'HOSTEL_AISLES']) {
        expect(dxf, contains(layer));
      }
    }
  });

  test('invalid counts, blocked clearance or unsupported cases never export', () {
    for (final (brief, issue) in [
      (hostel(beds: 3), '2, 4, 6 or 8'),
      (hostel(edits: {'resident_capacity': 7}), 'must match'),
      (hostel(rooms: {'accessible_room': 1}), 'Other room types'),
      (hostel(config: 'mixed_rooms'), 'Choose Shared Rooms'),
      (hostel(floors: 2), 'exactly one floor'),
      (hostel(edits: {'hostel_cross_aisle': .9}), 'at least as wide'),
      (hostel(edits: {'hostel_bed_length': 3}), 'cannot fit'),
      (hostel(beds: 8), 'cannot fit'),
      (hostel(details: {'bedroom': {'width': 5.5, 'length': 6.4, 'cad_window': 1.8}}), 'without blocking a window'),
      (hostel(details: {'warden_room': {'width': 3, 'length': 3.2, 'zone_edge': 'rear'}}), 'at the front'),
    ]) {
      final result = run(brief);
      expect(result.issue, contains(issue), reason: issue);
      expect(result.plan, isNull);
      expect(result.fixtures, isEmpty);
    }
  });

  testWidgets('hostel CAD offers export only when furnishings and clearances fit', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HostelCadScreen(name: 'Hostel brief', brief: hostel(),
      widthFt: 90, depthFt: 110, facing: 'West')));
    expect(find.text('Shared-room hostel CAD'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: HostelCadScreen(key: const ValueKey('blocked'), name: 'Hostel brief',
      brief: hostel(edits: {'hostel_bed_length': 3}), widthFt: 90, depthFt: 110, facing: 'West')));
    expect(find.textContaining('cannot fit all measured bedrooms'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsNothing);
  });
}
