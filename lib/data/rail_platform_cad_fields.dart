import 'project_requirements.dart';
import 'space_planning.dart';

bool railPlatformCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'transport' && const {'railway_station', 'metro_station'}.contains(type);

final railPlatformCadMode = planningChoice('rail_platform_mode', 'Rail platform drawing', {
  'survey_side_platform': 'Surveyed side platform: track offset and cross-section',
}, required: false);

RequirementField _n(String id, String label, String unit, num min, num max) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final railPlatformCadFields = <RequirementField>[
  const RequirementField('rp_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('rp_datum', 'Common elevation datum and reference rail', required: true),
  const RequirementField('rp_axis', 'Track centreline controls A then B: Easting,Northing (m); separate with ; or newline', required: true),
  const RequirementField('rp_levels', 'Samples: chainage from A, reference rail level, platform edge level (m); separate with ; or newline', required: true),
  planningChoice('rp_side', 'Platform side looking from A toward B', {'left': 'Left', 'right': 'Right'}),
  _n('rp_offset', 'Perpendicular offset from track centreline to platform edge', 'm', .001, 100),
  _n('rp_min_offset', 'Submitted minimum static offset to platform edge', 'm', .001, 100),
  _n('rp_width', 'Total platform width perpendicular to track', 'm', .001, 100),
  _n('rp_edge_band', 'Reserved strip behind track-side platform edge', 'm', .001, 100),
  _n('rp_back_band', 'Reserve along back of platform', 'm', 0, 100),
  _n('rp_walk_min', 'Minimum clear width between the two reserves', 'm', .001, 100),
  _n('rp_crossfall', 'Submitted crossfall away from track', '%', 0, 20),
  _n('rp_rise_min', 'Minimum signed platform edge level minus reference rail level', 'm', -10, 10),
  _n('rp_rise_max', 'Maximum signed platform edge level minus reference rail level', 'm', -10, 10),
  _n('rp_grade_max', 'Maximum absolute longitudinal platform-edge grade', '%', 0, 25),
];
