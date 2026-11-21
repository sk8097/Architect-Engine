import 'project_requirements.dart';

const warehouseLoadingTypes = {
  'general_warehouse', 'distribution_centre', 'fulfilment_centre',
  'e_commerce_warehouse', 'bulk_storage', 'agricultural_warehouse',
};

const warehouseLoadingFields = <RequirementField>[
  RequirementField('wh_width', 'Warehouse shell width', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_depth', 'Warehouse shell depth', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_wall', 'Warehouse shell wall thickness', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_access_depth', 'Clear approach depth before yard', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_drive_width', 'Vehicle approach lane width', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_bay_width', 'Clear vehicle bay width per dock', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_bay_depth', 'Clear vehicle bay depth', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_dock_opening', 'Clear dock opening width', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_staging_depth', 'Clear internal staging depth', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_staff_width', 'Separate staff path and internal aisle width', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_staff_door', 'Staff door opening width', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_apron_width', 'Required manoeuvring reserve width', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_apron_depth', 'Required manoeuvring reserve depth', kind: RequirementKind.decimal, unit: 'm', min: .001, required: true),
  RequirementField('wh_vehicle_basis', 'Vehicle and source of clearance dimensions', required: true),
];
