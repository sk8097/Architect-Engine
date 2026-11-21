import 'project_requirements.dart';

bool athleticsTrackCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' &&
    const {'stadium', 'sports_complex', 'sports_club', 'training_centre'}.contains(type);

RequirementField _measure(String id, String label, {num min = .001, num max = 300}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final athleticsTrackCadFields = <RequirementField>[
  const RequirementField('ak_lanes', 'Equal-width running lanes', kind: RequirementKind.integer, min: 2, max: 10, required: true),
  _measure('ak_straight', 'Length of each straight between curve tangents'),
  _measure('ak_radius', 'Curve radius at the inside track boundary'),
  _measure('ak_lane_width', 'Width between adjacent lane boundaries', max: 10),
  _measure('ak_offset_1', 'Lane 1 measurement offset from its inner boundary', max: 10),
  _measure('ak_offset_other', 'Other lanes’ measurement offset from their inner boundary', max: 10),
  _measure('ak_runoff', 'Outside run-off reserve measured from outer lane boundary'),
  _measure('ak_west', 'Run-off envelope offset from west plot edge', min: 0, max: 2000),
  _measure('ak_south', 'Run-off envelope offset from south plot edge', min: 0, max: 2000),
  _measure('ak_target', 'Target lane 1 lap distance', max: 3000),
  _measure('ak_tolerance', 'Allowed absolute deviation from target lap distance', max: 100),
];
