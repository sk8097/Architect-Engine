/// Canonical concept geometry. All coordinates are integer millimetres, with
/// north up and the south-west plot corner at (0, 0).
class PlanRect {
  const PlanRect(this.left, this.bottom, this.right, this.top);
  final int left, bottom, right, top;
  int get width => right - left;
  int get depth => top - bottom;
  int get area => width * depth;

  bool contains(PlanRect other) => left <= other.left && bottom <= other.bottom &&
      right >= other.right && top >= other.top;
  bool overlaps(PlanRect other) => left < other.right && right > other.left &&
      bottom < other.top && top > other.bottom;
}

class PlanRoom {
  const PlanRoom(this.id, this.label, this.bounds);
  final String id, label;
  final PlanRect bounds;
}

enum PlanOpeningKind { door, window, loadingDoor }

class PlanOpening {
  const PlanOpening(this.kind, this.bounds, this.from, this.to);
  final PlanOpeningKind kind;
  final PlanRect bounds;
  final String from, to;
}

/// Plan-view stair linework in the same millimetre coordinates as the rooms.
class StairDrawing {
  StairDrawing({required this.roomId, required this.up, required this.risers,
    required this.riseMm, required this.goingMm, required this.floorHeightMm,
    required Iterable<((int, int), (int, int))> strokes}) : strokes = List.unmodifiable(strokes);
  final String roomId;
  final bool up;
  final int risers, goingMm, floorHeightMm;
  final double riseMm;
  final List<((int, int), (int, int))> strokes;
}

class AutomaticFloorPlan {
  AutomaticFloorPlan({required this.plot, required this.footprint,
    required this.facing, this.bedrooms = 1, this.sheetTitle, required Iterable<PlanRoom> rooms,
    required Iterable<PlanRect> walls, required Iterable<PlanOpening> openings,
    Iterable<StairDrawing> stairs = const []})
      : rooms = List.unmodifiable(rooms), walls = List.unmodifiable(walls),
        openings = List.unmodifiable(openings), stairs = List.unmodifiable(stairs);

  static const generatorVersion = 'house-concept-v2';
  static const entry = 'outside';
  final PlanRect plot, footprint;
  final String facing;
  final int bedrooms;
  final String? sheetTitle;
  String get configurationLabel => '$bedrooms BHK';
  final List<PlanRoom> rooms;
  final List<PlanRect> walls;
  final List<PlanOpening> openings;
  final List<StairDrawing> stairs;
}
