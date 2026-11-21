import 'project_requirements.dart';
import 'space_planning.dart';

const ductBankModeId = 'survey_duct_bank';

bool ductBankCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'energy' && type == 'telecom_network';

final ductBankCadMode = planningChoice('duct_bank_mode', 'Telecom network drawing', {
  ductBankModeId: 'Surveyed duct bank: cover and utility crossings',
}, required: false);

RequirementField _m(String id, String label, {num max = 20}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: .001, max: max, required: true);

final ductBankCadFields = <RequirementField>[
  const RequirementField('db_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('db_datum', 'Common elevation datum', required: true),
  const RequirementField('db_axis', 'Duct-bank centreline A then B: Easting,Northing (m); separate with ; or newline', required: true),
  const RequirementField('db_levels', 'Samples: chainage from A, ground level, proposed bank top level (m); separate with ; or newline', required: true),
  _m('db_width', 'Outside bank width, perpendicular to centreline'),
  _m('db_depth', 'Outside bank depth, measured vertically', max: 10),
  _m('db_cover', 'Submitted minimum vertical cover above bank top'),
  _m('db_gap', 'Submitted minimum vertical clearance at a recorded crossing'),
  const RequirementField('db_crossings', 'Crossings: ID, chainage, existing lower level, existing upper level (m); separate with ; or newline', required: true),
];
