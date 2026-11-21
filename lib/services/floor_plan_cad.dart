import 'dart:math' as math;

import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/survey_corridor.dart';

class CadPoint {
  const CadPoint(this.x, this.y);
  final num x, y;
}

class CadLine {
  const CadLine(this.layer, this.start, this.end);
  final String layer;
  final CadPoint start, end;
}

class CadArc {
  const CadArc(this.layer, this.center, this.radius, this.start, this.end);
  final String layer;
  final CadPoint center;
  final num radius, start, end;
}

class CadLabel {
  const CadLabel(this.layer, this.at, this.text, this.height, {this.angle = 0});
  final String layer, text;
  final CadPoint at;
  final num height, angle;
}

/// One set of drawing entities for the interactive preview and DXF export.
class FloorPlanCad {
  FloorPlanCad.fromPlan(AutomaticFloorPlan plan, {Iterable<MeasuredZone> siteZones = const []}) {
    void line(String layer, num x1, num y1, num x2, num y2) =>
        _lines.add(CadLine(layer, CadPoint(x1, y1), CadPoint(x2, y2)));
    void box(String layer, PlanRect bounds) {
      line(layer, bounds.left, bounds.bottom, bounds.right, bounds.bottom);
      line(layer, bounds.right, bounds.bottom, bounds.right, bounds.top);
      line(layer, bounds.right, bounds.top, bounds.left, bounds.top);
      line(layer, bounds.left, bounds.top, bounds.left, bounds.bottom);
    }
    final plot = plan.plot, building = plan.footprint;
    box('PLOT', plot);
    _wallPerimeter(plan.walls, line);
    for (final zone in siteZones) {
      final b = zone.bounds;
      box(zone.layer, b);
      final x = (b.left + b.right) / 2, y = (b.bottom + b.top) / 2;
      if (zone.direction case final direction?) {
        final (dx,dy) = switch(direction) {
          ZoneDirection.north => (0,1), ZoneDirection.south => (0,-1),
          ZoneDirection.east => (1,0), ZoneDirection.west => (-1,0),
        };
        final length = dx == 0 ? b.depth : b.width, clear = dx == 0 ? b.width : b.depth;
        final head = (clear < length / 10 ? clear : length / 10) / 4;
        line(zone.layer,x-dx*length/2,y-dy*length/2,x+dx*length/2,y+dy*length/2);
        for (final fraction in [-.3,0.0,.3]) {
          final tipX = x+dx*length*fraction, tipY = y+dy*length*fraction;
          for (final side in [-1,1]) {
            line(zone.layer,tipX-dx*head+side*dy*head,tipY-dy*head+side*dx*head,tipX,tipY);
          }
        }
        continue;
      }
      final height = (b.width / ((zone.name.length + 2) * .72)).clamp(1, 350).toDouble();
      _labels.add(CadLabel(zone.layer, CadPoint(x, y + height / 2), zone.name.toUpperCase(), height));
      _labels.add(CadLabel('DIMENSIONS', CadPoint(x, y - height), '${b.width} x ${b.depth}', height * .75));
    }
    final rooms = {for (final room in plan.rooms) room.id: room.bounds};
    for (final opening in plan.openings) {
      final b = opening.bounds;
      final horizontal = b.width > b.depth;
      if (opening.kind == PlanOpeningKind.loadingDoor || opening.kind == PlanOpeningKind.materialOpening) {
        final layer = opening.kind == PlanOpeningKind.loadingDoor ? 'DOCK_OPENINGS' : 'PACKHOUSE_OPENINGS';
        if (horizontal) { line(layer, b.left, (b.bottom + b.top) / 2, b.right, (b.bottom + b.top) / 2); }
        else { line(layer, (b.left + b.right) / 2, b.bottom, (b.left + b.right) / 2, b.top); }
        continue;
      }
      if (opening.kind == PlanOpeningKind.window) {
        for (final fraction in [1 / 3, 2 / 3]) {
          if (horizontal) {
            final y = b.bottom + b.depth * fraction;
            line('WINDOWS', b.left, y, b.right, y);
          } else {
            final x = b.left + b.width * fraction;
            line('WINDOWS', x, b.bottom, x, b.top);
          }
        }
        continue;
      }
      final room = rooms[opening.to]!;
      final layer = opening.to.startsWith('patient_') ? 'PATIENT_ROUTE' :
        opening.from == 'school_arrival_route' && opening.to == 'school_learning_route' ? 'SCHOOL_THRESHOLD' :
        opening.to.startsWith('service_') ? 'SERVICE_ROUTE' : opening.to == 'retail_stock' ? 'RETAIL_SERVICE' : 'DOORS';
      if (horizontal) {
        final inward = room.bottom == b.top ? 1 : -1;
        final y = inward == 1 ? b.top : b.bottom;
        line(layer, b.left, y, b.left, y + inward * b.width);
        _arcs.add(CadArc(layer, CadPoint(b.left, y), b.width,
          inward == 1 ? 0 : 270, inward == 1 ? 90 : 360));
      } else {
        final inward = room.left == b.right ? 1 : -1;
        final x = inward == 1 ? b.right : b.left;
        line(layer, x, b.bottom, x + inward * b.depth, b.bottom);
        _arcs.add(CadArc(layer, CadPoint(x, b.bottom), b.depth,
          inward == 1 ? 0 : 90, inward == 1 ? 90 : 180));
      }
    }
    for (final stair in plan.stairs) {
      for (final (from, to) in stair.strokes) { line('STAIRS', from.$1, from.$2, to.$1, to.$2); }
    }
    for (final room in plan.rooms) {
      final b = room.bounds;
      final center = (b.left + b.right) / 2;
      final y = (b.bottom + b.top) / 2;
      final core = room.id.startsWith('stair_') || room.id.startsWith('lift_') || room.id.startsWith('shaft_');
      final measured = plan.stairs.where((stair) => stair.roomId == room.id).firstOrNull;
      if (core && measured == null) {
        // Reserve marker only; never present invented stair treads or lift equipment.
        final ix = b.width / 10, iy = b.depth / 10;
        line('CORE_RESERVES', b.left + ix, b.bottom + iy, b.right - ix, b.bottom + iy);
        line('CORE_RESERVES', b.left + ix, b.top - iy, b.right - ix, b.top - iy);
      }
      if (measured != null) {
        final vertical = b.depth >= b.width;
        final offset = vertical ? b.width / 3 : b.depth / 3;
        _labels.add(CadLabel('STAIRS', CadPoint(center + (vertical ? offset : 0), y + (vertical ? 0 : offset)),
          '${measured.up ? 'UP' : 'DOWN'} - ${measured.risers} RISERS', 145, angle: vertical ? 90 : 0));
      } else if (const {'patient_internal_passage','service_internal_passage','school_arrival_route','school_learning_route'}.contains(room.id)) {
        final layer = switch (room.id) {
          'patient_internal_passage' => 'PATIENT_ROUTE', 'service_internal_passage' => 'SERVICE_ROUTE',
          'school_arrival_route' => 'SCHOOL_ARRIVAL', _ => 'SCHOOL_LEARNING',
        };
        final vertical = b.heightLongerThanWidth;
        final edge = vertical ? b.left + b.width / 4 : b.bottom + b.depth / 4;
        if (vertical) { line(layer, edge, b.bottom, edge, b.top); }
        else { line(layer, b.left, edge, b.right, edge); }
        _labels.add(CadLabel(layer, CadPoint(center, y), room.label.toUpperCase(), 180, angle: vertical ? 90 : 0));
      } else if (room.id == 'internal_passage' && b.heightLongerThanWidth) {
        _labels.add(CadLabel('ROOM_LABELS', CadPoint(center, y), 'PASSAGE', 180, angle: 90));
      } else {
        _labels.add(CadLabel('ROOM_LABELS', CadPoint(center, y + 120), room.label.toUpperCase(), 180));
        _labels.add(CadLabel('ROOM_LABELS', CadPoint(center, y - 155), '${b.width} x ${b.depth}', 145));
      }
    }

    void horizontalDim(PlanRect b, int y) {
      line('DIMENSIONS', b.left, b.bottom, b.left, y - 90);
      line('DIMENSIONS', b.right, b.bottom, b.right, y - 90);
      line('DIMENSIONS', b.left, y, b.right, y);
      for (final x in [b.left, b.right]) { line('DIMENSIONS', x - 80, y - 80, x + 80, y + 80); }
      _labels.add(CadLabel('DIMENSIONS', CadPoint((b.left + b.right) / 2, y + 125), '${b.width}', 180));
    }
    void verticalDim(PlanRect b, int x) {
      line('DIMENSIONS', b.right, b.bottom, x + 90, b.bottom);
      line('DIMENSIONS', b.right, b.top, x + 90, b.top);
      line('DIMENSIONS', x, b.bottom, x, b.top);
      for (final y in [b.bottom, b.top]) { line('DIMENSIONS', x - 80, y - 80, x + 80, y + 80); }
      _labels.add(CadLabel('DIMENSIONS', CadPoint(x - 125, (b.bottom + b.top) / 2), '${b.depth}', 180, angle: 90));
    }
    // Dimension strings outside the plot: inner stack is building, outer plot.
    horizontalDim(building, plot.bottom - 420);
    horizontalDim(plot, plot.bottom - 980);
    verticalDim(building, plot.right + 420);
    verticalDim(plot, plot.right + 980);
    final arrowX = plot.right + 900;
    final arrowY = plot.top + 450;
    line('ANNOTATIONS', arrowX, arrowY - 350, arrowX, arrowY + 100);
    line('ANNOTATIONS', arrowX, arrowY + 100, arrowX - 100, arrowY - 100);
    line('ANNOTATIONS', arrowX, arrowY + 100, arrowX + 100, arrowY - 100);
    _labels.add(CadLabel('ANNOTATIONS', CadPoint(arrowX, arrowY + 260), 'N', 180));
    _labels.add(CadLabel('ANNOTATIONS', CadPoint(plot.width / 2, plot.top + 440),
      '${plan.sheetTitle ?? plan.configurationLabel} CONCEPT - NOT FOR CONSTRUCTION', 200));
    _labels.add(CadLabel('ANNOTATIONS', CadPoint(plot.width / 2, plot.top + 155),
      'DIMENSIONS IN MILLIMETRES', 140));
    bounds = PlanRect(plot.left - 250, plot.bottom - 1250, plot.right + 1250, plot.top + 920);
  }

  /// Keeps projected grid coordinates in mm; no sheet-set offset is applied.
  FloorPlanCad.fromSurveyCorridor(SurveyCorridorDrawing sheet) {
    CadPoint cad(CorridorPoint p) => CadPoint(p.easting,p.northing);
    void line(String layer, CorridorPoint a, CorridorPoint b) => _lines.add(CadLine(layer,cad(a),cad(b)));
    void trace(String layer, List<CorridorPoint> points) {
      for (var i=0;i+1<points.length;i++) { line(layer,points[i],points[i+1]); }
    }
    final edges = sheet.edges, axis = sheet.stations.map((s)=>s.point).toList();
    trace('SURVEY_AXIS',axis);
    for (var i=0;i<edges.length;i++) {
      // If a band edge is exactly the centreline, it is already on SURVEY_AXIS.
      final edge = edges[i];
      final outer = i==0 || i==edges.length-1;
      if (outer || !List.generate(edge.length,(j)=>edge[j].easting==axis[j].easting && edge[j].northing==axis[j].northing).every((same)=>same)) {
        trace(outer?'RIGHT_OF_WAY':'CORRIDOR_BANDS',edge);
      }
    }
    line('RIGHT_OF_WAY',edges.first.first,edges.last.first);
    line('RIGHT_OF_WAY',edges.first.last,edges.last.last);
    final all = [...edges.first,...edges.last];
    final left = all.map((p)=>p.easting).reduce(math.min), right = all.map((p)=>p.easting).reduce(math.max);
    final bottom = all.map((p)=>p.northing).reduce(math.min), top = all.map((p)=>p.northing).reduce(math.max);
    final gap = (sheet.widthMm/10).clamp(200,1800).toDouble();
    final mid = (left+right)/2;
    _labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(mid,top+gap*3),'${sheet.title} / SURVEY CORRIDOR - CONCEPT ONLY',gap),
      CadLabel('ANNOTATIONS',CadPoint(mid,top+gap*1.8),'${sheet.grid} / ${sheet.reference}',gap*.65),
      CadLabel('ANNOTATIONS',CadPoint(mid,top+gap*.7),'PROJECTED COORDINATES IN MM - NOT FOR CONSTRUCTION',gap*.65),
    ]);
    final arrowX = right+gap*2, arrowY = top+gap*2;
    final tip = CadPoint(arrowX,arrowY+gap), bottomArrow = CadPoint(arrowX,arrowY-gap);
    _lines.addAll([CadLine('ANNOTATIONS',bottomArrow,tip),
      CadLine('ANNOTATIONS',CadPoint(arrowX-gap/3,arrowY+gap/3),tip),
      CadLine('ANNOTATIONS',CadPoint(arrowX+gap/3,arrowY+gap/3),tip)]);
    _labels.add(CadLabel('ANNOTATIONS',CadPoint(arrowX,arrowY+gap*1.5),'GRID N',gap*.65));
    double length(int i) {
      final dx=axis[i+1].easting-axis[i].easting, dy=axis[i+1].northing-axis[i].northing;
      return math.sqrt(dx.toDouble()*dx+dy.toDouble()*dy);
    }
    var longest = 0;
    for (var i=1;i+1<axis.length;i++) { if (length(i)>length(longest)) longest=i; }
    final dx = axis[longest+1].easting-axis[longest].easting, dy = axis[longest+1].northing-axis[longest].northing;
    final bearing = math.atan2(dy,dx)*180/math.pi;
    final upright = bearing > 90 ? bearing-180 : bearing < -90 ? bearing+180 : bearing;
    for (var i=0;i<sheet.bands.length;i++) {
      final band=sheet.bands[i];
      final points=[edges[i][longest],edges[i][longest+1],edges[i+1][longest],edges[i+1][longest+1]];
      final x=points.fold<int>(0,(n,p)=>n+p.easting)/4, y=points.fold<int>(0,(n,p)=>n+p.northing)/4;
      final text = '${band.label} ${(band.widthMm/1000).toStringAsFixed(3)} M';
      final height = math.min(gap*.65,math.min(band.widthMm*.36,length(longest)/(text.length*.85)));
      _labels.add(CadLabel('CORRIDOR_BANDS',CadPoint(x,y),text,height,angle:upright));
    }
    for (var i=0;i<axis.length;i++) {
      final p=axis[i];
      final size=gap*.20;
      _lines.add(CadLine('SURVEY_STATIONS',CadPoint(p.easting-size,p.northing-size),CadPoint(p.easting+size,p.northing+size)));
      _lines.add(CadLine('SURVEY_STATIONS',CadPoint(p.easting-size,p.northing+size),CadPoint(p.easting+size,p.northing-size)));
      _labels.add(CadLabel('SURVEY_STATIONS',CadPoint(p.easting,p.northing+gap*.55),'STA ${sheet.stations[i].label}',gap*.5));
    }
    final labelSpan = math.max(52,(sheet.grid.length+sheet.reference.length+3)*.65)*gap*.31;
    bounds=PlanRect(math.min(left-gap,mid-labelSpan).floor(),(bottom-gap*1.5).floor(),
      math.max(right+gap*4,mid+labelSpan).ceil(),(top+gap*4).ceil());
  }

  FloorPlanCad.fromZoning(ZoningSheet sheet) {
    void line(String layer, num x, num y, num ex, num ey) =>
      _lines.add(CadLine(layer, CadPoint(x, y), CadPoint(ex, ey)));
    void rectangle(String layer, PlanRect box) {
      line(layer, box.left, box.bottom, box.right, box.bottom);
      line(layer, box.right, box.bottom, box.right, box.top);
      line(layer, box.right, box.top, box.left, box.top);
      line(layer, box.left, box.top, box.left, box.bottom);
    }
    void label(String layer, num x, num y, String text, num height, {num angle = 0}) =>
      _labels.add(CadLabel(layer, CadPoint(x, y), text, height, angle: angle));
    final site = sheet.boundary, envelope = sheet.envelope;
    final minSide = site.width < site.depth ? site.width : site.depth;
    final gap = (minSide ~/ 50).clamp(250, 2000).toInt();
    rectangle(sheet.corridor ? 'RIGHT_OF_WAY' : 'PLOT', site);
    if (envelope.left != site.left || envelope.bottom != site.bottom || envelope.right != site.right || envelope.top != site.top) {
      rectangle('PLANNING_ENVELOPE', envelope);
    }
    for (final item in sheet.zones) {
      final box = item.bounds, x = (box.left + box.right) / 2, y = (box.bottom + box.top) / 2;
      final height = (box.width / ((item.name.length + 2) * .72)).clamp(1, box.depth / 5 > 1 ? box.depth / 5 : 1).clamp(1, gap).toDouble();
      rectangle(item.layer, box);
      label('ROOM_LABELS', x, y + height * .65, item.name, height);
      label('DIMENSIONS', x, y - height * .85, '${box.width} x ${box.depth}', height * .75);
    }
    final mid = (site.left + site.right) / 2;
    label('ANNOTATIONS', mid, site.top + gap * 3, '${sheet.title} - CONCEPT ZONING', gap);
    label('ANNOTATIONS', mid, site.top + gap * 1.65, 'NOT FOR CONSTRUCTION - DIMENSIONS IN MM', gap * .65);
    label('ANNOTATIONS', mid, site.top + gap * .6, sheet.axisLabel, gap * .65);
    final y = site.bottom - gap * 1.6, x = site.right + gap * 2;
    line('DIMENSIONS', site.left, site.bottom, site.left, y - gap / 3);
    line('DIMENSIONS', site.right, site.bottom, site.right, y - gap / 3);
    line('DIMENSIONS', site.left, y, site.right, y);
    label('DIMENSIONS', mid, y + gap / 4, '${site.width}', gap * .75);
    line('DIMENSIONS', site.right, site.bottom, x + gap / 3, site.bottom);
    line('DIMENSIONS', site.right, site.top, x + gap / 3, site.top);
    line('DIMENSIONS', x, site.bottom, x, site.top);
    label('DIMENSIONS', x - gap / 4, (site.bottom + site.top) / 2, '${site.depth}', gap * .75, angle: 90);
    if (sheet.corridor) {
      final end = site.width ~/ 1000000;
      final remainder = ((site.width % 1000000) / 1000).toStringAsFixed(3).padLeft(7, '0');
      label('ANNOTATIONS', site.left + gap * 2, y - gap, 'STA 0+000', gap * .8);
      label('ANNOTATIONS', site.right - gap * 2, y - gap, 'STA $end+$remainder', gap * .8);
    }
    bounds = PlanRect(site.left - gap * 3, site.bottom - gap * 4, site.right + gap * 4, site.top + gap * 5);
  }

  /// A single model-space DXF with the indexed sheets laid out in non-overlapping cells.
  /// Per-sheet exports retain their original coordinates.
  factory FloorPlanCad.sheetSet(Iterable<AutomaticFloorPlan> plans) => FloorPlanCad.combined(plans.map(FloorPlanCad.fromPlan));

  FloorPlanCad.combined(Iterable<FloorPlanCad> geometry) {
    final drawings = geometry.toList(growable: false);
    final cellWidth = drawings.fold<int>(0, (n, d) => n > d.bounds.width ? n : d.bounds.width) + 4000;
    final cellDepth = drawings.fold<int>(0, (n, d) => n > d.bounds.depth ? n : d.bounds.depth) + 4000;
    var index = 0, right = 0, bottom = 0;
    for (final sheet in drawings) {
      final dx = (index % 4) * cellWidth - sheet.bounds.left;
      final dy = -(index ~/ 4) * cellDepth - sheet.bounds.top;
      CadPoint offset(CadPoint p) => CadPoint(p.x + dx, p.y + dy);
      _lines.addAll(sheet.lines.map((line) => CadLine(line.layer, offset(line.start), offset(line.end))));
      _arcs.addAll(sheet.arcs.map((arc) => CadArc(arc.layer, offset(arc.center), arc.radius, arc.start, arc.end)));
      _labels.addAll(sheet.labels.map((label) => CadLabel(label.layer, offset(label.at), label.text, label.height, angle: label.angle)));
      final edge = dx + sheet.bounds.right, base = dy + sheet.bounds.bottom;
      if (edge > right) right = edge;
      if (base < bottom) bottom = base;
      index++;
    }
    bounds = PlanRect(0, bottom, right, 0);
  }

  late final PlanRect bounds;
  final _lines = <CadLine>[];
  final _arcs = <CadArc>[];
  final _labels = <CadLabel>[];
  Iterable<CadLine> get lines => _lines;
  Iterable<CadArc> get arcs => _arcs;
  Iterable<CadLabel> get labels => _labels;

  /// Remove shared segment seams between adjacent wall rectangles but leave
  /// door/window gaps. Parity cancels edges where two solids touch.
  static void _wallPerimeter(Iterable<PlanRect> walls,
      void Function(String, num, num, num, num) line) {
    final horizontal = <int, List<int>>{}, vertical = <int, List<int>>{};
    void add(Map<int, List<int>> groups, int fixed, int lo, int hi) =>
        groups.putIfAbsent(fixed, () => []).addAll([lo, hi]);
    for (final b in walls) {
      add(horizontal, b.bottom, b.left, b.right);
      add(horizontal, b.top, b.left, b.right);
      add(vertical, b.left, b.bottom, b.top);
      add(vertical, b.right, b.bottom, b.top);
    }
    void emit(Map<int, List<int>> groups, bool isHorizontal) {
      for (final group in groups.entries) {
        final events = group.value..sort();
        int? start;
        var i = 0;
        while (i < events.length) {
          final position = events[i];
          var count = 0;
          while (i < events.length && events[i] == position) { i++; count++; }
          if (count.isEven) continue;
          if (start == null) {
            start = position;
          } else {
            final fixed = group.key;
            if (isHorizontal) { line('WALLS', start, fixed, position, fixed); }
            else { line('WALLS', fixed, start, fixed, position); }
            start = null;
          }
        }
      }
    }
    emit(horizontal, true);
    emit(vertical, false);
  }

  /// AutoCAD R12 ASCII; one drawing unit is one millimetre. R12 does not use
  /// $INSUNITS, so the sheet explicitly labels its units.
  String toDxf() {
    final output = StringBuffer();
    void pair(int code, Object value) => output.write('$code\r\n$value\r\n');
    String number(num value) => value.toStringAsFixed(3);
    void xyz(int code, CadPoint p) {
      pair(code, number(p.x)); pair(code + 10, number(p.y)); pair(code + 20, '0.0');
    }
    const layers = {'0': 7, 'PLOT': 8, 'WALLS': 7, 'DOORS': 3, 'WINDOWS': 5,
      'ROOM_LABELS': 7, 'DIMENSIONS': 6, 'ANNOTATIONS': 7, 'CORE_RESERVES': 8, 'RIGHT_OF_WAY': 8, 'PLANNING_ENVELOPE': 6,
      'ZONES_PUBLIC': 4, 'ZONES_SERVICE': 2, 'ZONES_PROGRAM': 7, 'CORRIDOR_BANDS': 3, 'VEHICLE_ROUTE': 2, 'WALK_ROUTE': 3, 'DOCK_BAYS': 4,
      'DOCK_OPENINGS': 1, 'WAREHOUSE_MARKINGS': 8, 'PATIENT_ROUTE': 4, 'SERVICE_ROUTE': 2, 'CUSTOMER_ROUTE': 4, 'RETAIL_DISPLAY': 8,
      'RETAIL_QUEUE': 2, 'RETAIL_CHECKOUT': 6, 'RETAIL_SERVICE': 3, 'STAIRS': 5, 'PARKING_BAYS': 4, 'VEHICLE_APPROACH': 6, 'PEDESTRIAN_APPROACH': 3,
      'SCHOOL_ARRIVAL': 30, 'SCHOOL_LEARNING': 5, 'SCHOOL_THRESHOLD': 6, 'SCHOOL_ENTRY_WALK': 30,
      'MIXED_SHOP_ACCESS': 30, 'MIXED_HOME_ACCESS': 3, 'MIXED_DIVIDER': 6,
      'PACKHOUSE_PADS': 30, 'PACKHOUSE_OPENINGS': 6, 'PACKHOUSE_FLOW': 3, 'SURVEY_AXIS': 4, 'SURVEY_STATIONS': 6};
    pair(0, 'SECTION'); pair(2, 'HEADER');
    pair(9, r'$ACADVER'); pair(1, 'AC1009');
    pair(9, r'$LUNITS'); pair(70, 2);
    pair(0, 'ENDSEC');
    pair(0, 'SECTION'); pair(2, 'TABLES');
    pair(0, 'TABLE'); pair(2, 'LTYPE'); pair(70, 1);
    pair(0, 'LTYPE'); pair(2, 'CONTINUOUS'); pair(70, 0);
    pair(3, 'Solid line'); pair(72, 65); pair(73, 0); pair(40, '0.0'); pair(0, 'ENDTAB');
    pair(0, 'TABLE'); pair(2, 'LAYER'); pair(70, layers.length);
    for (final layer in layers.entries) {
      pair(0, 'LAYER'); pair(2, layer.key); pair(70, 0); pair(62, layer.value); pair(6, 'CONTINUOUS');
    }
    pair(0, 'ENDTAB'); pair(0, 'ENDSEC');
    pair(0, 'SECTION'); pair(2, 'ENTITIES');
    for (final line in _lines) {
      pair(0, 'LINE'); pair(8, line.layer); xyz(10, line.start); xyz(11, line.end);
    }
    for (final arc in _arcs) {
      pair(0, 'ARC'); pair(8, arc.layer); xyz(10, arc.center);
      pair(40, number(arc.radius)); pair(50, number(arc.start)); pair(51, number(arc.end));
    }
    for (final label in _labels) {
      pair(0, 'TEXT'); pair(8, label.layer); xyz(10, label.at);
      pair(40, number(label.height));
      pair(1, label.text.replaceAll(RegExp(r'[^\x20-\x7e]'), '?'));
      pair(50, number(label.angle)); pair(72, 1); xyz(11, label.at);
    }
    pair(0, 'ENDSEC'); pair(0, 'EOF');
    return output.toString();
  }
}

extension on PlanRect {
  bool get heightLongerThanWidth => depth > width;
}
