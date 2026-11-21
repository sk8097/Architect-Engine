import 'project_requirements.dart';

bool publicToiletCadEligible(String? category, String? group, String? type) =>
    (category == 'institutional' && group == 'sports' && type == 'public_toilet_block') ||
    (category == 'infrastructure' && group == 'public_realm' && type == 'public_toilet');

RequirementField _m(String id, String label, {num min = .001, num max = 50}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final publicToiletCadFields = <RequirementField>[
  const RequirementField('pt_rooms', 'Identical single-occupancy rooms', kind: RequirementKind.integer, min: 1, max: 6, required: true),
  _m('pt_width', 'Clear room width west–east'),
  _m('pt_depth', 'Clear room depth south–north'),
  _m('pt_wall', 'Perimeter and partition wall thickness', max: 2),
  _m('pt_door', 'Centred clear opening width on each south room wall'),
  _m('pt_gallery', 'Clear depth of the shared south entrance gallery'),
  _m('pt_entry', 'Width of the straight clear strip from doorway to circle centre'),
  _m('pt_circle', 'Required clear manoeuvring circle diameter'),
  _m('pt_center', 'Circle centre offset from inside face of south room wall'),
  _m('pt_wc_x', 'WC envelope offset from west inside face', min: 0),
  _m('pt_wc_y', 'WC envelope offset from south inside face', min: 0),
  _m('pt_wc_w', 'WC envelope width west–east'),
  _m('pt_wc_d', 'WC envelope depth south–north'),
  _m('pt_basin_x', 'Basin envelope offset from west inside face', min: 0),
  _m('pt_basin_y', 'Basin envelope offset from south inside face', min: 0),
  _m('pt_basin_w', 'Basin envelope width west–east'),
  _m('pt_basin_d', 'Basin envelope depth south–north'),
  _m('pt_west', 'Block-plus-gallery offset from west plot edge', min: 0, max: 2000),
  _m('pt_south', 'Gallery outer edge offset from south plot edge', min: 0, max: 2000),
];
