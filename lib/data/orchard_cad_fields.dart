import 'project_requirements.dart';
import 'space_planning.dart';

bool orchardCadEligible(String? category, String? group, String? type) =>
    category == 'rural' && group == 'farm' && const {'orchard_estate', 'plantation_estate'}.contains(type);

RequirementField _m(String key, String label, {double min = .001, double max = 2000}) =>
    RequirementField(key, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final orchardCadFields = <RequirementField>[
  planningChoice('orc_axis', 'Planting row axis', {'ns': 'North–south', 'ew': 'East–west'}),
  const RequirementField('orc_rows', 'Planting rows', kind: RequirementKind.integer, min: 1, max: 120, required: true),
  const RequirementField('orc_trees', 'Trees per row', kind: RequirementKind.integer, min: 1, max: 120, required: true),
  _m('orc_row_pitch', 'Centre-to-centre distance between rows', max: 200),
  _m('orc_tree_pitch', 'Centre-to-centre tree spacing along each row', max: 200),
  _m('orc_canopy', 'Mature canopy diameter to reserve', max: 100),
  _m('orc_headland', 'Clear headland at both ends of each row', max: 100),
  _m('orc_side_lane', 'Clear side access lane width on both sides', max: 100),
  _m('orc_west', 'Access loop offset from the west plot edge', min: 0),
  _m('orc_south', 'Access loop offset from the south plot edge', min: 0),
];

const orchardExclusions = RequirementField('orc_exclusions',
  'Optional exclusions: ID,west offset,south offset,width,depth (m); separate rows with ; or newline');
