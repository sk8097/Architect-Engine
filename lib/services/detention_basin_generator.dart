import 'dart:math' as math;

import '../data/detention_basin_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class BasinStage {
  const BasinStage(this.label, this.levelMm, this.areaM2, this.storageM3);
  final String label;
  final int levelMm;
  final double areaM2, storageM3;
}

class DetentionBasinResult {
  const DetentionBasinResult({this.plan, this.section, this.issue, this.stages = const [], this.freeboardMm = 0,
    this.activeStorageM3 = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final List<BasinStage> stages;
  final int freeboardMm;
  final double activeStorageM3;
}

/// Concept geometry for one flat-bottomed rectangle with constant side slopes.
class DetentionBasinGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'basin_stage_storage';

  DetentionBasinResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    DetentionBasinResult stop(String issue) => DetentionBasinResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !detentionBasinEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Water / wastewater / stormwater → Detention/Retention Pond and save the current brief.');
    }
    if (!const {null, 'storage', 'drainage_system'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a new open basin in Storage or Drainage System, with no structures, parking or separate Space selections.');
    }
    if (!const {'square', 'rectangular'}.contains(sel.plotShapeId)) return stop('Use a measured rectangular or square plot aligned to the cardinal axes.');
    final a = snap.answers, reference = snap.answers['db_reference'];
    if (reference is! String || reference.trim().isEmpty || reference.trim().length > 120) {
      return stop('Enter the survey and level datum reference (up to 120 characters).');
    }
    double? value(Object? v, double min, double max) => v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    int? mm(Object? v, double min, double max) {
      final metres = value(v, min, max);
      return metres == null ? null : (metres * 1000).round();
    }
    final plotW = mm(widthFt * .3048, .001, 2000), plotL = mm(depthFt * .3048, .001, 2000);
    final w = mm(a['db_width'], .001, 2000), l = mm(a['db_length'], .001, 2000);
    final sx = value(a['db_slope_x'], .1, 30), sy = value(a['db_slope_y'], .1, 30);
    final west = mm(a['db_west'], 0, 2000), south = mm(a['db_south'], 0, 2000);
    final floor = mm(a['db_bottom'], -10000, 10000), normal = mm(a['db_normal'], -10000, 10000);
    final design = mm(a['db_design'], -10000, 10000), crest = mm(a['db_crest'], -10000, 10000);
    final needed = mm(a['db_freeboard'], 0, 100), target = value(a['db_target'], 0, 1000000000);
    if (plotW == null || plotL == null || w == null || l == null || sx == null || sy == null || west == null || south == null ||
        floor == null || normal == null || design == null || crest == null || needed == null || target == null ||
        (sel.plotShapeId == 'square' && plotW != plotL)) {
      return stop('Enter measured plot and basin dimensions, offsets, slopes, levels, storage target and freeboard.');
    }
    if (normal < floor || design <= normal || crest <= design) {
      return stop('Levels must follow floor ≤ normal pool < design high water < inner crest, on one datum.');
    }
    final height = crest - floor, freeboard = crest - design;
    if (height > 100000) return stop('Limit the modelled basin depth to 100 m.');
    String m(num mm) => (mm / 1000).toStringAsFixed(3);
    if (freeboard < needed) return stop('Freeboard is ${m(freeboard)} m, below the supplied ${m(needed)} m minimum.');
    final crestW = w + 2 * sx * height, crestL = l + 2 * sy * height;
    const epsilon = 1e-6;
    for (final (key, side, clear) in [
      ('left_setback', 'west', west), ('right_setback', 'east', plotW - west - crestW),
      ('front_setback', 'south', south), ('rear_setback', 'north', plotL - south - crestL),
    ]) {
      final raw = a[key], setback = raw == null ? 0 : mm(raw, 0, 2000);
      if (setback == null || clear < setback - epsilon) {
        return stop('The inner crest footprint conflicts with the $side plot edge or supplied setback.');
      }
    }
    final wm = w / 1000, lm = l / 1000;
    double area(double h) => (wm + 2 * sx * h) * (lm + 2 * sy * h);
    // Integral of (W + 2*sx*h)*(L + 2*sy*h) from the floor to the stage.
    double volume(double h) => wm * lm * h + (wm * sy + lm * sx) * h * h + (4 / 3) * sx * sy * h * h * h;
    BasinStage stage(String id, int z) {
      final h = (z - floor) / 1000;
      return BasinStage(id, z, area(h), volume(h));
    }
    final stages = [stage('Floor', floor), stage('Normal pool', normal), stage('Design high water', design), stage('Inner crest', crest)];
    final active = stages[2].storageM3 - stages[1].storageM3;
    if (active < target - epsilon) {
      return stop('Active storage is ${active.toStringAsFixed(3)} m³, below the supplied ${target.toStringAsFixed(3)} m³ target.');
    }
    final cx = west + crestW / 2, cy = south + crestL / 2;
    final planLines = <CadLine>[], planLabels = <CadLabel>[];
    final sectionLines = <CadLine>[], sectionLabels = <CadLabel>[];
    void line(List<CadLine> out, String layer, num a, num b, num c, num d) => out.add(CadLine(layer, CadPoint(a,b), CadPoint(c,d)));
    void box(String layer, num x, num y, num r, num t) {
      line(planLines, layer, x,y,r,y); line(planLines, layer,r,y,r,t);
      line(planLines, layer,r,t,x,t); line(planLines, layer,x,t,x,y);
    }
    box('BASIN_PLOT', 0, 0, plotW, plotL);
    final text = (math.max(plotW, plotL) / 76).clamp(30, 20000).toDouble();
    final sectionText = (math.max(crestW, height) / 65).clamp(15, 20000).toDouble();
    const layers = ['BASIN_FLOOR', 'BASIN_NORMAL', 'BASIN_DESIGN', 'BASIN_CREST'];
    for (var i = 0; i < stages.length; i++) {
      final h = stages[i].levelMm - floor, wx = w / 2 + sx * h, ly = l / 2 + sy * h;
      if (i == 1 && normal == floor) continue;
      box(layers[i], cx - wx, cy - ly, cx + wx, cy + ly);
      planLabels.add(CadLabel(layers[i], CadPoint(cx, cy + ly + text * .2), '${stages[i].label} ${m(stages[i].levelMm)} m', text * .55));
      if (i == 1 || i == 2) line(sectionLines, layers[i], crestW / 2 - wx, h, crestW / 2 + wx, h);
    }
    line(planLines, 'BASIN_SECTION_LINE', west - text, cy, west + crestW + text, cy);
    planLabels.add(CadLabel('BASIN_SECTION_LINE', CadPoint(west - text, cy + text * .6), 'A', text * .7));
    planLabels.add(CadLabel('BASIN_SECTION_LINE', CadPoint(west + crestW + text, cy + text * .6), 'A', text * .7));
    line(sectionLines, 'BASIN_CREST', 0, height, sx * height, 0);
    line(sectionLines, 'BASIN_FLOOR', sx * height, 0, sx * height + w, 0);
    line(sectionLines, 'BASIN_CREST', sx * height + w, 0, crestW, height);
    if (normal == floor) sectionLabels.add(CadLabel('BASIN_FLOOR', CadPoint(crestW / 2, -sectionText), 'DRY NORMAL POOL AT FLOOR', sectionText * .65));
    // Levels are at true geometry. The short freeboard bar is outside the section.
    final barX = crestW + sectionText * 2;
    line(sectionLines, 'BASIN_FREEBOARD', barX, design - floor, barX, height);
    for (final h in [design - floor, height]) {
      line(sectionLines, 'BASIN_FREEBOARD', barX - sectionText * .3, h, barX + sectionText * .3, h);
    }
    sectionLabels.add(CadLabel('BASIN_FREEBOARD', CadPoint(barX + sectionText * 4, (design - floor + height) / 2),
      'FB ${m(freeboard)} m', sectionText * .65));
    final source = reference.trim().replaceAll(RegExp(r'\s+'), ' ');
    planLabels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(plotW / 2, plotL + text * 4.3), 'DETENTION / RETENTION BASIN - CONCEPT', text),
      CadLabel('ANNOTATIONS', CadPoint(plotW / 2, plotL + text * 2.8), source, text * .65),
      CadLabel('ANNOTATIONS', CadPoint(plotW / 2, plotL + text * 1.5), 'LOCAL PLAN IN MM / NORTH UP / NO EMBANKMENT DESIGN', text * .65),
    ]);
    sectionLabels.addAll([
      CadLabel('ANNOTATIONS', CadPoint(crestW / 2, height + sectionText * 4.8), 'BASIN SECTION A-A / WEST TO EAST', sectionText),
      CadLabel('ANNOTATIONS', CadPoint(crestW / 2, height + sectionText * 3.45),
        'Y = (LEVEL - ${m(floor)} M) IN MM / TRUE SCALE', sectionText * .65),
      CadLabel('BASIN_DESIGN', CadPoint(crestW / 2, height + sectionText * 2.1),
        'NORMAL ${m(normal)} M / DESIGN ${m(design)} M / CREST ${m(crest)} M', sectionText * .62),
      CadLabel('ANNOTATIONS', CadPoint(crestW / 2, -sectionText * 2.5),
        'ACTIVE STORAGE ${active.toStringAsFixed(3)} M3 / ABOVE NORMAL POOL', sectionText * .65),
    ]);
    for (var i = 0; i < stages.length; i++) {
      final row = stages[i];
      sectionLabels.add(CadLabel('ANNOTATIONS', CadPoint(crestW / 2, -sectionText * (3.7 + i)),
        '${row.label.toUpperCase()} ${m(row.levelMm)} M / ${row.areaM2.toStringAsFixed(3)} M2 / ${row.storageM3.toStringAsFixed(3)} M3',
        sectionText * .58));
    }
    final span = math.max(22, source.length * .26) * text;
    final plan = FloorPlanCad.fromEntities(bounds: PlanRect(math.min(-2 * text, plotW / 2 - span).floor(), (-text).floor(),
      math.max(plotW + 2 * text, plotW / 2 + span).ceil(), (plotL + 6 * text).ceil()), lines: planLines, labels: planLabels);
    final section = FloorPlanCad.fromEntities(bounds: PlanRect(math.min(-sectionText * 2, crestW / 2 - sectionText * 22).floor(),
      (-sectionText * 8).floor(), math.max(barX + sectionText * 9, crestW / 2 + sectionText * 22).ceil(),
      (height + sectionText * 6).ceil()), lines: sectionLines, labels: sectionLabels);
    return DetentionBasinResult(plan: plan, section: section, stages: List.unmodifiable(stages), freeboardMm: freeboard, activeStorageM3: active);
  }
}
