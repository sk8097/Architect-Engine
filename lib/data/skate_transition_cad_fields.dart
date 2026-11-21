import 'project_requirements.dart';

const skateTransitionMode = 'public_measured_skate_transition';

bool skateTransitionCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' && const {'public_park', 'playground'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 100, String unit = 'm'}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final skateTransitionCadFields = <RequirementField>[
  _m('st_r', 'Circular transition radius', max: 50),
  _m('st_rise', 'Lip elevation above the flat run-in', max: 50),
  _m('st_angle', 'Submitted maximum tangent angle at the lip', max: 90, unit: 'degrees'),
  _m('st_width', 'Clear surface width, west–east'),
  _m('st_runin', 'Flat run-in length south of the curve'),
  _m('st_min_runin', 'Submitted minimum flat run-in length'),
  _m('st_deck', 'Flat deck length north of the lip'),
  _m('st_min_deck', 'Submitted minimum flat deck length'),
  _m('st_side', 'Plan reserve on each side of the surface'),
  _m('st_end', 'Plan reserve beyond each end of the surface'),
  _m('st_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _m('st_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
];
