import 'dart:math' as math;

import '../data/bus_layby_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class BusLaybyCadResult {
  const BusLaybyCadResult({this.drawing,this.issue,this.berths=0,this.edgeMm=0,this.startMm=0,
    this.endMm=0,this.requiredWidthMm=0,this.shelterGapMm=0});
  final FloorPlanCad? drawing;
  final String? issue;
  final int berths,startMm,endMm,requiredWidthMm;
  final double edgeMm,shelterGapMm;
}

/// Plan geometry on one straight existing road edge, not a swept-path model.
class BusLaybyCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['bus_layby_mode']=='survey_layby';

  BusLaybyCadResult generate(ProjectBrief brief) {
    BusLaybyCadResult stop(String issue) => BusLaybyCadResult(issue:issue);
    final sel=brief.taxonomy, snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !busLaybyCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Transport Infrastructure → Bus Stop and save the current surveyed brief.');
    }
    if(!const {null,'linear_corridor','node_interchange'}.contains(sel.configurationId) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        (brief.floorCount??0)!=0 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one roadside bus stop concept without buildings, separate car parking or Space selections.');
    }
    final a=snap.answers;
    final rawGrid=a['bl_grid'];
    final grid=rawGrid is String ? rawGrid.trim().replaceAll(RegExp(r'\s+'),' ') : '';
    if(grid.isEmpty || grid.length>120) return stop('Enter the projected metre grid reference (up to 120 characters).');
    final raw=a['bl_edge'];
    final rows=raw is String && raw.length<=240 ? raw.split(RegExp(r'[;\r\n]+')).where((s)=>s.trim().isNotEmpty).toList() : <String>[];
    if(rows.length!=2) return stop('Enter exactly two Easting,Northing road-edge controls in the direction of travel.');
    final decimal=RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? projectMm(String raw) {
      final text=raw.trim(), value=double.tryParse(raw);
      return decimal.hasMatch(text) && value!=null && value.isFinite && value.abs()<=10000000 ? (value*1000).round() : null;
    }
    final controls=<(int,int)>[];
    for(final row in rows) {
      final cols=row.split(',');
      if(cols.length!=2) return stop('Each road-edge control needs Easting,Northing in projected metres.');
      final x=projectMm(cols[0]),y=projectMm(cols[1]);
      if(x==null || y==null) return stop('Enter valid projected coordinates to three decimal places.');
      controls.add((x,y));
    }
    final (sx,sy)=controls.first;
    final (ex,ey)=controls.last;
    final dx=(ex-sx).toDouble(),dy=(ey-sy).toDouble(),edge=math.sqrt(dx*dx+dy*dy);
    if(edge<1 || edge>2000000) return stop('The surveyed road edge must have positive length and be at most 2 km long.');
    int? mm(String key,{bool zero=false,int max=300}) {
      final v=a[key];
      return v is num && v.isFinite && v>=(zero?0:.001) && v<=max ? (v*1000).round() : null;
    }
    final side=a['bl_side'],count=a['bl_count'],start=mm('bl_offset',zero:true,max:2000);
    final entry=mm('bl_entry'),exit=mm('bl_exit'),berth=mm('bl_berth'),gap=mm('bl_gap',zero:true),bay=mm('bl_width');
    final board=mm('bl_board'),shelter=mm('bl_shelter_len'),shelterDepth=mm('bl_shelter_depth');
    final connection=mm('bl_connection'),walk=mm('bl_walk'),row=mm('bl_row',max:1000);
    if(!const {'left','right'}.contains(side) || count is! int || count<1 || count>4 || start==null || entry==null || exit==null ||
        berth==null || gap==null || bay==null || board==null || shelter==null || shelterDepth==null || connection==null || walk==null || row==null) {
      return stop('Enter measured bay, taper, boarding strip, shelter and roadside dimensions and a lay-by side.');
    }
    if((count==1 && gap!=0) || (count>1 && gap==0)) {
      return stop('Use zero inter-berth gap for one berth, or a positive gap for multiple berths.');
    }
    final run=count*berth+(count-1)*gap, near=start+entry, far=near+run, end=far+exit;
    String m(num mm)=>(mm/1000).toStringAsFixed(3);
    if(end>edge+1e-6) return stop('The exit taper ends at ${m(end)} m, beyond the surveyed edge length ${m(edge)} m.');
    final clear=(run-shelter)/2;
    if(clear<connection) return stop('The shelter reserve does not leave the supplied clear connection at both ends of the boarding strip.');
    final behind=bay+board, walkEdge=behind+shelterDepth, need=walkEdge+walk;
    if(need>row) return stop('The bay, boarding strip, shelter and rear path need ${m(need)} m, beyond the ${m(row)} m available roadside width.');

    final ux=dx/edge,uy=dy/edge,sign=side=='left'?1:-1;
    CadPoint p(num station,num off)=>CadPoint(sx+ux*station-uy*off*sign,sy+uy*station+ux*off*sign);
    final lines=<CadLine>[],labels=<CadLabel>[];
    void line(String layer,num s,num t,num x,num y)=>lines.add(CadLine(layer,p(s,t),p(x,y)));
    void box(String layer,num l,num n,num r,num f) {
      line(layer,l,n,r,n);line(layer,r,n,r,f);line(layer,r,f,l,f);line(layer,l,f,l,n);
    }
    line('LAYBY_ROAD',0,0,edge,0);
    line('LAYBY_ROW',0,row,edge,row);
    line('LAYBY_EDGE',start,0,near,bay);
    line('LAYBY_EDGE',near,bay,far,bay);
    line('LAYBY_EDGE',far,bay,end,0);
    // The common boarding edge uses the lay-by line, not a second coincident line.
    line('LAYBY_BOARD',near,bay,near,behind);
    line('LAYBY_BOARD',far,bay,far,behind);
    // Delimit the boarding strip only at the shelter frontage; leave both passenger connections open.
    box('LAYBY_SHELTER',near+clear,behind,far-clear,walkEdge);
    line('LAYBY_WALK',start,walkEdge,near+clear,walkEdge);
    line('LAYBY_WALK',far-clear,walkEdge,end,walkEdge);
    line('LAYBY_WALK',start,need,end,need);
    final text=(math.max(edge,row)/110).clamp(35,15000).toDouble();
    final angle=math.atan2(uy,ux)*180/math.pi;
    final readable=angle>90 ? angle-180 : angle < -90 ? angle+180 : angle;
    for(var i=0;i<count;i++) {
      final s=near+i*(berth+gap);
      line('LAYBY_BERTH',s,0,s,bay);
      line('LAYBY_BERTH',s+berth,0,s+berth,bay);
      labels.add(CadLabel('LAYBY_BERTH',p(s+berth/2,bay/2),'B${i+1}',math.min(text*.75,math.min(berth,bay)/3),angle:readable));
    }
    labels.add(CadLabel('LAYBY_SHELTER',p((near+far)/2,behind+shelterDepth/2),'SHELTER RESERVE',
      math.min(text*.7,math.min(shelter/13,shelterDepth/3)),angle:readable));
    final arrow=math.min((end-start)*.07,text*2),at=(start+end)/2,off=-bay/2;
    line('LAYBY_TRAVEL',at-arrow,off,at,off);
    line('LAYBY_TRAVEL',at-arrow*.5,off+arrow*.28,at,off);
    line('LAYBY_TRAVEL',at-arrow*.5,off-arrow*.28,at,off);
    final corners=[p(0,0),p(edge,0),p(0,row),p(edge,row),p(at-arrow,off-arrow*.28),p(at,off+arrow*.28)];
    final xmin=corners.map((q)=>q.x).reduce(math.min),xmax=corners.map((q)=>q.x).reduce(math.max);
    final ymin=corners.map((q)=>q.y).reduce(math.min),ymax=corners.map((q)=>q.y).reduce(math.max),cx=(xmin+xmax)/2;
    final nx=math.max(xmax+text*3,cx+text*32);
    final north=CadPoint(nx,ymax);
    lines.addAll([CadLine('ANNOTATIONS',CadPoint(nx,ymax-text*1.8),north),
      CadLine('ANNOTATIONS',CadPoint(nx-text*.45,ymax-text*.7),north),CadLine('ANNOTATIONS',CadPoint(nx+text*.45,ymax-text*.7),north)]);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(nx,ymax+text),'GRID N',text*.62),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+text*7.1),'SURVEYED BUS STOP LAY-BY / PROJECTED MM',text),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+text*5.75),'$count BERTH(S) / CH ${m(start)} TO ${m(end)} M / ${side.toString().toUpperCase()} OF TRAVEL',text*.67),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+text*4.4),'WIDTH ${m(need)} M / BOARDING ${m(board)} M / REAR WALK ${m(walk)} M',text*.67),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+text*3.05),'GRID: $grid',text*.57),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+text*1.7),'CONCEPT GEOMETRY ONLY / NO VEHICLE TRACKING',text*.63),
    ]);
    final bounds=PlanRect(math.min(xmin-text*3,cx-text*32).floor(),(ymin-text*3).floor(),(nx+text*3).ceil(),(ymax+text*8.8).ceil());
    return BusLaybyCadResult(drawing:FloorPlanCad.fromEntities(bounds:bounds,lines:lines,labels:labels),berths:count,
      edgeMm:edge,startMm:start,endMm:end,requiredWidthMm:need,shelterGapMm:clear);
  }
}
