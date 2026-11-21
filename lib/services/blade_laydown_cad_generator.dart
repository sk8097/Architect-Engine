import 'dart:math' as math;

import '../data/blade_laydown_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm, [int places = 3]) => (mm / 1000).toStringAsFixed(places);

class BladeLaydownPad {
  const BladeLaydownPad(this.id, this.startMm, this.endMm, this.widthMm, this.worstChMm, this.widestMm);
  final String id;
  final double startMm, endMm, worstChMm, widestMm;
  final int widthMm;
  double get marginMm => (widthMm - widestMm) / 2;
  String _row() => '$id,${_m(startMm, 6)},${_m(endMm, 6)},${_m(widthMm, 6)},${_m(worstChMm, 6)},${_m(widestMm, 6)},${_m(marginMm, 6)}';
}

class BladeLaydownCadResult {
  const BladeLaydownCadResult({this.drawing, this.issue, this.pads = const [], this.widthMm = 0, this.depthMm = 0, this.gapMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<BladeLaydownPad> pads;
  final int widthMm, depthMm, gapMm;

  String? toCsv() => drawing == null ? null : [
    'pad,along_start_m,along_end_m,pad_width_m,critical_chainage_m,maximum_blade_width_m,minimum_each_side_margin_m',
    for (final pad in pads) pad._row(),
    '',
  ].join('\r\n');
}

/// One symmetric, piecewise-linear plan envelope and two geometric pad reserves.
class BladeLaydownCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == bladeLaydownMode;

  BladeLaydownCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    BladeLaydownCadResult stop(String issue) => BladeLaydownCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !bladeLaydownCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Wind Support Facility and save the current blade laydown brief.');
    }
    if (!const {null, 'outdoor_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Outdoor Yard and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor blade laydown strip. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 250}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final length = mm(a['bl_length']), root = mm(a['bl_root']), peakCh = mm(a['bl_peak_ch']), peak = mm(a['bl_peak']), tip = mm(a['bl_tip'], min: 0);
    final chA = mm(a['bl_a_ch']), chB = mm(a['bl_b_ch']), padL = mm(a['bl_pad_l']), wA = mm(a['bl_a_w']), wB = mm(a['bl_b_w']);
    final minMargin = mm(a['bl_min_margin'], min: 0), minGap = mm(a['bl_min_gap']);
    final side = mm(a['bl_side']), end = mm(a['bl_end']);
    final west = mm(a['bl_west'], min: 0, max: 2000), south = mm(a['bl_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || length == null || root == null || peakCh == null ||
        peak == null || tip == null || chA == null || chB == null || padL == null || wA == null || wB == null ||
        minMargin == null || minGap == null || side == null || end == null || west == null || south == null) {
      return stop('Enter valid measured plot, blade, pad and reserve dimensions.');
    }
    if (peakCh >= length || peak < math.max(root, tip)) return stop('The widest blade station must be inside its length and at least as wide as both ends.');
    final halfPad = padL / 2;
    if (chA >= chB || chA - halfPad < 0 || chB + halfPad > length) {
      return stop('Order the south and north pad reserves by chainage and keep their complete lengths between root and tip.');
    }
    final gap = chB - chA - padL;
    if (gap < minGap) return stop('Increase the clear gap between pad reserves to meet its submitted minimum.');
    double bladeWidth(double ch) => ch <= peakCh
        ? root + (peak - root) * ch / peakCh
        : peak + (tip - peak) * (ch - peakCh) / (length - peakCh);
    final pads = <BladeLaydownPad>[];
    for (final (id, centre, width) in [('A', chA, wA), ('B', chB, wB)]) {
      final low = centre - halfPad, high = centre + halfPad;
      // The linear outline can attain its interval maximum only at an end or the interior join.
      final candidates = [low, if (peakCh > low && peakCh < high) peakCh.toDouble(), high];
      var worst = low, widest = bladeWidth(low);
      for (final ch in candidates.skip(1)) {
        final sample = bladeWidth(ch);
        if (sample > widest) {
          widest = sample;
          worst = ch;
        }
      }
      final pad = BladeLaydownPad(id, low, high, width, worst, widest);
      if (pad.marginMm < minMargin - 1e-8) return stop('Pad $id leaves ${_m(pad.marginMm, 6)} m per side at Ch ${_m(worst, 4)} m, below the submitted margin.');
      pads.add(pad);
    }
    final width = math.max(peak, math.max(wA, wB)) + 2 * side, depth = length + 2 * end;
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final minimum = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (minimum == null || available < minimum) return stop('The full laydown and service envelope conflict with the $edge plot edge or supplied setback.');
    }

    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void mark(String layer, num x, num y, String text, num size) => labels.add(CadLabel(layer, CadPoint(x, y), text, size));
    box('BL_PLOT', 0, 0, pw, pd);
    box('BL_RESERVE', west, south, west + width, south + depth);
    final cx = west + width / 2, y0 = south + end;
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    for (final pad in pads) {
      box('BL_PAD', cx - pad.widthMm / 2, y0 + pad.startMm, cx + pad.widthMm / 2, y0 + pad.endMm);
      mark('BL_PAD', west + width + t, y0 + (pad.startMm + pad.endMm) / 2, 'PAD ${pad.id}', t * .6);
    }
    for (final sign in [-1, 1]) {
      line('BL_BLADE', cx + sign * root / 2, y0, cx + sign * peak / 2, y0 + peakCh);
      line('BL_BLADE', cx + sign * peak / 2, y0 + peakCh, cx + sign * tip / 2, y0 + length);
    }
    line('BL_BLADE', cx - root / 2, y0, cx + root / 2, y0);
    if (tip > 0) line('BL_BLADE', cx - tip / 2, y0 + length, cx + tip / 2, y0 + length);
    line('BL_STATION', cx - peak / 2, y0 + peakCh, cx + peak / 2, y0 + peakCh);
    mark('BL_STATION', cx, y0 - .6 * t, 'ROOT / CH 0', .6 * t);
    mark('BL_STATION', cx, y0 + length + .6 * t, 'TIP', .6 * t);
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    mark('ANNOTATIONS', pw / 2, pd + 4 * t, 'MEASURED WIND-BLADE LAYDOWN / PLAN / LOCAL MM', t);
    mark('ANNOTATIONS', pw / 2, pd + 2.5 * t, '2 PAD RESERVES / CLEAR GAP ${_m(gap)} M / ENVELOPE ${_m(width)} x ${_m(depth)} M', .64 * t);
    num minX = 0, maxX = nx, minY = 0, maxY = pd;
    for (final label in labels) {
      final half = label.height * label.text.length * .43;
      minX = math.min(minX, label.at.x - half);
      maxX = math.max(maxX, label.at.x + half);
      minY = math.min(minY, label.at.y - label.height);
      maxY = math.max(maxY, label.at.y + label.height);
    }
    final drawing = FloorPlanCad.fromEntities(bounds: PlanRect((minX - 2 * t).floor(), (minY - 2 * t).floor(),
      (maxX + 2 * t).ceil(), (maxY + 2 * t).ceil()), lines: lines, labels: labels);
    return BladeLaydownCadResult(drawing: drawing, pads: List.unmodifiable(pads), widthMm: width, depthMm: depth, gapMm: gap);
  }
}
