import 'project_requirements.dart';

const jumpRunwayMode = 'sports_measured_jump_runway';

bool jumpRunwayCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' &&
    const {'stadium', 'sports_complex', 'sports_club', 'training_centre'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 120}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final jumpRunwayCadFields = <RequirementField>[
  _m('jr_run_l', 'Runway length from south start to near sand edge'),
  _m('jr_run_w', 'Clear paved runway width', max: 20),
  _m('jr_pit_l', 'Usable sand pit length, along direction of travel', max: 30),
  _m('jr_pit_w', 'Usable sand pit width, centred on runway', max: 20),
  _m('jr_long_offset', 'Long-jump take-off line to near sand edge', max: 30),
  _m('jr_triple_offset', 'Triple-jump take-off line to near sand edge', max: 30),
  _m('jr_long_run_min', 'Submitted minimum approach to long-jump line'),
  _m('jr_triple_run_min', 'Submitted minimum approach to triple-jump line'),
  _m('jr_long_far_min', 'Submitted minimum long-jump line to far sand edge'),
  _m('jr_triple_far_min', 'Submitted minimum triple-jump line to far sand edge'),
  _m('jr_side', 'Side reserve beyond each side edge of the sand pit', max: 25),
  _m('jr_south_reserve', 'Clear reserve behind runway start', max: 25),
  _m('jr_north_reserve', 'Clear reserve beyond far sand edge', max: 25),
  _m('jr_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _m('jr_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
];
