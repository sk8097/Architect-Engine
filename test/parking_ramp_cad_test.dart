import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/parking_ramp_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/parking_ramp_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/parking_ramp_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief ramp({Map<String, Object> edits = const {}, String type = 'parking_structure', int? floors}) => ProjectBrief(
  floorCount: floors, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'transport',
    typeId: type, configurationId: 'linear_corridor', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': parkingRampMode, 'vk_rise': 3, 'vk_run': 24, 'vk_trans': 4,
    'vk_lower': 4, 'vk_upper': 5, 'vk_width': 4, 'vk_edge': .5,
    'vk_max_grade': 15, 'vk_max_break': 7.5,
    'vk_oh_start': 6, 'vk_oh_end': 30, 'vk_oh_z0': 3.25, 'vk_oh_z1': 5.65, 'vk_head': 2.35,
    'vk_west': 2, 'vk_south': 3, 'left_setback': 2, 'right_setback': 3, 'front_setback': 3, 'rear_setback': 4,
    ...edits,
  }));

void main() {
  const widthFt = 10 / .3048, depthFt = 40 / .3048;
  ParkingRampCadResult run(ProjectBrief b) => ParkingRampCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('parking structure opt-in does not replace ordinary CAD or apply to bus terminals', () {
    expect(parkingRampCadEligible('infrastructure', 'transport', 'parking_structure'), isTrue);
    expect(parkingRampCadEligible('infrastructure', 'transport', 'bus_terminal'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(parkingRampMode)));
    expect(cadOutputOptions(warehouseLoading: false, parkingRamp: true).options.map((o) => o.id), containsAll([...ordinary, parkingRampMode]));
  });

  test('saved brief exports exact footprint and profile; the minimum is at a grade break', () {
    final brief = ProjectBrief.fromMap(ramp().toMap())!;
    expect(ParkingRampCadGenerator.requested(brief), isTrue);
    final r = run(brief);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.grade, r.change, r.stationMm), (5000, 33000, 15, 7.5, 24000));
    expect(r.headMm, closeTo(2350, 1e-9));
    final plan = r.plan!, profile = r.profile!;
    final breaks = plan.lines.where((l) => l.layer == 'VK_BREAK').toList();
    expect(breaks.map((l) => l.start.y), [7000, 11000, 27000, 31000]);
    expect((breaks.first.start.x, breaks.first.end.x), (2500, 6500));
    final drive = profile.lines.where((l) => l.layer == 'VK_DRIVE').toList();
    expect(drive.map((l) => (l.end.x, l.end.y)), [(4000, 0), (8000, 300), (24000, 2700), (28000, 3000), (33000, 3000)]);
    final marker = profile.lines.singleWhere((l) => l.layer == 'VK_HEAD');
    expect((marker.start.x, marker.start.y, marker.end.x, marker.end.y), (24000, 2700, 24000, 5050));
    expect(plan.toDxf(), contains('TOTAL ENVELOPE 5.000 x 33.000 M'));
    expect(profile.toDxf(), contains('MIN HEADROOM 2.350 M AT CH 24.000 M'));
  });

  test('minimum may occur at a soffit endpoint inside a ramp segment', () {
    final r = run(ramp(edits: {'vk_oh_end': 20, 'vk_oh_z1': 4.4, 'vk_head': 2.3}));
    expect(r.issue, isNull);
    expect(r.stationMm, 20000);
    expect(r.headMm, closeTo(2300, 1e-9));
  });

  test('scope, footprint, grades and headroom conflicts block both drawings', () {
    for (final (brief, reason) in [
      (ramp(type: 'bus_terminal'), 'Select Parking Structure'),
      (ramp(floors: 2), 'Leave building floors'),
      (ramp(edits: {'vk_trans': 12}), 'positive length of main ramp'),
      (ramp(edits: {'vk_max_grade': 14.999}), 'Main ramp grade'),
      (ramp(edits: {'vk_max_break': 7.499}), 'Grade changes by'),
      (ramp(edits: {'vk_oh_end': 6}), 'soffit interval'),
      (ramp(edits: {'vk_oh_end': 33.001}), 'soffit interval'),
      (ramp(edits: {'right_setback': 3.001}), 'right plot edge'),
      (ramp(edits: {'rear_setback': 4.001}), 'rear plot edge'),
      (ramp(edits: {'vk_head': 2.351}), 'headroom at Ch 24.000 m'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.profile, isNull);
    }
  });

  testWidgets('valid brief opens the plan and switches to profile DXF', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ParkingRampCadScreen(name: 'Ramp', brief: ramp(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Share ramp plan DXF'), findsOneWidget);
    await tester.tap(find.text('Longitudinal profile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Minimum headroom 2.350 m at Ch 24.000 m'), findsOneWidget);
    expect(find.text('Share ramp profile DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens the conflicting brief without generic fallback or DXFs', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'ramp', name: 'Ramp conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: ramp(edits: {'vk_head': 2.351}));
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
    await tester.tap(find.text('Parking ramp CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('headroom at Ch 24.000 m'), findsOneWidget);
    expect(find.text('Share ramp plan DXF'), findsNothing);
    expect(find.text('Share ramp profile DXF'), findsNothing);
  });
}
