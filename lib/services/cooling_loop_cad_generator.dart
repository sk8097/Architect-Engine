import 'dart:math' as math;

import '../data/cooling_loop_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm, [int places = 3]) => (mm / 1000).toStringAsFixed(places);

class CoolingLoopSegment {
  const CoolingLoopSegment(this.id, this.type, this.startMm, this.endMm, this.radiusMm);
  final int id, radiusMm;
  final String type;
  final double startMm, endMm;
  String _row() => '$id,$type,${_m(startMm, 6)},${_m(endMm, 6)},${_m(endMm - startMm, 6)},${radiusMm == 0 ? '' : _m(radiusMm, 6)}';
}

class CoolingLoopCadResult {
  const CoolingLoopCadResult({this.drawing, this.issue, this.segments = const [], this.widthMm = 0, this.depthMm = 0,
    this.reachMm = 0, this.lengthMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<CoolingLoopSegment> segments;
  final int widthMm, depthMm, reachMm;
  final double lengthMm;

  String? toCsv() => drawing == null ? null : [
    'segment,type,start_chainage_m,end_chainage_m,centreline_length_m,bend_radius_m',
    for (final segment in segments) segment._row(),
    '',
  ].join('\r\n');
}

/// One planar U-offset with four quarter bends. No thermal, stress or hydraulic sizing.
class CoolingLoopCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == coolingLoopMode;

  CoolingLoopCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    CoolingLoopCadResult stop(String issue) => CoolingLoopCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !coolingLoopCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select District Cooling and save the current pipe loop brief.');
    }
    if (!const {null, 'outdoor_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Outdoor Yard and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor pipe loop only. Remove floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 200}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final radius = mm(a['cl_r']), minR = mm(a['cl_min_r']), od = mm(a['cl_od']), clear = mm(a['cl_clear']);
    final leadW = mm(a['cl_w_lead']), leadE = mm(a['cl_e_lead']), leg = mm(a['cl_leg']), bridge = mm(a['cl_bridge']);
    final west = mm(a['cl_west'], min: 0, max: 2000), south = mm(a['cl_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || radius == null || minR == null || od == null ||
        clear == null || leadW == null || leadE == null || leg == null || bridge == null || west == null || south == null) {
      return stop('Enter valid plot dimensions, bend radius, outside diameter, clearance and tangent lengths.');
    }
    if (radius < minR) return stop('Increase the centreline bend radius to meet the submitted minimum.');
    final band2 = od + 2 * clear;
    if (2 * radius <= band2) return stop('The inside clearance arc has no positive radius. Increase the bend radius or revise the pipe envelope.');
    final halfPipe = od / 2, halfBand = band2 / 2;
    final horizontal = leadW + leadE + 4 * radius + bridge, reach = 2 * radius + leg;
    final width = horizontal + band2, depth = reach + band2;
    for (final (edge, available) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || available < min) return stop('The full loop and tie-in clearance envelope conflict with the $edge plot edge or supplied setback.');
    }
    final lines = <CadLine>[], arcs = <CadArc>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void mark(String layer, num x, num y, String text, num size) => labels.add(CadLabel(layer, CadPoint(x, y), text, size));
    box('CL_PLOT', 0, 0, pw, pd);
    final x0 = west + halfBand, x1 = x0 + horizontal, y0 = south + halfBand, y1 = y0 + reach;
    final aX = x0 + leadW, bX = aX + 2 * radius, cX = bX + bridge, dX = cX + 2 * radius;
    final low = y0 + radius, high = y1 - radius;
    // Positive offset is left of west-to-east travel. Arc entities remain CCW for DXF,
    // independently of traversal direction, with the same centres on all parallel offsets.
    void trace(String layer, double s, double extend) {
      line(layer, x0 - extend, y0 + s, aX, y0 + s);
      arcs.add(CadArc(layer, CadPoint(aX, low), radius - s, 270, 360));
      line(layer, aX + radius - s, low, aX + radius - s, high);
      arcs.add(CadArc(layer, CadPoint(bX, high), radius + s, 90, 180));
      line(layer, bX, y1 + s, cX, y1 + s);
      arcs.add(CadArc(layer, CadPoint(cX, high), radius + s, 0, 90));
      line(layer, cX + radius + s, high, cX + radius + s, low);
      arcs.add(CadArc(layer, CadPoint(dX, low), radius - s, 180, 270));
      line(layer, dX, y0 + s, x1 + extend, y0 + s);
    }
    trace('CL_AXIS', 0, 0);
    for (final s in [-halfPipe, halfPipe]) {
      trace('CL_PIPE', s, 0);
    }
    for (final s in [-halfBand, halfBand]) {
      trace('CL_CLEAR', s, halfBand);
    }
    for (final x in [x0, x1]) {
      line('CL_TIE', x, y0 - halfPipe, x, y0 + halfPipe);
    }
    for (final x in [west, west + width]) {
      line('CL_CLEAR', x, south, x, south + band2);
    }
    final segments = <CoolingLoopSegment>[];
    var station = 0.0;
    final quarter = math.pi * radius / 2;
    for (final (type, length) in <(String, num)>[
      ('straight', leadW), ('bend_left_90', quarter), ('straight', leg), ('bend_right_90', quarter),
      ('straight', bridge), ('bend_right_90', quarter), ('straight', leg), ('bend_left_90', quarter), ('straight', leadE),
    ]) {
      final next = station + length.toDouble();
      segments.add(CoolingLoopSegment(segments.length + 1, type, station, next, type == 'straight' ? 0 : radius));
      station = next;
    }
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble(), nx = pw + 2.5 * t;
    mark('CL_TIE', x0, south - t, 'WEST TIE-IN', .65 * t);
    mark('CL_TIE', x1, south - t, 'EAST TIE-IN', .65 * t);
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    mark('ANNOTATIONS', pw / 2, pd + 4 * t, 'MEASURED DISTRICT COOLING PIPE LOOP / PLAN / LOCAL MM', t);
    mark('ANNOTATIONS', pw / 2, pd + 2.5 * t, 'CENTRELINE ${_m(station)} M / 4 QUARTER BENDS / ENVELOPE ${_m(width)} x ${_m(depth)} M', .64 * t);
    num minX = 0, maxX = nx, minY = 0, maxY = pd;
    for (final label in labels) {
      final half = label.height * label.text.length * .43;
      minX = math.min(minX, label.at.x - half);
      maxX = math.max(maxX, label.at.x + half);
      minY = math.min(minY, label.at.y - label.height);
      maxY = math.max(maxY, label.at.y + label.height);
    }
    final drawing = FloorPlanCad.fromEntities(bounds: PlanRect((minX - 2 * t).floor(), (minY - 2 * t).floor(),
      (maxX + 2 * t).ceil(), (maxY + 2 * t).ceil()), lines: lines, arcs: arcs, labels: labels);
    return CoolingLoopCadResult(drawing: drawing, segments: List.unmodifiable(segments), widthMm: width, depthMm: depth,
      reachMm: reach, lengthMm: station);
  }
}
