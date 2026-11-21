import 'dart:math' as math;

import 'package:architect_engine/data/footbridge_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/footbridge_cad_screen.dart';
import 'package:architect_engine/services/footbridge_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief crossing({Map<String,Object> edits=const {},String type='bridge'})=>ProjectBrief(
  floorCount:null,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'infrastructure',subcategoryId:'transport',
    typeId:type,configurationId:'linear_corridor'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'footbridge_mode':'survey_footbridge','fb_grid':'Projected grid','fb_datum':'BM-01',
    'fb_ends':'500000,2000000,100;500080,2000000,100.2','fb_cross':40,'fb_bearing':30,'fb_channel':20,
    'fb_edge_gap':1,'fb_deck_start':26,'fb_deck_end':54,'fb_width':3,'fb_level':101.3,'fb_depth':.5,
    'fb_water':99.4,'fb_clearance':1.4,'fb_limit':5,...edits,
  }));

void main() {
  final generator=FootbridgeCadGenerator();

  test('opt-in round trips and the full skewed deck spans both banks', () {
    expect(footbridgeCadMode.options.single.id,'survey_footbridge');
    final saved=ProjectBrief.fromMap(crossing().toMap())!;
    expect(FootbridgeCadGenerator.requested(saved),isTrue);
    final r=generator.generate(saved),half=23500/math.sqrt(3);
    expect(r.issue,isNull);
    expect((r.lengthMm,r.spanMm,r.gradeA,r.clearanceMm),(80000,28000,5,1400));
    expect(r.gradeB,closeTo(1100/260,1e-10));
    expect(r.requiredStartMm,closeTo(40000-half,1e-8));
    expect(r.requiredEndMm,closeTo(40000+half,1e-8));
    final deck=r.plan!.lines.where((l)=>l.layer=='FOOTBRIDGE_DECK').toList();
    expect(deck.length,4);
    expect((deck[0].start.x,deck[0].start.y,deck[0].end.x,deck[0].end.y),(500026000,1999998500,500054000,1999998500));
    expect((deck[3].start.x,deck[3].start.y,deck[3].end.x,deck[3].end.y),(500054000,1999998500,500054000,2000001500));
    expect(r.plan!.toDxf(),contains('DECK CH 26.000 TO 54.000 M / SPAN 28.000 M'));
  });

  test('true-scale profile has separate soffit and reference water with real vertical clearance', () {
    final r=generator.generate(crossing());
    final p=r.profile!;
    final soffit=p.lines.singleWhere((l)=>l.layer=='FOOTBRIDGE_SOFFIT');
    expect((soffit.start.x,soffit.start.y,soffit.end.x,soffit.end.y),(26000,1400,54000,1400));
    final water=p.lines.singleWhere((l)=>l.layer=='FOOTBRIDGE_WATER');
    expect((water.start.y,water.end.y),(0,0));
    expect(water.end.x-water.start.x,closeTo(40000/math.sqrt(3),1e-8));
    expect(p.toDxf(),contains('VERTICAL CLEARANCE 1.400 M / PROFILE ZERO AT RL 99.400 M'));
  });

  test('allows exact perpendicular bank gap and signed survey levels', () {
    final r=generator.generate(crossing(edits:{'fb_bearing':360,'fb_deck_start':29,'fb_deck_end':51,
      'fb_ends':'500000,2000000,-10;500080,2000000,-9.8','fb_level':-8.7,'fb_water':-10.6'}));
    expect(r.issue,isNull);
    expect((r.requiredStartMm,r.requiredEndMm,r.clearanceMm),(29000,51000,1400));
  });

  test('rejects invalid controls, end-face skew missed by centreline-only fit, slope and clearance', () {
    for(final (brief,message) in [
      (crossing(type:'road'),'Bridge and save'),
      (crossing(edits:{'fb_ends':'0,0,100'}),'exactly two'),
      (crossing(edits:{'fb_ends':'0,0.0001,99;80,0,99'}),'three decimal places'),
      (crossing(edits:{'fb_deck_end':80}),'positive approach lengths'),
      (crossing(edits:{'fb_bearing':90}),'15° from parallel'),
      (crossing(edits:{'fb_deck_start':27}),'across the full deck width'),
      (crossing(edits:{'fb_deck_end':53}),'across the full deck width'),
      (crossing(edits:{'fb_limit':4.999}),'each must meet'),
      (crossing(edits:{'fb_clearance':1.401}),'below the supplied'),
      (crossing(edits:{'fb_water':101,'fb_clearance':0}),'below the supplied'),
    ]) {
      final r=generator.generate(brief);
      expect(r.issue,contains(message));
      expect(r.plan,isNull);
      expect(r.profile,isNull);
    }
  });

  testWidgets('preview switches to profile and invalid fit blocks both exports',(tester) async {
    await tester.pumpWidget(MaterialApp(home:FootbridgeCadScreen(name:'Park crossing',brief:crossing())));
    expect(find.textContaining('Deck span 28.000 m'),findsOneWidget);
    expect(find.text('Share footbridge plan DXF'),findsOneWidget);
    await tester.tap(find.text('Deck profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share footbridge profile DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:FootbridgeCadScreen(key:const ValueKey('failed'),name:'Park crossing',
      brief:crossing(edits:{'fb_deck_start':27}))));
    expect(find.textContaining('full deck width'),findsOneWidget);
    expect(find.text('Share footbridge plan DXF'),findsNothing);
    expect(find.text('Share footbridge profile DXF'),findsNothing);
  });
}
