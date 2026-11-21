import '../data/assembly_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;

class AssemblyCadResult {
  const AssemblyCadResult(this.plan,this.issue,{this.zones=const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
}

/// A dry, single-line assembly concept. One side of the rectangular building
/// is reserved for a walled personnel route; the opposite side has the straight
/// material lane. Bench modules are positioned between them, by measurements.
class AssemblyCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='assembly_workflow';

  AssemblyCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    AssemblyCadResult stop(String issue)=>AssemblyCadResult(null,issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion) {
      return stop('Save the assembly brief with the current measured requirements.');
    }
    if(sel.categoryId!='industrial' || sel.subcategoryId!='manufacturing' || !assemblyCadTypes.contains(sel.typeId)) {
      return stop('This template supports Assembly Plant, Light Manufacturing and Electronics Assembly only.');
    }
    final a=snap.answers;
    bool positive(String id)=>a[id] is num && (a[id] as num)>0;
    if(brief.floorCount!=1 || (a['building_count']??1)!=1 || positive('basements') || positive('mezzanines') ||
      !const {null,'assembly_line'}.contains(sel.configurationId)) return stop('Use one new ground-floor building and an Assembly Line arrangement.');
    if(!const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
      const {'existing','brownfield','partial_demolition'}.contains(a['build_status']) ||
      const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) return stop('Existing factories and construction drawings need a surveyed design workflow.');
    if(!const {null,ProjectParking.none}.contains(brief.parking) || a['parking_sqft']!=null || a['terrace_needed']=='yes') {
      return stop('Parking or an accessible terrace cannot be drawn in this assembly template.');
    }
    if(a['as_scope']!='confirmed') return stop('Confirm dry non-hazardous assembly, independent front staff and receiving access, and rear dispatch access.');
    if(!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return stop('Use a rectangular or square measured plot and a cardinal receiving frontage.');
    }
    int? mm(Object? raw,{bool zero=false}) {
      if(raw is! num || !raw.isFinite || raw<0 || raw>300) return null;
      final n=(raw*1000).round();
      return n>0 || zero?n:null;
    }
    final plotW=mm(widthFt*.3048),plotD=mm(depthFt*.3048),w=mm(a['cad_plate_width']),d=mm(a['cad_plate_depth']);
    final x=mm(a['cad_offset_left'],zero:true),y=mm(a['cad_offset_front'],zero:true),t=mm(a['cad_wall']);
    final staff=mm(a['cad_corridor']),door=mm(a['cad_door']);
    if(plotW==null || plotD==null || w==null || d==null || x==null || y==null || t==null || staff==null || door==null ||
      (sel.plotShapeId=='square' && plotW!=plotD)) return stop('Enter the measured plot, building, wall, staff passage and staff door dimensions.');
    for(final (side,available) in [('left',x),('right',plotW-x-w),('front',y),('rear',plotD-y-d)]) {
      final raw=a['${side}_setback'],setback=raw==null?0:mm(raw,zero:true);
      if(setback==null || available<setback) return stop('The assembly building conflicts with the plot boundary or $side setback.');
    }
    final fsi=a['fsi_limit'],coverage=a['coverage_limit'];
    if(fsi is num && w*d>plotW*plotD*fsi) return stop('The gross floor exceeds the supplied FAR/FSI allowance.');
    if(coverage is num && w*d>plotW*plotD*coverage/100) return stop('The footprint exceeds the supplied coverage allowance.');
    final opening=mm(a['as_goods_opening']),lane=mm(a['as_goods_lane']);
    final receive=mm(a['as_receiving_pad']),dispatch=mm(a['as_dispatch_pad']),work=mm(a['as_work_aisle']);
    final bw=mm(a['as_bench_width']),bd=mm(a['as_bench_depth']),clear=mm(a['as_cell_clear']);
    final count=a['as_station_count'];
    if(opening==null || lane==null || receive==null || dispatch==null || work==null || bw==null || bd==null || clear==null ||
      count is! int || count<1 || count>100) return stop('Enter measured transfer openings, pads, aisles, bench and clearance sizes, and 1–100 workstations.');
    final coreW=w-3*t-staff,coreLeft=staff+t,far=w-2*t;
    if(door<=t || staff-door<2 || d-2*t<door || work<door) return stop('Both the staff passage and the assembly work aisle must fit the person-door swing.');
    if(opening<=t || lane>opening || coreW-opening<=t) return stop('The material lane must fit every opening, with room for the opening jambs.');
    if(receive>y || y+d+dispatch>plotD) return stop('The front receiving or rear dispatch pad extends beyond the plot.');

    const order=['raw_material_receiving','incoming_inspection','raw_store','production_line','quality_control','finished_goods','dispatch'];
    const needed={'raw_material_receiving','production_line','quality_control','dispatch'};
    const peopleStages={'production_line','quality_control'};
    final counts=sel.spaceQuantities;
    if(needed.any((id)=>counts[id]!=1) || counts.entries.any((e)=>!order.contains(e.key)||e.value!=1)) {
      return stop('Select one Receiving, Production Line, Quality Control and Dispatch room. Incoming Inspection, Raw Store and Finished Goods are optional; no other rooms are drawn.');
    }
    final stages=order.where(counts.containsKey).toList();
    final group=taxonomyGroup(taxonomyCategory(sel.categoryId),sel.subcategoryId)!;
    final type=taxonomyChoice(group.types,sel.typeId)!;
    final labels={for(final space in taxonomyProgram(group,type).spaces) space.id:space.label};
    final depths=<int>[];
    for(var i=0;i<stages.length;i++) {
      final key=stages[i],label=labels[key]!;
      final r=snap.spaceDetails[key]??const <String,Object>{};
      final depth=mm(r['length']);
      if(depth==null || mm(r['width'])!=coreW) return stop('$label needs its measured depth and the full clear process-room width ${(coreW/1000).toStringAsFixed(3)} m.');
      if(!const {'','0','g','ground','ground floor'}.contains('${r['floor_level']??''}'.trim().toLowerCase())) return stop('$label must be on the ground floor.');
      if(peopleStages.contains(key) && depth-door<2) return stop('$label is too shallow for the measured staff doorway.');
      final allowedEdges={'right',if(i==0) 'front',if(i==stages.length-1) 'rear'};
      if(r['zone_edge']!=null && r['zone_edge']!='any' && !allowedEdges.contains(r['zone_edge'])) return stop('$label cannot reach its requested exterior edge in this layout.');
      if(const {'public','semi_public'}.contains(r['access'])) return stop('Process rooms cannot have public access in this template.');
      if(r['daylight']=='required' || r['cad_window']!=null || const {'temperature','humidity','cleanroom'}.contains(r['environment'])) {
        return stop('$label requires window or environmental geometry not provided by this dry assembly template.');
      }
      final services=r['services'];
      if(services is Iterable && services.any((s)=>const {'wet','drainage','gas','exhaust'}.contains(s))) {
        return stop('$label needs wet, gas, exhaust or specialist service design outside this drawing.');
      }
      for(final bound in ['area_min','area_max']) {
        final area=r[bound];
        if(area==null) continue;
        final unit=r['area_unit'];
        if(area is! num || !const {'sqm','sqft'}.contains(unit)) return stop('$label needs an area unit for its supplied limit.');
        final actual=coreW*depth/1000000,target=area*(unit=='sqft' ? .09290304 : 1);
        if(bound=='area_min'?actual<target-.001:actual>target+.001) return stop('$label clear geometry conflicts with its area limit.');
      }
      final neighbors={if(i>0) stages[i-1],if(i+1<stages.length) stages[i+1]};
      final adjacent=r['adjacent_required'],separated=r['separate_from'];
      if((adjacent is Iterable && adjacent.any((n)=>!neighbors.contains(n))) ||
        (separated is Iterable && separated.any(neighbors.contains))) return stop('$label room relationships conflict with the linear material sequence.');
      depths.add(depth);
    }
    final neededD=depths.fold<int>(0,(sum,depth)=>sum+depth)+(depths.length+1)*t;
    if(neededD!=d) return stop('Process room depths plus their walls require ${(neededD/1000).toStringAsFixed(3)} m of building depth.');
    final openX=far-t-opening,laneX=openX+(opening-lane)~/2;
    final cellWidth=bw+2*clear,cellDepth=bd+2*clear,cellsX=coreLeft+work;
    final prodD=depths[stages.indexOf('production_line')];
    if(cellsX+cellWidth>laneX || prodD<cellDepth*count) return stop('The requested bench row and measured working clearances do not fit between the work aisle and material lane.');

    final rotated=facing=='East'||facing=='West';
    PlanRect orient(PlanRect b)=>switch(facing) {
      'North'=>PlanRect(plotW-b.right,plotD-b.top,plotW-b.left,plotD-b.bottom),
      'East'=>PlanRect(plotD-b.top,b.left,plotD-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,plotW-b.right,b.top,plotW-b.left),_=>b,
    };
    PlanRect rect(int l,int b,int r,int top)=>orient(PlanRect(x+t+l,y+t+b,x+t+r,y+t+top));
    final inside=d-2*t;
    const outside=AutomaticFloorPlan.entry,passage='assembly_staff_passage';
    String id(String stage)=>'assembly_$stage';
    final rooms=[PlanRoom(passage,'Separate staff passage',rect(0,0,staff,inside))];
    final walls=<PlanRect>[rect(-t,-t,0,inside+t),rect(far,-t,far+t,inside+t)];
    final openings=<PlanOpening>[],zones=<MeasuredZone>[];
    void wall(int l,int b,int r,int top) {if(l<r && b<top) walls.add(rect(l,b,r,top));}
    void material(int yy,String from,String to) {
      wall(coreLeft,yy,openX,yy+t); wall(openX+opening,yy,far,yy+t);
      openings.add(PlanOpening(PlanOpeningKind.materialOpening,rect(openX,yy,openX+opening,yy+t),from,to));
    }
    final entry=(staff-door)~/2;
    wall(0,-t,entry,0); wall(entry+door,-t,coreLeft,0); wall(0,inside,coreLeft,inside+t);
    openings.add(PlanOpening(PlanOpeningKind.door,rect(entry,-t,entry+door,0),outside,passage));
    material(-t,outside,id(stages.first));
    var b=0;
    for(var i=0;i<stages.length;i++) {
      final key=stages[i],top=b+depths[i];
      rooms.add(PlanRoom(id(key),labels[key]!,rect(coreLeft,b,far,top)));
      if(peopleStages.contains(key)) {
        final ds=b+(depths[i]-door)~/2;
        wall(staff,b,coreLeft,ds);wall(staff,ds+door,coreLeft,top);
        openings.add(PlanOpening(PlanOpeningKind.door,rect(staff,ds,coreLeft,ds+door),passage,id(key)));
      } else {wall(staff,b,coreLeft,top);}
      if(key=='production_line') {
        zones.add(MeasuredZone('as_work_aisle','Assembly work aisle',rect(coreLeft,b,coreLeft+work,top),'ASSEMBLY_WORK_AISLE'));
        final start=b+(depths[i]-cellDepth*count)~/2;
        for(var n=0;n<count;n++) {
          final yy=start+n*cellDepth;
          zones.addAll([
            MeasuredZone('as_clear_$n','Working clearance',rect(cellsX,yy,cellsX+cellWidth,yy+cellDepth),'ASSEMBLY_CLEARANCE'),
            MeasuredZone('as_bench_$n','Bench ${n+1}',rect(cellsX+clear,yy+clear,cellsX+clear+bw,yy+clear+bd),'ASSEMBLY_BENCHES'),
          ]);
        }
      }
      if(i+1<stages.length) {
        wall(staff,top,coreLeft,top+t);
        material(top,id(key),id(stages[i+1]));
      } else {material(top,outside,id(key));}
      b=top+t;
    }
    final direction=switch(facing) {'North'=>ZoneDirection.south,'East'=>ZoneDirection.west,'West'=>ZoneDirection.east,_=>ZoneDirection.north};
    zones.addAll([
      MeasuredZone('as_staff_walk','Staff entry walk',rect(0,-y-t,staff,-t),'ASSEMBLY_STAFF'),
      MeasuredZone('as_receiving_pad','Receiving pad',rect(openX,-t-receive,openX+opening,-t),'ASSEMBLY_PADS'),
      MeasuredZone('as_dispatch_pad','Dispatch pad',rect(openX,inside+t,openX+opening,inside+t+dispatch),'ASSEMBLY_PADS'),
      MeasuredZone('as_material_lane','Material lane',rect(laneX,-t-receive,laneX+lane,inside+t+dispatch),'ASSEMBLY_MATERIAL',direction:direction),
    ]);
    final materialRoute=zones.last.bounds;
    if(walls.any(materialRoute.overlaps)) return stop('The material lane clips a partition or opening jamb.');
    final plan=AutomaticFloorPlan(plot:PlanRect(0,0,rotated?plotD:plotW,rotated?plotW:plotD),
      footprint:orient(PlanRect(x,y,x+w,y+d)),facing:facing,sheetTitle:'FACTORY / DRY ASSEMBLY LINE',
      rooms:rooms,walls:walls,openings:openings);
    final issue=validatePlanGeometry(plan,sealedRooms:{for(final key in stages) if(!peopleStages.contains(key)) id(key)});
    if(issue!=null) return stop('The assembly plan failed geometry validation: $issue');
    return AssemblyCadResult(plan,null,zones:List.unmodifiable(zones));
  }
}
