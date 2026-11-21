import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/dwelling_g1_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/dwelling_g1_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/tower_plan_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief house({Map<String,Object> values = const {}, Map<String,Map<String,Object>> rooms = const {},
  ProjectParking? parking = ProjectParking.none}) {
  final program = <String, Map<String,Object>>{
    'closed_kitchen': {'floor_level':'0','width':3,'length':3},
    'family_living_room': {'floor_level':'0','width':6,'length':5,'cad_window':1.4},
    'shared_bathroom': {'floor_level':'0','width':2,'length':2.2},
    'master_bedroom': {'floor_level':'1','width':4,'length':4},
    'secondary_bedroom': {'floor_level':'1','width':3.5,'length':3.5},
    ...rooms,
  };
  return ProjectBrief(floorCount:2,parking:parking,features:const [],
    taxonomy: TaxonomySelection(version:projectTaxonomyVersion,categoryId:'residential',subcategoryId:'houses',
      typeId:'independent_house',configurationId:'2_bhk',plotShapeId:'rectangular',
      spaceQuantities:{for(final key in program.keys) key:1}),
    requirements: ProjectRequirementsSnapshot(version:requirementsSchemaVersion,spaceDetails:program,answers:{
      'cad_output':'dwelling_g1','stair_access':'inside','stair_form':'straight','upper_use':'private','lift_plan':'none',
      'cad_plate_width':14,'cad_plate_depth':19,'cad_offset_left':3,'cad_offset_front':4,'cad_wall':.2,
      'cad_corridor':1.2,'cad_door':.9,'g1_height':3.06,'g1_width':1.2,'g1_risers':17,'g1_going':.26,'g1_landing':1.2,
      'main_kitchen_floor':'0','level_bedrooms_0':0,'level_bedrooms_1':2,'level_baths_0':1,'level_baths_1':0,
      'bedrooms':2,'kitchen_type':'closed',...values,
    }));
}

const openParking = <String,Object>{
  'cad_offset_front':8, 'parking_sqft':350, 'parking_arrangement':['open'],
  'g1_parking_frontage':'confirmed', 'g1_parking_offset':.8, 'g1_parking_apron':2.5,
  'g1_parking_path':1.4, 'g1_parking_gap':.4, 'cars':1, 'two_wheelers':2,
  'g1_car_width':2.6, 'g1_car_depth':5, 'g1_bike_width':1.1, 'g1_bike_depth':2.1,
};

const openTerrace = <String,Object>{
  'terrace_needed':'yes','terrace_use':['open'],'terrace_sqft':155,'terrace_area_open':120,
  'g1_roof_height':2.88,'g1_roof_risers':16,'g1_roof_stair_width':1.3,
  'g1_roof_going':.28,'g1_roof_landing':1.2,'g1_roof_walk':1.1,
  'g1_roof_width':3,'g1_roof_depth':4,'g1_roof_parapet':.15,
};

void main() {
  TowerResult run(ProjectBrief input,[String facing='South']) =>
    DwellingG1Generator().generate(input,widthFt:80,depthFt:100,facing:facing);

  test('both floors stack on the same measured stair with opposite approach landings', () {
    for (final facing in ['South','North','East','West']) {
      final result = run(house(),facing);
      expect(result.issues,isEmpty,reason:facing);
      final ground=result.sheets.first.plan, upper=result.sheets.last.plan;
      expect(result.sheets.map((s)=>s.range),['Ground floor','First floor']);
      List<int> bounds(PlanRect b)=>[b.left,b.bottom,b.right,b.top];
      final lowerStair=ground.rooms.singleWhere((r)=>r.id=='stair_0').bounds;
      final upperStair=upper.rooms.singleWhere((r)=>r.id=='stair_0').bounds;
      expect(bounds(lowerStair),bounds(upperStair));
      final swap = facing=='East'||facing=='West';
      expect(swap?lowerStair.depth:lowerStair.width,1200);
      expect(swap?lowerStair.width:lowerStair.depth,6560);
      expect(ground.stairs.single.up,isTrue);
      expect(upper.stairs.single.up,isFalse);
      expect(ground.stairs.single.riseMm,180);
      expect(ground.stairs.single.strokes.take(17),orderedEquals(upper.stairs.single.strokes.take(17)));
      expect(ground.stairs.single.strokes[17],(upper.stairs.single.strokes[17].$2,upper.stairs.single.strokes[17].$1));
      final groundDoor = ground.openings.singleWhere((o)=>o.to=='stair_0').bounds;
      final upperDoor = upper.openings.singleWhere((o)=>o.to=='stair_0').bounds;
      expect(groundDoor.overlaps(upperDoor),isFalse);
      if (facing=='South') {
        expect(groundDoor.bottom-lowerStair.bottom,150);
        expect(upperStair.top-upperDoor.top,150);
      }
      expect(validatePlanPartition(ground),isNull);
      expect(validatePlanPartition(upper),isNull);
      expect(upper.openings.where((o)=>o.from==AutomaticFloorPlan.entry && o.kind==PlanOpeningKind.door),isEmpty);
      final dxf=FloorPlanCad.sheetSet([ground,upper]).toDxf();
      expect(dxf,contains('UP - 17 RISERS'));
      expect(dxf,contains('DOWN - 17 RISERS'));
    }
  });

  test('invalid stair, requested external access, parking and floor conflicts block all sheets', () {
    expect(run(house(values:{'g1_landing':.7})).issues.single,contains('landing must fit'));
    expect(run(house(values:{'stair_access':'outside'})).issues.single,contains('inside straight stair'));
    expect(run(house(values:{'upper_use':'separate'})).issues.single,contains('rental'));
    expect(run(house(parking:ProjectParking.car)).issues.single,contains('Confirm that open parking'));
    expect(run(house(values:{'terrace_needed':'yes'})).issues.single,contains('open terrace only'));
    expect(run(house(values:{'fsi_limit':.2})).issues.single,contains('Both gross floor plates'));
    expect(run(house(values:{'main_kitchen_floor':'1'})).issues.single,contains('closed kitchen'));
    final conflict=run(house(rooms:{'closed_kitchen':{
      'floor_level':'0','width':3,'length':3,'adjacent_required':['master_bedroom'],
    }}));
    expect(conflict.issues.single,contains('same floor'));
    expect(conflict.sheets,isEmpty);
  });

  test('parking fits the ground site for four frontages and survives brief serialization', () {
    final brief = ProjectBrief.fromMap(house(values:openParking,parking:ProjectParking.both).toMap())!;
    for (final facing in ['South','North','East','West']) {
      final result = DwellingG1Generator().generate(brief,widthFt:100,depthFt:110,facing:facing);
      expect(result.issues,isEmpty,reason:facing);
      final ground = result.sheets.first, upstairs = result.sheets.last;
      expect(upstairs.siteZones,isEmpty);
      expect(ground.siteZones.map((z)=>z.id),['vehicle_approach','pedestrian_approach','car_1','bike_1','bike_2']);
      final plot=ground.plan.plot;
      final (apron,walk,car,bike) = (ground.siteZones[0].bounds,ground.siteZones[1].bounds,
        ground.siteZones[2].bounds,ground.siteZones[3].bounds);
      final door = ground.plan.openings.singleWhere((o)=>o.from==AutomaticFloorPlan.entry && o.kind==PlanOpeningKind.door).bounds;
      final vertical = facing=='North' || facing=='South';
      expect(vertical ? car.width : car.depth,2600);
      expect(vertical ? car.depth : car.width,5000);
      expect(vertical ? bike.width : bike.depth,1100);
      expect(vertical ? walk.depth : walk.width,8000);
      expect(vertical ? apron.width : apron.depth,4800);
      expect(vertical ? apron.depth : apron.width,2500);
      expect(vertical ? walk.left<=door.left && walk.right>=door.right : walk.bottom<=door.bottom && walk.top>=door.top,isTrue);
      expect(switch (facing) {
        'North'=>apron.top==plot.top && walk.top==plot.top && walk.bottom==door.top && car.top==apron.bottom,
        'East'=>apron.right==plot.right && walk.right==plot.right && walk.left==door.right && car.right==apron.left,
        'West'=>apron.left==plot.left && walk.left==plot.left && walk.right==door.left && car.left==apron.right,
        _=>apron.bottom==plot.bottom && walk.bottom==plot.bottom && walk.top==door.bottom && car.bottom==apron.top,
      },isTrue,reason:facing);
      for (final zone in ground.siteZones) {
        expect(plot.contains(zone.bounds),isTrue);
        expect(zone.bounds.overlaps(ground.plan.footprint),isFalse);
        expect(ground.siteZones.where((other)=>other!=zone && other.bounds.overlaps(zone.bounds)),isEmpty);
      }
      final groundDrawing = FloorPlanCad.fromPlan(ground.plan,siteZones:ground.siteZones);
      final upperDrawing = FloorPlanCad.fromPlan(upstairs.plan,siteZones:upstairs.siteZones);
      final combined = FloorPlanCad.combined([groundDrawing,upperDrawing]);
      for (final layer in ['PARKING_BAYS','PEDESTRIAN_APPROACH','VEHICLE_APPROACH']) {
        expect(groundDrawing.lines.where((line)=>line.layer==layer),isNotEmpty);
        expect(upperDrawing.lines.where((line)=>line.layer==layer),isEmpty);
        expect(combined.lines.where((line)=>line.layer==layer).length,groundDrawing.lines.where((line)=>line.layer==layer).length);
      }
      expect(combined.toDxf(),contains('TWO-WHEELER 2'));
    }
  });

  test('wrong arrangement, missing counts, access overlap and limited plot or area block export', () {
    for (final (edits,message) in <(Map<String,Object>,String)>[
      ({'parking_arrangement':['covered']},'open-surface'),
      ({'accessible_bays':1},'specialist'),
      ({'g1_parking_frontage':'pending'},'Confirm that open parking'),
      ({'cars':0},'number of parking bays'),
      ({'g1_bike_width':0},'measured bay'),
      ({'parking_sqft':300},'supplied parking allowance'),
      ({'g1_parking_offset':8},'pedestrian approach conflict'),
      ({'g1_parking_offset':28},'frontage width'),
      ({'g1_parking_apron':4},'do not fit between'),
      ({'g1_parking_path':.8},'front-door opening'),
    ]) {
      final result = DwellingG1Generator().generate(house(values:{...openParking,...edits},parking:ProjectParking.both),
        widthFt:100,depthFt:110,facing:'South');
      expect(result.issues.single,contains(message),reason:edits.toString());
      expect(result.sheets,isEmpty);
    }
  });

  test('single vehicle choice only draws the selected bay type', () {
    for (final (type,count) in [(ProjectParking.car,1),(ProjectParking.twoWheeler,2)]) {
      final result = DwellingG1Generator().generate(house(values:openParking,parking:type),
        widthFt:100,depthFt:110,facing:'South');
      expect(result.issues,isEmpty);
      expect(result.sheets.first.siteZones.where((zone)=>zone.layer=='PARKING_BAYS').length,count);
    }
  });

  test('open terrace uses a second aligned stair and connected measured roof route', () {
    final brief=ProjectBrief.fromMap(house(values:{...openParking,...openTerrace},parking:ProjectParking.both).toMap())!;
    List<int> edges(PlanRect b)=>[b.left,b.bottom,b.right,b.top];
    bool sharesEdge(PlanRect a,PlanRect b)=>
      ((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&a.top>b.bottom) ||
      ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&a.right>b.left);
    for (final facing in ['South','North','East','West']) {
      final result=run(brief,facing);
      expect(result.issues,isEmpty,reason:'$facing: ${result.issues}');
      expect(result.sheets.map((s)=>s.range),['Ground floor','First floor','Roof terrace']);
      final ground=result.sheets[0], first=result.sheets[1], roof=result.sheets[2];
      final access=first.plan.stairs.singleWhere((s)=>s.roomId=='stair_1'), top=roof.plan.stairs.single;
      expect(ground.plan.stairs.single.roomId,'stair_0');
      expect(ground.siteZones.where((z)=>z.layer=='PARKING_BAYS').length,3);
      expect(ground.plan.openings.where((o)=>o.to=='stair_1'),isEmpty);
      PlanRect stairBox(TowerSheet s)=>s.plan.rooms.singleWhere((r)=>r.id=='stair_1').bounds;
      expect(edges(stairBox(ground)),edges(stairBox(first)));
      expect(edges(stairBox(first)),edges(stairBox(roof)));
      expect(access.up,isTrue);
      expect(top.up,isFalse);
      expect(top.riseMm,180);
      expect(top.strokes.take(16),orderedEquals(access.strokes.take(16)));
      expect(top.strokes[16],(access.strokes[16].$2,access.strokes[16].$1));
      final door=roof.plan.openings.single;
      final walk=roof.siteZones.singleWhere((z)=>z.id=='roof_walk').bounds;
      final deck=roof.siteZones.singleWhere((z)=>z.id=='roof_deck').bounds;
      expect(door.from,'roof_walk');
      expect(door.to,'stair_1');
      expect(sharesEdge(stairBox(roof),door.bounds),isTrue);
      expect(sharesEdge(door.bounds,walk),isTrue);
      expect(sharesEdge(walk,deck),isTrue);
      final rotated=facing=='East'||facing=='West';
      expect(rotated?deck.depth:deck.width,3000);
      expect(rotated?deck.width:deck.depth,4000);
      expect(rotated?walk.depth:walk.width,1100);
      expect(validatePlanPartition(roof.plan),isNull);
      final drawing=FloorPlanCad.combined([
        for(final s in result.sheets) FloorPlanCad.fromPlan(s.plan,siteZones:s.siteZones),
      ]);
      for(final layer in ['TERRACE_ACCESS','TERRACE_DECK']) {
        expect(drawing.lines.where((l)=>l.layer==layer).length,4);
      }
      expect(drawing.toDxf(),contains('DOWN - 16 RISERS'));
    }
  });

  test('invalid terrace configuration blocks all export rather than omitting the roof', () {
    for (final (edits,message) in <(Map<String,Object>,String)>[
      ({'terrace_use':['open','garden']},'open terrace only'),
      ({'g1_roof_height':0},'second straight flight'),
      ({'g1_roof_landing':.5},'landing must fit'),
      ({'g1_roof_parapet':.3},'parapet thickness'),
      ({'g1_roof_walk':.8},'Terrace walk must span the door'),
      ({'g1_roof_depth':25},'do not fit'),
      ({'terrace_sqft':130},'available terrace area'),
      ({'terrace_area_open':140},'requested area'),
      ({'fsi_limit':.72},'roof stair enclosure'),
    ]) {
      final result=run(house(values:{...openTerrace,...edits}));
      expect(result.issues.single,contains(message),reason:edits.toString());
      expect(result.sheets,isEmpty);
    }
  });

  testWidgets('terrace sheet can be selected in the saved brief preview', (tester) async {
    await tester.pumpWidget(MaterialApp(home:DwellingG1Screen(name:'Terrace test',brief:house(values:openTerrace),
      widthFt:80,depthFt:100,facing:'South')));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roof terrace — Open terrace').last);
    await tester.pumpAndSettle();
    expect(find.text('Roof terrace · Open terrace'),findsOneWidget);
    await tester.scrollUntilVisible(find.text('Share all sheets DXF'),250);
    expect(find.textContaining('DOWN: 16 risers'),findsOneWidget);
    expect(find.text('Share selected DXF'),findsOneWidget);
  });

  testWidgets('dwelling preview switches between ground and first floor and exposes DXF', (tester) async {
    await tester.pumpWidget(MaterialApp(home:DwellingG1Screen(name:'House test',brief:house(),
      widthFt:80,depthFt:100,facing:'South')));
    expect(find.text('G+1 house CAD'),findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First floor — Independent House G+1').last);
    await tester.pumpAndSettle();
    expect(find.text('First floor · Independent House G+1'),findsOneWidget);
    await tester.scrollUntilVisible(find.text('Share all sheets DXF'),250);
    expect(find.textContaining('DOWN: 17 risers'),findsOneWidget);
    expect(find.text('Share selected DXF'),findsOneWidget);
  });
}
