import 'dart:math' as math;

import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/angled_parking_cad_screen.dart';
import 'package:architect_engine/services/angled_parking_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief parkingLot({Map<String,Object> edits=const {},String type='public_parking'})=>ProjectBrief(
  floorCount:null,features:const [],parking:ProjectParking.none,
  taxonomy:TaxonomySelection(version:projectTaxonomyVersion,categoryId:'institutional',subcategoryId:'sports',
    typeId:type,configurationId:'outdoor',plotShapeId:'rectangular'),
  requirements:ProjectRequirementsSnapshot(version:requirementsSchemaVersion,answers:{
    'cad_output':'angled_surface_parking','ap_angle':'60','ap_spaces':8,'ap_width':2.5,'ap_length':5,
    'ap_drive':6,'ap_side':1.5,'ap_head_s':3,'ap_head_n':4,'ap_west':3,'ap_south':4,...edits,
  }));

void main() {
  const widthFt=28/.3048,depthFt=45/.3048;
  AngledParkingCadResult run(ProjectBrief b)=>AngledParkingCadGenerator().generate(b,widthFt:widthFt,depthFt:depthFt);

  test('opt-in round trips and projects normal width, full depth, and end skew without approximation', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o)=>o.id),isNot(contains('angled_surface_parking')));
    expect(cadOutputOptions(warehouseLoading:false,angledParking:true).options.map((o)=>o.id),contains('angled_surface_parking'));
    final saved=ProjectBrief.fromMap(parkingLot().toMap())!;
    expect(AngledParkingCadGenerator.requested(saved),isTrue);
    final r=run(saved),root3=math.sqrt(3);
    expect(r.issue,isNull);
    expect((r.spaces,r.angle),(16,60));
    expect(r.pitchMm,closeTo(5000/root3,1e-8));
    expect(r.rowDepthMm,closeTo(2500*root3+1250,1e-8));
    expect(r.depthMm,closeTo(7000+8*r.pitchMm+r.rowDepthMm/root3,1e-8));
    expect(r.widthMm,closeTo(9000+2*r.rowDepthMm,1e-8));
    expect(r.drawing!.toDxf(),contains('16 STALLS / 60 DEG / 2.887 M PITCH / 5.580 M ROW DEPTH'));
  });

  test('static fit rectangles are orthogonal and contained between the actual markings on both sides', () {
    for(final degrees in [30,45,60]) {
      final r=run(parkingLot(edits:{'ap_spaces':4,'ap_angle':'$degrees'})), c=r.drawing!;
      final fit=c.lines.where((l)=>l.layer=='ANGLE_PARK_FIT').toList();
      expect(fit.length,32);
      final mid=3000+r.widthMm/2;
      final rad=degrees*math.pi/180,s=math.sin(rad),cos=math.cos(rad);
      for(var i=0;i<8;i++) {
        final a=fit[i*4],b=fit[i*4+1];
        final u=(a.end.x-a.start.x,a.end.y-a.start.y),v=(b.end.x-b.start.x,b.end.y-b.start.y);
        expect(u.$1*u.$1+u.$2*u.$2,closeTo(5000*5000,1e-6));
        expect(v.$1*v.$1+v.$2*v.$2,closeTo(2500*2500,1e-6));
        expect(u.$1*v.$1+u.$2*v.$2,closeTo(0,1e-6));
        for(final l in fit.skip(i*4).take(4)) {
          final dx=(l.start.x-mid).abs()-3000, dy=l.start.y-7000-(i%4)*r.pitchMm;
          expect(dx,inInclusiveRange(-1e-8,r.rowDepthMm+1e-8));
          expect(s*dy-cos*dx,inInclusiveRange(-1e-8,2500+1e-8));
        }
      }
    }
  });

  test('perpendicular preset has no skew or duplicate guides; exact setbacks and through aisle fit', () {
    final r=run(parkingLot(edits:{'ap_angle':'90','left_setback':3,'right_setback':6,'front_setback':4,'rear_setback':14}));
    expect(r.issue,isNull);
    expect((r.rowDepthMm,r.widthMm,r.depthMm),(5000,19000,27000));
    final c=r.drawing!;
    expect(c.lines.where((l)=>l.layer=='ANGLE_PARK_FIT'),isEmpty);
    final aisle=c.lines.where((l)=>l.layer=='ANGLE_PARK_DRIVE');
    expect(aisle.map((l)=>(l.start.x,l.start.y,l.end.y)),[(9500,0,45000),(15500,0,45000)]);
    final front=c.lines.where((l)=>l.layer=='ANGLE_PARK_LIMIT' && l.start.y==4000 && l.end.y==4000);
    expect(front.map((l)=>(l.start.x,l.end.x)),[(3000,9500),(15500,22000)]);
  });

  test('rejects invalid presets, counts and actual angled footprint shortfalls', () {
    for(final (brief,message) in [
      (parkingLot(type:'public_park'),'Select Public Parking'),
      (parkingLot(edits:{'ap_angle':'75'}),'Enter measured'),
      (parkingLot(edits:{'ap_spaces':31}),'Enter measured'),
      (parkingLot(edits:{'ap_angle':'30'}),'rear plot edge'),
      (parkingLot(edits:{'right_setback':4.84}),'right plot edge'),
      (parkingLot(edits:{'front_setback':4.001}),'front plot edge'),
    ]) {
      final r=run(brief);
      expect(r.issue,contains(message));
      expect(r.drawing,isNull);
    }
  });

  testWidgets('preview shows stall count and withholds DXF if the angled layout does not fit',(tester) async {
    await tester.pumpWidget(MaterialApp(home:AngledParkingCadScreen(name:'Surface lot',brief:parkingLot(),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('16 stalls at 60°'),findsOneWidget);
    expect(find.text('Share parking plan DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:AngledParkingCadScreen(key:const ValueKey('failed'),name:'Surface lot',
      brief:parkingLot(edits:{'ap_angle':'30'}),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('rear plot edge'),findsOneWidget);
    expect(find.text('Share parking plan DXF'),findsNothing);
  });
}
