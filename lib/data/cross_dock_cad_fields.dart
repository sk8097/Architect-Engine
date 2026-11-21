import 'project_requirements.dart';
import 'space_planning.dart';
import 'warehouse_cad_fields.dart';

const crossDockTypes = {'cross_dock','distribution_centre','general_warehouse'};

final crossDockFields = <RequirementField>[
  for (final field in warehouseLoadingFields)
    if (const {'wh_width','wh_depth','wh_wall','wh_staff_width','wh_staff_door','wh_vehicle_basis'}.contains(field.id)) field,
  planningChoice('xd_access','Independent boundary access confirmed?',{
    'confirmed':'Front inbound, opposite outbound and side staff access are available',
    'pending':'Not confirmed or different circulation needed',
  }),
  const RequirementField('xd_in_count','Inbound docks (remaining total docks are outbound)',kind:RequirementKind.integer,min:1,max:29,required:true),
  const RequirementField('xd_left','Shell offset from the left plot edge, looking inward',kind:RequirementKind.decimal,unit:'m',min:.001,required:true),
  const RequirementField('xd_lane','Clear internal freight transfer lane width',kind:RequirementKind.decimal,unit:'m',min:.001,required:true),
  for (final (side,label) in [('in','Inbound'),('out','Outbound')]) ...[
    for (final (id,title) in [
      ('bay_width','clear width per dock bay'),('bay_depth','clear bay depth'),('opening','clear dock opening'),
      ('apron_width','manoeuvring reserve width'),('apron_depth','manoeuvring reserve depth'),
      ('drive_width','clear approach lane width'),('approach_depth','minimum clear approach depth'),('stage_depth','clear internal staging depth'),
    ]) RequirementField('xd_${side}_$id','$label $title',kind:RequirementKind.decimal,unit:'m',min:.001,required:true),
  ],
];
