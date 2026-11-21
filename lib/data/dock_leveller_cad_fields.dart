import 'project_requirements.dart';

const dockLevellerMode = 'warehouse_measured_dock_leveller';

bool dockLevellerCadEligible(String? category, String? group, String? type) =>
    category == 'industrial' && group == 'logistics' && const {'general_warehouse', 'distribution_centre'}.contains(type);

RequirementField _measure(String id, String label, {num min = .001, num max = 100, String unit = 'm'}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final dockLevellerCadFields = <RequirementField>[
  _measure('dl_hinge', 'Platform hinge elevation above common datum', max: 20),
  _measure('dl_low', 'Lowest stationary truck-bed elevation above datum', min: 0, max: 20),
  _measure('dl_high', 'Highest stationary truck-bed elevation above datum', min: 0, max: 20),
  _measure('dl_deck', 'Main deck length, hinge to lip joint', max: 30),
  _measure('dl_lip', 'Length of the horizontal lip from joint to tip', max: 10),
  _measure('dl_gap', 'Horizontal distance south from dock hinge to truck rear edge'),
  _measure('dl_landing', 'Usable landing depth from truck rear edge forward'),
  _measure('dl_overlap', 'Submitted minimum lip overlap onto the truck bed', max: 10),
  _measure('dl_joint', 'Submitted minimum horizontal gap from lip joint to truck rear edge'),
  _measure('dl_grade', 'Submitted maximum main-deck grade magnitude', max: 200, unit: '%'),
  _measure('dl_deck_w', 'Clear width of deck and lip'),
  _measure('dl_bed_w', 'Usable width of centred truck-bed landing strip'),
  _measure('dl_side', 'Service reserve along each side of the bay'),
  _measure('dl_inside', 'Clear reserve north of the hinge within the dock'),
  _measure('dl_west', 'Full envelope offset from west plot edge', min: 0, max: 2000),
  _measure('dl_south', 'Full envelope offset from south plot edge', min: 0, max: 2000),
];
