import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/windrow_yard_cad_screen.dart';
import 'package:architect_engine/services/windrow_yard_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief yard({Map<String,Object> edits=const {},String type='composting_facility'}) => ProjectBrief(
  floorCount:null,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'infrastructure',subcategoryId:'public_realm',
    typeId:type,configurationId:'support_facility',plotShapeId:'rectangular'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'windrow_measured_yard','wy_rows':4,'wy_base_w':4,'wy_base_l':30,'wy_top_w':2,'wy_top_l':24,
    'wy_height':2,'wy_aisle':3,'wy_side':2,'wy_south_head':5,'wy_north_head':6,'wy_west':3,'wy_south':4,
    'wy_target':656,...edits,
  }));

void main() {
  const widthFt=40/.3048,depthFt=55/.3048;
  WindrowYardCadResult run(ProjectBrief b)=>WindrowYardCadGenerator().generate(b,widthFt:widthFt,depthFt:depthFt);

  test('mode is opt-in; geometry and both tapered ends determine the exact volume', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o)=>o.id),isNot(contains('windrow_measured_yard')));
    expect(cadOutputOptions(warehouseLoading:false,windrowYard:true).options.map((o)=>o.id),contains('windrow_measured_yard'));
    final saved=ProjectBrief.fromMap(yard().toMap())!;
    expect(WindrowYardCadGenerator.requested(saved),isTrue);
    final r=run(saved);
    expect(r.issue,isNull);
    expect((r.rows,r.widthMm,r.depthMm,r.eachM3,r.totalM3,r.clearM2),(4,29000,41000,164,656,709));
    // Independent integrated polynomial: (4 - z)(30 - 3z) over z=0..2.
    expect(r.eachM3,120*2-42*2+8);
    final c=r.plan!;
    final toes=c.lines.where((l)=>l.layer=='WINDROW_TOE').toList();
    final tops=c.lines.where((l)=>l.layer=='WINDROW_TOP').toList();
    expect((toes.length,tops.length),(16,16));
    expect((toes.first.start.x,toes.first.start.y,toes.first.end.x),(5000,9000,9000));
    expect(toes[4].start.x-toes.first.end.x,3000);
    expect((tops.first.start.x,tops.first.start.y,tops.first.end.x),(6000,12000,8000));
    final hip=c.lines.firstWhere((l)=>l.layer=='WINDROW_HIPS');
    expect((hip.start.x,hip.start.y,hip.end.x,hip.end.y),(5000,9000,6000,12000));
    expect(c.toDxf(),contains('656.000 M3 GEOMETRIC'));
  });

  test('true-scale transverse section preserves pile side and aisle dimensions', () {
    final r=run(yard(edits:{'left_setback':3,'right_setback':8,'front_setback':4,'rear_setback':10}));
    expect(r.issue,isNull);
    final s=r.section!;
    final faces=s.lines.where((l)=>l.layer=='WINDROW_FACE').toList();
    expect(faces.length,8);
    expect((faces.first.start.x,faces.first.start.y,faces.first.end.x,faces.first.end.y),(2000,0,3000,2000));
    expect(faces[2].start.x-faces[1].end.x,3000);
    expect(s.toDxf(),contains('164.000 M3 PER PILE'));
    final one=run(yard(edits:{'wy_rows':1,'wy_aisle':0,'wy_target':0}));
    expect((one.issue,one.widthMm,one.totalM3),(null,8000,164));
  });

  test('failed pile geometry, clearances and volume target block both DXFs', () {
    for(final (brief,message) in [
      (yard(type:'public_garden'),'Select Composting Facility'),
      (yard(edits:{'wy_rows':31}),'Enter measured'),
      (yard(edits:{'wy_top_w':4}),'narrower and shorter'),
      (yard(edits:{'wy_top_l':31}),'narrower and shorter'),
      (yard(edits:{'wy_aisle':0}),'positive clear aisle'),
      (yard(edits:{'rear_setback':10.001}),'rear plot edge'),
      (yard(edits:{'wy_target':656.001}),'below the supplied 656.001'),
    ]) {
      final r=run(brief);
      expect(r.issue,contains(message));
      expect(r.plan,isNull);
      expect(r.section,isNull);
    }
  });

  testWidgets('preview switches sheets and hides exports on a failed target',(tester) async {
    await tester.pumpWidget(MaterialApp(home:WindrowYardCadScreen(name:'Yard',brief:yard(),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('656.000 m³ total'),findsOneWidget);
    expect(find.text('Share windrow plan DXF'),findsOneWidget);
    await tester.tap(find.text('Transverse section'));
    await tester.pumpAndSettle();
    expect(find.text('Share windrow section DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:WindrowYardCadScreen(key:const ValueKey('failed'),name:'Yard',
      brief:yard(edits:{'wy_target':657}),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('below the supplied'),findsOneWidget);
    expect(find.text('Share windrow plan DXF'),findsNothing);
    expect(find.text('Share windrow section DXF'),findsNothing);
  });
}
