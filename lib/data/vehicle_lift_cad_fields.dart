import 'project_requirements.dart';

bool vehicleLiftCadEligible(String? category, String? group, String? type) =>
    category == 'industrial' && group == 'workshop' &&
    const {'vehicle_repair', 'equipment_maintenance', 'mechanical_workshop'}.contains(type);

RequirementField _m(String id, String label, {num min = .001, num max = 30}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final vehicleLiftCadFields = <RequirementField>[
  _m('lv_bay_w', 'Clear width budget per bay (no internal divider walls)'),
  _m('lv_wall', 'Perimeter wall thickness', max: 2),
  _m('lv_car_w', 'Maximum static vehicle width including protrusions'),
  _m('lv_car_l', 'Maximum static vehicle length'),
  _m('lv_car_h', 'Vehicle envelope height at floor level'),
  _m('lv_front', 'Clear distance from the inside door line to vehicle envelope'),
  _m('lv_rear', 'Clear distance behind vehicle envelope to rear wall'),
  _m('lv_door_w', 'Centred clear door opening width per bay'),
  _m('lv_door_h', 'Clear door opening height per bay'),
  _m('lv_door_head', 'Minimum overhead margin at doorway for floor-level vehicle'),
  _m('lv_inner', 'Clear distance between inside faces of lift posts'),
  _m('lv_post_w', 'Width of each lift post footprint across the bay'),
  _m('lv_post_d', 'Depth of each lift post footprint along the bay'),
  _m('lv_post_h', 'Height of posts above floor'),
  _m('lv_rise', 'Submitted raised vehicle base height above floor'),
  _m('lv_side', 'Minimum static clearance on each vehicle side at door and posts'),
  _m('lv_outside', 'Minimum clearance from each outer post face to the bay limit'),
  _m('lv_overhead', 'Minimum margin above the raised vehicle and posts inside the hall'),
  _m('lv_apron', 'Clear south apron depth across the workshop frontage', max: 200),
  _m('lv_west', 'Workshop and apron envelope offset from west plot edge', min: 0, max: 2000),
  _m('lv_south', 'Apron outer edge offset from south plot edge', min: 0, max: 2000),
];
