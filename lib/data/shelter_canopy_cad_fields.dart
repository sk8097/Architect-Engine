import 'project_requirements.dart';

bool shelterCanopyCadEligible(String? category, String? group, String? type) =>
    category == 'institutional' && group == 'sports' && type == 'passenger_shelter';

RequirementField _m(String id, String label, {num min = .001, num max = 50}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final shelterCanopyCadFields = <RequirementField>[
  const RequirementField('sh_bays', 'Equal bays along each north–south post row', kind: RequirementKind.integer, min: 1, max: 8, required: true),
  _m('sh_pitch', 'Post centre spacing along rows'),
  _m('sh_span', 'West-to-east distance between post-row centre lines'),
  _m('sh_post', 'Square plan envelope of each post', max: 5),
  _m('sh_oh_w', 'Roof west edge projection from west post centre line'),
  _m('sh_oh_e', 'Roof east edge projection from east post centre line'),
  _m('sh_oh_end', 'Roof projection from first and last post grid lines'),
  _m('sh_w_z', 'West high soffit level above common grade datum'),
  _m('sh_e_z', 'East low soffit level above common grade datum'),
  _m('sh_roof_d', 'Vertical depth from roof soffit to outer top plane', max: 5),
  _m('sh_min_walk', 'Minimum clear walking width between post rows'),
  _m('sh_min_head', 'Minimum vertical headroom in the clear walking strip'),
  _m('sh_min_eave', 'Minimum vertical headroom at low east eave'),
  _m('sh_west', 'Roof projection offset from west plot edge', min: 0, max: 2000),
  _m('sh_south', 'Roof projection offset from south plot edge', min: 0, max: 2000),
];
