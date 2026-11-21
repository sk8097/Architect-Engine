import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/greenhouse_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/greenhouse_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief greenhouse({Map<String, Object> edits = const {}, Map<String, int> spaces = const {},
  String type = 'greenhouse_farm', String config = 'production_site'}) => ProjectBrief(
  floorCount: 1, parking: ProjectParking.none, features: const [], taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: 'rural', subcategoryId: 'farm', typeId: type, configurationId: config, plotShapeId: 'rectangular', spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'greenhouse_benches', 'cad_plate_width': 12.8, 'cad_plate_depth': 20,
    'cad_offset_left': 3, 'cad_offset_front': 4, 'cad_wall': .15, 'cad_door': 1.2,
    'gh_pair_rows': 3, 'gh_bench_width': 1.2, 'gh_bench_length': 7.5, 'gh_bench_aisle': .6,
    'gh_main_aisle': 1.6, 'gh_cross_aisle': 1.4, 'gh_front_clear': 1.5, 'gh_rear_clear': 1.2,
    'gh_irrigation': 'layout_only', ...edits,
  }));

void main() {
  GreenhouseCadResult run(ProjectBrief brief, [String facing = 'South']) =>
    GreenhouseCadGenerator().generate(brief, widthFt: 85, depthFt: 105, facing: facing);
  bool touches(PlanRect a, PlanRect b) =>
    ((a.left == b.right || a.right == b.left) && a.bottom < b.top && b.bottom < a.top) ||
    ((a.bottom == b.top || a.top == b.bottom) && a.left < b.right && b.left < a.right);

  test('reopened brief fits two bench banks, routes and a connected schematic on all frontages', () {
    final brief = ProjectBrief.fromMap(greenhouse().toMap())!;
    expect(GreenhouseCadGenerator.requested(brief), isTrue);
    for (final facing in ['South', 'East', 'North', 'West']) {
      final result = run(brief, facing);
      expect(result.issue, isNull, reason: '$facing: ${result.issue}');
      final plan = result.plan!, rotated = facing == 'East' || facing == 'West';
      expect(validatePlanGeometry(plan), isNull);
      expect(result.benchAreaMm2, 108000000);
      final door = plan.openings.single.bounds, bay = plan.rooms.single.bounds;
      final zones = {for (final zone in result.zones) zone.id: zone.bounds};
      final entry = zones['gh_entry']!, front = zones['gh_front']!, middle = zones['gh_middle']!, rear = zones['gh_rear']!;
      expect(touches(entry, door) && touches(door, front), isTrue);
      expect(plan.plot.contains(entry) && !entry.overlaps(plan.footprint), isTrue);
      expect(rotated ? entry.depth : entry.width, 1600);
      expect(rotated ? middle.width : middle.depth, 1400);
      expect(rotated ? front.width : front.depth, greaterThanOrEqualTo(1500));
      expect(rotated ? rear.width : rear.depth, greaterThanOrEqualTo(1200));
      final interior = result.zones.where((z) => z.id != 'gh_entry').toList();
      // No accidental loss of working space to a bench or another zone.
      expect(interior.fold<int>(0, (sum, z) => sum + z.bounds.area), bay.area);
      for (var i = 0; i < interior.length; i++) {
        expect(bay.contains(interior[i].bounds), isTrue);
        for (var j = 0; j < i; j++) { expect(interior[i].bounds.overlaps(interior[j].bounds), isFalse); }
      }
      final fixtures = result.zones.where((z) => z.layer == 'GREENHOUSE_BENCHES');
      expect(fixtures.length, 12);
      for (final z in interior.where((z) => z.layer == 'GREENHOUSE_AISLES' || z.layer == 'GREENHOUSE_BENCHES')) {
        expect(touches(z.bounds, middle) && touches(z.bounds, z.id.contains('_front_') ? front : rear), isTrue);
        if (z.layer == 'GREENHOUSE_BENCHES') {
          expect(rotated ? z.bounds.depth : z.bounds.width, 1200);
          expect(rotated ? z.bounds.width : z.bounds.depth, 7500);
          expect(touches(z.bounds, zones[z.id.replaceFirst('_bench', '_aisle')]!), isTrue);
        } else if (z.id.endsWith('_main')) {
          expect(rotated ? z.bounds.depth : z.bounds.width, 1600);
        } else {
          expect(rotated ? z.bounds.depth : z.bounds.width, greaterThanOrEqualTo(600));
        }
      }
      final header = plan.markings.where((m) => m.layer == 'GREENHOUSE_IRR_HEADER').toList();
      final laterals = plan.markings.where((m) => m.layer == 'GREENHOUSE_IRR_LATERALS').toList();
      expect(header.length, 7);
      expect(laterals.length, 12);
      final nodes = <(int, int), Set<(int, int)>>{};
      for (final line in plan.markings) {
        final p = (line.fromX, line.fromY), q = (line.toX, line.toY);
        nodes.putIfAbsent(p, () => {}).add(q);
        nodes.putIfAbsent(q, () => {}).add(p);
      }
      final queue = [(header.first.fromX, header.first.fromY)], visited = <(int, int)>{};
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        if (visited.add(current)) queue.addAll(nodes[current]!);
      }
      expect(visited, unorderedEquals(nodes.keys));
      for (final fixture in fixtures) {
        final b = fixture.bounds;
        expect(laterals.where((m) => b.contains(PlanRect(m.fromX, m.fromY, m.fromX, m.fromY)) ||
          b.contains(PlanRect(m.toX, m.toY, m.toX, m.toY))).length, 1);
      }
      final drawing = FloorPlanCad.fromPlan(plan, siteZones: result.zones);
      expect(drawing.lines.where((l) => l.layer == 'GREENHOUSE_IRR_HEADER').length, 7);
      final dxf = drawing.toDxf();
      for (final layer in ['GREENHOUSE_AISLES', 'GREENHOUSE_BENCHES', 'GREENHOUSE_HEADLAND', 'GREENHOUSE_APPROACH',
        'GREENHOUSE_IRR_HEADER', 'GREENHOUSE_IRR_LATERALS']) { expect(dxf, contains(layer)); }
    }
  });

  test('exact clear width fits and optional irrigation can be omitted', () {
    final result = run(greenhouse(edits: {'gh_irrigation': 'none', 'cad_plate_width': 12.7}));
    expect(result.issue, isNull);
    expect(result.plan!.markings, isEmpty);
    final lines = FloorPlanCad.fromPlan(result.plan!, siteZones: result.zones).lines;
    expect(lines.where((l) => l.layer.startsWith('GREENHOUSE_IRR')), isEmpty);
    expect(cadOutputOptions(warehouseLoading: false, greenhouse: true).options.map((o) => o.id), contains('greenhouse_benches'));
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('greenhouse_benches')));
  });

  test('unfittable bench banks, access, placement and unsupported programs block the whole output', () {
    for (final (brief, issue) in [
      (greenhouse(type: 'farm_estate'), 'Select Greenhouse Farm'),
      (greenhouse(config: 'residence_plus_production'), 'one ground-floor production greenhouse'),
      (greenhouse(spaces: {'tool_store': 1}), 'Leave separate Space selections empty'),
      (greenhouse(edits: {'gh_pair_rows': 4}), '16.000 m clear width'),
      (greenhouse(edits: {'cad_plate_depth': 19.3}), '19.100 m clear depth'),
      (greenhouse(edits: {'gh_main_aisle': 1.1}), 'Align the door within the centre aisle'),
      (greenhouse(edits: {'cad_offset_front': 0}), 'clear approach'),
      (greenhouse(edits: {'front_setback': 5}), 'front setback'),
      (greenhouse(edits: {'coverage_limit': 20}), 'site coverage'),
    ]) {
      final result = run(brief);
      expect(result.issue, contains(issue), reason: issue);
      expect(result.plan, isNull);
      expect(result.zones, isEmpty);
    }
  });

  testWidgets('preview offers editable DXF only when measured growing layout fits', (tester) async {
    await tester.pumpWidget(MaterialApp(home: GreenhouseCadScreen(name: 'Bench trial', brief: greenhouse(),
      widthFt: 85, depthFt: 105, facing: 'North')));
    expect(find.text('Greenhouse bench CAD'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: GreenhouseCadScreen(key: const ValueKey('blocked'), name: 'Bench trial',
      brief: greenhouse(edits: {'gh_pair_rows': 4}), widthFt: 85, depthFt: 105, facing: 'North')));
    expect(find.textContaining('Both bench banks'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsNothing);
  });
}
