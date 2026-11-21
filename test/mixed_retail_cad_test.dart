import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/mixed_retail_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/mixed_retail_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief mixed({Map<String,Object> edits=const {},Map<String,int> counts=const {},String configuration='horizontal_mixed_use',
  Map<String, Map<String,Object>> rooms=const {},int floors=1}) => ProjectBrief(floorCount:floors,parking:ProjectParking.none,features:const [],
    taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'mixed_use',subcategoryId:'mixed_development',
      typeId:'residential_plus_retail',configurationId:configuration,plotShapeId:'rectangular',
      spaceQuantities:{'family_living_room':1,'master_bedroom':1,'closed_kitchen':1,'shared_bathroom':1,...counts}),
    requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
      'cad_output':'mixed_shop_home','mixed_components':['housing','retail'],'mixed_levels':['ground'],
      'mx_access':'confirmed','mx_home_entry':'same','mx_retail_width':12,'mx_divider':.6,'mx_bedrooms':1,'mx_shop_walk':1.6,'mx_home_walk':1.4,
      'cad_plate_width':26,'cad_plate_depth':20,'cad_offset_left':3,'cad_offset_front':4,'cad_wall':.2,'cad_door':.9,'cad_corridor':1.2,
      'rt_public_door':1,'rt_stock_door':1.1,'rt_stock_depth':4,'rt_fixture_count':3,'rt_fixture_width':1,'rt_fixture_depth':7,
      'rt_aisle':1.3,'rt_checkout_width':2.5,'rt_checkout_depth':.9,'rt_queue_depth':2,...edits,
    },spaceDetails:{
      'family_living_room':{'width':5.9,'length':4.5,'cad_window':1.6},
      'master_bedroom':{'width':5.9,'length':4,'cad_window':1.5},
      'closed_kitchen':{'width':3,'length':3},'shared_bathroom':{'width':2.5,'length':2.8},...rooms,
    }));

void main() {
  MixedRetailCadResult run(ProjectBrief input,[String facing='South']) => MixedRetailCadGenerator().generate(input,widthFt:120,depthFt:120,facing:facing);
  test('real rooms, fixtures and independent walks across all frontage orientations', () {
    for(final entrySide in ['same','opposite']) {
      final brief=ProjectBrief.fromMap(mixed(edits:{'mx_home_entry':entrySide}).toMap())!;
      for(final facing in ['South','North','East','West']) {
        final result=run(brief,facing);
        expect(result.issue,isNull,reason:'$facing $entrySide');
        final plan=result.plan!;
        expect(validatePlanPartition(plan),isNull);
        final entrances=plan.openings.where((o)=>o.kind==PlanOpeningKind.door && o.from==AutomaticFloorPlan.entry).toList();
        expect(entrances.map((o)=>o.to),['retail_sales','dwelling_internal_passage']);
        final interior=plan.openings.where((o)=>o.from!=AutomaticFloorPlan.entry);
        expect(interior.every((o)=>o.from.startsWith('dwelling_')==o.to.startsWith('dwelling_')),isTrue);
        expect(plan.rooms.map((r)=>r.label),containsAll(['Sales floor','Stock room','Private home passage','Closed Kitchen','Master Bedroom','Shared Bathroom']));
        final shop=result.zones.singleWhere((z)=>z.id=='mx_shop_walk').bounds;
        final home=result.zones.singleWhere((z)=>z.id=='mx_home_walk').bounds;
        final divider=result.zones.singleWhere((z)=>z.id=='mx_divider').bounds;
        expect(divider.area,600*20000);
        expect(plan.openings.where((o)=>o.bounds.overlaps(divider)),isEmpty);
        expect(plan.openings.where((o)=>o.kind==PlanOpeningKind.window).length,2);
        expect(plan.plot.contains(shop) && plan.plot.contains(home),isTrue);
        expect(shop.overlaps(home) || shop.overlaps(plan.footprint) || home.overlaps(plan.footprint),isFalse);
        final alongNorth=facing=='East'||facing=='West';
        expect(alongNorth?shop.depth:shop.width,1600);
        expect(alongNorth?home.depth:home.width,1400);
        String boundary(PlanRect path)=>path.left==plan.plot.left?'West':path.right==plan.plot.right?'East':path.top==plan.plot.top?'North':'South';
        final opposite={'South':'North','North':'South','East':'West','West':'East'};
        expect(boundary(shop),facing);
        expect(boundary(home),entrySide=='same'?facing:opposite[facing]);
        for(final (path,entrance) in [(shop,entrances.first.bounds),(home,entrances.last.bounds)]) {
          expect(switch(boundary(path)) {
            'North'=>path.bottom==entrance.top && path.left<=entrance.left && path.right>=entrance.right,
            'East'=>path.left==entrance.right && path.bottom<=entrance.bottom && path.top>=entrance.top,
            'West'=>path.right==entrance.left && path.bottom<=entrance.bottom && path.top>=entrance.top,
            _=>path.top==entrance.bottom && path.left<=entrance.left && path.right>=entrance.right,
          },isTrue);
        }
        final cad=FloorPlanCad.fromPlan(plan,siteZones:result.zones);
        for(final layer in ['MIXED_SHOP_ACCESS','MIXED_HOME_ACCESS','MIXED_DIVIDER','CUSTOMER_ROUTE','RETAIL_DISPLAY']) {
          expect(cad.lines.where((l)=>l.layer==layer),isNotEmpty);
        }
      }
    }
  });

  test('unsupported and conflicting geometry never exports either wing in isolation', () {
    for(final (input,problem) in [
      (mixed(floors:2),'ground-floor horizontal'),
      (mixed(configuration:'vertical_mixed_use'),'ground-floor horizontal'),
      (mixed(edits:{'mixed_components':['housing','retail','food']}),'no other uses'),
      (mixed(edits:{'mx_access':'pending'}),'Confirm independent access'),
      (mixed(edits:{'mx_divider':.3}),'twice the wall thickness'),
      (mixed(edits:{'mx_shop_walk':14,'mx_home_walk':14}),'walks overlap'),
      (mixed(edits:{'mx_home_walk':.7}),'narrower than its door'),
      (mixed(edits:{'coverage_limit':30}),'combined footprint'),
      (mixed(edits:{'rt_fixture_count':20}),'Shop:'),
      (mixed(counts:{'retail':1}),'listed measured dwelling'),
      (mixed(edits:{'mx_bedrooms':2}),'bedroom quantities'),
      (mixed(counts:{'closed_kitchen':0}),'closed kitchen'),
      (mixed(rooms:{'master_bedroom':{'width':5.9,'length':4,'cad_window':1.5,'zone_edge':'left'}}),'true exterior'),
    ]) {
      final result=run(input);
      expect(result.issue,contains(problem));
      expect(result.plan,isNull);
      expect(result.zones,isEmpty);
    }
  });

  testWidgets('mixed-use preview exposes DXF only when both uses fit', (tester) async {
    Future<void> open(ProjectBrief brief)=>tester.pumpWidget(MaterialApp(home:MixedRetailCadScreen(key:ObjectKey(brief),
      name:'Corner shop and home',brief:brief,widthFt:120,depthFt:120,facing:'South')));
    await open(mixed());
    expect(find.text('Save or share DXF'),findsOneWidget);
    await open(mixed(floors:2));
    expect(find.text('No plan generated'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
