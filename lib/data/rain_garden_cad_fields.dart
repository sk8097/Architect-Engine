import 'project_requirements.dart';

const rainGardenMode = 'garden_measured_bioretention';

bool rainGardenCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' && type == 'public_garden';

RequirementField _n(String id, String label, String? unit, num max, {num min = .001}) =>
    RequirementField(id, label, unit: unit, kind: RequirementKind.decimal, min: min, max: max, required: true);

final rainGardenCadFields = <RequirementField>[
  _n('rg_bed_w', 'Flat bed width west–east at the top of planting media', 'm', 100),
  _n('rg_bed_l', 'Flat bed depth south–north at the top of planting media', 'm', 100),
  _n('rg_slope_we', 'West and east bank slope: horizontal run per 1 m rise', 'H:1V', 20, min: 1),
  _n('rg_slope_sn', 'South and north bank slope: horizontal run per 1 m rise', 'H:1V', 20, min: 1),
  _n('rg_pond', 'Design ponding depth above the flat bed', 'm', 5),
  _n('rg_free', 'Freeboard from design water surface to level rim', 'm', 5),
  _n('rg_media', 'Planting media depth below the flat bed', 'm', 5),
  _n('rg_agg', 'Aggregate layer depth below the planting media', 'm', 5),
  _n('rg_reserve', 'Horizontal maintenance reserve beyond the rim on all four sides', 'm', 25),
  _n('rg_reserve_min', 'Submitted minimum horizontal maintenance reserve', 'm', 25),
  _n('rg_storage_min', 'Submitted minimum surface ponding volume', 'm³', 1000000),
  _n('rg_west', 'Full envelope offset from west plot edge', 'm', 2000, min: 0),
  _n('rg_south', 'Full envelope offset from south plot edge', 'm', 2000, min: 0),
];
