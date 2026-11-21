import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/twin_tank_cad_screen.dart';
import 'package:architect_engine/services/twin_tank_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief tank({Map<String,Object> edits=const {},String type='water_tank'})=>ProjectBrief(
  floorCount:null,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'infrastructure',subcategoryId:'water',
    typeId:type,configurationId:'storage',plotShapeId:'rectangular'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'tank_twin_cell','tt_w_a':5,'tt_w_b':4,'tt_length':10,'tt_wall':.25,'tt_divider':.3,'tt_height':3.5,
    'tt_lower_a':.4,'tt_normal_a':3.1,'tt_lower_b':.3,'tt_normal_b':2.8,'tt_freeboard':.4,'tt_service':1.5,
    'tt_west':3,'tt_south':4,'tt_total':235,'tt_reserve':100,...edits,
  }));

void main() {
  const widthFt=22/.3048,depthFt=24/.3048;
  TwinTankCadResult run(ProjectBrief b)=>TwinTankCadGenerator().generate(b,widthFt:widthFt,depthFt:depthFt);

  test('opt-in persists and volumes use clear dimensions and operating levels independently', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o)=>o.id),isNot(contains('tank_twin_cell')));
    expect(cadOutputOptions(warehouseLoading:false,twinTank:true).options.map((o)=>o.id),contains('tank_twin_cell'));
    final saved=ProjectBrief.fromMap(tank().toMap())!;
    expect(TwinTankCadGenerator.requested(saved),isTrue);
    final r=run(saved);
    expect(r.issue,isNull);
    expect((r.usableA,r.usableB,r.usableTotal,r.reserve),(135,100,235,100));
    expect((r.widthMm,r.depthMm,r.freeboardA,r.freeboardB),(9800,10500,400,700));
    final p=r.plan!;
    final cells=p.lines.where((l)=>l.layer=='TWIN_TANK_CELL').toList();
    expect(cells.length,8);
    expect((cells[0].start.x,cells[0].start.y,cells[0].end.x,cells[4].start.x,cells[4].end.x),(4750,5750,9750,10050,14050));
    final service=p.lines.firstWhere((l)=>l.layer=='TWIN_TANK_SERVICE');
    expect((service.start.x,service.start.y,service.end.x,service.end.y),(3000,4000,15800,4000));
    expect(p.toDxf(),contains('235.000 M3 USABLE TOTAL / 100.000 M3 WITH EITHER CELL OFFLINE'));
  });

  test('exact setbacks fit; true-scale cross-section shows both normal and lower levels', () {
    final r=run(tank(type:'ground_reservoir',edits:{'left_setback':3,'right_setback':6.2,'front_setback':4,'rear_setback':6.5}));
    expect(r.issue,isNull);
    final s=r.section!;
    final levels=s.lines.where((l)=>l.layer=='TWIN_TANK_NORMAL');
    expect(levels.map((l)=>(l.start.x,l.start.y,l.end.x,l.end.y)),[(250,3100,5250,3100),(5550,2800,9550,2800)]);
    expect(s.lines.where((l)=>l.layer=='TWIN_TANK_LOW').map((l)=>l.start.y),[400,300]);
    expect(s.toDxf(),contains('FREEBOARD A 0.400 M / B 0.700 M'));
    final floor=run(tank(edits:{'tt_lower_a':0}));
    expect(floor.usableA,155);
    expect(floor.section!.lines.where((l)=>l.layer=='TWIN_TANK_LOW').length,1);
  });

  test('worst case uses smaller usable cell, not smaller footprint or average', () {
    final r=run(tank(edits:{'tt_lower_a':2.1,'tt_total':140,'tt_reserve':50}));
    expect(r.issue,isNull);
    expect((r.usableA,r.usableB,r.usableTotal,r.reserve),(50,100,150,50));
  });

  test('invalid levels, required outage reserve, combined capacity and plot fit block both DXFs', () {
    for(final (brief,message) in [
      (tank(type:'rainwater_harvesting_system'),'Select Water Tank'),
      (tank(edits:{'tt_normal_b':.3}),'Cell B normal level must be above'),
      (tank(edits:{'tt_normal_a':3.101}),'Cell A normal level exceeds'),
      (tank(edits:{'tt_normal_b':3.501,'tt_freeboard':0}),'Cell B normal level exceeds'),
      (tank(edits:{'right_setback':6.201}),'right plot edge'),
      (tank(edits:{'tt_total':235.001}),'total target'),
      (tank(edits:{'tt_reserve':100.001}),'worst-case remaining volume'),
    ]) {
      final r=run(brief);
      expect(r.issue,contains(message));
      expect(r.plan,isNull);
      expect(r.section,isNull);
    }
  });

  testWidgets('previews section and withholds exports if the one-cell reserve fails',(tester) async {
    await tester.pumpWidget(MaterialApp(home:TwinTankCadScreen(name:'Tank',brief:tank(),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('Worst case with one offline 100.000 m³'),findsOneWidget);
    expect(find.text('Share tank plan DXF'),findsOneWidget);
    await tester.tap(find.text('Tank cross-section'));
    await tester.pumpAndSettle();
    expect(find.text('Share tank section DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:TwinTankCadScreen(key:const ValueKey('failed'),name:'Tank',
      brief:tank(edits:{'tt_reserve':110}),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('worst-case remaining volume'),findsOneWidget);
    expect(find.text('Share tank plan DXF'),findsNothing);
    expect(find.text('Share tank section DXF'),findsNothing);
  });
}
