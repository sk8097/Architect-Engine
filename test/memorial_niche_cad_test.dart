import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/memorial_niche_cad_screen.dart';
import 'package:architect_engine/services/memorial_niche_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief memorial({Map<String, Object> edits = const {}, String type = 'cemetery_memorial_landscape'}) => ProjectBrief(
  floorCount: null, features: const [], parking: ProjectParking.none,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'public_realm',
    typeId: type, configurationId: 'public_open_space', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'memorial_niche_walls', 'mn_panels': 3, 'mn_faces': '2', 'mn_columns': 8, 'mn_tiers': 4,
    'mn_width': .36, 'mn_height': .32, 'mn_depth': .4, 'mn_web': .06, 'mn_frame': .12, 'mn_core': .16,
    'mn_plinth': .3, 'mn_gap': .5, 'mn_ends': 1.2, 'mn_south_strip': 1.8, 'mn_north_strip': 1.5,
    'mn_west': 2, 'mn_south': 3, 'mn_target': 192, ...edits,
  }));

void main() {
  const widthFt = 20 / .3048, depthFt = 10 / .3048;
  MemorialNicheCadResult run(ProjectBrief b) => MemorialNicheCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('opt-in and capacity persist; opposing pockets leave the exact central spine', () {
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('memorial_niche_walls')));
    expect(cadOutputOptions(warehouseLoading: false, memorialNiche: true).options.map((o) => o.id), contains('memorial_niche_walls'));
    final saved = ProjectBrief.fromMap(memorial().toMap())!;
    expect(MemorialNicheCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.capacity, r.panelWidthMm, r.panelDepthMm, r.panelHeightMm), (192, 3540, 960, 2000));
    expect((r.bankWidthMm, r.bankDepthMm), (14020, 4260));
    final p = r.plan!;
    final walls = p.lines.where((l) => l.layer == 'NICHE_WALL').toList();
    expect(walls.length, 12);
    expect((walls[0].start.x, walls[0].start.y, walls[0].end.x, walls[4].start.x), (3200, 4800, 6740, 7240));
    final pockets = p.lines.where((l) => l.layer == 'NICHE_POCKET').toList();
    expect(pockets.length, 144);
    expect((pockets[0].start.x, pockets[0].start.y, pockets[0].end.y), (3320, 4800, 5200));
    expect((pockets[3].start.x, pockets[3].start.y, pockets[3].end.y), (3320, 5760, 5360));
    expect(p.toDxf(), contains('192 NOMINAL NICHES'));
  });

  test('typical elevation shows one true-scale grid and exact setback/height equality fits', () {
    final r = run(memorial(edits: {'left_setback': 2, 'right_setback': 3.98, 'front_setback': 3, 'rear_setback': 2.74, 'max_height': 2}));
    expect(r.issue, isNull);
    final e = r.elevation!;
    final openings = e.lines.where((l) => l.layer == 'NICHE_OPENING').toList();
    expect(openings.length, 4 * 32);
    expect((openings[0].start.x, openings[0].start.y, openings[0].end.x), (120, 420, 480));
    expect((openings[124].start.x, openings[124].start.y, openings[125].end.y), (3060, 1560, 1880));
    expect(e.toDxf(), contains('BOTH FACES IDENTICAL'));
    expect(e.toDxf(), contains('TRUE SCALE MM'));
  });

  test('single south face uses a rear reserve and no zero-height plinth line', () {
    final r = run(memorial(edits: {'mn_panels': 1, 'mn_faces': '1', 'mn_plinth': 0, 'mn_gap': 0, 'mn_target': 0}));
    expect((r.issue, r.capacity, r.panelDepthMm, r.panelHeightMm, r.bankWidthMm), (null, 32, 560, 1700, 5940));
    expect(r.plan!.lines.where((l) => l.layer == 'NICHE_POCKET').length, 24);
    expect(r.plan!.lines.where((l) => l.layer == 'NICHE_REAR').length, 4);
    expect(r.elevation!.lines.where((l) => l.layer == 'NICHE_PLINTH'), isEmpty);
  });

  test('unsupported type, invalid gaps, excess height and short capacity block both sheets', () {
    for (final (brief, message) in [
      (memorial(type: 'public_garden'), 'Select Cemetery'),
      (memorial(edits: {'mn_columns': 8.5}), 'valid whole'),
      (memorial(edits: {'mn_gap': 0}), 'positive gap'),
      (memorial(edits: {'mn_panels': 1}), 'zero panel gap'),
      (memorial(edits: {'max_height': 1.999}), 'height limit'),
      (memorial(edits: {'right_setback': 3.981}), 'right plot edge'),
      (memorial(edits: {'rear_setback': 2.741}), 'rear plot edge'),
      (memorial(edits: {'mn_faces': '1'}), '96 nominal niches'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.plan, isNull);
      expect(r.elevation, isNull);
    }
  });

  testWidgets('switches export sheet and withholds both for an invalid saved brief', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MemorialNicheCadScreen(name: 'Memorial', brief: memorial(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('192 nominal niches'), findsOneWidget);
    expect(find.text('Share niche plan DXF'), findsOneWidget);
    await tester.tap(find.text('Typical elevation'));
    await tester.pumpAndSettle();
    expect(find.text('Share niche elevation DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: MemorialNicheCadScreen(key: const ValueKey('invalid'), name: 'Memorial',
      brief: memorial(edits: {'mn_target': 193}), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('supplied target of 193'), findsOneWidget);
    expect(find.text('Share niche plan DXF'), findsNothing);
    expect(find.text('Share niche elevation DXF'), findsNothing);
  });
}
