import 'project_requirements.dart';
import 'space_planning.dart';

bool bicycleRackCadEligible(String? category, String? group, String? type) =>
    (category == 'institutional' && group == 'sports' && type == 'public_parking') ||
    (category == 'infrastructure' && group == 'transport' &&
      const {'railway_station', 'metro_station', 'transit_interchange'}.contains(type));

RequirementField _m(String id, String label, {num min = .001, num max = 50}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final bicycleRackCadFields = <RequirementField>[
  planningChoice('br_banks', 'Stand rows beside the aisle', {'1': 'West row only', '2': 'Two mirrored rows'}),
  const RequirementField('br_stands', 'Identical two-sided stands per row', kind: RequirementKind.integer, min: 1, max: 30, required: true),
  _m('br_cycle_l', 'Parked bicycle envelope length perpendicular to aisle', max: 8),
  _m('br_cycle_w', 'Parked bicycle envelope width along aisle', max: 4),
  _m('br_stand_l', 'Stand footprint length perpendicular to aisle', max: 8),
  _m('br_stand_w', 'Stand footprint width along aisle', max: 4),
  _m('br_flank', 'Clear gap from stand edge to each adjacent bicycle envelope', min: 0, max: 4),
  _m('br_pitch', 'Stand centre-to-centre pitch (zero for one stand per row)', min: 0),
  _m('br_pair_gap', 'Minimum gap between adjacent loaded stands (zero if none)', min: 0),
  _m('br_aisle', 'Clear aisle width between loaded rows (east of the west row if single)'),
  _m('br_outer', 'Clear reserve behind each outer side of the layout'),
  _m('br_head_s', 'Clear head space south of loaded rows'),
  _m('br_head_n', 'Clear head space north of loaded rows'),
  _m('br_west', 'Layout envelope offset from west plot edge', min: 0, max: 2000),
  _m('br_south', 'Layout envelope offset from south plot edge', min: 0, max: 2000),
  const RequirementField('br_target', 'Required nominal bicycle positions (zero for no target)', kind: RequirementKind.integer, min: 0, max: 120, required: true),
];
