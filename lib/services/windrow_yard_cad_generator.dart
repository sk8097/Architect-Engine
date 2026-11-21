import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/windrow_yard_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class WindrowYardCadResult {
  const WindrowYardCadResult({this.plan,this.section,this.issue,this.rows=0,this.widthMm=0,this.depthMm=0,
    this.eachM3=0,this.totalM3=0,this.clearM2=0});
  final FloorPlanCad? plan,section;
  final String? issue;
  final int rows,widthMm,depthMm;
  final double eachM3,totalM3,clearM2;
}

/// Geometric takeoff for parallel rectangular prismoids with flat tops and
/// planar sides and ends. Does not estimate throughput or material density.
class WindrowYardCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='windrow_measured_yard';

  WindrowYardCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt}) {
    WindrowYardCadResult stop(String issue)=>WindrowYardCadResult(issue:issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !windrowYardCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Composting Facility and save the current measured windrow yard brief.');
    }
    if(!const {null,'support_facility'}.contains(sel.configurationId) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        (brief.floorCount??0)!=0 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one open windrow yard without buildings, parking or separate Space selections.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a=snap.answers;
    int? mm(Object? v,{bool zero=false,int max=300}) {
      if(v is! num || !v.isFinite || v<(zero?0:.001) || v>max) return null;
      return (v*1000).round();
    }
    final pw=mm(widthFt*.3048,max:2000),pd=mm(depthFt*.3048,max:2000),rows=a['wy_rows'];
    final bw=mm(a['wy_base_w']),bl=mm(a['wy_base_l']),tw=mm(a['wy_top_w']),tl=mm(a['wy_top_l']),height=mm(a['wy_height'],max:25);
    final aisle=mm(a['wy_aisle'],zero:true),side=mm(a['wy_side']),southHead=mm(a['wy_south_head']),northHead=mm(a['wy_north_head']);
    final west=mm(a['wy_west'],zero:true,max:2000),south=mm(a['wy_south'],zero:true,max:2000),target=a['wy_target'];
    if(pw==null || pd==null || rows is! int || rows<1 || rows>30 || bw==null || bl==null || tw==null || tl==null || height==null ||
        aisle==null || side==null || southHead==null || northHead==null || west==null || south==null || target is! num ||
        !target.isFinite || target<0 || target>100000000 || (sel.plotShapeId=='square' && pw!=pd)) {
      return stop('Enter measured plot, pile, aisle, headland and target volume inputs.');
    }
    if(tw>=bw || tl>=bl) return stop('The pile top must be strictly narrower and shorter than the base for sloping sides and ends.');
    if((rows==1 && aisle!=0) || (rows>1 && aisle==0)) return stop('Use a positive clear aisle between multiple rows, or zero aisle for one row.');
    final width=2*side+rows*bw+(rows-1)*aisle,depth=southHead+bl+northHead;
    for(final (edge,clear) in [('left',west),('right',pw-west-width),('front',south),('rear',pd-south-depth)]) {
      final raw=a['${edge}_setback'],minimum=raw==null?0:mm(raw,zero:true,max:2000);
      if(minimum==null || clear<minimum) return stop('The windrow yard envelope conflicts with the $edge plot edge or supplied setback.');
    }
    // Horizontal slice area is quadratic in height: Simpson's rule is exact
    // here. Convert before multiplying to keep wide-yard intermediates safe.
    final bottomM2=bw*bl/1e6,topM2=tw*tl/1e6,midM2=(bw+tw)*(bl+tl)/4e6;
    final eachM3=(height/1000)*(bottomM2+4*midM2+topM2)/6,totalM3=rows*eachM3;
    if(totalM3<target-1e-9) {
      return stop('Geometric pile volume ${totalM3.toStringAsFixed(6)} m³ is below the supplied $target m³ target.');
    }
    final clearM2=(width*depth-rows*bw*bl)/1e6;
    final lines=<CadLine>[],labels=<CadLabel>[],sLines=<CadLine>[],sLabels=<CadLabel>[];
    void line(List<CadLine> dest,String layer,num x,num y,num ex,num ey)=>dest.add(CadLine(layer,CadPoint(x,y),CadPoint(ex,ey)));
    void p(String layer,num x,num y,num ex,num ey)=>line(lines,layer,x,y,ex,ey);
    void sl(String layer,num x,num y,num ex,num ey)=>line(sLines,layer,x,y,ex,ey);
    void box(String layer,num x,num y,num ex,num ey) {
      p(layer,x,y,ex,y);p(layer,ex,y,ex,ey);p(layer,ex,ey,x,ey);p(layer,x,ey,x,y);
    }
    final y=south+southHead,wx=(bw-tw)/2,ly=(bl-tl)/2;
    box('WINDROW_PLOT',0,0,pw,pd);
    box('WINDROW_YARD',west,south,west+width,south+depth);
    final t=(math.max(pw,pd)/84).clamp(45,6500).toDouble();
    for(var i=0;i<rows;i++) {
      final x=west+side+i*(bw+aisle);
      box('WINDROW_TOE',x,y,x+bw,y+bl);
      box('WINDROW_TOP',x+wx,y+ly,x+bw-wx,y+bl-ly);
      for(final (sx,sy) in [(1,1),(-1,1),(1,-1),(-1,-1)]) {
        final cornerX=sx==1?x:x+bw,cornerY=sy==1?y:y+bl;
        p('WINDROW_HIPS',cornerX,cornerY,cornerX+sx*wx,cornerY+sy*ly);
      }
      labels.add(CadLabel('WINDROW_TOP',CadPoint(x+bw/2,y+bl/2),'W${i+1}',math.min(t*.8,math.min(tw/4,tl/3))));
      // Transverse view takes the middle of the piles. Keep the actual aisle
      // widths and show a single yard datum without fictitious grades.
      final localX=x-west;
      sl('WINDROW_FACE',localX,0,localX+wx,height);
      sl('WINDROW_TOP',localX+wx,height,localX+bw-wx,height);
      sl('WINDROW_FACE',localX+bw-wx,height,localX+bw,0);
    }
    sl('WINDROW_YARD',0,0,width,0);
    String m(num v)=>(v/1000).toStringAsFixed(3);
    final ax=pw+2*t;
    p('ANNOTATIONS',ax,pd-t*1.7,ax,pd);p('ANNOTATIONS',ax-t*.4,pd-t*.7,ax,pd);p('ANNOTATIONS',ax+t*.4,pd-t*.7,ax,pd);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(ax,pd+t),'N',t*.7),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*5.9),'OPEN WINDROW YARD / LOCAL MM',t),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*4.4),'$rows ROW(S) / ${m(width)} x ${m(depth)} M YARD / ${totalM3.toStringAsFixed(3)} M3 GEOMETRIC',t*.66),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*2.9),'CLEAR HEADLANDS: ${m(southHead)} M SOUTH / ${m(northHead)} M NORTH',t*.65),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*1.4),'LAYOUT ONLY / NO EQUIPMENT TURNING OR PROCESS DESIGN',t*.62),
    ]);
    final plan=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-2*t,pw/2-28*t).floor(),(-2*t).floor(),
      math.max(ax+3*t,pw/2+28*t).ceil(),(pd+7.5*t).ceil()),lines:lines,labels:labels);
    final st=(math.max(width,height)/48).clamp(35,6500).toDouble();
    for(final (row,text,size) in [
      (5.9,'MID-LENGTH TRANSVERSE SECTION / TRUE SCALE MM',1.0),
      (4.4,'BASE ${m(bw)} M / TOP ${m(tw)} M / HEIGHT ${m(height)} M',.66),
      (2.9,'${eachM3.toStringAsFixed(3)} M3 PER PILE / PLAN SHOWS BOTH TAPERED ENDS',.65),
      (1.4,'FLAT DATUM / NO PAD GRADES OR BANK STABILITY CHECK',.61),
    ]) {
      sLabels.add(CadLabel('ANNOTATIONS',CadPoint(width/2,height+row*st),text,st*size));
    }
    final section=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-2*st,width/2-28*st).floor(),(-2*st).floor(),
      math.max(width+2*st,width/2+28*st).ceil(),(height+7.5*st).ceil()),lines:sLines,labels:sLabels);
    return WindrowYardCadResult(plan:plan,section:section,rows:rows,widthMm:width,depthMm:depth,
      eachM3:eachM3,totalM3:totalM3,clearM2:clearM2);
  }
}
