import 'project_requirements.dart';
import 'space_planning.dart';

bool footbridgeCadEligible(String? category,String? group,String? type) =>
    category=='infrastructure' && group=='transport' && type=='bridge';

final footbridgeCadMode=planningChoice('footbridge_mode','Bridge drawing',{
  'survey_footbridge':'Surveyed footbridge: straight deck and approaches over a channel',
},required:false);

RequirementField _n(String key,String label,String unit,num min,num max)=>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:unit,min:min,max:max,required:true);

final footbridgeCadFields=<RequirementField>[
  const RequirementField('fb_grid','Projected survey grid / CRS in metres',required:true),
  const RequirementField('fb_datum','Survey source and common elevation datum',required:true),
  const RequirementField('fb_ends','Approach A then B: Easting,Northing,tie-in level (m); separate rows with ; or newline',required:true),
  _n('fb_cross','Channel centreline crossing chainage from A','m',.001,2000),
  _n('fb_bearing','Channel grid bearing, clockwise from north','°',0,360),
  _n('fb_channel','Channel band width perpendicular to its axis','m',.001,300),
  _n('fb_edge_gap','Minimum perpendicular gap from a deck end face to channel bank','m',0,100),
  _n('fb_deck_start','Start of level deck, chainage from A','m',.001,2000),
  _n('fb_deck_end','End of level deck, chainage from A','m',.001,2000),
  _n('fb_width','Overall deck and approach plan width','m',.001,30),
  _n('fb_level','Level deck top elevation on supplied datum','m',-10000,10000),
  _n('fb_depth','Vertical deck envelope depth from top to underside','m',.001,20),
  _n('fb_water','Supplied reference water elevation on the same datum','m',-10000,10000),
  _n('fb_clearance','Required vertical clearance above reference water elevation','m',0,100),
  _n('fb_limit','Maximum submitted grade for either straight approach','%',.001,100),
];
