import 'project_requirements.dart';
import 'space_planning.dart';

const cattleShedTypes = {'dairy_farm','cattle_farm'};

const cattleShedHerdField = RequirementField('animal_capacity','Planned herd size',
  kind:RequirementKind.integer,min:1,max:2000,required:true);

final cattleShedFields = <RequirementField>[
  planningChoice('df_access','On-site access at the opposite shed ends',{
    'confirmed':'Separate front feed access and rear cleaning access confirmed',
    'pending':'Not confirmed or different arrangement needed',
  }),
  const RequirementField('df_pens','Group pens in each of the two rows',kind:RequirementKind.integer,min:1,max:20,required:true),
  const RequirementField('df_animals_per_pen','Planned animals per pen (user assumption)',kind:RequirementKind.integer,min:1,max:50,required:true),
  const RequirementField('df_pen_width','Clear pen width across the shed',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('df_pen_depth','Clear pen depth along the row',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('df_rail','Pen rail or barrier thickness in plan',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('df_feed_lane','Clear centre feed-lane width',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('df_scrape_lane','Clear width of each manure-cleaning alley',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('df_trough','Trough depth inside each pen',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('df_pen_gate','Clear gate width for each pen',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('df_feed_door','Clear front feed door width',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('df_scrape_door','Clear rear door width at each cleaning alley',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('df_scrape_pad','Clear depth of each rear cleaning approach pad',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
];
