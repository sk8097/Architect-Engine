import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/solar_farm_screen.dart';
import 'package:architect_engine/services/solar_farm_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief solar({Map<String, Object> edits = const {}, String type = 'solar_farm',
  String shape = 'rectangular', Map<String, int> spaces = const {}}) => ProjectBrief(
  floorCount: 0, parking: ProjectParking.none, features: const [],
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'energy',
    typeId: type, configurationId: 'outdoor_yard', plotShapeId: shape, spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'solar_fixed_tilt', 'pv_face': 'south', 'pv_rows': 3, 'pv_tables': 4, 'pv_cols': 5, 'pv_stacks': 2,
    'pv_module_x': 1.1, 'pv_module_s': 2, 'pv_seam': .02, 'pv_watts': 550, 'pv_tilt': 30, 'pv_sun': 30,
    'pv_pitch': 8, 'pv_side_gap': 2, 'pv_walk': 3, 'pv_perimeter': 3, 'pv_west': 5, 'pv_first': 4,
    'pv_obstacles': 'duct,11,4,1,2', ...edits,
  }),
);

void main() {
  SolarFarmResult run(ProjectBrief brief) => SolarFarmGenerator().generate(brief, widthFt: 50 / .3048, depthFt: 40 / .3048);

  test('module dimensions project with tilt and independent seams, and retain nameplate capacity', () {
    final saved = ProjectBrief.fromMap(solar().toMap())!;
    expect(SolarFarmGenerator.requested(saved), isTrue);
    expect(cadOutputOptions(warehouseLoading: false, solarFarm: true).options.map((o) => o.id), contains('solar_fixed_tilt'));
    final result = run(saved);
    expect(result.issue, isNull);
    final cad = result.drawing!;
    final projectedDepth = 4020 * math.cos(math.pi / 6);
    expect(result.tables, 12);
    expect(result.modules, 120);
    expect(result.peakKw, 66);
    expect(result.projectedDepthMm, closeTo(projectedDepth, 1e-6));
    expect(result.riseMm, closeTo(2010, 1e-6));
    expect(result.shadowMm, closeTo(projectedDepth, 1e-6));
    expect(result.rowGapMm, closeTo(8000 - projectedDepth, 1e-6));
    final modules = cad.lines.where((l) => l.layer == 'PV_MODULE').toList();
    expect(modules.length, 120 * 4);
    expect((modules.first.start.x, modules.first.start.y, modules.first.end.x), (5000, 4000, 6100));
    expect(modules[4].start.x, 6120);
    expect(modules[20].start.y, closeTo(4000 + 2020 * math.cos(math.pi / 6), 1e-6));
    final low = cad.lines.where((l) => l.layer == 'PV_LOW_EDGE').toList();
    expect(low.length, 12);
    expect((low[0].start.x, low[0].end.x, low[1].start.x, low[4].start.y), (5000, 10580, 12580, 12000));
    final shade = cad.lines.where((l) => l.layer == 'PV_SHADOW_LIMIT').toList();
    expect(shade.length, 8);
    expect(shade.first.start.y, closeTo(4000 + 2 * projectedDepth, 1e-6));
    expect(shade.first.start.y, lessThan(low[4].start.y));
    final dxf = cad.toDxf();
    for (final value in ['PV_MODULE', 'PV_PLOT', 'PV_BUILDABLE', 'PV_EXCLUSION', 'PV_LOW_EDGE', 'PV_SHADOW_LIMIT', '66.000 KWP DC']) {
      expect(dxf, contains(value));
    }
  });

  test('north-facing rows mirror shade geometry, but a single row has no inter-row test', () {
    final n = run(solar(edits: {'pv_face': 'north'}));
    expect(n.issue, isNull);
    final cad = n.drawing!;
    expect(cad.lines.firstWhere((l) => l.layer == 'PV_LOW_EDGE').start.y, 36000);
    expect(cad.lines.firstWhere((l) => l.layer == 'PV_SHADOW_LIMIT').start.y, closeTo(36000 - n.projectedDepthMm - n.shadowMm, 1e-6));
    final single = run(solar(edits: {'pv_rows': 1, 'pv_pitch': 1, 'pv_sun': 2}));
    expect(single.issue, isNull);
    expect(single.rowGapMm, isNull);
    expect(single.drawing!.lines.where((l) => l.layer == 'PV_SHADOW_LIMIT'), isEmpty);
  });

  test('shade, setbacks, exclusion conflict and unbounded complexity prevent export', () {
    for (final (brief, issue) in [
      (solar(type: 'transformer_yard'), 'Select Energy'),
      (solar(shape: 'irregular'), 'rectangular or square'),
      (solar(spaces: {'control_room': 1}), 'no floors, parking or separate Space'),
      (solar(edits: {'pv_pitch': 5}), 'maintenance gap'),
      (solar(edits: {'pv_sun': 10}), 'supplied sun profile angle'),
      (solar(edits: {'front_setback': 6}), 'buildable rectangle'),
      (solar(edits: {'pv_face': 'north', 'rear_setback': 6}), 'buildable rectangle'),
      (solar(edits: {'pv_obstacles': 'duct,5,4,1,2'}), 'Row 1, table 1 overlaps exclusion duct'),
      (solar(edits: {'pv_obstacles': 'duct,51,4,1,2'}), 'outside the plot'),
      (solar(edits: {'pv_rows': 80, 'pv_tables': 80}), '8,000 modules'),
    ]) {
      final result = run(brief);
      expect(result.issue, contains(issue));
      expect(result.drawing, isNull);
    }
  });

  testWidgets('valid solar preview exposes export; blocked layout retains the explanation', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SolarFarmScreen(name: 'PV block', brief: solar(), widthFt: 165, depthFt: 132)));
    expect(find.text('12 tables · 120 modules · 66.000 kWp DC'), findsOneWidget);
    expect(find.text('Share solar layout DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: SolarFarmScreen(key: const ValueKey('invalid'), name: 'PV block',
      brief: solar(edits: {'pv_sun': 10}), widthFt: 165, depthFt: 132)));
    expect(find.textContaining('too small at the supplied sun'), findsOneWidget);
    expect(find.text('Share solar layout DXF'), findsNothing);
  });
}
