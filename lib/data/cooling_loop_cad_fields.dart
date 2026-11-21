import 'project_requirements.dart';

const coolingLoopMode = 'energy_measured_cooling_pipe_loop';

bool coolingLoopCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'energy' && type == 'district_cooling';

RequirementField _m(String id, String label, {num min = .001, num max = 200}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final coolingLoopCadFields = <RequirementField>[
  _m('cl_r', 'Centreline radius of each of the four quarter bends'),
  _m('cl_min_r', 'Submitted minimum centreline bend radius'),
  _m('cl_od', 'Total outside diameter including insulation, if present'),
  _m('cl_clear', 'Clear reserve beyond the outside pipe on each side'),
  _m('cl_w_lead', 'West tie-in straight length before the first bend'),
  _m('cl_e_lead', 'East tie-in straight length after the last bend'),
  _m('cl_leg', 'Straight length along each north–south leg between tangents'),
  _m('cl_bridge', 'Straight length along the north link between tangents'),
  _m('cl_west', 'Full envelope offset from the west plot edge', min: 0, max: 2000),
  _m('cl_south', 'Full envelope offset from the south plot edge', min: 0, max: 2000),
];
