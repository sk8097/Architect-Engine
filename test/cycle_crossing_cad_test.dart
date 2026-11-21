import 'package:architect_engine/data/cycle_crossing_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/survey_corridor_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/cycle_crossing_cad_screen.dart';
import 'package:architect_engine/services/cycle_crossing_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief track({Map<String, Object> edits = const {}, String type = 'cycle_track'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure',
    subcategoryId: 'transport', typeId: type, configurationId: 'linear_corridor'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'corridor_cad_mode': cycleCrossingMode, 'cyc_grid': 'Example grid', 'cyc_axis': '1000,2000;1060,2080',
    'cyc_side': 'left', 'cyc_limits': '10,7;\n40,6\r\n90,8', 'cyc_buffer': 1.5, 'cyc_width': 3,
    'cyc_margin': 1.5, 'cyc_island': 28, 'cyc_driveways': 'D1,20,26;D2,54,62', ...edits,
  }));

void main() {
  final generator = CycleCrossingCadGenerator();

  test('specialist option is separate from standard corridor modes', () {
    expect(cycleCrossingCadEligible('infrastructure', 'transport', 'cycle_track'), isTrue);
    expect(cycleCrossingCadEligible('infrastructure', 'transport', 'road'), isFalse);
    expect(surveyCorridorMode.options.map((o) => o.id), isNot(contains(cycleCrossingMode)));
    expect(surveyCorridorModeField(includeCycleCrossings: true).options.map((o) => o.id),
      containsAll(['survey_circular', cycleCrossingMode]));
    expect(CycleCrossingCadGenerator.requested(track(edits: {'corridor_cad_mode': 'survey_circular'})), isFalse);
  });

  test('oblique projection, separator breaks, continuous track and driveway quantities', () {
    final saved = ProjectBrief.fromMap(track().toMap())!;
    expect(CycleCrossingCadGenerator.requested(saved), isTrue);
    final r = generator.generate(saved);
    expect(r.issue, isNull);
    expect((r.lengthMm, r.widthMm, r.separatorMm, r.minGapMm, r.minGapStationMm, r.crossingAreaM2),
      (80000, 3000, 66000, 1500, 40000, 42));
    final drawing = r.drawing!;
    final opening = drawing.lines.where((l) => l.layer == 'CYCLE_DRIVEWAY').first;
    expect((opening.start.x, opening.start.y, opening.end.x, opening.end.y), (1012000, 2016000, 1008400, 2018700));
    final separator = drawing.lines.where((l) => l.layer == 'CYCLE_SEPARATOR').toList();
    expect(separator.length, 3);
    expect((separator[0].start.x, separator[0].start.y, separator[0].end.x, separator[0].end.y),
      (1005400, 2008450, 1011400, 2016450));
    expect(drawing.lines.where((l) => l.layer == 'CYCLE_TRACK').length, 4);
    expect(drawing.toDxf(), contains('MIN ROADSIDE GAP 1.500 M AT CH 40.000 M'));
    expect(r.toCsv(), contains('D2,54.000,62.000,8.000,24.000000\r\n'));
    final right = generator.generate(track(edits: {'cyc_side': 'right'})).drawing!;
    final reflected = right.lines.firstWhere((l) => l.layer == 'CYCLE_DRIVEWAY').end;
    expect((reflected.x, reflected.y), (1015600, 2013300));
  });

  test('boundary driveways avoid drawing duplicate track ends or zero-length separator', () {
    final r = generator.generate(track(edits: {'cyc_driveways': 'D1,10,20;D2,80,90'}));
    expect(r.issue, isNull);
    expect(r.drawing!.lines.where((l) => l.layer == 'CYCLE_TRACK').length, 2);
    expect(r.drawing!.lines.where((l) => l.layer == 'CYCLE_SEPARATOR').length, 1);
  });

  test('invalid surveys and driveway spacing block both exports with a reason', () {
    for (final (brief, reason) in [
      (track(type: 'road'), 'Select Cycle Track'),
      (track(edits: {'cyc_margin': 1.501}), 'at Ch 40.000 m'),
      (track(edits: {'cyc_limits': '10,7;10,7;90,7'}), 'strictly increase'),
      (track(edits: {'cyc_limits': '0,7;100.001,7'}), 'within the surveyed A–B length'),
      (track(edits: {'cyc_driveways': 'D1,9,12'}), 'within the surveyed track chainages'),
      (track(edits: {'cyc_driveways': 'D1,20,26;D2,25,30'}), 'overlaps or is out of order'),
      (track(edits: {'cyc_driveways': 'D1,20,26;D2,53.999,62'}), 'only 27.999 m of separator'),
      (track(edits: {'cyc_driveways': 'D1,20,26;d1,54,62'}), 'is repeated'),
      (track(edits: {'cyc_driveways': '=1,20,26'}), 'starting with a letter or number'),
    ]) {
      final r = generator.generate(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid preview offers DXF and CSV; failed fit hides both', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CycleCrossingCadScreen(name: 'Cycle track', brief: track())));
    expect(find.text('Share cycle track DXF'), findsOneWidget);
    expect(find.text('Share driveway schedule CSV'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: CycleCrossingCadScreen(key: const ValueKey('invalid'), name: 'Cycle track',
      brief: track(edits: {'cyc_margin': 1.501}))));
    expect(find.textContaining('at Ch 40.000 m'), findsOneWidget);
    expect(find.text('Share cycle track DXF'), findsNothing);
    expect(find.text('Share driveway schedule CSV'), findsNothing);
  });
}
