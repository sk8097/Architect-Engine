import 'dart:math' as math;

import '../models/survey_corridor.dart';

/// Builds minor circular fillets at points of intersection of surveyed
/// tangents. Radius comes from the brief, not a design speed assumption.
({SurveyCurveGeometry? geometry,List<CorridorStation> stations,double length,String? issue}) surveyCurves(
    List<CorridorPoint> points,List<double> radii,List<double> offsets,double startMm) {
  ({SurveyCurveGeometry? geometry,List<CorridorStation> stations,double length,String? issue}) block(String issue)=>
    (geometry:null,stations:const [],length:0.0,issue:issue);
  final ps=[for(final p in points) SurveyPosition(p.easting.toDouble(),p.northing.toDouble())];
  final chords=[for(var i=0;i+1<ps.length;i++) ps[i+1]-ps[i]];
  final lengths=chords.map((p)=>p.norm).toList();
  final tangents=[for(var i=0;i<chords.length;i++) chords[i]*(1/lengths[i])];
  final trims=List<double>.filled(ps.length,0);
  final arcs=<SurveyArc>[];
  for(var i=1;i+1<ps.length;i++) {
    final a=tangents[i-1], b=tangents[i];
    final turn=math.atan2(a.cross(b),a.dot(b));
    final degrees=turn.abs()*180/math.pi;
    if (degrees<.01 || degrees>175) return block('Point ${i+1}: circular bends require a turn from 0.01° to 175°. Remove collinear controls or review reversals.');
    final radius=radii[i-1];
    if (radius-offsets.first<1) return block('Point ${i+1}: the radius must exceed half the ROW width by at least 1 mm.');
    final trim=radius*math.tan(turn.abs()/2);
    trims[i]=trim;
    final pc=ps[i]-a*trim, center=pc+a.left*(turn.sign*radius);
    final angle=math.atan2(-turn.sign*a.x,turn.sign*a.y);
    arcs.add(SurveyArc(center,radius,angle,turn));
  }
  for(var i=0;i<lengths.length;i++) {
    if(lengths[i]-trims[i]-trims[i+1]<1) {
      return block('The supplied radii leave less than 1 mm of straight tangent between points ${i+1} and ${i+2}. Reduce the radii or revise the alignment.');
    }
  }
  List<SurveyPrimitive> path(double offset) {
    final parts=<SurveyPrimitive>[];
    var begin=ps.first+tangents.first.left*offset;
    for(var i=0;i<arcs.length;i++) {
      final a=arcs[i];
      final arc=SurveyArc(a.centre,a.radius-a.sweep.sign*offset,a.start,a.sweep);
      final pc=arc.point(arc.start),pt=arc.point(arc.start+arc.sweep);
      parts.add(SurveyPrimitive(begin,pc));
      parts.add(SurveyPrimitive(pc,pt,arc:arc));
      begin=pt;
    }
    parts.add(SurveyPrimitive(begin,ps.last+tangents.last.left*offset));
    return parts;
  }
  final axis=path(0), edges=[for(final offset in offsets) if(offset==0) axis else path(offset)];
  final length=axis.fold<double>(0,(n,p)=>n+_length(p));
  final paths=[axis,for(var i=0;i<edges.length;i++) if(offsets[i]!=0) edges[i]];
  for(var i=0;i<paths.length;i++) {
    final a=paths[i];
    for(var p=0;p<a.length;p++) {
      // Adjacent primitives have one shared tangent endpoint by construction.
      for(var q=p+2;q<a.length;q++) {
        if(_meet(a[p],a[q])) return block('The curved centreline or an offset edge crosses or touches itself.');
      }
    }
    for(var j=i+1;j<paths.length;j++) {
      final b=paths[j];
      for(final u in a) {
        for(final v in b) {
          if(_meet(u,v)) return block('The curved ROW, centreline or band edges cross or touch. Reduce width or review the control geometry.');
        }
      }
    }
  }
  final head=SurveyPrimitive(edges.first.first.from,edges.last.first.from);
  final tail=SurveyPrimitive(edges.first.last.to,edges.last.last.to);
  if (_meet(head,tail)) return block('The two ROW end caps overlap or touch.');
  for(final p in paths) {
    for(var i=0;i<p.length;i++) {
      if ((i>0 && _meet(head,p[i])) || (i<p.length-1 && _meet(tail,p[i]))) {
        return block('A curved ROW end cap crosses or touches another part of the alignment.');
      }
    }
  }
  var distance=startMm;
  final stations=[CorridorStation(axis.first.from.rounded,distance,mark:'START')];
  for(var i=0;i<axis.length;i++) {
    final p=axis[i];
    distance+=_length(p);
    final mark=i==axis.length-1?'END':p.arc==null?'PC':'PT';
    stations.add(CorridorStation(p.to.rounded,distance,mark:mark));
  }
  return (geometry:SurveyCurveGeometry(axis,edges,offsets),stations:stations,length:length,issue:null);
}

double _length(SurveyPrimitive p)=>p.arc==null?(p.to-p.from).norm:p.arc!.radius*p.arc!.sweep.abs();

// Analytic intersections (not chord sampling); the small tolerance treats
// near contact as touching. Bounds include all cardinal extrema of each arc.
const _eps=.01; // mm
bool _meet(SurveyPrimitive a,SurveyPrimitive b) {
  final x=a.bounds,y=b.bounds;
  if (x.right+_eps<y.left || y.right+_eps<x.left || x.top+_eps<y.bottom || y.top+_eps<x.bottom) return false;
  final arcA=a.arc,arcB=b.arc;
  if (arcA!=null && arcB!=null) return _arcArc(arcA,arcB);
  if (arcA!=null) return _lineArc(b,arcA);
  if (arcB!=null) return _lineArc(a,arcB);
  int side(SurveyPrimitive l,SurveyPosition p) {
    final u=l.to-l.from;
    final d=u.cross(p-l.from)/u.norm;
    return d.abs()<=_eps?0:d.sign.toInt();
  }
  return side(a,b.from)*side(a,b.to)<=0 && side(b,a.from)*side(b,a.to)<=0;
}

bool _onSweep(SurveyArc a,SurveyPosition p) {
  final d=p-a.centre;
  return a.spans(math.atan2(d.y,d.x),angularTolerance:_eps/a.radius);
}

bool _lineArc(SurveyPrimitive line,SurveyArc arc) {
  final v=line.to-line.from,len=v.norm,u=v*(1/len);
  final c=arc.centre-line.from;
  final along=c.dot(u), normal=c.cross(u).abs();
  if(normal>arc.radius+_eps) return false;
  final half=math.sqrt(math.max(0,(arc.radius-normal)*(arc.radius+normal)));
  for(final t in [along-half,along+half]) {
    if(t>=-_eps && t<=len+_eps && _onSweep(arc,line.from+u*t)) return true;
  }
  return false;
}

bool _arcArc(SurveyArc a,SurveyArc b) {
  final diff=b.centre-a.centre,d=diff.norm;
  if(d<_eps) {
    if((a.radius-b.radius).abs()>_eps+d) return false;
    return _onSweep(a,b.point(b.start)) || _onSweep(a,b.point(b.start+b.sweep)) ||
      _onSweep(b,a.point(a.start)) || _onSweep(b,a.point(a.start+a.sweep));
  }
  if (d>a.radius+b.radius+_eps || d<(a.radius-b.radius).abs()-_eps) return false;
  final u=diff*(1/d);
  final x=(d*d+(a.radius-b.radius)*(a.radius+b.radius))/(2*d);
  final base=a.centre+u*x;
  final half=math.sqrt(math.max(0,(a.radius-x)*(a.radius+x)));
  return [base+u.left*half,base-u.left*half].any((p)=>_onSweep(a,p)&&_onSweep(b,p));
}
