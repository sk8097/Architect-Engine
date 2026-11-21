import 'project_requirements.dart';

const weighbridgeMode = 'transport_measured_freight_weighbridge';

bool weighbridgeCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'transport' && type == 'freight_terminal';

RequirementField _m(String id, String label, {num min = .001, num max = 200}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final weighbridgeCadFields = <RequirementField>[
  _m('wb_plate_l', 'Clear weighing platform length'),
  _m('wb_plate_w', 'Clear weighing platform width'),
  _m('wb_approach_s', 'Clear south approach length before platform'),
  _m('wb_approach_n', 'Clear north approach length after platform'),
  _m('wb_lane', 'Clear width of weighing corridor'),
  _m('wb_split', 'Separator strip between corridor and east bypass'),
  _m('wb_bypass', 'Clear width of straight east bypass reserve'),
  _m('wb_axle_edge', 'Submitted minimum distance from axle centre to a platform end', min: 0),
  _m('wb_side_clear', 'Submitted minimum each-side clearance for vehicle body and tyre envelope', min: 0),
  _m('wb_body', 'Truck body width'),
  _m('wb_tyre', 'Largest full tyre envelope width across the axles'),
  _m('wb_wheelbase', 'Front axle to forward rear axle distance'),
  _m('wb_tandem', 'Distance between the two rear axles'),
  _m('wb_front_oh', 'Truck body overhang ahead of front axle', min: 0),
  _m('wb_rear_oh', 'Truck body overhang behind rearmost axle', min: 0),
  _m('wb_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _m('wb_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
];
