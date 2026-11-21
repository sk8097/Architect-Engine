import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/rainwater_cad_screen.dart';
import 'package:architect_engine/services/rainwater_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief harvest({Map<String,Object> edits=const {},String type='rainwater_harvesting_system'}) => ProjectBrief(
  floorCount:1,parking:ProjectParking.none,features:const [],taxonomy:TaxonomySelection(version:projectTaxonomyVersion,
    categoryId:'infrastructure',subcategoryId:'water',typeId:type,configurationId:'storage',plotShapeId:'rectangular'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'rainwater_roof_tanks','rw_roof_width':20,'rw_roof_depth':16,'rw_roof_west':3,'rw_roof_south':5,
    'rw_tank_west':26,'rw_tank_south':8,'rw_count':2,'rw_outer':2.2,'rw_inner':2,'rw_useful':1.5,'rw_service':.8,
    'rw_rain':42,'rw_coefficient':.8,'rw_flush':400,'rw_target':9000,...edits,
  }));

void main() {
  RainwaterCadResult run(ProjectBrief brief) => RainwaterCadGenerator().generate(brief,widthFt:40/.3048,depthFt:30/.3048);

  test('event volumes use horizontal area, inside diameter, useful depth and both tanks', () {
    final saved=ProjectBrief.fromMap(harvest().toMap())!;
    expect(RainwaterCadGenerator.requested(saved),isTrue);
    expect(cadOutputOptions(warehouseLoading:false,rainwater:true).options.map((o)=>o.id),contains('rainwater_roof_tanks'));
    final r=run(saved), capacity=3000*math.pi;
    expect(r.issue,isNull);
    expect((r.roofM2,r.runoffL,r.divertedL,r.availableL),(320,10752,400,10352));
    expect(r.capacityL,closeTo(capacity,1e-8));
    expect(r.storedL,closeTo(capacity,1e-8));
    expect(r.excessL,closeTo(10352-capacity,1e-8));
    final cad=r.drawing!;
    final outer=cad.arcs.where((a)=>a.layer=='RAIN_TANK').toList();
    final inner=cad.arcs.where((a)=>a.layer=='RAIN_TANK_INNER').toList();
    expect((outer.length,inner.length),(4,4));
    expect(outer.map((a)=>a.radius),everyElement(1100));
    expect(inner.map((a)=>a.radius),everyElement(1000));
    expect((outer.first.center.x,outer.first.center.y,outer.last.center.x,outer.last.center.y),(27900,9900,30900,9900));
    final service=cad.lines.firstWhere((l)=>l.layer=='RAIN_SERVICE');
    expect((service.start.x,service.start.y,service.end.x,service.end.y),(26000,8000,32800,8000));
    expect(cad.toDxf(),contains('USABLE CAPACITY 9424.778 L / EXCESS 927.222 L IF STARTING EMPTY'));
  });

  test('first flush is capped by runoff and does not affect tank capacity', () {
    final small=run(harvest(edits:{'rw_rain':1}));
    expect((small.runoffL,small.divertedL,small.availableL,small.storedL,small.excessL),(256,256,0,0,0));
    final retained=run(harvest(edits:{'rw_rain':10}));
    expect((retained.availableL,retained.storedL,retained.excessL),(2160,2160,0));
    expect(retained.capacityL,small.capacityL);
    expect(run(harvest(edits:{'rw_coefficient':0})).storedL,0);
  });

  test('diameter, capacity, roof overlap and setbacks block the file', () {
    for(final (brief,issue) in [
      (harvest(type:'water_tank'),'Select Water'),
      (harvest(edits:{'rw_inner':2.2}),'inside tank diameter'),
      (harvest(edits:{'rw_count':1}),'below the supplied'),
      (harvest(edits:{'rw_tank_west':21}),'overlaps the roof'),
      (harvest(edits:{'right_setback':7.201}),'tank bank and its clear service envelope'),
      (harvest(edits:{'left_setback':3.001}),'roof catchment lies outside'),
      (harvest(edits:{'rw_coefficient':1.1}),'measured catchment'),
    ]) {
      final r=run(brief);
      expect(r.issue,contains(issue));
      expect(r.drawing,isNull);
    }
  });

  testWidgets('preview shows event water balance and blocks an undersized bank',(tester) async {
    await tester.pumpWidget(MaterialApp(home:RainwaterCadScreen(name:'Tank bank',brief:harvest(),widthFt:132,depthFt:99)));
    expect(find.text('Usable capacity 9424.778 L'),findsOneWidget);
    expect(find.text('Starting empty: stored 9424.778 L · Excess 927.222 L'),findsOneWidget);
    expect(find.text('Share rainwater plan DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:RainwaterCadScreen(key:const ValueKey('blocked'),name:'Tank bank',
      brief:harvest(edits:{'rw_target':9500}),widthFt:132,depthFt:99)));
    expect(find.textContaining('below the supplied'),findsOneWidget);
    expect(find.text('Share rainwater plan DXF'),findsNothing);
  });
}
