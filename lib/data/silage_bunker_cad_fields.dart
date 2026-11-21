import 'project_requirements.dart';

const silageBunkerMode = 'farm_measured_silage_bunker';

bool silageBunkerCadEligible(String? category, String? group, String? type) =>
    category == 'rural' && group == 'farm' && const {'dairy_farm', 'cattle_farm'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 150, String unit = 'm'}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final silageBunkerCadFields = <RequirementField>[
  _m('sb_w', 'Clear bunker width between side walls'),
  _m('sb_l', 'Horizontal clear length from south opening to rear wall'),
  _m('sb_wall', 'Uniform thickness of side and rear walls in plan', max: 10),
  _m('sb_rise', 'Rear floor elevation above south opening datum', max: 30),
  _m('sb_floor_max', 'Submitted maximum floor grade magnitude', unit: '%', max: 100),
  _m('sb_fill', 'Level fill crest above south opening datum', max: 30),
  _m('sb_face', 'Horizontal length of the rising fill face from opening to crest'),
  _m('sb_face_max', 'Submitted maximum fill-face grade from horizontal', unit: '%', max: 500),
  _m('sb_rim', 'Level wall top elevation above south opening datum', max: 30),
  _m('sb_free', 'Submitted minimum vertical gap between crest and wall top', max: 30),
  _m('sb_apron', 'Clear level apron length south of opening'),
  _m('sb_reserve', 'Service reserve outside both sides and the rear wall'),
  _m('sb_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _m('sb_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
  const RequirementField('sb_min_vol', 'Submitted minimum geometric fill volume', kind: RequirementKind.decimal,
    unit: 'm³', min: .001, max: 700000, required: true),
];
