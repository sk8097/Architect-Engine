import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/truck_sweep_screen.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/truck_sweep_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief truck({Map<String,Object> edits = const {}, String type = 'general_warehouse', Map<String,int> spaces = const {}}) => ProjectBrief(
  floorCount: 1, parking: ProjectParking.none, features: const [], taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: 'industrial', subcategoryId: 'logistics', typeId: type, plotShapeId: 'rectangular', spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'truck_reverse_sweep', 'ts_width': 48, 'ts_depth': 32, 'ts_offset': 2,
    'ts_dock_x': 17, 'ts_dock_width': 4, 'ts_radius': 8, 'ts_wheelbase': 5, 'ts_front': 1, 'ts_rear': 2,
    'ts_body_width': 2.5, 'ts_buffer': .3, 'ts_lead': 4, 'ts_reverse': 8, 'ts_stop_gap': .5, 'ts_approach_side': 'right', ...edits,
  }));

void main() {
  TruckSweepResult run(ProjectBrief brief, [String facing = 'South']) =>
    TruckSweepGenerator().generate(brief, widthFt: 185, depthFt: 125, facing: facing);
  double distance(CadPoint a, CadPoint b) => math.sqrt(math.pow(a.x-b.x,2)+math.pow(a.y-b.y,2));
  CadPoint arcAt(CadArc a, num deg) => CadPoint(a.center.x+a.radius*math.cos(deg*math.pi/180), a.center.y+a.radius*math.sin(deg*math.pi/180));

  test('exact quarter-circle, buffer tracks and dock alignment survive all frontages and reopening', () {
    final brief = ProjectBrief.fromMap(truck(edits: {'ts_obstacles':'SAFE,2,2,2,2'}).toMap())!;
    expect(TruckSweepGenerator.requested(brief), isTrue);
    expect(cadOutputOptions(warehouseLoading: true, truckSweep: true).options.map((o) => o.id), contains('truck_reverse_sweep'));
    for (final facing in ['South','East','North','West']) {
      final result = run(brief,facing);
      expect(result.issue,isNull,reason:'$facing: ${result.issue}');
      expect(result.axleTravelMm,closeTo(12000+4000*math.pi,.001));
      final cad = result.drawing!, arc = cad.arcs.singleWhere((a)=>a.layer=='TRUCK_AXLE');
      final legs = cad.lines.where((l)=>l.layer=='TRUCK_AXLE').toList();
      expect(arc.radius,8000);
      expect((arc.end-arc.start)%360,closeTo(90,1e-8));
      expect(distance(arcAt(arc,arc.end),legs.first.end),lessThan(.001));
      expect(distance(arcAt(arc,arc.start),legs.last.start),lessThan(.001));
      expect(distance(legs.first.start,legs.first.end),4000);
      expect(distance(legs.last.start,legs.last.end),8000);
      final turned = facing=='East'||facing=='West';
      expect(turned ? (legs.last.end.x-legs.last.start.x).abs() : (legs.last.end.y-legs.last.start.y).abs(),8000);
      // The parked rear bumper is half a metre from the dock; its buffered
      // trace extends another 300 mm but stays inside the apron.
      final expected = switch(facing) {'West'=>29500,'East'=>(125*.3048*1000).round()-29500,
        'North'=>(125*.3048*1000).round()-29500,_=>29500};
      expect(turned ? legs.last.end.x : legs.last.end.y,expected);
      final sweep = cad.arcs.where((a)=>a.layer=='TRUCK_CLEAR_SWEEP').toList();
      expect(sweep.length,4);
      for (final a in sweep) { expect((a.end-a.start)%360,closeTo(90,1e-8)); }
      expect(cad.lines.where((l)=>l.layer=='TRUCK_POSES').length,20);
      final dxf=cad.toDxf();
      for (final layer in ['TRUCK_APRON','TRUCK_BAY','TRUCK_OBSTACLE','TRUCK_AXLE','TRUCK_CLEAR_SWEEP','TRUCK_POSES']) { expect(dxf,contains(layer)); }
      expect(RegExp(r'\r?\nARC\r?\n8\r?\nTRUCK_CLEAR_SWEEP\r?\n').allMatches(dxf).length,4);
    }
  });

  test('left approach mirrors right geometry about the dock without changing axle travel', () {
    final right = run(truck()), left = run(truck(edits: {'ts_approach_side':'left','ts_dock_x':31}));
    expect(left.issue,isNull);
    expect(left.axleTravelMm,right.axleTravelMm);
    final rightArc=right.drawing!.arcs.singleWhere((a)=>a.layer=='TRUCK_AXLE');
    final leftArc=left.drawing!.arcs.singleWhere((a)=>a.layer=='TRUCK_AXLE');
    expect(rightArc.center.x+leftArc.center.x,52000); // 48 m apron + twice the 2 m offset.
    expect(leftArc.center.y,rightArc.center.y);
    expect((leftArc.end-leftArc.start)%360,closeTo(90,1e-8));
    final lead=left.drawing!.lines.firstWhere((l)=>l.layer=='TRUCK_AXLE');
    expect(distance(arcAt(leftArc,leftArc.start),lead.end),lessThan(.001));
  });

  test('boundary, bay and conflicts on different manoeuvre legs block export', () {
    for (final (brief,issue) in [
      (truck(type:'cross_dock'),'supported single-sided'),
      (truck(spaces:{'loading':1}),'no separate Space selections'),
      (truck(edits:{'ts_width':60}),'outside the measured'),
      (truck(edits:{'ts_dock_width':3}),'accommodate the measured clearance'),
      (truck(edits:{'ts_stop_gap':.2}),'accommodate the measured clearance'),
      (truck(edits:{'ts_lead':20}),'leaves the paved apron during the straight approach'),
      (truck(edits:{'ts_obstacles':'POST,22.25,11.0,0.1,0.1'}),'POST during the 90-degree turn'),
      (truck(edits:{'ts_obstacles':'DOCKPOST,16.8,30.5,0.2,0.2'}),'DOCKPOST during the straight docking leg'),
      (truck(edits:{'ts_obstacles':'OUTSIDE,47,31,2,2'}),'entirely inside the apron'),
    ]) {
      final result=run(brief);
      expect(result.issue,contains(issue),reason:issue);
      expect(result.drawing,isNull);
    }
  });

  testWidgets('only a fitted sweep exposes DXF on preview',(tester) async {
    await tester.pumpWidget(MaterialApp(home:TruckSweepScreen(name:'Apron trial',brief:truck(),widthFt:185,depthFt:125,facing:'South')));
    expect(find.text('Rigid truck swept-path CAD'),findsOneWidget);
    expect(find.text('Share swept-path DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:TruckSweepScreen(key:const ValueKey('blocked'),name:'Apron trial',
      brief:truck(edits:{'ts_obstacles':'POST,22.25,11.0,0.1,0.1'}),widthFt:185,depthFt:125,facing:'South')));
    expect(find.textContaining('POST during the 90-degree turn'),findsOneWidget);
    expect(find.text('Share swept-path DXF'),findsNothing);
  });
}
