import 'project_requirements.dart';
import 'space_planning.dart';

RequirementField cadOutputOptions({required bool warehouseLoading, bool clinicSeparated = false, bool retailFixtures = false, bool dwellingG1 = false, bool schoolArrival = false, bool packhouseFlow = false, bool mixedShopHome = false, bool crossDock = false, bool officeWorkplace = false, bool diningService = false, bool cattleShed = false, bool assembly = false, bool libraryReading = false, bool badminton = false, bool hostel = false, bool greenhouse = false, bool sharedCore = false, bool inpatientWard = false, bool truckSweep = false, bool pairedApartments = false, bool solarFarm = false, bool detentionBasin = false, bool evHub = false, bool orchard = false, bool switchbackRamp = false, bool teachingLab = false, bool hotelWing = false, bool basketball = false, bool rainwater = false, bool lapPool = false, bool publicMarket = false, bool raisedBeds = false, bool amphitheatre = false, bool parkLoop = false, bool windrowYard = false, bool galleryPanels = false, bool angledParking = false, bool coldRacks = false, bool twinTank = false, bool tennis = false, bool memorialNiche = false, bool bicycleRack = false, bool playground = false}) => planningChoice('cad_output', 'Automatic drawing', {
  if (playground) 'playground_measured_zones': 'Playground: measured equipment and clearance zones',
  if (bicycleRack) 'bicycle_measured_racks': 'Bicycle parking: measured two-sided stands',
  if (memorialNiche) 'memorial_niche_walls': 'Memorial: measured niche walls and elevation',
  if (tennis) 'tennis_measured_bank': 'Outdoor tennis: measured court bank',
  if (twinTank) 'tank_twin_cell': 'Twin-cell tank: measured storage and single-cell reserve',
  if (coldRacks) 'cold_storage_racks': 'Cold storage: measured pallet racks and bay schedule',
  if (angledParking) 'angled_surface_parking': 'Surface parking: measured angled stalls and through aisle',
  if (galleryPanels) 'gallery_panel_layout': 'Gallery: double-sided display panels and clear viewing zones',
  if (windrowYard) 'windrow_measured_yard': 'Composting yard: measured windrows and geometric volume',
  if (parkLoop) 'park_measured_loop': 'Public park: measured walking loop and lawn reserve',
  if (amphitheatre) 'outdoor_tiered_amphitheatre': 'Outdoor amphitheatre: stage, tiers and centreline sightline',
  if (raisedBeds) 'garden_raised_beds': 'Public garden: raised beds, paths and medium takeoff',
  if (publicMarket) 'public_market_stalls': 'Open-air public market: measured stalls and circulation',
  if (lapPool) 'lap_pool_measured': 'Outdoor lap pool: measured lanes, deck and floor section',
  if (rainwater) 'rainwater_roof_tanks': 'Roof rainwater: measured catchment and tank storage',
  if (basketball) 'basketball_measured_court': 'Outdoor basketball: measured markings and run-offs',
  if (hotelWing) 'hotel_guestroom_wing': 'Hotel wing: mirrored guestrooms and shared corridor',
  if (teachingLab) 'school_teaching_lab': 'Teaching lab: measured bench banks and enclosed prep room',
  if (switchbackRamp) 'measured_switchback': 'Public-space ramp: two flights and turning landings',
  if (orchard) 'orchard_measured_rows': 'Orchard: measured planting rows and access loop',
  if (evHub) 'ev_measured_hub': 'EV charging yard: measured bays, equipment and transfer route',
  if (detentionBasin) 'basin_stage_storage': 'Detention / retention basin: plan, section and storage',
  if (solarFarm) 'solar_fixed_tilt': 'Solar farm: measured fixed-tilt rows and shade clearance',
  if (pairedApartments) 'paired_apartments': 'Paired 1 BHK flats: shared lobby and mirrored rooms',
  if (truckSweep) 'truck_reverse_sweep': 'Loading apron: rigid truck reverse swept path',
  if (inpatientWard) 'inpatient_ward': 'General ward: measured bed bays and nursing access',
  if (sharedCore) 'shared_core_shop_office': 'Shop below office: shared lobby, stair and shaft',
  if (greenhouse) 'greenhouse_benches': 'Greenhouse: measured bench banks and work aisles',
  if (hostel) 'hostel_shared_rooms': 'Hostel: shared bedrooms, beds and lockers',
  if (badminton) 'badminton_hall': 'Indoor badminton: measured courts and separate viewing',
  if (libraryReading) 'library_reading': 'Library: checkout, open stacks and quiet reading',
  if (assembly) 'assembly_workflow': 'Factory assembly: material route, staff passage and benches',
  if (cattleShed) 'cattle_shed': 'Cattle shed: double pen rows, feed and cleaning lanes',
  if (diningService) 'dining_service': 'Dine-in: seating, kitchen pass and dish return',
  if (officeWorkplace) 'office_workplace': 'Office: visitor rooms and measured staff workstations',
  if (crossDock) 'warehouse_cross_dock': 'Cross-dock: opposing inbound and outbound banks',
  if (mixedShopHome) ...{
    'mixed_shop_home': 'Shop + dwelling: side-by-side with independent entries',
    'mixed_shop_below_home': 'Shop below dwelling: independent stair and entries',
  },
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
