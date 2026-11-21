import 'project_requirements.dart';

bool teachingLabEligible(String? category, String? group, String? type) => category == 'institutional' &&
    group == 'education' && const {'secondary_school', 'senior_secondary_school'}.contains(type);

RequirementField _m(String id, String label) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true);

final teachingLabFields = <RequirementField>[
  const RequirementField('sl_rows', 'Bench rows per bank (two banks)', kind: RequirementKind.integer, min: 1, max: 10, required: true),
  const RequirementField('sl_places', 'Student places per bench', kind: RequirementKind.integer, min: 1, max: 8, required: true),
  _m('sl_place_span', 'Minimum bench frontage per student place'),
  _m('sl_bench_width', 'Student bench width across room'),
  _m('sl_bench_depth', 'Student bench depth from front to rear'),
  _m('sl_use', 'Clear student-use depth behind each bench'),
  _m('sl_cross', 'Clear cross passage after each student-use strip'),
  _m('sl_centre', 'Clear centre aisle between bench banks'),
  _m('sl_side', 'Clear side aisle at each outer wall'),
  _m('sl_front', 'Clear front teaching band depth, including entry and counter'),
  _m('sl_rear', 'Minimum clear rear cross aisle in the lab'),
  _m('sl_teacher_width', 'Teacher counter width across room'),
  _m('sl_teacher_depth', 'Teacher counter depth from front to rear'),
  _m('sl_teacher_work', 'Clear teacher work depth behind the counter'),
  _m('sl_prep', 'Clear rear prep-room depth'),
  _m('sl_prep_width', 'Prep counter width across room'),
  _m('sl_prep_depth', 'Prep counter depth from front to rear'),
  _m('sl_prep_work', 'Clear working depth in front of prep counter'),
];
