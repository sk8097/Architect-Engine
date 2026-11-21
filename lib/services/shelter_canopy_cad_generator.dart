import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/shelter_canopy_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class ShelterCanopyCadResult {
  const ShelterCanopyCadResult({this.plan, this.section, this.issue, this.posts = 0, this.widthMm = 0, this.depthMm = 0,
    this.walkMm = 0, this.walkHeadMm = 0, this.eaveMm = 0, this.fallPct = 0, this.roofM2 = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int posts, widthMm, depthMm, walkMm, eaveMm;
  final double walkHeadMm, fallPct, roofM2;
}

/// A single geometric roof plane above level grade; no structural design.
class ShelterCanopyCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == 'shelter_measured_canopy';

  ShelterCanopyCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    ShelterCanopyCadResult stop(String issue) => ShelterCanopyCadResult(issue: issue);
    final sel = brief.taxonomy, req = brief.requirements;
    if (sel == null || req == null || sel.version != projectTaxonomyVersion || req.version != requirementsSchemaVersion ||
        !shelterCanopyCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Passenger Shelter and save the current measured canopy brief.');
    }
    if (!const {null, 'outdoor', 'indoor_plus_outdoor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one open-sided shelter without enclosed floors, parking or separate Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId)) return stop('Use a cardinally aligned rectangular or square plot.');
    final a = req.answers, rawBays = req.answers['sh_bays'];
    if (rawBays is! num || !rawBays.isFinite || rawBays < 1 || rawBays > 8 || rawBays != rawBays.toInt()) {
      return stop('Enter a whole number of post bays from 1 to 8.');
    }
    int? mm(Object? v, {bool zero = false, int max = 50}) =>
        v is num && v.isFinite && v >= (zero ? 0 : .001) && v <= max ? (v * 1000).round() : null;
    final bays = rawBays.toInt();
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final pitch = mm(a['sh_pitch']), span = mm(a['sh_span']), post = mm(a['sh_post'], max: 5);
    final wProj = mm(a['sh_oh_w']), eProj = mm(a['sh_oh_e']), end = mm(a['sh_oh_end']);
    final westZ = mm(a['sh_w_z']), eastZ = mm(a['sh_e_z']), roofD = mm(a['sh_roof_d'], max: 5);
    final needWalk = mm(a['sh_min_walk']), needHead = mm(a['sh_min_head']), needEave = mm(a['sh_min_eave']);
    final west = mm(a['sh_west'], zero: true, max: 2000), south = mm(a['sh_south'], zero: true, max: 2000);
    if (pw == null || pd == null || (sel.plotShapeId == 'square' && pw != pd) || pitch == null || span == null || post == null ||
        wProj == null || eProj == null || end == null || westZ == null || eastZ == null || roofD == null ||
        needWalk == null || needHead == null || needEave == null || west == null || south == null) {
      return stop('Enter measured plot, canopy grid, roof and clearance dimensions.');
    }
    if (pitch <= post) return stop('Post spacing along the rows must exceed the post envelope width.');
    if (2 * wProj < post || 2 * eProj < post || 2 * end < post) {
      return stop('Roof projections from the post centres must cover the full outer post footprints.');
    }
    final walk = span - post;
    if (walk < needWalk) return stop('The clear walking width between inner post faces is below the submitted minimum.');
    if (westZ <= eastZ) return stop('For eastward fall, the west soffit must be higher than the east soffit.');
    if (eastZ < needEave) return stop('Headroom at the low east eave is below the submitted minimum.');
    final rawLimit = a['max_height'];
    if (rawLimit != null) {
      final limit = mm(rawLimit, max: 2000);
      if (limit == null || westZ + roofD > limit) return stop('The high roof top exceeds the supplied height limit, or the limit is invalid.');
    }
    final width = wProj + span + eProj, depth = 2 * end + bays * pitch;
    final half = post / 2;
    final xWalkW = wProj + half, xWalkE = wProj + span - half;
    final fall = westZ - eastZ;
    // The plane falls linearly eastward; the east edge of the walking strip governs.
    double underside(num x) => westZ.toDouble() - fall * x / width;
    final head = underside(xWalkE);
    if (head < needHead - 1e-8) return stop('Headroom at the east edge of the clear walking strip is below the submitted minimum.');
    for (final (edge, remaining) in [('left', west), ('right', pw - west - width), ('front', south), ('rear', pd - south - depth)]) {
      final raw = a['${edge}_setback'];
      final min = raw == null ? 0 : mm(raw, zero: true, max: 2000);
      if (min == null || remaining < min) return stop('The full roof projection conflicts with the $edge plot edge or supplied setback.');
    }
    final count = 2 * (bays + 1), slope = 100 * fall / width;
    final roofArea = math.sqrt(width * width + fall * fall) * depth / 1e6;
    final plan = _CanopySheet(), section = _CanopySheet();
    plan.box('CANOPY_PLOT', 0, 0, pw, pd);
    plan.box('CANOPY_ROOF', west, south, west + width, south + depth);
    plan.box('CANOPY_WALK', west + xWalkW, south, west + xWalkE, south + depth);
    for (var i = 0; i <= bays; i++) {
      final y = south + end + i * pitch;
      for (final rowX in [wProj, wProj + span]) {
        final x = west + rowX;
        plan.box('CANOPY_POST', x - half, y - half, x + half, y + half);
      }
    }
    final t = (math.max(pw, pd) / 88).clamp(25, 6000).toDouble(), ax = pw + 2 * t;
    plan.line('ANNOTATIONS', ax, pd - 2 * t, ax, pd);
    plan.line('ANNOTATIONS', ax - t / 2, pd - t, ax, pd);
    plan.line('ANNOTATIONS', ax + t / 2, pd - t, ax, pd);
    plan.label(ax, pd + t, 'N', t * .7);
    String m(num value) => (value / 1000).toStringAsFixed(3);
    plan.heading(pw, pd, t, [
      'MEASURED PASSENGER SHELTER / ROOF PLAN / LOCAL MM',
      'ROOF ${m(width)} x ${m(depth)} M / $count POST ENVELOPES / CLEAR WALK ${m(walk)} M',
      'ONE ROOF PLANE / EASTWARD FALL ${slope.toStringAsFixed(3)}% / NO STRUCTURE DESIGN',
    ]);

    section.line('CANOPY_GRADE', 0, 0, width, 0);
    section.line('CANOPY_ROOF', 0, westZ, width, eastZ);
    section.line('CANOPY_ROOF', 0, westZ + roofD, width, eastZ + roofD);
    section.line('CANOPY_ROOF', 0, westZ, 0, westZ + roofD);
    section.line('CANOPY_ROOF', width, eastZ, width, eastZ + roofD);
    for (final x in [wProj, wProj + span]) {
      final l = x - half, r = x + half;
      section.line('CANOPY_POST', l, 0, l, underside(l));
      section.line('CANOPY_POST', r, 0, r, underside(r));
    }
    section.line('CANOPY_WALK', xWalkW, needHead, xWalkE, needHead);
    final top = westZ + roofD, st = (math.max(width, top) / 55).clamp(18, 4500).toDouble();
    section.heading(width, top, st, [
      'TYPICAL TRANSVERSE SECTION THROUGH POSTS / TRUE SCALE MM',
      'LOW EAVE ${m(eastZ)} M / MIN WALK HEADROOM ${m(head)} M / GRADE DATUM 0',
      'GREEN LINE = SUBMITTED HEADROOM MINIMUM / NO CONNECTIONS OR FOOTINGS',
    ]);
    return ShelterCanopyCadResult(plan: plan.drawing(pw, pd, t, rightMargin: 5), section: section.drawing(width, top, st),
      posts: count, widthMm: width, depthMm: depth, walkMm: walk, walkHeadMm: head, eaveMm: eastZ, fallPct: slope, roofM2: roofArea);
  }
}

class _CanopySheet {
  final lines = <CadLine>[], labels = <CadLabel>[];
  void line(String layer, num x, num y, num ex, num ey) => lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
  void box(String layer, num x, num y, num ex, num ey) {
    line(layer, x, y, ex, y);
    line(layer, ex, y, ex, ey);
    line(layer, ex, ey, x, ey);
    line(layer, x, ey, x, y);
  }
  void label(num x, num y, String text, num size) => labels.add(CadLabel('ANNOTATIONS', CadPoint(x, y), text, size));
  void heading(int w, int h, double t, List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      label(w / 2, h + t * (5.5 - 1.4 * i), rows[i], i == 0 ? t : t * .65);
    }
  }
  FloorPlanCad drawing(int w, int h, double t, {int rightMargin = 2}) => FloorPlanCad.fromEntities(
    bounds: PlanRect(math.min(-2 * t, w / 2 - 40 * t).floor(), (-2 * t).floor(),
      math.max(w + rightMargin * t, w / 2 + 40 * t).ceil(), (h + 7.2 * t).ceil()), lines: lines, labels: labels);
}
