import 'project_requirements.dart';

const bladeLaydownMode = 'energy_measured_blade_laydown';

bool bladeLaydownCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'energy' && type == 'wind_support_facility';

RequirementField _m(String id, String label, {num min = .001, num max = 250}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final bladeLaydownCadFields = <RequirementField>[
  _m('bl_length', 'Blade plan length from south root to north tip'),
  _m('bl_root', 'Full envelope width at root'),
  _m('bl_peak_ch', 'Chainage of widest blade envelope from root'),
  _m('bl_peak', 'Full width at widest chainage'),
  _m('bl_tip', 'Full envelope width at tip', min: 0),
  _m('bl_a_ch', 'South pad reserve centre chainage from root'),
  _m('bl_b_ch', 'North pad reserve centre chainage from root'),
  _m('bl_pad_l', 'Along-blade length of each pad reserve'),
  _m('bl_a_w', 'Clear width of south pad reserve'),
  _m('bl_b_w', 'Clear width of north pad reserve'),
  _m('bl_min_margin', 'Submitted minimum pad margin on each side of the blade outline', min: 0),
  _m('bl_min_gap', 'Submitted minimum positive gap between pad reserves'),
  _m('bl_side', 'Clear side reserve beyond the widest blade or pad'),
  _m('bl_end', 'Clear reserve beyond each blade end'),
  _m('bl_west', 'Offset of the full envelope from the west plot edge', min: 0, max: 2000),
  _m('bl_south', 'Offset of the full envelope from the south plot edge', min: 0, max: 2000),
];
