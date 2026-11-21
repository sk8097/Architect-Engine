import '../data/badminton_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanPartition;

class BadmintonCadResult {
  const BadmintonCadResult(this.plan,this.issue,{this.zones=const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
}

/// Rectangular badminton training hall. Playing lines are driven by the
/// supplied dimensions and are not certified competition markings.
class BadmintonCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='badminton_hall';

  BadmintonCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    BadmintonCadResult stop(String issue)=>BadmintonCadResult(null,issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion) {
      return stop('Save the court hall brief with the current measured requirements.');
    }
    if(sel.categoryId!='institutional' || sel.subcategoryId!='sports' || !badmintonCadTypes.contains(sel.typeId)) {
      return stop('Select a supported indoor sports hall, club, training or recreation centre for this badminton template.');
    }
    final a=snap.answers;
    bool positive(String id)=>a[id] is num && (a[id] as num)>0;
    if(brief.floorCount!=1 || (a['building_count']??1)!=1 || positive('basements') || positive('mezzanines') ||
        !const {null,'indoor'}.contains(sel.configurationId)) return stop('Use one indoor ground-floor hall, not a campus, mezzanine or outdoor sports layout.');
    if(!const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        const {'existing','brownfield','partial_demolition'}.contains(a['build_status']) ||
        const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) return stop('This is a new hall concept, not a surveyed retrofit or approval drawing.');
    if(!const {null,ProjectParking.none}.contains(brief.parking) || a['parking_sqft']!=null || a['terrace_needed']=='yes') {
      return stop('Parking and accessible terraces are not drawn by this court hall template.');
    }
    if(!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and a cardinal entrance frontage.');
    }
    final spaces=sel.spaceQuantities;
    final count=spaces['field_court'],viewing=spaces.containsKey('spectator_seating');
    if(count==null || count<1 || count>2 || spaces['athlete_change']!=1 ||
        (viewing && spaces['spectator_seating']!=1) || spaces.keys.any((id)=>!const {'field_court','athlete_change','spectator_seating'}.contains(id))) {
      return stop('Include one or two identical Field/Court spaces and one Athlete Change room, with at most one spectator strip. No other rooms or accessible bleachers are drawn.');
    }
    if(a['activity_areas']!=count) return stop('The facility court count must match the measured Field/Court quantity.');
    final seats=a['spectators'];
    if(viewing ? (seats is! int || seats<1 || seats>200) : !const {null,0}.contains(seats)) {
      return stop('Enter 1–200 spectator seats if a viewing strip is selected, or zero without a viewing strip.');
    }
    int? mm(Object? raw,{bool zero=false}) {
      if(raw is! num || !raw.isFinite || raw<0 || raw>300) return null;
      final n=(raw*1000).round();
      return n>0 || zero?n:null;
    }
    final plotW=mm(widthFt*.3048),plotD=mm(depthFt*.3048),w=mm(a['cad_plate_width']),d=mm(a['cad_plate_depth']);
    final x=mm(a['cad_offset_left'],zero:true),y=mm(a['cad_offset_front'],zero:true),t=mm(a['cad_wall']);
    final door=mm(a['cad_door']),walk=mm(a['bc_player_walk']);
    if(plotW==null || plotD==null || w==null || d==null || x==null || y==null || t==null || door==null || walk==null ||
        (sel.plotShapeId=='square' && plotW!=plotD)) return stop('Enter measured plot, shell, offsets, walls, shared door width and player walk.');
    for(final (side,available) in [('left',x),('right',plotW-x-w),('front',y),('rear',plotD-y-d)]) {
      final raw=a['${side}_setback'],setback=raw==null?0:mm(raw,zero:true);
      if(setback==null || available<setback) return stop('The hall conflicts with the plot boundary or $side setback.');
    }
    final fsi=a['fsi_limit'],coverage=a['coverage_limit'];
    if(fsi is num && w*d>plotW*plotD*fsi) return stop('The gross hall exceeds the supplied FAR/FSI allowance.');
    if(coverage is num && w*d>plotW*plotD*coverage/100) return stop('The gross hall exceeds the supplied coverage allowance.');
    if(y<=0 || door<=t || walk<door) return stop('The front player approach must span the door and have clear depth to the plot boundary.');
    final dims=<String,(int,int)>{};
    for(final id in spaces.keys) {
      final details=snap.spaceDetails[id]??const <String,Object>{};
      final width=mm(details['width']),depth=mm(details['length']);
      if(width==null || depth==null) return stop('$id: enter measured clear width and length. For Field/Court, measure the marked playing rectangle, not the run-off.');
      if(!const {'','0','g','ground','ground floor'}.contains('${details['floor_level']??''}'.trim().toLowerCase())) return stop('$id must be on the ground floor.');
      final edge=details['zone_edge'], edges=switch(id) {'athlete_change'=>const {'front','left'},'spectator_seating'=>const {'front','right','rear'},_=>const <String>{}};
      if(edge!=null && edge!='any' && !edges.contains(edge)) return stop('$id conflicts with the required edge. The court markings must be inset for run-off.');
      if(id=='athlete_change' && details['access']=='public') return stop('Athlete Change belongs to the player side, not the public viewing route.');
      if(details['daylight']=='required' || details['cad_window']!=null) return stop('Window placement and indoor lighting are not specified in this court hall template.');
      final adjacent=details['adjacent_required'];
      if(adjacent is Iterable && adjacent.isNotEmpty) return stop('The changing room and court connect through a lobby; additional direct room adjacencies are not supported.');
      for(final key in ['area_min','area_max']) {
        final area=details[key];
        if(area==null) continue;
        final unit=details['area_unit'];
        if (area is! num || !const {'sqm','sqft'}.contains(unit)) return stop('$id needs a valid area unit for its supplied limit.');
        final target=area*(unit=='sqft' ? .09290304 : 1),actual=width*depth/1000000;
        if(key=='area_min'?actual<target-.001:actual>target+.001) return stop('$id measured geometry conflicts with the supplied area limit.');
      }
      dims[id]=(width,depth);
    }
    final (courtW,courtL)=dims['field_court']!;
    final (changeW,changeD)=dims['athlete_change']!;
    final side=mm(a['bc_side_clear']),end=mm(a['bc_end_clear']),singles=mm(a['bc_singles_inset']);
    final short=mm(a['bc_short_service']),long=mm(a['bc_long_service']);
    if(side==null || end==null || singles==null || short==null || long==null) return stop('Enter measured run-off, singles inset and both service-line offsets.');
    if(2*singles>=courtW || short+long>=courtL~/2) return stop('Singles and service markings must be inside the supplied playing boundary without crossing.');
    final iw=w-2*t,id=d-2*t;
    final viewW=dims['spectator_seating']?.$1??0, mainW=iw-(viewing?viewW+t:0),hallStart=changeD+t;
    final playW=count*(courtW+2*side),playD=courtL+2*end;
    if(playW>mainW || playD>id-hallStart) return stop('The measured courts plus their full side and end run-offs do not fit in the playing hall.');
    final lobbyLeft=changeW+t,lobbyW=mainW-lobbyLeft;
    if(changeW<door || changeD<=2*door || lobbyW<=door || walk>lobbyW) {
      return stop('The changing room and player lobby must fit both lobby door swings and the measured approach.');
    }
    final glassStart=hallStart+t,glassEnd=id-t;
    int? viewAisle,seatSpan,seatDepth;
    if(viewing) {
      viewAisle=mm(a['bc_view_aisle']);seatSpan=mm(a['bc_seat_span']);seatDepth=mm(a['bc_seat_depth']);
      if(viewAisle==null || seatSpan==null || seatDepth==null || dims['spectator_seating']!.$2!=id ||
          viewAisle<=door || viewAisle+seatDepth>viewW || glassEnd-glassStart < (seats as int)*seatSpan) {
        return stop('The viewing strip must span the full inside depth and fit the entry aisle, door swing and all seats alongside the glazing.');
      }
    }
    final rotated=facing=='East'||facing=='West';
    PlanRect orient(PlanRect b)=>switch(facing) {
      'North'=>PlanRect(plotW-b.right,plotD-b.top,plotW-b.left,plotD-b.bottom),
      'East'=>PlanRect(plotD-b.top,b.left,plotD-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,plotW-b.right,b.top,plotW-b.left),_=>b,
    };
    PlanRect rect(int l,int b,int r,int top)=>orient(PlanRect(x+t+l,y+t+b,x+t+r,y+t+top));
    const outside=AutomaticFloorPlan.entry,lobby='badminton_lobby',change='badminton_change',hall='badminton_hall',view='badminton_view';
    final rooms=[PlanRoom(lobby,'Player lobby',rect(lobbyLeft,0,mainW,changeD)),PlanRoom(change,'Athlete Change reserve',rect(0,0,changeW,changeD)),
      PlanRoom(hall,'Playing hall',rect(0,hallStart,mainW,id))];
    final walls=[rect(-t,-t,0,id+t),rect(iw,-t,iw+t,id+t),rect(0,id,iw,id+t)];
    final openings=<PlanOpening>[],zones=<MeasuredZone>[],markings=<PlanMarking>[];
    void wall(int l,int b,int r,int top) {if(l<r && b<top) walls.add(rect(l,b,r,top));}
    void threshold(int y,int x,String from,String to) => openings.add(PlanOpening(PlanOpeningKind.door,rect(x,y,x+door,y+t),from,to));
    void mark(String layer,int x1,int y1,int x2,int y2) {
      final a=rect(x1,y1,x1,y1),b=rect(x2,y2,x2,y2);
      markings.add(PlanMarking(layer,a.left,a.bottom,b.left,b.bottom));
    }
    final entry=lobbyLeft+(lobbyW-door)~/2, walkway=entry-(walk-door)~/2;
    wall(0,-t,entry,0);
    threshold(-t,entry,outside,lobby);
    wall(0,changeD,entry,hallStart);wall(entry+door,changeD,mainW,hallStart);
    // Swing back into the lobby, not into the court run-off.
    threshold(changeD,entry,hall,lobby);
    final c=(changeD-door)~/2;
    wall(changeW,0,lobbyLeft,c);wall(changeW,c+door,lobbyLeft,changeD);
    openings.add(PlanOpening(PlanOpeningKind.door,rect(changeW,c,lobbyLeft,c+door),lobby,change));
    zones.add(MeasuredZone('bc_player_walk','Player approach',rect(walkway,-y-t,walkway+walk,-t),'BADMINTON_PLAYERS'));
    if(viewing) {
      final vx=mainW+t,aisle=viewAisle!,span=seatSpan!,dep=seatDepth!,n=seats as int;
      final vEntry=vx+(aisle-door)~/2;
      wall(entry+door,-t,vEntry,0);wall(vEntry+door,-t,iw,0);
      // Continuous plan separation with a glazed viewing opening to the
      // court hall only. It is not a doorway or an engineered barrier.
      if(glassEnd-glassStart<=t) return stop('The viewing strip leaves no usable glazed opening to the hall.');
      wall(mainW,0,vx,glassStart);wall(mainW,glassEnd,vx,id);
      final glazing=rect(mainW,glassStart,vx,glassEnd);
      openings.add(PlanOpening(PlanOpeningKind.window,glazing,hall,view));
      zones.add(MeasuredZone('bc_view_divider','Glazed viewing opening',glazing,'BADMINTON_VIEW_DIVIDER'));
      threshold(-t,vEntry,outside,view);
      rooms.add(PlanRoom(view,'Separate spectator strip',rect(vx,0,iw,id)));
      final walkX=vEntry-(aisle-door)~/2;
      zones.addAll([
        MeasuredZone('bc_view_walk','Spectator approach',rect(walkX,-y-t,walkX+aisle,-t),'BADMINTON_SPECTATOR'),
        MeasuredZone('bc_view_aisle','Viewing aisle',rect(vx,0,vx+aisle,id),'BADMINTON_SPECTATOR'),
        for(var i=0;i<n;i++) MeasuredZone('bc_seat_$i','Seat ${i+1}',rect(vx+aisle,glassStart+i*span,vx+aisle+dep,glassStart+(i+1)*span),'BADMINTON_SEATS'),
      ]);
    } else {wall(entry+door,-t,iw,0);}
    final playX=(mainW-playW)~/2,playY=hallStart+(id-hallStart-playD)~/2;
    for(var i=0;i<count;i++) {
      final runX=playX+i*(courtW+2*side),lx=runX+side,b=playY+end,rx=lx+courtW,top=b+courtL,mid=b+courtL~/2;
      zones.addAll([
        MeasuredZone('bc_runoff_$i','Court ${i+1} clear envelope',rect(runX,playY,runX+courtW+2*side,playY+playD),'BADMINTON_RUNOFF'),
        MeasuredZone('bc_court_$i','Court ${i+1}',rect(lx,b,rx,top),'BADMINTON_COURTS'),
      ]);
      for(final xx in [lx+singles,rx-singles]) {mark('BADMINTON_LINES',xx,b,xx,top);}
      for(final yy in [b+long,top-long,mid-short,mid+short]) {mark('BADMINTON_LINES',lx,yy,rx,yy);}
      final center=lx+courtW~/2;
      mark('BADMINTON_LINES',center,b,center,mid-short);mark('BADMINTON_LINES',center,mid+short,center,top);
      mark('BADMINTON_NET',lx,mid,rx,mid);
    }
    final plan=AutomaticFloorPlan(plot:PlanRect(0,0,rotated?plotD:plotW,rotated?plotW:plotD),
      footprint:orient(PlanRect(x,y,x+w,y+d)),facing:facing,sheetTitle:'INDOOR BADMINTON / COURTS & SEPARATE ACCESS',
      rooms:rooms,walls:walls,openings:openings,markings:markings);
    final issue=validatePlanPartition(plan);
    if(issue!=null) return stop('The measured hall failed geometry validation: $issue');
    return BadmintonCadResult(plan,null,zones:List.unmodifiable(zones));
  }
}
