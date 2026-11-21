import 'project_requirements.dart';

const facadeLouvreMode = 'office_measured_facade_louvre';

bool facadeLouvreCadEligible(String? category, String? group, String? type) =>
    category == 'commercial' && group == 'office' && const {'small_office', 'corporate_office', 'branch_office'}.contains(type);

RequirementField _measure(String id, String label, {num min = .001, num max = 30, String unit = 'm'}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final facadeLouvreCadFields = <RequirementField>[
  _measure('fl_width', 'Measured façade bay width'),
  _measure('fl_height', 'Measured façade bay height'),
  _measure('fl_side', 'Unassessed side margin at each jamb', min: 0),
  _measure('fl_sill', 'Distance from sill to bottom of first blade', min: 0),
  _measure('fl_head', 'Minimum reserve above the top blade', min: 0),
  _measure('fl_pitch', 'Vertical pitch between blade undersides'),
  _measure('fl_thickness', 'Vertical blade thickness', max: 5),
  _measure('fl_projection', 'Horizontal blade projection from the façade plane', max: 10),
  _measure('fl_low', 'Lower submitted profile angle above horizontal', min: 0, max: 89.9, unit: '°'),
  _measure('fl_high', 'Higher submitted profile angle above horizontal', max: 89.9, unit: '°'),
  _measure('fl_min_open', 'Minimum directly lit fraction of a clear gap at the lower angle', max: 100, unit: '%'),
  _measure('fl_min_shade', 'Minimum shaded fraction of a clear gap at the higher angle', max: 100, unit: '%'),
];
