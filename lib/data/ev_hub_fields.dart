import 'project_requirements.dart';

bool evHubEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'energy' && type == 'ev_charging_hub';

RequirementField _m(String key, String label, {double min = .001}) =>
    RequirementField(key, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: 300, required: true);

final evHubFields = <RequirementField>[
  const RequirementField('ev_count', 'Charging bay count, including one transfer bay', kind: RequirementKind.integer,
    min: 2, max: 40, required: true),
  _m('ev_offset_left', 'Pedestrian walk offset from plot left', min: 0),
  _m('ev_offset_front', 'First transfer strip offset from plot frontage'),
  _m('ev_bay_width', 'Standard bay width along the drive aisle'),
  _m('ev_access_width', 'Designated transfer bay width along the drive aisle'),
  _m('ev_bay_depth', 'Clear parking depth perpendicular to the drive aisle'),
  _m('ev_transfer', 'Clear side transfer strip width beside the designated bay'),
  _m('ev_aisle', 'Clear drive aisle width'),
  _m('ev_end', 'Clear drive aisle extension beyond the last bay'),
  _m('ev_walk', 'Clear pedestrian walkway width'),
  _m('ev_service', 'Width of charger equipment strip at bay heads'),
  _m('ev_pad_x', 'Each charger pad dimension across the equipment strip'),
  _m('ev_pad_y', 'Each charger pad dimension along the row'),
  _m('ev_head_pass', 'Minimum clear passage beside each charger pad'),
];
