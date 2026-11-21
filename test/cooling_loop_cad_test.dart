import 'dart:math' as math;

import 'package:architect_engine/data/cooling_loop_cad_fields.dart';
import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/cooling_loop_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/cooling_loop_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief loop({Map<String, Object> edits = const {}, String type = 'district_cooling', String config = 'outdoor_yard'}) =>
  ProjectBrief(floorCount: null, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'energy',
      typeId: type, configurationId: config, actionId: 'concept_design', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': coolingLoopMode, 'cl_r': 1.5, 'cl_min_r': 1.5, 'cl_od': .501, 'cl_clear': .5, 'cl_w_lead': 4, 'cl_e_lead': 5,
      'cl_leg': 3, 'cl_bridge': 2.5, 'cl_west': 2, 'cl_south': 2, 'left_setback': 2, 'right_setback': 4,
      'front_setback': 2, 'rear_setback': 3, ...edits,
    }));

void main() {
  const widthFt = 25.001 / .3048, depthFt = 12.501 / .3048;
  CoolingLoopCadResult run(ProjectBrief b) => CoolingLoopCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('opt-in is only for infrastructure District Cooling', () {
    expect(coolingLoopCadEligible('infrastructure', 'energy', 'district_cooling'), isTrue);
    expect(coolingLoopCadEligible('infrastructure', 'energy', 'transformer_yard'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(coolingLoopMode)));
    expect(cadOutputOptions(warehouseLoading: false, coolingLoop: true).options.map((o) => o.id), containsAll([...ordinary, coolingLoopMode]));
  });

  test('saved geometry is tangent at every centreline, pipe edge and clearance join', () {
    final saved = ProjectBrief.fromMap(loop().toMap())!;
    expect(CoolingLoopCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.reachMm, r.segments.length), (19001, 7501, 6000, 9));
    expect(r.lengthMm, closeTo(26924.77796076938, 1e-8));
    final d = r.drawing!;
    final axis = d.lines.firstWhere((l) => l.layer == 'CL_AXIS');
    expect((axis.start.x, axis.start.y, axis.end.x), (2750.5, 2750.5, 6750.5));
    final clearArcs = d.arcs.where((a) => a.layer == 'CL_CLEAR').toList();
    expect(clearArcs.map((a) => a.radius), [2250.5, 749.5, 749.5, 2250.5, 749.5, 2250.5, 2250.5, 749.5]);
    for (final (layer, traceCount) in [('CL_AXIS', 1), ('CL_PIPE', 2), ('CL_CLEAR', 2)]) {
      final arcs = d.arcs.where((a) => a.layer == layer).toList();
      final lines = d.lines.where((l) => l.layer == layer).toList();
      expect(arcs.length, traceCount * 4);
      for (var trace = 0; trace < traceCount; trace++) {
        for (var i = 0; i < 4; i++) {
          final arc = arcs[4 * trace + i], before = lines[5 * trace + i], after = lines[5 * trace + i + 1];
          final reverse = i == 1 || i == 2;
          for (final (point, angle) in [(before.end, reverse ? arc.end : arc.start), (after.start, reverse ? arc.start : arc.end)]) {
            final rad = angle * math.pi / 180;
            expect(point.x, closeTo(arc.center.x + arc.radius * math.cos(rad), 1e-8));
            expect(point.y, closeTo(arc.center.y + arc.radius * math.sin(rad), 1e-8));
          }
        }
      }
    }
    expect(d.toDxf(), contains('CENTRELINE 26.925 M / 4 QUARTER BENDS / ENVELOPE 19.001 x 7.501 M'));
    expect(r.toCsv(), contains('2,bend_left_90,4.000000,6.356194,2.356194,1.500000\r\n'));
    expect(r.toCsv(), endsWith('9,straight,21.924778,26.924778,5.000000,\r\n'));
  });

  test('radius, non-positive inner clearance and plot failures suppress both exports', () {
    for (final (b, reason) in [
      (loop(type: 'solar_farm'), 'Select District Cooling'),
      (loop(config: 'enclosed_facility'), 'Outdoor Yard'),
      (loop(edits: {'cl_bridge': 0}), 'tangent lengths'),
      (loop(edits: {'cl_min_r': 1.501}), 'submitted minimum'),
      (loop(edits: {'cl_od': 2}), 'has no positive radius'),
      (loop(edits: {'right_setback': 4.001}), 'right plot edge'),
      (loop(edits: {'rear_setback': 3.001}), 'rear plot edge'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid drawing exposes plan and bend schedule', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CoolingLoopCadScreen(name: 'Loop', brief: loop(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('26.925 m centreline'), findsOneWidget);
    expect(find.text('Share loop plan DXF'), findsOneWidget);
    expect(find.text('Share bend schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved fit conflict without export or generic fallback', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'loop', name: 'Loop conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: loop(edits: {'rear_setback': 3.001}));
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
    await tester.tap(find.text('Cooling pipe loop CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('rear plot edge'), findsOneWidget);
    expect(find.text('Share loop plan DXF'), findsNothing);
    expect(find.text('Share bend schedule CSV'), findsNothing);
  });
}
