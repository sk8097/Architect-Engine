import 'dart:math' as math;

import '../data/park_loop_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class ParkLoopCadResult {
  const ParkLoopCadResult({this.drawing,this.issue,this.lapM=0,this.loopM2=0,this.entryM2=0,
    this.outerWidthMm=0,this.outerDepthMm=0});
  final FloorPlanCad? drawing;
  final String? issue;
  final double lapM,loopM2,entryM2;
  final int outerWidthMm,outerDepthMm;
}

/// Parallel offsets of a rounded rectangle. The paths are measured plan areas,
/// not a design for graded, drained or accessible surfaces.
class ParkLoopCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='park_measured_loop';

  ParkLoopCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt}) {
    ParkLoopCadResult stop(String issue)=>ParkLoopCadResult(issue:issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !parkLoopCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Public Park and save the current measured walking-loop brief.');
    }
    final expected=sel.categoryId=='infrastructure'?'public_open_space':'outdoor';
    if((sel.configurationId!=null && sel.configurationId!=expected) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        (brief.floorCount??0)!=0 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one open public park without buildings, parking or separate Space selections.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a=snap.answers;
    int? mm(Object? v,{num min=.001,int max=300}) {
      if(v is! num || !v.isFinite || v<min || v>max) return null;
      return (v*1000).round();
    }
    final pw=mm(widthFt*.3048,max:2000),pd=mm(depthFt*.3048,max:2000);
    final w=mm(a['pl_width']),d=mm(a['pl_depth']),r=mm(a['pl_radius']),path=mm(a['pl_path']);
    final west=mm(a['pl_west'],min:0,max:2000),south=mm(a['pl_south'],max:2000);
    final entry=mm(a['pl_entry']),shift=mm(a['pl_shift'],min:-150,max:150);
    final lawnW=mm(a['pl_lawn_w']),lawnD=mm(a['pl_lawn_d']),gap=mm(a['pl_lawn_gap'],min:0);
    if(pw==null || pd==null || w==null || d==null || r==null || path==null || west==null || south==null ||
        entry==null || shift==null || lawnW==null || lawnD==null || gap==null || (sel.plotShapeId=='square' && pw!=pd)) {
      return stop('Enter measured plot, centreline, radius, path, approach and lawn dimensions.');
    }
    if(2*r>=math.min(w,d)) return stop('The centreline radius must leave positive straight segments on all four sides.');
    final half=path/2,innerR=r-half;
    if(innerR<=0) return stop('The corner radius must be larger than half the path width so the inner edge retains a positive radius.');
    if(entry>path) return stop('The approach width must not exceed the loop path width.');
    final straightW=w-2*r;
    if(2*shift.abs()+entry>straightW) return stop('The entire approach opening must land on the south straight, between its two tangent points.');
    final envW=w+path,envD=d+path;
    for(final (edge,clear) in [('left',west),('right',pw-west-envW),('front',south),('rear',pd-south-envD)]) {
      final raw=a['${edge}_setback'],min=raw==null?0:mm(raw,min:0,max:2000);
      if(min==null || clear<min) return stop('The loop envelope conflicts with the $edge plot edge or supplied setback.');
    }
    // Erode the inner rounded rectangle by the supplied clearance. If the
    // clearance consumes the inner radius, its inward offset has square corners.
    final usableX=w/2-half-gap,usableY=d/2-half-gap;
    final usableR=math.max(0.0,innerR-gap);
    final lx=lawnW/2,ly=lawnD/2;
    final vx=math.max(0.0,lx-(usableX-usableR)),vy=math.max(0.0,ly-(usableY-usableR));
    if(lx>usableX || ly>usableY || vx*vx+vy*vy>usableR*usableR+1e-6) {
      return stop('The centred lawn reserve and clearance do not fit inside the loop, including its rounded corners.');
    }

    final cx=west+envW/2,cy=south+envD/2;
    final x=w/2-r,y=d/2-r;
    final lines=<CadLine>[],arcs=<CadArc>[],labels=<CadLabel>[];
    CadPoint p(num east,num north)=>CadPoint(cx+east,cy+north);
    void line(String layer,num east,num north,num ex,num ny) {
      if(east!=ex || north!=ny) lines.add(CadLine(layer,p(east,north),p(ex,ny)));
    }
    void box(String layer,num east,num north,num ex,num ny) {
      line(layer,east,north,ex,north);line(layer,ex,north,ex,ny);
      line(layer,ex,ny,east,ny);line(layer,east,ny,east,north);
    }
    final entryL=shift-entry/2,entryR=shift+entry/2;
    void outline(String layer,num radius,{bool approach=false}) {
      final north=y+radius,east=x+radius;
      line(layer,-x,north,x,north);line(layer,east,-y,east,y);line(layer,-east,y,-east,-y);
      if(approach) {
        line(layer,-x,-north,entryL,-north);line(layer,entryR,-north,x,-north);
      } else {
        line(layer,-x,-north,x,-north);
      }
      arcs.addAll([
        CadArc(layer,p(x,y),radius,0,90),CadArc(layer,p(-x,y),radius,90,180),
        CadArc(layer,p(-x,-y),radius,180,270),CadArc(layer,p(x,-y),radius,270,360),
      ]);
    }
    box('PARK_LOOP_PLOT',-cx,-cy,pw-cx,pd-cy);
    outline('PARK_LOOP_OUTER',r+half,approach:true);
    outline('PARK_LOOP_AXIS',r);
    outline('PARK_LOOP_INNER',innerR);
    line('PARK_LOOP_ENTRY',entryL,-cy,entryL,-d/2-half);
    line('PARK_LOOP_ENTRY',entryR,-cy,entryR,-d/2-half);
    box('PARK_LOOP_LAWN',-lx,-ly,lx,ly);
    final lap=(2*(w+d-4*r)+2*math.pi*r)/1000;
    final area=lap*(path/1000),approach=entry*south/1e6;
    final t=(math.max(pw,pd)/85).clamp(35,6000).toDouble();
    final nx=pw+2*t;
    line('ANNOTATIONS',nx-cx,pd-cy-t*1.7,nx-cx,pd-cy);
    line('ANNOTATIONS',nx-cx-t*.4,pd-cy-t*.7,nx-cx,pd-cy);
    line('ANNOTATIONS',nx-cx+t*.4,pd-cy-t*.7,nx-cx,pd-cy);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(nx,pd+t),'N',t*.7),
      CadLabel('PARK_LOOP_LAWN',p(0,0),'LAWN RESERVE',math.min(t*.8,math.min(lawnW/12,lawnD/3))),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*5.3),'PUBLIC PARK WALKING LOOP / LOCAL MM',t),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*3.9),'CENTRELINE LAP ${lap.toStringAsFixed(3)} M / LOOP ${area.toStringAsFixed(3)} M2',t*.67),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*2.5),'APPROACH ${approach.toStringAsFixed(3)} M2 / AREA EXCLUDES LAWN',t*.67),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*1.1),'PLAN GEOMETRY ONLY / NOT A CERTIFIED COURSE',t*.61),
    ]);
    final bounds=PlanRect(math.min(-2*t,pw/2-26*t).floor(),(-2*t).floor(),
      math.max(nx+t*3,pw/2+26*t).ceil(),(pd+7*t).ceil());
    return ParkLoopCadResult(drawing:FloorPlanCad.fromEntities(bounds:bounds,lines:lines,arcs:arcs,labels:labels),
      lapM:lap,loopM2:area,entryM2:approach,outerWidthMm:envW,outerDepthMm:envD);
  }
}
