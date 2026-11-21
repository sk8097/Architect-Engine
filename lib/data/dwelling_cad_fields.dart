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

final dwellingParkingCommonFields = <RequirementField>[
  planningChoice('g1_parking_frontage', 'Open parking and frontage access verified for this strip?', {
    'confirmed': 'Confirmed: open parking and full-width vehicle access are allowed here',
    'pending': 'Not yet verified',
  }),
  const RequirementField('g1_parking_offset', 'Vehicle strip offset from left (looking in from street)',
    kind: RequirementKind.decimal, min: 0, max: 300, unit: 'm', required: true),
  const RequirementField('g1_parking_apron', 'Clear vehicle approach depth from frontage',
    kind: RequirementKind.decimal, min: .001, max: 300, unit: 'm', required: true),
  const RequirementField('g1_parking_path', 'Clear pedestrian path width to front door',
    kind: RequirementKind.decimal, min: .001, max: 300, unit: 'm', required: true),
  const RequirementField('g1_parking_gap', 'Clear gap between parking and pedestrian path',
    kind: RequirementKind.decimal, min: .001, max: 300, unit: 'm', required: true),
];

const dwellingCarBayFields = <RequirementField>[
  RequirementField('g1_car_width', 'Clear width per car bay', kind: RequirementKind.decimal, min: .001, max: 300, unit: 'm', required: true),
  RequirementField('g1_car_depth', 'Clear depth per car bay', kind: RequirementKind.decimal, min: .001, max: 300, unit: 'm', required: true),
];

const dwellingTwoWheelerBayFields = <RequirementField>[
  RequirementField('g1_bike_width', 'Clear width per two-wheeler bay', kind: RequirementKind.decimal, min: .001, max: 300, unit: 'm', required: true),
  RequirementField('g1_bike_depth', 'Clear depth per two-wheeler bay', kind: RequirementKind.decimal, min: .001, max: 300, unit: 'm', required: true),
];

const dwellingRoofFields = <RequirementField>[
  RequirementField('g1_roof_height','First floor to terrace rise',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('g1_roof_stair_width','Clear width of second straight flight',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('g1_roof_risers','Risers in second flight',kind:RequirementKind.integer,min:2,max:50,required:true),
  RequirementField('g1_roof_going','Going per tread in second flight',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('g1_roof_landing','Each second-flight end landing depth',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('g1_roof_walk','Clear terrace walk width at stair head',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('g1_roof_width','Clear open terrace width across the plate',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('g1_roof_depth','Clear open terrace depth along the plate',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
  RequirementField('g1_roof_parapet','Parapet thickness in plan (no greater than house wall)',kind:RequirementKind.decimal,unit:'m',min:.001,max:300,required:true),
];
