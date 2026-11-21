import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/silage_bunker_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/silage_bunker_cad_screen.dart';
import 'package:architect_engine/services/silage_bunker_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief bunker({Map<String, Object> edits = const {}, String type = 'dairy_farm', String config = 'production_site'}) =>
  ProjectBrief(floorCount: null, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'rural', subcategoryId: 'farm',
      typeId: type, configurationId: config, actionId: 'concept_design', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': silageBunkerMode, 'sb_w': 8, 'sb_l': 24, 'sb_wall': .25, 'sb_rise': .48, 'sb_floor_max': 2,
      'sb_fill': 2.4, 'sb_face': 6, 'sb_face_max': 40, 'sb_rim': 3, 'sb_free': .6, 'sb_apron': 6, 'sb_reserve': 1.25,
      'sb_west': 2, 'sb_south': 3, 'sb_min_vol': 357.12, 'left_setback': 2, 'right_setback': 4, 'front_setback': 3,
      'rear_setback': 4, ...edits,
    }));

void main() {
  const widthFt = 17 / .3048, depthFt = 38.5 / .3048;
  SilageBunkerCadResult run(ProjectBrief b) => SilageBunkerCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('Dairy and Cattle Farm opt-in preserves other ordinary CAD choices', () {
    expect(silageBunkerCadEligible('rural', 'farm', 'dairy_farm'), isTrue);
    expect(silageBunkerCadEligible('rural', 'farm', 'cattle_farm'), isTrue);
    expect(silageBunkerCadEligible('rural', 'farm', 'poultry_farm'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(silageBunkerMode)));
    expect(cadOutputOptions(warehouseLoading: false, silageBunker: true).options.map((o) => o.id), containsAll([...ordinary, silageBunkerMode]));
  });

  test('saved plan leaves the opening clear and section accounts for both volume deductions', () {
    final saved = ProjectBrief.fromMap(bunker().toMap())!;
    expect(SilageBunkerCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.freeMm, r.volumeM3, r.floorGrade, r.faceGrade), (11000, 31500, 600, 357.12, 2, 40));
    final plan = r.plan!, section = r.section!;
    final wall = plan.lines.where((l) => l.layer == 'SB_WALL');
    expect(wall.length, 8);
    final stubs = wall.where((l) => l.start.y == 9000 && l.end.y == 9000);
    expect(stubs.map((l) => (l.start.x, l.end.x)), [(3250, 3500), (11750, 11500)]);
    final crest = plan.lines.singleWhere((l) => l.layer == 'SB_FACE');
    expect((crest.start.x, crest.end.x, crest.start.y), (3500, 11500, 15000));
    final floor = section.lines.singleWhere((l) => l.layer == 'SB_FLOOR');
    final face = section.lines.singleWhere((l) => l.layer == 'SB_FACE');
    final flat = section.lines.singleWhere((l) => l.layer == 'SB_FILL');
    expect((floor.end.x, floor.end.y, face.start.x, face.start.y, face.end.x, face.end.y), (24000, 480, 0, 0, 6000, 2400));
    expect((flat.start.x, flat.start.y, flat.end.x, flat.end.y), (6000, 2400, 24000, 2400));
    expect(plan.toDxf(), contains('FULL ENVELOPE 11.000 x 31.500 M / GEOMETRIC FILL 357.120 M3'));
    expect(section.toDxf(), contains('FLOOR 2.000% / FILL FACE 40.000% / FREEBOARD 0.600 M'));
  });

  test('longer open-front face lowers volume, without changing the fitting footprint', () {
    final r = run(bunker(edits: {'sb_face': 12, 'sb_min_vol': 299.52}));
    expect((r.issue, r.depthMm, r.volumeM3, r.faceGrade), (null, 31500, 299.52, 20));
  });

  test('scope, crest, grades, freeboard, fit and volume conflicts suppress both DXFs', () {
    for (final (b, reason) in [
      (bunker(type: 'poultry_farm'), 'Select Dairy Farm or Cattle Farm'),
      (bunker(config: 'farm_residence'), 'blank arrangement or Production Site'),
      (bunker(edits: {'sb_face': 24}), 'end before the rear wall'),
      (bunker(edits: {'sb_fill': .48}), 'above the rear floor'),
      (bunker(edits: {'sb_free': .601}), 'submitted freeboard'),
      (bunker(edits: {'sb_rise': .481}), 'floor grade exceeds'),
      (bunker(edits: {'sb_face': 5.999}), 'fill-face grade exceeds'),
      (bunker(edits: {'right_setback': 4.001}), 'right plot edge'),
      (bunker(edits: {'sb_min_vol': 357.1201}), 'below the submitted minimum'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('valid template switches from plan to section', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SilageBunkerCadScreen(name: 'Bunker', brief: bunker(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Geometric fill volume 357.120 m³'), findsOneWidget);
    expect(find.text('Share bunker plan DXF'), findsOneWidget);
    await tester.tap(find.text('Section A–A'));
    await tester.pumpAndSettle();
    expect(find.text('Share bunker section DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved grade conflict without fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'bunker', name: 'Grade conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: bunker(edits: {'sb_face': 5.999}));
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
    await tester.tap(find.text('Silage bunker CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('fill-face grade exceeds'), findsOneWidget);
    expect(find.text('Share bunker plan DXF'), findsNothing);
    expect(find.text('Share bunker section DXF'), findsNothing);
  });
}
