import 'project_requirements.dart';
import 'space_planning.dart';

bool angledParkingCadEligible(String? category,String? group,String? type) =>
    category=='institutional' && group=='sports' && type=='public_parking';

RequirementField _m(String key,String label,{num min=.001,num max=300}) =>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:'m',min:min,max:max,required:true);

final angledParkingCadFields=<RequirementField>[
  planningChoice('ap_angle','Stall stripe angle measured from the drive aisle',{'30':'30°','45':'45°','60':'60°','90':'90°'}),
  const RequirementField('ap_spaces','Identical stalls per side (two rows)',kind:RequirementKind.integer,min:1,max:30,required:true),
  _m('ap_width','Clear rectangular footprint width across each stall',max:30),
  _m('ap_length','Clear rectangular footprint length along each stall',max:30),
  _m('ap_drive','Clear one-way through aisle width'),
  _m('ap_side','Clear outer reserve width beyond each row'),
  _m('ap_head_s','Clear space south of all marked stalls'),
  _m('ap_head_n','Clear space north of all marked stalls'),
  _m('ap_west','Parking envelope offset from west plot edge',min:0,max:2000),
  _m('ap_south','Parking envelope offset from south plot edge',min:0,max:2000),
];
