import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/paired_apartment_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/paired_apartment_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief apartments({Map<String,Object> edits=const {},String type='rental_apartment',int floors=1,
  Map<String,int> spaces=const {}})=>ProjectBrief(floorCount:floors,parking:ProjectParking.none,features:const [],
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'residential',subcategoryId:'apartments',
    typeId:type,configurationId:'low_rise',plotShapeId:'rectangular',spaceQuantities:spaces),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'paired_apartments','unit_count':2,'units_per_floor':2,'apartment_mix':['1_bhk'],
    'cad_plate_width':15.4,'cad_plate_depth':9,'cad_wall':.2,'cad_door':1,'cad_offset_left':3,'cad_offset_front':4,
    'pa_lobby_width':2.2,'pa_lobby_depth':2.8,'pa_walk':1.6,'pa_living_depth':5.2,'pa_bath_width':2.1,
    'pa_kitchen_length':3.4,'pa_kitchen_depth':.65,'pa_kitchen_clear':1.2,'pa_living_window':2.4,'pa_bed_window':1.8,...edits,
  }));

void main() {
  PairedApartmentResult run(ProjectBrief brief,[String facing='South'])=>
    PairedApartmentGenerator().generate(brief,widthFt:85,depthFt:75,facing:facing);
  bool touches(PlanRect a,PlanRect b)=>((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top)||
    ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);

  test('two mirrored entries, rooms and kitchens persist on all frontages', () {
    final brief=ProjectBrief.fromMap(apartments().toMap())!;
    expect(PairedApartmentGenerator.requested(brief),isTrue);
    expect(cadOutputOptions(warehouseLoading:false,pairedApartments:true).options.map((o)=>o.id),contains('paired_apartments'));
    for (final facing in ['South','North','East','West']) {
      final result=run(brief,facing);
      expect(result.issue,isNull,reason:'$facing: ${result.issue}');
      final plan=result.plan!,rooms={for(final r in result.plan!.rooms)r.id:r.bounds};
      expect(validatePlanGeometry(plan),isNull);
      expect(rooms.length,8);
      final rotated=facing=='East'||facing=='West';
      expect(rotated?rooms['paired_lobby']!.depth:rooms['paired_lobby']!.width,2200);
      expect(rotated?rooms['flat_a_bed']!.depth:rooms['flat_a_bed']!.width,3900);
      expect(rotated?rooms['flat_a_bed']!.width:rooms['flat_a_bed']!.depth,3200);
      final doors=plan.openings.where((o)=>o.kind==PlanOpeningKind.door);
      expect(doors.where((o)=>o.from==AutomaticFloorPlan.entry).single.to,'paired_lobby');
      expect(doors.where((o)=>o.from=='paired_lobby').map((o)=>o.to),unorderedEquals(['paired_service','flat_a_living','flat_b_living']));
      expect(doors.where((o)=>o.from=='paired_service'),isEmpty);
      for(final (first,last) in [('flat_a','flat_b'),('flat_b','flat_a')]) {
        final internal=doors.where((o)=>o.from.startsWith(first));
        expect(internal.map((o)=>o.to),unorderedEquals(['${first}_bed','${first}_bath']));
        final wing=['living','bed','bath'];
        for(final role in wing) {
          final a=rooms['${first}_$role']!, b=rooms['${last}_$role']!;
          expect((a.width,a.depth),(b.width,b.depth));
          expect(rotated?a.bottom+b.top:a.left+b.right,rotated?plan.footprint.bottom+plan.footprint.top:plan.footprint.left+plan.footprint.right);
        }
        final window=plan.openings.singleWhere((o)=>o.kind==PlanOpeningKind.window&&o.to=='${first}_living');
        final rear=plan.openings.singleWhere((o)=>o.kind==PlanOpeningKind.window&&o.to=='${first}_bed');
        expect(rotated?window.bounds.depth:window.bounds.width,2400);
        expect(rotated?rear.bounds.depth:rear.bounds.width,1800);
        final kitchen=result.zones.singleWhere((z)=>z.id=='${first}_counter').bounds;
        final working=result.zones.singleWhere((z)=>z.id=='${first}_work').bounds;
        expect(kitchen.area,650*3400);
        expect(working.area,1200*3400);
        expect(rooms['${first}_living']!.contains(kitchen)&&rooms['${first}_living']!.contains(working),isTrue);
        expect(touches(kitchen,working)&&!touches(kitchen,window.bounds),isTrue);
      }
      final approach=result.zones.singleWhere((z)=>z.id=='pa_walk').bounds;
      expect(touches(approach,doors.first.bounds) && plan.plot.contains(approach),isTrue);
      final dxf=FloorPlanCad.fromPlan(plan,siteZones:result.zones).toDxf();
      for(final layer in ['WINDOWS','PAIRED_SHARED','PAIRED_COUNTER','PAIRED_CLEAR']) {expect(dxf,contains(layer));}
    }
  });

  test('unit scope, clearance and site conflicts block the whole sheet', () {
    for(final (brief,issue) in [
      (apartments(type:'accessible_apartment'),'supported low-rise apartment'),
      (apartments(floors:2),'requires one ground-floor'),
      (apartments(edits:{'unit_count':3}),'exactly two identical'),
      (apartments(edits:{'apartment_mix':['1_bhk','2_bhk']}),'exactly two identical'),
      (apartments(edits:{'unit_layout':['balcony']}),'alternate kitchen, balcony'),
      (apartments(spaces:{'lift':1}),'Leave separate Space selections empty'),
      (apartments(edits:{'pa_lobby_width':.8}),'span the entrances'),
      (apartments(edits:{'pa_bath_width':.9}),'bedroom and bathroom'),
      (apartments(edits:{'pa_kitchen_length':6}),'Kitchen counter'),
      (apartments(edits:{'pa_bed_window':4}),'windows need wall returns'),
      (apartments(edits:{'rear_setback':15}),'rear setback'),
    ]) {
      final result=run(brief);
      expect(result.issue?.toLowerCase(),contains(issue.toLowerCase()),reason:issue);
      expect(result.plan,isNull);
      expect(result.zones,isEmpty);
    }
  });

  testWidgets('paired apartment preview enables DXF only for a fitted brief', (tester) async {
    await tester.pumpWidget(MaterialApp(home:PairedApartmentScreen(name:'Rental pair',brief:apartments(),widthFt:85,depthFt:75,facing:'West')));
    expect(find.text('Paired apartment CAD'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:PairedApartmentScreen(key:const ValueKey('blocked'),name:'Rental pair',
      brief:apartments(edits:{'pa_kitchen_length':6}),widthFt:85,depthFt:75,facing:'West')));
    expect(find.textContaining('kitchen counter'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
