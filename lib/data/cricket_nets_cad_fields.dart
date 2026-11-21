import 'project_requirements.dart';

const cricketNetsMode = 'sports_measured_cricket_nets';

bool cricketNetsCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' &&
    const {'stadium', 'sports_complex', 'sports_club', 'training_centre'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 150}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final cricketNetsCadFields = <RequirementField>[
  const RequirementField('cn_count', 'Number of parallel practice lanes', kind: RequirementKind.integer, min: 1, max: 12, required: true),
  _m('cn_w', 'Clear lane width west–east'),
  _m('cn_gap', 'Separator strip between lanes (zero uses a shared side line)', min: 0),
  _m('cn_pitch', 'Wicket-to-wicket distance south–north'),
  _m('cn_runup', 'Clear south run-up to the bowler wicket line'),
  _m('cn_min_runup', 'Submitted minimum run-up to the bowler wicket line'),
  _m('cn_rear', 'Clear north depth behind the batter wicket line'),
  _m('cn_min_rear', 'Submitted minimum depth behind the batter wicket line'),
  _m('cn_crease', 'Total length of each transverse crease mark'),
  _m('cn_pop', 'Popping crease offset infield from each wicket line'),
  _m('cn_return_w', 'Separation between each pair of return creases'),
  _m('cn_return_l', 'Length of each return crease from popping crease toward its wicket end'),
  _m('cn_side', 'Clear reserve outside the west and east sides of the lane bank'),
  _m('cn_end', 'Clear reserve beyond each end of the lane bank'),
  _m('cn_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _m('cn_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
];
