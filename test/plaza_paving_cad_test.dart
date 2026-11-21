import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/plaza_paving_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/plaza_paving_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/plaza_paving_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief paving({Map<String, Object> edits = const {}, bool institutional = false, String type = 'urban_plaza'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: institutional ? 'institutional' : 'infrastructure',
    subcategoryId: institutional ? 'sports' : 'public_realm', typeId: type,
    configurationId: institutional ? 'outdoor' : 'public_open_space', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': plazaPavingMode, 'pav_w': 7.04, 'pav_l': 4.23, 'pav_west': 2, 'pav_south': 1,
    'pav_unit_x': .6, 'pav_unit_y': .4, 'pav_joint': .005, 'pav_min_x': .2, 'pav_min_y': .12, ...edits,
  }));

void main() {
  const widthFt = 12 / .3048, depthFt = 8 / .3048;
  PlazaPavingCadResult run(ProjectBrief brief) => PlazaPavingCadGenerator().generate(brief, widthFt: widthFt, depthFt: depthFt);

  test('centred cuts use the maximum full core and account for every millimetre and joint', () {
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains(plazaPavingMode)));
    expect(cadOutputOptions(warehouseLoading: false, plazaPaving: true).options.map((o) => o.id), contains(plazaPavingMode));
    final saved = ProjectBrief.fromMap(paving().toMap())!;
    expect(PlazaPavingCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.columns, r.rows, r.fullCount, r.cutCount, r.grossMm2, r.pieceMm2), (12, 11, 90, 42, 29779200, 29197300));
    expect(r.jointM2, closeTo(.5819, 1e-10));
    final d = r.drawing!;
    final first = d.lines.firstWhere((l) => l.layer == 'PAV_CUT');
    final firstFull = d.lines.firstWhere((l) => l.layer == 'PAV_FULL');
    final last = d.lines.where((l) => l.layer == 'PAV_CUT').toList()[41 * 4];
    expect((first.start.x, first.start.y, first.end.x), (2000, 1000, 2492));
    expect((firstFull.start.x, firstFull.start.y, firstFull.end.x), (2497, 1295, 3097));
    expect((last.start.x, last.start.y, last.end.x), (8547, 4940, 9040));
    expect(d.lines.where((l) => l.layer == 'PAV_FULL').length, 90 * 4);
    expect(d.toDxf(), contains('GRID 12 x 11 / 7.040 x 4.230 M / JOINT 0.005 M'));
    expect(r.toCsv(), contains('full,0.600,0.400,90,21.600000\r\n'));
    expect(r.toCsv(), contains('cut,0.492,0.290,2,0.285360\r\n'));
    expect(r.toCsv(), contains('cut,0.493,0.400,9,1.774800\r\n'));
  });

  test('exact fits have no border cuts; permits a two-cut axis without a full core', () {
    final exact = run(paving(institutional: true, edits: {'pav_w': 1.810, 'pav_l': 1.210, 'pav_min_x': .6, 'pav_min_y': .4}));
    expect((exact.issue, exact.columns, exact.rows, exact.fullCount, exact.cutCount), (null, 3, 3, 9, 0));
    final narrow = run(paving(edits: {'pav_w': .451, 'pav_l': .4}));
    expect((narrow.issue, narrow.columns, narrow.rows, narrow.fullCount, narrow.cutCount), (null, 2, 1, 0, 2));
    expect(narrow.pieceTypes.single.widthMm, 223);
  });

  test('conflicts, impossible cuts and excessive counts block both exports', () {
    for (final (brief, reason) in [
      (paving(type: 'public_park'), 'Select Urban Plaza'),
      (paving(edits: {'pav_west': 5}), 'right plot edge'),
      (paving(edits: {'rear_setback': 2.771}), 'rear plot edge'),
      (paving(edits: {'pav_min_x': .601}), 'cannot exceed'),
      (paving(edits: {'pav_unit_x': .05, 'pav_min_x': .025, 'pav_joint': .05}), 'narrower than both'),
      (paving(edits: {'pav_w': .45, 'pav_min_x': .3}), 'west–east layout'),
      (paving(edits: {'pav_l': .449, 'pav_min_y': .3}), 'south–north layout'),
      (paving(edits: {'pav_unit_x': .05, 'pav_unit_y': .05, 'pav_min_x': .02, 'pav_min_y': .02}), '2,500 pieces'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('preview offers both exports on a successful balanced grid', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PlazaPavingCadScreen(name: 'Plaza', brief: paving(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('90 full pieces · 42 cut pieces'), findsOneWidget);
    expect(find.text('Share paving plan DXF'), findsOneWidget);
    expect(find.text('Share paving cut schedule CSV'), findsOneWidget);
  });

  testWidgets('an impossible grid reopens from Projects without fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'plaza', name: 'Short plaza', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: paving(edits: {'pav_w': .45, 'pav_min_x': .3}));
    SharedPreferences.setMockInitialValues({'ae_projects_v1': [p.toJson()]});
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ], child: const MaterialApp(home: ProjectsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Short plaza'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Concept zoning CAD'), findsNothing);
    await tester.tap(find.text('Urban plaza paving CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('west–east layout'), findsOneWidget);
    expect(find.text('Share paving plan DXF'), findsNothing);
    expect(find.text('Share paving cut schedule CSV'), findsNothing);
  });
}
