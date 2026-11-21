import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/public_toilet_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class PublicToiletCadResult {
  const PublicToiletCadResult({this.drawing, this.issue, this.rooms = 0, this.widthMm = 0, this.depthMm = 0,
    this.galleryMm = 0, this.circleMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final int rooms, widthMm, depthMm, galleryMm, circleMm;
}

/// Static plan only. The specified clear circle and strip are not certification criteria.
class PublicToiletCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == 'public_toilet_measured_bank';

  PublicToiletCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    PublicToiletCadResult stop(String issue) => PublicToiletCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !publicToiletCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Public Toilet or Public Toilet Block and save the measured brief.');
    }
    final configs = sel.categoryId == 'infrastructure' ? const {null, 'support_facility', 'public_open_space'} : const {null, 'indoor', 'indoor_plus_outdoor'};
    if (!configs.contains(sel.configurationId) || !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        brief.floorCount != 1 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a single ground-floor block with a south gallery and no separate parking or Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = snap.answers;
    final rawCount = a['pt_rooms'];
    if (rawCount is! num || !rawCount.isFinite || rawCount < 1 || rawCount > 6 || rawCount != rawCount.toInt()) {
      return stop('Enter a whole room count from 1 to 6.');
    }
    final rooms = rawCount.toInt();
    int? mm(Object? v, {bool zero = false, int max = 50}) =>
        v is num && v.isFinite && v >= (zero ? 0 : .001) && v <= max ? (v * 1000).round() : null;
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final w = mm(a['pt_width']), d = mm(a['pt_depth']), wall = mm(a['pt_wall'], max: 2);
    final door = mm(a['pt_door']), gallery = mm(a['pt_gallery']), entry = mm(a['pt_entry']);
    final diameter = mm(a['pt_circle']), center = mm(a['pt_center']);
    final west = mm(a['pt_west'], zero: true, max: 2000), south = mm(a['pt_south'], zero: true, max: 2000);
    PlanRect? fixture(String id) {
      final x = mm(a['pt_${id}_x'], zero: true), y = mm(a['pt_${id}_y'], zero: true);
      final w = mm(a['pt_${id}_w']), d = mm(a['pt_${id}_d']);
      return x == null || y == null || w == null || d == null ? null : PlanRect(x, y, x + w, y + d);
    }
    final wc = fixture('wc'), basin = fixture('basin');
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || w == null || d == null || wall == null ||
        door == null || gallery == null || entry == null || diameter == null || center == null || west == null || south == null ||
        wc == null || basin == null) {
      return stop('Enter the measured plot, room, opening, gallery, manoeuvring reserve and fixture dimensions.');
    }
    if (door >= w || entry > door) return stop('Each opening must leave wall returns and be at least as wide as the clear entry strip.');
    final cx = w / 2, radius = diameter / 2;
    if (diameter > w || center < radius || center + radius > d) {
      return stop('The submitted manoeuvring circle does not fit within the clear room depth and width.');
    }
    final room = PlanRect(0, 0, w, d);
    if (!room.contains(wc) || !room.contains(basin)) return stop('The WC and basin envelopes must be inside the clear room.');
    if (wc.overlaps(basin)) return stop('The WC and basin envelopes overlap.');
    final entryL = cx - entry / 2, entryR = cx + entry / 2;
    for (final (name, r) in [('WC', wc), ('basin', basin)]) {
      if (entryL < r.right && entryR > r.left && center > r.bottom) {
        return stop('The $name envelope overlaps the clear strip from the doorway.');
      }
      final nearestX = cx.clamp(r.left, r.right), nearestY = center.clamp(r.bottom, r.top);
      final dx = cx - nearestX, dy = center - nearestY;
      if (dx * dx + dy * dy < radius * radius) return stop('The $name envelope intrudes into the submitted manoeuvring circle.');
    }
    final width = rooms * w + (rooms + 1) * wall, depth = gallery + d + 2 * wall;
    for (final (edge, clear) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, zero: true, max: 2000);
      if (min == null || clear < min) return stop('The block and gallery conflict with the $edge plot edge or supplied setback.');
    }

    final lines = <CadLine>[], arcs = <CadArc>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void box(String layer, num x, num y, num ex, num ey) {
      line(layer, x, y, ex, y);
      line(layer, ex, y, ex, ey);
      line(layer, ex, ey, x, ey);
      line(layer, x, ey, x, y);
    }
    box('WC_PLOT', 0, 0, pw, pd);
    final front = south + gallery, rear = south + depth, end = west + width, iy = front + wall;
    // The gallery shares its north edge with the block; no line across the actual openings.
    line('WC_GALLERY', west, front, west, south);
    line('WC_GALLERY', west, south, end, south);
    line('WC_GALLERY', end, south, end, front);
    line('WC_WALL', west, front, west, rear);
    line('WC_WALL', west, rear, end, rear);
    line('WC_WALL', end, rear, end, front);
    num prev = west;
    final t = (math.max(pw, pd) / 88).clamp(25, 6000).toDouble();
    for (var i = 0; i < rooms; i++) {
      final ix = west + wall + i * (w + wall);
      final dl = ix + cx - door / 2, dr = ix + cx + door / 2;
      line('WC_WALL', prev, front, dl, front);
      line('WC_WALL', dl, front, dl, iy);
      line('WC_WALL', dr, iy, dr, front);
      prev = dr;
      line('WC_WALL', ix, iy, dl, iy);
      line('WC_WALL', dr, iy, ix + w, iy);
      line('WC_WALL', ix, iy, ix, iy + d);
      line('WC_WALL', ix + w, iy, ix + w, iy + d);
      line('WC_WALL', ix, iy + d, ix + w, iy + d);
      line('WC_OPENING', dl, front + wall / 2, dr, front + wall / 2);
      box('WC_ROUTE', ix + entryL, front, ix + entryR, iy + center);
      final c = CadPoint(ix + cx, iy + center);
      arcs.addAll([CadArc('WC_CIRCLE', c, radius, 0, 180), CadArc('WC_CIRCLE', c, radius, 180, 360)]);
      for (final (name, r) in [('WC', wc), ('BASIN', basin)]) {
        box('WC_FIXTURE', ix + r.left, iy + r.bottom, ix + r.right, iy + r.top);
        labels.add(CadLabel('WC_FIXTURE', CadPoint(ix + (r.left + r.right) / 2, iy + (r.bottom + r.top) / 2), name,
          math.min(t * .74, math.min(r.width / (name.length + 1), r.depth / 3))));
      }
      labels.add(CadLabel('ANNOTATIONS', CadPoint(ix + cx, south + gallery / 2), 'ROOM ${i + 1}', math.min(t, math.min(w / 8, gallery / 3))));
    }
    line('WC_WALL', prev, front, end, front);
    final ax = pw + 2 * t;
    line('ANNOTATIONS', ax, pd - 2 * t, ax, pd);
    line('ANNOTATIONS', ax - t / 2, pd - t, ax, pd);
    line('ANNOTATIONS', ax + t / 2, pd - t, ax, pd);
    String m(int value) => (value / 1000).toStringAsFixed(3);
    labels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(ax, pd + t), 'N', t * .7),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 5.2 * t), 'MEASURED PUBLIC TOILET BANK / LOCAL MM', t),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 3.7 * t), '$rooms ROOM(S) / ${m(width)} x ${m(depth)} M INCLUDING GALLERY', t * .69),
      CadLabel('ANNOTATIONS', CadPoint(pw / 2, pd + 2.2 * t), 'CLEAR CIRCLE DIA ${m(diameter)} M / NO ACCESSIBILITY CERTIFICATION', t * .65),
    ]);
    final bounds = PlanRect(math.min(-2 * t, pw / 2 - 31 * t).floor(), (-2 * t).floor(),
      math.max(ax + 3 * t, pw / 2 + 31 * t).ceil(), (pd + 7 * t).ceil());
    return PublicToiletCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, arcs: arcs, labels: labels),
      rooms: rooms, widthMm: width, depthMm: depth, galleryMm: gallery, circleMm: diameter);
  }
}
