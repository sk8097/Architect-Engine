import 'dart:math' as math;

class CorridorPoint {
  const CorridorPoint(this.easting, this.northing);
  final int easting, northing;
}

class CorridorStation {
  const CorridorStation(this.point, this.chainageMm, {this.mark = 'STA'});
  final CorridorPoint point;
  final double chainageMm;
  final String mark;
  String get label {
    final cm = (chainageMm / 10).round();
    return '${cm ~/ 100000}+${((cm % 100000) / 100).toStringAsFixed(2).padLeft(6,'0')}';
  }
}

class CorridorBand {
  const CorridorBand(this.label, this.widthMm);
  final String label;
  final int widthMm;
}

class SurveyCorridorDrawing {
  SurveyCorridorDrawing({required this.title, required this.grid, required this.reference, required this.widthMm,
    required this.lengthMm, required Iterable<CorridorStation> stations, required Iterable<CorridorBand> bands,
    required Iterable<List<CorridorPoint>> edges, this.curves})
    : stations = List.unmodifiable(stations), bands = List.unmodifiable(bands),
      edges = List.unmodifiable(edges.map((edge) => List<CorridorPoint>.unmodifiable(edge)));
  final String title, grid, reference;
  final int widthMm;
  final double lengthMm;
  final List<CorridorStation> stations;
  final List<CorridorBand> bands;
  final SurveyCurveGeometry? curves;
  /// Ordered left ROW edge, unique band dividers, right ROW edge.
  final List<List<CorridorPoint>> edges;
}

/// Unrounded projected millimetres for exact tangent and arc entities.
class SurveyPosition {
  const SurveyPosition(this.x,this.y);
  final double x,y;
  SurveyPosition operator +(SurveyPosition other)=>SurveyPosition(x+other.x,y+other.y);
  SurveyPosition operator -(SurveyPosition other)=>SurveyPosition(x-other.x,y-other.y);
  SurveyPosition operator *(double factor)=>SurveyPosition(x*factor,y*factor);
  double dot(SurveyPosition other)=>x*other.x+y*other.y;
  double cross(SurveyPosition other)=>x*other.y-y*other.x;
  double get norm=>math.sqrt(dot(this));
  SurveyPosition get left=>SurveyPosition(-y,x);
  CorridorPoint get rounded=>CorridorPoint(x.round(),y.round());
}

double surveyAngle(double radians)=>radians % (2*math.pi);

class SurveyArc {
  const SurveyArc(this.centre,this.radius,this.start,this.sweep);
  final SurveyPosition centre;
  final double radius,start,sweep;
  SurveyPosition point(double angle)=>centre+SurveyPosition(math.cos(angle),math.sin(angle))*radius;
  bool spans(double angle,{double angularTolerance=0}) {
    final delta=surveyAngle((sweep>0?1:-1)*(angle-start));
    return delta<=sweep.abs()+angularTolerance || 2*math.pi-delta<=angularTolerance;
  }
}

class SurveyPrimitive {
  SurveyPrimitive(this.from,this.to,{this.arc});
  final SurveyPosition from,to;
  final SurveyArc? arc;
  Iterable<SurveyPosition> get extrema sync* {
    yield from;
    yield to;
    if (arc case final a?) {
      for(var i=0;i<4;i++) {
        final angle=i*math.pi/2;
        if(a.spans(angle,angularTolerance:1e-12)) yield a.point(angle);
      }
    }
  }
  late final ({double left,double right,double bottom,double top}) bounds=(
    left:extrema.map((p)=>p.x).reduce(math.min),right:extrema.map((p)=>p.x).reduce(math.max),
    bottom:extrema.map((p)=>p.y).reduce(math.min),top:extrema.map((p)=>p.y).reduce(math.max),
  );
}

class SurveyCurveGeometry {
  SurveyCurveGeometry(Iterable<SurveyPrimitive> axis,Iterable<List<SurveyPrimitive>> edges,Iterable<double> offsets)
    : axis=List.unmodifiable(axis),edges=List.unmodifiable(edges.map((p)=>List<SurveyPrimitive>.unmodifiable(p))),
      offsets=List.unmodifiable(offsets);
  final List<SurveyPrimitive> axis;
  final List<List<SurveyPrimitive>> edges;
  final List<double> offsets;
}
