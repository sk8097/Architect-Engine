import 'project_taxonomy.dart';

class ZoningProfile {
  const ZoningProfile(this.focus, this.front, this.back);
  final String focus;
  final Set<String> front, back;

  String preferredEdge(String? access) => front.contains(access) ? 'front' : back.contains(access) ? 'rear' : 'any';
}

/// Access tags influence the starting side of a zone search, not code checks.
/// Every taxonomy program must have a policy; never infer building use from labels.
const zoningProfiles = <String, ZoningProfile>{
  'single_room': ZoningProfile('Room and support zones', {'public'}, {'private'}),
  'home': ZoningProfile('Living and private zones', {'public', 'semi_public'}, {'private', 'service'}),
  'apartment': ZoningProfile('Shared and unit zones', {'public', 'semi_public'}, {'private', 'service'}),
  'community': ZoningProfile('Homes, shared amenities and service zones', {'public', 'semi_public'}, {'service', 'restricted'}),
  'hostel': ZoningProfile('Resident and shared zones', {'public', 'semi_public'}, {'private', 'service'}),
  'senior': ZoningProfile('Resident, care and service zones', {'public'}, {'staff', 'service'}),
  'office': ZoningProfile('Visitor, staff and operations zones', {'public', 'semi_public'}, {'staff', 'restricted'}),
  'retail': ZoningProfile('Sales and back-of-house zones', {'public', 'semi_public'}, {'service', 'staff', 'restricted'}),
  'hotel': ZoningProfile('Guest and service zones', {'public', 'semi_public'}, {'private', 'service', 'staff'}),
  'food': ZoningProfile('Customer and kitchen-service zones', {'public', 'semi_public'}, {'service', 'staff', 'restricted'}),
  'service': ZoningProfile('Customer and restricted work zones', {'public'}, {'restricted', 'service', 'staff'}),
  'factory': ZoningProfile('Production and logistics zones', {'public', 'staff'}, {'service', 'restricted'}),
  'warehouse': ZoningProfile('Receiving, storage and dispatch zones', {'service'}, {'restricted'}),
  'workshop': ZoningProfile('Service and work-bay zones', {'public', 'service'}, {'restricted'}),
  'utility': ZoningProfile('Operations and equipment zones', {'staff'}, {'service', 'restricted'}),
  'education': ZoningProfile('Learning and supervised access zones', {'public', 'semi_public'}, {'restricted', 'service'}),
  'healthcare': ZoningProfile('Patient, staff and clinical service zones', {'public', 'semi_public'}, {'restricted', 'service'}),
  'civic': ZoningProfile('Public, screened and staff zones', {'public', 'semi_public'}, {'restricted', 'staff'}),
  'culture': ZoningProfile('Assembly and support zones', {'public', 'semi_public'}, {'staff', 'restricted'}),
  'sports': ZoningProfile('Activities, spectators and support zones', {'public', 'semi_public'}, {'service', 'staff'}),
  'farm': ZoningProfile('Production, farm access and support zones', {'service'}, {'restricted'}),
  'agro': ZoningProfile('Receiving, processing and dispatch zones', {'service'}, {'restricted', 'staff'}),
  'rural': ZoningProfile('Visitor and rural service zones', {'public'}, {'private', 'service'}),
  'mixed': ZoningProfile('Use components and shared services', {'public', 'semi_public'}, {'service', 'restricted'}),
  'complex': ZoningProfile('Public, operational and specialist reserves', {'public'}, {'service', 'restricted'}),
  'heritage': ZoningProfile('Use and protection zones', {'public'}, {'restricted', 'service'}),
  'emergency': ZoningProfile('Receiving and operational support zones', {'public', 'service'}, {'restricted'}),
  'transport': ZoningProfile('Movement and support zones', {'public', 'service'}, {'restricted'}),
  'water': ZoningProfile('Treatment, storage and maintenance zones', {'staff'}, {'restricted', 'service'}),
  'landscape': ZoningProfile('Public realm and maintenance zones', {'public'}, {'service', 'restricted'}),
};

ZoningProfile? zoningProfile(TaxonomyGroup group, TaxonomyChoice type) => zoningProfiles[type.programId ?? group.programId];
