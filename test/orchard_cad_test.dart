import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/orchard_cad_screen.dart';
import 'package:architect_engine/services/orchard_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief orchard({Map<String, Object> edits = const {}, String type = 'orchard_estate',
  Map<String, int> spaces = const {}}) => ProjectBrief(floorCount: 0, parking: ProjectParking.none, features: const [],
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'rural', subcategoryId: 'farm',
    typeId: type, configurationId: 'production_site', plotShapeId: 'rectangular', spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'orchard_measured_rows', 'orc_axis': 'ns', 'orc_rows': 4, 'orc_trees': 5, 'orc_row_pitch': 7,
    'orc_tree_pitch': 6, 'orc_canopy': 4, 'orc_headland': 5, 'orc_side_lane': 3, 'orc_west': 8, 'orc_south': 10,
    'orc_exclusions': 'corner,11.1,15.1,.1,.1', ...edits,
  }));

void main() {
  OrchardCadResult run(ProjectBrief brief) => OrchardCadGenerator().generate(brief, widthFt: 80 / .3048, depthFt: 65 / .3048);

  test('saved planting grid uses exact row and tree pitch, with local coordinate export', () {
    final saved = ProjectBrief.fromMap(orchard().toMap())!;
    expect(OrchardCadGenerator.requested(saved), isTrue);
    expect(cadOutputOptions(warehouseLoading: false, orchard: true).options.map((o) => o.id), contains('orchard_measured_rows'));
    final result = run(saved);
    expect(result.issue, isNull);
    expect(result.trees.length, 20);
    final first = result.trees.first, last = result.trees.last;
    expect((first.id, first.point.x, first.point.y), ('R01-T01', 13000, 17000));
    expect((last.id, last.point.x, last.point.y), ('R04-T05', 34000, 41000));
    final csv = result.toCsv()!.trim().split('\r\n');
    expect(csv.length, 21);
    expect(csv.first, 'tree_id,row,tree_in_row,east_from_plot_sw_m,north_from_plot_sw_m');
    expect(csv[1], 'R01-T01,1,1,13.0000,17.0000');
    expect(csv.last, 'R04-T05,4,5,34.0000,41.0000');
    final cad = result.drawing!;
    expect(cad.arcs.length, 40);
    expect(cad.arcs.every((arc) => arc.radius == 2000 && arc.layer == 'ORCHARD_CANOPY'), isTrue);
    final dxf = cad.toDxf();
    expect(RegExp(r'\r?\nARC\r?\n8\r?\nORCHARD_CANOPY\r?\n').allMatches(dxf).length, 40);
    final head = cad.lines.firstWhere((line) => line.layer == 'ORCHARD_HEADLAND');
    final lane = cad.lines.firstWhere((line) => line.layer == 'ORCHARD_LANE');
    expect((head.start.x, head.start.y, head.end.x, head.end.y), (8000, 10000, 39000, 10000));
    expect((lane.start.x, lane.start.y, lane.end.x, lane.end.y), (8000, 15000, 11000, 15000));
    expect(dxf, contains('ORCHARD_EXCLUSION'));
  });

  test('east–west rows rotate around the block while preserving southwest offsets', () {
    final result = run(orchard(type: 'plantation_estate', edits: {'orc_axis': 'ew', 'orc_exclusions': ''}));
    expect(result.issue, isNull);
    final first = result.trees.first, last = result.trees.last;
    expect((first.point.x, first.point.y, last.point.x, last.point.y), (15000, 36000, 39000, 15000));
    final head = result.drawing!.lines.firstWhere((l) => l.layer == 'ORCHARD_HEADLAND');
    expect((head.start.x, head.start.y, head.end.x, head.end.y), (8000, 10000, 13000, 10000));
    final fine = run(orchard(edits: {'orc_canopy': 4.001, 'orc_exclusions': ''}));
    expect(fine.toCsv(), contains('R01-T01,1,1,13.0005,17.0005'));
  });

  test('exact circle collision, blocked access, setbacks and impossible pitch block both files', () {
    for (final (brief, issue) in [
      (orchard(type: 'farmhouse'), 'Select Orchard Estate'),
      (orchard(spaces: {'water_storage': 1}), 'separate Space selections'),
      (orchard(edits: {'orc_exclusions': 'well,12,16,1,1'}), 'R01-T01 overlaps exclusion well'),
      (orchard(edits: {'orc_exclusions': 'gate,8,14,1,2'}), 'overlaps a clear headland or side access lane'),
      (orchard(edits: {'orc_exclusions': 'gate,81,14,1,2'}), 'outside the plot'),
      (orchard(edits: {'orc_canopy': 6.001}), 'overlaps the reserved mature canopies'),
      (orchard(edits: {'orc_rows': 100, 'orc_trees': 100}), '3,000 trees'),
      (orchard(edits: {'rear_setback': 17.001}), 'north plot edge'),
    ]) {
      final result = run(brief);
      expect(result.issue, contains(issue));
      expect(result.drawing, isNull);
      expect(result.toCsv(), isNull);
    }
  });

  testWidgets('preview makes both files available only for a fitted orchard', (tester) async {
    await tester.pumpWidget(MaterialApp(home: OrchardCadScreen(name: 'Orchard', brief: orchard(), widthFt: 263, depthFt: 215)));
    expect(find.textContaining('20 trees'), findsOneWidget);
    expect(find.text('Share planting DXF'), findsOneWidget);
    expect(find.text('Share tree coordinates CSV'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: OrchardCadScreen(key: const ValueKey('invalid'), name: 'Orchard',
      brief: orchard(edits: {'orc_exclusions': 'well,12,16,1,1'}), widthFt: 263, depthFt: 215)));
    expect(find.textContaining('R01-T01 overlaps exclusion'), findsOneWidget);
    expect(find.text('Share planting DXF'), findsNothing);
    expect(find.text('Share tree coordinates CSV'), findsNothing);
  });
}
