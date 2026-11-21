import 'dart:math' as math;

import '../data/paired_apartment_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;

class PairedApartmentResult {
  const PairedApartmentResult(this.plan,this.issue,{this.zones=const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
}

/// Two mirror-image ground-floor 1 BHK units reached only from one shared lobby.
class PairedApartmentGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output']=='paired_apartments';

  PairedApartmentResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    PairedApartmentResult stop(String issue) => PairedApartmentResult(null,issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if (sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion ||
        !pairedApartmentEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) return stop('Select a supported low-rise apartment type and save the current paired-unit brief.');
    final a=snap.answers;
    bool positive(String id)=>a[id] is num && (a[id] as num)>0;
    if (brief.floorCount!=1 || (a['building_count']??1)!=1 || positive('basements') || positive('mezzanines') ||
        !const {null,'low_rise','walk_up'}.contains(sel.configurationId)) {
      return stop('This paired template requires one ground-floor building; no upper levels, basement or tower are drawn.');
    }
    if (!const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        const {'existing','brownfield','partial_demolition'}.contains(a['build_status']) ||
        const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) {
      return stop('This draws a new concept, not a surveyed conversion or approval drawing.');
    }
    if (!const {null,ProjectParking.none}.contains(brief.parking) || a['parking_sqft']!=null || a['terrace_needed']=='yes' || sel.spaceQuantities.isNotEmpty) {
      return stop('This template already draws both flats, the shared lobby and service reserve. Leave separate Space selections empty; parking and terraces are not drawn.');
    }
    final mix=a['apartment_mix'], layout=a['unit_layout'];
    if (a['unit_count']!=2 || (a['units_per_floor']??2)!=2 || (a['tower_count']??1)!=1 ||
        (mix!=null && (mix is! Iterable || mix.any((v)=>v!='1_bhk')))) {
      return stop('Use exactly two identical 1 BHK apartments on the same floor.');
    }
    if (layout!=null && (layout is! Iterable || layout.any((v)=>!const {'dual','corner','through','open_kitchen'}.contains(v)))) {
      return stop('This template uses an open kitchen and front and rear windows; alternate kitchen, balcony and split-level layouts are not drawn.');
    }
    if (!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and cardinal entrance frontage.');
    }
    int? mm(Object? raw,{bool zero=false}) {
      if (raw is! num || !raw.isFinite || raw<0 || raw>300) return null;
      final n=(raw*1000).round();
      return n>0 || zero?n:null;
    }
    final pw=mm(widthFt*.3048),pd=mm(depthFt*.3048),w=mm(a['cad_plate_width']),d=mm(a['cad_plate_depth']);
    final x=mm(a['cad_offset_left'],zero:true),y=mm(a['cad_offset_front'],zero:true),t=mm(a['cad_wall']),door=mm(a['cad_door']);
    final lw=mm(a['pa_lobby_width']),ld=mm(a['pa_lobby_depth']),walk=mm(a['pa_walk']);
    final living=mm(a['pa_living_depth']),bath=mm(a['pa_bath_width']);
    final kl=mm(a['pa_kitchen_length']),kd=mm(a['pa_kitchen_depth']),clear=mm(a['pa_kitchen_clear']);
    final frontWindow=mm(a['pa_living_window']),rearWindow=mm(a['pa_bed_window']);
    if (pw==null || pd==null || w==null || d==null || x==null || y==null || t==null || door==null || lw==null || ld==null ||
        walk==null || living==null || bath==null || kl==null || kd==null || clear==null || frontWindow==null || rearWindow==null ||
        (sel.plotShapeId=='square' && pw!=pd)) return stop('Enter measured plot, plate, offsets, walls, shared approach, room, kitchen and window dimensions.');
    for(final (side,available) in [('left',x),('right',pw-x-w),('front',y),('rear',pd-y-d)]) {
      final raw=a['${side}_setback'],setback=raw==null?0:mm(raw,zero:true);
      if(setback==null || available<setback) return stop('The apartment footprint conflicts with the plot or the supplied $side setback.');
    }
    final fsi=a['fsi_limit'],coverage=a['coverage_limit'];
    if (fsi is num && w*d>pw*pd*fsi) return stop('The combined apartment plate exceeds the supplied FAR/FSI.');
    if (coverage is num && w*d>pw*pd*coverage/100) return stop('The apartment footprint exceeds the supplied coverage allowance.');
    final iw=w-2*t,id=d-2*t,uw=(iw-lw-2*t)~/2;
    final lobbyLeft=uw+t,lobbyRight=iw-uw-t,rear=living+t,service=ld+t,bedW=uw-bath-t;
    if (y<=0 || door<=t || lw<=door || walk<door || walk>lw || math.min(living,ld)<=door || id-service<door) {
      return stop('The shared lobby and approach must span the entrances; leave space for the shared reserve door swing.');
    }
    if (bedW<=door || bath<=door || id-rear<door) return stop('Each mirrored bedroom and bathroom must fit its door and rear room width and depth.');
    if (kl>living || kd+clear+door>uw || (living-kl<door && kd>(bedW-door)~/2)) return stop('The kitchen counter and working clearance conflict with the living room depth, bedroom approach or flat-entry door swing.');
    final winX=(uw-frontWindow)~/2,bedWinX=(bedW-rearWindow)~/2;
    if (frontWindow<=t || rearWindow<=t || winX<kd || uw-winX-frontWindow<1 || bedWinX<1 || bedW-bedWinX-rearWindow<1) {
      return stop('The front/rear windows need wall returns and must clear the side-wall kitchen counter.');
    }
    final rotated=facing=='East'||facing=='West';
    PlanRect orient(PlanRect b)=>switch(facing) {
      'North'=>PlanRect(pw-b.right,pd-b.top,pw-b.left,pd-b.bottom),
      'East'=>PlanRect(pd-b.top,b.left,pd-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,pw-b.right,b.top,pw-b.left),_=>b,
    };
    PlanRect rect(int l,int b,int r,int top)=>orient(PlanRect(x+t+l,y+t+b,x+t+r,y+t+top));
    const outside=AutomaticFloorPlan.entry,lobby='paired_lobby',reserve='paired_service';
    final rooms=[PlanRoom(lobby,'Shared entrance lobby',rect(lobbyLeft,0,lobbyRight,ld)),
      PlanRoom(reserve,'Shared service reserve',rect(lobbyLeft,service,lobbyRight,id))];
    final walls=[rect(-t,-t,0,id+t),rect(iw,-t,iw+t,id+t),rect(uw,id,iw-uw,id+t)];
    final openings=<PlanOpening>[],zones=<MeasuredZone>[];
    void wall(int l,int b,int r,int top) { if(l<r && b<top) walls.add(rect(l,b,r,top)); }
    final entryX=lobbyLeft+(lobbyRight-lobbyLeft-door)~/2,walkX=entryX-(walk-door)~/2;
    wall(uw,-t,entryX,0); wall(entryX+door,-t,iw-uw,0);
    openings.add(PlanOpening(PlanOpeningKind.door,rect(entryX,-t,entryX+door,0),outside,lobby));
    wall(lobbyLeft,ld,entryX,service); wall(entryX+door,ld,lobbyRight,service);
    openings.add(PlanOpening(PlanOpeningKind.door,rect(entryX,ld,entryX+door,service),lobby,reserve));
    zones.add(MeasuredZone('pa_walk','Shared front approach',rect(walkX,-y-t,walkX+walk,-t),'PAIRED_SHARED'));
    zones.add(MeasuredZone('pa_lobby','Shared entrance lobby',rect(lobbyLeft,0,lobbyRight,ld),'PAIRED_SHARED'));
    final doorY=(math.min(living,ld)-door)~/2;
    for (final left in [true,false]) {
      final prefix=left?'flat_a':'flat_b', label=left?'Flat A':'Flat B';
      final hall='${prefix}_living', bed='${prefix}_bed', toilet='${prefix}_bath';
      PlanRect wing(int l,int b,int r,int top)=>left?rect(l,b,r,top):rect(iw-r,b,iw-l,top);
      void solid(int l,int b,int r,int top) { if(l<r && b<top) walls.add(wing(l,b,r,top)); }
      void opening(PlanOpeningKind kind,String from,String to,int l,int b,int r,int top) =>
          openings.add(PlanOpening(kind,wing(l,b,r,top),from,to));
      rooms.addAll([
        PlanRoom(hall,'$label living / kitchen',wing(0,0,uw,living)),
        PlanRoom(bed,'$label bedroom',wing(0,rear,bedW,id)),
        PlanRoom(toilet,'$label bathroom reserve',wing(bedW+t,rear,uw,id)),
      ]);
      solid(uw,0,uw+t,doorY);
      opening(PlanOpeningKind.door,lobby,hall,uw,doorY,uw+t,doorY+door);
      solid(uw,doorY+door,uw+t,id);
      solid(0,-t,winX,0); solid(winX+frontWindow,-t,uw,0);
      opening(PlanOpeningKind.window,outside,hall,winX,-t,winX+frontWindow,0);
      solid(0,id,bedWinX,id+t); solid(bedWinX+rearWindow,id,uw,id+t);
      opening(PlanOpeningKind.window,outside,bed,bedWinX,id,bedWinX+rearWindow,id+t);
      final bd=(bedW-door)~/2,wd=bedW+t+(bath-door)~/2;
      solid(0,living,bd,rear); solid(bd+door,living,wd,rear); solid(wd+door,living,uw,rear);
      opening(PlanOpeningKind.door,hall,bed,bd,living,bd+door,rear);
      opening(PlanOpeningKind.door,hall,toilet,wd,living,wd+door,rear);
      solid(bedW,rear,bedW+t,id);
      zones.add(MeasuredZone('${prefix}_counter','Kitchen counter',wing(0,0,kd,kl),'PAIRED_COUNTER'));
      zones.add(MeasuredZone('${prefix}_work','Kitchen working clearance',wing(kd,0,kd+clear,kl),'PAIRED_CLEAR'));
    }
    final plan=AutomaticFloorPlan(plot:PlanRect(0,0,rotated?pd:pw,rotated?pw:pd), footprint:orient(PlanRect(x,y,x+w,y+d)),
      facing:facing,sheetTitle:'TWO MIRRORED 1 BHK / SHARED ENTRY',rooms:rooms,walls:walls,openings:openings);
    final issue=validatePlanGeometry(plan);
    return issue==null?PairedApartmentResult(plan,null,zones:List.unmodifiable(zones)):stop('Paired apartment geometry failed validation: $issue');
  }
}
