import 'project_requirements.dart';
import 'space_planning.dart';

const streetLightMode = 'survey_equal_poles';

bool streetLightCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'energy' && type == 'street_lighting_network';

final streetLightCadMode = planningChoice('street_light_mode', 'Street lighting drawing', {
  streetLightMode: 'Surveyed pole row: equal spacing and exclusions',
}, required: false);

RequirementField _m(String id, String label, {num min = .001, num max = 2000}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final streetLightCadFields = <RequirementField>[
  const RequirementField('sl_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('sl_axis', 'Straight roadside baseline A then B: Easting,Northing (m); separate with ; or newline', required: true),
  planningChoice('sl_side', 'Pole side looking from A to B', {'left': 'Left', 'right': 'Right'}),
  _m('sl_offset', 'Perpendicular offset from baseline to pole centres', max: 100),
  _m('sl_start', 'Fixed first pole chainage from A', min: 0),
  _m('sl_end', 'Fixed last pole chainage from A', min: 0),
  _m('sl_min', 'Minimum pole-centre spacing', max: 500),
  _m('sl_max', 'Maximum pole-centre spacing', max: 500),
  const RequirementField('sl_exclusions', 'Optional no-pole windows: start,end chainages (m); separate with ; or newline'),
];
