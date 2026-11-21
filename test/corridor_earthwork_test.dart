import 'package:architect_engine/data/survey_corridor_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/screens/corridor_earthwork_screen.dart';
import 'package:architect_engine/services/corridor_earthwork_generator.dart';
import 'package:architect_engine/services/corridor_section_generator.dart';
import 'package:architect_engine/services/survey_corridor_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'longitudinal_profile_test.dart' show profile;

const _ground = '100,-6,100;100.000,8,100;110,-6,100;110,8,100;135,-6,100;135,8,100';
const _design = '100,-4,99;100,0,101;100,6,98\n110,-4,101;110,6,101\n135,-4,99;135,6,99';

ProjectBrief takeoff({Map<String, Object> edits = const {}, String type = 'road'}) => profile(type: type, edits: {
  'corridor_cad_mode': 'survey_earthwork', 'ew_reference': 'BM12 local datum',
  'ew_ground': _ground, 'ew_design': _design, 'ew_exaggeration': '5', ...edits,
});

void main() {
  final gen = CorridorEarthworkGenerator();

  test('uneven station intervals use separate average-end areas and retain measured section geometry', () {
    final saved = ProjectBrief.fromMap(takeoff().toMap())!;
    expect(CorridorEarthworkGenerator.requested(saved), isTrue);
    expect(CorridorSectionGenerator.requested(saved), isFalse);
    expect(SurveyCorridorGenerator.requested(saved), isFalse);
    expect(surveyCorridorMode.options.map((o) => o.id), contains('survey_earthwork'));
    final result = gen.generate(saved);
    expect(result.issue, isNull);
    expect(result.sections.map((s) => s.chainageMm), [100000, 110000, 135000]);
    expect(result.sections.map((s) => s.cutM2), [5, 0, 10]);
    expect(result.sections.map((s) => s.fillM2), [2, 10, 0]);
    expect(result.intervals.map((i) => (i.lengthM, i.cutM3, i.fillM3)), [(10, 25, 60), (25, 125, 125)]);
    expect((result.totalCutM3, result.totalFillM3), (150, 185));
    final sameQuantities = gen.generate(takeoff(edits: {'ew_exaggeration': '1'}));
    expect(sameQuantities.toCsv(), result.toCsv());
    final set = result.drawing!;
    final localOriginText = set.labels.where((l) => l.text.startsWith('LOCAL ORIGIN: CL'));
    expect(localOriginText.length, 3);
    expect(localOriginText.every((l) => l.text.endsWith('VERTICAL x 5')), isTrue);
    final ground = set.lines.where((l) => l.layer == 'SECTION_GROUND').toList();
    expect(ground.length, 3);
    expect(ground.every((l) => l.end.x - l.start.x == 14000), isTrue);
    expect(ground[0].end.x, lessThan(ground[1].start.x));
    expect(ground[1].end.x, lessThan(ground[2].start.x));
    final dxf = set.toDxf();
    for (final station in [100, 110, 135]) {
      expect(dxf, contains('CH $station.000 M'));
    }
    final rows = result.toCsv()!.trim().split('\r\n');
    expect(rows.map((r) => r.split(',').length), [10, 10, 10, 10]);
    expect(rows[1], 'interval,100.000,110.000,10.000,5.000,0.000,2.000,10.000,25.000,60.000');
    expect(rows[3], 'total,100.000,135.000,35.000,,,,,150.000,185.000');
  });

  test('station mismatch, invalid points and span errors prevent both exports', () {
    for (final (brief, reason) in [
      (takeoff(type: 'intersection'), 'Select a Road'),
      (takeoff(edits: {'ew_ground': '100,-6,100;100,8,100'}), 'at least two distinct Surveyed chainages'),
      (takeoff(edits: {'ew_design': _design.replaceAll('135,', '140,')}), '135.000 m is missing from the proposed list'),
      (takeoff(edits: {'ew_ground': '110,-6,100;110,8,100;$_ground'}), 'increasing chainage'),
      (takeoff(edits: {'ew_design': _design.replaceFirst('100,-4,99', '100.0001,-4,99')}), 'Proposed row 1'),
      (takeoff(edits: {'ew_ground': _ground.replaceFirst('110,-6,100', '110,-3,100')}), 'Chainage 110.000 m: The ground survey must cover'),
      (takeoff(edits: {'ew_ground': _ground.replaceAll('135,', '20101,'), 'ew_design': _design.replaceAll('135,', '20101,')}), '20 km chainage span'),
    ]) {
      final result = gen.generate(brief);
      expect(result.issue, contains(reason));
      expect(result.drawing, isNull);
      expect(result.toCsv(), isNull);
      expect(result.sections, isEmpty);
    }
  });

  testWidgets('takeoff preview offers both exports and previews a different station', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CorridorEarthworkScreen(name: 'Main road', brief: takeoff())));
    expect(find.text('Estimated cut 150.000 m³ · fill 185.000 m³'), findsOneWidget);
    expect(find.text('Share section-set DXF'), findsOneWidget);
    expect(find.text('Share takeoff CSV'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ch 135.000 m').last);
    await tester.pumpAndSettle();
    expect(find.text('Section cut 10.000 m² · Fill 0.000 m²'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: CorridorEarthworkScreen(key: const ValueKey('invalid'), name: 'Main road',
      brief: takeoff(edits: {'ew_design': _design.replaceAll('135,', '140,')}))));
    expect(find.textContaining('missing from the proposed list'), findsOneWidget);
    expect(find.text('Share section-set DXF'), findsNothing);
    expect(find.text('Share takeoff CSV'), findsNothing);
  });
}
