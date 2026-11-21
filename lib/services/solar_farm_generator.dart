import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/solar_farm_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class SolarFarmResult {
  const SolarFarmResult(this.drawing, this.issue, {this.tables = 0, this.modules = 0, this.peakKw = 0,
    this.projectedDepthMm = 0, this.riseMm = 0, this.shadowMm = 0, this.rowGapMm});
  final FloorPlanCad? drawing;
  final String? issue;
  final int tables, modules;
  final double peakKw, projectedDepthMm, riseMm, shadowMm;
  final double? rowGapMm;
}

/// Local north-up plan for identical, coplanar-baseline fixed-tilt tables.
class SolarFarmGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'solar_fixed_tilt';

  SolarFarmResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    SolarFarmResult stop(String issue) => SolarFarmResult(null, issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !solarFarmEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Energy / utilities / communications → Solar Farm and save the current brief.');
    }
    if (!const {null, 'outdoor_yard'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a new outdoor yard with no floors, parking or separate Space selections.');
    }
    if (!const {'square', 'rectangular'}.contains(sel.plotShapeId)) return stop('Use a rectangular or square plot aligned east–west and north–south.');
    final a = snap.answers;
    double? number(Object? value, double min, double max) =>
        value is num && value.isFinite && value >= min && value <= max ? value.toDouble() : null;
    double? n(String key, double min, double max) => number(a[key], min, max);
    int? count(String key, int max) {
      final v = a[key];
      return v is int && v >= 1 && v <= max ? v : null;
    }
    final widthM = number(widthFt * .3048, .001, 2000), depthM = number(depthFt * .3048, .001, 2000);
    final face = a['pv_face'];
    final rows = count('pv_rows', 80), tables = count('pv_tables', 80), cols = count('pv_cols', 40), stacks = count('pv_stacks', 12);
    final mx = n('pv_module_x', .001, 10), ms = n('pv_module_s', .001, 10), seam = n('pv_seam', 0, 1);
    final power = n('pv_watts', 1, 5000), tilt = n('pv_tilt', 1, 75), sun = n('pv_sun', 1, 89);
    final pitch = n('pv_pitch', .001, 2000), sideGap = n('pv_side_gap', 0, 2000), walk = n('pv_walk', 0, 2000);
    final margin = n('pv_perimeter', 0, 2000), west = n('pv_west', 0, 2000), first = n('pv_first', 0, 2000);
    if (widthM == null || depthM == null || (face != 'south' && face != 'north') || rows == null || tables == null ||
        cols == null || stacks == null || mx == null || ms == null || seam == null || power == null || tilt == null ||
        sun == null || pitch == null || sideGap == null || walk == null || margin == null || west == null || first == null) {
      return stop('Enter measured plot and array dimensions, table/module counts, tilt, nameplate power and a design sun profile angle.');
    }
    final width = (widthM * 1000).round(), depth = (depthM * 1000).round();
    if (sel.plotShapeId == 'square' && width != depth) return stop('The measured sides do not form a square.');
    final moduleCount = rows * tables * cols * stacks;
    if (moduleCount > 8000) return stop('Limit one drawing to 8,000 modules. Split larger arrays into blocks.');
    final south = face == 'south';
    final radians = tilt * math.pi / 180;
    final cosine = math.cos(radians);
    final tableW = (cols * mx + (cols - 1) * seam) * 1000;
    final chord = (stacks * ms + (stacks - 1) * seam) * 1000;
    final projectedDepth = chord * cosine, rise = chord * math.sin(radians);
    final shadow = rise / math.tan(sun * math.pi / 180);
    final gap = pitch * 1000 - projectedDepth;
    const eps = 1e-6;
    if (rows > 1 && (gap < -eps || gap < walk * 1000 - eps)) {
      return stop('Row pitch does not leave the supplied maintenance gap after projecting the tilted tables.');
    }
    if (rows > 1 && gap < shadow - eps) {
      return stop('Row pitch is too small at the supplied sun profile angle. Minimum pitch for shade clearance is ${((projectedDepth + shadow) / 1000).toStringAsFixed(3)} m.');
    }
    double? setback(String key) {
      final v = a[key];
      final m = v == null ? margin : n(key, 0, 2000);
      return m == null ? null : math.max(m, margin) * 1000;
    }
    // A solar plot always treats south as front and east as right.
    final sW = setback('left_setback'), sE = setback('right_setback'), sS = setback('front_setback'), sN = setback('rear_setback');
    if (sW == null || sE == null || sS == null || sN == null || sW + sE >= width || sS + sN >= depth) {
      return stop('The supplied perimeter clearances and setbacks leave no buildable rectangle.');
    }
    final x0 = west * 1000, a0 = first * 1000;
    final eastEdge = x0 + tables * tableW + (tables - 1) * sideGap * 1000;
    final rear = a0 + (rows - 1) * pitch * 1000 + projectedDepth;
    if (x0 < sW - eps || eastEdge > width - sE + eps ||
        a0 < (south ? sS : sN) - eps || rear > depth - (south ? sN : sS) + eps) {
      return stop('The measured array exceeds the buildable rectangle after perimeter clearances and setbacks.');
    }
    final exclusions = <String, (double, double, double, double)>{};
    final raw = a['pv_obstacles'];
    if (raw != null && raw is! String) return stop('Use ID,west offset,south offset,width,depth for exclusions.');
    if (raw is String && raw.trim().isNotEmpty) {
      if (raw.length > 6000) return stop('Use no more than 40 rectangular exclusions.');
      final points = raw.split(RegExp(r'[;\r\n]+')).where((s) => s.trim().isNotEmpty);
      for (final line in points) {
        if (exclusions.length == 40) return stop('Use no more than 40 rectangular exclusions.');
        final v = line.split(',').map((s) => s.trim()).toList();
        if (v.length != 5 || !RegExp(r'^[A-Za-z0-9_-]{1,24}$').hasMatch(v[0]) || exclusions.containsKey(v[0])) {
          return stop('Each exclusion needs a unique ID and four dimensions: west offset,south offset,width,depth.');
        }
        final data = v.skip(1).map((s) => RegExp(r'^[+]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$').hasMatch(s) ? double.tryParse(s) : null).toList();
        if (data.any((x) => x == null || !x.isFinite || x > 2000) || data[2]! <= 0 || data[3]! <= 0) {
          return stop('Exclusion ${v[0]} needs nonnegative offsets and positive dimensions in metres to three decimals.');
        }
        final x = data[0]! * 1000, y = data[1]! * 1000, r = x + data[2]! * 1000, t = y + data[3]! * 1000;
        if (r > width + eps || t > depth + eps) return stop('Exclusion ${v[0]} is outside the plot.');
        exclusions[v[0]] = (x, y, r, t);
      }
    }

    double y(double offset) => south ? offset : depth - offset;
    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num r, num t) => lines.add(CadLine(layer, CadPoint(x,y), CadPoint(r,t)));
    void box(String layer, num l, num b, num r, num t) {
      line(layer,l,b,r,b); line(layer,r,b,r,t); line(layer,r,t,l,t); line(layer,l,t,l,b);
    }
    box('PV_PLOT', 0, 0, width, depth);
    box('PV_BUILDABLE', sW, sS, width - sE, depth - sN);
    final text = (math.max(width, depth) / 72).clamp(80, 8000).toDouble();
    for (final item in exclusions.entries) {
      final (l, b, r, t) = item.value;
      box('PV_EXCLUSION', l, b, r, t);
      labels.add(CadLabel('PV_EXCLUSION', CadPoint((l+r)/2, (b+t)/2), item.key, text * .65));
    }
    for (var row = 0; row < rows; row++) {
      final low = a0 + row * pitch * 1000, high = low + projectedDepth;
      for (var table = 0; table < tables; table++) {
        final l = x0 + table * (tableW + sideGap * 1000), r = l + tableW;
        final b = math.min(y(low), y(high)), t = math.max(y(low), y(high));
        for (final item in exclusions.entries) {
          final (ol, ob, or, ot) = item.value;
          if (l < or - eps && r > ol + eps && b < ot - eps && t > ob + eps) {
            return stop('Row ${row+1}, table ${table+1} overlaps exclusion ${item.key}.');
          }
        }
        for (var s = 0; s < stacks; s++) {
          final a = low + s * (ms + seam) * 1000 * cosine;
          for (var c = 0; c < cols; c++) {
            final x = l + c * (mx + seam) * 1000;
            box('PV_MODULE', x, y(a), x + mx * 1000, y(a + ms * 1000 * cosine));
          }
        }
        box('PV_TABLE', l, b, r, t);
        line('PV_LOW_EDGE', l, y(low), r, y(low));
        if (row < rows - 1) line('PV_SHADOW_LIMIT', l, y(high + shadow), r, y(high + shadow));
      }
    }
    final peak = moduleCount * power / 1000;
    final arrowX = width + text * 2, arrowTop = depth;
    line('ANNOTATIONS', arrowX, arrowTop - text * 2, arrowX, arrowTop);
    line('ANNOTATIONS', arrowX - text * .4, arrowTop - text * .75, arrowX, arrowTop);
    line('ANNOTATIONS', arrowX + text * .4, arrowTop - text * .75, arrowX, arrowTop);
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(arrowX, arrowTop + text), 'N', text * .75),
      CadLabel('ANNOTATIONS', CadPoint(width / 2, depth + text * 5), 'FIXED-TILT PV ARRAY / CONCEPT ONLY', text),
      CadLabel('ANNOTATIONS', CadPoint(width / 2, depth + text * 3.5),
        '$moduleCount MODULES / ${peak.toStringAsFixed(3)} KWP DC / ${face.toString().toUpperCase()}-FACING', text * .7),
      CadLabel('ANNOTATIONS', CadPoint(width / 2, depth + text * 2.1),
        'SUN PROFILE ANGLE $sun DEG / TILT $tilt DEG / LOCAL MM', text * .7),
    ]);
    final bounds = PlanRect(math.min(-text * 2, width / 2 - text * 22).floor(), (-text * 2).floor(),
      math.max(width + text * 4, width / 2 + text * 22).ceil(), (depth + text * 6.5).ceil());
    return SolarFarmResult(FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels), null,
      tables: rows * tables, modules: moduleCount, peakKw: peak, projectedDepthMm: projectedDepth,
      riseMm: rise, shadowMm: shadow, rowGapMm: rows > 1 ? gap : null);
  }
}
