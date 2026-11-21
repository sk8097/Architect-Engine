import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/bus_layby_cad_screen.dart';
import 'package:architect_engine/screens/project_wizard_screen.dart';
import 'package:architect_engine/services/bus_layby_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProjectBrief layby({Map<String,Object> edits=const {},String type='bus_stop'}) => ProjectBrief(
  floorCount:null,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'infrastructure',subcategoryId:'transport',
    typeId:type,configurationId:'node_interchange'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'bus_layby_mode':'survey_layby','bl_grid':'Projected survey grid','bl_edge':'500000,2000000;500060,2000080',
    'bl_side':'left','bl_offset':10,'bl_entry':12,'bl_exit':10,'bl_count':2,'bl_berth':15,'bl_gap':3,
    'bl_width':3.2,'bl_board':2,'bl_shelter_len':8,'bl_shelter_depth':1.5,'bl_connection':2,'bl_walk':1.8,'bl_row':8.5,
    ...edits,
  }));

void main() {
  final generator=BusLaybyCadGenerator();

  test('surveyed dimensioned taper endpoints and opposite survey offsets', () {
    final saved=ProjectBrief.fromMap(layby().toMap())!;
    expect(BusLaybyCadGenerator.requested(saved),isTrue);
    final r=generator.generate(saved);
    expect(r.issue,isNull);
    expect((r.berths,r.edgeMm,r.startMm,r.endMm,r.requiredWidthMm,r.shelterGapMm),(2,100000,10000,65000,8500,12500));
    final cad=r.drawing!;
    final taper=cad.lines.where((l)=>l.layer=='LAYBY_EDGE').toList();
    expect(taper.length,3);
    expect((taper.first.start.x,taper.first.start.y,taper.first.end.x,taper.first.end.y),
      (500006000,2000008000,500010640,2000019520));
    expect((taper.last.end.x,taper.last.end.y),(500039000,2000052000));
    final mirror=generator.generate(layby(edits:{'bl_side':'right'})).drawing!;
    final right=mirror.lines.firstWhere((l)=>l.layer=='LAYBY_EDGE');
    expect((right.end.x,right.end.y),(500015760,2000015680));
    expect(cad.labels.where((l)=>l.layer=='LAYBY_BERTH').map((l)=>l.text),['B1','B2']);
    expect(cad.lines.where((l)=>l.layer=='LAYBY_SHELTER').length,4);
    expect(cad.toDxf(),contains('2 BERTH(S) / CH 10.000 TO 65.000 M / LEFT OF TRAVEL'));
  });

  test('accepts exact frontage and shelter connections and a single berth without a gap', () {
    final equal=generator.generate(layby(edits:{'bl_offset':45,'bl_shelter_len':29}));
    expect(equal.endMm,100000);
    expect(equal.shelterGapMm,2000);
    final one=generator.generate(layby(edits:{'bl_count':1,'bl_gap':0}));
    expect(one.issue,isNull);
    expect(one.endMm,47000);
  });

  test('invalid inputs block export and explain the reason', () {
    for(final (brief,message) in [
      (layby(type:'bus_terminal'),'Bus Stop'),
      (layby(edits:{'bl_edge':'0,0'}),'exactly two'),
      (layby(edits:{'bl_edge':'0,0;0,0'}),'positive length'),
      (layby(edits:{'bl_side':'centre'}),'lay-by side'),
      (layby(edits:{'bl_gap':0}),'positive gap'),
      (layby(edits:{'bl_offset':45.001}),'beyond the surveyed edge'),
      (layby(edits:{'bl_shelter_len':29.001}),'clear connection at both ends'),
      (layby(edits:{'bl_row':8.499}),'available roadside width'),
    ]) {
      final r=generator.generate(brief);
      expect(r.issue,contains(message));
      expect(r.drawing,isNull);
    }
  });

  testWidgets('bus stop wizard swaps parcel fields for the survey mode only after opt-in',(tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(950,1050));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(providers:[
      ChangeNotifierProvider(create:(_)=>ProjectProvider()),
      ChangeNotifierProvider(create:(_)=>NotificationProvider()),
    ],child:MaterialApp(home:Scaffold(body:Builder(builder:(context)=>TextButton(
      onPressed:()=>ProjectWizardScreen.open(context),child:const Text('New brief'),
    ))))));
    Future<void> tap(String label) async {
      final item=find.text(label).last;
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pumpAndSettle();
    }
    await tap('New brief');
    await tap('Infrastructure / Public Works');
    await tap('Transport infrastructure');
    await tap('Bus Stop');
    final plot=find.byKey(const ValueKey('Plot geometry (required)'));
    expect(plot,findsOneWidget);
    final mode=find.descendant(of:find.byKey(const ValueKey('bus_layby_mode')),
      matching:find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap('Surveyed lay-by: bus berths, boarding strip and shelter reserve');
    expect(plot,findsNothing);
    expect(find.byKey(const ValueKey('route_length')),findsNothing);
  });

  testWidgets('shows fit readout and removes DXF action on a failed brief',(tester) async {
    await tester.pumpWidget(MaterialApp(home:BusLaybyCadScreen(name:'Stop A',brief:layby())));
    expect(find.textContaining('Required roadside width 8.500 m'),findsOneWidget);
    expect(find.text('Share lay-by plan DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:BusLaybyCadScreen(key:const ValueKey('invalid'),
      name:'Stop A',brief:layby(edits:{'bl_row':8}))));
    expect(find.textContaining('available roadside width'),findsOneWidget);
    expect(find.text('Share lay-by plan DXF'),findsNothing);
  });
}
