import 'project_requirements.dart';

bool galleryPanelCadEligible(String? category,String? group,String? type) =>
    category=='institutional' && group=='culture' && const {'museum','gallery','art_centre'}.contains(type);

RequirementField _m(String key,String label,{num min=.001,num max=100}) =>
    RequirementField(key,label,kind:RequirementKind.decimal,unit:'m',min:min,max:max,required:true);

final galleryPanelCadFields=<RequirementField>[
  const RequirementField('gp_pairs','Panels per bank (two mirrored banks)',kind:RequirementKind.integer,min:1,max:10,required:true),
  _m('gp_length','Physical panel length along the gallery'),
  _m('gp_thick','Physical panel thickness',max:5),
  _m('gp_end_margin','Non-display margin at each panel end',min:0),
  _m('gp_display_height','Usable hanging height per display face',max:20),
  _m('gp_view','Clear viewing depth in front of each face'),
  _m('gp_middle','Clear central aisle, excluding both viewing zones'),
  _m('gp_between','Clear inter-panel passage beyond viewing zones (0 for one panel per bank)',min:0),
  _m('gp_side','Clear passage beyond each outer viewing zone'),
  _m('gp_front','Clear depth across front ends of panels'),
  _m('gp_rear','Clear depth across rear ends of panels'),
  _m('gp_door','Clear south entrance opening width'),
  _m('gp_wall','Uniform exterior wall thickness',max:5),
  _m('gp_west','Outside hall offset from west plot edge',min:0,max:2000),
  _m('gp_south','Outside hall offset from south plot edge',min:0,max:2000),
];
