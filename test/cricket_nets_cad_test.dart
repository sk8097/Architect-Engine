import 'package:architect_engine/data/cricket_nets_cad_fields.dart';
import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/cricket_nets_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/cricket_nets_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief nets({Map<String, Object> edits = const {}, String type = 'sports_complex', String setting = 'outdoor'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'institutional', subcategoryId: 'sports',
    typeId: type, configurationId: setting, actionId: 'concept_design', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': cricketNetsMode, 'cn_count': 3, 'cn_w': 3.6, 'cn_gap': .25, 'cn_pitch': 20.12,
    'cn_runup': 14, 'cn_min_runup': 14, 'cn_rear': 3, 'cn_min_rear': 3, 'cn_crease': 2.64,
    'cn_pop': 1.22, 'cn_return_w': 2.44, 'cn_return_l': 2.44, 'cn_side': 1.2, 'cn_end': 1,
    'cn_west': 2, 'cn_south': 3, 'left_setback': 2, 'right_setback': 4, 'front_setback': 3, 'rear_setback': 3, ...edits,
  }));

void main() {
  const widthFt = 19.7 / .3048, depthFt = 45.12 / .3048;
  CricketNetsCadResult run(ProjectBrief b) => CricketNetsCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('opt-in leaves other sports modes unchanged', () {
    expect(cricketNetsCadEligible('institutional', 'sports', 'training_centre'), isTrue);
    expect(cricketNetsCadEligible('institutional', 'sports', 'indoor_arena'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false, footballPitch: true).options.map((o) => o.id);
    expect(ordinary, isNot(contains(cricketNetsMode)));
    expect(cadOutputOptions(warehouseLoading: false, footballPitch: true, cricketNets: true).options.map((o) => o.id),
      containsAll([...ordinary, cricketNetsMode]));
  });

  test('saved plan and CSV agree on aligned wickets and mirrored crease geometry', () {
    final b = ProjectBrief.fromMap(nets().toMap())!;
    expect(CricketNetsCadGenerator.requested(b), isTrue);
    final r = run(b);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.lanes.length, r.pitchMm, r.runupMm), (13700, 39120, 3, 20120, 14000));
    expect(r.lanes.map((lane) => lane.centerMm), [5000, 8850, 12700]);
    final d = r.drawing!;
    final wickets = d.lines.where((l) => l.layer == 'CN_WICKET').toList();
    expect(wickets.length, 6);
    expect((wickets[0].start.x, wickets[0].end.x, wickets[0].start.y, wickets[1].start.y), (3680, 6320, 18000, 38120));
    final popping = d.lines.where((l) => l.layer == 'CN_POP').toList();
    expect((popping[0].start.y, popping[1].start.y), (19220, 36900));
    final returns = d.lines.where((l) => l.layer == 'CN_RETURN').toList();
    expect(returns.length, 12);
    expect((returns[0].start.x, returns[0].start.y, returns[0].end.y, returns[2].start.y, returns[2].end.y),
      (3780, 19220, 16780, 36900, 39340));
    expect(d.toDxf(), contains('3 LANES / WICKETS 20.120 M APART / ENVELOPE 13.700 x 39.120 M'));
    expect(r.toCsv(), endsWith('N03,12.7000,18.0000,38.1200,19.2200,36.9000\r\n'));
  });

  test('zero gaps share single side lines and odd-mm lanes retain half-mm centre coordinates', () {
    final shared = run(nets(edits: {'cn_gap': 0, 'cn_w': 3.599}));
    expect(shared.issue, isNull);
    final lanes = shared.drawing!.lines.where((l) => l.layer == 'CN_LANE').toList();
    expect(lanes.length, 10);
    expect(lanes.where((l) => l.start.x == l.end.x).map((l) => l.start.x), [3200, 6799, 10398, 13997]);
    expect(shared.toCsv(), contains('N01,4.9995,18.0000'));
  });

  test('scope, invalid crease nesting, clearance and setbacks stop exports', () {
    for (final (b, reason) in [
      (nets(type: 'indoor_arena'), 'eligible sports facility'),
      (nets(setting: 'indoor'), 'Outdoor'),
      (nets(edits: {'cn_count': 3.5}), 'whole lane count'),
      (nets(edits: {'cn_runup': 13.999}), 'run-up or batter rear clearance'),
      (nets(edits: {'cn_min_rear': 3.001}), 'run-up or batter rear clearance'),
      (nets(edits: {'cn_crease': 3.6}), 'narrower than the lane'),
      (nets(edits: {'cn_return_w': 2.64}), 'Return crease separation'),
      (nets(edits: {'cn_pop': 10.06}), 'popping creases must stay separate'),
      (nets(edits: {'cn_return_l': 1.22}), 'reach behind its wicket line'),
      (nets(edits: {'cn_return_l': 4.221}), 'without going beyond the lane end'),
      (nets(edits: {'right_setback': 4.001}), 'right plot edge'),
      (nets(edits: {'rear_setback': 3.001}), 'rear plot edge'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid mode previews the DXF and crease schedule options', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CricketNetsCadScreen(name: 'Nets', brief: nets(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('3 practice lanes'), findsOneWidget);
    expect(find.text('Share practice plan DXF'), findsOneWidget);
    expect(find.text('Share crease set-out CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved crease conflict without fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'nets', name: 'Crease conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: nets(edits: {'cn_pop': 10.06}));
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
    await tester.tap(find.text('Cricket nets CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('popping creases must stay separate'), findsOneWidget);
    expect(find.text('Share practice plan DXF'), findsNothing);
    expect(find.text('Share crease set-out CSV'), findsNothing);
  });
}
