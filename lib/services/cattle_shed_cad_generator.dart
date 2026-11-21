import '../data/cattle_shed_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;

class CattleShedResult {
  const CattleShedResult(this.plan,this.issue,{this.zones=const [],this.plannedCapacity=0});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
  final int plannedCapacity;
}

/// Double group-pen rows around a feed lane. Cleaning alleys are outboard,
/// with gated access to the pens and two measured rear pads. The rear pads
/// are not designed manure storage, vehicle circulation or effluent drainage.
class CattleShedCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='cattle_shed';

  CattleShedResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    CattleShedResult stop(String issue)=>CattleShedResult(null,issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion) {
      return stop('Save a cattle shed brief with the current measured requirements.');
    }
    if(sel.categoryId!='rural' || sel.subcategoryId!='farm' || !cattleShedTypes.contains(sel.typeId)) {
      return stop('This double-row group-pen template supports Dairy Farm and Cattle Farm only.');
    }
    final a=snap.answers;
    bool positive(String id)=>a[id] is num && (a[id] as num)>0;
    if(brief.floorCount!=1 || (a['building_count']??1)!=1 || positive('basements') || positive('mezzanines') ||
       !const {null,'production_site'}.contains(sel.configurationId)) {
      return stop('Use one ground-floor production shed only, not a residence, compound or multi-building farm.');
    }
    if(!const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
       const {'existing','brownfield','partial_demolition'}.contains(a['build_status']) ||
       const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) {
      return stop('This is a new group-pen concept, not a surveyed retrofit or approval drawing.');
    }
    if(!const {null,ProjectParking.none}.contains(brief.parking) || a['parking_sqft']!=null || a['terrace_needed']=='yes' || sel.spaceQuantities.isNotEmpty) {
      return stop('This drawing only models the measured cattle shed, not other Space selections, parking or an accessible terrace.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','South','East','West'}.contains(facing)) {
      return stop('Use a rectangular or square measured plot and a cardinal feed entrance frontage.');
    }
    if(a['df_access']!='confirmed') return stop('Confirm independent on-site access to the front feed door and both rear cleaning doors.');
    final pens=a['df_pens'],each=a['df_animals_per_pen'],herd=a['animal_capacity'];
    if(pens is! int || pens<1 || pens>20 || each is! int || each<1 || each>50 || herd is! int || herd<1 || herd>2000) {
      return stop('Enter 1–20 pens per row, 1–50 planned animals per pen and a positive whole herd count.');
    }
    final capacity=2*pens*each;
    if(herd>capacity) return stop('The planned herd of $herd exceeds $capacity places from the supplied pen count and animals per pen. This is not a welfare capacity check.');

    int? mm(Object? raw,{bool zero=false}) {
      if(raw is! num || !raw.isFinite || raw<0 || raw>300) return null;
      final n=(raw*1000).round();
      return n>0 || zero?n:null;
    }
    final plotW=mm(widthFt*.3048),plotD=mm(depthFt*.3048),w=mm(a['cad_plate_width']),d=mm(a['cad_plate_depth']);
    final x=mm(a['cad_offset_left'],zero:true),y=mm(a['cad_offset_front'],zero:true),t=mm(a['cad_wall']);
    if(plotW==null || plotD==null || w==null || d==null || x==null || y==null || t==null ||
       (sel.plotShapeId=='square' && plotW!=plotD)) return stop('Enter the measured plot, shed envelope, offsets and outer wall thickness.');
    for(final (side,space) in [('left',x),('right',plotW-x-w),('front',y),('rear',plotD-y-d)]) {
      final raw=a['${side}_setback'],setback=raw==null?0:mm(raw,zero:true);
      if(setback==null || space<setback) return stop('The shed conflicts with the plot or the supplied $side setback.');
    }
    final fsi=a['fsi_limit'],coverage=a['coverage_limit'];
    if(fsi is num && w*d>plotW*plotD*fsi) return stop('The shed exceeds the supplied FAR/FSI allowance.');
    if(coverage is num && w*d>plotW*plotD*coverage/100) return stop('The shed exceeds the supplied site coverage.');
    final pw=mm(a['df_pen_width']),pd=mm(a['df_pen_depth']),r=mm(a['df_rail']);
    final feed=mm(a['df_feed_lane']),clean=mm(a['df_scrape_lane']),trough=mm(a['df_trough']);
    final gate=mm(a['df_pen_gate']),entry=mm(a['df_feed_door']),rear=mm(a['df_scrape_door']),pad=mm(a['df_scrape_pad']);
    if(pw==null || pd==null || r==null || feed==null || clean==null || trough==null || gate==null || entry==null || rear==null || pad==null) {
      return stop('Enter measured pen, barrier, passage, trough, door, gate and rear pad sizes.');
    }
    final neededW=2*t+2*clean+2*pw+4*r+feed,neededD=2*t+pens*pd+(pens-1)*r;
    if(w!=neededW || d!=neededD) return stop('The two pen rows, lanes and barriers require exactly ${(neededW/1000).toStringAsFixed(3)} × ${(neededD/1000).toStringAsFixed(3)} m of gross shed. Reconcile the measured plate and clear dimensions.');
    if(gate<=r || pd-gate<2 || pw-trough<gate) {
      return stop('Each pen gate needs jambs and must swing clear of the trough. Check the gate width, barrier and clear pen dimensions.');
    }
    if(entry<=t || rear<=t || feed-entry<2 || clean-rear<2 || d-2*t<entry || d-2*t<rear) {
      return stop('The front feed door and both rear cleaning doors must fit their clear lanes and leave wall returns.');
    }
    if(y<=0 || y+d+pad>plotD) return stop('There is no clear front approach or the rear cleaning pads extend outside the plot.');

    final rotated=facing=='East'||facing=='West';
    PlanRect orient(PlanRect b)=>switch(facing) {
      'North'=>PlanRect(plotW-b.right,plotD-b.top,plotW-b.left,plotD-b.bottom),
      'East'=>PlanRect(plotD-b.top,b.left,plotD-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,plotW-b.right,b.top,plotW-b.left), _=>b,
    };
    final iw=w-2*t,id=d-2*t;
    PlanRect box(int l,int b,int rr,int top)=>orient(PlanRect(x+t+l,y+t+b,x+t+rr,y+t+top));
    final lp=clean+r, lf=lp+pw+r, rf=lf+feed, rp=rf+r, right=rp+pw+r;
    const feedId='dairy_feed_lane', leftId='dairy_scrape_left',rightId='dairy_scrape_right',outside=AutomaticFloorPlan.entry;
    final rooms=[
      PlanRoom(leftId,'Left cleaning alley',box(0,0,clean,id)),
      PlanRoom(feedId,'Centre feed lane',box(lf,0,rf,id)),
      PlanRoom(rightId,'Right cleaning alley',box(right,0,iw,id)),
    ];
    final walls=[box(-t,-t,0,id+t),box(iw,-t,iw+t,id+t),box(lp+pw,0,lf,id),box(rf,0,rp,id)];
    final openings=<PlanOpening>[],zones=<MeasuredZone>[];
    void wall(int l,int b,int rr,int top) {if(l<rr && b<top) walls.add(box(l,b,rr,top));}
    void facade(int yy,int width,List<(int,String)> cuts) {
      var previous=0;
      for(final (center,room) in cuts) {
        final left=center-width~/2,end=left+width;
        wall(previous,yy,left,yy+t);
        openings.add(PlanOpening(PlanOpeningKind.door,box(left,yy,end,yy+t),outside,room));
        previous=end;
      }
      wall(previous,yy,iw,yy+t);
    }
    facade(-t,entry,[(lf+feed~/2,feedId)]);
    facade(id,rear,[(clean~/2,leftId),(right+clean~/2,rightId)]);
    for(var i=0;i<pens;i++) {
      final b=i*(pd+r),top=b+pd,opening=b+(pd-gate)~/2;
      for(final (side,l,rail,alley) in [('Left',lp,clean,leftId),('Right',rp,rp+pw,rightId)]) {
        final key='dairy_pen_${side.toLowerCase()}_${i+1}';
        rooms.add(PlanRoom(key,'$side pen ${i+1}',box(l,b,l+pw,top)));
        wall(rail,b,rail+r,opening); wall(rail,opening+gate,rail+r,top);
        openings.add(PlanOpening(PlanOpeningKind.door,box(rail,opening,rail+r,opening+gate),alley,key));
        final tr=side=='Left'?l+pw-trough:l;
        zones.add(MeasuredZone('${key}_trough','Feed trough',box(tr,b,tr+trough,top),'DAIRY_TROUGHS'));
        if(i<pens-1) wall(side=='Left'?rail:l,top,side=='Left'?l+pw:rail+r,top+r);
      }
    }
    zones.addAll([
      MeasuredZone('dairy_front_walk','Front feed approach',box(lf,-y-t,rf,-t),'DAIRY_FEED_ACCESS'),
      MeasuredZone('dairy_left_pad','Left cleaning pad',box(0,id+t,clean,id+t+pad),'DAIRY_CLEAN_ACCESS'),
      MeasuredZone('dairy_right_pad','Right cleaning pad',box(right,id+t,iw,id+t+pad),'DAIRY_CLEAN_ACCESS'),
    ]);
    final plan=AutomaticFloorPlan(plot:PlanRect(0,0,rotated?plotD:plotW,rotated?plotW:plotD),
      footprint:orient(PlanRect(x,y,x+w,y+d)),facing:facing,sheetTitle:'CATTLE SHED / FEED AND CLEANING ACCESS',
      rooms:rooms,walls:walls,openings:openings);
    final issue=validatePlanGeometry(plan,sealedRooms:rooms.where((r)=>r.id!=feedId).map((r)=>r.id).toSet(),
      secondaryExteriorDoorRooms:{leftId,rightId});
    if(issue!=null) return stop('The cattle shed failed geometry validation: $issue');
    return CattleShedResult(plan,null,zones:List.unmodifiable(zones),plannedCapacity:capacity);
  }
}
