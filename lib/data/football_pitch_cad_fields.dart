import 'project_requirements.dart';

const footballPitchMode = 'sports_measured_football_pitch';

bool footballPitchCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' &&
    const {'stadium', 'sports_complex', 'sports_club', 'training_centre'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 200}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final footballPitchCadFields = <RequirementField>[
  _m('fp_w', 'Marked pitch width west–east'),
  _m('fp_l', 'Marked pitch length south–north'),
  _m('fp_mouth', 'Goal-mouth width centred on each end line'),
  _m('fp_goal_w', 'Width of each goal area'),
  _m('fp_goal_d', 'Depth of each goal area from its end line'),
  _m('fp_pen_w', 'Width of each penalty area'),
  _m('fp_pen_d', 'Depth of each penalty area from its end line'),
  _m('fp_spot', 'Distance of each penalty spot from its end line'),
  _m('fp_arc', 'Penalty arc radius measured from the penalty spot'),
  _m('fp_centre', 'Centre circle radius'),
  _m('fp_corner', 'Corner arc radius'),
  _m('fp_side_run', 'Run-off beyond each touchline'),
  _m('fp_end_run', 'Run-off beyond each end line'),
  _m('fp_side_min', 'Submitted minimum touchline run-off'),
  _m('fp_end_min', 'Submitted minimum end-line run-off'),
  _m('fp_west', 'Full run-off envelope offset from west plot edge', min: 0, max: 2000),
  _m('fp_south', 'Full run-off envelope offset from south plot edge', min: 0, max: 2000),
];
