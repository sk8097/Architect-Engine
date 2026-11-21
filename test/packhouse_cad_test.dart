import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/concept_zoning.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/packhouse_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/packhouse_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief packhouse({bool store = false, Map<String,Object> answers = const {}, Map<String,int> counts = const {},
  Map<String, Map<String,Object>> rooms = const {}, String configuration = 'processing_plus_storage'}) {
  final depths = {'receiving':4,'grading':5,'packaging':4,if(store) 'finished_store':3,'dispatch':3};
  return ProjectBrief(floorCount:1,parking:ProjectParking.none,features:const [],taxonomy:TaxonomySelection(version:projectTaxonomyVersion,
    categoryId:'rural',subcategoryId:'agro_processing',typeId:'fruit_vegetable_packhouse',configurationId:configuration,plotShapeId:'rectangular',
    spaceQuantities:{for(final key in depths.keys.toList().reversed) key:1,...counts}),
    requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
      'cad_output':'packhouse_flow','ph_access':'confirmed','cad_offset_front':5,'cad_offset_left':3,
      'cad_plate_width':12,'cad_plate_depth':store?20.2:17,'cad_wall':.2,'ph_transfer':1.8,'ph_end_opening':2.4,
      'ph_route':1.6,'ph_apron_width':4,'ph_receiving_apron':3,'ph_dispatch_apron':2.8,...answers,
    },spaceDetails:{for(final e in depths.entries) e.key:{'width':11.6,'length':e.value,...?rooms[e.key]}}));
}

void main() {
  PackhouseCadResult run(ProjectBrief brief,[String facing='South']) =>
    PackhouseCadGenerator().generate(brief,widthFt:100,depthFt:110,facing:facing);
  test('same front-to-rear sequence, fit and editable arrow direction on all cardinal frontages', () {
    for (final store in [false,true]) {
      final brief=ProjectBrief.fromMap(packhouse(store:store).toMap())!;
      final ids=['receiving','grading','packaging',if(store) 'finished_store','dispatch'];
      for(final facing in ['South','North','East','West']) {
        final result=run(brief,facing);
        expect(result.issue,isNull,reason:facing);
        final plan=result.plan!;
        expect(validatePlanPartition(plan),isNull);
        expect(plan.rooms.map((r)=>r.id),ids);
        expect(plan.openings.map((o)=>o.kind).toSet(),{PlanOpeningKind.materialOpening});
        expect(plan.openings.map((o)=>(o.from,o.to)),[(AutomaticFloorPlan.entry,ids.first),
          for(var i=1;i<ids.length;i++) (ids[i-1],ids[i]), (AutomaticFloorPlan.entry,ids.last)]);
        final [receiving, dispatch, lane]=result.zones;
        final dir=switch(facing){'North'=>ZoneDirection.south,'East'=>ZoneDirection.west,'West'=>ZoneDirection.east,_=>ZoneDirection.north};
        expect(lane.direction,dir);
        expect(plan.plot.contains(lane.bounds),isTrue);
        expect(plan.walls.where(lane.bounds.overlaps),isEmpty);
        expect(plan.rooms.every((r)=>r.bounds.overlaps(lane.bounds)),isTrue);
        expect(plan.openings.every((o)=>o.bounds.overlaps(lane.bounds)),isTrue);
        expect(plan.footprint.overlaps(receiving.bounds),isFalse);
        expect(plan.footprint.overlaps(dispatch.bounds),isFalse);
        final horizontal=facing=='East'||facing=='West';
        expect(horizontal?lane.bounds.depth:lane.bounds.width,1600);
        expect(receiving.bounds.area,4000*3000);
        expect(dispatch.bounds.area,4000*2800);
        final drawing=FloorPlanCad.fromPlan(plan,siteZones:result.zones);
        expect(drawing.lines.where((line)=>line.layer=='PACKHOUSE_OPENINGS').length,ids.length+1);
        final flow=drawing.lines.where((line)=>line.layer=='PACKHOUSE_FLOW').toList();
        expect(flow.length,11);
        final spine=flow[4];
        expect(switch(dir){
          ZoneDirection.north=>spine.start.x==spine.end.x && spine.start.y<spine.end.y,
          ZoneDirection.south=>spine.start.x==spine.end.x && spine.start.y>spine.end.y,
          ZoneDirection.east=>spine.start.y==spine.end.y && spine.start.x<spine.end.x,
          ZoneDirection.west=>spine.start.y==spine.end.y && spine.start.x>spine.end.x,
        },isTrue);
        expect(drawing.toDxf(),contains('PACKHOUSE_PADS'));
      }
    }
  });

  test('unsafe fit and mismatched process scope return blockers without substitute geometry', () {
    for (final (brief,reason) in [
      (packhouse(configuration:'cold_chain'),'cold chain'),
      (packhouse(answers:{'ph_access':'pending'}),'independent on-site access'),
      (packhouse(counts:{'cold_room':1}),'raw/cold storage'),
      (packhouse(counts:{'dispatch':2}),'exactly one'),
      (packhouse(answers:{'right_setback':18}),'right setback'),
      (packhouse(answers:{'ph_receiving_apron':6}),'outside the plot'),
      (packhouse(answers:{'ph_route':2}),'fit through every opening'),
      (packhouse(answers:{'cad_plate_depth':17.1}),'17.000 m'),
      (packhouse(rooms:{'grading':{'width':10}}),'full clear building width'),
      (packhouse(rooms:{'grading':{'services':['wet']}}),'wet or specialist'),
      (packhouse(rooms:{'receiving':{'adjacent_required':['dispatch']}}),'room relationships'),
      (packhouse(rooms:{'packaging':{'area_min':50,'area_unit':'sqm'}}),'area limits'),
    ]) {
      final result=run(brief);
      expect(result.plan,isNull,reason:reason);
      expect(result.zones,isEmpty);
      expect(result.issue,contains(reason));
    }
  });

  testWidgets('valid plan enables DXF, unsupported brief remains saved without DXF', (tester) async {
    Future<void> open(ProjectBrief brief) => tester.pumpWidget(MaterialApp(home:PackhouseCadScreen(key:ObjectKey(brief),name:'Packhouse',
      brief:brief,widthFt:100,depthFt:110,facing:'South')));
    await open(packhouse());
    expect(find.text('Save or share DXF'),findsOneWidget);
    await open(packhouse(configuration:'cold_chain'));
    expect(find.text('No plan generated'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
