import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/street_light_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/street_light_cad_screen.dart';
import 'package:architect_engine/services/street_light_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief lights({Map<String, Object> edits = const {}, String type = 'street_lighting_network'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'energy',
    typeId: type, configurationId: 'outdoor_yard'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'street_light_mode': streetLightMode, 'sl_grid': 'Example grid', 'sl_axis': '1000,2000;1060,2080',
    'sl_side': 'left', 'sl_start': 10, 'sl_end': 90, 'sl_offset': 3, 'sl_min': 14, 'sl_max': 22,
    'sl_exclusions': '30,31;\n29,30\r\n4,6;94,96', ...edits,
  }));

void main() {
  final generator = StreetLightCadGenerator();

  test('finds the fewest fixed-end equal spans avoiding closed windows', () {
    expect(streetLightCadEligible('infrastructure', 'energy', 'street_lighting_network'), isTrue);
    expect(streetLightCadEligible('infrastructure', 'energy', 'utility_corridor'), isFalse);
    final b = ProjectBrief.fromMap(lights().toMap())!;
    expect(StreetLightCadGenerator.requested(b), isTrue);
    expect(StreetLightCadGenerator.requested(lights(edits: {'street_light_mode': 'other'})), isFalse);
    final r = generator.generate(b);
    expect(r.issue, isNull);
    expect((r.lengthMm, r.spacingMm), (80000, 16000));
    expect(r.poles.map((p) => p.stationMm), [10000, 26000, 42000, 58000, 74000, 90000]);
    expect(r.poles.map((p) => p.id), ['P01', 'P02', 'P03', 'P04', 'P05', 'P06']);
    expect((r.poles.first.point.x, r.poles.first.point.y, r.poles.last.point.x, r.poles.last.point.y),
      (1003600, 2009800, 1051600, 2073800));
    expect(r.toCsv(), contains('P02,26.000000,1013.200000,2022.600000\r\n'));
    final drawing = r.drawing!;
    final exclusion = drawing.lines.singleWhere((l) => l.layer == 'SL_EXCLUDE');
    expect((exclusion.start.x, exclusion.start.y, exclusion.end.x, exclusion.end.y), (1015000, 2025000, 1016200, 2026600));
    expect(drawing.lines.where((l) => l.layer == 'SL_ROW').length, 2);
    expect(drawing.toDxf(), contains('6 POLE(S) / 16.000 M EQUAL SPACING'));
    final reflected = generator.generate(lights(edits: {'sl_side': 'right'})).poles.first.point;
    expect((reflected.x, reflected.y), (1008400, 2006200));
  });

  test('blank exclusions keep wider spacing and an exact interior boundary is blocked', () {
    final blank = generator.generate(lights(edits: {'sl_exclusions': ''}));
    expect((blank.issue, blank.poles.length, blank.spacingMm), (null, 5, 20000));
    final blocked = generator.generate(lights(edits: {'sl_exclusions': '30,31'}));
    expect((blocked.issue, blocked.poles.length, blocked.spacingMm), (null, 6, 16000));
  });

  test('fractional pole stations are checked before any rounding', () {
    final r = generator.generate(lights(edits: {'sl_min': 26, 'sl_max': 27, 'sl_exclusions': '36.667,37'}));
    expect(r.issue, isNull);
    expect(r.poles[1].stationMm, closeTo(36666.6666667, 1e-6));
    expect(r.toCsv(), contains('P02,36.666667,'));
    final blocked = generator.generate(lights(edits: {'sl_min': 26, 'sl_max': 27, 'sl_exclusions': '36.666,37'}));
    expect(blocked.issue, contains('No equal-spacing layout'));
  });

  test('endpoint conflicts, invalid spacing and infeasible layouts block both exports', () {
    for (final (brief, reason) in [
      (lights(type: 'utility_corridor'), 'Select Street Lighting Network'),
      (lights(edits: {'sl_end': 100.001}), 'within the surveyed A–B span'),
      (lights(edits: {'sl_min': 23}), 'Maximum spacing cannot be smaller'),
      (lights(edits: {'sl_min': 17, 'sl_max': 19}), 'No equal subdivision'),
      (lights(edits: {'sl_min': .1, 'sl_max': .4}), 'more than 200 poles'),
      (lights(edits: {'sl_exclusions': '9,10'}), 'fixed first pole falls'),
      (lights(edits: {'sl_exclusions': '90,91'}), 'fixed last pole falls'),
      (lights(edits: {'sl_exclusions': '40,40'}), 'must have positive length'),
      (lights(edits: {'sl_exclusions': '29,31;41,43'}), 'No equal-spacing layout'),
    ]) {
      final r = generator.generate(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid preview offers DXF and coordinate CSV', (tester) async {
    await tester.pumpWidget(MaterialApp(home: StreetLightCadScreen(name: 'Lighting', brief: lights())));
    expect(find.textContaining('6 poles · 16.000 m equal spacing'), findsOneWidget);
    expect(find.text('Share pole layout DXF'), findsOneWidget);
    expect(find.text('Share pole coordinates CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a first-pole conflict without fallback or downloads', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'lights', name: 'Pole conflict', width: 0, length: 0,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: lights(edits: {'sl_exclusions': '9,10'}));
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
    await tester.tap(find.text('Surveyed street-light pole CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('fixed first pole'), findsOneWidget);
    expect(find.text('Share pole layout DXF'), findsNothing);
    expect(find.text('Share pole coordinates CSV'), findsNothing);
  });
}
