import 'project_requirements.dart';

bool raisedBedCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'public_realm' && type == 'public_garden';

RequirementField _m(String id,String label,{num min=.001,num max=50}) =>
    RequirementField(id,label,kind:RequirementKind.decimal,unit:'m',min:min,max:max,required:true);

final raisedBedCadFields=<RequirementField>[
  const RequirementField('gb_pairs','Bed pairs (one bed on each side of the central path)',kind:RequirementKind.integer,
    min:1,max:30,required:true),
  _m('gb_width','Outside bed width west–east'),
  _m('gb_length','Outside bed length south–north'),
  _m('gb_wall','Uniform horizontal bed wall thickness',max:5),
  _m('gb_height','Usable inside wall height above bed base',max:5),
  _m('gb_fill','Growing-medium fill depth above bed base',max:5),
  _m('gb_reach','Supplied horizontal reach limit from either long outside edge',max:25),
  _m('gb_spine','Clear central path width'),
  _m('gb_cross','Clear cross-aisle depth between bed pairs (0 for one pair)',min:0),
  _m('gb_side','Clear outer path width on each side'),
  _m('gb_ends','Clear end path depth at both ends'),
  _m('gb_west','Garden envelope offset from west plot edge',min:0,max:2000),
  _m('gb_south','Garden envelope offset from south plot edge',min:0,max:2000),
];
