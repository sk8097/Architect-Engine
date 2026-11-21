import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/athletics_track_cad_screen.dart';
import 'package:architect_engine/services/athletics_track_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief track({Map<String, Object> edits = const {}, String type = 'stadium'}) => ProjectBrief(
  floorCount: null, features: const [], parking: ProjectParking.none,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'institutional', subcategoryId: 'sports',
    typeId: type, configurationId: 'outdoor', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'athletics_measured_track', 'ak_lanes': 8, 'ak_straight': 84.39, 'ak_radius': 36.5, 'ak_lane_width': 1.22,
    'ak_offset_1': .3, 'ak_offset_other': .2, 'ak_runoff': 3, 'ak_west': 4, 'ak_south': 7, 'ak_target': 400,
    'ak_tolerance': .01, ...edits,
  }));

void main() {
  const widthFt = 110 / .3048, depthFt = 200 / .3048;
  AthleticsTrackCadResult run(ProjectBrief b) => AthleticsTrackCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('measured oval persists; native arcs, start/finish geometry and all lap distances agree', () {
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('athletics_measured_track')));
    expect(cadOutputOptions(warehouseLoading: false, athleticsTrack: true).options.map((o) => o.id), contains('athletics_measured_track'));
    final saved = ProjectBrief.fromMap(track().toMap())!;
    expect(AthleticsTrackCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.lanes.length, r.widthMm, r.depthMm), (8, 98520, 182910));
    expect(r.lanes.first.lapM, closeTo(400.0012193042, 1e-9));
    expect(r.lanes[1].staggerM, closeTo(7.037167544, 1e-9));
    expect(r.lanes.last.staggerM, closeTo(53.030083993, 1e-9));
    for (final lane in r.lanes) {
      expect(lane.lapM - lane.staggerM, closeTo(r.lanes.first.lapM, 1e-9));
    }
    final d = r.drawing!;
    expect(d.arcs.length, 36);
    final runoff = d.arcs.where((a) => a.layer == 'TRACK_RUNOFF').toList();
    expect((runoff.first.center.x, runoff.first.center.y, runoff.first.radius, runoff.first.start, runoff.first.end),
      (53260, 140650, 49260, 0, 180));
    final finish = d.lines.singleWhere((l) => l.layer == 'TRACK_FINISH');
    expect((finish.start.x, finish.start.y, finish.end.x, finish.end.y), (89760, 56260, 99520, 56260));
    final staggers = d.lines.where((l) => l.layer == 'TRACK_STAGGER').toList();
    expect(staggers.length, 7);
    expect((staggers.first.start.x, staggers.first.end.x), (90980, 92200));
    expect(staggers.first.start.y, closeTo(63297.167544, 1e-6));
    expect(staggers.first.end.y, staggers.first.start.y);
    expect(d.toDxf(), contains('\r\nARC\r\n8\r\nTRACK_MEASURE\r\n'));
    expect(r.toCsv()!.split('\r\n')[1], '1,36.800000,400.001219,0.000000,90.060000,56.260000');
  });

  test('short straights exercise radial north/south projection and the west straight', () {
    const small = {'ak_lanes': 3, 'ak_radius': 1, 'ak_lane_width': 1.5, 'ak_target': 12.168, 'ak_tolerance': .001};
    final north = run(track(edits: {...small, 'ak_straight': 2}));
    expect(north.issue, isNull);
    final northMark = north.drawing!.lines.firstWhere((l) => l.layer == 'TRACK_STAGGER');
    final theta = (north.lanes[1].staggerM - 2) / 2.7;
    expect(northMark.start.x, closeTo(12500 + 2500 * math.cos(theta), 1e-7));
    expect(northMark.end.y, closeTo(17500 + 4000 * math.sin(theta), 1e-7));
    final west = run(track(edits: {...small, 'ak_straight': .2, 'ak_target': 8.568}));
    expect(west.issue, isNull);
    final marks = west.drawing!.lines.where((l) => l.layer == 'TRACK_STAGGER').toList();
    expect((marks.first.start.x, marks.first.end.x), (10000, 8500));
    expect(marks.first.start.y, closeTo(15700 - (west.lanes[1].staggerM * 1000 - 200 - math.pi * 2700), 1e-7));
    expect(marks.first.end.y, marks.first.start.y);
    final phi = math.pi + (west.lanes[2].staggerM - .4 - math.pi * 4.2) / 4.2;
    expect(marks.last.start.x, closeTo(12500 + 4000 * math.cos(phi), 1e-7));
    expect(marks.last.end.y, closeTo(15500 + 5500 * math.sin(phi), 1e-7));
  });

  test('exact setbacks fit; count, measurements, setbacks and tolerance block both exports', () {
    expect(run(track(edits: {'left_setback': 4, 'right_setback': 7.48, 'front_setback': 7, 'rear_setback': 10.09})).issue, isNull);
    for (final (brief, message) in [
      (track(type: 'indoor_arena'), 'supported outdoor sports type'),
      (track(edits: {'ak_lanes': 8.5}), 'whole lane count'),
      (track(edits: {'ak_offset_other': 1.22}), 'strictly inside'),
      (track(edits: {'ak_tolerance': .001}), 'misses the 400.000 m target'),
      (track(edits: {'right_setback': 7.481}), 'right plot edge'),
      (track(edits: {'rear_setback': 10.091}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('track preview offers DXF and CSV only when the supplied fit checks pass', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AthleticsTrackCadScreen(name: 'Oval', brief: track(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Share athletics track DXF'), findsOneWidget);
    expect(find.text('Share lane schedule CSV'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: AthleticsTrackCadScreen(key: const ValueKey('invalid'), name: 'Oval',
      brief: track(edits: {'ak_target': 410}), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('misses the 410.000 m target'), findsOneWidget);
    expect(find.text('Share athletics track DXF'), findsNothing);
    expect(find.text('Share lane schedule CSV'), findsNothing);
  });
}
