import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/concept_zoning.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/assembly_cad_screen.dart';
import 'package:architect_engine/services/assembly_cad_generator.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief factory({Map<String,Object> edits=const {},Map<String,int> counts=const {},Map<String,Map<String,Object>> rooms=const {},
  String type='assembly_plant',String configuration='assembly_line',int floors=1})=>ProjectBrief(
  floorCount:floors,parking:ProjectParking.none,features:const [],taxonomy:TaxonomySelection(version:projectTaxonomyVersion,
    categoryId:'industrial',subcategoryId:'manufacturing',typeId:type,configurationId:configuration,plotShapeId:'rectangular',
    spaceQuantities:{'raw_material_receiving':1,'production_line':1,'quality_control':1,'dispatch':1,...counts}),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'assembly_workflow','as_scope':'confirmed','cad_plate_width':14,'cad_plate_depth':30,'cad_wall':.2,
    'cad_offset_left':4,'cad_offset_front':5,'cad_corridor':1.6,'cad_door':.95,'as_goods_opening':3.2,
    'as_goods_lane':2.4,'as_receiving_pad':4,'as_dispatch_pad':3,'as_work_aisle':1.4,'as_station_count':4,
    'as_bench_width':2,'as_bench_depth':1.5,'as_cell_clear':.55,...edits,
  },spaceDetails:{
    'raw_material_receiving':{'width':11.8,'length':6},'production_line':{'width':11.8,'length':13},
    'quality_control':{'width':11.8,'length':4},'dispatch':{'width':11.8,'length':6},...rooms,
  }));

void main() {
  AssemblyCadResult run(ProjectBrief brief,[String facing='South'])=>
    AssemblyCadGenerator().generate(brief,widthFt:100,depthFt:140,facing:facing);
  const passage='assembly_staff_passage',prod='assembly_production_line',qc='assembly_quality_control';
  bool touches(PlanRect a,PlanRect b)=>
    ((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top)||
    ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);

  test('saved measured assembly makes continuous material flow and separated staff access on four frontages', () {
    final brief=ProjectBrief.fromMap(factory().toMap())!;
    expect(AssemblyCadGenerator.requested(brief),isTrue);
    for(final facing in ['South','North','East','West']) {
      final result=run(brief,facing);
      expect(result.issue,isNull,reason:'$facing: ${result.issue}');
      final plan=result.plan!, room={for(final r in result.plan!.rooms)r.id:r.bounds};
      expect(validatePlanGeometry(plan,sealedRooms:{'assembly_raw_material_receiving','assembly_dispatch'}),isNull);
      final doors=plan.openings.where((o)=>o.kind==PlanOpeningKind.door);
      final staffDoor=doors.singleWhere((o)=>o.from==AutomaticFloorPlan.entry);
      expect(staffDoor.to,passage);
      expect(doors.where((o)=>o.from==passage).map((o)=>o.to),unorderedEquals([prod,qc]));
      final workDoor=doors.singleWhere((o)=>o.to==prod);
      final openings=plan.openings.where((o)=>o.kind==PlanOpeningKind.materialOpening).toList();
      expect(openings.map((o)=>(o.from,o.to)),[
        (AutomaticFloorPlan.entry,'assembly_raw_material_receiving'),('assembly_raw_material_receiving',prod),
        (prod,qc),(qc,'assembly_dispatch'),(AutomaticFloorPlan.entry,'assembly_dispatch'),
      ]);
      final zones={for(final z in result.zones)z.id:z.bounds};
      final lane=zones['as_material_lane']!,walk=zones['as_staff_walk']!,work=zones['as_work_aisle']!;
      final inPad=zones['as_receiving_pad']!,outPad=zones['as_dispatch_pad']!;
      final rotated=facing=='East'||facing=='West';
      expect(rotated?lane.depth:lane.width,2400);
      expect(rotated?lane.width:lane.depth,37000);
      expect(rotated?work.depth:work.width,1400);
      expect(touches(workDoor.bounds,work),isTrue);
      expect(touches(walk,staffDoor.bounds),isTrue);
      expect(walk.overlaps(inPad) || work.overlaps(lane) || walk.overlaps(lane),isFalse);
      expect(touches(inPad,openings.first.bounds) && touches(outPad,openings.last.bounds),isTrue);
      expect([walk,inPad,outPad].every((b)=>plan.plot.contains(b)&&!plan.footprint.overlaps(b)),isTrue);
      expect(plan.walls.where(lane.overlaps),isEmpty);
      for(final h in openings) {
        final b=h.bounds;
        expect(rotated?b.depth:b.width,3200);
        expect(rotated?lane.bottom>=b.bottom&&lane.top<=b.top:lane.left>=b.left&&lane.right<=b.right,isTrue);
        expect(lane.overlaps(b),isTrue);
      }
      expect(result.zones.singleWhere((z)=>z.id=='as_material_lane').direction,switch(facing) {
        'North'=>ZoneDirection.south,'East'=>ZoneDirection.west,'West'=>ZoneDirection.east,_=>ZoneDirection.north,
      });
      final cells=result.zones.where((z)=>z.layer=='ASSEMBLY_CLEARANCE').toList();
      expect(cells.length,4);
      for(var i=0;i<cells.length;i++) {
        final cell=cells[i].bounds,bench=zones['as_bench_$i']!;
        expect(cell.contains(bench),isTrue);
        expect(bench.area,2000*1500);
        expect(cell.area,3100*2600);
        expect(room[prod]!.contains(cell) && touches(cell,work) && !cell.overlaps(lane),isTrue);
        expect(cells.where((c)=>c!=cells[i]&&c.bounds.overlaps(cell)),isEmpty);
      }
      final drawing=FloorPlanCad.fromPlan(plan,siteZones:result.zones);
      expect(drawing.lines.where((l)=>l.layer=='ASSEMBLY_OPENINGS').length,5);
      expect(drawing.arcs.where((a)=>a.layer=='ASSEMBLY_STAFF').length,2);
      final dxf=drawing.toDxf();
      for(final layer in ['ASSEMBLY_OPENINGS','ASSEMBLY_WORK_AISLE','ASSEMBLY_STAFF','ASSEMBLY_MATERIAL','ASSEMBLY_PADS','ASSEMBLY_BENCHES','ASSEMBLY_CLEARANCE']) {
        expect(dxf,contains(layer));
      }
    }
  });

  test('optional process rooms extend the actual path without changing the required stages', () {
    final result=run(factory(type:'electronics_assembly',edits:{'cad_plate_depth':33.2,'as_station_count':5},
      counts:{'raw_store':1},rooms:{'raw_store':{'width':11.8,'length':3}}));
    expect(result.issue,isNull);
    expect(result.plan!.rooms.map((r)=>r.id),contains('assembly_raw_store'));
    expect(result.plan!.openings.where((o)=>o.kind==PlanOpeningKind.materialOpening).length,6);
    expect(result.zones.where((z)=>z.layer=='ASSEMBLY_BENCHES').length,5);
  });

  test('no fallback when a requested dimension, program or scope cannot fit', () {
    for(final (brief,issue) in [
      (factory(type:'heavy_manufacturing'),'supports Assembly Plant'),
      (factory(configuration:'cleanroom'),'Assembly Line arrangement'),
      (factory(floors:2),'ground-floor building'),
      (factory(edits:{'as_scope':'pending'}),'Confirm dry non-hazardous'),
      (factory(edits:{'as_goods_lane':3.3}),'fit every opening'),
      (factory(edits:{'as_work_aisle':.8}),'person-door swing'),
      (factory(edits:{'as_receiving_pad':6}),'extends beyond the plot'),
      (factory(edits:{'cad_plate_depth':29}),'30.000 m'),
      (factory(edits:{'as_station_count':6}),'working clearances do not fit'),
      (factory(rooms:{'quality_control':{'width':10,'length':4}}),'11.800 m'),
      (factory(counts:{'maintenance':1}),'no other rooms'),
    ]) {
      final result=run(brief);
      expect(result.issue,contains(issue),reason:issue);
      expect(result.plan,isNull);
      expect(result.zones,isEmpty);
    }
  });

  testWidgets('assembly preview exposes DXF only for a fitted layout', (tester) async {
    await tester.pumpWidget(MaterialApp(home:AssemblyCadScreen(name:'Assembly',brief:factory(),
      widthFt:100,depthFt:140,facing:'North')));
    expect(find.text('Factory assembly CAD'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:AssemblyCadScreen(key:const ValueKey('blocked'),name:'Assembly',
      brief:factory(edits:{'as_station_count':6}),widthFt:100,depthFt:140,facing:'North')));
    expect(find.textContaining('working clearances do not fit'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
