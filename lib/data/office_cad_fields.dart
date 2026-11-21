import 'project_requirements.dart';

const officeCadTypes = {'small_office', 'branch_office', 'professional_office', 'startup_office'};

const officeCadFields = <RequirementField>[
  RequirementField('office_visitor_depth', 'Clear front visitor passage depth',
    kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('office_desk_span', 'Desk width along each row',
    kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('office_desk_depth', 'Desk depth across the workspace',
    kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('office_chair_depth', 'Clear chair depth behind each desk',
    kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('office_aisle', 'Clear main and cross-aisle width',
    kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('office_desk_gap', 'Clear gap between desks along a row',
    kind: RequirementKind.decimal, unit: 'm', min: 0, max: 300, required: true),
];
