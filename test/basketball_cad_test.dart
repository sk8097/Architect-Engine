import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/basketball_cad_screen.dart';
import 'package:architect_engine/services/basketball_cad_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief basketball({Map<String,Object> edits=const {},String setting='outdoor',String type='sports_complex',
    Map<String,int> spaces=const {}}) => ProjectBrief(floorCount:0,parking:ProjectParking.none,features:const [],
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'institutional',subcategoryId:'sports',typeId:type,
    configurationId:setting,plotShapeId:'rectangular',spaceQuantities:spaces),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'basketball_measured_court','bk_width':15,'bk_length':28,'bk_side':2,'bk_end':2.5,'bk_left':3,
    'bk_front':4,'bk_walk':1.8,'bk_rim':1.575,'bk_centre_r':1.8,'bk_key_width':4.9,'bk_key_depth':5.8,
    'bk_free_r':1.8,'bk_three_r':6.75,'bk_corner_inset':.9,...edits,
  }));

void main() {
  BasketballCadResult run(ProjectBrief brief,[String facing='South']) => BasketballCadGenerator().generate(brief,
    widthFt:26/.3048,depthFt:44/.3048,facing:facing);
  bool near(CadPoint p,CadPoint q) => (p.x-q.x).abs()<1e-6&&(p.y-q.y).abs()<1e-6;
  CadPoint endpoint(CadArc a,num deg) => CadPoint(a.center.x+a.radius*math.cos(deg*math.pi/180),
    a.center.y+a.radius*math.sin(deg*math.pi/180));
  num length(CadLine l) => (l.start.x-l.end.x).abs()+(l.start.y-l.end.y).abs();

  test('DXF preserves measured run-offs and exact arc-to-corner junctions for each orientation', () {
    final saved=ProjectBrief.fromMap(basketball().toMap())!;
    expect(BasketballCadGenerator.requested(saved),isTrue);
    expect(cadOutputOptions(warehouseLoading:false,basketball:true).options.map((o)=>o.id),contains('basketball_measured_court'));
    for(final facing in ['South','North','East','West']) {
      final r=run(saved,facing);
      expect(r.issue,isNull,reason:facing);
      expect((r.widthMm,r.lengthMm,r.sideMm,r.endMm),(15000,28000,2000,2500));
      final cad=r.drawing!;
      final lines=cad.lines.where((l)=>l.layer=='BASKET_THREE').toList(), arcs=cad.arcs.where((a)=>a.layer=='BASKET_THREE').toList();
      expect((lines.length,arcs.length),(4,2));
      expect(arcs.map((a)=>a.radius),[6750,6750]);
      final joins=arcs.expand((a)=>[endpoint(a,a.start),endpoint(a,a.end)]).toList();
      for(final line in lines) {expect(joins.where((p)=>near(p,line.end)).length,1);}
      final centres=cad.arcs.where((a)=>a.layer=='BASKET_LINES').toList();
      expect(centres.map((a)=>a.radius),[1800,1800]);
      expect(near(endpoint(centres.first,centres.first.end),endpoint(centres.last,centres.last.start)),isTrue);
      expect(near(endpoint(centres.last,centres.last.end),endpoint(centres.first,centres.first.start)),isTrue);
      expect(cad.lines.where((l)=>l.layer=='BASKET_APPROACH').map(length),[1800,4000,1800,4000]);
      expect(cad.lines.where((l)=>l.layer=='BASKET_RUNOFF').map(length),[19000,33000,19000,33000]);
      final dxf=cad.toDxf();
      expect(RegExp(r'\r?\nARC\r?\n8\r?\nBASKET_THREE\r?\n').allMatches(dxf).length,2);
      expect(dxf,contains('NO RULEBOOK CERTIFICATION'));
    }
  });

  test('short radii, excessive keys or insufficient run-off space prevent export', () {
    for(final (brief,issue) in [
      (basketball(type:'swimming_pool'),'Select a supported outdoor'),
      (basketball(setting:'indoor'),'one new outdoor court'),
      (basketball(spaces:{'field_court':1}),'separate Space selections'),
      (basketball(edits:{'bk_walk':16}),'approach must fit'),
      (basketball(edits:{'bk_front':12}),'rear plot edge'),
      (basketball(edits:{'left_setback':3.01}),'left plot edge'),
      (basketball(edits:{'bk_corner_inset':7.5}),'straight corner lines'),
      (basketball(edits:{'bk_three_r':6.6}),'nonzero arc transition'),
      (basketball(edits:{'bk_centre_r':6}),'court halves'),
      (basketball(edits:{'bk_key_depth':7.5}),'beyond the three-point'),
    ]) {
      final result=run(brief);
      expect(result.issue,contains(issue));
      expect(result.drawing,isNull);
    }
  });

  testWidgets('a blocked run-off layout does not offer DXF',(tester) async {
    await tester.pumpWidget(MaterialApp(home:BasketballCadScreen(name:'Outdoor court',brief:basketball(),
      widthFt:86,depthFt:145,facing:'East')));
    expect(find.text('Marked court 15.000 × 28.000 m'),findsOneWidget);
    expect(find.text('Share basketball court DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:BasketballCadScreen(key:const ValueKey('blocked'),name:'Outdoor court',
      brief:basketball(edits:{'bk_front':12}),widthFt:86,depthFt:145,facing:'East')));
    expect(find.textContaining('rear plot edge'),findsOneWidget);
    expect(find.text('Share basketball court DXF'),findsNothing);
  });
}
