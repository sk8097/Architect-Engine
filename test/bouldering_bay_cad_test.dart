import 'package:architect_engine/data/bouldering_bay_cad_fields.dart';
import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/bouldering_bay_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/bouldering_bay_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief bay({Map<String, Object> edits = const {}, String type = 'indoor_arena', String config = 'indoor', int floors = 1}) =>
  ProjectBrief(floorCount: floors, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'institutional', subcategoryId: 'sports',
      typeId: type, configurationId: config, actionId: 'concept_design', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': boulderingBayMode, 'bb_hall_w': 12, 'bb_hall_l': 11, 'bb_hall_h': 6,
      'bb_wall_w': 8, 'bb_lower': 1.5, 'bb_upper': 2, 'bb_throw': 1.5, 'bb_max_angle': 38,
      'bb_above': 2.5, 'bb_mat': 5, 'bb_beyond': 3.5, 'bb_side': 1, 'bb_access': 1.8, 'bb_rear': 1.2,
      'bb_west': 2, 'bb_south': 3, 'left_setback': 2, 'right_setback': 3, 'front_setback': 3, 'rear_setback': 3, ...edits,
    }));

void main() {
  const plotFt = 17 / .3048;
  BoulderingBayCadResult run(ProjectBrief b) => BoulderingBayCadGenerator().generate(b, widthFt: plotFt, depthFt: plotFt);

  test('bouldering bay is opt-in for eligible indoor sports facilities', () {
    expect(boulderingBayCadEligible('institutional', 'sports', 'indoor_arena'), isTrue);
    expect(boulderingBayCadEligible('institutional', 'sports', 'recreation_centre'), isTrue);
    expect(boulderingBayCadEligible('institutional', 'sports', 'swimming_pool'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(boulderingBayMode)));
    expect(cadOutputOptions(warehouseLoading: false, boulderingBay: true).options.map((o) => o.id), containsAll([...ordinary, boulderingBayMode]));
  });

  test('saved plan and section agree on exact lip projection and clearances', () {
    final saved = ProjectBrief.fromMap(bay().toMap())!;
    expect(BoulderingBayCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.heightMm, r.lipGapMm, r.matBeyondMm, r.panelM2), (3500, 2500, 3500, 32));
    expect(r.angle, closeTo(36.86989764584, 1e-9));
    final plan = r.plan!, section = r.section!;
    final lip = plan.lines.where((l) => l.layer == 'BB_PANEL').last;
    expect((lip.start.x, lip.end.x, lip.start.y), (4000, 12000, 11300));
    final mat = plan.lines.firstWhere((l) => l.layer == 'BB_MAT');
    expect((mat.start.x, mat.end.x, mat.start.y), (3000, 13000, 7800));
    final access = plan.lines.where((l) => l.layer == 'BB_ACCESS').last;
    expect((access.start.x, access.end.x, access.start.y), (3000, 13000, 6000));
    final panels = section.lines.where((l) => l.layer == 'BB_PANEL').toList();
    expect(panels.map((l) => (l.start.x, l.start.y, l.end.x, l.end.y)), [(0, 0, 0, 1500), (0, 1500, 1500, 3500)]);
    final gap = section.lines.singleWhere((l) => l.layer == 'BB_GAP');
    expect((gap.start.x, gap.start.y, gap.end.y), (1500, 3500, 6000));
    expect(plan.toDxf(), contains('CLEAR HALL 12.000 x 11.000 M / MAT 10.000 x 5.000 M'));
    expect(section.toDxf(), contains('BEYOND LIP 3.500 M / PANEL SURFACE 32.000 M2'));
  });

  test('exact-width mat and exact-depth access reuse shared hall boundary', () {
    final r = run(bay(edits: {'bb_side': 2, 'bb_access': 4.8}));
    expect(r.issue, isNull);
    final lines = r.plan!.lines;
    expect(lines.where((l) => l.layer == 'BB_MAT').length, 2);
    expect(lines.where((l) => l.layer == 'BB_ACCESS'), isEmpty);
  });

  test('scope, slope, clearances and hall fit suppress both DXFs', () {
    for (final (b, reason) in [
      (bay(type: 'swimming_pool'), 'eligible indoor sports facility'),
      (bay(config: 'outdoor'), 'setting or Indoor'),
      (bay(floors: 2), 'one ground-floor hall only'),
      (bay(edits: {'bb_max_angle': 36.869}), 'above the submitted limit'),
      (bay(edits: {'bb_hall_h': 5.999}), 'submitted overhead clearance'),
      (bay(edits: {'bb_beyond': 3.501}), 'mat extension beyond the projected lip'),
      (bay(edits: {'bb_side': 2.001}), 'wider than the clear hall'),
      (bay(edits: {'bb_access': 4.801}), 'do not fit the clear hall depth'),
      (bay(edits: {'right_setback': 3.001}), 'right plot edge'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('valid mode switches from plan to section', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BoulderingBayCadScreen(name: 'Bay', brief: bay(), widthFt: plotFt, depthFt: plotFt)));
    expect(find.textContaining('Lip height 3.500 m'), findsOneWidget);
    expect(find.text('Share bay plan DXF'), findsOneWidget);
    await tester.tap(find.text('Section A–A'));
    await tester.pumpAndSettle();
    expect(find.text('Share bay section DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved clearance conflict without fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'bay', name: 'Bay conflict', width: plotFt, length: plotFt,
      bhk: '', floors: '1', facing: 'Not decided', createdAt: now, updatedAt: now, brief: bay(edits: {'bb_beyond': 3.501}));
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
    await tester.tap(find.text('Bouldering bay CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('mat extension beyond the projected lip'), findsOneWidget);
    expect(find.text('Share bay plan DXF'), findsNothing);
    expect(find.text('Share bay section DXF'), findsNothing);
  });
}
