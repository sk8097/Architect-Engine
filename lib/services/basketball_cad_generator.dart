import 'dart:math' as math;

import '../data/basketball_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class BasketballCadResult {
  const BasketballCadResult(this.drawing,this.issue,{this.widthMm=0,this.lengthMm=0,this.sideMm=0,this.endMm=0});
  final FloorPlanCad? drawing;
  final String? issue;
  final int widthMm,lengthMm,sideMm,endMm;
}

/// Single measured outdoor court with native arcs. No rulebook presets.
class BasketballCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'basketball_measured_court';

  BasketballCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    BasketballCadResult stop(String issue) => BasketballCadResult(null,issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null||snap==null||sel.version!=projectTaxonomyVersion||snap.version!=requirementsSchemaVersion||
        !basketballCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select a supported outdoor sports type and save the current basketball court brief.');
    }
    if(!const {null,'outdoor'}.contains(sel.configurationId)||
       !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId)||
       (brief.floorCount??0)!=0||!const {null,ProjectParking.none}.contains(brief.parking)||sel.spaceQuantities.isNotEmpty) {
      return stop('Use one new outdoor court without buildings, parking or separate Space selections.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)||!const {'North','South','East','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot with cardinal frontage.');
    }
    final a=snap.answers;
    int? mm(Object? v,{bool zero=false}) {
      if(v is! num||!v.isFinite||v<0||v>300) return null;
      final n=(v*1000).round();
      return n>0||zero?n:null;
    }
    final pw=mm(widthFt*.3048), pd=mm(depthFt*.3048), w=mm(a['bk_width']), d=mm(a['bk_length']);
    final side=mm(a['bk_side']),end=mm(a['bk_end']),left=mm(a['bk_left'],zero:true),front=mm(a['bk_front']);
    final walk=mm(a['bk_walk']),rim=mm(a['bk_rim']),circle=mm(a['bk_centre_r']),keyW=mm(a['bk_key_width']),keyD=mm(a['bk_key_depth']);
    final free=mm(a['bk_free_r']),arcR=mm(a['bk_three_r']),inset=mm(a['bk_corner_inset']);
    if(pw==null||pd==null||w==null||d==null||side==null||end==null||left==null||front==null||walk==null||rim==null||
       circle==null||keyW==null||keyD==null||free==null||arcR==null||inset==null||(sel.plotShapeId=='square'&&pw!=pd)) {
      return stop('Enter measured plot, court, run-off, approach and marking dimensions.');
    }
    final envW=w+2*side,envD=d+2*end;
    if(walk>w) return stop('The clear front approach must fit within the court width.');
    for(final (edge,clear) in [('left',left),('right',pw-left-envW),('front',front),('rear',pd-front-envD)]) {
      final v=a['${edge}_setback'],min=v==null?0:mm(v,zero:true);
      if(min==null||clear<min) return stop('The court and run-off envelope conflict with the $edge plot edge or supplied setback.');
    }
    final halfW=w/2,halfD=d/2,cornerX=halfW-inset;
    if(cornerX<=0||keyW/2>=cornerX||rim>=keyD||free>keyW/2) {
      return stop('The keys, basket offsets and free-throw arcs must fit inside the straight corner lines.');
    }
    if(arcR<=cornerX) return stop('The three-point radius must meet both straight corner lines with a nonzero arc transition.');
    if(circle>=halfW||rim+arcR+circle>halfD||keyD+free+circle>halfD) {
      return stop('The measured end markings and centre circle do not fit within their court halves.');
    }
    final keyY=keyD-rim;
    if(keyY+free>arcR||keyY*keyY+keyW*keyW/4>arcR*arcR) {
      return stop('The key or free-throw semicircle extends beyond the three-point marking.');
    }
    final jump=math.sqrt(arcR*arcR-cornerX*cornerX), join=rim+jump;
    final theta=math.atan2(jump,cornerX)*180/math.pi;
    final rotated=facing=='East'||facing=='West',plotW=rotated?pd:pw,plotD=rotated?pw:pd;
    CadPoint orient(num x,num y) => switch(facing) {
      'North'=>CadPoint(pw-x,pd-y),'East'=>CadPoint(pd-y,x),'West'=>CadPoint(y,pw-x),_=>CadPoint(x,y),
    };
    final cx=left+side+halfW,base=front+end;
    CadPoint p(num u,num v) => orient(cx+u,base+v);
    final lines=<CadLine>[],arcs=<CadArc>[],labels=<CadLabel>[];
    void line(String layer,num x,num y,num xx,num yy) => lines.add(CadLine(layer,p(x,y),p(xx,yy)));
    void box(String layer,num x,num y,num xx,num yy) {
      line(layer,x,y,xx,y);line(layer,xx,y,xx,yy);line(layer,xx,yy,x,yy);line(layer,x,yy,x,y);
    }
    final bearing=switch(facing){'East'=>90,'North'=>180,'West'=>270,_=>0};
    void arc(String layer,num y,num radius,num start,num end) =>
      arcs.add(CadArc(layer,p(0,y),radius,(start+bearing)%360,(end+bearing)%360));
    box('BASKET_PLOT',-cx,-base,pw-cx,pd-base);
    box('BASKET_RUNOFF',-halfW-side,-end,halfW+side,d+end);
    box('BASKET_APPROACH',-walk/2,-base,walk/2,-end);
    box('BASKET_LINES',-halfW,0,halfW,d);
    line('BASKET_LINES',-halfW,halfD,halfW,halfD);
    arc('BASKET_LINES',halfD,circle,0,180); arc('BASKET_LINES',halfD,circle,180,360);
    for(final rear in [false,true]) {
      num v(num y)=>rear?d-y:y;
      line('BASKET_KEY',-keyW/2,v(0),-keyW/2,v(keyD));
      line('BASKET_KEY',-keyW/2,v(keyD),keyW/2,v(keyD));
      line('BASKET_KEY',keyW/2,v(keyD),keyW/2,v(0));
      arc('BASKET_KEY',v(keyD),free,rear?180:0,rear?360:180);
      line('BASKET_THREE',-cornerX,v(0),-cornerX,v(join));
      line('BASKET_THREE',cornerX,v(0),cornerX,v(join));
      arc('BASKET_THREE',v(rim),arcR,rear?180+theta:theta,rear?360-theta:180-theta);
      final mark=math.min(rim,keyW/2)*.13;
      line('BASKET_RIM',-mark,v(rim),mark,v(rim));
      line('BASKET_RIM',0,v(rim-mark),0,v(rim+mark));
    }
    final text=(math.max(plotW,plotD)/80).clamp(50,5000).toDouble();
    final ax=plotW+text*2;
    lines.addAll([CadLine('ANNOTATIONS',CadPoint(ax,plotD-text*1.7),CadPoint(ax,plotD)),
      CadLine('ANNOTATIONS',CadPoint(ax-text*.4,plotD-text*.7),CadPoint(ax,plotD)),
      CadLine('ANNOTATIONS',CadPoint(ax+text*.4,plotD-text*.7),CadPoint(ax,plotD))]);
    String m(num mm)=>(mm/1000).toStringAsFixed(3);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(ax,plotD+text),'N',text*.7),
      CadLabel('ANNOTATIONS',CadPoint(plotW/2,plotD+text*4.5),'MEASURED OUTDOOR BASKETBALL COURT',text),
      CadLabel('ANNOTATIONS',CadPoint(plotW/2,plotD+text*3.1),'${m(w)} x ${m(d)} M / RUN-OFF ${m(side)} M SIDE, ${m(end)} M END',text*.7),
      CadLabel('ANNOTATIONS',CadPoint(plotW/2,plotD+text*1.8),'MARKING CENTRELINES / LOCAL MM / NO RULEBOOK CERTIFICATION',text*.65),
    ]);
    final bounds=PlanRect(math.min(-text*2,plotW/2-text*23).floor(),(-text*2).floor(),
      math.max(ax+text*3,plotW/2+text*23).ceil(),(plotD+text*6).ceil());
    return BasketballCadResult(FloorPlanCad.fromEntities(bounds:bounds,lines:lines,arcs:arcs,labels:labels),null,
      widthMm:w,lengthMm:d,sideMm:side,endMm:end);
  }
}
