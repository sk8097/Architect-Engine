import 'package:architect_engine/data/boardwalk_cad_fields.dart';
import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/boardwalk_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/boardwalk_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief walk({Map<String, Object> edits = const {}, String type = 'public_garden'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'public_realm',
    typeId: type, configurationId: 'public_open_space', actionId: 'concept_design', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': boardwalkMode, 'bw_length': 24, 'bw_width': 3, 'bw_top': 102, 'bw_thick': .25,
    'bw_z0': 100, 'bw_ch': 8.3, 'bw_zm': 101.1, 'bw_z1': 100.4, 'bw_clear': .65,
    'bw_first': 1.2, 'bw_last': 1.8, 'bw_overhang': 1.8, 'bw_spacing': 4, 'bw_post': .3, 'bw_inset': .55,
    'bw_reserve': .75, 'bw_west': 2, 'bw_south': 2.5, 'left_setback': 2, 'right_setback': 3.5,
    'front_setback': 2.5, 'rear_setback': 3, ...edits,
  }));

void main() {
  const widthFt = 10 / .3048, depthFt = 31 / .3048;
  BoardwalkCadResult run(ProjectBrief b) => BoardwalkCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('boardwalk is a public park or garden opt-in and preserves ordinary park modes', () {
    expect(boardwalkCadEligible('infrastructure', 'public_realm', 'public_garden'), isTrue);
    expect(boardwalkCadEligible('infrastructure', 'public_realm', 'public_park'), isTrue);
    expect(boardwalkCadEligible('infrastructure', 'public_realm', 'waterfront_promenade'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false, parkFence: true).options.map((o) => o.id);
    expect(ordinary, isNot(contains(boardwalkMode)));
    expect(cadOutputOptions(warehouseLoading: false, parkFence: true, boardwalk: true).options.map((o) => o.id),
      containsAll([...ordinary, boardwalkMode]));
  });

  test('saved plan and profile agree on supports; clearance is checked between supports', () {
    final saved = ProjectBrief.fromMap(walk().toMap())!;
    expect(BoardwalkCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.pairs, r.pitchMm, r.gapMm, r.criticalMm), (4500, 25500, 7, 3500, 650, 8300));
    final plan = r.plan!, profile = r.profile!;
    final squares = plan.lines.where((l) => l.layer == 'BW_POST').toList();
    expect(squares.length, 56);
    expect((squares[0].start.x, squares[0].start.y, squares[4].start.x), (3150, 4300, 5050));
    final poles = profile.lines.where((l) => l.layer == 'BW_POST').toList();
    expect(poles.map((l) => l.start.x), [1200, 4700, 8200, 11700, 15200, 18700, 22200]);
    expect(poles.first.start.y, closeTo(159.0361445783, 1e-9));
    expect(poles.every((l) => l.end.y == 1750), isTrue);
    final gap = profile.lines.singleWhere((l) => l.layer == 'BW_GAP');
    expect((gap.start.x, gap.start.y, gap.end.x, gap.end.y), (8300, 1100, 8300, 1750));
    expect(plan.toDxf(), contains('7 SUPPORT PAIRS / PITCH 3.500 M / FULL ENVELOPE 4.500 x 25.500 M'));
    expect(profile.toDxf(), contains('MIN SOFFIT GAP 0.650 M AT CH 8.300 M'));
  });

  test('equal pitch honours the exact limit, and signed datums and highest end work', () {
    expect(run(walk(edits: {'bw_spacing': 3.5})).pairs, 7);
    final reduced = run(walk(edits: {'bw_spacing': 3.499}));
    expect((reduced.issue, reduced.pairs, reduced.pitchMm), (null, 8, 3000));
    final negative = run(walk(edits: {'bw_top': -8, 'bw_z0': -10, 'bw_zm': -9.6, 'bw_z1': -8.9}));
    expect((negative.issue, negative.gapMm, negative.criticalMm), (null, 650, 24000));
    expect(negative.profile!.toDxf(), contains('SECTION DATUM RL -10.000 M'));
  });

  test('ground, overhang, footprints and boundary conflicts block both drawings', () {
    for (final (brief, reason) in [
      (walk(type: 'waterfront_promenade'), 'Select Public Park or Public Garden'),
      (walk(edits: {'bw_ch': 24}), 'interior ground break'),
      (walk(edits: {'bw_clear': .651}), 'Soffit-to-ground gap at Ch 8.300 m'),
      (walk(edits: {'bw_overhang': 1.799}), 'end overhang exceeds'),
      (walk(edits: {'bw_first': 12, 'bw_last': 12, 'bw_overhang': 12}), 'positive interval'),
      (walk(edits: {'bw_inset': 1.35}), 'both support footprints'),
      (walk(edits: {'bw_spacing': .3}), 'contact or overlap'),
      (walk(edits: {'bw_spacing': .1}), 'exceeds 100 support pairs'),
      (walk(edits: {'right_setback': 3.501}), 'right plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.profile, isNull);
    }
  });

  testWidgets('valid template switches from deck plan to profile', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BoardwalkCadScreen(name: 'Boardwalk', brief: walk(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('Minimum soffit gap 0.650 m'), findsOneWidget);
    expect(find.text('Share boardwalk plan DXF'), findsOneWidget);
    await tester.tap(find.text('Longitudinal profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share boardwalk profile DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved clearance conflict without export or fallback', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'walk', name: 'Clearance conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: walk(edits: {'bw_clear': .651}));
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
    await tester.tap(find.text('Raised boardwalk CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Soffit-to-ground gap at Ch 8.300 m'), findsOneWidget);
    expect(find.text('Share boardwalk plan DXF'), findsNothing);
    expect(find.text('Share boardwalk profile DXF'), findsNothing);
  });
}
