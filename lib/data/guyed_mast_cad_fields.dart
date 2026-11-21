import 'project_requirements.dart';

const guyedMastMode = 'telecom_measured_guyed_mast';

bool guyedMastCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'energy' && type == 'telecom_tower';

RequirementField _n(String id, String label, {String unit = 'm', num min = .001, num max = 2000}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final guyedMastCadFields = <RequirementField>[
  _n('gm_x', 'Mast centre offset east of west plot edge'),
  _n('gm_y', 'Mast centre offset north of south plot edge'),
  _n('gm_pad', 'Side of the square mast pad reserve', max: 100),
  _n('gm_anchor', 'Side of each square anchor reserve', max: 100),
  _n('gm_attach', 'Common guy attachment height above mast base datum', max: 300),
  _n('gm_min_angle', 'Submitted minimum upward guy angle above horizontal', unit: 'degrees', max: 89.999),
  _n('gm_max_angle', 'Submitted maximum upward guy angle above horizontal', unit: 'degrees', max: 89.999),
  _n('gm_max_gap', 'Submitted maximum consecutive anchor azimuth gap', unit: 'degrees', min: 120, max: 179.999),
  for (final id in ['a', 'b', 'c']) ...[
    _n('gm_${id}_x', 'Anchor ${id.toUpperCase()} centre east of west plot edge'),
    _n('gm_${id}_y', 'Anchor ${id.toUpperCase()} centre north of south plot edge'),
    _n('gm_${id}_z', 'Anchor ${id.toUpperCase()} attachment level relative to mast base', min: -300, max: 300),
  ],
];
