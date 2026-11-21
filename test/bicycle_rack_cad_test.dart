import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/bicycle_rack_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief racks({Map<String, Object> edits = const {}, bool station = false, String? type}) => ProjectBrief(
  floorCount: null, features: const [], parking: ProjectParking.none,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: station ? 'infrastructure' : 'institutional', subcategoryId: station ? 'transport' : 'sports',
    typeId: type ?? (station ? 'metro_station' : 'public_parking'), configurationId: station ? 'node_interchange' : 'outdoor', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'bicycle_measured_racks', 'br_banks': '2', 'br_stands': 5, 'br_cycle_l': 1.9, 'br_cycle_w': .65,
    'br_stand_l': .8, 'br_stand_w': .1, 'br_flank': .075, 'br_pitch': 1.8, 'br_pair_gap': .25, 'br_aisle': 2.2,
    'br_outer': .5, 'br_head_s': 1.5, 'br_head_n': 1.2, 'br_west': 2, 'br_south': 2, 'br_target': 20, ...edits,
  }));

void main() {
  const widthFt = 12 / .3048, depthFt = 16 / .3048;
  BicycleRackCadResult run(ProjectBrief b) => BicycleRackCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('opt-in persists and each stand has two non-overlapping parked envelopes', () {
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('bicycle_measured_racks')));
    expect(cadOutputOptions(warehouseLoading: false, bicycleRack: true).options.map((o) => o.id), contains('bicycle_measured_racks'));
    final saved = ProjectBrief.fromMap(racks().toMap())!;
    expect(BicycleRackCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.stands, r.positions, r.widthMm, r.depthMm, r.aisleMm, r.loadedGapMm), (10, 20, 7000, 11450, 2200, 250));
    final d = r.drawing!;
    List<(num, num, num, num)> segments(String layer) =>
        d.lines.where((l) => l.layer == layer).map((l) => (l.start.x, l.start.y, l.end.x, l.end.y)).toList();
    final bikes = segments('BIKE_PARKED'), stands = segments('BIKE_STAND');
    expect(bikes.length, 20 * 4);
    expect(stands.length, 10 * 4);
    expect(bikes[0], (2500, 3500, 4400, 3500));
    expect(bikes[4], (2500, 4400, 4400, 4400));
    expect(bikes[8], (2500, 5300, 4400, 5300));
    expect(bikes[40], (6600, 3500, 8500, 3500));
    expect(stands[0], (3050, 4225, 3850, 4225));
    expect(segments('BIKE_MANOEUVRE').take(2), [(4400, 3500, 6600, 3500), (6600, 3500, 6600, 12250)]);
    expect(d.labels.where((l) => l.layer == 'BIKE_IDS').length, 10);
    expect(d.toDxf(), contains('10 STANDS / 20 NOMINAL BICYCLE POSITIONS'));
  });

  test('exact setbacks work at a station and the single-stand mode has no pitch or gap', () {
    final exact = run(racks(station: true, edits: {'left_setback': 2, 'right_setback': 3, 'front_setback': 2, 'rear_setback': 2.55}));
    expect(exact.issue, isNull);
    final single = run(racks(edits: {'br_banks': '1', 'br_stands': 1, 'br_pitch': 0, 'br_pair_gap': 0, 'br_target': 2}));
    expect((single.issue, single.positions, single.widthMm, single.depthMm, single.loadedGapMm), (null, 2, 5100, 4250, null));
  });

  test('blocks tight pitches, long equipment, missed capacity and plot fit', () {
    for (final (brief, message) in [
      (racks(type: 'sports_complex'), 'Select Public Parking'),
      (racks(edits: {'br_stands': 5.5}), 'valid stand and target counts'),
      (racks(edits: {'br_stand_l': 1.901}), 'Stand footprint length'),
      (racks(edits: {'br_pitch': 1.799}), 'Stand pitch is too small'),
      (racks(edits: {'br_pitch': 1.549, 'br_pair_gap': 0}), 'Stand pitch is too small'),
      (racks(edits: {'br_stands': 1}), 'zero pitch'),
      (racks(edits: {'br_target': 21}), 'below the supplied target of 21'),
      (racks(edits: {'right_setback': 3.001}), 'right plot edge'),
      (racks(edits: {'rear_setback': 2.551}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(message));
      expect(r.drawing, isNull);
    }
  });

  testWidgets('Projects reopens a failed bicycle brief without zoning substitution', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'racks', name: 'Cycle parking', length: depthFt, width: widthFt,
      bhk: '', floors: '', facing: 'Not decided', brief: racks(edits: {'br_target': 21}), createdAt: now, updatedAt: now);
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
    await tester.tap(find.text('Bicycle rack CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('supplied target of 21'), findsOneWidget);
    expect(find.text('Share bicycle rack DXF'), findsNothing);
  });
}
