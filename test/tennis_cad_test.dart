import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/tennis_cad_screen.dart';
import 'package:architect_engine/services/tennis_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief tennis({Map<String, Object> edits = const {}, String type = 'sports_complex', String shape = 'rectangular', String config = 'outdoor'}) => ProjectBrief(
  floorCount: null, features: const [], parking: ProjectParking.none,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'institutional', subcategoryId: 'sports',
    typeId: type, configurationId: config, plotShapeId: shape),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'tennis_measured_bank', 'tc_count': 2, 'tc_doubles': 10.97, 'tc_singles': 8.23, 'tc_length': 23.77,
    'tc_service': 6.4, 'tc_mark': .1, 'tc_post': .914, 'tc_side': 3, 'tc_south_end': 6, 'tc_north_end': 7,
    'tc_gap': 4, 'tc_west': 2, 'tc_south': 3, ...edits,
  }));

void main() {
  const widthFt = 42 / .3048, depthFt = 44 / .3048;
  TennisCadResult run(ProjectBrief b, {double width = widthFt}) =>
      TennisCadGenerator().generate(b, widthFt: width, depthFt: depthFt);

  test('opt-in persists and two measured courts keep separate run-offs and markings', () {
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('tennis_measured_bank')));
    expect(cadOutputOptions(warehouseLoading: false, tennis: true).options.map((o) => o.id), contains('tennis_measured_bank'));
    final saved = ProjectBrief.fromMap(tennis().toMap())!;
    expect(TennisCadGenerator.requested(saved), isTrue);
    expect(TennisCadGenerator.requested(tennis(edits: {'cad_output': 'concept'})), isFalse);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.courtCount, r.bankWidthMm, r.bankDepthMm), (2, 37940, 36770));
    expect(r.courtEnvelopeAreaM2, closeTo(1247.9738, 1e-8));
    final d = r.drawing!;
    Iterable<(num, num, num, num)> segments(String layer) =>
        d.lines.where((l) => l.layer == layer).map((l) => (l.start.x, l.start.y, l.end.x, l.end.y));
    final runoff = segments('TENNIS_RUNOFF').toList();
    expect(runoff.length, 8);
    expect(runoff[0], (2000, 3000, 18970, 3000));
    expect(runoff[2], (18970, 39770, 2000, 39770));
    expect(runoff[4], (22970, 3000, 39940, 3000));
    expect(segments('TENNIS_DOUBLES').first, (5000, 9000, 15970, 9000));
    expect(segments('TENNIS_SINGLES').first, (6370, 9000, 6370, 32770));
    expect(segments('TENNIS_SERVICE').take(5), [
      (6370, 14485, 14600, 14485), (6370, 27285, 14600, 27285), (10485, 14485, 10485, 27285),
      (10485, 9000, 10485, 9100), (10485, 32770, 10485, 32670),
    ]);
    expect(segments('TENNIS_NET').first, (4086, 20885, 16884, 20885));
    expect(d.toDxf(), contains('BANK 37.940 x 36.770 M'));
    for (final layer in ['TENNIS_DOUBLES', 'TENNIS_SINGLES', 'TENNIS_NET', 'TENNIS_RUNOFF', 'TENNIS_SERVICE']) {
      expect(d.toDxf(), contains(layer));
    }
  });

  test('one court needs no inter-court gap and exact setbacks permit edge contact', () {
    final single = run(tennis(edits: {'tc_count': 1, 'tc_gap': 0}));
    expect((single.issue, single.bankWidthMm), (null, 16970));
    final exact = run(tennis(edits: {'left_setback': 2, 'right_setback': 2.06, 'front_setback': 3, 'rear_setback': 4.23}));
    expect(exact.issue, isNull);
    expect(exact.drawing!.lines.where((l) => l.layer == 'TENNIS_SETBACK').length, 4);
    final four = run(tennis(edits: {'tc_count': 4}), width: 84 / .3048);
    expect((four.issue, four.bankWidthMm), (null, 79880));
  });

  test('unsupported briefs, invalid markings, run-offs and setbacks do not export', () {
    for (final (brief, message) in [
      (tennis(type: 'indoor_arena'), 'supported sports type'),
      (tennis(config: 'indoor'), 'outdoor court bank'),
      (tennis(shape: 'square'), 'measured plot'),
      (tennis(edits: {'tc_count': 2.5}), 'whole number'),
      (tennis(edits: {'tc_singles': 10.97}), 'Singles sidelines'),
      (tennis(edits: {'tc_service': 11.885}), 'strictly between'),
      (tennis(edits: {'tc_mark': 5.485}), 'centre mark'),
      (tennis(edits: {'tc_post': 3}), 'net-post centre'),
      (tennis(edits: {'tc_gap': 0}), 'positive gap'),
      (tennis(edits: {'tc_count': 1}), 'zero inter-court gap'),
      (tennis(edits: {'right_setback': 2.061}), 'right plot edge'),
      (tennis(edits: {'rear_setback': 4.231}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.drawing, isNull);
    }
  });

  testWidgets('valid court preview offers the layered DXF', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TennisCadScreen(name: 'Courts', brief: tennis(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('37.940 × 36.770 m'), findsOneWidget);
    expect(find.text('Share tennis court DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens an invalid tennis brief without export or generic zoning', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'courts', name: 'Tennis courts', length: depthFt, width: widthFt,
      bhk: '', floors: '', facing: 'Not decided', brief: tennis(edits: {'rear_setback': 5}), createdAt: now, updatedAt: now);
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
    await tester.tap(find.text('Outdoor tennis court CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('rear plot edge'), findsOneWidget);
    expect(find.text('Share tennis court DXF'), findsNothing);
  });
}
