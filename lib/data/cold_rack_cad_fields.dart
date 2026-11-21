import 'project_requirements.dart';

bool coldRackCadEligible(String? category,String? group,String? type)=>
    category=='industrial' && group=='logistics' && const {'cold_storage','freezer_warehouse'}.contains(type);

RequirementField _m(String id,String label,{num min=.001,num max=300})=>
    RequirementField(id,label,kind:RequirementKind.decimal,unit:'m',min:min,max:max,required:true);
RequirementField _count(String id,String label,int min,int max)=>
    RequirementField(id,label,kind:RequirementKind.integer,min:min,max:max,required:true);

final coldRackCadFields=<RequirementField>[
  _count('cr_pairs','Internal back-to-back rack pairs, in addition to two single outer rows',0,8),
  _count('cr_bays','Identical bays along each rack row',1,20),
  _count('cr_slots','Pallet positions per bay per level',1,5),
  _count('cr_levels','Load levels per bay including level at floor',1,8),
  _m('cr_rack_depth','Outside rack depth (no pallet overhang)',max:20),
  _m('cr_bay','Clear opening between bay uprights',max:20),
  _m('cr_upright','Upright thickness along the bay row',max:5),
  _m('cr_pallet_w','Loaded pallet width along the row',max:20),
  _m('cr_pallet_d','Loaded pallet depth across the row',max:20),
  _m('cr_pallet_h','Loaded pallet height above its level',max:20),
  _m('cr_gap','Clear gap between loads and at both ends of each bay',max:10),
  _m('cr_pitch_z','Bottom-to-bottom load level pitch (0 for one level)',min:0,max:20),
  _m('cr_top_clear','Required clear space above top load',max:20),
  _m('cr_flue','Clear separation within each back-to-back pair (0 without pairs)',min:0,max:20),
  _m('cr_aisle','Clear aisle between facing rack rows'),
  _m('cr_wall_gap','Clear space behind each outer rack'),
  _m('cr_front','Front staging band clear depth'),
  _m('cr_rear','Rear cross-aisle clear depth'),
  _m('cr_door','Clear south entrance opening centred on first aisle'),
  _m('cr_wall','Uniform chamber wall thickness',max:5),
  _m('cr_west','Outside chamber offset from west plot edge',min:0,max:2000),
  _m('cr_south','Outside chamber offset from south plot edge',min:0,max:2000),
];
