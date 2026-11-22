import 'package:architect_engine/data/project_type_cad_coverage.dart';
import 'package:architect_engine/data/project_scenarios.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/screens/scenario_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the full taxonomy maps to unique scenario IDs in all eight categories', () {
    final ids = projectScenarios.map((s) => s.id);
    expect(ids.toSet(), hasLength(ids.length));
    expect(projectScenarios.map((s) => s.category.id).toSet(), hasLength(8));
    for (final c in projectTaxonomy) {
      for (final g in c.groups) {
        for (final t in g.types) {
          expect(scenarioFor(c.id, g.id, t.id, null), isNotNull);
          for (final config in taxonomyProgram(g, t).configurations) {
            expect(scenarioFor(c.id, g.id, t.id, config.id)?.configuration, same(config));
          }
        }
      }
    }
  });

  test('house combinations are distinct and unimplemented entries never claim CAD', () {
    final villa = scenarioFor('residential', 'houses', 'villa', '2_bhk')!;
    final variants = libraryVariants(villa).toList();
    expect(variants, hasLength(8));
    expect(variants.map((v) => v.id).toSet(), hasLength(8));
    final ready = variants.where((v) => v.generator != null).single;
    expect(ready.id, 'residential/houses/villa/2_bhk/floors_1/parking_none');
    expect(ready.generator, ScenarioGenerator.house2Bhk);
    expect(scenarioVariantFor(villa, 2, 'car')?.generator, isNull);
    final threeBhk = scenarioFor('residential', 'houses', 'villa', '3_bhk')!;
    expect(libraryVariants(threeBhk).every((v) => v.generator == null), isTrue);
    expect(projectScenarios.where((s) => s.generator != null), hasLength(10));
    expect(projectScenarios.where((s) => s.category.id != 'residential').every((s) => s.generator == null), isTrue);
    final selection = TaxonomySelection(version: 1, categoryId: 'residential',
      subcategoryId: 'houses', typeId: 'villa', configurationId: '2_bhk', scenarioId: ready.id);
    expect(TaxonomySelection.fromMap(selection.toMap())!.scenarioId, ready.id);
    final legacy = selection.toMap()..remove('scenarioId');
    expect(TaxonomySelection.fromMap(legacy)!.scenarioId, isNull);
  });

  test('type matrix exhaustively tracks shared and dedicated routes without counting configurations twice', () {
    final allTypes = projectScenarios.where((s) => s.configuration == null).toList();
    expect(projectTypeCadCoverage.length, allTypes.length);
    expect(projectTypeCadCoverage.values.every((entry) => entry.zoning), isTrue);
    expect(projectTypeCadCoverage['special/heritage/heritage_residence']!.hasDedicatedRoute, isFalse);
    expect(projectTypeCadCoverage['special/complex/high_rise_supertall_building']!.highRise, isTrue);
    expect(projectTypeCadCoverage['residential/houses/villa']!.registeredHouse, isTrue);
    expect(projectTypeCadCoverage['rural/farm/fish_farm_aquaculture']!.specialists.map((mode) => mode.id),
      contains('farm_measured_aquaculture_pond'));
    final road = projectTypeCadCoverage['infrastructure/transport/road']!;
    expect(road.offersEnclosed, isFalse);
    expect(road.specialists.map((mode) => mode.id), contains('survey_polyline'));
    expect(road.specialists.map((mode) => mode.id), isNot(contains('straight')));
    final csv = projectTypeCadCoverageCsv().trim().split('\r\n');
    expect(csv.length, projectTypeCadCoverage.length + 1);
    print('CAD coverage: ${allTypes.length} types, ${projectTypeCadCoverage.values.where((row) => row.hasDedicatedRoute).length} with a dedicated route');
  });

  testWidgets('scenario search opens a separate, prefilled house variant', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ScenarioLibraryScreen()));
    await tester.enterText(find.byType(TextField), 'villa 2 bhk ground floor no parking');
    await tester.pumpAndSettle();
    final variant = find.byKey(const ValueKey('residential/houses/villa/2_bhk/floors_1/parking_none'));
    expect(variant, findsOneWidget);
    expect(find.descendant(of: variant, matching: find.textContaining('CAD supported')), findsOneWidget);
    await tester.tap(variant);
    await tester.pumpAndSettle();
    expect(find.text('Configuration'), findsOneWidget);
    expect(find.text('2 BHK'), findsNothing); // Plot inputs come first.
    expect(find.byKey(const ValueKey('Plot geometry (required)')), findsOneWidget);
  });
}
