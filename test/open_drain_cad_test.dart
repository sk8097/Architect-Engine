import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/stormwater_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/open_drain_cad_screen.dart';
import 'package:architect_engine/services/open_drain_cad_generator.dart';
import 'package:architect_engine/services/stormwater_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief openDrain({Map<String,Object> edits=const {},String type='stormwater_drain'}) => ProjectBrief(
  floorCount:null,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'infrastructure',subcategoryId:'water',
    typeId:type,configurationId:'drainage_system'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'drain_cad_mode':'survey_open_drain','od_grid':'Projected survey grid','od_datum':'Survey BM 02',
    'od_ends':'500000,2000000,100.200;500030,2000040,99.700',
    'od_bottom':1.2,'od_depth':1,'od_reference':.6,'od_left_slope':2,'od_right_slope':1.5,
    'od_strip':.75,'od_left_limit':3.35,'od_right_limit':2.85,'od_min_fall':1,...edits,
  }));

void main() {
  final service=OpenDrainCadGenerator();

  test('new surveyed option round-trips without activating the gravity pipe mode', () {
    expect(stormwaterCadMode.options.map((o)=>o.id),containsAll(['survey_gravity','survey_open_drain']));
    final saved=ProjectBrief.fromMap(openDrain().toMap());
    expect(OpenDrainCadGenerator.requested(saved),isTrue);
    expect(StormwaterCadGenerator.requested(saved),isFalse);
    expect(service.generate(openDrain(type:'drainage_network')).issue,isNull);
  });

  test('calculates asymmetric trapezoid and preserves projected units and actual profile slope', () {
    final r=service.generate(openDrain());
    expect(r.issue,isNull);
    expect((r.lengthMm,r.grade,r.topWidthMm,r.freeboardMm),(50000,1,4700,400));
    expect(r.referenceAreaM2,closeTo(1.35,1e-9));
    final bank=r.plan!.lines.where((l)=>l.layer=='OPEN_DRAIN_BANK').toList();
    expect((bank[0].start.x,bank[0].start.y,bank[0].end.x,bank[0].end.y),(499997920,2000001560,500027920,2000041560));
    expect((bank[1].start.x,bank[1].start.y),(500001680,1999998740));
    final section=r.section!.lines.singleWhere((l)=>l.layer=='OPEN_DRAIN_REF');
    expect((section.start.x,section.start.y,section.end.x,section.end.y),(-1800,600,1500,600));
    final profile=r.profile!.lines.singleWhere((l)=>l.layer=='OPEN_DRAIN_BOTTOM');
    expect((profile.start.x,profile.start.y,profile.end.x,profile.end.y),(0,0,50000,-500));
    expect(r.plan!.toDxf(),contains('GRID: Projected survey grid'));
    expect(r.section!.toDxf(),contains('AREA 1.350 M2 / FREEBOARD 0.400 M'));
    expect(r.profile!.toDxf(),contains('INLET RL 100.200 M / OUTLET RL 99.700 M / FALL 0.500 M'));
  });

  test('rejects malformed controls, reverse grade, no freeboard and unilateral corridor shortfall', () {
    for(final (brief,issue) in [
      (openDrain(type:'culvert'),'Select Stormwater Drain'),
      (openDrain(edits:{'od_grid':' '}),'projected metre grid'),
      (openDrain(edits:{'od_ends':'0,0,2'}),'exactly two'),
      (openDrain(edits:{'od_ends':'0,0,2.0001;1,0,1'}),'three decimal places'),
      (openDrain(edits:{'od_ends':'0,0,2;0,0,1'}),'positive straight reach'),
      (openDrain(edits:{'od_ends':'0,0,1;3,4,2'}),'fall downstream'),
      (openDrain(edits:{'od_min_fall':1.01}),'minimum grade'),
      (openDrain(edits:{'od_reference':1}),'positive geometric freeboard'),
      (openDrain(edits:{'od_left_limit':3.349,'od_right_limit':10}),'left corridor limit'),
      (openDrain(edits:{'od_left_limit':10,'od_right_limit':2.849}),'right corridor limit'),
    ]) {
      final r=service.generate(brief);
      expect(r.issue,contains(issue));
      expect(r.plan,isNull);
      expect(r.section,isNull);
      expect(r.profile,isNull);
    }
  });

  testWidgets('previews all three export sheets and blocks an invalid saved brief',(tester) async {
    await tester.pumpWidget(MaterialApp(home:OpenDrainCadScreen(name:'Open drain',brief:openDrain())));
    expect(find.text('Share plan DXF'),findsOneWidget);
    await tester.tap(find.text('Cross-section'));
    await tester.pumpAndSettle();
    expect(find.text('Share section DXF'),findsOneWidget);
    await tester.tap(find.text('Invert profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share profile DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:OpenDrainCadScreen(key:const ValueKey('invalid'),name:'Open drain',
      brief:openDrain(edits:{'od_left_limit':3}))));
    expect(find.textContaining('left corridor limit'),findsOneWidget);
    expect(find.text('Share plan DXF'),findsNothing);
    expect(find.text('Share profile DXF'),findsNothing);
  });
}
