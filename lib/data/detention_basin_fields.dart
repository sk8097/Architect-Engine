import 'project_requirements.dart';

bool detentionBasinEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'water' && type == 'detention_retention_pond';

RequirementField _measure(String id, String label, String unit, num min, num max) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final detentionBasinFields = <RequirementField>[
  const RequirementField('db_reference', 'Survey source / common level datum', required: true),
  _measure('db_width', 'Level basin bottom width west–east', 'm', .001, 2000),
  _measure('db_length', 'Level basin bottom length south–north', 'm', .001, 2000),
  _measure('db_slope_x', 'Side slope on east/west banks (horizontal per 1 vertical)', 'H:1V', .1, 30),
  _measure('db_slope_y', 'Side slope on north/south banks (horizontal per 1 vertical)', 'H:1V', .1, 30),
  _measure('db_west', 'West offset from plot edge to basin inner crest', 'm', 0, 2000),
  _measure('db_south', 'South offset from plot edge to basin inner crest', 'm', 0, 2000),
  _measure('db_bottom', 'Basin floor elevation', 'm', -10000, 10000),
  _measure('db_normal', 'Normal pool elevation (use floor level for a dry basin)', 'm', -10000, 10000),
  _measure('db_design', 'Supplied design high-water elevation', 'm', -10000, 10000),
  _measure('db_crest', 'Inner crest elevation', 'm', -10000, 10000),
  _measure('db_freeboard', 'Required minimum vertical freeboard', 'm', 0, 100),
  _measure('db_target', 'Required active storage above normal pool', 'm³', 0, 1000000000),
];
