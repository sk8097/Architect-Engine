import 'project_requirements.dart';

bool sharedCoreCadEligible(String? category, String? group, String? type) =>
  category == 'mixed_use' && group == 'mixed_development' &&
    const {'office_plus_retail', 'shop_cum_office'}.contains(type);

const sharedCoreCadFields = <RequirementField>[
  RequirementField('sc_front_lobby', 'Clear shared ground-lobby depth', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('sc_upper_lobby', 'Minimum clear upper landing lobby depth', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('sc_shaft', 'Clear service shaft depth across the core strip', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('sc_approach', 'Clear width of shared frontage approach', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('sc_sales_depth', 'Clear front shop sales depth; remaining wing becomes stock', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('sc_meeting_depth', 'Clear front meeting room depth; remaining upper wing becomes workspace', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
];
