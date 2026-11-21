import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/skate_transition_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/skate_transition_cad_screen.dart';
import 'package:architect_engine/services/skate_transition_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief transition({Map<String, Object> edits = const {}, String type = 'public_park'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'public_realm',
    typeId: type, configurationId: 'public_open_space', actionId: 'concept_design', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': skateTransitionMode, 'st_r': 3, 'st_rise': 1.2, 'st_angle': 54, 'st_width': 4,
    'st_runin': 4, 'st_min_runin': 4, 'st_deck': 1.8, 'st_min_deck': 1.8, 'st_side': .75, 'st_end': 1,
    'st_west': 2, 'st_south': 2, 'left_setback': 2, 'right_setback': 2, 'front_setback': 2, 'rear_setback': 3, ...edits,
  }));

void main() {
  const widthFt = 9.5 / .3048, depthFt = 15.2 / .3048;
  SkateTransitionCadResult run(ProjectBrief b) => SkateTransitionCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('opt-in preserves the park fence and playground clearance choices', () {
    expect(skateTransitionCadEligible('infrastructure', 'public_realm', 'public_park'), isTrue);
    expect(skateTransitionCadEligible('infrastructure', 'public_realm', 'playground'), isTrue);
    expect(skateTransitionCadEligible('infrastructure', 'public_realm', 'public_garden'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false, playground: true, parkFence: true).options.map((o) => o.id);
    expect(ordinary, isNot(contains(skateTransitionMode)));
    expect(cadOutputOptions(warehouseLoading: false, playground: true, parkFence: true, skateTransition: true).options.map((o) => o.id),
      containsAll([...ordinary, skateTransitionMode]));
  });

  test('saved profile joins the flat run-in tangentially and reaches the exact deck lip', () {
    final saved = ProjectBrief.fromMap(transition().toMap())!;
    expect(SkateTransitionCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.riseMm, r.curveRunMm), (5500, 10200, 1200, 2400));
    expect(r.lipAngle, closeTo(53.130102354, 1e-8));
    expect(r.curveLengthMm, closeTo(2781.885654, 1e-6));
    final plan = r.plan!, profile = r.profile!;
    final breaks = plan.lines.where((l) => l.layer == 'ST_BREAK');
    expect(breaks.map((l) => (l.start.x, l.start.y, l.end.x)), [(2750, 7000, 6750), (2750, 9400, 6750)]);
    final arc = profile.arcs.single;
    expect((arc.layer, arc.center.x, arc.center.y, arc.radius, arc.start), ('ST_CURVE', 4000, 3000, 3000, 270));
    final flat = profile.lines.singleWhere((l) => l.layer == 'ST_FLAT');
    final deck = profile.lines.singleWhere((l) => l.layer == 'ST_DECK');
    expect((flat.end.x, flat.end.y, deck.start.x, deck.start.y, deck.end.x), (4000, 0, 6400, 1200, 8200));
    final radians = arc.end * math.pi / 180;
    expect(arc.center.x + arc.radius * math.cos(radians), closeTo(deck.start.x, 1e-8));
    expect(arc.center.y + arc.radius * math.sin(radians), closeTo(deck.start.y, 1e-8));
    expect(plan.toDxf(), contains('FULL RESERVE ENVELOPE 5.500 x 10.200 M'));
    expect(profile.toDxf(), contains('ARC LENGTH 2.782 M'));
  });

  test('exact quarter-circle and unrounded plot fit limits', () {
    final quarter = run(transition(edits: {'st_r': 2.4, 'st_rise': 2.4, 'st_angle': 90}));
    expect((quarter.issue, quarter.curveRunMm, quarter.lipAngle), (null, 2400, 90));
    expect(quarter.profile!.arcs.single.end, 360);
    expect(run(transition(edits: {'st_rise': 1.201})).issue, contains('rear plot edge'));
    final fractional = run(transition(edits: {'st_rise': 1.201, 'rear_setback': 2.999}));
    expect(fractional.issue, isNull);
    expect(fractional.curveRunMm, inExclusiveRange(2400, 2401));
  });

  test('invalid scope, radius, angle, flats or fit suppress both exports', () {
    for (final (brief, reason) in [
      (transition(type: 'public_garden'), 'Select Public Park or Playground'),
      (transition(edits: {'st_rise': 3.001}), 'cannot exceed the radius'),
      (transition(edits: {'st_angle': 53.13}), 'above the submitted limit'),
      (transition(edits: {'st_runin': 3.999}), 'flat run-in or deck length'),
      (transition(edits: {'st_min_deck': 1.801}), 'flat run-in or deck length'),
      (transition(edits: {'right_setback': 2.001}), 'right plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.profile, isNull);
    }
  });

  testWidgets('valid brief switches from plan to profile', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SkateTransitionCadScreen(name: 'Transition', brief: transition(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('Lip tangent 53.130°'), findsOneWidget);
    expect(find.text('Share transition plan DXF'), findsOneWidget);
    await tester.tap(find.text('Longitudinal profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share transition profile DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved angle conflict without fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'skate', name: 'Transition conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: transition(edits: {'st_angle': 53}));
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
    await tester.tap(find.text('Skate transition CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The lip tangent angle'), findsOneWidget);
    expect(find.text('Share transition plan DXF'), findsNothing);
    expect(find.text('Share transition profile DXF'), findsNothing);
  });
}
