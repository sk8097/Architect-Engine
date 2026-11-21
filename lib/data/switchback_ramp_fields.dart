import 'project_requirements.dart';

bool switchbackRampEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' &&
    const {'public_park', 'public_garden', 'urban_plaza', 'playground'}.contains(type);

RequirementField _m(String key, String label, {num min = .001, num max = 300}) =>
    RequirementField(key, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final switchbackRampFields = <RequirementField>[
  const RequirementField('sr_datum', 'Survey source / common level datum', required: true),
  _m('sr_floor', 'Lower landing level', min: -10000, max: 10000),
  _m('sr_mid', 'Turn landing level', min: -10000, max: 10000),
  _m('sr_top', 'Upper landing level', min: -10000, max: 10000),
  _m('sr_run', 'Horizontal run of each equal-length flight'),
  _m('sr_width', 'Clear width of each parallel flight'),
  _m('sr_divider', 'Separator reserve between parallel flights', min: 0),
  _m('sr_end_depth', 'Depth of each front endpoint landing'),
  _m('sr_turn_depth', 'Depth of shared rear turning landing'),
  _m('sr_left', 'Left offset from plot edge', min: 0),
  _m('sr_front', 'Front offset from plot edge', min: 0),
  _m('sr_min_clear', 'Supplied minimum clear flight width'),
  _m('sr_min_landing', 'Supplied minimum square clear turning space at each landing'),
  _m('sr_max_rise', 'Supplied maximum rise per flight'),
  const RequirementField('sr_max_grade', 'Supplied maximum running slope of either flight', kind: RequirementKind.decimal,
    unit: '%', min: .001, max: 100, required: true),
];
