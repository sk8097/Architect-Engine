import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/services/enclosed_cad_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/screens/enclosed_cad_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief measured(String category, String subcategory, String type, {
  int floors = 1, ProjectParking? parking, Map<String, Object> overrides = const {},
  Map<String, Map<String, Object>>? rooms,
}) {
  final spaces = rooms ?? {'a': {'width': 5, 'length': 5, 'access': 'public'}, 'b': {'width': 4, 'length': 4, 'access': 'service'}};
  return ProjectBrief(floorCount: floors, parking: parking, features: const [],
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: category,
      subcategoryId: subcategory, typeId: type, plotShapeId: 'rectangular',
      spaceQuantities: {for (final id in spaces.keys) id: 1}),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion,
      answers: {'cad_output': 'building', 'cad_plate_width': 18, 'cad_plate_depth': 20, 'cad_offset_left': 3,
        'cad_offset_front': 4, 'cad_wall': .2, 'cad_corridor': 1.2, 'cad_door': .9, ...overrides},
      customSpaces: {for (final id in spaces.keys) if (!id.contains('_')) id: 'Room $id'}, spaceDetails: spaces));
}

void main() {
  final generator = EnclosedCadGenerator();
  run(ProjectBrief brief, [String facing = 'South']) => generator.generate(brief, widthFt: 100, depthFt: 140, facing: facing);

  test('measured building yields walls and connected doors, preserving the requested room sizes', () {
    final brief = measured('commercial', 'office', 'corporate_office');
    for (final entry in ['South','North','East','West']) {
      final result = run(brief, entry);
      expect(result.issues, isEmpty, reason: entry);
      final plan = result.sheets.single.plan;
      expect(plan.rooms.singleWhere((r) => r.label == 'Room a').bounds.area, 25000000);
      expect(plan.rooms.singleWhere((r) => r.label == 'Room b').bounds.area, 16000000);
      expect(plan.walls, isNotEmpty);
      expect(plan.openings.where((o) => o.kind == PlanOpeningKind.door), hasLength(3));
      expect(plan.openings.where((o) => o.from == AutomaticFloorPlan.entry), hasLength(1));
      expect(FloorPlanCad.fromPlan(plan).arcs, hasLength(3));
    }
  });

  test('measured enclosed uses in different categories reach actual geometry', () {
    for (final (c, g, t) in [
      ('industrial','logistics','general_warehouse'),
      ('institutional','education','primary_school'),
      ('rural','farm','dairy_farm'),
      ('mixed_use','mixed_development','mixed_use_development'),
      ('special','complex','long_span_building'),
      ('infrastructure','transport','parking_structure'),
    ]) {
      final result = run(measured(c,g,t));
      expect(result.issues, isEmpty, reason: '$c/$g/$t');
      expect(result.sheets.single.plan.walls, isNotEmpty);
    }
    final house = measured('residential','houses','independent_house', rooms: {
      'closed_kitchen': {'width': 3, 'length': 3}, 'shared_bathroom': {'width': 2, 'length': 3},
      'master_bedroom': {'width': 4, 'length': 4},
    }, overrides: {'bedrooms': 1});
    expect(run(house).sheets, hasLength(1));
  });

  test('measured facade window and mandatory room adjacency survive export', () {
    final brief = measured('commercial','office','corporate_office', rooms: {
      'a': {'width': 8, 'length': 5, 'cad_window': 1.4, 'zone_edge': 'front', 'adjacent_required': ['b']},
      'b': {'width': 6, 'length': 4},
    });
    final result = run(brief);
    expect(result.issues, isEmpty);
    final plan = result.sheets.single.plan;
    final window = plan.openings.singleWhere((o) => o.kind == PlanOpeningKind.window);
    expect(window.bounds.depth, 1400);
    final a = plan.rooms.singleWhere((r) => r.label == 'Room a').bounds;
    final b = plan.rooms.singleWhere((r) => r.label == 'Room b').bounds;
    expect(a.top + 200, b.bottom);
    expect(FloorPlanCad.fromPlan(plan).lines.any((line) => line.layer == 'WINDOWS'), isTrue);
  });

  test('unsupported requests and inconsistent geometry block rather than downgrade', () {
    expect(run(measured('commercial','office','corporate_office', floors: 2)).issues.single, contains('one floor'));
    expect(run(measured('commercial','office','corporate_office', parking: ProjectParking.car)).issues.single, contains('parking'));
    expect(run(measured('commercial','office','corporate_office', overrides: {'front_setback': 5})).issues.single, contains('setbacks'));
    final unfit = run(measured('commercial','office','corporate_office', rooms: {
      'a': {'width': 5, 'length': 5, 'cad_window': 1.4},
    }));
    expect(unfit.sheets, isEmpty);
    expect(unfit.issues.single, contains('exterior window'));
  });

  testWidgets('measured screen shows CAD only for a solvable request', (tester) async {
    Future<void> show(ProjectBrief brief) async {
      await tester.pumpWidget(MaterialApp(home: EnclosedCadScreen(key: ObjectKey(brief),
        name: 'Office project', brief: brief, widthFt: 100, depthFt: 140, facing: 'South')));
      await tester.pumpAndSettle();
    }
    await show(measured('commercial','office','corporate_office'));
    expect(find.text('Measured floor plan CAD'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsOneWidget);
    await show(measured('commercial','office','corporate_office', parking: ProjectParking.car));
    expect(find.text('No plan generated'), findsOneWidget);
    expect(find.textContaining('does not design parking'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsNothing);
  });

}
