import 'project_requirements.dart';
import 'space_planning.dart';

bool memorialNicheCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' && type == 'cemetery_memorial_landscape';

RequirementField _m(String id, String label, {num min = .001, num max = 50}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

RequirementField _count(String id, String label, int min, int max) =>
    RequirementField(id, label, kind: RequirementKind.integer, min: min, max: max, required: true);

final memorialNicheCadFields = <RequirementField>[
  _count('mn_panels', 'Identical wall panels in one row', 1, 6),
  planningChoice('mn_faces', 'Niche faces', {'1': 'South face only', '2': 'South and north faces'}),
  _count('mn_columns', 'Columns of niches per face', 1, 20),
  _count('mn_tiers', 'Tiers of niches per face', 1, 8),
  _m('mn_width', 'Clear niche opening width', max: 5),
  _m('mn_height', 'Clear niche opening height', max: 5),
  _m('mn_depth', 'Clear niche depth per face', max: 5),
  _m('mn_web', 'Grid web thickness between adjacent openings', max: 2),
  _m('mn_frame', 'Perimeter frame width around each face grid', max: 2),
  _m('mn_core', 'Solid back or centre spine thickness behind niche pockets', max: 5),
  _m('mn_plinth', 'Plinth height below face frame (zero for none)', min: 0, max: 5),
  _m('mn_gap', 'Panel-to-panel gap (zero for one panel)', min: 0),
  _m('mn_ends', 'Clear reserve at each end of the row'),
  _m('mn_south_strip', 'South viewing strip depth'),
  _m('mn_north_strip', 'North viewing strip depth, or rear reserve for one face'),
  _m('mn_west', 'Layout envelope offset from west plot edge', min: 0, max: 2000),
  _m('mn_south', 'Layout envelope offset from south plot edge', min: 0, max: 2000),
  _count('mn_target', 'Required total niche count (zero for no target)', 0, 1920),
];
