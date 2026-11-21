import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/warehouse_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanPartition;

class WarehouseLoadingResult {
  const WarehouseLoadingResult(this.plan, this.zones, this.issue);
  final AutomaticFloorPlan? plan;
  final List<MeasuredZone> zones;
  final String? issue;
}

/// Geometry for a one-sided dock bank and separate staff approach. A reserved
/// manoeuvring rectangle is not a driven vehicle trajectory or a swept path.
class WarehouseLoadingGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'warehouse_loading';

  WarehouseLoadingResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    WarehouseLoadingResult stop(String message) => WarehouseLoadingResult(null, const [], message);
    final selection = brief.taxonomy;
    final requirements = brief.requirements;
    if (selection == null || requirements == null || selection.version != projectTaxonomyVersion || requirements.version != requirementsSchemaVersion) {
      return stop('Save a warehouse brief with the current requirements.');
    }
    if (selection.categoryId != 'industrial' || selection.subcategoryId != 'logistics' || !warehouseLoadingTypes.contains(selection.typeId)) {
      return stop('This is a single-sided loading template for supported warehouse types; it is not a cross-dock, campus or specialist-storage layout.');
    }
    if (!const {'rectangular','square'}.contains(selection.plotShapeId) || !const {'North','South','East','West'}.contains(facing)) {
      return stop('Select a measured rectangular or square plot and the cardinal vehicle frontage.');
    }
    final a = requirements.answers;
    if (brief.floorCount != 1 || (a['building_count'] as num? ?? 1) != 1 || (a['basements'] as num? ?? 0) > 0 || (a['mezzanines'] as num? ?? 0) > 0) {
      return stop('The loading layout is for one ground-floor shell without a basement or mezzanine.');
    }
    if (selection.actionId != null && !const {'concept_design','new_design','feasibility'}.contains(selection.actionId) ||
        const {'existing','partial_demolition','brownfield'}.contains(a['build_status']) ||
        const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) {
      return stop('This loading layout is for a new concept. Existing structures and approval drawings need a surveyed design.');
    }
    final mode = a['dock_type'];
    if (mode is Iterable && mode.any(const {'cross','trailers','canopy','weighbridge','gatehouse'}.contains)) {
      return stop('Cross-dock, trailer storage, canopy, weighbridge or gatehouse details are not modelled by this single-sided loading layout.');
    }
    if ((brief.parking != null && brief.parking != ProjectParking.none) || a['terrace_needed'] == 'yes' || selection.spaceQuantities.isNotEmpty) {
      return stop('This specialised drawing includes only the measured shell, docks, staging, storage and routes. Additional spaces, parking or terrace must be handled in a separate design.');
    }
    int? metres(Object? value, {bool zero = false}) {
      if (value is! num || !value.isFinite || value < 0 || value > 500) return null;
      final n = (value * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final plotW = metres(widthFt * .3048), plotD = metres(depthFt * .3048);
    if (plotW == null || plotD == null || (selection.plotShapeId == 'square' && plotW != plotD)) return stop('Enter valid measured plot dimensions, up to 500 m per side.');
    final dimensions = <String, int>{};
    for (final field in warehouseLoadingFields.where((f) => f.kind == RequirementKind.decimal)) {
      final size = metres(a[field.id]);
      if (size == null) return stop('Enter ${field.label.toLowerCase()} in metres.');
      dimensions[field.id] = size;
    }
    int size(String key) => dimensions['wh_$key']!;
    final count = a['dock_count'];
    if (count is! int || count < 1 || count > 30) return stop('Enter a dock count between 1 and 30.');
    if (a['wh_vehicle_basis'] is! String || (a['wh_vehicle_basis'] as String).trim().isEmpty) return stop('Enter the vehicle and source of the clearance dimensions.');
    final setbacks = <String, int>{};
    for (final side in ['front','rear','left','right']) {
      final value = a['${side}_setback'];
      final inset = value == null ? 0 : metres(value, zero: true);
      if (inset == null) return stop('Invalid $side setback.');
      setbacks[side] = inset;
    }
    final staffW = size('staff_width'), t = size('wall'), doorW = size('staff_door');
    final shellW = size('width'), shellD = size('depth'), apronD = size('apron_depth');
    final bayW = size('bay_width'), bayD = size('bay_depth'), dockW = size('dock_opening');
    final driveW = size('drive_width'), stageD = size('staging_depth');
    final x = setbacks['left']! + staffW, yApron = setbacks['front']! + size('access_depth');
    final yBay = yApron + apronD, y = yBay + bayD;
    final r = x + shellW, top = y + shellD;
    if (r > plotW - setbacks['right']! || top > plotD - setbacks['rear']!) {
      return stop('The shell, approach, apron and dock bays exceed the measured envelope. They need ${(r / 1000).toStringAsFixed(2)} m from the left and ${(top / 1000).toStringAsFixed(2)} m from frontage before right/rear setbacks.');
    }
    final yardLeft = x + t + staffW;
    final yardWidth = r - yardLeft;
    if (size('apron_width') > yardWidth || driveW > yardWidth) return stop('The supplied manoeuvring reserve or vehicle lane is wider than the loading yard.');
    final coverage = a['coverage_limit'], fsi = a['fsi_limit'];
    if (coverage is num && shellW * shellD > plotW * plotD * coverage / 100) return stop('The shell exceeds supplied plot coverage.');
    if (fsi is num && shellW * shellD > plotW * plotD * fsi) return stop('The shell exceeds the supplied FAR/FSI limit.');
    final ix = x + t, ir = r - t, iy = y + t, it = top - t;
    final startDocking = ix + staffW;
    final available = ir - startDocking;
    if (available < bayW * count || bayW - dockW < t || dockW <= t) return stop('Dock bays and their openings do not fit the clear loading frontage after reserving the staff aisle.');
    if (doorW >= staffW || doorW <= t || it - iy <= doorW || stageD >= it - iy) {
      return stop('The staff door swing or staging depth does not leave usable internal space.');
    }
    final doorBottom = iy + (it - iy - doorW) ~/ 2, doorTop = doorBottom + doorW;
    final staffOutside = PlanRect(x - staffW, 0, x, doorTop);
    final vehicleX = yardLeft + (yardWidth - driveW) ~/ 2;
    final apron = PlanRect(yardLeft, yApron, r, yBay);
    final vehicle = PlanRect(vehicleX, 0, vehicleX + driveW, yApron);
    final stage = PlanRect(startDocking, iy, ir, iy + stageD);
    final storage = PlanRect(startDocking, iy + stageD, ir, it);
    final zones = <MeasuredZone>[
      MeasuredZone('vehicle', 'Vehicle approach', vehicle, 'VEHICLE_ROUTE'),
      MeasuredZone('apron', 'Vehicle manoeuvring reserve', apron, 'VEHICLE_ROUTE'),
      MeasuredZone('staff', 'Separate staff approach', staffOutside, 'WALK_ROUTE'),
      MeasuredZone('staging_line', 'Staging', stage, 'WAREHOUSE_MARKINGS'),
      MeasuredZone('storage_line', 'Storage', storage, 'WAREHOUSE_MARKINGS'),
    ];
    bool sharesEdge(PlanRect p, PlanRect q) =>
      ((p.left == q.right || q.left == p.right) && p.bottom < q.top && q.bottom < p.top) ||
      ((p.bottom == q.top || q.bottom == p.top) && p.left < q.right && q.left < p.right);
    final walls = <PlanRect>[];
    void wall(int l, int b, int rr, int tt) { if (l < rr && b < tt) walls.add(PlanRect(l,b,rr,tt)); }
    final staffDoor = PlanRect(x, doorBottom, ix, doorTop);
    final staffInside = PlanRect(ix, iy, startDocking, it);
    final openings = [const _OpeningSpec('staff_aisle', PlanOpeningKind.door).at(staffDoor)];
    wall(x, y, ix, doorBottom);
    wall(x, doorTop, ix, top);
    wall(ir, y, r, top);
    wall(ix, it, ir, top);
    final bayStart = startDocking + (available - bayW * count) ~/ 2;
    var cursor = ix;
    for (var i = 0; i < count; i++) {
      final bx = bayStart + i * bayW;
      final bay = PlanRect(bx, yBay, bx + bayW, y);
      final dx = bx + (bayW - dockW) ~/ 2;
      final gap = PlanRect(dx, y, dx + dockW, iy);
      if (!sharesEdge(apron,bay) || !sharesEdge(bay,gap) || !sharesEdge(gap,stage)) return stop('Dock ${i + 1} is disconnected from yard or staging.');
      wall(cursor, y, dx, iy);
      cursor = dx + dockW;
      openings.add(const _OpeningSpec('staging', PlanOpeningKind.loadingDoor).at(gap));
      zones.add(MeasuredZone('bay_$i', 'Dock bay ${i+1}', bay, 'DOCK_BAYS'));
    }
    wall(cursor, y, ir, iy);
    if (!sharesEdge(vehicle,apron) || !sharesEdge(staffOutside,staffDoor) || !sharesEdge(staffDoor,staffInside) || !sharesEdge(stage,storage) ||
        zones.where((z) => z.layer == 'VEHICLE_ROUTE' || z.layer == 'DOCK_BAYS').any((z) => z.bounds.overlaps(staffOutside))) {
      return stop('The vehicle or staff approach is disconnected or crosses the other approach.');
    }
    final plot = PlanRect(0, 0, plotW, plotD);
    if (zones.any((zone) => !plot.contains(zone.bounds))) return stop('A vehicle, staff or loading zone falls outside the plot.');
    PlanRect orient(PlanRect b) => switch (facing) {
      'North' => PlanRect(plotW-b.right, plotD-b.top, plotW-b.left, plotD-b.bottom),
      'East' => PlanRect(plotD-b.top, b.left, plotD-b.bottom, b.right),
      'West' => PlanRect(b.bottom, plotW-b.right, b.top, plotW-b.left),
      _ => b,
    };
    final rotated = facing == 'East' || facing == 'West';
    final title = taxonomyChoice(taxonomyGroup(taxonomyCategory('industrial'), 'logistics')!.types, selection.typeId)!.label;
    final plan = AutomaticFloorPlan(plot: rotated ? PlanRect(0,0,plotD,plotW) : plot,
      footprint: orient(PlanRect(x,y,r,top)), facing: facing, sheetTitle: '$title / LOADING', rooms: [
        PlanRoom('staff_aisle','Marked staff aisle',orient(staffInside)),
        PlanRoom('staging','Goods staging',orient(stage)), PlanRoom('storage','Storage floor',orient(storage)),
      ], walls: walls.map(orient), openings: openings.map((o) => PlanOpening(o.kind,orient(o.bounds),o.from,o.to)));
    final issue = validatePlanPartition(plan);
    if (issue != null) return stop('The generated shell failed validation: $issue');
    return WarehouseLoadingResult(plan, List.unmodifiable(zones.map((z) => MeasuredZone(z.id,z.name,orient(z.bounds),z.layer))), null);
  }
}

class _OpeningSpec {
  const _OpeningSpec(this.room, this.kind);
  final String room;
  final PlanOpeningKind kind;
  PlanOpening at(PlanRect gap) => PlanOpening(kind, gap, AutomaticFloorPlan.entry, room);
}
