import 'project_requirements.dart';

const retailFixtureTypes = {
  'shop', 'boutique', 'convenience_store', 'supermarket', 'showroom',
  'electronics_store', 'apparel_store', 'grocery',
};

const retailCadFields = <RequirementField>[
  RequirementField('rt_public_door', 'Public entrance clear width', kind: RequirementKind.decimal, min: .001, unit: 'm', required: true),
  RequirementField('rt_stock_door', 'Stock room door clear width', kind: RequirementKind.decimal, min: .001, unit: 'm', required: true),
  RequirementField('rt_stock_depth', 'Clear stock room depth', kind: RequirementKind.decimal, min: .001, unit: 'm', required: true),
  RequirementField('rt_fixture_count', 'Display rows', kind: RequirementKind.integer, min: 1, max: 24, required: true),
  RequirementField('rt_fixture_width', 'Width per display row', kind: RequirementKind.decimal, min: .001, unit: 'm', required: true),
  RequirementField('rt_fixture_depth', 'Length per display row', kind: RequirementKind.decimal, min: .001, unit: 'm', required: true),
  RequirementField('rt_aisle', 'Clear aisle and cross-aisle width', kind: RequirementKind.decimal, min: .001, unit: 'm', required: true),
  RequirementField('rt_checkout_width', 'Checkout and queue width', kind: RequirementKind.decimal, min: .001, unit: 'm', required: true),
  RequirementField('rt_checkout_depth', 'Checkout counter depth', kind: RequirementKind.decimal, min: .001, unit: 'm', required: true),
  RequirementField('rt_queue_depth', 'Queue clear depth', kind: RequirementKind.decimal, min: .001, unit: 'm', required: true),
  RequirementField('rt_rear_access', 'Rear staff approach depth, if needed', kind: RequirementKind.decimal, min: .001, unit: 'm'),
];
