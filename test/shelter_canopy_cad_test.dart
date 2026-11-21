import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/shelter_canopy_cad_screen.dart';
import 'package:architect_engine/services/shelter_canopy_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief shelter({Map<String, Object> edits = const {}, String type = 'passenger_shelter'}) => ProjectBrief(
  floorCount: null, features: const [], parking: ProjectParking.none,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'institutional', subcategoryId: 'sports',
    typeId: type, configurationId: 'outdoor', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'shelter_measured_canopy', 'sh_bays': 3, 'sh_pitch': 3.2, 'sh_span': 3.6, 'sh_post': .2,
    'sh_oh_w': 1, 'sh_oh_e': .8, 'sh_oh_end': .6, 'sh_w_z': 3.1, 'sh_e_z': 2.5, 'sh_roof_d': .18,
    'sh_min_walk': 3.4, 'sh_min_head': 2.6, 'sh_min_eave': 2.5, 'sh_west': 2, 'sh_south': 3, ...edits,
  }));

void main() {
  const widthFt = 12 / .3048, depthFt = 18 / .3048;
  ShelterCanopyCadResult run(ProjectBrief b) => ShelterCanopyCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('saved brief repeats post envelopes outside the clear strip and covers them', () {
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('shelter_measured_canopy')));
    expect(cadOutputOptions(warehouseLoading: false, shelterCanopy: true).options.map((o) => o.id), contains('shelter_measured_canopy'));
    final saved = ProjectBrief.fromMap(shelter().toMap())!;
    expect(ShelterCanopyCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.posts, r.widthMm, r.depthMm, r.walkMm, r.eaveMm), (8, 5400, 10800, 3400, 2500));
    expect(r.walkHeadMm, closeTo(2600, 1e-8));
    expect(r.fallPct, closeTo(11.111111111, 1e-8));
    expect(r.roofM2, closeTo(58.678895695, 1e-6));
    final p = r.plan!;
    final posts = p.lines.where((l) => l.layer == 'CANOPY_POST').toList();
    expect(posts.length, 32);
    expect((posts[0].start.x, posts[0].start.y, posts[0].end.x), (2900, 3500, 3100));
    expect((posts[28].start.x, posts[28].start.y, posts[28].end.x), (6500, 13100, 6700));
    final walk = p.lines.firstWhere((l) => l.layer == 'CANOPY_WALK');
    expect((walk.start.x, walk.start.y, walk.end.x), (3100, 3000, 6500));
    expect(p.toDxf(), contains('ROOF 5.400 x 10.800 M'));
  });

  test('true-scale section checks the sloping soffit at the inner post face, not at the eave', () {
    final r = run(shelter(edits: {'left_setback': 2, 'right_setback': 4.6, 'front_setback': 3, 'rear_setback': 4.2, 'max_height': 3.28}));
    expect(r.issue, isNull);
    final s = r.section!;
    final roof = s.lines.where((l) => l.layer == 'CANOPY_ROOF').toList();
    expect((roof[0].start.y, roof[0].end.x, roof[0].end.y, roof[1].start.y, roof[1].end.y), (3100, 5400, 2500, 3280, 2680));
    final head = s.lines.singleWhere((l) => l.layer == 'CANOPY_WALK');
    expect((head.start.x, head.start.y, head.end.x, head.end.y), (1100, 2600, 4500, 2600));
    expect(s.toDxf(), contains('LOW EAVE 2.500 M / MIN WALK HEADROOM 2.600 M'));
    expect(run(shelter(edits: {'sh_oh_w': .1})).issue, isNull);
  });

  test('invalid headroom, eaves, post spacing, setback and supplied height block both sheets', () {
    for (final (brief, message) in [
      (shelter(type: 'bus_terminal'), 'Select Passenger Shelter'),
      (shelter(edits: {'sh_bays': 9}), 'whole number'),
      (shelter(edits: {'sh_pitch': .2}), 'spacing along the rows'),
      (shelter(edits: {'sh_oh_w': .099}), 'cover the full outer post footprints'),
      (shelter(edits: {'sh_min_walk': 3.401}), 'clear walking width'),
      (shelter(edits: {'sh_w_z': 2.5}), 'west soffit must be higher'),
      (shelter(edits: {'sh_min_eave': 2.501}), 'low east eave'),
      (shelter(edits: {'sh_min_head': 2.601}), 'east edge of the clear walking strip'),
      (shelter(edits: {'max_height': 3.279}), 'high roof top exceeds'),
      (shelter(edits: {'rear_setback': 4.201}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('switching sheets exposes the correct export, invalid eave blocks both', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ShelterCanopyCadScreen(name: 'Shelter', brief: shelter(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Share canopy plan DXF'), findsOneWidget);
    await tester.tap(find.text('Transverse section'));
    await tester.pumpAndSettle();
    expect(find.text('Share canopy section DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: ShelterCanopyCadScreen(key: const ValueKey('invalid'), name: 'Shelter',
      brief: shelter(edits: {'sh_min_eave': 2.501}), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('low east eave'), findsOneWidget);
    expect(find.text('Share canopy plan DXF'), findsNothing);
    expect(find.text('Share canopy section DXF'), findsNothing);
  });
}
