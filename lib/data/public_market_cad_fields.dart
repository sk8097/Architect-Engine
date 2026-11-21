import 'project_requirements.dart';

bool publicMarketCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' && type == 'public_market';

RequirementField _m(String key, String label, {num min = .001}) =>
    RequirementField(key, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: 300, required: true);

final publicMarketCadFields = <RequirementField>[
  const RequirementField('pm_stalls', 'Identical stalls per row (two rows)', kind: RequirementKind.integer,
    min: 1, max: 24, required: true),
  _m('pm_pitch', 'Stall frontage along the shopping aisle'),
  _m('pm_depth', 'Stall depth measured away from the shopping aisle'),
  _m('pm_opening', 'Centred clear opening in each stall frontage'),
  _m('pm_aisle', 'Clear central shopping aisle width'),
  _m('pm_side', 'Clear outer passage width on each side'),
  _m('pm_entry_cross', 'Clear front cross-aisle depth'),
  _m('pm_rear_cross', 'Clear rear cross-aisle depth'),
  _m('pm_entry', 'Clear approach width from plot frontage'),
  _m('pm_left', 'Market envelope offset from plot left as seen from frontage', min: 0),
  _m('pm_front', 'Market envelope offset from plot frontage'),
];
