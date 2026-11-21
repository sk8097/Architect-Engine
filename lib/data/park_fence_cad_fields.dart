import 'project_requirements.dart';

const parkFenceMode = 'public_measured_park_fence';

bool parkFenceCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' &&
    const {'public_park', 'public_garden', 'playground'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 500}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final parkFenceCadFields = <RequirementField>[
  _m('pf_w', 'West–east span between corner post centres'),
  _m('pf_d', 'South–north span between corner post centres'),
  _m('pf_post', 'Side of every square post footprint', max: 5),
  _m('pf_gate_x', 'Distance east from southwest post centre to start of clear gate opening'),
  _m('pf_gate_w', 'Clear width between south gate post faces'),
  _m('pf_gate_min', 'Submitted minimum clear gate width'),
  _m('pf_min', 'Minimum clear panel span between adjacent post faces'),
  _m('pf_max', 'Maximum clear panel span between adjacent post faces'),
  _m('pf_west', 'Full fence footprint offset from west plot edge', min: 0, max: 2000),
  _m('pf_south', 'Full fence footprint offset from south plot edge', min: 0, max: 2000),
];
