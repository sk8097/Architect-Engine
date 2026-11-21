import 'project_requirements.dart';
import 'project_taxonomy.dart';

const sqftPerSqm = 10.7639104167;

/// Editable concept allowances, not building-code minima or surveyed sizes.
class PlanningSize {
  const PlanningSize(this.width, this.depth, this.typical);
  final double width, depth, typical;
  double get minimum => width * depth;

  bool fits(double availableWidth, double availableDepth) =>
      (width <= availableWidth && depth <= availableDepth) ||
      (depth <= availableWidth && width <= availableDepth);
}

const homeRoomSizes = <String, PlanningSize>{
  'master_bedroom': PlanningSize(9, 10, 120),
  'secondary_bedroom': PlanningSize(9, 10, 120),
  'childrens_bedroom': PlanningSize(8, 10, 100),
  'guest_bedroom': PlanningSize(8, 10, 100),
  'family_living_room': PlanningSize(10, 12, 160),
  'dining_room': PlanningSize(8, 8, 100),
  'open_kitchen': PlanningSize(7, 8, 85),
  'closed_kitchen': PlanningSize(7, 8, 85),
  'shared_bathroom': PlanningSize(5, 7, 45),
  'attached_bathroom': PlanningSize(5, 7, 45),
  'pantry': PlanningSize(4, 4, 25),
  'utility_area': PlanningSize(5, 6, 45),
  'study': PlanningSize(6, 8, 75),
  'garden': PlanningSize(6, 8, 90),
};

const pujaSizes = {
  'niche': PlanningSize(2, 2, 6),
  'corner': PlanningSize(3, 4, 16),
  'room': PlanningSize(5, 6, 40),
};

// Which existing profile inputs are essential to describe the intended use.
// These are brief requirements, not engineered occupancy/capacity defaults.
const planningEssentialIds = <String, Set<String>>{
  'single_room': {'room_use'}, 'apartment': {'unit_count', 'apartment_mix'},
  'community': {'phase_program'}, 'hostel': {'resident_capacity'}, 'senior': {'resident_capacity'},
  'office': {'workstations'}, 'retail': {'shop_count'}, 'hotel': {'room_keys'}, 'food': {'restaurant_model'},
  'service': {'service_process'}, 'factory': {'process_flow'}, 'warehouse': {'commodity', 'clear_height'},
  'workshop': {'workshop_equipment'}, 'utility': {'utility_capacity', 'equipment_envelope'},
  'education': {'students'}, 'healthcare': {'clinical_departments'}, 'civic': {'public_services'},
  'culture': {'stakeholder_needs'}, 'sports': {'sports_dimensions'}, 'farm': {'farm_use'},
  'agro': {'storage_capacity'}, 'rural': {'rural_services'}, 'mixed': {'mixed_components', 'component_schedule'},
  'complex': {'complex_core'}, 'heritage': {'condition_survey'}, 'emergency': {'supported_people'},
  'transport': {'transport_survey'}, 'water': {'catchment'}, 'landscape': {'public_realm_use'},
};

RequirementField asRequired(RequirementField field) => RequirementField(field.id, field.label,
    kind: field.kind, unit: field.unit, options: field.options, required: true,
    dependsOn: field.dependsOn, when: field.when, min: field.min, max: field.max);

const _yesNo = [TaxonomyChoice('yes', 'Yes'), TaxonomyChoice('no', 'No')];
RequirementField planningChoice(String id, String label, Map<String, String> choices,
    {bool required = true, String? dependsOn, List<String> when = const []}) => RequirementField(
      id, label, kind: RequirementKind.choice, required: required, dependsOn: dependsOn, when: when,
      options: [for (final item in choices.entries) TaxonomyChoice(item.key, item.value)],
    );
RequirementField planningArea(String id, String label) => RequirementField(id, label,
    kind: RequirementKind.decimal, unit: 'sqft', min: 0.01, required: true);

List<RequirementField> residentialPlanningFields(bool vastu) => [
  if (vastu) const RequirementField('vastu_notes', 'Specific Vastu preferences (if any)'),
  const RequirementField('puja_needed', 'Puja space needed?', kind: RequirementKind.choice,
    options: _yesNo, required: true),
  planningChoice('puja_form', 'Puja space', {'niche': 'Wall niche', 'corner': 'Puja corner', 'room': 'Separate puja room'},
    dependsOn: 'puja_needed', when: ['yes']),
];

List<RequirementField> accessPlanningFields(int floors, bool terrace, bool parking) => [
  if (floors > 1 || terrace) ...[
    planningChoice('stair_access', 'Stair access', {'inside': 'Inside the building', 'outside': 'Outside / independent', 'lobby': 'Shared lobby', 'suggest': 'App suggest location'}),
    planningChoice('stair_form', 'Stair shape', {'straight': 'Straight', 'l': 'L-shape', 'u': 'U-shape', 'spiral': 'Spiral (review required)', 'suggest': 'Decide after review'}),
    if (floors > 1) planningChoice('upper_use', 'Upper floor access', {'private': 'Same household / occupier', 'separate': 'Independent unit(s)', 'common': 'Common access'}),
    planningChoice('lift_plan', 'Lift', {'none': 'No lift', 'future': 'Future provision', 'now': 'Include lift'}),
    if (floors == 1) planningArea('ground_access_area', 'Stair and landing allowance on ground floor'),
  ],
  if (parking) planningArea('parking_sqft', 'Space for parking including manoeuvring'),
  if (terrace) ...[
    planningArea('terrace_sqft', 'Available terrace area'),
    const RequirementField('terrace_use', 'Terrace zones', kind: RequirementKind.multi, required: true, options: [
      TaxonomyChoice('open', 'Open terrace'), TaxonomyChoice('covered', 'Covered seating'),
      TaxonomyChoice('enclosed', 'Enclosed room'), TaxonomyChoice('garden', 'Terrace garden'),
    ]),
  ],
];

class AreaBudget {
  const AreaBudget({this.width, this.depth, required this.total, required this.available,
    required this.minimum, required this.typical, required this.unknown});
  final double? width, depth;
  final double total, available, minimum, typical;
  final bool unknown;
  double get remaining => available - minimum;
  bool fits(PlanningSize size) => remaining + 0.001 >= size.minimum &&
    (width == null || depth == null || size.fits(width!, depth!));
}

double? positiveNumber(Object? value) {
  final n = double.tryParse('${value ?? ''}');
  return n != null && n.isFinite && n > 0 ? n : null;
}

AreaBudget estimatePlanningArea({double? width, double? depth, double? surveyedSqft,
  Map<String, Object> rules = const {}, double minimum = 0, double typical = 0,
  bool unknown = false}) {
  double setback(String side) => (positiveNumber(rules['${side}_setback']) ?? 0) / .3048;
  final total = surveyedSqft ?? ((width ?? 0) * (depth ?? 0));
  final w = width == null ? null : (width - setback('left') - setback('right')).clamp(0.0, width).toDouble();
  final d = depth == null ? null : (depth - setback('front') - setback('rear')).clamp(0.0, depth).toDouble();
  final available = w == null || d == null ? total : w * d;
  return AreaBudget(width: w, depth: d, total: total, available: available,
    minimum: minimum, typical: typical, unknown: unknown);
}

/// Living, kitchen and at least one bathroom are reserved once per dwelling.
({double minimum, double typical}) dwellingAllowance(int bedrooms, int bathrooms) {
  final bath = bathrooms < 1 ? 1 : bathrooms;
  return (minimum: 1.15 * (120 + 56 + 35.0 * bath + 90.0 * bedrooms),
    typical: 1.2 * (160 + 85 + 45.0 * bath + 120.0 * bedrooms));
}

/// A wall/room allowance is charged to the level where the space is requested.
({double minimum, double typical}) homeLevelAllowance(int bedrooms, int bathrooms, bool kitchenAndLiving) => (
  minimum: 1.15 * ((kitchenAndLiving ? 176.0 : 0.0) + 35.0 * bathrooms + 90.0 * bedrooms),
  typical: 1.2 * ((kitchenAndLiving ? 245.0 : 0.0) + 45.0 * bathrooms + 120.0 * bedrooms),
);
