import 'project_requirements.dart';

const parkingRampMode = 'parking_measured_straight_ramp';

bool parkingRampCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'transport' && type == 'parking_structure';

RequirementField _n(String id, String label, {String unit = 'm', num min = .001, num max = 200}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final parkingRampCadFields = <RequirementField>[
  _n('vk_rise', 'Upper deck rise above lower landing datum', max: 50),
  _n('vk_run', 'Horizontal length of ramp between flat landings'),
  _n('vk_trans', 'Horizontal run of each end transition at half the main grade'),
  _n('vk_lower', 'Horizontal length of flat lower landing'),
  _n('vk_upper', 'Horizontal length of flat upper landing'),
  _n('vk_width', 'Clear straight drive strip width', max: 30),
  _n('vk_edge', 'Horizontal edge reserve on each side of drive strip', min: 0, max: 20),
  _n('vk_max_grade', 'Submitted maximum main ramp grade', unit: '%', max: 100),
  _n('vk_max_break', 'Submitted maximum absolute grade change at each break', unit: 'percentage points', max: 100),
  _n('vk_oh_start', 'Soffit start chainage from start of lower landing', min: 0, max: 600),
  _n('vk_oh_end', 'Soffit end chainage from start of lower landing', max: 600),
  _n('vk_oh_z0', 'Soffit level at start, above lower landing datum', max: 100),
  _n('vk_oh_z1', 'Soffit level at end, above lower landing datum', max: 100),
  _n('vk_head', 'Submitted minimum vertical centreline headroom', max: 30),
  _n('vk_west', 'Full ramp envelope offset from west plot edge', min: 0, max: 2000),
  _n('vk_south', 'Full ramp envelope offset from south plot edge', min: 0, max: 2000),
];
