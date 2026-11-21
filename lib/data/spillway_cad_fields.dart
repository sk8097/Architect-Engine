import 'project_requirements.dart';

const spillwayMode = 'water_measured_spillway';

bool spillwayCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'water' && type == 'flood_control_structure';

RequirementField _value(String id, String label, {String unit = 'm', num min = .001, num max = 200}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final spillwayCadFields = <RequirementField>[
  _value('sp_in_w', 'Clear width at south inlet'),
  _value('sp_throat', 'Constant clear throat width across the crest'),
  _value('sp_out_w', 'Clear width at chute toe and across the downstream apron'),
  _value('sp_in_l', 'Horizontal inlet transition run to the crest'),
  _value('sp_crest_l', 'Horizontal length of flat crest'),
  _value('sp_min_crest', 'Submitted minimum horizontal crest length'),
  _value('sp_chute_l', 'Horizontal chute run from crest to toe'),
  _value('sp_apron_l', 'Horizontal length of flat downstream apron'),
  _value('sp_rise', 'Vertical crest rise above inlet bed datum', max: 50),
  _value('sp_drop', 'Vertical drop from crest to chute toe', max: 50),
  _value('sp_in_max', 'Submitted maximum inlet bed grade', unit: '%', max: 200),
  _value('sp_chute_max', 'Submitted maximum chute bed grade magnitude', unit: '%', max: 200),
  _value('sp_taper_max', 'Submitted maximum plan taper: sideways shift per 100 m of run, per edge', unit: '%', min: 0, max: 200),
  _value('sp_reserve', 'Reserve outside the bounding rectangle on all four sides', min: 0, max: 50),
  _value('sp_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _value('sp_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
];
