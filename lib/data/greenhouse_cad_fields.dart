import 'project_requirements.dart';
import 'project_taxonomy.dart';

const greenhouseIrrigationOptions = [
  TaxonomyChoice('none', 'No irrigation linework'),
  TaxonomyChoice('layout_only', 'Concept routes to bench centerlines'),
];

bool greenhouseCadEligible(String? category, String? group, String? type) =>
  category == 'rural' && group == 'farm' && type == 'greenhouse_farm';

const greenhouseCadFields = <RequirementField>[
  RequirementField('gh_pair_rows', 'Parallel bench rows on each side of the main aisle', kind: RequirementKind.integer, min: 1, max: 16, required: true),
  RequirementField('gh_bench_width', 'Growing bench width', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('gh_bench_length', 'Length of each bench section', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('gh_bench_aisle', 'Clear gap between rows and outside bench banks', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('gh_main_aisle', 'Clear longitudinal main aisle width', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('gh_cross_aisle', 'Clear cross-aisle between front and rear bench sections', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('gh_front_clear', 'Minimum clear working depth at front', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('gh_rear_clear', 'Minimum clear working depth at rear', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('gh_irrigation', 'Show conceptual irrigation routing?', kind: RequirementKind.choice,
    options: greenhouseIrrigationOptions),
];
