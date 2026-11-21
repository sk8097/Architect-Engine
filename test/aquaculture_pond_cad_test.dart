import 'package:architect_engine/data/aquaculture_pond_cad_fields.dart';
import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/aquaculture_pond_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/aquaculture_pond_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief pond({Map<String, Object> edits = const {}, String type = 'fish_farm_aquaculture',
  String? config = 'production_site', String plot = 'rectangular'}) => ProjectBrief(floorCount: null, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'rural', subcategoryId: 'farm',
      typeId: type, configurationId: config, actionId: 'concept_design', plotShapeId: plot),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': aquaculturePondMode, 'aqp_w': 12, 'aqp_l': 20, 'aqp_rise': 2, 'aqp_run': 4, 'aqp_water': 1.5,
      'aqp_free': .5, 'aqp_min_slope': 2, 'aqp_reserve': 1.5, 'aqp_west': 2, 'aqp_south': 3, 'aqp_min_vol': 522,
      'left_setback': 2, 'right_setback': 4, 'front_setback': 3, 'rear_setback': 4, ...edits,
    }));

void main() {
  const widthFt = 29 / .3048, depthFt = 38 / .3048;
  AquaculturePondCadResult run(ProjectBrief b) => AquaculturePondCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('Aquaculture is opt-in and preserves existing farm CAD choices', () {
    expect(aquaculturePondCadEligible('rural', 'farm', 'fish_farm_aquaculture'), isTrue);
    expect(aquaculturePondCadEligible('rural', 'farm', 'dairy_farm'), isFalse);
    expect(aquaculturePondCadEligible('rural', 'other', 'fish_farm_aquaculture'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(aquaculturePondMode)));
    expect(cadOutputOptions(warehouseLoading: false, aquaculturePond: true).options.map((o) => o.id),
      containsAll([...ordinary, aquaculturePondMode]));
  });

  test('saved pond exactly fits submitted limits and exports four nested outlines and true-scale section', () {
    final saved = ProjectBrief.fromMap(pond().toMap())!;
    expect(AquaculturePondCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.freeMm, r.volumeM3, r.surfaceM2, r.slopeH), (23000, 31000, 500, 522, 468, 2));
    final plan = r.plan!, section = r.section!;
    for (final (layer, x, y, width) in [
      ('AQP_RESERVE', 2000, 3000, 23000), ('AQP_RIM', 3500, 4500, 20000),
      ('AQP_WATER', 4500, 5500, 18000), ('AQP_TOE', 7500, 8500, 12000),
    ]) {
      final outline = plan.lines.where((l) => l.layer == layer);
      expect(outline.length, 4);
      final south = outline.singleWhere((l) => l.start.y == y && l.end.y == y);
      expect((south.start.x, south.end.x), (x, x + width));
    }
    final cut = plan.lines.singleWhere((l) => l.layer == 'AQP_CUT');
    expect((cut.start.y, cut.end.y), (18500, 18500));
    final water = section.lines.singleWhere((l) => l.layer == 'AQP_WATER');
    expect((water.start.x, water.start.y, water.end.x, water.end.y), (2500, 1500, 20500, 1500));
    final slope = section.lines.firstWhere((l) => l.layer == 'AQP_RIM');
    expect((slope.start.x, slope.start.y, slope.end.x, slope.end.y), (1500, 2000, 5500, 0));
    expect(plan.toDxf(), contains('FULL ENVELOPE 23.000 x 31.000 M / WATER SURFACE 468.000 M2'));
    expect(section.toDxf(), contains('GEOMETRIC WATER VOLUME 522.000 M3'));
  });

  test('lower water reduces area and volume without moving the rim, and fractional shoreline mm stay editable', () {
    final lower = run(pond(config: null, edits: {'aqp_water': 1, 'aqp_min_vol': 309}));
    expect((lower.issue, lower.widthMm, lower.depthMm, lower.surfaceM2, lower.freeMm), (null, 23000, 31000, 384, 1000));
    expect(lower.volumeM3, closeTo(928 / 3, 1e-9));
    final fractional = run(pond(edits: {'aqp_run': 3.999, 'aqp_min_slope': 1.999, 'aqp_min_vol': 521}));
    final water = fractional.section!.lines.singleWhere((l) => l.layer == 'AQP_WATER');
    expect((water.start.x, water.end.x), (2499.75, 20498.25));
    expect(fractional.section!.toDxf(), contains('2499.750'));
  });

  test('scope, level, slope, freeboard, fit and volume conflicts suppress both DXFs', () {
    for (final (b, reason) in [
      (pond(type: 'dairy_farm'), 'Select Fish Farm/Aquaculture'),
      (pond(config: 'farm_residence'), 'blank arrangement or Production Site'),
      (pond(plot: 'square'), 'Enter valid plot'),
      (pond(edits: {'aqp_run': '4'}), 'Enter valid plot'),
      (pond(edits: {'aqp_water': 2}), 'strictly below the pond rim'),
      (pond(edits: {'aqp_water': 1.501}), 'submitted freeboard'),
      (pond(edits: {'aqp_run': 3.999}), 'side slope is steeper'),
      (pond(edits: {'aqp_reserve': 1.501}), 'right plot edge'),
      (pond(edits: {'rear_setback': 4.001}), 'rear plot edge'),
      (pond(edits: {'aqp_min_vol': 522.0001}), 'below the submitted minimum'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('valid template switches from plan to section', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AquaculturePondCadScreen(name: 'Pond', brief: pond(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Geometric water volume 522.000 m³'), findsOneWidget);
    expect(find.text('Share pond plan DXF'), findsOneWidget);
    await tester.tap(find.text('Section A–A'));
    await tester.pumpAndSettle();
    expect(find.text('Share pond section DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved slope conflict without fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'pond', name: 'Slope conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: pond(edits: {'aqp_run': 3.999}));
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
    await tester.tap(find.text('Aquaculture pond CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('side slope is steeper'), findsOneWidget);
    expect(find.text('Share pond plan DXF'), findsNothing);
    expect(find.text('Share pond section DXF'), findsNothing);
  });
}
