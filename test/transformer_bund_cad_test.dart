import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/transformer_bund_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/transformer_bund_cad_screen.dart';
import 'package:architect_engine/services/transformer_bund_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief bund({Map<String, Object> edits = const {}, String type = 'transformer_yard', String config = 'outdoor_yard'}) =>
  ProjectBrief(floorCount: null, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'energy',
      typeId: type, configurationId: config, actionId: 'site_development', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': transformerBundMode, 'tb_w': 10, 'tb_l': 8, 'tb_wall': .25, 'tb_rim': 1.2, 'tb_fill': .9,
      'tb_free_min': .3, 'tb_p_w': 2, 'tb_p_l': 3, 'tb_h_w': .4, 'tb_h_e': 1.1,
      'tb_gap': 2, 'tb_clear': 2, 'tb_reserve': 1.25, 'tb_west': 3, 'tb_south': 2, 'tb_volume': 64.2,
      'left_setback': 3, 'right_setback': 4, 'front_setback': 2, 'rear_setback': 4, ...edits,
    }));

void main() {
  const widthFt = 20 / .3048, depthFt = 17 / .3048;
  TransformerBundCadResult run(ProjectBrief b) => TransformerBundCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('Transformer Yard opt-in preserves ordinary CAD and excludes battery yards', () {
    expect(transformerBundCadEligible('infrastructure', 'energy', 'transformer_yard'), isTrue);
    expect(transformerBundCadEligible('infrastructure', 'energy', 'battery_energy_storage'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(transformerBundMode)));
    expect(cadOutputOptions(warehouseLoading: false, transformerBund: true).options.map((o) => o.id), containsAll([...ordinary, transformerBundMode]));
  });

  test('saved plan centres plinths and section clips fill at the taller solid only', () {
    final saved = ProjectBrief.fromMap(bund().toMap())!;
    expect(TransformerBundCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.freeboardMm, r.grossM3, r.displacedM3, r.netM3), (13000, 11000, 300, 72, 7.8, 64.2));
    final plan = r.plan!, section = r.section!;
    final plinths = plan.lines.where((l) => l.layer == 'TB_PLINTH').toList();
    expect(plinths.length, 8);
    expect((plinths[0].start.x, plinths[0].start.y, plinths[4].start.x, plinths[4].start.y), (6500, 6000, 10500, 6000));
    final cut = plan.lines.singleWhere((l) => l.layer == 'TB_CUT');
    expect((cut.start.x, cut.start.y, cut.end.x, cut.end.y), (3000, 7500, 16000, 7500));
    final level = section.lines.where((l) => l.layer == 'TB_LEVEL');
    expect(level.map((l) => (l.start.x, l.start.y, l.end.x, l.end.y)), [(1500, 900, 7500, 900), (9500, 900, 11500, 900)]);
    expect(section.lines.where((l) => l.layer == 'TB_FLOOR').length, 3);
    expect(plan.toDxf(), contains('FULL SERVICE ENVELOPE 13.000 x 11.000 M / NET 64.200 M3'));
    expect(section.toDxf(), contains('GROSS 72.000 M3 - SOLID PLINTH DISPLACEMENT 7.800 M3'));
  });

  test('a plinth top exactly at fill is not overdrawn by the fill line', () {
    final r = run(bund(edits: {'tb_h_w': .9, 'tb_h_e': .5, 'tb_volume': 63.6}));
    expect((r.issue, r.netM3), (null, 63.6));
    final level = r.section!.lines.where((l) => l.layer == 'TB_LEVEL');
    expect(level.map((l) => (l.start.x, l.end.x)), [(1500, 3500), (5500, 11500)]);
  });

  test('invalid scope, clearances, freeboard, setbacks and net volume block both sheets', () {
    for (final (brief, reason) in [
      (bund(type: 'battery_energy_storage'), 'Select Transformer Yard'),
      (bund(config: 'enclosed_facility'), 'Outdoor Yard'),
      (bund(edits: {'tb_fill': .901}), 'insufficient freeboard'),
      (bund(edits: {'tb_gap': 1.999}), 'gap between plinths'),
      (bund(edits: {'tb_p_w': 2.001}), 'clearance to every inner wall'),
      (bund(edits: {'tb_p_l': 4.001}), 'clearance to every inner wall'),
      (bund(edits: {'right_setback': 4.001}), 'right plot edge'),
      (bund(edits: {'tb_volume': 64.2001}), 'below the submitted target'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('valid CAD switches from plan to true-scale section', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TransformerBundCadScreen(name: 'Bund', brief: bund(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.text('Net geometric containment 64.200 m³'), findsOneWidget);
    expect(find.text('Share bund plan DXF'), findsOneWidget);
    await tester.tap(find.text('Section A–A'));
    await tester.pumpAndSettle();
    expect(find.text('Share bund section DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved volume conflict without fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'bund', name: 'Bund conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: bund(edits: {'tb_volume': 65}));
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
    await tester.tap(find.text('Transformer bund CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('below the submitted target'), findsOneWidget);
    expect(find.text('Share bund plan DXF'), findsNothing);
    expect(find.text('Share bund section DXF'), findsNothing);
  });
}
