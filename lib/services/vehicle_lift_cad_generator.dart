import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/vehicle_lift_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class VehicleLiftCadResult {
  const VehicleLiftCadResult({this.plan, this.section, this.issue, this.bays = 0, this.widthMm = 0,
    this.depthMm = 0, this.roofMm = 0, this.overheadMm = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int bays, widthMm, depthMm, roofMm, overheadMm;
}

/// Static clearance check of measured vehicle and lift envelopes, not a lift design.
class VehicleLiftCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'workshop_measured_lifts';

  VehicleLiftCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    VehicleLiftCadResult stop(String issue) => VehicleLiftCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !vehicleLiftCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select a supported workshop type and save the measured vehicle lift brief.');
    }
    if (!const {null, 'single_service_bay', 'multiple_service_bays', 'workshop_plus_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        brief.floorCount != 1 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one ground-floor workshop without separate parking or Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = snap.answers;
    final rawCount = a['service_bays'];
    if (rawCount is! num || !rawCount.isFinite || rawCount < 1 || rawCount > 4 || rawCount != rawCount.toInt()) {
      return stop('Enter a whole count of 1 to 4 Service bays in Facility setup.');
    }
    final count = rawCount.toInt();
    if ((sel.configurationId == 'single_service_bay' && count != 1) ||
        (sel.configurationId == 'multiple_service_bays' && count < 2)) {
      return stop('The Service bays count must agree with the selected single or multiple bay arrangement.');
    }
    int? mm(Object? v, {num min = .001, int max = 30}) =>
        v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final bayW = mm(a['lv_bay_w']), wall = mm(a['lv_wall'], max: 2);
    final vw = mm(a['lv_car_w']), vl = mm(a['lv_car_l']), vh = mm(a['lv_car_h']);
    final front = mm(a['lv_front']), rear = mm(a['lv_rear']);
    final doorW = mm(a['lv_door_w']), doorH = mm(a['lv_door_h']), doorHead = mm(a['lv_door_head']);
    final inside = mm(a['lv_inner']), postW = mm(a['lv_post_w']), postD = mm(a['lv_post_d']), postH = mm(a['lv_post_h']);
    final rise = mm(a['lv_rise']), side = mm(a['lv_side']), outside = mm(a['lv_outside']), clear = mm(a['clear_height'], min: .01);
    final overhead = mm(a['lv_overhead']), apron = mm(a['lv_apron'], max: 200);
    final west = mm(a['lv_west'], min: 0, max: 2000), south = mm(a['lv_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || bayW == null || wall == null ||
        vw == null || vl == null || vh == null || front == null || rear == null || doorW == null || doorH == null || doorHead == null ||
        inside == null || postW == null || postD == null || postH == null || rise == null || side == null || outside == null ||
        clear == null || overhead == null || apron == null || west == null || south == null) {
      return stop('Enter measured plot, bay, vehicle, lift, opening and clearance inputs, including Facility clear height.');
    }
    if (doorW >= bayW || doorH > clear || doorW < vw + 2 * side || doorH < vh + doorHead) {
      return stop('The door opening must leave side jambs, fit below the clear height, and meet the submitted vehicle width and head margins.');
    }
    if (inside < vw + 2 * side) return stop('The vehicle and its submitted side clearance do not fit between the lift posts.');
    if (inside + 2 * (postW + outside) > bayW) return stop('The lift posts and their outside clearances do not fit within each bay.');
    if (postD > vl) return stop('The centred lift-post depth must not exceed the depicted vehicle length.');
    if (rise >= postH) return stop('The submitted raised vehicle base must be below the depicted post tops.');
    final roof = rise + vh;
    final actualMargin = clear - (roof > postH ? roof : postH);
    if (actualMargin < overhead) return stop('The raised vehicle or lift posts leave less than the supplied overhead margin.');
    final width = count * bayW + 2 * wall, depth = front + vl + rear + 2 * wall;
    for (final (edge, remaining) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - apron - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || remaining < min) return stop('The workshop and apron conflict with the $edge plot edge or supplied setback.');
    }

    final p = _LiftSheet(), s = _LiftSheet();
    p.box('LIFT_PLOT', 0, 0, pw, pd);
    final f = south + apron, n = f + depth, e = west + width;
    // The apron ends at the frontage; omit its north edge across the door openings.
    p.line('LIFT_APRON', west, f, west, south);
    p.line('LIFT_APRON', west, south, e, south);
    p.line('LIFT_APRON', e, south, e, f);
    // Shell with real openings: jamb returns and inner/outer wall faces are separate lines.
    p.line('LIFT_SHELL', west, f, west, n);
    p.line('LIFT_SHELL', west, n, e, n);
    p.line('LIFT_SHELL', e, n, e, f);
    p.line('LIFT_SHELL', west + wall, f + wall, west + wall, n - wall);
    p.line('LIFT_SHELL', west + wall, n - wall, e - wall, n - wall);
    p.line('LIFT_SHELL', e - wall, n - wall, e - wall, f + wall);
    num last = west, lastInner = west + wall;
    final vehicleY = f + wall + front, py = vehicleY + (vl - postD) / 2;
    final t = (math.max(pw, pd) / 90).clamp(25, 6000).toDouble();
    for (var i = 0; i < count; i++) {
      final x = west + wall + i * bayW, cx = x + bayW / 2;
      final l = cx - doorW / 2, r = cx + doorW / 2;
      p.line('LIFT_SHELL', last, f, l, f);
      p.line('LIFT_SHELL', lastInner, f + wall, l, f + wall);
      p.line('LIFT_SHELL', l, f, l, f + wall);
      p.line('LIFT_SHELL', r, f, r, f + wall);
      p.line('LIFT_OPENING', l, f + wall / 2, r, f + wall / 2);
      last = lastInner = r;
      if (i > 0) p.line('LIFT_BAY_LIMIT', x, f + wall, x, n - wall);
      p.box('LIFT_VEHICLE', cx - vw / 2, vehicleY, cx + vw / 2, vehicleY + vl);
      p.box('LIFT_POST', cx - inside / 2 - postW, py, cx - inside / 2, py + postD);
      p.box('LIFT_POST', cx + inside / 2, py, cx + inside / 2 + postW, py + postD);
      p.label(cx, f + wall + front / 2, 'BAY ${i + 1}', math.min(t, math.min(front / 3, bayW / 6)));
    }
    p.line('LIFT_SHELL', last, f, e, f);
    p.line('LIFT_SHELL', lastInner, f + wall, e - wall, f + wall);
    final ax = pw + 2 * t;
    p.line('ANNOTATIONS', ax, pd - 2 * t, ax, pd);
    p.line('ANNOTATIONS', ax - t / 2, pd - t, ax, pd);
    p.line('ANNOTATIONS', ax + t / 2, pd - t, ax, pd);
    p.label(ax, pd + t, 'N', t * .7);
    String m(int v) => (v / 1000).toStringAsFixed(3);
    p.heading(pw, pd, t, [
      'MEASURED SERVICE BAYS / WORKSHOP PLAN / LOCAL MM',
      '$count BAY(S) / HALL ${m(width)} x ${m(depth)} M / SOUTH APRON ${m(apron)} M',
      'STATIC VEHICLE POSITION / NO ACCESS OR TURNING CHECK',
    ]);

    final cx = bayW / 2;
    s.line('LIFT_SHELL', 0, 0, bayW, 0);
    s.line('LIFT_HEAD', 0, clear, bayW, clear);
    s.line('LIFT_BAY_LIMIT', 0, 0, 0, clear);
    s.line('LIFT_BAY_LIMIT', bayW, 0, bayW, clear);
    s.box('LIFT_POST', cx - inside / 2 - postW, 0, cx - inside / 2, postH);
    s.box('LIFT_POST', cx + inside / 2, 0, cx + inside / 2 + postW, postH);
    s.box('LIFT_VEHICLE', cx - vw / 2, rise, cx + vw / 2, roof);
    final st = (math.max(bayW, clear) / 44).clamp(18, 4500).toDouble();
    s.heading(bayW, clear, st, [
      'TYPICAL TRANSVERSE SECTION THROUGH POSTS / TRUE SCALE MM',
      'RAISED ROOF ${m(roof)} M / POST TOP ${m(postH)} M / CLEAR HEIGHT ${m(clear)} M',
      'GOVERNING OVERHEAD GAP ${m(actualMargin)} M / NO LIFT COMPONENTS SHOWN',
    ]);
    return VehicleLiftCadResult(plan: p.drawing(pw, pd, t, rightMargin: 5), section: s.drawing(bayW, clear, st),
      bays: count, widthMm: width, depthMm: depth, roofMm: roof, overheadMm: actualMargin);
  }
}

class _LiftSheet {
  final lines = <CadLine>[], labels = <CadLabel>[];
  void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
  void box(String layer, num x, num y, num ex, num ey) {
    line(layer, x, y, ex, y);
    line(layer, ex, y, ex, ey);
    line(layer, ex, ey, x, ey);
    line(layer, x, ey, x, y);
  }
  void label(num x, num y, String text, num size) => labels.add(CadLabel('ANNOTATIONS', CadPoint(x, y), text, size));
  void heading(int w, int h, double t, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      label(w / 2, h + t * (5.5 - 1.4 * i), rows[i], i == 0 ? t : t * .65);
    }
  }
  FloorPlanCad drawing(int w, int h, double t, {int rightMargin = 2}) => FloorPlanCad.fromEntities(
    bounds: PlanRect(math.min(-2 * t, w / 2 - 37 * t).floor(), (-2 * t).floor(),
      math.max(w + rightMargin * t, w / 2 + 37 * t).ceil(), (h + 7.2 * t).ceil()), lines: lines, labels: labels);
}
