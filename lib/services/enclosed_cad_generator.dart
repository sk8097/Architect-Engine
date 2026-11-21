import '../data/concept_zoning_profiles.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import '../models/tower_brief.dart';
import 'tower_plan_generator.dart';

/// Measured concept floor plans across enclosure-based uses. The profile
/// influences ordering, while dimensions, edges and connectivity are hard checks.
class EnclosedCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'building';

  TowerResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing,
    bool Function(AutomaticFloorPlan)? extraAcceptance}) {
    TowerResult stop(String reason) => TowerResult(const [], [reason]);
    final selection = brief.taxonomy;
    final request = brief.requirements;
    if (selection == null || selection.version != projectTaxonomyVersion || request == null || request.version != requirementsSchemaVersion) {
      return stop('Edit and save the brief with the current requirements.');
    }
    final group = taxonomyGroup(taxonomyCategory(selection.categoryId), selection.subcategoryId);
    final type = taxonomyChoice(group?.types ?? const [], selection.typeId);
    if (group == null || type == null) return stop('Select a listed project type.');
    final data = request.answers;
    final program = type.programId ?? group.programId;
    final profile = zoningProfile(group, type);
    if (!const {'rectangular', 'square'}.contains(selection.plotShapeId)) return stop('Enclosed CAD uses a measured rectangular or square plot.');
    if (brief.floorCount != 1 || (data['basements'] as num? ?? 0) > 0 || (data['mezzanines'] as num? ?? 0) > 0 || (data['building_count'] as num? ?? 1) > 1) {
      return stop('This enclosed generator requires one building and exactly one floor above grade. It cannot draw basements or mezzanines. Use the high-rise planner for an applicable common rectangular plate.');
    }
    if (!const {'North','East','South','West'}.contains(facing)) return stop('Use a measured North, East, South or West frontage for the entrance.');
    if (data['terrace_needed'] == 'yes') return stop('Your accessible terrace requirement is saved; this enclosed layout does not draw terrace access.');
    if (data['parking_sqft'] != null || (brief.parking != null && brief.parking != ProjectParking.none)) {
      return stop('Your parking requirement is saved; this enclosed layout does not design parking or vehicle movement. Use site zoning separately for measured space allocation.');
    }
    if (usesLinearSite(selection.categoryId, selection.subcategoryId, selection.typeId) ||
        (selection.categoryId == 'infrastructure' && data['custom_site_kind'] == 'linear')) {
      return stop('A linear corridor is not an enclosed building. Use the measured corridor output.');
    }
    if (selection.actionId != null && !const {'new_design', 'concept_design', 'feasibility'}.contains(selection.actionId)) {
      return stop('This generator is for a new building concept. Existing work, approval and construction drawing requests need a different workflow.');
    }
    if (const {'existing', 'partial_demolition', 'brownfield'}.contains(data['build_status']) ||
        const {'existing', 'partial', 'renovation', 'demolish'}.contains(data['construction_status']) ||
        selection.subcategoryId == 'residential_works' || program == 'heritage' ||
        type.id == 'adaptive_reuse') {
      return stop('This case needs surveyed existing walls/structure; the enclosed floor-plan solver is for new concepts only.');
    }
    int? mm(Object? raw, {bool zero = false}) {
      if (raw is! num || !raw.isFinite || raw < 0 || raw > TowerPlanGenerator.maxDimension / 1000) return null;
      final value = (raw * 1000).round();
      return value > 0 || zero ? value : null;
    }
    final plotWidth = mm(widthFt * .3048), plotDepth = mm(depthFt * .3048);
    if (plotWidth == null || plotDepth == null || (selection.plotShapeId == 'square' && plotWidth != plotDepth)) {
      return stop('Enter valid measured plot sides, up to 300 m each.');
    }
    final w = mm(data['cad_plate_width']), d = mm(data['cad_plate_depth']);
    final l = mm(data['cad_offset_left'], zero: true), f = mm(data['cad_offset_front'], zero: true);
    final wall = mm(data['cad_wall']), corridor = mm(data['cad_corridor']), door = mm(data['cad_door']);
    if (w == null || d == null || l == null || f == null || wall == null || corridor == null || door == null) return stop('Enter the building dimensions, offsets, wall thickness, passage and door widths in Configuration.');
    int inset(String key) => mm(data['${key}_setback'], zero: true) ?? 0;
    for (final side in ['left','right','front','rear']) {
      if (data['${side}_setback'] != null && mm(data['${side}_setback'], zero: true) == null) return stop('Invalid $side setback.');
    }
    if (l < inset('left') || f < inset('front') || l + w > plotWidth - inset('right') || f + d > plotDepth - inset('rear')) {
      return stop('The building and offsets conflict with the plot or supplied setbacks.');
    }
    final coverage = data['coverage_limit'];
    if (coverage is num && w * d > plotWidth * plotDepth * coverage / 100) return stop('The building footprint exceeds the supplied coverage limit.');
    final fsi = data['fsi_limit'];
    if (fsi is num && w * d > plotWidth * plotDepth * fsi) return stop('The single-floor gross area exceeds the supplied FAR/FSI limit.');
    final spaces = <({String id, TowerSpace space, bool sealed})>[];
    final typesById = <String, String>{};
    final access = <String, String>{};
    final edges = <String, String>{};
    final active = selection.spaceQuantities;
    final quantities = active.values.fold(0, (sum, n) => sum + n);
    if (quantities < 1 || quantities > TowerPlanGenerator.maxSpaces || active.values.any((n) => n <= 0)) {
      return stop('Include 1 to ${TowerPlanGenerator.maxSpaces} measured interior rooms, with their quantities.');
    }
    if (program == 'home') {
      int matching(Set<String> ids) => active.entries.where((e) => ids.contains(e.key)).fold(0, (a, e) => a + e.value);
      final kitchen = data['kitchen_type'];
      if (matching({'closed_kitchen'}) != 1 || matching({'open_kitchen'}) > 0 || (kitchen != null && kitchen != 'closed')) {
        return stop('For a dwelling, add one measured closed kitchen. Open/specialist kitchens are not supported by this partitioned layout.');
      }
      final shared = matching({'shared_bathroom'}), attached = matching({'attached_bathroom'});
      if (shared == 0 || attached > 0 || (data['attached_toilets'] as num? ?? 0) > 0 ||
          (data['common_toilets'] != null && data['common_toilets'] != shared)) {
        return stop('Include the requested shared bathrooms. Ensuite access is not generated by the shared passage model.');
      }
      final inferred = int.tryParse(RegExp(r'^(\d+)_bhk$').firstMatch(selection.configurationId ?? '')?.group(1) ?? '');
      final bedrooms = data['bedrooms'] ?? inferred;
      if (bedrooms is num && bedrooms != matching({'master_bedroom','secondary_bedroom','childrens_bedroom','guest_bedroom','elderly_accessible_bedroom'})) {
        return stop('The measured bedroom quantity does not match the selected bedroom program.');
      }
      if (data['puja_needed'] == 'yes' && (data['puja_form'] != 'room' || matching({'prayer_puja_room'}) == 0)) {
        return stop('For a puja room, include it with measured dimensions. This enclosed generator does not detail niches or corners.');
      }
    }
    for (final entry in active.entries) {
      final name = request.customSpaces[entry.key] ?? taxonomyChoice(taxonomyProgram(group,type).spaces, entry.key)?.label;
      final details = request.spaceDetails[entry.key] ?? const <String, Object>{};
      if (name == null || name.trim().isEmpty) return stop('An included room has no valid label.');
      if (!const {'', '0', 'g', 'ground', 'ground floor'}.contains('${details['floor_level'] ?? ''}'.trim().toLowerCase())) return stop('$name is not assigned to the ground floor.');
      final width = mm(details['width']), depth = mm(details['length']);
      if (width == null || depth == null) return stop('$name: enter both clear width and length in Space details (m).');
      if (!const {'any','front','rear','left','right'}.contains(details['zone_edge'] ?? 'any')) return stop('$name: invalid requested edge.');
      final window = mm(details['cad_window']);
      if (details['cad_window'] != null && window == null) return stop('$name: enter a positive exterior-window width.');
      if (details['daylight'] == 'required' && window == null) return stop('$name: daylight is required in the brief. Supply an exterior window width; daylight performance itself is not verified.');
      for (final key in spaceAdjacencyKeys) {
        final targets = details[key];
        if (key == 'adjacent_required' && targets is Iterable && targets.any((id) => id == entry.key || !active.containsKey(id))) {
          return stop('$name: a required adjoining room is not in the room list.');
        }
      }
      for (var i = 0; i < entry.value; i++) {
        final id = 'room_${spaces.length}';
        typesById[id] = entry.key;
        edges[id] = '${details['zone_edge'] ?? 'any'}';
        access[id] = '${details['access'] ?? ''}';
        spaces.add((id: id, sealed: false, space: TowerSpace(entry.value == 1 ? name : '$name ${i + 1}', width, depth, window: window)));
      }
    }
    int rank(String id) {
      if (edges[id] == 'front') return -2;
      if (edges[id] == 'rear') return 2;
      return switch (profile?.preferredEdge(access[id])) {'front' => -1, 'rear' => 1, _ => 0};
    }
    spaces.sort((a,b) => rank(a.id).compareTo(rank(b.id)));
    final rotated = facing == 'East' || facing == 'West';
    final x = switch(facing) {'North' => plotWidth - l - w, 'East' => plotDepth - f - d, 'West' => f, _ => l};
    final y = switch(facing) {'North' => plotDepth - f - d, 'East' => l, 'West' => plotWidth - l - w, _ => f};
    final shell = TowerBrief(floors: 1, plotWidth: rotated ? plotDepth : plotWidth, plotDepth: rotated ? plotWidth : plotDepth,
      plateWidth: rotated ? d : w, plateDepth: rotated ? w : d, westOffset: x, southOffset: y,
      frontage: facing, wall: wall, corridor: corridor, door: door, basis: 'Measured concept inputs',
      stairs: const [], lifts: const [], shafts: const [],
      groups: [TowerFloorGroup(type.label, 1, 1, spaces.map((item) => item.space))]);
    bool validRoom(PlanRoom room, PlanRect plate) {
      final b = room.bounds, t = shell.wall;
      final (front,rear,left,right) = switch(facing) {
        'North' => (plate.top-b.top,b.bottom-plate.bottom,plate.right-b.right,b.left-plate.left),
        'East' => (plate.right-b.right,b.left-plate.left,b.bottom-plate.bottom,plate.top-b.top),
        'West' => (b.left-plate.left,plate.right-b.right,plate.top-b.top,b.bottom-plate.bottom),
        _ => (b.bottom-plate.bottom,plate.top-b.top,b.left-plate.left,plate.right-b.right),
      };
      if (!(switch(edges[room.id]) {'front'=>front == t,'rear'=>rear == t,'left'=>left == t,'right'=>right == t,_=>true})) return false;
      final details = request.spaceDetails[typesById[room.id]] ?? const <String,Object>{};
      for (final key in ['area_min','area_max']) {
        final area = details[key];
        if (area is! num) continue;
        final unit = details['area_unit'];
        if (unit != 'sqm' && unit != 'sqft') return false;
        final requested = area * (unit == 'sqft' ? .09290304 : 1);
        if (key == 'area_min' ? b.area / 1000000 < requested - .001 : b.area / 1000000 > requested + .001) return false;
      }
      return true;
    }
    bool adjoining(PlanRect a, PlanRect b) => ((a.right + shell.wall == b.left || b.right + shell.wall == a.left) && a.bottom < b.top && b.bottom < a.top) ||
      ((a.top + shell.wall == b.bottom || b.top + shell.wall == a.bottom) && a.left < b.right && b.left < a.right);
    bool accepts(AutomaticFloorPlan plan) {
      final rooms = plan.rooms.where((r) => typesById.containsKey(r.id)).toList();
      for (final r in rooms) {
        if (!validRoom(r, plan.footprint)) return false;
        final details = request.spaceDetails[typesById[r.id]] ?? const <String,Object>{};
        final required = details['adjacent_required'], separate = details['separate_from'];
        if (required is Iterable && required.any((id) => !rooms.any((other) => other.id != r.id && typesById[other.id] == id && adjoining(r.bounds, other.bounds)))) return false;
        if (separate is Iterable && rooms.any((other) => other.id != r.id && separate.contains(typesById[other.id]) && adjoining(r.bounds, other.bounds))) return false;
      }
      return extraAcceptance?.call(plan) ?? true;
    }
    return TowerPlanGenerator().generateEnclosed(shell, spaces, exactWidths: data['cad_width_mode'] != 'minimum', accepts: accepts);
  }
}
