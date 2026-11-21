import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/survey_corridor_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class SectionPoint {
  const SectionPoint(this.offsetMm, this.levelMm);
  final int offsetMm, levelMm;
}

class SectionBand {
  const SectionBand(this.from, this.to);
  final SectionPoint from, to;
  double get crossfallPercent => (to.levelMm - from.levelMm) * 100 / (to.offsetMm - from.offsetMm);
}

class CorridorSectionResult {
  const CorridorSectionResult(this.drawing, this.issue, {this.chainageMm = 0, this.datumMm = 0,
    this.exaggeration = 1, this.cutM2 = 0, this.fillM2 = 0, this.bands = const []});
  final FloorPlanCad? drawing;
  final String? issue;
  final int chainageMm, datumMm, exaggeration;
  final double cutM2, fillM2;
  final List<SectionBand> bands;
}

/// Single transverse section. Areas compare two piecewise-linear profiles
/// only over the surveyed proposed footprint; there is no extrapolation.
class CorridorSectionGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['corridor_cad_mode'] == 'survey_section';

  CorridorSectionResult generate(ProjectBrief brief, {bool sheetSet = false}) {
    CorridorSectionResult stop(String issue) => CorridorSectionResult(null, issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        sel.categoryId != 'infrastructure' || sel.subcategoryId != 'transport' || !surveyCorridorTypes.contains(sel.typeId)) {
      return stop('Select a Road, Street, Footpath or Cycle Track and save the current cross-section brief.');
    }
    if (!const {null, 'linear_corridor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a linear cross-section without structures, parking, junctions or separate Space selections.');
    }
    final a = snap.answers, ref = snap.answers['section_reference'], chain = snap.answers['section_chainage'];
    if (ref is! String || ref.trim().isEmpty || ref.trim().length > 120) {
      return stop('Enter the benchmark datum and survey reference (up to 120 characters).');
    }
    if (chain is! num || !chain.isFinite || chain < 0 || chain > 1000000) {
      return stop('Enter a chainage between 0 and 1,000,000 m.');
    }
    final chainage = (chain * 1000).round();
    final scale = switch (a['section_exaggeration']) {null || '1' => 1, '5' => 5, '10' => 10, _ => null};
    if (scale == null) return stop('Select an available vertical exaggeration.');
    final pattern = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    List<SectionPoint>? read(Object? raw, int maxRows) {
      if (raw is! String || raw.length > 12000) return null;
      final rows = raw.trim().split(RegExp(r'[;\r\n]+')).where((r) => r.trim().isNotEmpty).toList();
      if (rows.length < 2 || rows.length > maxRows) return null;
      final points = <SectionPoint>[];
      for (final row in rows) {
        final pair = row.split(',').map((p) => p.trim()).toList();
        if (pair.length != 2 || pair.any((p) => !pattern.hasMatch(p))) return null;
        final x = double.tryParse(pair[0]), z = double.tryParse(pair[1]);
        if (x == null || z == null || !x.isFinite || !z.isFinite || x.abs() > 1000 || z.abs() > 10000) return null;
        points.add(SectionPoint((x * 1000).round(), (z * 1000).round()));
      }
      return points;
    }
    final ground = read(a['section_ground'], 150), design = read(a['section_design'], 80);
    if (ground == null || design == null) {
      return stop('Enter 2–150 surveyed and 2–80 proposed offset,level pairs in metres (up to three decimals; offsets within ±1,000 m and levels within ±10,000 m).');
    }
    bool increasing(List<SectionPoint> points) {
      for (var i = 1; i < points.length; i++) {
        if (points[i].offsetMm <= points[i - 1].offsetMm) return false;
      }
      return true;
    }
    if (!increasing(ground) || !increasing(design)) return stop('Each offset list must increase strictly from left to right without duplicates.');
    final start = design.first.offsetMm, end = design.last.offsetMm;
    final left = ground.first.offsetMm, right = ground.last.offsetMm;
    if (start >= 0 || end <= 0) return stop('The proposed extents must span offset zero, from negative left to positive right.');
    if (left > start || right < end) return stop('The ground survey must cover the entire proposed footprint; offsets cannot be extrapolated.');

    final controlPoints = [...ground, ...design];
    final minLevel = controlPoints.map((pt) => pt.levelMm).reduce(math.min);
    final maxLevel = controlPoints.map((pt) => pt.levelMm).reduce(math.max);
    final datum = (minLevel / 1000).floor() * 1000 - 1000;
    final high = (maxLevel - datum) * scale;
    final text = (math.max(right - left, high) / 90).clamp(10, 3000000).toDouble();
    final source = ref.trim().replaceAll(RegExp(r'\s+'), ' ');
    final lines = <CadLine>[], labels = <CadLabel>[];
    CadPoint pt(num x, num z) => CadPoint(x, (z - datum) * scale);
    void line(String layer, CadPoint p, CadPoint q) {
      if (p.x != q.x || p.y != q.y) lines.add(CadLine(layer, p, q));
    }
    double levelAt(List<SectionPoint> points, int x) {
      for (var i = 1; i < points.length; i++) {
        final p = points[i - 1], q = points[i];
        if (x <= q.offsetMm) return p.levelMm + (q.levelMm - p.levelMm) * ((x - p.offsetMm) / (q.offsetMm - p.offsetMm));
      }
      return points.last.levelMm.toDouble();
    }
    final offsets = <int>{
      // Surface intersections within these intervals are found analytically.
      for (final p in ground) if (p.offsetMm > start && p.offsetMm < end) p.offsetMm,
      for (final p in design) p.offsetMm,
    }.toList()..sort();
    var cut = 0.0, fill = 0.0;
    void area(double x1, double x2, double g1, double g2, double d1, double d2) {
      final width = x2 - x1, sum = d1 + d2;
      if (sum == 0) return;
      final quantity = width * sum / 2e6;
      if (quantity > 0) { fill += quantity; } else { cut -= quantity; }
      // Short editable interior strokes distinguish cut from fill without
      // masking the ground or design lines. Strokes do not encode scale.
      final count = (width / (text * 2)).ceil().clamp(1, 24);
      for (var j = 0; j < count; j++) {
        final f = (j + .5) / count;
        final x = x1 + width * f, g = g1 + (g2 - g1) * f, dz = d1 + (d2 - d1) * f;
        line(quantity > 0 ? 'SECTION_FILL' : 'SECTION_CUT', pt(x, g + .15 * dz), pt(x, g + .85 * dz));
      }
    }
    double delta(double designZ, double groundZ) {
      final d = designZ - groundZ;
      return d.abs() < 1e-8 ? 0 : d;
    }
    for (var i = 1; i < offsets.length; i++) {
      final l = offsets[i - 1], r = offsets[i];
      final g1 = levelAt(ground, l), g2 = levelAt(ground, r);
      final d1 = delta(levelAt(design, l), g1), d2 = delta(levelAt(design, r), g2);
      if (d1 * d2 < 0) {
        final f = d1 / (d1 - d2), x = l + (r - l) * f, g = g1 + (g2 - g1) * f;
        area(l.toDouble(), x, g1, g, d1, 0);
        area(x, r.toDouble(), g, g2, 0, d2);
      } else {
        area(l.toDouble(), r.toDouble(), g1, g2, d1, d2);
      }
    }
    line('SECTION_AXES', CadPoint(left, 0), CadPoint(right, 0));
    line('SECTION_AXES', const CadPoint(0, 0), CadPoint(0, high + text * .65));
    void trace(String layer, List<SectionPoint> points) {
      for (var i = 1; i < points.length; i++) {
        final u = points[i - 1], v = points[i];
        line(layer, pt(u.offsetMm, u.levelMm), pt(v.offsetMm, v.levelMm));
      }
    }
    trace('SECTION_GROUND', ground);
    trace('SECTION_DESIGN', design);
    final bands = [for (var i = 1; i < design.length; i++) SectionBand(design[i - 1], design[i])];
    for (final band in bands) {
      final u = band.from, v = band.to;
      if (v.offsetMm - u.offsetMm < text * 8) continue;
      labels.add(CadLabel('SECTION_DESIGN', pt((u.offsetMm + v.offsetMm) / 2, (u.levelMm + v.levelMm) / 2 + text / scale),
        '${band.crossfallPercent.toStringAsFixed(2)}%', text * .66));
    }
    String m(num mm) => (mm / 1000).toStringAsFixed(3);
    final mid = (left + right) / 2;
    for (final (x, y, value) in [(left, -text, m(left)), (0, -text * 2.3, 'CL 0.000'), (right, -text, '+${m(right)}')]) {
      labels.add(CadLabel('SECTION_AXES', CadPoint(x, y), value, text * .64));
    }
    final headings = [
      'SURVEY CROSS-SECTION / CH ${m(chainage)} M',
      source,
      if (sheetSet)
        'LOCAL ORIGIN: CL / PLOT BASE ${m(datum)} M / MM / VERTICAL x $scale'
      else
        'X = SIGNED OFFSET MM / Y = (LEVEL - ${m(datum)} M) x $scale IN MM',
      'CUT ${cut.toStringAsFixed(3)} M2 / FILL ${fill.toStringAsFixed(3)} M2 WITHIN DESIGN EXTENTS',
    ];
    for (var i = 0; i < headings.length; i++) {
      labels.add(CadLabel('ANNOTATIONS', CadPoint(mid, high + text * (6 - 1.35 * i)), headings[i], i == 0 ? text : text * .65));
    }
    labels.add(CadLabel('SECTION_AXES', CadPoint(mid, -text * 3.6),
      'OFFSETS IN METRES / LOOKING TOWARD INCREASING CHAINAGE', text * .64));
    final halfTitle = math.max(22, source.length * .26) * text;
    final bounds = PlanRect(math.min(left - text * 6, mid - halfTitle).floor(), (-text * 4.7).floor(),
      math.max(right + text * 6, mid + halfTitle).ceil(), (high + text * 7.2).ceil());
    return CorridorSectionResult(FloorPlanCad.fromEntities(bounds: bounds, lines: lines, labels: labels), null,
      chainageMm: chainage, datumMm: datum, exaggeration: scale, cutM2: cut, fillM2: fill, bands: List.unmodifiable(bands));
  }
}
