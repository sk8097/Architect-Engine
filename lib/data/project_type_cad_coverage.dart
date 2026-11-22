import 'concept_zoning_profiles.dart';
import 'project_cad_options.dart';
import 'typology_bay_cad_fields.dart';
import 'project_requirements.dart' show usesLinearSite;
import 'project_scenarios.dart';
import 'project_taxonomy.dart';

/// Coverage means the route is offered, not that a particular design fits.
class ProjectTypeCadCoverage {
  ProjectTypeCadCoverage(this.category, this.group, this.type);
  final TaxonomyCategory category;
  final TaxonomyGroup group;
  final TaxonomyChoice type;

  String get id => '${category.id}/${group.id}/${type.id}';
  bool get highRise => id == 'special/complex/high_rise_supertall_building';
  bool get zoning => zoningProfile(group, type) != null;
  bool get linear => usesLinearSite(category.id, group.id, type.id);
  bool get offersEnclosed => !linear && !highRise;
  bool get registeredHouse => configurations.any((s) => s.generator != null);
  late final configurations = [for (final option in taxonomyProgram(group, type).configurations)
    scenarioFor(category.id, group.id, type.id, option.id)!];
  late final specialists = highRise
      ? const <TaxonomyChoice>[]
      : ProjectCadOptions(category.id, group.id, type.id)
          .specialistChoices(linearSite: linear)
          .where((o) => o.id != typologyBayMode)
          .toList(growable: false);

  bool get hasDedicatedRoute => highRise || registeredHouse || specialists.isNotEmpty;
}

final projectTypeCadCoverage = Map<String, ProjectTypeCadCoverage>.unmodifiable({
  for (final category in projectTaxonomy)
    for (final group in category.groups)
      for (final type in group.types)
        '${category.id}/${group.id}/${type.id}': ProjectTypeCadCoverage(category, group, type),
});

String projectTypeCadCoverageCsv() {
  String q(String value) => '"${value.replaceAll('"', '""')}"';
  return [
    'type_path,category,subcategory,project_type,configurations,zoning_route,enclosed_picker,high_rise_route,registered_house_configurations,specialist_mode_ids,finish_takeoff',
    for (final entry in projectTypeCadCoverage.values) [
      q(entry.id), q(entry.category.label), q(entry.group.label), q(entry.type.label),
      q(entry.configurations.map((s) => s.configuration!.id).join('; ')), '${entry.zoning}', '${entry.offersEnclosed}',
      '${entry.highRise}', q(entry.configurations.where((s) => s.generator != null).map((s) => s.configuration!.id).join('; ')),
      q(entry.specialists.map((s) => s.id).join('; ')), 'true',
    ].join(','),
    '',
  ].join('\r\n');
}
