import 'project_requirements.dart';

const transformerBundMode = 'energy_measured_transformer_bund';

bool transformerBundCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'energy' && type == 'transformer_yard';

RequirementField _m(String id, String label, {num min = .001, num max = 100}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final transformerBundCadFields = <RequirementField>[
  _m('tb_w', 'Clear inside bund width west–east'),
  _m('tb_l', 'Clear inside bund length south–north'),
  _m('tb_wall', 'Uniform perimeter wall thickness in plan', max: 10),
  _m('tb_rim', 'Wall rim height above the level bund floor', max: 30),
  _m('tb_fill', 'Submitted design fill level above the bund floor', max: 30),
  _m('tb_free_min', 'Submitted minimum vertical freeboard', max: 30),
  _m('tb_p_w', 'West–east width of each solid plinth'),
  _m('tb_p_l', 'South–north length of each solid plinth'),
  _m('tb_h_w', 'West plinth height above floor', max: 30),
  _m('tb_h_e', 'East plinth height above floor', max: 30),
  _m('tb_gap', 'Clear gap between the two centred plinths'),
  _m('tb_clear', 'Submitted minimum clear gap to inner walls and between plinths'),
  _m('tb_reserve', 'Clear service reserve outside each wall'),
  _m('tb_west', 'Full envelope offset from the west plot edge', min: 0, max: 2000),
  _m('tb_south', 'Full envelope offset from the south plot edge', min: 0, max: 2000),
  const RequirementField('tb_volume', 'Submitted minimum net geometric containment', kind: RequirementKind.decimal,
    unit: 'm³', min: .001, max: 300000, required: true),
];
