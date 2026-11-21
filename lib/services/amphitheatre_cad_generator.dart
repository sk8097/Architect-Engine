import 'dart:math' as math;

import '../data/amphitheatre_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class AmphitheatreCadResult {
  const AmphitheatreCadResult({this.plan,this.section,this.issue,this.rows=0,this.placesPerRow=0,
    this.envelopeWidthMm=0,this.envelopeDepthMm=0,this.clearanceMm=0,this.criticalRow=0});
  final FloorPlanCad? plan,section;
  final String? issue;
  final int rows,placesPerRow,envelopeWidthMm,envelopeDepthMm,criticalRow;
  final double clearanceMm;
  int get places=>rows*placesPerRow;
}

/// Straight stepped bank with a single centreline sightline target at the
/// audience-facing stage edge. Nominal places are not an occupancy count.
class AmphitheatreCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output']=='outdoor_tiered_amphitheatre';

  AmphitheatreCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt}) {
    AmphitheatreCadResult stop(String issue)=>AmphitheatreCadResult(issue:issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !amphitheatreCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Theatre, Auditorium or Performing Arts Centre and save the measured outdoor brief.');
    }
    if(sel.configurationId!=null || !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        (brief.floorCount??0)!=0 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor amphitheatre. Leave the indoor hall arrangement, building floors, parking and separate Space selections empty.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a=snap.answers;
    int? mm(Object? v,{bool zero=false,int max=100}) {
      if(v is! num || !v.isFinite || v<(zero?0:.001) || v>max) return null;
      return (v*1000).round();
    }
    final pw=mm(widthFt*.3048,max:2000),pd=mm(depthFt*.3048,max:2000),rows=a['at_rows'];
    final width=mm(a['at_width']),tread=mm(a['at_tread']),rise=mm(a['at_rise'],max:5),seat=mm(a['at_seat'],max:5);
    final margin=mm(a['at_margin'],zero:true),side=mm(a['at_side']),rear=mm(a['at_rear']);
    final sw=mm(a['at_stage_width']),sd=mm(a['at_stage_depth']),stage=mm(a['at_stage_level'],zero:true,max:20);
    final gap=mm(a['at_gap']),eye=mm(a['at_eye'],max:5),need=mm(a['at_clearance'],zero:true,max:5);
    final west=mm(a['at_west'],zero:true,max:2000),south=mm(a['at_south'],zero:true,max:2000);
    if(pw==null || pd==null || rows is! int || rows<2 || rows>28 || width==null || tread==null || rise==null || seat==null ||
        margin==null || side==null || rear==null || sw==null || sd==null || stage==null || gap==null || eye==null ||
        need==null || west==null || south==null || (sel.plotShapeId=='square' && pw!=pd)) {
      return stop('Enter measured stage, seating, eye height, sightline and plot dimensions.');
    }
    final perRow=(width-2*margin)~/seat;
    if(perRow<1 || perRow>80) return stop('The usable seating width must fit between 1 and 80 complete nominal places per row.');
    final first=sd+gap,bankDepth=rows*tread;
    final envW=math.max(width+2*side,sw),envD=first+bankDepth+rear;
    for(final (edge,clear) in [('left',west),('right',pw-west-envW),('front',south),('rear',pd-south-envD)]) {
      final raw=a['${edge}_setback'],min=raw==null?0:mm(raw,zero:true,max:2000);
      if(min==null || clear<min) return stop('The stage, tiers and reserves conflict with the $edge plot edge or supplied setback.');
    }
    double eyeX(int i)=>first+(i+.5)*tread;
    int eyeZ(int i)=>i*rise+eye;
    double rayZ(int i,num x)=>stage+(eyeZ(i)-stage)*(x-sd)/(eyeX(i)-sd);
    var worst=double.infinity,critical=1;
    for(var i=0;i<rows;i++) {
      // Check real tread before each eye. At the opposite end of every earlier
      // tread the next front is higher, so checking that next front suffices.
      for(var j=0;j<=i;j++) {
        if(rayZ(i,first+j*tread)<j*rise-1e-8) {
          return stop('The centreline sightline from row ${i+1} intersects a seating tier.');
        }
      }
      if(i==0) continue;
      final c=rayZ(i,eyeX(i-1))-eyeZ(i-1);
      if(c<worst) {worst=c;critical=i;}
    }
    String m(num v)=>(v/1000).toStringAsFixed(3);
    if(worst<need-1e-8) {
      return stop('Row ${critical+1} clears the preceding eye by ${worst.toStringAsFixed(2)} mm, below the supplied $need mm minimum.');
    }

    final planLines=<CadLine>[], planLabels=<CadLabel>[], sectionLines=<CadLine>[], sectionLabels=<CadLabel>[];
    void line(List<CadLine> dest,String layer,num x,num y,num ex,num ey) {
      if(x!=ex || y!=ey) dest.add(CadLine(layer,CadPoint(x,y),CadPoint(ex,ey)));
    }
    void pl(String layer,num x,num y,num ex,num ey)=>line(planLines,layer,x,y,ex,ey);
    void sl(String layer,num x,num y,num ex,num ey)=>line(sectionLines,layer,x,y,ex,ey);
    void box(String layer,num x,num y,num ex,num ey) {
      pl(layer,x,y,ex,y);pl(layer,ex,y,ex,ey);pl(layer,ex,ey,x,ey);pl(layer,x,ey,x,y);
    }
    final cx=west+envW/2, bankL=cx-width/2,bankR=cx+width/2,y=south+first;
    final stL=cx-sw/2,stR=cx+sw/2;
    box('AMPH_PLOT',0,0,pw,pd);
    box('AMPH_STAGE',stL,south,stR,south+sd);
    final reserveL=bankL-side,reserveR=bankR+side,reserveEnd=south+envD;
    pl('AMPH_RESERVES',bankL,y,reserveL,y);
    pl('AMPH_RESERVES',reserveL,y,reserveL,reserveEnd);
    pl('AMPH_RESERVES',reserveL,reserveEnd,reserveR,reserveEnd);
    pl('AMPH_RESERVES',reserveR,reserveEnd,reserveR,y);
    pl('AMPH_RESERVES',reserveR,y,bankR,y);
    box('AMPH_TIERS',bankL,y,bankR,y+bankDepth);
    for(var i=1;i<rows;i++) pl('AMPH_TIERS',bankL,y+i*tread,bankR,y+i*tread);
    final seatsL=cx-perRow*seat/2;
    for(var i=0;i<rows;i++) {
      final rowY=y+(i+.5)*tread;
      for(var j=0;j<perRow;j++) {
        final x=seatsL+(j+.5)*seat,half=math.min(seat,tread)*.15;
        pl('AMPH_PLACES',x-half,rowY,x+half,rowY);
      }
    }
    final pt=(math.max(pw,pd)/82).clamp(40,6000).toDouble();
    final ax=pw+2*pt;
    pl('ANNOTATIONS',ax,pd-pt*1.7,ax,pd);pl('ANNOTATIONS',ax-pt*.4,pd-pt*.7,ax,pd);pl('ANNOTATIONS',ax+pt*.4,pd-pt*.7,ax,pd);
    planLabels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(ax,pd+pt),'N',pt*.7),
      CadLabel('AMPH_STAGE',CadPoint(cx,south+sd/2),'STAGE',math.min(pt,math.min(sw/6,sd/2))),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+pt*5.3),'OUTDOOR AMPHITHEATRE PLAN / LOCAL MM',pt),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+pt*3.9),'$rows ROWS x $perRow NOMINAL PLACES / ${m(envW)} x ${m(envD)} M ENVELOPE',pt*.65),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+pt*2.5),'SIDE AND REAR RESERVES ONLY / NO OCCUPANCY OR EGRESS APPROVAL',pt*.63),
    ]);
    final plan=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-pt*2,pw/2-pt*25).floor(),(-pt*2).floor(),
      math.max(ax+pt*3,pw/2+pt*25).ceil(),(pd+pt*7).ceil()),lines:planLines,labels:planLabels);

    sl('AMPH_STAGE',0,0,0,stage);sl('AMPH_STAGE',0,stage,sd,stage);sl('AMPH_STAGE',sd,stage,sd,0);
    sl('AMPH_RESERVES',sd,0,first,0);
    for(var i=0;i<rows;i++) {
      final x=first+i*tread,z=i*rise;
      if(i>0) sl('AMPH_TIERS',x,z-rise,x,z);
      sl('AMPH_TIERS',x,z,x+tread,z);
    }
    final top=(rows-1)*rise,high=math.max(top+eye,stage);
    sl('AMPH_TIERS',first+bankDepth,top,first+bankDepth,0);
    sl('AMPH_SIGHT',sd,stage,eyeX(critical),eyeZ(critical));
    final mark=math.min(eye,tread)*.075;
    for(var i=0;i<rows;i++) {
      sl('AMPH_EYES',eyeX(i)-mark,eyeZ(i),eyeX(i)+mark,eyeZ(i));
      sl('AMPH_EYES',eyeX(i),eyeZ(i)-mark,eyeX(i),eyeZ(i)+mark);
    }
    sl('AMPH_SIGHT',eyeX(critical-1),eyeZ(critical-1),eyeX(critical-1),rayZ(critical,eyeX(critical-1)));
    final t=(math.max(envD,high)/48).clamp(30,5000).toDouble();
    for(final (row,text,scale) in [
      (6.0,'CENTRELINE SEATING SECTION / TRUE SCALE MM',1.0),
      (4.6,'TARGET AT AUDIENCE-FACING STAGE DECK EDGE / EYES AT MID TREAD',.65),
      (3.25,'ROW ${critical+1} MIN CLEARANCE ${m(worst)} M / SUPPLIED ${m(need)} M',.65),
      (1.9,'CENTRELINE GEOMETRY ONLY / NO FULL STAGE VISIBILITY CHECK',.6),
    ]) {
      sectionLabels.add(CadLabel('ANNOTATIONS',CadPoint(envD/2,high+row*t),text,t*scale));
    }
    final section=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-2*t,envD/2-26*t).floor(),(-2*t).floor(),
      math.max(envD+2*t,envD/2+26*t).ceil(),(high+7.6*t).ceil()),lines:sectionLines,labels:sectionLabels);
    return AmphitheatreCadResult(plan:plan,section:section,rows:rows,placesPerRow:perRow,envelopeWidthMm:envW,
      envelopeDepthMm:envD,clearanceMm:worst,criticalRow:critical+1);
  }
}
