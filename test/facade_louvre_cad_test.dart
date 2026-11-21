import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/facade_louvre_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/facade_louvre_cad_screen.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/facade_louvre_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief louvre({Map<String, Object> edits = const {}, String type = 'corporate_office', String action = 'renovation'}) =>
    ProjectBrief(floorCount: 3, features: const [], parking: null,
      taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'commercial', subcategoryId: 'office',
        typeId: type, configurationId: 'open_workspace', actionId: action, plotShapeId: 'rectangular'),
      requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
        'cad_output': facadeLouvreMode, 'fl_width': 3.6, 'fl_height': 2.4, 'fl_side': .15, 'fl_sill': .1,
        'fl_head': .1, 'fl_pitch': .4, 'fl_thickness': .04, 'fl_projection': .36, 'fl_low': 15, 'fl_high': 45,
        'fl_min_open': 73.2, 'fl_min_shade': 100, ...edits,
      }));

void main() {
  final run = FacadeLouvreCadGenerator().generate;
  test('office façade opt-in preserves other office CAD choices', () {
    expect(facadeLouvreCadEligible('commercial', 'office', 'small_office'), isTrue);
    expect(facadeLouvreCadEligible('commercial', 'office', 'branch_office'), isTrue);
    expect(facadeLouvreCadEligible('commercial', 'retail', 'corporate_office'), isFalse);
    final ordinary = cadOutputOptions(warehouseLoading: false, officeWorkplace: true).options.map((o) => o.id);
    expect(ordinary, contains('office_workplace'));
    expect(ordinary, isNot(contains(facadeLouvreMode)));
    expect(cadOutputOptions(warehouseLoading: false, officeWorkplace: true, facadeLouvre: true).options.map((o) => o.id),
      containsAll([...ordinary, facadeLouvreMode]));
  });

  test('saved louvre bay exports count, clear gap and two true-scale grazing rays', () {
    final saved = ProjectBrief.fromMap(louvre().toMap())!;
    expect(FacadeLouvreCadGenerator.requested(saved), isTrue);
    final r = run(saved);
    expect(r.issue, isNull);
    expect((r.count, r.spanMm, r.clearMm, r.headMm), (6, 3300, 360, 260));
    expect(r.lowerOpen, closeTo(73.2050807569, 1e-9));
    expect(r.upperShade, closeTo(100, 1e-9));
    expect(r.cutoffDeg, closeTo(45, 1e-9));
    final elev = r.elevation!, section = r.section!;
    final blades = elev.lines.where((l) => l.layer == 'FL_BLADE');
    expect(blades.length, 24);
    final first = blades.first, top = blades.elementAt(21);
    expect((first.start.x, first.start.y, first.end.x, first.end.y), (150, 100, 3450, 100));
    expect((top.start.y, top.end.y), (2140, 2140));
    final cut = elev.lines.singleWhere((l) => l.layer == 'FL_CUT');
    expect((cut.start.x, cut.end.x, cut.end.y), (1800, 1800, 2400));
    final low = section.lines.singleWhere((l) => l.layer == 'FL_LOW');
    final high = section.lines.singleWhere((l) => l.layer == 'FL_HIGH');
    expect((low.start.x, low.start.y, low.end.x), (360, 500, 0));
    expect(low.end.y, closeTo(403.538290725, 1e-8));
    expect(high.end.x, closeTo(0, 1e-9));
    expect(high.end.y, closeTo(140, 1e-9));
    expect(elev.toDxf(), contains('6 BLADES / 3.300 M SPAN / 0.360 M CLEAR GAP / 0.260 M TOP RESERVE'));
    expect(section.toDxf(), contains('FULL CUT-OFF 45.000 DEG / COMPLETE GAPS ONLY'));
  });

  test('zero margins use shared edges, zero-angle ray is implicit, and steep ray stops on lower blade', () {
    final r = run(louvre(edits: {'fl_height': 2.04, 'fl_side': 0, 'fl_sill': 0, 'fl_head': 0, 'fl_low': 0,
      'fl_min_open': 100, 'fl_high': 60}));
    expect(r.issue, isNull);
    expect((r.count, r.headMm, r.spanMm, r.lowerOpen, r.upperShade), (6, 0, 3600, 100, 100));
    expect(r.elevation!.lines.where((l) => l.layer == 'FL_BLADE').length, 10);
    expect(r.section!.lines.where((l) => l.layer == 'FL_LOW'), isEmpty);
    final high = r.section!.lines.singleWhere((l) => l.layer == 'FL_HIGH');
    expect(high.end.x, closeTo(152.153903092, 1e-9));
    expect(high.end.y, 40);
  });

  test('failed measurement, fit or solar criteria block both DXFs', () {
    for (final (b, reason) in [
      (louvre(type: 'headquarters'), 'Select Small Office'),
      (louvre(action: 'site_development'), 'early design or renovation'),
      (louvre(edits: {'fl_low': '15'}), 'Enter valid bay'),
      (louvre(edits: {'fl_high': 15}), 'must exceed the lower'),
      (louvre(edits: {'fl_side': 1.8}), 'no blade span'),
      (louvre(edits: {'fl_thickness': .4}), 'smaller than pitch'),
      (louvre(edits: {'fl_height': .639}), 'At least two blades'),
      (louvre(edits: {'fl_height': 30}), 'at most 60 blades'),
      (louvre(edits: {'fl_min_open': 73.206}), 'less than the submitted directly lit'),
      (louvre(edits: {'fl_high': 44.9}), 'less than the submitted shaded fraction'),
    ]) {
      final r = run(b);
      expect(r.issue, contains(reason));
      expect(r.elevation, isNull);
      expect(r.section, isNull);
    }
  });

  testWidgets('valid bay switches from elevation to section', (tester) async {
    await tester.pumpWidget(MaterialApp(home: FacadeLouvreCadScreen(name: 'Bay', brief: louvre())));
    expect(find.text('6 blades · 3.300 m span · 0.360 m clear gap'), findsOneWidget);
    expect(find.text('Share louvre elevation DXF'), findsOneWidget);
    await tester.tap(find.text('Section A–A'));
    await tester.pumpAndSettle();
    expect(find.text('Share louvre section DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens a shade conflict without fallback or export', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'louvre', name: 'Shade conflict', width: 100, length: 100,
      bhk: '', floors: '3', facing: 'Not decided', createdAt: now, updatedAt: now, brief: louvre(edits: {'fl_high': 44.9}));
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
    await tester.tap(find.text('Façade louvre CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('less than the submitted shaded fraction'), findsOneWidget);
    expect(find.text('Share louvre elevation DXF'), findsNothing);
    expect(find.text('Share louvre section DXF'), findsNothing);
  });
}
