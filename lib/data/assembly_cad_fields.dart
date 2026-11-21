import 'project_requirements.dart';
import 'space_planning.dart';

const assemblyCadTypes = {'light_manufacturing','assembly_plant','electronics_assembly'};

final assemblyCadFields = <RequirementField>[
  planningChoice('as_scope','Assembly process and access',{
    'confirmed':'Dry non-hazardous assembly; separate staff/receiving access and rear dispatch confirmed',
    'pending':'Not confirmed or specialist process required',
  }),
  const RequirementField('as_goods_opening','Clear material opening width at each end and partition',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('as_goods_lane','Clear continuous material lane width',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('as_receiving_pad','Clear depth of front receiving pad',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('as_dispatch_pad','Clear depth of rear dispatch pad',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('as_work_aisle','Clear personnel aisle inside the assembly room',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('as_station_count','Workstations in the straight bench row',kind:RequirementKind.integer,min:1,max:100,required:true),
  const RequirementField('as_bench_width','Bench footprint across the line',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('as_bench_depth','Bench footprint along the line',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('as_cell_clear','Reserved working clearance on each side of a bench',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
];
