import 'project_requirements.dart';

const refugeCrossingMode = 'survey_staggered_refuge';

bool refugeCrossingCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'transport' && type == 'street';

RequirementField _m(String id, String label, {num min = .001, num max = 100}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final refugeCrossingCadFields = <RequirementField>[
  const RequirementField('ref_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('ref_axis', 'Median centreline A then B: Easting,Northing (m); separate with ; or newline', required: true),
  _m('ref_ch_l', 'Left crossing centre chainage from A', min: 0, max: 2000),
  _m('ref_ch_r', 'Right crossing centre chainage from A', min: 0, max: 2000),
  _m('ref_road_l', 'Left carriageway width between median and roadside edge'),
  _m('ref_road_r', 'Right carriageway width between median and roadside edge'),
  _m('ref_median', 'Total measured median width'),
  _m('ref_cross_w', 'Clear width of each crossing opening, along the median axis'),
  _m('ref_walk_w', 'Clear width of the centred longitudinal median walk'),
  _m('ref_min_w', 'Submitted minimum clear width for both crossings and median walk'),
  _m('ref_reserve', 'Minimum median reserve on each side of the connecting walk between openings', min: 0),
  _m('ref_stagger', 'Minimum clear longitudinal gap between the two opening windows'),
  _m('ref_land_l', 'Measured depth available and drawn at the left roadside landing'),
  _m('ref_land_r', 'Measured depth available and drawn at the right roadside landing'),
  _m('ref_min_land', 'Submitted minimum roadside landing depth'),
];
