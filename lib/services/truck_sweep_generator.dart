import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/truck_sweep_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

typedef _P = math.Point<double>;

class TruckSweepResult {
  const TruckSweepResult(this.drawing, this.issue, {this.axleTravelMm = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final double axleTravelMm;
}

/// One rigid (not articulated) rectangular body with rear-axle centre on
/// straight-circle-straight tangents. Coordinates in local apron millimetres.
class TruckSweepGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'truck_reverse_sweep';

  TruckSweepResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    TruckSweepResult stop(String issue) => TruckSweepResult(null, issue);
    final s = brief.taxonomy, snap = brief.requirements;
    if (s == null || snap == null || s.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !truckSweepEligible(s.categoryId, s.subcategoryId, s.typeId)) return stop('Select a supported single-sided warehouse type and save the measured apron brief.');
    if (s.spaceQuantities.isNotEmpty || !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(s.actionId)) {
      return stop('The sweep sheet draws only one loading manoeuvre. Use a concept brief with no separate Space selections.');
    }
    if (!const {'rectangular','square'}.contains(s.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and cardinal vehicle frontage.');
    }
    final a = snap.answers;
    int? mm(Object? value, {bool zero = false}) {
      if (value is! num || !value.isFinite || value < 0 || value > 300) return null;
      final n = (value * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final pw = mm(widthFt * .3048), pd = mm(depthFt * .3048), w = mm(a['ts_width']), d = mm(a['ts_depth']);
    final off = mm(a['ts_offset'], zero: true), dock = mm(a['ts_dock_x']), bay = mm(a['ts_dock_width']);
    final radius = mm(a['ts_radius']), wheelbase = mm(a['ts_wheelbase']), front = mm(a['ts_front'], zero: true);
    final rear = mm(a['ts_rear']), bodyW = mm(a['ts_body_width']), clearance = mm(a['ts_buffer'], zero: true);
    final lead = mm(a['ts_lead'], zero: true), tail = mm(a['ts_reverse']), gap = mm(a['ts_stop_gap']);
    final side = a['ts_approach_side'];
    if (pw == null || pd == null || w == null || d == null || off == null || dock == null || bay == null || radius == null ||
        wheelbase == null || front == null || rear == null || bodyW == null || clearance == null || lead == null || tail == null || gap == null ||
        !const {'left','right'}.contains(side) || (s.plotShapeId == 'square' && pw != pd)) {
      return stop('Enter all measured apron, bay, vehicle, turn and clearance inputs and select the approach side.');
    }
    if (off + w > pw || d > pd || dock - bay / 2 < 0 || dock + bay / 2 > w) return stop('The apron or dock bay lies outside the measured paved/plot boundary.');
    if (gap < clearance || bay < bodyW + 2 * clearance) return stop('The dock bay width and rear stop gap must accommodate the measured clearance buffer.');
    final obstacles = <(String, PlanRect)>[];
    final raw = a['ts_obstacles'];
    if (raw != null) {
      if (raw is! String || raw.length > 3000) return stop('Enter up to 20 directly measured apron obstacles.');
      final rows = raw.split(RegExp(r'[;\r\n]+')).where((row) => row.trim().isNotEmpty).toList();
      if (rows.length > 20) return stop('Enter up to 20 directly measured apron obstacles.');
      final names = <String>{}, name = RegExp(r'^[A-Za-z][A-Za-z0-9_-]{0,15}$');
      for (final row in rows) {
        final parts = row.split(',').map((p) => p.trim()).toList();
        if (parts.length != 5 || !name.hasMatch(parts[0]) || !names.add(parts[0].toUpperCase())) return stop('Use unique obstacle IDs as ID,left,front,width,depth (m).');
        final x = mm(double.tryParse(parts[1]), zero: true), y = mm(double.tryParse(parts[2]), zero: true);
        final bw = mm(double.tryParse(parts[3])), bh = mm(double.tryParse(parts[4]));
        if (x == null || y == null || bw == null || bh == null || x + bw > w || y + bh > d) return stop('Obstacle ${parts[0]} needs valid dimensions entirely inside the apron.');
        obstacles.add((parts[0], PlanRect(x,y,x+bw,y+bh)));
      }
    }
    final reflect = side == 'right' ? 1 : -1;
    final turnEndY = d - rear - gap - tail;
    final centre = _P((dock + reflect * radius).toDouble(), turnEndY.toDouble());
    final maxF = (wheelbase + front + clearance).toDouble(), minF = (-rear - clearance).toDouble(), half = bodyW / 2 + clearance;
    List<_P> body(double angle, double pre, double post, bool buffered) {
      final c = math.cos(angle), sn = math.sin(angle);
      final axisX = radius - radius * sn + pre, axisY = turnEndY - radius * c + post;
      final f1 = buffered ? minF : -rear.toDouble(), f2 = buffered ? maxF : (wheelbase + front).toDouble();
      final h = buffered ? half : bodyW / 2;
      return [for (final (f, lateral) in [(f1,-h),(f2,-h),(f2,h),(f1,h)])
        _P(dock + reflect * (axisX + f * c + lateral * sn), axisY - f * sn + lateral * c)];
    }
    const quarter = math.pi / 2;
    final start = body(0, lead.toDouble(), 0, true), begin = body(0, 0, 0, true);
    final end = body(quarter, 0, 0, true), parked = body(quarter, 0, tail.toDouble(), true);
    final farthest = begin.map((p) => p.distanceTo(centre)).reduce(math.max);
    final steps = math.max(16, (quarter * math.sqrt(farthest / 32)).ceil());
    final error = farthest * (1 - math.cos(quarter / steps / 2));
    String? check(List<_P> before, List<_P> after, double pad, String leg) {
      final hull = _hull([...before,...after]);
      if (hull.any((p) => p.x < pad - 1e-6 || p.y < pad - 1e-6 || p.x > w - pad + 1e-6 || p.y > d - pad + 1e-6)) {
        return 'The clearance envelope leaves the paved apron during $leg.';
      }
      for (final (id, rect) in obstacles) {
        if (_hits(hull, rect, pad)) return 'The clearance sweep conflicts with obstacle $id during $leg.';
      }
      return null;
    }
    final entryIssue = check(start, begin, 0, 'the straight approach');
    if (entryIssue != null) return stop(entryIssue);
    var last = begin;
    for (var step = 1; step <= steps; step++) {
      final next = body(quarter * step / steps, 0, 0, true);
      final issue = check(last, next, error, 'the 90-degree turn');
      if (issue != null) return stop(issue);
      last = next;
    }
    final dockIssue = check(end, parked, 0, 'the straight docking leg');
    if (dockIssue != null) return stop(dockIssue);

    CadPoint p(_P q) {
      final x = q.x + off, y = q.y;
      return switch (facing) {
        'North' => CadPoint(pw - x, pd - y), 'East' => CadPoint(pd - y, x), 'West' => CadPoint(y, pw - x), _ => CadPoint(x,y),
      };
    }
    final lines = <CadLine>[], arcs = <CadArc>[], labels = <CadLabel>[];
    void line(String layer, _P a, _P b) { if (a.distanceTo(b) > 1e-6) lines.add(CadLine(layer,p(a),p(b))); }
    void box(String layer, List<_P> pts) {
      for (var i = 0; i < pts.length; i++) { line(layer,pts[i],pts[(i+1)%pts.length]); }
    }
    List<_P> rect(num l,num b,num r,num t) => [_P(l.toDouble(),b.toDouble()),_P(r.toDouble(),b.toDouble()),
      _P(r.toDouble(),t.toDouble()),_P(l.toDouble(),t.toDouble())];
    box('TRUCK_APRON',rect(0,0,w,d));
    box('TRUCK_BAY',rect(dock-bay/2,turnEndY,dock+bay/2,d));
    final text = (math.min(w,d)/55).clamp(130,2000).toDouble();
    for (final (id, r) in obstacles) {
      box('TRUCK_OBSTACLE',rect(r.left,r.bottom,r.right,r.top));
      labels.add(CadLabel('TRUCK_OBSTACLE',p(_P((r.left+r.right)/2,(r.bottom+r.top)/2)),id,text*.65));
    }
    void drawArc(String layer,_P a,_P b) {
      final c = p(centre), rad = a.distanceTo(centre);
      if (rad < 1e-6) return;
      double angle(_P q) { final xy = p(q); return (math.atan2(xy.y-c.y,xy.x-c.x)*180/math.pi)%360; }
      arcs.add(CadArc(layer,c,rad,angle(reflect==1?b:a),angle(reflect==1?a:b)));
    }
    final axle1 = _P(centre.x+reflect*lead,centre.y-radius), axle2 = _P(centre.x,centre.y-radius);
    final axle3 = _P(dock.toDouble(),centre.y), axle4 = _P(dock.toDouble(),centre.y+tail);
    const track = 'TRUCK_CLEAR_SWEEP', axle = 'TRUCK_AXLE';
    line(axle,axle1,axle2); drawArc(axle,axle2,axle3); line(axle,axle3,axle4);
    for (var i = 0; i < 4; i++) {
      line(track,start[i],begin[i]);drawArc(track,begin[i],end[i]);line(track,end[i],parked[i]);
    }
    box(track,start); box(track,parked);
    for (final angle in [0.0,quarter/4,quarter/2,quarter*3/4,quarter]) {
      box('TRUCK_POSES',body(angle,angle==0?lead.toDouble():0,angle==quarter?tail.toDouble():0,false));
    }
    labels.addAll([
      CadLabel('TRUCK_BAY',p(_P(dock.toDouble(),d+text*.8)),'DOCK FACE',text*.7),
      CadLabel('ANNOTATIONS',p(_P(w/2,d+text*3.6)),'RIGID TRUCK / ONE REVERSE MANOEUVRE',text),
      CadLabel('ANNOTATIONS',p(_P(w/2,d+text*2.25)),'APRON DIMENSIONS IN MM / CONCEPT ONLY',text*.68),
    ]);
    final boundary = rect(-text*7,-text*7,w+text*7,d+text*7).map(p).toList();
    final bounds = PlanRect(boundary.map((v)=>v.x).reduce(math.min).floor(),boundary.map((v)=>v.y).reduce(math.min).floor(),
      boundary.map((v)=>v.x).reduce(math.max).ceil(),boundary.map((v)=>v.y).reduce(math.max).ceil());
    return TruckSweepResult(FloorPlanCad.fromEntities(bounds:bounds,lines:lines,arcs:arcs,labels:labels),null,
      axleTravelMm:lead+quarter*radius+tail);
  }
}

/// Convex sweep patch between two rigid poses. A circular track between the
/// endpoints deviates by no more than its sagitta; adding that radius makes
/// this test conservative even for an obstacle lying between sampled poses.
List<_P> _hull(List<_P> points) {
  final pts = points.toSet().toList()..sort((a,b)=>a.x==b.x?a.y.compareTo(b.y):a.x.compareTo(b.x));
  double cross(_P a,_P b,_P c) => (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
  List<_P> chain(Iterable<_P> inputs) {
    final result = <_P>[];
    for (final p in inputs) {
      while (result.length>=2 && cross(result[result.length-2],result.last,p)<=0) {result.removeLast();}
      result.add(p);
    }
    return result;
  }
  final lower=chain(pts)..removeLast(), upper=chain(pts.reversed)..removeLast();
  return [...lower,...upper];
}

bool _hits(List<_P> hull,PlanRect r,double pad) {
  final box=[_P(r.left.toDouble(),r.bottom.toDouble()),_P(r.right.toDouble(),r.bottom.toDouble()),
    _P(r.right.toDouble(),r.top.toDouble()),_P(r.left.toDouble(),r.top.toDouble())];
  bool gap(double x,double y) {
    final n=math.sqrt(x*x+y*y);
    if (n==0) return false;
    final u=hull.map((p)=>p.x*x+p.y*y), v=box.map((p)=>p.x*x+p.y*y);
    return u.reduce(math.max)+pad*n<v.reduce(math.min) || v.reduce(math.max)+pad*n<u.reduce(math.min);
  }
  if (gap(1,0)||gap(0,1)) return false;
  for(var i=0;i<hull.length;i++) {
    final a=hull[i],b=hull[(i+1)%hull.length];
    if(gap(a.y-b.y,b.x-a.x)) return false;
  }
  return true;
}
