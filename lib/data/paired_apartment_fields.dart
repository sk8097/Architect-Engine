import 'project_requirements.dart';

bool pairedApartmentEligible(String? category, String? group, String? type) =>
    category == 'residential' && group == 'apartments' &&
    const {'1_bhk','rental_apartment','apartment_building','low_rise_apartment'}.contains(type);

const pairedApartmentFields = <RequirementField>[
  RequirementField('pa_lobby_width','Clear shared lobby width between flats',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('pa_lobby_depth','Clear shared lobby depth',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('pa_walk','Clear width of shared front approach',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('pa_living_depth','Clear depth of each living/kitchen room',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('pa_bath_width','Clear width of each bathroom beside service reserve',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('pa_kitchen_length','Kitchen counter length along exterior side wall',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('pa_kitchen_depth','Kitchen counter depth',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('pa_kitchen_clear','Usable working clearance in front of kitchen counter',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('pa_living_window','Front window width in each living room',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('pa_bed_window','Rear window width in each bedroom',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
];
