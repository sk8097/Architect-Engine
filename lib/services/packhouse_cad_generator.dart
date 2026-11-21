import '../data/packhouse_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanPartition;

class PackhouseCadResult {
  const PackhouseCadResult(this.plan, this.issue, {this.zones = const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
}

/// Single straight sequence for dry ambient handling of whole produce.
/// The marked lane is reserved space, not equipment or a hygiene barrier.
class PackhouseCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'packhouse_flow';

  PackhouseCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    PackhouseCadResult stop(String issue) => PackhouseCadResult(null, issue);
    final sel = brief.taxonomy, snapshot = brief.requirements;
    if (sel == null || snapshot == null || sel.version != projectTaxonomyVersion || snapshot.version != requirementsSchemaVersion) {
      return stop('Save a packhouse brief with the current measured requirements.');
    }
    if (sel.categoryId != 'rural' || sel.subcategoryId != 'agro_processing' || !packhouseCadTypes.contains(sel.typeId)) {
      return stop('This goods-flow layout is for the Fruit/Vegetable Packhouse only.');
    }
    final a = snapshot.answers;
    if (brief.floorCount != 1 || (a['building_count'] ?? 1) != 1 ||
        (a['basements'] is num && (a['basements'] as num) > 0) || (a['mezzanines'] is num && (a['mezzanines'] as num) > 0)) {
      return stop('Packhouse goods flow needs one new ground-floor building without basement or mezzanine.');
    }
    if ((sel.actionId != null && !const {'new_design','concept_design','feasibility'}.contains(sel.actionId)) ||
        const {'existing','brownfield','partial_demolition'}.contains(a['build_status']) ||
        const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) {
      return stop('This template is for a new packhouse concept, not alteration, construction or approval of an existing site.');
    }
    if ((brief.parking != null && brief.parking != ProjectParking.none) || a['parking_sqft'] != null || a['terrace_needed'] == 'yes') {
      return stop('Parking or accessible terrace requirements are not drawn by this packhouse template.');
    }
    if ((sel.configurationId != null && sel.configurationId != 'processing_plus_storage') || a['ph_access'] != 'confirmed') {
      return stop('Confirm dry ambient handling and independent on-site access at both ends. Storage-only, cold chain and wet processing are not supported.');
    }
    if (!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot with a cardinal receiving frontage.');
    }
    int? mm(Object? raw, {bool zero = false}) {
      if (raw is! num || !raw.isFinite || raw < 0 || raw > 300) return null;
      final n = (raw * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final plotW = mm(widthFt * .3048), plotD = mm(depthFt * .3048);
    final w = mm(a['cad_plate_width']), d = mm(a['cad_plate_depth']), t = mm(a['cad_wall']);
    final x = mm(a['cad_offset_left'],zero:true), y = mm(a['cad_offset_front'],zero:true);
    if (plotW == null || plotD == null || w == null || d == null || t == null || x == null || y == null ||
        (sel.plotShapeId == 'square' && plotW != plotD)) return stop('Enter the measured plot, building envelope, offsets and wall thickness.');
    final r = x+w, top = y+d;
    for (final (side,remaining) in [('left',x),('right',plotW-r),('front',y),('rear',plotD-top)]) {
      final raw = a['${side}_setback'];
      final inset = raw == null ? 0 : mm(raw,zero:true);
      if (inset == null || remaining < inset) return stop('The packhouse exceeds the plot boundary or supplied $side setback.');
    }
    final coverage = a['coverage_limit'], fsi = a['fsi_limit'];
    if (coverage is num && w*d > plotW*plotD*coverage/100) return stop('The packhouse exceeds supplied plot coverage.');
    if (fsi is num && w*d > plotW*plotD*fsi) return stop('The packhouse exceeds supplied FAR/FSI.');
    final transfer = mm(a['ph_transfer']), exterior = mm(a['ph_end_opening']), lane = mm(a['ph_route']);
    final padWidth = mm(a['ph_apron_width']), front = mm(a['ph_receiving_apron']), rear = mm(a['ph_dispatch_apron']);
    if (transfer == null || exterior == null || lane == null || padWidth == null || front == null || rear == null) {
      return stop('Enter measured transfer openings, goods route and both handling pads.');
    }
    final iw = w-2*t;
    if (iw - transfer < 2 || iw - exterior < 2 || transfer <= t || exterior <= t) {
      return stop('The transfer or exterior opening leaves no usable wall return or is not wider than the wall thickness.');
    }
    if (lane > transfer || lane > exterior || exterior > padWidth) return stop('The goods route must fit through every opening, and the handling pads must span the exterior openings.');
    int centre(int width) => x+t+(iw-width)~/2;
    final padX = centre(padWidth);
    if (front > y || top+rear > plotD || padX < 0 || padX+padWidth > plotW) {
      return stop('The front receiving or rear dispatch pad extends outside the plot.');
    }
    final counts = sel.spaceQuantities;
    const order = ['receiving','grading','packaging','finished_store','dispatch'];
    if (counts.keys.any((key) => !order.contains(key))) {
      return stop('Only receiving, grading, packaging, optional ambient finished store and dispatch are drawn. Do not use this mode for washing, raw/cold storage, equipment or vehicle yards.');
    }
    if (const ['receiving','grading','packaging','dispatch'].any((id) => counts[id] != 1) || counts.values.any((n) => n != 1)) {
      return stop('Include exactly one receiving, grading, packaging and dispatch room; finished store is optional (one room).');
    }
    final stages = order.where(counts.containsKey).toList();
    final group = taxonomyGroup(taxonomyCategory(sel.categoryId),sel.subcategoryId)!;
    final type = taxonomyChoice(group.types,sel.typeId)!;
    final labels = {for (final space in taxonomyProgram(group,type).spaces) space.id:space.label};
    final lengths = <int>[];
    for (var i=0;i<stages.length;i++) {
      final id = stages[i], label = labels[id]!;
      final detail = snapshot.spaceDetails[id] ?? const <String,Object>{};
      final length = mm(detail['length']);
      if (length == null || mm(detail['width']) != iw) {
        return stop('$label: enter measured depth and the full clear building width (${(iw/1000).toStringAsFixed(3)} m).');
      }
      if (!const {'','0','g','ground','ground floor'}.contains('${detail['floor_level'] ?? ''}'.trim().toLowerCase())) return stop('$label must be on the ground floor.');
      final edge = detail['zone_edge'];
      if ((edge == 'front' && i != 0) || (edge == 'rear' && i != stages.length-1)) return stop('$label conflicts with its required frontage edge in the process sequence.');
      if (const {'temperature','humidity','cleanroom'}.contains(detail['environment']) || detail['daylight'] == 'required') {
        return stop('$label needs environmental or window design not provided by this ambient workflow drawing.');
      }
      final services = detail['services'];
      if (services is Iterable && services.any((id) => const {'wet','drainage','gas','exhaust'}.contains(id))) {
        return stop('$label specifies wet or specialist process services outside the supported dry handling workflow.');
      }
      for (final key in ['area_min','area_max']) {
        final area = detail[key];
        if (area == null) continue;
        final unit = detail['area_unit'];
        if (area is! num || !area.isFinite || !const {'sqm','sqft'}.contains(unit)) return stop('$label needs a valid area and units.');
        final sqm = area * (unit == 'sqft' ? .09290304 : 1);
        final actual = iw*length/1000000;
        if (key == 'area_min' ? actual < sqm-.001 : actual > sqm+.001) return stop('$label measured geometry conflicts with the supplied area limits.');
      }
      final adjacent = {if(i>0) stages[i-1],if(i+1<stages.length) stages[i+1]};
      final required = detail['adjacent_required'], separated = detail['separate_from'];
      if ((required is Iterable && required.any((id) => !adjacent.contains(id))) ||
          (separated is Iterable && separated.any(adjacent.contains))) return stop('$label room relationships conflict with the straight one-way process sequence.');
      lengths.add(length);
    }
    final neededDepth = lengths.fold<int>(0,(sum,length)=>sum+length)+(stages.length+1)*t;
    if (neededDepth != d) {
      return stop('Measured stages plus wall thicknesses need ${(neededDepth/1000).toStringAsFixed(3)} m of building depth; you supplied ${(d/1000).toStringAsFixed(3)} m.');
    }
    final rotated = facing == 'East' || facing == 'West';
    PlanRect orient(PlanRect b) => switch (facing) {
      'North'=>PlanRect(plotW-b.right,plotD-b.top,plotW-b.left,plotD-b.bottom),
      'East'=>PlanRect(plotD-b.top,b.left,plotD-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,plotW-b.right,b.top,plotW-b.left),
      _=>b,
    };
    final rooms = <PlanRoom>[], openings = <PlanOpening>[];
    final walls = [PlanRect(x,y,x+t,top),PlanRect(r-t,y,r,top)];
    void opening(int v,int width,String from,String to) {
      final left = centre(width);
      walls.addAll([PlanRect(x+t,v,left,v+t),PlanRect(left+width,v,r-t,v+t)]);
      openings.add(PlanOpening(PlanOpeningKind.materialOpening,PlanRect(left,v,left+width,v+t),from,to));
    }
    var cursor = y;
    for (var i=0;i<stages.length;i++) {
      final id = stages[i];
      opening(cursor,i==0?exterior:transfer,i==0?AutomaticFloorPlan.entry:stages[i-1],id);
      cursor += t;
      rooms.add(PlanRoom(id,labels[id]!,PlanRect(x+t,cursor,r-t,cursor+lengths[i])));
      cursor += lengths[i];
    }
    // The canonical outside ID is listed first for an exterior opening. The
    // drawing arrows, not the endpoint ordering, show dispatch direction.
    opening(cursor,exterior,AutomaticFloorPlan.entry,stages.last);
    final laneX = centre(lane);
    final route = PlanRect(laneX,y-front,laneX+lane,top+rear);
    if (walls.any(route.overlaps)) return stop('The goods route clips an opening jamb or partition.');
    final plot = rotated ? PlanRect(0,0,plotD,plotW) : PlanRect(0,0,plotW,plotD);
    final plan = AutomaticFloorPlan(plot:plot,footprint:orient(PlanRect(x,y,r,top)),facing:facing,
      sheetTitle:'Fruit/vegetable packhouse / DRY GOODS FLOW',
      rooms:rooms.map((room)=>PlanRoom(room.id,room.label,orient(room.bounds))),walls:walls.map(orient),
      openings:openings.map((o)=>PlanOpening(o.kind,orient(o.bounds),o.from,o.to)));
    final issue = validatePlanPartition(plan);
    if (issue != null) return stop('The generated packhouse does not form a complete shell: $issue');
    final direction = switch (facing) {'North'=>ZoneDirection.south,'East'=>ZoneDirection.west,'West'=>ZoneDirection.east,_=>ZoneDirection.north};
    return PackhouseCadResult(plan,null,zones:List.unmodifiable([
      MeasuredZone('receiving_pad','Receiving pad',orient(PlanRect(padX,y-front,padX+padWidth,y)),'PACKHOUSE_PADS'),
      MeasuredZone('dispatch_pad','Dispatch pad',orient(PlanRect(padX,top,padX+padWidth,top+rear)),'PACKHOUSE_PADS'),
      MeasuredZone('goods_lane','Goods route',orient(route),'PACKHOUSE_FLOW',direction:direction),
    ]));
  }
}
