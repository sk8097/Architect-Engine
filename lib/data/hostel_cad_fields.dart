import 'project_requirements.dart';

bool hostelCadEligible(String? category, String? group, String? type) =>
    category == 'residential' && group == 'hostels' &&
    const {'student_hostel', 'working_person_hostel', 'dormitory'}.contains(type);

const hostelCadRoomIds = {'bedroom', 'warden_room', 'toilets_baths'};

const hostelCadFields = <RequirementField>[
  RequirementField('hostel_bed_width', 'Bed footprint width', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('hostel_bed_length', 'Bed footprint length', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('hostel_bed_side', 'Clear access on one side of each bed', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('hostel_cross_aisle', 'Clear cross-aisle width at bedroom door', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('hostel_locker_width', 'Individual locker width along exterior wall', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('hostel_locker_depth', 'Individual locker depth', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
  RequirementField('hostel_locker_aisle', 'Clear retrieval aisle in front of lockers', kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true),
];
