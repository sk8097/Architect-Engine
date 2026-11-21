import 'project_requirements.dart';
import 'space_planning.dart';

const steppedWallMode = 'survey_stepped_landscape_wall';

bool steppedWallCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' && type == 'streetscape';

final steppedWallCadMode = planningChoice('stepped_wall_mode', 'Streetscape drawing', {
  steppedWallMode: 'Surveyed stepped landscape wall: profile and quantities',
}, required: false);

RequirementField _m(String id, String label, {num min = .001, num max = 20}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final steppedWallCadFields = <RequirementField>[
  const RequirementField('sw_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('sw_datum', 'Common elevation datum', required: true),
  const RequirementField('sw_axis', 'Straight wall centreline A then B: Easting,Northing (m); separate with ; or newline', required: true),
  planningChoice('sw_back_side', 'Higher ground (back) side looking from A toward B', {'left': 'Left', 'right': 'Right'}),
  const RequirementField('sw_ground', 'Samples: chainage, proposed front ground level, proposed back ground level (m); separate with ; or newline', required: true),
  const RequirementField('sw_steps', 'Steps: end chainage, base level, top level (m); separate with ; or newline', required: true),
  _m('sw_width', 'Constant horizontal wall thickness', max: 10),
  _m('sw_embed', 'Minimum wall base depth below front ground'),
  _m('sw_top_margin', 'Minimum wall top height above back ground', min: 0),
  _m('sw_visible_max', 'Maximum exposed wall height above front ground'),
];
