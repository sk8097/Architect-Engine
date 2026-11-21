import 'automatic_floor_plan.dart';

class MeasuredZone {
  const MeasuredZone(this.id, this.name, this.bounds, this.layer);
  final String id, name, layer;
  final PlanRect bounds;
}

class ZoningSheet {
  ZoningSheet({required this.title, required this.envelope, required this.boundary,
    required this.axisLabel, this.corridor = false, Iterable<MeasuredZone> zones = const []})
    : zones = List.unmodifiable(zones);
  final String title, axisLabel;
  final PlanRect envelope, boundary;
  final bool corridor;
  final List<MeasuredZone> zones;
  int get allocated => zones.fold(0, (sum, zone) => sum + zone.bounds.area);
}
