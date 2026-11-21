import 'project_requirements.dart';
import 'project_taxonomy.dart';

const schoolCadTypes = {'primary_school'};

const schoolCadFields = <RequirementField>[
  RequirementField('school_lobby_depth', 'Clear visitor lobby depth to internal door', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm', required: true),
  RequirementField('school_entry_walk', 'Straight on-site entry walk width (optional)', kind: RequirementKind.decimal,
    min: .001, max: 300, unit: 'm'),
];

const schoolPlaygroundFields = <RequirementField>[
  RequirementField('school_play_access','Rear open-play use and fence siting confirmed?',kind:RequirementKind.choice,
    options:[TaxonomyChoice('confirmed','Confirmed for this plot'),TaxonomyChoice('pending','Not verified')],required:true),
  RequirementField('school_play_walk_width','Clear width of rear playground walk',kind:RequirementKind.decimal,
    min:.001,max:300,unit:'m',required:true),
  RequirementField('school_play_walk_depth','Clear distance from rear school wall to fence',kind:RequirementKind.decimal,
    min:.001,max:300,unit:'m',required:true),
  RequirementField('school_play_door','Clear width of rear playground door',kind:RequirementKind.decimal,
    min:.001,max:300,unit:'m',required:true),
  RequirementField('school_play_fence','Fence thickness in plan',kind:RequirementKind.decimal,
    min:.001,max:300,unit:'m',required:true),
  RequirementField('school_play_gate','Clear opening width in the playground fence',kind:RequirementKind.decimal,
    min:.001,max:300,unit:'m',required:true),
];
