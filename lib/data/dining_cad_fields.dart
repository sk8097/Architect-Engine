import 'project_requirements.dart';
import 'space_planning.dart';

const diningCadTypes = {'restaurant','cafe','coffee_shop'};

final diningCadFields = <RequirementField>[
  planningChoice('food_rear_access','On-site access to rear service doors',{
    'confirmed':'Independent on-site approach to both rear service doors confirmed',
    'pending':'Not confirmed or a different access arrangement needed',
  }),
  const RequirementField('food_serve_width','Clear kitchen serving hatch width',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('food_return_width','Clear used-dish return hatch width',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('food_pass_pad','Clear dining-side approach depth at each hatch',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('food_rear_pad','Clear depth outside each rear service door',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('food_table_width','Width of each four-seat table across the dining room',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('food_table_depth','Length of each table along the dining room',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  const RequirementField('food_chair_depth','Chair clearance depth at both table sides',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
];
