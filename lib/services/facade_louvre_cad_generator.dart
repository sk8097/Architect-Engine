import 'dart:math' as math;

import '../data/facade_louvre_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

String _m(num mm) => (mm / 1000).toStringAsFixed(3);

class FacadeLouvreCadResult {
  const FacadeLouvreCadResult({this.elevation, this.section, this.issue, this.count = 0, this.spanMm = 0,
    this.clearMm = 0, this.headMm = 0, this.lowerOpen = 0, this.upperShade = 0, this.cutoffDeg = 0});
  final FloorPlanCad? elevation, section;
  final String? issue;
  final int count, spanMm, clearMm, headMm;
  final double lowerOpen, upperShade, cutoffDeg;
}

/// Profiles direct rays in a central section, considering only complete inter-blade gaps.
class FacadeLouvreCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == facadeLouvreMode;

  FacadeLouvreCadResult generate(ProjectBrief brief) {
    FacadeLouvreCadResult stop(String issue) => FacadeLouvreCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (!requested(brief) || sel == null || req == null || sel.version != projectTaxonomyVersion ||
        req.version != requirementsSchemaVersion || !facadeLouvreCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Small Office, Corporate Office or Branch Office and save the current louvre brief.');
    }
    if (!const {null, 'new_design', 'concept_design', 'feasibility', 'renovation'}.contains(sel.actionId)) {
      return stop('Use an early design or renovation action for this façade study.');
    }
    if (sel.spaceQuantities.isNotEmpty) return stop('Use one façade bay only. Remove separate Space selections.');
    final a = req.answers;
    double? scalar(Object? v, {num min = .001, num max = 30}) =>
        v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    int? mm(Object? v, {num min = .001, num max = 30}) {
      final value = scalar(v, min: min, max: max);
      return value == null ? null : (value * 1000).round();
    }
    final w = mm(a['fl_width']), h = mm(a['fl_height']);
    final side = mm(a['fl_side'], min: 0), sill = mm(a['fl_sill'], min: 0), head = mm(a['fl_head'], min: 0);
    final pitch = mm(a['fl_pitch']), thickness = mm(a['fl_thickness'], max: 5), projection = mm(a['fl_projection'], max: 10);
    final low = scalar(a['fl_low'], min: 0, max: 89.9), high = scalar(a['fl_high'], max: 89.9);
    final minOpen = scalar(a['fl_min_open'], max: 100), minShade = scalar(a['fl_min_shade'], max: 100);
    if (w == null || h == null || side == null || sill == null || head == null || pitch == null || thickness == null ||
        projection == null || low == null || high == null || minOpen == null || minShade == null) {
      return stop('Enter valid bay, blade, profile angle and percentage dimensions.');
    }
    if (low >= high) return stop('The higher profile angle must exceed the lower profile angle.');
    final span = w - 2 * side, gap = pitch - thickness, stack = h - sill - head;
    if (span <= 0) return stop('The two side margins leave no blade span.');
    if (gap <= 0) return stop('Blade thickness must be smaller than pitch to leave a clear gap.');
    if (stack < pitch + thickness) return stop('At least two blades must fit between the sill and head reserves.');
    final count = 1 + (stack - thickness) ~/ pitch;
    if (count > 60) return stop('This one-bay sheet supports at most 60 blades. Increase the pitch or reduce the measured bay height.');
    final headLeft = h - sill - (count - 1) * pitch - thickness;

    // Trace a ray from the upper outer underside toward the wall. It can shade
    // the entire gap but cannot create negative daylight opening at the wall.
    double tangent(double angle) => math.tan(angle * math.pi / 180);
    double shade(double angle) => (projection * tangent(angle) / gap).clamp(0.0, 1.0).toDouble();
    final open = 100 * (1 - shade(low)), shaded = 100 * shade(high);
    final cutoff = math.atan(gap / projection) * 180 / math.pi;
    if (open + 1e-9 < minOpen) return stop('The lower profile angle leaves less than the submitted directly lit fraction.');
    if (shaded + 1e-9 < minShade) return stop('The higher profile angle shades less than the submitted shaded fraction.');

    final elevation = _Sheet(), section = _Sheet();
    final t = (math.max(w, h) / 95).clamp(20, 12000).toDouble();
    // At zero margins, draw the shared jamb/blade segments only once as jambs.
    elevation.box('FL_BAY', 0, 0, w, h);
    section.line('FL_BAY', 0, 0, 0, h);
    for (var i = 0; i < count; i++) {
      final bottom = sill + i * pitch, top = bottom + thickness;
      if (bottom != 0) elevation.line('FL_BLADE', side, bottom, w - side, bottom);
      if (top != h) elevation.line('FL_BLADE', side, top, w - side, top);
      if (side > 0) {
        elevation.line('FL_BLADE', side, bottom, side, top);
        elevation.line('FL_BLADE', w - side, bottom, w - side, top);
      }
      section.line('FL_BLADE', 0, bottom, projection, bottom);
      section.line('FL_BLADE', projection, bottom, projection, top);
      section.line('FL_BLADE', projection, top, 0, top);
    }
    elevation.line('FL_CUT', w / 2, 0, w / 2, h);
    elevation.mark('FL_CUT', w / 2, -t, 'A', .65 * t);
    elevation.mark('FL_CUT', w / 2, h + t, 'A', .65 * t);
    elevation.heading(w / 2, h, t, [
      'MEASURED FACADE LOUVRE / EXTERIOR ELEVATION / LOCAL MM',
      '$count BLADES / ${_m(span)} M SPAN / ${_m(gap)} M CLEAR GAP / ${_m(headLeft)} M TOP RESERVE',
    ]);
    final upper = sill + pitch, lower = sill + thickness;
    for (final (layer, angle) in [('FL_LOW', low), ('FL_HIGH', high)]) {
      if (angle == 0) continue; // A horizontal grazing ray coincides with the underside.
      final slope = tangent(angle);
      // Stop at the lower blade if the ray hits it before reaching the facade.
      section.line(layer, projection, upper, math.max(0.0, projection - gap / slope), math.max(lower, upper - projection * slope));
    }
    final st = (math.max(h, projection) / 95).clamp(20, 12000).toDouble();
    section.heading(projection / 2, h, st, [
      'TRUE-SCALE A-A / FACADE X = 0 / OUTWARD TO RIGHT / MM',
      'LOW ${low.toStringAsFixed(3)} DEG: ${open.toStringAsFixed(3)}% DIRECTLY LIT / HIGH ${high.toStringAsFixed(3)} DEG: ${shaded.toStringAsFixed(3)}% SHADED',
      'FULL CUT-OFF ${cutoff.toStringAsFixed(3)} DEG / COMPLETE GAPS ONLY',
    ]);
    return FacadeLouvreCadResult(elevation: elevation.drawing(t), section: section.drawing(st), count: count, spanMm: span,
      clearMm: gap, headMm: headLeft, lowerOpen: open, upperShade: shaded, cutoffDeg: cutoff);
  }
}
class _Sheet {
  final lines = <CadLine>[], labels = <CadLabel>[];
  void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
  void box(String layer, num x, num y, num ex, num ey) {
    line(layer, x, y, ex, y);
    line(layer, ex, y, ex, ey);
    line(layer, ex, ey, x, ey);
    line(layer, x, ey, x, y);
  }
  void mark(String layer, num x, num y, String text, num height) => labels.add(CadLabel(layer, CadPoint(x, y), text, height));
  void heading(num x, num y, double t, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      labels.add(CadLabel('ANNOTATIONS', CadPoint(x, y + (rows.length - i + .5) * 1.3 * t), rows[i], i == 0 ? t : .62 * t));
    }
  }
  FloorPlanCad drawing(double t) {
    final pts = [for (final l in lines) ...[l.start, l.end], for (final l in labels) ...[
      CadPoint(l.at.x - l.height * l.text.length * .42, l.at.y - l.height),
      CadPoint(l.at.x + l.height * l.text.length * .42, l.at.y + l.height),
    ]];
    return FloorPlanCad.fromEntities(bounds: PlanRect((pts.map((p) => p.x).reduce(math.min) - 3 * t).floor(),
      (pts.map((p) => p.y).reduce(math.min) - 3 * t).floor(), (pts.map((p) => p.x).reduce(math.max) + 3 * t).ceil(),
      (pts.map((p) => p.y).reduce(math.max) + 3 * t).ceil()), lines: lines, labels: labels);
  }
}
