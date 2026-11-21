import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/recycling_dropoff_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm, [int places = 3]) => (mm / 1000).toStringAsFixed(places);

class RecyclingDropoffBay {
  const RecyclingDropoffBay(this.id, this.westMm, this.southMm, this.eastMm, this.northMm);
  final String id;
  final double westMm, eastMm;
  final int southMm, northMm;

  String _csvRow() => '$id,${_m(westMm, 4)},${_m(southMm, 4)},${_m(eastMm, 4)},${_m(northMm, 4)},south,north';
}

class RecyclingDropoffCadResult {
  const RecyclingDropoffCadResult({this.drawing, this.issue, this.bays = const [], this.widthMm = 0,
    this.depthMm = 0, this.apronMm = 0, this.laneMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<RecyclingDropoffBay> bays;
  final int widthMm, depthMm, apronMm, laneMm;

  String? toCsv() => drawing == null ? null : [
    'bay_id,x_min_m,y_min_m,x_max_m,y_max_m,public_face,collection_face',
    for (final bay in bays) bay._csvRow(),
    '',
  ].join('\r\n');
}

/// Fits one container bank between public and collection strips; not an access or operations model.
class RecyclingDropoffCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == recyclingDropoffMode;

  RecyclingDropoffCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    RecyclingDropoffCadResult stop(String issue) => RecyclingDropoffCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !recyclingDropoffCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Recycling Centre and save the current drop-off brief.');
    }
    if (!const {null, 'support_facility'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'site_development', 'feasibility'}.contains(sel.actionId)) {
      return stop('Use a blank arrangement or Support Facility and an early design or site-development action.');
    }
    if ((brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor drop-off row. Remove building floors, separate parking and Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers;
    int? mm(Object? v, {num min = .001, num max = 100}) =>
        v is num && v.isFinite && v >= min && v <= max ? (1000 * v).round() : null;
    int? count(Object? v) => v is num && v.isFinite && v >= 1 && v <= 60 && v == v.toInt() ? v.toInt() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final min = count(a['rd_min']), cap = count(a['rd_cap']), w = mm(a['rd_w']), d = mm(a['rd_d']);
    final gap = mm(a['rd_gap']), end = mm(a['rd_end']), apron = mm(a['rd_apron']), lane = mm(a['rd_lane']);
    final apronMin = mm(a['rd_apron_min']), laneMin = mm(a['rd_lane_min']), south = mm(a['rd_south'], min: 0, max: 2000);
    int? setback(String side) => a['${side}_setback'] == null ? 0 : mm(a['${side}_setback'], min: 0, max: 2000);
    final left = setback('left'), right = setback('right'), front = setback('front'), rear = setback('rear');
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || min == null || cap == null || w == null ||
        d == null || gap == null || end == null || apron == null || lane == null || apronMin == null || laneMin == null ||
        south == null || left == null || right == null || front == null || rear == null) {
      return stop('Enter valid plot dimensions, setbacks, whole bay counts and measured strip widths.');
    }
    if (cap < min) return stop('Raise the maximum bay count to at least the required minimum.');
    if (apron < apronMin) return stop('Increase the public apron depth to meet its submitted minimum.');
    if (lane < laneMin) return stop('Increase the rear collection aisle depth to meet its submitted minimum.');
    final depth = apron + d + lane;
    if (south < front || south + depth > pd - rear) return stop('The public apron, container row and collection aisle conflict with the front or rear plot limit.');
    final usable = pw - left - right, forRow = usable - 2 * end;
    final fit = forRow < w ? 0 : (forRow + gap) ~/ (w + gap);
    final n = math.min(fit, cap);
    if (n < min) return stop('Only $n container bays fit between the side setbacks and end reserves; $min required.');
    final width = 2 * end + n * w + (n - 1) * gap;
    final west = left + (usable - width) / 2, east = west + width;
    final yPublic = south + apron, yRear = yPublic + d, north = south + depth;
    final lines = <CadLine>[], labels = <CadLabel>[], bays = <RecyclingDropoffBay>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    void mark(String layer, num x, num y, String text, num size) => labels.add(CadLabel(layer, CadPoint(x, y), text, size));
    box('RD_PLOT', 0, 0, pw, pd);
    // Span the full envelope but avoid coincident lines along the container faces.
    for (final (layer, outer, inner) in [('RD_PUBLIC', south, yPublic), ('RD_COLLECT', north, yRear)]) {
      line(layer, west, inner, west, outer);
      line(layer, west, outer, east, outer);
      line(layer, east, outer, east, inner);
    }
    var previous = west;
    for (var i = 0; i < n; i++) {
      final x = west + end + i * (w + gap), ex = x + w;
      final id = 'B${(i + 1).toString().padLeft(2, '0')}';
      line('RD_PUBLIC', previous, yPublic, x, yPublic);
      line('RD_COLLECT', previous, yRear, x, yRear);
      box('RD_BAY', x, yPublic, ex, yRear);
      mark('RD_BAY', (x + ex) / 2, (yPublic + yRear) / 2, id, math.min(w * .22, d * .22));
      bays.add(RecyclingDropoffBay(id, x, yPublic, ex, yRear));
      previous = ex;
    }
    line('RD_PUBLIC', previous, yPublic, east, yPublic);
    line('RD_COLLECT', previous, yRear, east, yRear);
    line('RD_END', west, yPublic, west, yRear);
    line('RD_END', east, yPublic, east, yRear);
    final t = (math.max(pw, pd) / 95).clamp(20, 12000).toDouble();
    final cx = (west + east) / 2, nx = pw + 2.5 * t;
    mark('RD_PUBLIC', cx, (south + yPublic) / 2, 'PUBLIC APRON', math.min(apron * .3, width / 15));
    mark('RD_COLLECT', cx, (north + yRear) / 2, 'COLLECTION AISLE', math.min(lane * .3, width / 19));
    line('ANNOTATIONS', nx, pd - 2 * t, nx, pd);
    line('ANNOTATIONS', nx - .5 * t, pd - t, nx, pd);
    line('ANNOTATIONS', nx + .5 * t, pd - t, nx, pd);
    mark('ANNOTATIONS', nx, pd + t, 'N', .75 * t);
    mark('ANNOTATIONS', pw / 2, pd + 3.8 * t, 'MEASURED RECYCLING DROP-OFF / PLAN / LOCAL MM', t);
    mark('ANNOTATIONS', pw / 2, pd + 2.3 * t, '$n CONTAINER BAYS / ENVELOPE ${_m(width)} x ${_m(depth)} M', .65 * t);
    num minX = 0, maxX = nx, maxY = pd;
    for (final label in labels) {
      final half = label.height * label.text.length * .43;
      minX = math.min(minX, label.at.x - half);
      maxX = math.max(maxX, label.at.x + half);
      maxY = math.max(maxY, label.at.y + label.height);
    }
    final drawing = FloorPlanCad.fromEntities(bounds: PlanRect((minX - 2 * t).floor(), (-2 * t).floor(),
      (maxX + 2 * t).ceil(), (maxY + 2 * t).ceil()), lines: lines, labels: labels);
    return RecyclingDropoffCadResult(drawing: drawing, bays: List.unmodifiable(bays), widthMm: width,
      depthMm: depth, apronMm: apron, laneMm: lane);
  }
}
