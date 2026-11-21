import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/teaching_lab_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;

class TeachingLabResult {
  const TeachingLabResult(this.plan, this.issue, {this.zones = const [], this.places = 0});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
  final int places;
}

/// Measured general teaching bench layout, not specialist laboratory design.
class TeachingLabGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'school_teaching_lab';

  TeachingLabResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    TeachingLabResult stop(String issue) => TeachingLabResult(null, issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !teachingLabEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Secondary School or Senior Secondary School and save the current teaching lab brief.');
    }
    final a = snap.answers;
    bool positive(String key) => a[key] is num && (a[key] as num) > 0;
    if (brief.floorCount != 1 || (a['building_count'] ?? 1) != 1 || positive('basements') || positive('mezzanines') ||
        !const {null, 'single_building'}.contains(sel.configurationId)) {
      return stop('Use a single ground-floor teaching lab block, not a full school, basement or multistorey program.');
    }
    if (!const {null, 'concept_design', 'new_design', 'feasibility'}.contains(sel.actionId) ||
        const {'existing', 'brownfield', 'partial_demolition'}.contains(a['build_status']) ||
        const {'existing', 'partial', 'renovation', 'demolish'}.contains(a['construction_status'])) {
      return stop('Use a new concept, not a surveyed retrofit or approval drawing.');
    }
    if (sel.spaceQuantities.isNotEmpty || !const {null, ProjectParking.none}.contains(brief.parking) || a['terrace_needed'] == 'yes') {
      return stop('The template already draws the lab and enclosed prep room. Leave separate Spaces, parking and terrace requests empty.');
    }
    if (!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and choose a cardinal approach frontage.');
    }
    int? mm(Object? value, {bool zero = false}) {
      if (value is! num || !value.isFinite || value < 0 || value > 300) return null;
      final n = (value * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final pw = mm(widthFt * .3048), pd = mm(depthFt * .3048), w = mm(a['cad_plate_width']), d = mm(a['cad_plate_depth']);
    final x = mm(a['cad_offset_left'],zero:true), y = mm(a['cad_offset_front'],zero:true), t = mm(a['cad_wall']), door = mm(a['cad_door']);
    final centre = mm(a['sl_centre']), side = mm(a['sl_side']), front = mm(a['sl_front']), rear = mm(a['sl_rear']);
    final rows = a['sl_rows'], places = a['sl_places'], span = mm(a['sl_place_span']);
    final bw = mm(a['sl_bench_width']), bd = mm(a['sl_bench_depth']), use = mm(a['sl_use']), cross = mm(a['sl_cross']);
    final tw = mm(a['sl_teacher_width']), td = mm(a['sl_teacher_depth']), twk = mm(a['sl_teacher_work']);
    final prep = mm(a['sl_prep']), pcw = mm(a['sl_prep_width']), pcd = mm(a['sl_prep_depth']), pwk = mm(a['sl_prep_work']);
    if (pw == null || pd == null || w == null || d == null || x == null || y == null || t == null || door == null ||
      centre == null || side == null || front == null || rear == null || rows is! int || rows < 1 || rows > 10 ||
      places is! int || places < 1 || places > 8 || span == null || bw == null || bd == null || use == null || cross == null ||
      tw == null || td == null || twk == null || prep == null || pcw == null || pcd == null || pwk == null ||
      (sel.plotShapeId == 'square' && pw != pd)) {
      return stop('Enter measured plot, envelope, bench, passage, counter and prep-room dimensions and counts.');
    }
    for (final (key, clear) in [('left',x),('right',pw-x-w),('front',y),('rear',pd-y-d)]) {
      final raw = a['${key}_setback'], setback = raw == null ? 0 : mm(raw,zero:true);
      if (setback == null || clear < setback) return stop('The lab block conflicts with the plot or supplied $key setback.');
    }
    final fsi = a['fsi_limit'], coverage = a['coverage_limit'];
    if (fsi is num && w * d > pw * pd * fsi) return stop('The lab block exceeds the supplied FAR/FSI allowance.');
    if (coverage is num && w * d > pw * pd * coverage / 100) return stop('The lab block exceeds the supplied site coverage.');
    if (bw < places * span) return stop('The measured bench frontage cannot fit the entered student places.');
    final iw = w - 2*t, id = d - 2*t, prepStart = id - prep, labEnd = prepStart - t;
    final left = (iw-centre)~/2, right = left+centre;
    if (left < bw+side || iw-right < bw+side) return stop('Both bench banks, the centre aisle and both side aisles do not fit the clear width.');
    if (y <= 0 || door <= t || centre < door) return stop('The front approach and centre aisle must span both door openings.');
    if (tw > left || door + td + twk > front) return stop('The teacher counter and its work zone conflict with the centre aisle, entrance swing or teaching-band depth.');
    if (pcw > left || prep - pcd - pwk < door) return stop('The prep counter and work zone leave too little clear space beyond the prep door swing.');
    final rowDepth = bd+use+cross, benchEnd = front + rows*rowDepth;
    if (labEnd-benchEnd < math.max(rear,door)) return stop('The measured bench rows and rear cross aisle do not fit ahead of the prep room.');
    final dx = left + (centre-door)~/2;
    final rotated = facing == 'East' || facing == 'West';
    PlanRect orient(PlanRect b) => switch(facing) {
      'North' => PlanRect(pw-b.right,pd-b.top,pw-b.left,pd-b.bottom),
      'East' => PlanRect(pd-b.top,b.left,pd-b.bottom,b.right),
      'West' => PlanRect(b.bottom,pw-b.right,b.top,pw-b.left), _ => b,
    };
    PlanRect rect(int l,int b,int r,int top) => orient(PlanRect(x+t+l,y+t+b,x+t+r,y+t+top));
    const lab = 'school_lab', store = 'school_lab_prep';
    final plan = AutomaticFloorPlan(plot:PlanRect(0,0,rotated?pd:pw,rotated?pw:pd),
      footprint:orient(PlanRect(x,y,x+w,y+d)),facing:facing,sheetTitle:'TEACHING LAB / BENCHES AND PREP',rooms:[
        PlanRoom(lab,'Teaching laboratory',rect(0,0,iw,labEnd)),
        PlanRoom(store,'Enclosed prep room',rect(0,prepStart,iw,id)),
      ],walls:[
        rect(-t,-t,0,id+t),rect(iw,-t,iw+t,id+t),rect(0,id,iw,id+t),
        rect(0,-t,dx,0),rect(dx+door,-t,iw,0),
        rect(0,labEnd,dx,prepStart),rect(dx+door,labEnd,iw,prepStart),
      ],openings:[
        PlanOpening(PlanOpeningKind.door,rect(dx,-t,dx+door,0),AutomaticFloorPlan.entry,lab),
        PlanOpening(PlanOpeningKind.door,rect(dx,labEnd,dx+door,prepStart),lab,store),
      ]);
    final issue = validatePlanGeometry(plan);
    if (issue != null) return stop('Teaching lab geometry could not be validated: $issue');
    final zones = <MeasuredZone>[];
    void mark(String id,String name,String layer,int l,int b,int r,int top) => zones.add(MeasuredZone(id,name,rect(l,b,r,top),layer));
    const route = 'TEACH_LAB_ROUTE', clear = 'TEACH_LAB_CLEAR', bench = 'TEACH_LAB_BENCH', counter = 'TEACH_LAB_COUNTER';
    mark('sl_approach','Front approach',route,left,-y-t,right,-t);
    mark('sl_entry','Clear entry cross aisle',route,0,0,iw,door);
    mark('sl_centre','Centre aisle',route,left,door,right,benchEnd);
    mark('sl_side_a','Left side aisle',route,0,front,left-bw,benchEnd);
    mark('sl_side_b','Right side aisle',route,right+bw,front,iw,benchEnd);
    mark('sl_rear','Rear cross aisle',route,0,benchEnd,iw,labEnd);
    // Clear strip across the right teaching flank links the right side aisle;
    // the left side aisle connects at the rear and at every row crossing.
    mark('sl_front_right','Clear teaching-side access',route,right,door,iw,front);
    mark('sl_teacher','Teacher counter',counter,left-tw,door,left,door+td);
    mark('sl_teacher_work','Teacher work zone',clear,left-tw,door+td,left,door+td+twk);
    mark('sl_prep_path','Prep approach',route,left,prepStart,right,id);
    mark('sl_prep_counter','Prep counter',counter,left-pcw,id-pcd,left,id);
    mark('sl_prep_work','Prep work zone',clear,left-pcw,id-pcd-pwk,left,id-pcd);
    for (var i = 0; i < rows; i++) {
      final b = front + i*rowDepth;
      for (final (suffix,l,r) in [('a',left-bw,left),('b',right,right+bw)]) {
        final key = 'sl_${i+1}_$suffix';
        mark('${key}_bench','$places places',bench,l,b,r,b+bd);
        mark('${key}_use','Student-use clearance',clear,l,b+bd,r,b+bd+use);
        mark('${key}_cross','Clear row crossing',route,l,b+bd+use,r,b+rowDepth);
      }
    }
    return TeachingLabResult(plan,null,zones:List.unmodifiable(zones),places:2*rows*places);
  }
}
