import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_scenarios.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';

class FloorPlanResult {
  const FloorPlanResult(this.plan, this.issues, this.warnings);
  final AutomaticFloorPlan? plan;
  final List<String> issues, warnings;
}

/// A deterministic, local concept generator for supported low-rise house profiles.
/// Its dimensions are template heuristics, never statutory minimums.
class AutomaticFloorPlanGenerator {
  static const _bed = 'master_bedroom';
  static const _bed2 = 'secondary_bedroom';
  static const _living = 'family_living_room';
  static const _kitchen = 'closed_kitchen';
  static const _bath = 'shared_bathroom';
  static const _hall = 'internal_passage';
  static final supportedTypes = Set<String>.unmodifiable(
    projectScenarios.where((s) => s.generator != null).map((s) => s.type.id),
  );
  static const availability = 'Single-floor 1 BHK and 2 BHK: Independent House, Detached House, Villa, Bungalow and residential Farmhouse.';
  static const _rooms = {
    _bed: 'Bedroom', _living: 'Living room', _kitchen: 'Kitchen',
    _bath: 'Shared bathroom', _hall: 'Entry / passage',
  };
  static const wall = 150;

  static bool supportsProfile(String? category, String? group, String? type, String? config) =>
      scenarioFor(category, group, type, config)?.generator != null;

  static ProjectScenario? _scenarioForBrief(ProjectBrief? brief) {
    final selection = brief?.taxonomy;
    if (selection == null) return null;
    return scenarioForRequirements(selection.categoryId, selection.subcategoryId,
      selection.typeId, selection.configurationId, brief?.requirements?.answers['bedrooms']);
  }

  static bool supportsBrief(ProjectBrief? brief) => _scenarioForBrief(brief)?.generator != null;

  FloorPlanResult generate({required ProjectBrief brief, required double frontageFt,
    required double depthFt, required String facing}) {
    FloorPlanResult blocked(List<String> issues) => FloorPlanResult(null, issues, const []);
    final taxonomy = brief.taxonomy;
    final scenario = _scenarioForBrief(brief);
    if (scenario == null || scenario.generator == null || taxonomy == null) {
      return blocked(['Automatic plans are available for: $availability']);
    }
    final bedrooms = scenario.generator == ScenarioGenerator.house2Bhk ? 2 : 1;
    final two = bedrooms == 2;
    final rooms = {..._rooms, if (two) _bed2: 'Bedroom 2'};
    final snapshot = brief.requirements;
    if (taxonomy.version != projectTaxonomyVersion ||
        (snapshot != null && snapshot.version != requirementsSchemaVersion)) {
      return blocked(['This saved brief uses an unsupported input version.']);
    }
    final values = snapshot?.answers ?? const <String, Object>{};
    final roomDetails = snapshot?.spaceDetails ?? const <String, Map<String, Object>>{};
    final issues = <String>[];
    if (taxonomy.actionId != null && !const {'new_design', 'concept_design', 'feasibility'}.contains(taxonomy.actionId)) {
      issues.add('This generator is for a new standalone concept, not work on an existing design or an approval drawing.');
    }
    if (const {'existing', 'partial_demolition', 'brownfield'}.contains(values['build_status']) ||
        const {'existing', 'partial', 'renovation', 'demolish'}.contains(values['construction_status'])) {
      issues.add('Existing structures or demolition need a surveyed layout. They are not supported by this generator.');
    }
    const sides = {'North': 'n', 'East': 'e', 'South': 's', 'West': 'w'};
    const supportedShapes = {'rectangular', 'square'};
    if (!supportedShapes.contains(taxonomy.plotShapeId)) issues.add('Choose a rectangular or square plot.');
    bool validDimension(double feet) => feet.isFinite && feet > 0 && feet <= 328;
    if (!validDimension(frontageFt) || !validDimension(depthFt)) {
      issues.add('Enter measured plot dimensions in feet, up to 328 ft per side for this preview.');
    } else if (taxonomy.plotShapeId == 'square' && (frontageFt - depthFt).abs() > 0.001) {
      issues.add('The sides of a square plot must match.');
    }
    if (!sides.containsKey(facing)) issues.add('Select North, East, South or West as the front-facing side.');
    final roads = values['road_sides'];
    if (roads is Iterable && roads.isNotEmpty && (roads.length != 1 || roads.first != sides[facing])) {
      issues.add('This profile needs one road edge matching the selected front-facing side.');
    }
    if (const {'two', 'three', 'four'}.contains(values['access'])) issues.add('Multiple road edges are not supported yet.');
    if (const {'gentle', 'steep', 'split', 'retaining', 'cut_fill'}.contains(values['topography'])) {
      issues.add('Sites requiring slope or level changes are not supported by this concept layout.');
    }
    if (brief.floorCount != 1 || (values['basements'] as num? ?? 0) > 0 || (values['mezzanines'] as num? ?? 0) > 0 ||
        (values['building_count'] as num? ?? 1) > 1 || (values['wing_count'] as num? ?? 1) > 1) {
      issues.add('Enter one floor above grade. Only one building without a basement or mezzanine is supported.');
    }
    if (brief.parking == null) {
      issues.add('Tell us whether parking is needed.');
    } else if (brief.parking != ProjectParking.none) {
      issues.add('Your parking requirement is saved, but this generator cannot draw it yet.');
    }
    if (values['terrace_needed'] == 'yes') issues.add('Your terrace and access requirements are saved, but this generator cannot draw them yet.');
    if (values['puja_needed'] == 'yes') issues.add('Your puja-space requirement is saved, but this generator cannot draw it yet.');
    final houseForm = values['house_form'];
    if (houseForm != null && houseForm != 'single_floor') issues.add('Only the single-floor house form is supported.');
    final kitchen = values['kitchen_type'];
    if (kitchen != null && kitchen != 'closed') issues.add('Open or specialist kitchen layouts are not supported yet. This template has a closed kitchen.');
    if ((values['bedrooms'] != null && values['bedrooms'] != bedrooms) ||
        (values['attached_toilets'] as num? ?? 0) > 0 ||
        (values['common_toilets'] != null && values['common_toilets'] != 1)) {
      issues.add('This layout has $bedrooms bedroom(s) and one shared bathroom.');
    }
    final customSpaces = snapshot?.customSpaces ?? const <String, String>{};
    final profile = taxonomyProgram(taxonomyGroup(taxonomyCategory('residential'), 'houses')!,
      const TaxonomyChoice('independent_house', 'Independent House'));
    for (final entry in taxonomy.spaceQuantities.entries) {
      if (!rooms.containsKey(entry.key) || entry.value != 1) {
        final label = customSpaces[entry.key] ?? taxonomyChoice(profile.spaces, entry.key)?.label ?? entry.key;
        issues.add('This layout cannot place ${entry.value} × $label.');
      }
    }
    for (final entry in roomDetails.entries) {
      if (rooms.containsKey(entry.key) && isExcludedSpace(entry.value)) {
        issues.add('${rooms[entry.key]} is essential to this profile and cannot be excluded.');
      }
      final floor = entry.value['floor_level'];
      if (floor is String && !const {'ground', 'ground floor', 'g', '0'}.contains(floor.trim().toLowerCase())) {
        issues.add('${rooms[entry.key] ?? entry.key} requests another floor. Only ground floor is supported.');
      }
    }
    if (issues.isNotEmpty) return blocked(issues);

    final w = (frontageFt * 304.8).round(), d = (depthFt * 304.8).round();
    final setbacks = <String, int>{};
    for (final side in ['front', 'rear', 'left', 'right']) {
      final value = values['${side}_setback'];
      if (value is num) {
        if (!value.isFinite || value < 0 || value > 100) return blocked(['Invalid $side setback; enter a measured value in metres.']);
        setbacks[side] = (value * 1000).ceil();
      }
    }
    // Unspecified sides are bounded by the plot only, not assumed to have a
    // verified statutory setback. The warning is carried into every preview.
    final left = setbacks['left'] ?? 0, right = setbacks['right'] ?? 0;
    final front = setbacks['front'] ?? 0, rear = setbacks['rear'] ?? 0;
    final maxWidth = w - left - right, maxDepth = d - front - rear;
    if (maxWidth <= 0 || maxDepth <= 0) return blocked(['The supplied setbacks consume the entire plot.']);

    final picks = _search(roomDetails, values, maxWidth, maxDepth, w * d, two);
    if (picks == null) return blocked([
      'No supported $bedrooms BHK layout fits this plot envelope and the selected room constraints. '
      'Check plot size, supplied setbacks, requested areas, clear dimensions and adjacency. '
      'This is not a finding that the site cannot be developed.',
    ]);
    final local = _layout(picks, left + (maxWidth - picks.width) ~/ 2,
        front + (maxDepth - picks.depth) ~/ 2);
    PlanRect orient(PlanRect rect) {
      final (x1, y1, x2, y2) = (rect.left, rect.bottom, rect.right, rect.top);
      return switch (facing) {
        'North' => PlanRect(w - x2, d - y2, w - x1, d - y1),
        'East' => PlanRect(d - y2, x1, d - y1, x2),
        'West' => PlanRect(y1, w - x2, y2, w - x1),
        _ => rect,
      };
    }
    final plan = AutomaticFloorPlan(
      plot: (facing == 'East' || facing == 'West') ? PlanRect(0, 0, d, w) : PlanRect(0, 0, w, d),
      footprint: orient(local.footprint), facing: facing, bedrooms: bedrooms,
      rooms: local.rooms.map((r) => PlanRoom(r.id, r.label, orient(r.bounds))),
      walls: local.walls.map(orient),
      openings: local.openings.map((o) => PlanOpening(o.kind, orient(o.bounds), o.from, o.to)),
    );
    final validation = validateAutomaticFloorPlan(plan);
    if (validation != null) return blocked(['The model did not pass geometry checks: $validation']);
    const applied = {'road_sides', 'access', 'basements', 'mezzanines', 'building_count', 'wing_count',
      'build_status', 'construction_status', 'house_form', 'kitchen_type', 'bedrooms', 'attached_toilets', 'common_toilets',
      'front_setback', 'rear_setback', 'left_setback', 'right_setback', 'target_builtup_area',
      'coverage_limit', 'fsi_limit'};
    const appliedRoom = {'priority', 'area_unit', 'area_min', 'area_target', 'area_max', 'width', 'length',
      'floor_level', 'adjacent_required', 'adjacent_preferred', 'separate_from'};
    return FloorPlanResult(plan, const [], [
      'Concept only. Local rules, structure, accessibility and services have not been verified.',
      if (setbacks.length != 4) 'Unsupplied setbacks were not checked; those sides are limited only by the plot boundary.',
      if (values.keys.any((key) => !applied.contains(key)) || roomDetails.values.any((d) => d.keys.any((key) => !appliedRoom.contains(key))))
        'Other saved brief fields (such as site, technical or design preferences) are recorded but not evaluated by this layout.',
      if (picks.missedPreference) 'Some target areas or preferred adjacencies could not be matched exactly; compare the shown room dimensions.',
      'Room sizes and wall thickness are concept assumptions. No structural, furniture, egress or daylight analysis is included.',
    ]);
  }
}

class _Candidate {
  const _Candidate(this.a, this.b, this.front, this.back, this.hall, this.bathSplit, this.missedPreference);
  final int a, b, front, back, hall;
  final int? bathSplit;
  bool get two => bathSplit != null;
  final bool missedPreference;
  int get width => a + b + hall + 4 * AutomaticFloorPlanGenerator.wall;
  int get depth => front + back + 3 * AutomaticFloorPlanGenerator.wall;
}

const _roomGrid = {
  'family_living_room': (0, 0), 'master_bedroom': (0, 1),
  'closed_kitchen': (2, 0), 'shared_bathroom': (2, 1),
  'internal_passage': (1, -1), 'secondary_bedroom': (2, 2),
};

_Candidate? _search(Map<String, Map<String, Object>> details, Map<String, Object> values,
    int maxWidth, int maxDepth, int plotArea, bool two) {
  final grid = {..._roomGrid};
  if (!two) grid.remove('secondary_bedroom');
  bool adjacent(String a, String b) {
    final x = grid[a], y = grid[b];
    if (x == null || y == null || a == b) return false;
    return x.$1 == 1 || y.$1 == 1 || (x.$1 == y.$1 && (x.$2 - y.$2).abs() == 1);
  }
  final geometryFields = details.entries.where((e) => grid.containsKey(e.key)).toList();
  for (final e in geometryFields) {
    for (final key in ['adjacent_required', 'separate_from']) {
      final choices = e.value[key];
      if (choices is Iterable && choices.whereType<String>().any((b) =>
          !grid.containsKey(b) || adjacent(e.key, b) != (key == 'adjacent_required'))) return null;
    }
  }
  final preferredAdjacencyMiss = geometryFields.any((e) {
    final options = e.value['adjacent_preferred'];
    return options is Iterable && options.whereType<String>().any((b) => !adjacent(e.key, b));
  });
  int? exact(String id, String field) {
    final value = details[id]?[field];
    return value is num && value > 0 && value <= 100 ? (value * 1000).round() : null;
  }
  int? sharedExact(String field, String a, String b) => exact(a, field) ?? exact(b, field);
  List<int> sizes(int min, int ideal, int? exact) => exact == null
      ? {min, ideal, for (var i = min; i <= math.max(min, ideal + 1000); i += 250) i}.toList()
      : (exact < min ? [] : [exact]);
  final lefts = sizes(3000, 3450, sharedExact('width', 'family_living_room', 'master_bedroom'));
  final rights = sizes(two ? 2800 : 2300, two ? 3100 : 2500,
      sharedExact('width', 'closed_kitchen', 'shared_bathroom') ?? (two ? exact('secondary_bedroom', 'width') : null));
  final fronts = sizes(3000, 3400, sharedExact('length', 'family_living_room', 'closed_kitchen'));
  const wall = AutomaticFloorPlanGenerator.wall;
  final idealBack = two ? 5350 : 3300;
  final bathSplits = two ? sizes(1650, 1850, exact('shared_bathroom', 'length')) : const [0];
  final secondDepth = two ? exact('secondary_bedroom', 'length') : null;
  final backExact = two ? exact('master_bedroom', 'length') : sharedExact('length', 'master_bedroom', 'shared_bathroom');

  final halls = sizes(1050, 1100, exact('internal_passage', 'width'));
  final coverage = values['coverage_limit'] as num?, fsi = values['fsi_limit'] as num?;
  final target = values['target_builtup_area'] as num?;
  _Candidate? best;
  var bestScore = double.infinity;
  for (final a in lefts) {
    for (final b in rights) {
      for (final front in fronts) {
        for (final bath in bathSplits) {
          final minBack = two ? bath + wall + 2850 : 3000;
          final backs = sizes(minBack, math.max(idealBack, minBack),
              backExact ?? (secondDepth != null ? bath + wall + secondDepth : null));
          for (final back in backs) {
            for (final hall in halls) {
              final candidate = _Candidate(a, b, front, back, hall, two ? bath : null, false);
              if (candidate.width > maxWidth || candidate.depth > maxDepth) continue;
              final footprint = candidate.width * candidate.depth;
              if (coverage != null && footprint * 100 > plotArea * coverage) continue;
              if (fsi != null && footprint > plotArea * fsi) continue;
              final sizes = {
                'family_living_room': (a, front), 'master_bedroom': (a, back),
                'closed_kitchen': (b, front), 'shared_bathroom': (b, two ? bath : back),
                if (two) 'secondary_bedroom': (b, back - bath - wall),
                'internal_passage': (hall, front + back + AutomaticFloorPlanGenerator.wall),
              };
              var totalError = target == null ? 0.0 : (footprint / 1000000 - target).abs();
              var valid = true;
              for (final e in geometryFields) {
                final (width, depth) = sizes[e.key]!;
                final input = e.value;
                if ((input['width'] != null && exact(e.key, 'width') != width) ||
                    (input['length'] != null && exact(e.key, 'length') != depth)) { valid = false; break; }
                final area = width * depth / (input['area_unit'] == 'sqft' ? 92903.04 : 1000000);
                final min = input['area_min'] as num?, max = input['area_max'] as num?, targetArea = input['area_target'] as num?;
                if ((min != null && area < min) || (max != null && area > max)) { valid = false; break; }
                if (targetArea != null) totalError += (targetArea - area).abs().toDouble() * (input['area_unit'] == 'sqft' ? 0.09290304 : 1);
              }
              if (!valid) continue;
              final score = totalError * 10 + ((a - 3450).abs() + (b - (two ? 3100 : 2500)).abs() +
                  (front - 3400).abs() + (back - idealBack).abs() + (two ? (bath - 1850).abs() : 0) + (hall - 1100).abs()) / 1000;
              if (score < bestScore) {
                bestScore = score;
                best = _Candidate(a, b, front, back, hall, two ? bath : null, totalError > 0.1 || preferredAdjacencyMiss);
              }
            }
          }
        }
      }
    }
  }
  return best;
}

AutomaticFloorPlan _layout(_Candidate c, int x, int y) {
  const t = AutomaticFloorPlanGenerator.wall;
  final r = x + c.width, top = y + c.depth;
  final aLeft = x + t, aRight = aLeft + c.a;
  final hallLeft = aRight + t, hallRight = hallLeft + c.hall;
  final bLeft = hallRight + t, bRight = r - t;
  final frontStart = y + t, frontEnd = frontStart + c.front;
  final backStart = frontEnd + t, backEnd = top - t;
  const outside = AutomaticFloorPlan.entry;
  const hall = 'internal_passage', living = 'family_living_room', bed = 'master_bedroom';
  const kitchen = 'closed_kitchen', bath = 'shared_bathroom', bed2 = 'secondary_bedroom';
  final bathEnd = c.two ? backStart + c.bathSplit! : backEnd;
  final secondStart = bathEnd + t;
  final rooms = [
    PlanRoom(living, 'Living room', PlanRect(aLeft, frontStart, aRight, frontEnd)),
    PlanRoom(bed, c.two ? 'Bedroom 1' : 'Bedroom', PlanRect(aLeft, backStart, aRight, backEnd)),
    PlanRoom(kitchen, 'Kitchen', PlanRect(bLeft, frontStart, bRight, frontEnd)),
    PlanRoom(bath, 'Shared bathroom', PlanRect(bLeft, backStart, bRight, bathEnd)),
    if (c.two) PlanRoom(bed2, 'Bedroom 2', PlanRect(bLeft, secondStart, bRight, backEnd)),
    PlanRoom(hall, 'Entry / passage', PlanRect(hallLeft, frontStart, hallRight, backEnd)),
  ];
  final walls = <PlanRect>[], openings = <PlanOpening>[];
  void strip(bool horizontal, int fixed, int start, int end,
      List<(int, int, PlanOpeningKind, String, String)> gaps) {
    PlanRect segment(int lo, int hi) => horizontal
        ? PlanRect(lo, fixed, hi, fixed + t) : PlanRect(fixed, lo, fixed + t, hi);
    var cursor = start;
    for (final (offset, size, kind, from, to) in gaps) {
      if (offset > cursor) walls.add(segment(cursor, offset));
      openings.add(PlanOpening(kind, segment(offset, offset + size), from, to));
      cursor = offset + size;
    }
    if (cursor < end) walls.add(segment(cursor, end));
  }
  int center(int start, int length, int opening) => start + (length - opening) ~/ 2;
  const door = PlanOpeningKind.door, window = PlanOpeningKind.window;
  strip(true, y, x, r, [(center(hallLeft, c.hall, 900), 900, door, outside, hall)]);
  strip(true, top - t, x, r, []);
  strip(false, x, frontStart, backEnd, [
    (center(frontStart, c.front, 1400), 1400, window, outside, living),
    (center(backStart, c.back, 1200), 1200, window, outside, bed),
  ]);
  strip(false, r - t, frontStart, backEnd, [
    (center(frontStart, c.front, 1100), 1100, window, outside, kitchen),
    (center(backStart, bathEnd - backStart, 600), 600, window, outside, bath),
    if (c.two) (center(secondStart, backEnd - secondStart, 1200), 1200, window, outside, bed2),
  ]);
  strip(false, aRight, frontStart, backEnd, [
    (center(frontStart, c.front, 900), 900, door, hall, living),
    (center(backStart, c.back, 900), 900, door, hall, bed),
  ]);
  strip(false, hallRight, frontStart, backEnd, [
    (center(frontStart, c.front, 850), 850, door, hall, kitchen),
    (center(backStart, bathEnd - backStart, 800), 800, door, hall, bath),
    if (c.two) (center(secondStart, backEnd - secondStart, 900), 900, door, hall, bed2),
  ]);
  strip(true, frontEnd, aLeft, aRight, []);
  strip(true, frontEnd, bLeft, bRight, []);
  if (c.two) strip(true, bathEnd, bLeft, bRight, []);
  final footprint = PlanRect(x, y, r, top);
  return AutomaticFloorPlan(plot: footprint, footprint: footprint, facing: 'South',
    rooms: rooms, walls: walls, openings: openings, bedrooms: c.two ? 2 : 1);
}

String? validateAutomaticFloorPlan(AutomaticFloorPlan plan) => validatePlanGeometry(plan,
  expectedRoomCount: 4 + plan.bedrooms,
);

/// Checks containment and exact non-overlapping coverage of the shell.
String? validatePlanPartition(AutomaticFloorPlan plan) {
  bool positive(PlanRect r) => r.width > 0 && r.depth > 0;
  if (!positive(plan.plot) || !positive(plan.footprint) || !plan.plot.contains(plan.footprint)) return 'Footprint outside the plot.';
  final parts = [...plan.rooms.map((r) => r.bounds), ...plan.walls, ...plan.openings.map((o) => o.bounds)];
  var area = 0;
  for (var i = 0; i < parts.length; i++) {
    final part = parts[i];
    if (!positive(part) || !plan.footprint.contains(part)) return 'Invalid geometry bounds.';
    area += part.area;
    for (var j = 0; j < i; j++) {
      if (part.overlaps(parts[j])) return 'Geometry overlaps.';
    }
  }
  if (area != plan.footprint.area) return 'Open spaces in the wall and room partition.';

  return null;
}

/// Shared geometric validation, not fire/egress or engineering certification.
String? validatePlanGeometry(AutomaticFloorPlan plan, {int? expectedRoomCount,
  String? indoorSeed, Set<String> sealedRooms = const {}}) {
  final partitionIssue = validatePlanPartition(plan);
  if (partitionIssue != null) return partitionIssue;

  bool touches(PlanRect a, PlanRect b) =>
      ((a.left == b.right || a.right == b.left) && a.bottom < b.top && a.top > b.bottom) ||
      ((a.bottom == b.top || a.top == b.bottom) && a.left < b.right && a.right > b.left);
  final rooms = {for (final r in plan.rooms) r.id: r.bounds};
  const outside = AutomaticFloorPlan.entry;
  if (rooms.length != plan.rooms.length || rooms.containsKey(outside) || (expectedRoomCount != null && rooms.length != expectedRoomCount)) return 'Invalid room program.';
  final adjacent = <String, Set<String>>{};
  var entranceCount = 0;
  for (final opening in plan.openings) {
    final from = rooms[opening.from], to = rooms[opening.to], bounds = opening.bounds;
    final exterior = opening.from == outside;
    if (to == null || !touches(bounds, to) || opening.from == opening.to ||
        (!exterior && (from == null || !touches(bounds, from)))) return 'Opening does not connect its listed spaces.';
    final footprint = plan.footprint;
    if (exterior && bounds.left != footprint.left && bounds.right != footprint.right &&
        bounds.bottom != footprint.bottom && bounds.top != footprint.top) return 'Exterior opening misses the footprint edge.';
    if (opening.kind != PlanOpeningKind.door) continue;
    if (exterior) {
      entranceCount++;
      final mirroredEdge = switch (plan.facing) {
        'North' => bounds.top == footprint.top,
        'East' => bounds.right == footprint.right,
        'West' => bounds.left == footprint.left,
        'South' => bounds.bottom == footprint.bottom,
        _ => false,
      };
      if (!mirroredEdge) return 'Entrance differs from the selected frontage.';
    }
    adjacent.putIfAbsent(opening.from, () => {}).add(opening.to);
    adjacent.putIfAbsent(opening.to, () => {}).add(opening.from);
  }
  if (indoorSeed != null && !rooms.containsKey(indoorSeed)) return 'Indoor circulation is missing.';
  final start = indoorSeed ?? outside;
  final reachable = <String>{start};
  final stack = <String>[start];
  while (stack.isNotEmpty) {
    for (final next in adjacent[stack.removeLast()] ?? const <String>{}) {
      if (reachable.add(next)) stack.add(next);
    }
  }
  if (entranceCount != (indoorSeed == null ? 1 : 0)) {
    return indoorSeed == null ? 'The plan must have exactly one exterior entrance.' : 'An upper floor cannot have an exterior entrance.';
  }
  return reachable.containsAll(rooms.keys.where((id) => !sealedRooms.contains(id))) ? null :
      (indoorSeed == null ? 'A room has no connected route from the entrance.' : 'A room has no connected route to circulation.');
}
