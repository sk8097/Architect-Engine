import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/spillway_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/spillway_cad_screen.dart';
import 'package:architect_engine/services/spillway_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief spillway({Map<String, Object> edits = const {}, String type = 'flood_control_structure', String config = 'drainage_system'}) =>
  ProjectBrief(floorCount: null, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'water',
      typeId: type, configurationId: config, actionId: 'site_development', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': spillwayMode, 'sp_in_w': 10, 'sp_throat': 4, 'sp_out_w': 12,
      'sp_in_l': 20, 'sp_crest_l': 5, 'sp_min_crest': 5, 'sp_chute_l': 15, 'sp_apron_l': 8,
      'sp_rise': 2, 'sp_drop': 3.6, 'sp_in_max': 10, 'sp_chute_max': 24, 'sp_taper_max': 27,
      'sp_reserve': 2, 'sp_west': 3, 'sp_south': 5, 'left_setback': 3, 'right_setback': 5,
      'front_setback': 5, 'rear_setback': 3, ...edits,
    }));

void main() {
  const widthFt = 24 / .3048, depthFt = 60 / .3048;
  SpillwayCadResult run(ProjectBrief b) => SpillwayCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('specialist opt-in does not replace ordinary CAD or apply to detention ponds', () {
    expect(spillwayCadEligible('infrastructure', 'water', 'flood_control_structure'), isTrue);
    expect(spillwayCadEligible('infrastructure', 'water', 'detention_retention_pond'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(spillwayMode)));
    expect(cadOutputOptions(warehouseLoading: false, spillway: true).options.map((o) => o.id), containsAll([...ordinary, spillwayMode]));
  });

  test('reopened CAD has symmetric edges, horizontal crest and a toe below datum', () {
    final saved = ProjectBrief.fromMap(spillway().toMap())!;
    expect(SpillwayCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.toeMm, r.inletGrade, r.chuteGrade, r.inletTaper), (16000, 52000, -1600, 10, 24, 15));
    expect(r.chuteTaper, closeTo(26.6666666667, 1e-10));
    final plan = r.plan!, profile = r.profile!;
    final inlets = plan.lines.where((l) => l.layer == 'SP_INLET').toList();
    expect(inlets.map((l) => (l.start.x, l.start.y, l.end.x, l.end.y)), [(6000, 7000, 9000, 27000), (16000, 7000, 13000, 27000)]);
    final stations = plan.lines.where((l) => l.layer == 'SP_STATION').toList();
    expect(stations.map((l) => (l.start.y, l.end.x - l.start.x)), [(7000, 10000), (27000, 4000), (32000, 4000), (47000, 12000), (55000, 12000)]);
    final bed = profile.lines.where((l) => l.layer.startsWith('SP_')).toList();
    expect(bed.map((l) => (l.start.x, l.start.y, l.end.x, l.end.y)), [
      (0, 0, 20000, 2000), (20000, 2000, 25000, 2000), (25000, 2000, 40000, -1600), (40000, -1600, 48000, -1600),
    ]);
    expect(plan.toDxf(), contains('ENVELOPE 16.000 x 52.000 M'));
    expect(profile.toDxf(), contains('TOE AND APRON LEVEL -1.600 M'));
  });

  test('zero-taper limits allow straight edges and odd-mm width stays symmetric', () {
    final r = run(spillway(edits: {'sp_in_w': 4.001, 'sp_throat': 4.001, 'sp_out_w': 4.001, 'sp_taper_max': 0}));
    expect(r.issue, isNull);
    expect((r.widthMm, r.inletTaper, r.chuteTaper), (8001, 0, 0));
    final lines = r.plan!.lines.where((l) => l.layer == 'SP_INLET').toList();
    expect(lines.map((l) => (l.start.x, l.end.x)), [(5000, 5000), (9001, 9001)]);
  });

  test('invalid scope, throat widths, crest length, grades, tapers and fit block both sheets', () {
    for (final (brief, reason) in [
      (spillway(type: 'detention_retention_pond'), 'Select Flood-Control Structure'),
      (spillway(config: 'plant'), 'Drainage System'),
      (spillway(edits: {'sp_in_w': 3.999}), 'as wide as the crest throat'),
      (spillway(edits: {'sp_out_w': 3.999}), 'as wide as the crest throat'),
      (spillway(edits: {'sp_min_crest': 5.001}), 'flat crest is shorter'),
      (spillway(edits: {'sp_in_max': 9.999}), 'Inlet bed grade'),
      (spillway(edits: {'sp_chute_max': 23.999}), 'Chute bed grade'),
      (spillway(edits: {'sp_taper_max': 14.999}), 'Inlet edge taper'),
      (spillway(edits: {'sp_taper_max': 26.666}), 'Chute edge taper'),
      (spillway(edits: {'right_setback': 5.001}), 'right plot edge'),
      (spillway(edits: {'rear_setback': 3.001}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.profile, isNull);
    }
  });

  testWidgets('valid drawing switches from plan to true-scale profile', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SpillwayCadScreen(name: 'Spillway', brief: spillway(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Share spillway plan DXF'), findsOneWidget);
    await tester.tap(find.text('Longitudinal profile'));
    await tester.pumpAndSettle();
    expect(find.text('Chute toe: -1.600 m relative to inlet bed'), findsOneWidget);
    expect(find.text('Share spillway profile DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved conflict without generic fallback or DXF', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'spillway', name: 'Spillway conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: spillway(edits: {'sp_taper_max': 25}));
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
    await tester.tap(find.text('Spillway CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chute edge taper'), findsOneWidget);
    expect(find.text('Share spillway plan DXF'), findsNothing);
    expect(find.text('Share spillway profile DXF'), findsNothing);
  });
}
