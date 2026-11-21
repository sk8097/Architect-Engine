import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/switchback_ramp_screen.dart';
import 'package:architect_engine/services/switchback_ramp_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief ramp({Map<String, Object> edits = const {}, String type = 'public_park',
  Map<String,int> spaces = const {}}) => ProjectBrief(floorCount: 0, parking: ProjectParking.none, features: const [],
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'public_realm',
    typeId: type, configurationId: 'public_open_space', plotShapeId: 'rectangular', spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'measured_switchback', 'sr_datum': 'BM1 survey', 'sr_floor': 100, 'sr_mid': 100.48, 'sr_top': 101.04,
    'sr_run': 8, 'sr_width': 1.8, 'sr_divider': .25, 'sr_end_depth': 2, 'sr_turn_depth': 2.2, 'sr_left': 3, 'sr_front': 2.5,
    'sr_min_clear': 1.8, 'sr_min_landing': 1.5, 'sr_max_rise': .56, 'sr_max_grade': 7, ...edits,
  }));

void main() {
  SwitchbackRampResult run(ProjectBrief brief, [String facing = 'South']) => SwitchbackRampGenerator().generate(brief,
    widthFt: 20 / .3048, depthFt: 25 / .3048, facing: facing);

  test('two independent grades, flat landings and centreline chainage survive export', () {
    final saved = ProjectBrief.fromMap(ramp().toMap())!;
    expect(SwitchbackRampGenerator.requested(saved), isTrue);
    expect(cadOutputOptions(warehouseLoading: false, switchbackRamp: true).options.map((o) => o.id), contains('measured_switchback'));
    for (final facing in ['South','North','East','West']) {
      final result = run(saved, facing);
      expect(result.issue, isNull, reason: facing);
      expect(result.flights.map((f) => (f.riseMm,f.gradePercent)), [(480,6),(560,7)]);
      expect(result.walkMm, 24250);
      final plan = result.plan!, profile = result.profile!;
      final path = plan.lines.where((l) => l.layer == 'RAMP_PATH').take(3).toList();
      expect((path[0].end.x,path[0].end.y), (path[1].start.x,path[1].start.y));
      expect((path[1].end.x,path[1].end.y), (path[2].start.x,path[2].start.y));
      expect(path.fold<num>(0,(n,l) => n + (l.end.x-l.start.x).abs() + (l.end.y-l.start.y).abs()), 24250);
      final clear = plan.lines.where((line) => line.layer == 'RAMP_CLEAR').toList();
      expect(clear.length, 12);
      expect(clear.every((l) => (l.end.x-l.start.x).abs()+(l.end.y-l.start.y).abs() == 1500), isTrue);
      final plot = plan.lines.where((l) => l.layer == 'RAMP_PLOT').expand((l) => [l.start,l.end]);
      expect(plot.map((p) => p.x).reduce(math.max), facing == 'East' || facing == 'West' ? 25000 : 20000);
      expect(profile.lines.map((l) => (l.start.x,l.start.y,l.end.x,l.end.y)).toList(), [
        (0,0,2000,0),(2000,0,10000,480),(10000,480,14250,480),(14250,480,22250,1040),(22250,1040,24250,1040),
      ]);
      for (final name in ['RAMP_SEPARATOR','RAMP_CLEAR','RAMP_PATH','RAMP_FLIGHT','RAMP_LANDING']) {
        expect(plan.toDxf(), contains(name));
      }
      expect(profile.toDxf(), contains('X = WALK CHAINAGE MM / Y = LEVEL ABOVE 100.000 M IN MM'));
    }
  });

  test('signed levels and zero separator are valid with the same slopes', () {
    final result = run(ramp(edits: {'sr_floor': -1, 'sr_mid': -.52, 'sr_top': .04, 'sr_divider': 0}));
    expect(result.issue, isNull);
    expect(result.walkMm, 24000);
    expect(result.plan!.lines.where((l) => l.layer == 'RAMP_SEPARATOR'), isEmpty);
    expect(result.flights.map((f) => f.gradePercent), [6,7]);
  });

  test('missing clearance, a steep flight, an excessive rise or a setback conflict block both DXFs', () {
    for (final (brief, issue) in [
      (ramp(type: 'public_toilet'), 'Select a Public Park'),
      (ramp(spaces: {'accessible_route':1}), 'separate Space selections'),
      (ramp(edits: {'sr_min_clear': 1.801}), 'minimum clear width'),
      (ramp(edits: {'sr_turn_depth': 1.49}), 'turning square does not fit'),
      (ramp(edits: {'sr_mid': 100}), 'Levels must increase'),
      (ramp(edits: {'sr_max_rise': .559}), 'Flight 2 rise'),
      (ramp(edits: {'sr_max_grade': 6.999}), 'Flight 2 slope'),
      (ramp(edits: {'sr_run': 30}), 'rear plot edge'),
      (ramp(edits: {'left_setback': 3.001}), 'left plot edge'),
    ]) {
      final result = run(brief);
      expect(result.issue, contains(issue));
      expect(result.plan, isNull);
      expect(result.profile, isNull);
    }
  });

  testWidgets('plan and profile toggle and blocked schedule hides export', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SwitchbackRampScreen(name: 'Park path', brief: ramp(),
      widthFt: 66, depthFt: 83, facing: 'East')));
    expect(find.text('Horizontal route length 24.250 m · Total rise 1.040 m'), findsOneWidget);
    expect(find.text('Share ramp plan DXF'), findsOneWidget);
    await tester.tap(find.text('Unfolded profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share ramp profile DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: SwitchbackRampScreen(key: const ValueKey('blocked'), name: 'Park path',
      brief: ramp(edits: {'sr_max_grade': 6}), widthFt: 66, depthFt: 83, facing: 'East')));
    expect(find.textContaining('Flight 2 slope'), findsOneWidget);
    expect(find.text('Share ramp plan DXF'), findsNothing);
    expect(find.text('Share ramp profile DXF'), findsNothing);
  });
}
