import 'dart:math' as math;

import 'package:architect_engine/data/t_junction_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/screens/t_junction_cad_screen.dart';
import 'package:architect_engine/services/cross_junction_cad_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 't_junction_cad_test.dart' show junction;

const _controls = '345000,2110000;345040,2110000;345090,2110000;345061,2110028;345016,2109968';
const _rightAngle = '-40,0;0,0;50,0;0,35;0,-40';

ProjectBrief crossBrief({Map<String, Object> edits = const {}, Map<String, int> spaces = const {}}) =>
    junction(spaces: spaces, edits: {
      'junction_cad_mode': 'survey_cross', 'cross_controls': _controls,
      'cross_radius_ac': 5, 'cross_radius_ad': 6, 'cross_radius_bc': 7, 'cross_radius_bd': 8,
      ...edits,
    });

CadPoint arcPoint(CadArc arc, num degrees) {
  final t = degrees * math.pi / 180;
  return CadPoint(arc.center.x + arc.radius * math.cos(t), arc.center.y + arc.radius * math.sin(t));
}

bool near(CadPoint a, CadPoint b) => (a.x - b.x).abs() < .001 && (a.y - b.y).abs() < .001;

void main() {
  final gen = CrossJunctionCadGenerator();

  test('saved skew survey keeps projected controls, four radii and true angles', () {
    final saved = ProjectBrief.fromMap(crossBrief().toMap())!;
    expect(CrossJunctionCadGenerator.requested(saved), isTrue);
    expect(tJunctionCadMode.options.map((option) => option.id), containsAll(['survey_t', 'survey_cross']));
    expect(crossJunctionCadFields.where((field) => field.id.startsWith('cross_radius_')).length, 4);
    final result = gen.generate(saved);
    expect(result.issue, isNull);
    final cad = result.drawing!;
    final arcs = cad.arcs.toList();
    expect(arcs.map((arc) => arc.radius), unorderedEquals([5000, 6000, 7000, 8000]));
    final bc = arcs.singleWhere((arc) => arc.radius == 7000);
    expect(near(bc.center, const CadPoint(345061375, 2110011000)), isTrue);
    final acute = math.atan2(28, 21) * 180 / math.pi;
    expect((bc.end - bc.start) % 360, closeTo(180 - acute, 1e-8));
    expect((arcs.singleWhere((arc) => arc.radius == 5000).end -
        arcs.singleWhere((arc) => arc.radius == 5000).start) % 360, closeTo(acute, 1e-8));
    final axes = cad.lines.where((line) => line.layer == 'JUNCTION_AXIS');
    expect(axes.length, 4);
    expect(axes.every((line) => near(line.start, const CadPoint(345040000, 2110000000))), isTrue);
    expect(axes.any((line) => near(line.end, const CadPoint(345016000, 2109968000))), isTrue);
    final dxf = cad.toDxf();
    expect(RegExp(r'\r?\nARC\r?\n8\r?\nJUNCTION_CURB\r?\n').allMatches(dxf).length, 4);
    for (final layer in ['JUNCTION_ROW', 'JUNCTION_EDGE', 'JUNCTION_AXIS', 'JUNCTION_CONTROLS']) {
      expect(dxf, contains(layer));
    }
  });

  test('curb returns are tangent and both outlines close with either handedness', () {
    for (final controls in [_controls, _rightAngle, '0,-40;0,0;0,50;28,21;-32,-24']) {
      final result = gen.generate(crossBrief(edits: {'cross_controls': controls}));
      expect(result.issue, isNull, reason: controls);
      final cad = result.drawing!;
      final edges = cad.lines.where((line) => line.layer == 'JUNCTION_EDGE').toList();
      final rows = cad.lines.where((line) => line.layer == 'JUNCTION_ROW').toList();
      expect(edges.length, 12);
      expect(rows.length, 12);
      final points = edges.expand((line) => [line.start, line.end]).toList();
      for (final arc in cad.arcs) {
        for (final angle in [arc.start, arc.end]) {
          final p = arcPoint(arc, angle);
          final edge = edges.singleWhere((line) => near(line.start, p) || near(line.end, p));
          final dx = edge.end.x - edge.start.x, dy = edge.end.y - edge.start.y;
          final dot = (p.x - arc.center.x) * dx + (p.y - arc.center.y) * dy;
          expect(dot / (arc.radius * math.sqrt(dx * dx + dy * dy)), closeTo(0, 1e-9));
          points.add(p);
        }
      }
      for (final loop in [points, rows.expand((line) => [line.start, line.end]).toList()]) {
        for (final p in loop) { expect(loop.where((q) => near(p, q)).length, 2); }
      }
    }
  });

  test('opposite tangents can snap without changing supplied survey marks', () {
    final result = gen.generate(crossBrief(edits: {'cross_controls': '-40,0.012;0,0;50,0;0,35;0.016,-40'}));
    expect(result.issue, isNull);
    final cad = result.drawing!;
    expect(cad.lines.where((line) => line.layer == 'JUNCTION_AXIS').any((line) => near(line.end, const CadPoint(0, -40000))), isTrue);
    final mark = cad.lines.where((line) => line.layer == 'JUNCTION_CONTROLS').toList()[8];
    expect((mark.start.x + mark.end.x) / 2, closeTo(16, .001));
  });

  test('an interior arc excursion blocks DXF even though both endpoints fit', () {
    // In the BC quadrant the ROW margins are 3 and 6 m. The equality
    // point is away from the 45-degree midpoint; at R = 15.1 m even the
    // midpoint is inside the ROW, but a nearby portion is outside it.
    const edits = {'cross_controls': _rightAngle, 'junction_main_row': 14, 'junction_branch_row': 19};
    expect(gen.generate(crossBrief(edits: {...edits, 'cross_radius_bc': 15})).issue, isNull);
    final blocked = gen.generate(crossBrief(edits: {...edits, 'cross_radius_bc': 15.1}));
    expect(blocked.drawing, isNull);
    expect(blocked.issue, contains('BC curb return extends outside'));
  });

  test('invalid controls, undersized ROW or insufficient arm extents block drawing', () {
    for (final (brief, reason) in [
      (crossBrief(spaces: {'crossing': 1}), 'separate Space selections'),
      (crossBrief(edits: {'cross_controls': '0,0;1,0;2,0'}), 'exactly five'),
      (crossBrief(edits: {'cross_controls': '-40,0;0,0;50,0;0,35;0,40'}), 'opposite sides'),
      (crossBrief(edits: {'cross_controls': '-40,0;0,0;50,0;30,10;-33,-11'}), '30° and 150°'),
      (crossBrief(edits: {'cross_controls': '-40,0;0,0;50,0;0,9;0,-40'}), 'extend past'),
      (crossBrief(edits: {'junction_main_row': 6}), 'at least as wide'),
      (crossBrief(edits: {'cross_radius_bd': 0}), 'all four curb-return radii'),
    ]) {
      final result = gen.generate(brief);
      expect(result.drawing, isNull, reason: reason);
      expect(result.issue, contains(reason));
    }
  });

  testWidgets('shared junction preview routes cross mode and hides blocked export', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TJunctionCadScreen(name: 'Survey node', brief: crossBrief())));
    expect(find.text('Survey four-arm intersection CAD'), findsOneWidget);
    expect(find.text('Share junction DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: TJunctionCadScreen(key: const ValueKey('blocked'), name: 'Survey node',
      brief: crossBrief(edits: {'junction_main_row': 8, 'junction_branch_row': 7}))));
    expect(find.textContaining('extends outside'), findsOneWidget);
    expect(find.text('Share junction DXF'), findsNothing);
  });
}
