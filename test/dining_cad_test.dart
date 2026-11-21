import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/dining_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/dining_cad_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief venue({Map<String,Object> answers=const {},Map<String,Map<String,Object>> rooms=const {},
    Map<String,int> counts=const {},String type='restaurant',String configuration='on_site_cooking'}) =>
  ProjectBrief(floorCount:1,parking:ProjectParking.none,features:const [],taxonomy:TaxonomySelection(
    version:projectTaxonomyVersion,categoryId:'commercial',subcategoryId:'food_service',typeId:type,
    configurationId:configuration,plotShapeId:'rectangular',spaceQuantities:{'dining':1,'toilets':1,'kitchen':1,'wash':1,...counts}),
    requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
      'cad_output':'dining_service','seats':12,'cad_plate_width':14.4,'cad_plate_depth':17.6,
      'cad_offset_left':3,'cad_offset_front':4,'cad_wall':.2,'cad_door':.9,'cad_corridor':1.25,
      'food_rear_access':'confirmed','food_serve_width':1.35,'food_return_width':1.1,'food_pass_pad':1.5,
      'food_rear_pad':2,'food_table_width':.85,'food_table_depth':1.45,'food_chair_depth':.8,...answers,
    },spaceDetails:{
      'toilets':{'width':2.5,'length':2.4},'dining':{'width':14,'length':10},
      'kitchen':{'width':8,'length':4.4},'wash':{'width':5.8,'length':4.4},...rooms,
    }));

void main() {
  DiningCadResult run(ProjectBrief brief,[String facing='South'])=>
    DiningCadGenerator().generate(brief,widthFt:90,depthFt:100,facing:facing);
  const dining='food_dining',kitchen='food_kitchen',wash='food_wash',lobby='food_lobby',toilet='food_toilet';
  bool sharesEdge(PlanRect a,PlanRect b)=>
    ((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top)||
    ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);

  test('visitor rooms and rear service doors stay separate on all frontages', () {
    final brief=ProjectBrief.fromMap(venue().toMap())!;
    expect(DiningCadGenerator.requested(brief),isTrue);
    for(final facing in ['South','North','East','West']) {
      final result=run(brief,facing);
      expect(result.issue,isNull,reason:'$facing: ${result.issue}');
      final plan=result.plan!,rooms={for(final r in result.plan!.rooms)r.id:r.bounds};
      final zones={for(final z in result.zones)z.id:z.bounds};
      expect(validatePlanGeometry(plan,sealedRooms:{kitchen,wash},secondaryExteriorDoorRooms:{kitchen,wash}),isNull);
      final doors=plan.openings.where((o)=>o.kind==PlanOpeningKind.door).toList();
      expect(doors.where((o)=>o.from==lobby).map((o)=>o.to),unorderedEquals([dining,toilet]));
      expect(doors.where((o)=>o.from==AutomaticFloorPlan.entry).map((o)=>o.to),unorderedEquals([lobby,kitchen,wash]));
      final hatches=plan.openings.where((o)=>o.kind==PlanOpeningKind.materialOpening);
      final isRotated=facing=='East'||facing=='West';
      for(final (side,id,width) in [('serve',kitchen,1350),('return',wash,1100)]) {
        final hatch=hatches.singleWhere((o)=>o.to==id);
        final approach=zones['${side}_approach']!,pad=zones['${side}_rear_pad']!;
        expect(hatch.from,dining);
        expect(isRotated?hatch.bounds.depth:hatch.bounds.width,width);
        expect(sharesEdge(hatch.bounds,approach),isTrue);
        expect(sharesEdge(hatch.bounds,rooms[id]!),isTrue);
        expect(sharesEdge(approach,zones['rear_cross']!),isTrue);
        expect(sharesEdge(doors.singleWhere((o)=>o.to==id).bounds,pad),isTrue);
        expect(pad.area,2000*1250);
        expect(plan.plot.contains(pad),isTrue);
        expect(plan.footprint.overlaps(pad),isFalse);
      }
      final aisle=zones['main_aisle']!;
      expect(isRotated?aisle.depth:aisle.width,1250);
      expect(sharesEdge(aisle,zones['front_cross']!),isTrue);
      expect(sharesEdge(aisle,zones['rear_cross']!),isTrue);
      expect(sharesEdge(zones['front_cross']!,doors.singleWhere((o)=>o.to==dining).bounds),isTrue);
      for(final z in result.zones) {
        if (z.layer!='FOOD_SERVICE_PADS') expect(rooms[dining]!.contains(z.bounds),isTrue);
        expect(result.zones.where((other)=>z!=other&&z.bounds.overlaps(other.bounds)),isEmpty);
      }
      final drawing=FloorPlanCad.fromPlan(plan,siteZones:result.zones);
      expect(result.zones.where((z)=>z.layer=='FOOD_TABLES').length,3);
      expect(result.zones.where((z)=>z.layer=='FOOD_SEATS').length,12);
      for(final z in result.zones.where((z)=>z.layer=='FOOD_TABLES')) { expect(z.bounds.area,850*1450); }
      expect(drawing.lines.where((l)=>l.layer=='FOOD_SERVE_PASS').length,5); // four pad edges and the hatch
      expect(drawing.lines.where((l)=>l.layer=='FOOD_RETURN_PASS').length,5);
      final dxf=drawing.toDxf();
      for(final layer in ['FOOD_GUEST_AISLES','FOOD_SERVE_PASS','FOOD_RETURN_PASS','FOOD_SERVICE_PADS','FOOD_TABLES','FOOD_SEATS']) {
        expect(dxf,contains(layer));
      }
    }
  });

  test('seat count and measured table changes affect the CAD furniture', () {
    final result=run(venue(type:'cafe',answers:{'seats':16,'food_table_width':.95}));
    expect(result.issue,isNull);
    final tables=result.zones.where((z)=>z.layer=='FOOD_TABLES').toList();
    expect(tables.length,4);
    expect(tables.every((z)=>z.bounds.width==950&&z.bounds.depth==1450),isTrue);
    expect(result.zones.where((z)=>z.layer=='FOOD_SEATS').length,16);
  });

  test('unsupported programs and failed fit produce explicit blockers and no CAD', () {
    for(final (brief,issue) in [
      (venue(type:'cloud_kitchen'),'Restaurant, Café or Coffee Shop'),
      (venue(configuration:'central_production'),'on-site cooking'),
      (venue(answers:{'food_rear_access':'pending'}),'Confirm independent'),
      (venue(answers:{'food_rear_pad':9}),'outside the plot'),
      (venue(counts:{'dry_store':1}),'exactly one Toilets'),
      (venue(answers:{'seats':10}),'multiples of four'),
      (venue(answers:{'seats':20}),'at most 16 seats'),
      (venue(answers:{'food_return_width':6}),'leave wall returns'),
      (venue(answers:{'food_chair_depth':3}),'two table rows'),
      (venue(rooms:{'wash':{'width':5.8,'length':4}}),'depths must match'),
      (venue(rooms:{'toilets':{'width':2.5,'length':2.4,'daylight':'required'}}),'daylight geometry'),
    ]) {
      final result=run(brief);
      expect(result.issue,contains(issue),reason:issue);
      expect(result.plan,isNull);
      expect(result.zones,isEmpty);
    }
  });

  testWidgets('dine-in preview enables DXF only for a fitted measured plan', (tester) async {
    await tester.pumpWidget(MaterialApp(home:DiningCadScreen(name:'Measured café',brief:venue(),
      widthFt:90,depthFt:100,facing:'East')));
    expect(find.text('Dine-in service CAD'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:DiningCadScreen(key:const ValueKey('blocked'),name:'Blocked café',
      brief:venue(answers:{'seats':20}),widthFt:90,depthFt:100,facing:'South')));
    expect(find.text('Save or share DXF'),findsNothing);
    expect(find.textContaining('at most 16 seats'),findsOneWidget);
  });
}
