import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/park_fence_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/park_fence_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/park_fence_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief fence({Map<String, Object> edits = const {}, String type = 'public_park'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'public_realm',
    typeId: type, configurationId: 'public_open_space', actionId: 'site_development', plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': parkFenceMode, 'pf_w': 23, 'pf_d': 12, 'pf_post': .201, 'pf_gate_x': 9, 'pf_gate_w': 2, 'pf_gate_min': 2,
    'pf_min': 2, 'pf_max': 3, 'pf_west': 2, 'pf_south': 3, 'left_setback': 2, 'right_setback': 4, 'front_setback': 3,
    'rear_setback': 3, ...edits,
  }));

void main() {
  const widthFt = 29.201 / .3048, depthFt = 18.201 / .3048;
  ParkFenceCadResult run(ProjectBrief b) => ParkFenceCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('park fence is opt-in and never replaces ordinary or playground clearance CAD', () {
    expect(parkFenceCadEligible('infrastructure', 'public_realm', 'public_park'), isTrue);
    expect(parkFenceCadEligible('infrastructure', 'public_realm', 'public_garden'), isTrue);
    expect(parkFenceCadEligible('infrastructure', 'public_realm', 'playground'), isTrue);
    expect(parkFenceCadEligible('infrastructure', 'public_realm', 'urban_plaza'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false, playground: true).options.map((o) => o.id);
    expect(ordinary, isNot(contains(parkFenceMode)));
    expect(cadOutputOptions(warehouseLoading: false, playground: true, parkFence: true).options.map((o) => o.id), containsAll([...ordinary, parkFenceMode]));
  });

  test('saved dimensions preserve half-mm axes, a clear gate, and shared corner posts', () {
    final b = ProjectBrief.fromMap(fence().toMap())!;
    expect(ParkFenceCadGenerator.requested(b), isTrue);
    final r = run(b);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.gateMm, r.panels, r.posts), (23201, 12201, 2000, 23, 24));
    expect(r.runs.map((e) => e.panels), [3, 4, 4, 8, 4]);
    expect(r.runs.map((e) => e.centresMm), [8899.5, 11899.5, 12000, 23000, 12000]);
    expect(r.runs.first.clearPanelMm, closeTo(2765.5, 1e-9));
    final d = r.drawing!;
    final panel = d.lines.where((l) => l.layer == 'PF_PANEL').toList();
    expect(panel.length, 23);
    expect((panel.first.start.x, panel.first.start.y, panel.first.end.x), (2201, 3100.5, 4966.5));
    expect(panel[2].end.x, 10899.5);
    expect(panel[3].start.x, 13301.5);
    final gate = d.lines.where((l) => l.layer == 'PF_GATE_POST').toList();
    expect(gate.length, 8);
    expect(gate[4].start.x - gate[0].end.x, 2000);
    expect(d.lines.where((l) => l.layer == 'PF_POST').length, 88);
    expect(d.toDxf(), contains('23 PANELS / 24 POSTS / 1 SOUTH GATE'));
    expect(r.toCsv(), contains('south_west,8.899500,3,2.765500,2,\r\n'));
    expect(r.toCsv(), endsWith('total,,23,,18,24\r\n'));
  });

  test('exact maximum span does not add another bay', () {
    final r = run(fence(edits: {'pf_max': 2.799}));
    expect(r.issue, isNull);
    expect(r.runs.singleWhere((r) => r.id == 'east').panels, 4);
    final below = run(fence(edits: {'pf_max': 2.798}));
    expect(below.issue, isNull);
    expect(below.runs.singleWhere((r) => r.id == 'east').panels, 5);
  });

  test('setbacks, gate geometry and infeasible equal panels block exports', () {
    for (final (b, reason) in [
      (fence(type: 'urban_plaza'), 'Select Public Park'),
      (fence(edits: {'pf_gate_w': 1.999}), 'clear gate width'),
      (fence(edits: {'pf_gate_x': .1}), 'strictly between'),
      (fence(edits: {'pf_gate_x': 21}), 'strictly between'),
      (fence(edits: {'pf_min': 3.001}), 'minimum clear panel span exceeds'),
      (fence(edits: {'pf_min': 2.8}), 'No equal panel count fits the clear span limits on the south west run'),
      (fence(edits: {'right_setback': 4.001}), 'right plot edge'),
      (fence(edits: {'rear_setback': 3.001}), 'rear plot edge'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid drawing previews both export options', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ParkFenceCadScreen(name: 'Fence', brief: fence(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('23 panels · 24 unique posts'), findsOneWidget);
    expect(find.text('Share fence plan DXF'), findsOneWidget);
    expect(find.text('Share panel schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved spacing conflict without generic fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'fence', name: 'Fence conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: fence(edits: {'pf_min': 2.8}));
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
    await tester.tap(find.text('Park fence CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No equal panel count fits'), findsOneWidget);
    expect(find.text('Share fence plan DXF'), findsNothing);
    expect(find.text('Share panel schedule CSV'), findsNothing);
  });
}
