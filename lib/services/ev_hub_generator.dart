import 'dart:math' as math;

import '../data/ev_hub_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class EvHubResult {
  const EvHubResult(this.drawing, this.issue, {this.bays = 0, this.clearHeadPassMm = 0, this.transferWidthMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final int bays, clearHeadPassMm, transferWidthMm;
}

/// One row of perpendicular EV bays, with separate drive and pedestrian frontage access.
class EvHubGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'ev_measured_hub';

  EvHubResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    EvHubResult stop(String issue) => EvHubResult(null, issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !evHubEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Energy / utilities / communications → EV Charging Hub and save the current brief.');
    }
    if (!const {null, 'outdoor_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none, ProjectParking.car}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a new outdoor yard with no structures, separate Space selections or non-car parking.');
    }
    if (!const {'square', 'rectangular'}.contains(sel.plotShapeId) || !const {'North', 'South', 'East', 'West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and a cardinal frontage.');
    }
    final a = snap.answers;
    int? mm(Object? value, {bool zero = false}) {
      if (value is! num || !value.isFinite || value < 0 || value > 300) return null;
      final n = (value * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final w = mm(widthFt * .3048), d = mm(depthFt * .3048), count = a['ev_count'];
    final left = mm(a['ev_offset_left'], zero: true), start = mm(a['ev_offset_front']);
    final bayW = mm(a['ev_bay_width']), accessW = mm(a['ev_access_width']), bayDepth = mm(a['ev_bay_depth']);
    final transfer = mm(a['ev_transfer']), aisle = mm(a['ev_aisle']), end = mm(a['ev_end']);
    final walk = mm(a['ev_walk']), service = mm(a['ev_service']);
    final padX = mm(a['ev_pad_x']), padY = mm(a['ev_pad_y']), pass = mm(a['ev_head_pass']);
    if (w == null || d == null || count is! int || count < 2 || count > 40 || left == null || start == null ||
        bayW == null || accessW == null || bayDepth == null || transfer == null || aisle == null || end == null ||
        walk == null || service == null || padX == null || padY == null || pass == null || (sel.plotShapeId == 'square' && w != d)) {
      return stop('Enter measured plot and layout dimensions, pad sizes, clear passages and a count of 2–40 bays.');
    }
    if (a['cars'] case final num entered when entered != count) {
      return stop('The separate car count must match the entered charging bay count.');
    }
    if (accessW < bayW) return stop('The designated transfer bay cannot be narrower than a standard bay.');
    if (padX > service) return stop('Charger pads must fit the equipment strip without protruding into the walkway or bay.');
    final clearPass = (bayW - padY) ~/ 2;
    if (clearPass < pass) return stop('The centred charger pad leaves too little clear passage beside it in a standard bay.');
    final head = left + walk, bayLeft = head + service, bayRight = bayLeft + bayDepth, right = bayRight + aisle;
    final firstBay = start + transfer, lastBayEnd = firstBay + accessW + (count - 1) * bayW;
    final back = lastBayEnd + end;
    for (final (side, available) in [('left', left), ('right', w - right), ('front', start), ('rear', d - back)]) {
      final raw = a['${side}_setback'], setback = raw == null ? 0 : mm(raw, zero: true);
      if (setback == null || available < setback) {
        return stop('The measured hub conflicts with the $side plot edge or supplied setback.');
      }
    }
    final rotated = facing == 'East' || facing == 'West', pw = rotated ? d : w, pd = rotated ? w : d;
    CadPoint p(num x, num y) => switch (facing) {
      'North' => CadPoint(w-x, d-y), 'East' => CadPoint(d-y, x), 'West' => CadPoint(y, w-x), _ => CadPoint(x,y),
    };
    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num r, num t) => lines.add(CadLine(layer, p(x,y), p(r,t)));
    void box(String layer, num l, num b, num r, num t) {
      line(layer,l,b,r,b); line(layer,r,b,r,t); line(layer,r,t,l,t); line(layer,l,t,l,b);
    }
    box('EV_PLOT', 0, 0, w, d);
    box('EV_WALK', left, 0, head, lastBayEnd);
    box('EV_DRIVE', bayRight, 0, right, back);
    box('EV_EQUIPMENT', head, firstBay, bayLeft, lastBayEnd);
    box('EV_TRANSFER', head, start, bayRight, firstBay);
    // The transfer strip meets the uninterrupted frontage walk directly.
    final marker = math.min(walk, transfer) * .2;
    line('EV_TRANSFER', (left+head)/2, 0, (left+head)/2, (start+firstBay)/2);
    line('EV_TRANSFER', (left+head)/2, (start+firstBay)/2, bayRight-marker, (start+firstBay)/2);
    final text = (math.max(w, d) / 80).clamp(50, 5000).toDouble();
    for (var i = 0; i < count; i++) {
      final b = firstBay + (i == 0 ? 0 : accessW + (i - 1)*bayW), bay = i == 0 ? accessW : bayW;
      final top = b + bay, py = b + (bay-padY)~/2, px = head + (service-padX)~/2;
      box('EV_BAYS', bayLeft, b, bayRight, top);
      box('EV_PADS', px, py, px+padX, py+padY);
      box('EV_HEAD_PASS', head, top-pass, bayLeft, top);
      labels.add(CadLabel('EV_BAYS', p((bayLeft+bayRight)/2, (b+top)/2), i == 0 ? 'EV 1 / TRANSFER' : 'EV ${i+1}',
        math.min(text * .7, math.min(bayDepth / 11, bay / 4))));
    }
    labels.add(CadLabel('EV_DRIVE', p((bayRight+right)/2, start/2), 'DRIVE ENTRY', math.min(text*.65, aisle/9)));
    final ax = pw + text * 2;
    lines.addAll([
      CadLine('ANNOTATIONS', CadPoint(ax, pd-text*2), CadPoint(ax,pd)),
      CadLine('ANNOTATIONS', CadPoint(ax-text*.4,pd-text*.7), CadPoint(ax,pd)),
      CadLine('ANNOTATIONS', CadPoint(ax+text*.4,pd-text*.7), CadPoint(ax,pd)),
    ]);
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(ax,pd+text), 'N', text*.7),
      CadLabel('ANNOTATIONS', CadPoint(pw/2,pd+text*4.5), 'EV CHARGING YARD / CONCEPT ONLY', text),
      CadLabel('ANNOTATIONS', CadPoint(pw/2,pd+text*3.1), '$count BAYS / 1 TRANSFER BAY / LOCAL MM', text*.7),
      CadLabel('ANNOTATIONS', CadPoint(pw/2,pd+text*1.8), 'NO VEHICLE SWEPT PATH OR ELECTRICAL DESIGN', text*.65),
    ]);
    final bounds = PlanRect(math.min(-text*2, pw/2-text*21).floor(), (-text*2).floor(),
      math.max(ax+text*3, pw/2+text*21).ceil(), (pd+text*6).ceil());
    return EvHubResult(FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels), null,
      bays: count, clearHeadPassMm: clearPass, transferWidthMm: transfer);
  }
}
