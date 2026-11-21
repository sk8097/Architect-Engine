import 'project_requirements.dart';

bool rainwaterCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'water' && type == 'rainwater_harvesting_system';

RequirementField _n(String id,String label,String unit,{num min=.001,num max=2000}) =>
    RequirementField(id,label,kind:RequirementKind.decimal,unit:unit,min:min,max:max,required:true);

final rainwaterCadFields = <RequirementField>[
  _n('rw_roof_width','Horizontal roof catchment width west–east','m'),
  _n('rw_roof_depth','Horizontal roof catchment depth south–north','m'),
  _n('rw_roof_west','Roof catchment offset from west plot edge','m',min:0),
  _n('rw_roof_south','Roof catchment offset from south plot edge','m',min:0),
  _n('rw_tank_west','Tank service envelope offset from west plot edge','m',min:0),
  _n('rw_tank_south','Tank service envelope offset from south plot edge','m',min:0),
  const RequirementField('rw_count','Identical cylindrical tanks in one row',kind:RequirementKind.integer,min:1,max:8,required:true),
  _n('rw_outer','Outside tank diameter','m',max:50),
  _n('rw_inner','Inside tank diameter','m',max:50),
  _n('rw_useful','Usable water depth above unusable storage','m',max:50),
  _n('rw_service','Clear service space around and between tanks','m',max:50),
  _n('rw_rain','Supplied rainfall event depth','mm',max:5000),
  _n('rw_coefficient','Roof runoff coefficient (0 to 1)','ratio',min:0,max:1),
  _n('rw_flush','First-flush volume to divert before tanks','L',min:0,max:100000000),
  _n('rw_target','Required usable tank-bank capacity','L',min:0,max:100000000),
];
