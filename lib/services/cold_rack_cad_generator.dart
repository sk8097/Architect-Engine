import 'dart:math' as math;

import '../data/cold_rack_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class ColdRackBay {
  const ColdRackBay(this.row,this.bay,this.westMm,this.southMm,this.facing);
  final int row,bay,westMm,southMm;
  final String facing;
}

class ColdRackCadResult {
  const ColdRackCadResult({this.drawing,this.issue,this.bays=const [],this.rows=0,this.slots=0,this.levels=0,
    this.widthMm=0,this.depthMm=0,this.topLoadMm=0,this.overheadMm=0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<ColdRackBay> bays;
  final int rows,slots,levels,widthMm,depthMm,topLoadMm,overheadMm;
  int get positions=>bays.length*slots*levels;

  String? toCsv() {
    if(drawing==null) return null;
    String m(num mm)=>(mm/1000).toStringAsFixed(3);
    return [
      'row,bay,west_offset_m,south_opening_m,load_face,slots_per_level,levels,nominal_positions',
      for(final b in bays) '${b.row},${b.bay},${m(b.westMm)},${m(b.southMm)},${b.facing},$slots,$levels,${slots*levels}',
    ].join('\r\n')+'\r\n';
  }
}

/// One chamber with static pallet envelopes. No rack beams, loading or cooling
/// equipment is designed; nominal positions are a geometric count only.
class ColdRackCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='cold_storage_racks';

  ColdRackCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt}) {
    ColdRackCadResult stop(String issue)=>ColdRackCadResult(issue:issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !coldRackCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Cold Storage or Freezer Warehouse and save the measured rack brief.');
    }
    final a=snap.answers;
    if(!const {null,'rack_storage'}.contains(sel.configurationId) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        brief.floorCount!=1 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty ||
        (a['chambers']!=null && a['chambers']!=1) || a['cold_zones']=='multi') {
      return stop('Use one ground-floor, single-temperature rack chamber without parking or separate Space selections.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    int? mm(Object? v,{bool zero=false,int max=300}) {
      if(v is! num || !v.isFinite || v<(zero?0:.001) || v>max) return null;
      return (v*1000).round();
    }
    int? count(String k,int min,int max) {
      final v=a[k];return v is int && v>=min && v<=max?v:null;
    }
    final pw=mm(widthFt*.3048,max:2000),pd=mm(depthFt*.3048,max:2000),clear=mm(a['clear_height'],max:300);
    final pairs=count('cr_pairs',0,8),bays=count('cr_bays',1,20),slots=count('cr_slots',1,5),levels=count('cr_levels',1,8);
    final rd=mm(a['cr_rack_depth'],max:20),opening=mm(a['cr_bay'],max:20),upright=mm(a['cr_upright'],max:5);
    final w=mm(a['cr_pallet_w'],max:20),d=mm(a['cr_pallet_d'],max:20),h=mm(a['cr_pallet_h'],max:20),gap=mm(a['cr_gap'],max:10);
    final pitch=mm(a['cr_pitch_z'],zero:true,max:20),above=mm(a['cr_top_clear'],max:20),flue=mm(a['cr_flue'],zero:true,max:20);
    final aisle=mm(a['cr_aisle']),wallGap=mm(a['cr_wall_gap']),front=mm(a['cr_front']),rear=mm(a['cr_rear']);
    final door=mm(a['cr_door']),wall=mm(a['cr_wall'],max:5),west=mm(a['cr_west'],zero:true,max:2000),south=mm(a['cr_south'],zero:true,max:2000);
    if(pw==null || pd==null || clear==null || pairs==null || bays==null || slots==null || levels==null || rd==null || opening==null ||
        upright==null || w==null || d==null || h==null || gap==null || pitch==null || above==null || flue==null || aisle==null ||
        wallGap==null || front==null || rear==null || door==null || wall==null || west==null || south==null || (sel.plotShapeId=='square' && pw!=pd)) {
      return stop('Enter measured plot, rack, pallet, passage and Facility clear height inputs.');
    }
    if(d>rd || slots*w+(slots+1)*gap>opening) return stop('The loaded pallets and gaps do not fit inside a clear bay without overhang.');
    if((levels==1 && pitch!=0) || (levels>1 && pitch<=h)) {
      return stop('Use zero level pitch for one level, or a pitch greater than the loaded pallet height.');
    }
    if((pairs==0 && flue!=0) || (pairs>0 && flue==0)) return stop('Use positive separation within a back-to-back pair, or zero when there are no pairs.');
    final top=(levels-1)*pitch+h;
    if(top+above>clear) return stop('The top loaded pallet and required overhead clearance exceed the Facility clear height.');
    if(door>aisle) return stop('The entrance must be no wider than the clear aisle it leads to through staging.');
    final rows=2+2*pairs,run=bays*opening+(bays+1)*upright;
    final width=2*(wall+wallGap)+rows*rd+pairs*flue+(pairs+1)*aisle,depth=2*wall+front+run+rear;
    for(final (edge,dist) in [('left',west),('right',pw-west-width),('front',south),('rear',pd-south-depth)]) {
      final raw=a['${edge}_setback'],min=raw==null?0:mm(raw,zero:true,max:2000);
      if(min==null || dist<min) return stop('The rack chamber conflicts with the $edge plot edge or supplied setback.');
    }
    final ratio=width*depth/(pw*pd),fsi=a['fsi_limit'],coverage=a['coverage_limit'];
    if(fsi!=null && (fsi is! num || !fsi.isFinite || fsi<=0 || ratio>fsi+1e-12)) return stop('The chamber exceeds the supplied FSI or the limit is invalid.');
    if(coverage!=null && (coverage is! num || !coverage.isFinite || coverage<=0 || coverage>100 || ratio*100>coverage+1e-10)) {
      return stop('The chamber exceeds the supplied site coverage or the limit is invalid.');
    }
    final maximum=rows*bays*slots*levels,goal=a['pallet_positions'];
    if(goal!=null && (goal is! int || goal<0 || maximum<goal)) return stop('The chamber has $maximum nominal positions and does not meet the supplied pallet position target.');
    final lines=<CadLine>[],labels=<CadLabel>[],items=<ColdRackBay>[];
    void line(String layer,num x,num y,num ex,num ey) {
      if(x!=ex || y!=ey) lines.add(CadLine(layer,CadPoint(x,y),CadPoint(ex,ey)));
    }
    void box(String layer,num x,num y,num ex,num ey) {
      line(layer,x,y,ex,y);line(layer,ex,y,ex,ey);line(layer,ex,ey,x,ey);line(layer,x,ey,x,y);
    }
    box('COLD_PLOT',0,0,pw,pd);
    final startX=west+wall+wallGap,y=south+wall+front,endY=y+run;
    final doorX=startX+rd+aisle/2,dl=doorX-door/2,dr=doorX+door/2;
    void shell(int x,int y,int ex,int ey) {
      line('COLD_WALL',x,y,dl,y);line('COLD_WALL',dr,y,ex,y);line('COLD_WALL',ex,y,ex,ey);
      line('COLD_WALL',ex,ey,x,ey);line('COLD_WALL',x,ey,x,y);
    }
    shell(west,south,west+width,south+depth);shell(west+wall,south+wall,west+width-wall,south+depth-wall);
    line('COLD_WALL',dl,south,dl,south+wall);line('COLD_WALL',dr,south,dr,south+wall);
    line('COLD_ROUTE',doorX,south+wall,doorX,endY+rear/2);
    final t=(math.max(pw,pd)/84).clamp(35,6500).toDouble();
    var x=startX;
    for(var row=0;row<rows;row++) {
      final east=row.isEven;
      box('COLD_RACK',x,y,x+rd,endY);
      for(var b=0;b<bays;b++) {
        final q=y+upright+b*(opening+upright);
        line('COLD_RACK',x,q,x+rd,q);line('COLD_RACK',x,q+opening,x+rd,q+opening);
        items.add(ColdRackBay(row+1,b+1,x,q,east?'east':'west'));
        final lo=east?x+rd-d:x;
        final extra=(opening-slots*w-(slots+1)*gap)/2;
        for(var i=0;i<slots;i++) {
          final yy=q+extra+gap+i*(w+gap);
          box('COLD_LOAD',lo,yy,lo+d,yy+w);
        }
      }
      labels.add(CadLabel('COLD_RACK',CadPoint(x+rd/2,y-front/2),'R${row+1}',math.min(t*.7,math.min(rd/3,front/4))));
      if(row<rows-1) {
        x+=rd;
        if(east) {
          x+=aisle;
        } else {
          line('COLD_FLUE',x+flue/2,y,x+flue/2,endY);
          x+=flue;
        }
      }
    }
    if(front>=t*3 && width>=t*14) {
      labels.add(CadLabel('COLD_ROUTE',CadPoint(west+width/2,south+wall+front*.18),'FRONT STAGING',t*.62));
    }
    labels.add(CadLabel('COLD_ROUTE',CadPoint(west+width/2,endY+rear/2),'REAR CROSS-AISLE',math.min(t*.7,rear/3)));
    String m(num v)=>(v/1000).toStringAsFixed(3);
    final ax=pw+2*t;
    line('ANNOTATIONS',ax,pd-t*1.7,ax,pd);line('ANNOTATIONS',ax-t*.4,pd-t*.7,ax,pd);line('ANNOTATIONS',ax+t*.4,pd-t*.7,ax,pd);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(ax,pd+t),'N',t*.7),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*5.7),'COLD STORAGE RACK CHAMBER / LOCAL MM',t),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*4.3),'$rows ROWS x $bays BAYS x $slots SLOTS x $levels LEVELS / $maximum NOMINAL POSITIONS',t*.64),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*2.9),'TOP LOAD ${m(top)} M / OVERHEAD ${m(clear-top)} M / AISLE ${m(aisle)} M',t*.64),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*1.5),'STATIC GEOMETRY ONLY / NO LOAD RATING OR REFRIGERATION CHECK',t*.61),
    ]);
    final bounds=PlanRect(math.min(-2*t,pw/2-28*t).floor(),(-2*t).floor(),
      math.max(ax+3*t,pw/2+28*t).ceil(),(pd+7.4*t).ceil());
    return ColdRackCadResult(drawing:FloorPlanCad.fromEntities(bounds:bounds,lines:lines,labels:labels),
      bays:List.unmodifiable(items),rows:rows,slots:slots,levels:levels,widthMm:width,depthMm:depth,topLoadMm:top,overheadMm:clear-top);
  }
}
