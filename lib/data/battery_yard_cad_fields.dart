import 'project_requirements.dart';

const batteryYardMode = 'energy_measured_battery_yard';

bool batteryYardCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'energy' && type == 'battery_energy_storage';

RequirementField _length(String id, String label, {num min = .001, num max = 100}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final batteryYardCadFields = <RequirementField>[
  const RequirementField('by_pairs', 'Aligned equipment positions per row (two rows)', kind: RequirementKind.integer, min: 2, max: 100, required: true),
  const RequirementField('by_group', 'Maximum consecutive positions before each cross-aisle', kind: RequirementKind.integer, min: 1, max: 100, required: true),
  _length('by_w', 'Unit footprint width along the row (south–north)'),
  _length('by_d', 'Unit footprint depth across the row (west–east)'),
  _length('by_gap', 'Clear gap between units within a group'),
  _length('by_gap_min', 'Submitted minimum clear separation along each row'),
  _length('by_aisle', 'Clear central lane between the facing rows'),
  _length('by_aisle_min', 'Submitted minimum clear central lane'),
  _length('by_cross', 'Clear cross-aisle between groups (replaces the normal gap)'),
  _length('by_cross_min', 'Submitted minimum clear cross-aisle'),
  _length('by_rear', 'Clear reserve outside each row (west and east)'),
  _length('by_rear_min', 'Submitted minimum clear reserve outside each row'),
  _length('by_end', 'Clear reserve at each row end (south and north)'),
  _length('by_end_min', 'Submitted minimum clear reserve at the row ends'),
  _length('by_west', 'Entire yard envelope offset from west plot edge', min: 0, max: 2000),
  _length('by_south', 'Entire yard envelope offset from south plot edge', min: 0, max: 2000),
];
