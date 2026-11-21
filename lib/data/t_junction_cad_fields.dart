import 'project_requirements.dart';
import 'space_planning.dart';

final tJunctionCadMode = planningChoice('junction_cad_mode', 'Junction drawing', {
  'survey_t': 'Survey controls: orthogonal T-junction CAD',
}, required: false);

const tJunctionCadFields = <RequirementField>[
  RequirementField('junction_grid', 'Projected survey grid / CRS', required: true),
  RequirementField('junction_reference', 'Junction survey reference', required: true),
  RequirementField('junction_controls', 'Easting,Northing in m: main A; junction J; main B; branch C', required: true),
  RequirementField('junction_main_width', 'Main carriageway width', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 1000, required: true),
  RequirementField('junction_branch_width', 'Branch carriageway width', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 1000, required: true),
  RequirementField('junction_main_row', 'Full main road right-of-way width', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 1000, required: true),
  RequirementField('junction_branch_row', 'Full branch right-of-way width', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 1000, required: true),
  RequirementField('junction_a_radius', 'Curb-return radius on main A side', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 1000, required: true),
  RequirementField('junction_b_radius', 'Curb-return radius on main B side', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 1000, required: true),
];
