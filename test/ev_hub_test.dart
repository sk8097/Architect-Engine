import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/ev_hub_screen.dart';
import 'package:architect_engine/services/ev_hub_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief evHub({Map<String, Object> edits = const {}, String type = 'ev_charging_hub',
  ProjectParking parking = ProjectParking.none}) => ProjectBrief(
  floorCount: 0, parking: parking, features: const [],
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'energy',
    typeId: type, configurationId: 'outdoor_yard', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'ev_measured_hub', 'ev_count': 6, 'ev_offset_left': 2, 'ev_offset_front': 4,
    'ev_bay_width': 2.6, 'ev_access_width': 3.4, 'ev_bay_depth': 5, 'ev_transfer': 1.5,
    'ev_aisle': 6, 'ev_end': 4, 'ev_walk': 2, 'ev_service': 1.2, 'ev_pad_x': .8, 'ev_pad_y': .8,
    'ev_head_pass': .75, ...edits,
  }),
);

void main() {
  EvHubResult run(ProjectBrief brief, [String facing = 'South']) =>
      EvHubGenerator().generate(brief, widthFt: 24 / .3048, depthFt: 38 / .3048, facing: facing);
  PlanRect bounds(Iterable<CadLine> lines) {
    final points = lines.expand((l) => [l.start, l.end]);
    return PlanRect(points.map((p) => p.x).reduce(math.min).round(), points.map((p) => p.y).reduce(math.min).round(),
      points.map((p) => p.x).reduce(math.max).round(), points.map((p) => p.y).reduce(math.max).round());
  }
  bool connects(PlanRect a, PlanRect b) => ((a.right == b.left || a.left == b.right) && a.bottom < b.top && a.top > b.bottom) ||
      ((a.top == b.bottom || a.bottom == b.top) && a.left < b.right && a.right > b.left);

  test('measured equipment and transfer routes remain connected on all four frontages', () {
    final saved = ProjectBrief.fromMap(evHub().toMap())!;
    expect(EvHubGenerator.requested(saved), isTrue);
    expect(cadOutputOptions(warehouseLoading: false, evHub: true).options.map((o) => o.id), contains('ev_measured_hub'));
    for (final facing in ['South', 'North', 'East', 'West']) {
      final result = run(saved, facing);
      expect(result.issue, isNull, reason: facing);
      expect((result.bays, result.clearHeadPassMm, result.transferWidthMm), (6, 900, 1500));
      final cad = result.drawing!;
      List<CadLine> layer(String key) => cad.lines.where((l) => l.layer == key).toList();
      final plot = bounds(layer('EV_PLOT')), walk = bounds(layer('EV_WALK')), drive = bounds(layer('EV_DRIVE'));
      final transfer = bounds(layer('EV_TRANSFER').take(4)), bays = layer('EV_BAYS'), pads = layer('EV_PADS'), passages = layer('EV_HEAD_PASS');
      final rotated = facing == 'East' || facing == 'West';
      expect(rotated ? plot.width : plot.depth, 38000);
      expect(rotated ? walk.depth : walk.width, 2000);
      expect(rotated ? drive.depth : drive.width, 6000);
      expect(rotated ? drive.width : drive.depth, 25900);
      bool onFrontage(PlanRect item) => switch (facing) {
        'South' => item.bottom == plot.bottom, 'North' => item.top == plot.top,
        'East' => item.right == plot.right, _ => item.left == plot.left,
      };
      expect(onFrontage(walk) && onFrontage(drive) && !walk.overlaps(drive), isTrue);
      expect(connects(transfer, walk) && connects(transfer, bounds(bays.take(4))), isTrue);
      expect(!transfer.overlaps(drive), isTrue);
      expect((bays.length, pads.length, passages.length), (24, 24, 24));
      final equipment = bounds(layer('EV_EQUIPMENT'));
      for (var i = 0; i < 6; i++) {
        final bay = bounds(bays.skip(i*4).take(4)), pad = bounds(pads.skip(i*4).take(4));
        final pass = bounds(passages.skip(i*4).take(4));
        expect(rotated ? bay.width : bay.depth, i == 0 ? 3400 : 2600);
        expect(equipment.contains(pad) && equipment.contains(pass) && !pad.overlaps(pass), isTrue);
        expect(connects(pass, walk) && connects(pass, bay), isTrue);
        expect(!pad.overlaps(transfer) && !pad.overlaps(walk) && !pad.overlaps(bay), isTrue);
      }
      final dxf = cad.toDxf();
      for (final expected in ['EV_BAYS', 'EV_TRANSFER', 'EV_PADS', 'EV_DRIVE', 'EV_WALK', 'EV_HEAD_PASS', '6 BAYS']) {
        expect(dxf, contains(expected));
      }
    }
  });

  test('incompatible brief or measured conflicts block the full layout', () {
    for (final (brief, issue) in [
      (evHub(type: 'solar_farm'), 'Select Energy'),
      (evHub(parking: ProjectParking.twoWheeler), 'non-car parking'),
      (evHub(edits: {'cars': 5}), 'car count must match'),
      (evHub(edits: {'ev_access_width': 2.5}), 'cannot be narrower'),
      (evHub(edits: {'ev_pad_x': 1.3}), 'fit the equipment strip'),
      (evHub(edits: {'ev_pad_y': 1.2}), 'too little clear passage'),
      (evHub(edits: {'front_setback': 4.001}), 'front plot edge'),
      (evHub(edits: {'ev_count': 20}), 'rear plot edge'),
      (evHub(edits: {'ev_aisle': 20}), 'right plot edge'),
    ]) {
      final result = run(brief);
      expect(result.issue, contains(issue));
      expect(result.drawing, isNull);
    }
    expect(run(evHub(), 'North-East').issue, contains('cardinal frontage'));
  });

  testWidgets('charging yard shows the measured result and blocks export for pad conflicts', (tester) async {
    await tester.pumpWidget(MaterialApp(home: EvHubScreen(name: 'EV yard', brief: evHub(), widthFt: 79, depthFt: 125, facing: 'East')));
    expect(find.text('6 charging bays · 1 designated transfer bay'), findsOneWidget);
    expect(find.text('Share EV yard DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: EvHubScreen(key: const ValueKey('blocked'), name: 'EV yard',
      brief: evHub(edits: {'ev_pad_y': 1.2}), widthFt: 79, depthFt: 125, facing: 'East')));
    expect(find.textContaining('too little clear passage'), findsOneWidget);
    expect(find.text('Share EV yard DXF'), findsNothing);
  });
}
