import 'project_requirements.dart';
import 'space_planning.dart';

const underpassMode = 'survey_pedestrian_underpass';

bool underpassCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'transport' && type == 'underpass';

final underpassCadMode = planningChoice('underpass_mode', 'Underpass drawing', {
  underpassMode: 'Surveyed pedestrian underpass: grade and headroom',
}, required: false);

RequirementField _n(String id, String label, String unit, num min, num max) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final underpassCadFields = <RequirementField>[
  const RequirementField('up_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('up_datum', 'Common elevation datum', required: true),
  const RequirementField('up_axis', 'Straight walkway centreline A then B: Easting,Northing (m); separate with ; or newline', required: true),
  const RequirementField('up_walk', 'Walkway including both approaches: chainage, floor level (m); separate with ; or newline', required: true),
  const RequirementField('up_soffit', 'Covered span: chainage, underside level (m); first and last are portals; separate with ; or newline', required: true),
  _n('up_clear', 'Clear walkway width between walls', 'm', .001, 100),
  _n('up_min_width', 'Submitted minimum clear walkway width', 'm', .001, 100),
  _n('up_wall', 'Plan envelope thickness of each covered-span side wall', 'm', .001, 10),
  _n('up_corridor', 'Available total corridor width centred on baseline', 'm', .001, 200),
  _n('up_head', 'Submitted minimum vertical headroom in covered span', 'm', .001, 20),
  _n('up_grade', 'Submitted maximum absolute walkway grade including approaches', '%', 0, 100),
];
