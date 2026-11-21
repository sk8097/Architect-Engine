import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/stormwater_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/stormwater_cad_screen.dart';
import 'package:architect_engine/services/stormwater_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief drain({Map<String, Object> edits = const {}, String type = 'stormwater_drain',
  String config = 'drainage_system', Map<String, int> spaces = const {}}) => ProjectBrief(
  floorCount: null, parking: null, features: const [], taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: 'infrastructure', subcategoryId: 'water', typeId: type, configurationId: config, spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'drain_cad_mode': 'survey_gravity', 'dr_grid': 'Local survey grid', 'dr_reference': 'BM17',
    'dr_nodes': 'A,345000,2110000,101.5,100;B,345040,2110000,101.2,99.6;C,345070,2110040,100.8,99.1',
    'dr_ground': '65,100.9;20,100.99', 'dr_crown_rise': .55, 'dr_cover': .6, 'dr_min_grade': 1, ...edits,
  }));

void main() {
  final gen = StormwaterCadGenerator();

  test('saved drain renders projected plan, downhill direction and true profile schedule', () {
    final brief = ProjectBrief.fromMap(drain().toMap())!;
    expect(StormwaterCadGenerator.requested(brief), isTrue);
    expect(stormwaterCadMode.options.map((o) => o.id), contains('survey_gravity'));
    final result = gen.generate(brief);
    expect(result.issue, isNull);
    expect(result.reaches.map((r) => r.length), [40000, 50000]);
    expect(result.reaches.map((r) => r.fall), [400, 500]);
    final first = result.reaches.first, second = result.reaches.last;
    expect(first.gradePercent, 1);
    expect(second.gradePercent, 1);
    expect(first.minimumCoverAt, 20000);
    expect(first.minimumCover, closeTo(640, .0001));
    expect(second.minimumCoverAt, 65000);
    expect(second.minimumCover, closeTo(1000, .0001));
    final plan = result.plan!, profile = result.profile!;
    final axes = plan.lines.where((l) => l.layer == 'DRAIN_PLAN_AXIS').toList();
    expect(axes.length, 2);
    expect((axes.first.start.x, axes.first.start.y), (345000000, 2110000000));
    expect((axes.last.end.x, axes.last.end.y), (345070000, 2110040000));
    expect(plan.arcs.where((a) => a.layer == 'DRAIN_NODES').length, 6);
    final arrows = plan.lines.where((l) => l.layer == 'DRAIN_FLOW').toList();
    expect(arrows.length, 4);
    for (var i = 0; i < arrows.length; i++) {
      final a = arrows[i], axis = axes[i ~/ 2];
      final dx = axis.end.x - axis.start.x, dy = axis.end.y - axis.start.y;
      expect((a.end.x - a.start.x) * dx + (a.end.y - a.start.y) * dy, greaterThan(0));
    }
    final invert = profile.lines.where((l) => l.layer == 'DRAIN_INVERT').toList();
    final crown = profile.lines.where((l) => l.layer == 'DRAIN_CROWN').toList();
    final surface = profile.lines.where((l) => l.layer == 'DRAIN_GROUND').toList();
    expect(result.exaggeration, 10);
    expect(invert.length, 2);
    expect(crown.length, 2);
    expect(surface.map((l) => l.end.x), [20000, 40000, 65000, 90000]);
    expect(invert.first.start.y - invert.first.end.y, 4000);
    expect(crown.last.end.y - invert.last.end.y, 5500);
    expect(invert.last.end.x, 90000);
    expect(plan.toDxf(), contains('PROJECTED COORDINATES IN MM'));
    expect(profile.toDxf(), contains('X = CHAINAGE MM / Y = (LEVEL - 98.000 M) x 10 IN MM'));
    expect(profile.labels.map((l) => l.text), contains('CH 90.000'));
  });

  test('true-scale profiles work without intervening samples; the drain is not resized', () {
    final result = gen.generate(drain(type: 'drainage_network', config: 'network', edits: {'dr_ground': '', 'dr_exaggeration': '1'}));
    expect(result.issue, isNull);
    expect(result.reaches.first.minimumCover, 950);
    final invert = result.profile!.lines.where((l) => l.layer == 'DRAIN_INVERT').first;
    final crown = result.profile!.lines.where((l) => l.layer == 'DRAIN_CROWN').first;
    expect(crown.start.y - invert.start.y, 550);
  });

  test('blocked topology, rise or minimum slope, sampled cover and unsupported scope produce no sheets', () {
    for (final (brief, issue) in [
      (drain(type: 'sewerage_network'), 'Select Stormwater Drain'),
      (drain(spaces: {'pumps': 1}), 'one unbranched gravity pipe'),
      (drain(edits: {'dr_nodes': 'A,0,0,101,100;B,20,20,100,99;C,0,20,99,98;D,20,0,98,97'}), 'crosses or overlaps'),
      (drain(edits: {'dr_nodes': 'A,0,0,101,100;B,30,0,100,99;C,15,0,99,98'}), 'doubles back'),
      (drain(edits: {'dr_nodes': 'A,0,0,101,100;a,30,0,100,99'}), 'repeats an ID'),
      (drain(edits: {'dr_nodes': 'A,0,0,101,100;B,30,0,102,100.1', 'dr_ground': ''}), 'must fall downstream'),
      (drain(edits: {'dr_min_grade': 1.01}), 'minimum percentage'),
      (drain(edits: {'dr_cover': .65}), '0.640 m at chainage 20.000 m'),
      (drain(edits: {'dr_ground': '40,99'}), 'distinct from all node stations'),
      (drain(edits: {'dr_ground': '95,99'}), 'in-range chainages'),
    ]) {
      final result = gen.generate(brief);
      expect(result.issue, contains(issue), reason: issue);
      expect(result.plan, isNull);
      expect(result.profile, isNull);
      expect(result.reaches, isEmpty);
    }
  });

  testWidgets('both editable sheets can be selected and blocked runs offer no export', (tester) async {
    await tester.pumpWidget(MaterialApp(home: StormwaterCadScreen(name: 'Gravity run', brief: drain())));
    expect(find.text('Stormwater plan + profile CAD'), findsOneWidget);
    expect(find.text('Share survey plan DXF'), findsOneWidget);
    await tester.tap(find.text('Pipe profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share pipe profile DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: StormwaterCadScreen(key: const ValueKey('blocked'), name: 'Gravity run',
      brief: drain(edits: {'dr_cover': .65}))));
    expect(find.textContaining('below the supplied minimum'), findsOneWidget);
    expect(find.textContaining('DXF'), findsNothing);
  });
}
