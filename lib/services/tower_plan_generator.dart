import '../models/automatic_floor_plan.dart';
import '../models/tower_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;

class TowerSheet {
  const TowerSheet(this.name, this.range, this.first, this.last, this.plan, this.unallocated);
  final String name, range;
  final int first, last, unallocated;
  final AutomaticFloorPlan plan;
  int get available => plan.footprint.area;
  int get planned => available - unallocated;
}

class TowerResult {
  const TowerResult(this.sheets, this.issues);
  final List<TowerSheet> sheets;
  final List<String> issues;
}

/// User-supplied straight flight and identical end landings. Riser height is
/// derived from the supplied floor-to-floor height, not from a code default.
class StraightStairSpec {
  const StraightStairSpec({required this.risers, required this.going, required this.landing, required this.height});
  final int risers, going, landing, height;
  int get run => (risers - 1) * going;
  int get depth => run + 2 * landing;
}

/// Fixed rectangular plate, single straight circulation spine, two room lanes.
/// This is space planning using supplied assumptions, not a structural solver.
class TowerPlanGenerator {
  static const maxDimension = 300000;
  static const maxSpaces = 24;
  static const maxCoreSpaces = 12;
  static const maxLevels = 100;

  TowerResult generate(TowerBrief input) => _generate(input);

  TowerResult generateDwelling(TowerBrief input, StraightStairSpec stair) => _generate(input, stair: stair);

  TowerResult _generate(TowerBrief input, {StraightStairSpec? stair}) {
    TowerResult block(String message) => TowerResult(const [], [message]);
    bool valid(int n) => n > 0 && n <= maxDimension;
    if (input.floors < 2 || input.floors > maxLevels) return block('Enter 2 to 100 levels, including ground.');
    if (![input.plotWidth, input.plotDepth, input.plateWidth, input.plateDepth,
        input.wall, input.corridor, input.door].every(valid)) return block('Enter positive site, plate and circulation dimensions. Maximum dimension: 300 m.');
    if (input.basis.trim().isEmpty) return block('Enter the source of the core and circulation dimensions.');
    if (!const {'South', 'North', 'East', 'West'}.contains(input.frontage)) return block('Select the ground-floor entry side.');
    final plate = PlanRect(input.westOffset, input.southOffset,
      input.westOffset + input.plateWidth, input.southOffset + input.plateDepth);
    final plot = PlanRect(0, 0, input.plotWidth, input.plotDepth);
    if (!plot.contains(plate)) return block('The plate and offsets put part of the building outside the plot.');
    if (stair == null && (input.stairs.isEmpty || input.lifts.isEmpty || input.shafts.isEmpty)) {
      return block('Supply at least one stair, lift and service-shaft reserve. These are not code minima.');
    }
    if (stair != null && (input.floors != 2 || input.stairs.length != 1 || input.lifts.isNotEmpty || input.shafts.isNotEmpty ||
        stair.risers < 2 || stair.risers > 50 || stair.going <= 0 || stair.landing < input.door || stair.height <= 0 ||
        input.stairs.single.depth != stair.depth || input.stairs.single.width <= input.door)) {
      return block('The dwelling plan needs two levels and one measured straight flight. The stair and each landing must fit the supplied door swing.');
    }
    if (input.stairs.length + input.lifts.length + input.shafts.length > maxCoreSpaces) return block('Use up to $maxCoreSpaces core reserves in this planner.');
    if (input.groups.isEmpty || input.groups.length > input.floors) return block('Add floor groups covering every level.');
    final groups = [...input.groups]..sort((a, b) => a.first.compareTo(b.first));
    var expected = 1;
    for (final group in groups) {
      if (group.name.trim().isEmpty || group.first < 1 || group.last < group.first || group.last > input.floors) return block('Correct the name or level range for ${group.name.isEmpty ? 'an unnamed group' : group.name}.');
      if (group.first < expected) return block('Level ${group.first} is assigned more than once. Correct the range for ${group.name}.');
      if (group.first > expected) return block('Level $expected is not assigned to a floor group.');
      if (group.spaces.isEmpty || group.spaces.length > maxSpaces) return block('${group.name}: supply 1 to $maxSpaces room or zone entries.');
      expected = group.last + 1;
    }
    if (expected <= input.floors) return block('Level $expected is not assigned to a floor group.');
    final rotated = input.frontage == 'East' || input.frontage == 'West';
    final w = rotated ? plate.depth : plate.width;
    final d = rotated ? plate.width : plate.depth;
    final t = input.wall;
    final passage = input.corridor;
    if (passage <= input.door || d - 2 * t <= input.door) return block('The entry opening and swing must fit inside the circulation spine.');
    final left = (w - 4 * t - passage) ~/ 2;
    final right = w - 4 * t - passage - left;
    final capacity = d - t; // cost is room depth plus separator; final separator may abut exterior
    if (left <= 0 || right <= 0) return block('The plate is too narrow for the supplied walls and circulation spine.');
    final core = [
      for (var i = 0; i < input.stairs.length; i++) (id: 'stair_$i', space: input.stairs[i], sealed: false),
      for (var i = 0; i < input.lifts.length; i++) (id: 'lift_$i', space: input.lifts[i], sealed: false),
      for (var i = 0; i < input.shafts.length; i++) (id: 'shaft_$i', space: input.shafts[i], sealed: true),
    ];
    bool widthFits(TowerSpace space, int lane) {
      if (stair == null) return space.width <= lane;
      final extra = lane - space.width;
      return (extra == 0 || extra >= t) && (space.window == null || extra == 0);
    }
    String? check(TowerSpace space, bool sealed) {
      if (space.name.trim().isEmpty || !valid(space.width) || !valid(space.depth)) return 'Enter a space name and valid dimensions.';
      if ((!widthFits(space, left) && !widthFits(space, right)) || (!sealed && (right <= input.door || (stair != null && space.width <= input.door)))) return '${space.name}: clear width or door swing exceeds both available room lanes.';
      if ((!sealed && space.depth <= input.door) || space.depth > d - 2 * t) return '${space.name}: depth does not fit the door opening or plate.';
      if (space.window != null && (space.window! <= t || space.window! >= space.depth)) return '${space.name}: window width must exceed the wall thickness and be less than the room depth.';
      return null;
    }
    if (input.door <= t) return block('Opening width must be larger than wall thickness for this drawing model.');
    for (final space in core) {
      final reason = check(space.space, space.sealed);
      if (reason != null) return block('Common core: $reason');
    }
    const maxSearchStates = 32000;
    List<bool>? pack(List<({String id, TowerSpace space, bool sealed})> items, int capLeft, int capRight) {
      final total = items.fold(0, (sum, item) => sum + item.space.depth + t);
      if (total > capLeft + capRight) return null;
      var states = <int, int>{0: 0}; // depth on left -> bit mask of left items
      var prefix = 0;
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final cost = item.space.depth + t;
        prefix += cost;
        final canLeft = widthFits(item.space, left) && (item.sealed || left > input.door);
        final canRight = widthFits(item.space, right) && (item.sealed || right > input.door);
        final next = <int, int>{};
        for (final state in states.entries) {
          if (canRight && prefix - state.key <= capRight) next[state.key] = state.value;
          if (canLeft && state.key + cost <= capLeft) next[state.key + cost] = state.value | (1 << i);
          if (next.length > maxSearchStates) return null;
        }
        if (next.isEmpty) return null;
        states = next;
      }
      final selected = states.entries.reduce((a, b) =>
        (a.key * 2 - total).abs() <= (b.key * 2 - total).abs() ? a : b).value;
      return [for (var i = 0; i < items.length; i++) (selected & (1 << i)) != 0];
    }
    final assignedCore = pack(core, capacity, capacity);
    if (assignedCore == null) return block('The common core could not fit in the two available lanes. Check the supplied core and plate dimensions.');
    var usedLeft = 0, usedRight = 0;
    for (var i = 0; i < core.length; i++) {
      if (assignedCore[i]) { usedLeft += core[i].space.depth + t; }
      else { usedRight += core[i].space.depth + t; }
    }
    final sheets = <TowerSheet>[];
    for (final group in groups) {
      for (final space in group.spaces) {
        final reason = check(space, false);
        if (reason != null) return block('${group.name}: $reason');
      }
      final rooms = [for (var i = 0; i < group.spaces.length; i++) (id: 'room_$i', space: group.spaces[i], sealed: false)];
      final assignment = pack(rooms, capacity - usedLeft, capacity - usedRight);
      if (assignment == null) return block('${group.name} (${group.range}): requested depths could not be arranged around the fixed core. Check lane width and depth; this does not prove that all layouts are infeasible.');
      final placements = [...core, ...rooms];
      final sides = [...assignedCore, ...assignment];
      void addSheet(int first, int last, bool ground) {
        final range = stair != null ? (ground ? 'Ground floor' : 'First floor') :
          ground ? 'Ground (Level 1)' : first == last ? 'Level $first' : 'Levels $first-$last';
        final result = _layout(input, plot, plate, w, d, left, right, placements, sides,
          ground, '${group.name} / $range', exactWidths: stair != null, stair: stair);
        sheets.add(TowerSheet(group.name, range, first, last, result.plan, result.unallocated));
      }
      if (group.first == 1) addSheet(1, 1, true);
      if (group.last > 1) addSheet(group.first == 1 ? 2 : group.first, group.last, false);
    }
    for (final sheet in sheets) {
      final issue = validatePlanGeometry(sheet.plan,
        indoorSeed: sheet.first == 1 ? null : 'internal_passage',
        sealedRooms: sheet.plan.rooms.where((room) => room.id.startsWith('shaft_') || room.id.startsWith('reserve_')).map((r) => r.id).toSet());
      if (issue != null) return block('${sheet.range}: drawing failed geometry validation. $issue');
    }
    return TowerResult(List.unmodifiable(sheets), const []);
  }

  /// Shared detailed single-storey layout. No core or floor is invented.
  TowerResult generateEnclosed(TowerBrief shell, List<({String id, TowerSpace space, bool sealed})> items, {
    required bool exactWidths,
    required bool Function(AutomaticFloorPlan) accepts,
  }) {
    TowerResult block(String issue) => TowerResult(const [], [issue]);
    final plot = PlanRect(0, 0, shell.plotWidth, shell.plotDepth);
    final plate = PlanRect(shell.westOffset, shell.southOffset,
      shell.westOffset + shell.plateWidth, shell.southOffset + shell.plateDepth);
    if (!plot.contains(plate) || shell.plateWidth < 1 || shell.plateDepth < 1) return block('The building footprint exceeds the measured plot.');
    if (!const {'South','North','East','West'}.contains(shell.frontage)) return block('Select a cardinal entrance side.');
    final rotated = shell.frontage == 'East' || shell.frontage == 'West';
    final w = rotated ? plate.depth : plate.width, d = rotated ? plate.width : plate.depth, t = shell.wall;
    final corridor = shell.corridor, door = shell.door;
    final left = (w - 4 * t - corridor) ~/ 2, right = w - 4 * t - corridor - left;
    if (t <= 0 || door <= t || corridor <= door || d - 2 * t <= door || left <= door || right <= door) {
      return block('The supplied plate, wall, corridor and door dimensions do not leave room for the circulation spine and door swings.');
    }
    if (items.isEmpty || items.length > maxSpaces) return block('Add 1 to $maxSpaces dimensioned enclosed rooms.');
    final capacity = d - t;
    bool fits(TowerSpace space, int lane) {
      final spare = lane - space.width;
      return spare >= 0 && (!exactWidths || (spare == 0 || spare >= t)) &&
        (!exactWidths || space.window == null || spare == 0);
    }
    for (final item in items) {
      final s = item.space;
      if (s.width <= door || s.depth <= door || s.depth > d - 2 * t) {
        return block('${s.name}: its clear dimensions do not fit the supplied door swing or floor plate.');
      }
      if (s.window != null && (s.window! <= t || s.window! >= s.depth)) {
        return block('${s.name}: the window width must exceed the wall thickness and be smaller than the clear room depth.');
      }
      if (!fits(s, left) && !fits(s, right)) return block('${s.name}: its clear width or exterior window does not fit either room lane. A window in exact-width mode needs a room spanning its lane.');
    }
    if (items.fold(0, (sum, item) => sum + item.space.depth + t) > 2 * capacity) {
      return block('The total room depths and partitions exceed the available depth in both lanes.');
    }
    final sides = List<bool>.filled(items.length, false);
    TowerSheet? match;
    var visits = 0;
    bool arrange(int i, int remainingLeft, int remainingRight) {
      if (++visits > 12000) return false;
      if (i == items.length) {
        final output = _layout(shell, plot, plate, w, d, left, right, items, sides, true,
          '${shell.groups.first.name} / GROUND', exactWidths: exactWidths);
        if (!accepts(output.plan)) return false;
        final reserves = output.plan.rooms.where((r) => r.id.startsWith('reserve_')).map((r) => r.id).toSet();
        if (validatePlanGeometry(output.plan, sealedRooms: reserves) != null) return false;
        match = TowerSheet(shell.groups.first.name, 'Ground', 1, 1, output.plan, output.unallocated);
        return true;
      }
      final s = items[i].space, used = items[i].space.depth + t;
      for (final useLeft in [remainingLeft >= remainingRight, remainingLeft < remainingRight]) {
        if (useLeft) {
          if (!fits(s, left) || used > remainingLeft) continue;
          sides[i] = true;
          if (arrange(i + 1, remainingLeft - used, remainingRight)) return true;
        } else {
          if (!fits(s, right) || used > remainingRight) continue;
          sides[i] = false;
          if (arrange(i + 1, remainingLeft, remainingRight - used)) return true;
        }
      }
      return false;
    }
    arrange(0, capacity, capacity);
    return match == null ? block('No supported corridor arrangement satisfies all room dimensions, edges and relationships. This is not a proof that the site cannot be designed.') : TowerResult([match!], const []);
  }

  ({AutomaticFloorPlan plan, int unallocated}) _layout(TowerBrief input, PlanRect plot,
      PlanRect plate, int w, int d, int left, int right,
      List<({String id, TowerSpace space, bool sealed})> items, List<bool> leftSide, bool ground, String title, {bool exactWidths = false, StraightStairSpec? stair}) {
    final t = input.wall;
    final corridor = input.corridor;
    final door = input.door;
    final cx = 2 * t + left, ce = cx + corridor;
    final innerTop = d - t;
    const hall = 'internal_passage';
    const outside = AutomaticFloorPlan.entry;
    final walls = <PlanRect>[];
    final openings = <PlanOpening>[];
    final rooms = <PlanRoom>[PlanRoom(hall, 'Shared circulation', PlanRect(cx, t, ce, innerTop))];
    void wall(int x1, int y1, int x2, int y2) {
      if (x1 < x2 && y1 < y2) walls.add(PlanRect(x1, y1, x2, y2));
    }
    wall(0, innerTop, w, d);
    if (ground) {
      final dx = cx + (corridor - door) ~/ 2;
      wall(0, 0, dx, t); wall(dx + door, 0, w, t);
      openings.add(PlanOpening(PlanOpeningKind.door, PlanRect(dx, 0, dx + door, t), outside, hall));
    } else {
      wall(0, 0, w, t);
    }
    var unused = 0;
    PlanRect? stairRoom;
    for (final side in [true, false]) {
      final x1 = side ? t : ce + t;
      final x2 = side ? t + left : ce + t + right;
      final wx1 = side ? x2 : ce;
      final wx2 = wx1 + t;
      final ex1 = side ? 0 : w - t;
      final ex2 = ex1 + t;
      var y = t;
      for (var i = 0; i < items.length; i++) {
        if (leftSide[i] != side) continue;
        final item = items[i];
        final end = y + item.space.depth;
        final prefix = item.id.startsWith('stair_') ? 'Stair: ' : item.id.startsWith('lift_') ? 'Lift: '
          : item.id.startsWith('shaft_') ? 'Shaft: ' : '';
        final roomLeft = exactWidths && side ? x2 - item.space.width : x1;
        final roomRight = exactWidths && !side ? x1 + item.space.width : x2;
        final straight = stair != null && item.id == 'stair_0' ? stair : null;
        final bounds = PlanRect(roomLeft, y, roomRight, end);
        if (straight != null) stairRoom = bounds;
        rooms.add(PlanRoom(item.id, straight == null ? '$prefix${item.space.name}' : 'Straight stair', bounds));
        if (roomLeft > x1 || roomRight < x2) {
          final divider = side ? roomLeft - t : roomRight;
          wall(divider, y, divider + t, end);
          final residual = side ? PlanRect(x1, y, divider, end) : PlanRect(divider + t, y, x2, end);
          if (residual.width > 0) {
            unused += residual.area;
            rooms.add(PlanRoom('reserve_width_$i', 'Unallocated space', residual));
          }
        }
        if (item.sealed) {
          wall(wx1, y, wx2, end);
        } else {
          final dy = straight == null ? y + (item.space.depth - door) ~/ 2 :
            (ground ? y : end - straight.landing) + (straight.landing - door) ~/ 2;
          wall(wx1, y, wx2, dy); wall(wx1, dy + door, wx2, end);
          openings.add(PlanOpening(PlanOpeningKind.door, PlanRect(wx1, dy, wx2, dy + door), hall, item.id));
        }
        final window = item.space.window;
        if (window != null && !item.sealed) {
          final wy = y + (item.space.depth - window) ~/ 2;
          wall(ex1, y, ex2, wy); wall(ex1, wy + window, ex2, end);
          openings.add(PlanOpening(PlanOpeningKind.window, PlanRect(ex1, wy, ex2, wy + window), outside, item.id));
        } else {
          wall(ex1, y, ex2, end);
        }
        y = end + t < innerTop ? end + t : innerTop;
        wall(side ? 0 : ce, end, side ? cx : w, y);
      }
      if (y < innerTop) {
        final reserve = PlanRect(x1, y, x2, innerTop);
        unused += reserve.area;
        rooms.add(PlanRoom('reserve_$side', 'Unallocated space', reserve));
        wall(wx1, y, wx2, innerTop); wall(ex1, y, ex2, innerTop);
      }
    }
    PlanRect orient(PlanRect r) {
      final local = switch (input.frontage) {
        'North' => PlanRect(w-r.right, d-r.top, w-r.left, d-r.bottom),
        'East' => PlanRect(d-r.top, r.left, d-r.bottom, r.right),
        'West' => PlanRect(r.bottom, w-r.right, r.top, w-r.left),
        _ => r,
      };
      return PlanRect(local.left + plate.left, local.bottom + plate.bottom,
        local.right + plate.left, local.top + plate.bottom);
    }
    final stairGraphics = <StairDrawing>[];
    final stairBounds = stairRoom;
    if (stair != null && stairBounds != null) {
      final first = stairBounds.bottom + stair.landing;
      final last = first + stair.run;
      final centre = (stairBounds.left + stairBounds.right) ~/ 2;
      (int, int) point(int x, int y) {
        final transformed = orient(PlanRect(x,y,x,y));
        return (transformed.left, transformed.bottom);
      }
      final graphics = <((int,int),(int,int))>[
        for (var i=0; i<stair.risers; i++)
          (point(stairBounds.left,first+i*stair.going), point(stairBounds.right,first+i*stair.going)),
      ];
      final start = ground ? first : last, end = ground ? last : first;
      final head = (stairBounds.width < stair.going ? stairBounds.width : stair.going) ~/ 4;
      final back = ground ? end - head : end + head;
      graphics.addAll([(point(centre,start),point(centre,end)),
        (point(centre-head,back),point(centre,end)), (point(centre+head,back),point(centre,end))]);
      stairGraphics.add(StairDrawing(roomId: 'stair_0', up: ground, risers: stair.risers,
        riseMm: stair.height / stair.risers, goingMm: stair.going, floorHeightMm: stair.height, strokes: graphics));
    }
    return (plan: AutomaticFloorPlan(plot: plot, footprint: plate, facing: input.frontage,
      sheetTitle: title, stairs: stairGraphics, rooms: rooms.map((r) => PlanRoom(r.id, r.label, orient(r.bounds))),
      walls: walls.map(orient), openings: openings.map((o) => PlanOpening(o.kind, orient(o.bounds), o.from, o.to))),
      unallocated: unused);
  }
}
