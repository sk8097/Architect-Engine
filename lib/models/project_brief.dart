import '../data/project_taxonomy.dart';
import 'project_requirements_snapshot.dart';

/// Structured inputs captured by the project wizard, separate from CAD geometry.
// Legacy IDs used by briefs saved before the central taxonomy.
enum ProjectType {
  singleRoom('Single room', 'One room, with optional attached facilities.'),
  house('Independent house', 'A compact home or a multi-storey family house.'),
  villa('Villa', 'An independent home with space for outdoor amenities.'),
  farmhouse('Farmhouse', 'A home with outdoor living and utility spaces.'),
  bungalow('Bungalow', 'An independent home with a garden or verandah.'),
  apartments('Apartment building', 'Multiple homes within one building.'),
  shop('Shop', 'Retail display, customer areas and stock space.'),
  office('Office', 'Workspaces, meeting rooms and reception.'),
  warehouse('Warehouse', 'Storage, loading and supporting facilities.'),
  mixedUse('Mixed-use building', 'Combine residential and commercial spaces.');

  const ProjectType(this.label, this.description);

  final String label;
  final String description;
}

enum ProjectParking {
  none('No parking'),
  car('Car parking'),
  twoWheeler('Two-wheeler parking'),
  both('Car + two-wheeler parking');

  const ProjectParking(this.label);
  final String label;
}

class ProjectBrief {
  ProjectBrief({
    this.type,
    this.taxonomy,
    this.legacyLayout,
    this.requirements,
    required this.floorCount,
    required this.parking,
    required Iterable<String> features,
  }) : features = List.unmodifiable(features);

  final ProjectType? type;
  final TaxonomySelection? taxonomy;
  final String? legacyLayout;
  final ProjectRequirementsSnapshot? requirements;
  String? get typeLabel => taxonomy?.typeLabel ?? type?.label;
  final int? floorCount;
  final ProjectParking? parking;
  final List<String> features;

  String get floorLabel {
    final count = floorCount;
    if (count == null) return 'Floors not provided';
    if (count == 0) return 'No floors above grade';
    return count == 1 ? 'Ground floor' : 'G+${count - 1}';
  }

  Map<String, dynamic> toMap() => {
        if (type != null) 'type': type!.name,
        if (taxonomy != null) 'taxonomy': taxonomy!.toMap(),
        if (legacyLayout != null) 'legacyLayout': legacyLayout,
        if (requirements != null) 'requirements': requirements!.toMap(),
        'floorCount': floorCount,
        'parking': parking?.name,
        'features': features,
      };

  static ProjectBrief? fromMap(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final types = ProjectType.values.where((type) => type.name == value['type']);
    final parking = ProjectParking.values.where((p) => p.name == value['parking']);
    final taxonomy = TaxonomySelection.fromMap(value['taxonomy']);
    if (types.isEmpty && taxonomy == null) return null;
    final floorCount = value['floorCount'];
    final features = value['features'];
    return ProjectBrief(
      type: types.isEmpty ? null : types.first,
      taxonomy: taxonomy,
      legacyLayout: value['legacyLayout'] is String ? value['legacyLayout'] as String : null,
      requirements: ProjectRequirementsSnapshot.fromMap(value['requirements']),
      floorCount: floorCount is int && floorCount >= 0 ? floorCount : null,
      parking: parking.isEmpty ? null : parking.first,
      features: features is List ? features.whereType<String>() : const [],
    );
  }
}

/// Records user selections only. No code limits or assumptions are inferred.
class TaxonomySelection {
  TaxonomySelection({
    required this.version,
    required this.categoryId,
    required this.subcategoryId,
    required this.typeId,
    this.configurationId,
    this.actionId,
    this.stageId,
    this.plotShapeId,
    this.scenarioId,
    Map<String, int> spaceQuantities = const {},
  }) : spaceQuantities = Map.unmodifiable(spaceQuantities);

  final int version;
  final String categoryId;
  final String subcategoryId;
  final String typeId;
  final String? configurationId;
  final String? actionId;
  final String? stageId;
  final String? plotShapeId;
  final String? scenarioId;
  final Map<String, int> spaceQuantities;

  String get typeLabel {
    final group = taxonomyGroup(taxonomyCategory(categoryId), subcategoryId);
    return taxonomyChoice(group?.types ?? const [], typeId)?.label ?? typeId;
  }

  Map<String, dynamic> toMap() => {
        'version': version,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'typeId': typeId,
        'configurationId': configurationId,
        'actionId': actionId,
        'stageId': stageId,
        'plotShapeId': plotShapeId,
        if (scenarioId != null) 'scenarioId': scenarioId,
        'spaceQuantities': spaceQuantities,
      };

  static TaxonomySelection? fromMap(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final version = value['version'];
    final category = value['categoryId'];
    final group = value['subcategoryId'];
    final type = value['typeId'];
    if (version is! int || category is! String || group is! String || type is! String) return null;
    final spaces = value['spaceQuantities'];
    String? id(String key) => value[key] is String ? value[key] as String : null;
    return TaxonomySelection(
      version: version,
      categoryId: category,
      subcategoryId: group,
      typeId: type,
      configurationId: id('configurationId'),
      actionId: id('actionId'),
      stageId: id('stageId'),
      plotShapeId: id('plotShapeId'),
      scenarioId: id('scenarioId'),
      spaceQuantities: {
        if (spaces is Map<String, dynamic>)
          for (final entry in spaces.entries)
            if (entry.value is int && (entry.value as int) > 0) entry.key: entry.value as int,
      },
    );
  }
}
