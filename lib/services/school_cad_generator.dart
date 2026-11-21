import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/school_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import '../models/project_requirements_snapshot.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;
import 'enclosed_cad_generator.dart';

class SchoolCadResult {
  const SchoolCadResult(this.plan, this.issue, {this.siteZones = const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> siteZones;
}

typedef _Playground = ({int width,int depth,int walkWidth,int walkDepth,int door,int fence,int gate});

/// A new one-storey primary school with a monitored visitor-to-learning
/// threshold. This is not a locking, evacuation or life-safety specification.
class SchoolCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'school_arrival';

  SchoolCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    SchoolCadResult stop(String message) => SchoolCadResult(null, message);
    final selection = brief.taxonomy, snapshot = brief.requirements;
    if (selection == null || snapshot == null || selection.version != projectTaxonomyVersion || snapshot.version != requirementsSchemaVersion) {
      return stop('Save a school brief with the current measured requirements.');
    }
    if (selection.categoryId != 'institutional' || selection.subcategoryId != 'education' || !schoolCadTypes.contains(selection.typeId)) {
      return stop('The monitored-arrival template supports Primary School only.');
    }
    if (selection.configurationId != null && selection.configurationId != 'single_building') {
      return stop('Multiple blocks and campus circulation are not drawn by this single-building school template.');
    }
    if (!const {'North','East','South','West'}.contains(facing)) return stop('Choose a cardinal direction for the school entrance.');
    final a = snapshot.answers;
    final counts = selection.spaceQuantities;
    final hasPlayground = counts.containsKey('playground');
    if (hasPlayground && (counts['playground']!=1 || a['school_play_access']!='confirmed')) {
      return stop('For a playground, select one rear play area and confirm that the site allows the open play area and fence.');
    }
    if (counts['administration'] != 1 || (counts['classroom'] ?? 0) < 1 || (counts['student_toilets'] ?? 0) < 1) {
      return stop('Add one measured administration/check-in room, at least one classroom and student toilets.');
    }
    if (a['classrooms'] != null && a['classrooms'] != counts['classroom']) {
      return stop('The measured classroom quantity must match the classroom count in Facility requirements.');
    }
    const supported = {'playground','administration','classroom','student_toilets','accessible_toilet','faculty_room','staff_toilets','first_aid_room','library','records','counselling'};
    if (counts.entries.any((room) => room.value < 1 || !supported.contains(room.key))) {
      return stop('This school template only draws classrooms and listed support rooms. Bus drop-off, labs, kitchens, halls and custom room programs are not part of this layout.');
    }
    final admin = snapshot.spaceDetails['administration'] ?? const <String,Object>{};
    if (!const {null,'any','front'}.contains(admin['zone_edge'])) {
      return stop('The administration/check-in room must use the front edge of the school in this template.');
    }
    if (!const {null,'public','semi_public'}.contains(admin['access'])) {
      return stop('Administration/check-in must accept visitors. Staff-only administration needs a separate reception layout.');
    }
    for (final id in counts.keys.where((id) => id != 'administration')) {
      if (snapshot.spaceDetails[id]?['access'] == 'public') {
        return stop('Only administration/check-in can be on the public side of the threshold. A separately public support room needs a different layout.');
      }
    }
    int? mm(Object? v) {
      if (v is! num || !v.isFinite || v <= 0 || v > 300) return null;
      final n = (v*1000).round();
      return n > 0 ? n : null;
    }
    if (mm(snapshot.spaceDetails['classroom']?['cad_window']) == null) {
      return stop('Enter a measured exterior window width for the classroom. Daylight performance is not calculated.');
    }
    final depth = mm(a['school_lobby_depth']), t = mm(a['cad_wall']), door = mm(a['cad_door']);
    final plateDepth = mm(a['cad_plate_depth']), corridor=mm(a['cad_corridor']);
    if (depth == null || t == null || door == null || plateDepth == null || corridor==null) return stop('Enter measured lobby depth, building depth, wall thickness and door opening.');
    if (depth < door || plateDepth - 3*t - depth < door) {
      return stop('The lobby or learning passage is too short for the supplied door swing on its side of the threshold.');
    }
    final walk = mm(a['school_entry_walk']);
    if (a['school_entry_walk'] != null && (walk == null || walk < door || mm(a['cad_offset_front']) == null)) {
      return stop('A straight entry walk needs positive space in front of the building and clear width at least equal to the door opening.');
    }
    _Playground? playground;
    if (hasPlayground) {
      final details=snapshot.spaceDetails['playground'] ?? const <String,Object>{};
      final pw=mm(details['width']), pd=mm(details['length']);
      final ww=mm(a['school_play_walk_width']), wd=mm(a['school_play_walk_depth']);
      final accessDoor=mm(a['school_play_door']), fence=mm(a['school_play_fence']), gate=mm(a['school_play_gate']);
      if (pw==null || pd==null || ww==null || wd==null || accessDoor==null || fence==null || gate==null) {
        return stop('Enter the clear playground width and depth, rear walk, rear door, fence and gate dimensions.');
      }
      final edge=details['zone_edge'];
      if (!const {null,'any','rear'}.contains(edge) || !const {'','g','0','ground','ground floor'}.contains('${details['floor_level']??''}'.trim().toLowerCase())) {
        return stop('This playground must use the rear of the ground-level plot.');
      }
      if (accessDoor<=t || gate<accessDoor || gate>ww || gate>=pw || accessDoor>=corridor || plateDepth-3*t-depth < door+accessDoor) {
        return stop('The rear door, walk, gate and classroom passage do not leave the required geometric opening and swing clearances.');
      }
      for (final key in ['area_min','area_max']) {
        final area=details[key];
        if (area==null) continue;
        final unit=details['area_unit'];
        if (area is! num || !const {'sqm','sqft'}.contains(unit)) return stop('Supply an area unit for the playground limit.');
        final wanted=area*(unit == 'sqft' ? .09290304 : 1), actual=pw*pd/1000000;
        if (key=='area_min'?actual<wanted-.001:actual>wanted+.001) return stop('Clear playground size conflicts with the supplied area limits.');
      }
      final links=details['adjacent_required'];
      if (links is Iterable && links.isNotEmpty || counts.keys.where((id)=>id!='playground').any((id) {
        final adjacent=snapshot.spaceDetails[id]?['adjacent_required'];
        return adjacent is Iterable && adjacent.contains('playground');
      })) return stop('The playground connects to the student passage, not directly to individual rooms. A direct room-to-playground adjacency is not drawn.');
      playground=(width:pw,depth:pd,walkWidth:ww,walkDepth:wd,door:accessDoor,fence:fence,gate:gate);
    }
    final interiorSelection=TaxonomySelection(version:selection.version,categoryId:selection.categoryId,subcategoryId:selection.subcategoryId,
      typeId:selection.typeId,configurationId:selection.configurationId,actionId:selection.actionId,stageId:selection.stageId,
      plotShapeId:selection.plotShapeId,spaceQuantities:{for (final entry in counts.entries) if (entry.key!='playground') entry.key:entry.value});
    final baseBrief = ProjectBrief(floorCount: brief.floorCount, parking: brief.parking, features: brief.features,
      taxonomy: interiorSelection, requirements: ProjectRequirementsSnapshot(version: snapshot.version, answers: snapshot.answers,
        customSpaces: snapshot.customSpaces, spaceDetails: {...snapshot.spaceDetails, 'administration': {...admin, 'zone_edge':'front'}}));
    SchoolCadResult? match;
    final enclosed = EnclosedCadGenerator().generate(baseBrief, widthFt: widthFt, depthFt: depthFt, facing: facing,
      roomTypeAcceptance: (plan, types) {
        match = _split(plan, types, depth, t, door, walk, playground);
        return match != null;
      });
    if (enclosed.sheets.isEmpty || match == null) {
      final yardNote=hasPlayground?' The rear door, walk and whole fenced playground must fit on the plot.':'';
      return stop('${enclosed.issues.join(' ')} The administration door must open into the lobby; all other room doors must open beyond the internal threshold. If supplied, the entry walk must stay on the plot.$yardNote');
    }
    return match!;
  }

  SchoolCadResult? _split(AutomaticFloorPlan plan, Map<String,String> types, int lobby, int t, int door, int? walk, _Playground? playground) {
    const passage = 'internal_passage', arrival = 'school_arrival_route', learning = 'school_learning_route';
    final hall = plan.rooms.singleWhere((r) => r.id == passage).bounds;
    final plot = plan.plot;
    // Passage-local axes: u along the frontage, v increasing away from it.
    // Hall bounds are the origin even when projecting a site walk outside it.
    PlanRect orient(int x1,int y1,int x2,int y2) => switch (plan.facing) {
      'North'=>PlanRect(hall.right-x2,hall.top-y2,hall.right-x1,hall.top-y1),
      'East'=>PlanRect(hall.right-y2,hall.bottom+x1,hall.right-y1,hall.bottom+x2),
      'West'=>PlanRect(hall.left+y1,hall.top-x2,hall.left+y2,hall.top-x1),
      _=>PlanRect(hall.left+x1,hall.bottom+y1,hall.left+x2,hall.bottom+y2),
    };
    (int,int) along(PlanRect b) => switch (plan.facing) {
      'North'=>(hall.top-b.top,hall.top-b.bottom),
      'East'=>(hall.right-b.right,hall.right-b.left),
      'West'=>(b.left-hall.left,b.right-hall.left),
      _=>(b.bottom-hall.bottom,b.top-hall.bottom),
    };
    final rotated = plan.facing == 'East' || plan.facing == 'West';
    final width = rotated ? hall.depth : hall.width, length = rotated ? hall.width : hall.depth;
    final centre = (width-door) ~/ 2, after = lobby+t;
    // Keep positive jambs on both sides of the centrally placed door.
    if (centre < 1 || width-centre-door < 1) return null;
    final openings = <PlanOpening>[];
    for (final opening in plan.openings) {
      if (opening.to == passage && opening.from == AutomaticFloorPlan.entry && opening.kind == PlanOpeningKind.door) {
        openings.add(PlanOpening(opening.kind,opening.bounds,opening.from,arrival));
      } else if (opening.from == passage) {
        final (start, end) = along(opening.bounds);
        final admin = types[opening.to] == 'administration';
        if (admin ? end > lobby : start < after) return null;
        openings.add(PlanOpening(opening.kind,opening.bounds,admin ? arrival : learning,opening.to));
      } else {
        openings.add(opening);
      }
    }
    openings.add(PlanOpening(PlanOpeningKind.door,orient(centre,lobby,centre+door,after),arrival,learning));
    final walls=[...plan.walls,orient(0,lobby,centre,after),orient(centre+door,lobby,width,after)];
    final zones=<MeasuredZone>[];
    bool outsideShell(PlanRect b)=>b.width>0 && b.depth>0 && plot.contains(b) && !b.overlaps(plan.footprint);
    if (playground case final p?) {
      int centreBox(int clear)=>(width-clear)~/2;
      final rearDoorX=centreBox(p.door), rearTop=length+t;
      if (rearDoorX<1 || width-rearDoorX-p.door<1) return null;
      final rearDoor=orient(rearDoorX,length,rearDoorX+p.door,rearTop);
      final rearWall=walls.where((wall)=>wall.contains(rearDoor)).firstOrNull;
      if (rearWall==null) return null;
      walls.remove(rearWall);
      final halves=rotated?[PlanRect(rearWall.left,rearWall.bottom,rearWall.right,rearDoor.bottom),
        PlanRect(rearWall.left,rearDoor.top,rearWall.right,rearWall.top)]:
        [PlanRect(rearWall.left,rearWall.bottom,rearDoor.left,rearWall.top),PlanRect(rearDoor.right,rearWall.bottom,rearWall.right,rearWall.top)];
      walls.addAll(halves.where((b)=>b.width>0 && b.depth>0));
      openings.add(PlanOpening(PlanOpeningKind.door,rearDoor,AutomaticFloorPlan.entry,learning));
      final lx=centreBox(p.width), wx=centreBox(p.walkWidth), gx=centreBox(p.gate);
      final fenceLine=rearTop+p.walkDepth, playStart=fenceLine+p.fence, playEnd=playStart+p.depth;
      if (gx<=lx || gx+p.gate>=lx+p.width) return null;
      final yard=orient(lx,playStart,lx+p.width,playEnd);
      final path=orient(wx,rearTop,wx+p.walkWidth,fenceLine);
      final gate=orient(gx,fenceLine,gx+p.gate,playStart);
      final fences=[
        orient(lx-p.fence,fenceLine,lx,playEnd+p.fence),
        orient(lx+p.width,fenceLine,lx+p.width+p.fence,playEnd+p.fence),
        orient(lx,playEnd,lx+p.width,playEnd+p.fence),
        orient(lx,fenceLine,gx,playStart),orient(gx+p.gate,fenceLine,lx+p.width,playStart),
      ];
      if (![yard,path,gate,...fences].every(outsideShell)) return null;
      zones.addAll([
        MeasuredZone('school_playground','Clear playground',yard,'SCHOOL_PLAYGROUND'),
        MeasuredZone('school_play_walk','Playground walk',path,'SCHOOL_PLAY_WALK'),
        MeasuredZone('school_play_gate','Clear gate opening',gate,'SCHOOL_PLAY_WALK'),
        for (var i=0;i<fences.length;i++) MeasuredZone('school_fence_$i','Fence',fences[i],'SCHOOL_PLAY_FENCE'),
      ]);
    }
    final output=AutomaticFloorPlan(plot:plot,footprint:plan.footprint,facing:plan.facing,
      sheetTitle:playground==null?'Primary school / VISITOR ARRIVAL & LEARNING':'Primary school / ARRIVAL, LEARNING & PLAY',
      rooms:[...plan.rooms.where((r)=>r.id!=passage),
        PlanRoom(arrival,'Visitor check-in lobby',orient(0,0,width,lobby)),
        PlanRoom(learning,'Student passage',orient(0,after,width,length))],
      walls:walls,openings:openings);
    final reserves=output.rooms.where((r)=>r.id.startsWith('reserve_')).map((r)=>r.id).toSet();
    if (validatePlanGeometry(output,sealedRooms:reserves,secondaryExteriorDoorRooms:{if(playground!=null) learning})!=null) return null;
    if (walk!=null) {
      final frontDepth=switch (plan.facing) {
        'North'=>plot.top-hall.top-t, 'East'=>plot.right-hall.right-t,
        'West'=>hall.left-plot.left-t, _=>hall.bottom-plot.bottom-t,
      };
      final walkX=centre-(walk-door)~/2;
      final path=orient(walkX,-t-frontDepth,walkX+walk,-t);
      if (!outsideShell(path)) return null;
      zones.insert(0,MeasuredZone('school_walk','School entry walk',path,'SCHOOL_ENTRY_WALK'));
    }
    return SchoolCadResult(output,null,siteZones:List.unmodifiable(zones));
  }
}
