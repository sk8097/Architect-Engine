import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/stormwater_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class OpenDrainCadResult {
  const OpenDrainCadResult({this.plan,this.section,this.profile,this.issue,this.lengthMm=0,this.grade=0,
    this.topWidthMm=0,this.referenceAreaM2=0,this.freeboardMm=0});
  final FloorPlanCad? plan, section, profile;
  final String? issue;
  final double lengthMm, grade, topWidthMm, referenceAreaM2, freeboardMm;
}

/// Uniform section swept along one surveyed straight, falling invert.
/// Reference depth and bank lines are geometric offsets, not surveyed ground
/// or a simulated water surface.
class OpenDrainCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['drain_cad_mode'] == 'survey_open_drain';

  OpenDrainCadResult generate(ProjectBrief brief) {
    OpenDrainCadResult stop(String issue) => OpenDrainCadResult(issue:issue);
    final sel=brief.taxonomy, snap=brief.requirements;
    if (sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        sel.categoryId!='infrastructure' || sel.subcategoryId!='water' || !stormwaterCadTypes.contains(sel.typeId)) {
      return stop('Select Stormwater Drain or Drainage Network and save the current surveyed brief.');
    }
    if (!const {null,'drainage_system','network'}.contains(sel.configurationId) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        (brief.floorCount??0)!=0 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one straight surveyed open drain without buildings, parking or separate Space selections.');
    }
    final a=snap.answers;
    String? ref(String key) {
      final raw=a[key];
      if(raw is! String) return null;
      final text=raw.trim().replaceAll(RegExp(r'\s+'),' ');
      return text.isNotEmpty && text.length<=120 ? text : null;
    }
    final grid=ref('od_grid'), datum=ref('od_datum');
    if(grid==null || datum==null) return stop('Enter the projected metre grid and the common invert datum (up to 120 characters each).');
    final raw=a['od_ends'];
    final rows=raw is String && raw.length<=300 ? raw.split(RegExp(r'[;\r\n]+')).where((s)=>s.trim().isNotEmpty).toList() : <String>[];
    if(rows.length!=2) return stop('Enter exactly two controls, inlet then outlet: Easting,Northing,invert.');
    final decimal=RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? metre(String raw,int max) {
      final text=raw.trim(), v=double.tryParse(raw);
      return decimal.hasMatch(text) && v!=null && v.isFinite && v.abs()<=max ? (v*1000).round() : null;
    }
    final controls=<(int,int,int)>[];
    for(final row in rows) {
      final cols=row.split(',');
      if(cols.length!=3) return stop('Each control needs three numbers: Easting,Northing,invert.');
      final x=metre(cols[0],10000000), y=metre(cols[1],10000000), z=metre(cols[2],10000);
      if(x==null || y==null || z==null) return stop('Use valid projected metre coordinates and invert levels to three decimal places.');
      controls.add((x,y,z));
    }
    final (ix,iy,iz)=controls.first;
    final (ox,oy,oz)=controls.last;
    final dx=(ox-ix).toDouble(),dy=(oy-iy).toDouble(), length=math.sqrt(dx*dx+dy*dy);
    if(length<1 || length>2000000) return stop('The inlet and outlet must define a positive straight reach at most 2 km long.');
    double? n(String key,num min,num max) {
      final v=a[key];
      return v is num && v.isFinite && v>=min && v<=max ? v.toDouble() : null;
    }
    int? mm(String key,int max) {
      final value=n(key,.001,max);
      return value==null ? null : (value*1000).round();
    }
    final bottom=mm('od_bottom',100), depth=mm('od_depth',30), reference=mm('od_reference',30);
    final ls=n('od_left_slope',.001,20), rs=n('od_right_slope',.001,20), strip=mm('od_strip',100);
    final leftLimit=mm('od_left_limit',1000), rightLimit=mm('od_right_limit',1000), minFall=n('od_min_fall',0,100);
    if(bottom==null || depth==null || reference==null || ls==null || rs==null || strip==null ||
        leftLimit==null || rightLimit==null || minFall==null) return stop('Enter measured section dimensions, side slopes, corridor limits and minimum fall.');
    if(reference>=depth) return stop('The reference depth must be below the bank top so there is positive geometric freeboard.');
    final fall=iz-oz, grade=100*fall/length;
    if(fall<=0 || grade<minFall-1e-10) return stop('The invert must fall downstream and meet the supplied minimum grade.');
    final left=bottom/2+ls*depth,right=bottom/2+rs*depth,topWidth=left+right;
    final leftReserve=left+strip,rightReserve=right+strip;
    String m(num value)=>(value/1000).toStringAsFixed(3);
    if(leftReserve>leftLimit+1e-6) return stop('Left bank and maintenance strip need ${m(leftReserve)} m, beyond the ${m(leftLimit)} m left corridor limit.');
    if(rightReserve>rightLimit+1e-6) return stop('Right bank and maintenance strip need ${m(rightReserve)} m, beyond the ${m(rightLimit)} m right corridor limit.');
    final leftRef=bottom/2+ls*reference, rightRef=bottom/2+rs*reference;
    final area=reference*(bottom+leftRef+rightRef)/2e6, freeboard=(depth-reference).toDouble();
    final ux=dx/length,uy=dy/length;
    // Positive offset is left when looking from inlet to outlet.
    CadPoint p(num chain,num off)=>CadPoint(ix+ux*chain-uy*off,iy+uy*chain+ux*off);
    final planLines=<CadLine>[],planLabels=<CadLabel>[];
    void longitudinal(String layer,num off)=>planLines.add(CadLine(layer,p(0,off),p(length,off)));
    for(final (layer,l,r) in [('OPEN_DRAIN_CORRIDOR',leftLimit,rightLimit),('OPEN_DRAIN_STRIP',leftReserve,rightReserve),
        ('OPEN_DRAIN_BANK',left,right),('OPEN_DRAIN_BOTTOM',bottom/2,bottom/2)]) {
      longitudinal(layer,l);longitudinal(layer,-r);
    }
    longitudinal('OPEN_DRAIN_AXIS',0);
    for(final s in [0.0,length]) {
      planLines.add(CadLine('OPEN_DRAIN_BANK',p(s,left),p(s,-right)));
    }
    final text=(math.max(length,leftLimit+rightLimit)/90).clamp(40,15000).toDouble();
    final arrow=math.min(length*.07,text*2);
    planLines.addAll([CadLine('OPEN_DRAIN_AXIS',p(length*.58-arrow,arrow*.4),p(length*.58,0)),
      CadLine('OPEN_DRAIN_AXIS',p(length*.58-arrow,-arrow*.4),p(length*.58,0))]);
    final corners=[p(0,leftLimit),p(0,-rightLimit),p(length,leftLimit),p(length,-rightLimit)];
    final xmin=corners.map((c)=>c.x).reduce(math.min),xmax=corners.map((c)=>c.x).reduce(math.max);
    final ymin=corners.map((c)=>c.y).reduce(math.min),ymax=corners.map((c)=>c.y).reduce(math.max),cx=(xmin+xmax)/2;
    final angle=math.atan2(uy,ux)*180/math.pi;
    final readableAngle=angle>90 ? angle-180 : angle < -90 ? angle+180 : angle;
    final endLabels=[p(-text*2,0),p(length+text*2,0)];
    planLabels.add(CadLabel('OPEN_DRAIN_AXIS',endLabels.first,'INLET',text*.7,angle:readableAngle));
    planLabels.add(CadLabel('OPEN_DRAIN_AXIS',endLabels.last,'OUTLET',text*.7,angle:readableAngle));
    planLabels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+text*7.3),'SURVEYED OPEN DRAIN / PROJECTED MM',text),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+text*5.9),'${m(length)} M REACH / GRADE ${grade.toStringAsFixed(3)}% / BANK TOP WIDTH ${m(topWidth)} M',text*.65),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+text*4.6),'GRID: $grid',text*.6),
      CadLabel('ANNOTATIONS',CadPoint(cx,ymax+text*3.3),'DATUM: $datum',text*.6),
    ]);
    final northX=math.max(xmax+text*4,cx+text*34);
    planLabels.add(CadLabel('ANNOTATIONS',CadPoint(northX,ymax+text),'GRID N',text*.65));
    planLines.addAll([CadLine('ANNOTATIONS',CadPoint(northX,ymax-text*2),CadPoint(northX,ymax)),
      CadLine('ANNOTATIONS',CadPoint(northX-text*.5,ymax-text),CadPoint(northX,ymax)),
      CadLine('ANNOTATIONS',CadPoint(northX+text*.5,ymax-text),CadPoint(northX,ymax))]);
    final plan=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(xmin-text*5,cx-text*34).floor(),(ymin-text*5).floor(),
      (northX+text*3).ceil(),(ymax+text*9).ceil()),lines:planLines,labels:planLabels);

    final slines=<CadLine>[],slabels=<CadLabel>[];
    void seg(List<CadLine> list,String layer,num x,num y,num ex,num ey)=>list.add(CadLine(layer,CadPoint(x,y),CadPoint(ex,ey)));
    seg(slines,'OPEN_DRAIN_BANK',-left,depth,-bottom/2,0);
    seg(slines,'OPEN_DRAIN_BOTTOM',-bottom/2,0,bottom/2,0);
    seg(slines,'OPEN_DRAIN_BANK',bottom/2,0,right,depth);
    seg(slines,'OPEN_DRAIN_REF',-leftRef,reference,rightRef,reference);
    seg(slines,'OPEN_DRAIN_STRIP',-leftReserve,depth,-left,depth);
    seg(slines,'OPEN_DRAIN_STRIP',right,depth,rightReserve,depth);
    final st=(math.max(leftReserve+rightReserve,depth)/44).clamp(20,10000).toDouble();
    void note(List<CadLabel> list,num x,num y,String title,num size)=>list.add(CadLabel('ANNOTATIONS',CadPoint(x,y),title,size));
    note(slabels,0,depth+st*6,'TYPICAL TRANSVERSE SECTION / LOOKING DOWNSTREAM / TRUE SCALE MM',st);
    note(slabels,0,depth+st*4.6,'BOTTOM ${m(bottom)} M / TOP ${m(topWidth)} M / BANK DEPTH ${m(depth)} M',st*.65);
    note(slabels,0,depth+st*3.25,'REFERENCE ${m(reference)} M / AREA ${area.toStringAsFixed(3)} M2 / FREEBOARD ${m(freeboard)} M',st*.65);
    note(slabels,0,depth+st*1.9,'GEOMETRY ONLY / NOT A WATER SURFACE MODEL',st*.6);
    final section=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-leftReserve-st*3,-st*29).floor(),(-st*3).floor(),
      math.max(rightReserve+st*3,st*29).ceil(),(depth+st*7.5).ceil()),lines:slines,labels:slabels);

    final plines=<CadLine>[],plabels=<CadLabel>[];
    seg(plines,'OPEN_DRAIN_BOTTOM',0,0,length,-fall);
    seg(plines,'OPEN_DRAIN_BANK',0,depth,length,depth-fall);
    seg(plines,'OPEN_DRAIN_REF',0,reference,length,reference-fall);
    seg(plines,'OPEN_DRAIN_AXIS',0,0,0,depth);
    seg(plines,'OPEN_DRAIN_AXIS',length,-fall,length,depth-fall);
    final pt=(math.max(length,fall+depth)/55).clamp(20,18000).toDouble();
    note(plabels,length/2,depth+pt*6,'INVERT PROFILE / TRUE SCALE MM / LOCAL VERTICAL ZERO AT INLET INVERT',pt);
    note(plabels,length/2,depth+pt*4.6,'INLET RL ${m(iz)} M / OUTLET RL ${m(oz)} M / FALL ${m(fall)} M',pt*.65);
    note(plabels,length/2,depth+pt*3.25,'CHAINAGE 0 TO ${m(length)} M / GRADE ${grade.toStringAsFixed(3)}%',pt*.65);
    note(plabels,length/2,depth+pt*1.9,'BANK AND REFERENCE LINES ARE DESIGN OFFSETS / NO SURVEYED GROUND',pt*.6);
    final profile=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-pt*3,length/2-pt*32).floor(),(-fall-pt*3).floor(),
      math.max(length+pt*3,length/2+pt*32).ceil(),(depth+pt*7.5).ceil()),lines:plines,labels:plabels);
    return OpenDrainCadResult(plan:plan,section:section,profile:profile,lengthMm:length,grade:grade,
      topWidthMm:topWidth,referenceAreaM2:area,freeboardMm:freeboard);
  }
}
