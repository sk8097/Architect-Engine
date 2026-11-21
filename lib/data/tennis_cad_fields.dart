import 'project_requirements.dart';

bool tennisCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' &&
    const {'sports_complex', 'sports_club', 'training_centre', 'recreation_centre'}.contains(type);

RequirementField _metres(String id, String label, {num min = .001, num max = 300}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final tennisCadFields = <RequirementField>[
  const RequirementField('tc_count', 'Identical courts side by side', kind: RequirementKind.integer, min: 1, max: 4, required: true),
  _metres('tc_doubles', 'Doubles width between marking centrelines'),
  _metres('tc_singles', 'Singles width between marking centrelines'),
  _metres('tc_length', 'Length between baseline centrelines'),
  _metres('tc_service', 'Net centreline to each service line'),
  _metres('tc_mark', 'Baseline centre mark length into court'),
  _metres('tc_post', 'Net-post centre offset outside each doubles sideline'),
  _metres('tc_side', 'Side allowance outside each doubles sideline (includes net posts)'),
  _metres('tc_south_end', 'Run-off behind south baseline'),
  _metres('tc_north_end', 'Run-off behind north baseline'),
  _metres('tc_gap', 'Gap between adjacent run-off envelopes (zero for one court)', min: 0),
  _metres('tc_west', 'West edge of court bank from west plot edge', min: 0, max: 2000),
  _metres('tc_south', 'South edge of court bank from south plot edge', min: 0, max: 2000),
];
