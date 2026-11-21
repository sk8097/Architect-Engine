import 'dart:math' as math;

import '../data/lap_pool_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class LapPoolCadResult {
  const LapPoolCadResult({this.plan, this.section, this.issue, this.lanes = 0, this.widthMm = 0,
    this.lengthMm = 0, this.deckWidthMm = 0, this.deckLengthMm = 0, this.grade = 0, this.volumeM3 = 0});
  final FloorPlanCad? plan, section;
  final String? issue;
  final int lanes, widthMm, lengthMm, deckWidthMm, deckLengthMm;
  final double grade, volumeM3;
}

/// Constant clear width, vertical ends, two flat reaches and one planar transition.
/// The section datum is water level (0); deck elevations are not assumed.
class LapPoolCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'lap_pool_measured';

  LapPoolCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    LapPoolCadResult stop(String issue) => LapPoolCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !lapPoolCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Swimming Pool and save the current measured pool brief.');
    }
    if (!const {null, 'outdoor'}.contains(sel.configurationId) ||
        !const {null, 'concept_design', 'new_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor pool without buildings, parking or separate Space selections.');
    }
    if (!const {'square', 'rectangular'}.contains(sel.plotShapeId)) {
      return stop('Use a cardinally aligned rectangular or square plot.');
    }
    final a = snap.answers;
    int? mm(Object? v, {bool zero = false, int max = 300}) {
      if (v is! num || !v.isFinite || v < (zero ? 0 : .001) || v > max) return null;
      return (v * 1000).round();
    }
    final pw = mm(widthFt * .3048, max: 2000), pd = mm(depthFt * .3048, max: 2000);
    final length = mm(a['lp_length']), lanes = a['lp_lanes'], laneWidth = mm(a['lp_lane_width'], max: 20);
    final margin = mm(a['lp_side_margin'], zero: true, max: 20), side = mm(a['lp_side_deck']);
    final south = mm(a['lp_south_deck']), north = mm(a['lp_north_deck']);
    final westOffset = mm(a['lp_west'], zero: true), southOffset = mm(a['lp_south'], zero: true);
    final shallow = mm(a['lp_shallow_depth'], max: 20), deep = mm(a['lp_deep_depth'], max: 20);
    final shallowFlat = mm(a['lp_shallow_flat']), deepFlat = mm(a['lp_deep_flat']), maxGrade = a['lp_max_grade'];
    if (pw == null || pd == null || length == null || lanes is! int || lanes < 1 || lanes > 12 || laneWidth == null ||
        margin == null || side == null || south == null || north == null || westOffset == null || southOffset == null ||
        shallow == null || deep == null || shallowFlat == null || deepFlat == null || maxGrade is! num ||
        !maxGrade.isFinite || maxGrade < .001 || maxGrade > 100 || (sel.plotShapeId == 'square' && pw != pd)) {
      return stop('Enter measured plot, lane, deck and pool floor dimensions and a maximum grade.');
    }
    final width = lanes * laneWidth + 2 * margin, deckW = width + 2 * side, deckD = length + south + north;
    for (final (edge, clear) in [('left', westOffset), ('front', southOffset),
      ('right', pw - westOffset - deckW), ('rear', pd - southOffset - deckD)]) {
      final raw = a['${edge}_setback'], requiredClear = raw == null ? 0 : mm(raw, zero: true, max: 2000);
      if (requiredClear == null || clear < requiredClear) {
        return stop('The pool and clear deck conflict with the $edge plot edge or supplied setback.');
      }
    }
    if (deep <= shallow) return stop('The deep end must have greater water depth than the shallow end.');
    final transition = length - shallowFlat - deepFlat;
    if (transition <= 0) return stop('The shallow and deep flats leave no positive length for the floor transition.');
    final grade = 100 * (deep - shallow) / transition;
    if (grade > maxGrade + 1e-9) {
      return stop('Transition grade ${grade.toStringAsFixed(3)}% exceeds the supplied $maxGrade% maximum.');
    }
    final volume = width / 1000 * (shallowFlat / 1000 * shallow / 1000 +
      transition / 1000 * (shallow + deep) / 2000 + deepFlat / 1000 * deep / 1000);
    String m(num value) => (value / 1000).toStringAsFixed(3);
    void line(List<CadLine> lines, String layer, num x, num y, num xx, num yy) =>
      lines.add(CadLine(layer, CadPoint(x,y), CadPoint(xx,yy)));
    void label(List<CadLabel> labels, String layer, num x, num y, String text, num height) =>
      labels.add(CadLabel(layer, CadPoint(x,y), text, height));
    final planLines = <CadLine>[], planLabels = <CadLabel>[];
    void box(String layer, int x, int y, int xx, int yy) {
      line(planLines,layer,x,y,xx,y); line(planLines,layer,xx,y,xx,yy);
      line(planLines,layer,xx,yy,x,yy); line(planLines,layer,x,yy,x,y);
    }
    final x = westOffset + side, y = southOffset + south;
    final deepBreak = length - deepFlat;
    box('POOL_PLOT',0,0,pw,pd);
    box('POOL_DECK',westOffset,southOffset,westOffset + deckW,southOffset + deckD);
    box('POOL_WATER',x,y,x + width,y + length);
    for (var i = 0; i <= lanes; i++) {
      if (margin == 0 && (i == 0 || i == lanes)) continue; // Water edge already drawn.
      final lx = x + margin + i * laneWidth;
      line(planLines,'POOL_LANES',lx,y,lx,y + length);
    }
    for (final ch in [shallowFlat, deepBreak]) {
      line(planLines,'POOL_BREAKS',x,y + ch,x + width,y + ch);
    }
    final text = (math.max(pw,pd) / 82).clamp(35,5000).toDouble();
    final numberSize = math.min(text*.65, math.min(laneWidth*.42, shallowFlat/2));
    for (var i = 0; i < lanes; i++) {
      label(planLabels,'POOL_LANES',x + margin + (i + .5)*laneWidth,y + shallowFlat/2,'${i+1}',numberSize);
    }
    final arrowX = pw + text*2;
    line(planLines,'ANNOTATIONS',arrowX,pd - text*2,arrowX,pd);
    line(planLines,'ANNOTATIONS',arrowX - text*.45,pd - text*.75,arrowX,pd);
    line(planLines,'ANNOTATIONS',arrowX + text*.45,pd - text*.75,arrowX,pd);
    label(planLabels,'ANNOTATIONS',arrowX,pd + text,'N',text*.65);
    label(planLabels,'ANNOTATIONS',pw/2,pd + text*4.9,'OUTDOOR LAP POOL PLAN / LOCAL MM',text);
    label(planLabels,'ANNOTATIONS',pw/2,pd + text*3.5,'${m(width)} x ${m(length)} M WATER / $lanes LANES / SHALLOW TO SOUTH',text*.65);
    label(planLabels,'ANNOTATIONS',pw/2,pd + text*2.1,'DECK ENVELOPE ${m(deckW)} x ${m(deckD)} M / SEE LONG SECTION',text*.65);
    final plan = FloorPlanCad.fromEntities(bounds: PlanRect(math.min(-2*text,pw/2-23*text).floor(),(-2*text).floor(),
      math.max(arrowX+2*text,pw/2+23*text).ceil(),(pd+6.4*text).ceil()),lines:planLines,labels:planLabels);

    final sectionLines = <CadLine>[], sectionLabels = <CadLabel>[];
    void sl(String layer,num sx,num sy,num ex,num ey) => line(sectionLines,layer,sx,sy,ex,ey);
    sl('POOL_WATER',0,0,length,0);
    sl('POOL_FLOOR',0,0,0,-shallow);
    sl('POOL_FLOOR',0,-shallow,shallowFlat,-shallow);
    sl('POOL_FLOOR',shallowFlat,-shallow,deepBreak,-deep);
    sl('POOL_FLOOR',deepBreak,-deep,length,-deep);
    sl('POOL_FLOOR',length,-deep,length,0);
    sl('POOL_BREAKS',shallowFlat,0,shallowFlat,-shallow);
    sl('POOL_BREAKS',deepBreak,0,deepBreak,-deep);
    final st = (math.max(length,deep)/40).clamp(25,2000).toDouble();
    void note(double row,String message,{num size = .66}) =>
      label(sectionLabels,'ANNOTATIONS',length/2,row*st,message,st*size);
    note(6,'LONGITUDINAL POOL SECTION / TRUE SCALE MM',size:1);
    note(4.5,'WATER DATUM 0 / SHALLOW SOUTH ${m(shallow)} M / DEEP NORTH ${m(deep)} M');
    note(3.2,'FLAT ${m(shallowFlat)} M / TRANSITION ${m(transition)} M / FLAT ${m(deepFlat)} M');
    note(1.9,'GRADE ${grade.toStringAsFixed(3)}% / WATER VOLUME ${volume.toStringAsFixed(3)} M3');
    final section = FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-2*st,length/2-26*st).floor(),(-deep-2*st).floor(),
      math.max(length+2*st,length/2+26*st).ceil(),(7.5*st).ceil()),lines:sectionLines,labels:sectionLabels);
    return LapPoolCadResult(plan:plan,section:section,lanes:lanes,widthMm:width,lengthMm:length,
      deckWidthMm:deckW,deckLengthMm:deckD,grade:grade,volumeM3:volume);
  }
}
