import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/raised_bed_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class RaisedBedItem {
  const RaisedBedItem(this.id,this.outer,this.inner);
  final String id;
  final PlanRect outer,inner;
}

class RaisedBedCadResult {
  const RaisedBedCadResult({this.drawing,this.issue,this.beds=const [],this.envelopeWidthMm=0,
    this.envelopeDepthMm=0,this.fillMm=0,this.growingAreaM2=0,this.mediumM3=0,this.pathAreaM2=0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<RaisedBedItem> beds;
  final int envelopeWidthMm,envelopeDepthMm,fillMm;
  final double growingAreaM2,mediumM3,pathAreaM2;

  String? toCsv() {
    if(drawing==null) return null;
    String m(num mm)=>(mm/1000).toStringAsFixed(3);
    // Retain mm precision in lengths and the resulting exact SI products.
    return [
      'bed,west_m,south_m,outside_width_m,outside_length_m,inside_width_m,inside_length_m,fill_depth_m,growing_area_m2,medium_m3',
      for(final bed in beds) [bed.id,m(bed.outer.left),m(bed.outer.bottom),m(bed.outer.width),m(bed.outer.depth),
        m(bed.inner.width),m(bed.inner.depth),m(fillMm),(bed.inner.area/1e6).toStringAsFixed(6),
        (bed.inner.area*fillMm/1e9).toStringAsFixed(9)].join(','),
    ].join('\r\n')+'\r\n';
  }
}

/// Two banks of rectangular beds flank a through path and connect at every
/// cross-aisle. Takeoff uses the clear bed interior, not the outer footprint.
class RaisedBedCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output']=='garden_raised_beds';

  RaisedBedCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt}) {
    RaisedBedCadResult stop(String issue)=>RaisedBedCadResult(issue:issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !raisedBedCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Public Garden and save the current measured raised-bed brief.');
    }
    if(!const {null,'public_open_space'}.contains(sel.configurationId) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        (brief.floorCount??0)!=0 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one open public garden without buildings, parking or separate Space selections.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a=snap.answers;
    int? mm(Object? v,{bool zero=false,int max=50}) {
      if(v is! num || !v.isFinite || v<(zero?0:.001) || v>max) return null;
      return (v*1000).round();
    }
    final pw=mm(widthFt*.3048,max:2000),pd=mm(depthFt*.3048,max:2000),pairs=a['gb_pairs'];
    final w=mm(a['gb_width']),d=mm(a['gb_length']),wall=mm(a['gb_wall'],max:5);
    final height=mm(a['gb_height'],max:5),fill=mm(a['gb_fill'],max:5),reach=mm(a['gb_reach'],max:25);
    final spine=mm(a['gb_spine']),cross=mm(a['gb_cross'],zero:true),side=mm(a['gb_side']),ends=mm(a['gb_ends']);
    final west=mm(a['gb_west'],zero:true,max:2000),south=mm(a['gb_south'],zero:true,max:2000);
    if(pw==null || pd==null || pairs is! int || pairs<1 || pairs>30 || w==null || d==null || wall==null || height==null ||
        fill==null || reach==null || spine==null || cross==null || side==null || ends==null || west==null || south==null ||
        (sel.plotShapeId=='square' && pw!=pd)) return stop('Enter measured plot, bed, fill, reach and path dimensions.');
    final innerW=w-2*wall,innerD=d-2*wall;
    if(innerW<=0 || innerD<=0) return stop('The bed wall thickness leaves no positive clear growing interior.');
    if(fill>height) return stop('The growing-medium fill depth cannot exceed the usable inside wall height.');
    if(w>2*reach) return stop('The bed centreline is beyond the supplied horizontal reach from either long outside edge.');
    if((pairs==1 && cross!=0) || (pairs>1 && cross==0)) return stop('Use a positive cross-aisle depth for multiple pairs, or zero for one pair.');
    final envW=2*(w+side)+spine,envD=2*ends+pairs*d+(pairs-1)*cross;
    for(final (edge,clear) in [('left',west),('right',pw-west-envW),('front',south),('rear',pd-south-envD)]) {
      final raw=a['${edge}_setback'],minimum=raw==null?0:mm(raw,zero:true,max:2000);
      if(minimum==null || clear<minimum) return stop('The garden and clear paths conflict with the $edge plot edge or supplied setback.');
    }
    final beds=<RaisedBedItem>[],lines=<CadLine>[],labels=<CadLabel>[];
    void line(String layer,num x,num y,num xx,num yy)=>lines.add(CadLine(layer,CadPoint(x,y),CadPoint(xx,yy)));
    void box(String layer,PlanRect r) {
      line(layer,r.left,r.bottom,r.right,r.bottom);line(layer,r.right,r.bottom,r.right,r.top);
      line(layer,r.right,r.top,r.left,r.top);line(layer,r.left,r.top,r.left,r.bottom);
    }
    box('GARDEN_PLOT',PlanRect(0,0,pw,pd));
    box('GARDEN_PATHS',PlanRect(west,south,west+envW,south+envD));
    final t=(math.max(pw,pd)/83).clamp(35,6000).toDouble();
    final tagSize=math.min(t*.75,math.min(innerW/4,innerD/3));
    for(var i=0;i<pairs;i++) {
      final y=south+ends+i*(d+cross);
      for(final (bank,x) in [('W',west+side),('E',west+side+w+spine)]) {
        final id='$bank${i+1}';
        final outer=PlanRect(x,y,x+w,y+d),inner=PlanRect(x+wall,y+wall,x+w-wall,y+d-wall);
        beds.add(RaisedBedItem(id,outer,inner));
        box('GARDEN_BED_WALL',outer);box('GARDEN_GROWING',inner);
        labels.add(CadLabel('GARDEN_GROWING',CadPoint(x+w/2,y+d/2),id,tagSize));
      }
    }
    final count=beds.length,growing=count*innerW*innerD/1e6;
    final volume=count*innerW*innerD*fill/1e9;
    final pathArea=(envW*envD-count*w*d)/1e6;
    String m(num v)=>(v/1000).toStringAsFixed(3);
    final ax=pw+t*2;
    line('ANNOTATIONS',ax,pd-t*1.7,ax,pd);
    line('ANNOTATIONS',ax-t*.4,pd-t*.7,ax,pd);
    line('ANNOTATIONS',ax+t*.4,pd-t*.7,ax,pd);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(ax,pd+t),'N',t*.7),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*5.4),'PUBLIC GARDEN / MEASURED RAISED BEDS / LOCAL MM',t),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*4),'$count BEDS / ${m(envW)} x ${m(envD)} M ENVELOPE / ${m(spine)} M SPINE',t*.66),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*2.55),'${growing.toStringAsFixed(3)} M2 GROWING / ${volume.toStringAsFixed(3)} M3 NET MEDIUM',t*.66),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*1.1),'NO MATERIAL WASTE, SETTLEMENT OR ACCESSIBILITY ASSESSMENT',t*.61),
    ]);
    final bounds=PlanRect(math.min(-2*t,pw/2-26*t).floor(),(-2*t).floor(),
      math.max(ax+3*t,pw/2+26*t).ceil(),(pd+7*t).ceil());
    return RaisedBedCadResult(drawing:FloorPlanCad.fromEntities(bounds:bounds,lines:lines,labels:labels),
      beds:List.unmodifiable(beds),envelopeWidthMm:envW,envelopeDepthMm:envD,fillMm:fill,
      growingAreaM2:growing,mediumM3:volume,pathAreaM2:pathArea);
  }
}
