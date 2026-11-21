import 'project_requirements.dart';

bool parkLoopCadEligible(String? category,String? group,String? type) =>
    type=='public_park' && ((category=='infrastructure' && group=='public_realm') ||
      (category=='institutional' && group=='sports'));

RequirementField _m(String key,String label,{num min=.001,num max=300}) =>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:'m',min:min,max:max,required:true);

final parkLoopCadFields=<RequirementField>[
  _m('pl_width','Overall west–east span on loop centreline'),
  _m('pl_depth','Overall south–north span on loop centreline'),
  _m('pl_radius','Centreline corner radius'),
  _m('pl_path','Clear loop path width'),
  _m('pl_west','Outer path edge offset from west plot edge',min:0,max:2000),
  _m('pl_south','Outer path edge offset from south plot edge',max:2000),
  _m('pl_entry','Clear approach width from south edge'),
  _m('pl_shift','Approach centre offset from loop centre (negative west, positive east)',min:-150,max:150),
  _m('pl_lawn_w','Centred rectangular lawn reserve width (west–east)'),
  _m('pl_lawn_d','Centred rectangular lawn reserve depth (south–north)'),
  _m('pl_lawn_gap','Minimum clearance from lawn reserve to inside path edge',min:0),
];
