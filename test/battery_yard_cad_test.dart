import 'package:architect_engine/data/battery_yard_cad_fields.dart';
import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/battery_yard_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/battery_yard_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief yard({Map<String, Object> edits = const {}, String type = 'battery_energy_storage', String config = 'outdoor_yard', int? floors}) =>
  ProjectBrief(floorCount: floors, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'energy',
      typeId: type, configurationId: config, actionId: 'site_development', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': batteryYardMode, 'by_pairs': 7, 'by_group': 3, 'by_w': 2.5, 'by_d': 6,
      'by_gap': 1.2, 'by_gap_min': 1.2, 'by_aisle': 5, 'by_aisle_min': 5,
      'by_cross': 3.5, 'by_cross_min': 3.5, 'by_rear': 2, 'by_rear_min': 2, 'by_end': 3, 'by_end_min': 3,
      'by_west': 2, 'by_south': 4, 'left_setback': 2, 'right_setback': 2, 'front_setback': 4, 'rear_setback': 3.7,
      ...edits,
    }));

void main() {
  const widthFt = 25 / .3048, depthFt = 43 / .3048;
  BatteryYardCadResult run(ProjectBrief b) => BatteryYardCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('option is opt-in for Battery Energy Storage, not transformer yards', () {
    expect(batteryYardCadEligible('infrastructure', 'energy', 'battery_energy_storage'), isTrue);
    expect(batteryYardCadEligible('infrastructure', 'energy', 'transformer_yard'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(batteryYardMode)));
    expect(cadOutputOptions(warehouseLoading: false, batteryYard: true).options.map((o) => o.id), containsAll([...ordinary, batteryYardMode]));
  });

  test('reopened plan and CSV share exact coordinates, with a shorter final group', () {
    final saved = ProjectBrief.fromMap(yard().toMap())!;
    expect(BatteryYardCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.groups, r.crossAisles, r.units.length), (21000, 35300, 3, 2, 14));
    final west = r.units.where((u) => u.row == 'west').toList();
    expect(west.map((u) => u.southMm), [7000, 10700, 14400, 20400, 24100, 27800, 33800]);
    expect(west.map((u) => u.group), [1, 1, 1, 2, 2, 2, 3]);
    final plan = r.drawing!;
    final outline = plan.lines.where((l) => l.layer == 'BY_UNIT').toList();
    expect(outline.length, 56);
    expect((outline[0].start.x, outline[0].start.y, outline[0].end.x), (4000, 7000, 10000));
    expect((outline[4].start.x, outline[4].start.y, outline[4].end.x), (15000, 7000, 21000));
    final lane = plan.lines.where((l) => l.layer == 'BY_LANE');
    expect(lane.map((l) => (l.start.x, l.start.y, l.end.y)), [(12500, 7000, 16900), (12500, 20400, 30300), (12500, 33800, 36300)]);
    final cross = plan.lines.where((l) => l.layer == 'BY_CROSS').toList();
    expect(cross.length, 10);
    expect((cross.first.start.x, cross.first.end.x, cross.first.start.y, cross[1].start.y), (2000, 4000, 16900, 20400));
    expect(plan.toDxf(), contains('14 UNITS / 3 GROUPS / 2 CROSS-AISLES / ENVELOPE 21.000 x 35.300 M'));
    expect(r.toCsv(), startsWith('unit_id,row,group,x_min_m,y_min_m,x_max_m,y_max_m,facing\r\nW001,west,1,4.000,7.000,10.000,9.500,east\r\n'));
    expect(r.toCsv(), endsWith('E007,east,3,15.000,33.800,21.000,36.300,west\r\n'));
  });

  test('no cross-aisle beyond the last group, and singleton groups have no normal gaps', () {
    final exact = run(yard(edits: {'by_pairs': 6}));
    expect((exact.issue, exact.groups, exact.crossAisles, exact.depthMm), (null, 2, 1, 29300));
    final singletons = run(yard(edits: {'by_pairs': 3, 'by_group': 1, 'by_gap': .5}));
    expect((singletons.issue, singletons.crossAisles, singletons.depthMm), (null, 2, 20500));
  });

  test('scope, width, gaps and plot conflicts suppress both exports', () {
    for (final (brief, reason) in [
      (yard(type: 'transformer_yard'), 'Select Battery Energy Storage'),
      (yard(config: 'enclosed_facility'), 'Use the Outdoor Yard'),
      (yard(floors: 1), 'Remove enclosed floors'),
      (yard(edits: {'by_pairs': 7.5}), 'whole unit counts'),
      (yard(edits: {'by_group': 7}), 'at least one cross-aisle'),
      (yard(edits: {'by_gap': 1.199}), 'within a group'),
      (yard(edits: {'by_aisle': 4.999}), 'central lane'),
      (yard(edits: {'by_cross_min': 3.501}), 'cross-aisle must meet'),
      (yard(edits: {'by_gap_min': 3.501, 'by_group': 1}), 'unit separation minimum'),
      (yard(edits: {'by_end': 2.999}), 'row-end reserve'),
      (yard(edits: {'right_setback': 2.001}), 'right plot edge'),
      (yard(edits: {'rear_setback': 3.701}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid drawing shows both export options', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BatteryYardCadScreen(name: 'Yard', brief: yard(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('14 units · 3 groups · 2 cross-aisles'), findsOneWidget);
    expect(find.text('Share yard plan DXF'), findsOneWidget);
    expect(find.text('Share unit schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved clearance conflict with no generic fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'yard', name: 'Yard conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: yard(edits: {'by_aisle_min': 5.001}));
    SharedPreferences.setMockInitialValues({'ae_projects_v1': [p.toJson()]});
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ], child: const MaterialApp(home: ProjectsScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Concept zoning CAD'), findsNothing);
    await tester.tap(find.text('Battery yard CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('central lane is below'), findsOneWidget);
    expect(find.text('Share yard plan DXF'), findsNothing);
    expect(find.text('Share unit schedule CSV'), findsNothing);
  });
}
