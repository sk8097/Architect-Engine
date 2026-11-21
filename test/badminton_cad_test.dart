import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/badminton_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/badminton_cad_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief sports({Map<String,Object> edits=const {},Map<String,Map<String,Object>> rooms=const {},
  Map<String,int> spaces=const {},bool viewing=true,int courts=2,String type='indoor_arena',String config='indoor'})=>ProjectBrief(
  floorCount:1,parking:ProjectParking.none,features:const [],taxonomy:TaxonomySelection(version:projectTaxonomyVersion,
    categoryId:'institutional',subcategoryId:'sports',typeId:type,configurationId:config,plotShapeId:'rectangular',
    spaceQuantities:{'field_court':courts,'athlete_change':1,if(viewing) 'spectator_seating':1,...spaces}),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'badminton_hall','cad_plate_width':21.6,'cad_plate_depth':24,'cad_wall':.2,'cad_door':1,
    'cad_offset_left':4,'cad_offset_front':4,'activity_areas':courts,'spectators':viewing?20:0,
    'bc_side_clear':1.4,'bc_end_clear':2,'bc_singles_inset':.46,'bc_short_service':1.98,'bc_long_service':.76,
    'bc_player_walk':1.8,'bc_view_aisle':1.35,'bc_seat_span':.5,'bc_seat_depth':.7,...edits,
  },spaceDetails:{
    'field_court':{'width':6.1,'length':13.4},'athlete_change':{'width':4,'length':4},
    if(viewing) 'spectator_seating':{'width':2.8,'length':23.6},...rooms,
  }));

void main() {
  BadmintonCadResult run(ProjectBrief brief,[String facing='South'])=>
    BadmintonCadGenerator().generate(brief,widthFt:110,depthFt:125,facing:facing);
  const lobby='badminton_lobby',hall='badminton_hall',change='badminton_change',view='badminton_view';
  bool touches(PlanRect a,PlanRect b)=>
    ((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top)||
    ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);

  test('two fitted courts, service lines, player route and glazed spectator strip on four frontages', () {
    final brief=ProjectBrief.fromMap(sports().toMap())!;
    expect(BadmintonCadGenerator.requested(brief),isTrue);
    for(final facing in ['South','North','East','West']) {
      final result=run(brief,facing);
      expect(result.issue,isNull,reason:'$facing: ${result.issue}');
      final plan=result.plan!,rooms={for(final r in result.plan!.rooms)r.id:r.bounds};
      expect(validatePlanPartition(plan),isNull);
      final doors=plan.openings.where((o)=>o.kind==PlanOpeningKind.door);
      expect(doors.where((o)=>o.from==AutomaticFloorPlan.entry).map((o)=>o.to),unorderedEquals([lobby,view]));
      expect(doors.singleWhere((o)=>o.to==change).from,lobby);
      expect(doors.singleWhere((o)=>o.from==hall).to,lobby);
      expect(doors.where((o)=>o.from==view||o.to==view).single.from,AutomaticFloorPlan.entry);
      final glass=plan.openings.singleWhere((o)=>o.kind==PlanOpeningKind.window);
      expect((glass.from,glass.to),(hall,view));
      expect(touches(glass.bounds,rooms[hall]!)&&touches(glass.bounds,rooms[view]!),isTrue);
      final zones={for(final z in result.zones)z.id:z.bounds};
      final player=zones['bc_player_walk']!,spectator=zones['bc_view_walk']!,aisle=zones['bc_view_aisle']!;
      expect(player.overlaps(spectator),isFalse);
      expect(touches(player,doors.singleWhere((o)=>o.from==AutomaticFloorPlan.entry&&o.to==lobby).bounds),isTrue);
      final viewDoor=doors.singleWhere((o)=>o.to==view).bounds;
      expect(touches(spectator,viewDoor)&&touches(viewDoor,aisle),isTrue);
      final rotated=facing=='East'||facing=='West';
      expect(rotated?aisle.depth:aisle.width,1350);
      expect(zones['bc_runoff_0']!.overlaps(zones['bc_runoff_1']!),isFalse);
      for(var i=0;i<2;i++) {
        final court=zones['bc_court_$i']!,runoff=zones['bc_runoff_$i']!;
        expect(rooms[hall]!.contains(runoff),isTrue);
        expect(runoff.contains(court),isTrue);
        expect(rotated?court.depth:court.width,6100);
        expect(rotated?court.width:court.depth,13400);
        expect(rotated?runoff.depth-court.depth:runoff.width-court.width,2800);
        expect(rotated?runoff.width-court.width:runoff.depth-court.depth,4000);
        final markings=plan.markings.where((m)=>court.contains(PlanRect(m.fromX,m.fromY,m.fromX,m.fromY)) &&
          court.contains(PlanRect(m.toX,m.toY,m.toX,m.toY))).toList();
        expect(markings.length,9);
        final net=markings.singleWhere((m)=>m.layer=='BADMINTON_NET');
        expect(rotated?net.fromX:net.fromY,rotated?(court.left+court.right)~/2:(court.bottom+court.top)~/2);
        expect(rotated?(net.toY-net.fromY).abs():(net.toX-net.fromX).abs(),6100);
      }
      final seats=result.zones.where((z)=>z.layer=='BADMINTON_SEATS').toList();
      expect(seats.length,20);
      for(final seat in seats) {
        final b=seat.bounds;
        expect(rooms[view]!.contains(b)&&touches(b,aisle),isTrue);
        expect(b.area,500*700);
        expect(rotated?b.left>=glass.bounds.left&&b.right<=glass.bounds.right:b.bottom>=glass.bounds.bottom&&b.top<=glass.bounds.top,isTrue);
      }
      final drawing=FloorPlanCad.fromPlan(plan,siteZones:result.zones);
      expect(drawing.lines.where((l)=>l.layer=='BADMINTON_LINES').length,16);
      expect(drawing.lines.where((l)=>l.layer=='BADMINTON_NET').length,2);
      final dxf=drawing.toDxf();
      for(final layer in ['BADMINTON_COURTS','BADMINTON_LINES','BADMINTON_NET','BADMINTON_RUNOFF','BADMINTON_PLAYERS',
        'BADMINTON_SPECTATOR','BADMINTON_VIEW_DIVIDER','BADMINTON_SEATS']) {expect(dxf,contains(layer));}
    }
  });

  test('one-court layout draws no spectator doors, rooms or fixtures when viewing is not requested', () {
    final result=run(sports(viewing:false,courts:1,type:'sports_club',edits:{'cad_plate_width':12.2,'bc_short_service':2}));
    expect(result.issue,isNull);
    final plan=result.plan!;
    expect(validatePlanGeometry(plan),isNull);
    expect(plan.rooms.any((r)=>r.id==view),isFalse);
    expect(result.zones.where((z)=>z.layer=='BADMINTON_SEATS'),isEmpty);
    expect(plan.markings.length,9);
    final net=plan.markings.singleWhere((m)=>m.layer=='BADMINTON_NET');
    expect(plan.markings.where((m)=>m.layer=='BADMINTON_LINES' && m.fromY==m.toY && (m.fromY-net.fromY).abs()==2000).length,2);
  });

  test('count conflicts, run-off and seating fit, and custom requests block all output', () {
    for(final (brief,issue) in [
      (sports(type:'swimming_pool'),'supported indoor sports hall'),
      (sports(config:'outdoor'),'one indoor ground-floor hall'),
      (sports(edits:{'activity_areas':1}),'count must match'),
      (sports(edits:{'bc_singles_inset':3.1}),'inside the supplied playing boundary'),
      (sports(edits:{'bc_side_clear':1.6}),'run-offs do not fit'),
      (sports(edits:{'spectators':60}),'all seats alongside the glazing'),
      (sports(viewing:false,edits:{'spectators':10}),'zero without a viewing strip'),
      (sports(spaces:{'accessible_viewing':1}),'No other rooms'),
      (sports(rooms:{'athlete_change':{'width':4,'length':1.9}}),'both lobby door swings'),
    ]) {
      final result=run(brief);
      expect(result.issue,contains(issue),reason:issue);
      expect(result.plan,isNull);
      expect(result.zones,isEmpty);
    }
  });

  testWidgets('badminton preview offers DXF only when measured courts fit', (tester) async {
    await tester.pumpWidget(MaterialApp(home:BadmintonCadScreen(name:'Court hall',brief:sports(),
      widthFt:110,depthFt:125,facing:'North')));
    expect(find.text('Indoor badminton CAD'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:BadmintonCadScreen(key:const ValueKey('blocked'),name:'Court hall',
      brief:sports(edits:{'bc_side_clear':1.6}),widthFt:110,depthFt:125,facing:'North')));
    expect(find.textContaining('run-offs do not fit'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
