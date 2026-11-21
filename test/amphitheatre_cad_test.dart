import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/amphitheatre_cad_screen.dart';
import 'package:architect_engine/services/amphitheatre_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief amphitheatre({Map<String,Object> edits=const {},String type='theatre',String? arrangement}) => ProjectBrief(
  floorCount:null,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'institutional',subcategoryId:'culture',
    typeId:type,configurationId:arrangement,plotShapeId:'square'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'outdoor_tiered_amphitheatre','at_rows':6,'at_width':12,'at_tread':.9,'at_rise':.35,
    'at_seat':.5,'at_margin':.25,'at_side':2,'at_rear':2,'at_stage_width':12,'at_stage_depth':5,
    'at_stage_level':.65,'at_gap':3,'at_eye':1.2,'at_clearance':.085,'at_west':3,'at_south':4,...edits,
  }));

void main() {
  const plotFt=24/.3048;
  AmphitheatreCadResult run(ProjectBrief b)=>AmphitheatreCadGenerator().generate(b,widthFt:plotFt,depthFt:plotFt);

  test('opt-in round trips and draws one mark per whole nominal place', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o)=>o.id),isNot(contains('outdoor_tiered_amphitheatre')));
    expect(cadOutputOptions(warehouseLoading:false,amphitheatre:true).options.map((o)=>o.id),contains('outdoor_tiered_amphitheatre'));
    final saved=ProjectBrief.fromMap(amphitheatre().toMap())!;
    expect(AmphitheatreCadGenerator.requested(saved),isTrue);
    final r=run(saved);
    expect(r.issue,isNull);
    expect((r.envelopeWidthMm,r.envelopeDepthMm,r.rows,r.placesPerRow,r.places),(16000,15400,6,23,138));
    final places=r.plan!.lines.where((l)=>l.layer=='AMPH_PLACES').toList();
    expect(places.length,138);
    expect((places.first.start.x+places.first.end.x)/2,5500);
    expect(places.first.start.y,12450);
    expect(r.plan!.toDxf(),contains('6 ROWS x 23 NOMINAL PLACES'));
  });

  test('centreline section uses actual tier rise and evaluates clearance at the preceding eye', () {
    final r=run(amphitheatre(type:'performing_arts_centre'));
    expect(r.criticalRow,6);
    expect(r.clearanceMm,closeTo(712500/7950,1e-9));
    final ll=r.section!.lines;
    final tier=ll.where((l)=>l.layer=='AMPH_TIERS').toList();
    expect((tier[1].start.x,tier[1].start.y,tier[1].end.x,tier[1].end.y),(8900,0,8900,350));
    final sight=ll.where((l)=>l.layer=='AMPH_SIGHT').toList();
    expect((sight.first.start.x,sight.first.start.y,sight.first.end.x,sight.first.end.y),(5000,650,12950,2950));
    expect((sight.last.start.x,sight.last.start.y),(12050,2600));
    expect(sight.last.end.y-sight.last.start.y,closeTo(r.clearanceMm,1e-9));
    expect(r.section!.toDxf(),contains('ROW 6 MIN CLEARANCE 0.090 M'));
  });

  test('fits exact setbacks; wider stage controls the transverse envelope', () {
    final exact=run(amphitheatre(edits:{'left_setback':3,'right_setback':5,'front_setback':4,'rear_setback':4.6}));
    expect(exact.issue,isNull);
    expect(run(amphitheatre(edits:{'at_stage_width':18})).envelopeWidthMm,18000);
  });

  test('mismatched taxonomy, tier obstruction, supplied clearance and plot limits block both exports', () {
    for(final (brief,message) in [
      (amphitheatre(type:'museum'),'Select Theatre'),
      (amphitheatre(arrangement:'main_hall'),'Leave the indoor hall arrangement'),
      (amphitheatre(edits:{'at_margin':6}),'complete nominal places'),
      (amphitheatre(edits:{'at_rear':6.601}),'rear plot edge'),
      (amphitheatre(edits:{'at_eye':.01,'at_stage_level':0}),'intersects a seating tier'),
      (amphitheatre(edits:{'at_clearance':.09}),'89.62 mm, below the supplied 90 mm minimum'),
    ]) {
      final r=run(brief);
      expect(r.issue,contains(message));
      expect(r.plan,isNull);
      expect(r.section,isNull);
    }
  });

  testWidgets('preview switches to section and invalid brief hides export',(tester) async {
    await tester.pumpWidget(MaterialApp(home:AmphitheatreCadScreen(name:'Outdoor stage',brief:amphitheatre(),widthFt:plotFt,depthFt:plotFt)));
    expect(find.textContaining('138 nominal places'),findsOneWidget);
    expect(find.text('Share amphitheatre plan DXF'),findsOneWidget);
    await tester.tap(find.text('Centreline section'));
    await tester.pumpAndSettle();
    expect(find.text('Share seating section DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:AmphitheatreCadScreen(key:const ValueKey('blocked'),name:'Outdoor stage',
      brief:amphitheatre(edits:{'at_clearance':.1}),widthFt:plotFt,depthFt:plotFt)));
    expect(find.textContaining('below the supplied'),findsOneWidget);
    expect(find.text('Share seating section DXF'),findsNothing);
    expect(find.text('Share amphitheatre plan DXF'),findsNothing);
  });
}
