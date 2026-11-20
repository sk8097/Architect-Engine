import 'project_taxonomy.dart';

const requirementsSchemaVersion = 1;

enum RequirementKind { text, integer, decimal, choice, multi }

class RequirementField {
  const RequirementField(this.id, this.label, {
    this.kind = RequirementKind.text,
    this.unit,
    this.options = const [],
    this.required = false,
    this.dependsOn,
    this.when = const [],
    this.min,
    this.max,
  });

  final String id;
  final String label;
  final RequirementKind kind;
  final String? unit;
  final List<TaxonomyChoice> options;
  final bool required;
  final String? dependsOn;
  final List<String> when;
  final num? min;
  final num? max;

  bool applies(Map<String, Object> values) =>
      dependsOn == null || when.contains(values[dependsOn]);

  bool _blank(Object? value) => value == null ||
      (value is String && value.trim().isEmpty) || (value is Iterable && value.isEmpty);

  String? validate(Object? value) {
    if (_blank(value)) return required ? 'Enter or select $label.' : null;
    switch (kind) {
      case RequirementKind.integer:
      case RequirementKind.decimal:
        final number = kind == RequirementKind.integer
            ? int.tryParse('$value'.trim()) : double.tryParse('$value'.trim());
        if (number == null || !number.isFinite) {
          return kind == RequirementKind.integer ? 'Enter a whole number.' : 'Enter a valid number.';
        }
        if (min != null && number < min!) return 'Enter a value of at least $min.';
        if (max != null && number > max!) return 'Enter a value no greater than $max.';
        return null;
      case RequirementKind.choice:
        return options.any((o) => o.id == value) ? null : 'Select a listed option.';
      case RequirementKind.multi:
        return value is Iterable && value.every((v) => options.any((o) => o.id == v))
            ? null : 'Select listed options.';
      case RequirementKind.text:
        return value is String ? null : 'Enter text.';
    }
  }

  Object? normalized(Object? value) {
    if (_blank(value) || validate(value) != null) return null;
    return switch (kind) {
      RequirementKind.integer => int.parse('$value'.trim()),
      RequirementKind.decimal => double.parse('$value'.trim()),
      RequirementKind.multi => (value as Iterable).whereType<String>().toList(growable: false),
      _ => (value as String).trim(),
    };
  }

  String? display(Object? value) {
    final answer = normalized(value);
    if (answer == null) return null;
    if (kind == RequirementKind.choice) return taxonomyChoice(options, answer as String)?.label;
    if (kind == RequirementKind.multi) {
      return (answer as List<String>).map((id) => taxonomyChoice(options, id)!.label).join(', ');
    }
    return unit == null || unit!.isEmpty ? '$answer' : '$answer $unit';
  }
}

Map<String, Object> requirementAnswers(Iterable<RequirementField> fields, Map<String, Object> draft) {
  final result = <String, Object>{};
  for (final field in fields) {
    if (!field.applies(draft)) continue;
    final value = field.normalized(draft[field.id]);
    if (value != null) result[field.id] = value;
  }
  return result;
}

// These helpers parse author-authored, explicit ID|label pairs. IDs are never
// computed from labels and may be kept unchanged when the wording changes.
List<TaxonomyChoice> _options(String input) => input.split(';').map((entry) {
  final parts = entry.split('|');
  return TaxonomyChoice(parts[0], parts[1]);
}).toList(growable: false);

RequirementField _select(String id, String label, String options, {bool multi = false}) =>
    RequirementField(id, label, kind: multi ? RequirementKind.multi : RequirementKind.choice, options: _options(options));
RequirementField _count(String id, String label, {num min = 0, num? max}) =>
    RequirementField(id, label, kind: RequirementKind.integer, min: min, max: max);
RequirementField _measure(String id, String label, String unit, {num min = 0}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, min: min, unit: unit);

final projectInformationFields = <RequirementField>[
  const RequirementField('client', 'Client / owner'),
  const RequirementField('contact', 'Contact details'),
  const RequirementField('address', 'Street address / site address'),
  const RequirementField('city', 'City / locality'),
  const RequirementField('region', 'State / region'),
  const RequirementField('country', 'Country'),
  const RequirementField('postal_code', 'Postal code'),
  _select('delivery', 'Delivery model', 'single|Single building;multiple|Multiple buildings;campus|Campus;estate|Estate;township|Township;subdivision|Plot subdivision;phased|Phased development'),
  _select('build_status', 'New-build status', 'greenfield|Greenfield;brownfield|Brownfield;existing|Existing building;partial_demolition|Existing site with partial demolition'),
  _select('occupancy_status', 'Occupancy during works', 'vacant|Vacant;occupied|Occupied;partial|Partially occupied;operational|Operational during works'),
  _select('scope', 'Project scope', 'architecture|Architecture;interiors|Interiors;landscape|Landscape;site_planning|Site planning;structure|Structural coordination;mep|MEP coordination;fire|Fire / life safety;accessibility|Accessibility;sustainability|Sustainability;cost|Cost and area planning', multi: true),
  const RequirementField('project_notes', 'Project description / priorities / notes'),
];

const previousDesignField = RequirementField('source_project', 'Existing drawing / survey / project reference');
const customTypeField = RequirementField('custom_type', 'Specify the unlisted project type and intended use', required: true);
const customSiteKindField = RequirementField('custom_site_kind', 'Site data type for this infrastructure project',
  kind: RequirementKind.choice, required: true, options: [
    TaxonomyChoice('parcel', 'Parcel / facility'), TaxonomyChoice('linear', 'Alignment / corridor'),
  ]);
const customConfigurationField = RequirementField('custom_configuration', 'Describe the unlisted configuration', required: true);

bool usesLinearSite(String category, String group, String type) => category == 'infrastructure' && (
    (group == 'transport' && const {'road','street','intersection','roundabout','bridge','flyover','underpass','tunnel','footpath','cycle_track'}.contains(type)) ||
    (group == 'water' && const {'water_distribution','stormwater_drain','culvert','drainage_network','sewerage_network'}.contains(type)) ||
    (group == 'energy' && const {'utility_corridor','street_lighting_network','distribution_utility','telecom_network'}.contains(type)) ||
    (group == 'public_realm' && const {'greenway','waterfront_promenade','streetscape'}.contains(type)));

final siteCommonFields = <RequirementField>[
  const RequirementField('site_id', 'Site / parcel reference'),
  _select('site_status', 'Site context', 'vacant|Vacant plot;existing|Existing building;partial|Partially built;redevelopment|Redevelopment;brownfield|Brownfield;agricultural|Agricultural;hillside|Sloping / hilly;waterfront|Waterfront;corner|Corner plot;interior|Interior plot;contiguous|Multiple contiguous parcels', multi: true),
  _select('topography', 'Levels / topography', 'level|Level;gentle|Gentle slope;steep|Steep slope;split|Split-level;retaining|Retaining required;cut_fill|Cut-and-fill likely;survey|Survey pending'),
  _select('site_conditions', 'Observed site conditions', 'stable|Developed / stable;soft|Soft soil suspected;rocky|Rocky;fill|Filled ground;waterlogged|Waterlogged;flood|Flood-prone;water_table|High water table;erosion|Erosion-prone;contaminated|Contamination suspected;trees|Existing trees;utilities|Existing utilities;structures|Existing structures;demolition|Demolition required;unknown|Investigation required', multi: true),
  _select('exposure', 'Climate / exposure', 'hot_dry|Hot-dry;warm_humid|Warm-humid;composite|Composite;temperate|Temperate;cold|Cold;rain|High rainfall;coastal|Coastal / saline;wind|High wind;snow|Snow / freeze;seismic|Seismic review', multi: true),
  _select('context', 'Neighbours / context', 'low_rise|Low-rise;mid_rise|Mid-rise;high_rise|High-rise;residential|Residential;commercial|Commercial;industrial|Industrial;institutional|Institutional;open|Open land;heritage|Heritage;protected|Sensitive / protected', multi: true),
  _select('access', 'Road / access type', 'one|One road;two|Two roads;three|Three roads;four|Four-side access;private|Private road;shared|Shared access;service|Service road;highway|Highway / arterial;rural|Rural road;lane|Access lane'),
  _select('road_sides', 'Road edges / entry sides', 'n|North;ne|North-east;e|East;se|South-east;s|South;sw|South-west;w|West;nw|North-west;survey|Survey required', multi: true),
  _measure('road_width', 'Existing road width', 'm', min: 0.01),
  _select('utilities', 'Available infrastructure', 'water|Water;sewer|Sewer;stormwater|Stormwater;power|Electricity;gas|Gas;telecom|Telecom / fibre;road|Road;transit|Public transport;fire|Fire access;waste|Waste collection', multi: true),
  const RequirementField('survey_reference', 'Survey reference / date / datum'),
  const RequirementField('site_observations', 'Existing structures, trees, access and survey notes'),
];

final surveyedPlotFields = <RequirementField>[
  _measure('surveyed_plot_area', 'Surveyed plot area', 'm²', min: 0.01),
  _measure('rear_width', 'Rear width', 'm', min: 0.01),
  _measure('left_depth', 'Left depth', 'm', min: 0.01),
  _measure('right_depth', 'Right depth', 'm', min: 0.01),
  _select('coordinate_unit', 'Survey coordinate unit', 'mm|mm;cm|cm;m|m;ft|ft;in|in'),
  const RequirementField('survey_boundary', 'Survey boundary / ordered coordinates (recorded as notes)'),
];

final alignmentFields = <RequirementField>[
  const RequirementField('alignment_reference', 'Alignment / corridor survey reference'),
  _measure('route_length', 'Surveyed route length', 'm', min: 0.01),
  _measure('right_of_way', 'Available right-of-way', 'm', min: 0.01),
  const RequirementField('chainage', 'Start and end chainage / datum'),
  const RequirementField('cross_section', 'Cross-section and terrain notes'),
  const RequirementField('crossings', 'Crossings / utilities / network tie-ins'),
];

final jurisdictionFields = <RequirementField>[
  const RequirementField('jurisdiction', 'Jurisdiction / local authority'),
  const RequirementField('land_use', 'Recorded land-use / zoning designation'),
  _select('rule_status', 'Rule reference status', 'unverified|Unverified;unavailable|Unavailable;reference_provided|Reference supplied (not checked by app)'),
  const RequirementField('rule_reference', 'Code / rule edition and source', required: true, dependsOn: 'rule_status', when: ['reference_provided']),
  const RequirementField('restrictions', 'Easements, right-of-way, heritage, height, flood or other constraints'),
  _measure('front_setback', 'Front setback from supplied authority data', 'm'),
  _measure('rear_setback', 'Rear setback from supplied authority data', 'm'),
  _measure('left_setback', 'Left setback from supplied authority data', 'm'),
  _measure('right_setback', 'Right setback from supplied authority data', 'm'),
  _measure('max_height', 'Height limit from supplied authority data', 'm', min: 0.01),
  const RequirementField('coverage_limit', 'Coverage limit from supplied authority data', kind: RequirementKind.decimal, min: 0, max: 100, unit: '%'),
  _measure('fsi_limit', 'FAR / FSI limit from supplied authority data', 'ratio'),
];

final buildingProgramFields = <RequirementField>[
  _count('building_count', 'Buildings', min: 1),
  _count('wing_count', 'Blocks / wings', min: 1),
  _count('basements', 'Basements'),
  _count('mezzanines', 'Mezzanines'),
  _count('typical_floors', 'Typical floors'),
  _measure('floor_to_floor', 'Preferred floor-to-floor height', 'm', min: 0.01),
  _measure('target_height', 'Target building height', 'm', min: 0.01),
  _measure('target_builtup_area', 'Target gross built-up area', 'm²', min: 0.01),
  _select('roof', 'Roof preference', 'flat|Flat;sloped|Sloped;terrace|Accessible terrace;green|Green roof;long_span|Long-span;engineered|To be engineered'),
  _select('construction_status', 'Construction status', 'proposed|Proposed;existing|Existing;partial|Partially constructed;renovation|Under renovation;demolish|To be demolished'),
  _select('vertical', 'Vertical circulation requested', 'stair|Stair;fire_stair|Fire stair;lift|Passenger lift;service_lift|Service lift;ramp|Ramp;escalator|Escalator;platform_lift|Platform lift;goods_lift|Goods lift', multi: true),
  _select('access_zones', 'Access zones', 'public|Public;semi_public|Semi-public;restricted|Restricted;staff|Staff-only;service|Service-only;accessible|Accessible route', multi: true),
];

final operationalFields = <RequirementField>[
  _count('peak_people', 'Expected peak occupancy / visitors', min: 1),
  const RequirementField('use_mix', 'Occupancy / use mix and capacity notes'),
  const RequirementField('operating_hours', 'Operating hours / shifts'),
  const RequirementField('loading_needs', 'Service, deliveries and loading needs'),
];

final parkingFields = <RequirementField>[
  _select('parking_arrangement', 'Parking arrangement', 'open|Open surface;covered|Covered;stilt|Stilt;basement|Basement;podium|Podium;mechanical|Mechanical;accessible|Accessible;ev|EV charging;visitor|Visitor;bicycle|Bicycle;loading|Loading / service bays', multi: true),
  _count('cars', 'Car spaces'), _count('two_wheelers', 'Two-wheeler spaces'),
  _count('bicycles', 'Bicycle spaces'), _count('accessible_bays', 'Accessible bays'),
  _count('ev_bays', 'EV charging bays'), _count('loading_bays', 'Loading bays'),
];

final technicalFields = <RequirementField>[
  _select('structure_preference', 'Non-final structural preference', 'rcc|RCC;steel|Steel;timber|Timber;masonry|Masonry;composite|Composite;long_span|Long-span;engineered|To be engineered'),
  _select('services', 'Services to coordinate', 'hvac|HVAC;electrical|Electrical;lighting|Lighting;plumbing|Plumbing;drainage|Drainage;fire|Fire protection;ict|ICT / data;security|Security;bms|BMS;renewable|Renewable energy;backup|Backup power;water_treatment|Water treatment;waste|Waste handling', multi: true),
  _select('accessibility', 'Accessibility targets', 'universal|Universal design;step_free|Step-free routes;toilets|Accessible toilets;parking|Accessible parking;wayfinding|Wayfinding;assistance|Hearing / visual assistance', multi: true),
  const RequirementField('fire_review', 'Fire / life-safety inputs for specialist review'),
  const RequirementField('equipment_requirements', 'Equipment sizes, loads and clearance notes'),
  const RequirementField('discipline_review', 'Engineering, environmental or specialist coordination notes'),
];

final preferenceFields = <RequirementField>[
  _select('style', 'Design style', 'modern|Modern;contemporary|Contemporary;traditional|Traditional;vernacular|Vernacular;minimalist|Minimalist;industrial|Industrial;tropical|Tropical;biophilic|Biophilic;classic|Classic;art_deco|Art Deco;brutalist|Brutalist;high_tech|High-tech;heritage|Heritage-inspired;luxury|Luxury;affordable|Affordable / functional;contextual|Contextual;fusion|Fusion'),
  _select('form', 'Building form preference', 'compact|Compact;courtyard|Courtyard;linear|Linear;l_shape|L-shaped;u_shape|U-shaped;h_shape|H-shaped;cluster|Clustered;atrium|Atrium;pavilion|Pavilion;tower|Tower and podium;campus|Campus;modular|Modular;expandable|Expandable'),
  _select('planning', 'Planning preference', 'open|Open plan;cellular|Cellular;hybrid|Hybrid;central_core|Central core;side_core|Side core;double_corridor|Double-loaded corridor;single_corridor|Single-loaded corridor;courtyard|Courtyard;atrium|Atrium;zones|Public / private / service zoning'),
  _select('privacy', 'Privacy', 'high|High;balanced|Balanced;open|Open / collaborative;controlled|Controlled access'),
  _select('daylight', 'Daylight preference', 'standard|Standard;prioritized|Daylight prioritized;glare|Glare controlled;deep_plan|Deep-plan mitigation'),
  _select('ventilation', 'Ventilation preference', 'natural|Natural;mixed|Mixed mode;mechanical|Mechanical;process|Process-specific exhaust'),
  _select('sustainability', 'Sustainability targets', 'passive|Passive design;shading|Shading;daylight|Daylighting;natural_air|Natural ventilation;rainwater|Rainwater harvesting;greywater|Greywater reuse;pv|Solar PV;solar_hot|Solar hot water;green_roof|Green roof;low_carbon|Low-carbon materials;local|Local materials;heat|Heat-island mitigation;waste|Waste segregation;ev|EV readiness', multi: true),
  _select('finish', 'Materials / finish intent', 'economy|Economy;standard|Standard;premium|Premium;luxury|Luxury;durable|Durable / low maintenance;local|Locally available;specified|Client specified'),
  _select('vastu', 'Vastu preference (advisory)', 'none|Not required;user|User-provided preferences;review|Review requested'),
  const RequirementField('vastu_notes', 'User-provided orientation / Vastu preferences', dependsOn: 'vastu', when: ['user']),
];

final deliveryFields = <RequirementField>[
  _count('alternatives', 'Requested layout options', min: 1, max: 5),
  _select('compare_by', 'Compare options by', 'area|Area efficiency;circulation|Circulation;privacy|Privacy;daylight|Daylight;ventilation|Ventilation;cost|Cost;expand|Expandability;site|Site fit;access|Accessibility;sustainability|Sustainability;vastu|Vastu preference', multi: true),
  _select('layout_strategy', 'Layout strategy', 'compact|Compact;balanced|Balanced;spacious|Spacious;flexible|Flexible;expandable|Future-expandable;efficient|Operationally efficient'),
  _select('area_basis', 'Source of area target', 'user|User-provided;brief|Brief-derived;standard|Identified standard;benchmark|Reference benchmark;unknown|Not yet known'),
  const RequirementField('area_reference', 'Standard / benchmark reference', required: true, dependsOn: 'area_basis', when: ['standard', 'benchmark']),
  _select('area_metrics', 'Requested area metrics', 'plot|Plot area;coverage|Ground coverage;builtup|Built-up;gfa|Gross floor area;net|Net usable;carpet|Carpet;far|FAR / FSI;parking|Parking;landscape|Open space;service|Service', multi: true),
  _measure('budget', 'Target budget amount', 'currency units'),
  const RequirementField('currency', 'Budget currency / ISO code'),
  _select('cost_tier', 'Cost tier', 'economy|Economy;standard|Standard;premium|Premium;luxury|Luxury;specialist|Specialist / high performance'),
  _select('cost_source', 'Cost basis', 'user|User budget;database|Local database;quantity|Quantity-based estimate;benchmark|Benchmark;unavailable|Unavailable'),
  _select('procurement', 'Procurement', 'bid|Design-bid-build;design_build|Design-build;managed|Construction management;phased|Phased;owner|Owner-built;unknown|Not decided'),
  _select('delivery_priority', 'Delivery priority', 'initial|Lowest initial cost;lifecycle|Lowest lifecycle cost;fast|Fast delivery;durability|High durability;maintenance|Low maintenance;flexibility|High flexibility'),
  const RequirementField('schedule', 'Target dates / phases / operational constraints'),
  _select('requested_outputs', 'Requested deliverables (not generated yet)', 'site_analysis|Site analysis;area_statement|Area statement;bubble|Bubble diagram;adjacency|Adjacency matrix;concepts|Concept options;site_plan|Site plan;floor_plans|Floor plans;elevations|Elevations;sections|Sections;roof_plan|Roof plan;furniture|Furniture layout;ceiling|Reflected ceiling;openings|Door / window schedule;finishes|Finish schedule;room_schedule|Room schedule;massing|3D massing;views|3D views;landscape|Landscape plan;parking|Parking plan;accessibility|Accessibility review;fire|Fire coordination;mep|MEP coordination;structure|Structural coordination;cost|Quantity / cost;permit|Approval set;tender|Tender set;working|Working drawings;as_built|As-built set;brief|Project brief', multi: true),
  _select('export_interest', 'Preferred formats (unavailable in this wizard)', 'pdf|PDF;png|PNG;jpg|JPG;svg|SVG;dxf|DXF;dwg|DWG;ifc|IFC', multi: true),
];

final _profileFields = <String, List<RequirementField>>{
  'single_room': [
    _measure('room_area', 'Preferred room area', 'm²', min: 0.01),
    _select('room_use', 'Room use', 'sleeping|Sleeping;living|Living;work|Work;guest|Guest;utility|Utility;flexible|Flexible'),
  ],
  'home': [
    _select('house_form', 'House form / storey arrangement', 'single_floor|Single floor;duplex|Duplex;triplex|Triplex;g_plus_n|G+N;split_level|Split-level;custom|Custom'),
    _select('kitchen_type', 'Kitchen type', 'open|Open;closed|Closed;semi_open|Semi-open;parallel|Parallel;l_shape|L-shaped;u_shape|U-shaped;island|Island;peninsula|Peninsula;wet_dry|Wet + dry kitchen'),
    _count('bedrooms', 'Bedroom count', min: 1), _count('common_toilets', 'Common bathrooms / toilets'),
    _count('attached_toilets', 'Attached bathrooms'),
    _select('house_priorities', 'House requirements', 'ground_bedroom|Ground-floor bedroom;elderly|Elderly-friendly;office|Work from home;rental|Separate rental access;formal|Separate formal/family zones;expansion|Future vertical expansion;solar|Solar ready;rainwater|Rainwater harvesting ready', multi: true),
    const RequirementField('house_form_custom', 'Describe the unlisted house form', required: true, dependsOn: 'house_form', when: ['custom']),
  ],
  'apartment': [
    _count('units_per_floor', 'Units per typical floor', min: 1), _count('unit_count', 'Total units', min: 1),
    _count('tower_count', 'Tower count', min: 1),
    _select('apartment_mix', 'Unit mix', 'studio|Studio;1_bhk|1 BHK;2_bhk|2 BHK;3_bhk|3 BHK;4_bhk|4 BHK;5_plus|5+ BHK;penthouse|Penthouse;accessible|Accessible units', multi: true),
    _select('management', 'Management model', 'owned|Owner-occupied;rental|Rental;coliving|Co-living;serviced|Serviced;society|Cooperative / society;affordable|Affordable / regulated housing'),
    const RequirementField('unit_mix_counts', 'Unit quantities by layout / floor'),
    _select('unit_layout', 'Unit layout preferences', 'single|Single aspect;dual|Dual aspect;corner|Corner;through|Through unit;balcony|Balcony;terrace|Terrace;split|Split-level;open_kitchen|Open kitchen;separate_kitchen|Separate kitchen;study|Study nook;utility|Utility balcony;staff|Staff room', multi: true),
  ],
  'community': [_count('plots', 'Plots / dwellings', min: 1), _count('tower_count', 'Tower count', min: 1), const RequirementField('phase_program', 'Development phases and shared amenities')],
  'hostel': [_count('resident_capacity', 'Resident capacity', min: 1), _count('room_count', 'Sleeping rooms', min: 1), _count('beds_per_room', 'Beds per typical room', min: 1)],
  'senior': [_count('resident_capacity', 'Resident capacity', min: 1), _count('care_units', 'Care units'), const RequirementField('care_program', 'Care and accessibility brief')],
  'office': [_count('workstations', 'Workstations', min: 1), _count('tenants', 'Tenants', min: 1), _measure('floor_plate', 'Target floor-plate area', 'm²', min: 0.01),
    _select('desk_model', 'Workplace model', 'fixed|Fixed desks;activity|Activity-based;hybrid|Hybrid work;hot_desk|Hot desking;shifts|Shift-based;continuous|24/7'), const RequirementField('department_mix', 'Departments and office / meeting capacity by team')],
  'retail': [_count('shop_count', 'Shop units', min: 1), _measure('frontage', 'Target shop frontage', 'm', min: 0.01), _measure('sales_area', 'Display / sales area', 'm²', min: 0.01), _measure('stock_area', 'Stock / back-of-house area', 'm²', min: 0.01),
    _select('retail_form', 'Retail setting', 'single|Single shop;multiple|Multiple shops;corner|Corner shop;street|Street retail;mall|Mall unit')],
  'hotel': [_count('room_keys', 'Guest rooms / keys', min: 1), _count('suite_count', 'Suites'),
    _select('guest_room_mix', 'Guest-room mix', 'standard|Standard;superior|Superior;deluxe|Deluxe;twin|Twin;double|Double;king|King;family|Family;suite|Suite;junior|Junior suite;accessible|Accessible;connecting|Connecting;longstay|Long-stay', multi: true), const RequirementField('guest_room_counts', 'Room counts by type')],
  'food': [_count('seats', 'Customer seats'), _select('restaurant_model','Service model','fine|Fine dining;casual|Casual;quick|Quick service;family|Family;cafe|Café;bakery|Bakery;buffet|Buffet;specialty|Specialty cuisine;drive|Drive-through;takeaway|Takeaway;delivery|Delivery-first;stall|Food hall stall'), const RequirementField('food_operations', 'Menu, meal throughput, kitchen and exhaust notes')],
  'service': [_count('service_stations', 'Customer / service stations', min: 1), const RequirementField('service_process', 'Customer journey and restricted work areas')],
  'factory': [_measure('clear_height', 'Required clear height', 'm', min: 0.01),
    const RequirementField('throughput', 'Production capacity and unit / time period'), const RequirementField('process_flow', 'Process flow, equipment footprints and material movement'), const RequirementField('specialist_process', 'Plant, environmental and specialist hazard review needs')],
  'warehouse': [_measure('clear_height', 'Required clear height', 'm', min: 0.01), _count('pallet_positions', 'Pallet positions'), _count('dock_count', 'Docks / loading doors'),
    _select('dock_type', 'Dock / yard types', 'high|Dock-high;grade|Grade-level;multiple|Multiple docks;cross|Cross-dock;canopy|Canopy;yard|Yard;trailers|Trailer parking;turning|Truck turning;weighbridge|Weighbridge;gatehouse|Gatehouse', multi: true),
    const RequirementField('truck_envelope', 'Truck type, size and vehicle movement'), const RequirementField('commodity', 'Commodity, rack dimensions, storage height and specialist review notes')],
  'workshop': [_count('service_bays', 'Service bays', min: 1), _measure('clear_height', 'Required clear height', 'm', min: 0.01), const RequirementField('workshop_equipment', 'Machines / vehicle sizes and working zones')],
  'utility': [const RequirementField('utility_capacity', 'Design capacity and units'), const RequirementField('equipment_envelope', 'Equipment footprint and specialist clearance inputs'), const RequirementField('redundancy', 'Power / cooling / backup requirements')],
  'education': [_count('students', 'Student capacity', min: 1), _count('classrooms', 'Classrooms', min: 1), const RequirementField('academic_program', 'Grades, departments and authority / board references'), const RequirementField('school_access', 'Safeguarding, supervision, labs and safe drop-off needs')],
  'healthcare': [_count('beds', 'Patient beds'), _count('consult_rooms', 'Consultation rooms'), _count('procedure_rooms', 'Procedure rooms'),
    _select('clinical_departments','Department requirements','opd|Outpatient;emergency|Emergency;ipd|Inpatient;icu|ICU;ot|Operating theatre;diagnostics|Diagnostics;pharmacy|Pharmacy;isolation|Isolation;cssd|Sterilisation / CSSD;rehab|Rehabilitation',multi:true),
    const RequirementField('clinical_flow', 'Patient, staff, clean/dirty workflow and licensing review notes')],
  'civic': [_count('service_counters', 'Public service counters'), const RequirementField('public_services', 'Public services and queue capacity'), const RequirementField('security_zoning', 'Public / screened / staff access review')],
  'culture': [_count('seating', 'Seats / congregation capacity'), const RequirementField('stakeholder_needs', 'Event, stakeholder or worship-specific requirements'), _measure('hall_area', 'Target hall area', 'm²', min: 0.01)],
  'sports': [_count('spectators', 'Spectator capacity'), _count('activity_areas', 'Fields / courts / pools', min: 1), const RequirementField('sports_dimensions', 'Sport, activity dimensions and applicable design reference')],
  'farm': [_measure('farm_area', 'Land in operation', 'hectare', min: 0.01), const RequirementField('farm_use', 'Crop / livestock type and season'), const RequirementField('farm_water', 'Water demand, irrigation and drainage'), const RequirementField('farm_logistics', 'Equipment, storage duration and hygiene requirements')],
  'agro': [const RequirementField('storage_capacity', 'Commodity and storage capacity / units'), const RequirementField('agro_process', 'Processing, receiving, grading and dispatch workflow'), _measure('shed_height', 'Clear shed height', 'm', min: 0.01)],
  'rural': [_count('visitor_capacity', 'Daily visitor capacity', min: 1), _count('overnight_capacity', 'Overnight capacity'), const RequirementField('rural_services', 'Water, wastewater and community constraints')],
  'mixed': [
    _select('mixed_components', 'Use components', 'housing|Housing;office|Offices;retail|Retail;food|Food service;hotel|Hotel;entertainment|Entertainment;community|Community facilities;transit|Transit;parking|Parking', multi: true),
    _select('mixed_levels', 'Level zoning', 'ground|Public ground;podium|Retail podium;office|Office levels;housing|Housing levels;hotel|Hotel levels;amenity|Amenity levels;plant|Plant levels;parking|Parking levels;service|Service levels', multi: true),
    _select('mixed_management', 'Operating model','single|Single owner;multiple|Multiple owners;association|Condominium / association;lease|Lease mix;public_private|Public-private;phased|Phased development'),
    _select('mixed_separation', 'Separation / shared-service coordination', 'entries|Independent entries;lobbies|Separate lobbies;lifts|Separate lift banks;acoustics|Acoustic separation;exhaust|Exhaust separation;loading|Loading and waste routes;fire|Fire compartment review;metering|Shared utility metering', multi: true),
    const RequirementField('component_schedule', 'Areas, floors, capacities and units by use component'),
  ],
  'complex': [_count('tower_count', 'Tower count', min: 1), _count('podium_levels', 'Podium levels'), _count('plant_levels', 'Plant / service floors'), const RequirementField('specialist_signoffs', 'Required specialist reviews and sign-offs'), const RequirementField('complex_core', 'Core, vertical transportation, redundancy and evacuation brief')],
  'heritage': [const RequirementField('condition_survey', 'Measured drawing / photo / condition survey reference'), const RequirementField('protected_elements', 'Protected elements and conservation constraints'), const RequirementField('heritage_approvals', 'Proposed reversible works and approval references')],
  'emergency': [_count('supported_people', 'Expected supported population', min: 1), _count('operation_days', 'Expected duration (days)', min: 1), const RequirementField('autonomy', 'Water, power, sanitation and logistics needs')],
  'transport': [_count('lanes', 'Lanes'), _count('bays_platforms', 'Bays / platforms'), _count('passenger_capacity', 'Peak passengers', min: 1), const RequirementField('transport_survey', 'Vehicle mix, traffic counts, speeds and turning survey')],
  'water': [_measure('design_flow', 'Design flow supplied by specialist', 'm³/day', min: 0.01), _measure('storage_volume', 'Target storage volume', 'm³', min: 0.01), const RequirementField('catchment', 'Population/load, rainfall, catchment and flood data'), const RequirementField('water_service', 'Water quality, process, discharge / reuse and approvals')],
  'landscape': [_measure('public_area','Target public realm area','m²',min:0.01), const RequirementField('public_realm_use','User groups, public use and maintenance needs'),const RequirementField('landscape_conditions','Water, soil, climate, flood and service constraints')],
};

final _typeFields = <String, List<RequirementField>>{
  'houses/rural_house': [_select('rural_house_style','Rural house style','traditional|Traditional;modern|Modern;hybrid|Hybrid'),_count('household_size','Household size',min:1),const RequirementField('rural_house_utilities','Water, sanitation and outdoor utility needs')],
  'farm/farmhouse': [_count('farmhouse_bedrooms','Bedrooms',min:1),_measure('farmhouse_built_area','Target residential built-up area','m²',min:0.01),const RequirementField('farmhouse_program','Household rooms and separation from farm operations')],
  'manufacturing/process_plant': [const RequirementField('plant_zones','Process, equipment and control zones'),const RequirementField('plant_corridors','Pipe / service corridors and maintenance access')],
  'healthcare/multi_specialty_hospital': [_count('specialties','Clinical specialties',min:1),const RequirementField('department_capacities','Capacity and operating requirements by department')],
  'mixed_development/mall_office': [_count('mixed_anchors','Retail anchors'),_count('office_levels','Office levels'),const RequirementField('mall_office_access','Separate retail, office and loading access')],
  'mixed_development/hotel_office': [_count('hotel_keys','Hotel keys',min:1),_measure('hotel_office_area','Target office area','m²',min:0.01),const RequirementField('hotel_commercial_services','Back-of-house, loading and guest/office separation')],
  'complex/cluster_development': [_count('cluster_units','Plots / units',min:1),const RequirementField('cluster_phasing','Cluster phases and shared access / services')],
  'complex/gated_community': [_count('community_plots','Plots / units',min:1),const RequirementField('community_facilities','Internal roads, gated access, open spaces and amenities')],
  'complex/township': [_measure('township_land','Township land area','hectare',min:0.01),_count('target_population','Target population',min:1),const RequirementField('township_phasing','Use mix, phases, transport and shared community services')],
  'complex/campus_development': [_select('campus_focus','Campus focus','education|Education;healthcare|Healthcare;corporate|Corporate;institutional|Institutional;mixed|Mixed'),const RequirementField('campus_program','Departments, blocks and shared facilities')],
  'complex/redevelopment': [_measure('retained_area','Target retained area','m²'),_count('proposed_units','Proposed units'),const RequirementField('retention_phases','Existing survey, retention / demolition and phased access')],
  'complex/integrated_development': [const RequirementField('integrated_components','Land-use mix, capacity, components and phasing')],
  'water/sewerage_network': [const RequirementField('sewer_reaches','Network reaches, treatment and pumping tie-ins')],
  'water/drainage_network': [const RequirementField('drainage_profile','Catchment references, gradients, outfalls and discharge constraints')],
  'energy/electrical_substation': [const RequirementField('substation_spec','Equipment ratings, maintenance access and authority clearance reference')],
  'houses/row_house': [_count('row_units','Row unit count',min:1), _select('row_position','Unit position','single|Single;mid|Mid;end|End;corner|Corner;multi|Multi-unit row'), const RequirementField('party_walls','Shared walls and access conditions')],
  'houses/townhouse': [_count('row_units','Townhouse unit count',min:1), _select('row_position','Unit position','single|Single;mid|Mid;end|End;corner|Corner;multi|Multi-unit row'), const RequirementField('party_walls','Shared walls and access conditions')],
  'apartments/low_rise_apartment': [_select('stilt_layout','Stilt / floor configuration','stilt_g1|Stilt + 1;stilt_g2|Stilt + 2;stilt_g3|Stilt + 3;stilt_g4|Stilt + 4;no_stilt|No stilt')],
  'apartments/mid_rise_apartment': [_select('floor_band','Brief floor band (not a legal class)','g4|G+4;g5|G+5;g10|G+10;g15|G+15;g20|G+20;g25|G+25;g30|G+30')],
  'apartments/high_rise_apartment': [_select('floor_band','Brief floor band (not a legal class)','g4|G+4;g5|G+5;g10|G+10;g15|G+15;g20|G+20;g25|G+25;g30|G+30'), const RequirementField('core_notes','Core, lifts, fire stairs, refuge and MEP brief')],
  'complex/high_rise_supertall_building': [_select('tower_band','Brief floor band (not a legal class)','31_50|31–50;51_75|51–75;76_100|76–100;101_plus|101+'), const RequirementField('wind_lift_review','Wind, structure and vertical transportation review needs')],
  'residential_works/slum_chawl_redevelopment': [_count('existing_units','Existing units'),_count('rehab_units','Rehabilitation units'),_count('proposed_units','Proposed units'),const RequirementField('rehab_survey','Existing settlement survey and rehabilitation programme')],
  'retail/showroom': [_select('showroom_levels','Display arrangement','single|Single level;multi|Multi-level;double|Double height'), _measure('display_height','Target display clear height','m',min:0.01)],
  'commercial_development/it_park': [_count('it_capacity','Office capacity / workstations',min:1),const RequirementField('it_amenities','Campus amenities, IT, UPS and cooling coordination')],
  'retail/shopping_mall': [_count('anchors','Anchor stores'),_measure('mall_retail_area','Target retail area','m²',min:0.01),const RequirementField('mall_circulation','Atrium, escalator, service lift and loading brief')],
  'business_services/multiplex': [_count('screen_count','Screen count',min:2),_count('seats_per_screen','Typical seats per screen',min:1),const RequirementField('projection_spaces','Screen-specific seats, projection and service notes')],
  'lodging/resort': [_count('villa_cottage_count','Villas / cottages'),_measure('resort_land','Resort land area','m²',min:0.01),const RequirementField('resort_amenities','Accommodation mix, amenity and outdoor zones')],
  'lodging/serviced_apartment': [_count('serviced_units','Serviced units',min:1),_select('serviced_mix','Serviced unit mix','studio|Studio;1_bhk|1 BHK;2_bhk|2 BHK;3_bhk|3 BHK',multi:true),const RequirementField('serviced_operations','Kitchenettes, housekeeping and shared facilities')],
  'logistics/logistics_park': [_count('warehouses','Warehouse buildings',min:1),_count('peak_trucks','Peak trucks'),const RequirementField('shared_logistics','Yards, security and shared utility / staging requirements')],
  'logistics/cold_storage': [_select('cold_zones','Temperature zones','chilled|Chilled;frozen|Frozen;multi|Multi-temperature'),_count('chambers','Chambers',min:1),const RequirementField('cold_chain','Temperature targets, room sizes, refrigeration and backup')],
  'logistics/freezer_warehouse': [_count('chambers','Freezer chambers',min:1),const RequirementField('cold_chain','Temperature targets, room sizes, refrigeration and backup')],
  'workshop/msme_cottage_industry_shed': [_select('shed_scale','Workshop scale','cottage|Cottage industry;msme|Small MSME;workshop|Workshop'),const RequirementField('shed_product','Production method, storage and ventilation notes')],
  'education/college': [_select('college_focus','College focus','general|General;engineering|Engineering;medical|Medical;arts_commerce|Arts / Commerce;technical|Technical'),_count('departments','Departments',min:1)],
  'education/university': [_count('departments','Departments',min:1),const RequirementField('university_blocks','Academic, research, housing and shared campus blocks')],
  'culture/community_hall': [_select('stage_option','Stage preference','none|No stage;fixed|Fixed;movable|Movable')],
  'farm/dairy_farm': [_count('animal_capacity','Livestock capacity',min:1),const RequirementField('livestock_ops','Feeding, water, veterinary, ventilation and waste needs')],
  'farm/livestock_facility': [_count('animal_capacity','Livestock capacity',min:1),_select('livestock_type','Livestock type','cattle|Cattle;dairy|Dairy;goat|Goat;sheep|Sheep',multi:true)],
  'farm/poultry_farm': [_count('bird_capacity','Bird capacity',min:1),_count('poultry_sheds','Shed count',min:1),_select('poultry_model','Operation','broiler|Broiler;layer|Layer;breeding|Breeding'),const RequirementField('poultry_needs','Feeding, ventilation, hygiene and service access needs')],
  'agro_processing/agricultural_shed': [_select('shed_use','Shed use','grain|Grain storage;produce|Produce storage;equipment|Equipment shed'),_measure('shed_width','Target shed width','m',min:0.01),_measure('shed_length','Target shed length','m',min:0.01)],
  'mixed_development/shop_cum_office': [_select('sco_layout','Shop / office arrangement','ground_shop|Ground shop + office;g1|G+1;g2|G+2'),_measure('office_area','Target office share','m²',min:0.01),_measure('shop_area','Target retail share','m²',min:0.01)],
  'transport/road': [_select('road_class','Road context','internal|Internal;residential|Residential;commercial|Commercial;arterial|Arterial'),_measure('carriageway','Target carriageway width','m',min:0.01)],
  'transport/bridge': [_select('bridge_use','Crossing use','road|Road;pedestrian|Pedestrian;shared|Shared'),_measure('bridge_span','Surveyed span / crossing distance','m',min:0.01),const RequirementField('bridge_clearance','Crossing, approaches and clearance notes for review')],
  'transport/parking_structure': [_select('parking_structure_form','Parking structure type','surface|Surface;levels|Multi-level;basement|Basement;automated|Automated'),const RequirementField('parking_design_data','Bay, ramp and vehicle-turning notes for review')],
  'water/culvert': [_measure('opening_width','Surveyed opening width','m',min:0.01),_measure('opening_height','Surveyed opening height','m',min:0.01),const RequirementField('culvert_levels','Inlet, outlet and ground levels from survey')],
};

List<RequirementField> facilityFields(TaxonomyGroup group, TaxonomyChoice type) => [
  ...?_profileFields[type.programId ?? group.programId],
  ...?_typeFields['${group.id}/${type.id}'],
];

List<RequirementField> spaceDetailFields(List<TaxonomyChoice> adjacentSpaces) => [
  _select('priority','Requirement priority','must|Must have;should|Should have;nice|Nice to have;excluded|Excluded'),
  _select('area_unit','Area unit','sqm|m²;sqft|ft²'),
  _measure('area_min','Minimum area (chosen area unit)','',min:0.01),
  _measure('area_target','Target area (chosen area unit)','',min:0.01),
  _measure('area_max','Maximum area (chosen area unit)','',min:0.01),
  _measure('width','Clear width','m',min:0.01), _measure('length','Clear length','m',min:0.01),
  _measure('clear_height','Clear height','m',min:0.01),
  const RequirementField('floor_level','Requested floor / level'),
  _count('capacity','Occupants / capacity',min:1), const RequirementField('occupancy_type','Occupancy / use notes'),
  if (adjacentSpaces.isNotEmpty) ...[
    RequirementField('adjacent_required','Must be adjacent to',kind: RequirementKind.multi,options:adjacentSpaces),
    RequirementField('adjacent_preferred','Prefer to be adjacent to',kind: RequirementKind.multi,options:adjacentSpaces),
    RequirementField('separate_from','Must be separated from',kind: RequirementKind.multi,options:adjacentSpaces),
  ],
  _select('access','Access level','public|Public;semi_public|Semi-public;private|Private;staff|Staff;restricted|Restricted;service|Service'),
  _select('privacy','Privacy','public|Public;semi_public|Semi-public;semi_private|Semi-private;private|Private;restricted|Restricted'),
  _select('daylight','Daylight','required|Required;preferred|Preferred;none|Not required;controlled|Controlled'),
  _select('lighting','Lighting','general|General;task|Task;accent|Accent;emergency|Emergency;daylight|Daylight-controlled',multi:true),
  _select('ventilation','Ventilation','natural|Natural;mechanical|Mechanical;mixed|Mixed mode;exhaust|Dedicated exhaust;process|Process-specific;smoke|Engineered smoke control'),
  _select('acoustic','Acoustics','quiet|Quiet;normal|Normal;noisy|Noisy;isolated|Sound-isolated;controlled|Acoustic-controlled'),
  _select('environment','Environmental control','ambient|Unconditioned;fan|Fan-assisted;ac|Air-conditioned;temperature|Temperature-controlled;humidity|Humidity-controlled;cleanroom|Specialist cleanroom'),
  _select('services','Room services','wet|Wet service;drainage|Drainage;gas|Gas;power|Power;data|Data;exhaust|Exhaust',multi:true),
  _select('equipment_source','Furniture / equipment scope','none|None;user|User-listed;standard|Standard equipment set;process|Process equipment schedule'),
  const RequirementField('equipment','Furniture and equipment list / dimensions'),
  const RequirementField('accessibility','Accessibility needs'), const RequirementField('fire_notes','Fire / life-safety notes for specialist review'),
  _select('finish','Finish / durability','basic|Basic;standard|Standard;premium|Premium;heavy|Heavy-duty;hygienic|Hygienic;chemical|Chemical-resistant;slip|Slip-resistant;acoustic|Acoustic;fire|Fire-rated subject to specification'),
  const RequirementField('notes','Rationale / special notes'),
];

String? validateSpaceDetails(Map<String, Object> values) {
  num? area(String id) => num.tryParse('${values[id] ?? ''}');
  final minimum = area('area_min'), target = area('area_target'), maximum = area('area_max');
  if ([minimum, target, maximum].any((v) => v != null) && values['area_unit'] == null) {
    return 'Select an area unit for the entered room areas.';
  }
  if ((minimum != null && target != null && minimum > target) ||
      (target != null && maximum != null && target > maximum) ||
      (minimum != null && maximum != null && minimum > maximum)) {
    return 'Room areas must be ordered minimum ≤ target ≤ maximum.';
  }
  final seen = <Object>{};
  for (final key in spaceAdjacencyKeys) {
    final ids = values[key];
    if (ids is Iterable && ids.any((id) => !seen.add(id))) {
      return 'Use only one adjacency relationship per other space.';
    }
  }
  return null;
}

const spaceAdjacencyKeys = ['adjacent_required', 'adjacent_preferred', 'separate_from'];

bool isExcludedSpace(Map<String, Object>? details) => details?['priority'] == 'excluded';

Map<String, int> activeSpaceQuantities(
  Map<String, String> quantities, Map<String, Map<String, Object>> details,
) {
  final active = <String, int>{};
  for (final entry in quantities.entries) {
    if (isExcludedSpace(details[entry.key])) continue;
    final quantity = int.tryParse(entry.value.trim());
    if (quantity != null && quantity > 0) active[entry.key] = quantity;
  }
  return active;
}

/// Validate the complete space program, including reciprocal constraints.
String? validateSpaceProgram(
  Map<String, String> selected, Map<String, Map<String, Object>> details,
) {
  final relationships = <(String, String), bool>{};
  for (final from in selected.keys) {
    final source = details[from];
    if (source == null || isExcludedSpace(source)) continue;
    final issue = validateSpaceDetails(source);
    if (issue != null) return '${selected[from]}: $issue';
    for (final kind in spaceAdjacencyKeys) {
      final targets = source[kind];
      if (targets is! Iterable) continue;
      for (final to in targets.whereType<String>()) {
        if (from == to || !selected.containsKey(to) || isExcludedSpace(details[to])) {
          return '${selected[from]}: remove the adjacency reference to '
              '${selected[to] ?? to}; the target is excluded, missing, or the same space.';
        }
        final pair = from.compareTo(to) < 0 ? (from, to) : (to, from);
        final separate = kind == 'separate_from';
        final previous = relationships[pair];
        if (previous != null && previous != separate) {
          return '${selected[from]} and ${selected[to]} are marked both adjacent '
              'and separate. Correct one of the space requirements.';
        }
        relationships[pair] = separate;
      }
    }
  }
  return null;
}
