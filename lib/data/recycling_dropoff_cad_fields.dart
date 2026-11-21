import 'project_requirements.dart';

const recyclingDropoffMode = 'waste_measured_recycling_dropoff';

bool recyclingDropoffCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' && type == 'recycling_centre';

RequirementField _length(String id, String label, {num min = .001, num max = 100}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final recyclingDropoffCadFields = <RequirementField>[
  const RequirementField('rd_min', 'Required minimum container bays', kind: RequirementKind.integer, min: 1, max: 60, required: true),
  const RequirementField('rd_cap', 'Maximum container bays to draw', kind: RequirementKind.integer, min: 1, max: 60, required: true),
  _length('rd_w', 'Container frontage along the row (west–east)'),
  _length('rd_d', 'Container footprint depth (south–north)'),
  _length('rd_gap', 'Clear gap between neighbouring containers'),
  _length('rd_end', 'Clear end reserve on each side of the row'),
  _length('rd_apron', 'Clear public drop-off apron south of the row'),
  _length('rd_apron_min', 'Submitted minimum clear public apron depth'),
  _length('rd_lane', 'Clear collection aisle north of the row'),
  _length('rd_lane_min', 'Submitted minimum clear rear collection depth'),
  _length('rd_south', 'Full drop-off envelope offset from the south plot edge', min: 0, max: 2000),
];
