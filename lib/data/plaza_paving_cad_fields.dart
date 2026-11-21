import 'project_requirements.dart';

const plazaPavingMode = 'plaza_measured_paving';

bool plazaPavingCadEligible(String? category, String? group, String? type) =>
    type == 'urban_plaza' && ((category == 'infrastructure' && group == 'public_realm') ||
      (category == 'institutional' && group == 'sports'));

RequirementField _m(String id, String label, {num min = .001, num max = 120}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final plazaPavingCadFields = <RequirementField>[
  _m('pav_w', 'Paving rectangle width (west–east)'),
  _m('pav_l', 'Paving rectangle depth (south–north)'),
  _m('pav_west', 'Paving rectangle offset from west plot edge', min: 0, max: 2000),
  _m('pav_south', 'Paving rectangle offset from south plot edge', min: 0, max: 2000),
  _m('pav_unit_x', 'Actual piece width, excluding joints', min: .05, max: 5),
  _m('pav_unit_y', 'Actual piece depth, excluding joints', min: .05, max: 5),
  _m('pav_joint', 'Joint width between adjoining pieces (no perimeter joint)', max: .10),
  _m('pav_min_x', 'Minimum installed piece width, including border cuts', max: 5),
  _m('pav_min_y', 'Minimum installed piece depth, including border cuts', max: 5),
];
