import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/football_pitch_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/football_pitch_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/football_pitch_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief pitch({Map<String, Object> edits = const {}, String type = 'sports_complex', String setting = 'outdoor'}) =>
  ProjectBrief(floorCount: null, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'institutional', subcategoryId: 'sports',
      typeId: type, configurationId: setting, actionId: 'site_development', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': footballPitchMode, 'fp_w': 68, 'fp_l': 105, 'fp_mouth': 7.32, 'fp_goal_w': 18.32,
      'fp_goal_d': 5.5, 'fp_pen_w': 40.32, 'fp_pen_d': 16.5, 'fp_spot': 11, 'fp_arc': 9.15, 'fp_centre': 9.15,
      'fp_corner': 1, 'fp_side_run': 3, 'fp_end_run': 5, 'fp_side_min': 3, 'fp_end_min': 5,
      'fp_west': 4, 'fp_south': 4, 'left_setback': 4, 'right_setback': 4, 'front_setback': 4, 'rear_setback': 4,
      ...edits,
    }));

void main() {
  const widthFt = 82 / .3048, depthFt = 123 / .3048;
  FootballPitchCadResult run(ProjectBrief b) => FootballPitchCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('football pitch is opt-in for eligible sports sites and excludes swimming pools', () {
    expect(footballPitchCadEligible('institutional', 'sports', 'sports_complex'), isTrue);
    expect(footballPitchCadEligible('institutional', 'sports', 'swimming_pool'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(footballPitchMode)));
    expect(cadOutputOptions(warehouseLoading: false, footballPitch: true).options.map((o) => o.id), containsAll([...ordinary, footballPitchMode]));
  });

  test('saved geometry clips arcs to the penalty fronts and marks only once along each end line', () {
    final saved = ProjectBrief.fromMap(pitch().toMap())!;
    expect(FootballPitchCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm), (74000, 115000));
    final plan = r.drawing!;
    final mouth = plan.lines.where((l) => l.layer == 'FP_MOUTH').toList();
    expect(mouth.map((l) => (l.start.x, l.end.x, l.start.y)), [(37340, 44660, 9000), (37340, 44660, 114000)]);
    final penalty = plan.arcs.where((arc) => arc.layer == 'FP_PENALTY').toList();
    expect(penalty.length, 2);
    expect((penalty.first.center.x, penalty.first.center.y, penalty.last.center.y, penalty.first.radius), (41000, 20000, 103000, 9150));
    expect(penalty.first.start, closeTo(36.948210733, 1e-8));
    for (var i = 0; i < penalty.length; i++) {
      final arc = penalty[i];
      for (final angle in [arc.start, arc.end]) {
        expect(arc.center.y + arc.radius * math.sin(angle * math.pi / 180), closeTo(i == 0 ? 25500 : 97500, 1e-8));
      }
    }
    expect(plan.arcs.where((a) => a.layer == 'FP_CORNER').map((a) => (a.start, a.end)), [(0, 90), (90, 180), (180, 270), (270, 360)]);
    expect(plan.arcs.where((a) => a.layer == 'FP_CENTRE').length, 2);
    expect(plan.toDxf(), contains('RUN-OFF ENVELOPE 74.000 x 115.000 M'));
    expect(r.markingMm['perimeter'], 346000);
    expect(r.markingMm['goal_areas'], 58640);
    expect(r.markingMm['penalty_areas'], 146640);
    expect(r.totalMarkingMm, closeTo(716943.3101901111, 1e-6));
    expect(r.toCsv(), contains('centre_circle,57.491\r\npenalty_arcs,33.889\r\ncorner_arcs,6.283\r\ntotal,716.943\r\n'));
  });

  test('scope, arc, mark nesting and run-off conflicts block both exports', () {
    for (final (brief, reason) in [
      (pitch(type: 'swimming_pool'), 'eligible sports facility'),
      (pitch(setting: 'indoor'), 'Outdoor'),
      (pitch(edits: {'fp_mouth': 18.32}), 'goal-mouth width'),
      (pitch(edits: {'fp_spot': 5.5}), 'beyond the goal area'),
      (pitch(edits: {'fp_arc': 5.5}), 'extends beyond'),
      (pitch(edits: {'fp_arc': 22}), 'strictly between'),
      (pitch(edits: {'fp_centre': 33}), 'clear of both penalty arcs'),
      (pitch(edits: {'fp_corner': 14}), 'corner arcs must stay clear'),
      (pitch(edits: {'fp_w': 40, 'fp_l': 40, 'fp_mouth': 1, 'fp_goal_w': 2, 'fp_pen_w': 3,
        'fp_goal_d': 1, 'fp_spot': 2, 'fp_pen_d': 3, 'fp_arc': 1.2, 'fp_centre': 16, 'fp_corner': 15}), 'clear of the corner arcs'),
      (pitch(edits: {'fp_side_run': 2.999}), 'submitted minimum'),
      (pitch(edits: {'rear_setback': 4.001}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid mode previews both export options', (tester) async {
    await tester.pumpWidget(MaterialApp(home: FootballPitchCadScreen(name: 'Pitch', brief: pitch(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('716.943 m of marking centrelines'), findsOneWidget);
    expect(find.text('Share pitch plan DXF'), findsOneWidget);
    expect(find.text('Share marking schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved run-off conflict without generic fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'pitch', name: 'Pitch conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: pitch(edits: {'fp_end_min': 5.001}));
    SharedPreferences.setMockInitialValues({'ae_projects_v1': [p.toJson()]});
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ], child: const MaterialApp(home: ProjectsScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Concept zoning CAD'), findsNothing);
    await tester.tap(find.text('Football pitch CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Increase the touchline or end-line run-off'), findsOneWidget);
    expect(find.text('Share pitch plan DXF'), findsNothing);
    expect(find.text('Share marking schedule CSV'), findsNothing);
  });
}
