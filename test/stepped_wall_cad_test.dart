import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/stepped_wall_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/screens/stepped_wall_cad_screen.dart';
import 'package:architect_engine/services/stepped_wall_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief wall({Map<String, Object> edits = const {}, String type = 'streetscape'}) => ProjectBrief(
  floorCount: null, features: const [], parking: null,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'infrastructure',
    subcategoryId: 'public_realm', typeId: type, configurationId: 'linear_corridor'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'stepped_wall_mode': steppedWallMode, 'sw_grid': 'Example grid', 'sw_datum': 'Local RL',
    'sw_axis': '1000,2000;1060,2080', 'sw_back_side': 'left', 'sw_width': .4,
    'sw_ground': '10,100,101;\n40,100.3,101.6\r\n70,100.6,102.1;90,100.8,102.4',
    'sw_steps': '35,99.5,101.7;65,99.8,102.3;90,100.1,102.6',
    'sw_embed': .45, 'sw_top_margin': .2, 'sw_visible_max': 2.05, ...edits,
  }));

void main() {
  final generator = SteppedWallCadGenerator();

  test('saved wall has projected faces, true-scale exposed steps and per-run quantities', () {
    expect(steppedWallCadEligible('infrastructure', 'public_realm', 'streetscape'), isTrue);
    expect(steppedWallCadEligible('infrastructure', 'public_realm', 'greenway'), isFalse);
    expect(SteppedWallCadGenerator.requested(wall(edits: {'stepped_wall_mode': 'other'})), isFalse);
    final saved = ProjectBrief.fromMap(wall().toMap())!;
    expect(SteppedWallCadGenerator.requested(saved), isTrue);
    final r = generator.generate(saved);
    expect(r.issue, isNull);
    expect((r.lengthMm, r.widthMm, r.minEmbedMm, r.minTopMarginMm, r.maxVisibleMm, r.grossM3),
      (80000, 400, 450, 200, 2050, 77));
    expect(r.runs.map((s) => s.grossM3), [22, 30, 25]);
    expect(r.toCsv(), contains('2,35.000,65.000,99.800,102.300,0.400,30.000000\r\n'));
    final plan = r.plan!;
    final back = plan.lines.singleWhere((l) => l.layer == 'SW_BACK');
    expect((back.start.x, back.start.y, back.end.x, back.end.y), (1005840, 2008120, 1053840, 2072120));
    expect(plan.lines.where((l) => l.layer == 'SW_STEP').length, 4);
    expect(plan.toDxf(), contains('BACK: LEFT OF A-B'));
    final reflected = generator.generate(wall(edits: {'sw_back_side': 'right'})).plan!.lines.singleWhere((l) => l.layer == 'SW_BACK');
    expect((reflected.start.x, reflected.start.y), (1006160, 2007880));
    final profile = r.profile!;
    final steps = profile.lines.where((l) => l.layer == 'SW_STEP').toList();
    expect(steps.length, 4);
    expect((steps[0].start.x, steps[0].start.y, steps[0].end.y), (35000, 2700, 3300));
    expect((steps[1].start.x, steps[1].start.y, steps[1].end.y), (35000, 500, 800));
    expect(profile.lines.where((l) => l.layer == 'SW_ENVELOPE').length, 8);
    expect(profile.toDxf(), contains('RL ZERO AT 99.000 M'));
  });

  test('same base and top do not draw an internal profile seam', () {
    final r = generator.generate(wall(edits: {'sw_steps': '35,99.5,102.6;90,99.5,102.6', 'sw_visible_max': 3}));
    expect(r.issue, isNull);
    expect(r.profile!.lines.where((l) => l.layer == 'SW_STEP'), isEmpty);
  });

  test('fails at interpolated run endpoints and internal ground knots', () {
    for (final (brief, message) in [
      (wall(type: 'greenway'), 'Select Streetscape'),
      (wall(edits: {'sw_ground': '10,102,101;90,102,103'}), 'Back ground is lower'),
      (wall(edits: {'sw_ground': '10,100,101;100.001,100,101'}), 'within the surveyed A–B span'),
      (wall(edits: {'sw_steps': '35,99.5,101.699;65,99.8,102.3;90,100.1,102.6'}), 'Run 1 at Ch 35.000 m has insufficient top margin'),
      (wall(edits: {'sw_steps': '35,99.5,101.7;65,99.801,102.3;90,100.1,102.6'}), 'Run 2 at Ch 35.000 m has insufficient base depth'),
      (wall(edits: {'sw_visible_max': 2.049}), 'Run 2 at Ch 35.000 m exceeds'),
      (wall(edits: {'sw_steps': '35,99.5,101.7;65,99.8,102.3'}), 'last run must end'),
      (wall(edits: {'sw_ground': '10,100,101;40,100.3,101.6;52,100.4,102.101;70,100.6,102.1;90,100.8,102.4'}),
        'Run 2 at Ch 52.000 m has insufficient top margin'),
    ]) {
      final r = generator.generate(brief);
      expect(r.issue, contains(message));
      expect(r.plan, isNull);
      expect(r.profile, isNull);
      expect(r.toCsv(), isNull);
    }
  });

  testWidgets('valid preview offers both sheets and quantity CSV', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SteppedWallCadScreen(name: 'Wall', brief: wall())));
    expect(find.text('Share wall plan DXF'), findsOneWidget);
    expect(find.text('Share wall quantity CSV'), findsOneWidget);
    await tester.tap(find.text('Longitudinal profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share wall profile DXF'), findsOneWidget);
  });

  testWidgets('Projects reopens failed wall checks without generic fallback or exports', (tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id: 'wall', name: 'Wall conflict', width: 0, length: 0,
      bhk: '', floors: '', facing: 'Not decided', createdAt: now, updatedAt: now,
      brief: wall(edits: {'sw_visible_max': 2.049}));
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
    await tester.tap(find.text('Surveyed stepped landscape wall CAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Run 2 at Ch 35.000 m exceeds'), findsOneWidget);
    expect(find.text('Share wall plan DXF'), findsNothing);
    expect(find.text('Share wall profile DXF'), findsNothing);
    expect(find.text('Share wall quantity CSV'), findsNothing);
  });
}
