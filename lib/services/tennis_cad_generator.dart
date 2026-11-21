import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/tennis_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class TennisCadResult {
  const TennisCadResult({this.drawing, this.issue, this.courtCount = 0,
    this.bankWidthMm = 0, this.bankDepthMm = 0, this.courtEnvelopeAreaM2 = 0});

  final FloorPlanCad? drawing;
  final String? issue;
  final int courtCount, bankWidthMm, bankDepthMm;
  /// Sum of individual court envelopes, excluding gaps between them.
  final double courtEnvelopeAreaM2;
}

/// Measured marking centrelines in local millimetres; no rulebook presets.
class TennisCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == 'tennis_measured_bank';

  TennisCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    TennisCadResult stop(String issue) => TennisCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion ||
        snap.version != requirementsSchemaVersion || !tennisCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select a supported sports type and save the measured tennis brief.');
    }
    if (!const {null, 'outdoor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use an outdoor court bank without buildings, parking or separate Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) {
      return stop('Use a cardinally aligned rectangular or square plot.');
    }

    final a = snap.answers;
    int? mm(Object? v, {bool zero = false, int max = 300}) {
      if (v is! num || !v.isFinite || v < (zero ? 0 : .001) || v > max) return null;
      return (v * 1000).round();
    }
    final rawCount = a['tc_count'];
    if (rawCount is! num || !rawCount.isFinite || rawCount < 1 || rawCount > 4 || rawCount != rawCount.toInt()) {
      return stop('Enter a whole number of courts from 1 to 4.');
    }
    final count = rawCount.toInt();
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final w = mm(a['tc_doubles']), singles = mm(a['tc_singles']), length = mm(a['tc_length']);
    final service = mm(a['tc_service']), mark = mm(a['tc_mark']), post = mm(a['tc_post']);
    final side = mm(a['tc_side']), southEnd = mm(a['tc_south_end']), northEnd = mm(a['tc_north_end']);
    final gap = mm(a['tc_gap'], zero: true);
    final west = mm(a['tc_west'], zero: true, max: 2000), south = mm(a['tc_south'], zero: true, max: 2000);
    if (pw == null || pd == null || w == null || singles == null || length == null || service == null ||
        mark == null || post == null || side == null || southEnd == null || northEnd == null || gap == null ||
        west == null || south == null || (sel.plotShapeId == 'square' && pw != pd)) {
      return stop('Enter the measured plot, court markings, net-post locations, run-off and bank offsets.');
    }
    if (singles >= w) return stop('Singles sidelines must be inside the doubles sidelines.');
    if (2 * service >= length) return stop('Each service line must be strictly between the net and its baseline.');
    if (2 * (mark + service) >= length) return stop('Each baseline centre mark must end before its service line.');
    if (post >= side) return stop('Each net-post centre must be inside the side allowance.');
    if (count > 1 && gap == 0) return stop('Enter a positive gap between adjacent court envelopes.');
    if (count == 1 && gap != 0) return stop('Use a zero inter-court gap for a single court.');

    final unitW = w + 2 * side, bankD = length + southEnd + northEnd;
    final bankW = count * unitW + (count - 1) * gap;
    final setbacks = <String, int>{};
    for (final (edge, clear) in [('left', west), ('right', pw - west - bankW),
      ('front', south), ('rear', pd - south - bankD)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, zero: true, max: 2000);
      if (min == null || clear < min) return stop('The court bank conflicts with the $edge plot edge or supplied setback.');
      setbacks[edge] = min;
    }

    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) =>
        lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    box('TENNIS_PLOT', 0, 0, pw, pd);
    if (setbacks.values.any((v) => v > 0)) {
      box('TENNIS_SETBACK', setbacks['left']!, setbacks['front']!, pw - setbacks['right']!, pd - setbacks['rear']!);
    }
    final text = (math.max(pw, pd) / 85).clamp(50, 6500).toDouble();
    final y0 = south + southEnd, y1 = y0 + length, net = y0 + length / 2;
    for (var i = 0; i < count; i++) {
      final left = west + i * (unitW + gap);
      final x0 = left + side, x1 = x0 + w, mid = x0 + w / 2;
      final xs = mid - singles / 2, xe = mid + singles / 2;
      box('TENNIS_RUNOFF', left, south, left + unitW, south + bankD);
      box('TENNIS_DOUBLES', x0, y0, x1, y1);
      for (final x in [xs, xe]) {
        line('TENNIS_SINGLES', x, y0, x, y1);
      }
      for (final y in [net - service, net + service]) {
        line('TENNIS_SERVICE', xs, y, xe, y);
      }
      line('TENNIS_SERVICE', mid, net - service, mid, net + service);
      line('TENNIS_SERVICE', mid, y0, mid, y0 + mark);
      line('TENNIS_SERVICE', mid, y1, mid, y1 - mark);
      line('TENNIS_NET', x0 - post, net, x1 + post, net);
      // Ticks identify centres, not the post footprint or required clearance.
      final tick = math.min((side - post) / 2, length / 30);
      for (final x in [x0 - post, x1 + post]) {
        line('TENNIS_NET', x, net - tick, x, net + tick);
      }
      labels.add(CadLabel('ANNOTATIONS', CadPoint(mid, south + southEnd / 2), 'COURT ${i + 1}',
        math.min(text, math.min(unitW / 8, southEnd / 3))));
    }
    final ax = pw + 2 * text;
    line('ANNOTATIONS', ax, pd - 2 * text, ax, pd);
    line('ANNOTATIONS', ax - text / 2, pd - text, ax, pd);
    line('ANNOTATIONS', ax + text / 2, pd - text, ax, pd);
    String m(int v) => (v / 1000).toStringAsFixed(3);
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(ax, pd + text), 'N', text * .7),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 5 * text), 'MEASURED OUTDOOR TENNIS / LOCAL MM', text),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 3.5 * text),
        '$count COURT(S) / ${m(w)} x ${m(length)} M DOUBLES / ${m(singles)} M SINGLES', text * .68),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 2 * text),
        'BANK ${m(bankW)} x ${m(bankD)} M / CENTRELINES ONLY / NO CERTIFICATION', text * .64),
    ]);
    final bounds = PlanRect(math.min(-text * 2, pw / 2 - text * 28).floor(), (-text * 2).floor(),
      math.max(ax + text * 3, pw / 2 + text * 28).ceil(), (pd + text * 7).ceil());
    return TennisCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels),
      courtCount: count, bankWidthMm: bankW, bankDepthMm: bankD, courtEnvelopeAreaM2: count * unitW * bankD / 1e6);
  }
}
