import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/inpatient_ward_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/inpatient_ward_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief ward({Map<String, Object> edits = const {}, Map<String, int> spaces = const {},
  String type = 'general_hospital', String config = 'inpatient', int floors = 1}) => ProjectBrief(
  floorCount: floors, parking: ProjectParking.none, features: const [], taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: 'institutional', subcategoryId: 'healthcare', typeId: type, configurationId: config,
    plotShapeId: 'rectangular', spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'inpatient_ward', 'cad_plate_width': 10.4, 'cad_plate_depth': 20, 'cad_wall': .2, 'cad_door': 1.4,
    'cad_offset_left': 3, 'cad_offset_front': 4, 'beds': 8,
    'iw_lobby_depth': 4.2, 'iw_central': 2.4, 'iw_end_clear': 1.6,
    'iw_bed_width': 1.1, 'iw_bed_length': 2.2, 'iw_bed_side': .8, 'iw_bed_foot': 1.15,
    'iw_counter_length': 2.4, 'iw_counter_depth': .65, 'iw_counter_work': 1, ...edits,
  }));

void main() {
  InpatientWardResult run(ProjectBrief brief, [String facing = 'South']) =>
    InpatientWardCadGenerator().generate(brief, widthFt: 80, depthFt: 110, facing: facing);
  bool touches(PlanRect a, PlanRect b) =>
    ((a.left == b.right || a.right == b.left) && a.bottom < b.top && b.bottom < a.top) ||
    ((a.bottom == b.top || a.top == b.bottom) && a.left < b.right && b.left < a.right);

  test('ward mode opts in and produces the measured layout after brief round-trip for every frontage', () {
    expect(cadOutputOptions(warehouseLoading: false, inpatientWard: true).options.map((o) => o.id), contains('inpatient_ward'));
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('inpatient_ward')));
    final brief = ProjectBrief.fromMap(ward().toMap())!;
    expect(InpatientWardCadGenerator.requested(brief), isTrue);
    for (final facing in ['South', 'East', 'North', 'West']) {
      final result = run(brief, facing);
      expect(result.issue, isNull, reason: '$facing: ${result.issue}');
      final plan = result.plan!, rooms = {for (final r in result.plan!.rooms) r.id: r.bounds};
      expect(validatePlanGeometry(plan), isNull);
      final zones = {for (final z in result.zones) z.id: z.bounds};
      final chain = [zones['iw_approach']!, plan.openings.first.bounds, zones['iw_lobby_aisle']!, plan.openings[1].bounds,
        zones['iw_front_pad']!, zones['iw_main_aisle']!, zones['iw_rear_pad']!];
      for (var i = 1; i < chain.length; i++) { expect(touches(chain[i - 1], chain[i]), isTrue); }
      final rotated = facing == 'East' || facing == 'West';
      expect(rotated ? chain[5].depth : chain[5].width, 2400);
      expect(rotated ? chain[4].width : chain[4].depth, greaterThanOrEqualTo(1600));
      final washDoor = plan.openings.last;
      expect((washDoor.from, washDoor.to), ('ward_lobby', 'ward_wash'));
      expect(touches(washDoor.bounds, chain[2]), isTrue);
      final desk = zones['iw_nursing_counter']!, work = zones['iw_nursing_work']!, access = zones['iw_nursing_return']!;
      expect(touches(desk, chain[2]) && touches(work, access) && touches(access, chain[2]), isTrue);
      expect(rooms['ward_lobby']!.contains(work), isTrue);
      final beds = result.zones.where((z) => z.layer == 'WARD_BEDS').toList();
      expect(beds.length, 8);
      for (final b in beds) {
        final prefix = b.id.substring(0, b.id.length - '_bed'.length);
        final f = zones['${prefix}_foot']!, a = zones['${prefix}_side_a']!, s = zones['${prefix}_side_b']!;
        expect(b.bounds.area, 2420000);
        expect(a.area, 1760000);
        expect(f.area, 3105000);
        expect(touches(b.bounds, a) && touches(b.bounds, s) && touches(b.bounds, f), isTrue);
        expect(touches(f, chain[5]) && touches(f, a) && touches(f, s), isTrue);
        expect(rooms['ward_room']!.contains(f), isTrue);
      }
      final all = result.zones;
      for (var i = 0; i < all.length; i++) {
        expect(plan.plot.contains(all[i].bounds), isTrue);
        for (var j = 0; j < i; j++) { expect(all[i].bounds.overlaps(all[j].bounds), isFalse); }
      }
      final dxf = FloorPlanCad.fromPlan(plan, siteZones: result.zones).toDxf();
      for (final layer in ['WARD_BEDS', 'WARD_CLEAR', 'WARD_ROUTE', 'WARD_COUNTER']) { expect(dxf, contains(layer)); }
    }
  });

  test('unsupported clinical scope, odd capacities, short circulation and poor fit block export', () {
    for (final (brief, issue) in [
      (ward(type: 'day_care_centre'), 'Select Hospital'),
      (ward(config: 'mixed_care'), 'one ground-floor inpatient ward'),
      (ward(floors: 2), 'one ground-floor inpatient ward'),
      (ward(edits: {'consult_rooms': 1}), 'Remove other Space selections'),
      (ward(spaces: {'icu': 1}), 'Remove other Space selections'),
      (ward(edits: {'beds': 7}), 'even ward bed count'),
      (ward(edits: {'beds': 10}), 'end pads require'),
      (ward(edits: {'iw_central': 1.2}), 'must span the door'),
      (ward(edits: {'iw_bed_foot': 1.7}), 'both bed banks require'),
      (ward(edits: {'iw_counter_length': 3.5}), 'working pocket do not fit'),
      (ward(edits: {'left_setback': 4}), 'left setback'),
    ]) {
      final result = run(brief);
      expect(result.issue?.toLowerCase(), contains(issue.toLowerCase()), reason: issue);
      expect(result.plan, isNull);
      expect(result.zones, isEmpty);
    }
  });

  testWidgets('ward preview only offers DXF when the requested beds fit', (tester) async {
    await tester.pumpWidget(MaterialApp(home: InpatientWardCadScreen(name: 'General ward', brief: ward(), widthFt: 80, depthFt: 110, facing: 'North')));
    expect(find.text('General inpatient ward CAD'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: InpatientWardCadScreen(key: const ValueKey('blocked'), name: 'General ward',
      brief: ward(edits: {'beds': 10}), widthFt: 80, depthFt: 110, facing: 'North')));
    expect(find.textContaining('end pads require'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsNothing);
  });
}
