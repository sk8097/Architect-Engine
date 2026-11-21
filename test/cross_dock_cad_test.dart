import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/concept_zoning.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/warehouse_loading_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/cross_dock_cad_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/warehouse_loading_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief crossDock({Map<String,Object> edits=const {},String type='cross_dock',String? configuration,
  ProjectParking? parking,Map<String,int> spaces=const {}})=>ProjectBrief(floorCount:1,parking:parking,features:const [],
    taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'industrial',subcategoryId:'logistics',typeId:type,
      configurationId:configuration,plotShapeId:'rectangular',spaceQuantities:spaces),
    requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
      'cad_output':'warehouse_cross_dock','xd_access':'confirmed','dock_count':5,'xd_in_count':2,'dock_type':['grade','cross'],
      'wh_width':32,'wh_depth':24,'wh_wall':.2,'xd_left':4,'wh_staff_width':2,'wh_staff_door':.9,'xd_lane':6,
      'wh_vehicle_basis':'Measured vehicle clearance study',
      'xd_in_bay_width':4,'xd_in_bay_depth':7,'xd_in_opening':3,'xd_in_apron_width':14,'xd_in_apron_depth':8,
      'xd_in_drive_width':6,'xd_in_approach_depth':4,'xd_in_stage_depth':5,
      'xd_out_bay_width':4.4,'xd_out_bay_depth':9,'xd_out_opening':3.2,'xd_out_apron_width':20,'xd_out_apron_depth':10,
      'xd_out_drive_width':7,'xd_out_approach_depth':6,'xd_out_stage_depth':6,...edits,
    }));

void main() {
  WarehouseLoadingResult run(ProjectBrief brief,[String facing='South'])=>CrossDockCadGenerator().generate(brief,widthFt:160,depthFt:240,facing:facing);
  test('separate opposing banks, connected handoffs and staff path on every cardinal frontage', () {
    final restored=ProjectBrief.fromMap(crossDock().toMap())!;
    for (final facing in ['South','North','East','West']) {
      final result=run(restored,facing);
      expect(result.issue,isNull,reason:facing);
      final plan=result.plan!,plot=plan.plot;
      expect(validatePlanPartition(plan),isNull);
      final docks=plan.openings.where((o)=>o.kind==PlanOpeningKind.loadingDoor).toList();
      expect(docks.length,5);
      final zones={for(final z in result.zones)z.id:z};
      final staff=zones['staff_walk']!.bounds;
      final lane=zones['through_lane']!;
      expect(lane.direction,switch(facing){'North'=>ZoneDirection.south,'East'=>ZoneDirection.west,'West'=>ZoneDirection.east,_=>ZoneDirection.north});
      final sideY=facing=='East'||facing=='West';
      expect(sideY?lane.bounds.depth:lane.bounds.width,6000);
      bool touch(PlanRect a,PlanRect b)=>((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top)||
        ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);
      String boundary(PlanRect b)=>b.bottom==plot.bottom?'South':b.top==plot.top?'North':b.left==plot.left?'West':'East';
      final inbound=zones['in_drive']!.bounds,outbound=zones['out_drive']!.bounds;
      final opposite={'South':'North','North':'South','East':'West','West':'East'};
      final staffSide={'South':'West','North':'East','East':'South','West':'North'};
      expect(boundary(inbound),facing);
      expect(boundary(outbound),opposite[facing]);
      expect(boundary(staff),staffSide[facing]);
      final staffDoor=plan.openings.singleWhere((o)=>o.to=='staff_aisle');
      final transferDoor=plan.openings.singleWhere((o)=>o.from=='staff_aisle');
      expect(touch(staff,staffDoor.bounds),isTrue);
      expect(transferDoor.to,'freight_hall');
      expect(transferDoor.bounds.overlaps(lane.bounds),isFalse);
      for (final (id,count,offset,width,depth,opening) in [('in',2,0,4000,7000,3000),('out',3,2,4400,9000,3200)]) {
        final drive=zones['${id}_drive']!.bounds,apron=zones['${id}_apron']!.bounds,stage=zones['${id}_stage']!.bounds;
        expect(touch(drive,apron),isTrue);
        expect(stage.overlaps(lane.bounds),isTrue);
        for (var i=0;i<count;i++) {
          final bay=zones['${id}_bay_$i']!.bounds,dock=docks[offset+i].bounds;
          expect(bay.area,width*depth);
          expect(sideY?dock.depth:dock.width,opening);
          expect(touch(apron,bay)&&touch(bay,dock)&&touch(dock,stage),isTrue);
          expect(staff.overlaps(bay),isFalse);
        }
      }
      final dxf=FloorPlanCad.fromPlan(plan,siteZones:result.zones);
      for(final layer in ['CROSS_DOCK_INBOUND','CROSS_DOCK_OUTBOUND','CROSS_DOCK_FLOW','CROSS_DOCK_STAGING','DOCK_OPENINGS','WALK_ROUTE']) {
        expect(dxf.lines.where((l)=>l.layer==layer),isNotEmpty);
      }
      expect(dxf.toDxf(),contains('OPPOSING CROSS-DOCK BANKS'));
    }
  });

  test('invalid counts, yard and staffing geometry or specialist requests produce no CAD', () {
    for (final (input,reason) in [
      (crossDock(edits:{'xd_in_count':5}),'at least one dock in each bank'),
      (crossDock(edits:{'xd_access':'pending'}),'Confirm independent'),
      (crossDock(edits:{'xd_out_approach_depth':20}),'available plot depth'),
      (crossDock(edits:{'xd_out_apron_width':10}),'Outbound dock bank'),
      (crossDock(edits:{'xd_lane':29}),'clearance beside'),
      (crossDock(edits:{'xd_out_stage_depth':19}),'enough transfer space'),
      (crossDock(edits:{'left_setback':5}),'left setback'),
      (crossDock(edits:{'dock_type':['high']}),'dock-high equipment'),
      (crossDock(configuration:'rack_storage'),'not racks'),
      (crossDock(type:'cold_storage'),'Cross-Dock, Distribution Centre'),
      (crossDock(spaces:{'storage':1}),'extra spaces'),
    ]) {
      final result=run(input);
      expect(result.issue,contains(reason));
      expect(result.plan,isNull);
      expect(result.zones,isEmpty);
    }
  });

  testWidgets('warehouse preview distinguishes cross-dock and blocks invalid export', (tester) async {
    Future<void> open(ProjectBrief brief)=>tester.pumpWidget(MaterialApp(home:WarehouseLoadingScreen(key:ObjectKey(brief),
      name:'Cross-dock',brief:brief,widthFt:160,depthFt:240,facing:'South')));
    await open(crossDock());
    expect(find.text('Warehouse cross-dock CAD'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsOneWidget);
    await open(crossDock(edits:{'xd_in_count':5}));
    expect(find.text('No plan generated'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
