import 'package:architect_engine/data/culvert_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/culvert_cad_screen.dart';
import 'package:architect_engine/services/culvert_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief culvert({Map<String,Object> edits=const {},String type='culvert'}) => ProjectBrief(
  floorCount:null,parking:null,features:const [],taxonomy:TaxonomySelection(version:projectTaxonomyVersion,
    categoryId:'infrastructure',subcategoryId:'water',typeId:type,configurationId:'drainage_system'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'culvert_cad_mode':'survey_crossing','cv_grid':'Local grid','cv_reference':'BM12 survey',
    'cv_ends':'345000,2110000,100.200,100;345030,2110040,99.800,99.500',
    'cv_surface':'10,102.600;20,102.400;30,101.750;40,102.120',
    'cv_road_station':25,'cv_road_bearing':0,'cv_road_width':12,'cv_barrel_width':2,'cv_crown':1.2,
    'cv_cover':.85,'cv_fall':1,...edits,
  }));

void main() {
  final gen=CulvertCadGenerator();
  test('skew projected road edges, exact low point, barrel ends and level datum export', () {
    final saved=ProjectBrief.fromMap(culvert(edits:{'cv_scale':'5'}).toMap())!;
    expect(CulvertCadGenerator.requested(saved),isTrue);
    expect(culvertCadMode.options.map((option)=>option.id),contains('survey_crossing'));
    final result=gen.generate(saved);
    expect(result.issue,isNull);
    expect((result.lengthMm,result.gradePercent,result.roadStartMm,result.roadEndMm),(50000,1,15000,35000));
    expect((result.coverMm,result.coverAtMm,result.exaggeration),(850,30000,5));
    final plan=result.plan!,profile=result.profile!;
    final axis=plan.lines.singleWhere((l)=>l.layer=='CULVERT_BARREL_AXIS');
    expect((axis.start.x,axis.start.y,axis.end.x,axis.end.y),(345000000,2110000000,345030000,2110040000));
    final road=plan.lines.where((l)=>l.layer=='CULVERT_ROAD').toList();
    expect(road.length,4);
    expect(road.first.start.x,345009000);
    expect(road[2].start.x,345021000);
    final cover=profile.lines.singleWhere((l)=>l.layer=='CULVERT_COVER');
    expect((cover.start.x,cover.end.x),(30000,30000));
    expect(cover.end.y-cover.start.y,4250);
    final trueScale=gen.generate(culvert());
    expect(trueScale.coverMm,result.coverMm);
    expect(trueScale.roadEndMm,result.roadEndMm);
    expect(profile.toDxf(),contains('X = INLET CHAINAGE MM / Y = (LEVEL - 98.000 M) x 5 IN MM'));
    for(final layer in ['CULVERT_ROAD','CULVERT_BARREL','CULVERT_ROAD_AXIS','CULVERT_CONTROLS']) {
      expect(plan.toDxf(),contains(layer));
    }
  });

  test('interpolates at exact road limits and ignores exposed ends outside the road', () {
    final result=gen.generate(culvert(edits:{'cv_cover':.35,'cv_surface':'10,100.4;20,102.4;30,103;40,103','cv_road_bearing':180}));
    expect(result.issue,isNull);
    expect(result.coverAtMm,closeTo(15000,.001));
    expect(result.coverMm,closeTo(350,.001));
    final straightInterpolated=gen.generate(culvert(edits:{'cv_surface':'','cv_cover':0}));
    expect(straightInterpolated.issue,contains('below the supplied'));
  });

  test('bad surveyed fit or limits prevent both drawings', () {
    for(final (brief,reason) in [
      (culvert(type:'stormwater_drain'),'Select Water'),
      (culvert(edits:{'cv_ends':'0,0,1,0'}),'exactly two controls'),
      (culvert(edits:{'cv_surface':'30,102;20,103'}),'increase strictly'),
      (culvert(edits:{'cv_fall':1.01}),'minimum grade'),
      (culvert(edits:{'cv_road_bearing':36.87}),'at least 15°'),
      (culvert(edits:{'cv_road_station':11}),'Both full barrel ends'),
      (culvert(edits:{'cv_cover':.851}),'0.850 m at chainage 30.000 m'),
    ]) {
      final result=gen.generate(brief);
      expect(result.issue,contains(reason));
      expect(result.plan,isNull);
      expect(result.profile,isNull);
    }
  });

  testWidgets('crossing and barrel profile are selectable only on valid briefs',(tester) async {
    await tester.pumpWidget(MaterialApp(home:CulvertCadScreen(name:'Survey crossing',brief:culvert())));
    expect(find.text('Min. cover 0.850 m at ch 30.000 m'),findsOneWidget);
    expect(find.text('Share crossing plan DXF'),findsOneWidget);
    await tester.tap(find.text('Barrel profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share barrel profile DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:CulvertCadScreen(key:const ValueKey('blocked'),name:'Survey crossing',
      brief:culvert(edits:{'cv_cover':.851}))));
    expect(find.textContaining('below the supplied'),findsOneWidget);
    expect(find.text('Share crossing plan DXF'),findsNothing);
    expect(find.text('Share barrel profile DXF'),findsNothing);
  });
}
