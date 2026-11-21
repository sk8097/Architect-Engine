import 'package:architect_engine/data/circular_clarifier_cad_fields.dart';
import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/circular_clarifier_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/circular_clarifier_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief clarifier({Map<String, Object> edits = const {}, String type = 'sewage_treatment_plant', String setting = 'plant'}) =>
  ProjectBrief(floorCount: null, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'water',
      typeId: type, configurationId: setting, actionId: 'concept_design', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': circularClarifierMode, 'cc_inside': 20, 'cc_wall': .3, 'cc_launder': 1, 'cc_feed': 4, 'cc_min_clear': 7,
      'cc_rim': 4, 'cc_water': 3.4, 'cc_free': .6, 'cc_trough_z': 3, 'cc_feed_lower': 1.4, 'cc_feed_upper': 3.8,
      'cc_reserve': 1.7, 'cc_west': 2, 'cc_south': 3, 'cc_min_area': 241.9,
      'left_setback': 2, 'right_setback': 4, 'front_setback': 3, 'rear_setback': 4, ...edits,
    }));

void main() {
  const widthFt = 30 / .3048, depthFt = 31 / .3048;
  CircularClarifierCadResult run(ProjectBrief b) => CircularClarifierCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('opt-in applies only to Sewage Treatment Plant', () {
    expect(circularClarifierCadEligible('infrastructure', 'water', 'sewage_treatment_plant'), isTrue);
    expect(circularClarifierCadEligible('infrastructure', 'water', 'water_treatment_plant'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(circularClarifierMode)));
    expect(cadOutputOptions(warehouseLoading: false, circularClarifier: true).options.map((o) => o.id), containsAll([...ordinary, circularClarifierMode]));
  });

  test('saved geometry excludes the launder and feedwell from the settling area', () {
    final b = ProjectBrief.fromMap(clarifier().toMap())!;
    expect(CircularClarifierCadGenerator.requested(b), isTrue);
    final r = run(b);
    expect(r.issue, isNull);
    expect((r.diameterMm, r.radialClearMm, r.freeboardMm), (24000, 7000, 600));
    expect(r.settlingM2, closeTo(241.90263432641407, 1e-9));
    expect(r.weirM, closeTo(56.548667764616276, 1e-9));
    final plan = r.plan!, section = r.section!;
    expect(plan.arcs.map((a) => a.radius), [12000, 12000, 10300, 10300, 10000, 10000, 9000, 9000, 2000, 2000]);
    expect(plan.arcs.every((a) => a.center.x == 14000 && a.center.y == 15000), isTrue);
    final water = section.lines.where((l) => l.layer == 'CC_WATER');
    expect(water.map((l) => (l.start.x, l.start.y, l.end.x, l.end.y)), [(3000, 3400, 10000, 3400), (21000, 3400, 14000, 3400)]);
    final weir = section.lines.where((l) => l.layer == 'CC_WEIR').toList();
    expect((weir[1].start.x, weir[1].start.y, weir[1].end.y), (3000, 3000, 3400));
    final feed = section.lines.where((l) => l.layer == 'CC_FEED');
    expect(feed.map((l) => (l.start.x, l.start.y, l.end.y)), [(10000, 1400, 3800), (14000, 1400, 3800)]);
    expect(plan.toDxf(), contains('SETTLING RING 241.903 M2 / NOMINAL WEIR 56.549 M'));
    expect(section.toDxf(), contains('FREEBOARD 0.600 M / CLEAR RING 7.000 M'));
  });

  test('odd-mm diameters preserve fractional centres and clearance', () {
    final r = run(clarifier(edits: {'cc_inside': 20.001, 'cc_reserve': 1.699}));
    expect(r.issue, isNull);
    expect((r.diameterMm, r.radialClearMm), (23999, 7000.5));
    final weir = r.plan!.arcs.firstWhere((a) => a.layer == 'CC_WEIR');
    expect((weir.center.x, weir.center.y, weir.radius), (13999.5, 14999.5, 9000.5));
  });

  test('invalid scope, levels, radial clearance, area and setbacks block both exports', () {
    for (final (b, reason) in [
      (clarifier(type: 'water_treatment_plant'), 'Select Sewage Treatment Plant'),
      (clarifier(setting: 'storage'), 'blank arrangement or Plant'),
      (clarifier(edits: {'cc_free': .601}), 'insufficient freeboard'),
      (clarifier(edits: {'cc_trough_z': 3.4}), 'launder bottom below'),
      (clarifier(edits: {'cc_feed_lower': 3.4}), 'feedwell lower edge must be below'),
      (clarifier(edits: {'cc_feed_upper': 3.4}), 'upper edge above water'),
      (clarifier(edits: {'cc_launder': 1.001}), 'clear radial settling width'),
      (clarifier(edits: {'cc_min_area': 241.903}), 'below the submitted minimum'),
      (clarifier(edits: {'right_setback': 4.001}), 'right plot edge'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('valid drawing switches from plan to diametral section', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CircularClarifierCadScreen(name: 'Clarifier', brief: clarifier(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Annular settling area 241.903 m²'), findsOneWidget);
    expect(find.text('Share clarifier plan DXF'), findsOneWidget);
    await tester.tap(find.text('Section A–A'));
    await tester.pumpAndSettle();
    expect(find.text('Share clarifier section DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved area conflict without fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'clarifier', name: 'Area conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: clarifier(edits: {'cc_min_area': 242}));
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
    await tester.tap(find.text('Circular clarifier CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('below the submitted minimum'), findsOneWidget);
    expect(find.text('Share clarifier plan DXF'), findsNothing);
    expect(find.text('Share clarifier section DXF'), findsNothing);
  });
}
