import 'project_requirements.dart';

const boulderingBayMode = 'sports_measured_bouldering_bay';

bool boulderingBayCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' && const {'indoor_arena', 'sports_complex', 'recreation_centre'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 100, String unit = 'm'}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final boulderingBayCadFields = <RequirementField>[
  _m('bb_hall_w', 'Clear hall width west–east'),
  _m('bb_hall_l', 'Clear hall depth south–north'),
  _m('bb_hall_h', 'Clear overhead elevation above the finished mat datum', max: 30),
  _m('bb_wall_w', 'Clear width of both climbing panels'),
  _m('bb_lower', 'Vertical rise of lower panel', max: 30),
  _m('bb_upper', 'Vertical rise of upper panel', max: 30),
  _m('bb_throw', 'South projection of upper lip from wall foot'),
  _m('bb_max_angle', 'Submitted maximum upper panel angle from vertical', max: 89.999, unit: 'degrees'),
  _m('bb_above', 'Submitted minimum vertical clearance above the lip'),
  _m('bb_mat', 'Mat plan depth south from wall foot'),
  _m('bb_beyond', 'Submitted minimum mat depth remaining beyond the lip projection'),
  _m('bb_side', 'Mat extension on each side of the wall'),
  _m('bb_access', 'Separate clear plan strip south of the mat'),
  _m('bb_rear', 'Horizontal reserve behind wall foot to the north hall face'),
  _m('bb_west', 'Clear hall offset from west plot edge', min: 0, max: 2000),
  _m('bb_south', 'Clear hall offset from south plot edge', min: 0, max: 2000),
];
