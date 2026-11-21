import 'project_requirements.dart';

RequirementField _n(String key, String label, String unit, num min, num max) =>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:unit,min:min,max:max,required:true);

final openDrainCadFields = <RequirementField>[
  const RequirementField('od_grid','Projected survey grid / CRS in metres',required:true),
  const RequirementField('od_datum','Survey source and common invert datum',required:true),
  const RequirementField('od_ends','Inlet then outlet: Easting,Northing,invert (m); separate rows by ; or newline',required:true),
  _n('od_bottom','Clear bottom width','m',.001,100),
  _n('od_depth','Vertical depth from invert to bank top','m',.001,30),
  _n('od_reference','Reference depth above invert (geometry only)','m',.001,30),
  _n('od_left_slope','Left side slope, horizontal units per vertical unit','H:1V',.001,20),
  _n('od_right_slope','Right side slope, horizontal units per vertical unit','H:1V',.001,20),
  _n('od_strip','Reserved maintenance strip beyond each bank','m',.001,100),
  _n('od_left_limit','Available corridor left of bottom centreline','m',.001,1000),
  _n('od_right_limit','Available corridor right of bottom centreline','m',.001,1000),
  _n('od_min_fall','Supplied minimum downstream invert grade','%',0,100),
];
