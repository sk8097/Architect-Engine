import 'project_requirements.dart';
import 'space_planning.dart';

const stormwaterCadTypes = {'stormwater_drain', 'drainage_network'};

final stormwaterCadMode = planningChoice('drain_cad_mode', 'Drainage drawing', {
  'survey_open_drain': 'Open stormwater drain: surveyed trapezoidal reach',
  'survey_gravity': 'Gravity stormwater: surveyed plan and pipe profile',
}, required: false);

final stormwaterCadFields = <RequirementField>[
  const RequirementField('dr_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('dr_reference', 'Survey source and elevation datum', required: true),
  const RequirementField('dr_nodes', 'Upstream to downstream: ID,Easting,Northing,ground,invert (m); one row per line or separated by ;', required: true),
  const RequirementField('dr_ground', 'Optional intervening surface points: chainage,ground level (m); start chainage is 0'),
  const RequirementField('dr_crown_rise', 'Vertical rise from invert to outside pipe crown', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 20, required: true),
  const RequirementField('dr_cover', 'Supplied minimum ground-to-crown cover', kind: RequirementKind.decimal, unit: 'm', min: 0, max: 100, required: true),
  const RequirementField('dr_min_grade', 'Supplied minimum downstream fall', kind: RequirementKind.decimal, unit: '%', min: 0, max: 100, required: true),
  planningChoice('dr_exaggeration', 'Profile vertical exaggeration (also applies in DXF)', {
    '1': '1× true scale', '5': '5× vertical', '10': '10× vertical',
  }, required: false),
];
