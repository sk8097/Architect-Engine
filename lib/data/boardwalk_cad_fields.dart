import 'project_requirements.dart';

const boardwalkMode = 'public_measured_raised_boardwalk';

bool boardwalkCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' && const {'public_park', 'public_garden'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 150}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final boardwalkCadFields = <RequirementField>[
  _m('bw_length', 'Deck length south–north'),
  _m('bw_width', 'Deck width west–east'),
  _m('bw_top', 'Level deck-top elevation (common datum)', min: -200, max: 10000),
  _m('bw_thick', 'Depth from deck top to continuous soffit', max: 10),
  _m('bw_z0', 'Centreline ground elevation at south deck end', min: -200, max: 10000),
  _m('bw_ch', 'Chainage of interior ground break from south deck end'),
  _m('bw_zm', 'Centreline ground elevation at interior break', min: -200, max: 10000),
  _m('bw_z1', 'Centreline ground elevation at north deck end', min: -200, max: 10000),
  _m('bw_clear', 'Submitted minimum vertical soffit-to-ground gap'),
  _m('bw_first', 'South deck end to first support-pair centreline'),
  _m('bw_last', 'North deck end to last support-pair centreline'),
  _m('bw_overhang', 'Submitted maximum end overhang to support centreline'),
  _m('bw_spacing', 'Submitted maximum pitch between support pairs'),
  _m('bw_post', 'Side of each square support footprint', max: 10),
  _m('bw_inset', 'Support centre inset from each side of deck'),
  _m('bw_reserve', 'Clear plan reserve beyond each side and end of deck'),
  _m('bw_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _m('bw_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
];
