import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';

({List<MeasuredZone> zones, String? issue}) dwellingSurfaceParking(
  AutomaticFloorPlan plan, ProjectParking? parking, Map<String, Object> answers,
) {
  ({List<MeasuredZone> zones, String? issue}) block(String message) => (zones: const [], issue: message);
  if (parking == ProjectParking.none) {
    return answers['parking_sqft'] == null ? (zones: const [], issue: null) : block('The saved parking allowance conflicts with No parking.');
  }
  if (parking == null) return block('Choose whether the dwelling needs parking.');
  final arrangement = answers['parking_arrangement'];
  final access = answers['accessibility'];
  if ((arrangement != null && (arrangement is! Iterable || arrangement.any((kind) => kind != 'open'))) ||
      (access is Iterable && access.contains('parking')) ||
      ['bicycles','accessible_bays','ev_bays','loading_bays'].any((key) => (answers[key] is num) && (answers[key] as num) > 0)) {
    return block('Only regular open-surface car and two-wheeler bays are drawn. Covered, structured, accessible, EV and other specialist bays are not generated.');
  }
  if (answers['g1_parking_frontage'] != 'confirmed') {
    return block('Confirm that open parking and full-width vehicle access are permitted in the supplied frontage strip before drawing parking.');
  }
  int? mm(String key, {bool allowZero = false}) {
    final value = answers[key];
    if (value is! num || !value.isFinite || value < 0 || value > 300) return null;
    final rounded = (value * 1000).round();
    return rounded > 0 || allowZero ? rounded : null;
  }
  final wantCars = parking != ProjectParking.twoWheeler;
  final wantBikes = parking != ProjectParking.car;
  final cars = wantCars ? answers['cars'] : 0, bikes = wantBikes ? answers['two_wheelers'] : 0;
  if (cars is! int || bikes is! int || (wantCars && (cars < 1 || cars > 12)) || (wantBikes && (bikes < 1 || bikes > 24))) {
    return block('Enter the requested number of parking bays: 1–12 cars and/or 1–24 two-wheelers.');
  }
  final carW = wantCars ? mm('g1_car_width') : 0, carD = wantCars ? mm('g1_car_depth') : 0;
  final bikeW = wantBikes ? mm('g1_bike_width') : 0, bikeD = wantBikes ? mm('g1_bike_depth') : 0;
  final offset = mm('g1_parking_offset', allowZero: true), apron = mm('g1_parking_apron');
  final path = mm('g1_parking_path'), gap = mm('g1_parking_gap');
  if (carW == null || carD == null || bikeW == null || bikeD == null || offset == null || apron == null || path == null || gap == null) {
    return block('Enter measured bay, vehicle approach, frontage offset, walking path and separation dimensions.');
  }

  // Use plot-local (u,v) axes, u increasing left-to-right as seen from
  // the street, v increasing inland. Plan coordinates are north-up.
  final plot = plan.plot;
  PlanRect rotate(PlanRect b) => switch (plan.facing) {
    'North' => PlanRect(plot.right-b.right, plot.top-b.top, plot.right-b.left, plot.top-b.bottom),
    'East' => PlanRect(plot.right-b.top, plot.bottom+b.left, plot.right-b.bottom, plot.bottom+b.right),
    'West' => PlanRect(plot.left+b.bottom, plot.top-b.right, plot.left+b.top, plot.top-b.left),
    _ => PlanRect(plot.left+b.left, plot.bottom+b.bottom, plot.left+b.right, plot.bottom+b.top),
  };
  final entries = plan.openings.where((o) => o.from == AutomaticFloorPlan.entry && o.kind == PlanOpeningKind.door);
  if (entries.length != 1) return block('Parking needs one ground-floor entrance on the vehicle frontage.');
  final b = entries.single.bounds, footprint = plan.footprint;
  final (doorLeft, doorRight, depth, frontage) = switch (plan.facing) {
    'North' => (plot.right-b.right, plot.right-b.left, plot.top-footprint.top, plot.width),
    'East' => (b.bottom-plot.bottom, b.top-plot.bottom, plot.right-footprint.right, plot.depth),
    'West' => (plot.top-b.top, plot.top-b.bottom, footprint.left-plot.left, plot.depth),
    _ => (b.left-plot.left,b.right-plot.left,footprint.bottom-plot.bottom,plot.width),
  };
  final bankWidth = cars*carW + bikes*bikeW;
  final end = offset + bankWidth;
  final parkingDepth = apron + (carD > bikeD ? carD : bikeD);
  if (end > frontage) return block('Parking bays and their offset exceed the available frontage width.');
  if (parkingDepth > depth) return block('The vehicle approach and deepest bay do not fit between the frontage and house.');
  final pathLeft = (doorLeft + doorRight - path) ~/ 2;
  final pathRight = pathLeft + path;
  if (path < doorRight-doorLeft || pathLeft < 0 || pathRight > frontage) {
    return block('The pedestrian path must fit inside the plot and span the entire front-door opening.');
  }
  if (pathRight + gap > offset && end + gap > pathLeft) {
    return block('Parking and pedestrian approach conflict. Change the vehicle frontage offset or provide more clear frontage for separation.');
  }
  final parkingAreaSqft = (bankWidth * apron + cars * carW * carD + bikes * bikeW * bikeD) / 92903.04;
  final allowance = answers['parking_sqft'];
  if (allowance is! num || !allowance.isFinite || allowance <= 0) return block('Enter the available parking area, including vehicle approach.');
  if (parkingAreaSqft > allowance + .001) {
    return block('Bays and the vehicle approach need ${parkingAreaSqft.toStringAsFixed(1)} sqft, over the supplied parking allowance.');
  }
  final zones = <MeasuredZone>[
    MeasuredZone('vehicle_approach', 'Vehicle approach', rotate(PlanRect(offset,0,end,apron)), 'VEHICLE_APPROACH'),
    MeasuredZone('pedestrian_approach', 'Entry walk', rotate(PlanRect(pathLeft,0,pathRight,depth)), 'PEDESTRIAN_APPROACH'),
  ];
  var x = offset;
  for (final (id, label, count, width, bayDepth) in [('car','Car',cars,carW,carD),('bike','Two-wheeler',bikes,bikeW,bikeD)]) {
    for (var i = 1; i <= count; i++) {
      zones.add(MeasuredZone('${id}_$i', '$label $i', rotate(PlanRect(x,apron,x+width,apron+bayDepth)), 'PARKING_BAYS'));
      x += width;
    }
  }
  for (var i = 0; i < zones.length; i++) {
    final r = zones[i].bounds;
    if (!plot.contains(r) || r.overlaps(footprint) || zones.take(i).any((zone) => zone.bounds.overlaps(r))) {
      return block('The generated approach or bay layout conflicts with the site or house.');
    }
  }
  return (zones: List.unmodifiable(zones), issue: null);
}
