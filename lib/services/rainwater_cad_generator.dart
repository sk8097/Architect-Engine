import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/rainwater_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class RainwaterCadResult {
  const RainwaterCadResult(this.drawing,this.issue,{this.roofM2=0,this.runoffL=0,this.divertedL=0,
    this.availableL=0,this.capacityL=0,this.storedL=0,this.excessL=0});
  final FloorPlanCad? drawing;
  final String? issue;
  final double roofM2,runoffL,divertedL,availableL,capacityL,storedL,excessL;
}

/// One roof catchment and one line of identical above-ground tanks. Water
/// totals are event-volume estimates, not hydraulic or seasonal simulation.
class RainwaterCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output']=='rainwater_roof_tanks';

  RainwaterCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt}) {
    RainwaterCadResult stop(String issue) => RainwaterCadResult(null,issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null||snap==null||sel.version!=projectTaxonomyVersion||snap.version!=requirementsSchemaVersion||
       !rainwaterCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Water / wastewater / stormwater → Rainwater Harvesting System and save the current brief.');
    }
    if(!const {null,'storage','drainage_system'}.contains(sel.configurationId)||
       !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId)||
       !const {null,ProjectParking.none}.contains(brief.parking)||sel.spaceQuantities.isNotEmpty) {
      return stop('Use a roof collection and tank storage concept without parking or separate Space selections.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)) return stop('Use a measured cardinally aligned rectangular or square plot.');
    final a=snap.answers;
    int? mm(Object? v,{bool zero=false,int max=2000}) {
      if(v is! num||!v.isFinite||v<0||v>max) return null;
      final count=(v*1000).round();
      return count>0||zero?count:null;
    }
    double? n(String key,num min,num max) {
      final v=a[key];
      return v is num && v.isFinite && v>=min && v<=max?v.toDouble():null;
    }
    final w=mm(widthFt*.3048),d=mm(depthFt*.3048),rw=mm(a['rw_roof_width']),rd=mm(a['rw_roof_depth']);
    final rx=mm(a['rw_roof_west'],zero:true),ry=mm(a['rw_roof_south'],zero:true);
    final tx=mm(a['rw_tank_west'],zero:true),ty=mm(a['rw_tank_south'],zero:true);
    final outer=mm(a['rw_outer'],max:50),inner=mm(a['rw_inner'],max:50),useful=mm(a['rw_useful'],max:50),walk=mm(a['rw_service'],max:50);
    final count=a['rw_count'],rain=n('rw_rain',.001,5000),coeff=n('rw_coefficient',0,1);
    final flush=n('rw_flush',0,100000000),target=n('rw_target',0,100000000);
    if(w==null||d==null||rw==null||rd==null||rx==null||ry==null||tx==null||ty==null||outer==null||inner==null||
       useful==null||walk==null||count is! int||count<1||count>8||rain==null||coeff==null||flush==null||target==null||
       (sel.plotShapeId=='square'&&w!=d)) return stop('Enter measured catchment, plot, tank, service and rainfall inputs.');
    if(inner>=outer) return stop('The inside tank diameter must be smaller than the outside diameter.');
    final roof=PlanRect(rx,ry,rx+rw,ry+rd);
    final service=PlanRect(tx,ty,tx+count*outer+(count+1)*walk,ty+outer+2*walk);
    final offsets=<int>[];
    for(final edge in ['left','front','right','rear']) {
      final raw=a['${edge}_setback'],setback=raw==null?0:mm(raw,zero:true);
      if(setback==null) return stop('Enter valid non-negative plot setbacks.');
      offsets.add(setback);
    }
    final allowed=PlanRect(offsets[0],offsets[1],w-offsets[2],d-offsets[3]);
    if(!allowed.contains(roof)) return stop('The roof catchment lies outside the plot or supplied setbacks.');
    if(!allowed.contains(service)) return stop('The tank bank and its clear service envelope exceed the plot or supplied setbacks.');
    if(roof.overlaps(service)) return stop('The tank service envelope overlaps the roof catchment footprint.');

    final area=roof.area/1e6, gross=area*rain*coeff;
    final diverted=math.min(gross,flush), available=gross-diverted;
    final radiusM=inner/2000;
    final volumeEachM3=math.pi*radiusM*radiusM*(useful/1000);
    final cap=count*volumeEachM3*1000;
    if(cap<target-1e-6) return stop('Usable tank capacity ${cap.toStringAsFixed(3)} L is below the supplied ${target.toStringAsFixed(3)} L target.');
    final stored=math.min(available,cap),excess=available-stored;
    final lines=<CadLine>[],arcs=<CadArc>[],labels=<CadLabel>[];
    void line(String layer,num x,num y,num r,num t)=>lines.add(CadLine(layer,CadPoint(x,y),CadPoint(r,t)));
    void box(String layer,PlanRect b) {
      line(layer,b.left,b.bottom,b.right,b.bottom);line(layer,b.right,b.bottom,b.right,b.top);
      line(layer,b.right,b.top,b.left,b.top);line(layer,b.left,b.top,b.left,b.bottom);
    }
    box('RAIN_PLOT',PlanRect(0,0,w,d));box('RAIN_ROOF',roof);box('RAIN_SERVICE',service);
    final text=(math.max(w,d)/78).clamp(40,10000).toDouble();
    for(var i=0;i<count;i++) {
      final p=CadPoint(tx+walk+outer/2+i*(outer+walk),ty+walk+outer/2);
      for(final (layer,radius) in [('RAIN_TANK',outer/2),('RAIN_TANK_INNER',inner/2)]) {
        arcs.addAll([CadArc(layer,p,radius,0,180),CadArc(layer,p,radius,180,0)]);
      }
      labels.add(CadLabel('RAIN_TANK',p,'T${i+1}',math.min(text*.75,inner/4)));
    }
    String l(double value)=>value.toStringAsFixed(3);
    labels.addAll([
      CadLabel('RAIN_ROOF',CadPoint((roof.left+roof.right)/2,(roof.bottom+roof.top)/2),
        'ROOF ${l(area)} M2',math.min(text*.75,math.min(rw/16,rd/3))),
      CadLabel('ANNOTATIONS',CadPoint(w/2,d+text*7.2),'ROOF RAINWATER / TANK BANK CONCEPT',text),
      CadLabel('ANNOTATIONS',CadPoint(w/2,d+text*5.85),'RUNOFF ${l(gross)} L / FIRST FLUSH ${l(diverted)} L / NET ${l(available)} L',text*.64),
      CadLabel('ANNOTATIONS',CadPoint(w/2,d+text*4.5),'USABLE CAPACITY ${l(cap)} L / EXCESS ${l(excess)} L IF STARTING EMPTY',text*.64),
      CadLabel('ANNOTATIONS',CadPoint(w/2,d+text*3.15),'${l(rain)} MM EVENT / RUNOFF COEFFICIENT $coeff / LOCAL MM',text*.64),
      CadLabel('ANNOTATIONS',CadPoint(w/2,d+text*1.8),'NORTH UP / NO PIPEWORK OR STRUCTURAL DESIGN',text*.64),
    ]);
    final ax=w+text*2;
    line('ANNOTATIONS',ax,d-text*1.7,ax,d);line('ANNOTATIONS',ax-text*.4,d-text*.7,ax,d);line('ANNOTATIONS',ax+text*.4,d-text*.7,ax,d);
    labels.add(CadLabel('ANNOTATIONS',CadPoint(ax,d+text),'N',text*.7));
    final bounds=PlanRect(math.min(-text*2,w/2-text*27).floor(),(-text*2).floor(),
      math.max(ax+text*3,w/2+text*27).ceil(),(d+text*8.8).ceil());
    return RainwaterCadResult(FloorPlanCad.fromEntities(bounds:bounds,lines:lines,arcs:arcs,labels:labels),null,
      roofM2:area,runoffL:gross,divertedL:diverted,availableL:available,capacityL:cap,storedL:stored,excessL:excess);
  }
}
