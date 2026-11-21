import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/park_loop_cad_screen.dart';
import 'package:architect_engine/services/park_loop_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief park({Map<String,Object> edits=const {},bool institutional=false,String type='public_park'}) => ProjectBrief(
  floorCount:null,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:institutional?'institutional':'infrastructure',
    subcategoryId:institutional?'sports':'public_realm',typeId:type,
    configurationId:institutional?'outdoor':'public_open_space',plotShapeId:'rectangular'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'park_measured_loop','pl_width':40,'pl_depth':28,'pl_radius':6,'pl_path':3,'pl_west':3,'pl_south':4,
    'pl_entry':2,'pl_shift':-4,'pl_lawn_w':32,'pl_lawn_d':20,'pl_lawn_gap':1,...edits,
  }));

void main() {
  const widthFt=50/.3048,depthFt=40/.3048;
  ParkLoopCadResult run(ProjectBrief b)=>ParkLoopCadGenerator().generate(b,widthFt:widthFt,depthFt:depthFt);

  test('opt-in persists and supports both public park taxonomy paths', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o)=>o.id),isNot(contains('park_measured_loop')));
    expect(cadOutputOptions(warehouseLoading:false,parkLoop:true).options.map((o)=>o.id),contains('park_measured_loop'));
    final saved=ProjectBrief.fromMap(park().toMap())!;
    expect(ParkLoopCadGenerator.requested(saved),isTrue);
    expect(run(saved).issue,isNull);
    expect(run(park(institutional:true)).issue,isNull);
  });

  test('centreline lap and uniform offset area are exact with tangent native quarter arcs', () {
    final r=run(park());
    final lap=88+12*math.pi;
    expect(r.lapM,closeTo(lap,1e-10));
    expect(r.loopM2,closeTo(43*31-37*25-(4-math.pi)*(7.5*7.5-4.5*4.5),1e-10));
    expect((r.outerWidthMm,r.outerDepthMm,r.entryM2),(43000,31000,8));
    final c=r.drawing!;
    expect(c.arcs.length,12);
    for(final (layer,radius) in [('PARK_LOOP_AXIS',6000),('PARK_LOOP_INNER',4500),('PARK_LOOP_OUTER',7500)]) {
      final lines=c.lines.where((l)=>l.layer==layer);
      final endpoints=[for(final l in lines) ...[l.start,l.end]];
      for(final a in c.arcs.where((a)=>a.layer==layer)) {
        expect(a.radius,radius);
        expect(a.end-a.start,90);
        for(final degrees in [a.start,a.end]) {
          final angle=degrees*math.pi/180;
          final x=a.center.x+a.radius*math.cos(angle),y=a.center.y+a.radius*math.sin(angle);
          expect(endpoints.any((p)=>(p.x-x).abs()<1e-7 && (p.y-y).abs()<1e-7),isTrue);
        }
      }
    }
    final outerSouth=c.lines.where((l)=>l.layer=='PARK_LOOP_OUTER' && l.start.y==4000 && l.end.y==4000);
    expect(outerSouth.map((l)=>(l.start.x,l.end.x)),[(10500,19500),(21500,38500)]);
    final walk=c.lines.where((l)=>l.layer=='PARK_LOOP_ENTRY');
    expect(walk.map((l)=>(l.start.x,l.start.y,l.end.y)),[(19500,0,4000),(21500,0,4000)]);
    expect(c.toDxf(),contains('CENTRELINE LAP 125.699 M / LOOP 377.097 M2'));
    expect(c.toDxf(),contains('ARC'));
  });

  test('exact setback and tangent fits; lawn clearance can exhaust the inner radius', () {
    final exact=run(park(edits:{'left_setback':3,'right_setback':4,'front_setback':4,'rear_setback':5,
      'pl_shift':13,'pl_lawn_gap':5,'pl_lawn_w':27,'pl_lawn_d':15}));
    expect(exact.issue,isNull);
    expect(exact.drawing!.lines.every((l)=>l.start.x!=l.end.x || l.start.y!=l.end.y),isTrue);
    final fail=run(park(edits:{'pl_lawn_gap':5,'pl_lawn_w':27,'pl_lawn_d':15.001}));
    expect(fail.issue,contains('lawn reserve and clearance'));
  });

  test('reports setback, inner radius, approach and actual rounded-corner failures', () {
    for(final (brief,message) in [
      (park(type:'public_garden'),'Select Public Park'),
      (park(edits:{'pl_radius':14}),'positive straight segments'),
      (park(edits:{'pl_radius':1.5}),'half the path width'),
      (park(edits:{'pl_entry':3.001}),'must not exceed'),
      (park(edits:{'pl_shift':-13.001}),'between its two tangent points'),
      (park(edits:{'rear_setback':5.001}),'rear plot edge'),
      (park(edits:{'pl_lawn_w':34,'pl_lawn_d':22}),'rounded corners'),
    ]) {
      final r=run(brief);
      expect(r.issue,contains(message));
      expect(r.drawing,isNull);
    }
  });

  testWidgets('shows lap summary and blocks export on rounded-corner conflict',(tester) async {
    await tester.pumpWidget(MaterialApp(home:ParkLoopCadScreen(name:'Park loop',brief:park(),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('Centreline lap 125.699 m'),findsOneWidget);
    expect(find.text('Share walking loop DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:ParkLoopCadScreen(key:const ValueKey('failed'),name:'Park loop',
      brief:park(edits:{'pl_lawn_w':34,'pl_lawn_d':22}),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('including its rounded corners'),findsOneWidget);
    expect(find.text('Share walking loop DXF'),findsNothing);
  });
}
