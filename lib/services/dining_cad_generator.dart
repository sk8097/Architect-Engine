import '../data/dining_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;

class DiningCadResult {
  const DiningCadResult(this.plan,this.issue,{this.zones=const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
}

/// One dining room, a front lobby and customer toilet, and two independent
/// service rooms. This is a plan of openings and clearances, not food safety design.
class DiningCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output']=='dining_service';

  DiningCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    DiningCadResult stop(String issue)=>DiningCadResult(null,issue);
    final sel=brief.taxonomy, snap=brief.requirements;
    if (sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion) {
      return stop('Save a dine-in brief with the current measured requirements.');
    }
    if (sel.categoryId!='commercial' || sel.subcategoryId!='food_service' || !diningCadTypes.contains(sel.typeId)) {
      return stop('Use a Restaurant, Café or Coffee Shop for this dine-in template.');
    }
    final a=snap.answers;
    if (brief.floorCount!=1 || (a['building_count']??1)!=1 ||
        ((a['basements'] as num?)??0)>0 || ((a['mezzanines'] as num?)??0)>0) {
      return stop('This dine-in layout needs one ground floor in a single building, without a basement or mezzanine.');
    }
    if (!const {null,'on_site_cooking'}.contains(sel.configurationId) ||
        !const {null,'casual','family','cafe'}.contains(a['restaurant_model'])) {
      return stop('This template draws casual/family dine-in or café service with on-site cooking, not delivery, bar or central production.');
    }
    if (!const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        const {'existing','partial_demolition','brownfield'}.contains(a['build_status']) ||
        const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) {
      return stop('Use this for a new dine-in concept, not surveyed alterations or approval drawings.');
    }
    if (!const {null,ProjectParking.none}.contains(brief.parking) || a['parking_sqft']!=null || a['terrace_needed']=='yes') {
      return stop('This floor plan does not draw parking or accessible terraces.');
    }
    if (!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'South','North','East','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and cardinal customer frontage.');
    }
    if (a['food_rear_access']!='confirmed') return stop('Confirm independent on-site approach to both rear service doors. The drawing checks only the measured pads, not site access beyond them.');
    final seats=a['seats'];
    if (seats is! int || seats<4 || seats>200 || seats%4!=0) return stop('Enter 4–200 seats in multiples of four for the measured four-seat tables.');
    int? mm(Object? v,{bool zero=false}) {
      if (v is! num || !v.isFinite || v<0 || v>300) return null;
      final n=(v*1000).round();
      return n>0 || zero ? n : null;
    }
    final plotW=mm(widthFt*.3048),plotD=mm(depthFt*.3048),w=mm(a['cad_plate_width']),d=mm(a['cad_plate_depth']);
    final x=mm(a['cad_offset_left'],zero:true),y=mm(a['cad_offset_front'],zero:true),t=mm(a['cad_wall']);
    final door=mm(a['cad_door']),aisle=mm(a['cad_corridor']);
    if (plotW==null || plotD==null || w==null || d==null || x==null || y==null || t==null || door==null || aisle==null ||
        (sel.plotShapeId=='square' && plotW!=plotD)) return stop('Enter the measured plot, plate, offsets, walls, shared clear aisle and door widths.');
    for (final (side,clear) in [('left',x),('right',plotW-x-w),('front',y),('rear',plotD-y-d)]) {
      final raw=a['${side}_setback'];
      final setback=raw==null?0:mm(raw,zero:true);
      if (setback==null || clear<setback) return stop('The building conflicts with the plot boundary or $side setback.');
    }
    final coverage=a['coverage_limit'], fsi=a['fsi_limit'];
    if (coverage is num && w*d>plotW*plotD*coverage/100) return stop('The footprint exceeds the supplied coverage limit.');
    if (fsi is num && w*d>plotW*plotD*fsi) return stop('The footprint exceeds the supplied FAR/FSI limit.');
    final serve=mm(a['food_serve_width']),returned=mm(a['food_return_width']),pass=mm(a['food_pass_pad']);
    final pad=mm(a['food_rear_pad']), tableW=mm(a['food_table_width']),tableD=mm(a['food_table_depth']),chair=mm(a['food_chair_depth']);
    if (serve==null || returned==null || pass==null || pad==null || tableW==null || tableD==null || chair==null) {
      return stop('Enter both hatch widths and the measured approaches, table size and chair clearance.');
    }
    if (door<=t || aisle<door || serve<=t || returned<=t || tableD<2) return stop('Doors and hatches must exceed the wall thickness, and the aisle must fit the door swing. Enter a positive length for each chair position.');
    if (y+d+pad>plotD) return stop('The measured rear service pads extend outside the plot.');
    const ids=['toilets','dining','kitchen','wash'];
    const labels={'toilets':'Customer toilet reserve','dining':'Dining','kitchen':'Kitchen','wash':'Dishwashing'};
    final counts=sel.spaceQuantities;
    if (counts.length!=4 || ids.any((id)=>counts[id]!=1)) {
      return stop('Include exactly one Toilets, Dining, Kitchen and Wash room. Extra prep, storage, delivery, waste or private dining rooms are not drawn in this template.');
    }
    final widths=<String,int>{},lengths=<String,int>{};
    for (final id in ids) {
      final detail=snap.spaceDetails[id]??const <String,Object>{}, label=labels[id]!;
      final rw=mm(detail['width']),rd=mm(detail['length']);
      if (rw==null || rd==null) return stop('$label: enter measured clear width and length.');
      if (!const {'','0','g','ground','ground floor'}.contains('${detail['floor_level']??''}'.trim().toLowerCase())) return stop('$label must be on the ground floor.');
      final public=id=='toilets'||id=='dining', access=detail['access'];
      if (access!=null && public!=const {'public','semi_public'}.contains(access)) return stop('$label conflicts with the required customer/service split.');
      final edges=switch(id) {
        'toilets'=>const {'front','left'}, 'dining'=>const {'left','right'}, 'kitchen'=>const {'left','rear'}, _=>const {'right','rear'},
      };
      if (detail['zone_edge']!=null && detail['zone_edge']!='any' && !edges.contains(detail['zone_edge'])) return stop('$label cannot reach its requested plate edge in this template.');
      if (detail['daylight']=='required' || detail['cad_window']!=null) return stop('$label requests window or daylight geometry not drawn by this template.');
      for (final key in ['area_min','area_max']) {
        final area=detail[key];
        if (area==null) continue;
        final unit=detail['area_unit'];
        if (area is! num || !const {'sqm','sqft'}.contains(unit)) return stop('$label needs an area unit for the supplied limit.');
        final actual=rw*rd/1000000, target=area*(unit=='sqft' ? .09290304 : 1);
        if (key=='area_min'?actual<target-.001:actual>target+.001) return stop('$label conflicts with the supplied clear-area limit.');
      }
      final adjacent=id=='dining'?{'toilets','kitchen','wash'}:id=='toilets'?{'dining'}:{'dining',id=='kitchen'?'wash':'kitchen'};
      final required=detail['adjacent_required'], separated=detail['separate_from'];
      if ((required is Iterable && required.any((other)=>!adjacent.contains(other))) ||
          (separated is Iterable && separated.any(adjacent.contains))) return stop('$label room relationships conflict with the shared walls of this layout.');
      widths[id]=rw; lengths[id]=rd;
    }
    final iw=w-2*t, toiletW=widths['toilets']!, lobbyD=lengths['toilets']!;
    final diningD=lengths['dining']!, kitchenW=widths['kitchen']!, washW=widths['wash']!, serviceD=lengths['kitchen']!;
    if (widths['dining']!=iw || kitchenW+washW+t!=iw || serviceD!=lengths['wash'] || lobbyD+diningD+serviceD+4*t!=d) {
      return stop('Dining must span the clear plate width. Kitchen + divider + Wash must span that same width; Kitchen and Wash depths must match. Toilet, Dining and Kitchen depths plus four walls must equal the building depth.');
    }
    final hallX=toiletW+t, centre=iw~/2, aisleX=centre-aisle~/2, guest=centre-door~/2;
    if (toiletW<door || lobbyD<=door || serviceD<door || aisleX<=hallX || aisleX+aisle>=iw) {
      return stop('The toilet/lobby split or rear rooms do not leave space for the door swings and aligned customer aisle.');
    }
    final washX=kitchenW+t, kitchenCenter=kitchenW~/2,washCenter=washX+washW~/2;
    int centered(int mid,int clear)=>mid-clear~/2;
    if ([ (kitchenW,serve),(washW,returned),(kitchenW,aisle),(washW,aisle) ].any((pair)=>pair.$1-pair.$2<2)) {
      return stop('Hatches and rear service pads must fit within their own room widths and leave wall returns.');
    }
    final seatingW=tableW+2*chair, tableStart=aisle, rearCross=diningD-pass-aisle;
    // Outside aisles keep both sides of each table accessible geometrically;
    // the cross aisles connect all three lanes at the front and rear.
    if (aisleX-seatingW<aisle || iw-aisleX-aisle-seatingW<aisle || rearCross<=tableStart) {
      return stop('Dining is too narrow or short for two table rows, chair clearances and connected aisles.');
    }
    final slots=(rearCross-tableStart+aisle)~/(tableD+aisle);
    if (seats~/4>2*slots) return stop('The measured dining area fits at most ${8*slots} seats with these tables, chair clearances and aisles.');

    final rotated=facing=='East'||facing=='West';
    PlanRect orient(PlanRect b)=>switch(facing) {
      'North'=>PlanRect(plotW-b.right,plotD-b.top,plotW-b.left,plotD-b.bottom),
      'East'=>PlanRect(plotD-b.top,b.left,plotD-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,plotW-b.right,b.top,plotW-b.left), _=>b,
    };
    PlanRect r(int l,int f,int rr,int back)=>orient(PlanRect(x+t+l,y+t+f,x+t+rr,y+t+back));
    final walls=<PlanRect>[r(-t,-t,0,d-t),r(iw,-t,iw+t,d-t)];
    final openings=<PlanOpening>[],rooms=<PlanRoom>[],zones=<MeasuredZone>[];
    void wall(int l,int f,int rr,int back) { if (rr>l && back>f) walls.add(r(l,f,rr,back)); }
    const outside=AutomaticFloorPlan.entry, lobbying='food_lobby', dining='food_dining', toilet='food_toilet', kitchen='food_kitchen', wash='food_wash';
    void horizontal(int yy,List<({int left,int width,String from,String to,PlanOpeningKind kind})> cuts) {
      var lead=0;
      for (final cut in cuts) {
        wall(lead,yy,cut.left,yy+t);
        final end=cut.left+cut.width;
        openings.add(PlanOpening(cut.kind,r(cut.left,yy,end,yy+t),cut.from,cut.to));
        lead=end;
      }
      wall(lead,yy,iw,yy+t);
    }
    final front=lobbyD+t, rear=front+diningD, work=rear+t, end=work+serviceD;
    const doorKind=PlanOpeningKind.door, hatch=PlanOpeningKind.materialOpening;
    horizontal(-t,[(left:guest,width:door,from:outside,to:lobbying,kind:doorKind)]);
    horizontal(lobbyD,[(left:guest,width:door,from:lobbying,to:dining,kind:doorKind)]);
    final wc=(lobbyD-door)~/2;
    wall(toiletW,0,hallX,wc); wall(toiletW,wc+door,hallX,lobbyD);
    openings.add(PlanOpening(doorKind,r(toiletW,wc,hallX,wc+door),lobbying,toilet));
    horizontal(rear,[(left:centered(kitchenCenter,serve),width:serve,from:dining,to:kitchen,kind:hatch),
      (left:centered(washCenter,returned),width:returned,from:dining,to:wash,kind:hatch)]);
    wall(kitchenW,work,washX,end);
    horizontal(end,[(left:centered(kitchenCenter,door),width:door,from:outside,to:kitchen,kind:doorKind),
      (left:centered(washCenter,door),width:door,from:outside,to:wash,kind:doorKind)]);
    rooms.addAll([
      PlanRoom(toilet,labels['toilets']!,r(0,0,toiletW,lobbyD)),PlanRoom(lobbying,'Customer lobby',r(hallX,0,iw,lobbyD)),
      PlanRoom(dining,labels['dining']!,r(0,front,iw,rear)),PlanRoom(kitchen,labels['kitchen']!,r(0,work,kitchenW,end)),
      PlanRoom(wash,labels['wash']!,r(washX,work,iw,end)),
    ]);
    void zone(String id,String name,String layer,int left,int bottom,int right,int top) =>
      zones.add(MeasuredZone(id,name,r(left,bottom,right,top),layer));
    const paths='FOOD_GUEST_AISLES';
    zone('front_cross','Front cross aisle',paths,0,front,iw,front+aisle);
    zone('rear_cross','Rear cross aisle',paths,0,front+rearCross,iw,rear-pass);
    for (final (id,l) in [('left',0),('main',aisleX),('right',iw-aisle)]) {
      zone('${id}_aisle','Dining aisle',paths,l,front+aisle,l+aisle,front+rearCross);
    }
    for (final (id,name,layer,mid,clear) in [('serve','Serving approach','FOOD_SERVE_PASS',kitchenCenter,serve),
      ('return','Used-dish return','FOOD_RETURN_PASS',washCenter,returned)]) {
      final l=centered(mid,clear), p=centered(mid,aisle);
      zone('${id}_approach',name,layer,l,rear-pass,l+clear,rear);
      zone('${id}_rear_pad','Rear service pad','FOOD_SERVICE_PADS',p,end+t,p+aisle,end+t+pad);
    }
    for (var i=0;i<seats~/4;i++) {
      final l=(i.isEven?aisleX-seatingW:aisleX+aisle), bottom=front+tableStart+(i~/2)*(tableD+aisle);
      final left=l+chair, right=left+tableW;
      zone('table_$i','Table ${i+1}','FOOD_TABLES',left,bottom,right,bottom+tableD);
      for (final (side,m) in [('l',l),('r',right)]) {
        zone('seat_${i}_${side}1','Chair clearance','FOOD_SEATS',m,bottom,m+chair,bottom+tableD~/2);
        zone('seat_${i}_${side}2','Chair clearance','FOOD_SEATS',m,bottom+tableD~/2,m+chair,bottom+tableD);
      }
    }
    final plan=AutomaticFloorPlan(plot:PlanRect(0,0,rotated?plotD:plotW,rotated?plotW:plotD),
      footprint:orient(PlanRect(x,y,x+w,y+d)),facing:facing,sheetTitle:'DINE-IN / DINING & SEPARATE SERVICE PASSES',
      rooms:rooms,walls:walls,openings:openings);
    final issue=validatePlanGeometry(plan,sealedRooms:{kitchen,wash},secondaryExteriorDoorRooms:{kitchen,wash});
    if (issue!=null) return stop('The dine-in plan failed geometry validation: $issue');
    return DiningCadResult(plan,null,zones:List.unmodifiable(zones));
  }
}
