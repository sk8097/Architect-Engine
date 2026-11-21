import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/gallery_panel_cad_screen.dart';
import 'package:architect_engine/services/gallery_panel_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief gallery({Map<String,Object> edits=const {},String type='museum',int? floors=1})=>ProjectBrief(
  floorCount:floors,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'institutional',subcategoryId:'culture',
    typeId:type,configurationId:'main_hall',plotShapeId:'rectangular'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'gallery_panel_layout','gp_pairs':2,'gp_length':6,'gp_thick':.2,'gp_end_margin':.5,'gp_display_height':1.8,
    'gp_view':1.25,'gp_middle':2,'gp_between':.9,'gp_side':1.2,'gp_front':2,'gp_rear':2.5,'gp_door':1.8,
    'gp_wall':.2,'gp_west':3,'gp_south':4,...edits,
  }));

void main() {
  const widthFt=25/.3048,depthFt=20/.3048;
  GalleryPanelCadResult run(ProjectBrief b)=>GalleryPanelCadGenerator().generate(b,widthFt:widthFt,depthFt:depthFt);

  test('explicit option persists and measures both usable faces of every panel', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o)=>o.id),isNot(contains('gallery_panel_layout')));
    expect(cadOutputOptions(warehouseLoading:false,galleryPanels:true).options.map((o)=>o.id),contains('gallery_panel_layout'));
    final saved=ProjectBrief.fromMap(gallery().toMap())!;
    expect(GalleryPanelCadGenerator.requested(saved),isTrue);
    final r=run(saved);
    expect(r.issue,isNull);
    expect((r.panels,r.faces.length,r.widthMm,r.depthMm,r.displayM,r.displayM2),(4,8,17400,10900,40,72));
    final first=r.faces.first;
    expect((first.panel,first.side,first.xMm,first.startMm,first.endMm),('W1','west',5650,6700,11700));
    final csv=r.toCsv()!.trimRight().split('\r\n');
    expect(csv.length,9);
    expect(csv[1],'W1,west,5.650,6.700,11.700,5.000,1.800,9.000000');
    expect(csv.last,startsWith('E2,east,17.750,'));
    expect(r.drawing!.toDxf(),contains('40.000 M DISPLAY LENGTH / 72.000 M2 HANGING AREA'));
  });

  test('viewing depth and side / centre passage widths do not overlap', () {
    final c=run(gallery(type:'art_centre')).drawing!;
    final bounds=c.lines.where((l)=>l.layer=='GALLERY_VIEW' && l.start.x==l.end.x).map((l)=>l.start.x).toList();
    expect(bounds,[4400,7100,8000,10700,12700,15400,16300,19000]);
    expect(bounds[4]-bounds[3],2000);
    expect(bounds[2]-bounds[1],900);
    final outerFront=c.lines.where((l)=>l.layer=='GALLERY_WALL' && l.start.y==4000 && l.end.y==4000);
    expect(outerFront.map((l)=>(l.start.x,l.end.x)),[(3000,10800),(12600,20400)]);
    final spine=c.lines.singleWhere((l)=>l.layer=='GALLERY_SPINE');
    expect((spine.start.x,spine.start.y,spine.end.x,spine.end.y),(11700,4200,11700,14700));
  });

  test('exact setbacks and FSI / coverage limits fit; two-panel layout has no internal gaps', () {
    final exact=run(gallery(edits:{'left_setback':3,'right_setback':4.6,'front_setback':4,'rear_setback':5.1,
      'fsi_limit':.37932,'coverage_limit':37.932}));
    expect(exact.issue,isNull);
    final two=run(gallery(edits:{'gp_pairs':1,'gp_between':0,'gp_end_margin':0}));
    expect((two.issue,two.panels,two.widthMm,two.displayM),(null,2,10200,24));
    expect(two.drawing!.lines.every((l)=>l.start.x!=l.end.x || l.start.y!=l.end.y),isTrue);
  });

  test('incompatible briefs, capacity widths and site limits block both outputs', () {
    for(final (brief,message) in [
      (gallery(type:'theatre'),'Select Museum'),
      (gallery(floors:2),'one ground-floor gallery'),
      (gallery(edits:{'gp_door':2.001}),'aligned clear central aisle'),
      (gallery(edits:{'gp_end_margin':3}),'no positive usable display length'),
      (gallery(edits:{'gp_between':0}),'positive inter-panel passage'),
      (gallery(edits:{'rear_setback':5.101}),'rear plot edge'),
      (gallery(edits:{'fsi_limit':.37}),'supplied FSI'),
      (gallery(edits:{'coverage_limit':37}),'supplied site coverage'),
    ]) {
      final r=run(brief);
      expect(r.issue,contains(message));
      expect(r.drawing,isNull);
      expect(r.toCsv(),isNull);
    }
  });

  testWidgets('preview reports usable area and blocks DXF and CSV on fit failure',(tester) async {
    await tester.pumpWidget(MaterialApp(home:GalleryPanelCadScreen(name:'Small gallery',brief:gallery(),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('Hanging area 72.000 m²'),findsOneWidget);
    expect(find.text('Share gallery plan DXF'),findsOneWidget);
    expect(find.text('Share display-face CSV'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:GalleryPanelCadScreen(key:const ValueKey('failed'),name:'Small gallery',
      brief:gallery(edits:{'gp_door':2.1}),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('aligned clear central aisle'),findsOneWidget);
    expect(find.text('Share gallery plan DXF'),findsNothing);
    expect(find.text('Share display-face CSV'),findsNothing);
  });
}
