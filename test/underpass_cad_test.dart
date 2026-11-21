import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/underpass_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/underpass_cad_screen.dart';
import 'package:architect_engine/services/underpass_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief underpass({Map<String, Object> edits = const {}, String type = 'underpass'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure',
    subcategoryId: 'transport', typeId: type, configurationId: 'linear_corridor'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'underpass_mode': underpassMode, 'up_grid': 'Example grid', 'up_datum': 'Local RL', 'up_axis': '500000,2000000;500060,2000080',
    'up_walk': '5,100.8;25,99.8;\n45,99.6\r\n65,99.8;85,100.8', 'up_soffit': '23,102.5;35,102.25;55,102.25;67,102.5',
    'up_clear': 4, 'up_min_width': 4, 'up_wall': .3, 'up_corridor': 5, 'up_head': 2.55, 'up_grade': 5, ...edits,
  }));

void main() {
  final generator = UnderpassCadGenerator();

  test('projected plan and true-scale profile preserve portals and report governing centreline checks', () {
    expect(underpassCadEligible('infrastructure', 'transport', 'underpass'), isTrue);
    expect(underpassCadEligible('infrastructure', 'transport', 'tunnel'), isFalse);
    expect(UnderpassCadGenerator.requested(underpass(edits: {'underpass_mode': 'other'})), isFalse);
    final b = ProjectBrief.fromMap(underpass().toMap())!;
    expect(UnderpassCadGenerator.requested(b), isTrue);
    final r = generator.generate(b);
    expect(r.issue, isNull);
    expect((r.lengthMm, r.coveredMm, r.clearMm, r.minHeadMm, r.headStationMm, r.maxGrade), (80000, 44000, 4000, 2550, 35000, 5));
    final plan = r.plan!;
    final portal = plan.lines.firstWhere((l) => l.layer == 'UP_PORTAL');
    expect((portal.start.x, portal.start.y, portal.end.x, portal.end.y), (500015400, 2000017200, 500012200, 2000019600));
    expect(plan.lines.where((l) => l.layer == 'UP_WALL').length, 6);
    expect(plan.toDxf(), contains('PORTALS CH 23.000 AND 67.000 M'));
    final profile = r.profile!;
    final marker = profile.lines.singleWhere((l) => l.layer == 'UP_HEAD');
    expect((marker.start.x, marker.start.y, marker.end.x, marker.end.y), (35000, 700, 35000, 3250));
    final entry = profile.lines.firstWhere((l) => l.layer == 'UP_PORTAL');
    expect((entry.start.x, entry.start.y, entry.end.y), (23000, 900, 3500));
    expect(profile.toDxf(), contains('MIN VERTICAL HEADROOM 2.550 M AT CH 35.000 M'));
  });

  test('floor knots and interpolated endpoints can govern; exact lateral fit avoids coincident lines', () {
    final raisedWalk = generator.generate(underpass(edits: {'up_walk': '5,100.8;25,99.8;45,100.1;65,99.8;85,100.8', 'up_head': 2.15}));
    expect((raisedWalk.issue, raisedWalk.minHeadMm, raisedWalk.headStationMm), (null, 2150, 45000));
    final exact = generator.generate(underpass(edits: {'up_corridor': 4.6, 'up_soffit': '23,102.45;67,102.5'}));
    expect((exact.issue, exact.minHeadMm, exact.headStationMm), (null, 2550, 23000));
    expect(exact.plan!.lines.where((l) => l.layer == 'UP_LIMIT').length, 4);
    expect(exact.profile!.lines.where((l) => l.layer == 'UP_HEAD'), isEmpty);
  });

  test('grade, headroom, geometry and survey conflicts block both drawings', () {
    for (final (b, reason) in [
      (underpass(type: 'tunnel'), 'Select Underpass'),
      (underpass(edits: {'up_clear': 3.999}), 'narrower than the submitted minimum'),
      (underpass(edits: {'up_corridor': 4.599}), 'do not fit the submitted corridor'),
      (underpass(edits: {'up_soffit': '23,102.5;23,102.4'}), 'Soffit chainages must strictly increase'),
      (underpass(edits: {'up_soffit': '5,104;67,104'}), 'portals must be strictly inside'),
      (underpass(edits: {'up_soffit': '23,104;85,104'}), 'portals must be strictly inside'),
      (underpass(edits: {'up_grade': 4.999}), 'Walkway grade from Ch 5.000 to 25.000 m'),
      (underpass(edits: {'up_head': 2.551}), 'Vertical headroom at Ch 35.000 m'),
      (underpass(edits: {'up_walk': '5,100.8;25,99.8;45,100.1;65,99.8;85,100.8'}), 'Vertical headroom at Ch 45.000 m'),
    ]) {
      final r = generator.generate(b);
      expect(r.issue, contains(reason));
      expect(r.plan, isNull);
      expect(r.profile, isNull);
    }
  });

  testWidgets('profile toggle exposes the separate DXF', (tester) async {
    await tester.pumpWidget(MaterialApp(home: UnderpassCadScreen(name: 'Underpass', brief: underpass())));
    expect(find.text('Share underpass plan DXF'), findsOneWidget);
    await tester.tap(find.text('Longitudinal profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share underpass profile DXF'), findsOneWidget);
    expect(find.text('Share underpass plan DXF'), findsNothing);
  });

  testWidgets('Projects reopens low-headroom conflict without fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'up', name: 'Low underpass', width: 0, length: 0,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: underpass(edits: {'up_head': 2.551}));
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
    await tester.tap(find.text('Surveyed pedestrian underpass CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vertical headroom at Ch 35.000'), findsOneWidget);
    expect(find.text('Share underpass plan DXF'), findsNothing);
    expect(find.text('Share underpass profile DXF'), findsNothing);
  });
}
