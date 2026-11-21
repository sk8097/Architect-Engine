import '../data/office_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import '../models/project_requirements_snapshot.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;
import 'enclosed_cad_generator.dart';

class OfficeCadResult {
  const OfficeCadResult(this.plan, this.issue, {this.fixtures = const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> fixtures;
}

const _hall = 'internal_passage', _visitor = 'office_visitor_route', _staff = 'office_staff_route';
const _visitorRooms = {'reception','meeting_room','visitor_lounge','accessible_toilet'};
const _staffRooms = {'open_workstation','private_cabin','pantry','quiet_room','staff_lockers','copy','archive','it_server_room'};

/// A single-tenant office concept: visitor rooms before a threshold and a
/// workroom with a door-aligned cross-aisle feeding two measured bench rows.
class OfficeCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'office_workplace';

  OfficeCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    OfficeCadResult stop(String issue) => OfficeCadResult(null, issue);
    final selection = brief.taxonomy, snapshot = brief.requirements;
    if (selection == null || snapshot == null || selection.version != projectTaxonomyVersion || snapshot.version != requirementsSchemaVersion) {
      return stop('Save an office brief with the current measured requirements.');
    }
    if (selection.categoryId != 'commercial' || selection.subcategoryId != 'office' || !officeCadTypes.contains(selection.typeId)) {
      return stop('Choose a Small, Branch, Professional or Startup Office for this template.');
    }
    final a = snapshot.answers;
    if (!const {null,'open_workspace'}.contains(selection.configurationId) || !const {null,1}.contains(a['tenants']) ||
        !const {null,'fixed'}.contains(a['desk_model'])) {
      return stop('This template draws one tenant with a fixed-desk open workspace, not separate tenancies or flexible desk configurations.');
    }
    final rooms = selection.spaceQuantities;
    if (rooms['reception'] != 1 || rooms['open_workstation'] != 1 || (rooms['meeting_room'] ?? 0) < 1) {
      return stop('Add one reception, at least one meeting room, and one Open Workstation room. Enter the individual desk count separately.');
    }
    if (rooms.entries.any((r) => r.value < 1 || !(_visitorRooms.contains(r.key) || _staffRooms.contains(r.key)))) {
      return stop('Only the listed visitor and staff rooms are supported. Large assembly, shared facilities and custom rooms need a different office layout.');
    }
    final count = a['workstations'];
    if (count is! int || count < 1 || count > 200) return stop('Enter a whole-number workstation count from 1 to 200.');
    final details = <String,Map<String,Object>>{};
    for (final id in rooms.keys) {
      final detail = snapshot.spaceDetails[id] ?? const <String,Object>{};
      final visitor = _visitorRooms.contains(id);
      final access = detail['access'];
      if (access != null && (visitor != const {'public','semi_public'}.contains(access))) {
        return stop('A requested room access level conflicts with the visitor/staff split. Reception, meeting, visitor lounge and any selected accessible toilet are before the threshold.');
      }
      if (id == 'reception' && !const {null,'any','front'}.contains(detail['zone_edge'])) {
        return stop('Reception must touch the front of the floor plate in this layout.');
      }
      details[id] = {...detail,
        'access': visitor ? 'semi_public' : 'staff',
        if (id == 'reception') 'zone_edge':'front',
      };
    }
    int? mm(String key, {bool zero = false}) {
      final v = a[key];
      if (v is! num || !v.isFinite || v < 0 || v > 300) return null;
      final n = (v * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final lobby = mm('office_visitor_depth'), wall = mm('cad_wall'), door = mm('cad_door'), plate = mm('cad_plate_depth');
    final span = mm('office_desk_span'), desk = mm('office_desk_depth'), chair = mm('office_chair_depth');
    final aisle = mm('office_aisle'), gap = mm('office_desk_gap', zero:true);
    if (lobby == null || wall == null || door == null || plate == null || span == null || desk == null || chair == null || aisle == null || gap == null) {
      return stop('Enter the measured visitor passage, shell, door, desk, chair clearance, aisle and desk gap dimensions.');
    }
    if (lobby < door || plate - 3*wall - lobby < door || aisle < door) {
      return stop('Both passages and the workspace cross-aisle must fit the supplied door swing.');
    }
    final prepared = ProjectBrief(floorCount:brief.floorCount, parking:brief.parking, features:brief.features,
      taxonomy:selection, requirements:ProjectRequirementsSnapshot(version:snapshot.version, answers:a,
        spaceDetails:details));
    OfficeCadResult? accepted;
    var fittedThreshold = false;
    final result = EnclosedCadGenerator().generate(prepared, widthFt:widthFt, depthFt:depthFt, facing:facing,
      roomTypeAcceptance:(shell, ids) {
        final plan = _split(shell,ids,lobby,wall,door);
        if (plan == null) return false;
        fittedThreshold = true;
        final workspace = shell.rooms.singleWhere((r) => ids[r.id] == 'open_workstation');
        final entry = plan.openings.singleWhere((o) => o.from == _staff && o.to == workspace.id).bounds;
        final fixtures = _deskRows(_FrontageFrame(workspace.bounds, facing),entry,count,span,desk,chair,aisle,gap);
        if (fixtures == null) return false;
        accepted = OfficeCadResult(plan,null,fixtures:List.unmodifiable(fixtures));
        return true;
      });
    if (result.sheets.isNotEmpty && accepted != null) return accepted!;
    return stop('${result.issues.join(' ')} ${fittedThreshold
      ? 'The workstation count, desks, chair clearances and door-aligned aisles do not fit the measured workspace.'
      : 'Reception and meeting doors must open before the threshold, and staff doors beyond it.'}');
  }

  AutomaticFloorPlan? _split(AutomaticFloorPlan plan, Map<String,String> ids, int front, int wall, int door) {
    final frame = _FrontageFrame(plan.rooms.singleWhere((r) => r.id == _hall).bounds,plan.facing);
    final x = (frame.width-door)~/2, after = front+wall;
    if (x < 1 || x+door >= frame.width || after >= frame.depth) return null;
    final openings = <PlanOpening>[];
    for (final o in plan.openings) {
      if (o.to == _hall) {
        openings.add(PlanOpening(o.kind,o.bounds,o.from,_visitor));
      } else if (o.from == _hall) {
        final (start,end) = frame.along(o.bounds);
        final visitors = _visitorRooms.contains(ids[o.to]);
        if (visitors ? end > front : start < after) return null;
        openings.add(PlanOpening(o.kind,o.bounds,visitors?_visitor:_staff,o.to));
      } else {
        openings.add(o);
      }
    }
    openings.add(PlanOpening(PlanOpeningKind.door,frame.rect(x,front,x+door,after),_visitor,_staff));
    final office = AutomaticFloorPlan(plot:plan.plot,footprint:plan.footprint,facing:plan.facing,
      sheetTitle:'OFFICE / VISITOR & STAFF WORKPLACE',
      rooms:[...plan.rooms.where((r) => r.id != _hall),
        PlanRoom(_visitor,'Visitor passage',frame.rect(0,0,frame.width,front)),
        PlanRoom(_staff,'Staff passage',frame.rect(0,after,frame.width,frame.depth))],
      walls:[...plan.walls,frame.rect(0,front,x,after),frame.rect(x+door,front,frame.width,after)],openings:openings);
    final reserves = office.rooms.where((r) => r.id.startsWith('reserve_')).map((r) => r.id).toSet();
    return validatePlanGeometry(office,sealedRooms:reserves) == null ? office : null;
  }

  List<MeasuredZone>? _deskRows(_FrontageFrame f, PlanRect entry, int count,
      int span, int desk, int chair, int aisle, int gap) {
    final bank = desk+chair;
    if (2*bank+aisle > f.width || aisle > f.depth) return null;
    final x = (f.width-aisle)~/2;
    final (start,end) = f.along(entry);
    final centred = start-(aisle-(end-start))~/2;
    final cross = centred.clamp(0,f.depth-aisle).toInt(), back = cross+aisle;
    if (cross > start || back < end) return null;
    final zones = <MeasuredZone>[
      MeasuredZone('office_cross','Cross-aisle',f.rect(0,cross,f.width,back),'OFFICE_AISLES'),
      if (cross>0) MeasuredZone('office_front_aisle','Main aisle',f.rect(x,0,x+aisle,cross),'OFFICE_AISLES'),
      if (back<f.depth) MeasuredZone('office_rear_aisle','Main aisle',f.rect(x,back,x+aisle,f.depth),'OFFICE_AISLES'),
    ];
    var n = 0;
    // Grow outward from the shared cross-aisle so every filled desk has a
    // chair clearance directly adjoining the connected main aisle.
    final pitch = span+gap;
    for (var i=0; n<count; i++) {
      final before = cross-span-i*pitch, behind = back+i*pitch;
      final ends = [if(before>=0) before, if(behind+span<=f.depth) behind];
      if (ends.isEmpty) return null;
      for (final y in ends) {
        for (final left in [true,false]) {
          if (n == count) break;
          n++;
          final c = left ? x-chair : x+aisle;
          final d = left ? c-desk : c+chair;
          zones.addAll([
            MeasuredZone('office_desk_$n','Desk $n',f.rect(d,y,d+desk,y+span),'OFFICE_DESKS'),
            MeasuredZone('office_chair_$n','Chair clearance $n',f.rect(c,y,c+chair,y+span),'OFFICE_CHAIR_CLEAR'),
          ]);
        }
      }
    }
    return zones;
  }
}

/// Width along frontage and increasing depth into the building.
class _FrontageFrame {
  const _FrontageFrame(this.b,this.facing);
  final PlanRect b;
  final String facing;
  bool get rotated => facing == 'East' || facing == 'West';
  int get width => rotated ? b.depth : b.width;
  int get depth => rotated ? b.width : b.depth;
  PlanRect rect(int l,int f,int r,int d) => switch(facing) {
    'North'=>PlanRect(b.right-r,b.top-d,b.right-l,b.top-f),
    'East'=>PlanRect(b.right-d,b.bottom+l,b.right-f,b.bottom+r),
    'West'=>PlanRect(b.left+f,b.top-r,b.left+d,b.top-l),
    _=>PlanRect(b.left+l,b.bottom+f,b.left+r,b.bottom+d),
  };
  (int,int) along(PlanRect r) => switch(facing) {
    'North'=>(b.top-r.top,b.top-r.bottom), 'East'=>(b.right-r.right,b.right-r.left),
    'West'=>(r.left-b.left,r.right-b.left), _=>(r.bottom-b.bottom,r.top-b.bottom),
  };
}
