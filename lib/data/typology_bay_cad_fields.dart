import 'project_requirements.dart';

const typologyBayMode = 'typology_measured_bay_cad';

bool typologyBayCadEligible(String? category, String? group, String? type) =>
    (category ?? '').trim().isNotEmpty &&
    (group ?? '').trim().isNotEmpty &&
    (type ?? '').trim().isNotEmpty;

RequirementField _m(String id, String label, {num min = .001, num max = 500}) =>
    RequirementField(id, label, kind: RequirementKind.measurement, unit: 'm', required: true, min: min, max: max);

RequirementField _count(String id, String label, {num min = 1, num max = 20}) =>
    RequirementField(id, label, kind: RequirementKind.number, required: true, min: min, max: max);

final typologyBayCadFields = <RequirementField>[
  _m('tb_site_w', 'Site / parcel width', min: 3, max: 500),
  _m('tb_site_d', 'Site / parcel depth', min: 3, max: 500),
  _m('tb_setback_front', 'Front setback', min: 0, max: 50),
  _m('tb_setback_side', 'Side setback (each side)', min: 0, max: 50),
  _m('tb_setback_rear', 'Rear setback', min: 0, max: 50),
  _count('tb_bays_x', 'Structural bays across width', min: 1, max: 20),
  _count('tb_bays_y', 'Structural bays along depth', min: 1, max: 20),
  _m('tb_bay_w', 'Bay width', min: 2, max: 30),
  _m('tb_bay_d', 'Bay depth', min: 2, max: 30),
  _m('tb_corridor_w', 'Main circulation / corridor width', min: 1.2, max: 12),
  _m('tb_clear_h', 'Floor-to-floor height', min: 2.4, max: 18),
  _count('tb_storeys', 'Number of storeys', min: 1, max: 12),
];
