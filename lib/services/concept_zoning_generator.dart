import '../data/concept_zoning_profiles.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/survey_corridor_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';

class ZoningResult {
  const ZoningResult(this.sheets, this.issues, {this.focus = ''});
  final List<ZoningSheet> sheets;
  final List<String> issues;
  final String focus;
}

class _RequestedZone {
  const _RequestedZone(this.id, this.name, this.width, this.depth, this.level, this.edge, this.preferred, this.layer);
  final String id, name, edge, preferred, layer;
  final int width, depth, level;
}

/// Rectangular measured envelopes only. This creates zoning geometry, not
/// partitions, circulation/egress or any category-specific engineering layout.
class ConceptZoningGenerator {
  /// Catalogue routing only; dimensions and constraints are checked at generation.
  static bool supportsBrief(ProjectBrief? brief) {
    final selection = brief?.taxonomy;
    final group = taxonomyGroup(taxonomyCategory(selection?.categoryId), selection?.subcategoryId);
    final type = taxonomyChoice(group?.types ?? const [], selection?.typeId);
    return group != null && type != null && zoningProfile(group, type) != null;
  }

  ZoningResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, String? facing}) {
    ZoningResult blocked(String issue) => ZoningResult(const [], [issue]);
    final selection = brief.taxonomy;
    final requirements = brief.requirements;
    if (selection == null || !supportsBrief(brief)) return blocked('Select a listed project type.');
    if (selection.version != projectTaxonomyVersion || requirements?.version != requirementsSchemaVersion) {
      return blocked('This brief has no compatible measured requirements. Edit and save it again.');
    }
    final group = taxonomyGroup(taxonomyCategory(selection.categoryId), selection.subcategoryId)!;
    final type = taxonomyChoice(group.types, selection.typeId)!;
    final profile = zoningProfile(group, type)!;
    final answers = requirements!.answers;
    final linear = usesLinearSite(selection.categoryId, selection.subcategoryId, selection.typeId) ||
        (selection.categoryId == 'infrastructure' && type.id == 'custom' && answers['custom_site_kind'] == 'linear');
    final counts = selection.spaceQuantities;
    final sheets = <ZoningSheet>[];
    final requests = <_RequestedZone>[];
    final relationships = <String, Map<String, Set<String>>>{};
    final levels = brief.floorCount ?? 0;
    int? metres(Object? input, {int limit = 1000000}) {
      if (input is! num || !input.isFinite || input <= 0 || input > limit / 1000) return null;
      final result = (1000 * input).round();
      return result > 0 ? result : null;
    }
    if (levels < 0 || levels > 100) return blocked('Enter a valid floor count between 0 and 100.');
    if (counts.values.any((n) => n < 1 || n > 40) || counts.values.fold(0, (sum, n) => sum + n) > 40) {
      return blocked('This concept solver supports up to 40 measured zones in one brief.');
    }
    int? readLevel(Object? value) {
      final text = '${value ?? ''}'.trim().toLowerCase();
      if (const {'', 'g', 'ground', 'ground floor'}.contains(text)) return 0;
      return int.tryParse(text.replaceFirst(RegExp(r'^floor\s+'), ''));
    }
    for (final entry in counts.entries) {
      final id = entry.key;
      final name = requirements.customSpaces[id] ?? taxonomyChoice(taxonomyProgram(group, type).spaces, id)?.label;
      if (name == null || name.trim().isEmpty) return blocked('An included zone has no valid label: $id.');
      final detail = requirements.spaceDetails[id] ?? const <String, Object>{};
      final width = metres(detail['width']), depth = metres(detail['length']);
      if (width == null || depth == null) return blocked('$name: enter both clear width and length in Space details. An area alone does not define a CAD envelope.');
      final level = readLevel(detail['floor_level']);
      if (level == null || level < 0 || (linear && level != 0) || (level > 0 && level >= levels)) {
        return blocked('$name: enter an existing level (0 for ground). A corridor drawing has no upper floors.');
      }
      for (final key in ['area_min', 'area_max']) {
        final area = detail[key];
        if (area is num) {
          final unit = detail['area_unit'];
          if (unit != 'sqft' && unit != 'sqm') return blocked('$name: select a valid area unit.');
          final areaM2 = area * (unit == 'sqft' ? .09290304 : 1);
          final measuredM2 = width * depth / 1000000;
          if ((key == 'area_min' && measuredM2 < areaM2 - .001) || (key == 'area_max' && measuredM2 > areaM2 + .001)) {
            return blocked('$name: clear dimensions conflict with the requested ${key == 'area_min' ? 'minimum' : 'maximum'} area.');
          }
        }
      }
      relationships[id] = {
        for (final key in spaceAdjacencyKeys)
          if (detail[key] is Iterable) key: (detail[key] as Iterable).whereType<String>().toSet(),
      };
      final access = detail['access'];
      final edge = '${detail['zone_edge'] ?? 'any'}';
      if (!const {'any', 'front', 'rear', 'left', 'right'}.contains(edge)) return blocked('$name: invalid placement edge.');
      final layer = switch (access) {
        'public' || 'semi_public' => 'ZONES_PUBLIC',
        'staff' || 'restricted' || 'service' => 'ZONES_SERVICE',
        _ => 'ZONES_PROGRAM',
      };
      for (var copy = 0; copy < entry.value; copy++) {
        requests.add(_RequestedZone(id, entry.value == 1 ? name : '$name ${copy + 1}', width, depth, level, edge,
          profile.preferredEdge(access is String ? access : null), layer));
      }
    }
    for (final item in requests) {
      for (final other in relationships[item.id]!['adjacent_required'] ?? const <String>{}) {
        if (!requests.any((r) => r.id == other && r.level == item.level && other != item.id)) {
          return blocked('${item.name}: a required adjacent space is not included on the same level.');
        }
      }
    }
    if (linear) {
      if (surveyCorridorCadModes.contains(answers['corridor_cad_mode'])) return blocked('This brief requests survey corridor CAD, not straight zoning.');
      if (answers['concept_straight_alignment'] != 'confirmed') {
        return blocked('For CAD, confirm a straight measured corridor. A curved or surveyed multi-segment alignment needs a different generator.');
      }
      final length = metres(answers['route_length'], limit: 20000000), row = metres(answers['right_of_way']);
      if (length == null || row == null) return blocked('Enter measured route length (up to 20 km) and right-of-way.');
      final boundary = PlanRect(0, 0, length, row);
      final bands = <MeasuredZone>[];
      var usedWidth = 0;
      final specification = answers['corridor_bands'];
      if (specification is String && specification.trim().isNotEmpty) {
        final entries = specification.split(';').where((s) => s.trim().isNotEmpty).toList();
        if (entries.isEmpty || entries.length > 24) return blocked('Enter 1 to 24 measured bands in label:width format.');
        for (final entry in entries) {
          final fields = entry.split(':');
          final name = fields.first.trim();
          final width = fields.length == 2 ? metres(double.tryParse(fields[1].trim())) : null;
          if (name.isEmpty || width == null) return blocked('Invalid band "$entry". Enter the name and measured width in metres (e.g. Footway:1.5).');
          if (usedWidth + width > row) return blocked('The measured corridor bands exceed the right-of-way at "$name".');
          bands.add(MeasuredZone('band_${bands.length}', name, PlanRect(0, usedWidth, length, usedWidth + width), 'CORRIDOR_BANDS'));
          usedWidth += width;
        }
      }
      final zones = requests.isEmpty ? const <MeasuredZone>[] :
        _pack(PlanRect(0, usedWidth, length, row), requests, relationships);
      if (zones == null) return blocked('The corridor components do not fit the supplied right-of-way or adjacency requirements.');
      return ZoningResult([ZoningSheet(title: '${type.label} / CORRIDOR', envelope: boundary,
        boundary: boundary, axisLabel: 'STATION AXIS - NO GEOGRAPHIC BEARING', corridor: true, zones: [...bands, ...zones])], const [], focus: profile.focus);
    }
    if (!const {'rectangular', 'square'}.contains(selection.plotShapeId)) return blocked('Measured rectangular or square geometry is required. Survey area alone cannot be turned into a plot outline.');
    final w = metres(widthFt * .3048), d = metres(depthFt * .3048);
    if (w == null || d == null || (selection.plotShapeId == 'square' && w != d)) return blocked('Enter valid plot sides (up to 1000 m). The sides of a square must match.');
    if (requests.isEmpty) return blocked('Select at least one space and enter its clear dimensions to generate a zoning sheet.');
    int setback(String side) => metres(answers['${side}_setback']) ?? 0;
    for (final side in ['front', 'rear', 'left', 'right']) {
      final supplied = answers['${side}_setback'];
      if (supplied != null && supplied != 0 && metres(supplied) == null) return blocked('Invalid $side setback.');
    }
    final full = PlanRect(0, 0, w, d);
    final inside = PlanRect(setback('left'), setback('front'), w - setback('right'), d - setback('rear'));
    if (inside.width <= 0 || inside.depth <= 0) return blocked('The supplied setbacks consume the plot.');
    // Cumulative caps cannot be checked against this drawing: zones are clear
    // rectangles and do not include walls/services or a gross floor envelope.
    for (final level in requests.map((item) => item.level).toSet().toList()..sort()) {
      final local = requests.where((item) => item.level == level).toList();
      final upperW = level == 0 ? inside.width : metres(answers['zoning_width_$level']);
      final upperD = level == 0 ? inside.depth : metres(answers['zoning_depth_$level']);
      if (upperW == null || upperD == null) return blocked('Floor $level: enter the measured planning envelope width and depth.');
      if (level > 0 && (upperW > inside.width || upperD > inside.depth)) return blocked('Floor $level: the envelope exceeds the site planning bounds.');
      final envelope = PlanRect(inside.left, inside.bottom, inside.left + upperW, inside.bottom + upperD);
      final label = level == 0 ? (levels == 0 ? 'SITE' : 'GROUND') : 'FLOOR $level';
      final zones = _pack(envelope, local, relationships);
      if (zones == null) return blocked('$label: the measured zones could not be placed together with the given edge and adjacency constraints. Check width, depth and required connections.');
      sheets.add(ZoningSheet(title: '${type.label} / $label', envelope: envelope, boundary: full,
        axisLabel: 'FRONTAGE EDGE AT BOTTOM${const {'North', 'East', 'South', 'West'}.contains(facing) ? ' ($facing)' : ' - BEARING UNVERIFIED'}', zones: zones));
    }
    return ZoningResult(List.unmodifiable(sheets), const [], focus: profile.focus);
  }

  List<MeasuredZone>? _pack(PlanRect envelope, List<_RequestedZone> zones, Map<String, Map<String, Set<String>>> relationships) {
    bool related(String a, String b, String key) =>
      (relationships[a]?[key]?.contains(b) ?? false) || (relationships[b]?[key]?.contains(a) ?? false);
    bool touch(PlanRect a, PlanRect b) =>
      ((a.left == b.right || b.left == a.right) && a.bottom < b.top && b.bottom < a.top) ||
      ((a.bottom == b.top || b.bottom == a.top) && a.left < b.right && b.left < a.right);
    final placed = <MeasuredZone>[];
    var attempts = 0;
    final ordered = [...zones]..sort((a, b) {
      final constrained = (b.edge != 'any' ? 1 : 0) - (a.edge != 'any' ? 1 : 0);
      return constrained == 0 ? (b.width * b.depth).compareTo(a.width * a.depth) : constrained;
    });
    if (ordered.fold(0, (sum, z) => sum + z.width * z.depth) > envelope.area) return null;
    bool solve(int index) {
      if (++attempts > 12000) return false;
      if (index == ordered.length) {
        return placed.every((item) => (relationships[item.id]?['adjacent_required'] ?? const <String>{})
          .every((id) => placed.any((other) => other.id == id && touch(item.bounds, other.bounds))));
      }
      final z = ordered[index];
      final xs = {envelope.left, envelope.right - z.width}, ys = {envelope.bottom, envelope.top - z.depth};
      for (final item in placed) {
        xs.addAll([item.bounds.left, item.bounds.right, item.bounds.left - z.width, item.bounds.right - z.width]);
        ys.addAll([item.bounds.bottom, item.bounds.top, item.bounds.bottom - z.depth, item.bounds.top - z.depth]);
      }
      final xx = xs.toList()..sort(), yy = ys.toList()..sort((a, b) => z.preferred == 'rear' ? b.compareTo(a) : a.compareTo(b));
      for (final y in yy) {
        for (final x in xx) {
          if (++attempts > 12000) return false;
          final r = PlanRect(x, y, x + z.width, y + z.depth);
          final edgeOK = switch (z.edge) {
            'left' => r.left == envelope.left, 'right' => r.right == envelope.right,
            'front' => r.bottom == envelope.bottom, 'rear' => r.top == envelope.top, _ => true,
          };
          if (!edgeOK || !envelope.contains(r) || placed.any((p) => p.bounds.overlaps(r) ||
              (related(z.id, p.id, 'separate_from') && touch(r, p.bounds)))) continue;
          placed.add(MeasuredZone(z.id, z.name, r, z.layer));
          if (solve(index + 1)) return true;
          placed.removeLast();
        }
      }
      return false;
    }
    return solve(0) ? List.unmodifiable(placed) : null;
  }
}
