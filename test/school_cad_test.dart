import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/school_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/school_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief school({Map<String,Object> answers = const {}, Map<String,Map<String,Object>> rooms = const {},
  Map<String,int> counts = const {}, String type = 'primary_school', String configuration = 'single_building', int floors = 1}) =>
  ProjectBrief(floorCount:floors,parking:ProjectParking.none,features:const [],
    taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'institutional',subcategoryId:'education',
      typeId:type,configurationId:configuration,plotShapeId:'rectangular',
      spaceQuantities:{'administration':1,'classroom':2,'student_toilets':1,...counts}),
    requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
      'cad_output':'school_arrival','classrooms':2,'students':50,'cad_plate_width':18,'cad_plate_depth':18,
      'cad_offset_left':3,'cad_offset_front':4,'cad_wall':.20,'cad_door':.90,'cad_corridor':2,
      'school_lobby_depth':2.5,'school_entry_walk':1.6,...answers,
    },spaceDetails:{
      'administration':{'width':4,'length':2.2},
      'classroom':{'width':7.6,'length':6.8,'cad_window':1.8},
      'student_toilets':{'width':3,'length':2.8},...rooms,
    }));

void main() {
  SchoolCadResult run(ProjectBrief brief,[String facing='South']) =>
    SchoolCadGenerator().generate(brief,widthFt:100,depthFt:110,facing:facing);
  const arrival = 'school_arrival_route', learning = 'school_learning_route';
  test('visitor entry, check-in and learning threshold are connected correctly on every frontage', () {
    final brief = ProjectBrief.fromMap(school().toMap())!;
    for (final facing in ['South','North','East','West']) {
      final result = run(brief,facing);
      expect(result.issue,isNull,reason:facing);
      final plan=result.plan!;
      final rooms={for(final room in plan.rooms) room.id:room};
      expect(validatePlanGeometry(plan,sealedRooms:rooms.keys.where((id)=>id.startsWith('reserve_')).toSet()),isNull);
      final doors = plan.openings.where((o)=>o.kind==PlanOpeningKind.door).toList();
      final entry=doors.singleWhere((o)=>o.from==AutomaticFloorPlan.entry);
      final threshold=doors.singleWhere((o)=>o.from==arrival && o.to==learning);
      final lobbyDoor=doors.singleWhere((o)=>rooms[o.to]!.label=='Administration');
      expect(entry.to,arrival);
      expect(lobbyDoor.from,arrival);
      expect(doors.where((o)=>o.from==learning).map((o)=>rooms[o.to]!.label),unorderedEquals(['Classroom 1','Classroom 2','Student Toilets']));
      expect(plan.openings.where((o)=>o.kind==PlanOpeningKind.window && rooms[o.to]!.label.startsWith('Classroom')).length,2);
      final walk=result.siteZones.single.bounds;
      final front=entry.bounds;
      final split=threshold.bounds;
      final plot=plan.plot;
      expect(switch(facing) {
        'North'=>walk.top==plot.top && walk.bottom==front.top && front.bottom-split.top==2500,
        'East'=>walk.right==plot.right && walk.left==front.right && front.left-split.right==2500,
        'West'=>walk.left==plot.left && walk.right==front.left && split.left-front.right==2500,
        _=>walk.bottom==plot.bottom && walk.top==front.bottom && split.bottom-front.top==2500,
      },isTrue,reason:facing);
      expect(walk.overlaps(plan.footprint),isFalse);
      expect(walk.area,1600*4000);
      final drawing=FloorPlanCad.fromPlan(plan,siteZones:result.siteZones);
      expect(drawing.arcs.where((a)=>a.layer=='SCHOOL_THRESHOLD').single.radius,900);
      for(final layer in ['SCHOOL_ARRIVAL','SCHOOL_LEARNING','SCHOOL_THRESHOLD','SCHOOL_ENTRY_WALK']) {
        expect(drawing.lines.where((line)=>line.layer==layer),isNotEmpty);
        expect(drawing.toDxf(),contains(layer));
      }
    }
  });

  test('missing rooms, unsupported school programs and impossible thresholds block generation', () {
    for(final (input,message) in [
      (school(counts:{'student_toilets':0}),'student toilets'),
      (school(counts:{'playground':1}),'Playgrounds'),
      (school(configuration:'campus'),'campus circulation'),
      (school(type:'secondary_school'),'Primary School only'),
      (school(floors:2),'one floor'),
      (school(answers:{'classrooms':3}),'classroom count'),
      (school(answers:{'school_lobby_depth':.5}),'too short'),
      (school(answers:{'school_lobby_depth':1.3}),'administration door'),
      (school(answers:{'school_entry_walk':.7}),'entry walk'),
      (school(rooms:{'student_toilets':{'width':3,'length':2.8,'access':'public'}}),'Only administration'),
      (school(rooms:{'classroom':{'width':7.6,'length':6.8}}),'exterior window'),
    ]) {
      final result=run(input);
      expect(result.issue,contains(message),reason:message);
      expect(result.plan,isNull);
      expect(result.siteZones,isEmpty);
    }
  });

  testWidgets('valid school shows DXF action; unsupported scope saves the brief without DXF', (tester) async {
    Future<void> open(ProjectBrief brief) => tester.pumpWidget(MaterialApp(home:SchoolCadScreen(key:ObjectKey(brief),name:'School',
      brief:brief,widthFt:100,depthFt:110,facing:'South')));
    await open(school());
    expect(find.text('Save or share DXF'),findsOneWidget);
    await open(school(configuration:'campus'));
    expect(find.text('No plan generated'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
