import 'dart:math' as math;

import '../data/footbridge_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class FootbridgeCadResult {
  const FootbridgeCadResult({this.plan,this.profile,this.issue,this.spanMm=0,this.lengthMm=0,
    this.gradeA=0,this.gradeB=0,this.clearanceMm=0,this.requiredStartMm=0,this.requiredEndMm=0});
  final FloorPlanCad? plan,profile;
  final String? issue;
  final int spanMm,clearanceMm;
  final double lengthMm,gradeA,gradeB,requiredStartMm,requiredEndMm;
}

/// Constant-width, level-deck concept. Full deck width is considered for
/// channel strip fit. Clearance uses a single submitted reference RL.
class FootbridgeCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['footbridge_mode']=='survey_footbridge';

  FootbridgeCadResult generate(ProjectBrief brief) {
    FootbridgeCadResult stop(String issue)=>FootbridgeCadResult(issue:issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !footbridgeCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Transport infrastructure → Bridge and save the surveyed footbridge brief.');
    }
    if(!const {null,'linear_corridor','node_interchange'}.contains(sel.configurationId) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        (brief.floorCount??0)!=0 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one surveyed pedestrian crossing without buildings, parking or separate Space selections.');
    }
    final a=snap.answers;
    String? ref(String key) {
      final raw=a[key];
      if(raw is! String) return null;
      final text=raw.trim().replaceAll(RegExp(r'\s+'),' ');
      return text.isNotEmpty && text.length<=120?text:null;
    }
    final grid=ref('fb_grid'),datum=ref('fb_datum');
    if(grid==null || datum==null) return stop('Enter the projected metre grid and common elevation datum (up to 120 characters each).');
    final raw=a['fb_ends'];
    final rows=raw is String && raw.length<=300?raw.split(RegExp(r'[;\r\n]+')).where((s)=>s.trim().isNotEmpty).toList():<String>[];
    if(rows.length!=2) return stop('Enter exactly two tie-in controls, A then B: Easting,Northing,level.');
    final decimal=RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? metre(String raw,int limit) {
      final v=double.tryParse(raw);
      return decimal.hasMatch(raw.trim()) && v!=null && v.isFinite && v.abs()<=limit?(v*1000).round():null;
    }
    final pts=<(int,int,int)>[];
    for(final row in rows) {
      final c=row.split(',');
      if(c.length!=3) return stop('Use three numbers for each surveyed tie-in: Easting,Northing,level.');
      final x=metre(c[0],10000000),y=metre(c[1],10000000),z=metre(c[2],10000);
      if(x==null || y==null || z==null) return stop('Use valid projected metre coordinates and levels to three decimal places.');
      pts.add((x,y,z));
    }
    final (ax,ay,az)=pts.first;
    final (bx,by,bz)=pts.last;
    final dx=(bx-ax).toDouble(),dy=(by-ay).toDouble(),length=math.sqrt(dx*dx+dy*dy);
    if(length<1 || length>2000000) return stop('The surveyed A–B length must be positive and at most 2 km.');
    double? n(String key,num min,num max) {
      final v=a[key];
      return v is num && v.isFinite && v>=min && v<=max?v.toDouble():null;
    }
    int? mm(String key,num min,num max) {
      final v=n(key,min,max);
      return v==null?null:(v*1000).round();
    }
    final cross=mm('fb_cross',.001,2000),bearing=n('fb_bearing',0,360),channel=mm('fb_channel',.001,300);
    final bankGap=mm('fb_edge_gap',0,100),start=mm('fb_deck_start',.001,2000),end=mm('fb_deck_end',.001,2000);
    final width=mm('fb_width',.001,30),deck=mm('fb_level',-10000,10000),depth=mm('fb_depth',.001,20);
    final water=mm('fb_water',-10000,10000),need=mm('fb_clearance',0,100),maxGrade=n('fb_limit',.001,100);
    if(cross==null || bearing==null || channel==null || bankGap==null || start==null || end==null || width==null ||
        deck==null || depth==null || water==null || need==null || maxGrade==null) {
      return stop('Enter channel, deck, reference water clearance and approach slope dimensions.');
    }
    if(cross>=length || start>=end || end>=length-1e-6) {
      return stop('Keep crossing chainage between A and B and leave positive approach lengths on both sides of the ordered deck.');
    }
    final ux=dx/length,uy=dy/length;
    final rad=(bearing%360)*math.pi/180,qx=math.sin(rad),qy=math.cos(rad);
    final transverse=(ux*qy-uy*qx).abs(),parallel=(ux*qx+uy*qy).abs();
    if(transverse<math.sin(math.pi/12)-1e-12) return stop('Use a channel axis at least 15° from parallel to the bridge.');
    final halfW=width/2,halfChannel=channel/2;
    // Convert perpendicular bank distances to bridge-axis chainages, then
    // include the skew offset of both outer corners of each deck end face.
    final requiredHalf=(halfChannel+bankGap+halfW*parallel)/transverse;
    final mustStart=cross-requiredHalf,mustEnd=cross+requiredHalf;
    String m(num v)=>(v/1000).toStringAsFixed(3);
    if(start>mustStart+1e-6 || end<mustEnd-1e-6) {
      return stop('To clear both banks across the full deck width, start no later than ch ${m(mustStart)} m and end no earlier than ch ${m(mustEnd)} m.');
    }
    final gA=100*(deck-az).abs()/start,gB=100*(deck-bz).abs()/(length-end);
    if(gA>maxGrade+1e-10 || gB>maxGrade+1e-10) {
      return stop('Approach A is ${gA.toStringAsFixed(3)}% and B is ${gB.toStringAsFixed(3)}%; each must meet the supplied $maxGrade% maximum.');
    }
    final soffit=deck-depth,clearance=soffit-water;
    if(clearance<need) return stop('Deck underside clearance ${m(clearance)} m is below the supplied ${m(need)} m above the reference water level.');

    CadPoint b(num s,num off)=>CadPoint(ax+ux*s-uy*off,ay+uy*s+ux*off);
    final crossing=b(cross,0);
    final patch=math.max(cross,length-cross)*parallel+halfW+math.max(3000,channel);
    CadPoint q(num s,num off)=>CadPoint(crossing.x+qx*s-qy*off,crossing.y+qy*s+qx*off);
    final lines=<CadLine>[],labels=<CadLabel>[],pLines=<CadLine>[],pLabels=<CadLabel>[];
    void loop(String layer,List<CadPoint> pts) {
      for(var i=0;i<pts.length;i++) lines.add(CadLine(layer,pts[i],pts[(i+1)%pts.length]));
    }
    final bankPoints=[q(-patch,-halfChannel),q(patch,-halfChannel),q(patch,halfChannel),q(-patch,halfChannel)];
    loop('FOOTBRIDGE_BANK',bankPoints);
    lines.add(CadLine('FOOTBRIDGE_CHANNEL',q(-patch,0),q(patch,0)));
    for(final (layer,s,e) in [('FOOTBRIDGE_APPROACH',0,start),('FOOTBRIDGE_DECK',start,end),('FOOTBRIDGE_APPROACH',end,length)]) {
      lines.add(CadLine(layer,b(s,-halfW),b(e,-halfW)));lines.add(CadLine(layer,b(s,halfW),b(e,halfW)));
    }
    for(final (layer,s) in [('FOOTBRIDGE_APPROACH',0),('FOOTBRIDGE_DECK',start),('FOOTBRIDGE_DECK',end),('FOOTBRIDGE_APPROACH',length)]) {
      lines.add(CadLine(layer,b(s,-halfW),b(s,halfW)));
    }
    lines.add(CadLine('FOOTBRIDGE_AXIS',b(0,0),b(length,0)));
    final boundsPts=[...bankPoints,b(0,-halfW),b(0,halfW),b(length,-halfW),b(length,halfW)];
    final xmin=boundsPts.map((p)=>p.x).reduce(math.min),xmax=boundsPts.map((p)=>p.x).reduce(math.max);
    final ymin=boundsPts.map((p)=>p.y).reduce(math.min),ymax=boundsPts.map((p)=>p.y).reduce(math.max),cx=(xmin+xmax)/2;
    final t=(math.max(xmax-xmin,ymax-ymin)/84).clamp(40,15000).toDouble(),nx=math.max(xmax+4*t,cx+34*t);
    labels.addAll([
      CadLabel('FOOTBRIDGE_AXIS',b(-2*t,0),'A',t*.75),CadLabel('FOOTBRIDGE_AXIS',b(length+2*t,0),'B',t*.75),
      CadLabel('ANNOTATIONS',CadPoint(nx,ymax+t),'GRID N',t*.65),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+7.1*t),'SURVEYED FOOTBRIDGE PLAN / PROJECTED MM',t),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+5.7*t),'DECK CH ${m(start)} TO ${m(end)} M / SPAN ${m(end-start)} M',t*.65),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+4.3*t),'FULL-WIDTH REQUIRED COVERAGE CH ${m(mustStart)} TO ${m(mustEnd)} M',t*.65),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+2.9*t),'GRID: $grid',t*.57),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+1.5*t),'CHANNEL BAND ONLY / NO SUPPORT OR FOUNDATION DESIGN',t*.66),
    ]);
    final arrow=CadPoint(nx,ymax);
    lines.addAll([CadLine('ANNOTATIONS',CadPoint(nx,ymax-t*1.7),arrow),
      CadLine('ANNOTATIONS',CadPoint(nx-t*.45,ymax-t*.7),arrow),CadLine('ANNOTATIONS',CadPoint(nx+t*.45,ymax-t*.7),arrow)]);
    final plan=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(xmin-5*t,cx-34*t).floor(),(ymin-5*t).floor(),
      (nx+3*t).ceil(),(ymax+8.9*t).ceil()),lines:lines,labels:labels);

    final base=math.min(math.min(az,bz),water),high=math.max(math.max(az,bz),deck)-base;
    void profileLine(String layer,num s,num z,num e,num ez) {
      if(s!=e || z!=ez) pLines.add(CadLine(layer,CadPoint(s,z-base),CadPoint(e,ez-base)));
    }
    profileLine('FOOTBRIDGE_APPROACH',0,az,start,deck);
    profileLine('FOOTBRIDGE_APPROACH',end,deck,length,bz);
    profileLine('FOOTBRIDGE_DECK',start,deck,end,deck);
    profileLine('FOOTBRIDGE_SOFFIT',start,soffit,end,soffit);
    profileLine('FOOTBRIDGE_DECK',start,soffit,start,deck);
    profileLine('FOOTBRIDGE_DECK',end,soffit,end,deck);
    profileLine('FOOTBRIDGE_WATER',cross-halfChannel/transverse,water,cross+halfChannel/transverse,water);
    profileLine('FOOTBRIDGE_CLEARANCE',cross,water,cross,soffit);
    final pt=(math.max(length,high)/55).clamp(30,18000).toDouble();
    for(final (row,text,size) in [
      (7.3,'CENTRELINE BRIDGE PROFILE / TRUE SCALE MM',1.0),
      (5.95,'APPROACH A ${gA.toStringAsFixed(3)}% / B ${gB.toStringAsFixed(3)}% / MAX $maxGrade%',.66),
      (4.6,'DECK RL ${m(deck)} M / SOFFIT RL ${m(soffit)} M / WATER REF RL ${m(water)} M',.65),
      (3.25,'VERTICAL CLEARANCE ${m(clearance)} M / PROFILE ZERO AT RL ${m(base)} M',.64),
      (1.9,'DATUM: $datum',.56),
    ]) {
      pLabels.add(CadLabel('ANNOTATIONS',CadPoint(length/2,high+row*pt),text,pt*size));
    }
    final profile=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-3*pt,length/2-34*pt).floor(),(-3*pt).floor(),
      math.max(length+3*pt,length/2+34*pt).ceil(),(high+9*pt).ceil()),lines:pLines,labels:pLabels);
    return FootbridgeCadResult(plan:plan,profile:profile,spanMm:end-start,lengthMm:length,gradeA:gA,gradeB:gB,
      clearanceMm:clearance,requiredStartMm:mustStart,requiredEndMm:mustEnd);
  }
}
