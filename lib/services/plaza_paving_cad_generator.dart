import 'dart:math' as math;

import '../data/plaza_paving_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class PavingPieceType {
  const PavingPieceType(this.widthMm, this.depthMm, this.count, this.cut);
  final int widthMm, depthMm, count;
  final bool cut;
  int get areaMm2 => widthMm * depthMm * count;
}

class PlazaPavingCadResult {
  const PlazaPavingCadResult({this.drawing, this.issue, this.pieceTypes = const [], this.columns = 0, this.rows = 0,
    this.grossMm2 = 0, this.pieceMm2 = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<PavingPieceType> pieceTypes;
  final int columns, rows, grossMm2, pieceMm2;
  int get fullCount => pieceTypes.where((p) => !p.cut).fold(0, (sum, p) => sum + p.count);
  int get cutCount => columns * rows - fullCount;
  double get grossM2 => grossMm2 / 1e6;
  double get jointM2 => (grossMm2 - pieceMm2) / 1e6;

  String? toCsv() => drawing == null ? null : [
    'piece_kind,installed_width_m,installed_depth_m,count,installed_area_m2',
    for (final p in pieceTypes)
      '${p.cut ? 'cut' : 'full'},${_m(p.widthMm)},${_m(p.depthMm)},${p.count},${(p.areaMm2 / 1e6).toStringAsFixed(6)}',
    '',
  ].join('\r\n');
}

class PlazaPavingCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == plazaPavingMode;

  /// Straight bond with a full-field fit or two nearly equal border widths.
  /// A one-millimetre remainder goes to the positive end of the axis.
  static List<int>? _axis(int span, int unit, int joint, int minimum) {
    final n = (span + joint) ~/ (unit + joint);
    if (n > 0 && n * unit + (n - 1) * joint == span) return List.filled(n, unit);
    // With k full internal pieces, k+1 joints and two border pieces are needed.
    // Select the largest k that could leave two minimum-width cuts.
    final free = span - joint - 2 * minimum;
    if (free < 0) return null;
    final k = free ~/ (unit + joint);
    final remaining = span - k * unit - (k + 1) * joint;
    final first = remaining ~/ 2, last = remaining - first;
    if (last > unit) return null; // Fewer full pieces would only make the borders larger.
    return [first, ...List<int>.filled(k, unit), last];
  }

  PlazaPavingCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    PlazaPavingCadResult stop(String issue) => PlazaPavingCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !plazaPavingCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Urban Plaza and save the current measured paving brief.');
    }
    final config = sel.categoryId == 'institutional' ? 'outdoor' : 'public_open_space';
    if (!{null, config}.contains(sel.configurationId) || !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor plaza without enclosed floors, separate parking or Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    int? mm(Object? v, {num min = .001, num max = 120}) =>
        v is num && v.isFinite && v >= min && v <= max ? (v * 1000).round() : null;
    final a = req.answers;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final width = mm(a['pav_w']), depth = mm(a['pav_l']);
    final west = mm(a['pav_west'], min: 0, max: 2000), south = mm(a['pav_south'], min: 0, max: 2000);
    final unitX = mm(a['pav_unit_x'], min: .05, max: 5), unitY = mm(a['pav_unit_y'], min: .05, max: 5);
    final joint = mm(a['pav_joint'], max: .1), minX = mm(a['pav_min_x'], max: 5), minY = mm(a['pav_min_y'], max: 5);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || width == null || depth == null || west == null ||
        south == null || unitX == null || unitY == null || joint == null || minX == null || minY == null) {
      return stop('Enter measured plot, paving rectangle, piece, joint and minimum cut dimensions.');
    }
    if (minX > unitX || minY > unitY) return stop('Minimum installed piece sizes cannot exceed the corresponding full piece dimensions.');
    if (joint >= math.min(unitX, unitY)) return stop('The joint must be narrower than both full piece dimensions.');
    for (final (edge, remaining) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, min: 0, max: 2000);
      if (min == null || remaining < min) return stop('The paving rectangle conflicts with the $edge plot edge or supplied setback.');
    }
    final xs = _axis(width, unitX, joint, minX), ys = _axis(depth, unitY, joint, minY);
    if (xs == null) return stop('No centred west–east layout meets the submitted minimum border width. Adjust the paving width, piece width or joint.');
    if (ys == null) return stop('No centred south–north layout meets the submitted minimum border depth. Adjust the paving depth, piece depth or joint.');
    if (xs.length * ys.length > 2500) return stop('The layout exceeds 2,500 pieces. Use a smaller paving rectangle or a larger piece size.');
    final lines = <CadLine>[], labels = <CadLabel>[];
    void box(String layer, int x, int y, int ex, int ey) {
      final a = CadPoint(x, y), b = CadPoint(ex, y), c = CadPoint(ex, ey), d = CadPoint(x, ey);
      lines.addAll([CadLine(layer, a, b), CadLine(layer, b, c), CadLine(layer, c, d), CadLine(layer, d, a)]);
    }
    box('PAV_PLOT', 0, 0, pw, pd);
    final counts = <(int, int), int>{};
    var x = west, pieceArea = 0;
    for (final w in xs) {
      var y = south;
      for (final d in ys) {
        box(w == unitX && d == unitY ? 'PAV_FULL' : 'PAV_CUT', x, y, x + w, y + d);
        counts.update((w, d), (v) => v + 1, ifAbsent: () => 1);
        pieceArea += w * d;
        y += d + joint;
      }
      x += w + joint;
    }
    final types = counts.entries.map((entry) {
      final (w, d) = entry.key;
      return PavingPieceType(w, d, entry.value, w != unitX || d != unitY);
    }).toList()..sort((a, b) {
      if (a.cut != b.cut) return a.cut ? 1 : -1;
      final byWidth = a.widthMm.compareTo(b.widthMm);
      return byWidth != 0 ? byWidth : a.depthMm.compareTo(b.depthMm);
    });
    final gross = width * depth;
    final t = (math.max(pw, pd) / 90).clamp(20, 7500).toDouble(), nx = pw + 2 * t;
    final tip = CadPoint(nx, pd);
    lines.addAll([CadLine('ANNOTATIONS', CadPoint(nx, pd - 2 * t), tip),
      CadLine('ANNOTATIONS', CadPoint(nx - t / 2, pd - t), tip), CadLine('ANNOTATIONS', CadPoint(nx + t / 2, pd - t), tip)]);
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(nx, pd + t), 'N', .65 * t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 5.5 * t), 'MEASURED URBAN PLAZA PAVING / LOCAL MM', t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 4.2 * t), 'GRID ${xs.length} x ${ys.length} / ${_m(width)} x ${_m(depth)} M / JOINT ${_m(joint)} M', .66 * t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 2.9 * t), 'GROSS ${(gross / 1e6).toStringAsFixed(3)} M2 / JOINTS ${((gross - pieceArea) / 1e6).toStringAsFixed(3)} M2', .64 * t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 1.6 * t), 'INSTALLED PIECES ONLY / NO PURCHASE, WASTE OR INSTALLATION ALLOWANCE', .6 * t),
    ]);
    return PlazaPavingCadResult(drawing: FloorPlanCad.fromEntities(
      bounds: PlanRect(math.min(-2 * t, pw / 2 - 43 * t).floor(), (-2 * t).floor(),
        math.max(nx + 3 * t, pw / 2 + 43 * t).ceil(), (pd + 7 * t).ceil()), lines: lines, labels: labels),
      columns: xs.length, rows: ys.length, grossMm2: gross, pieceMm2: pieceArea, pieceTypes: List.unmodifiable(types));
  }
}
