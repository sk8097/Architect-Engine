import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/dock_leveller_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/dock_leveller_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/dock_leveller_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief dock({Map<String, Object> edits = const {}, String type = 'general_warehouse',
  String? config = 'rack_storage', int? floors = 1}) => ProjectBrief(floorCount: floors, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'industrial', subcategoryId: 'logistics',
      typeId: type, configurationId: config, actionId: 'concept_design', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': dockLevellerMode, 'dl_hinge': 1.2, 'dl_low': .5, 'dl_high': 1.7, 'dl_deck': 2.5, 'dl_lip': .45,
      'dl_gap': 2.55, 'dl_landing': .4, 'dl_overlap': .3, 'dl_joint': .05, 'dl_grade': 30, 'dl_deck_w': 2,
      'dl_bed_w': 2.4, 'dl_side': .8, 'dl_inside': 1.5, 'dl_west': 2, 'dl_south': 3,
      'left_setback': 2, 'right_setback': 4, 'front_setback': 3, 'rear_setback': 4, ...edits,
    }));

void main() {
  const widthFt = 10 / .3048, depthFt = 11.45 / .3048;
  DockLevellerCadResult run(ProjectBrief b) => DockLevellerCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('dock leveller is opt-in and preserves ordinary warehouse loading choices', () {
    expect(dockLevellerCadEligible('industrial', 'logistics', 'general_warehouse'), isTrue);
    expect(dockLevellerCadEligible('industrial', 'logistics', 'distribution_centre'), isTrue);
    expect(dockLevellerCadEligible('industrial', 'logistics', 'cross_dock'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: true).options.map((o) => o.id);
    expect(ordinary, contains('warehouse_loading'));
    expect(ordinary, isNot(contains(dockLevellerMode)));
    expect(cadOutputOptions(warehouseLoading: true, dockLeveller: true).options.map((o) => o.id),
      containsAll([...ordinary, dockLevellerMode]));
  });

  test('saved bay fits exactly; separate section includes interior level position', () {
    final saved = ProjectBrief.fromMap(dock().toMap())!;
    expect(DockLevellerCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.minOverlapMm, r.maxOverlapMm, r.jointGapMm), (4000, 4450, 300, 400, 50));
    expect(r.maxGrade, closeTo(175 / 6, 1e-9));
    final plan = r.plan!, section = r.section!;
    final rear = plan.lines.singleWhere((l) => l.layer == 'DL_LANDING' && l.start.y == l.end.y);
    expect((rear.start.x, rear.end.x, rear.start.y), (2800, 5200, 3400));
    final short = plan.lines.singleWhere((l) => l.layer == 'DL_SHORT');
    expect((short.start.x, short.end.x, short.start.y), (3000, 5000, 3100));
    final deck = section.lines.where((l) => l.layer == 'DL_DECK').toList();
    expect(deck.length, 3);
    expect(deck.map((l) => (l.start.x, l.start.y)), [(0, 1200), (0, 1200), (0, 1200)]);
    expect(deck.map((l) => l.end.y), [500, 1200, 1700]);
    expect((deck[0].end.x, deck[1].end.x), (2400, 2500));
    expect(deck[2].end.x, closeTo(2449.489743, 1e-6));
    final levelLip = section.lines.singleWhere((l) => l.layer == 'DL_LIP' && l.start.y == 1200);
    expect((levelLip.start.x, levelLip.end.x, levelLip.end.y), (2500, 2950, 1200));
    expect(plan.toDxf(), contains('FULL ENVELOPE 4.000 x 4.450 M / LIP OVERLAP 0.300 TO 0.400 M'));
    expect(section.toDxf(), contains('BED LEVELS 0.500 TO 1.700 M / MAX GRADE 29.167%'));
  });

  test('one-sided ranges use the nearest endpoint and a singleton draws one position', () {
    final r = run(dock(config: null, floors: null, edits: {'dl_high': .7, 'dl_landing': .35, 'dl_joint': .1}));
    expect(r.issue, isNull);
    expect(r.maxOverlapMm, closeTo(349.489743, 1e-6));
    expect(r.section!.lines.where((l) => l.layer == 'DL_DECK').length, 2);
    final single = run(dock(edits: {'dl_high': .5}));
    expect(single.issue, isNull);
    expect(single.maxOverlapMm, 300);
    expect(single.section!.lines.where((l) => l.layer == 'DL_DECK').length, 1);
    expect(single.plan!.lines.where((l) => l.layer == 'DL_SHORT'), isEmpty);
  });

  test('rejects conflicts even if both endpoints fit but the interior horizontal position does not', () {
    for (final (b, reason) in [
      (dock(type: 'cold_storage'), 'Select General Warehouse or Distribution Centre'),
      (dock(config: 'mezzanine'), 'Open Storage or Rack Storage'),
      (dock(floors: 2), 'one dock bay only'),
      (dock(edits: {'dl_low': 1.701}), 'must not exceed the highest'),
      (dock(edits: {'dl_bed_w': 1.999}), 'narrower than the deck'),
      (dock(edits: {'dl_high': 3.7}), 'positive horizontal run'),
      (dock(edits: {'dl_grade': 29.16}), 'grade exceeds'),
      (dock(edits: {'dl_joint': .051}), 'too close to the truck rear edge'),
      (dock(edits: {'dl_overlap': .301}), 'less than the submitted minimum overlap'),
      (dock(edits: {'dl_landing': .399}), 'exceeds the usable truck-bed landing depth'),
      (dock(edits: {'dl_side': .801}), 'right plot edge'),
      (dock(edits: {'rear_setback': 4.001}), 'rear plot edge'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('valid template switches from plan to section', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DockLevellerCadScreen(name: 'Bay', brief: dock(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Lip overlap 0.300–0.400 m'), findsOneWidget);
    expect(find.text('Share dock plan DXF'), findsOneWidget);
    await tester.tap(find.text('Section A–A'));
    await tester.pumpAndSettle();
    expect(find.text('Share dock section DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved landing conflict without fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'dock', name: 'Landing conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '1', facing: 'Not decided', createdAt: now, updatedAt: now, brief: dock(edits: {'dl_landing': .399}));
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
    await tester.tap(find.text('Dock leveller CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('exceeds the usable truck-bed landing depth'), findsOneWidget);
    expect(find.text('Share dock plan DXF'), findsNothing);
    expect(find.text('Share dock section DXF'), findsNothing);
  });
}
