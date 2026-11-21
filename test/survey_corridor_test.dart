import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/survey_corridor_screen.dart';
import 'package:architect_engine/services/concept_zoning_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/survey_corridor_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief brief({String type='road',String configuration='linear_corridor',Map<String,Object> edits=const {},Map<String,int> spaces=const {}}) =>
  ProjectBrief(floorCount:null,parking:null,features:const [],taxonomy:TaxonomySelection(version:projectTaxonomyVersion,
    categoryId:'infrastructure',subcategoryId:'transport',typeId:type,configurationId:configuration,spaceQuantities:spaces),
    requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
      'corridor_cad_mode':'survey_polyline','corridor_grid':'Projected example grid','alignment_reference':'Survey A1',
      'corridor_start_station':980.25,'route_length':100,'right_of_way':12,
      'corridor_points':'345000.250,2110000.500\n345060.250,2110000.500;345060.250,2110040.500',
      'corridor_bands':'Footway:2;Traveled way:7',...edits,
    }));

void main() {
  final generator=SurveyCorridorGenerator();
  test('measured bend retains grid coordinates, mitred offsets and cumulative chainage', () {
    for(final type in ['road','street','footpath','cycle_track']) {
      final saved=ProjectBrief.fromMap(brief(type:type).toMap())!;
      final result=generator.generate(saved);
      expect(result.issue,isNull,reason:type);
      final drawing=result.drawing!;
      expect(drawing.stations.map((station)=>station.label),['0+980.25','1+040.25','1+080.25']);
      expect(drawing.lengthMm,100000);
      expect(drawing.bands.map((band)=>(band.label,band.widthMm)),[('Footway',2000),('Traveled way',7000),('Unallocated ROW',3000)]);
      expect(drawing.edges.map((edge)=>(edge[1].easting,edge[1].northing)),[
        (345054250,2110006500),(345056250,2110004500),(345063250,2109997500),(345066250,2109994500),
      ]);
      final cad=FloorPlanCad.fromSurveyCorridor(drawing);
      final axis=cad.lines.where((line)=>line.layer=='SURVEY_AXIS').toList();
      expect(axis.length,2);
      expect((axis.first.start.x,axis.first.start.y),(345000250,2110000500));
      expect((axis.last.end.x,axis.last.end.y),(345060250,2110040500));
      expect(cad.lines.where((line)=>line.layer=='RIGHT_OF_WAY').length,6);
      expect(cad.lines.where((line)=>line.layer=='CORRIDOR_BANDS').length,4);
      final dxf=cad.toDxf();
      expect(dxf,contains('345000250.000'));
      expect(dxf,contains('2110040500.000'));
      expect(dxf,contains('STA 1+080.25'));
      expect(dxf,contains('Projected example grid / Survey A1'));
    }
  });

  test('centreline boundary is not duplicated; a two-point survey remains supported', () {
    final result=generator.generate(brief(edits:{'corridor_points':'-25,0;75,0','corridor_bands':'Left:6;Right:6'}));
    expect(result.issue,isNull);
    final drawing=result.drawing!;
    expect(drawing.edges[1].first.easting,-25000);
    expect(drawing.edges[1].first.northing,0);
    final cad=FloorPlanCad.fromSurveyCorridor(drawing);
    expect(cad.lines.where((line)=>line.layer=='SURVEY_AXIS').length,1);
    expect(cad.lines.where((line)=>line.layer=='CORRIDOR_BANDS'),isEmpty);
  });

  test('bad input or non-fitting geometry does not generate fallback CAD', () {
    for(final (candidate,message) in [
      (brief(type:'intersection'),'supports roads'),
      (brief(configuration:'node_interchange'),'Use a linear'),
      (brief(spaces:{'footpath':1}),'separate Space'),
      (brief(edits:{'corridor_grid':''}),'survey grid'),
      (brief(edits:{'corridor_bands':'Footway:13'}),'exceeds'),
      (brief(edits:{'corridor_points':'0,0;A,40'}),'Point 2'),
      (brief(edits:{'corridor_points':'0,0;0,0;100,0'}),'coincide'),
      (brief(edits:{'route_length':99.9}),'within 0.05 m'),
      (brief(edits:{'corridor_points':'0,0;50,0;0,0'}),'reverses'),
      (brief(edits:{'corridor_points':'0,0;40,0;40,8;0,8','route_length':88}),'fold'),
      (brief(edits:{'corridor_points':'0,0;40,0;40,30;20,30;20,-20','route_length':140}),'crosses or touches itself'),
      (brief(edits:{'corridor_points':'0,0;40,0;40,30;20,30;20,1','route_length':119}),'crosses or touches itself'),
    ]) {
      final result=generator.generate(candidate);
      expect(result.drawing,isNull,reason:message);
      expect(result.issue,contains(message));
    }
    final zoning=ConceptZoningGenerator().generate(brief(edits:{'concept_straight_alignment':'confirmed'}),widthFt:0,depthFt:0);
    expect(zoning.sheets,isEmpty);
    expect(zoning.issues.single,contains('not straight zoning'));
  });

  testWidgets('survey CAD preview exposes DXF only when geometry is valid', (tester) async {
    Future<void> open(ProjectBrief input) => tester.pumpWidget(MaterialApp(home:SurveyCorridorScreen(key:ObjectKey(input),name:'Street',brief:input)));
    await open(brief());
    await tester.scrollUntilVisible(find.text('Share corridor DXF'),200);
    expect(find.text('Share corridor DXF'),findsOneWidget);
    await open(brief(edits:{'route_length':95}));
    expect(find.text('No corridor drawing generated'),findsOneWidget);
    expect(find.text('Share corridor DXF'),findsNothing);
  });
}
