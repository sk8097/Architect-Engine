import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/playground_cad_screen.dart';
import 'package:architect_engine/services/playground_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const equipment = 'A1,4,5,3,4,1,2,2,1;\nB2,5,15,2,3,2,1,1,2\r\nC3,16,6,3,3,1,1,2,1';

ProjectBrief playground({Map<String, Object> edits = const {}, bool infrastructure = false, String type = 'playground'}) => ProjectBrief(
  floorCount: null, features: const [], parking: ProjectParking.none,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: infrastructure ? 'infrastructure' : 'institutional', subcategoryId: infrastructure ? 'public_realm' : 'sports',
    typeId: type, configurationId: infrastructure ? 'public_open_space' : 'outdoor', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'playground_measured_zones', 'py_path_west': 11, 'py_path_width': 2, 'py_gap': 2,
    'left_setback': 2, 'right_setback': 2, 'front_setback': 2, 'rear_setback': 2, 'py_equipment': equipment, ...edits,
  }));

void main() {
  const widthFt = 24 / .3048, depthFt = 25 / .3048;
  PlaygroundCadResult run(ProjectBrief b) => PlaygroundCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('saved inputs create asymmetric disjoint zones and measurable path, DXF and CSV', () {
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('playground_measured_zones')));
    expect(cadOutputOptions(warehouseLoading: false, playground: true).options.map((o) => o.id), contains('playground_measured_zones'));
    final saved = ProjectBrief.fromMap(playground(infrastructure: true).toMap())!;
    expect(PlaygroundCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.zoneAreaM2, r.pathAreaM2), (102, 42));
    expect(r.zones.map((z) => (z.id, z.zone.left, z.zone.bottom, z.zone.right, z.zone.top)),
      [('A1', 3000, 3000, 9000, 10000), ('B2', 3000, 14000, 8000, 20000), ('C3', 15000, 4000, 20000, 10000)]);
    final d = r.drawing!;
    final path = d.lines.where((l) => l.layer == 'PLAY_PATH').toList();
    expect((path[0].start.x, path[0].start.y, path[0].end.x, path[1].end.y), (11000, 2000, 13000, 23000));
    expect(d.lines.where((l) => l.layer == 'PLAY_EQUIPMENT').length, 12);
    expect(d.lines.where((l) => l.layer == 'PLAY_SETBACK').length, 4);
    expect(d.toDxf(), contains('3 ZONES / 102.000 M2 GROSS / 42.000 M2 PATH'));
    final csv = r.toCsv()!.split('\r\n');
    expect(csv.length, 5);
    expect(csv[1], 'A1,4.000,5.000,3.000,4.000,3.000,3.000,9.000,10.000,42.000000');
  });

  test('diagonal gap uses corner distance and zero-gap contact does not mean overlap', () {
    const diagonal = 'A,2,2,1,1,0,0,0,0;B,6,7,1,1,0,0,0,0';
    final exact = run(playground(edits: {'py_equipment': diagonal, 'py_path_west': 17, 'py_gap': 5}));
    expect(exact.issue, isNull);
    expect(run(playground(edits: {'py_equipment': diagonal, 'py_path_west': 17, 'py_gap': 5.001})).issue, contains('A and B'));
    final contact = run(playground(edits: {'py_equipment': 'A,2,2,1,1,0,0,0,0;B,3,2,1,1,0,0,0,0', 'py_gap': 0}));
    expect(contact.issue, isNull);
    expect(contact.zoneAreaM2, 2);
  });

  test('rejects malformed records, setback, path and zone conflicts without either export', () {
    for (final (brief, message) in [
      (playground(type: 'public_park'), 'Select Playground'),
      (playground(edits: {'left_setback': 23}), 'positive rectangular'),
      (playground(edits: {'py_path_west': 1.9}), 'path crosses'),
      (playground(edits: {'py_gap': 2.001}), 'zone for A1 overlaps the path or misses'),
      (playground(edits: {'py_path_west': 8, 'py_gap': 0}), 'zone for A1 overlaps the path'),
      (playground(edits: {'py_equipment': 'A,2,2,1,1,1,0,0,0', 'py_gap': 0}), 'zone for A crosses'),
      (playground(edits: {'py_equipment': 'A,2,2,1,1,0,0,0,0;B,2.999,2,1,1,0,0,0,0', 'py_gap': 0}), 'A and B'),
      (playground(edits: {'py_equipment': 'A,2,2,1,1,0,0,0,0;a,6,7,1,1,0,0,0,0', 'py_gap': 0}), 'IDs must be unique'),
      (playground(edits: {'py_equipment': '=A,2,2,1,1,0,0,0,0'}), 'letter-led ID'),
      (playground(edits: {'py_equipment': 'A,2,2,1,1,0,0,0'}), 'exactly eight dimensions'),
      (playground(edits: {'py_equipment': 'A,NaN,2,1,1,0,0,0,0'}), 'finite nonnegative'),
      (playground(edits: {'py_equipment': List.filled(25, 'A,2,2,1,1,0,0,0,0').join(';')}), '1–24'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid preview offers both exports; a saved path conflict offers neither', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PlaygroundCadScreen(name: 'Play area', brief: playground(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Share playground DXF'), findsOneWidget);
    expect(find.text('Share zone schedule CSV'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: PlaygroundCadScreen(key: const ValueKey('invalid'), name: 'Play area',
      brief: playground(edits: {'py_gap': 2.001}), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('zone for A1 overlaps the path'), findsOneWidget);
    expect(find.text('Share playground DXF'), findsNothing);
    expect(find.text('Share zone schedule CSV'), findsNothing);
  });
}
