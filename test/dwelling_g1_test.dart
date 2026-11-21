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
    expect(run(house(parking:ProjectParking.car)).issues.single,contains('Parking or terrace'));
    expect(run(house(values:{'fsi_limit':.2})).issues.single,contains('Both gross floor plates'));
    expect(run(house(values:{'main_kitchen_floor':'1'})).issues.single,contains('closed kitchen'));
    final conflict=run(house(rooms:{'closed_kitchen':{
      'floor_level':'0','width':3,'length':3,'adjacent_required':['master_bedroom'],
    }}));
    expect(conflict.issues.single,contains('same floor'));
    expect(conflict.sheets,isEmpty);
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
