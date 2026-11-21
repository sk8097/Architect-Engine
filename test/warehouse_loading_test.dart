import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/warehouse_loading_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/warehouse_loading_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief warehouse({String type = 'general_warehouse', Map<String, Object> values = const {}}) => ProjectBrief(
  floorCount: 1, parking: ProjectParking.none, features: const [],
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'industrial',
    subcategoryId: 'logistics', typeId: type, plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'warehouse_loading', 'wh_width': 35, 'wh_depth': 35, 'wh_wall': .2,
    'wh_access_depth': 6, 'wh_drive_width': 7, 'wh_bay_width': 3.5, 'wh_bay_depth': 12,
    'wh_dock_opening': 3, 'wh_staging_depth': 7, 'wh_staff_width': 1.8, 'wh_staff_door': 1.1,
    'wh_apron_width': 25, 'wh_apron_depth': 18, 'wh_vehicle_basis': 'User-supplied vehicle study',
    'dock_count': 4, 'front_setback': 4, 'left_setback': 3, 'right_setback': 3, 'rear_setback': 5,
    ...values,
  }),
);

void main() {
  final generator = WarehouseLoadingGenerator();
  WarehouseLoadingResult run(ProjectBrief input, {String side = 'South', double width = 180, double depth = 300}) =>
    generator.generate(input, widthFt: width, depthFt: depth, facing: side);

  test('staging, storage and linked dock openings preserve dimensions without intersecting staff access', () {
    for (final side in ['South', 'North', 'East', 'West']) {
      final result = run(warehouse(), side: side);
      expect(result.issue, isNull, reason: side);
      final plan = result.plan!;
      expect(validatePlanPartition(plan), isNull, reason: side);
      final staffPath = result.zones.singleWhere((z) => z.id == 'staff').bounds;
      for (final zone in result.zones.where((z) => z.layer == 'VEHICLE_ROUTE' || z.layer == 'DOCK_BAYS')) {
        expect(staffPath.overlaps(zone.bounds), isFalse, reason: '${zone.id} $side');
        expect(plan.plot.contains(zone.bounds), isTrue);
        if (zone.id.startsWith('bay_')) {
          expect(zone.bounds.area, 3500 * 12000);
        }
      }
      expect(plan.openings.where((o) => o.kind == PlanOpeningKind.loadingDoor), hasLength(4));
      expect(plan.openings.where((o) => o.kind == PlanOpeningKind.door), hasLength(1));
      expect(result.zones.where((z) => z.layer == 'DOCK_BAYS'), hasLength(4));
      final drawing = FloorPlanCad.fromPlan(plan, siteZones: result.zones);
      expect(drawing.arcs, hasLength(1)); // loading doors are not swing doors
      for (final layer in ['VEHICLE_ROUTE','WALK_ROUTE','DOCK_BAYS','DOCK_OPENINGS','WAREHOUSE_MARKINGS']) {
        expect(drawing.lines.where((line) => line.layer == layer), isNotEmpty);
      }
      expect(drawing.toDxf(), contains('VEHICLE MANOEUVRING RESERVE'));
    }
  });

  test('site, apron, dock frontage and unsupported cross-dock requirements block export', () {
    expect(run(warehouse(), depth: 150).issue, contains('exceed the measured envelope'));
    expect(run(warehouse(values: {'wh_apron_width': 36})).issue, contains('wider than the loading yard'));
    expect(run(warehouse(values: {'dock_count': 20})).issue, contains('Dock bays'));
    expect(run(warehouse(values: {'dock_type': ['cross']})).issue, contains('Cross-dock'));
    expect(run(warehouse(type: 'cross_dock')).issue, contains('single-sided'));
    expect(run(warehouse(values: {'wh_vehicle_basis': '  '})).issue, contains('source'));
  });

  testWidgets('warehouse preview exposes export only for a valid specialised drawing', (tester) async {
    Future<void> show(double depth) async {
      await tester.pumpWidget(MaterialApp(home: WarehouseLoadingScreen(key: ValueKey(depth),
        name: 'Warehouse project', brief: warehouse(), widthFt: 180, depthFt: depth, facing: 'South')));
      await tester.pumpAndSettle();
    }
    await show(300);
    expect(find.text('Warehouse loading CAD'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsOneWidget);
    await show(150);
    expect(find.textContaining('exceed the measured envelope'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsNothing);
  });
}
