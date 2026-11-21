import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/twin_tank_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class TwinTankCadResult {
  const TwinTankCadResult({this.plan,this.section,this.issue,this.usableA=0,this.usableB=0,this.usableTotal=0,
    this.reserve=0,this.widthMm=0,this.depthMm=0,this.freeboardA=0,this.freeboardB=0});
  final FloorPlanCad? plan,section;
  final String? issue;
  final int widthMm,depthMm,freeboardA,freeboardB;
  final double usableA,usableB,usableTotal,reserve;
}

/// Plan and cross-section of two rectangular storage cells on one floor datum.
/// Outage volumes assume independent operation, not designed isolation.
class TwinTankCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='tank_twin_cell';

  TwinTankCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt}) {
    TwinTankCadResult stop(String issue)=>TwinTankCadResult(issue:issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !twinTankCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Water Tank or Ground Reservoir and save the measured twin-cell brief.');
    }
    if(!const {null,'storage'}.contains(sel.configurationId) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        (brief.floorCount??0)!=0 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one ground-level tank with two cells, without buildings, parking or separate Space selections.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a=snap.answers;
    int? mm(Object? v,{bool zero=false,int max=300}) {
      if(v is! num || !v.isFinite || v<(zero?0:.001) || v>max) return null;
      return (v*1000).round();
    }
    double? volume(String key) {
      final v=a[key];return v is num && v.isFinite && v>=0 && v<=100000000?v.toDouble():null;
    }
    final pw=mm(widthFt*.3048,max:2000),pd=mm(depthFt*.3048,max:2000);
    final wa=mm(a['tt_w_a']),wb=mm(a['tt_w_b']),length=mm(a['tt_length']);
    final wall=mm(a['tt_wall'],max:10),divider=mm(a['tt_divider'],max:10),height=mm(a['tt_height'],max:30);
    final loA=mm(a['tt_lower_a'],zero:true,max:30),loB=mm(a['tt_lower_b'],zero:true,max:30);
    final hiA=mm(a['tt_normal_a'],max:30),hiB=mm(a['tt_normal_b'],max:30),requiredFree=mm(a['tt_freeboard'],zero:true,max:30);
    final service=mm(a['tt_service']),west=mm(a['tt_west'],zero:true,max:2000),south=mm(a['tt_south'],zero:true,max:2000);
    final totalGoal=volume('tt_total'),reserveGoal=volume('tt_reserve');
    if(pw==null || pd==null || wa==null || wb==null || length==null || wall==null || divider==null || height==null ||
        loA==null || loB==null || hiA==null || hiB==null || requiredFree==null || service==null || west==null || south==null ||
        totalGoal==null || reserveGoal==null || (sel.plotShapeId=='square' && pw!=pd)) {
      return stop('Enter measured plot, cell, level, service and storage target inputs.');
    }
    final freeA=height-hiA,freeB=height-hiB;
    for(final (id,lo,hi,free) in [('A',loA,hiA,freeA),('B',loB,hiB,freeB)]) {
      if(hi<=lo) return stop('Cell $id normal level must be above its lower usable level.');
      if(free<requiredFree) return stop('Cell $id normal level exceeds the wall top or leaves less than the supplied freeboard.');
    }
    final width=2*wall+wa+divider+wb,depth=2*wall+length,envW=width+2*service,envD=depth+2*service;
    for(final (edge,clear) in [('left',west),('right',pw-west-envW),('front',south),('rear',pd-south-envD)]) {
      final raw=a['${edge}_setback'],min=raw==null?0:mm(raw,zero:true,max:2000);
      if(min==null || clear<min) return stop('The tank and service envelope conflict with the $edge plot edge or supplied setback.');
    }
    final usableA=wa*length/1e6*(hiA-loA)/1000,usableB=wb*length/1e6*(hiB-loB)/1000;
    final total=usableA+usableB,reserve=math.min(usableA,usableB);
    if(total<totalGoal-1e-9) return stop('Both cells hold ${total.toStringAsFixed(6)} m³ usable, below the supplied $totalGoal m³ total target.');
    if(reserve<reserveGoal-1e-9) return stop('With either cell offline, the worst-case remaining volume is ${reserve.toStringAsFixed(6)} m³, below the supplied $reserveGoal m³ reserve target.');

    final lines=<CadLine>[],labels=<CadLabel>[],sLines=<CadLine>[],sLabels=<CadLabel>[];
    void line(List<CadLine> dest,String layer,num x,num y,num ex,num ey) {
      if(x!=ex || y!=ey) dest.add(CadLine(layer,CadPoint(x,y),CadPoint(ex,ey)));
    }
    void p(String layer,num x,num y,num ex,num ey)=>line(lines,layer,x,y,ex,ey);
    void sl(String layer,num x,num y,num ex,num ey)=>line(sLines,layer,x,y,ex,ey);
    void box(String layer,num x,num y,num ex,num ey) {
      p(layer,x,y,ex,y);p(layer,ex,y,ex,ey);p(layer,ex,ey,x,ey);p(layer,x,ey,x,y);
    }
    final x=west+service,y=south+service;
    final startA=wall,endA=wall+wa,startB=endA+divider,endB=startB+wb;
    box('TWIN_TANK_PLOT',0,0,pw,pd);
    box('TWIN_TANK_SERVICE',west,south,west+envW,south+envD);
    box('TWIN_TANK_WALL',x,y,x+width,y+depth);
    box('TWIN_TANK_CELL',x+startA,y+wall,x+endA,y+wall+length);
    box('TWIN_TANK_CELL',x+startB,y+wall,x+endB,y+wall+length);
    final t=(math.max(pw,pd)/84).clamp(40,6500).toDouble();
    final ax=pw+2*t;
    p('ANNOTATIONS',ax,pd-t*1.7,ax,pd);p('ANNOTATIONS',ax-t*.4,pd-t*.7,ax,pd);p('ANNOTATIONS',ax+t*.4,pd-t*.7,ax,pd);
    String m(num v)=>(v/1000).toStringAsFixed(3);
    for(final (id,l,r) in [('A',startA,endA),('B',startB,endB)]) {
      labels.add(CadLabel('TWIN_TANK_CELL',CadPoint(x+(l+r)/2,y+depth/2),'CELL $id',math.min(t*.9,math.min((r-l)/6,length/3))));
    }
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(ax,pd+t),'N',t*.7),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+5.7*t),'TWIN-CELL GROUND-LEVEL WATER TANK / LOCAL MM',t),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+4.3*t),'${m(width)} x ${m(depth)} M TANK / ${m(service)} M CLEAR SERVICE STRIP',t*.66),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+2.9*t),'${total.toStringAsFixed(3)} M3 USABLE TOTAL / ${reserve.toStringAsFixed(3)} M3 WITH EITHER CELL OFFLINE',t*.64),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+1.5*t),'GEOMETRY ONLY / NO ISOLATION OR STRUCTURE DESIGN',t*.64),
    ]);
    final plan=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-2*t,pw/2-28*t).floor(),(-2*t).floor(),
      math.max(ax+3*t,pw/2+28*t).ceil(),(pd+7.4*t).ceil()),lines:lines,labels:labels);

    sl('TWIN_TANK_FLOOR',0,0,width,0);
    for(final (l,r) in [(0,startA),(endA,startB),(endB,width)]) {
      sl('TWIN_TANK_WALL',l,0,l,height);sl('TWIN_TANK_WALL',l,height,r,height);sl('TWIN_TANK_WALL',r,height,r,0);
    }
    final st=(math.max(width,height)/48).clamp(24,6500).toDouble();
    for(final (id,l,r,lo,hi) in [('A',startA,endA,loA,hiA),('B',startB,endB,loB,hiB)]) {
      sl('TWIN_TANK_NORMAL',l,hi,r,hi);
      if(lo>0) sl('TWIN_TANK_LOW',l,lo,r,lo);
      sLabels.add(CadLabel('TWIN_TANK_CELL',CadPoint((l+r)/2,height+st*.65),'CELL $id',math.min(st*.76,(r-l)/6)));
    }
    for(final (row,text,size) in [
      (7.2,'TRANSVERSE TANK SECTION / TRUE SCALE MM / COMMON FLOOR DATUM 0',1.0),
      (5.8,'A LOW ${m(loA)} / NORMAL ${m(hiA)} M / B LOW ${m(loB)} / NORMAL ${m(hiB)} M',.66),
      (4.4,'USABLE A ${usableA.toStringAsFixed(3)} M3 / B ${usableB.toStringAsFixed(3)} M3',.64),
      (3.0,'FREEBOARD A ${m(freeA)} M / B ${m(freeB)} M / NO ROOF OR BASE THICKNESS SHOWN',.62),
    ]) {
      sLabels.add(CadLabel('ANNOTATIONS',CadPoint(width/2,height+row*st),text,st*size));
    }
    final section=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-2*st,width/2-32*st).floor(),(-2*st).floor(),
      math.max(width+2*st,width/2+32*st).ceil(),(height+9*st).ceil()),lines:sLines,labels:sLabels);
    return TwinTankCadResult(plan:plan,section:section,usableA:usableA,usableB:usableB,usableTotal:total,reserve:reserve,
      widthMm:width,depthMm:depth,freeboardA:freeA,freeboardB:freeB);
  }
}
