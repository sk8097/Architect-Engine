import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/projects_screen.dart';
import 'package:architect_engine/services/public_market_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief market({Map<String,Object> edits = const {}, String type = 'public_market'}) => ProjectBrief(
  floorCount:null, features:const [], parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion, categoryId:'institutional', subcategoryId:'sports',
    typeId:type, configurationId:'outdoor', plotShapeId:'rectangular'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion, answers:{
    'cad_output':'public_market_stalls', 'pm_stalls':5, 'pm_pitch':3, 'pm_depth':2.4, 'pm_opening':1.8,
    'pm_aisle':3.6, 'pm_side':1.8, 'pm_entry_cross':2.5, 'pm_rear_cross':3, 'pm_entry':2.4,
    'pm_left':2, 'pm_front':4, ...edits,
  }));

void main() {
  const widthFt = 20/.3048, depthFt = 30/.3048;
  PublicMarketCadResult run(ProjectBrief brief, {String facing = 'South'}) =>
    PublicMarketCadGenerator().generate(brief,widthFt:widthFt,depthFt:depthFt,facing:facing);

  test('explicit option persists and reserves exactly the measured stall and circulation areas', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o) => o.id),isNot(contains('public_market_stalls')));
    expect(cadOutputOptions(warehouseLoading:false,publicMarket:true).options.map((o) => o.id),contains('public_market_stalls'));
    final saved = ProjectBrief.fromMap(market().toMap())!;
    expect(PublicMarketCadGenerator.requested(saved),isTrue);
    final r = run(saved), c = r.drawing!;
    expect((r.stalls,r.widthMm,r.depthMm,r.stallAreaM2,r.circulationM2),(10,12000,20500,72,174));
    expect(c.labels.where((l) => l.layer == 'MARKET_STALL').map((l) => l.text),
      ['L1','L2','L3','L4','L5','R1','R2','R3','R4','R5']);
    final westFace = c.lines.where((l) => l.layer=='MARKET_STALL' && l.start.x==6200 && l.end.x==6200);
    expect(westFace.map((line) => (line.start.y,line.end.y)).take(2),[(6500,7100),(8900,9500)]);
    final across = c.lines.where((l) => l.layer=='MARKET_LOOP' && l.start.y==4000 && l.end.y==4000);
    expect(across.map((line) => (line.start.x,line.end.x)),[(2000,6800),(9200,14000)]);
    expect(c.toDxf(),contains('INTERNAL CIRCULATION 174.000 M2'));
  });

  test('plot and both approach sides rotate onto all four different frontage edges', () {
    for (final (face,start,end) in [
      ('South',(6800,0),(6800,4000)), ('North',(13200,30000),(13200,26000)),
      ('East',(30000,6800),(26000,6800)), ('West',(0,13200),(4000,13200)),
    ]) {
      final drawing = run(market(),facing:face).drawing!;
      final entry = drawing.lines.where((l) => l.layer=='MARKET_ENTRY').toList();
      expect(entry.length,2);
      expect((entry.first.start.x,entry.first.start.y),start);
      expect((entry.first.end.x,entry.first.end.y),end);
      final second = entry.last;
      expect((second.start.x-entry.first.start.x).abs()+(second.start.y-entry.first.start.y).abs(),2400);
    }
  });

  test('exact setbacks and fully open stalls fit without zero-length faces', () {
    final r = run(market(edits:{'rear_setback':5.5,'right_setback':6,'pm_opening':3}));
    expect(r.issue,isNull);
    expect(r.drawing!.lines.where((l) => l.layer=='MARKET_STALL').length,14);
    expect(r.drawing!.lines.every((l) => l.start.x!=l.end.x || l.start.y!=l.end.y),isTrue);
  });

  test('rejects invalid dimensions, setbacks and incompatible briefs without DXF', () {
    for (final (brief,message) in [
      (market(type:'playground'),'Select Public Market'),
      (market(edits:{'pm_stalls':25}),'Enter measured'),
      (market(edits:{'pm_opening':3.001}),'centred stall opening'),
      (market(edits:{'pm_entry':3.601}),'central shopping aisle'),
      (market(edits:{'rear_setback':5.501}),'rear plot edge'),
      (market(edits:{'front_setback':4.001}),'front plot edge'),
    ]) {
      final r = run(brief);
      expect(r.issue,contains(message));
      expect(r.drawing,isNull);
    }
    expect(run(market(),facing:'Not decided').issue,contains('cardinal frontage'));
  });

  testWidgets('Projects reopens the measured mode with a reason and without generic fallback',(tester) async {
    final now = DateTime(2026);
    final p = ProjectModel(id:'market',name:'Saturday market',length:depthFt,width:widthFt,
      bhk:'',floors:'',facing:'West',brief:market(edits:{'rear_setback':6}),createdAt:now,updatedAt:now);
    SharedPreferences.setMockInitialValues({'ae_projects_v1':[p.toJson()]});
    await tester.binding.setSurfaceSize(const Size(900,1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(providers:[
      ChangeNotifierProvider(create:(_) => ProjectProvider()),
      ChangeNotifierProvider(create:(_) => AppStateProvider()),
      ChangeNotifierProvider(create:(_) => NotificationProvider()),
    ], child:const MaterialApp(home:ProjectsScreen())));
    await tester.pumpAndSettle();
    final button = find.byType(PopupMenuButton<String>);
    expect(button,findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Concept zoning CAD'),findsNothing);
    await tester.tap(find.text('Open-air public market CAD'));
    await tester.pumpAndSettle();
    expect(find.text('No market layout generated'),findsOneWidget);
    expect(find.textContaining('rear plot edge'),findsOneWidget);
    expect(find.text('Share market plan DXF'),findsNothing);
  });
}
