import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/cold_rack_cad_screen.dart';
import 'package:architect_engine/services/cold_rack_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief chamber({Map<String,Object> edits=const {},String type='cold_storage'})=>ProjectBrief(
  floorCount:1,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'industrial',subcategoryId:'logistics',
    typeId:type,configurationId:'rack_storage',plotShapeId:'rectangular'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'cold_storage_racks','clear_height':5.8,'pallet_positions':72,'chambers':1,
    'cr_pairs':1,'cr_bays':3,'cr_slots':2,'cr_levels':3,'cr_rack_depth':1.2,'cr_bay':2.6,'cr_upright':.1,
    'cr_pallet_w':1.1,'cr_pallet_d':1.1,'cr_pallet_h':1.4,'cr_gap':.1,'cr_pitch_z':1.8,'cr_top_clear':.8,
    'cr_flue':.3,'cr_aisle':3.2,'cr_wall_gap':.3,'cr_front':3,'cr_rear':2,'cr_door':2.4,'cr_wall':.2,
    'cr_west':3,'cr_south':4,...edits,
  }));

void main() {
  const widthFt=20/.3048,depthFt=24/.3048;
  ColdRackCadResult run(ProjectBrief b)=>ColdRackCadGenerator().generate(b,widthFt:widthFt,depthFt:depthFt);

  test('opt-in survives serialization and positions count bays, slots and all levels', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o)=>o.id),isNot(contains('cold_storage_racks')));
    expect(cadOutputOptions(warehouseLoading:false,coldRacks:true).options.map((o)=>o.id),contains('cold_storage_racks'));
    final saved=ProjectBrief.fromMap(chamber().toMap())!;
    expect(ColdRackCadGenerator.requested(saved),isTrue);
    final r=run(saved);
    expect(r.issue,isNull);
    expect((r.rows,r.bays.length,r.positions,r.widthMm,r.depthMm,r.topLoadMm,r.overheadMm),(4,12,72,12500,13600,5000,800));
    final first=r.bays.first,last=r.bays.last;
    expect((first.row,first.bay,first.westMm,first.southMm,first.facing),(1,1,3500,7300,'east'));
    expect((last.row,last.bay,last.westMm,last.southMm,last.facing),(4,3,13800,12700,'west'));
    final csv=r.toCsv()!.trimRight().split('\r\n');
    expect(csv.length,13);
    expect(csv[1],'1,1,3.500,7.300,east,2,3,6');
    expect(csv.last,'4,3,13.800,12.700,west,2,3,6');
    expect(r.drawing!.toDxf(),contains('72 NOMINAL POSITIONS'));
  });

  test('shows two unblocked aisles, actual flue, 24 plan loads and aligned opening', () {
    final c=run(chamber(type:'freezer_warehouse')).drawing!;
    final left=c.lines.where((l)=>l.layer=='COLD_RACK').map((l)=>l.start.x).toSet();
    expect(left,containsAll([3500,4700,7900,9100,9400,10600,13800,15000]));
    final flue=c.lines.singleWhere((l)=>l.layer=='COLD_FLUE');
    expect((flue.start.x,flue.start.y,flue.end.y),(9250,7200,15400));
    expect(c.lines.where((l)=>l.layer=='COLD_LOAD').length,96);
    final door=c.lines.where((l)=>l.layer=='COLD_WALL' && l.start.y==4000 && l.end.y==4000);
    expect(door.map((l)=>(l.start.x,l.end.x)),[(3000,5100),(7500,15500)]);
    expect(c.lines.singleWhere((l)=>l.layer=='COLD_ROUTE').start.x,6300);
  });

  test('exact plot setbacks fit and optional single level with no internal pair works', () {
    final exact=run(chamber(edits:{'left_setback':3,'right_setback':4.5,'front_setback':4,'rear_setback':6.4}));
    expect(exact.issue,isNull);
    final two=run(chamber(edits:{'cr_pairs':0,'cr_flue':0,'cr_levels':1,'cr_pitch_z':0,'pallet_positions':12}));
    expect((two.issue,two.rows,two.positions,two.topLoadMm),(null,2,12,1400));
    expect(two.drawing!.lines.where((l)=>l.layer=='COLD_FLUE'),isEmpty);
  });

  test('rejects incompatible chambers, static fit, load height, plot and target failures', () {
    for(final (brief,message) in [
      (chamber(type:'general_warehouse'),'Select Cold Storage'),
      (chamber(edits:{'chambers':2}),'single-temperature rack chamber'),
      (chamber(edits:{'cr_bay':2.499}),'without overhang'),
      (chamber(edits:{'cr_pallet_d':1.201}),'without overhang'),
      (chamber(edits:{'cr_pitch_z':1.4}),'pitch greater'),
      (chamber(edits:{'clear_height':5.799}),'Facility clear height'),
      (chamber(edits:{'cr_flue':0}),'positive separation'),
      (chamber(edits:{'cr_door':3.201}),'no wider than the clear aisle'),
      (chamber(edits:{'rear_setback':6.401}),'rear plot edge'),
      (chamber(edits:{'coverage_limit':35}),'site coverage'),
      (chamber(edits:{'pallet_positions':73}),'not meet the supplied pallet'),
    ]) {
      final r=run(brief);
      expect(r.issue,contains(message));
      expect(r.drawing,isNull);
      expect(r.toCsv(),isNull);
    }
  });

  testWidgets('preview reports nominal count and withholds both outputs for invalid fit',(tester) async {
    await tester.pumpWidget(MaterialApp(home:ColdRackCadScreen(name:'Chamber',brief:chamber(),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('72 nominal pallet positions'),findsOneWidget);
    expect(find.text('Share rack plan DXF'),findsOneWidget);
    expect(find.text('Share rack bay CSV'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:ColdRackCadScreen(key:const ValueKey('failed'),name:'Chamber',
      brief:chamber(edits:{'pallet_positions':73}),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('pallet position target'),findsOneWidget);
    expect(find.text('Share rack plan DXF'),findsNothing);
    expect(find.text('Share rack bay CSV'),findsNothing);
  });
}

