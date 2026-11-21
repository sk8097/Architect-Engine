import 'project_requirements.dart';
import 'space_planning.dart';

bool promenadeCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' && type == 'waterfront_promenade';

final promenadeCadMode = planningChoice('promenade_mode', 'Waterfront drawing', {
  'survey_promenade': 'Surveyed promenade: path and lookout pads',
}, required: false);

RequirementField _m(String id, String label, {num min = .001, num max = 200}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final promenadeCadFields = <RequirementField>[
  const RequirementField('pmr_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('pmr_axis', 'Baseline A then B: Easting,Northing (m); separate with ; or newline', required: true),
  planningChoice('pmr_land_side', 'Direction of positive landward offsets, looking A to B', {'left': 'Left', 'right': 'Right'}),
  const RequirementField('pmr_limits', 'Samples: chainage, shoreline offset, inland limit offset (m); separate with ; or newline', required: true),
  _m('pmr_path', 'Signed offset to the shore-facing side of the constant-width path', min: -500, max: 500),
  _m('pmr_width', 'Clear width of the uninterrupted path'),
  _m('pmr_shore_gap', 'Minimum baseline-normal gap to the shoreline', min: 0),
  _m('pmr_inland_gap', 'Minimum baseline-normal gap to the inland limit', min: 0),
  const RequirementField('pmr_pads', 'Lookout pads: ID, start chainage, end chainage, shoreward projection (m); separate with ; or newline', required: true),
];
