import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/tower_brief.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/screens/tower_planner_screen.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

List<TowerFloorGroup> steppedGroups() => [
  TowerFloorGroup('Podium',1,5,const [TowerSpace('Reception',5000,4000)]),
  TowerFloorGroup('Mid tower',6,25,const [TowerSpace('Workspace',5000,5000,window:1600)],
    insets:const TowerPlateInsets(west:2000,south:2500,east:1500,north:2800)),
  TowerFloorGroup('Upper tower',26,100,const [TowerSpace('Study',5000,5000)],
    insets:const TowerPlateInsets(west:3000,south:4000,east:2200,north:4000)),
];

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

  test('100-level podium and inset tower keep exact world-coordinate cores at every frontage', () {
    for (final side in ['North','East','South','West']) {
      final input=tower(frontage:side,groups:steppedGroups());
      final saved=TowerBrief.fromMap(input.toMap())!;
      expect(saved.groups.last.insets.toMap(),input.groups.last.insets.toMap());
      expect(saved.groups.first.insets.isZero,isTrue);
      final result=generator.generate(saved);
      expect(result.issues,isEmpty,reason:side);
      expect(result.sheets.map((sheet)=>(sheet.first,sheet.last)),[(1,1),(2,5),(6,25),(26,100)]);
      final ground=result.sheets.first.plan;
      (int,int,int,int) bounds(PlanRect b)=>(b.left,b.bottom,b.right,b.top);
      final upper=result.sheets.last.plan;
      expect(bounds(upper.footprint),(6000,9000,24800,41000));
      expect(result.sheets.map((sheet)=>sheet.available),[24000*40000,24000*40000,20500*34700,18800*32000]);
      final coreIds=['stair_0','stair_1','lift_0','shaft_0'];
      final rotated=side=='East'||side=='West';
      for (final sheet in result.sheets) {
        final plan=sheet.plan;
        expect(sheet.planned+sheet.unallocated,sheet.available);
        expect(plan.openings.where((o)=>o.kind==PlanOpeningKind.door && o.from==AutomaticFloorPlan.entry).length,sheet.first==1?1:0);
        for (var i=0;i<coreIds.length;i++) {
          final r=plan.rooms.singleWhere((room)=>room.id==coreIds[i]);
          expect(bounds(r.bounds),bounds(ground.rooms.singleWhere((room)=>room.id==r.id).bounds));
          expect(rotated?r.bounds.depth:r.bounds.width,[3500,3500,4300,1600][i]);
          if (i<3) {
            final door=plan.openings.singleWhere((o)=>o.to==r.id && o.kind==PlanOpeningKind.door);
            final baseline=ground.openings.singleWhere((o)=>o.to==r.id && o.kind==PlanOpeningKind.door);
            expect(bounds(door.bounds),bounds(baseline.bounds));
          }
        }
        final corridor=plan.rooms.singleWhere((r)=>r.id=='internal_passage').bounds;
        final baseline=ground.rooms.singleWhere((r)=>r.id=='internal_passage').bounds;
        expect(rotated?(corridor.bottom,corridor.top):(corridor.left,corridor.right),
          rotated?(baseline.bottom,baseline.top):(baseline.left,baseline.right));
      }
      expect(ground.rooms.where((r)=>r.id.startsWith('reserve_front_')).length,2);
      final cad=FloorPlanCad.fromPlan(upper,siteZones:result.sheets.last.siteZones);
      expect(cad.lines.where((line)=>line.layer=='GROUND_PLATE_REFERENCE').length,4);
      expect(cad.toDxf(),contains('GROUND_PLATE_REFERENCE'));
      expect(cad.toDxf(),contains('Upper tower / Levels 26-100'));
    }
  });

  test('inset geometry blocks ground insets, expansions and invalid core offsets', () {
    final groups=steppedGroups();
    TowerFloorGroup change(int i,TowerPlateInsets insets)=>TowerFloorGroup(groups[i].name,groups[i].first,groups[i].last,
      groups[i].spaces,insets:insets);
    for (final (items,reason) in [
      ([change(0,const TowerPlateInsets(west:100)),...groups.skip(1)],'group including ground'),
      ([groups[0],groups[1],change(2,const TowerPlateInsets())],'fit entirely inside'),
      ([groups[0],change(1,const TowerPlateInsets(west:-1)),groups[2]],'nonnegative'),
      ([groups[0],change(1,const TowerPlateInsets(west:12000,east:12000)),groups[2]],'positive width'),
      ([groups[0],TowerFloorGroup('Narrow upper',6,100,groups[1].spaces,
          insets:const TowerPlateInsets(west:8000,east:8000))],'common core'),
    ]) {
      final result=generator.generate(tower(groups:items));
      expect(result.sheets,isEmpty);
      expect(result.issues.single,contains(reason));
    }
  });

  test('a front inset smaller than wall thickness still aligns the core without overlapping geometry', () {
    final groups=steppedGroups();
    final result=generator.generate(tower(groups:[groups.first,TowerFloorGroup('Small inset',6,100,groups[1].spaces,
      insets:const TowerPlateInsets(south:50))]));
    expect(result.issues,isEmpty);
    expect(result.sheets.last.plan.footprint.bottom,result.sheets.first.plan.footprint.bottom+50);
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


  testWidgets('edit an upper inset and save it with the regenerated 100-level plan', (tester) async {
    final now=DateTime.utc(2026);
    final saved=ProjectModel(id:'stepped',name:'Stepped tower',length:100,width:60,bhk:'',floors:'100',facing:'South',
      tower:tower(groups:steppedGroups()),createdAt:now,updatedAt:now);
    SharedPreferences.setMockInitialValues({'ae_projects_v1':[saved.toJson()]});
    final provider=ProjectProvider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<ProjectProvider>.value(value:provider,
      child:MaterialApp(home:TowerPlannerScreen(existing:saved))));
    await tester.pumpAndSettle();
    for (var i=0;i<2;i++) { await tester.tap(find.text('Continue')); await tester.pumpAndSettle(); }
    await tester.tap(find.text('Upper tower'));
    await tester.pumpAndSettle();
    final field=find.byKey(const ValueKey('tower_inset_west'));
    await tester.ensureVisible(field);
    expect(tester.widget<TextFormField>(field).initialValue,'3.0');
    await tester.enterText(field,'3.5');
    await tester.ensureVisible(find.text('Save floor group'));
    await tester.tap(find.text('Save floor group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & generate CAD'));
    await tester.pumpAndSettle();
    expect(find.text('High-rise CAD'),findsOneWidget);
    expect(provider.projects.single.tower!.groups.last.insets.west,3500);
    expect(generator.generate(provider.projects.single.tower!).sheets.last.plan.footprint.left,6500);
  });


  testWidgets('saved 100-level requirements can be edited and regenerate the preview', (tester) async {
    final now = DateTime.utc(2026);
    final saved = ProjectModel(id: 'tower_test', name: 'Saved tower', length: 100, width: 60,
      bhk: '', floors: '100 levels', facing: 'South', tower: tower(), createdAt: now, updatedAt: now);
    SharedPreferences.setMockInitialValues({'ae_projects_v1': [saved.toJson()]});
    final provider = ProjectProvider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<ProjectProvider>.value(value: provider,
      child: MaterialApp(home: TowerPlannerScreen(existing: saved))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('tower_name')), 'Updated tower');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Shared stairs, lifts and shafts'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Floor groups'), findsOneWidget);
    await tester.tap(find.text('Save & generate CAD'));
    await tester.pumpAndSettle();
    expect(find.text('High-rise CAD'), findsOneWidget);
    expect(find.text('Updated tower'), findsOneWidget);
    expect(provider.projects.single.tower!.floors, 100);
  });

}
