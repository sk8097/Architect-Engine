import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/office_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/office_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief office({Map<String,Object> answers = const {}, Map<String,Map<String,Object>> rooms = const {},
  Map<String,int> counts = const {}, String type = 'small_office', String configuration = 'open_workspace', int floors = 1}) =>
  ProjectBrief(floorCount:floors,parking:ProjectParking.none,features:const [],
    taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'commercial',subcategoryId:'office',
      typeId:type,configurationId:configuration,plotShapeId:'rectangular',
      spaceQuantities:{'reception':1,'meeting_room':1,'open_workstation':1,'pantry':1,...counts}),
    requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
      'cad_output':'office_workplace','workstations':7,'cad_plate_width':14,'cad_plate_depth':15,
      'cad_offset_left':3,'cad_offset_front':4,'cad_wall':.2,'cad_door':.9,'cad_corridor':1.8,
      'office_visitor_depth':3.2,'office_desk_span':1.4,'office_desk_depth':.75,
      'office_chair_depth':.95,'office_aisle':1.3,'office_desk_gap':.2,...answers,
    },spaceDetails:{
      'reception':{'width':4,'length':2.4},'meeting_room':{'width':4,'length':3},
      'open_workstation':{'width':5.7,'length':8,'cad_window':1.6},'pantry':{'width':3,'length':2},...rooms,
    }));

void main() {
  OfficeCadResult run(ProjectBrief brief,[String facing='South']) =>
    OfficeCadGenerator().generate(brief,widthFt:90,depthFt:100,facing:facing);
  const visitor = 'office_visitor_route', staff = 'office_staff_route';
  bool sharesEdge(PlanRect a, PlanRect b) =>
    ((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top) ||
    ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);

  test('saved office brief generates connected visitor/staff and fitted desk geometry on four frontages', () {
    final brief=ProjectBrief.fromMap(office().toMap())!;
    expect(OfficeCadGenerator.requested(brief),isTrue);
    for (final facing in ['South','North','East','West']) {
      final result=run(brief,facing);
      expect(result.issue,isNull,reason:'$facing: ${result.issue}');
      final plan=result.plan!, rooms={for(final r in result.plan!.rooms) r.id:r};
      expect(validatePlanGeometry(plan,sealedRooms:rooms.keys.where((id)=>id.startsWith('reserve_')).toSet()),isNull);
      final doors=plan.openings.where((o)=>o.kind==PlanOpeningKind.door).toList();
      expect(doors.singleWhere((o)=>o.from==AutomaticFloorPlan.entry).to,visitor);
      expect(doors.where((o)=>o.from==visitor && o.to!=staff).map((o)=>rooms[o.to]!.label),
        unorderedEquals(['Reception','Meeting Room']));
      expect(doors.where((o)=>o.from==staff).map((o)=>rooms[o.to]!.label),unorderedEquals(['Open Workstation','Pantry']));
      final door=doors.singleWhere((o)=>o.from==staff && rooms[o.to]!.label=='Open Workstation');
      final workspace=rooms[door.to]!.bounds;
      final cross=result.fixtures.singleWhere((z)=>z.id=='office_cross').bounds;
      final mains=result.fixtures.where((z)=>z.id.endsWith('_aisle')).map((z)=>z.bounds).toList();
      final rotated=facing=='East'||facing=='West';
      expect(rotated?cross.width:cross.depth,1300);
      expect(sharesEdge(cross,door.bounds),isTrue);
      expect(rotated ? cross.left<=door.bounds.left && cross.right>=door.bounds.right
        : cross.bottom<=door.bounds.bottom && cross.top>=door.bounds.top,isTrue);
      expect(mains.length,2);
      expect(mains.every((b)=>sharesEdge(b,cross) && (rotated?b.depth:b.width)==1300),isTrue);
      for (final zone in result.fixtures) {
        expect(workspace.contains(zone.bounds),isTrue);
        expect(result.fixtures.where((other)=>other!=zone && zone.bounds.overlaps(other.bounds)),isEmpty);
      }
      final desks=result.fixtures.where((z)=>z.layer=='OFFICE_DESKS').toList();
      final chairs=result.fixtures.where((z)=>z.layer=='OFFICE_CHAIR_CLEAR').toList();
      expect(desks.length,7);
      expect(chairs.length,7);
      for (var i=0;i<desks.length;i++) {
        final d=desks[i].bounds, c=chairs[i].bounds;
        expect(d.area,750*1400);
        expect(c.area,950*1400);
        expect(sharesEdge(d,c),isTrue);
        expect(mains.any((b)=>sharesEdge(b,c)),isTrue);
      }
      final drawing=FloorPlanCad.fromPlan(plan,siteZones:result.fixtures);
      expect(drawing.arcs.singleWhere((a)=>a.layer=='OFFICE_THRESHOLD').radius,900);
      final dxf=drawing.toDxf();
      for (final layer in ['OFFICE_VISITOR_ROUTE','OFFICE_STAFF_ROUTE','OFFICE_THRESHOLD','OFFICE_DESKS','OFFICE_CHAIR_CLEAR','OFFICE_AISLES']) {
        expect(drawing.lines.where((l)=>l.layer==layer),isNotEmpty);
        expect(dxf,contains(layer));
      }
    }
  });

  test('seat count and fixture measurements change actual furniture linework', () {
    final smaller=run(office(answers:{'workstations':3,'office_desk_depth':.85}));
    expect(smaller.issue,isNull);
    final desks=smaller.fixtures.where((z)=>z.layer=='OFFICE_DESKS').toList();
    expect(desks.length,3);
    expect(desks.every((d)=>d.bounds.width==850),isTrue);
    final full=run(office(answers:{'workstations':8}));
    expect(full.issue,isNull);
    expect(full.fixtures.where((z)=>z.layer=='OFFICE_DESKS').length,8);
  });

  test('out-of-scope requests and unsupported geometry produce no drawing', () {
    for (final (brief,message) in [
      (office(type:'multi_tenant_office'),'Choose a Small'),
      (office(answers:{'tenants':2}),'one tenant'),
      (office(configuration:'hybrid_workspace'),'fixed-desk'),
      (office(floors:2),'one floor'),
      (office(counts:{'open_workstation':2}),'one Open Workstation'),
      (office(answers:{'workstations':0}),'whole-number'),
      (office(answers:{'workstations':9}),'do not fit the measured workspace'),
      (office(answers:{'office_chair_depth':2}),'do not fit the measured workspace'),
      (office(answers:{'office_aisle':.8}),'door swing'),
      (office(answers:{'office_visitor_depth':1.1}),'doors must open before'),
      (office(rooms:{'pantry':{'width':3,'length':2,'access':'public'}}),'conflicts with the visitor/staff split'),
    ]) {
      final result=run(brief);
      expect(result.issue,contains(message),reason:message);
      expect(result.plan,isNull);
      expect(result.fixtures,isEmpty);
    }
  });

  testWidgets('office preview exposes the editable DXF action', (tester) async {
    await tester.pumpWidget(MaterialApp(home:OfficeCadScreen(name:'Measured office',brief:office(),
      widthFt:90,depthFt:100,facing:'South')));
    expect(find.text('Office workplace CAD'),findsOneWidget);
    await tester.scrollUntilVisible(find.text('Share DXF'),300);
    expect(find.text('Share DXF'),findsOneWidget);
  });
}
