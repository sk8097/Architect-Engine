import 'project_requirements.dart';

bool windrowYardCadEligible(String? category,String? group,String? type) =>
    category=='infrastructure' && group=='public_realm' && type=='composting_facility';

RequirementField _m(String key,String label,{num min=.001,num max=300}) =>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:'m',min:min,max:max,required:true);

final windrowYardCadFields=<RequirementField>[
  const RequirementField('wy_rows','Identical parallel windrows',kind:RequirementKind.integer,min:1,max:30,required:true),
  _m('wy_base_w','Pile base width west–east'),
  _m('wy_base_l','Pile base length south–north'),
  _m('wy_top_w','Pile flat top width west–east'),
  _m('wy_top_l','Pile flat top length south–north'),
  _m('wy_height','Pile height',max:25),
  _m('wy_aisle','Clear aisle between toes of adjacent piles (0 for one row)',min:0),
  _m('wy_side','Clear outer strip on each side of the yard'),
  _m('wy_south_head','Clear south headland depth'),
  _m('wy_north_head','Clear north headland depth'),
  _m('wy_west','Yard envelope offset from west plot edge',min:0,max:2000),
  _m('wy_south','Yard envelope offset from south plot edge',min:0,max:2000),
  const RequirementField('wy_target','Required total geometric pile volume',kind:RequirementKind.decimal,
    unit:'m³',min:0,max:100000000,required:true),
];
