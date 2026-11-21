import 'project_requirements.dart';

bool hotelWingEligible(String? category, String? group, String? type) => category == 'commercial' && group == 'lodging' &&
    const {'hotel', 'boutique_hotel', 'business_hotel', 'budget_hotel', 'motel', 'guest_house'}.contains(type);

RequirementField _m(String id, String label) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: .001, max: 300, required: true);

final hotelWingFields = <RequirementField>[
  _m('hw_module', 'Clear guestroom module length along the corridor'),
  _m('hw_corridor', 'Minimum clear corridor width'),
  _m('hw_vest_depth', 'Clear vestibule length along the corridor'),
  _m('hw_service_width', 'Clear width of vestibule and bathroom strip perpendicular to corridor'),
  _m('hw_bed_width', 'Bed width across each sleeping room'),
  _m('hw_bed_depth', 'Bed length parallel to the corridor'),
  _m('hw_bed_side', 'Minimum clearance at each side of the bed'),
  _m('hw_bed_foot', 'Minimum clear depth in front of the bed'),
  _m('hw_window', 'Exterior side-wall window length for each sleeping room'),
];
