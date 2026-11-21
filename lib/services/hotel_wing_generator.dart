import '../data/hotel_wing_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;

class HotelWingResult {
  const HotelWingResult(this.plan, this.issue, {this.zones = const [], this.keys = 0});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
  final int keys;
}

/// Single ground-floor guestroom wing. Both banks use one measured module.
class HotelWingGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'hotel_guestroom_wing';

  HotelWingResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    HotelWingResult stop(String issue) => HotelWingResult(null, issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !hotelWingEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select a supported Hotel, Motel or Guest House type and save the current wing brief.');
    }
    final a = snap.answers;
    bool positive(String key) => a[key] is num && (a[key] as num) > 0;
    if (brief.floorCount != 1 || (a['building_count'] ?? 1) != 1 || positive('basements') || positive('mezzanines')) {
      return stop('Use one ground-floor guestroom wing, not a complete hotel or multistorey program.');
    }
    if (!const {null, 'concept_design', 'new_design', 'feasibility'}.contains(sel.actionId) ||
        const {'existing', 'brownfield', 'partial_demolition'}.contains(a['build_status']) ||
        const {'existing', 'partial', 'renovation', 'demolish'}.contains(a['construction_status'])) {
      return stop('This draws a new concept, not a retrofit or approval drawing.');
    }
    if (sel.spaceQuantities.isNotEmpty || !const {null, ProjectParking.none}.contains(brief.parking) || a['terrace_needed'] == 'yes') {
      return stop('The template already draws both guestroom banks. Leave separate Space, parking and terrace requests empty.');
    }
    final keys = a['room_keys'], mix = a['guest_room_mix'];
    if (keys is! int || keys < 2 || keys > 20 || keys.isOdd || positive('suite_count') ||
        (mix != null && (mix is! Iterable || mix.any((type) => !const {'standard','double','king'}.contains(type)) || mix.length > 1))) {
      return stop('Use 2–20 even keys of one identical standard, double or king layout, with no suites or alternate room types.');
    }
    if (!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot with a cardinal frontage.');
    }
    int? mm(Object? value, {bool zero = false}) {
      if (value is! num || !value.isFinite || value < 0 || value > 300) return null;
      final n = (value * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final pw = mm(widthFt*.3048), pd = mm(depthFt*.3048), w = mm(a['cad_plate_width']);
    final x = mm(a['cad_offset_left'],zero:true), y = mm(a['cad_offset_front'],zero:true), t = mm(a['cad_wall']), door = mm(a['cad_door']);
    final mod = mm(a['hw_module']), aisle = mm(a['hw_corridor']), vest = mm(a['hw_vest_depth']), service = mm(a['hw_service_width']);
    final bw = mm(a['hw_bed_width']), bl = mm(a['hw_bed_depth']), beside = mm(a['hw_bed_side']), foot = mm(a['hw_bed_foot']);
    final window = mm(a['hw_window']);
    if (pw == null || pd == null || w == null || x == null || y == null || t == null || door == null || mod == null ||
        aisle == null || vest == null || service == null || bw == null || bl == null || beside == null || foot == null || window == null ||
        (sel.plotShapeId == 'square' && pw != pd)) {
      return stop('Enter measured plot, wing, room module, walls, openings, bed and clearances.');
    }
    final n = keys ~/ 2, id = mod * n + t * (n-1), d = id + 2*t;
    for (final (side, clear) in [('left',x),('right',pw-x-w),('front',y),('rear',pd-y-d)]) {
      final raw = a['${side}_setback'], setback = raw == null ? 0 : mm(raw,zero:true);
      if (setback == null || clear < setback) return stop('The ${ (d/1000).toStringAsFixed(3)} m-deep wing conflicts with the plot or supplied $side setback.');
    }
    final fsi = a['fsi_limit'], coverage = a['coverage_limit'];
    if (fsi is num && w*d > pw*pd*fsi) return stop('The wing exceeds the supplied FAR/FSI allowance.');
    if (coverage is num && w*d > pw*pd*coverage/100) return stop('The wing exceeds the supplied site coverage.');
    final iw = w-2*t, bank = (iw-aisle-2*t)~/2, sleep = bank-service-t, left = bank+t, right = iw-bank-t;
    if (y <= 0 || door <= t || aisle <= door || id < door || service <= door || vest <= door || mod-vest-t < door) {
      return stop('The corridor, vestibule and bathroom reserve need room for the supplied doors and their swings.');
    }
    final doorY = (vest-door)~/2, win = (mod-window)~/2, bedX = (sleep-bw)~/2, bedY = mod-bl;
    if (bedX < beside || sleep-bw-bedX < beside || bedY < foot || bedY < doorY+door || sleep < door) {
      return stop('The sleeping room cannot fit the measured bed, side and foot clearances, and clear inward door swing.');
    }
    // Keep the declared foot clearance free of the sleeping-room door sweep.
    if (bedY-foot < doorY+door && sleep-door < bedX+bw) {
      return stop('The sleeping-room door swing reaches into the supplied bed foot clearance.');
    }
    if (window <= t || win <= 0 || mod-win-window <= 0) return stop('The exterior window must fit with solid wall returns in each module.');
    final rotated = facing == 'East' || facing == 'West';
    PlanRect orient(PlanRect b) => switch (facing) {
      'North'=>PlanRect(pw-b.right,pd-b.top,pw-b.left,pd-b.bottom),
      'East'=>PlanRect(pd-b.top,b.left,pd-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,pw-b.right,b.top,pw-b.left), _=>b,
    };
    PlanRect rect(int l,int b,int r,int top) => orient(PlanRect(x+t+l,y+t+b,x+t+r,y+t+top));
    const corridor = 'hotel_corridor', entry = AutomaticFloorPlan.entry;
    final rooms = [PlanRoom(corridor,'Guest corridor',rect(left,0,right,id))], openings = <PlanOpening>[];
    final walls = [rect(-t,-t,0,0),rect(iw,-t,iw+t,0),rect(-t,id,0,id+t),rect(iw,id,iw+t,id+t),rect(0,id,iw,id+t)];
    final zones = <MeasuredZone>[];
    void wall(int l,int b,int r,int top) { if (l<r && b<top) walls.add(rect(l,b,r,top)); }
    final dx = left+(right-left-door)~/2;
    wall(0,-t,dx,0); wall(dx+door,-t,iw,0);
    openings.add(PlanOpening(PlanOpeningKind.door,rect(dx,-t,dx+door,0),entry,corridor));
    zones.addAll([
      MeasuredZone('hw_approach','Front approach',rect(left,-y-t,right,-t),'HOTEL_WING_ROUTE'),
      MeasuredZone('hw_corridor','Clear corridor',rect(left,0,right,id),'HOTEL_WING_ROUTE'),
    ]);
    for (var i = 0; i < n; i++) {
      final b = i*(mod+t);
      if (i < n-1) {
        wall(-t,b+mod,left,b+mod+t);
        wall(right,b+mod,iw+t,b+mod+t);
      }
      for (final nearLeft in [true,false]) {
        final key = 'key_${2*i+(nearLeft?1:2)}', lobby = '${key}_entry', bed = '${key}_sleep', bath = '${key}_bath';
        PlanRect wing(int l,int lo,int r,int hi) => nearLeft ? rect(l,b+lo,r,b+hi) : rect(iw-r,b+lo,iw-l,b+hi);
        void addWall(int l,int lo,int r,int hi) { if (l<r && lo<hi) walls.add(wing(l,lo,r,hi)); }
        void opening(PlanOpeningKind kind,String from,String to,int l,int lo,int r,int hi) =>
            openings.add(PlanOpening(kind,wing(l,lo,r,hi),from,to));
        rooms.addAll([
          PlanRoom(lobby,'${key.replaceAll('_',' ')} entry',wing(sleep+t,0,bank,vest)),
          PlanRoom(bed,'${key.replaceAll('_',' ')} sleeping room',wing(0,0,sleep,mod)),
          PlanRoom(bath,'${key.replaceAll('_',' ')} bathroom reserve',wing(sleep+t,vest+t,bank,mod)),
        ]);
        addWall(bank,0,bank+t,doorY); addWall(bank,doorY+door,bank+t,mod);
        opening(PlanOpeningKind.door,corridor,lobby,bank,doorY,bank+t,doorY+door);
        addWall(sleep,0,sleep+t,doorY); addWall(sleep,doorY+door,sleep+t,mod);
        opening(PlanOpeningKind.door,lobby,bed,sleep,doorY,sleep+t,doorY+door);
        final bathX = sleep+t+(service-door)~/2;
        addWall(sleep+t,vest,bathX,vest+t); addWall(bathX+door,vest,bank,vest+t);
        opening(PlanOpeningKind.door,lobby,bath,bathX,vest,bathX+door,vest+t);
        addWall(-t,0,0,win); addWall(-t,win+window,0,mod);
        opening(PlanOpeningKind.window,entry,bed,-t,win,0,win+window);
        zones.addAll([
          MeasuredZone('${key}_bed','Bed',wing(bedX,bedY,bedX+bw,mod),'HOTEL_WING_BED'),
          MeasuredZone('${key}_foot','Clear at bed foot',wing(bedX,bedY-foot,bedX+bw,bedY),'HOTEL_WING_CLEAR'),
          MeasuredZone('${key}_side_a','Bedside clearance',wing(bedX-beside,bedY,bedX,mod),'HOTEL_WING_CLEAR'),
          MeasuredZone('${key}_side_b','Bedside clearance',wing(bedX+bw,bedY,bedX+bw+beside,mod),'HOTEL_WING_CLEAR'),
        ]);
      }
    }
    final plan = AutomaticFloorPlan(plot:PlanRect(0,0,rotated?pd:pw,rotated?pw:pd),footprint:orient(PlanRect(x,y,x+w,y+d)),
      facing:facing,sheetTitle:'GUESTROOM WING / $keys KEYS',rooms:rooms,walls:walls,openings:openings);
    final issue = validatePlanGeometry(plan);
    if (issue != null) return stop('Guestroom partitions could not be validated: $issue');
    return HotelWingResult(plan,null,zones:List.unmodifiable(zones),keys:keys);
  }
}
