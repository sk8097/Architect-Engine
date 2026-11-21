import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/rain_garden_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/rain_garden_cad_screen.dart';
import 'package:architect_engine/services/rain_garden_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief garden({Map<String, Object> edits = const {}, String type = 'public_garden'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'public_realm',
    typeId: type, configurationId: 'public_open_space', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': rainGardenMode, 'rg_bed_w': 6, 'rg_bed_l': 8, 'rg_slope_we': 3, 'rg_slope_sn': 4,
    'rg_pond': .25, 'rg_free': .15, 'rg_media': .6, 'rg_agg': .25, 'rg_reserve': 1.2, 'rg_reserve_min': .9,
    'rg_storage_min': 15.25, 'rg_west': 1, 'rg_south': 2, ...edits,
  }));

void main() {
  const widthFt = 14 / .3048, depthFt = 18 / .3048;
  RainGardenCadResult run(ProjectBrief b) => RainGardenCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('public garden modes are opt-in and coexist', () {
    expect(rainGardenCadEligible('infrastructure', 'public_realm', 'public_garden'), isTrue);
    expect(rainGardenCadEligible('infrastructure', 'public_realm', 'public_park'), isFalse);
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains(rainGardenMode)));
    expect(cadOutputOptions(warehouseLoading: false, rainGarden: true, raisedBeds: true).options.map((o) => o.id),
      containsAll([rainGardenMode, 'garden_raised_beds']));
  });

  test('unequal side slopes give exact surface ponding and independent gross layer volumes', () {
    final b = ProjectBrief.fromMap(garden().toMap())!;
    expect(RainGardenCadGenerator.requested(b), isTrue);
    final r = run(b);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.pondMm, r.freeboardMm), (10800, 13600, 250, 150));
    expect((r.storageM3, r.mediaM3, r.aggregateM3), (15.25, 28.8, 12));
    final plan = r.plan!;
    for (final (layer, x, y, ex) in [
      ('RG_RESERVE', 1000, 2000, 11800), ('RG_RIM', 2200, 3200, 10600),
      ('RG_WATER', 2650, 3800, 10150), ('RG_BED', 3400, 4800, 9400),
    ]) {
      final line = plan.lines.firstWhere((l) => l.layer == layer);
      expect((line.start.x, line.start.y, line.end.x), (x, y, ex));
    }
    final cut = plan.lines.singleWhere((l) => l.layer == 'RG_CUT');
    expect((cut.start.x, cut.start.y, cut.end.x, cut.end.y), (1000, 8800, 11800, 8800));
    expect(plan.toDxf(), contains('RIM 8.400 x 11.200 M / FULL ENVELOPE 10.800 x 13.600 M'));
    final section = r.section!;
    final water = section.lines.singleWhere((l) => l.layer == 'RG_WATER');
    expect((water.start.x, water.start.y, water.end.x, water.end.y), (1650, 250, 9150, 250));
    final bank = section.lines.firstWhere((l) => l.layer == 'RG_RIM');
    expect((bank.start.x, bank.start.y, bank.end.x, bank.end.y), (1200, 400, 2400, 0));
    final underside = section.lines.where((l) => l.layer == 'RG_AGG').toList()[1];
    expect((underside.start.x, underside.start.y, underside.end.x, underside.end.y), (2400, -850, 8400, -850));
    expect(section.toDxf(), contains('PLANTING MEDIA 28.800 M3 / AGGREGATE 12.000 M3 GROSS'));
  });

  test('freeboard and below-bed thickness change the relevant geometry without inflating ponding storage', () {
    final r = run(garden(edits: {'rg_free': .25, 'rg_media': .8, 'rg_agg': .1}));
    expect(r.issue, isNull);
    expect((r.storageM3, r.mediaM3, r.aggregateM3), (15.25, 38.4, 4.8));
    expect((r.widthMm, r.depthMm), (11400, 14400));
    expect(run(garden(edits: {'right_setback': 2.2, 'rear_setback': 2.4})).issue, isNull);
  });

  test('insufficient surface volume, reserve and fit all block both drawings', () {
    for (final (b, reason) in [
      (garden(type: 'public_park'), 'Select Public Garden'),
      (garden(edits: {'rg_slope_we': .999}), 'Enter valid measured'),
      (garden(edits: {'rg_reserve_min': 1.201}), 'reserve beyond the rim'),
      (garden(edits: {'right_setback': 2.201}), 'right plot edge'),
      (garden(edits: {'rg_south': 4.401}), 'rear plot edge'),
      (garden(edits: {'rg_storage_min': 15.251}), 'Surface ponding volume is 15.250000 m³'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('valid preview switches between plan and section exports', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RainGardenCadScreen(name: 'Rain garden', brief: garden(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Share rain garden plan DXF'), findsOneWidget);
    await tester.tap(find.text('Section A–A'));
    await tester.pumpAndSettle();
    expect(find.text('Share rain garden section DXF'), findsOneWidget);
    expect(find.text('Share rain garden plan DXF'), findsNothing);
  });

  testWidgets('Projects reopens a failed volume check without generic fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'rain', name: 'Short storage', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: garden(edits: {'rg_storage_min': 17}));
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
    await tester.tap(find.text('Rain garden CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('below the submitted target'), findsOneWidget);
    expect(find.text('Share rain garden plan DXF'), findsNothing);
    expect(find.text('Share rain garden section DXF'), findsNothing);
  });
}
