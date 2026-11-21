import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/survey_corridor_fields.dart';
import '../models/project_brief.dart';
import '../models/survey_corridor.dart';

class SurveyCorridorResult {
  const SurveyCorridorResult(this.drawing, this.issue);
  final SurveyCorridorDrawing? drawing;
  final String? issue;
}

/// Plan view of an open, surveyed polyline with constant symmetric ROW and
/// straight mitred offsets. This does not interpolate engineering curves.
class SurveyCorridorGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['corridor_cad_mode'] == 'survey_polyline';

  SurveyCorridorResult generate(ProjectBrief brief) {
    SurveyCorridorResult block(String message) => SurveyCorridorResult(null, message);
    final sel = brief.taxonomy, snapshot = brief.requirements;
    if (sel == null || snapshot == null || sel.version != projectTaxonomyVersion || snapshot.version != requirementsSchemaVersion) {
      return block('Save the corridor brief with the current measured requirements.');
    }
    if (sel.categoryId != 'infrastructure' || sel.subcategoryId != 'transport' || !surveyCorridorTypes.contains(sel.typeId)) {
      return block('Survey polyline CAD supports roads, streets, footpaths and cycle tracks only. Junctions and structures need specialist geometry.');
    }
    final a = snapshot.answers;
    if ((sel.configurationId != null && sel.configurationId != 'linear_corridor') ||
        (sel.actionId != null && !const {'new_design','concept_design','feasibility'}.contains(sel.actionId)) ||
        (brief.floorCount ?? 0) != 0 || (brief.parking != null && brief.parking != ProjectParking.none)) {
      return block('Use a linear, plan-view concept without structures, building levels or parking.');
    }
    if (sel.spaceQuantities.isNotEmpty) {
      return block('This mode uses the measured band list, not separate Space selections. Nodes, local widening or discrete facilities are not generated.');
    }
    String? description(Object? raw, int max) => raw is String && raw.trim().isNotEmpty && raw.trim().length <= max
      ? raw.trim().replaceAll(RegExp(r'\s+'), ' ') : null;
    final grid = description(a['corridor_grid'],120), reference = description(a['alignment_reference'],120);
    if (grid == null || reference == null) return block('Enter the projected survey grid/CRS and survey reference (up to 120 characters each). Supply metre coordinates, not latitude/longitude.');
    int? mm(Object? raw, {required num limit, bool zero = false}) {
      if (raw is! num || !raw.isFinite || raw < 0 || raw > limit) return null;
      final n = (1000*raw).round();
      return n > 0 || zero ? n : null;
    }
    final row = mm(a['right_of_way'],limit:1000), stated = mm(a['route_length'],limit:20000);
    final start = mm(a['corridor_start_station'],limit:1000000,zero:true);
    if (row == null || stated == null || start == null) return block('Enter positive surveyed route length (up to 20 km), right-of-way (up to 1000 m) and start chainage.');
    final raw = a['corridor_points'];
    if (raw is! String || raw.length > 8000) return block('Paste 2 to 100 ordered Easting,Northing pairs in metres.');
    final rows = raw.split(RegExp(r'[;\r\n]+')).map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList();
    if (rows.length < 2 || rows.length > 100) return block('Enter 2 to 100 ordered survey points.');
    final points = <CorridorPoint>[];
    final pattern = RegExp(r'^[+-]?\d+(?:\.\d{1,3})?$');
    for (var i=0;i<rows.length;i++) {
      final values = rows[i].split(',').map((s)=>s.trim()).toList();
      if (values.length != 2 || values.any((v)=>!pattern.hasMatch(v))) {
        return block('Point ${i+1}: use Easting,Northing in metres with up to 3 decimal places (e.g. 345000.250,2110000.500).');
      }
      final x = double.tryParse(values[0]), y = double.tryParse(values[1]);
      if (x == null || y == null || !x.isFinite || !y.isFinite || x.abs() > 10000000 || y.abs() > 10000000) {
        return block('Point ${i+1}: coordinates must be within ±10,000,000 metres.');
      }
      points.add(CorridorPoint((x*1000).round(),(y*1000).round()));
    }
    final tangents = <(double,double)>[], stations = [CorridorStation(points.first,start.toDouble())];
    var length = 0.0;
    for (var i=0;i+1<points.length;i++) {
      final dx = points[i+1].easting-points[i].easting, dy = points[i+1].northing-points[i].northing;
      final segment = math.sqrt(dx.toDouble()*dx+dy.toDouble()*dy);
      if (segment < 1) return block('Points ${i+1} and ${i+2} coincide.');
      length += segment;
      if (length > 20000050) return block('The supplied alignment exceeds the 20 km drawing limit.');
      tangents.add((dx/segment,dy/segment));
      stations.add(CorridorStation(points[i+1],start+length));
    }
    if ((length-stated).abs() > 50) {
      return block('Survey points total ${(length/1000).toStringAsFixed(3)} m, not ${(stated/1000).toStringAsFixed(3)} m. Reconcile the surveyed route length to within 0.05 m.');
    }
    final spec = a['corridor_bands'];
    final bands = <CorridorBand>[];
    final boundaries = <double>[row/2];
    var used = 0;
    if (spec != null) {
      if (spec is! String || spec.length > 1500) return block('Enter up to 16 bands in Label:width format, starting at the left ROW edge.');
      final entries = spec.split(';').map((entry)=>entry.trim()).where((entry)=>entry.isNotEmpty).toList();
      if (entries.length > 16) return block('Use up to 16 bands.');
      for (final entry in entries) {
        final pair = entry.split(':');
        final label = description(pair.first,40);
        final w = pair.length == 2 ? mm(double.tryParse(pair[1].trim()),limit:1000) : null;
        if (label == null || w == null) return block('Invalid band "$entry". Use Label:width in metres.');
        used += w;
        if (used > row) return block('Band "$label" exceeds the supplied right-of-way.');
        bands.add(CorridorBand(label,w));
        boundaries.add(row/2-used);
      }
    }
    if (used < row) {
      bands.add(CorridorBand('Unallocated ROW',row-used));
      boundaries.add(-row/2);
    }
    final mitres = <(double,double)>[];
    for (var i=0;i<points.length;i++) {
      final (ux,uy) = tangents[i == 0 ? 0 : i-1];
      final (vx,vy) = tangents[i == points.length-1 ? i-1 : i];
      final divisor = 1+ux*vx+uy*vy;
      if (divisor <= 0.000001) return block('Point ${i+1} reverses the alignment.');
      final offset = (-(uy+vy)/divisor,(ux+vx)/divisor);
      if (offset.$1*offset.$1 + offset.$2*offset.$2 > 6.25) {
        return block('Point ${i+1} has too sharp a bend for a simple mitred corridor. Use a surveyed curve or junction design separately.');
      }
      mitres.add(offset);
    }
    final edges = [for (final offset in boundaries) [
      for (var i=0;i<points.length;i++) CorridorPoint(points[i].easting+(offset*mitres[i].$1).round(),
        points[i].northing+(offset*mitres[i].$2).round()),
    ]];
    for (var i=0;i<tangents.length;i++) {
      final (tx,ty) = tangents[i];
      for (final edge in edges) {
        final dx = edge[i+1].easting-edge[i].easting, dy = edge[i+1].northing-edge[i].northing;
        if (dx*tx+dy*ty < 1) return block('ROW or band boundaries fold near points ${i+1}–${i+2}. Reduce width or review the alignment.');
      }
      for (var j=0;j+1<edges.length;j++) {
        for (final k in [i,i+1]) {
          final left = edges[j][k], right = edges[j+1][k];
          if (-(left.easting-right.easting)*ty+(left.northing-right.northing)*tx <= 0) {
            return block('Band edges touch or reverse near point ${k+1} after millimetre rounding.');
          }
        }
      }
    }
    // Include end caps and check the whole outer boundary, not just the
    // centreline. Nearby runs can intersect even with a simple centreline.
    final outline = [...edges.first,...edges.last.reversed];
    if (_selfIntersects(outline,closed:true) || _selfIntersects(points)) {
      return block('The surveyed centreline or the offset right-of-way crosses or touches itself. Split the corridor or use specialist junction/curve design.');
    }
    for (var a=0;a<edges.length;a++) {
      if (_selfIntersects(edges[a])) return block('An offset band crosses itself.');
      for (var b=a+1;b<edges.length;b++) {
        if (_pathsIntersect(edges[a],edges[b])) return block('Two offset band edges cross or touch.');
      }
      if (_pathsIntersect(edges[a], points) && boundaries[a] != 0) {
        // The centreline is allowed to cross a band only at offset zero,
        // where it coincides exactly with the explicitly supplied boundary.
        return block('An offset band crosses the surveyed centreline.');
      }
    }
    final group = taxonomyGroup(taxonomyCategory(sel.categoryId),sel.subcategoryId)!;
    final type = taxonomyChoice(group.types,sel.typeId)!;
    return SurveyCorridorResult(SurveyCorridorDrawing(title:type.label,grid:grid,reference:reference,
      widthMm:row,lengthMm:length,stations:stations,bands:bands,edges:edges),null);
  }
}

bool _selfIntersects(List<CorridorPoint> path,{bool closed = false}) {
  final segments = closed ? path.length : path.length-1;
  for (var i=0;i<segments;i++) {
    for (var j=i+2;j<segments;j++) {
      if (closed && i==0 && j==segments-1) continue;
      if (_intersects(path[i],path[(i+1)%path.length],path[j],path[(j+1)%path.length])) return true;
    }
  }
  return false;
}

bool _pathsIntersect(List<CorridorPoint> a,List<CorridorPoint> b) {
  for (var i=0;i+1<a.length;i++) {
    for (var j=0;j+1<b.length;j++) {
      if (_intersects(a[i],a[i+1],b[j],b[j+1])) return true;
    }
  }
  return false;
}

bool _intersects(CorridorPoint a,CorridorPoint b,CorridorPoint c,CorridorPoint d) {
  if (math.max(a.easting,b.easting) < math.min(c.easting,d.easting) ||
      math.max(c.easting,d.easting) < math.min(a.easting,b.easting) ||
      math.max(a.northing,b.northing) < math.min(c.northing,d.northing) ||
      math.max(c.northing,d.northing) < math.min(a.northing,b.northing)) return false;
  int side(CorridorPoint p,CorridorPoint q,CorridorPoint r) =>
    ((q.easting-p.easting)*(r.northing-p.northing)-(q.northing-p.northing)*(r.easting-p.easting)).sign;
  return side(a,b,c)*side(a,b,d) <= 0 && side(c,d,a)*side(c,d,b) <= 0;
}
