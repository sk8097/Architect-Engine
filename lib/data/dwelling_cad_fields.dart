import 'project_requirements.dart';
import 'space_planning.dart';

const dwellingG1Types = {'independent_house','detached_house','duplex_house','villa'};
const dwellingBedroomIds = {'master_bedroom','secondary_bedroom','childrens_bedroom','guest_bedroom','elderly_accessible_bedroom'};

const straightDwellingStairFields = <RequirementField>[
  RequirementField('g1_height', 'Measured floor-to-floor rise', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('g1_width', 'Clear stair width', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('g1_risers', 'Number of risers', kind: RequirementKind.integer, min: 2, max: 50, required: true),
  RequirementField('g1_going', 'Clear going per tread', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('g1_landing', 'Depth of each end landing', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
];

final dwellingRoomLevel = planningChoice('floor_level','Place this space on', {'0':'Ground floor','1':'First floor'});
