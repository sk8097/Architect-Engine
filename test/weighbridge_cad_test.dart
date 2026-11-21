import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/weighbridge_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/weighbridge_cad_screen.dart';
import 'package:architect_engine/services/weighbridge_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief bridge({Map<String, Object> edits = const {}, String type = 'freight_terminal'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'transport',
    typeId: type, configurationId: 'terminal_depot', actionId: 'concept_design', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': weighbridgeMode, 'wb_plate_l': 18, 'wb_plate_w': 3, 'wb_approach_s': 6, 'wb_approach_n': 5,
    'wb_lane': 5, 'wb_split': 1, 'wb_bypass': 3.5, 'wb_axle_edge': .8, 'wb_side_clear': .3,
    'wb_body': 2.6, 'wb_tyre': 2.4, 'wb_wheelbase': 6, 'wb_tandem': 1.4, 'wb_front_oh': 1.5, 'wb_rear_oh': 2,
    'wb_west': 2, 'wb_south': 3, 'left_setback': 2, 'right_setback': 4, 'front_setback': 3, 'rear_setback': 4, ...edits,
  }));

void main() {
  const widthFt = 15.5 / .3048, depthFt = 36 / .3048;
  WeighbridgeCadResult run(ProjectBrief b) => WeighbridgeCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('freight-terminal opt-in does not apply to bus terminals or ordinary outputs', () {
    expect(weighbridgeCadEligible('infrastructure', 'transport', 'freight_terminal'), isTrue);
    expect(weighbridgeCadEligible('infrastructure', 'transport', 'bus_terminal'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(weighbridgeMode)));
    expect(cadOutputOptions(warehouseLoading: false, weighbridge: true).options.map((o) => o.id), containsAll([...ordinary, weighbridgeMode]));
  });

  test('saved plan and CSV agree on axle positions and keep bypass separate', () {
    final saved = ProjectBrief.fromMap(bridge().toMap())!;
    expect(WeighbridgeCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.fromMm, r.toMm, r.stopMm), (9500, 29000, 6800, 15800, 11300));
    final plan = r.drawing!;
    final axles = plan.lines.where((l) => l.layer == 'WB_AXLE').toList();
    expect(axles.map((l) => (l.start.x, l.end.x, l.start.y)), [(3300, 5700, 14300), (3300, 5700, 15700), (3300, 5700, 21700)]);
    final bypass = plan.lines.firstWhere((l) => l.layer == 'WB_BYPASS');
    expect((bypass.start.x, bypass.end.x, bypass.start.y), (8000, 11500, 3000));
    final body = plan.lines.where((l) => l.layer == 'WB_BODY').toList();
    expect((body.first.start.x, body.first.start.y, body[2].start.y), (3200, 12300, 23200));
    expect(plan.toDxf(), contains('REARMOST AXLE CH 6.800 TO 15.800 M / ENVELOPE 9.500 x 29.000 M'));
    expect(r.toCsv(), endsWith('rearmost,6.8000,11.3000,15.8000\r\nforward_rear,8.2000,12.7000,17.2000\r\nfront,14.2000,18.7000,23.2000\r\n'));
  });

  test('body limits can narrow both ends and permit one exact stop', () {
    final narrowed = run(bridge(edits: {'wb_front_oh': 8, 'wb_rear_oh': 8}));
    expect((narrowed.issue, narrowed.fromMm, narrowed.toMm), (null, 8000, 13600));
    final exact = run(bridge(edits: {'wb_front_oh': 14.8, 'wb_plate_w': 5}));
    expect((exact.issue, exact.fromMm, exact.toMm), (null, 6800, 6800));
    expect(exact.drawing!.lines.where((l) => l.layer == 'WB_RANGE').length, 1);
    expect(exact.drawing!.lines.where((l) => l.layer == 'WB_LANE').length, 6);
    final half = run(bridge(edits: {'wb_front_oh': 14.799}));
    expect(half.stopMm, 6800.5);
    expect(half.toCsv(), contains('rearmost,6.8000,6.8005,6.8010'));
  });

  test('invalid scope, widths, axle fit, overhang and site stop both exports', () {
    for (final (b, reason) in [
      (bridge(type: 'bus_terminal'), 'Select Freight Terminal'),
      (bridge(edits: {'wb_plate_w': 5.001}), 'must fit inside the weighing corridor'),
      (bridge(edits: {'wb_tyre': 2.601}), 'cannot exceed the vehicle body'),
      (bridge(edits: {'wb_plate_w': 2.999}), 'tyre envelope and both side clearances'),
      (bridge(edits: {'wb_body': 4.401}), 'body envelope and both side clearances'),
      (bridge(edits: {'wb_plate_l': 8.999}), 'full axle span'),
      (bridge(edits: {'wb_front_oh': 14.801}), 'no common stopping position'),
      (bridge(edits: {'right_setback': 4.001}), 'right plot edge'),
      (bridge(edits: {'rear_setback': 4.001}), 'rear plot edge'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid mode previews the axle window and exports', (tester) async {
    await tester.pumpWidget(MaterialApp(home: WeighbridgeCadScreen(name: 'Bridge', brief: bridge(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('6.800–15.800 m'), findsOneWidget);
    expect(find.text('Share weighbridge plan DXF'), findsOneWidget);
    expect(find.text('Share axle schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved overhang conflict without fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'bridge', name: 'Overhang conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: bridge(edits: {'wb_front_oh': 14.801}));
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
    await tester.tap(find.text('Freight weighbridge CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no common stopping position'), findsOneWidget);
    expect(find.text('Share weighbridge plan DXF'), findsNothing);
    expect(find.text('Share axle schedule CSV'), findsNothing);
  });
}
