import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/jump_runway_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/jump_runway_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/jump_runway_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief runway({Map<String, Object> edits = const {}, String type = 'sports_complex'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'institutional', subcategoryId: 'sports',
    typeId: type, configurationId: 'outdoor', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': jumpRunwayMode, 'jr_run_l': 55, 'jr_run_w': 1.22, 'jr_pit_l': 9, 'jr_pit_w': 3,
    'jr_long_offset': 2, 'jr_triple_offset': 11, 'jr_long_run_min': 53, 'jr_triple_run_min': 44,
    'jr_long_far_min': 11, 'jr_triple_far_min': 20, 'jr_side': 1.5, 'jr_south_reserve': 2,
    'jr_north_reserve': 4, 'jr_west': 2, 'jr_south': 2, ...edits,
  }));

void main() {
  const widthFt = 10 / .3048, depthFt = 75 / .3048;
  JumpRunwayCadResult run(ProjectBrief b) => JumpRunwayCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('opt-in runway mode coexists with the oval-track mode', () {
    expect(jumpRunwayCadEligible('institutional', 'sports', 'training_centre'), isTrue);
    expect(jumpRunwayCadEligible('institutional', 'sports', 'playground'), isFalse);
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains(jumpRunwayMode)));
    expect(cadOutputOptions(warehouseLoading: false, athleticsTrack: true, jumpRunway: true).options.map((o) => o.id),
      containsAll([jumpRunwayMode, 'athletics_measured_track']));
  });

  test('saved layout measures both reference edges and leaves no doubled sand mouth', () {
    final saved = ProjectBrief.fromMap(runway().toMap())!;
    expect(JumpRunwayCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm), (6000, 70000));
    expect(r.takeoffs.map((t) => (t.event, t.approachMm, t.nearMm, t.farMm)),
      [('long_jump', 53000, 2000, 11000), ('triple_jump', 44000, 11000, 20000)]);
    final drawing = r.drawing!;
    expect(drawing.lines.where((l) => l.layer == 'JR_RUN').length, 3);
    final sand = drawing.lines.firstWhere((l) => l.layer == 'JR_SAND');
    expect((sand.start.x, sand.start.y, sand.end.x), (3500, 59000, 6500));
    final marks = drawing.lines.where((l) => l.layer == 'JR_BOARD').toList();
    expect(marks.map((l) => (l.start.x, l.start.y, l.end.x)), [(4390, 57000, 5610), (4390, 48000, 5610)]);
    expect(drawing.toDxf(), contains('LJ TO SAND: 2.000-11.000 M / TJ TO SAND: 11.000-20.000 M'));
    expect(r.toCsv(), contains('long_jump,53.000,2.000,11.000\r\ntriple_jump,44.000,11.000,20.000\r\n'));
  });

  test('limits are inclusive for fit; a millimetre conflict is attributed to the correct event or edge', () {
    expect(run(runway(edits: {'left_setback': 2, 'right_setback': 2, 'front_setback': 2, 'rear_setback': 3})).issue, isNull);
    expect(run(runway(edits: {'jr_pit_w': 1.22})).issue, isNull);
    for (final (brief, reason) in [
      (runway(type: 'playground'), 'Select an eligible outdoor sports project'),
      (runway(edits: {'jr_pit_w': 1.219}), 'at least as wide as the runway'),
      (runway(edits: {'jr_triple_offset': 2}), 'must be farther from the near sand edge'),
      (runway(edits: {'jr_run_l': 11, 'jr_long_run_min': 8}), 'Triple-jump take-off line must lie inside'),
      (runway(edits: {'jr_long_run_min': 53.001}), 'Long-jump has only 53.000 m'),
      (runway(edits: {'jr_triple_run_min': 44.001}), 'Triple-jump has only 44.000 m'),
      (runway(edits: {'jr_long_far_min': 11.001}), 'Long-jump take-off line is only 11.000 m'),
      (runway(edits: {'jr_triple_far_min': 20.001}), 'Triple-jump take-off line is only 20.000 m'),
      (runway(edits: {'rear_setback': 3.001}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('preview offers plan and take-off schedule', (tester) async {
    await tester.pumpWidget(MaterialApp(home: JumpRunwayCadScreen(name: 'Jump runway', brief: runway(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('Triple jump: 44.000 m approach'), findsOneWidget);
    expect(find.text('Share jump runway DXF'), findsOneWidget);
    expect(find.text('Share take-off schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a failed event check without fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'jump', name: 'Short approach', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: runway(edits: {'jr_triple_run_min': 46}));
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
    await tester.tap(find.text('Jump runway CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Triple-jump has only 44.000 m'), findsOneWidget);
    expect(find.text('Share jump runway DXF'), findsNothing);
    expect(find.text('Share take-off schedule CSV'), findsNothing);
  });
}
