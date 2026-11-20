import 'dart:convert';

import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:flutter_test/flutter_test.dart';

import 'automatic_floor_plan_test.dart' show brief;

void main() {
  test('R12 DXF preserves CAD primitive entities and coordinates from the preview', () {
    final plan = AutomaticFloorPlanGenerator().generate(brief: brief(config: '2_bhk'),
      frontageFt: 30, depthFt: 40, facing: 'North').plan!;
    final drawing = FloorPlanCad.fromPlan(plan);
    final dxf = drawing.toDxf();
    expect(() => ascii.encode(dxf), returnsNormally);
    final rows = dxf.trimRight().split('\r\n');
    expect(rows.length.isEven, isTrue);
    final pairs = [for (var i = 0; i < rows.length; i += 2) (int.parse(rows[i]), rows[i + 1])];
    expect(pairs, contains((1, 'AC1009')));
    expect(pairs.last, (0, 'EOF'));
    expect(pairs.where((p) => p == (0, 'LINE')), hasLength(drawing.lines.length));
    expect(pairs.where((p) => p == (0, 'ARC')), hasLength(drawing.arcs.length));
    expect(pairs.where((p) => p == (0, 'TEXT')), hasLength(drawing.labels.length));
    for (final layer in ['WALLS', 'DOORS', 'WINDOWS', 'PLOT', 'DIMENSIONS', 'ROOM_LABELS']) {
      expect(pairs, contains((8, layer)));
    }
    final start = pairs.indexOf((0, 'LINE'));
    expect(pairs.sublist(start, start + 8), [
      (0, 'LINE'), (8, 'PLOT'), (10, '0.000'), (20, '0.000'), (30, '0.0'),
      (11, '${plan.plot.width}.000'), (21, '0.000'), (31, '0.0'),
    ]);
    expect(pairs, contains((1, 'DIMENSIONS IN MILLIMETRES')));
    expect(pairs, contains((1, '2 BHK CONCEPT - NOT FOR CONSTRUCTION')));
  });

  test('door swings exist for every entry orientation and do not replace wall gaps', () {
    for (final orientation in ['North', 'East', 'South', 'West']) {
      final result = AutomaticFloorPlanGenerator().generate(brief: brief(),
        frontageFt: 30, depthFt: 40, facing: orientation);
      final plan = result.plan!;
      final cad = FloorPlanCad.fromPlan(plan);
      final doorCount = plan.openings.where((o) => o.kind == PlanOpeningKind.door).length;
      expect(cad.arcs, hasLength(doorCount));
      expect(cad.arcs.every((arc) => arc.end - arc.start == 90), isTrue);
      expect(validateAutomaticFloorPlan(plan), isNull);
    }
  });
}
