import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/stacked_retail_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/stacked_retail_cad_generator.dart';
import 'package:architect_engine/services/tower_plan_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief stacked({Map<String,Object> edits=const {},Map<String,Map<String,Object>> rooms=const {},
  Map<String,int> counts=const {},int floors=2,String config='vertical_mixed_use'})=>ProjectBrief(
    floorCount:floors,parking:ProjectParking.none,features:const [],taxonomy:TaxonomySelection(version:projectTaxonomyVersion,
      categoryId:'mixed_use',subcategoryId:'mixed_development',typeId:'residential_plus_retail',configurationId:config,
      plotShapeId:'rectangular',spaceQuantities:{'family_living_room':1,'master_bedroom':1,'closed_kitchen':1,'shared_bathroom':1,...counts}),
    requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
      'cad_output':'mixed_shop_below_home','ms_access':'confirmed','mixed_components':['housing','retail'],
      'mixed_levels':['ground','housing'],'mx_bedrooms':1,'mx_shop_walk':1.6,'mx_home_walk':1.4,
      'cad_plate_width':14,'cad_plate_depth':20,'cad_offset_left':3,'cad_offset_front':4,'cad_wall':.2,'cad_door':.9,'cad_corridor':1.2,
      'rt_public_door':1,'rt_stock_door':1.1,'rt_stock_depth':4,'rt_fixture_count':3,'rt_fixture_width':1,'rt_fixture_depth':7,
      'rt_aisle':1.3,'rt_checkout_width':2.5,'rt_checkout_depth':.9,'rt_queue_depth':2,
      'g1_height':3.06,'g1_width':1.2,'g1_risers':17,'g1_going':.26,'g1_landing':1.2,...edits,
    },spaceDetails:{
      'family_living_room':{'width':9,'length':4.5,'cad_window':1.6,'floor_level':'1','zone_edge':'front'},
      'master_bedroom':{'width':9,'length':4,'cad_window':1.5,'floor_level':'1','zone_edge':'rear'},
      'closed_kitchen':{'width':3,'length':3,'floor_level':'1'},
      'shared_bathroom':{'width':2.5,'length':2.8,'floor_level':'1'},...rooms,
    }));

void main() {
  TowerResult run(ProjectBrief brief,[String facing='South'])=>
    StackedRetailCadGenerator().generate(brief,widthFt:120,depthFt:110,facing:facing);
  List<int> bounds(PlanRect b)=>[b.left,b.bottom,b.right,b.top];
  bool touches(PlanRect a,PlanRect b)=>
    ((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top)||
    ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);

  test('common plate, separate ground entry and vertically aligned stair on four frontages', () {
    final brief=ProjectBrief.fromMap(stacked().toMap())!;
    expect(StackedRetailCadGenerator.requested(brief),isTrue);
    for(final facing in ['South','North','East','West']) {
      final result=run(brief,facing);
      expect(result.issues,isEmpty,reason:'$facing: ${result.issues}');
      final ground=result.sheets[0],upper=result.sheets[1];
      expect(bounds(ground.plan.footprint),bounds(upper.plan.footprint));
      expect(bounds(ground.plan.plot),bounds(upper.plan.plot));
      expect(validatePlanPartition(ground.plan),isNull);
      expect(validatePlanGeometry(upper.plan,indoorSeed:'stair_0',sealedRooms:upper.plan.rooms.where((r)=>r.id.startsWith('reserve_')).map((r)=>r.id).toSet()),isNull);
      final groundDoors=ground.plan.openings.where((o)=>o.kind==PlanOpeningKind.door).toList();
      expect(groundDoors.where((o)=>o.from==AutomaticFloorPlan.entry).map((o)=>o.to),unorderedEquals(['retail_sales','stair_0']));
      expect(groundDoors.where((o)=>o.from=='stair_0'||o.to=='stair_0').single.from,AutomaticFloorPlan.entry);
      final divider=ground.siteZones.singleWhere((z)=>z.layer=='MIXED_DIVIDER').bounds;
      expect(ground.plan.openings.where((o)=>o.bounds.overlaps(divider)),isEmpty);
      final shop=ground.siteZones.singleWhere((z)=>z.id=='mx_shop_walk').bounds;
      final home=ground.siteZones.singleWhere((z)=>z.id=='mx_home_walk').bounds;
      expect(shop.overlaps(home),isFalse);
      expect(home.area,1400*4000);
      expect(shop.area,1600*4000);
      expect(touches(home,groundDoors.singleWhere((o)=>o.to=='stair_0').bounds),isTrue);
      expect(touches(shop,groundDoors.singleWhere((o)=>o.to=='retail_sales').bounds),isTrue);
      expect(upper.plan.openings.where((o)=>o.kind==PlanOpeningKind.door && o.from==AutomaticFloorPlan.entry),isEmpty);
      final upperDoor=upper.plan.openings.singleWhere((o)=>o.from=='stair_0');
      expect(upperDoor.to,'internal_passage');
      final upperStair=upper.plan.rooms.singleWhere((r)=>r.id=='stair_0').bounds;
      expect(touches(upperStair,upperDoor.bounds),isTrue);
      final g=ground.plan.stairs.single,u=upper.plan.stairs.single;
      expect(g.up,isTrue);
      expect(u.up,isFalse);
      expect(g.riseMm,180);
      expect(g.strokes.take(17),orderedEquals(u.strokes.take(17)));
      expect(g.strokes[17],(u.strokes[17].$2,u.strokes[17].$1));
      expect(upper.plan.rooms.map((r)=>r.label),containsAll(['Family Living Room','Master Bedroom','Closed Kitchen','Shared Bathroom']));
      final p=upper.plan.footprint;
      final windows=upper.plan.openings.where((o)=>o.kind==PlanOpeningKind.window);
      expect(windows.length,2);
      expect(windows.every((o)=>o.bounds.left==p.left||o.bounds.right==p.right||o.bounds.bottom==p.bottom||o.bounds.top==p.top),isTrue);
      final groundCad=FloorPlanCad.fromPlan(ground.plan,siteZones:ground.siteZones),upperCad=FloorPlanCad.fromPlan(upper.plan,siteZones:upper.siteZones);
      for(final layer in ['MIXED_DIVIDER','MIXED_HOME_ACCESS','MIXED_SHOP_ACCESS','RETAIL_DISPLAY']) {
        expect(groundCad.lines.where((l)=>l.layer==layer),isNotEmpty);
        expect(upperCad.lines.where((l)=>l.layer==layer),isEmpty);
      }
      final combined=FloorPlanCad.combined([groundCad,upperCad]).toDxf();
      expect(combined,contains('UP - 17 RISERS'));
      expect(combined,contains('DOWN - 17 RISERS'));
    }
  });

  test('unsupported scope, too long a stair, or bad frontage block the full sheet set', () {
    for(final (brief,issue) in [
      (stacked(floors:1),'requires two floors'),
      (stacked(config:'horizontal_mixed_use'),'one vertical building'),
      (stacked(edits:{'mixed_levels':['ground','housing','hotel']}),'only Retail'),
      (stacked(edits:{'lift_plan':'now'}),'without a lift'),
      (stacked(edits:{'ms_access':'pending'}),'Confirm independent'),
      (stacked(edits:{'g1_going':.65}),'do not align'),
      (stacked(edits:{'g1_landing':.7}),'must fit the door swing'),
      (stacked(edits:{'mx_home_walk':.8}),'must span their doors'),
      (stacked(edits:{'fsi_limit':.3}),'Both gross floor plates'),
      (stacked(rooms:{'closed_kitchen':{'width':3,'length':3,'floor_level':'0'}}),'assign each measured dwelling room'),
    ]) {
      final result=run(brief);
      expect(result.sheets,isEmpty,reason:issue);
      expect(result.issues.single.toLowerCase(),contains(issue.toLowerCase()));
    }
  });

  testWidgets('valid mixed-use preview exports individually or together; blocked brief cannot export', (tester) async {
    await tester.pumpWidget(MaterialApp(home:StackedRetailCadScreen(name:'Shop and home',brief:stacked(),
      widthFt:120,depthFt:110,facing:'South')));
    expect(find.text('Shop below dwelling CAD'),findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First floor — Private dwelling').last);
    await tester.pumpAndSettle();
    expect(find.text('First floor · Private dwelling'),findsOneWidget);
    await tester.scrollUntilVisible(find.text('Share all sheets DXF'),250);
    expect(find.textContaining('DOWN: 17 risers'),findsOneWidget);
    expect(find.text('Share selected DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:StackedRetailCadScreen(key:const ValueKey('blocked'),name:'Blocked shop',
      brief:stacked(edits:{'g1_going':.65}),widthFt:120,depthFt:110,facing:'South')));
    expect(find.textContaining('do not align'),findsOneWidget);
    expect(find.text('Share selected DXF'),findsNothing);
  });
}
