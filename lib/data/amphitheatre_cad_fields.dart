import 'project_requirements.dart';

bool amphitheatreCadEligible(String? category,String? group,String? type) =>
    category=='institutional' && group=='culture' && const {'theatre','auditorium','performing_arts_centre'}.contains(type);

RequirementField _m(String key,String label,{num min=.001,num max=100}) =>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:'m',min:min,max:max,required:true);

final amphitheatreCadFields=<RequirementField>[
  const RequirementField('at_rows','Identical straight seating rows',kind:RequirementKind.integer,min:2,max:28,required:true),
  _m('at_width','Clear seating bank width'),
  _m('at_tread','Row depth (horizontal pitch)'),
  _m('at_rise','Uniform rise between adjacent rows',max:5),
  _m('at_seat','Nominal place width along each row',max:5),
  _m('at_margin','Clear margin at each end of seating row',min:0),
  _m('at_side','Width of each side reserve (plan only)'),
  _m('at_rear','Depth of rear reserve (plan only)'),
  _m('at_stage_width','Stage width'),
  _m('at_stage_depth','Stage depth south–north'),
  _m('at_stage_level','Stage deck above first row datum',min:0,max:20),
  _m('at_gap','Clear gap between stage edge and first tread'),
  _m('at_eye','Submitted seated eye height above each tread',max:5),
  _m('at_clearance','Required minimum sightline height above preceding eye',min:0,max:5),
  _m('at_west','Envelope offset from west plot edge',min:0,max:2000),
  _m('at_south','Envelope offset from south plot edge',min:0,max:2000),
];
