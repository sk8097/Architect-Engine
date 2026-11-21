import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/survey_corridor_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/longitudinal_profile_screen.dart';
import 'package:architect_engine/services/longitudinal_profile_generator.dart';
import 'package:architect_engine/services/survey_corridor_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief profile({Map<String, Object> edits = const {}, String type = 'road', Map<String, int> spaces = const {}}) => ProjectBrief(
  floorCount: null, parking: null, features: const [], taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: 'infrastructure', subcategoryId: 'transport', typeId: type, configurationId: 'linear_corridor', spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'corridor_cad_mode': 'survey_profile', 'profile_reference': 'BM12 site datum', 'profile_exaggeration': '5',
    'profile_ground': '500,100;525,102;540,105;550,103;560,104;575,101;600,100',
    'profile_grade': '500,100,0;550,105,40;600,100,0', ...edits,
  }));

void main() {
  final gen = LongitudinalProfileGenerator();

  test('saved profile computes true elevations and signed level differences despite vertical exaggeration', () {
    final saved = ProjectBrief.fromMap(profile().toMap())!;
    expect(LongitudinalProfileGenerator.requested(saved), isTrue);
    expect(SurveyCorridorGenerator.requested(saved), isFalse);
    expect(surveyCorridorMode.options.map((o) => o.id), contains('survey_profile'));
    final result = gen.generate(saved), cad = result.drawing!;
    expect(result.issue, isNull);
    expect(result.exaggeration, 5);
    expect(result.datumMm, 99000);
    expect(result.slopes, [.1, -.1]);
    final c = result.curves.single;
    expect(c.startMm, 530000);
    expect(c.endMm, 570000);
    expect(c.startLevelMm, 103000);
    expect(c.levelAt(c.endMm), closeTo(103000, 1e-6));
    expect(c.extremumMm, 550000);
    expect(c.levelAt(c.extremumMm!), closeTo(104000, 1e-6));
    expect(result.stations.map((s) => s.designMm), [100000, 102500, 103750, 104000, 103750, 102500, 100000]);
    expect(result.stations.map((s) => s.differenceMm), [0, 500, -1250, 1000, -250, 1500, 0]);
    expect(cad.lines.where((l) => l.layer == 'PROFILE_CUT').length, 2);
    expect(cad.lines.where((l) => l.layer == 'PROFILE_FILL').length, 3);
    final fill = cad.lines.singleWhere((l) => l.layer == 'PROFILE_FILL' && l.start.x == 550000);
    expect(fill.end.y - fill.start.y, 5000);
    expect(cad.labels.map((l) => l.text), containsAll(['BVC', 'EVC', 'HIGH', '10.00%', '-10.00%']));
    final dxf = cad.toDxf();
    for (final layer in ['PROFILE_GROUND', 'PROFILE_DESIGN', 'PROFILE_STATIONS', 'PROFILE_CUT', 'PROFILE_FILL', 'PROFILE_CURVE_POINTS']) {
      expect(dxf, contains(layer));
    }
    expect(dxf, contains('X = CHAINAGE MM / Y = (LEVEL - 99.000 M) x 5 IN MM'));
    expect(dxf, contains('BM12 site datum'));
  });

  test('curve chords remain within 5 mm unexaggerated and monotone in chainage', () {
    final result = gen.generate(profile());
    final c = result.curves.single;
    for (final edge in result.drawing!.lines.where((l) => l.layer == 'PROFILE_DESIGN')) {
      expect(edge.end.x, greaterThan(edge.start.x));
      if (edge.start.x < c.startMm || edge.end.x > c.endMm) continue;
      final x = (edge.start.x + edge.end.x) / 2;
      final interpolated = result.datumMm + (edge.start.y + edge.end.y) / (2 * result.exaggeration);
      expect((interpolated - c.levelAt(x)).abs(), lessThanOrEqualTo(5.000001));
    }
  });

  test('true-scale tangents, sag curves, and adjacent curves sharing a tangent point', () {
    final tangent = gen.generate(profile(edits: {'profile_grade': '500,99,0;600,101,0', 'profile_exaggeration': '1'}));
    expect(tangent.issue, isNull);
    expect(tangent.exaggeration, 1);
    expect(tangent.curves, isEmpty);
    expect(tangent.stations[3].designMm, 100000);
    final simulated = gen.generate(profile(edits: {
      'profile_ground': '0,98;25,97;50,100;75,102;100,102',
      'profile_grade': '0,100,0;25,95,50;75,105,50;100,100,0',
    }));
    expect(simulated.issue, isNull);
    final first = simulated.curves.first, last = simulated.curves.last;
    expect(first.endMm, last.startMm);
    expect(first.levelAt(first.endMm), closeTo(last.startLevelMm, .0001));
    expect(simulated.drawing!.labels.map((l) => l.text), containsAll(['LOW', 'HIGH']));
    expect(simulated.drawing!.lines.where((l) => l.layer == 'PROFILE_DESIGN').every((line) => line.end.x > line.start.x), isTrue);
  });

  test('malformed rows, incompatible extents and overlapping curves block output', () {
    for (final (brief, issue) in [
      (profile(type: 'intersection'), 'Select a Road'),
      (profile(spaces: {'footpath': 1}), 'separate Space selections'),
      (profile(edits: {'profile_ground': '500,100;500,102;600,100'}), 'strictly increasing'),
      (profile(edits: {'profile_ground': '500,100;600,100.0001'}), 'three decimals'),
      (profile(edits: {'profile_grade': '500,100,0;599,100,0'}), 'must match the survey limits'),
      (profile(edits: {'profile_grade': '500,100,1;600,100,0'}), 'zero curve length'),
      (profile(edits: {'profile_grade': '500,100,0;535,104,40;565,96,40;600,100,0'}), 'overlaps'),
      (profile(edits: {'profile_grade': '500,100,0;550,101,20;600,102,0'}), 'different entering and leaving grades'),
    ]) {
      final result = gen.generate(brief);
      expect(result.issue, contains(issue), reason: issue);
      expect(result.drawing, isNull);
      expect(result.stations, isEmpty);
    }
  });

  testWidgets('profile preview offers editable DXF only with a valid grade', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LongitudinalProfileScreen(name: 'Road profile', brief: profile())));
    expect(find.text('Longitudinal profile CAD'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Share profile DXF'), 180);
    expect(find.text('Share profile DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: LongitudinalProfileScreen(key: const ValueKey('blocked'), name: 'Road profile',
      brief: profile(edits: {'profile_grade': '500,100,0;599,100,0'}))));
    expect(find.textContaining('must match the survey limits'), findsOneWidget);
    expect(find.text('Share profile DXF'), findsNothing);
  });
}
