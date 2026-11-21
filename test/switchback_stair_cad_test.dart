import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/switchback_stair_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/switchback_stair_cad_screen.dart';
import 'package:architect_engine/services/switchback_stair_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief stair({Map<String, Object> edits = const {}, String type = 'public_park'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'public_realm',
    typeId: type, configurationId: 'public_open_space', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': switchbackStairMode, 'ss_datum': 'Local RL', 'ss_lower': 100, 'ss_upper': 103.75,
    'ss_min_riser': .14, 'ss_max_riser': .17, 'ss_going': .29, 'ss_width': 1.5, 'ss_gap': .3,
    'ss_end': 1.6, 'ss_turn': 1.8, 'ss_west': 1, 'ss_south': 1.2, ...edits,
  }));

void main() {
  const widthFt = 7 / .3048, depthFt = 10 / .3048;
  SwitchbackStairCadResult run(ProjectBrief b) => SwitchbackStairCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('stair mode is opt-in and preserves ramp mode', () {
    expect(switchbackStairCadEligible('infrastructure', 'public_realm', 'urban_plaza'), isTrue);
    expect(switchbackStairCadEligible('infrastructure', 'public_realm', 'public_garden'), isFalse);
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains(switchbackStairMode)));
    final options = cadOutputOptions(warehouseLoading: false, switchbackRamp: true, switchbackStair: true).options;
    expect(options.map((o) => o.id), contains(switchbackStairMode));
    expect(options.where((o) => o.label.toLowerCase().contains('ramp')), isNotEmpty);
  });

  test('preserves exact uniform fractional risers, open turn and full landing levels', () {
    final saved = ProjectBrief.fromMap(stair().toMap())!;
    expect(SwitchbackStairCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.risers, r.riserMm, r.runMm, r.widthMm, r.depthMm, r.turnRlMm), (12, 156.25, 3190, 3300, 6590, 101875));
    final p = r.plan!;
    final steps = p.lines.where((l) => l.layer == 'SS_UP_W' && l.start.y == l.end.y).toList();
    expect(steps.length, 12);
    expect((steps.first.start.x, steps.first.start.y, steps.first.end.x, steps.last.end.y), (1000, 2800, 2500, 5990));
    final between = p.lines.where((l) => l.layer == 'SS_LAND' && l.start.y == 5990 && l.end.y == 5990).single;
    expect((between.start.x, between.end.x), (2500, 2800));
    expect(p.toDxf(), contains('12 RISERS PER FLIGHT / 11 GOINGS / 3.190 M RUN EACH'));
    final e = r.elevation!;
    final low = e.lines.where((l) => l.layer == 'SS_UP_W' && l.start.x == l.end.x).toList();
    final high = e.lines.where((l) => l.layer == 'SS_UP_E' && l.start.x == l.end.x).toList();
    expect(low.length, 12);
    expect(high.length, 12);
    expect((low.first.start.x, low.first.start.y, low.first.end.y, low.last.end.x, low.last.end.y), (1600, 0, 156.25, 4790, 1875));
    expect((high.first.start.x, high.first.start.y, high.last.end.x, high.last.end.y), (4790, 1875, 1600, 3750));
    expect(e.toDxf(), contains('BASE RL 100.000 M = ZERO / TURN RL 101.875 M'));
  });

  test('zero reserve keeps the shared edge single and exact riser/setback limits are inclusive', () {
    final exact = run(stair(edits: {'ss_upper': 103.6, 'ss_min_riser': .15, 'ss_max_riser': .15,
      'left_setback': 1, 'right_setback': 2.7, 'front_setback': 1.2, 'rear_setback': 2.21}));
    expect((exact.issue, exact.risers, exact.riserMm), (null, 12, 150));
    final touching = run(stair(edits: {'ss_gap': 0}));
    expect(touching.issue, isNull);
    final shared = touching.plan!.lines.where((l) => l.start.x == 2500 && l.end.x == 2500 && l.start.y == 2800 && l.end.y == 5990);
    expect(shared.length, 1);
  });

  test('impossible rise, landings and plot fit prevent both sheets', () {
    for (final (b, reason) in [
      (stair(type: 'playground'), 'Select Public Park or Urban Plaza'),
      (stair(edits: {'ss_upper': 100}), 'upper landing level must be higher'),
      (stair(edits: {'ss_min_riser': .171}), 'minimum riser height cannot exceed'),
      (stair(edits: {'ss_min_riser': .16}), 'No equal two-flight stair'),
      (stair(edits: {'ss_upper': 110}), 'more than 24 risers per flight'),
      (stair(edits: {'ss_turn': 1.499}), 'landing depths must each be at least'),
      (stair(edits: {'rear_setback': 2.211}), 'rear plot edge'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.elevation, isNull);
    }
  });

  testWidgets('preview toggles separate plan and elevation exports', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SwitchbackStairCadScreen(name: 'Stair', brief: stair(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Share stair plan DXF'), findsOneWidget);
    await tester.tap(find.text('Side elevation'));
    await tester.pumpAndSettle();
    expect(find.text('Share stair elevation DXF'), findsOneWidget);
    expect(find.text('Share stair plan DXF'), findsNothing);
  });

  testWidgets('Projects reopens the failed stair without fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'stair', name: 'Stair conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: stair(edits: {'ss_min_riser': .16}));
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
    await tester.tap(find.text('Outdoor switchback stair CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No equal two-flight stair'), findsOneWidget);
    expect(find.text('Share stair plan DXF'), findsNothing);
    expect(find.text('Share stair elevation DXF'), findsNothing);
  });
}
