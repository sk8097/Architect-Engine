import 'project_requirements.dart';
import 'space_planning.dart';

bool busLaybyCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'transport' && type == 'bus_stop';

final busLaybyCadMode = planningChoice('bus_layby_mode', 'Bus stop drawing', {
  'survey_layby': 'Surveyed lay-by: bus berths, boarding strip and shelter reserve',
}, required: false);

RequirementField _m(String key, String label, {num min=.001, num max=300}) =>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:'m',min:min,max:max,required:true);

final busLaybyCadFields = <RequirementField>[
  const RequirementField('bl_grid','Projected survey grid / CRS in metres',required:true),
  const RequirementField('bl_edge','Road edge in travel order: Easting,Northing (m); two controls separated by ; or newline',required:true),
  planningChoice('bl_side','Lay-by side looking in the direction of travel',{'left':'Left','right':'Right'}),
  _m('bl_offset','Entry taper start chainage from first edge control',min:0,max:2000),
  _m('bl_entry','Entry taper length'),
  _m('bl_exit','Exit taper length'),
  const RequirementField('bl_count','Inline berth count',kind:RequirementKind.integer,min:1,max:4,required:true),
  _m('bl_berth','Clear length per berth'),
  _m('bl_gap','Clear longitudinal gap between berths (0 for one berth)',min:0),
  _m('bl_width','Clear width of full lay-by'),
  _m('bl_board','Clear boarding strip width between lay-by and shelter reserve'),
  _m('bl_shelter_len','Shelter reserve length'),
  _m('bl_shelter_depth','Shelter reserve depth'),
  _m('bl_connection','Minimum clear connection alongside each shelter end'),
  _m('bl_walk','Clear rear pedestrian path width'),
  _m('bl_row','Available roadside width measured from surveyed edge',max:1000),
];
