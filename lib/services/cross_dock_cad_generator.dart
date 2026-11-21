import '../data/cross_dock_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanPartition;
import 'warehouse_loading_generator.dart' show WarehouseLoadingResult;

/// Opposing dock banks with measured site pads, staging strips and an internal
/// through-lane. Truck envelopes and pedestrian protection are not designed.
class CrossDockCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='warehouse_cross_dock';

  WarehouseLoadingResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    WarehouseLoadingResult block(String issue)=>WarehouseLoadingResult(null,const [],issue);
    final sel=brief.taxonomy, req=brief.requirements;
    if (sel==null || req==null || sel.version!=projectTaxonomyVersion || req.version!=requirementsSchemaVersion) return block('Save the cross-dock brief with the current measured requirements.');
    if (sel.categoryId!='industrial' || sel.subcategoryId!='logistics' || !crossDockTypes.contains(sel.typeId)) {
      return block('The opposing-bank cross-dock template is for Cross-Dock, Distribution Centre and General Warehouse only.');
    }
    final a=req.answers;
    bool positive(String key)=>a[key] is num && (a[key] as num)>0;
    if (brief.floorCount!=1 || (a['building_count']??1)!=1 || positive('basements') || positive('mezzanines')) {
      return block('Use one ground-floor cross-dock shell with no basements, mezzanines or other buildings.');
    }
    if ((sel.actionId!=null && !const {'new_design','concept_design','feasibility'}.contains(sel.actionId)) ||
      const {'existing','partial_demolition','brownfield'}.contains(a['build_status']) ||
      const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) return block('This drawing is for a new concept, not surveyed retrofit or approvals.');
    final arrangement=a['dock_type'];
    if (sel.configurationId!=null ||
        (arrangement is Iterable && arrangement.any((id)=>!const {'grade','multiple','cross','yard'}.contains(id))) ||
        (brief.parking!=null && brief.parking!=ProjectParking.none) || a['terrace_needed']=='yes' ||
        sel.spaceQuantities.isNotEmpty || positive('pallet_positions') || a['parking_sqft']!=null) {
      return block('This plan shows ground-level opposing dock banks and transfer, not racks, truck turning, dock-high equipment, extra spaces or parking.');
    }
    if (!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return block('Select a rectangular/square plot and cardinal inbound frontage.');
    }
    final vehicle=a['wh_vehicle_basis'];
    if (a['xd_access']!='confirmed' || vehicle is! String || vehicle.trim().isEmpty) {
      return block('Confirm independent inbound, outbound and side staff access and record your vehicle dimension reference.');
    }
    final total=a['dock_count'], inbound=a['xd_in_count'];
    if (total is! int || inbound is! int || total<2 || total>30 || inbound<1 || inbound>=total) {
      return block('Enter 2–30 total docks and leave at least one dock in each bank.');
    }
    int? mm(Object? raw,{bool zero=false}) {
      if (raw is! num || !raw.isFinite || raw<0 || raw>500) return null;
      final n=(1000*raw).round();
      return n>0 || zero ? n : null;
    }
    final plotW=mm(widthFt*.3048),plotD=mm(depthFt*.3048);
    if (plotW==null || plotD==null || (sel.plotShapeId=='square' && plotW!=plotD)) return block('Enter consistent measured plot sides, up to 500 m.');
    final values=<String,int>{};
    for (final f in crossDockFields.where((f)=>f.kind==RequirementKind.decimal)) {
      final n=mm(a[f.id]);
      if (n==null) return block('Enter ${f.label.toLowerCase()} in metres.');
      values[f.id]=n;
    }
    int v(String key)=>values[key]!;
    final w=v('wh_width'),d=v('wh_depth'),t=v('wh_wall'),x=v('xd_left'),staff=v('wh_staff_width'),door=v('wh_staff_door'),lane=v('xd_lane');
    final freightLeft=x+2*t+staff,freightRight=x+w-t,freightWidth=freightRight-freightLeft;
    if (door<=t || door>=staff || door*2+lane>=freightWidth) {
      return block('Staff doors, aisle and clearance beside the internal freight lane do not fit the supplied width.');
    }
    final front=v('xd_in_approach_depth'),inApron=v('xd_in_apron_depth'),inBay=v('xd_in_bay_depth');
    final rear=v('xd_out_approach_depth'),outApron=v('xd_out_apron_depth'),outBay=v('xd_out_bay_depth');
    final y=front+inApron+inBay,top=y+d;
    if (top+outBay+outApron+rear>plotD) return block('Both dock banks, manoeuvring reserves and minimum approach lengths do not fit the available plot depth.');
    for (final (side,available) in [('left',x),('right',plotW-x-w),('front',y),('rear',plotD-top)]) {
      final raw=a['${side}_setback'];
      final inset=raw==null?0:mm(raw,zero:true);
      if (inset==null || available<inset) return block('The cross-dock shell exceeds the plot or the supplied $side setback.');
    }
    final coverage=a['coverage_limit'],fsi=a['fsi_limit'];
    if (coverage is num && w*d>plotW*plotD*coverage/100) return block('The shell exceeds the supplied site coverage.');
    if (fsi is num && w*d>plotW*plotD*fsi) return block('The shell exceeds the supplied FAR/FSI.');
    final innerFront=y+t,innerRear=top-t;
    final inStage=v('xd_in_stage_depth'),outStage=v('xd_out_stage_depth');
    final midStart=innerFront+inStage,midEnd=innerRear-outStage;
    if (midEnd-midStart<=door) return block('Inbound and outbound staging do not leave enough transfer space for the measured staff access door.');
    final staffDoorY=midStart+(midEnd-midStart-door)~/2;
    final laneX=freightLeft+(freightWidth-lane)~/2;
    final plant=PlanRect(x,y,x+w,top);
    final staffWalkY=staffDoorY-(staff-door)~/2;
    if (staffWalkY<y || staffWalkY+staff>top) return block('The measured staff walk cannot align with the side door within the shell side length.');
    final outsideStaff=PlanRect(0,staffWalkY,x,staffWalkY+staff);
    final freight=PlanRect(freightLeft,innerFront,freightRight,innerRear);
    final staffRoom=PlanRect(x+t,innerFront,x+t+staff,innerRear);
    final staffDoor=PlanRect(x,staffDoorY,x+t,staffDoorY+door);
    final innerDoor=PlanRect(x+t+staff,staffDoorY,freightLeft,staffDoorY+door);
    final inStageRect=PlanRect(freightLeft,innerFront,freightRight,midStart);
    final outStageRect=PlanRect(freightLeft,midEnd,freightRight,innerRear);
    final flow=PlanRect(laneX,innerFront,laneX+lane,innerRear);
    const outside=AutomaticFloorPlan.entry;
    final openings=<PlanOpening>[
      PlanOpening(PlanOpeningKind.door,staffDoor,outside,'staff_aisle'),
      PlanOpening(PlanOpeningKind.door,innerDoor,'staff_aisle','freight_hall'),
    ];
    final walls=<PlanRect>[];
    void wall(int l,int b,int r,int t) { if (l<r && b<t) walls.add(PlanRect(l,b,r,t)); }
    wall(x,y,x+t,staffDoorY); wall(x,staffDoorY+door,x+t,top);
    wall(freightRight,y,x+w,top);
    wall(x+t+staff,innerFront,freightLeft,staffDoorY); wall(x+t+staff,staffDoorY+door,freightLeft,innerRear);
    bool touches(PlanRect p,PlanRect q)=>((p.left==q.right||p.right==q.left)&&p.bottom<q.top&&q.bottom<p.top)||
      ((p.bottom==q.top||p.top==q.bottom)&&p.left<q.right&&q.left<p.right);
    final direction=switch(facing){'North'=>ZoneDirection.south,'East'=>ZoneDirection.west,'West'=>ZoneDirection.east,_=>ZoneDirection.north};
    final zones=<MeasuredZone>[
      MeasuredZone('staff_walk','Separate staff approach',outsideStaff,'WALK_ROUTE'),
      MeasuredZone('in_stage','Inbound staging',inStageRect,'CROSS_DOCK_STAGING'),
      MeasuredZone('out_stage','Outbound staging',outStageRect,'CROSS_DOCK_STAGING'),
      MeasuredZone('through_lane','Freight transfer lane',flow,'CROSS_DOCK_FLOW',direction:direction),
    ];
    for (final (id,label,isIn,n) in [('in','Inbound',true,inbound),('out','Outbound',false,total-inbound)]) {
      int value(String key)=>v('xd_${id}_$key');
      final bw=value('bay_width'),bd=value('bay_depth'),dw=value('opening');
      final aw=value('apron_width'),ad=value('apron_depth'),rw=value('drive_width');
      if (bw-dw<t || dw<=t || n*bw>aw || aw>freightWidth || rw>aw) {
        return block('$label dock bank: bay count, door clearances or manoeuvring/approach widths do not fit the loading frontage.');
      }
      int centered(int width)=>freightLeft+(freightWidth-width)~/2;
      final ax=centered(aw),vx=centered(rw);
      final bayStart=isIn?y-bd:top,bayEnd=isIn?y:top+bd;
      final apron=isIn?PlanRect(ax,bayStart-ad,ax+aw,bayStart):PlanRect(ax,bayEnd,ax+aw,bayEnd+ad);
      final drive=isIn?PlanRect(vx,0,vx+rw,apron.bottom):PlanRect(vx,apron.top,vx+rw,plotD);
      final layer=isIn?'CROSS_DOCK_INBOUND':'CROSS_DOCK_OUTBOUND';
      if (!touches(drive,apron)) return block('$label vehicle approach is disconnected from the manoeuvring reserve.');
      zones.addAll([MeasuredZone('${id}_drive','$label approach',drive,layer),MeasuredZone('${id}_apron','$label manoeuvring reserve',apron,layer)]);
      final bankX=centered(n*bw);
      final startY=isIn?y:innerRear,endY=isIn?innerFront:top;
      var cursor=x+t;
      for (var i=0;i<n;i++) {
        final bx=bankX+i*bw,dx=bx+(bw-dw)~/2;
        final bay=PlanRect(bx,bayStart,bx+bw,bayEnd),gap=PlanRect(dx,startY,dx+dw,endY);
        if (!touches(apron,bay) || !touches(bay,gap) || !touches(gap,isIn?inStageRect:outStageRect)) return block('$label bay ${i+1} does not reach its manoeuvring reserve, door and staging.');
        wall(cursor,startY,dx,endY); cursor=dx+dw;
        openings.add(PlanOpening(PlanOpeningKind.loadingDoor,gap,outside,'freight_hall'));
        zones.add(MeasuredZone('${id}_bay_$i','$label bay ${i+1}',bay,layer));
      }
      wall(cursor,startY,freightRight,endY);
    }
    final plot=PlanRect(0,0,plotW,plotD);
    if (zones.any((zone)=>!plot.contains(zone.bounds)) ||
        zones.where((z)=>z.layer=='CROSS_DOCK_INBOUND'||z.layer=='CROSS_DOCK_OUTBOUND').any((z)=>z.bounds.overlaps(outsideStaff)||z.bounds.overlaps(plant)) ||
        !touches(outsideStaff,staffDoor) || !touches(staffDoor,staffRoom) || !touches(staffRoom,innerDoor) || !touches(innerDoor,freight) ||
        !flow.overlaps(inStageRect) || !flow.overlaps(outStageRect)) {
      return block('A vehicle approach, staff walk or freight link overlaps the wrong area or is disconnected.');
    }
    PlanRect orient(PlanRect b)=>switch(facing) {
      'North'=>PlanRect(plotW-b.right,plotD-b.top,plotW-b.left,plotD-b.bottom),
      'East'=>PlanRect(plotD-b.top,b.left,plotD-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,plotW-b.right,b.top,plotW-b.left),
      _=>b,
    };
    final rotated=facing=='East'||facing=='West';
    final plan=AutomaticFloorPlan(plot:rotated?PlanRect(0,0,plotD,plotW):plot,footprint:orient(plant),facing:facing,
      sheetTitle:'WAREHOUSE / OPPOSING CROSS-DOCK BANKS',rooms:[
        PlanRoom('freight_hall','Cross-dock freight hall',orient(freight)),PlanRoom('staff_aisle','Separate staff aisle',orient(staffRoom)),
      ],walls:walls.map(orient),openings:openings.map((o)=>PlanOpening(o.kind,orient(o.bounds),o.from,o.to)));
    final issue=validatePlanPartition(plan);
    if (issue!=null) return block('Cross-dock shell failed geometry validation: $issue');
    return WarehouseLoadingResult(plan,List.unmodifiable(zones.map((z)=>MeasuredZone(z.id,z.name,orient(z.bounds),z.layer,direction:z.direction))),null);
  }
}
