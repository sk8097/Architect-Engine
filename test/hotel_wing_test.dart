import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/hotel_wing_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/hotel_wing_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief hotel({Map<String,Object> edits=const {},String type='hotel',int floors=1,Map<String,int> spaces=const {}}) =>
    ProjectBrief(floorCount:floors,parking:ProjectParking.none,features:const [],taxonomy:TaxonomySelection(
      version:projectTaxonomyVersion,categoryId:'commercial',subcategoryId:'lodging',typeId:type,configurationId:'midscale',
      plotShapeId:'rectangular',spaceQuantities:spaces),requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
        'cad_output':'hotel_guestroom_wing','room_keys':6,'guest_room_mix':['double'],'cad_plate_width':16.4,
        'cad_offset_left':4,'cad_offset_front':5,'cad_wall':.2,'cad_door':1,'hw_module':4.4,'hw_corridor':2,'hw_vest_depth':2,
        'hw_service_width':2.4,'hw_bed_width':1.8,'hw_bed_depth':2.1,'hw_bed_side':.7,'hw_bed_foot':.9,'hw_window':2,...edits,
      }));

void main() {
  HotelWingResult run(ProjectBrief brief,[String facing='South']) => HotelWingGenerator().generate(brief,
    widthFt:28/.3048, depthFt:28/.3048, facing:facing);

  test('mirrored keys connect only via the corridor and draw all reserves on four frontages', () {
    final saved=ProjectBrief.fromMap(hotel().toMap())!;
    expect(HotelWingGenerator.requested(saved),isTrue);
    expect(cadOutputOptions(warehouseLoading:false,hotelWing:true).options.map((o)=>o.id),contains('hotel_guestroom_wing'));
    for(final facing in ['South','North','East','West']) {
      final result=run(saved,facing);
      expect(result.issue,isNull,reason:facing);
      expect(result.keys,6);
      final plan=result.plan!, rooms={for(final r in result.plan!.rooms)r.id:r.bounds};
      expect(validatePlanGeometry(plan),isNull);
      expect(rooms.length,19);
      final rot=facing=='East'||facing=='West';
      expect((rot?plan.footprint.depth:plan.footprint.width,rot?plan.footprint.width:plan.footprint.depth),(16400,14000));
      final hall=rooms['hotel_corridor']!;
      expect(rot?hall.depth:hall.width,2000);
      final doors=plan.openings.where((o)=>o.kind==PlanOpeningKind.door);
      expect(doors.where((o)=>o.from==AutomaticFloorPlan.entry).single.to,'hotel_corridor');
      expect(doors.where((o)=>o.from=='hotel_corridor').length,6);
      for(var i=1;i<=6;i++) {
        final id='key_$i', vestibule='${id}_entry',sleep='${id}_sleep',bath='${id}_bath';
        expect(doors.singleWhere((o)=>o.to==vestibule).from,'hotel_corridor');
        expect(doors.where((o)=>o.from==vestibule).map((o)=>o.to),unorderedEquals([sleep,bath]));
        final reserve=rooms[bath]!;
        expect((rot?reserve.depth:reserve.width,rot?reserve.width:reserve.depth),(2400,2200));
        final window=plan.openings.singleWhere((o)=>o.kind==PlanOpeningKind.window && o.to==sleep);
        expect(rot?window.bounds.width:window.bounds.depth,2000);
        expect(rot?window.bounds.bottom==plan.footprint.bottom||window.bounds.top==plan.footprint.top:
          window.bounds.left==plan.footprint.left||window.bounds.right==plan.footprint.right,isTrue);
        final bed=result.zones.singleWhere((z)=>z.id=='${id}_bed').bounds;
        final clear=result.zones.where((z)=>z.id.startsWith(id)&&z.layer=='HOTEL_WING_CLEAR');
        expect(bed.area,1800*2100);
        expect(clear.length,3);
        expect(clear.every((z)=>rooms[sleep]!.contains(z.bounds)&&!bed.overlaps(z.bounds)),isTrue);
      }
      final dxf=FloorPlanCad.fromPlan(plan,siteZones:result.zones).toDxf();
      for(final layer in ['WINDOWS','DOORS','HOTEL_WING_ROUTE','HOTEL_WING_BED','HOTEL_WING_CLEAR']) {expect(dxf,contains(layer));}
    }
  });

  test('nonuniform room mixes, blocked door/bed clearance and site conflicts suppress export', () {
    for(final (brief, issue) in [
      (hotel(type:'resort'),'Select a supported Hotel'),
      (hotel(floors:2),'one ground-floor'),
      (hotel(spaces:{'restaurant':1}),'Leave separate Space'),
      (hotel(edits:{'room_keys':5}),'2–20 even keys'),
      (hotel(edits:{'guest_room_mix':['king','accessible']}),'one identical'),
      (hotel(edits:{'hw_vest_depth':.9}),'supplied doors'),
      (hotel(edits:{'hw_bed_side':1.3}),'side and foot clearances'),
      (hotel(edits:{'hw_bed_width':2.4,'hw_bed_foot':1.5}),'bed foot clearance'),
      (hotel(edits:{'hw_window':4.4}),'solid wall returns'),
      (hotel(edits:{'room_keys':12}),'rear setback'),
    ]) {
      final result=run(brief);
      expect(result.issue,contains(issue));
      expect(result.plan,isNull);
      expect(result.zones,isEmpty);
    }
  });

  testWidgets('guestroom wing screen previews the key count and blocks invalid exports',(tester) async {
    await tester.pumpWidget(MaterialApp(home:HotelWingScreen(name:'Guest wing',brief:hotel(),widthFt:92,depthFt:92,facing:'North')));
    expect(find.text('Hotel guestroom wing CAD'),findsOneWidget);
    expect(find.textContaining('6 keys in mirrored banks'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:HotelWingScreen(key:const ValueKey('blocked'),name:'Guest wing',
      brief:hotel(edits:{'room_keys':5}),widthFt:92,depthFt:92,facing:'North')));
    expect(find.textContaining('2–20 even keys'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
