import 'dart:math' as math;

import '../data/athletics_track_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class TrackLane {
  const TrackLane(this.number, this.radiusMm, this.lapM, this.staggerM, this.start);
  final int number, radiusMm;
  final double lapM, staggerM;
  final CadPoint start;
}

class AthleticsTrackCadResult {
  const AthleticsTrackCadResult({this.drawing, this.issue, this.lanes = const [], this.widthMm = 0, this.depthMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<TrackLane> lanes;
  final int widthMm, depthMm;

  String? toCsv() {
    if (drawing == null) return null;
    String m(num mm) => (mm / 1000).toStringAsFixed(6);
    return [
      'lane,running_radius_m,lap_m,one_lap_stagger_m,start_east_m,start_north_m',
      for (final lane in lanes)
        [lane.number, m(lane.radiusMm), lane.lapM.toStringAsFixed(6), lane.staggerM.toStringAsFixed(6),
          m(lane.start.x), m(lane.start.y)].join(','),
      '',
    ].join('\r\n');
  }
}

/// Horizontal oval; stagger marks equalize a single lap to lane 1 distance.
class AthleticsTrackCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == 'athletics_measured_track';

  AthleticsTrackCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    AthleticsTrackCadResult stop(String issue) => AthleticsTrackCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !athleticsTrackCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select a supported outdoor sports type and save the measured track brief.');
    }
    if (!const {null, 'outdoor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use an outdoor track without building floors, parking or separate Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = snap.answers;
    int? mm(Object? v, {bool zero = false, int max = 300}) =>
        v is num && v.isFinite && v >= (zero ? 0 : .001) && v <= max ? (v * 1000).round() : null;
    final entered = a['ak_lanes'];
    if (entered is! num || !entered.isFinite || entered < 2 || entered > 10 || entered.toInt() != entered) {
      return stop('Enter a whole lane count from 2 to 10.');
    }
    final count = entered.toInt();
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final straight = mm(a['ak_straight']), inner = mm(a['ak_radius']), width = mm(a['ak_lane_width'], max: 10);
    final offset1 = mm(a['ak_offset_1'], max: 10), offsetOther = mm(a['ak_offset_other'], max: 10);
    final runoff = mm(a['ak_runoff']);
    final west = mm(a['ak_west'], zero: true, max: 2000), south = mm(a['ak_south'], zero: true, max: 2000);
    final target = mm(a['ak_target'], max: 3000), tolerance = mm(a['ak_tolerance'], max: 100);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || straight == null || inner == null ||
        width == null || offset1 == null || offsetOther == null || runoff == null || west == null || south == null ||
        target == null || tolerance == null) {
      return stop('Enter measured plot, track, run-off, calculation offsets and lap target dimensions.');
    }
    if (offset1 >= width || offsetOther >= width) return stop('Both measurement offsets must be strictly inside their lanes.');
    final outer = inner + count * width, reserve = outer + runoff;
    final envelopeW = 2 * reserve, envelopeD = straight + envelopeW;
    for (final (edge, clear) in [('left', west), ('right', pw - west - envelopeW), ('front', south), ('rear', pd - south - envelopeD)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, zero: true, max: 2000);
      if (min == null || clear < min) return stop('The track and run-off envelope conflict with the $edge plot edge or supplied setback.');
    }
    final firstRadius = inner + offset1;
    final firstLap = 2 * straight + 2 * math.pi * firstRadius;
    if ((firstLap - target).abs() > tolerance + 1e-8) {
      return stop('Lane 1 lap ${(firstLap / 1000).toStringAsFixed(6)} m misses the ${(target / 1000).toStringAsFixed(3)} m target by more than ${(tolerance / 1000).toStringAsFixed(3)} m.');
    }

    final lines = <CadLine>[], arcs = <CadArc>[], labels = <CadLabel>[], lanes = <TrackLane>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    final cx = west + reserve, sy = south + reserve, ny = sy + straight;
    void oval(String layer, int r) {
      line(layer, cx + r, sy, cx + r, ny);
      line(layer, cx - r, ny, cx - r, sy);
      arcs.addAll([CadArc(layer, CadPoint(cx, ny), r, 0, 180), CadArc(layer, CadPoint(cx, sy), r, 180, 360)]);
    }
    line('TRACK_PLOT', 0, 0, pw, 0);
    line('TRACK_PLOT', pw, 0, pw, pd);
    line('TRACK_PLOT', pw, pd, 0, pd);
    line('TRACK_PLOT', 0, pd, 0, 0);
    oval('TRACK_RUNOFF', reserve);
    for (var i = 0; i <= count; i++) {
      oval('TRACK_LANES', inner + i * width);
    }
    line('TRACK_FINISH', cx + inner, sy, cx + outer, sy);

    // Project a station on the running line across its lane using the local radial
    // direction on a bend, or a transverse line on either straight.
    for (var lane = 1; lane <= count; lane++) {
      final inR = inner + (lane - 1) * width, outR = inR + width;
      final r = inR + (lane == 1 ? offset1 : offsetOther);
      final bend = math.pi * r, advance = 2 * math.pi * (r - firstRadius);
      late final CadPoint Function(int) at;
      if (advance <= straight) {
        at = (radius) => CadPoint(cx + radius, sy + advance);
      } else if (advance <= straight + bend) {
        final angle = (advance - straight) / r;
        at = (radius) => CadPoint(cx + radius * math.cos(angle), ny + radius * math.sin(angle));
      } else if (advance <= 2 * straight + bend) {
        at = (radius) => CadPoint(cx - radius, ny - (advance - straight - bend));
      } else {
        final angle = math.pi + (advance - 2 * straight - bend) / r;
        at = (radius) => CadPoint(cx + radius * math.cos(angle), sy + radius * math.sin(angle));
      }
      final start = at(r);
      final lap = (2 * straight + 2 * bend) / 1000;
      lanes.add(TrackLane(lane, r, lap, advance / 1000, start));
      oval('TRACK_MEASURE', r);
      if (lane > 1) lines.add(CadLine('TRACK_STAGGER', at(inR), at(outR)));
    }
    final t = (math.max(pw, pd) / 88).clamp(30, 6500).toDouble();
    final ax = pw + 2 * t;
    line('ANNOTATIONS', ax, pd - 2 * t, ax, pd);
    line('ANNOTATIONS', ax - t / 2, pd - t, ax, pd);
    line('ANNOTATIONS', ax + t / 2, pd - t, ax, pd);
    String m(int value) => (value / 1000).toStringAsFixed(3);
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(ax, pd + t), 'N', t * .7),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 5.5 * t), 'MEASURED OVAL ATHLETICS TRACK / LOCAL MM', t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 4.1 * t),
        '$count LANES / LANE 1 LAP ${(firstLap / 1000).toStringAsFixed(3)} M / TARGET ${m(target)} M', t * .68),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 2.7 * t),
        'RUN-OFF ENVELOPE ${m(envelopeW)} x ${m(envelopeD)} M / COUNTERCLOCKWISE', t * .66),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 1.3 * t),
        'ONE-LAP GEOMETRIC STAGGERS / NOT A CERTIFIED COURSE', t * .65),
    ]);
    final bounds = PlanRect(math.min(-2 * t, pw / 2 - 30 * t).floor(), (-2 * t).floor(),
      math.max(ax + 3 * t, pw / 2 + 30 * t).ceil(), (pd + 7.2 * t).ceil());
    return AthleticsTrackCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, arcs: arcs, labels: labels),
      lanes: List.unmodifiable(lanes), widthMm: envelopeW, depthMm: envelopeD);
  }
}
