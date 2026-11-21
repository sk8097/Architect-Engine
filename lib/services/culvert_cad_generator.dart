import 'dart:math' as math;

import '../data/culvert_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class CulvertCadResult {
  const CulvertCadResult({this.plan, this.profile, this.issue, this.lengthMm = 0, this.gradePercent = 0,
    this.roadStartMm = 0, this.roadEndMm = 0, this.coverMm = 0, this.coverAtMm = 0, this.exaggeration = 1});
  final FloorPlanCad? plan, profile;
  final String? issue;
  final double lengthMm, gradePercent, roadStartMm, roadEndMm, coverMm, coverAtMm;
  final int exaggeration;
}

/// Straight surveyed barrel beneath a straight road band. Only longitudinal
/// cover along the barrel centreline is checked, not the full 3D surface.
class CulvertCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['culvert_cad_mode'] == 'survey_crossing';

  CulvertCadResult generate(ProjectBrief brief) {
    CulvertCadResult stop(String issue) => CulvertCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !culvertCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Water / wastewater / stormwater → Culvert and save the current surveyed brief.');
    }
    if (!const {null, 'drainage_system', 'network'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one new surveyed culvert concept with no parking, floors or separate Space selections.');
    }
    final a = snap.answers;
    String? ref(String key) {
      final v = a[key];
      return v is String && v.trim().isNotEmpty && v.trim().length <= 120 ? v.trim().replaceAll(RegExp(r'\s+'), ' ') : null;
    }
    final grid = ref('cv_grid'), source = ref('cv_reference');
    if (grid == null || source == null) return stop('Enter the projected grid and common elevation datum reference (up to 120 characters each).');
    double? n(String key, num min, num max) {
      final v = a[key];
      return v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;
    }
    final stationM = n('cv_road_station', .001, 2000), bearing = n('cv_road_bearing', 0, 360);
    final roadM = n('cv_road_width', .001, 300), barrelM = n('cv_barrel_width', .001, 20), crownM = n('cv_crown', .001, 20);
    final minCover = n('cv_cover', 0, 100), minFall = n('cv_fall', 0, 100);
    final scale = switch (a['cv_scale']) {null || '1' => 1, '5' => 5, '10' => 10, _ => null};
    if (stationM == null || bearing == null || roadM == null || barrelM == null || crownM == null ||
        minCover == null || minFall == null || scale == null) return stop('Enter road station, bearing and width, barrel shape, minimum cover and fall, and a supported vertical scale.');
    final decimal = RegExp(r'^[+-]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    int? mm(String token, int limit) {
      final n = decimal.hasMatch(token) ? double.tryParse(token) : null;
      return n != null && n.isFinite && n.abs() <= limit ? (n * 1000).round() : null;
    }
    List<String>? read(Object? raw, int max) => raw is String && raw.length <= max
        ? raw.split(RegExp(r'[;\r\n]+')).where((line) => line.trim().isNotEmpty).toList() : null;
    final ends = read(a['cv_ends'], 300);
    if (ends == null || ends.length != 2) return stop('Enter exactly two controls, inlet then outlet, in Easting,Northing,surface,invert format.');
    final points = <(int, int, int, int)>[];
    for (final row in ends) {
      final p = row.split(',').map((entry) => entry.trim()).toList();
      if (p.length != 4) return stop('Use four numbers for each end: Easting,Northing,surface,invert.');
      final x = mm(p[0], 10000000), y = mm(p[1], 10000000), z = mm(p[2], 10000), invert = mm(p[3], 10000);
      if (x == null || y == null || z == null || invert == null) return stop('Use valid projected metre coordinates and levels to three decimal places.');
      points.add((x,y,z,invert));
    }
    final (ix,iy,iz,ii) = points[0];
    final (ox,oy,oz,oi) = points[1];
    final dx = (ox-ix).toDouble(), dy = (oy-iy).toDouble();
    final length = math.sqrt(dx*dx + dy*dy);
    if (length < 1 || length > 2000000) return stop('The surveyed barrel length must be positive and at most 2 km.');
    final fall = ii-oi, grade = fall/length*100;
    if (fall <= 0 || grade < minFall - 1e-10) return stop('The barrel must fall downstream and meet the supplied minimum grade.');
    final ux = dx/length, uy = dy/length;
    final angle = bearing*math.pi/180, rx = math.sin(angle), ry = math.cos(angle);
    final cross = (ux*ry-uy*rx).abs();
    if (cross < math.sin(math.pi/12)-1e-12) return stop('The road and barrel axes must cross at an angle of at least 15° from parallel.');
    final station = (stationM*1000).roundToDouble(), road = (roadM*1000).round()/2, barrel = (barrelM*1000).round()/2;
    final crown = (crownM*1000).round(), need = (minCover*1000).round();
    final near = station-road/cross, far = station+road/cross;
    // Check both entire end faces, not just the centre of each cap.
    final cap = barrel*(ux*rx+uy*ry).abs()/cross;
    if (near - cap <= 0 || far + cap >= length) {
      return stop('Both full barrel ends must extend past the surveyed road band at the supplied skew and width.');
    }
    final ground = <(double,int)>[(0.0,iz)];
    final raw = a['cv_surface'];
    if (raw != null) {
      final rows = read(raw,12000);
      if (rows == null || rows.length > 150) return stop('Enter up to 150 intermediate chainage,level pairs.');
      for (final row in rows) {
        final p = row.split(',').map((entry) => entry.trim()).toList();
        final s = p.length == 2 ? mm(p[0], 2000) : null, z = p.length == 2 ? mm(p[1],10000) : null;
        if (s == null || z == null || s <= ground.last.$1 || s >= length) {
          return stop('Intermediate surface chainages must increase strictly between the inlet and outlet, with valid levels.');
        }
        ground.add((s.toDouble(),z));
      }
    }
    ground.add((length,oz));
    double surface(double x) {
      for (var i=1;i<ground.length;i++) {
        final (r, z) = ground[i];
        final (l, g) = ground[i-1];
        if (x <= r) return g + (z-g)*(x-l)/(r-l);
      }
      return oz.toDouble();
    }
    double invert(double x) => ii-fall*x/length;
    var min = double.infinity, at = near;
    for (final x in [near, for(final sample in ground) if (sample.$1 > near && sample.$1 < far) sample.$1, far]) {
      final cover = surface(x) - (invert(x)+crown);
      if (cover < min) { min = cover; at = x; }
    }
    String m(num mm) => (mm/1000).toStringAsFixed(3);
    if (min < need-1e-6) return stop('Minimum roadway cover is ${m(min)} m at chainage ${m(at)} m, below the supplied ${m(need)} m.');

    final origin = CadPoint(ix,iy), rc = CadPoint(ix+ux*station,iy+uy*station);
    CadPoint b(double s,double off) => CadPoint(origin.x+ux*s-uy*off,origin.y+uy*s+ux*off);
    CadPoint r(double s,double off) => CadPoint(rc.x+rx*s+ry*off,rc.y+ry*s-rx*off);
    final patch = math.max(station,length-station)*(ux*rx+uy*ry).abs() + barrel + math.max(road,2000).toDouble();
    final corners = [r(-patch,-road),r(patch,-road),r(patch,road),r(-patch,road)];
    final barrelOutline = [b(0,-barrel),b(length,-barrel),b(length,barrel),b(0,barrel)];
    final planLines = <CadLine>[], planLabels = <CadLabel>[];
    void loop(String layer,List<CadPoint> ps) {
      for (var i=0;i<ps.length;i++) { planLines.add(CadLine(layer,ps[i],ps[(i+1)%ps.length])); }
    }
    loop('CULVERT_ROAD',corners);
    loop('CULVERT_BARREL',barrelOutline);
    planLines.addAll([CadLine('CULVERT_ROAD_AXIS',r(-patch,0),r(patch,0)),CadLine('CULVERT_BARREL_AXIS',origin,CadPoint(ox,oy))]);
    final text = (math.max(length,patch*2)/85).clamp(60,10000).toDouble();
    final ymin = [...corners,...barrelOutline].map((p)=>p.y).reduce(math.min), ymax = [...corners,...barrelOutline].map((p)=>p.y).reduce(math.max);
    final xmin = [...corners,...barrelOutline].map((p)=>p.x).reduce(math.min), xmax = [...corners,...barrelOutline].map((p)=>p.x).reduce(math.max);
    final cx=(xmin+xmax)/2, title=ymax+text*5;
    for (final (s,name) in [(0.0,'INLET'),(length,'OUTLET'),(near,'ROAD EDGE'),(far,'ROAD EDGE')]) {
      final left=b(s,-text*.38), right=b(s,text*.38);
      planLines.add(CadLine('CULVERT_CONTROLS',left,right));
      final p=b(s,barrel+text*.7);
      planLabels.add(CadLabel('CULVERT_CONTROLS',p,name,text*.6));
    }
    final ax = xmax+text*2;
    final tip = CadPoint(ax,ymax);
    planLines.addAll([CadLine('ANNOTATIONS',CadPoint(ax,ymax-text*1.7),tip),
      CadLine('ANNOTATIONS',CadPoint(ax-text*.4,ymax-text*.7),tip),CadLine('ANNOTATIONS',CadPoint(ax+text*.4,ymax-text*.7),tip)]);
    planLabels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(ax,ymax+text),'GRID N',text*.65),
      CadLabel('ANNOTATIONS',CadPoint(cx,title),'SURVEYED ROAD CULVERT / CONCEPT',text),
      CadLabel('ANNOTATIONS',CadPoint(cx,title-text*1.4),'$grid / $source',text*.62),
      CadLabel('ANNOTATIONS',CadPoint(cx,title-text*2.8),'PROJECTED MM / STRAIGHT ROAD BAND IS LOCAL ONLY',text*.62),
    ]);
    final planHalf=math.max(22,(grid.length+source.length+3)*.25)*text;
    final plan=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(xmin-text*5,cx-planHalf).floor(),(ymin-text*3).floor(),
      math.max(ax+text*4,cx+planHalf).ceil(),(title+text*1.5).ceil()),lines:planLines,labels:planLabels);

    final datum = (math.min(oi,ground.map((p)=>p.$2).reduce(math.min))/1000).floor()*1000-1000;
    CadPoint q(num x,num z)=>CadPoint(x,(z-datum)*scale);
    final profileLines=<CadLine>[], profileLabels=<CadLabel>[];
    for (var i=1;i<ground.length;i++) {
      final (s,z)=ground[i-1];
      final (t,w)=ground[i];
      profileLines.add(CadLine('CULVERT_SURFACE',q(s,z),q(t,w)));
    }
    profileLines.addAll([CadLine('CULVERT_INVERT',q(0,ii),q(length,oi)),CadLine('CULVERT_CROWN',q(0,ii+crown),q(length,oi+crown))]);
    final h=(math.max(ii+crown,ground.map((p)=>p.$2).reduce(math.max))-datum)*scale;
    final label=(math.max(length,h)/85).clamp(50,20000).toDouble();
    for (final x in [near,far]) {
      profileLines.add(CadLine('CULVERT_ROAD',CadPoint(x,0),q(x,surface(x))));
      profileLabels.add(CadLabel('CULVERT_ROAD',CadPoint(x, -label),m(x),label*.64));
    }
    profileLines.addAll([CadLine('CULVERT_ROAD',CadPoint(near,0),CadPoint(far,0)),
      CadLine('CULVERT_COVER',q(at,invert(at)+crown),q(at,surface(at)))]);
    profileLabels.addAll([
      CadLabel('CULVERT_COVER',q(at,surface(at)+label/scale),'MIN COVER ${m(min)} M',label*.7),
      CadLabel('ANNOTATIONS',CadPoint(length/2,h+label*5),'CULVERT BARREL PROFILE / ROAD BAND',label),
      CadLabel('ANNOTATIONS',CadPoint(length/2,h+label*3.8),source,label*.65),
      CadLabel('ANNOTATIONS',CadPoint(length/2,h+label*2.5),'X = INLET CHAINAGE MM / Y = (LEVEL - ${m(datum)} M) x $scale IN MM',label*.65),
      CadLabel('ANNOTATIONS',CadPoint(length/2,-label*2.6),'INVERT ${m(ii)} M TO ${m(oi)} M / ${grade.toStringAsFixed(3)}% FALL',label*.65),
    ]);
    final profileHalf=math.max(25,source.length*.25)*label;
    final profile=FloorPlanCad.fromEntities(bounds:PlanRect(math.min(-label*4,length/2-profileHalf).floor(),(-4*label).floor(),
      math.max(length+label*4,length/2+profileHalf).ceil(),(h+label*6.5).ceil()),lines:profileLines,labels:profileLabels);
    return CulvertCadResult(plan:plan,profile:profile,lengthMm:length,gradePercent:grade,roadStartMm:near,roadEndMm:far,
      coverMm:min,coverAtMm:at,exaggeration:scale);
  }
}
