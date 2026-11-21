import 'project_requirements.dart';
import 'project_taxonomy.dart';

bool libraryCadEligible(String? category,String? group,String? type) => category=='institutional' &&
  ((group=='education' && type=='library') || (group=='culture' && type=='public_library'));

const libraryCadRooms = <TaxonomyChoice>[
  TaxonomyChoice('lib_checkout','Library checkout / return'),
  TaxonomyChoice('lib_stacks','Open book stacks'),
  TaxonomyChoice('lib_reading','Quiet reading room'),
  TaxonomyChoice('lib_children','Children’s reading room'),
  TaxonomyChoice('lib_processing','Staff book processing'),
  TaxonomyChoice('lib_toilet','Public toilet reserve'),
];

const libraryCadFields = <RequirementField>[
  RequirementField('lib_front_depth','Clear public passage depth before the quiet threshold',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('lib_ranges','Shelf ranges on each side of the cross-aisle',kind:RequirementKind.integer,min:1,max:30,required:true),
  RequirementField('lib_shelf_width','Clear shelf range footprint across the room',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('lib_shelf_length','Length of each shelf range away from the cross-aisle',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('lib_stack_aisle','Clear stack aisle and cross-aisle width',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('lib_read_count','Number of individual quiet reading desks',kind:RequirementKind.integer,min:1,max:100,required:true),
  RequirementField('lib_read_span','Desk width along the reading row',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('lib_read_depth','Desk depth across the room',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('lib_chair_depth','Clear chair depth per desk',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('lib_read_aisle','Clear reading aisle width beside the chair clearances',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
];
