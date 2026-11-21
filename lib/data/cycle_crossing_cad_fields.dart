import 'project_requirements.dart';
import 'space_planning.dart';

const cycleCrossingMode = 'survey_cycle_crossings';

bool cycleCrossingCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'transport' && type == 'cycle_track';

RequirementField _m(String id, String label, {num min = .001, num max = 50}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final cycleCrossingCadFields = <RequirementField>[
  const RequirementField('cyc_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('cyc_axis', 'Straight road edge A then B: Easting,Northing (m); separate with ; or newline', required: true),
  planningChoice('cyc_side', 'Cycle track side, looking from A toward B', {'left': 'Left', 'right': 'Right'}),
  const RequirementField('cyc_limits', 'Roadside limit: chainage, outward offset (m); separate with ; or newline', required: true),
  _m('cyc_buffer', 'Separator width from road edge to cycle track'),
  _m('cyc_width', 'Clear cycle track width'),
  _m('cyc_margin', 'Minimum gap from track to roadside limit', min: 0),
  _m('cyc_island', 'Minimum uninterrupted separator between successive driveways'),
  const RequirementField('cyc_driveways', 'Driveways: ID, start chainage, end chainage (m); separate with ; or newline', required: true),
];
