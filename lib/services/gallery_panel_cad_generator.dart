import 'dart:math' as math;

import '../data/gallery_panel_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class GalleryDisplayFace {
  const GalleryDisplayFace(this.panel,this.side,this.xMm,this.startMm,this.endMm);
  final String panel,side;
  final num xMm,startMm,endMm;
}

class GalleryPanelCadResult {
  const GalleryPanelCadResult({this.drawing,this.issue,this.faces=const [],this.panels=0,this.widthMm=0,this.depthMm=0,
    this.displayHeightMm=0,this.displayM=0,this.displayM2=0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<GalleryDisplayFace> faces;
  final int panels,widthMm,depthMm,displayHeightMm;
  final double displayM,displayM2;

  String? toCsv() {
    if(drawing==null) return null;
    String m(num mm)=>(mm/1000).toStringAsFixed(3);
    return [
      'panel,face,west_offset_m,south_start_m,south_end_m,usable_length_m,hanging_height_m,usable_area_m2',
      for(final f in faces) [f.panel,f.side,m(f.xMm),m(f.startMm),m(f.endMm),m(f.endMm-f.startMm),m(displayHeightMm),
        ((f.endMm-f.startMm)*displayHeightMm/1e6).toStringAsFixed(6)].join(','),
    ].join('\r\n')+'\r\n';
  }
}

/// One symmetrical ground-floor gallery. Clear through lanes are distinct
/// from the reserved area needed to view a panel face.
class GalleryPanelCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='gallery_panel_layout';

  GalleryPanelCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt}) {
    GalleryPanelCadResult stop(String issue)=>GalleryPanelCadResult(issue:issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !galleryPanelCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) {
      return stop('Select Museum, Gallery or Art Centre and save the measured display-panel brief.');
    }
    if(!const {null,'main_hall'}.contains(sel.configurationId) ||
        !const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        brief.floorCount!=1 || !const {null,ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one ground-floor gallery hall without parking or separate Space selections.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a=snap.answers;
    int? mm(Object? v,{bool zero=false,int max=100}) {
      if(v is! num || !v.isFinite || v<(zero?0:.001) || v>max) return null;
      return (v*1000).round();
    }
    final pw=mm(widthFt*.3048,max:2000),pd=mm(depthFt*.3048,max:2000),pairs=a['gp_pairs'];
    final length=mm(a['gp_length']),thick=mm(a['gp_thick'],max:5),margin=mm(a['gp_end_margin'],zero:true);
    final height=mm(a['gp_display_height'],max:20),view=mm(a['gp_view']),middle=mm(a['gp_middle']);
    final between=mm(a['gp_between'],zero:true),side=mm(a['gp_side']),front=mm(a['gp_front']),rear=mm(a['gp_rear']);
    final door=mm(a['gp_door']),wall=mm(a['gp_wall'],max:5),west=mm(a['gp_west'],zero:true,max:2000),south=mm(a['gp_south'],zero:true,max:2000);
    if(pw==null || pd==null || pairs is! int || pairs<1 || pairs>10 || length==null || thick==null || margin==null ||
        height==null || view==null || middle==null || between==null || side==null || front==null || rear==null ||
        door==null || wall==null || west==null || south==null || (sel.plotShapeId=='square' && pw!=pd)) {
      return stop('Enter measured plot, panel, viewing, passage and hall dimensions.');
    }
    final active=length-2*margin;
    if(active<=0) return stop('The end margins leave no positive usable display length.');
    if((pairs==1 && between!=0) || (pairs>1 && between==0)) {
      return stop('Use a positive inter-panel passage for more than one panel per bank, or zero for one panel per bank.');
    }
    if(door>middle) return stop('The entrance opening must be no wider than the aligned clear central aisle.');
    final bankWidth=pairs*(thick+2*view)+(pairs-1)*between;
    final width=2*(wall+side+bankWidth)+middle,depth=2*wall+front+length+rear;
    for(final (edge,clear) in [('left',west),('right',pw-west-width),('front',south),('rear',pd-south-depth)]) {
      final raw=a['${edge}_setback'],min=raw==null?0:mm(raw,zero:true,max:2000);
      if(min==null || clear<min) return stop('The gallery hall conflicts with the $edge plot edge or supplied setback.');
    }
    final ratio=width*depth/(pw*pd), fsi=a['fsi_limit'],coverage=a['coverage_limit'];
    if(fsi!=null && (fsi is! num || !fsi.isFinite || fsi<=0 || ratio>fsi+1e-12)) {
      return stop('The hall exceeds the supplied FSI or the FSI limit is invalid.');
    }
    if(coverage!=null && (coverage is! num || !coverage.isFinite || coverage<=0 || coverage>100 || ratio*100>coverage+1e-10)) {
      return stop('The hall exceeds the supplied site coverage or the coverage limit is invalid.');
    }
    final lines=<CadLine>[],labels=<CadLabel>[],faces=<GalleryDisplayFace>[];
    void line(String layer,num x,num y,num ex,num ey) {
      if(x!=ex || y!=ey) lines.add(CadLine(layer,CadPoint(x,y),CadPoint(ex,ey)));
    }
    void box(String layer,num x,num y,num ex,num ey) {
      line(layer,x,y,ex,y);line(layer,ex,y,ex,ey);line(layer,ex,ey,x,ey);line(layer,x,ey,x,y);
    }
    box('GALLERY_PLOT',0,0,pw,pd);
    final cx=west+width/2,entryL=cx-door/2,entryR=cx+door/2;
    void wallOutline(int x,int y,int ex,int ey) {
      line('GALLERY_WALL',x,y,entryL,y);line('GALLERY_WALL',entryR,y,ex,y);
      line('GALLERY_WALL',ex,y,ex,ey);line('GALLERY_WALL',ex,ey,x,ey);line('GALLERY_WALL',x,ey,x,y);
    }
    wallOutline(west,south,west+width,south+depth);
    wallOutline(west+wall,south+wall,west+width-wall,south+depth-wall);
    line('GALLERY_WALL',entryL,south,entryL,south+wall);line('GALLERY_WALL',entryR,south,entryR,south+wall);
    final y=south+wall+front,top=y+length,lowActive=y+margin,highActive=top-margin;
    final xStart=west+wall+side;
    final t=(math.max(pw,pd)/84).clamp(40,6500).toDouble();
    for(final (bank,bankStart) in [('W',xStart),('E',xStart+bankWidth+middle)]) {
      for(var i=0;i<pairs;i++) {
        final viewLeft=bankStart+i*(thick+2*view+between),x=viewLeft+view;
        final id='$bank${i+1}';
        line('GALLERY_PANEL',x,y,x+thick,y);line('GALLERY_PANEL',x,top,x+thick,top);
        for(final (orientation,faceX,viewX) in [('west',x,viewLeft),('east',x+thick,x+thick+view)]) {
          line('GALLERY_PANEL',faceX,y,faceX,lowActive);
          line('GALLERY_FACE',faceX,lowActive,faceX,highActive);
          line('GALLERY_PANEL',faceX,highActive,faceX,top);
          line('GALLERY_VIEW',faceX,lowActive,viewX,lowActive);
          line('GALLERY_VIEW',viewX,lowActive,viewX,highActive);
          line('GALLERY_VIEW',viewX,highActive,faceX,highActive);
          faces.add(GalleryDisplayFace(id,orientation,faceX,lowActive,highActive));
        }
        labels.add(CadLabel('GALLERY_PANEL',CadPoint(x+thick/2,y+length/2),id,
          math.min(t*.82,math.min(thick*.66,length/5)),angle:90));
      }
    }
    line('GALLERY_SPINE',cx,south+wall,cx,top+rear);
    final displayM=faces.length*active/1000,displayM2=faces.length*active*height/1e6;
    String m(num mm)=>(mm/1000).toStringAsFixed(3);
    final ax=pw+t*2;
    line('ANNOTATIONS',ax,pd-t*1.7,ax,pd);line('ANNOTATIONS',ax-t*.4,pd-t*.7,ax,pd);line('ANNOTATIONS',ax+t*.4,pd-t*.7,ax,pd);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(ax,pd+t),'N',t*.7),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*5.6),'GALLERY DISPLAY PANEL PLAN / LOCAL MM',t),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*4.2),'${pairs*2} PANELS / ${faces.length} DISPLAY FACES / ${m(middle)} M CLEAR CENTRAL AISLE',t*.65),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*2.8),'${displayM.toStringAsFixed(3)} M DISPLAY LENGTH / ${displayM2.toStringAsFixed(3)} M2 HANGING AREA',t*.65),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+t*1.4),'CONCEPT ONLY / ENTRANCE OPENING NOT AN EGRESS CHECK',t*.62),
    ]);
    final bounds=PlanRect(math.min(-2*t,pw/2-26*t).floor(),(-2*t).floor(),
      math.max(ax+3*t,pw/2+26*t).ceil(),(pd+7.2*t).ceil());
    return GalleryPanelCadResult(drawing:FloorPlanCad.fromEntities(bounds:bounds,lines:lines,labels:labels),
      faces:List.unmodifiable(faces),panels:pairs*2,widthMm:width,depthMm:depth,displayHeightMm:height,
      displayM:displayM,displayM2:displayM2);
  }
}
