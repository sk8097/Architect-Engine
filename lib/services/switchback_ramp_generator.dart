import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/switchback_ramp_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class RampFlight {
  const RampFlight(this.fromMm, this.toMm, this.runMm);
  final int fromMm, toMm, runMm;
  int get riseMm => toMm - fromMm;
  double get gradePercent => 100 * riseMm / runMm;
}

class SwitchbackRampResult {
  const SwitchbackRampResult({this.plan, this.profile, this.issue, this.flights = const [], this.walkMm = 0});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final List<RampFlight> flights;
  final int walkMm;
}

/// One outdoor two-flight return ramp with level endpoint and turn landings.
class SwitchbackRampGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'measured_switchback';

  SwitchbackRampResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    SwitchbackRampResult stop(String issue) => SwitchbackRampResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !switchbackRampEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select a Public Park, Public Garden, Urban Plaza or Playground and save the current ramp brief.');
    }
    if (!const {null, 'public_open_space'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a new Public Open Space with no floors, parking or separate Space selections.');
    }
    if (!const {'square', 'rectangular'}.contains(sel.plotShapeId) || !const {'North','South','East','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and choose a cardinal frontage.');
    }
    final a = snap.answers, datum = snap.answers['sr_datum'];
    if (datum is! String || datum.trim().isEmpty || datum.trim().length > 120) {
      return stop('Enter a common survey datum and source reference (up to 120 characters).');
    }
    int? mm(Object? value, {num min = .001, num max = 300}) =>
        value is num && value.isFinite && value >= min && value <= max ? (value * 1000).round() : null;
    final w = mm(widthFt * .3048), d = mm(depthFt * .3048);
    final low = mm(a['sr_floor'], min: -10000, max: 10000), mid = mm(a['sr_mid'], min: -10000, max: 10000);
    final high = mm(a['sr_top'], min: -10000, max: 10000);
    final run = mm(a['sr_run']), width = mm(a['sr_width']), divider = mm(a['sr_divider'], min: 0);
    final land = mm(a['sr_end_depth']), turn = mm(a['sr_turn_depth']);
    final left = mm(a['sr_left'], min: 0), front = mm(a['sr_front'], min: 0);
    final minWidth = mm(a['sr_min_clear']), minLand = mm(a['sr_min_landing']), maxRise = mm(a['sr_max_rise']);
    final maxGrade = a['sr_max_grade'];
    if (w == null || d == null || low == null || mid == null || high == null || run == null || width == null || divider == null ||
        land == null || turn == null || left == null || front == null || minWidth == null || minLand == null || maxRise == null ||
        maxGrade is! num || !maxGrade.isFinite || maxGrade < .001 || maxGrade > 100 || (sel.plotShapeId == 'square' && w != d)) {
      return stop('Enter measured levels, geometry and supplied limits for width, turning clearance, rise and slope.');
    }
    if (low >= mid || mid >= high) return stop('Levels must increase from the lower landing to the turn, then to the upper landing.');
    if (width < minWidth) return stop('The flight width is less than the supplied minimum clear width.');
    if (math.min(width, math.min(land, turn)) < minLand) return stop('The supplied clear turning square does not fit at every landing.');
    final flights = [RampFlight(low,mid,run), RampFlight(mid,high,run)];
    String m(num mm) => (mm / 1000).toStringAsFixed(3);
    for (var i = 0; i < flights.length; i++) {
      final f = flights[i];
      if (f.riseMm > maxRise) return stop('Flight ${i+1} rise ${m(f.riseMm)} m exceeds the supplied maximum ${m(maxRise)} m.');
      if (f.gradePercent > maxGrade + 1e-10) return stop('Flight ${i+1} slope ${f.gradePercent.toStringAsFixed(3)}% exceeds the supplied maximum $maxGrade%.');
    }
    final shellW = 2 * width + divider, shellD = land + run + turn;
    for (final (side, clear) in [('left',left), ('right',w-left-shellW), ('front',front), ('rear',d-front-shellD)]) {
      final raw = a['${side}_setback'], setback = raw == null ? 0 : mm(raw, min: 0);
      if (setback == null || clear < setback) return stop('The ramp footprint conflicts with the $side plot edge or supplied setback.');
    }
    final rotated = facing == 'East' || facing == 'West', pw = rotated ? d : w, pd = rotated ? w : d;
    CadPoint p(num x, num y) => switch (facing) {
      'North' => CadPoint(w-x,d-y), 'East' => CadPoint(d-y,x), 'West' => CadPoint(y,w-x), _ => CadPoint(x,y),
    };
    CadPoint r(num x, num y) => p(left+x,front+y);
    final planLines = <CadLine>[], planLabels = <CadLabel>[];
    void line(String layer, num x, num y, num xx, num yy) => planLines.add(CadLine(layer,r(x,y),r(xx,yy)));
    void box(String layer, num x, num y, num xx, num yy) {
      line(layer,x,y,xx,y); line(layer,xx,y,xx,yy); line(layer,xx,yy,x,yy); line(layer,x,yy,x,y);
    }
    box('RAMP_PLOT',-left,-front,w-left,d-front);
    final second = width+divider, tail = land+run;
    box('RAMP_LANDING',0,0,width,land); box('RAMP_LANDING',second,0,shellW,land);
    box('RAMP_LANDING',0,tail,shellW,shellD);
    box('RAMP_FLIGHT',0,land,width,tail); box('RAMP_FLIGHT',second,land,shellW,tail);
    if (divider > 0) box('RAMP_SEPARATOR',width,0,second,tail);
    final x1 = width / 2, x2 = second + width / 2, endY = tail + turn / 2;
    final halfClear = minLand / 2;
    for (final (cx,cy) in [(x1,land/2),(x2,land/2),(shellW/2,endY)]) {
      box('RAMP_CLEAR',cx-halfClear,cy-halfClear,cx+halfClear,cy+halfClear);
    }
    line('RAMP_PATH',x1,0,x1,endY); line('RAMP_PATH',x1,endY,x2,endY); line('RAMP_PATH',x2,endY,x2,0);
    final arrow = math.min(width,run) * .17;
    final arrowY = land + run / 2;
    for (final side in [-1,1]) {
      line('RAMP_PATH',x1+side*arrow,arrowY-arrow,x1,arrowY+arrow);
      line('RAMP_PATH',x2+side*arrow,arrowY+arrow,x2,arrowY-arrow);
    }
    final text = (math.max(pw,pd) / 78).clamp(30,5000).toDouble();
    final small = math.min(text*.7,math.min(width,land)/12);
    planLabels.addAll([
      CadLabel('RAMP_LANDING',r(x1,land/2),'LOWER ${m(low)} M',small),
      CadLabel('RAMP_LANDING',r(x2,land/2),'UPPER ${m(high)} M',small),
      CadLabel('RAMP_LANDING',r(shellW/2,endY+turn*.25),'TURN ${m(mid)} M',small),
      CadLabel('RAMP_FLIGHT',r(x1,land+run*.27),'F1 ${flights[0].gradePercent.toStringAsFixed(2)}%',small),
      CadLabel('RAMP_FLIGHT',r(x2,land+run*.27),'F2 ${flights[1].gradePercent.toStringAsFixed(2)}%',small),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+text*4.4),'TWO-FLIGHT SWITCHBACK RAMP / CONCEPT',text),
      CadLabel('ANNOTATIONS',CadPoint(pw/2,pd+text*2.95),'$facing FRONTAGE / NORTH UP / LOCAL MM',text*.7),
    ]);
    final markX = pw + text * 2;
    planLines.addAll([
      CadLine('ANNOTATIONS',CadPoint(markX,pd-text*1.7),CadPoint(markX,pd)),
      CadLine('ANNOTATIONS',CadPoint(markX-text*.4,pd-text*.7),CadPoint(markX,pd)),
      CadLine('ANNOTATIONS',CadPoint(markX+text*.4,pd-text*.7),CadPoint(markX,pd)),
    ]);
    planLabels.add(CadLabel('ANNOTATIONS',CadPoint(markX,pd+text),'N',text*.7));
    final plan = FloorPlanCad.fromEntities(bounds: PlanRect(math.min(-text*2,pw/2-text*22).floor(),(-text*2).floor(),
      math.max(markX+text*3,pw/2+text*22).ceil(),(pd+text*6).ceil()), lines:planLines, labels:planLabels);

    // The unfolded X axis follows the orthogonal centreline, including
    // half the turn depth at each end and a traverse between the flight axes.
    final acrossTurn = turn + width + divider, walk = 2*(land+run)+acrossTurn;
    final z1 = mid-low, z2 = high-low;
    final stops = [const CadPoint(0,0),CadPoint(land,0),CadPoint(tail,z1),CadPoint(tail+acrossTurn,z1),
      CadPoint(walk-land,z2),CadPoint(walk,z2)];
    final profileLines = <CadLine>[], profileLabels = <CadLabel>[];
    final label = (math.max(walk,z2) / 80).clamp(25,5000).toDouble();
    for (var i=1; i<stops.length; i++) {
      final u=stops[i-1],v=stops[i], flight=i==2 || i==4;
      final layer = flight ? 'RAMP_FLIGHT' : 'RAMP_LANDING';
      profileLines.add(CadLine(layer,u,v));
      if (flight) profileLabels.add(CadLabel(layer,CadPoint((u.x+v.x)/2,(u.y+v.y)/2+label),
        '${flights[i~/2-1].gradePercent.toStringAsFixed(2)}%',label*.7));
    }
    final source = datum.trim().replaceAll(RegExp(r'\s+'),' ');
    profileLabels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(walk/2,z2+label*5.5),'UNFOLDED RAMP PROFILE / TRUE SCALE',label),
      CadLabel('ANNOTATIONS',CadPoint(walk/2,z2+label*4),source,label*.65),
      CadLabel('ANNOTATIONS',CadPoint(walk/2,z2+label*2.7),'X = WALK CHAINAGE MM / Y = LEVEL ABOVE ${m(low)} M IN MM',label*.65),
      CadLabel('ANNOTATIONS',CadPoint(walk/2,-label*2.5),'LOW ${m(low)} M / TURN ${m(mid)} M / HIGH ${m(high)} M',label*.65),
    ]);
    final span=math.max(23,source.length*.26)*label;
    final profile = FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-label*2,walk/2-span).floor(),(-label*4).floor(),
      math.max(walk+label*2,walk/2+span).ceil(),(z2+label*7).ceil()),lines:profileLines,labels:profileLabels);
    return SwitchbackRampResult(plan:plan, profile:profile, flights:List.unmodifiable(flights), walkMm:walk);
  }
}
