import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/guyed_mast_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/guyed_mast_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/guyed_mast_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief mast({Map<String, Object> edits = const {}, String type = 'telecom_tower'}) =>
  ProjectBrief(floorCount: null, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'energy',
      typeId: type, configurationId: 'outdoor_yard', actionId: 'site_development', plotShapeId: 'square'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': guyedMastMode, 'gm_x': 30, 'gm_y': 30, 'gm_pad': 4, 'gm_anchor': 4, 'gm_attach': 15,
      'gm_min_angle': 30, 'gm_max_angle': 45, 'gm_max_gap': 130,
      'gm_a_x': 30, 'gm_a_y': 50, 'gm_a_z': 0, 'gm_b_x': 48, 'gm_b_y': 18, 'gm_b_z': 1,
      'gm_c_x': 12, 'gm_c_y': 18, 'gm_c_z': -1, 'left_setback': 5, 'right_setback': 5,
      'front_setback': 5, 'rear_setback': 8, ...edits,
    }));

void main() {
  const sideFt = 60 / .3048;
  GuyedMastCadResult run(ProjectBrief b) => GuyedMastCadGenerator().generate(b, widthFt: sideFt, depthFt: sideFt);

  test('Telecom Tower opt-in leaves ordinary and telecom duct-bank modes unchanged', () {
    expect(guyedMastCadEligible('infrastructure', 'energy', 'telecom_tower'), isTrue);
    expect(guyedMastCadEligible('infrastructure', 'energy', 'telecom_network'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(guyedMastMode)));
    expect(cadOutputOptions(warehouseLoading: false, guyedMast: true).options.map((o) => o.id), containsAll([...ordinary, guyedMastMode]));
  });

  test('reopened brief uses signed anchor levels and exact plan projections', () {
    final saved = ProjectBrief.fromMap(mast().toMap())!;
    expect(GuyedMastCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect(r.maxGap, closeTo(123.690067526, 1e-8));
    expect(r.anchors.map((a) => a.levelMm), [0, 1000, -1000]);
    expect(r.anchors.first.chordMm, 25000);
    expect(r.anchors.first.angle, closeTo(36.869897646, 1e-8));
    expect(r.anchors.last.chordMm, greaterThan(r.anchors[1].chordMm));
    final plan = r.drawing!;
    final guys = plan.lines.where((l) => l.layer == 'GM_GUY');
    expect(guys.map((l) => (l.start.x, l.start.y, l.end.x, l.end.y)), [
      (30000, 30000, 30000, 50000), (30000, 30000, 48000, 18000), (30000, 30000, 12000, 18000),
    ]);
    final reserve = plan.lines.where((l) => l.layer == 'GM_ANCHOR').toList();
    expect(reserve.length, 12);
    expect((reserve[2].start.y, reserve[2].end.y), (52000, 52000));
    expect(plan.toDxf(), contains('MAX AZIMUTH GAP 123.690 DEG'));
    expect(r.toCsv(), startsWith('anchor_id,x_m,y_m,level_m,plan_run_m,azimuth_deg,upward_angle_deg,straight_chord_m\r\nA,30.000,50.000,0.000,20.000,0.000,36.870,25.000\r\n'));
    expect(r.toCsv(), endsWith('C,12.000,18.000,-1.000,21.633,236.310,36.487,26.907\r\n'));
  });

  test('gap check wraps through north and reserves may touch but not overlap', () {
    final wrap = run(mast(edits: {'gm_a_x': 25, 'gm_max_gap': 140}));
    expect(wrap.issue, isNull);
    expect(wrap.maxGap, closeTo(137.726310994, 1e-8));
    expect(run(mast(edits: {'gm_a_x': 25})).issue, contains('137.726 degrees'));
    final touching = run(mast(edits: {'gm_anchor': 12, 'gm_a_y': 38, 'gm_a_z': 9}));
    expect(touching.issue, isNull);
    final overlapping = run(mast(edits: {'gm_anchor': 12, 'gm_a_y': 37.999, 'gm_a_z': 9}));
    expect(overlapping.issue, contains('overlaps the mast pad'));
  });

  test('scope, level, angles, setbacks and angular distribution block both exports', () {
    for (final (brief, reason) in [
      (mast(type: 'telecom_network'), 'Select Telecom Tower'),
      (mast(edits: {'gm_a_z': 15}), 'below the common guy attachment'),
      (mast(edits: {'gm_a_y': 30}), 'away from the mast'),
      (mast(edits: {'gm_min_angle': 46}), 'minimum upward guy angle exceeds'),
      (mast(edits: {'gm_max_angle': 36}), 'Anchor A gives an upward angle'),
      (mast(edits: {'rear_setback': 8.001}), 'Anchor A reserve conflicts'),
      (mast(edits: {'gm_max_gap': 123.689}), 'Largest consecutive azimuth gap'),
    ]) {
      final r = run(brief);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid mode previews both exports', (tester) async {
    await tester.pumpWidget(MaterialApp(home: GuyedMastCadScreen(name: 'Mast', brief: mast(), widthFt: sideFt, depthFt: sideFt)));
    expect(find.textContaining('Largest azimuth gap 123.690'), findsOneWidget);
    expect(find.text('Share mast plan DXF'), findsOneWidget);
    expect(find.text('Share anchor schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens saved conflict without generic fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'mast', name: 'Mast conflict', width: sideFt, length: sideFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: mast(edits: {'gm_a_x': 25}));
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
    await tester.tap(find.text('Guyed mast CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Largest consecutive azimuth gap'), findsOneWidget);
    expect(find.text('Share mast plan DXF'), findsNothing);
    expect(find.text('Share anchor schedule CSV'), findsNothing);
  });
}
