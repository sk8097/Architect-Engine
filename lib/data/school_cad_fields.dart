import 'project_requirements.dart';

const schoolCadTypes = {'primary_school'};

const schoolCadFields = <RequirementField>[
  RequirementField('school_lobby_depth', 'Clear visitor lobby depth to internal door', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm', required: true),
  RequirementField('school_entry_walk', 'Straight on-site entry walk width (optional)', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm'),
];
