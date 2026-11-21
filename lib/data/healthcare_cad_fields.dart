import 'project_requirements.dart';
import 'space_planning.dart';

/// Deliberately outpatient-only. Hospital intake must not inherit this capability.
const separatedClinicTypes = {
  'primary_health_centre', 'community_health_centre', 'polyclinic',
  'general_clinic', 'specialty_clinic', 'dental_clinic',
};

const patientRoomIds = {'registration', 'waiting', 'consultation', 'examination', 'accessible_toilet'};
const serviceRoomIds = {'staff_facilities', 'staff_change', 'clinical_store'};
const unsupportedClinicRoomIds = {
  'patient_ward', 'triage', 'emergency', 'observation', 'isolation', 'icu', 'theatre',
  'clean_utility', 'dirty_utility', 'cssd', 'diagnostics', 'imaging', 'medical_gas',
  'waste_holding', 'laundry', 'ambulance',
};

final clinicCadFields = <RequirementField>[
  const RequirementField('hc_patient_width', 'Patient wing width along frontage', kind: RequirementKind.decimal,
    min: .001, unit: 'm', required: true),
  const RequirementField('hc_service_corridor', 'Service passage width', kind: RequirementKind.decimal,
    min: .001, unit: 'm', required: true),
  planningChoice('hc_service_entry', 'Service entrance side', {
    'same': 'Same frontage, separate entrance', 'opposite': 'Opposite side of building',
  }),
  planningChoice('hc_transfer', 'Internal transfer between wings', {
    'not_required': 'Not required: wings can operate with separate external access',
    'required': 'Required: the two wings must connect inside',
  }),
];

final clinicRoomRoute = planningChoice('hc_route', 'Clinic route for this room', {
  'patient': 'Patient route', 'service': 'Staff / service route',
});
