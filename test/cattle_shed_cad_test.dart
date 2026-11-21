import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/cattle_shed_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/cattle_shed_cad_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief shed({Map<String,Object> edits=const {},Map<String,int> spaces=const {},String type='dairy_farm',
  String config='production_site',int floors=1})=>ProjectBrief(floorCount:floors,parking:ProjectParking.none,
  features:const [],taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'rural',
    subcategoryId:'farm',typeId:type,configurationId:config,plotShapeId:'rectangular',spaceQuantities:spaces),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'cattle_shed','df_access':'confirmed','animal_capacity':28,'df_pens':3,'df_animals_per_pen':5,
    'cad_plate_width':17.6,'cad_plate_depth':15.6,'cad_wall':.2,'cad_offset_left':4,'cad_offset_front':4,
    'df_pen_width':4.2,'df_pen_depth':5,'df_rail':.1,'df_feed_lane':3.6,'df_scrape_lane':2.4,
    'df_trough':.7,'df_pen_gate':1.6,'df_feed_door':3,'df_scrape_door':1.8,'df_scrape_pad':3.5,...edits,
  }));

void main() {
  CattleShedResult run(ProjectBrief brief,[String facing='South'])=>
    CattleShedCadGenerator().generate(brief,widthFt:100,depthFt:105,facing:facing);
  const feed='dairy_feed_lane',left='dairy_scrape_left',right='dairy_scrape_right';
  bool touch(PlanRect a,PlanRect b)=>
    ((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top)||
    ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);

  test('saved shed plan connects front feed and independent rear cleaning doors on all frontages', () {
    final input=ProjectBrief.fromMap(shed().toMap())!;
    expect(CattleShedCadGenerator.requested(input),isTrue);
    for(final facing in ['South','North','East','West']) {
      final result=run(input,facing);
      expect(result.issue,isNull,reason:'$facing: ${result.issue}');
      expect(result.plannedCapacity,30);
      final p=result.plan!,rooms={for(final r in result.plan!.rooms)r.id:r.bounds};
      expect(validatePlanGeometry(p,sealedRooms:rooms.keys.where((id)=>id!=feed).toSet(),secondaryExteriorDoorRooms:{left,right}),isNull);
      final exterior=p.openings.where((o)=>o.from==AutomaticFloorPlan.entry);
      expect(exterior.map((o)=>o.to),unorderedEquals([feed,left,right]));
      final zones={for(final z in result.zones)z.id:z.bounds};
      final rotated=facing=='East'||facing=='West';
      for(final (room,zone,width,depth,doorWidth) in [(feed,'dairy_front_walk',3600,4000,3000),
        (left,'dairy_left_pad',2400,3500,1800),(right,'dairy_right_pad',2400,3500,1800)]) {
        final door=exterior.singleWhere((o)=>o.to==room), path=zones[zone]!;
        expect(rotated?door.bounds.depth:door.bounds.width,doorWidth);
        expect(rotated?path.depth:path.width,width);
        expect(rotated?path.width:path.depth,depth);
        expect(touch(path,door.bounds),isTrue);
        expect(touch(door.bounds,rooms[room]!),isTrue);
        expect(p.plot.contains(path),isTrue);
        expect(path.overlaps(p.footprint),isFalse);
        expect(result.zones.where((z)=>z.id!=zone&&z.bounds.overlaps(path)),isEmpty);
      }
      final gates=p.openings.where((o)=>o.to.startsWith('dairy_pen_'));
      expect(gates.length,6);
      expect(gates.where((o)=>o.from==left).length,3);
      expect(gates.where((o)=>o.from==right).length,3);
      expect(p.openings.where((o)=>o.from==feed),isEmpty);
      for(final g in gates) {
        expect(touch(g.bounds,rooms[g.to]!),isTrue);
        expect(touch(g.bounds,rooms[g.from]!),isTrue);
        expect(rotated?g.bounds.width:g.bounds.depth,1600);
        final trough=zones['${g.to}_trough']!,pen=rooms[g.to]!;
        expect(pen.contains(trough),isTrue);
        expect(pen.area,4200*5000);
        expect(trough.area,700*5000);
        expect(rotated?trough.depth:trough.width,700);
      }
      final cad=FloorPlanCad.fromPlan(p,siteZones:result.zones);
      expect(cad.arcs.where((a)=>a.layer=='DAIRY_PEN_GATES').map((a)=>a.radius),List.filled(6,1600));
      for(final layer in ['DAIRY_PEN_GATES','DAIRY_FEED_ACCESS','DAIRY_CLEAN_ACCESS','DAIRY_TROUGHS']) {
        expect(cad.lines.where((l)=>l.layer==layer),isNotEmpty);
        expect(cad.toDxf(),contains(layer));
      }
    }
  });

  test('plan responds to exact count and pen size; no unused pens are added', () {
    final result=run(shed(type:'cattle_farm',edits:{'df_pens':1,'animal_capacity':7,
      'df_pen_depth':4.5,'cad_plate_depth':4.9,'df_animals_per_pen':4}));
    expect(result.issue,isNull);
    expect(result.plannedCapacity,8);
    expect(result.plan!.rooms.where((r)=>r.id.startsWith('dairy_pen_')).length,2);
    expect(result.zones.where((z)=>z.layer=='DAIRY_TROUGHS').map((z)=>z.bounds.depth),[4500,4500]);
  });

  test('blocked shed has no partial geometry or fallback DXF', () {
    for(final (brief,issue) in [
      (shed(type:'poultry_farm'),'Dairy Farm and Cattle Farm only'),
      (shed(config:'residence_plus_production'),'production shed only'),
      (shed(floors:2),'ground-floor'),
      (shed(spaces:{'feed_store':1}),'other Space selections'),
      (shed(edits:{'animal_capacity':31}),'exceeds 30 places'),
      (shed(edits:{'df_pens':0}),'1–20 pens'),
      (shed(edits:{'df_access':'pending'}),'Confirm independent'),
      (shed(edits:{'df_trough':3}),'swing clear of the trough'),
      (shed(edits:{'df_scrape_door':2.4}),'leave wall returns'),
      (shed(edits:{'df_scrape_pad':20}),'outside the plot'),
      (shed(edits:{'cad_plate_depth':15.5}),'17.600 × 15.600'),
    ]) {
      final result=run(brief);
      expect(result.issue,contains(issue),reason:issue);
      expect(result.plan,isNull);
      expect(result.zones,isEmpty);
    }
  });

  testWidgets('shed preview offers DXF only after a valid measured fit', (tester) async {
    await tester.pumpWidget(MaterialApp(home:CattleShedCadScreen(name:'Dairy shed',brief:shed(),
      widthFt:100,depthFt:105,facing:'West')));
    expect(find.text('Cattle shed CAD'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:CattleShedCadScreen(key:const ValueKey('blocked'),name:'Dairy shed',
      brief:shed(edits:{'animal_capacity':31}),widthFt:100,depthFt:105,facing:'West')));
    expect(find.textContaining('exceeds 30 places'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
