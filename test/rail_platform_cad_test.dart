import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/rail_platform_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/rail_platform_cad_screen.dart';
import 'package:architect_engine/services/rail_platform_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief platform({Map<String, Object> edits = const {}, String type = 'railway_station'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'transport',
    typeId: type, configurationId: 'node_interchange'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'rail_platform_mode': 'survey_side_platform', 'rp_grid': 'Projected example', 'rp_datum': 'Survey datum A',
    'rp_axis': '500000,2000000;500096,2000128', 'rp_levels': '20,100,100.95;\n60,100.2,101.1\r\n120,100.4,101.4',
    'rp_side': 'left', 'rp_offset': 1.8, 'rp_min_offset': 1.8, 'rp_width': 6, 'rp_edge_band': .8, 'rp_back_band': 1,
    'rp_walk_min': 4.2, 'rp_crossfall': 2, 'rp_rise_min': .9, 'rp_rise_max': 1, 'rp_grade_max': .5, ...edits,
  }));

void main() {
  RailPlatformCadResult run(ProjectBrief b) => RailPlatformCadGenerator().generate(b);

  test('opt-in survives saving; oblique projected track, orthogonal platform edges and cut', () {
    expect(railPlatformCadEligible('infrastructure', 'transport', 'railway_station'), isTrue);
    expect(railPlatformCadEligible('infrastructure', 'transport', 'bus_terminal'), isFalse);
    final saved = ProjectBrief.fromMap(platform().toMap())!;
    expect(RailPlatformCadGenerator.requested(saved), isTrue);
    expect(RailPlatformCadGenerator.requested(platform(edits: {'rail_platform_mode': 'other'})), isFalse);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.lengthMm, r.walkMm, r.offsetMm, r.cutMm, r.minRiseMm, r.maxRiseMm), (100000, 4200, 1800, 60000, 900, 1000));
    expect(r.maxGrade, .5);
    final p = r.plan!;
    final edge = p.lines.firstWhere((l) => l.layer == 'RAIL_EDGE');
    expect((edge.start.x, edge.start.y, edge.end.x, edge.end.y), (500010560, 2000017080, 500070560, 2000097080));
    final cut = p.lines.singleWhere((l) => l.layer == 'RAIL_CUT');
    expect((cut.start.x, cut.start.y, cut.end.x, cut.end.y), (500036000, 2000048000, 500029760, 2000052680));
    expect(p.toDxf(), contains('CH 20.000 TO 120.000 M / LEFT OF A-B'));
    final right = run(platform(type: 'metro_station', edits: {'rp_side': 'right'}));
    final reflected = right.plan!.lines.firstWhere((l) => l.layer == 'RAIL_EDGE');
    expect((reflected.start.x, reflected.start.y), (500013440, 2000014920));
  });

  test('cross-section preserves true scale and signed rail-relative levels', () {
    final r = run(platform());
    final s = r.section!;
    final walk = s.lines.singleWhere((l) => l.layer == 'RAIL_WALK');
    expect((walk.start.x, walk.start.y, walk.end.x, walk.end.y), (2600, 884, 6800, 800));
    final reserves = s.lines.where((l) => l.layer == 'RAIL_EDGE').toList();
    expect((reserves.first.start.x, reserves.first.start.y, reserves.last.end.x, reserves.last.end.y), (1800, 900, 7800, 780));
    expect(s.toDxf(), contains('RAIL REF RL 100.200 M = ZERO / EDGE RL 101.100 M'));
    final signed = run(platform(edits: {'rp_levels': '0,-20,-20.1;160,-20,-20.2', 'rp_rise_min': -.2, 'rp_rise_max': -.1,
      'rp_crossfall': 0, 'rp_back_band': 0}));
    expect(signed.issue, isNull);
    expect((signed.minRiseMm, signed.maxRiseMm, signed.cutMm), (-200, -100, 160000));
    expect(signed.section!.lines.where((l) => l.layer == 'RAIL_EDGE').length, 1);
  });

  test('invalid surveys, widths, offset, level band and grade block both exports', () {
    for (final (brief, message) in [
      (platform(type: 'bus_terminal'), 'Select Railway Station'),
      (platform(edits: {'rp_axis': '0,0;0,0'}), 'positive'),
      (platform(edits: {'rp_levels': '60,100,100.9;60,100,100.9'}), 'strictly increase'),
      (platform(edits: {'rp_levels': '20,100,100.9;160.001,100,100.9'}), 'within the A–B'),
      (platform(edits: {'rp_levels': '20.0001,100,100.9;120,100,100.9'}), 'three decimal places'),
      (platform(edits: {'rp_min_offset': 1.801}), 'minimum static track offset'),
      (platform(edits: {'rp_walk_min': 4.201}), 'clear width'),
      (platform(edits: {'rp_rise_min': 1.001}), 'cannot exceed'),
      (platform(edits: {'rp_rise_max': .999}), 'At Ch 120.000 m'),
      (platform(edits: {'rp_grade_max': .499}), 'Between Ch 60.000 and 120.000 m'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('preview switches to the transverse section and withholds exports after failed fit', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RailPlatformCadScreen(name: 'Platform', brief: platform())));
    expect(find.text('Share platform plan DXF'), findsOneWidget);
    await tester.tap(find.text('Transverse section'));
    await tester.pumpAndSettle();
    expect(find.text('Share platform section DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: RailPlatformCadScreen(key: const ValueKey('invalid'), name: 'Platform',
      brief: platform(edits: {'rp_min_offset': 1.801}))));
    expect(find.textContaining('minimum static track offset'), findsOneWidget);
    expect(find.text('Share platform plan DXF'), findsNothing);
    expect(find.text('Share platform section DXF'), findsNothing);
  });
}
