import 'project_requirements.dart';
import 'space_planning.dart';

bool solarFarmEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'energy' && type == 'solar_farm';

RequirementField _m(String id, String label, {double min = .001, double max = 2000}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);
RequirementField _count(String id, String label, int max) =>
    RequirementField(id, label, kind: RequirementKind.integer, min: 1, max: max.toDouble(), required: true);

final solarFarmFields = <RequirementField>[
  planningChoice('pv_face', 'Direction the tilted modules face', {'south': 'South-facing', 'north': 'North-facing'}),
  _count('pv_rows', 'Parallel east–west table rows', 80),
  _count('pv_tables', 'Tables per row', 80),
  _count('pv_cols', 'Modules across each table (east–west)', 40),
  _count('pv_stacks', 'Modules up each table along the tilt', 12),
  _m('pv_module_x', 'Module dimension east–west', max: 10),
  _m('pv_module_s', 'Module dimension along the slope', max: 10),
  _m('pv_seam', 'Module-to-module gap along the table plane', min: 0, max: 1),
  const RequirementField('pv_watts', 'Module nameplate power', kind: RequirementKind.decimal, unit: 'Wp', min: 1, max: 5000, required: true),
  const RequirementField('pv_tilt', 'Module tilt from horizontal', kind: RequirementKind.decimal, unit: '°', min: 1, max: 75, required: true),
  const RequirementField('pv_sun', 'Design sun profile angle perpendicular to the rows', kind: RequirementKind.decimal, unit: '°', min: 1, max: 89, required: true),
  _m('pv_pitch', 'Horizontal pitch between equal low edges of successive rows'),
  _m('pv_side_gap', 'Horizontal gap between tables within each row', min: 0),
  _m('pv_walk', 'Supplied minimum horizontal maintenance gap between rows', min: 0),
  _m('pv_perimeter', 'Minimum clear offset from all four plot edges', min: 0),
  _m('pv_west', 'First table offset from the west edge', min: 0),
  _m('pv_first', 'First row low-edge offset from the sunward plot edge', min: 0),
];

const solarFarmObstacles = RequirementField('pv_obstacles',
  'Optional exclusions: ID,west offset,south offset,width,depth (m); separate rows with ; or newline');
