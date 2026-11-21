import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/public_toilet_cad_screen.dart';
import 'package:architect_engine/services/public_toilet_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief toilets({Map<String, Object> edits = const {}, bool infrastructure = false, String? type}) => ProjectBrief(
  floorCount: 1, features: const [], parking: ProjectParking.none,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: infrastructure ? 'infrastructure' : 'institutional', subcategoryId: infrastructure ? 'public_realm' : 'sports',
    typeId: type ?? (infrastructure ? 'public_toilet' : 'public_toilet_block'),
    configurationId: infrastructure ? 'support_facility' : 'indoor', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'public_toilet_measured_bank', 'pt_rooms': 3, 'pt_width': 3.2, 'pt_depth': 3.5, 'pt_wall': .2,
    'pt_door': .95, 'pt_gallery': 1.8, 'pt_entry': .9, 'pt_circle': 1.6, 'pt_center': 1.7,
    'pt_wc_x': .25, 'pt_wc_y': 2.65, 'pt_wc_w': .7, 'pt_wc_d': .75,
    'pt_basin_x': 2.4, 'pt_basin_y': 1.1, 'pt_basin_w': .6, 'pt_basin_d': .6,
    'pt_west': 2, 'pt_south': 2, ...edits,
  }));

void main() {
  const widthFt = 16 / .3048, depthFt = 12 / .3048;
  PublicToiletCadResult run(ProjectBrief b) => PublicToiletCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('saved template repeats real openings, clear strips and native circular guides', () {
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('public_toilet_measured_bank')));
    expect(cadOutputOptions(warehouseLoading: false, publicToilet: true).options.map((o) => o.id), contains('public_toilet_measured_bank'));
    final saved = ProjectBrief.fromMap(toilets().toMap())!;
    expect(PublicToiletCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.rooms, r.widthMm, r.depthMm, r.galleryMm, r.circleMm), (3, 10400, 5700, 1800, 1600));
    final d = r.drawing!;
    final openings = d.lines.where((l) => l.layer == 'WC_OPENING').toList();
    final front = d.lines.where((l) => l.layer == 'WC_WALL' && l.start.y == 3800 && l.end.y == 3800);
    expect(front.length, 4);
    for (final opening in openings) {
      expect(front.every((l) => l.end.x <= opening.start.x || l.start.x >= opening.end.x), isTrue);
    }
    expect(openings.map((l) => (l.start.x, l.start.y, l.end.x)), [(3325, 3900, 4275), (6725, 3900, 7675), (10125, 3900, 11075)]);
    final strip = d.lines.where((l) => l.layer == 'WC_ROUTE').take(2).toList();
    expect((strip[0].start.x, strip[0].start.y, strip[0].end.x, strip[1].end.y), (3350, 3800, 4250, 5700));
    expect(d.arcs.length, 6);
    final arc = d.arcs.first;
    expect((arc.layer, arc.center.x, arc.center.y, arc.radius), ('WC_CIRCLE', 3800, 5700, 800));
    expect(d.toDxf(), contains('\r\nARC\r\n8\r\nWC_CIRCLE\r\n'));
  });

  test('exact setback and circle tangency fit; a near diagonal corner is checked radially', () {
    expect(run(toilets(infrastructure: true, edits: {'left_setback': 2, 'right_setback': 3.6, 'front_setback': 2, 'rear_setback': 4.3})).issue, isNull);
    expect(run(toilets(edits: {'pt_wc_y': 2.2})).issue, isNull);
    expect(run(toilets(edits: {'pt_wc_y': 2.15})).issue, contains('WC envelope intrudes'));
    final single = run(toilets(edits: {'pt_rooms': 1}));
    expect((single.rooms, single.widthMm, single.drawing!.arcs.length), (1, 3600, 2));
  });

  test('invalid room, door, fixtures, circle or setbacks stop DXF', () {
    for (final (brief, message) in [
      (toilets(type: 'public_parking'), 'Select Public Toilet'),
      (toilets(edits: {'pt_rooms': 1.5}), 'whole room count'),
      (toilets(edits: {'pt_door': .899}), 'clear entry strip'),
      (toilets(edits: {'pt_door': 3.2}), 'leave wall returns'),
      (toilets(edits: {'pt_center': 2.701}), 'circle does not fit'),
      (toilets(edits: {'pt_basin_x': 2.601}), 'inside the clear room'),
      (toilets(edits: {'pt_wc_x': 2.45, 'pt_wc_y': 1.25}), 'envelopes overlap'),
      (toilets(edits: {'pt_basin_x': 1.15, 'pt_basin_y': .1}), 'overlaps the clear strip'),
      (toilets(edits: {'pt_basin_x': 2.399}), 'basin envelope intrudes'),
      (toilets(edits: {'right_setback': 3.601}), 'right plot edge'),
      (toilets(edits: {'rear_setback': 4.301}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.drawing, isNull);
    }
  });

  testWidgets('preview offers export only when all checks pass', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PublicToiletCadScreen(name: 'Facilities', brief: toilets(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('3 rooms'), findsOneWidget);
    expect(find.text('Share public toilet DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: PublicToiletCadScreen(key: const ValueKey('invalid'), name: 'Facilities',
      brief: toilets(edits: {'pt_basin_x': 2.399}), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('basin envelope intrudes'), findsOneWidget);
    expect(find.text('Share public toilet DXF'), findsNothing);
  });
}
