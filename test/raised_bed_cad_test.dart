import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/raised_bed_cad_screen.dart';
import 'package:architect_engine/services/raised_bed_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief garden({Map<String,Object> edits=const {},String type='public_garden',String shape='rectangular'}) => ProjectBrief(
  floorCount:null,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'infrastructure',subcategoryId:'public_realm',
    typeId:type,configurationId:'public_open_space',plotShapeId:shape),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'garden_raised_beds','gb_pairs':4,'gb_width':1.4,'gb_length':2.6,'gb_wall':.1,'gb_height':.45,
    'gb_fill':.35,'gb_reach':.7,'gb_spine':1.8,'gb_cross':1.2,'gb_side':1.2,'gb_ends':1.5,'gb_west':2,'gb_south':3,
    ...edits,
  }));

void main() {
  final generator=RaisedBedCadGenerator();
  const widthFt=12/.3048,depthFt=22/.3048;
  RaisedBedCadResult run(ProjectBrief brief) => generator.generate(brief,widthFt:widthFt,depthFt:depthFt);

  test('mode is opt-in; saved dimensions yield exact layout and takeoff', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o)=>o.id),isNot(contains('garden_raised_beds')));
    expect(cadOutputOptions(warehouseLoading:false,raisedBeds:true).options.map((o)=>o.id),contains('garden_raised_beds'));
    final saved=ProjectBrief.fromMap(garden().toMap())!;
    expect(RaisedBedCadGenerator.requested(saved),isTrue);
    final r=run(saved);
    expect(r.issue,isNull);
    expect((r.beds.length,r.envelopeWidthMm,r.envelopeDepthMm),(8,7000,17000));
    expect(r.growingAreaM2,closeTo(23.04,1e-9));
    expect(r.mediumM3,closeTo(8.064,1e-9));
    expect(r.pathAreaM2,closeTo(89.88,1e-9));
    expect(r.beds.map((bed)=>bed.id),['W1','E1','W2','E2','W3','E3','W4','E4']);
    final first=r.beds.first,last=r.beds.last;
    expect((first.outer.left,first.outer.bottom,first.inner.width,first.inner.depth),(3200,4500,1200,2400));
    expect((last.outer.left,last.outer.bottom),(6400,15900));
    expect(r.beds[1].outer.left-first.outer.right,1800);
    expect(r.beds[2].outer.bottom-first.outer.top,1200);
    expect(r.drawing!.lines.where((l)=>l.layer=='GARDEN_GROWING').length,32);
    expect(r.drawing!.toDxf(),contains('23.040 M2 GROWING / 8.064 M3 NET MEDIUM'));
    final csv=r.toCsv()!.trimRight().split('\r\n');
    expect(csv.length,9);
    expect(csv.first,contains('inside_width_m,inside_length_m,fill_depth_m,growing_area_m2,medium_m3'));
    expect(csv[1],'W1,3.200,4.500,1.400,2.600,1.200,2.400,0.350,2.880000,1.008000000');
    expect(csv.last,startsWith('E4,6.400,15.900,'));
  });

  test('exact setback and fill boundaries fit; single pair has no cross-aisle', () {
    final r=run(garden(edits:{'left_setback':2,'right_setback':3,'front_setback':3,'rear_setback':2,'gb_fill':.45}));
    expect(r.issue,isNull);
    expect(r.mediumM3,closeTo(10.368,1e-9));
    final single=run(garden(edits:{'gb_pairs':1,'gb_cross':0}));
    expect(single.issue,isNull);
    expect((single.beds.length,single.envelopeDepthMm),(2,5600));
  });

  test('rejects incompatible brief or measured constraint and blocks both outputs', () {
    for(final (brief,message) in [
      (garden(type:'public_park'),'Select Public Garden'),
      (garden(shape:'square'),'Enter measured'),
      (garden(edits:{'gb_pairs':31}),'Enter measured'),
      (garden(edits:{'gb_wall':.7}),'no positive clear growing interior'),
      (garden(edits:{'gb_fill':.451}),'usable inside wall height'),
      (garden(edits:{'gb_reach':.699}),'supplied horizontal reach'),
      (garden(edits:{'gb_cross':0}),'positive cross-aisle'),
      (garden(edits:{'rear_setback':2.001}),'rear plot edge'),
    ]) {
      final r=run(brief);
      expect(r.issue,contains(message));
      expect(r.drawing,isNull);
      expect(r.toCsv(),isNull);
    }
  });

  testWidgets('preview shows net quantity and blocks both exports when reach fails',(tester) async {
    await tester.pumpWidget(MaterialApp(home:RaisedBedCadScreen(name:'Community beds',brief:garden(),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('Net growing medium 8.064 m³'),findsOneWidget);
    expect(find.text('Share raised-bed DXF'),findsOneWidget);
    expect(find.text('Share bed takeoff CSV'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:RaisedBedCadScreen(key:const ValueKey('failed'),name:'Community beds',
      brief:garden(edits:{'gb_reach':.6}),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('supplied horizontal reach'),findsOneWidget);
    expect(find.text('Share raised-bed DXF'),findsNothing);
    expect(find.text('Share bed takeoff CSV'),findsNothing);
  });
}
