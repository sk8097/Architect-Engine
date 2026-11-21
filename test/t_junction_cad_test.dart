import 'dart:math' as math;

import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/t_junction_cad_screen.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/t_junction_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief junction({Map<String, Object> edits = const {}, String type = 'intersection',
  Map<String, int> spaces = const {}, String? action}) => ProjectBrief(
  floorCount: null, parking: null, features: const [], taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure',
    subcategoryId: 'transport', typeId: type, configurationId: 'node_interchange', actionId: action, spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'junction_cad_mode': 'survey_t', 'junction_grid': 'Local metre grid', 'junction_reference': 'Test control survey',
    'junction_controls': '345000,2110000;345040,2110000;345090,2110000;345040,2110035',
    'junction_main_width': 8, 'junction_branch_width': 7, 'junction_main_row': 20, 'junction_branch_row': 17,
    'junction_a_radius': 6, 'junction_b_radius': 8, ...edits,
  }));

void main() {
  final gen = TJunctionCadGenerator();
  CadPoint arcPoint(CadArc arc, num degrees) => CadPoint(arc.center.x + math.cos(degrees * math.pi / 180) * arc.radius,
    arc.center.y + math.sin(degrees * math.pi / 180) * arc.radius);
  bool near(CadPoint a, CadPoint b) => (a.x - b.x).abs() < .001 && (a.y - b.y).abs() < .001;

  test('analytical curb arcs and projected control coordinates survive saved briefs and DXF', () {
    final saved = ProjectBrief.fromMap(junction().toMap())!;
    expect(TJunctionCadGenerator.requested(saved), isTrue);
    final result = gen.generate(saved);
    expect(result.issue, isNull);
    final cad = result.drawing!, arcs = cad.arcs.toList();
    expect(arcs.length, 2);
    expect(arcs.map((a) => a.radius), orderedEquals([6000, 8000]));
    expect(near(arcs.first.center, const CadPoint(345030500, 2110010000)), isTrue);
    expect(near(arcs.last.center, const CadPoint(345051500, 2110012000)), isTrue);
    final axes = cad.lines.where((l) => l.layer == 'JUNCTION_AXIS').toList();
    expect(axes.length, 3);
    expect(near(axes.first.start, const CadPoint(345000000, 2110000000)), isTrue);
    expect(near(axes.last.end, const CadPoint(345040000, 2110035000)), isTrue);
    expect(cad.lines.where((l) => l.layer == 'JUNCTION_ROW').length, 8);
    final dxf = cad.toDxf();
    expect(RegExp(r'\r?\nARC\r?\n8\r?\nJUNCTION_CURB\r?\n').allMatches(dxf).length, 2);
    expect(dxf, contains('PROJECTED COORDINATES IN MM'));
    for (final layer in ['JUNCTION_ROW', 'JUNCTION_EDGE', 'JUNCTION_AXIS', 'JUNCTION_CONTROLS']) { expect(dxf, contains(layer)); }
  });

  test('both handednesses and arbitrary bearing retain tangent, closed outlines', () {
    for (final controls in [
      '-32,-24;0,0;40,30;-21,28', // basis (0.8,0.6), branch to the left
      '-32,-24;0,0;40,30;21,-28', // branch to the right
      '0,-40;0,0;0,50;35,0',
      '0,40;0,0;0,-50;35,0',
    ]) {
      final result = gen.generate(junction(edits: {'junction_controls': controls}));
      expect(result.issue, isNull, reason: controls);
      final cad = result.drawing!;
      final edges = cad.lines.where((l) => l.layer == 'JUNCTION_EDGE').toList();
      final points = edges.expand((l) => [l.start, l.end]).toList();
      for (final arc in cad.arcs) {
        expect((arc.end - arc.start) % 360, closeTo(90, 1e-8));
        for (final degrees in [arc.start, arc.end]) {
          final p = arcPoint(arc, degrees);
          final edge = edges.singleWhere((edge) => near(edge.start, p) || near(edge.end, p));
          final dx = edge.end.x - edge.start.x, dy = edge.end.y - edge.start.y;
          final radiusX = p.x - arc.center.x, radiusY = p.y - arc.center.y;
          final dot = dx * radiusX + dy * radiusY;
          expect(dot / (arc.radius * math.sqrt(dx * dx + dy * dy)), closeTo(0, 1e-9));
          points.add(p);
        }
      }
      for (final p in points) { expect(points.where((q) => near(p, q)).length, 2); }
    }
  });

  test('small survey deviations are snapped to the declared orthogonal basis but control ticks stay raw', () {
    final result = gen.generate(junction(edits: {'junction_controls': '-40,0.012;0,0;50,0;0.016,35'}));
    expect(result.issue, isNull);
    final cad = result.drawing!;
    final branch = cad.lines.where((l) => l.layer == 'JUNCTION_AXIS').last;
    expect(near(branch.end, const CadPoint(0, 35000)), isTrue);
    final branchControl = cad.lines.where((l) => l.layer == 'JUNCTION_CONTROLS').toList()[6];
    expect((branchControl.start.x + branchControl.end.x) / 2, closeTo(16, .001));
  });

  test('rejects skew, bad ordering, narrow or clipped right-of-way and conflicting programs', () {
    for (final (brief, issue) in [
      (junction(type: 'roundabout'), 'Select Transport'),
      (junction(spaces: {'crossing': 1}), 'separate Space selections'),
      (junction(action: 'approval'), 'new plan-view'),
      (junction(edits: {'junction_controls': '0,0;1,0;2,0'}), 'exactly four'),
      (junction(edits: {'junction_controls': '30,0;0,0;50,0;0,35'}), 'opposite sides'),
      (junction(edits: {'junction_controls': '-40,0;0,0;50,0;1,35'}), 'perpendicular'),
      (junction(edits: {'junction_controls': '-40,0;0,0;50,0;0,11'}), 'extend past'),
      (junction(edits: {'junction_main_row': 6}), 'at least as wide'),
      (junction(edits: {'junction_main_row': 12, 'junction_branch_row': 10}), 'extends outside'),
    ]) {
      final result = gen.generate(brief);
      expect(result.drawing, isNull);
      expect(result.issue, contains(issue), reason: issue);
    }
  });

  testWidgets('junction preview exposes DXF for valid survey controls only', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TJunctionCadScreen(name: 'Survey node', brief: junction())));
    expect(find.text('Survey T-junction CAD'), findsOneWidget);
    expect(find.text('Share junction DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: TJunctionCadScreen(key: const ValueKey('blocked'), name: 'Survey node',
      brief: junction(edits: {'junction_main_row': 12, 'junction_branch_row': 10}))));
    expect(find.textContaining('extends outside'), findsOneWidget);
    expect(find.text('Share junction DXF'), findsNothing);
  });
}
