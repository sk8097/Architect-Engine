import 'project_requirements.dart';
import 'space_planning.dart';

RequirementField cadOutputOptions({required bool warehouseLoading, bool clinicSeparated = false, bool retailFixtures = false, bool dwellingG1 = false, bool schoolArrival = false, bool packhouseFlow = false, bool mixedShopHome = false, bool crossDock = false, bool officeWorkplace = false}) => planningChoice('cad_output', 'Automatic drawing', {
  if (officeWorkplace) 'office_workplace': 'Office: visitor rooms and measured staff workstations',
  if (crossDock) 'warehouse_cross_dock': 'Cross-dock: opposing inbound and outbound banks',
  if (mixedShopHome) 'mixed_shop_home': 'Shop + dwelling: side-by-side with independent entries',
  if (packhouseFlow) 'packhouse_flow': 'Packhouse: receiving, grading, packing and dispatch',
  if (schoolArrival) 'school_arrival': 'Primary school: visitor lobby and classroom route',
  if (dwellingG1) 'dwelling_g1': 'G+1 house with measured indoor staircase',
  if (retailFixtures) 'retail_fixtures': 'Retail displays, checkout and stock',
  if (clinicSeparated) 'clinic_separated': 'Outpatient clinic: separate patient and service routes',
  if (warehouseLoading) 'warehouse_loading': 'Warehouse loading and staff routes',
  'building': 'Measured enclosed floor plan (walls and doors)',
  'zones': 'Site / open-space zoning only',
}, required: false);

final cadOutputField = cadOutputOptions(warehouseLoading: false);

const enclosedCadFields = <RequirementField>[
  RequirementField('cad_plate_width', 'Building width along frontage', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('cad_plate_depth', 'Building depth from frontage', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('cad_offset_left', 'Offset from plot left along frontage', kind: RequirementKind.decimal, unit: 'm', min: 0, required: true),
  RequirementField('cad_offset_front', 'Offset from plot frontage', kind: RequirementKind.decimal, unit: 'm', min: 0, required: true),
  RequirementField('cad_wall', 'Concept wall thickness', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('cad_corridor', 'Clear passage width', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('cad_door', 'Door opening width', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
];

final cadWidthMode = planningChoice('cad_width_mode', 'Room widths', {
  'exact': 'Keep exact clear width', 'minimum': 'Treat clear width as minimum; allow full lane width',
}, required: false);

const cadWindowField = RequirementField('cad_window', 'Exterior window width for enclosed CAD',
  kind: RequirementKind.decimal, unit: 'm', min: .001);
