import 'project_requirements.dart';
import 'space_planning.dart';

const packhouseCadTypes = {'fruit_vegetable_packhouse'};

final packhouseCadFields = <RequirementField>[
  planningChoice('ph_access', 'Handling scope and opposite-side access', {
    'confirmed': 'Dry ambient handling only; clear on-site access at both ends confirmed',
    'pending': 'Not confirmed or another workflow needed',
  }),
  const RequirementField('ph_transfer', 'Clear width of each internal transfer opening', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm', required: true),
  const RequirementField('ph_end_opening', 'Clear width of receiving and dispatch openings', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm', required: true),
  const RequirementField('ph_route', 'Clear goods route width through all stages', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm', required: true),
  const RequirementField('ph_apron_width', 'Clear width of front and rear handling pads', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm', required: true),
  const RequirementField('ph_receiving_apron', 'Front receiving pad depth', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm', required: true),
  const RequirementField('ph_dispatch_apron', 'Rear dispatch pad depth', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm', required: true),
];
