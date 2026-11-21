import 'project_requirements.dart';

bool twinTankCadEligible(String? category,String? group,String? type)=>
    category=='infrastructure' && group=='water' && const {'water_tank','ground_reservoir'}.contains(type);

RequirementField _m(String key,String label,{num min=.001,num max=300})=>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:'m',min:min,max:max,required:true);
RequirementField _volume(String key,String label)=>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:'m³',min:0,max:100000000,required:true);

final twinTankCadFields=<RequirementField>[
  _m('tt_w_a','West cell A clear width'),
  _m('tt_w_b','East cell B clear width'),
  _m('tt_length','Common clear cell length south–north'),
  _m('tt_wall','Perimeter wall thickness in plan',max:10),
  _m('tt_divider','Divider thickness in plan',max:10),
  _m('tt_height','Inside wall-top elevation above common tank floor',max:30),
  _m('tt_lower_a','Cell A lower usable level above floor',min:0,max:30),
  _m('tt_normal_a','Cell A normal level above floor',max:30),
  _m('tt_lower_b','Cell B lower usable level above floor',min:0,max:30),
  _m('tt_normal_b','Cell B normal level above floor',max:30),
  _m('tt_freeboard','Minimum geometric freeboard at normal level',min:0,max:30),
  _m('tt_service','Clear service strip around outside of tank'),
  _m('tt_west','Service envelope offset from west plot edge',min:0,max:2000),
  _m('tt_south','Service envelope offset from south plot edge',min:0,max:2000),
  _volume('tt_total','Required usable volume with both cells online'),
  _volume('tt_reserve','Required usable volume with either single cell offline'),
];
