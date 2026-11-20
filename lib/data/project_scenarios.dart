import 'project_taxonomy.dart';

/// A generator is assigned only to a scenario with an implemented layout.
enum ScenarioGenerator { house1Bhk, house2Bhk }

class ProjectScenario {
  const ProjectScenario(this.category, this.group, this.type, this.configuration);

  final TaxonomyCategory category;
  final TaxonomyGroup group;
  final TaxonomyChoice type;
  final TaxonomyChoice? configuration;

  static const unspecified = 'unspecified';
  String get id => key(category.id, group.id, type.id, configuration?.id);
  String get label => '${type.label} / ${configuration?.label ?? 'No configuration specified'}';
  String get path => '${category.label} › ${group.label}';
  ScenarioGenerator? get generator => _implementedScenarios[id];

  /// These are separate catalogue entries, not claims of generator support.
  bool get hasHouseVariants => category.id == 'residential' && group.id == 'houses' &&
      const {'1_rk', '1_bhk', '2_bhk', '3_bhk', '4_bhk', '5_bhk', '6_plus_bhk'}.contains(configuration?.id);

  static String key(String category, String group, String type, String? configuration) =>
      '$category/$group/$type/${configuration ?? unspecified}';
}

class ProjectScenarioVariant {
  const ProjectScenarioVariant(this.scenario, this.floors, this.parkingId);
  final ProjectScenario scenario;
  final int floors;
  final String parkingId;

  String get id => '${scenario.id}/floors_$floors/parking_$parkingId';
  String get label => '${floors == 1 ? 'Ground floor' : 'G+${floors - 1}'} / ${scenarioParkingLabels[parkingId]}';
  ScenarioGenerator? get generator => floors == 1 && parkingId == 'none' ? scenario.generator : null;
}

// These IDs match ProjectParking's persisted names.
const scenarioParkingLabels = {
  'none': 'No parking', 'car': 'Car parking',
  'twoWheeler': 'Two-wheeler parking', 'both': 'Car + two-wheeler parking',
};

// Explicit registration per scenario. Similar plans are allowed to share an
// engine without inheriting capabilities from a different project type.
const _implementedScenarios = {
  'residential/houses/detached_house/1_bhk': ScenarioGenerator.house1Bhk,
  'residential/houses/detached_house/2_bhk': ScenarioGenerator.house2Bhk,
  'residential/houses/independent_house/1_bhk': ScenarioGenerator.house1Bhk,
  'residential/houses/independent_house/2_bhk': ScenarioGenerator.house2Bhk,
  'residential/houses/bungalow/1_bhk': ScenarioGenerator.house1Bhk,
  'residential/houses/bungalow/2_bhk': ScenarioGenerator.house2Bhk,
  'residential/houses/villa/1_bhk': ScenarioGenerator.house1Bhk,
  'residential/houses/villa/2_bhk': ScenarioGenerator.house2Bhk,
  'residential/houses/farmhouse/1_bhk': ScenarioGenerator.house1Bhk,
  'residential/houses/farmhouse/2_bhk': ScenarioGenerator.house2Bhk,
};

final projectScenarios = List<ProjectScenario>.unmodifiable([
  for (final category in projectTaxonomy)
    for (final group in category.groups)
      for (final type in group.types) ...[
        ProjectScenario(category, group, type, null),
        for (final configuration in taxonomyProgram(group, type).configurations)
          ProjectScenario(category, group, type, configuration),
      ],
]);

final _scenariosById = Map<String, ProjectScenario>.unmodifiable({
  for (final item in projectScenarios) item.id: item,
});

ProjectScenario? scenarioFor(String? category, String? group, String? type, String? configuration) {
  if (category == null || group == null || type == null) return null;
  return _scenariosById[ProjectScenario.key(category, group, type, configuration)];
}

/// An explicit selection wins. Otherwise resolve a scenario only from an
/// explicit bedroom count for a program that offers that exact BHK option.
/// The saved configuration field stays exactly as the user entered it.
ProjectScenario? scenarioForRequirements(String? category, String? group,
    String? type, String? configuration, Object? bedroomCount) {
  if (configuration == null && category == 'residential' && group == 'houses' &&
      bedroomCount is int && bedroomCount > 0) {
    final derived = scenarioFor(category, group, type,
      bedroomCount >= 6 ? '6_plus_bhk' : '${bedroomCount}_bhk');
    if (derived != null) return derived;
  }
  return scenarioFor(category, group, type, configuration);
}

/// Common named variants appear together in the library. Other floor counts
/// can be recorded in a brief but are not batch generation capabilities.
Iterable<ProjectScenarioVariant> libraryVariants(ProjectScenario scenario) => [
  if (scenario.hasHouseVariants)
    for (final floors in [1, 2])
      for (final parking in scenarioParkingLabels.keys)
        ProjectScenarioVariant(scenario, floors, parking),
];

ProjectScenarioVariant? scenarioVariantFor(ProjectScenario scenario, int? floors, String? parking) =>
    scenario.hasHouseVariants && floors != null && (floors == 1 || floors == 2) &&
      parking != null && scenarioParkingLabels.containsKey(parking)
        ? ProjectScenarioVariant(scenario, floors, parking) : null;
