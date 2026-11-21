import 'dart:math' as math;

import '../data/cinema_seating_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class CinemaSeatingCadResult {
  const CinemaSeatingCadResult({this.drawing, this.issue, this.rows = 0, this.seatsPerBank = 0, this.baysPerBank = 0,
    this.hallWidthMm = 0, this.hallDepthMm = 0, this.rowGapMm = 0, this.screenGapMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final int rows, seatsPerBank, baysPerBank, hallWidthMm, hallDepthMm, rowGapMm, screenGapMm;
  int get fixedSeats => rows * seatsPerBank * 2;
  int get flexibleBays => baysPerBank * 2;
  String? toCsv() => drawing == null ? null : [
    'row,west_fixed_seats,east_fixed_seats,west_flexible_bays,east_flexible_bays',
    for (var i = 1; i <= rows; i++) 'R$i,$seatsPerBank,$seatsPerBank,0,0',
    'REAR,0,0,$baysPerBank,$baysPerBank',
    '',
  ].join('\r\n');
}

/// One clear seating envelope, not walls, doors, viewing quality or occupancy approval.
class CinemaSeatingCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == cinemaSeatingMode;

  CinemaSeatingCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    CinemaSeatingCadResult stop(String issue) => CinemaSeatingCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !cinemaSeatingCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Cinema / Entertainment and save the current measured seating brief.');
    }
    if (!const {null, 'public_facing'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 1) != 1 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one ground-floor seating hall without separate spaces or parking.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    int? mm(Object? v, {num min = .001, num max = 60}) =>
        v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    final a = req.answers;
    int? count(String key, int max) {
      final v = a[key];
      return v is num && v.isFinite && v >= 1 && v <= max && v == v.toInt() ? v.toInt() : null;
    }
    final rows = count('cs_rows', 24), cap = count('cs_cap', 30), target = count('cs_target', 1440), bays = count('cs_bays', 8);
    if (rows == null || cap == null || target == null || bays == null) return stop('Enter valid whole numbers for rows, seat limit, fixed-seat target and rear bays.');
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000), width = mm(a['cs_hall']);
    final seatW = mm(a['cs_seat_w'], max: 5), seatD = mm(a['cs_seat_d'], max: 5);
    final pitch = mm(a['cs_pitch'], max: 10), needGap = mm(a['cs_row_gap'], max: 10);
    final centre = mm(a['cs_centre'], max: 10), side = mm(a['cs_side'], max: 10), rear = mm(a['cs_rear'], max: 10),
      aisleMin = mm(a['cs_aisle_min'], max: 10);
    final bayW = mm(a['cs_bay_w'], max: 10), bayD = mm(a['cs_bay_d'], max: 10);
    final front = mm(a['cs_front']), screenOffset = mm(a['cs_screen_y']), screenW = mm(a['cs_screen_w']);
    final west = mm(a['cs_west'], min: 0, max: 2000), south = mm(a['cs_south'], min: 0, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || width == null || seatW == null || seatD == null || pitch == null ||
        needGap == null || centre == null || side == null || rear == null || aisleMin == null || bayW == null || bayD == null ||
        front == null || screenOffset == null || screenW == null || west == null || south == null) {
      return stop('Enter valid plot, seating, aisle, rear bay and screen dimensions.');
    }
    if (side < aisleMin || centre < aisleMin || rear < aisleMin) return stop('A side, centre or rear aisle is below the submitted minimum.');
    if (pitch - seatD < needGap) return stop('The clear strip behind occupied seats is below the submitted minimum.');
    if (screenOffset >= front || screenW > width) return stop('The centred screen line must fit in the hall strictly in front of the first row.');
    final available = width - centre - 2 * side;
    if (available < 2 * seatW) return stop('There is not enough width for two fixed-seat banks after reserving the aisles.');
    final bank = available / 2;
    final seats = math.min(available ~/ (2 * seatW), cap);
    if (rows * 2 * seats < target) return stop('Only ${rows * 2 * seats} fixed seats fit, below the submitted target of $target.');
    if (2 * bays * bayW > available) return stop('The flexible bays do not fit within the width of each rear bank.');
    final bayStart = front + rows * pitch, rearStart = bayStart + bayD, depth = rearStart + rear;
    for (final (edge, gap) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || gap < min) return stop('The clear seating hall conflicts with the $edge plot edge or supplied setback.');
    }
    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void modules(String layer, double start, int y, int count, int unit, int d) {
      final x = start + (bank - count * unit) / 2, end = x + count * unit;
      line(layer, x, y, end, y);
      // The rear aisle already marks the north edge of the flexible bays.
      if (layer != 'CS_BAY') line(layer, x, y + d, end, y + d);
      for (var i = 0; i <= count; i++) {
        if (count * unit == bank && (i == 0 || i == count)) continue; // Shared aisle boundary.
        line(layer, x + i * unit, y, x + i * unit, y + d);
      }
    }
    box('CS_PLOT', 0, 0, pw, pd);
    box('CS_HALL', west, south, west + width, south + depth);
    final left = (west + side).toDouble(), right = (west + width - side).toDouble() - bank;
    final cx = west + width / 2;
    for (final x in [left, left + bank, right, right + bank]) {
      line('CS_AISLE', x, south + front, x, south + rearStart);
    }
    line('CS_AISLE', west, south + rearStart, west + width, south + rearStart);
    line('CS_SCREEN', cx - screenW / 2, south + screenOffset, cx + screenW / 2, south + screenOffset);
    final t = (math.max(pw, pd) / 90).clamp(15, 9000).toDouble();
    for (var i = 0; i < rows; i++) {
      final y = south + front + i * pitch;
      modules('CS_SEAT', left, y, seats, seatW, seatD);
      modules('CS_SEAT', right, y, seats, seatW, seatD);
      labels.add(CadLabel('CS_SEAT', CadPoint(cx, y + seatD / 2), 'R${i + 1}', math.min(t * .65, pitch / 4)));
    }
    for (final x in [left, right]) {
      modules('CS_BAY', x, south + bayStart, bays, bayW, bayD);
    }
    labels.addAll([CadLabel('CS_BAY', CadPoint(cx, south + bayStart + bayD / 2), 'REAR', .65 * t),
      CadLabel('CS_SCREEN', CadPoint(cx, south + screenOffset - .8 * t), 'SCREEN', .64 * t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 6 * t), 'MEASURED CINEMA SEAT BANKS / LOCAL MM', t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 4.6 * t), 'CLEAR HALL ${_m(width)} x ${_m(depth)} M / ${rows * 2 * seats} FIXED SEATS / ${2 * bays} FLEXIBLE BAYS', .65 * t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 3.2 * t), 'ROW GAP ${_m(pitch - seatD)} M / SCREEN TO FIRST ROW ${_m(front - screenOffset)} M', .6 * t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 1.8 * t), 'LAYOUT COUNTS ONLY / NO OCCUPANCY OR ACCESSIBILITY APPROVAL', .59 * t)]);
    final nx = pw + 2.5 * t;
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - t / 2, pd - t, nx, pd);
    line('ANNOTATIONS', nx + t / 2, pd - t, nx, pd);
    labels.add(CadLabel('ANNOTATIONS', CadPoint(nx, pd + t), 'N', .65 * t));
    final bounds = PlanRect(math.min(-2 * t, pw / 2 - 43 * t).floor(), (-2 * t).floor(), math.max(nx + 3 * t, pw / 2 + 43 * t).ceil(), (pd + 7.5 * t).ceil());
    return CinemaSeatingCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels), rows: rows,
      seatsPerBank: seats, baysPerBank: bays, hallWidthMm: width, hallDepthMm: depth, rowGapMm: pitch - seatD, screenGapMm: front - screenOffset);
  }
}
