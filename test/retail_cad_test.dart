import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/retail_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/retail_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief retail({Map<String,Object> overrides = const {}, String type = 'shop'}) => ProjectBrief(
  floorCount: 1, parking: ProjectParking.none, features: const [],
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'commercial',
    subcategoryId: 'retail', typeId: type, plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'retail_fixtures', 'shop_count': 1, 'cad_plate_width': 12, 'cad_plate_depth': 20,
    'cad_offset_left': 3, 'cad_offset_front': 3, 'cad_wall': .2, 'rt_public_door': 1,
    'rt_stock_door': 1.1, 'rt_stock_depth': 4, 'rt_fixture_count': 3, 'rt_fixture_width': 1,
    'rt_fixture_depth': 7, 'rt_aisle': 1.3, 'rt_checkout_width': 2.5, 'rt_checkout_depth': .9,
    'rt_queue_depth': 2, ...overrides,
  }),
);

void main() {
  final generator = RetailCadGenerator();
  RetailCadResult run(ProjectBrief input, [String side = 'South']) =>
    generator.generate(input, widthFt: 80, depthFt: 100, facing: side);

  test('preserves exact display footprints and clear aisle network in every orientation', () {
    for (final side in ['South','North','East','West']) {
      final result = run(retail(), side);
      expect(result.issue, isNull, reason: side);
      final plan = result.plan!;
      expect(validatePlanPartition(plan), isNull);
      final fixtures = result.zones.where((z) => z.layer == 'RETAIL_DISPLAY');
      final aisleRows = result.zones.where((z) => z.id.startsWith('aisle_'));
      final publicRoutes = result.zones.where((z) => z.layer == 'CUSTOMER_ROUTE');
      final queue = result.zones.singleWhere((z) => z.id == 'queue');
      expect(fixtures, hasLength(3));
      expect(fixtures.every((z) => z.bounds.area == 1000 * 7000), isTrue);
      expect(aisleRows, hasLength(4));
      expect(aisleRows.every((z) => z.bounds.area == 1300 * 7000), isTrue);
      expect(publicRoutes.every((r) => !r.bounds.overlaps(queue.bounds) && fixtures.every((z) => !z.bounds.overlaps(r.bounds))), isTrue);
      expect(plan.openings, hasLength(2));
      expect(plan.openings.singleWhere((o) => o.to == 'retail_stock').from, 'retail_sales');
      final drawing = FloorPlanCad.fromPlan(plan, siteZones: result.zones);
      expect(drawing.arcs, hasLength(2));
      for (final layer in ['RETAIL_DISPLAY','RETAIL_QUEUE','RETAIL_CHECKOUT','CUSTOMER_ROUTE','RETAIL_SERVICE']) {
        expect(drawing.toDxf(), contains(layer));
      }
    }
  });

  test('rear stock access is optional and cannot extend past the plot', () {
    final accepted = run(retail(overrides: {'rt_rear_access': 2}));
    expect(accepted.issue, isNull);
    expect(accepted.plan!.openings.where((o) => o.from == AutomaticFloorPlan.entry), hasLength(2));
    final approach = accepted.zones.singleWhere((z) => z.id == 'staff_approach');
    expect(approach.bounds.depth, 2000);
    expect(approach.bounds.bottom, accepted.plan!.footprint.top);
    expect(run(retail(overrides: {'rt_rear_access': 16})).issue, contains('beyond the measured plot'));
  });

  test('rows, checkout, queue and unsupported forms fail with individual blockers', () {
    expect(run(retail(overrides: {'rt_fixture_count': 7})).issue, contains('clear sales width'));
    expect(run(retail(overrides: {'rt_checkout_width': 11})).issue, contains('no clear connection'));
    expect(run(retail(overrides: {'rt_queue_depth': 8})).issue, contains('too shallow'));
    expect(run(retail(overrides: {'sales_area': 400})).issue, contains('below the requested area'));
    expect(run(retail(overrides: {'shop_count': 2})).issue, contains('one standalone'));
    expect(run(retail(type: 'shopping_mall')).issue, contains('not a mall'));
  });

  testWidgets('retail preview displays DXF only for a layout that fits', (tester) async {
    Future<void> show(ProjectBrief brief) async {
      await tester.pumpWidget(MaterialApp(home: RetailCadScreen(key: ObjectKey(brief),
        name: 'Shop test', brief: brief, widthFt: 80, depthFt: 100, facing: 'South')));
      await tester.pumpAndSettle();
    }
    await show(retail());
    expect(find.text('Retail fixture CAD'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsOneWidget);
    await show(retail(overrides: {'rt_fixture_count': 7}));
    expect(find.textContaining('clear sales width'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsNothing);
  });
}
