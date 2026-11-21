import 'project_requirements.dart';
import 'project_taxonomy.dart';
import 'space_planning.dart';

const mixedRetailCadType = 'residential_plus_retail';
const mixedDwellingBedrooms = {'master_bedroom','secondary_bedroom','childrens_bedroom','guest_bedroom','elderly_accessible_bedroom'};
const mixedDwellingRoomIds = {...mixedDwellingBedrooms,'closed_kitchen','family_living_room','shared_bathroom','prayer_puja_room','study','home_office'};

// Use the same stable room IDs and names as the residential registry.
final mixedDwellingRooms = taxonomyProgram(
  taxonomyGroup(taxonomyCategory('residential'),'houses')!,
  const TaxonomyChoice('independent_house','Independent House'),
).spaces.where((room)=>mixedDwellingRoomIds.contains(room.id)).toList(growable:false);

final mixedRetailCadFields = <RequirementField>[
  const RequirementField('mx_retail_width','Shop width on the left (looking in from shop frontage)',kind:RequirementKind.decimal,
    min:.001,max:300,unit:'m',required:true),
  const RequirementField('mx_divider','Total solid divider thickness (including both wing walls)',kind:RequirementKind.decimal,
    min:.001,max:300,unit:'m',required:true),
  planningChoice('mx_home_entry','Dwelling entrance relative to shop frontage',{
    'same':'Same frontage, separate walk','opposite':'Opposite boundary, separate walk',
  }),
  planningChoice('mx_access','Independent access to both ends of the entry walks',{
    'confirmed':'Confirmed access at both entry points on the plot boundary','pending':'Not confirmed',
  }),
  const RequirementField('mx_shop_walk','Clear width of shop entry walk',kind:RequirementKind.decimal,
    min:.001,max:300,unit:'m',required:true),
  const RequirementField('mx_home_walk','Clear width of home entry walk',kind:RequirementKind.decimal,
    min:.001,max:300,unit:'m',required:true),
  const RequirementField('mx_bedrooms','Bedrooms in the dwelling',kind:RequirementKind.integer,min:1,max:5,required:true),
];

final stackedRetailCadFields = <RequirementField>[
  planningChoice('ms_access','Independent shop and home walks at the front boundary',{
    'confirmed':'Confirmed independent access at both entry points','pending':'Not confirmed',
  }),
  ...mixedRetailCadFields.where((field)=>const {'mx_shop_walk','mx_home_walk','mx_bedrooms'}.contains(field.id)),
];

final stackedHomeLevel = planningChoice('floor_level','Place this dwelling room on',{'1':'First floor above shop'});
