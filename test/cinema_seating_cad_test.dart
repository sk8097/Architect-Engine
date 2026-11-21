import 'package:architect_engine/data/cinema_seating_cad_fields.dart';
import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/cinema_seating_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/cinema_seating_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief cinema({Map<String, Object> edits = const {}, String type = 'cinema_entertainment'}) => ProjectBrief(
  floorCount: 1, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'commercial', subcategoryId: 'business_services',
    typeId: type, configurationId: 'public_facing', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': cinemaSeatingMode, 'cs_hall': 14, 'cs_rows': 8, 'cs_seat_w': .55, 'cs_seat_d': .6,
    'cs_pitch': 1.05, 'cs_row_gap': .45, 'cs_cap': 10, 'cs_target': 144,
    'cs_centre': 1.6, 'cs_side': 1.2, 'cs_rear': 1.4, 'cs_aisle_min': 1.2,
    'cs_bays': 3, 'cs_bay_w': 1.1, 'cs_bay_d': 1.5, 'cs_front': 4, 'cs_screen_y': .5, 'cs_screen_w': 8,
    'cs_west': 2, 'cs_south': 2.5, ...edits,
  }));

void main() {
  const widthFt = 18 / .3048, depthFt = 20 / .3048;
  CinemaSeatingCadResult run(ProjectBrief b) => CinemaSeatingCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('specialist seating option preserves ordinary mode and excludes multiplexes', () {
    expect(cinemaSeatingCadEligible('commercial', 'business_services', 'cinema_entertainment'), isTrue);
    expect(cinemaSeatingCadEligible('commercial', 'business_services', 'multiplex'), isFalse);
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains(cinemaSeatingMode)));
    expect(cadOutputOptions(warehouseLoading: false, cinemaSeating: true).options.map((o) => o.id), contains(cinemaSeatingMode));
  });

  test('saved plan centres both fixed banks and keeps flexible bay counts separate', () {
    final saved = ProjectBrief.fromMap(cinema().toMap())!;
    expect(CinemaSeatingCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.fixedSeats, r.flexibleBays, r.seatsPerBank, r.rowGapMm, r.screenGapMm, r.hallWidthMm, r.hallDepthMm),
      (144, 6, 9, 450, 3500, 14000, 15300));
    final d = r.drawing!;
    final s = d.lines.where((l) => l.layer == 'CS_SEAT').toList();
    expect(s.length, 192);
    expect((s[0].start.x, s[0].start.y, s[0].end.x, s[12].start.x, s[12].end.x), (3225, 6500, 8175, 9825, 14775));
    final rearBays = d.lines.where((l) => l.layer == 'CS_BAY').toList();
    expect(rearBays.length, 10);
    expect((rearBays.first.start.x, rearBays.first.start.y, rearBays.first.end.x), (4050, 14900, 7350));
    final rearAisle = d.lines.where((l) => l.layer == 'CS_AISLE').last;
    expect((rearAisle.start.x, rearAisle.start.y, rearAisle.end.x), (2000, 16400, 16000));
    final screen = d.lines.singleWhere((l) => l.layer == 'CS_SCREEN');
    expect((screen.start.x, screen.start.y, screen.end.x), (5000, 3000, 13000));
    expect(d.toDxf(), contains('144 FIXED SEATS / 6 FLEXIBLE BAYS'));
    expect(r.toCsv(), contains('R8,9,9,0,0\r\nREAR,0,0,3,3\r\n'));
  });

  test('seat cap applies before target; exact fit shares bank and aisle boundaries', () {
    final capped = run(cinema(edits: {'cs_cap': 8, 'cs_target': 128}));
    expect((capped.issue, capped.fixedSeats, capped.flexibleBays), (null, 128, 6));
    final exact = run(cinema(edits: {'cs_seat_w': .625, 'cs_target': 128, 'cs_bays': 4, 'cs_bay_w': 1.25,
      'left_setback': 2, 'right_setback': 2, 'front_setback': 2.5, 'rear_setback': 2.2}));
    expect((exact.issue, exact.fixedSeats, exact.flexibleBays), (null, 128, 8));
    expect(exact.drawing!.lines.where((l) => l.layer == 'CS_SEAT').length, 144);
    expect(exact.drawing!.lines.where((l) => l.layer == 'CS_BAY').length, 8);
  });

  test('invalid aisles, row clearance, target, flexible bays, screen and setbacks block both exports', () {
    for (final (brief, reason) in [
      (cinema(type: 'multiplex'), 'Select Cinema / Entertainment'),
      (cinema(edits: {'cs_rows': 2.5}), 'valid whole numbers'),
      (cinema(edits: {'cs_side': 1.199}), 'aisle is below'),
      (cinema(edits: {'cs_pitch': 1.049}), 'clear strip behind occupied seats'),
      (cinema(edits: {'cs_hall': 4}), 'not enough width for two fixed-seat banks'),
      (cinema(edits: {'cs_target': 145}), 'Only 144 fixed seats fit'),
      (cinema(edits: {'cs_bay_w': 1.667}), 'flexible bays do not fit'),
      (cinema(edits: {'cs_screen_y': 4}), 'strictly in front of the first row'),
      (cinema(edits: {'rear_setback': 2.201}), 'rear plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid drawing offers plan and seating schedule', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CinemaSeatingCadScreen(name: 'Cinema', brief: cinema(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('144 fixed seats · 6 flexible bays'), findsOneWidget);
    expect(find.text('Share seating plan DXF'), findsOneWidget);
    expect(find.text('Share seating schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a failed brief without generic fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'cinema', name: 'Cinema conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: cinema(edits: {'cs_target': 145}));
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
    await tester.tap(find.text('Cinema seating CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only 144 fixed seats fit'), findsOneWidget);
    expect(find.text('Share seating plan DXF'), findsNothing);
    expect(find.text('Share seating schedule CSV'), findsNothing);
  });
}
