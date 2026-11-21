import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/tower_brief.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/screens/tower_planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:architect_engine/services/tower_plan_generator.dart';
import 'package:flutter_test/flutter_test.dart';

TowerBrief tower({String frontage = 'South', int floors = 100, int westOffset = 3000,
  String basis = 'Project geometry brief', List<TowerFloorGroup>? groups}) => TowerBrief(
  floors: floors, plotWidth: 30000, plotDepth: 60000, plateWidth: 24000, plateDepth: 40000,
  westOffset: westOffset, southOffset: 5000, frontage: frontage, wall: 200, corridor: 2200, door: 1000,
  basis: basis, stairs: const [TowerSpace('Core A', 3500, 6500), TowerSpace('Core B', 3500, 6500)],
  lifts: const [TowerSpace('Lift bank', 4300, 3800)], shafts: const [TowerSpace('Services', 1600, 2000)],
  groups: groups ?? [
    TowerFloorGroup('Lobby', 1, 1, const [TowerSpace('Reception', 5000, 6500)]),
    TowerFloorGroup('Parking zones', 2, 5, const [TowerSpace('Marked zone', 5000, 5000)]),
    TowerFloorGroup('Office', 6, 25, const [TowerSpace('Work area', 5500, 10500, window: 2200), TowerSpace('Meeting', 4000, 4500)]),
    TowerFloorGroup('Services', 26, 100, const [TowerSpace('Plant reserve', 3500, 5500)]),
  ],
);

void main() {
  final generator = TowerPlanGenerator();
  test('100 levels are covered by individual and typical plans with one fixed core', () {
    final result = generator.generate(tower());
    expect(result.issues, isEmpty);
    expect(result.sheets.map((s) => (s.first, s.last)), [(1, 1), (2, 5), (6, 25), (26, 100)]);
    final ground = result.sheets.first;
    for (final sheet in result.sheets) {
      expect(sheet.available, 24000 * 40000);
      expect(sheet.planned + sheet.unallocated, sheet.available);
      expect(sheet.unallocated, isPositive);
      for (final id in ['stair_0', 'stair_1', 'lift_0', 'shaft_0']) {
        List<int> rect(TowerSheet s) {
          final b = s.plan.rooms.singleWhere((r) => r.id == id).bounds;
          return [b.left, b.bottom, b.right, b.top];
        }
        expect(rect(sheet), rect(ground));
      }
      expect(sheet.plan.openings.where((o) => o.kind == PlanOpeningKind.door && o.from == AutomaticFloorPlan.entry),
        hasLength(sheet.first == 1 ? 1 : 0));
    }
    expect(result.sheets[2].plan.openings.where((o) => o.kind == PlanOpeningKind.window).single.bounds.depth, 2200);
    final dxfs = FloorPlanCad.sheetSet(result.sheets.map((s) => s.plan));
    final dxf = dxfs.toDxf();
    expect(dxf, contains('Office / Levels 6-25'));
    expect(dxf, contains('Services / Levels 26-100'));
    expect(dxf, contains('CORE_RESERVES'));
    expect(dxfs.lines.where((line) => line.layer == 'PLOT').map((line) => (line.start.x, line.start.y)).toSet(), hasLength(16));
  });

  test('all ground entry sides validate without changing the physical plate', () {
    for (final side in ['North', 'East', 'South', 'West']) {
      final result = generator.generate(tower(frontage: side));
      expect(result.issues, isEmpty, reason: side);
      expect(result.sheets.first.plan.footprint.width, 24000);
      expect(result.sheets.first.plan.footprint.depth, 40000);
    }
  });

  test('invalid level coverage, range and geometry block the whole document', () {
    final source = tower();
    expect(generator.generate(tower(groups: source.groups.take(3).toList())).issues.single, contains('Level 26'));
    final overlap = TowerFloorGroup('Office', 5, 25, source.groups[2].spaces);
    expect(generator.generate(tower(groups: [...source.groups.take(2), overlap, source.groups.last])).issues.single,
      contains('assigned more than once'));
    final huge = TowerFloorGroup('Oversized', 2, 100, const [TowerSpace('Hall', 15000, 5000)]);
    final failed = generator.generate(tower(groups: [source.groups.first, huge]));
    expect(failed.issues.single, contains('clear width'));
    expect(failed.sheets, isEmpty);
    expect(generator.generate(tower(westOffset: 7000)).issues.single, contains('outside the plot'));
    expect(generator.generate(tower(floors: 101)).issues.single, contains('2 to 100'));
    expect(generator.generate(tower(basis: '')).issues.single, contains('source'));
  });

  test('saved project round-trips the high-rise brief without a legacy brief', () {
    final time = DateTime.utc(2026);
    final project = ProjectModel(id: 'p', name: '100 levels', length: 100, width: 50,
      bhk: '', floors: '100 levels', facing: 'South', tower: tower(), createdAt: time, updatedAt: time);
    final restored = ProjectModel.fromJson(project.toJson());
    expect(restored.tower?.toMap(), project.tower?.toMap());
    expect(restored.brief, isNull);
    expect(generator.generate(restored.tower!).sheets, hasLength(4));
  });

  testWidgets('required site fields block high-rise configuration', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TowerPlannerScreen()));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Site and floor plate'), findsOneWidget);
    expect(find.text('Required.'), findsWidgets);
    expect(find.text('Step 2 of 3'), findsNothing);
  });

  testWidgets('a 100-level project exposes a typical sheet selector and DXF actions', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TowerPlanScreen(projectName: 'Tower test', brief: tower())));
    expect(find.textContaining('100 levels'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Levels 6-25 — Office').last);
    await tester.pumpAndSettle();
    expect(find.text('Levels 6-25 · Office'), findsOneWidget);
    expect(find.text('Per floor · Office'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Share all sheets DXF'), 250);
    expect(find.text('Share selected DXF'), findsOneWidget);
  });

}
