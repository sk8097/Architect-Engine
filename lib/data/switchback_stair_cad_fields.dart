import 'project_requirements.dart';

const switchbackStairMode = 'public_measured_switchback_stair';

bool switchbackStairCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' && const {'public_park', 'urban_plaza'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 25}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final switchbackStairCadFields = <RequirementField>[
  const RequirementField('ss_datum', 'Common elevation datum', required: true),
  _m('ss_lower', 'Lower south landing level', min: -10000, max: 10000),
  _m('ss_upper', 'Upper south landing level', min: -10000, max: 10000),
  _m('ss_min_riser', 'Submitted minimum uniform riser height', max: 1),
  _m('ss_max_riser', 'Submitted maximum uniform riser height', max: 1),
  _m('ss_going', 'Uniform horizontal going between consecutive risers', max: 5),
  _m('ss_width', 'Clear width of each flight'),
  _m('ss_gap', 'Horizontal separator reserve between the two flights', min: 0),
  _m('ss_end', 'Depth of each separate south landing'),
  _m('ss_turn', 'Depth of full-width north turn landing'),
  _m('ss_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _m('ss_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
];
