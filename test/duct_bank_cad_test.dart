import 'package:architect_engine/data/duct_bank_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/duct_bank_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/duct_bank_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief bank({Map<String, Object> edits = const {}, String type = 'telecom_network'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'energy',
    typeId: type, configurationId: 'outdoor_yard'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'duct_bank_mode': ductBankModeId, 'db_grid': 'Example grid', 'db_datum': 'Local RL',
    'db_axis': '500000,2000000;500060,2000080', 'db_levels': '10,102,100;\n40,101.1,100.2\r\n90,103,100.7',
    'db_width': 1.2, 'db_depth': .6, 'db_cover': .9, 'db_gap': .3,
    'db_crossings': 'U1,25,98.9,99.2;U2,70,100.9,101.05', ...edits,
  }));

void main() {
  final generator = DuctBankCadGenerator();

  test('projected plan and true-scale profile preserve controls, envelopes and governing gaps', () {
    expect(ductBankCadEligible('infrastructure', 'energy', 'telecom_network'), isTrue);
    expect(ductBankCadEligible('infrastructure', 'energy', 'utility_corridor'), isFalse);
    final saved = ProjectBrief.fromMap(bank().toMap())!;
    expect(DuctBankCadGenerator.requested(saved), isTrue);
    expect(DuctBankCadGenerator.requested(bank(edits: {'duct_bank_mode': 'other'})), isFalse);
    final r = generator.generate(saved);
    expect(r.issue, isNull);
    expect((r.lengthMm, r.widthMm, r.coverMm, r.coverStationMm, r.crossings, r.crossingGapMm, r.crossingId),
      (80000, 1200, 900, 40000, 2, 300, 'U1'));
    final plan = r.plan!;
    final edge = plan.lines.firstWhere((l) => l.layer == 'DUCT_BANK');
    expect((edge.start.x, edge.start.y, edge.end.x, edge.end.y), (500006480, 2000007640, 500054480, 2000071640));
    expect(plan.lines.where((l) => l.layer == 'DUCT_BANK').length, 4);
    expect(plan.lines.where((l) => l.layer == 'DUCT_CROSS').length, 2);
    expect(plan.toDxf(), contains('SURVEYED TELECOM DUCT BANK / PLAN / PROJECTED MM'));
    final profile = r.profile!;
    final cover = profile.lines.singleWhere((l) => l.layer == 'DUCT_COVER');
    expect((cover.start.x, cover.start.y, cover.end.x, cover.end.y), (40000, 2200, 40000, 3100));
    final markers = profile.lines.where((l) => l.layer == 'DUCT_GAP').toList();
    expect((markers[0].start.x, markers[0].start.y, markers[0].end.y), (25000, 1500, 1200));
    expect((markers[1].start.x, markers[1].start.y, markers[1].end.y), (70000, 2500, 2900));
    expect(profile.toDxf(), contains('Y ZERO AT RL 98.000 M / DATUM: Local RL'));
  });

  test('can evaluate crossings at both ends and at a level knot without extrapolation', () {
    final r = generator.generate(bank(edits: {'db_crossings': 'A,10,99,99.1;B,40,100.5,100.7;C,90,101,101.2'}));
    expect(r.issue, isNull);
    expect((r.crossings, r.crossingGapMm, r.crossingId), (3, 300, 'A'));
  });

  test('survey errors, cover and crossing clashes block both sheets', () {
    for (final (b, reason) in [
      (bank(type: 'utility_corridor'), 'Select Telecom Network'),
      (bank(edits: {'db_cover': .901}), 'Cover at Ch 40.000 m'),
      (bank(edits: {'db_levels': '10,102,100;10,102,100'}), 'strictly increase'),
      (bank(edits: {'db_levels': '10,102,100;100.001,103,101'}), 'within the surveyed A–B'),
      (bank(edits: {'db_gap': .301}), 'U1 leaves only 0.300 m'),
      (bank(edits: {'db_crossings': 'U1,25,99.2,99.6'}), 'overlaps the proposed duct bank'),
      (bank(edits: {'db_crossings': 'U1,25,98.9,99.5'}), 'leaves only 0.000 m'),
      (bank(edits: {'db_crossings': 'U1,25,99.2,99.1'}), 'positive envelope depth'),
      (bank(edits: {'db_crossings': 'U1,9,98.9,99.2'}), 'within the surveyed bank span'),
      (bank(edits: {'db_crossings': 'U1,25,98.9,99.2;U2,24,98.9,99.2'}), 'at an increasing chainage'),
      (bank(edits: {'db_crossings': 'U1,25,98.9,99.2;u1,70,100.9,101.05'}), 'is repeated'),
    ]) {
      final r = generator.generate(b);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.profile, isNull);
    }
  });

  testWidgets('preview toggles through separate plan and profile exports', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DuctBankCadScreen(name: 'Duct run', brief: bank())));
    expect(find.text('Share duct-bank plan DXF'), findsOneWidget);
    await tester.tap(find.text('Longitudinal profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share duct-bank profile DXF'), findsOneWidget);
    expect(find.text('Share duct-bank plan DXF'), findsNothing);
  });

  testWidgets('Projects reopens a crossing conflict without generic fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'duct', name: 'Duct conflict', width: 0, length: 0,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: bank(edits: {'db_crossings': 'U1,25,99.2,99.6'}));
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
    await tester.tap(find.text('Surveyed telecom duct bank CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('U1 overlaps'), findsOneWidget);
    expect(find.text('Share duct-bank plan DXF'), findsNothing);
    expect(find.text('Share duct-bank profile DXF'), findsNothing);
  });
}
