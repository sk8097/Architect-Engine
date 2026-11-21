import 'package:architect_engine/data/blade_laydown_cad_fields.dart';
import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/blade_laydown_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/blade_laydown_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief blade({Map<String, Object> edits = const {}, String type = 'wind_support_facility', String config = 'outdoor_yard'}) =>
  ProjectBrief(floorCount: null, features: const [], parking: null,
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure', subcategoryId: 'energy',
      typeId: type, configurationId: config, actionId: 'site_development', plotShapeId: 'rectangular'),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
      'cad_output': bladeLaydownMode, 'bl_length': 60, 'bl_root': 4, 'bl_peak_ch': 12, 'bl_peak': 6, 'bl_tip': .4,
      'bl_a_ch': 12, 'bl_b_ch': 42, 'bl_pad_l': 4, 'bl_a_w': 7, 'bl_b_w': 4, 'bl_min_margin': .5, 'bl_min_gap': 26,
      'bl_side': 2, 'bl_end': 3, 'bl_west': 3, 'bl_south': 4, 'left_setback': 3, 'right_setback': 4, 'front_setback': 4,
      'rear_setback': 4, ...edits,
    }));

void main() {
  const widthFt = 18 / .3048, depthFt = 74 / .3048;
  BladeLaydownCadResult run(ProjectBrief b) => BladeLaydownCadGenerator().generate(b, widthFt: widthFt, depthFt: depthFt);

  test('opt-in applies to Wind Support Facility only', () {
    expect(bladeLaydownCadEligible('infrastructure', 'energy', 'wind_support_facility'), isTrue);
    expect(bladeLaydownCadEligible('infrastructure', 'energy', 'solar_farm'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false).options.map((o) => o.id);
    expect(ordinary, isNot(contains(bladeLaydownMode)));
    expect(cadOutputOptions(warehouseLoading: false, bladeLaydown: true).options.map((o) => o.id), containsAll([...ordinary, bladeLaydownMode]));
  });

  test('saved plan and CSV report the interior peak and critical pad edge', () {
    final b = ProjectBrief.fromMap(blade().toMap())!;
    expect(BladeLaydownCadGenerator.requested(b), isTrue);
    final r = run(b);
    expect(r.issue, isNull);
    expect((r.widthMm, r.depthMm, r.gapMm), (11000, 66000, 26000));
    final a = r.pads.first, north = r.pads.last;
    expect((a.startMm, a.endMm, a.worstChMm, a.marginMm), (10000, 14000, 12000, 500));
    expect((north.startMm, north.endMm, north.worstChMm), (40000, 44000, 40000));
    expect(north.marginMm, closeTo(633.3333333, 1e-6));
    final d = r.drawing!;
    final pad = d.lines.where((l) => l.layer == 'BL_PAD').toList();
    expect(pad.length, 8);
    expect((pad[0].start.x, pad[0].start.y, pad[0].end.x, pad[4].start.x, pad[4].start.y), (5000, 17000, 12000, 6500, 47000));
    final outline = d.lines.where((l) => l.layer == 'BL_BLADE').toList();
    expect((outline[0].start.x, outline[0].start.y, outline[0].end.x, outline[0].end.y), (6500, 7000, 5500, 19000));
    expect((outline.last.start.x, outline.last.end.x, outline.last.start.y), (8300, 8700, 67000));
    expect(d.toDxf(), contains('CLEAR GAP 26.000 M / ENVELOPE 11.000 x 66.000 M'));
    expect(r.toCsv(), endsWith('A,10.000000,14.000000,7.000000,12.000000,6.000000,0.500000\r\nB,40.000000,44.000000,4.000000,40.000000,2.733333,0.633333\r\n'));
  });

  test('the widest interior station can fail even when both pad edges pass', () {
    final r = run(blade(edits: {'bl_a_ch': 11, 'bl_a_w': 6.9}));
    expect(r.issue, contains('Pad A leaves 0.450000 m per side at Ch 12.0000 m'));
    expect(r.drawing, isNull);
    expect(r.toCsv(), isNull);
  });

  test('pointed tip is valid and odd pad length retains half-mm intervals', () {
    final r = run(blade(edits: {'bl_tip': 0, 'bl_pad_l': 4.001, 'bl_min_gap': 25.999}));
    expect(r.issue, isNull);
    expect(r.drawing!.lines.where((l) => l.layer == 'BL_BLADE').length, 5);
    expect((r.pads.first.startMm, r.pads.first.endMm, r.gapMm), (9999.5, 14000.5, 25999));
  });

  test('scope, taper, pad position, inter-pad gap and fit conflicts block both exports', () {
    for (final (b, reason) in [
      (blade(type: 'solar_farm'), 'Select Wind Support Facility'),
      (blade(config: 'enclosed_facility'), 'Outdoor Yard'),
      (blade(edits: {'bl_peak_ch': 60}), 'widest blade station'),
      (blade(edits: {'bl_root': 6.001}), 'at least as wide as both ends'),
      (blade(edits: {'bl_a_ch': 1.999}), 'complete lengths between root and tip'),
      (blade(edits: {'bl_b_ch': 58.001}), 'complete lengths between root and tip'),
      (blade(edits: {'bl_min_gap': 26.001}), 'clear gap between pad reserves'),
      (blade(edits: {'bl_b_w': 3.733}), 'Pad B leaves'),
      (blade(edits: {'right_setback': 4.001}), 'right plot edge'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.drawing, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid plan shows DXF and pad schedule', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BladeLaydownCadScreen(name: 'Blade', brief: blade(), widthFt: widthFt, depthFt: depthFt)));
    expect(find.textContaining('Pad A: 0.500 m minimum per side'), findsOneWidget);
    expect(find.text('Share laydown plan DXF'), findsOneWidget);
    expect(find.text('Share pad schedule CSV'), findsOneWidget);
  });

  testWidgets('Projects reopens a saved pad conflict without fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'blade', name: 'Pad conflict', width: widthFt, length: depthFt,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now, brief: blade(edits: {'bl_min_margin': .501}));
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
    await tester.tap(find.text('Blade laydown CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('below the submitted margin'), findsOneWidget);
    expect(find.text('Share laydown plan DXF'), findsNothing);
    expect(find.text('Share pad schedule CSV'), findsNothing);
  });
}
