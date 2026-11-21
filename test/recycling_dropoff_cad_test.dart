import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/recycling_dropoff_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/recycling_dropoff_cad_screen.dart';
import 'package:architect_engine/services/recycling_dropoff_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief dropoff({Map<String, Object> edits = const {}, String type = 'recycling_centre', int? floors}) =>
  ProjectBrief(floorCount: floors, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'public_realm',
      typeId: type, configurationId: 'support_facility', actionId: 'site_development', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': recyclingDropoffMode, 'rd_min': 6, 'rd_cap': 12, 'rd_w': 3, 'rd_d': 3.2, 'rd_gap': .6,
      'rd_end': 1.5, 'rd_apron': 2.5, 'rd_apron_min': 2.5, 'rd_lane': 5.3, 'rd_lane_min': 5.3, 'rd_south': 2,
      'left_setback': 2, 'right_setback': 3, 'front_setback': 2, 'rear_setback': 3, ...edits,
    }));

void main() {
  const widthFt = 29.001 / .3048, depthFt = 16 / .3048;
  RecyclingDropoffCadResult run(ProjectBrief b, {double width = widthFt}) =>
    RecyclingDropoffCadGenerator().generate(b, widthFt: width, depthFt: depthFt);

  test('recycling centre opt-in preserves ordinary CAD and excludes compost facilities', () {
    expect(recyclingDropoffCadEligible('infrastructure', 'public_realm', 'recycling_centre'), isTrue);
    expect(recyclingDropoffCadEligible('infrastructure', 'public_realm', 'composting_facility'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(recyclingDropoffMode)));
    expect(cadOutputOptions(warehouseLoading: false, recyclingDropoff: true).options.map((o) => o.id), containsAll([...ordinary, recyclingDropoffMode]));
  });

  test('saved dimensions centre the bank between unequal setbacks and preserve half-mm in both exports', () {
    final saved = ProjectBrief.fromMap(dropoff().toMap())!;
    expect(RecyclingDropoffCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.bays.length, r.widthMm, r.depthMm, r.apronMm, r.laneMm), (6, 24000, 11000, 2500, 5300));
    expect(r.bays.map((b) => b.westMm), [3500.5, 7100.5, 10700.5, 14300.5, 17900.5, 21500.5]);
    final plan = r.drawing!;
    final bay = plan.lines.where((l) => l.layer == 'RD_BAY').first;
    expect((bay.start.x, bay.start.y, bay.end.x, bay.end.y), (3500.5, 4500, 6500.5, 4500));
    final front = plan.lines.where((l) => l.layer == 'RD_PUBLIC').toList();
    final rear = plan.lines.where((l) => l.layer == 'RD_COLLECT').toList();
    expect((front.length, rear.length), (10, 10));
    expect((front[1].start.x, front[1].end.x, front[1].start.y), (2000.5, 26000.5, 2000));
    expect((rear[1].start.x, rear[1].end.x, rear[1].start.y), (2000.5, 26000.5, 13000));
    expect(front[4].end.x - front[4].start.x, 600);
    expect(plan.toDxf(), contains('6 CONTAINER BAYS / ENVELOPE 24.000 x 11.000 M'));
    expect(r.toCsv(), startsWith('bay_id,x_min_m,y_min_m,x_max_m,y_max_m,public_face,collection_face\r\nB01,3.5005,4.5000,6.5005,7.7000,south,north\r\n'));
    expect(r.toCsv(), endsWith('B06,21.5005,4.5000,24.5005,7.7000,south,north\r\n'));
  });

  test('exact fit, one mm too narrow, and a cap below the geometric maximum', () {
    final exact = run(dropoff(), width: 29 / .3048);
    expect((exact.issue, exact.bays.length), (null, 6));
    final narrow = run(dropoff(), width: 28.999 / .3048);
    expect(narrow.issue, contains('Only 5 container bays fit'));
    expect(narrow.drawing, isNull);
    final capped = run(dropoff(edits: {'rd_min': 1, 'rd_cap': 1}));
    expect((capped.issue, capped.bays.length, capped.widthMm), (null, 1, 6000));
    expect(capped.bays.single.westMm, 12500.5);
  });

  test('scope, target and clearance conflicts suppress DXF and CSV', () {
    for (final (brief, reason) in [
      (dropoff(type: 'composting_facility'), 'Select Recycling Centre'),
      (dropoff(floors: 1), 'Remove building floors'),
      (dropoff(edits: {'rd_min': 2.5}), 'whole bay counts'),
      (dropoff(edits: {'rd_cap': 5}), 'Raise the maximum bay count'),
      (dropoff(edits: {'rd_apron': 2.499}), 'public apron depth'),
      (dropoff(edits: {'rd_lane_min': 5.301}), 'rear collection aisle depth'),
      (dropoff(edits: {'rd_south': 1.999}), 'front or rear plot limit'),
      (dropoff(edits: {'rear_setback': 3.001}), 'front or rear plot limit'),
      (dropoff(edits: {'right_setback': 3.002}), 'Only 5 container bays fit'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid mode previews both export options', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RecyclingDropoffCadScreen(name: 'Drop-off', brief: dropoff(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('6 container bays'), findsOneWidget);
    expect(find.text('Share drop-off plan DXF'), findsOneWidget);
    expect(find.text('Share bay schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved count conflict without generic fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'dropoff', name: 'Drop-off conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: dropoff(edits: {'rd_min': 7}));
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
    await tester.tap(find.text('Recycling drop-off CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only 6 container bays fit'), findsOneWidget);
    expect(find.text('Share drop-off plan DXF'), findsNothing);
    expect(find.text('Share bay schedule CSV'), findsNothing);
  });
}
