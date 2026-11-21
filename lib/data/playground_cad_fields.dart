import 'project_requirements.dart';

bool playgroundCadEligible(String? category, String? group, String? type) =>
    type == 'playground' && ((category == 'institutional' && group == 'sports') ||
      (category == 'infrastructure' && group == 'public_realm'));

final playgroundCadFields = <RequirementField>[
  const RequirementField('py_path_west', 'Path west edge offset from the west plot edge',
    kind: RequirementKind.decimal, unit: 'm', min: 0, max: 2000, required: true),
  const RequirementField('py_path_width', 'Clear north–south path width between setbacks',
    kind: RequirementKind.decimal, unit: 'm', min: .001, max: 100, required: true),
  const RequirementField('py_gap', 'Minimum separation between zones and from zones to path',
    kind: RequirementKind.decimal, unit: 'm', min: 0, max: 100, required: true),
];

const playgroundCadEquipment = RequirementField('py_equipment',
  'Equipment: ID, west offset, south offset, width, depth, west clearance, east clearance, south clearance, north clearance (m). Separate records with a new line or semicolon.',
  required: true);
