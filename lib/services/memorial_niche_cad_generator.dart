import 'dart:math' as math;

import '../data/memorial_niche_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class MemorialNicheCadResult {
  const MemorialNicheCadResult({this.plan, this.elevation, this.issue, this.capacity = 0,
    this.panelWidthMm = 0, this.panelDepthMm = 0, this.panelHeightMm = 0, this.bankWidthMm = 0, this.bankDepthMm = 0});

  final FloorPlanCad? plan, elevation;
  final String? issue;
  final int capacity, panelWidthMm, panelDepthMm, panelHeightMm, bankWidthMm, bankDepthMm;
}

/// Nominal rectangular niche grid. Both faces, when present, have identical geometry.
class MemorialNicheCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == 'memorial_niche_walls';

  MemorialNicheCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    MemorialNicheCadResult stop(String message) => MemorialNicheCadResult(issue: message);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !memorialNicheCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Cemetery/Memorial Landscape and save the measured niche wall brief.');
    }
    if (!const {null, 'public_open_space', 'support_facility'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use freestanding outdoor panels without building floors, parking or separate Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) {
      return stop('Use a cardinally aligned rectangular or square plot.');
    }
    final a = snap.answers;
    int? mm(Object? v, {bool zero = false, int max = 50}) =>
        v is num && v.isFinite && v >= (zero ? 0 : .001) && v <= max ? (v * 1000).round() : null;
    int? whole(String id, int min, int max) {
      final v = a[id];
      return v is num && v.isFinite && v >= min && v <= max && v == v.toInt() ? v.toInt() : null;
    }
    final panels = whole('mn_panels', 1, 6), columns = whole('mn_columns', 1, 20), tiers = whole('mn_tiers', 1, 8);
    final target = whole('mn_target', 0, 1920);
    final faces = switch (a['mn_faces']) {'1' => 1, '2' => 2, _ => null};
    if (panels == null || columns == null || tiers == null || faces == null || target == null) {
      return stop('Enter valid whole panel, column, tier and target counts and select one or two niche faces.');
    }
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final w = mm(a['mn_width'], max: 5), h = mm(a['mn_height'], max: 5), d = mm(a['mn_depth'], max: 5);
    final web = mm(a['mn_web'], max: 2), frame = mm(a['mn_frame'], max: 2), core = mm(a['mn_core'], max: 5);
    final plinth = mm(a['mn_plinth'], zero: true, max: 5), gap = mm(a['mn_gap'], zero: true);
    final ends = mm(a['mn_ends']), southStrip = mm(a['mn_south_strip']), northStrip = mm(a['mn_north_strip']);
    final west = mm(a['mn_west'], zero: true, max: 2000), south = mm(a['mn_south'], zero: true, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || w == null || h == null || d == null ||
        web == null || frame == null || core == null || plinth == null || gap == null || ends == null ||
        southStrip == null || northStrip == null || west == null || south == null) {
      return stop('Enter measured plot, niche, frame, reserve and offset dimensions.');
    }
    if (panels > 1 && gap == 0) return stop('Enter a positive gap between separate wall panels.');
    if (panels == 1 && gap != 0) return stop('Use a zero panel gap for a single wall panel.');

    final panelW = 2 * frame + columns * w + (columns - 1) * web;
    final panelH = plinth + 2 * frame + tiers * h + (tiers - 1) * web;
    final panelD = core + faces * d;
    final bankW = 2 * ends + panels * panelW + (panels - 1) * gap;
    final bankD = southStrip + panelD + northStrip;
    final rawHeight = a['max_height'];
    if (rawHeight != null) {
      final limit = mm(rawHeight, max: 2000);
      if (limit == null || panelH > limit) return stop('The panel top exceeds the supplied height limit, or the limit is invalid.');
    }
    for (final (edge, clear) in [('left', west), ('right', pw - west - bankW), ('front', south), ('rear', pd - south - bankD)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, zero: true, max: 2000);
      if (min == null || clear < min) return stop('The wall layout and reserves conflict with the $edge plot edge or supplied setback.');
    }
    final capacity = panels * faces * columns * tiers;
    if (capacity < target) return stop('The wall grid has $capacity nominal niches, below the supplied target of $target.');

    final p = _MemorialSheet(), e = _MemorialSheet();
    p.box('NICHE_PLOT', 0, 0, pw, pd);
    p.box('NICHE_LIMIT', west, south, west + bankW, south + bankD);
    final wallSouth = south + southStrip, wallNorth = wallSouth + panelD;
    final bankEast = west + bankW, bankNorth = south + bankD;
    // Strips run across the bank; end reserves connect the active faces.
    p.box('NICHE_VIEW', west, south, bankEast, wallSouth);
    p.box(faces == 2 ? 'NICHE_VIEW' : 'NICHE_REAR', west, wallNorth, bankEast, bankNorth);
    p.box('NICHE_VIEW', west, wallSouth, west + ends, wallNorth);
    p.box('NICHE_VIEW', bankEast - ends, wallSouth, bankEast, wallNorth);
    final text = (math.max(pw, pd) / 94).clamp(25, 6500).toDouble();
    for (var j = 0; j < panels; j++) {
      final x = west + ends + j * (panelW + gap);
      p.box('NICHE_WALL', x, wallSouth, x + panelW, wallNorth);
      for (var i = 0; i < columns; i++) {
        final x1 = x + frame + i * (w + web);
        p.pocket(x1, x1 + w, wallSouth, wallSouth + d);
        if (faces == 2) p.pocket(x1, x1 + w, wallNorth, wallNorth - d);
      }
      p.label('ANNOTATIONS', x + panelW / 2, south + southStrip / 2, 'W${j + 1}',
        math.min(text, math.min(panelW / 4, southStrip / 4)));
    }
    final ax = pw + 2 * text;
    p.line('ANNOTATIONS', ax, pd - 2 * text, ax, pd);
    p.line('ANNOTATIONS', ax - text / 2, pd - text, ax, pd);
    p.line('ANNOTATIONS', ax + text / 2, pd - text, ax, pd);
    p.label('ANNOTATIONS', ax, pd + text, 'N', text * .7);
    String m(int v) => (v / 1000).toStringAsFixed(3);
    p.heading(pw, pd, text, [
      'MEMORIAL NICHE WALLS / SITE PLAN / LOCAL MM',
      '$panels PANEL(S) / $faces FACE(S) PER PANEL / $capacity NOMINAL NICHES',
      'LAYOUT ${m(bankW)} x ${m(bankD)} M / POCKETS SHOWN IN PROJECTION',
      'SOUTH VIEWING STRIP / ${faces == 2 ? 'NORTH VIEWING STRIP' : 'NORTH REAR RESERVE'}',
    ]);
    e.box('NICHE_WALL', 0, 0, panelW, panelH);
    if (plinth > 0) e.line('NICHE_PLINTH', 0, plinth, panelW, plinth);
    for (var row = 0; row < tiers; row++) {
      for (var col = 0; col < columns; col++) {
        final x = frame + col * (w + web), z = plinth + frame + row * (h + web);
        e.box('NICHE_OPENING', x, z, x + w, z + h);
      }
    }
    final et = (math.max(panelW, panelH) / 57).clamp(15, 4000).toDouble();
    e.heading(panelW, panelH, et, [
      'TYPICAL PANEL ELEVATION / TRUE SCALE MM',
      '$columns COLUMNS x $tiers TIERS PER FACE / ${faces == 2 ? 'BOTH FACES IDENTICAL' : 'SOUTH FACE ONLY'}',
      'CLEAR OPENING ${m(w)} x ${m(h)} M / DEPTH ${m(d)} M',
      'PANEL TOP ${m(panelH)} M ABOVE GRADE DATUM 0 / NO FOUNDATION DETAIL',
    ]);
    return MemorialNicheCadResult(plan: p.drawing(pw, pd, text, rightMargin: 5), elevation: e.drawing(panelW, panelH, et),
      capacity: capacity, panelWidthMm: panelW, panelDepthMm: panelD, panelHeightMm: panelH, bankWidthMm: bankW, bankDepthMm: bankD);
  }
}

class _MemorialSheet {
  final lines = <CadLine>[], labels = <CadLabel>[];

  void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
  void box(String layer, num x, num y, num ex, num ey) {
    line(layer, x, y, ex, y);
    line(layer, ex, y, ex, ey);
    line(layer, ex, ey, x, ey);
    line(layer, x, ey, x, y);
  }

  void pocket(int left, int right, int face, int back) {
    line('NICHE_POCKET', left, face, left, back);
    line('NICHE_POCKET', left, back, right, back);
    line('NICHE_POCKET', right, back, right, face);
  }

  void label(String layer, num x, num y, String value, num size) => labels.add(CadLabel(layer, CadPoint(x, y), value, size));
  void heading(int width, int height, double t, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      label('ANNOTATIONS', width / 2, height + t * (5.7 - 1.4 * i), rows[i], i == 0 ? t : t * .66);
    }
  }

  FloorPlanCad drawing(int w, int h, double t, {int rightMargin = 2}) => FloorPlanCad.fromEntities(
    bounds: PlanRect(math.min(-2 * t, w / 2 - 29 * t).floor(), (-2 * t).floor(),
      math.max(w + rightMargin * t, w / 2 + 29 * t).ceil(), (h + 7.4 * t).ceil()), lines: lines, labels: labels);
}
