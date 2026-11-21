import 'project_requirements.dart';

bool inpatientWardEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'healthcare' &&
    const {'hospital', 'general_hospital', 'nursing_home'}.contains(type);

const inpatientWardFields = <RequirementField>[
  RequirementField('iw_lobby_depth', 'Clear depth of front nursing lobby and washroom reserve', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('iw_central', 'Clear centre aisle and approach width', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('iw_end_clear', 'Minimum clear depth at both ends of the ward', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('iw_bed_width', 'Bed footprint width parallel to the aisle', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('iw_bed_length', 'Bed footprint length perpendicular to the aisle', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('iw_bed_side', 'Clear access on each side of each bed', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('iw_bed_foot', 'Clear depth between bed foot and central aisle', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('iw_counter_length', 'Nursing counter length parallel to the aisle', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('iw_counter_depth', 'Nursing counter depth', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('iw_counter_work', 'Clear working depth behind nursing counter', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
];
