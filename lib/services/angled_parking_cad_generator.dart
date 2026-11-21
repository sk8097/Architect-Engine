import 'dart:math' as math;

import '../data/angled_parking_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class AngledParkingCadResult {
  const AngledParkingCadResult({this.drawing,this.issue,this.spaces=0,this.angle=0,this.pitchMm=0,
    this.rowDepthMm=0,this.widthMm=0,this.depthMm=0});
  final FloorPlanCad? drawing;
  final String? issue;
  final int spaces,angle;
  final double pitchMm,rowDepthMm,widthMm,depthMm;
}

/// Symmetric rows of angled parallelogram markings. Thin auxiliary rectangles
/// demonstrate static clear footprint fit, not swept paths or vehicle size.
class AngledParkingCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='angled_surface_parking';

  AngledParkingCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt}) {
    AngledParkingCadResult stop(String issue)=>AngledParkingCadResult(issue:issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !angledParkingCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Public Parking and save the measured surface parking brief.');
    }
    if(!const {null,'outdoor'}.contains(sel.configurationId) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        (brief.floorCount??0)!=0 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor parking layout without buildings or separate Parking and Space selections.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a=snap.answers;
    int? mm(Object? v,{bool zero=false,int max=300}) {
      if(v is! num || !v.isFinite || v<(zero?0:.001) || v>max) return null;
      return (v*1000).round();
    }
    final pw=mm(widthFt*.3048,max:2000),pd=mm(depthFt*.3048,max:2000),count=a['ap_spaces'];
    final angle=switch(a['ap_angle']){'30'=>30,'45'=>45,'60'=>60,'90'=>90,_=>null};
    final w=mm(a['ap_width'],max:30),l=mm(a['ap_length'],max:30),drive=mm(a['ap_drive']),side=mm(a['ap_side']);
    final headS=mm(a['ap_head_s']),headN=mm(a['ap_head_n']);
    final west=mm(a['ap_west'],zero:true,max:2000),south=mm(a['ap_south'],zero:true,max:2000);
    if(pw==null || pd==null || angle==null || count is! int || count<1 || count>30 || w==null || l==null ||
        drive==null || side==null || headS==null || headN==null || west==null || south==null ||
        (sel.plotShapeId=='square' && pw!=pd)) return stop('Enter measured plot, angle, rectangular footprint, aisle and edge reserves.');
    final rad=angle*math.pi/180, s=angle==90?1.0:math.sin(rad),c=angle==90?0.0:math.cos(rad);
    final pitch=w/s,rowDepth=l*s+w*c,skew=rowDepth*c/s;
    final width=drive+2*(rowDepth+side),depth=headS+count*pitch+skew+headN;
    for(final (edge,clear) in [('left',west),('right',pw-west-width),('front',south),('rear',pd-south-depth)]) {
      final raw=a['${edge}_setback'],min=raw==null?0:mm(raw,zero:true,max:2000);
      if(min==null || clear<min-1e-6) return stop('The parking and clear reserves conflict with the $edge plot edge or supplied setback.');
    }
    final lines=<CadLine>[],labels=<CadLabel>[];
    void line(String layer,num x,num y,num ex,num ey) {
      if((x-ex).abs()>1e-6 || (y-ey).abs()>1e-6) lines.add(CadLine(layer,CadPoint(x,y),CadPoint(ex,ey)));
    }
    void outline(String layer,List<CadPoint> points) {
      for(var i=0;i<points.length;i++) {
        final a=points[i],b=points[(i+1)%points.length];
        line(layer,a.x,a.y,b.x,b.y);
      }
    }
    outline('ANGLE_PARK_PLOT',[const CadPoint(0,0),CadPoint(pw,0),CadPoint(pw,pd),CadPoint(0,pd)]);
    final cx=west+width/2,y0=south+headS,end=south+depth;
    final aisleL=cx-drive/2,aisleR=cx+drive/2;
    // Leave the through lanes open at both ends of the envelope. The plot
    // polygon remains a parcel reference, not a drawn fence or kerb.
    for(final y in [south,end]) {
      line('ANGLE_PARK_LIMIT',west,y,aisleL,y);
      line('ANGLE_PARK_LIMIT',aisleR,y,west+width,y);
    }
    line('ANGLE_PARK_LIMIT',west,south,west,end);line('ANGLE_PARK_LIMIT',west+width,south,west+width,end);
    line('ANGLE_PARK_DRIVE',aisleL,0,aisleL,pd);line('ANGLE_PARK_DRIVE',aisleR,0,aisleR,pd);
    final t=(math.max(pw,pd)/85).clamp(40,6000).toDouble();
    for(final (prefix,sign) in [('W',-1),('E',1)]) {
      final x0=cx+sign*drive/2;
      CadPoint point(num offset,num along)=>CadPoint(x0+sign*offset,y0+along);
      for(var i=0;i<=count;i++) {
        final k=i*pitch;
        final a=point(0,k),b=point(rowDepth,k+skew);
        line('ANGLE_PARK_MARK',a.x,a.y,b.x,b.y);
        if(i==count) continue;
        // u=(sin,cos), v=(-cos,sin). Shift the rectangle by width*cos
        // in x and the matching cotangent offset along the front stripe.
        CadPoint rect(num len,num across) {
          final offset=w*c+s*len-c*across;
          return point(offset,k+w*c*c/s+c*len+s*across);
        }
        // In a 90-degree stall the static rectangle and marking coincide.
        // The mark layer already defines its edges in that case.
        if(angle!=90) outline('ANGLE_PARK_FIT',[rect(0,0),rect(l,0),rect(l,w),rect(0,w)]);
        labels.add(CadLabel('ANGLE_PARK_MARK',rect(l/2,w/2),'$prefix${i+1}',math.min(t*.7,w*.27)));
      }
      final toeA=point(rowDepth,skew),toeB=point(rowDepth,skew+count*pitch);
      line('ANGLE_PARK_MARK',toeA.x,toeA.y,toeB.x,toeB.y);
    }
    final arrow=math.min(drive*.45,depth*.11),at=south+depth*.51;
    line('ANGLE_PARK_FLOW',cx,at-arrow,cx,at);
    line('ANGLE_PARK_FLOW',cx-arrow*.32,at-arrow*.32,cx,at);line('ANGLE_PARK_FLOW',cx+arrow*.32,at-arrow*.32,cx,at);
    final nx=pw+2*t;
    line('ANNOTATIONS',nx,pd-t*1.7,nx,pd);
    line('ANNOTATIONS',nx-t*.4,pd-t*.7,nx,pd);line('ANNOTATIONS',nx+t*.4,pd-t*.7,nx,pd);
    String m(num mm)=>(mm/1000).toStringAsFixed(3);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(nx,pd+t),'N',t*.7),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*5.6),'ANGLED SURFACE PARKING / LOCAL MM',t),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*4.2),'${2*count} STALLS / $angle DEG / ${m(pitch)} M PITCH / ${m(rowDepth)} M ROW DEPTH',t*.65),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*2.8),'SOUTH ENTRY / NORTH EXIT / ${m(drive)} M STRAIGHT THROUGH AISLE',t*.65),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*1.4),'STATIC FOOTPRINT ONLY / NO TURNING OR ACCESS APPROVAL',t*.62),
    ]);
    final bounds=PlanRect(math.min(-2*t,pw/2-28*t).floor(),(-2*t).floor(),
      math.max(nx+3*t,pw/2+28*t).ceil(),(pd+7.2*t).ceil());
    return AngledParkingCadResult(drawing:FloorPlanCad.fromEntities(bounds:bounds,lines:lines,labels:labels),spaces:2*count,
      angle:angle,pitchMm:pitch,rowDepthMm:rowDepth,widthMm:width,depthMm:depth);
  }
}
