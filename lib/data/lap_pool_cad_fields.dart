import 'project_requirements.dart';

bool lapPoolCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' && type == 'swimming_pool';

RequirementField _m(String key, String label, {num min = .001, num max = 300}) =>
    RequirementField(key, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final lapPoolCadFields = <RequirementField>[
  _m('lp_length', 'Clear water length, shallow south to deep north'),
  const RequirementField('lp_lanes', 'Equal-width swim lanes', kind: RequirementKind.integer, min: 1, max: 12, required: true),
  _m('lp_lane_width', 'Clear width per lane', max: 20),
  _m('lp_side_margin', 'Water margin beyond outer lanes, each side', min: 0, max: 20),
  _m('lp_side_deck', 'Clear deck width on west and east sides'),
  _m('lp_south_deck', 'Clear deck width at shallow (south) end'),
  _m('lp_north_deck', 'Clear deck width at deep (north) end'),
  _m('lp_west', 'Deck envelope offset from west plot edge', min: 0),
  _m('lp_south', 'Deck envelope offset from south plot edge', min: 0),
  _m('lp_shallow_depth', 'Shallow water depth', max: 20),
  _m('lp_deep_depth', 'Deep water depth', max: 20),
  _m('lp_shallow_flat', 'Length of shallow flat floor'),
  _m('lp_deep_flat', 'Length of deep flat floor'),
  const RequirementField('lp_max_grade', 'Supplied maximum transition floor grade', kind: RequirementKind.decimal,
    unit: '%', min: .001, max: 100, required: true),
];
