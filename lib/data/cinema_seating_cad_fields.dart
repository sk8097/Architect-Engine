import 'project_requirements.dart';

const cinemaSeatingMode = 'cinema_measured_seat_banks';

bool cinemaSeatingCadEligible(String? category, String? group, String? type) =>
    category == 'commercial' && group == 'business_services' && type == 'cinema_entertainment';

RequirementField _m(String id, String label, {num min = .001, num max = 60}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final cinemaSeatingCadFields = <RequirementField>[
  _m('cs_hall', 'Clear hall width west–east'),
  const RequirementField('cs_rows', 'Number of fixed-seat rows (each split into two banks)', kind: RequirementKind.integer, min: 1, max: 24, required: true),
  _m('cs_seat_w', 'Installed fixed-seat module width', max: 5),
  _m('cs_seat_d', 'Occupied seat envelope depth', max: 5),
  _m('cs_pitch', 'Row pitch between successive seat fronts', max: 10),
  _m('cs_row_gap', 'Submitted minimum clear strip behind each occupied seat row', max: 10),
  const RequirementField('cs_cap', 'Submitted maximum fixed seats in one bank per row', kind: RequirementKind.integer, min: 1, max: 30, required: true),
  const RequirementField('cs_target', 'Submitted minimum fixed seats (excludes rear flexible bays)', kind: RequirementKind.integer, min: 1, max: 1440, required: true),
  _m('cs_centre', 'Clear centre aisle width', max: 10),
  _m('cs_side', 'Clear width of each side aisle', max: 10),
  _m('cs_rear', 'Clear depth of full-width rear cross aisle', max: 10),
  _m('cs_aisle_min', 'Submitted minimum for each aisle width/depth', max: 10),
  const RequirementField('cs_bays', 'Rear flexible bays per bank', kind: RequirementKind.integer, min: 1, max: 8, required: true),
  _m('cs_bay_w', 'Width of each flexible bay', max: 10),
  _m('cs_bay_d', 'Depth of the rear flexible bay row', max: 10),
  _m('cs_front', 'Distance from south hall edge to the first seat row'),
  _m('cs_screen_y', 'Screen plane offset from south hall edge'),
  _m('cs_screen_w', 'Centred screen line width'),
  _m('cs_west', 'Hall rectangle offset from west plot edge', min: 0, max: 2000),
  _m('cs_south', 'Hall rectangle offset from south plot edge', min: 0, max: 2000),
];
