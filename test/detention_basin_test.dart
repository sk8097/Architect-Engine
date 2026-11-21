import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/detention_basin_screen.dart';
import 'package:architect_engine/services/detention_basin_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief basin({Map<String, Object> edits = const {}, String type = 'detention_retention_pond',
  Map<String, int> spaces = const {}}) => ProjectBrief(floorCount: 0, parking: ProjectParking.none, features: const [],
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'water',
    typeId: type, configurationId: 'storage', plotShapeId: 'rectangular', spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'basin_stage_storage', 'db_reference': 'BM1 local datum', 'db_width': 12, 'db_length': 20,
    'db_slope_x': 3, 'db_slope_y': 2, 'db_west': 5, 'db_south': 6,
    'db_bottom': 100, 'db_normal': 101, 'db_design': 102, 'db_crest': 102.5, 'db_freeboard': .5, 'db_target': 548, ...edits,
  }));

void main() {
  DetentionBasinResult run(ProjectBrief brief) => DetentionBasinGenerator().generate(brief, widthFt: 50 / .3048, depthFt: 45 / .3048);

  test('asymmetric side slopes give true stage areas and volumes on the common datum', () {
    final saved = ProjectBrief.fromMap(basin().toMap())!;
    expect(DetentionBasinGenerator.requested(saved), isTrue);
    expect(cadOutputOptions(warehouseLoading: false, detentionBasin: true).options.map((o) => o.id), contains('basin_stage_storage'));
    final r = run(saved);
    expect(r.issue, isNull);
    expect(r.freeboardMm, 500);
    expect(r.stages.map((s) => s.levelMm), [100000, 101000, 102000, 102500]);
    expect(r.stages.map((s) => s.areaM2), [240, 432, 672, 810]);
    expect(r.stages.map((s) => s.storageM3), [0, 332, 880, 1250]);
    expect(r.activeStorageM3, 548);
    final plan = r.plan!, section = r.section!;
    final crest = plan.lines.firstWhere((l) => l.layer == 'BASIN_CREST');
    expect((crest.start.x, crest.start.y, crest.end.x, crest.end.y), (5000, 6000, 32000, 6000));
    final floor = section.lines.singleWhere((l) => l.layer == 'BASIN_FLOOR');
    expect((floor.start.x, floor.start.y, floor.end.x, floor.end.y), (7500, 0, 19500, 0));
    final design = section.lines.singleWhere((l) => l.layer == 'BASIN_DESIGN');
    expect((design.start.x, design.start.y, design.end.x, design.end.y), (1500, 2000, 25500, 2000));
    expect(plan.toDxf(), contains('BASIN_SECTION_LINE'));
    expect(section.toDxf(), contains('DESIGN HIGH WATER 102.000 M / 672.000 M2 / 880.000 M3'));
  });

  test('dry basin uses full geometric storage at high water and permits negative datum levels', () {
    final result = run(basin(edits: {'db_bottom': -5, 'db_normal': -5, 'db_design': -3, 'db_crest': -2.5}));
    expect(result.issue, isNull);
    expect(result.activeStorageM3, 880);
    expect(result.stages[1].storageM3, 0);
    expect(result.plan!.lines.where((l) => l.layer == 'BASIN_NORMAL'), isEmpty);
    expect(result.section!.toDxf(), contains('DRY NORMAL POOL AT FLOOR'));
  });

  test('no sheets if levels, active storage, freeboard or crest footprint cannot fit', () {
    for (final (brief, issue) in [
      (basin(type: 'culvert'), 'Select Water'),
      (basin(spaces: {'outlet': 1}), 'separate Space selections'),
      (basin(edits: {'db_normal': 102}), 'Levels must follow'),
      (basin(edits: {'db_freeboard': .501}), 'below the supplied 0.501 m minimum'),
      (basin(edits: {'db_target': 549}), '548.000 m³, below the supplied'),
      (basin(edits: {'db_slope_y': 6}), 'north plot edge'),
      (basin(edits: {'left_setback': 5.001}), 'west plot edge'),
      (basin(edits: {'db_reference': ''}), 'datum reference'),
    ]) {
      final result = run(brief);
      expect(result.issue, contains(issue));
      expect(result.plan, isNull);
      expect(result.section, isNull);
    }
  });

  testWidgets('basin preview toggles both sheets and hides exports when the target fails', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DetentionBasinScreen(name: 'Basin', brief: basin(), widthFt: 165, depthFt: 148)));
    expect(find.text('Active storage 548.000 m³ · Freeboard 0.500 m'), findsOneWidget);
    expect(find.text('Share basin plan DXF'), findsOneWidget);
    await tester.tap(find.text('Section A–A'));
    await tester.pumpAndSettle();
    expect(find.text('Share basin section DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: DetentionBasinScreen(key: const ValueKey('blocked'), name: 'Basin',
      brief: basin(edits: {'db_target': 549}), widthFt: 165, depthFt: 148)));
    expect(find.textContaining('below the supplied'), findsOneWidget);
    expect(find.text('Share basin plan DXF'), findsNothing);
    expect(find.text('Share basin section DXF'), findsNothing);
  });
}
