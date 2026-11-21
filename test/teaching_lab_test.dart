import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/teaching_lab_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/teaching_lab_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief lab({Map<String,Object> edits = const {}, String type = 'secondary_school', int floors = 1,
    Map<String,int> spaces = const {}}) => ProjectBrief(floorCount:floors, parking:ProjectParking.none, features:const [],
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'institutional',subcategoryId:'education',typeId:type,
    configurationId:'single_building',plotShapeId:'rectangular',spaceQuantities:spaces),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'school_teaching_lab','cad_plate_width':12,'cad_plate_depth':16,'cad_wall':.2,'cad_door':1.2,
    'cad_offset_left':3,'cad_offset_front':4,'sl_rows':3,'sl_places':4,'sl_place_span':.78,'sl_bench_width':3.4,
    'sl_bench_depth':.8,'sl_use':.75,'sl_cross':1,'sl_centre':2,'sl_side':1.2,'sl_front':3,'sl_rear':1.2,
    'sl_teacher_width':2.2,'sl_teacher_depth':.7,'sl_teacher_work':1,'sl_prep':3.1,'sl_prep_width':3,'sl_prep_depth':.65,
    'sl_prep_work':.9,...edits,
  }));

void main() {
  TeachingLabResult run(ProjectBrief brief,[String facing='South']) => TeachingLabGenerator().generate(brief,
    widthFt:25/.3048,depthFt:29/.3048,facing:facing);
  bool touches(PlanRect a,PlanRect b) => ((a.left==b.right||a.right==b.left)&&a.bottom<b.top&&b.bottom<a.top) ||
      ((a.bottom==b.top||a.top==b.bottom)&&a.left<b.right&&b.left<a.right);

  test('measured lab has two connected bench banks, an enclosed prep room and clear routes', () {
    final saved = ProjectBrief.fromMap(lab(type:'senior_secondary_school').toMap())!;
    expect(TeachingLabGenerator.requested(saved),isTrue);
    expect(cadOutputOptions(warehouseLoading:false,teachingLab:true).options.map((item)=>item.id),contains('school_teaching_lab'));
    for(final facing in ['South','North','East','West']) {
      final result=run(saved,facing);
      expect(result.issue,isNull,reason:facing);
      expect(result.places,24);
      final plan=result.plan!, zones={for(final z in result.zones) z.id:z.bounds};
      expect(validatePlanGeometry(plan),isNull);
      expect(plan.rooms.length,2);
      expect(plan.openings.map((door)=>(door.from,door.to)),[
        (AutomaticFloorPlan.entry,'school_lab'),('school_lab','school_lab_prep'),
      ]);
      final rotated=facing=='East'||facing=='West';
      final ais=zones['sl_centre']!, sideA=zones['sl_side_a']!, sideB=zones['sl_side_b']!;
      expect(rotated?ais.depth:ais.width,2000);
      for(final side in [sideA,sideB]) { expect(rotated?side.depth:side.width,1400); }
      expect(touches(zones['sl_approach']!,plan.openings.first.bounds),isTrue);
      expect(touches(zones['sl_entry']!,plan.openings.first.bounds),isTrue);
      expect(touches(zones['sl_rear']!,plan.openings.last.bounds),isTrue);
      expect(touches(zones['sl_prep_path']!,plan.openings.last.bounds),isTrue);
      final allBenches = result.zones.where((z)=>z.layer=='TEACH_LAB_BENCH').toList();
      expect(allBenches.length,6);
      for(final (i,bench) in allBenches.indexed) {
        final b=bench.bounds, prefix=bench.id.replaceFirst('_bench','');
        final use=zones['${prefix}_use']!,cross=zones['${prefix}_cross']!;
        expect((rotated?b.depth:b.width,rotated?b.width:b.depth),(3400,800));
        expect(rotated?use.width:use.depth,750);
        expect(rotated?cross.width:cross.depth,1000);
        expect(touches(cross,ais)&&touches(cross,i.isEven?sideA:sideB)&&touches(use,b),isTrue);
        expect(!b.overlaps(ais)&&!b.overlaps(sideA)&&!b.overlaps(sideB)&&plan.rooms.first.bounds.contains(b),isTrue);
      }
      expect(plan.rooms.last.bounds.contains(zones['sl_prep_counter']!),isTrue);
      expect(touches(zones['sl_prep_work']!,zones['sl_prep_path']!)&&!zones['sl_prep_counter']!.overlaps(zones['sl_prep_path']!),isTrue);
      final dxf=FloorPlanCad.fromPlan(plan,siteZones:result.zones).toDxf();
      for(final layer in ['TEACH_LAB_ROUTE','TEACH_LAB_BENCH','TEACH_LAB_COUNTER','TEACH_LAB_CLEAR']) {expect(dxf,contains(layer));}
    }
  });

  test('incompatible scope, insufficient fixtures or aisle dimensions block the sheet', () {
    for(final (brief, issue) in [
      (lab(type:'primary_school'),'Select Secondary School'),
      (lab(spaces:{'laboratory':1}),'Leave separate Spaces'),
      (lab(floors:2),'single ground-floor'),
      (lab(edits:{'sl_places':5}),'bench frontage'),
      (lab(edits:{'sl_side':1.5}),'do not fit the clear width'),
      (lab(edits:{'sl_centre':1.1}),'span both door openings'),
      (lab(edits:{'sl_teacher_depth':1.5}),'teacher counter'),
      (lab(edits:{'sl_prep_work':2}),'prep door swing'),
      (lab(edits:{'sl_cross':1.5}),'rear cross aisle'),
      (lab(edits:{'front_setback':4.1}),'front setback'),
    ]) {
      final result=run(brief);
      expect(result.issue,contains(issue));
      expect(result.plan,isNull);
      expect(result.zones,isEmpty);
    }
  });

  testWidgets('preview reports dimensional capacity and blocks invalid exports', (tester) async {
    await tester.pumpWidget(MaterialApp(home:TeachingLabScreen(name:'General teaching lab',brief:lab(),widthFt:83,depthFt:96,facing:'West')));
    expect(find.text('Teaching lab CAD'),findsOneWidget);
    expect(find.textContaining('24 student places'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:TeachingLabScreen(key:const ValueKey('blocked'),name:'General teaching lab',
      brief:lab(edits:{'sl_places':5}),widthFt:83,depthFt:96,facing:'West')));
    expect(find.textContaining('measured bench frontage'),findsOneWidget);
    expect(find.text('Save or share DXF'),findsNothing);
  });
}
