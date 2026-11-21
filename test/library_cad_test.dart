import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/library_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/library_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief library({Map<String,Object> edits=const {},Map<String,int> counts=const {},Map<String,Map<String,Object>> rooms=const {},
    String type='library',String group='education',String configuration='single_building',int floors=1})=>ProjectBrief(
  floorCount:floors,parking:ProjectParking.none,features:const [],taxonomy:TaxonomySelection(version:projectTaxonomyVersion,
    categoryId:'institutional',subcategoryId:group,typeId:type,configurationId:configuration,plotShapeId:'rectangular',
    spaceQuantities:{'lib_checkout':1,'lib_stacks':1,'lib_reading':1,...counts}),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'library_reading','cad_plate_width':16,'cad_plate_depth':19,'cad_wall':.2,'cad_corridor':1.8,'cad_door':.9,
    'cad_offset_left':3,'cad_offset_front':4,'lib_front_depth':5.4,
    'lib_ranges':3,'lib_shelf_width':.65,'lib_shelf_length':3.1,'lib_stack_aisle':1.1,
    'lib_read_count':5,'lib_read_span':1.2,'lib_read_depth':.7,'lib_chair_depth':.9,'lib_read_aisle':1.25,...edits,
  },spaceDetails:{
    'lib_checkout':{'width':3.4,'length':2.4},'lib_stacks':{'width':6.7,'length':8},
    'lib_reading':{'width':6.7,'length':7,'cad_window':1.8},...rooms,
  }));

void main() {
  LibraryCadResult run(ProjectBrief brief,[String facing='South'])=>
    LibraryCadGenerator().generate(brief,widthFt:100,depthFt:120,facing:facing);
  const public='library_public_route',quiet='library_quiet_route';
  bool touches(PlanRect a,PlanRect b)=>
    ((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top)||
    ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);

  test('saved brief produces a public stack network, quiet threshold and measured desk row on four frontages', () {
    final input=ProjectBrief.fromMap(library().toMap())!;
    expect(LibraryCadGenerator.requested(input),isTrue);
    for(final facing in ['South','North','East','West']) {
      final result=run(input,facing);
      expect(result.issue,isNull,reason:'$facing: ${result.issue}');
      final plan=result.plan!, rooms={for(final r in result.plan!.rooms)r.id:r};
      expect(validatePlanGeometry(plan,sealedRooms:rooms.keys.where((id)=>id.startsWith('reserve_')).toSet()),isNull);
      final doors=plan.openings.where((o)=>o.kind==PlanOpeningKind.door);
      expect(doors.singleWhere((o)=>o.from==AutomaticFloorPlan.entry).to,public);
      expect(doors.where((o)=>o.from==public&&o.to!=quiet).map((o)=>rooms[o.to]!.label),
        unorderedEquals(['Library checkout / return','Open book stacks']));
      expect(doors.singleWhere((o)=>o.from==quiet).to,rooms.values.singleWhere((r)=>r.label=='Quiet reading room').id);
      final shelves=result.fixtures.where((f)=>f.layer=='LIBRARY_SHELVES').toList();
      final aisle=result.fixtures.singleWhere((f)=>f.id=='lib_stack_cross');
      final shelfAisles=result.fixtures.where((f)=>f.layer=='LIBRARY_STACK_AISLES'&&f.id!=aisle.id);
      final stackDoor=doors.singleWhere((o)=>rooms[o.to]!.label=='Open book stacks');
      expect(touches(aisle.bounds,stackDoor.bounds),isTrue);
      expect(shelves.length,6);
      expect(shelfAisles.length,8);
      expect(shelfAisles.every((f)=>touches(f.bounds,aisle.bounds)),isTrue);
      final rotated=facing=='East'||facing=='West';
      for(final shelf in shelves) {
        expect(rotated?shelf.bounds.depth:shelf.bounds.width,650);
        expect(rotated?shelf.bounds.width:shelf.bounds.depth,3100);
        expect(shelfAisles.where((a)=>touches(a.bounds,shelf.bounds)).length,2);
      }
      final studyAisle=result.fixtures.singleWhere((f)=>f.id=='lib_read_walk').bounds;
      expect(touches(studyAisle,doors.singleWhere((o)=>o.from==quiet).bounds),isTrue);
      expect(rotated?studyAisle.depth:studyAisle.width,1250);
      final desks=result.fixtures.where((f)=>f.layer=='LIBRARY_DESKS').toList();
      final chairs=result.fixtures.where((f)=>f.layer=='LIBRARY_CHAIR_CLEAR').toList();
      expect(desks.length,5);
      expect(chairs.length,5);
      for(var i=0;i<desks.length;i++) {
        expect(desks[i].bounds.area,1200*700);
        expect(chairs[i].bounds.area,1200*900);
        expect(touches(desks[i].bounds,chairs[i].bounds)&&touches(chairs[i].bounds,studyAisle),isTrue);
      }
      for(final zone in result.fixtures) {
        final host=rooms[zone.id.startsWith('lib_read')?doors.singleWhere((o)=>o.from==quiet).to:stackDoor.to]!.bounds;
        expect(host.contains(zone.bounds),isTrue);
        expect(result.fixtures.where((f)=>f!=zone&&zone.bounds.overlaps(f.bounds)),isEmpty);
      }
      final drawing=FloorPlanCad.fromPlan(plan,siteZones:result.fixtures);
      expect(drawing.arcs.singleWhere((a)=>a.layer=='LIBRARY_QUIET_THRESHOLD').radius,900);
      final dxf=drawing.toDxf();
      for(final layer in ['LIBRARY_PUBLIC','LIBRARY_QUIET','LIBRARY_QUIET_THRESHOLD','LIBRARY_SHELVES','LIBRARY_DESKS',
        'LIBRARY_CHAIR_CLEAR','LIBRARY_STACK_AISLES','LIBRARY_STUDY_AISLE']) {
        expect(drawing.lines.where((l)=>l.layer==layer),isNotEmpty);
        expect(dxf,contains(layer));
      }
    }
  });

  test('public library supports a measured back-office room accessible from the public-side passage', () {
    final result=run(library(type:'public_library',group:'culture',configuration:'main_hall',
      counts:{'lib_processing':1},rooms:{'lib_processing':{'width':3,'length':2,'access':'staff'}},
      edits:{'lib_ranges':2,'lib_read_count':6,'lib_read_span':1}));
    expect(result.issue,isNull);
    final id=result.plan!.rooms.singleWhere((r)=>r.label=='Staff book processing').id;
    expect(result.plan!.openings.singleWhere((o)=>o.to==id).from,public);
    expect(result.fixtures.where((f)=>f.layer=='LIBRARY_SHELVES').length,4);
    expect(result.fixtures.where((f)=>f.layer=='LIBRARY_DESKS').length,6);
  });

  test('unsupported program or misfit keeps the brief and blocks fixtures and DXF', () {
    for(final (input,issue) in [
      (library(type:'primary_school'),'Education Library or a Public Library'),
      (library(configuration:'campus'),'single library building'),
      (library(floors:2),'one floor'),
      (library(counts:{'lib_stacks':0}),'Include one'),
      (library(edits:{'lib_front_depth':2}),'before the threshold'),
      (library(edits:{'lib_stack_aisle':.8}),'span the supplied door'),
      (library(edits:{'lib_shelf_length':4}),'do not fit on both sides'),
      (library(edits:{'lib_ranges':4}),'do not fit on both sides'),
      (library(edits:{'lib_read_count':6}),'chair clearances and aisle do not fit'),
      (library(counts:{'lib_processing':1},rooms:{'lib_processing':{'width':3,'length':2,'access':'public'}}),'staff-only'),
    ]) {
      final result=run(input);
      expect(result.issue,contains(issue),reason:issue);
      expect(result.plan,isNull);
      expect(result.fixtures,isEmpty);
    }
  });

  testWidgets('library preview enables export only when the measured furniture fits', (tester) async {
    await tester.pumpWidget(MaterialApp(home:LibraryCadScreen(name:'Branch library',brief:library(),
      widthFt:100,depthFt:120,facing:'West')));
    expect(find.text('Library reading CAD'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:LibraryCadScreen(key:const ValueKey('blocked'),name:'Branch library',
      brief:library(edits:{'lib_read_count':6}),widthFt:100,depthFt:120,facing:'West')));
    expect(find.textContaining('chair clearances and aisle do not fit'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
