import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/vehicle_lift_cad_screen.dart';
import 'package:architect_engine/services/vehicle_lift_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief workshop({Map<String, Object> edits = const {}, String type = 'vehicle_repair', String config = 'multiple_service_bays'}) => ProjectBrief(
  floorCount: 1, features: const [], parking: ProjectParking.none,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'industrial', subcategoryId: 'workshop',
    typeId: type, configurationId: config, plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'workshop_measured_lifts', 'service_bays': 2, 'clear_height': 4.6,
    'lv_bay_w': 4.8, 'lv_wall': .2, 'lv_car_w': 2.1, 'lv_car_l': 5.2, 'lv_car_h': 1.95, 'lv_front': 1.6, 'lv_rear': 1.4,
    'lv_door_w': 2.9, 'lv_door_h': 2.45, 'lv_door_head': .35, 'lv_inner': 2.7, 'lv_post_w': .35, 'lv_post_d': .4,
    'lv_post_h': 4, 'lv_rise': 1.8, 'lv_side': .3, 'lv_outside': .7, 'lv_overhead': .6, 'lv_apron': 4,
    'lv_west': 2.5, 'lv_south': 3, ...edits,
  }));

void main() {
  const widthFt = 18 / .3048, depthFt = 20 / .3048;
  VehicleLiftCadResult run(ProjectBrief b) => VehicleLiftCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('saved workshop repeats doors with unobstructed shell openings and static post footprints', () {
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('workshop_measured_lifts')));
    expect(cadOutputOptions(warehouseLoading: false, vehicleLift: true).options.map((o) => o.id), contains('workshop_measured_lifts'));
    final saved = ProjectBrief.fromMap(workshop().toMap())!;
    expect(VehicleLiftCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.bays, r.widthMm, r.depthMm, r.roofMm, r.overheadMm), (2, 10000, 8600, 3750, 600));
    final d = r.plan!;
    final openings = d.lines.where((l) => l.layer == 'LIFT_OPENING');
    expect(openings.map((l) => (l.start.x, l.start.y, l.end.x)), [(3650, 7100, 6550), (8450, 7100, 11350)]);
    for (final face in [7000, 7200]) {
      final walls = d.lines.where((l) => l.layer == 'LIFT_SHELL' && l.start.y == face && l.end.y == face).toList();
      expect(walls.length, 3);
      for (final opening in openings) {
        expect(walls.every((w) => w.end.x <= opening.start.x || w.start.x >= opening.end.x), isTrue);
      }
    }
    final post = d.lines.firstWhere((l) => l.layer == 'LIFT_POST');
    expect((post.start.x, post.start.y, post.end.x), (3400, 11200, 3750));
    expect(d.lines.where((l) => l.layer == 'LIFT_POST').length, 16);
    expect(d.toDxf(), contains('HALL 10.000 x 8.600 M'));
  });

  test('true-scale section uses the higher of roof and posts, not doorway height', () {
    final r = run(workshop(edits: {'left_setback': 2.5, 'right_setback': 5.5, 'front_setback': 3, 'rear_setback': 4.4}));
    expect(r.issue, isNull);
    final section = r.section!;
    final car = section.lines.where((l) => l.layer == 'LIFT_VEHICLE').toList();
    expect((car[0].start.x, car[0].start.y, car[0].end.x, car[1].end.y), (1350, 1800, 3450, 3750));
    final ceiling = section.lines.singleWhere((l) => l.layer == 'LIFT_HEAD');
    expect((ceiling.start.y, ceiling.end.y), (4600, 4600));
    expect(section.toDxf(), contains('GOVERNING OVERHEAD GAP 0.600 M'));
    final one = run(workshop(type: 'mechanical_workshop', config: 'single_service_bay',
      edits: {'service_bays': 1, 'lv_post_h': 3.5, 'lv_overhead': .85}));
    expect((one.issue, one.widthMm, one.overheadMm), (null, 5200, 850));
  });

  test('invalid door, lift, bay arrangement or setback withholds both drawings', () {
    for (final (brief, message) in [
      (workshop(type: 'carpentry'), 'supported workshop type'),
      (workshop(config: 'single_service_bay'), 'must agree'),
      (workshop(edits: {'service_bays': 2.5}), 'whole count'),
      (workshop(edits: {'lv_door_w': 2.699}), 'door opening'),
      (workshop(edits: {'lv_door_h': 2.299}), 'door opening'),
      (workshop(edits: {'lv_inner': 2.699}), 'between the lift posts'),
      (workshop(edits: {'lv_post_w': .351}), 'outside clearances'),
      (workshop(edits: {'lv_post_d': 5.201}), 'post depth'),
      (workshop(edits: {'lv_rise': 4}), 'below the depicted post tops'),
      (workshop(edits: {'clear_height': 4.599}), 'less than the supplied overhead margin'),
      (workshop(edits: {'lv_rise': 2.051}), 'less than the supplied overhead margin'),
      (workshop(edits: {'rear_setback': 4.401}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('preview switches sheets; overhead conflict prevents sharing both', (tester) async {
    await tester.pumpWidget(MaterialApp(home: VehicleLiftCadScreen(name: 'Workshop', brief: workshop(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('Governing overhead gap 0.600 m'), findsOneWidget);
    expect(find.text('Share workshop plan DXF'), findsOneWidget);
    await tester.tap(find.text('Transverse section'));
    await tester.pumpAndSettle();
    expect(find.text('Share lift section DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: VehicleLiftCadScreen(key: const ValueKey('invalid'), name: 'Workshop',
      brief: workshop(edits: {'lv_overhead': .601}), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('less than the supplied overhead margin'), findsOneWidget);
    expect(find.text('Share workshop plan DXF'), findsNothing);
    expect(find.text('Share lift section DXF'), findsNothing);
  });
}
