import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/refuge_crossing_cad_fields.dart';
import 'package:architect_engine/data/survey_corridor_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/refuge_crossing_cad_screen.dart';
import 'package:architect_engine/services/refuge_crossing_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief refuge({Map<String, Object> edits = const {}, String type = 'street'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'transport',
    typeId: type, configurationId: 'linear_corridor'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'corridor_cad_mode': refugeCrossingMode, 'ref_grid': 'Example grid', 'ref_axis': '1000,2000;1060,2080',
    'ref_ch_l': 35, 'ref_ch_r': 43, 'ref_road_l': 7, 'ref_road_r': 7.5, 'ref_median': 4,
    'ref_cross_w': 3, 'ref_walk_w': 2, 'ref_min_w': 2, 'ref_reserve': 1, 'ref_stagger': 5,
    'ref_land_l': 2.5, 'ref_land_r': 3, 'ref_min_land': 2.5, ...edits,
  }));

void main() {
  final generator = RefugeCrossingCadGenerator();

  test('specialist mode is opt-in and preserves existing street corridor choices', () {
    expect(refugeCrossingCadEligible('infrastructure', 'transport', 'street'), isTrue);
    expect(refugeCrossingCadEligible('infrastructure', 'transport', 'road'), isFalse);
    expect(surveyCorridorMode.options.map((o) => o.id), isNot(contains(refugeCrossingMode)));
    expect(surveyCorridorModeField(includeRefugeCrossing: true).options.map((o) => o.id),
      containsAll(['survey_circular', refugeCrossingMode]));
    expect(RefugeCrossingCadGenerator.requested(refuge(edits: {'corridor_cad_mode': 'survey_circular'})), isFalse);
  });

  test('projected widths, uninterrupted open mouths and centreline length survive save', () {
    final saved = ProjectBrief.fromMap(refuge().toMap())!;
    expect(RefugeCrossingCadGenerator.requested(saved), isTrue);
    final r = generator.generate(saved);
    expect(r.issue, isNull);
    expect((r.crossingMm, r.walkMm, r.staggerMm, r.openingGapMm, r.reserveMm, r.routeMm), (3000, 2000, 8000, 5000, 1000, 32000));
    final d = r.drawing!;
    expect(d.lines.where((l) => l.layer == 'REF_ROAD').length, 4);
    expect(d.lines.where((l) => l.layer == 'REF_MEDIAN').length, 4);
    expect(d.lines.where((l) => l.layer == 'REF_LAND').length, 6);
    final crossing = d.lines.firstWhere((l) => l.layer == 'REF_CROSS');
    expect((crossing.start.x, crossing.start.y, crossing.end.x, crossing.end.y), (1018500, 2028000, 1012900, 2032200));
    final walk = d.lines.where((l) => l.layer == 'REF_WALK').toList();
    expect(walk.length, 6);
    expect((walk[1].start.x, walk[1].start.y, walk[1].end.x, walk[1].end.y), (1021100, 2029800, 1025900, 2036200));
    final route = d.lines.where((l) => l.layer == 'REF_ROUTE').toList();
    expect((route.first.start.x, route.first.start.y, route.last.end.x, route.last.end.y), (1011800, 2034900, 1035800, 2026900));
    expect(d.toDxf(), contains('CENTRELINE ROUTE 32.000 M / GRID: Example grid'));
  });

  test('reverse stagger preserves side mapping; exact bounds and full-width walk avoid duplicate edges', () {
    final reversed = generator.generate(refuge(edits: {'ref_ch_l': 43, 'ref_ch_r': 35}));
    expect(reversed.issue, isNull);
    expect(reversed.routeMm, 32000);
    final line = reversed.drawing!.lines.firstWhere((l) => l.layer == 'REF_WALK');
    expect((line.start.x, line.start.y), (1023300, 2034400));
    final full = generator.generate(refuge(edits: {'ref_ch_l': 1.5, 'ref_ch_r': 98.5, 'ref_walk_w': 4, 'ref_reserve': 0}));
    expect(full.issue, isNull);
    expect(full.drawing!.lines.where((l) => l.layer == 'REF_MEDIAN').length, 2);
    // The longitudinal edges are the median edges in this case; only two
    // transverse end caps remain on the walk layer.
    final caps = full.drawing!.lines.where((l) => l.layer == 'REF_WALK').toList();
    expect(caps.length, 2);
    for (final cap in caps) {
      expect(((cap.end.x - cap.start.x).abs(), (cap.end.y - cap.start.y).abs()), (3200, 2400));
    }
  });

  test('invalid crossing widths, station extents, reserves and landings block DXF', () {
    for (final (brief, reason) in [
      (refuge(type: 'road'), 'Select Street'),
      (refuge(edits: {'ref_axis': '1000,2000;1000,2000'}), 'positive median baseline'),
      (refuge(edits: {'ref_ch_l': 1.499}), 'full left crossing opening'),
      (refuge(edits: {'ref_ch_r': 98.501}), 'full right crossing opening'),
      (refuge(edits: {'ref_ch_r': 42.999}), 'less than the submitted longitudinal gap'),
      (refuge(edits: {'ref_cross_w': 1.999}), 'crossing openings are narrower'),
      (refuge(edits: {'ref_walk_w': 1.999}), 'median walk is narrower'),
      (refuge(edits: {'ref_reserve': 1.001}), 'both side reserves do not fit'),
      (refuge(edits: {'ref_land_l': 2.499}), 'left roadside landing'),
      (refuge(edits: {'ref_land_r': 2.499}), 'right roadside landing'),
    ]) {
      final r = generator.generate(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
    }
  });

  testWidgets('valid preview offers layered DXF', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RefugeCrossingCadScreen(name: 'Refuge', brief: refuge())));
    expect(find.textContaining('5.000 m between opening edges'), findsOneWidget);
    expect(find.text('Share pedestrian refuge DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a failed stagger without fallback or DXF', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'ref', name: 'Refuge conflict', width: 0, length: 0,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: refuge(edits: {'ref_ch_r': 36}));
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
    await tester.tap(find.text('Surveyed pedestrian refuge CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('crossing windows overlap'), findsOneWidget);
    expect(find.text('Share pedestrian refuge DXF'), findsNothing);
  });
}
