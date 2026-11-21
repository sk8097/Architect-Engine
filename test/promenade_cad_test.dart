import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/promenade_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/promenade_cad_screen.dart';
import 'package:architect_engine/services/promenade_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief promenade({Map<String, Object> edits = const {}, String type = 'waterfront_promenade'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'public_realm',
    typeId: type, configurationId: 'linear_corridor'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'promenade_mode': 'survey_promenade', 'pmr_grid': 'Example projected grid', 'pmr_axis': '1000,2000;1060,2080',
    'pmr_land_side': 'left', 'pmr_limits': '10,-1,13;\n40,2,12\r\n70,0,11;100,-2,14',
    'pmr_path': 5, 'pmr_width': 3, 'pmr_shore_gap': 2, 'pmr_inland_gap': 3,
    'pmr_pads': 'L1,20,55,1;L2,75,90,2', ...edits,
  }));

void main() {
  PromenadeCadResult run(ProjectBrief b) => PromenadeCadGenerator().generate(b);

  test('oblique projected offsets persist and the plan leaves pad mouths open', () {
    expect(promenadeCadEligible('infrastructure', 'public_realm', 'waterfront_promenade'), isTrue);
    expect(promenadeCadEligible('infrastructure', 'public_realm', 'greenway'), isFalse);
    final saved = ProjectBrief.fromMap(promenade().toMap())!;
    expect(PromenadeCadGenerator.requested(saved), isTrue);
    expect(PromenadeCadGenerator.requested(promenade(edits: {'promenade_mode': 'other'})), isFalse);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.lengthMm, r.widthMm, r.pathAreaM2, r.padAreaM2, r.minShoreMm, r.minInlandMm), (90000, 3000, 270, 65, 2000, 3000));
    final drawing = r.drawing!;
    final pad = drawing.lines.where((l) => l.layer == 'PROM_PAD').toList();
    expect(pad.length, 6);
    expect((pad[1].start.x, pad[1].start.y, pad[1].end.x, pad[1].end.y), (1008800, 2018400, 1029800, 2046400));
    expect(drawing.lines.where((l) => l.layer == 'PROM_PATH').length, 6);
    expect(r.pads[1].minShoreMm, closeTo(3333.333333333, 1e-8));
    expect(r.toCsv(), contains('L2,75.000000,90.000000,2.000000,3.333333,30.000000\r\n'));
    expect(drawing.toDxf(), contains('MIN SHORE GAP 2.000 M / MIN INLAND GAP 3.000 M / BASELINE-NORMAL'));
    final right = run(promenade(edits: {'pmr_land_side': 'right'}));
    final reflected = right.drawing!.lines.where((l) => l.layer == 'PROM_PAD').toList()[1];
    expect((reflected.start.x, reflected.start.y), (1015200, 2013600));
  });

  test('touching equal-depth pads do not duplicate a shared edge; signed offsets can be negative', () {
    final touching = run(promenade(edits: {'pmr_pads': 'A,10,30,1;B,30,40,1'}));
    expect(touching.issue, isNull);
    expect(touching.drawing!.lines.where((l) => l.layer == 'PROM_PAD').length, 4);
    final signed = run(promenade(edits: {'pmr_limits': '0,-13,-1;100,-12,-1', 'pmr_path': -8, 'pmr_pads': 'A,0,100,2'}));
    expect(signed.issue, isNull);
    expect((signed.minShoreMm, signed.minInlandMm), (2000, 4000));
  });

  test('checks path at samples and pads at both interpolated ends and internal knots', () {
    for (final (brief, message) in [
      (promenade(type: 'greenway'), 'Select Waterfront Promenade'),
      (promenade(edits: {'pmr_limits': '10,0,13;10,0,13'}), 'strictly increase'),
      (promenade(edits: {'pmr_limits': '10,-1,13;100.001,0,13'}), 'within the A–B'),
      (promenade(edits: {'pmr_limits': '10,14,13;100,0,13'}), 'shoreward of the inland'),
      (promenade(edits: {'pmr_path': 3.999}), 'path does not leave the supplied baseline-normal'),
      (promenade(edits: {'pmr_width': 3.001}), 'path does not leave the supplied inland gap'),
      (promenade(edits: {'pmr_pads': 'L1,20,55,1.001'}), 'Pad L1 does not leave the supplied shoreline gap at Ch 40.000'),
      (promenade(edits: {'pmr_pads': 'L2,75,90,3.334'}), 'Pad L2 does not leave the supplied shoreline gap at Ch 75.000'),
      (promenade(edits: {'pmr_pads': 'L1,20,55,1;L2,54,90,1'}), 'overlap with the preceding pad'),
      (promenade(edits: {'pmr_pads': 'L1,20,55,1;l1,75,90,1'}), 'is repeated'),
      (promenade(edits: {'pmr_pads': 'L1,9,55,1'}), 'within the surveyed path chainages'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid preview offers DXF and CSV and a failed pad shows a specific reason', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PromenadeCadScreen(name: 'Promenade', brief: promenade())));
    expect(find.text('Share promenade DXF'), findsOneWidget);
    expect(find.text('Share lookout schedule CSV'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: PromenadeCadScreen(key: const ValueKey('invalid'), name: 'Promenade',
      brief: promenade(edits: {'pmr_pads': 'L1,20,55,1.001'}))));
    expect(find.textContaining('at Ch 40.000'), findsOneWidget);
    expect(find.text('Share promenade DXF'), findsNothing);
    expect(find.text('Share lookout schedule CSV'), findsNothing);
  });
}
