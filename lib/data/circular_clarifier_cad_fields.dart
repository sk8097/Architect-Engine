import 'project_requirements.dart';

const circularClarifierMode = 'water_measured_circular_clarifier';

bool circularClarifierCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'water' && type == 'sewage_treatment_plant';

RequirementField _m(String id, String label, {num min = .001, num max = 150}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: max, required: true);

final circularClarifierCadFields = <RequirementField>[
  _m('cc_inside', 'Basin inside diameter, including the peripheral launder'),
  _m('cc_wall', 'Outer wall radial thickness in plan', max: 10),
  _m('cc_launder', 'Peripheral launder radial clear width'),
  _m('cc_feed', 'Outside diameter of the central feedwell'),
  _m('cc_min_clear', 'Submitted minimum radial distance from feedwell to launder'),
  _m('cc_rim', 'Basin rim elevation above the level floor', max: 30),
  _m('cc_water', 'Submitted water and nominal inner weir elevation', max: 30),
  _m('cc_free', 'Submitted minimum freeboard to rim', max: 30),
  _m('cc_trough_z', 'Launder bottom elevation above the basin floor', max: 30),
  _m('cc_feed_lower', 'Feedwell lower edge elevation above floor', max: 30),
  _m('cc_feed_upper', 'Feedwell upper edge elevation above floor', max: 30),
  _m('cc_reserve', 'External service reserve measured radially from outer wall'),
  _m('cc_west', 'Distance west plot edge to west extremity of full envelope', min: 0, max: 2000),
  _m('cc_south', 'Distance south plot edge to south extremity of full envelope', min: 0, max: 2000),
  const RequirementField('cc_min_area', 'Submitted minimum annular settling plan area', kind: RequirementKind.decimal,
    unit: 'm²', min: .001, max: 20000, required: true),
];
