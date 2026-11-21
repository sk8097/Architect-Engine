import 'project_requirements.dart';

const aquaculturePondMode = 'farm_measured_aquaculture_pond';

bool aquaculturePondCadEligible(String? category, String? group, String? type) =>
    category == 'rural' && group == 'farm' && type == 'fish_farm_aquaculture';

RequirementField _measure(String id, String label, {num min = .001, num max = 150, String unit = 'm'}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final aquaculturePondCadFields = <RequirementField>[
  _measure('aqp_w', 'Level pond bottom width, east to west'),
  _measure('aqp_l', 'Level pond bottom length, south to north'),
  _measure('aqp_rise', 'Rim elevation above pond bottom', max: 30),
  _measure('aqp_run', 'Horizontal run from bottom toe to rim on each side'),
  _measure('aqp_water', 'Water elevation above pond bottom', max: 30),
  _measure('aqp_min_slope', 'Submitted minimum horizontal run per metre of rise', max: 100, unit: 'H:1V'),
  _measure('aqp_free', 'Submitted minimum vertical freeboard', max: 30),
  _measure('aqp_reserve', 'Clear service reserve beyond rim on all four sides'),
  _measure('aqp_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _measure('aqp_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
  _measure('aqp_min_vol', 'Submitted minimum geometric water volume', max: 6075000, unit: 'm³'),
];
