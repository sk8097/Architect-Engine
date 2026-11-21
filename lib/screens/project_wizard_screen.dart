import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/project_taxonomy.dart';
import '../data/project_requirements.dart';
import '../data/detailed_cad_fields.dart';
import '../data/warehouse_cad_fields.dart';
import '../data/truck_sweep_fields.dart';
import '../data/solar_farm_fields.dart';
import '../data/detention_basin_fields.dart';
import '../data/ev_hub_fields.dart';
import '../data/orchard_cad_fields.dart';
import '../data/switchback_ramp_fields.dart';
import '../data/teaching_lab_fields.dart';
import '../data/hotel_wing_fields.dart';
import '../data/basketball_cad_fields.dart';
import '../data/rainwater_cad_fields.dart';
import '../data/lap_pool_cad_fields.dart';
import '../data/public_market_cad_fields.dart';
import '../data/raised_bed_cad_fields.dart';
import '../data/amphitheatre_cad_fields.dart';
import '../data/park_loop_cad_fields.dart';
import '../data/windrow_yard_cad_fields.dart';
import '../data/gallery_panel_cad_fields.dart';
import '../data/angled_parking_cad_fields.dart';
import '../data/cold_rack_cad_fields.dart';
import '../data/rain_garden_cad_fields.dart';
import '../data/dock_leveller_cad_fields.dart';
import '../data/aquaculture_pond_cad_fields.dart';
import '../data/silage_bunker_cad_fields.dart';
import '../data/bouldering_bay_cad_fields.dart';
import '../data/weighbridge_cad_fields.dart';
import '../data/cooling_loop_cad_fields.dart';
import '../data/boardwalk_cad_fields.dart';
import '../data/circular_clarifier_cad_fields.dart';
import '../data/blade_laydown_cad_fields.dart';
import '../data/cricket_nets_cad_fields.dart';
import '../data/skate_transition_cad_fields.dart';
import '../data/park_fence_cad_fields.dart';
import '../data/transformer_bund_cad_fields.dart';
import '../data/football_pitch_cad_fields.dart';
import '../data/guyed_mast_cad_fields.dart';
import '../data/recycling_dropoff_cad_fields.dart';
import '../data/spillway_cad_fields.dart';
import '../data/battery_yard_cad_fields.dart';
import '../data/parking_ramp_cad_fields.dart';
import '../data/cinema_seating_cad_fields.dart';
import '../data/switchback_stair_cad_fields.dart';
import '../data/jump_runway_cad_fields.dart';
import '../data/plaza_paving_cad_fields.dart';
import '../data/shelter_canopy_cad_fields.dart';
import '../data/public_toilet_cad_fields.dart';
import '../data/vehicle_lift_cad_fields.dart';
import '../data/athletics_track_cad_fields.dart';
import '../data/playground_cad_fields.dart';
import '../data/bicycle_rack_cad_fields.dart';
import '../data/memorial_niche_cad_fields.dart';
import '../data/tennis_cad_fields.dart';
import '../data/twin_tank_cad_fields.dart';
import '../data/paired_apartment_fields.dart';
import '../data/cross_dock_cad_fields.dart';
import '../data/healthcare_cad_fields.dart';
import '../data/school_cad_fields.dart';
import '../data/office_cad_fields.dart';
import '../data/dining_cad_fields.dart';
import '../data/cattle_shed_cad_fields.dart';
import '../data/assembly_cad_fields.dart';
import '../data/library_cad_fields.dart';
import '../data/badminton_cad_fields.dart';
import '../data/hostel_cad_fields.dart';
import '../data/greenhouse_cad_fields.dart';
import '../data/shared_core_cad_fields.dart';
import '../data/inpatient_ward_cad_fields.dart';
import '../data/packhouse_cad_fields.dart';
import '../data/survey_corridor_fields.dart';
import '../data/longitudinal_profile_fields.dart';
import '../data/corridor_section_fields.dart';
import '../data/corridor_earthwork_fields.dart';
import '../data/stormwater_cad_fields.dart';
import '../data/open_drain_cad_fields.dart';
import '../data/bus_layby_cad_fields.dart';
import '../data/culvert_cad_fields.dart';
import '../data/refuge_crossing_cad_fields.dart';
import '../data/cycle_crossing_cad_fields.dart';
import '../data/promenade_cad_fields.dart';
import '../data/underpass_cad_fields.dart';
import '../data/stepped_wall_cad_fields.dart';
import '../data/street_light_cad_fields.dart';
import '../data/duct_bank_cad_fields.dart';
import '../data/rail_platform_cad_fields.dart';
import '../data/footbridge_cad_fields.dart';
import '../data/t_junction_cad_fields.dart';
import '../data/retail_cad_fields.dart';
import '../data/mixed_retail_cad_fields.dart';
import '../data/dwelling_cad_fields.dart';
import '../data/project_scenarios.dart';
import '../data/space_planning.dart';
import '../models/project_brief.dart';
import '../models/project_model.dart';
import '../models/project_requirements_snapshot.dart';
import '../providers/notification_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/requirement_fields.dart';
import '../services/automatic_floor_plan_generator.dart';
import 'automatic_floor_plan_screen.dart';
import 'tower_planner_screen.dart';
import 'concept_zoning_screen.dart';
import 'enclosed_cad_screen.dart';
import 'warehouse_loading_screen.dart';
import 'truck_sweep_screen.dart';
import 'solar_farm_screen.dart';
import 'detention_basin_screen.dart';
import 'ev_hub_screen.dart';
import 'orchard_cad_screen.dart';
import 'switchback_ramp_screen.dart';
import 'teaching_lab_screen.dart';
import 'hotel_wing_screen.dart';
import 'basketball_cad_screen.dart';
import 'rainwater_cad_screen.dart';
import 'lap_pool_cad_screen.dart';
import 'public_market_cad_screen.dart';
import 'raised_bed_cad_screen.dart';
import 'amphitheatre_cad_screen.dart';
import 'park_loop_cad_screen.dart';
import 'windrow_yard_cad_screen.dart';
import 'gallery_panel_cad_screen.dart';
import 'angled_parking_cad_screen.dart';
import 'cold_rack_cad_screen.dart';
import 'rain_garden_cad_screen.dart';
import 'dock_leveller_cad_screen.dart';
import 'aquaculture_pond_cad_screen.dart';
import 'silage_bunker_cad_screen.dart';
import 'bouldering_bay_cad_screen.dart';
import 'weighbridge_cad_screen.dart';
import 'cooling_loop_cad_screen.dart';
import 'boardwalk_cad_screen.dart';
import 'circular_clarifier_cad_screen.dart';
import 'blade_laydown_cad_screen.dart';
import 'cricket_nets_cad_screen.dart';
import 'skate_transition_cad_screen.dart';
import 'park_fence_cad_screen.dart';
import 'transformer_bund_cad_screen.dart';
import 'football_pitch_cad_screen.dart';
import 'guyed_mast_cad_screen.dart';
import 'recycling_dropoff_cad_screen.dart';
import 'spillway_cad_screen.dart';
import 'battery_yard_cad_screen.dart';
import 'parking_ramp_cad_screen.dart';
import 'cinema_seating_cad_screen.dart';
import 'switchback_stair_cad_screen.dart';
import 'jump_runway_cad_screen.dart';
import 'plaza_paving_cad_screen.dart';
import 'shelter_canopy_cad_screen.dart';
import 'public_toilet_cad_screen.dart';
import 'vehicle_lift_cad_screen.dart';
import 'athletics_track_cad_screen.dart';
import 'playground_cad_screen.dart';
import 'bicycle_rack_cad_screen.dart';
import 'memorial_niche_cad_screen.dart';
import 'tennis_cad_screen.dart';
import 'twin_tank_cad_screen.dart';
import '../services/rain_garden_cad_generator.dart';
import '../services/dock_leveller_cad_generator.dart';
import '../services/aquaculture_pond_cad_generator.dart';
import '../services/silage_bunker_cad_generator.dart';
import '../services/bouldering_bay_cad_generator.dart';
import '../services/weighbridge_cad_generator.dart';
import '../services/cooling_loop_cad_generator.dart';
import '../services/boardwalk_cad_generator.dart';
import '../services/circular_clarifier_cad_generator.dart';
import '../services/blade_laydown_cad_generator.dart';
import '../services/cricket_nets_cad_generator.dart';
import '../services/skate_transition_cad_generator.dart';
import '../services/park_fence_cad_generator.dart';
import '../services/transformer_bund_cad_generator.dart';
import '../services/football_pitch_cad_generator.dart';
import '../services/guyed_mast_cad_generator.dart';
import '../services/recycling_dropoff_cad_generator.dart';
import '../services/spillway_cad_generator.dart';
import '../services/battery_yard_cad_generator.dart';
import '../services/parking_ramp_cad_generator.dart';
import '../services/cinema_seating_cad_generator.dart';
import '../services/switchback_stair_cad_generator.dart';
import '../services/jump_runway_cad_generator.dart';
import '../services/plaza_paving_cad_generator.dart';
import '../services/shelter_canopy_cad_generator.dart';
import '../services/public_toilet_cad_generator.dart';
import '../services/vehicle_lift_cad_generator.dart';
import '../services/athletics_track_cad_generator.dart';
import '../services/playground_cad_generator.dart';
import '../services/bicycle_rack_cad_generator.dart';
import '../services/memorial_niche_cad_generator.dart';
import '../services/tennis_cad_generator.dart';
import '../services/twin_tank_cad_generator.dart';
import '../services/cold_rack_cad_generator.dart';
import '../services/angled_parking_cad_generator.dart';
import '../services/gallery_panel_cad_generator.dart';
import '../services/windrow_yard_cad_generator.dart';
import '../services/park_loop_cad_generator.dart';
import '../services/amphitheatre_cad_generator.dart';
import '../services/raised_bed_cad_generator.dart';
import '../services/public_market_cad_generator.dart';
import '../services/lap_pool_cad_generator.dart';
import '../services/rainwater_cad_generator.dart';
import '../services/basketball_cad_generator.dart';
import '../services/hotel_wing_generator.dart';
import '../services/teaching_lab_generator.dart';
import '../services/switchback_ramp_generator.dart';
import '../services/orchard_cad_generator.dart';
import '../services/ev_hub_generator.dart';
import '../services/detention_basin_generator.dart';
import '../services/solar_farm_generator.dart';
import 'paired_apartment_screen.dart';
import '../services/paired_apartment_generator.dart';
import '../services/truck_sweep_generator.dart';
import 'healthcare_cad_screen.dart';
import 'school_cad_screen.dart';
import 'office_cad_screen.dart';
import 'dining_cad_screen.dart';
import 'cattle_shed_cad_screen.dart';
import 'assembly_cad_screen.dart';
import 'library_cad_screen.dart';
import 'badminton_cad_screen.dart';
import 'hostel_cad_screen.dart';
import 'greenhouse_cad_screen.dart';
import 'shared_core_cad_screen.dart';
import 'inpatient_ward_cad_screen.dart';
import '../services/inpatient_ward_cad_generator.dart';
import '../services/shared_core_cad_generator.dart';
import '../services/greenhouse_cad_generator.dart';
import '../services/hostel_cad_generator.dart';
import '../services/badminton_cad_generator.dart';
import '../services/library_cad_generator.dart';
import '../services/assembly_cad_generator.dart';
import '../services/cattle_shed_cad_generator.dart';
import '../services/dining_cad_generator.dart';
import '../services/office_cad_generator.dart';
import 'packhouse_cad_screen.dart';
import 'survey_corridor_screen.dart';
import 'longitudinal_profile_screen.dart';
import 'corridor_section_screen.dart';
import 'corridor_earthwork_screen.dart';
import '../services/corridor_earthwork_generator.dart';
import '../services/corridor_section_generator.dart';
import 'stormwater_cad_screen.dart';
import 'open_drain_cad_screen.dart';
import 'bus_layby_cad_screen.dart';
import '../services/bus_layby_cad_generator.dart';
import '../services/open_drain_cad_generator.dart';
import 'culvert_cad_screen.dart';
import 'refuge_crossing_cad_screen.dart';
import 'cycle_crossing_cad_screen.dart';
import 'promenade_cad_screen.dart';
import 'underpass_cad_screen.dart';
import 'stepped_wall_cad_screen.dart';
import 'street_light_cad_screen.dart';
import 'duct_bank_cad_screen.dart';
import 'rail_platform_cad_screen.dart';
import 'footbridge_cad_screen.dart';
import '../services/refuge_crossing_cad_generator.dart';
import '../services/cycle_crossing_cad_generator.dart';
import '../services/promenade_cad_generator.dart';
import '../services/underpass_cad_generator.dart';
import '../services/stepped_wall_cad_generator.dart';
import '../services/street_light_cad_generator.dart';
import '../services/duct_bank_cad_generator.dart';
import '../services/rail_platform_cad_generator.dart';
import '../services/footbridge_cad_generator.dart';
import '../services/culvert_cad_generator.dart';
import '../services/stormwater_cad_generator.dart';
import '../services/longitudinal_profile_generator.dart';
import 't_junction_cad_screen.dart';
import '../services/t_junction_cad_generator.dart';
import '../services/cross_junction_cad_generator.dart';
import '../services/survey_corridor_generator.dart';
import '../services/packhouse_cad_generator.dart';
import '../services/school_cad_generator.dart';
import 'retail_cad_screen.dart';
import 'mixed_retail_cad_screen.dart';
import 'stacked_retail_cad_screen.dart';
import '../services/stacked_retail_cad_generator.dart';
import '../services/mixed_retail_cad_generator.dart';
import 'dwelling_g1_screen.dart';
import '../services/dwelling_g1_generator.dart';
import '../services/retail_cad_generator.dart';
import '../services/healthcare_cad_generator.dart';
import '../services/warehouse_loading_generator.dart';
import '../services/cross_dock_cad_generator.dart';
import '../services/enclosed_cad_generator.dart';

class ProjectWizardScreen extends StatefulWidget {
  const ProjectWizardScreen({super.key, this.existingProject, this.scenario, this.variant});

  final ProjectModel? existingProject;
  final ProjectScenario? scenario;
  final ProjectScenarioVariant? variant;

  static Future<void> open(BuildContext context, {ProjectModel? project,
    ProjectScenario? scenario, ProjectScenarioVariant? variant}) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => ProjectWizardScreen(existingProject: project, scenario: scenario, variant: variant),
    ));
  }

  @override
  State<ProjectWizardScreen> createState() => _ProjectWizardScreenState();
}

class _ProjectWizardScreenState extends State<ProjectWizardScreen> {
  static const _steps = [
    'Category', 'Subcategory', 'Project type', 'Configuration',
    'Space / room program', 'Project information', 'Site / plot / land',
    'Jurisdiction / rules', 'Facility requirements', 'Technical requirements',
    'Design preferences', 'Budget & deliverables', 'Review',
  ];
  static const _directions = [
    'North', 'North-East', 'East', 'South-East', 'South', 'South-West', 'West',
    'North-West', 'Not decided',
  ];

  final _sectionForms = List.generate(_steps.length, (_) => GlobalKey<FormState>());
  final _answers = <String, Object>{};
  final _facilityAnswers = <String, Object>{};
  final _spaceDetails = <String, Map<String, Object>>{};
  final _customSpaces = <String, String>{};
  String? _sectionError;
  final _spaceForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _width = TextEditingController();
  final _depth = TextEditingController();
  final _floors = TextEditingController();
  final _spaces = <String, String>{};
  TaxonomyCategory? _category;
  TaxonomyGroup? _group;
  TaxonomyChoice? _type;
  String? _configurationId;
  String? _actionId;
  String? _stageId;
  String? _shapeId;
  String? _facing;
  ProjectParking? _parking;
  String _typeQuery = '';
  int _step = 0;
  bool _saving = false;
  bool _unsupportedBrief = false;

  TaxonomyProgram get _program => taxonomyProgram(_group!, _type!);
  bool get _customInfrastructure => _category?.id == 'infrastructure' && _type?.id == 'custom';
  bool get _linearSite => _customInfrastructure
      ? _answers['custom_site_kind'] == 'linear'
      : _railPlatformCad || _busLaybyCad || (_type != null && usesLinearSite(_category!.id, _group!.id, _type!.id));
  bool get _isRectangular => !_linearSite && (_shapeId == 'rectangular' || _shapeId == 'square');
  bool get _wantsParking => !_linearSite && _parking != null && _parking != ProjectParking.none;
  List<TaxonomyChoice> get _allSpaces => [
    for (final room in _program.spaces)
      if ((!_mixedHomeCad && !_libraryCad && (!_hostelCad || hostelCadRoomIds.contains(room.id)) && !_greenhouseCad && !_sharedCoreCad && !_inpatientWardCad && !_surveySheetOnly && !_truckSweepCad && !_pairedApartmentCad && !_solarCad && !_basinCad && !_evHubCad && !_orchardCad && !_switchbackRampCad && !_teachingLabCad && !_hotelWingCad && !_basketballCad && !_rainwaterCad && !_lapPoolCad && !_publicMarketCad && !_raisedBedCad && !_amphitheatreCad && !_parkLoopCad && !_windrowYardCad && !_galleryPanelCad && !_angledParkingCad && !_coldRackCad && !_rainGardenCad && !_silageBunkerCad && !_aquaculturePondCad && !_dockLevellerCad && !_boulderingBayCad && !_weighbridgeCad && !_coolingLoopCad && !_boardwalkCad && !_circularClarifierCad && !_bladeLaydownCad && !_cricketNetsCad && !_skateTransitionCad && !_parkFenceCad && !_transformerBundCad && !_footballPitchCad && !_guyedMastCad && !_recyclingDropoffCad && !_spillwayCad && !_batteryYardCad && !_parkingRampCad && !_cinemaSeatingCad && !_switchbackStairCad && !_jumpRunwayCad && !_plazaPavingCad && !_shelterCanopyCad && !_publicToiletCad && !_vehicleLiftCad && !_athleticsTrackCad && !_playgroundCad && !_bicycleRackCad && !_memorialNicheCad && !_tennisCad && !_twinTankCad) || _spaces.containsKey(room.id)) room,
    if (_libraryEligible)
      for (final room in libraryCadRooms)
        if (_libraryCad || _spaces.containsKey(room.id)) room,
    if (_mixedEligible)
      for (final room in mixedDwellingRooms)
        if (_mixedHomeCad || _spaces.containsKey(room.id)) room,
    for (final item in _customSpaces.entries) TaxonomyChoice(item.key, item.value),
  ];
  List<RequirementField> get _facilitySchema => facilityFields(_group!, _type!);
  String get _programId => _type?.programId ?? _group?.programId ?? '';
  bool get _home => _programId == 'home';
  int get _floorCount => int.tryParse(_floors.text.trim()) ?? 0;
  bool get _terrace => _answers['terrace_needed'] == 'yes';
  bool get _vastu => const {'review', 'user'}.contains(_answers['vastu']);
  Iterable<int> get _levels => Iterable<int>.generate(_floorCount.clamp(0, 100).toInt());
  int get _bedrooms => int.tryParse('${_facilityAnswers['bedrooms'] ?? ''}') ??
    int.tryParse(RegExp(r'^([1-5])_(?:bhk|bedroom)$').firstMatch(_configurationId ?? '')?.group(1) ?? '') ??
    (const {'1_rk', 'studio'}.contains(_configurationId) ? 0 : -1);
  int get _baths => (int.tryParse('${_facilityAnswers['common_toilets'] ?? ''}') ?? 1) +
    (int.tryParse('${_facilityAnswers['attached_toilets'] ?? ''}') ?? 0);
  String _levelName(int n) => n == 0 ? 'Ground floor' : 'Floor $n';
  List<RequirementField> get _essential => [
    for (final field in _facilitySchema)
      if (((planningEssentialIds[_programId] ?? const <String>{}).contains(field.id) && !((_tennisCad || _athleticsTrackCad || _shelterCanopyCad || _plazaPavingCad || _jumpRunwayCad || _footballPitchCad || _cricketNetsCad || _boulderingBayCad) && field.id == 'sports_dimensions') && !(_vehicleLiftCad && field.id == 'workshop_equipment') && !(_cinemaSeatingCad && field.id == 'service_process') && !((_silageBunkerCad || _aquaculturePondCad) && field.id == 'farm_use') && !(_dockLevellerCad && const {'commodity', 'clear_height'}.contains(field.id)) && !((_spillwayCad || _circularClarifierCad) && field.id == 'catchment') && !((_memorialNicheCad || _promenadeCad || _plazaPavingCad || _rainGardenCad || _steppedWallCad || _switchbackStairCad || _recyclingDropoffCad || _parkFenceCad || _skateTransitionCad || _boardwalkCad) && field.id == 'public_realm_use') && !(_bicycleRackCad && const {'transport_survey', 'sports_dimensions'}.contains(field.id)) && !((_railPlatformCad || _cycleCrossingCad || _refugeCrossingCad || _underpassCad || _parkingRampCad || _weighbridgeCad) && field.id == 'transport_survey') && !((_ductBankCad || _streetLightCad || _batteryYardCad || _guyedMastCad || _transformerBundCad || _bladeLaydownCad || _coolingLoopCad) && const {'utility_capacity', 'equipment_envelope'}.contains(field.id)) && !((_playgroundCad || _publicToiletCad) && const {'public_realm_use', 'sports_dimensions'}.contains(field.id))) || ((_warehouseCad || _crossDockCad) && field.id == 'dock_count') || (_officeCad && field.id == 'workstations') || (_diningCad && field.id=='seats') || (_cattleCad && field.id=='animal_capacity') || (_badmintonCad && field.id=='activity_areas') ||
          (_badmintonViewing && field.id=='spectators') ||
          (_hostelCad && const {'room_count', 'beds_per_room'}.contains(field.id)) ||
          (_inpatientWardCad && field.id == 'beds') || (_vehicleLiftCad && const {'service_bays', 'clear_height'}.contains(field.id))) asRequired(field),
    if (_home) ...[
      for (final field in _facilitySchema)
        if (const {'bedrooms', 'common_toilets', 'attached_toilets', 'kitchen_type'}.contains(field.id)) field,
    ],
  ];
  String get _plotUnit => _answers['plot_unit'] == 'm' ? 'm' : 'ft';
  double? _measuredFeet(TextEditingController controller) {
    final n = positiveNumber(controller.text);
    if (n == null) return null;
    final feet = _plotUnit == 'm' ? n / .3048 : n;
    return feet.isFinite ? feet : null;
  }
  void _changePlotUnit(String? choice) {
    final next = choice ?? 'ft';
    if (next == _plotUnit) return;
    final width = _measuredFeet(_width), depth = _measuredFeet(_depth);
    setState(() {
      _answers['plot_unit'] = next;
      if (width != null) _width.text = _dimensionInSelectedUnit(width);
      if (depth != null) _depth.text = _dimensionInSelectedUnit(depth);
      _sectionError = null;
    });
  }
  String _dimensionInSelectedUnit(double feet) => _plotUnit == 'm'
      ? (feet * .3048).toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '') : feet.toString();
  bool get _enclosedCad => !_linearSite && _answers['cad_output'] == 'building';
  bool get _warehouseEligible => _category?.id == 'industrial' && _group?.id == 'logistics' && warehouseLoadingTypes.contains(_type?.id);
  bool get _crossDockEligible => _category?.id == 'industrial' && _group?.id == 'logistics' && crossDockTypes.contains(_type?.id);
  bool get _crossDockCad => _crossDockEligible && _answers['cad_output'] == 'warehouse_cross_dock';
  bool get _pairedApartmentEligible => pairedApartmentEligible(_category?.id,_group?.id,_type?.id);
  bool get _pairedApartmentCad => _pairedApartmentEligible && _answers['cad_output']=='paired_apartments';
  bool get _rainGardenEligible => rainGardenCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _rainGardenCad => _rainGardenEligible && _answers['cad_output'] == rainGardenMode;
  bool get _dockLevellerEligible => dockLevellerCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _aquaculturePondEligible => aquaculturePondCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _silageBunkerEligible => silageBunkerCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _dockLevellerCad => _dockLevellerEligible && _answers['cad_output'] == dockLevellerMode;
  bool get _aquaculturePondCad => _aquaculturePondEligible && _answers['cad_output'] == aquaculturePondMode;
  bool get _silageBunkerCad => _silageBunkerEligible && _answers['cad_output'] == silageBunkerMode;
  bool get _boulderingBayEligible => boulderingBayCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _boulderingBayCad => _boulderingBayEligible && _answers['cad_output'] == boulderingBayMode;
  bool get _weighbridgeEligible => weighbridgeCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _weighbridgeCad => _weighbridgeEligible && _answers['cad_output'] == weighbridgeMode;
  bool get _coolingLoopEligible => coolingLoopCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _coolingLoopCad => _coolingLoopEligible && _answers['cad_output'] == coolingLoopMode;
  bool get _boardwalkEligible => boardwalkCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _boardwalkCad => _boardwalkEligible && _answers['cad_output'] == boardwalkMode;
  bool get _circularClarifierEligible => circularClarifierCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _circularClarifierCad => _circularClarifierEligible && _answers['cad_output'] == circularClarifierMode;
  bool get _bladeLaydownEligible => bladeLaydownCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _bladeLaydownCad => _bladeLaydownEligible && _answers['cad_output'] == bladeLaydownMode;
  bool get _cricketNetsEligible => cricketNetsCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _cricketNetsCad => _cricketNetsEligible && _answers['cad_output'] == cricketNetsMode;
  bool get _skateTransitionEligible => skateTransitionCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _skateTransitionCad => _skateTransitionEligible && _answers['cad_output'] == skateTransitionMode;
  bool get _parkFenceEligible => parkFenceCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _parkFenceCad => _parkFenceEligible && _answers['cad_output'] == parkFenceMode;
  bool get _transformerBundEligible => transformerBundCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _transformerBundCad => _transformerBundEligible && _answers['cad_output'] == transformerBundMode;
  bool get _footballPitchEligible => footballPitchCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _footballPitchCad => _footballPitchEligible && _answers['cad_output'] == footballPitchMode;
  bool get _guyedMastEligible => guyedMastCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _guyedMastCad => _guyedMastEligible && _answers['cad_output'] == guyedMastMode;
  bool get _recyclingDropoffEligible => recyclingDropoffCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _recyclingDropoffCad => _recyclingDropoffEligible && _answers['cad_output'] == recyclingDropoffMode;
  bool get _spillwayEligible => spillwayCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _spillwayCad => _spillwayEligible && _answers['cad_output'] == spillwayMode;
  bool get _batteryYardEligible => batteryYardCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _batteryYardCad => _batteryYardEligible && _answers['cad_output'] == batteryYardMode;
  bool get _parkingRampEligible => parkingRampCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _parkingRampCad => _parkingRampEligible && _answers['cad_output'] == parkingRampMode;
  bool get _cinemaSeatingEligible => cinemaSeatingCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _cinemaSeatingCad => _cinemaSeatingEligible && _answers['cad_output'] == cinemaSeatingMode;
  bool get _switchbackStairEligible => switchbackStairCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _switchbackStairCad => _switchbackStairEligible && _answers['cad_output'] == switchbackStairMode;
  bool get _jumpRunwayEligible => jumpRunwayCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _jumpRunwayCad => _jumpRunwayEligible && _answers['cad_output'] == jumpRunwayMode;
  bool get _plazaPavingEligible => plazaPavingCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _plazaPavingCad => _plazaPavingEligible && _answers['cad_output'] == plazaPavingMode;
  bool get _shelterCanopyEligible => shelterCanopyCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _shelterCanopyCad => _shelterCanopyEligible && _answers['cad_output'] == 'shelter_measured_canopy';
  bool get _publicToiletEligible => publicToiletCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _publicToiletCad => _publicToiletEligible && _answers['cad_output'] == 'public_toilet_measured_bank';
  bool get _vehicleLiftEligible => vehicleLiftCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _vehicleLiftCad => _vehicleLiftEligible && _answers['cad_output'] == 'workshop_measured_lifts';
  bool get _athleticsTrackEligible => athleticsTrackCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _athleticsTrackCad => _athleticsTrackEligible && _answers['cad_output'] == 'athletics_measured_track';
  bool get _playgroundEligible => playgroundCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _playgroundCad => _playgroundEligible && _answers['cad_output'] == 'playground_measured_zones';
  bool get _bicycleRackEligible => bicycleRackCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _bicycleRackCad => _bicycleRackEligible && _answers['cad_output'] == 'bicycle_measured_racks';
  bool get _memorialNicheEligible => memorialNicheCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _memorialNicheCad => _memorialNicheEligible && _answers['cad_output'] == 'memorial_niche_walls';
  bool get _tennisEligible => tennisCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _tennisCad => _tennisEligible && _answers['cad_output'] == 'tennis_measured_bank';
  bool get _twinTankEligible => twinTankCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _twinTankCad => _twinTankEligible && _answers['cad_output'] == 'tank_twin_cell';
  bool get _coldRackEligible => coldRackCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _coldRackCad => _coldRackEligible && _answers['cad_output'] == 'cold_storage_racks';
  bool get _angledParkingEligible => angledParkingCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _angledParkingCad => _angledParkingEligible && _answers['cad_output'] == 'angled_surface_parking';
  bool get _galleryPanelEligible => galleryPanelCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _galleryPanelCad => _galleryPanelEligible && _answers['cad_output'] == 'gallery_panel_layout';
  bool get _windrowYardEligible => windrowYardCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _windrowYardCad => _windrowYardEligible && _answers['cad_output'] == 'windrow_measured_yard';
  bool get _parkLoopEligible => parkLoopCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _parkLoopCad => _parkLoopEligible && _answers['cad_output'] == 'park_measured_loop';
  bool get _amphitheatreEligible => amphitheatreCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _amphitheatreCad => _amphitheatreEligible && _answers['cad_output'] == 'outdoor_tiered_amphitheatre';
  bool get _raisedBedEligible => raisedBedCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _raisedBedCad => _raisedBedEligible && _answers['cad_output'] == 'garden_raised_beds';
  bool get _publicMarketEligible => publicMarketCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _publicMarketCad => _publicMarketEligible && _answers['cad_output'] == 'public_market_stalls';
  bool get _lapPoolEligible => lapPoolCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _lapPoolCad => _lapPoolEligible && _answers['cad_output'] == 'lap_pool_measured';
  bool get _rainwaterEligible => rainwaterCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _rainwaterCad => _rainwaterEligible && _answers['cad_output'] == 'rainwater_roof_tanks';
  bool get _basketballEligible => basketballCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _basketballCad => _basketballEligible && _answers['cad_output'] == 'basketball_measured_court';
  bool get _hotelWingEligible => hotelWingEligible(_category?.id, _group?.id, _type?.id);
  bool get _hotelWingCad => _hotelWingEligible && _answers['cad_output'] == 'hotel_guestroom_wing';
  bool get _teachingLabEligible => teachingLabEligible(_category?.id, _group?.id, _type?.id);
  bool get _teachingLabCad => _teachingLabEligible && _answers['cad_output'] == 'school_teaching_lab';
  bool get _switchbackRampEligible => switchbackRampEligible(_category?.id, _group?.id, _type?.id);
  bool get _switchbackRampCad => _switchbackRampEligible && _answers['cad_output'] == 'measured_switchback';
  bool get _orchardEligible => orchardCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _orchardCad => _orchardEligible && _answers['cad_output'] == 'orchard_measured_rows';
  bool get _evHubEligible => evHubEligible(_category?.id, _group?.id, _type?.id);
  bool get _evHubCad => _evHubEligible && _answers['cad_output'] == 'ev_measured_hub';
  bool get _basinEligible => detentionBasinEligible(_category?.id, _group?.id, _type?.id);
  bool get _basinCad => _basinEligible && _answers['cad_output'] == 'basin_stage_storage';
  bool get _solarEligible => solarFarmEligible(_category?.id, _group?.id, _type?.id);
  bool get _solarCad => _solarEligible && _answers['cad_output'] == 'solar_fixed_tilt';
  bool get _truckSweepCad => _warehouseEligible && _answers['cad_output']=='truck_reverse_sweep';
  bool get _warehouseCad => _warehouseEligible && _answers['cad_output'] == 'warehouse_loading';
  bool get _clinicEligible => _category?.id == 'institutional' && _group?.id == 'healthcare' && separatedClinicTypes.contains(_type?.id);
  bool get _clinicCad => _clinicEligible && _answers['cad_output'] == 'clinic_separated';
  bool get _retailEligible => _category?.id == 'commercial' && _group?.id == 'retail' && retailFixtureTypes.contains(_type?.id);
  bool get _retailCad => _retailEligible && _answers['cad_output'] == 'retail_fixtures';
  bool get _g1Eligible => _category?.id == 'residential' && _group?.id == 'houses' && dwellingG1Types.contains(_type?.id);
  bool get _g1Cad => _g1Eligible && _answers['cad_output'] == 'dwelling_g1';
  bool get _inpatientWardEligible => inpatientWardEligible(_category?.id, _group?.id, _type?.id);
  bool get _inpatientWardCad => _inpatientWardEligible && _answers['cad_output']=='inpatient_ward';
  bool get _sharedCoreEligible => sharedCoreCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _sharedCoreCad => _sharedCoreEligible && _answers['cad_output']=='shared_core_shop_office';
  bool get _greenhouseEligible => greenhouseCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _greenhouseCad => _greenhouseEligible && _answers['cad_output']=='greenhouse_benches';
  bool get _hostelEligible => hostelCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _hostelCad => _hostelEligible && _answers['cad_output']=='hostel_shared_rooms';
  bool get _badmintonEligible => _category?.id=='institutional' && _group?.id=='sports' && badmintonCadTypes.contains(_type?.id);
  bool get _badmintonCad => _badmintonEligible && _answers['cad_output']=='badminton_hall';
  bool get _badmintonViewing => _badmintonCad && activeSpaceQuantities(_spaces,_spaceDetails).containsKey('spectator_seating');
  bool get _libraryEligible => libraryCadEligible(_category?.id,_group?.id,_type?.id);
  bool get _libraryCad => _libraryEligible && _answers['cad_output']=='library_reading';
  bool get _assemblyEligible => _category?.id=='industrial' && _group?.id=='manufacturing' && assemblyCadTypes.contains(_type?.id);
  bool get _assemblyCad => _assemblyEligible && _answers['cad_output']=='assembly_workflow';
  bool get _cattleEligible => _category?.id=='rural' && _group?.id=='farm' && cattleShedTypes.contains(_type?.id);
  bool get _cattleCad => _cattleEligible && _answers['cad_output']=='cattle_shed';
  bool get _diningEligible => _category?.id=='commercial' && _group?.id=='food_service' && diningCadTypes.contains(_type?.id);
  bool get _diningCad => _diningEligible && _answers['cad_output']=='dining_service';
  bool get _officeEligible => _category?.id == 'commercial' && _group?.id == 'office' && officeCadTypes.contains(_type?.id);
  bool get _officeCad => _officeEligible && _answers['cad_output'] == 'office_workplace';
  bool get _schoolEligible => _category?.id == 'institutional' && _group?.id == 'education' && schoolCadTypes.contains(_type?.id);
  bool get _schoolCad => _schoolEligible && _answers['cad_output'] == 'school_arrival';
  bool get _schoolPlayground => _schoolCad && _spaces.containsKey('playground') && !isExcludedSpace(_spaceDetails['playground'] ?? const {});
  bool get _packhouseEligible => _category?.id == 'rural' && _group?.id == 'agro_processing' && packhouseCadTypes.contains(_type?.id);
  bool get _packhouseCad => _packhouseEligible && _answers['cad_output'] == 'packhouse_flow';
  bool get _cycleCrossingEligible => cycleCrossingCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _cycleCrossingCad => _cycleCrossingEligible && _answers['corridor_cad_mode'] == cycleCrossingMode;
  bool get _refugeCrossingEligible => refugeCrossingCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _refugeCrossingCad => _refugeCrossingEligible && _answers['corridor_cad_mode'] == refugeCrossingMode;
  RequirementField get _corridorModeField => _cycleCrossingEligible || _refugeCrossingEligible
      ? surveyCorridorModeField(includeCycleCrossings: _cycleCrossingEligible, includeRefugeCrossing: _refugeCrossingEligible)
      : surveyCorridorMode;
  bool get _promenadeEligible => promenadeCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _promenadeCad => _promenadeEligible && _answers['promenade_mode'] == 'survey_promenade';
  bool get _underpassEligible => underpassCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _underpassCad => _underpassEligible && _answers['underpass_mode'] == underpassMode;
  bool get _steppedWallEligible => steppedWallCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _steppedWallCad => _steppedWallEligible && _answers['stepped_wall_mode'] == steppedWallMode;
  bool get _streetLightEligible => streetLightCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _streetLightCad => _streetLightEligible && _answers['street_light_mode'] == streetLightMode;
  bool get _ductBankEligible => ductBankCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _ductBankCad => _ductBankEligible && _answers['duct_bank_mode'] == ductBankModeId;
  bool get _railPlatformEligible => railPlatformCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _railPlatformCad => _railPlatformEligible && _answers['rail_platform_mode'] == 'survey_side_platform';
  bool get _footbridgeEligible => footbridgeCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _footbridgeCad => _footbridgeEligible && _answers['footbridge_mode'] == 'survey_footbridge';
  bool get _culvertEligible => culvertCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _culvertCad => _culvertEligible && _answers['culvert_cad_mode'] == 'survey_crossing';
  bool get _stormwaterEligible => _category?.id == 'infrastructure' && _group?.id == 'water' && stormwaterCadTypes.contains(_type?.id);
  bool get _stormwaterCad => _stormwaterEligible && _answers['drain_cad_mode'] == 'survey_gravity';
  bool get _openDrainCad => _stormwaterEligible && _answers['drain_cad_mode'] == 'survey_open_drain';
  bool get _busLaybyEligible => busLaybyCadEligible(_category?.id, _group?.id, _type?.id);
  bool get _busLaybyCad => _busLaybyEligible && _answers['bus_layby_mode'] == 'survey_layby';
  bool get _surveySheetOnly => _junctionCad || _longProfileCad || _corridorSectionCad || _earthworkCad || _stormwaterCad || _openDrainCad || _culvertCad || _busLaybyCad || _footbridgeCad || _railPlatformCad || _promenadeCad || _cycleCrossingCad || _ductBankCad || _refugeCrossingCad || _streetLightCad || _steppedWallCad || _underpassCad;
  bool get _junctionEligible => _category?.id == 'infrastructure' && _group?.id == 'transport' && _type?.id == 'intersection';
  bool get _junctionCad => _junctionEligible && const {'survey_t', 'survey_cross'}.contains(_answers['junction_cad_mode']);
  bool get _crossJunctionCad => _junctionCad && _answers['junction_cad_mode'] == 'survey_cross';
  bool get _surveyCorridorEligible => _category?.id == 'infrastructure' && _group?.id == 'transport' && surveyCorridorTypes.contains(_type?.id);
  bool get _surveyCorridorCad => _surveyCorridorEligible && surveyCorridorCadModes.contains(_answers['corridor_cad_mode']);
  bool get _longProfileCad => _surveyCorridorEligible && _answers['corridor_cad_mode']=='survey_profile';
  bool get _corridorSectionCad => _surveyCorridorEligible && _answers['corridor_cad_mode'] == 'survey_section';
  bool get _earthworkCad => _surveyCorridorEligible && _answers['corridor_cad_mode'] == 'survey_earthwork';
  bool get _circularCorridor => _surveyCorridorCad && _answers['corridor_cad_mode']=='survey_circular';
  bool get _mixedEligible => _category?.id=='mixed_use' && _group?.id=='mixed_development' && _type?.id==mixedRetailCadType;
  bool get _mixedCad => _mixedEligible && _answers['cad_output']=='mixed_shop_home';
  bool get _stackedCad => _mixedEligible && _answers['cad_output']=='mixed_shop_below_home';
  bool get _mixedHomeCad => _mixedCad || _stackedCad;
  List<RequirementField> get _cadFields => [
    if (_surveyCorridorEligible) _corridorModeField,
    if (_junctionEligible) tJunctionCadMode,
    if (_stormwaterEligible) stormwaterCadMode,
    if (_culvertEligible) culvertCadMode,
    if (_promenadeEligible) promenadeCadMode,
    if (_underpassEligible) underpassCadMode,
    if (_steppedWallEligible) steppedWallCadMode,
    if (_streetLightEligible) streetLightCadMode,
    if (_ductBankEligible) ductBankCadMode,
    if (_railPlatformEligible) railPlatformCadMode,
    if (_footbridgeEligible) footbridgeCadMode,
    if (_busLaybyEligible) busLaybyCadMode,
    if (!_linearSite) cadOutputOptions(warehouseLoading: _warehouseEligible, clinicSeparated: _clinicEligible, retailFixtures: _retailEligible, dwellingG1: _g1Eligible, schoolArrival: _schoolEligible, packhouseFlow: _packhouseEligible, mixedShopHome: _mixedEligible, crossDock: _crossDockEligible, officeWorkplace: _officeEligible, diningService:_diningEligible,cattleShed:_cattleEligible,assembly:_assemblyEligible,libraryReading:_libraryEligible,badminton:_badmintonEligible,hostel:_hostelEligible,greenhouse:_greenhouseEligible,sharedCore:_sharedCoreEligible,inpatientWard:_inpatientWardEligible,truckSweep:_warehouseEligible,pairedApartments:_pairedApartmentEligible, solarFarm:_solarEligible, detentionBasin:_basinEligible, evHub:_evHubEligible, orchard:_orchardEligible, switchbackRamp:_switchbackRampEligible, teachingLab:_teachingLabEligible, hotelWing:_hotelWingEligible, basketball:_basketballEligible, rainwater:_rainwaterEligible, lapPool:_lapPoolEligible, publicMarket:_publicMarketEligible, raisedBeds:_raisedBedEligible, amphitheatre:_amphitheatreEligible, parkLoop:_parkLoopEligible, windrowYard:_windrowYardEligible, galleryPanels:_galleryPanelEligible, angledParking:_angledParkingEligible, coldRacks:_coldRackEligible, twinTank:_twinTankEligible, tennis:_tennisEligible, memorialNiche:_memorialNicheEligible, bicycleRack:_bicycleRackEligible, playground:_playgroundEligible, athleticsTrack:_athleticsTrackEligible, vehicleLift:_vehicleLiftEligible, publicToilet:_publicToiletEligible, shelterCanopy:_shelterCanopyEligible, plazaPaving:_plazaPavingEligible, rainGarden:_rainGardenEligible, jumpRunway:_jumpRunwayEligible, switchbackStair:_switchbackStairEligible, cinemaSeating:_cinemaSeatingEligible, parkingRamp:_parkingRampEligible, batteryYard:_batteryYardEligible, spillway:_spillwayEligible, recyclingDropoff:_recyclingDropoffEligible, guyedMast:_guyedMastEligible, footballPitch:_footballPitchEligible, transformerBund:_transformerBundEligible, parkFence:_parkFenceEligible, skateTransition:_skateTransitionEligible, cricketNets:_cricketNetsEligible, bladeLaydown:_bladeLaydownEligible, circularClarifier:_circularClarifierEligible, boardwalk:_boardwalkEligible, coolingLoop:_coolingLoopEligible, weighbridge:_weighbridgeEligible, boulderingBay:_boulderingBayEligible, silageBunker:_silageBunkerEligible, aquaculturePond:_aquaculturePondEligible, dockLeveller:_dockLevellerEligible),
    if (_g1Cad) ...[...enclosedCadFields, ...straightDwellingStairFields],
    if (_g1Cad && _wantsParking) ...[
      ...dwellingParkingCommonFields,
      if (_parking != ProjectParking.twoWheeler) ...dwellingCarBayFields,
      if (_parking != ProjectParking.car) ...dwellingTwoWheelerBayFields,
    ],
    if (_clinicCad) ...clinicCadFields,
    if (_mixedHomeCad) ...retailCadFields.where((f)=>f.id!='rt_rear_access'),
    if (_mixedCad) ...mixedRetailCadFields,
    if (_stackedCad) ...[...stackedRetailCadFields,...straightDwellingStairFields],
    if (_schoolCad) ...schoolCadFields,
    if (_officeCad) ...officeCadFields,
    if (_diningCad) ...[...enclosedCadFields,...diningCadFields],
    if (_assemblyCad) ...[...enclosedCadFields,...assemblyCadFields],
    if (_libraryCad) ...libraryCadFields,
    if (_inpatientWardCad) ...[...enclosedCadFields.where((field) => field.id != 'cad_corridor'), ...inpatientWardFields],
    if (_sharedCoreCad) ...[...enclosedCadFields.where((field) => field.id != 'cad_corridor'),
      ...straightDwellingStairFields, ...sharedCoreCadFields],
    if (_greenhouseCad) ...[...enclosedCadFields.where((field) => field.id != 'cad_corridor'), ...greenhouseCadFields],
    if (_hostelCad) ...[...enclosedCadFields, ...hostelCadFields],
    if (_badmintonCad) ...[...enclosedCadFields.where((field)=>field.id!='cad_corridor'),...badmintonCadFields],
    if (_cattleCad) ...[...enclosedCadFields.take(5),...cattleShedFields,
      if (_type?.id=='cattle_farm') cattleShedHerdField],
    if (_packhouseCad) ...[...enclosedCadFields.take(5), ...packhouseCadFields],
    if (_retailCad) ...[...enclosedCadFields.take(5), ...retailCadFields],
    if (_warehouseCad) ...warehouseLoadingFields,
    if (_truckSweepCad) ...truckSweepFields,
    if (_solarCad) ...solarFarmFields,
    if (_evHubCad) ...evHubFields,
    if (_orchardCad) ...orchardCadFields,
    if (_switchbackRampCad) ...switchbackRampFields,
    if (_basketballCad) ...basketballCadFields,
    if (_rainwaterCad) ...rainwaterCadFields,
    if (_lapPoolCad) ...lapPoolCadFields,
    if (_publicMarketCad) ...publicMarketCadFields,
    if (_raisedBedCad) ...raisedBedCadFields,
    if (_amphitheatreCad) ...amphitheatreCadFields,
    if (_parkLoopCad) ...parkLoopCadFields,
    if (_windrowYardCad) ...windrowYardCadFields,
    if (_galleryPanelCad) ...galleryPanelCadFields,
    if (_angledParkingCad) ...angledParkingCadFields,
    if (_coldRackCad) ...coldRackCadFields,
    if (_rainGardenCad) ...rainGardenCadFields,
    if (_dockLevellerCad) ...dockLevellerCadFields,
    if (_aquaculturePondCad) ...aquaculturePondCadFields,
    if (_silageBunkerCad) ...silageBunkerCadFields,
    if (_boulderingBayCad) ...boulderingBayCadFields,
    if (_weighbridgeCad) ...weighbridgeCadFields,
    if (_coolingLoopCad) ...coolingLoopCadFields,
    if (_boardwalkCad) ...boardwalkCadFields,
    if (_circularClarifierCad) ...circularClarifierCadFields,
    if (_bladeLaydownCad) ...bladeLaydownCadFields,
    if (_cricketNetsCad) ...cricketNetsCadFields,
    if (_skateTransitionCad) ...skateTransitionCadFields,
    if (_parkFenceCad) ...parkFenceCadFields,
    if (_transformerBundCad) ...transformerBundCadFields,
    if (_footballPitchCad) ...footballPitchCadFields,
    if (_guyedMastCad) ...guyedMastCadFields,
    if (_recyclingDropoffCad) ...recyclingDropoffCadFields,
    if (_spillwayCad) ...spillwayCadFields,
    if (_batteryYardCad) ...batteryYardCadFields,
    if (_parkingRampCad) ...parkingRampCadFields,
    if (_cinemaSeatingCad) ...cinemaSeatingCadFields,
    if (_switchbackStairCad) ...switchbackStairCadFields,
    if (_jumpRunwayCad) ...jumpRunwayCadFields,
    if (_plazaPavingCad) ...plazaPavingCadFields,
    if (_shelterCanopyCad) ...shelterCanopyCadFields,
    if (_publicToiletCad) ...publicToiletCadFields,
    if (_vehicleLiftCad) ...vehicleLiftCadFields,
    if (_athleticsTrackCad) ...athleticsTrackCadFields,
    if (_playgroundCad) ...playgroundCadFields,
    if (_bicycleRackCad) ...bicycleRackCadFields,
    if (_memorialNicheCad) ...memorialNicheCadFields,
    if (_tennisCad) ...tennisCadFields,
    if (_twinTankCad) ...twinTankCadFields,
    if (_hotelWingCad) ...[...enclosedCadFields.where((field) => !const {'cad_plate_depth','cad_corridor'}.contains(field.id)), ...hotelWingFields],
    if (_teachingLabCad) ...[...enclosedCadFields.where((field) => field.id != 'cad_corridor'), ...teachingLabFields],
    if (_pairedApartmentCad) ...[...enclosedCadFields.where((field)=>field.id!='cad_corridor'),...pairedApartmentFields],
    if (_crossDockCad) ...crossDockFields,
    if (_enclosedCad || _clinicCad || _officeCad || _schoolCad || _libraryCad || _mixedHomeCad) ...[...enclosedCadFields, cadWidthMode],
  ];
  List<RequirementField> get _frontPlanning => [
    if (_isRectangular) planningChoice('plot_unit', 'Plot measurement unit', {'ft': 'Feet', 'm': 'Metres'}, required: false),
    if (_customInfrastructure) customSiteKindField,
    if (_type?.id == 'custom') customTypeField,
    if (_configurationId == 'custom') customConfigurationField,
    if (_linearSite && !_surveySheetOnly)
      ...alignmentFields.take(3).map((field) => field.id == 'alignment_reference' && !_surveyCorridorCad ? field : asRequired(field))
    else if (!_linearSite && _shapeId != null && !_isRectangular)
      asRequired(surveyedPlotFields.first),
    if (!_linearSite) planningChoice('vastu', 'Vastu preference', {
      'none': 'No Vastu preference', 'review': 'Consider Vastu', 'user': 'Use my Vastu preferences', 'undecided': 'Not decided',
    }, required: false),
    if (!_linearSite) planningChoice('terrace_needed', 'Accessible terrace?', {'yes': 'Yes', 'no': 'No'}, required: false),
    if (_home) ...residentialPlanningFields(_vastu),
    if (!_linearSite) ...accessPlanningFields(_floorCount, _terrace, _wantsParking).where((field)=>
      !(_stackedCad || _sharedCoreCad) || !const {'stair_access','stair_form','upper_use','lift_plan'}.contains(field.id)),
    if (_terrace && _answers['terrace_use'] is Iterable)
      for (final zone in (_answers['terrace_use'] as Iterable).whereType<String>())
        if (const {'open', 'covered', 'enclosed', 'garden'}.contains(zone))
          planningArea('terrace_area_$zone', 'Area for $zone terrace zone'),
    if (_g1Cad && _terrace) ...dwellingRoofFields,
  ];
  List<RequirementField> _levelFields(int level) => [
    if (level > 0 && !_g1Cad && !_stackedCad && !_sharedCoreCad) ...[
      planningArea('level_area_$level', 'Available floor area'),
      RequirementField('zoning_width_$level', 'Zoning envelope width', kind: RequirementKind.decimal, min: .01, unit: 'm'),
      RequirementField('zoning_depth_$level', 'Zoning envelope depth', kind: RequirementKind.decimal, min: .01, unit: 'm'),
    ],
    if (_floorCount > 1 && !_g1Cad && !_stackedCad && !_sharedCoreCad) planningArea('level_access_$level', 'Stair, landing and lift allowance'),
    if (_home && _floorCount > 1) ...[
      RequirementField('level_bedrooms_$level', 'Bedrooms on this floor', kind: RequirementKind.integer, min: 0, required: true),
      RequirementField('level_baths_$level', 'Bathrooms on this floor', kind: RequirementKind.integer, min: 0, required: true),
    ],
  ];
  List<RequirementField> get _floorPlanning => _linearSite ? [] : [
    if (_home && _floorCount > 1)
      planningChoice('main_kitchen_floor', 'Main kitchen and living-room floor', {
        for (final n in _levels) '$n': _levelName(n),
      }),
    for (final n in _levels) ..._levelFields(n),
  ];
  Set<String> get _earlyIds => {..._frontPlanning.map((f) => f.id), 'surveyed_plot_area', 'route_length', 'right_of_way', 'alignment_reference', 'vastu', 'vastu_notes'};
  bool _earlyOptionalSize(String id) => _home && const {
    'master_bedroom','secondary_bedroom','childrens_bedroom','guest_bedroom','elderly_accessible_bedroom',
    'family_living_room','open_kitchen','closed_kitchen','shared_bathroom','attached_bathroom',
    'staircase','lift','terrace','prayer_puja_room',
  }.contains(id);
  bool _coveredByCore(String id) => _earlyOptionalSize(id) ||
      const {'staircase','lift','terrace'}.contains(id) && (_floorCount > 1 || _terrace);
  int? _spaceLevel(Map<String, Object> data) {
    final level = '${data['floor_level'] ?? ''}'.trim().toLowerCase();
    if (const {'', 'ground', 'ground floor', 'g'}.contains(level)) return 0;
    return int.tryParse(level.replaceFirst(RegExp(r'^floor\s+'), ''));
  }
  PlanningSize? _sizeFor(String id) => _home ? homeRoomSizes[id] : null;
  ({double? minimum, double? typical, double? width, double? depth}) _roomAllocation(String id) {
    final room = _spaceDetails[id] ?? const <String, Object>{};
    final fallback = _sizeFor(id);
    final width = positiveNumber(room['width']);
    final length = positiveNumber(room['length']);
    final unit = room['area_unit'];
    final conversion = unit == 'sqm' ? sqftPerSqm : 1.0;
    final min = unit == null ? null : positiveNumber(room['area_min']);
    final target = unit == null ? null : positiveNumber(room['area_target']);
    final fromSides = width == null || length == null ? null : width * length * sqftPerSqm;
    final supplied = [if (min != null) min * conversion, if (fromSides != null) fromSides];
    final least = supplied.isNotEmpty ? supplied.reduce((a,b) => a > b ? a : b) :
      (target == null ? fallback?.minimum : target * conversion);
    return (minimum: least, typical: target == null ? (fallback?.typical ?? least) : target * conversion,
      width: width == null ? fallback?.width : width / .3048,
      depth: length == null ? fallback?.depth : length / .3048);
  }
  AreaBudget _budget(int level) {
    final width = _isRectangular ? _measuredFeet(_width) : null;
    final depth = _shapeId == 'square' ? width : (_isRectangular ? _measuredFeet(_depth) : null);
    if (_g1Cad || _stackedCad) {
      final plateW = positiveNumber(_answers['cad_plate_width']), plateD = positiveNumber(_answers['cad_plate_depth']);
      final stairW = positiveNumber(_answers['g1_width']) ?? 0.0;
      final risers = positiveNumber(_answers['g1_risers']) ?? 1.0;
      final run = (risers - 1) * (positiveNumber(_answers['g1_going']) ?? 0.0) + 2 * (positiveNumber(_answers['g1_landing']) ?? 0.0);
      var areaM2 = stairW * run;
      if (_terrace) {
        final roofWidth=positiveNumber(_answers['g1_roof_stair_width'])??0.0;
        final steps=(positiveNumber(_answers['g1_roof_risers'])??1.0)-1;
        areaM2+=roofWidth*(steps*(positiveNumber(_answers['g1_roof_going'])??0.0)+2*(positiveNumber(_answers['g1_roof_landing'])??0.0));
      }
      var unknown = false;
      for (final entry in activeSpaceQuantities(_spaces, _spaceDetails).entries) {
        final detail = _spaceDetails[entry.key] ?? const <String,Object>{};
        if (_spaceLevel(detail) != level) continue;
        final w = positiveNumber(detail['width']), d = positiveNumber(detail['length']);
        if (w == null || d == null) { unknown = true; continue; }
        areaM2 += w * d * entry.value;
      }
      final plate = (plateW ?? 0.0) * (plateD ?? 0.0) * sqftPerSqm;
      return AreaBudget(width: plateW == null ? null : plateW / .3048,
        depth: plateD == null ? null : plateD / .3048,
        total: level == 0 ? ((width ?? 0) * (depth ?? 0)) : plate, available: plate,
        minimum: areaM2 * sqftPerSqm, typical: areaM2 * sqftPerSqm, unknown: unknown);
    }
    final area = positiveNumber(_answers['surveyed_plot_area']);
    final intNumber = (String key) => int.tryParse('${_answers[key] ?? ''}') ?? 0;
    final home = !_home ? (minimum: 0.0, typical: 0.0) : _floorCount > 1
      ? homeLevelAllowance(intNumber('level_bedrooms_$level'), intNumber('level_baths_$level'), _answers['main_kitchen_floor'] == '$level')
      : dwellingAllowance(_bedrooms < 0 ? 0 : _bedrooms, _baths);
    final allowance = (_floorCount > 1 ? positiveNumber(_answers['level_access_$level']) ?? 0.0 : 0.0) + (level == 0 ?
      ((_terrace && _floorCount == 1 ? positiveNumber(_answers['ground_access_area']) ?? 0.0 : 0) +
       (_wantsParking ? positiveNumber(_answers['parking_sqft']) ?? 0.0 : 0)) : 0);
    final puja = _home && level == 0 && _answers['puja_needed'] == 'yes' ? pujaSizes[_answers['puja_form']] : null;
    var minimum = home.minimum + allowance + (puja?.minimum ?? 0.0);
    var typical = home.typical + allowance + (puja?.typical ?? 0.0);
    var unknown = false;
    for (final entry in activeSpaceQuantities(_spaces, _spaceDetails).entries) {
      if (_coveredByCore(entry.key) || _spaceLevel(_spaceDetails[entry.key] ?? const {}) != level) continue;
      final allocation = _roomAllocation(entry.key);
      if (allocation.minimum == null) { unknown = true; continue; }
      minimum += allocation.minimum! * entry.value;
      final guess = allocation.typical ?? allocation.minimum!;
      typical += (guess < allocation.minimum! ? allocation.minimum! : guess) * entry.value;
    }
    return estimatePlanningArea(width: level == 0 ? width : null, depth: level == 0 ? depth : null,
      surveyedSqft: level > 0 ? positiveNumber(_answers['level_area_$level']) :
        (_isRectangular || area == null ? null : area * sqftPerSqm),
      rules: _answers, minimum: minimum, typical: typical, unknown: unknown);
  }
  AreaBudget get _roofBudget {
    final zones = _answers['terrace_use'];
    final used = zones is Iterable ? zones.whereType<String>().fold<double>(0,
      (sum, zone) => sum + (positiveNumber(_answers['terrace_area_$zone']) ?? 0)) : 0.0;
    return estimatePlanningArea(surveyedSqft: positiveNumber(_answers['terrace_sqft']), minimum: used, typical: used);
  }
  List<RequirementField> get _infoSchema => [
    ...projectInformationFields,
    if (_actionId != null && !const {'new_design', 'feasibility', 'concept_design', 'master_planning'}.contains(_actionId)) previousDesignField,
  ];
  List<RequirementField> get _siteSchema => [
    if (_playgroundCad) playgroundCadEquipment,
    ...siteCommonFields,
    if (_junctionCad) ...(_crossJunctionCad ? crossJunctionCadFields : tJunctionCadFields),
    if (_longProfileCad) ...longitudinalProfileFields,
    if (_corridorSectionCad) ...corridorSectionFields,
    if (_earthworkCad) ...corridorEarthworkFields,
    if (_stormwaterCad) ...stormwaterCadFields,
    if (_openDrainCad) ...openDrainCadFields,
    if (_busLaybyCad) ...busLaybyCadFields,
    if (_culvertCad) ...culvertCadFields,
    if (_refugeCrossingCad) ...refugeCrossingCadFields,
    if (_cycleCrossingCad) ...cycleCrossingCadFields,
    if (_promenadeCad) ...promenadeCadFields,
    if (_underpassCad) ...underpassCadFields,
    if (_steppedWallCad) ...steppedWallCadFields,
    if (_streetLightCad) ...streetLightCadFields,
    if (_ductBankCad) ...ductBankCadFields,
    if (_railPlatformCad) ...railPlatformCadFields,
    if (_footbridgeCad) ...footbridgeCadFields,
    if (_truckSweepCad) truckSweepObstacles,
    if (_solarCad) solarFarmObstacles,
    if (_basinCad) ...detentionBasinFields,
    if (_orchardCad) orchardExclusions,
    for (final field in (_surveySheetOnly ? const <RequirementField>[] : _linearSite ? alignmentFields : surveyedPlotFields))
      if (!_earlyIds.contains(field.id) && !(_surveyCorridorCad && const {'concept_straight_alignment','corridor_bands'}.contains(field.id))) field,
    if (_surveyCorridorCad) ...[...surveyCorridorFields,surveyCorridorBands],
    if (_circularCorridor) surveyCurveRadii,
    if (_schoolPlayground) ...schoolPlaygroundFields,
    if (_badmintonViewing) ...badmintonViewingFields,
  ];
  List<RequirementField> get _ruleSchema => _linearSite
      ? jurisdictionFields.take(5).toList() : jurisdictionFields;
  List<RequirementField> get _operationalSchema => [
    if (!_linearSite) ...buildingProgramFields,
    ...operationalFields,
    if (_wantsParking)
      ...parkingFields.where((field) => switch (field.id) {
        'cars' => _parking != ProjectParking.twoWheeler,
        'two_wheelers' => _parking != ProjectParking.car,
        _ => true,
      }).map((field) => _g1Cad && const {'cars','two_wheelers'}.contains(field.id) ? asRequired(field) : field),
  ];
  List<RequirementField> get _designSchema => _linearSite
      ? preferenceFields.where((f) => f.id == 'sustainability').toList()
      : preferenceFields.where((f) => !_earlyIds.contains(f.id)).toList();
  List<RequirementField> get _generalSchema => [
    ..._frontPlanning, ..._cadFields, ..._floorPlanning, ..._infoSchema, ..._siteSchema, ..._ruleSchema, ..._operationalSchema,
    ...technicalFields, ..._designSchema, ...deliveryFields,
  ];
  ProjectScenario? get _currentScenario => scenarioForRequirements(
    _category?.id, _group?.id, _type?.id, _configurationId,
    _facilitySchema.any((field) => field.id == 'bedrooms')
        ? int.tryParse('${_facilityAnswers['bedrooms'] ?? ''}') : null,
  );
  ProjectScenarioVariant? get _currentVariant {
    final scenario = _currentScenario;
    if (scenario == null) return null;
    return scenarioVariantFor(scenario, int.tryParse(_floors.text.trim()), _parking?.name);
  }
  bool get _canAutoPlan => _currentScenario?.generator != null;
  bool get _needsScenarioInputs => int.tryParse(_floors.text.trim()) == null || _parking == null;
  bool get _isReview => _step == _steps.length - 1;
  bool get _showsContinue => _step >= 3;
  String get _selectionPath => [
        if (_step > 0) _category!.label,
        if (_step > 1) _group!.label,
        if (_step > 2) _type!.label,
      ].join(' › ');

  @override
  void initState() {
    super.initState();
    final project = widget.existingProject;
    if (project == null) {
      final variant = widget.variant;
      final preset = variant?.scenario ?? widget.scenario;
      if (preset != null) {
        _category = preset.category;
        _group = preset.group;
        _type = preset.type;
        _configurationId = preset.configuration?.id;
        if (variant != null) {
          _floors.text = '${variant.floors}';
          _parking = ProjectParking.values.byName(variant.parkingId);
        }
        _step = 3;
      }
      return;
    }
    final brief = project.brief;
    final saved = brief?.taxonomy;
    _name.text = project.name;
    _width.text = project.width > 0 ? project.width.toString() : '';
    _depth.text = project.length > 0 ? project.length.toString() : '';
    _floors.text = brief?.floorCount?.toString() ?? '';
    _facing = _directions.contains(project.facing) ? project.facing : null;
    _parking = brief?.parking;
    if (saved != null) {
      _category = taxonomyCategory(saved.categoryId);
      _group = taxonomyGroup(_category, saved.subcategoryId);
      _type = taxonomyChoice(_group?.types ?? const [], saved.typeId);
      _unsupportedBrief = saved.version != projectTaxonomyVersion || _type == null;
      _configurationId = saved.configurationId;
      _actionId = saved.actionId;
      _stageId = saved.stageId;
      _shapeId = saved.plotShapeId;
      _spaces.addAll(saved.spaceQuantities.map((key, value) => MapEntry(key, '$value')));
      final requirements = brief?.requirements;
      if (requirements != null) {
        _unsupportedBrief = _unsupportedBrief || requirements.version != requirementsSchemaVersion;
        _answers.addAll(requirements.answers);
        if (_plotUnit == 'm') {
          if (project.width > 0) _width.text = _dimensionInSelectedUnit(project.width);
          if (project.length > 0) _depth.text = _dimensionInSelectedUnit(project.length);
        }
        _customSpaces.addAll(requirements.customSpaces);
        _spaceDetails.addAll(requirements.spaceDetails);
        for (final entry in _spaceDetails.entries) {
          if (isExcludedSpace(entry.value)) _spaces.putIfAbsent(entry.key, () => '1');
        }
        if (_type != null) {
          for (final field in _facilitySchema) {
            final value = _answers.remove(field.id);
            if (value != null) _facilityAnswers[field.id] = value;
          }
        }
      }
    } else if (brief != null && brief.type != null) {
      final path = switch (brief.type!) {
        ProjectType.singleRoom => ('residential', 'houses', 'single_room'),
        ProjectType.house => ('residential', 'houses', 'independent_house'),
        ProjectType.villa => ('residential', 'houses', 'villa'),
        ProjectType.farmhouse => ('residential', 'houses', 'farmhouse'),
        ProjectType.bungalow => ('residential', 'houses', 'bungalow'),
        ProjectType.apartments => ('residential', 'apartments', switch (project.bhk) {
          '1 BHK' => '1_bhk', '2 BHK' => '2_bhk', '3 BHK' => '3_bhk',
          '4 BHK' => '4_bhk', '5+ BHK' => '5_plus_bhk', _ => 'apartment_building',
        }),
        ProjectType.shop => ('commercial', 'retail', 'shop'),
        ProjectType.office => ('commercial', 'office', 'small_office'),
        ProjectType.warehouse => ('industrial', 'logistics', 'general_warehouse'),
        ProjectType.mixedUse => ('mixed_use', 'mixed_development', switch (project.bhk) {
          'Shops + homes' => 'residential_plus_retail',
          'Offices + homes' => 'residential_plus_office',
          'Shops + offices' => 'office_plus_retail', _ => 'mixed_use_development',
        }),
      };
      _category = taxonomyCategory(path.$1);
      _group = taxonomyGroup(_category, path.$2);
      _type = taxonomyChoice(_group?.types ?? const [], path.$3);
      // The previous wizard explicitly collected rectangular plot dimensions.
      _shapeId = 'rectangular';
      if (_type != null) {
        for (final choice in _program.configurations) {
          if (choice.label.toLowerCase() == project.bhk.toLowerCase()) {
            _configurationId = choice.id;
          }
        }
        for (final choice in _program.spaces) {
          if (brief.features.any((label) => label.toLowerCase() == choice.label.toLowerCase())) {
            _spaces[choice.id] = '1';
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _width.dispose();
    _depth.dispose();
    _floors.dispose();
    super.dispose();
  }

  void _categorySelected(TaxonomyCategory category) {
    setState(() {
      if (_category?.id != category.id) {
        _category = category;
        _group = null;
        _type = null;
        _clearProgram();
      }
      _step = 1;
    });
  }

  void _groupSelected(TaxonomyGroup group) {
    setState(() {
      if (_group?.id != group.id) {
        _group = group;
        _type = null;
        _clearProgram();
      }
      _typeQuery = '';
      _step = 2;
    });
  }

  void _typeSelected(TaxonomyChoice type) {
    if (widget.existingProject == null && _category?.id == 'special' && _group?.id == 'complex' &&
        type.id == 'high_rise_supertall_building') {
      Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const TowerPlannerScreen()));
      return;
    }
    setState(() {
      if (_type?.id != type.id) {
        _type = type;
        _clearProgram();
      }
      _step = 3;
    });
  }

  void _clearProgram() {
    _configurationId = null;
    _spaces.clear();
    _customSpaces.clear();
    _spaceDetails.clear();
    _facilityAnswers.clear();
    _answers.remove(customTypeField.id);
    _answers.remove(customSiteKindField.id);
    _answers.remove(customConfigurationField.id);
    for (final field in [cadOutputField, ...enclosedCadFields, cadWidthMode, ...warehouseLoadingFields, ...clinicCadFields, ...retailCadFields, ...straightDwellingStairFields, ...dwellingParkingCommonFields, ...dwellingCarBayFields, ...dwellingTwoWheelerBayFields, ...schoolCadFields, ...packhouseCadFields, surveyCorridorMode, ...surveyCorridorFields,surveyCurveRadii, ...mixedRetailCadFields,...stackedRetailCadFields,...crossDockFields,...schoolPlaygroundFields,...dwellingRoofFields,...officeCadFields,...diningCadFields,...cattleShedFields,cattleShedHerdField,...assemblyCadFields,...libraryCadFields,...badmintonCadFields,...badmintonViewingFields,...hostelCadFields,...greenhouseCadFields,tJunctionCadMode,...tJunctionCadFields,...crossJunctionCadFields,...sharedCoreCadFields,...inpatientWardFields,...longitudinalProfileFields,...corridorSectionFields,...corridorEarthworkFields,stormwaterCadMode,...stormwaterCadFields,...openDrainCadFields,busLaybyCadMode,...busLaybyCadFields,culvertCadMode,...culvertCadFields,footbridgeCadMode,...footbridgeCadFields,underpassCadMode,...underpassCadFields,steppedWallCadMode,...steppedWallCadFields,streetLightCadMode,...streetLightCadFields,ductBankCadMode,...ductBankCadFields,railPlatformCadMode,...railPlatformCadFields,...refugeCrossingCadFields,...cycleCrossingCadFields,promenadeCadMode,...promenadeCadFields,...truckSweepFields,truckSweepObstacles,...pairedApartmentFields,...solarFarmFields,solarFarmObstacles,...detentionBasinFields,...evHubFields,...orchardCadFields,orchardExclusions,...switchbackRampFields,...teachingLabFields,...hotelWingFields,...basketballCadFields,...rainwaterCadFields,...lapPoolCadFields,...publicMarketCadFields,...raisedBedCadFields,...amphitheatreCadFields,...parkLoopCadFields,...windrowYardCadFields,...galleryPanelCadFields,...angledParkingCadFields,...coldRackCadFields,...twinTankCadFields, ...tennisCadFields, ...memorialNicheCadFields, ...bicycleRackCadFields, ...playgroundCadFields, playgroundCadEquipment, ...athleticsTrackCadFields, ...vehicleLiftCadFields, ...publicToiletCadFields, ...shelterCanopyCadFields, ...silageBunkerCadFields, ...aquaculturePondCadFields, ...dockLevellerCadFields, ...boulderingBayCadFields, ...weighbridgeCadFields, ...coolingLoopCadFields, ...boardwalkCadFields, ...circularClarifierCadFields, ...bladeLaydownCadFields, ...cricketNetsCadFields, ...skateTransitionCadFields, ...parkFenceCadFields, ...transformerBundCadFields, ...footballPitchCadFields, ...guyedMastCadFields, ...recyclingDropoffCadFields, ...spillwayCadFields, ...batteryYardCadFields, ...parkingRampCadFields, ...cinemaSeatingCadFields, ...switchbackStairCadFields, ...jumpRunwayCadFields, ...plazaPavingCadFields, ...rainGardenCadFields]) { _answers.remove(field.id); }
    _sectionError = null;
  }

  void _back() {
    if (_saving) return;
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      FocusScope.of(context).unfocus();
      setState(() { _step--; _sectionError = null; });
    }
  }

  void _next() {
    final form = _step == 4 ? _spaceForm : _sectionForms[_step];
    if (form.currentState?.validate() == false) {
      setState(() => _sectionError = 'Correct the highlighted fields before continuing.');
      return;
    }
    final issue = switch (_step) {
      3 => _planningIssue(),
      4 => _spaceProgramIssue() ?? _planningIssue(checkRooms: true),
      7 => _planningIssue(checkRooms: true),
      6 => !_linearSite && _answers['survey_boundary']?.toString().trim().isNotEmpty == true && _answers['coordinate_unit'] == null
          ? 'Select the survey coordinate unit when entering a boundary.' : null,
      8 => _facilityIssue(),
      11 => _answers['budget']?.toString().trim().isNotEmpty == true && _answers['currency']?.toString().trim().isNotEmpty != true
          ? 'Enter the currency for the budget amount.' : null,
      _ => null,
    };
    if (issue != null) {
      setState(() => _sectionError = issue);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _step++; _sectionError = null; });
  }

  String? _planningIssue({bool checkRooms = false}) {
    if (_surveySheetOnly) return null; // Survey geometry is checked on Save.
    if (_linearSite) {
      if (positiveNumber(_answers['route_length']) == null || positiveNumber(_answers['right_of_way']) == null) {
        return 'Enter the measured route length and available right-of-way.';
      }
      return null;
    }
    if (_shapeId == null) return 'Select the geometry of your site.';
    if (_budget(0).total <= 0) return 'Enter the measured site size before continuing.';
    if (_vastu && (_facing == null || _facing == 'Not decided')) return 'Enter the measured frontage direction for Vastu suggestions.';
    if (_g1Cad && (_floorCount != 2 || !const {'South','North','East','West'}.contains(_facing))) {
      return 'Measured G+1 CAD needs two floors including ground and a cardinal frontage.';
    }
    if (_retailCad) {
      if (_floorCount != 1 || int.tryParse('${_facilityAnswers['shop_count'] ?? ''}') != 1) {
        return 'Retail fixture CAD requires one ground-floor shop. Enter 1 for both floor and shop count.';
      }
      if (!const {'South','North','East','West'}.contains(_facing)) return 'Choose the measured cardinal shop entrance side.';
      if (checkRooms && activeSpaceQuantities(_spaces, _spaceDetails).isNotEmpty) {
        return 'The fixture plan already draws sales, checkout and stock. Remove additional room selections or choose a different drawing type.';
      }
    }
    if (_crossDockCad) {
      if (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing)) return 'Cross-dock needs one ground floor and the cardinal inbound frontage.';
      final count=int.tryParse('${_facilityAnswers['dock_count'] ?? ''}');
      final inbound=int.tryParse('${_answers['xd_in_count'] ?? ''}');
      if (count==null || count<2 || count>30 || inbound==null || inbound>=count) return 'Enter 2–30 total docks, with at least one dock in each bank.';
      if (checkRooms && activeSpaceQuantities(_spaces,_spaceDetails).isNotEmpty) return 'Cross-dock CAD uses dock-bank, staging and lane measurements. Leave additional Space selections empty.';
    }
    if (_warehouseCad) {
      if (_floorCount != 1) return 'Warehouse loading CAD requires a single ground floor.';
      if (!const {'South','North','East','West'}.contains(_facing)) return 'Choose the cardinal vehicle frontage.';
      final dockCount = int.tryParse('${_facilityAnswers['dock_count'] ?? ''}');
      if (dockCount == null || dockCount < 1 || dockCount > 30) return 'Enter a dock count between 1 and 30.';
      if (checkRooms && activeSpaceQuantities(_spaces, _spaceDetails).isNotEmpty) {
        return 'Warehouse loading CAD already draws measured staging, storage and loading areas. Remove additional room selections or choose a different drawing type.';
      }
    }
    if (_sharedCoreCad && (_floorCount!=2 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Shared-core shop and office CAD needs two floors including ground and a cardinal entrance.';
    }
    if (_stackedCad && (_floorCount!=2 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Stacked shop and home CAD needs two floors including ground and a cardinal shop frontage.';
    }
    if (_mixedCad && (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'The shop and dwelling layout needs one ground floor and the cardinal shop frontage.';
    }
    if (_packhouseCad && (_floorCount != 1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'The packhouse flow needs one ground floor and a cardinal receiving frontage.';
    }
    if (_pairedApartmentCad && (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Paired apartment CAD needs one ground floor and a cardinal shared frontage.';
    }
    if (_rainGardenCad && !_isRectangular) return 'Rain garden CAD needs a cardinally aligned rectangular or square plot.';
    if (_dockLevellerCad && !_isRectangular) return 'Dock leveller CAD needs a cardinally aligned rectangular or square plot.';
    if (_aquaculturePondCad && !_isRectangular) return 'Aquaculture pond CAD needs a cardinally aligned rectangular or square plot.';
    if (_silageBunkerCad && !_isRectangular) return 'Silage bunker CAD needs a cardinally aligned rectangular or square plot.';
    if (_boulderingBayCad && !_isRectangular) return 'Bouldering bay CAD needs a cardinally aligned rectangular or square plot.';
    if (_weighbridgeCad && !_isRectangular) return 'Freight weighbridge CAD needs a cardinally aligned rectangular or square plot.';
    if (_coolingLoopCad && !_isRectangular) return 'Cooling pipe loop CAD needs a cardinally aligned rectangular or square plot.';
    if (_boardwalkCad && !_isRectangular) return 'Boardwalk CAD needs a cardinally aligned rectangular or square plot.';
    if (_circularClarifierCad && !_isRectangular) return 'Circular clarifier CAD needs a cardinally aligned rectangular or square plot.';
    if (_bladeLaydownCad && !_isRectangular) return 'Blade laydown CAD needs a cardinally aligned rectangular or square plot.';
    if (_cricketNetsCad && !_isRectangular) return 'Cricket nets CAD needs a cardinally aligned rectangular or square plot.';
    if (_skateTransitionCad && !_isRectangular) return 'Skate transition CAD needs a cardinally aligned rectangular or square plot.';
    if (_parkFenceCad && !_isRectangular) return 'Park fence CAD needs a cardinally aligned rectangular or square plot.';
    if (_transformerBundCad && !_isRectangular) return 'Transformer bund CAD needs a cardinally aligned rectangular or square plot.';
    if (_footballPitchCad && !_isRectangular) return 'Football pitch CAD needs a cardinally aligned rectangular or square plot.';
    if (_guyedMastCad && !_isRectangular) return 'Guyed mast CAD needs a cardinally aligned rectangular or square plot.';
    if (_recyclingDropoffCad && !_isRectangular) return 'Recycling drop-off CAD needs a cardinally aligned rectangular or square plot.';
    if (_spillwayCad && !_isRectangular) return 'Spillway CAD needs a cardinally aligned rectangular or square plot.';
    if (_batteryYardCad && !_isRectangular) return 'Battery yard CAD needs a cardinally aligned rectangular or square plot.';
    if (_parkingRampCad && !_isRectangular) return 'Parking ramp CAD needs a cardinally aligned rectangular or square plot.';
    if (_cinemaSeatingCad && !_isRectangular) return 'Cinema seating CAD needs a cardinally aligned rectangular or square plot.';
    if (_switchbackStairCad && !_isRectangular) return 'Switchback stair CAD needs a cardinally aligned rectangular or square plot.';
    if (_jumpRunwayCad && !_isRectangular) return 'Jump runway CAD needs a cardinally aligned rectangular or square plot.';
    if (_plazaPavingCad && !_isRectangular) return 'Plaza paving CAD needs a cardinally aligned rectangular or square plot.';
    if (_shelterCanopyCad && !_isRectangular) return 'Shelter canopy CAD needs a cardinally aligned rectangular or square plot.';
    if (_publicToiletCad && (!_isRectangular || _floorCount != 1)) return 'Public toilet CAD needs one ground floor on a cardinally aligned rectangular or square plot.';
    if (_vehicleLiftCad && (!_isRectangular || _floorCount != 1)) return 'Vehicle service bay CAD needs one ground floor on a cardinally aligned rectangular or square plot.';
    if (_athleticsTrackCad && !_isRectangular) return 'Athletics track CAD needs a cardinally aligned rectangular or square plot.';
    if (_playgroundCad && !_isRectangular) return 'Playground CAD needs a cardinally aligned rectangular or square plot.';
    if (_bicycleRackCad && !_isRectangular) return 'Bicycle rack CAD needs a cardinally aligned rectangular or square plot.';
    if (_memorialNicheCad && !_isRectangular) return 'Memorial niche CAD needs a cardinally aligned rectangular or square plot.';
    if (_tennisCad && !_isRectangular) return 'Tennis CAD needs a cardinally aligned rectangular or square plot.';
    if (_twinTankCad && !_isRectangular) return 'Twin-cell tank CAD needs a cardinally aligned rectangular or square plot.';
    if (_coldRackCad && (!_isRectangular || _floorCount!=1)) return 'Cold-storage rack CAD needs one ground floor on a cardinally aligned rectangular or square plot.';
    if (_angledParkingCad && !_isRectangular) return 'Surface parking CAD needs a cardinally aligned rectangular or square plot.';
    if (_galleryPanelCad && (!_isRectangular || _floorCount != 1)) return 'Gallery panel CAD needs one ground floor on a cardinally aligned rectangular or square plot.';
    if (_windrowYardCad && !_isRectangular) return 'Windrow yard CAD needs a cardinally aligned rectangular or square plot.';
    if (_parkLoopCad && !_isRectangular) return 'Park loop CAD needs a cardinally aligned rectangular or square plot.';
    if (_amphitheatreCad && !_isRectangular) return 'Amphitheatre CAD needs a cardinally aligned rectangular or square plot.';
    if (_raisedBedCad && !_isRectangular) return 'Raised-bed CAD needs a cardinally aligned rectangular or square plot.';
    if (_publicMarketCad && (!_isRectangular || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Public market CAD needs a rectangular or square plot with cardinal frontage.';
    }
    if (_lapPoolCad && !_isRectangular) return 'Lap pool CAD needs a cardinally aligned rectangular or square plot.';
    if (_rainwaterCad && !_isRectangular) return 'Rainwater CAD needs a cardinally aligned rectangular or square plot.';
    if (_basketballCad && (!_isRectangular || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Basketball court CAD needs a rectangular or square plot with cardinal frontage.';
    }
    if (_hotelWingCad && (!_isRectangular || _floorCount != 1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Hotel wing CAD needs one ground floor on a rectangular or square plot with cardinal frontage.';
    }
    if (_teachingLabCad && (!_isRectangular || _floorCount != 1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Teaching lab CAD needs one ground floor on a rectangular or square plot with cardinal frontage.';
    }
    if (_switchbackRampCad && (!_isRectangular || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Switchback ramp CAD requires a rectangular or square plot with cardinal frontage.';
    }
    if (_orchardCad && !_isRectangular) return 'Orchard CAD requires a rectangular or square plot aligned to the cardinal axes.';
    if (_evHubCad && (!_isRectangular || !const {'North','East','South','West'}.contains(_facing))) {
      return 'EV hub CAD requires a rectangular or square plot with cardinal frontage.';
    }
    if (_basinCad && !_isRectangular) return 'Basin CAD requires a rectangular or square plot aligned to the cardinal axes.';
    if (_solarCad && !_isRectangular) return 'Fixed-tilt solar CAD requires a rectangular or square plot aligned to the cardinal axes.';
    if (_truckSweepCad && (!_isRectangular || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Truck sweep CAD needs a measured rectangular or square plot and a cardinal approach.';
    }
    if (_inpatientWardCad && (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'General inpatient ward CAD needs one ground floor and a cardinal entrance.';
    }
    if (_greenhouseCad && (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Greenhouse bench CAD needs one ground floor and a cardinal entrance.';
    }
    if (_hostelCad && (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Shared-room hostel CAD needs one ground floor and a cardinal entrance.';
    }
    if (_badmintonCad && (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Indoor badminton CAD needs one ground floor and a cardinal player entrance.';
    }
    if (_libraryCad && (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Library CAD needs one ground floor and a cardinal public entrance.';
    }
    if (_assemblyCad && (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Factory assembly CAD needs one ground floor and a cardinal receiving frontage.';
    }
    if (_cattleCad) {
      if (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing)) {
        return 'Cattle shed CAD needs one ground floor and a cardinal feed entrance.';
      }
      if (checkRooms && activeSpaceQuantities(_spaces,_spaceDetails).isNotEmpty) {
        return 'Cattle shed CAD already draws the pens, troughs and alleys. Leave the additional Space selections empty.';
      }
    }
    if (_diningCad && (_floorCount!=1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Dine-in service CAD needs one ground floor and a cardinal customer frontage.';
    }
    if (_officeCad && (_floorCount != 1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'Office workplace CAD needs one ground floor and a cardinal entrance direction.';
    }
    if (_schoolCad && (_floorCount != 1 || !const {'North','East','South','West'}.contains(_facing))) {
      return 'The primary school template needs one ground floor and a cardinal entrance direction.';
    }
    if (_clinicCad) {
      if (_floorCount != 1) return 'Separate clinic route CAD requires one ground floor.';
      if (!const {'South','North','East','West'}.contains(_facing)) return 'Choose the measured cardinal patient entrance side.';
    }
    if (_enclosedCad && _floorCount != 1) return 'Measured enclosed CAD requires one floor. The high-rise planner is separate.';
    if (_enclosedCad && !const {'South','North','East','West'}.contains(_facing)) return 'Choose the cardinal frontage for the measured enclosed plan.';
    if (_home && (_floorCount < 1 || _floorCount > 100)) return 'Enter the total floor count, including the ground floor.';
    if (_home && _facing == null) return 'Select the frontage direction or mark it unknown.';
    if (_home && _bedrooms < 0) return 'Enter the bedroom count or choose a configuration with a known count.';
    if (_home && _parking == null) return 'Choose whether you need parking.';
    if (_home && _baths < 1) return 'A dwelling needs at least one bathroom in this brief.';
    final facility = _facilityIssue();
    if (facility != null) return facility;
    if (_floorCount > 1 && _home) {
      int sum(String name) => _levels.fold(0, (total, n) => total + (int.tryParse('${_answers['level_${name}_$n'] ?? ''}') ?? 0));
      if (sum('bedrooms') != _bedrooms || sum('baths') != _baths) {
        return 'The bedroom and bathroom counts on individual floors must add up to your total requirements.';
      }
    }
    if (_terrace && _roofBudget.remaining < -0.001) return 'The requested terrace zones exceed the available terrace area.';
    for (final level in {0, ..._levels}) {
      final area = _budget(level);
      if (area.remaining < -0.001) return '${_levelName(level)} needs more area than you have entered. Review the budget and your selections.';
      if (_home && !_g1Cad && area.width != null && area.depth != null &&
          (_floorCount <= 1 || _answers['main_kitchen_floor'] == '$level') &&
          !homeRoomSizes['family_living_room']!.fits(area.width!, area.depth!)) {
        return 'The measured width and depth cannot fit the concept living-room allowance.';
      }
    }
    if (checkRooms) {
      if ((_enclosedCad || _clinicCad || _officeCad || _diningCad || _schoolCad || _libraryCad || _mixedHomeCad || _g1Cad || _packhouseCad || _assemblyCad || _badmintonCad || _hostelCad) && activeSpaceQuantities(_spaces, _spaceDetails).isEmpty) return 'Add at least one measured interior room.';
      for (final entry in activeSpaceQuantities(_spaces, _spaceDetails).entries) {
        final label = _customSpaces[entry.key] ?? taxonomyChoice(_allSpaces, entry.key)?.label ?? entry.key;
        final detail = _spaceDetails[entry.key] ?? const <String, Object>{};
        final level = _spaceLevel(detail);
        if (level == null || level < 0 || (level > 0 && level >= _floorCount)) return '$label: choose an existing floor by level number (0 for ground).';
        if (_clinicCad && !const {'patient','service'}.contains(detail['hc_route'])) {
          return '$label: choose the patient or staff/service route in Space details.';
        }
        if (_stackedCad && detail['floor_level']!='1') return '$label: choose First floor above shop in Space details.';
        if (_g1Cad && !const {'0','1'}.contains(detail['floor_level'])) return '$label: choose Ground or First floor in Space details.';
        if ((_enclosedCad || _clinicCad || _officeCad || _diningCad || _schoolCad || _libraryCad || _mixedHomeCad || _g1Cad || _packhouseCad || _assemblyCad || _badmintonCad || _hostelCad) && (positiveNumber(detail['width']) == null || positiveNumber(detail['length']) == null)) {
          return '$label: measured enclosed CAD needs clear width and length in Space details.';
        }
        if (_coveredByCore(entry.key)) continue;
        final allocation = _roomAllocation(entry.key);
        if (allocation.minimum == null) return '$label: enter an area with units or both clear dimensions in its details.';
        final area = _budget(level);
        if (area.width != null && area.depth != null && allocation.width != null && allocation.depth != null &&
            !PlanningSize(allocation.width!, allocation.depth!, allocation.minimum!).fits(area.width!, area.depth!)) {
          return '$label does not fit the available width and depth.';
        }
      }
    }
    return null;
  }

  Widget _areaSummary() {
    final ground = _budget(0);
    String number(double n) => n.toStringAsFixed(0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text('Plot: ${number(ground.total)} sqft  •  Usable estimate: ${number(ground.available)} sqft',
        style: Theme.of(context).textTheme.labelMedium),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        for (final n in {0, ..._levels})
          Padding(padding: const EdgeInsets.only(right: 12), child: Text(
            '${_levelName(n)}: ${number(_budget(n).minimum)} planned / ${number(_budget(n).remaining)} left',
            style: Theme.of(context).textTheme.labelSmall)),
        if (_terrace) Text('Terrace: ${number(_roofBudget.minimum)} planned / ${number(_roofBudget.remaining)} left',
          style: Theme.of(context).textTheme.labelSmall),
      ])),
      if ({0, ..._levels}.any((n) => _budget(n).unknown)) const Text('Not counted: spaces without size inputs.'),
      if (_g1Cad) const Text('Draft counts measured rooms and stair; walls and passages are checked in the final CAD fit.')
      else if (_step == 3 || _step == 4)
        Text('Ground floor typical: ${number(ground.typical)} sqft • Concept estimates only',
          style: Theme.of(context).textTheme.labelSmall),
    ]);
  }

  String? _spaceProgramIssue() => validateSpaceProgram({
    for (final space in _allSpaces)
      if (_spaces.containsKey(space.id)) space.id: space.label,
  }, _spaceDetails);

  String? _facilityIssue() {
    final floors = int.tryParse(_floors.text);
    final typical = int.tryParse('${_answers['typical_floors'] ?? ''}');
    if (!_linearSite && floors != null && typical != null && typical > floors) {
      return 'Typical floors cannot exceed total floors above grade.';
    }
    if (!_linearSite && floors != null && _facilityAnswers['house_form'] == 'single_floor' && floors != 1) {
      return 'Single-floor house and the total floor count do not match.';
    }
    final bedrooms = int.tryParse('${_facilityAnswers['bedrooms'] ?? ''}');
    if (bedrooms != null && _facilitySchema.any((f) => f.id == 'bedrooms')) {
      final exactBhk = RegExp(r'^([1-5])_bhk$').firstMatch(_configurationId ?? '');
      if (exactBhk != null && bedrooms != int.parse(exactBhk.group(1)!)) {
        return 'Bedroom count must match the selected BHK. Go back to change the configuration if needed.';
      }
      if (_configurationId == '6_plus_bhk' && bedrooms < 6) return '6+ BHK requires at least six bedrooms.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final issue = _planningIssue(checkRooms: true);
    if (issue != null) { setState(() => _sectionError = issue); return; }
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProjectProvider>();
    final notifications = context.read<NotificationProvider>();
    final project = widget.existingProject;
    final name = _name.text.trim();
    final width = _isRectangular ? _measuredFeet(_width) : null;
    final length = _shapeId == 'square' ? width : (_isRectangular ? _measuredFeet(_depth) : null);
    final facing = _linearSite ? 'Not decided' : _facing ?? 'Not decided';
    final layout = _currentScenario?.configuration?.label ?? '';
    final previous = project?.brief;
    final brief = ProjectBrief(
      type: previous?.type,
      legacyLayout: previous?.legacyLayout ??
          (previous?.type != null && previous?.taxonomy == null ? project?.bhk : null),
      taxonomy: TaxonomySelection(
        version: projectTaxonomyVersion,
        categoryId: _category!.id,
        subcategoryId: _group!.id,
        typeId: _type!.id,
        configurationId: _configurationId,
        actionId: _actionId,
        stageId: _stageId,
        plotShapeId: _linearSite ? null : _shapeId,
        scenarioId: _currentVariant?.id ?? _currentScenario?.id,
        spaceQuantities: activeSpaceQuantities(_spaces, _spaceDetails),
      ),
      requirements: ProjectRequirementsSnapshot(
        version: requirementsSchemaVersion,
        answers: {
          ...requirementAnswers(_generalSchema, _answers),
          ...requirementAnswers(_facilitySchema, _facilityAnswers),
        },
        customSpaces: _customSpaces,
        spaceDetails: {
          for (final item in _spaceDetails.entries)
            if (_spaces.containsKey(item.key)) item.key: {
              for (final detail in item.value.entries)
                if (!isExcludedSpace(item.value) || !spaceAdjacencyKeys.contains(detail.key))
                  detail.key: detail.value,
            },
        },
      ),
      floorCount: _linearSite ? null : int.tryParse(_floors.text.trim()),
      parking: _linearSite ? null : _parking,
      features: previous?.features ?? const [],
    );
    setState(() => _saving = true);
    try {
      if (project == null) {
        await provider.addProject(
          name: name, length: length ?? 0, width: width ?? 0, bhk: layout,
          floors: brief.floorLabel, facing: facing, brief: brief,
        );
      } else {
        await provider.updateProject(
          id: project.id, name: name, length: length ?? 0, width: width ?? 0,
          bhk: layout, floors: brief.floorLabel, facing: facing, brief: brief,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(content: Text('Could not save the project. Please try again.')));
      return;
    }
    if (!mounted) return;
    final title = project == null ? 'New Project Created' : 'Project Updated';
    unawaited(notifications.addNotification('success', title, '$name • ${_type!.label}').catchError(
      (Object error, StackTrace stack) => debugPrint('Unable to save project notification: $error'),
    ));
    if (SharedCoreCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => SharedCoreCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (StackedRetailCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => StackedRetailCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (MixedRetailCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => MixedRetailCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (TJunctionCadGenerator.requested(brief) || CrossJunctionCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => TJunctionCadScreen(name:name,brief:brief)));
    } else if (RefugeCrossingCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => RefugeCrossingCadScreen(name: name, brief: brief)));
    } else if (CycleCrossingCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => CycleCrossingCadScreen(name: name, brief: brief)));
    } else if (PromenadeCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => PromenadeCadScreen(name: name, brief: brief)));
    } else if (UnderpassCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => UnderpassCadScreen(name: name, brief: brief)));
    } else if (SteppedWallCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => SteppedWallCadScreen(name: name, brief: brief)));
    } else if (StreetLightCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => StreetLightCadScreen(name: name, brief: brief)));
    } else if (DuctBankCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => DuctBankCadScreen(name: name, brief: brief)));
    } else if (RailPlatformCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => RailPlatformCadScreen(name: name, brief: brief)));
    } else if (FootbridgeCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => FootbridgeCadScreen(name:name,brief:brief)));
    } else if (CulvertCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => CulvertCadScreen(name:name,brief:brief)));
    } else if (BusLaybyCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => BusLaybyCadScreen(name:name,brief:brief)));
    } else if (OpenDrainCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => OpenDrainCadScreen(name:name,brief:brief)));
    } else if (StormwaterCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => StormwaterCadScreen(name:name,brief:brief)));
    } else if (CorridorEarthworkGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => CorridorEarthworkScreen(name:name,brief:brief)));
    } else if (CorridorSectionGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => CorridorSectionScreen(name:name,brief:brief)));
    } else if (LongitudinalProfileGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => LongitudinalProfileScreen(name:name,brief:brief)));
    } else if (SurveyCorridorGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => SurveyCorridorScreen(name:name,brief:brief),
      ));
    } else if (PackhouseCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => PackhouseCadScreen(name: name, brief: brief, widthFt: width ?? 0,
          depthFt: length ?? 0, facing: facing),
      ));
    } else if (PairedApartmentGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => PairedApartmentScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (RainGardenCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => RainGardenCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (SilageBunkerCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => SilageBunkerCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (AquaculturePondCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => AquaculturePondCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (DockLevellerCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => DockLevellerCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (BoulderingBayCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => BoulderingBayCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (WeighbridgeCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => WeighbridgeCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (CoolingLoopCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => CoolingLoopCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (BoardwalkCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => BoardwalkCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (CircularClarifierCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => CircularClarifierCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (BladeLaydownCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => BladeLaydownCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (CricketNetsCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => CricketNetsCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (SkateTransitionCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => SkateTransitionCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (ParkFenceCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => ParkFenceCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (TransformerBundCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => TransformerBundCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (FootballPitchCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => FootballPitchCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (GuyedMastCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => GuyedMastCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (RecyclingDropoffCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => RecyclingDropoffCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (SpillwayCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => SpillwayCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (BatteryYardCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => BatteryYardCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (ParkingRampCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => ParkingRampCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (CinemaSeatingCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => CinemaSeatingCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (SwitchbackStairCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => SwitchbackStairCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (JumpRunwayCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => JumpRunwayCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (PlazaPavingCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => PlazaPavingCadScreen(
        name: name, brief: brief, widthFt: width ?? 0, depthFt: length ?? 0)));
    } else if (ShelterCanopyCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => ShelterCanopyCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (PublicToiletCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => PublicToiletCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (VehicleLiftCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => VehicleLiftCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (AthleticsTrackCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => AthleticsTrackCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (PlaygroundCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => PlaygroundCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (BicycleRackCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => BicycleRackCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (MemorialNicheCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => MemorialNicheCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (TennisCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => TennisCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (TwinTankCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => TwinTankCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (ColdRackCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => ColdRackCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (AngledParkingCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => AngledParkingCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (GalleryPanelCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => GalleryPanelCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (WindrowYardCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => WindrowYardCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (ParkLoopCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => ParkLoopCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (AmphitheatreCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => AmphitheatreCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (RaisedBedCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => RaisedBedCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (PublicMarketCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => PublicMarketCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (LapPoolCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => LapPoolCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (RainwaterCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => RainwaterCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (BasketballCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => BasketballCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (HotelWingGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => HotelWingScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (TeachingLabGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => TeachingLabScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (SwitchbackRampGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => SwitchbackRampScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (OrchardCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => OrchardCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (EvHubGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => EvHubScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (DetentionBasinGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => DetentionBasinScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (SolarFarmGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => SolarFarmScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0)));
    } else if (TruckSweepGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => TruckSweepScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (InpatientWardCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => InpatientWardCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (GreenhouseCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => GreenhouseCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (HostelCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => HostelCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (BadmintonCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => BadmintonCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (LibraryCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => LibraryCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (AssemblyCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => AssemblyCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (CattleShedCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(builder: (_) => CattleShedCadScreen(
        name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing)));
    } else if (DiningCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void,void>(MaterialPageRoute(
        builder: (_) => DiningCadScreen(name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing),
      ));
    } else if (OfficeCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => OfficeCadScreen(name:name,brief:brief,widthFt:width??0,depthFt:length??0,facing:facing),
      ));
    } else if (SchoolCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => SchoolCadScreen(name: name, brief: brief, widthFt: width ?? 0,
          depthFt: length ?? 0, facing: facing),
      ));
    } else if (DwellingG1Generator.requested(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => DwellingG1Screen(name: name, brief: brief, widthFt: width ?? 0,
          depthFt: length ?? 0, facing: facing),
      ));
    } else if (RetailCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => RetailCadScreen(name: name, brief: brief, widthFt: width ?? 0,
          depthFt: length ?? 0, facing: facing),
      ));
    } else if (HealthcareCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => HealthcareCadScreen(name: name, brief: brief, widthFt: width ?? 0,
          depthFt: length ?? 0, facing: facing),
      ));
    } else if (WarehouseLoadingGenerator.requested(brief) || CrossDockCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => WarehouseLoadingScreen(name: name, brief: brief, widthFt: width ?? 0,
          depthFt: length ?? 0, facing: facing),
      ));
    } else if (EnclosedCadGenerator.requested(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => EnclosedCadScreen(name: name, brief: brief, widthFt: width ?? 0,
          depthFt: length ?? 0, facing: facing),
      ));
    } else if (_answers['cad_output'] != 'zones' && AutomaticFloorPlanGenerator.supportsBrief(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => AutomaticFloorPlanScreen(projectName: name, brief: brief,
          frontageFt: width ?? 0, depthFt: length ?? 0, facing: facing),
      ));
    } else {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => ConceptZoningScreen(name: name, brief: brief, widthFt: width ?? 0,
          depthFt: length ?? 0, facing: facing),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = _unsupportedBrief
        ? const Text('This brief uses an unavailable taxonomy version or type. Its saved data has not been changed.')
        : switch (_step) {
            0 => _selectionList(
                'Choose a category (required).',
                projectTaxonomy.map((c) => _selectionTile(c.label, c.id == _category?.id, () => _categorySelected(c))),
              ),
            1 => _selectionList(
                'Choose a subcategory (required).',
                _category!.groups.map((g) => _selectionTile(g.label, g.id == _group?.id, () => _groupSelected(g))),
              ),
            2 => _buildTypes(),
            3 => _buildConfiguration(),
            4 => _buildSpaces(),
            5 => _buildProjectInfo(),
            6 => _buildSite(),
            7 => _section('Authority data is recorded as provided. This app has not verified it.', _ruleSchema),
            8 => _buildFacility(),
            9 => _section('Record technical requirements for coordination and specialist review.', technicalFields),
            10 => _section('These are preferences, not verified design constraints. Vastu never overrides safety or local rules.', _designSchema),
            11 => _section('Capture budget, schedule and desired outputs. This does not enable generation or export.', deliveryFields),
            _ => _buildReview(),
          };
    return PopScope<void>(
      canPop: _step == 0 && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existingProject == null ? 'New Project' : 'Edit Project'),
          leading: BackButton(onPressed: _saving ? () {} : _back),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text('STEP ${_step + 1} OF ${_steps.length}', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: (_step + 1) / _steps.length),
                    const SizedBox(height: 12),
                    Text(_steps[_step], style: theme.textTheme.headlineSmall),
                    if (_step > 0)
                      Text(_selectionPath, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (!_unsupportedBrief && _step >= 3 && !_linearSite && _budget(0).total > 0)
                      _areaSummary(),
                    Expanded(
                      child: SingleChildScrollView(
                        key: ValueKey(_step),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: body,
                      ),
                    ),
                    if (_sectionError != null)
                      Text(_sectionError!, style: TextStyle(color: theme.colorScheme.error)),
                    if (_showsContinue)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: FilledButton(
                          onPressed: _saving ? null : (_isReview ? _save : _next),
                          child: Text(_saving ? 'Saving…' : (_isReview ? 'Save project brief' : 'Continue')),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionList(String prompt, Iterable<Widget> tiles) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text(prompt), const SizedBox(height: 8), ...tiles],
      );

  Widget _selectionTile(String label, bool selected, VoidCallback onTap) => Card(
        child: ListTile(
          title: Text(label),
          trailing: Icon(selected ? Icons.check : Icons.chevron_right),
          selected: selected,
          onTap: onTap,
        ),
      );

  Widget _buildTypes() {
    final query = _typeQuery.trim().toLowerCase();
    final matches = _group!.types.where((type) => type.label.toLowerCase().contains(query));
    return _selectionList('Choose a project type (required).', [
      TextFormField(
        initialValue: _typeQuery,
        decoration: const InputDecoration(labelText: 'Search project types', prefixIcon: Icon(Icons.search)),
        onChanged: (value) => setState(() => _typeQuery = value),
      ),
      const SizedBox(height: 8),
      if (matches.isEmpty) const Text('No matching project types.'),
      for (final type in matches)
        _selectionTile(type.label, type.id == _type?.id, () => _typeSelected(type)),
    ]);
  }

  Widget _buildConfiguration() => Form(
    key: _sectionForms[_step],
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_customInfrastructure) _fieldPanel([customSiteKindField]),
      if (_junctionEligible) _fieldPanel([tJunctionCadMode]),
      if (_stormwaterEligible) _fieldPanel([stormwaterCadMode]),
      if (_culvertEligible) _fieldPanel([culvertCadMode]),
      if (_promenadeEligible) _fieldPanel([promenadeCadMode]),
      if (_underpassEligible) _fieldPanel([underpassCadMode]),
      if (_steppedWallEligible) _fieldPanel([steppedWallCadMode]),
      if (_streetLightEligible) _fieldPanel([streetLightCadMode]),
      if (_ductBankEligible) _fieldPanel([ductBankCadMode]),
      if (_railPlatformEligible) _fieldPanel([railPlatformCadMode]),
      if (_footbridgeEligible) _fieldPanel([footbridgeCadMode]),
      if (_busLaybyEligible) _fieldPanel([busLaybyCadMode]),
      if (_surveyCorridorEligible) _fieldPanel([_corridorModeField]),
      if (!_linearSite) ...[
        _dropdown('Plot geometry (required)', _shapeId, plotShapes, (value) => setState(() => _shapeId = value), required: true),
        const SizedBox(height: 12),
        if (_isRectangular) ...[
          _dropdown('Plot units', _plotUnit, const [TaxonomyChoice('ft', 'Feet'), TaxonomyChoice('m', 'Metres')], _changePlotUnit),
          const SizedBox(height: 12),
          _dimension(_width, _shapeId == 'square' ? 'Plot side ($_plotUnit)' : 'Plot width / frontage ($_plotUnit)'),
          if (_shapeId == 'rectangular') ...[
            const SizedBox(height: 12),
            _dimension(_depth, 'Plot depth ($_plotUnit)'),
          ],
          const SizedBox(height: 12),
        ],
      ],
      _fieldPanel(_frontPlanning.where((f) =>
        const {'surveyed_plot_area', 'route_length','right_of_way','alignment_reference','vastu'}.contains(f.id)).toList()),
      if ((_home || _vastu || _enclosedCad || _warehouseCad || _crossDockCad || _clinicCad || _retailCad || _officeCad || _diningCad || _cattleCad || _schoolCad || _libraryCad || _packhouseCad || _assemblyCad || _badmintonCad || _hostelCad || _greenhouseCad || _sharedCoreCad || _inpatientWardCad || _truckSweepCad || _pairedApartmentCad || _evHubCad || _switchbackRampCad || _teachingLabCad || _hotelWingCad || _basketballCad || _publicMarketCad || _mixedHomeCad) && !_linearSite) ...[
        _facingPicker(required: true),
        if (_vastu && _facing != null && _facing != 'Not decided')
          const Text('Vastu review: consider northeast for puja, southeast for kitchen and southwest for the main bedroom when feasible. These are preferences, not layout or approval checks.'),
      ],
      if (_surveySheetOnly || (_linearSite ? positiveNumber(_answers['route_length']) != null && positiveNumber(_answers['right_of_way']) != null : _budget(0).total > 0)) ...[
      const SizedBox(height: 12),
      if (!_linearSite) ...[
        TextFormField(
          key: const ValueKey('floor_count'),
          controller: _floors,
          decoration: InputDecoration(labelText: _home ? 'Floors above grade (required)' : 'Floors above grade (optional)',
            helperText: 'Include the ground floor. Up to 100 levels in this brief.'),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _sectionError = null),
          validator: (value) {
            if (!_home && (value ?? '').trim().isEmpty) return null;
            final n = int.tryParse((value ?? '').trim());
            return n != null && n >= (_home ? 1 : 0) && n <= 100 ? null : 'Enter a valid floor count (up to 100).';
          },
        ),
        const SizedBox(height: 12),
      ],
      _dropdown('${_program.configurationLabel} (optional)', _configurationId, _program.configurations,
        (value) => setState(() {
          if (_configurationId != value) { _answers.remove(customConfigurationField.id); _sectionError = null; }
          _configurationId = value;
        }), available: (option) {
          if (!_home || _floorCount > 1) return true;
          final area = _budget(0);
          final bedrooms = int.tryParse(RegExp(r'^([1-5])_(?:bhk|bedroom)$').firstMatch(option.id)?.group(1) ?? '');
          return bedrooms == null || area.total <= 0 || dwellingAllowance(bedrooms, _baths).minimum <= area.available;
        }),
      const SizedBox(height: 12),
      if (_home) const Text('Kitchen and at least one bathroom are included. Enter a bedroom count if you skip the configuration label.'),
      _fieldPanel(_essential, facility: true),
      if (!_linearSite) ...[
        _dropdown(_home ? 'Parking (required)' : 'Parking (optional)', _parking?.name, [
          for (final parking in ProjectParking.values) TaxonomyChoice(parking.name, parking.label),
        ], (value) => setState(() => _parking = value == null ? null : ProjectParking.values.byName(value)), required: _home),
        const SizedBox(height: 12),
      ],
      if (_crossDockCad) const Text('Leave Storage layout as Not specified: this drawing uses a transfer hall, not storage/racking. Docks / loading doors is the total for both banks.'),
      if (_sharedCoreCad) const Text('The right-hand core uses the clear stair width. One entry connects to the shop and the measured stair; the shaft is a sealed space reserve.'),
      if (_stackedCad) const Text('The right-hand stair strip uses the measured stair width plus two walls. Both floors share the measured plate; the stair lands at the upper passage.'),
      if (_g1Cad) const Text('Optional terrace: select open terrace only. It uses a second measured straight flight, with an aligned sealed reserve below on ground.'),
      if (_g1Cad && _wantsParking) const Text('Open parking only: a row of bays with unobstructed vehicle access across its full width, plus a separate pedestrian walk. Enter requested bay counts in Operations.'),
      if (!_linearSite) _fieldPanel(_cadFields),
      if (_solarCad) const Text('The plot width is east–west and depth north–south. Setbacks use south as front and west as left. Use the sun angle in the vertical plane perpendicular to the rows.'),
      if (_isRectangular) ExpansionTile(
        title: const Text('Known setbacks (optional)'),
        maintainState: true,
        children: [_fieldPanel(jurisdictionFields.where((f) => f.id.endsWith('_setback')).toList())],
      ),
      _fieldPanel(_frontPlanning.where((f) =>
        !const {'plot_unit','custom_site_kind','surveyed_plot_area','route_length','right_of_way','alignment_reference','vastu'}.contains(f.id)).toList()),
      if (_floorCount > 1 && !_linearSite) ...[
        _fieldPanel(_floorPlanning.where((f) => f.id == 'main_kitchen_floor').toList()),
        for (final level in _levels) ...[
          const Divider(),
          Text(_levelName(level), style: Theme.of(context).textTheme.titleSmall),
          _fieldPanel(_levelFields(level)),
        ],
      ],
      ],
    ]),
  );

  Widget _facingPicker({bool required = false}) => _dropdown(
    required ? 'Front-facing side (required)' : 'Front-facing side (optional)', _facing, [
    for (final direction in _directions)
      TaxonomyChoice(direction, direction == 'Not decided' ? 'Unknown / survey required' : direction),
  ], (value) => setState(() => _facing = value), required: required);

  bool _canAddSpace(String id) {
    final size = _sizeFor(id);
    if (_linearSite || size == null || _coveredByCore(id)) return true;
    return {0, ..._levels}.any((n) => _budget(n).fits(size));
  }

  Widget? _spaceHint(String id) {
    if (_linearSite) return null;
    if (_coveredByCore(id)) return const Text('Already allowed for in the main requirements; optional room details.');
    final size = _sizeFor(id);
    if (size == null) return const Text('Enter your size in Details if selected.');
    if (!_spaces.containsKey(id) && !_canAddSpace(id)) return const Text('Not enough space in the entered floor budgets.');
    return Text('Concept minimum ${size.minimum.toStringAsFixed(0)} sqft • Typical ${size.typical.toStringAsFixed(0)} sqft');
  }

  Widget _buildSpaces() => Form(
        key: _spaceForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_underpassCad ? 'The survey defines the walkway, covered span and approaches. Leave separate Space selections empty.' : _steppedWallCad ? 'The survey defines the stepped wall envelope. Leave separate Space selections empty.' : _streetLightCad ? 'The surveyed baseline and spacing rules define one pole row. Leave separate Space selections empty.' : _ductBankCad ? 'The survey and proposed levels define a single straight duct bank. Leave separate Space selections empty.' : _refugeCrossingCad ? 'The surveyed median and crossing station data define this layout. Leave separate Space selections empty.' : _cycleCrossingCad ? 'The surveyed road edge and driveway windows define the track. Leave separate Space selections empty.' : _promenadeCad ? 'The surveyed shoreline and pad records define the promenade. Leave separate Space selections empty.' : _railPlatformCad ? 'The surveyed track and levels define the platform. Leave separate Space selections empty.' : _rainGardenCad ? 'The dimensions define one open rain garden. Leave floors, Parking and separate Space selections empty.' : _dockLevellerCad ? 'The dimensions define one dock bay. Leave separate Parking and Space selections empty.' : _aquaculturePondCad ? 'The dimensions define one open pond. Leave floors, Parking and separate Space selections empty.' : _silageBunkerCad ? 'The dimensions define one open-front bunker. Leave floors, Parking and separate Space selections empty.' : _boulderingBayCad ? 'The dimensions define one ground-floor climbing hall. Leave Parking and separate Space selections empty.' : _weighbridgeCad ? 'The dimensions define one weighbridge corridor and bypass. Leave floors, Parking and separate Space selections empty.' : _coolingLoopCad ? 'The dimensions define one outdoor cooling pipe loop. Leave floors, Parking and separate Space selections empty.' : _boardwalkCad ? 'The dimensions define one raised boardwalk. Leave floors, Parking and separate Space selections empty.' : _circularClarifierCad ? 'The dimensions define one outdoor clarifier. Leave floors, Parking and separate Space selections empty.' : _bladeLaydownCad ? 'The dimensions define one outdoor blade laydown strip. Leave floors, Parking and separate Space selections empty.' : _cricketNetsCad ? 'The dimensions define an outdoor cricket lane bank. Leave floors, Parking and separate Space selections empty.' : _skateTransitionCad ? 'The dimensions define one circular skate transition and its reserves. Leave floors, Parking and separate Space selections empty.' : _parkFenceCad ? 'The dimensions define one fence with a south gate. Leave floors, Parking and separate Space selections empty.' : _transformerBundCad ? 'The dimensions define one outdoor bund and two solid plinths. Leave floors, Parking and separate Space selections empty.' : _footballPitchCad ? 'The dimensions define one outdoor pitch and its run-off. Leave floors, Parking and separate Space selections empty.' : _guyedMastCad ? 'The dimensions define one outdoor mast and three guy anchors. Leave floors, Parking and separate Space selections empty.' : _recyclingDropoffCad ? 'The dimensions define an outdoor container drop-off row. Leave floors, Parking and separate Space selections empty.' : _spillwayCad ? 'The dimensions define one open spillway. Leave floors, Parking and separate Space selections empty.' : _batteryYardCad ? 'The dimensions define one outdoor battery equipment yard. Leave floors, Parking and separate Space selections empty.' : _parkingRampCad ? 'The dimensions define one vehicle ramp strip. Leave building floors, Parking and separate Space selections empty.' : _cinemaSeatingCad ? 'The dimensions define one clear ground-floor seating hall. Leave Parking and separate Space selections empty.' : _switchbackStairCad ? 'The measured fields define two open-air stair flights and three landings. Leave floors, Parking and separate Space selections empty.' : _jumpRunwayCad ? 'The dimensions define one outdoor straight runway and sand pit. Leave floors, Parking and separate Space selections empty.' : _plazaPavingCad ? 'The measured fields define one outdoor paving rectangle. Leave floors, Parking and separate Space selections empty.' : _shelterCanopyCad ? 'The fields define an open-sided shelter. Leave enclosed floors, Parking and separate Space selections empty.' : _publicToiletCad ? 'The measured fields define identical ground-floor rooms and their south gallery. Leave Parking and separate Space selections empty.' : _vehicleLiftCad ? 'Use one ground floor. Enter the Service bays count and clear height in Configuration; leave Parking and separate Space selections empty.' : _athleticsTrackCad ? 'The measured oval fields define the track geometry. Leave above-grade floors, Parking and separate Space selections empty.' : _playgroundCad ? 'Enter equipment and supplier-provided clearance dimensions in Site. Leave above-grade floors, Parking and separate Space selections empty.' : _bicycleRackCad ? 'The measured layout already includes the bicycle stands and the aisle. Leave floors, separate Parking and Space selections empty.' : _memorialNicheCad ? 'The fields define outdoor wall panels and their reserves. Leave above-grade floors, parking and separate Space selections empty.' : _tennisCad ? 'Use outdoor courts only. Leave above-grade floors, parking and separate Space selections empty.' : _twinTankCad ? 'Use one ground-level tank with two cells. Leave above-grade floors, parking and separate Space selections empty.' : _coldRackCad ? 'Use one ground-floor chamber. Enter the Facility clear height; leave separate Space selections and parking empty.' : _footbridgeCad ? 'The surveyed endpoints and deck dimensions define the crossing. Leave separate Space selections empty.' : _angledParkingCad ? 'The measured stall inputs define this outdoor parking layout. Leave above-grade floors and separate Parking and Space selections empty.' : _galleryPanelCad ? 'Use one ground-floor gallery hall without parking. Leave separate Space selections empty.' : _windrowYardCad ? 'Use one open windrow yard without buildings or parking. Leave above-grade floors and separate Space selections empty.' : _parkLoopCad ? 'Use one open park without buildings or parking. Leave above-grade floors and separate Space selections empty.' : _amphitheatreCad ? 'This is one outdoor amphitheatre. Leave the hall arrangement, building floors, parking and separate Space selections empty.' : _raisedBedCad ? 'Use one open garden without buildings or parking. Leave above-grade floors and separate Space selections empty.' : _busLaybyCad ? 'The surveyed road edge and measured reserves define the lay-by. Leave separate Space selections empty.' : _publicMarketCad ? 'Use one outdoor market without buildings or parking. Leave above-grade floors and separate Space selections empty.' : _lapPoolCad ? 'Use one outdoor pool without buildings or parking. Leave above-grade floors and separate Space selections empty.' : _rainwaterCad ? 'The template draws the entered horizontal roof footprint and tank bank. Leave separate Space selections empty.' : _basketballCad ? 'The template uses the measured outdoor court and run-offs directly. Leave separate Space selections empty.' : _hotelWingCad ? 'Enter an even guestroom key count in Facility. Wing depth follows from the measured module and walls. Leave separate Space selections empty.' : _teachingLabCad ? 'The lab template draws the bench banks, teacher counter and rear prep room. Leave separate Space selections empty.' : _switchbackRampCad ? 'The ramp uses the supplied flight and landing dimensions. Leave separate Space selections empty.' : _orchardCad ? 'The measured counts draw the trees, headlands and side access lanes. Leave separate Space selections empty.' : _evHubCad ? 'The hub draws one row of charging bays with a transfer strip, equipment pads and separate access walks. Leave separate Space selections empty.' : _basinCad ? 'The basin geometry comes from the measured levels and slopes in Site. Leave separate Space selections empty.' : _solarCad ? 'The solar sheet draws only tables, modules and setbacks from the brief. Leave separate Space selections empty.' : _pairedApartmentCad ? 'Enter two units and select 1 BHK in the unit mix. This template draws both mirrored flats and the shared lobby directly; leave separate Space selections empty.' : _truckSweepCad ? 'The swept-path sheet draws the measured apron, one truck and one dock. Leave separate Space selections empty and enter fixed apron obstacles in Site.' : _culvertCad ? 'The culvert drawing uses the two surveyed barrel ends and a straight road band. Leave separate Space selections empty.' : _stormwaterCad ? 'The surveyed drainage nodes define the run. Leave separate Space selections empty; this mode does not draw pumps, side branches or other structures.' : _earthworkCad ? 'The takeoff uses surveyed and proposed levels at matching stations. Leave separate Space selections empty.' : _corridorSectionCad ? 'The cross-section uses two offset/level lists at one chainage. Leave separate Space selections empty.' : _longProfileCad ? 'The longitudinal profile uses surveyed and proposed levels only. Leave separate Space selections empty.' : _inpatientWardCad ? 'The ward template draws the bed bays, nursing lobby and washroom reserve. Enter an even patient bed count (2–20) and leave separate Space selections empty.' : _sharedCoreCad ? 'The shared-core fields draw the shop, stock room, office and meeting room. Leave separate Space selections empty.' : _junctionCad ? 'The survey fields define the carriageway edges and right-of-way boundaries. Leave separate Space selections empty.' : _greenhouseCad ? 'The greenhouse dimensions already define the bay, benches and aisles. Leave separate Space selections empty; remove any selections from a previous drawing mode.' : _hostelCad ? 'Add 1–6 identical Bedrooms, one Warden Room and one Toilets/Baths reserve. Enter clear room dimensions in Details. Enter the resident count and 2, 4, 6 or 8 beds per bedroom in Facility setup.' : _badmintonCad ? 'Add one or two Field/Court spaces (measured marked rectangle), one Athlete Change room and optionally one Spectator Seating strip. For viewing, its clear depth equals the full inside hall depth; enter seats and aisle measurements separately.' : _libraryCad ? 'Add one Checkout/Return, Open Book Stacks and Quiet Reading room. Children’s reading, staff book processing and a toilet reserve are optional. Enter clear room dimensions in Details.' : _assemblyCad ? 'Add one Raw Material Receiving, Production Line, Quality Control and Dispatch room. Incoming Inspection, Raw Store and Finished Goods are optional. Enter the clear process-room width: gross width minus three walls and the staff passage.' : _cattleCad ? 'Pen rows, troughs and lanes come from the measured shed fields. Leave additional Space selections empty.' : _diningCad ? 'Add one Toilets, Dining, Kitchen and Wash room. Dining spans the plate; Kitchen and Wash fit side-by-side behind it. Enter seats in multiples of four.' : _officeCad ? 'Add one Reception, at least one Meeting Room and one Open Workstation room. Enter the individual desk count in Facility setup, not as a room quantity.' : _schoolCad ? 'Add measured school rooms. For a rear fenced playground, select Playground once, enter its clear size in Details, then enter access and fence measurements in Site.' : _crossDockCad ? 'The cross-dock drawing uses the measured banks, staging and staff access; leave separate space selections empty.' : _stackedCad ? 'Add the measured dwelling rooms only and assign them all to the first floor. Room width runs along the stair side; room length runs away from it. The shop and stair use their own inputs.' : _mixedCad ? 'Choose measured dwelling rooms only: living room, closed kitchen, shared bathroom(s) and the bedroom count you entered. The shop comes from the separate fixture dimensions.' : _surveyCorridorCad ? 'This CAD mode uses only the left-to-right band list in Site. Leave these discrete space selections empty.' : _packhouseCad ? 'Add one receiving, grading, packaging and dispatch room. An ambient finished store is optional. Each clear room width must match the clear building width.' : _retailCad ? 'The retail fixture plan already draws sales, display, checkout and stock. Do not add separate rooms for this drawing.' : _warehouseCad ? 'The measured loading plan already draws its staging, storage, bays and routes. Do not add separate rooms for this drawing.' :
              'Select spaces or components, then configure each one. This is not a code-required room schedule.'),
            const SizedBox(height: 8),
            if (!_mixedHomeCad && !_libraryCad && !_hostelCad && !_greenhouseCad && !_sharedCoreCad && !_inpatientWardCad && !_surveySheetOnly && !_truckSweepCad && !_pairedApartmentCad && !_solarCad && !_basinCad && !_evHubCad && !_orchardCad && !_switchbackRampCad && !_teachingLabCad && !_hotelWingCad && !_basketballCad && !_rainwaterCad && !_lapPoolCad && !_publicMarketCad && !_raisedBedCad && !_amphitheatreCad && !_parkLoopCad && !_windrowYardCad && !_galleryPanelCad && !_angledParkingCad && !_coldRackCad && !_rainGardenCad && !_silageBunkerCad && !_aquaculturePondCad && !_dockLevellerCad && !_boulderingBayCad && !_weighbridgeCad && !_coolingLoopCad && !_boardwalkCad && !_circularClarifierCad && !_bladeLaydownCad && !_cricketNetsCad && !_skateTransitionCad && !_parkFenceCad && !_transformerBundCad && !_footballPitchCad && !_guyedMastCad && !_recyclingDropoffCad && !_spillwayCad && !_batteryYardCad && !_parkingRampCad && !_cinemaSeatingCad && !_switchbackStairCad && !_jumpRunwayCad && !_plazaPavingCad && !_shelterCanopyCad && !_publicToiletCad && !_vehicleLiftCad && !_athleticsTrackCad && !_playgroundCad && !_bicycleRackCad && !_memorialNicheCad && !_tennisCad && !_twinTankCad) OutlinedButton.icon(onPressed: _addCustomSpace, icon: const Icon(Icons.add), label: const Text('Add an unlisted space')),
            for (final space in _allSpaces)
              Column(
                key: ValueKey(space.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(space.label),
                    subtitle: _spaceHint(space.id),
                    value: _spaces.containsKey(space.id),
                    onChanged: !_spaces.containsKey(space.id) && !_canAddSpace(space.id) ? null : (checked) => setState(() {
                      if (checked == true) {
                        _spaces[space.id] = '1';
                      } else {
                        _removeSpace(space.id);
                      }
                    }),
                  ),
                  if (_spaces.containsKey(space.id)) ...[
                    if (!isExcludedSpace(_spaceDetails[space.id])) TextFormField(
                      initialValue: _spaces[space.id],
                      decoration: InputDecoration(labelText: '${space.label} quantity (required)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => setState(() => _spaces[space.id] = value),
                      validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0 ? null : 'Enter a positive quantity.',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: () => _editSpace(space),
                        child: Text(_spaceDetails[space.id]?.isNotEmpty == true ? 'Edit ${space.label} details' : 'Add ${space.label} details')),
                    ),
                  ],
                ],
              ),
          ],
        ),
      );

  void _removeSpace(String id) {
    _spaces.remove(id);
    _customSpaces.remove(id);
    _spaceDetails.remove(id);
    for (final entry in _spaceDetails.entries.toList()) {
      final updated = Map<String, Object>.of(entry.value);
      for (final key in spaceAdjacencyKeys) {
        final current = updated[key];
        if (current is Iterable) {
          final remaining = current.whereType<String>().where((value) => value != id).toList();
          if (remaining.isEmpty) { updated.remove(key); } else { updated[key] = remaining; }
        }
      }
      _spaceDetails[entry.key] = updated;
    }
  }

  Future<void> _addCustomSpace() async {
    final names = _allSpaces.map((space) => space.label.toLowerCase()).toSet();
    final form = GlobalKey<FormState>();
    var draft = '';
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Add an unlisted space'),
      content: Form(key: form, child: TextFormField(
        decoration: const InputDecoration(labelText: 'Space name (required)'),
        maxLength: 80,
        onChanged: (value) => draft = value.trim(),
        validator: (_) => draft.isEmpty ? 'Enter a name.' : names.contains(draft.toLowerCase()) ? 'That space is already listed.' : null,
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (form.currentState!.validate()) Navigator.pop(context, draft);
        }, child: const Text('Add space')),
      ],
    ));
    if (!mounted || name == null) return;
    setState(() {
      var index = 1;
      while (_customSpaces.containsKey('custom_space_$index')) { index++; }
      final id = 'custom_space_$index';
      _customSpaces[id] = name;
      _spaces[id] = '1';
    });
  }

  List<RequirementField> _spaceSchema(String id) {
    final prior = _spaceDetails[id];
    final referenced = {
      for (final key in spaceAdjacencyKeys)
        if (prior?[key] is Iterable) ...(prior![key] as Iterable).whereType<String>(),
    };
    return [
      ...spaceDetailFields([
      for (final space in _allSpaces)
        if (space.id != id && _spaces.containsKey(space.id))
          if (!isExcludedSpace(_spaceDetails[space.id])) space
          else if (referenced.contains(space.id))
            TaxonomyChoice(space.id, '${space.label} (excluded)'),
      ]).where((field) => !(_g1Cad || _stackedCad) || field.id != 'floor_level'),
      if (_g1Cad) dwellingRoomLevel,
      if (_stackedCad) stackedHomeLevel,
      if ((_enclosedCad || _clinicCad || _officeCad || _schoolCad || _libraryCad || _mixedHomeCad || _g1Cad || _hostelCad) && !(_schoolCad && id=='playground')) cadWindowField,
      if (_clinicCad) clinicRoomRoute,
    ];
  }

  Future<void> _editSpace(TaxonomyChoice space) async {
    final details = await showDialog<Map<String, Object>>(context: context,
      builder: (_) => SpaceRequirementsDialog(title: space.label,
        fields: _spaceSchema(space.id), values: _spaceDetails[space.id] ?? const {}),
    );
    if (details != null && mounted) setState(() {
      _spaceDetails[space.id] = details;
      _sectionError = null;
    });
  }

  Widget _fieldPanel(List<RequirementField> fields, {bool facility = false}) {
    final values = facility ? _facilityAnswers : _answers;
    return RequirementFields(fields: fields, values: values,
      onChanged: (id, value) {
        if (value == null) { values.remove(id); } else { values[id] = value; }
        setState(() => _sectionError = null);
      },
      onChoiceChanged: () => setState(() {}),
    );
  }

  Widget _section(String introduction, List<RequirementField> fields) => Form(
    key: _sectionForms[_step],
    child: _selectionList(introduction, [_fieldPanel(fields)]),
  );

  Widget _buildProjectInfo() => Form(
    key: _sectionForms[_step],
    child: _selectionList('Identify the project and its scope. Leave unknown information blank.', [
      TextFormField(
        controller: _name,
        decoration: const InputDecoration(labelText: 'Project name (required)'),
        validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a project name.' : null,
      ),
      const SizedBox(height: 12),
      _dropdown('Project action (optional)', _actionId, projectActions, (value) => setState(() => _actionId = value)),
      const SizedBox(height: 12),
      _dropdown('Project stage (optional)', _stageId, projectStages, (value) => setState(() => _stageId = value)),
      const SizedBox(height: 12),
      _fieldPanel(_infoSchema),
    ]),
  );

  Widget _buildSite() => Form(
    key: _sectionForms[_step],
    child: _selectionList(_underpassCad ? 'Record projected controls, walkway and soffit profiles, and clear widths.' : _steppedWallCad ? 'Record wall controls, proposed ground levels and stepped base/top levels.' : _streetLightCad ? 'Record projected baseline, fixed pole limits, spacing range and any no-pole windows.' : _ductBankCad ? 'Record projected controls, levels and measured crossing envelopes.' : _refugeCrossingCad ? 'Record the median centreline, crossing locations, widths and roadside landing depths.' : _cycleCrossingCad ? 'Record the surveyed road edge, roadside limits and driveway windows.' : _promenadeCad ? 'Record the projected baseline, shoreline and inland limits, and lookout pads.' : _railPlatformCad ? 'Record the surveyed track controls and platform level samples.' : _footbridgeCad ? 'Record surveyed tie-ins, channel, deck and reference water level.' : _busLaybyCad ? 'Record the surveyed road edge, bay and passenger space dimensions.' : _openDrainCad ? 'Record the ends of the open drain, section geometry and available corridor.' : _culvertCad ? 'Record the culvert end survey, ground levels and road crossing.' : _stormwaterCad ? 'Record the surveyed gravity-run nodes, cover and fall requirements.' : _earthworkCad ? 'Record surveyed and proposed sections at two or more matching stations.' : _corridorSectionCad ? 'Record a transverse ground and design section against one benchmark.' : _longProfileCad ? 'Record the surveyed ground and proposed levels against the same benchmark.' : _junctionCad ? 'Record your junction survey controls and measured widths and radii.' : _linearSite ? 'Record alignment and corridor data from your survey.' : 'Record measured plot data and site conditions.', [
      if (!_linearSite && !_vastu && !_home && !_enclosedCad && !_warehouseCad && !_crossDockCad && !_clinicCad && !_retailCad && !_schoolCad && !_officeCad && !_diningCad && !_cattleCad && !_packhouseCad && !_libraryCad && !_assemblyCad && !_badmintonCad && !_hostelCad && !_greenhouseCad && !_sharedCoreCad && !_inpatientWardCad && !_truckSweepCad && !_pairedApartmentCad && !_solarCad && !_basinCad && !_evHubCad && !_orchardCad && !_switchbackRampCad && !_teachingLabCad && !_hotelWingCad && !_basketballCad && !_rainwaterCad && !_lapPoolCad && !_publicMarketCad && !_raisedBedCad && !_amphitheatreCad && !_parkLoopCad && !_windrowYardCad && !_galleryPanelCad && !_angledParkingCad && !_coldRackCad && !_rainGardenCad && !_silageBunkerCad && !_aquaculturePondCad && !_dockLevellerCad && !_boulderingBayCad && !_weighbridgeCad && !_coolingLoopCad && !_boardwalkCad && !_circularClarifierCad && !_bladeLaydownCad && !_cricketNetsCad && !_skateTransitionCad && !_parkFenceCad && !_transformerBundCad && !_footballPitchCad && !_guyedMastCad && !_recyclingDropoffCad && !_spillwayCad && !_batteryYardCad && !_parkingRampCad && !_cinemaSeatingCad && !_switchbackStairCad && !_jumpRunwayCad && !_plazaPavingCad && !_shelterCanopyCad && !_publicToiletCad && !_vehicleLiftCad && !_athleticsTrackCad && !_playgroundCad && !_bicycleRackCad && !_memorialNicheCad && !_tennisCad && !_twinTankCad && !_mixedHomeCad) _facingPicker(),
      if (_rainGardenCad) const Text('Plot width is west–east and depth south–north. Setbacks use west as left and south as front. Locate the full maintenance envelope, not the rim or flat bed.')
      else if (_dockLevellerCad) const Text('The truck sits south of the hinge. Measure both bed heights and the hinge from the same datum; setbacks use west as left and south as front.')
      else if (_aquaculturePondCad) const Text('Use the level bottom as the datum for water and rim elevations. Locate the full service envelope; setbacks use west as left and south as front.')
      else if (_silageBunkerCad) const Text('Use the south opening as the floor datum. The floor rises north. Locate the full apron and service envelope; setbacks use west as left and south as front.')
      else if (_boulderingBayCad) const Text('Set hall height from the finished mat. The wall foot is toward the north; the lip, mat and access strip extend south. Setbacks use west as left and south as front.')
      else if (_weighbridgeCad) const Text('The truck faces north and chainage zero is the south approach start. Locate the full envelope including the east bypass. Setbacks use west as left and south as front.')
      else if (_coolingLoopCad) const Text('Tie-ins share a west–east baseline; the loop reaches north. Measure offsets to the full clearance envelope. Setbacks use west as left and south as front.')
      else if (_boardwalkCad) const Text('Use the same elevation datum for ground and deck. The south end of the deck is chainage zero. Setbacks use west as left and south as front.')
      else if (_circularClarifierCad) const Text('The level basin floor is elevation zero. Offsets locate the full service ring, not the basin centre; setbacks use west as left and south as front.')
      else if (_bladeLaydownCad) const Text('The root is south at chainage zero and the tip is north. Measure the full service envelope from the west and south plot edges.')
      else if (_cricketNetsCad) const Text('The bowler starts south of the pitch and the batter is north. Offsets locate the full lane bank and reserves. Setbacks use west as left and south as front.')
      else if (_skateTransitionCad) const Text('The flat run-in is south and the deck is north. Offsets locate the entire envelope including reserves. Setbacks use west as left and south as front.')
      else if (_parkFenceCad) const Text('Use corner post centres for fence spans and the west inside gate face for the opening offset. Plot offsets locate the full post footprint, not the corner centre.')
      else if (_transformerBundCad) const Text('The level bund floor is elevation zero. Locate the full envelope including the service reserve. Setbacks use west as left and south as front.')
      else if (_footballPitchCad) const Text('End lines are south and north. The setbacks use west as left and south as front. Locate the full pitch and run-off envelope.')
      else if (_guyedMastCad) const Text('The southwest plot corner is the plan origin; the mast base is elevation zero. Setbacks use west as left and south as front.')
      else if (_recyclingDropoffCad) const Text('The row is centred west to east between the side setbacks. Measure the drop-off envelope from the south plot edge. The public apron is south of the containers; the collection aisle is north.')
      else if (_spillwayCad) const Text('The inlet is south and the apron is north. The inlet bed is the level datum. Locate the full rectangle including the reserve; setbacks use west as left and south as front.')
      else if (_batteryYardCad) const Text('Rows run south to north. Locate the full yard including the outside-row and end reserves. Setbacks use west as left and south as front.')
      else if (_parkingRampCad) const Text('The ramp rises south to north. Measure soffit stations from the start of the lower landing, which is the elevation zero. Setbacks use west as left and south as front; locate the full ramp envelope including both edge reserves.')
      else if (_cinemaSeatingCad) const Text('Locate the clear hall rectangle. The screen is south and the flexible bays are north. Plot width is west–east; setbacks use west as left and south as front.')
      else if (_switchbackStairCad) const Text('Locate the full stair envelope. The west flight rises north to the shared landing; the east flight returns south. Setbacks use west as left and south as front.')
      else if (_jumpRunwayCad) const Text('The runway runs south to north, with sand at the north end. Plot width is west–east. Locate the full reserve envelope; west is left and south is front for setbacks.')
      else if (_plazaPavingCad) const Text('Plot width is west–east and depth south–north. Setbacks use west as left and south as front. The piece dimensions exclude joints.')
      else if (_shelterCanopyCad) const Text('Plot width is west–east and depth south–north. The roof falls from west to east. Enter both eave levels above the same level-grade datum; setbacks use west as left and south as front.')
      else if (_publicToiletCad) const Text('Plot width is west–east and depth south–north. Doorways face the south gallery. Fixture offsets are from the inside southwest corner of each room; setbacks use west as left and south as front.')
      else if (_vehicleLiftCad) const Text('Plot width is west–east and depth south–north. Workshop doors face the south apron. Setbacks use west as left and south as front.')
      else if (_athleticsTrackCad) const Text('Plot width is west–east and depth south–north. The track straights run north–south. Measure the envelope from the west and south plot edges; setbacks use west as left and south as front.')
      else if (_playgroundCad) const Text('Plot width is west–east and depth south–north. Equipment offsets locate its southwest corner from the plot southwest corner. Enter only clearance dimensions you have verified for the equipment; no safety values are assumed.')
      else if (_bicycleRackCad) const Text('Plot width is west–east and depth south–north. The aisle runs north–south. Setbacks use west as left and south as front.')
      else if (_memorialNicheCad) const Text('Plot width is west–east and depth south–north. The panel row runs west–east and the single-face option opens south. Measure offsets from the southwest plot corner.')
      else if (_tennisCad) const Text('Plot width is west–east and depth south–north. Courts run north–south; measure the court bank offsets from the west and south plot edges.')
      else if (_twinTankCad) const Text('Plot width is west–east and depth south–north. Measure service offsets from the southwest plot corner; all cell levels are above one common tank floor.')
      else if (_coldRackCad) const Text('Plot width is west–east and depth south–north. Racks run north–south and the entrance is on the south wall. Setbacks use south as front and west as left.')
      else if (_angledParkingCad) const Text('Plot width is west–east and depth south–north. The through aisle runs from south entry to north exit. Setbacks use south as front and west as left.')
      else if (_galleryPanelCad) const Text('Plot width is west–east and depth south–north. The entrance is on the south wall. Setbacks use south as front and west as left.')
      else if (_windrowYardCad) const Text('Plot width is west–east and depth south–north. Windrows run north–south. Setbacks use south as front and west as left.')
      else if (_parkLoopCad) const Text('Plot width is west–east and depth south–north. The approach comes from the south edge. Setbacks use south as front and west as left.')
      else if (_amphitheatreCad) const Text('Plot width is west–east and depth south–north, with stage at the south. Setbacks use south as front and west as left.')
      else if (_raisedBedCad) const Text('Plot width is west–east and depth south–north. Setbacks use south as front and west as left. Measure garden offsets from the southwest plot corner.')
      else if (_publicMarketCad) const Text('Measure plot width along the selected frontage and depth inward. Left and right are as seen from the frontage, looking into the plot.')
      else if (_lapPoolCad) const Text('Plot width is west–east and depth south–north, with the shallow end to the south. Setbacks use south as front and west as left.')
      else if (_rainwaterCad) const Text('Plot width is west–east and depth south–north. Setbacks use south as front and west as left. Roof dimensions are horizontal, not measured along the slope.')
      else if (_orchardCad) const Text('Plot width is west–east and depth is south–north. Setbacks use south as front and west as left. Measure exclusions from the southwest plot corner.')
      else if (_basinCad) const Text('Plot width is west–east and depth is south–north. Setbacks use south as front and west as left. Use the same level datum for the floor, normal pool, design water and crest.')
      else if (_refugeCrossingCad) const Text('Left and right are as seen looking from A to B. Enter each crossing centre chainage from A. Model constant surveyed widths and leave the clear path and roadside landings unobstructed.')
      else if (_cycleCrossingCad) const Text('Measure chainage from road edge point A toward B. Positive roadside offsets are perpendicular to that edge on the selected side. The first and last roadside limits define the track ends.')
      else if (_promenadeCad) const Text('Measure chainage from A toward B. Offsets are perpendicular to the baseline and increase landward. The first and last limit samples define the path ends.')
      else if (_underpassCad) const Text('Use one elevation datum. Walkway stations include both uncovered approaches. The first and last soffit samples are the two portals.')
      else if (_steppedWallCad) const Text('Use one common elevation datum. The first and last ground samples define the wall span. Each run starts at the previous run end; the first uses the first ground station.')
      else if (_streetLightCad) const Text('Left and right are as seen from A toward B. Measure all chainages from A. Pole centres may not lie inside or touch a no-pole window.')
      else if (_ductBankCad) const Text('Use one elevation datum. First and last level samples define the run. Enter existing lower and upper levels at each recorded crossing station.')
      else if (_railPlatformCad) const Text('Measure chainage along the straight track from A toward B. First and last level samples define the platform ends. Use one elevation datum for rail and platform.')
      else if (_footbridgeCad) const Text('Measure chainage from tie-in A. Channel width and deck-end bank gaps are perpendicular to the channel. Use the same elevation datum for the tie-ins, deck and reference water level.')
      else if (_culvertCad) const Text('Measure chainage along the barrel from its inlet. Enter the straight road bearing from grid north, and road width perpendicular to its own axis.')
      else if (_busLaybyCad) const Text('Enter the two road-edge points in the direction of travel. Chainage starts at the first point. Available roadside width is measured perpendicular from the road edge on the chosen side.')
      else if (_openDrainCad) const Text('Enter projected metre coordinates and a common invert datum. Looking downstream, measure each corridor limit perpendicular from the bottom centreline.')
      else if (_stormwaterCad) const Text('Enter upstream to downstream. Use projected metre coordinates and ground/invert levels on one datum. Intermediate ground samples use cumulative plan distance from the first node.')
      else if (_earthworkCad) const Text('Group both lists by increasing chainage, with offsets increasing from negative left to positive right within each station. Use the same station set and level datum for both lists.')
      else if (_corridorSectionCad) const Text('Looking toward increasing chainage: left is negative, centreline is zero and right is positive. Use increasing offsets; surveyed ground must cover the full proposed width.')
      else if (_longProfileCad) const Text('Use increasing metre chainages in both lists. Proposed endpoints must match the survey extent; give zero curve length at the ends or at a straight grade break.')
      else if (_crossJunctionCad) const Text('Enter five projected coordinate pairs: A; J; B; C; D. A/B and C/D each lie on opposite sides of J. The two axes may meet at a skew angle.')
      else if (_junctionCad) const Text('Enter four projected coordinate pairs in A; J; B; C order. A and B are opposite ends of the straight main tangent; C is the perpendicular branch end.')
      else if (_circularCorridor) const Text('Enter start, tangent intersection points and end in travel order. Supply one radius per intermediate point; route length must include arcs, not run through the intersection points.')
      else if (_surveyCorridorCad) const Text('Paste projected metre coordinates (not latitude/longitude) in travel order. ROW is constant and centred on the supplied axis; any unallocated width stays on the right.'),
      _fieldPanel(_siteSchema),
    ]),
  );

  Widget _buildFacility() => Form(
    key: _sectionForms[_step],
    child: _selectionList('Provide capacities and requirements for ${_type!.label}. Do not enter estimated constraints as verified data.', [
      _fieldPanel(_facilitySchema.where((field) => !_essential.any((early) => early.id == field.id)).toList(), facility: true),
      const Divider(),
      _fieldPanel(_operationalSchema),
    ]),
  );

  Widget _dimension(TextEditingController controller, String label) => TextFormField(
        key: ValueKey(label),
        controller: controller,
        decoration: InputDecoration(labelText: '$label (required)'),
        onChanged: (_) => setState(() => _sectionError = null),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (input) {
          if ((input ?? '').trim().isEmpty) return 'Enter the measured dimension.';
          final number = double.tryParse(input!.trim());
          final width = _measuredFeet(_width);
          final depth = _shapeId == 'square' ? width : _measuredFeet(_depth);
          if (width != null && depth != null && !(width * depth).isFinite) {
            return 'Enter dimensions with a valid plot area.';
          }
          return number != null && number.isFinite && number > 0 && (number * 304.8).isFinite
              ? null : 'Enter a positive dimension in $_plotUnit.';
        },
      );

  // Use a distinct sentinel to let a user clear an optional field.
  Widget _dropdown(String label, String? selected, List<TaxonomyChoice> options,
      ValueChanged<String?> onChanged, {bool required = false, bool Function(TaxonomyChoice)? available}) {
    final current = taxonomyChoice(options, selected)?.id ?? '';
    return DropdownButtonFormField<String>(
      key: ValueKey(label),
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('Not specified')),
        for (final option in options)
          DropdownMenuItem(value: option.id, enabled: available?.call(option) ?? true,
            child: Text(available?.call(option) == false ? '${option.label} — not enough area' : option.label, overflow: TextOverflow.ellipsis)),
      ],
      validator: required ? (value) => value == null || value.isEmpty ? 'Select an option.' : null : null,
      onChanged: (value) => onChanged(value == '' ? null : value),
    );
  }

  Widget _buildReview() {
    final width = _isRectangular ? _width.text.trim() : '';
    final depth = _isRectangular ? _depth.text.trim() : '';
    final pending = [
      if (['city', 'address'].every((key) => _answers[key]?.toString().trim().isNotEmpty != true)) 'location',
      if (_linearSite ? alignmentFields.every((f) => f.normalized(_answers[f.id]) == null) : width.isEmpty && _answers['survey_boundary']?.toString().trim().isNotEmpty != true) 'measured site data',
      if (!_linearSite && !_rainGardenCad && !_silageBunkerCad && !_aquaculturePondCad && !_dockLevellerCad && !_boulderingBayCad && !_weighbridgeCad && !_coolingLoopCad && !_boardwalkCad && !_circularClarifierCad && !_bladeLaydownCad && !_cricketNetsCad && !_skateTransitionCad && !_parkFenceCad && !_transformerBundCad && !_footballPitchCad && !_guyedMastCad && !_recyclingDropoffCad && !_spillwayCad && !_batteryYardCad && !_parkingRampCad && !_cinemaSeatingCad && !_switchbackStairCad && !_jumpRunwayCad && !_plazaPavingCad && !_shelterCanopyCad && !_publicToiletCad && !_vehicleLiftCad && !_athleticsTrackCad && !_playgroundCad && !_bicycleRackCad && !_memorialNicheCad && !_tennisCad && (_facing == null || _facing == 'Not decided')) 'orientation',
      if (_answers['rule_status'] != 'reference_provided') 'local rule reference',
      if (_answers['jurisdiction']?.toString().trim().isNotEmpty != true) 'jurisdiction',
      if (!_rainGardenCad && !_silageBunkerCad && !_aquaculturePondCad && !_dockLevellerCad && !_boulderingBayCad && !_weighbridgeCad && !_coolingLoopCad && !_boardwalkCad && !_circularClarifierCad && !_bladeLaydownCad && !_cricketNetsCad && !_skateTransitionCad && !_parkFenceCad && !_transformerBundCad && !_footballPitchCad && !_guyedMastCad && !_recyclingDropoffCad && !_spillwayCad && !_batteryYardCad && !_parkingRampCad && !_cinemaSeatingCad && !_switchbackStairCad && !_jumpRunwayCad && !_plazaPavingCad && !_shelterCanopyCad && !_publicToiletCad && !_vehicleLiftCad && !_athleticsTrackCad && !_playgroundCad && !_bicycleRackCad && !_memorialNicheCad && !_tennisCad && activeSpaceQuantities(_spaces, _spaceDetails).isEmpty) 'space program',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_name.text.trim(), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('User-provided brief • Not verified'),
        _reviewRow('Project action', taxonomyChoice(projectActions, _actionId)?.label),
        _reviewRow('Project stage', taxonomyChoice(projectStages, _stageId)?.label),
        _reviewRow(_program.configurationLabel, taxonomyChoice(_program.configurations, _configurationId)?.label),
        if (_configurationId == null && _currentScenario?.configuration != null)
          _reviewRow('Layout label (derived from bedroom count)', _currentScenario!.configuration!.label),
        if (!_linearSite) _reviewRow('Plot geometry', taxonomyChoice(plotShapes, _shapeId)?.label),
        if (!_linearSite && _shapeId == 'square') ...[
          _reviewRow('Measured plot side', width.isEmpty ? null : '$width $_plotUnit'),
          if (width.isNotEmpty) _reviewRow('Plot footprint (derived from square)', '$width × $width $_plotUnit'),
        ] else if (!_linearSite)
          _reviewRow('Plot dimensions', width.isEmpty || depth.isEmpty ? null : '$width × $depth $_plotUnit'),
        if (!_linearSite) _reviewRow('Site orientation', _facing == 'Not decided' ? 'Unknown / survey required' : _facing),
        if (!_linearSite) _reviewRow('Floors above grade', _floors.text.trim()),
        if (!_linearSite) _reviewRow('Parking', _parking?.label),
        const Divider(),
        if (_spaces.isEmpty) _reviewRow('Space / room program', 'No spaces selected'),
        for (final space in _allSpaces)
          if (_spaces.containsKey(space.id)) ...[
            _reviewRow(space.label, isExcludedSpace(_spaceDetails[space.id]) ? 'Excluded from layout' : 'Quantity: ${_spaces[space.id]}'),
            ..._reviewAnswers(_spaceSchema(space.id), _spaceDetails[space.id] ?? const {}),
          ],
        const Divider(),
        ..._reviewAnswers(_generalSchema, _answers),
        ..._reviewAnswers(_facilitySchema, _facilityAnswers),
        if (pending.isNotEmpty) _reviewRow('Still needed before planning', pending.join(', ')),
        const SizedBox(height: 12),
        const Text('Survey and local rules have not been verified. Specialist review may be required.'),
        const SizedBox(height: 8),
        if (_sharedCoreCad)
          const Text('Saving checks the shared entrance, both floor wings and the measured stair and shaft alignment. Failed fit blocks both DXF sheets.')
        else if (_stackedCad)
          const Text('Saving checks ground shop fixtures, separate entry walks, first-floor dwelling and the private stair/landing alignment. Non-fitting requests do not fall back to zoning.')
        else if (_mixedCad)
          const Text('Saving checks the shop fixtures, measured dwelling rooms, solid divider and independent walks. A blocked plan does not fall back to a different drawing.')
        else if (_junctionCad)
          const Text('Saving checks the surveyed junction geometry, curb-return arcs and measured right-of-way. A failed fit does not fall back to corridor zoning.')
        else if (_refugeCrossingCad)
          const Text('Saving checks stagger, clear widths, median side reserves and measured landing depths. It does not assess vehicle traffic, signals, curb ramps or accessibility.')
        else if (_cycleCrossingCad)
          const Text('Saving checks measured roadside fit and uninterrupted separator between driveways. It does not assess traffic safety, sight distance or vehicle manoeuvres.')
        else if (_promenadeCad)
          const Text('Saving checks the path and pad gaps at equal chainages. No shoreline setbacks, flood levels or coastal safety are verified.')
        else if (_underpassCad)
          const Text('Saving checks corridor fit, the submitted grade limit and vertical headroom along the centreline only. No drainage, structure or accessibility check is made.')
        else if (_steppedWallCad)
          const Text('Saving checks base depth, top margin and exposed height at the ground samples and both sides of each step. It does not design a retaining structure.')
        else if (_streetLightCad)
          const Text('Saving searches for the fewest evenly spaced pole centres between the fixed ends without entering the submitted no-pole windows. This is not a lighting or installation design.')
        else if (_ductBankCad)
          const Text('Saving checks cover against the supplied centreline ground levels and vertical clearance at the recorded crossing stations only. It does not validate excavation or utility safety.')
        else if (_railPlatformCad)
          const Text('Saving checks the submitted static offset, clear width, signed edge-level band and longitudinal grade. No train or boarding clearance is verified.')
        else if (_footbridgeCad)
          const Text('Saving checks both full-width deck ends against the skewed channel, approach grade and clearance above the supplied reference water level. No structure or flood safety is assessed.')
        else if (_culvertCad)
          const Text('Saving checks the crossed road band, full end-face fit, longitudinal fall and centreline cover. Failed checks block both DXFs.')
        else if (_busLaybyCad)
          const Text('Saving checks both tapers, the rectangular berth run, clear shelter connections and roadside width. Vehicle tracking and road safety are not checked.')
        else if (_openDrainCad)
          const Text('Saving checks downstream fall, geometric freeboard and both corridor limits. A failed check blocks all three DXFs.')
        else if (_stormwaterCad)
          const Text('Saving checks plan intersections, downstream fall and cover at supplied surface points. Failed fit blocks both plan and profile DXF.')
        else if (_earthworkCad)
          const Text('Saving checks every station and estimates cut and fill by average-end area between surveyed stations only. Any invalid section blocks the DXF and CSV.')
        else if (_corridorSectionCad)
          const Text('Saving checks survey coverage and calculates separate cut and fill areas within the supplied design extents. Invalid sections do not fall back to plan-view zoning.')
        else if (_longProfileCad)
          const Text('Saving checks chainage coverage and vertical-curve fit. Existing and proposed levels are shown separately; an invalid profile does not fall back to plan-view zoning.')
        else if (_surveyCorridorCad)
          const Text('Saving checks the surveyed length, chainages and offset band geometry. Conflicting geometry blocks DXF rather than generating straight zoning.')
        else if (_packhouseCad)
          const Text('Saving checks exact stage lengths, transfer openings, both handling pads and the continuous front-to-rear goods lane. Invalid layouts do not fall back to zoning.')
        else if (_pairedApartmentCad)
          const Text('Saving checks the shared lobby, independent flat doors, wet rooms, kitchen clearances and windows. Failed fit blocks DXF.')
        else if (_rainGardenCad)
          const Text('Saving checks the full footprint, maintenance reserve and surface ponding target. It does not count pore storage or model runoff, infiltration or drawdown.')
        else if (_dockLevellerCad)
          const Text('Saving checks static deck grade, minimum lip overlap, joint clearance, usable landing depth and plot fit. It does not specify equipment or validate operation.')
        else if (_aquaculturePondCad)
          const Text('Saving checks geometric water volume, freeboard, side slope and plot fit. It does not verify bank stability, liners, drainage or operations.')
        else if (_silageBunkerCad)
          const Text('Saving checks geometric fill, freeboard, grades and plot fit. It does not verify storage mass, stability, drainage or operations.')
        else if (_boulderingBayCad)
          const Text('Saving checks wall angle, overhead clearance, mat projection and hall fit. It does not verify fall clearance, mats, anchors or safety compliance.')
        else if (_weighbridgeCad)
          const Text('Saving checks a static truck stop range, side clearance and plot fit. It does not check weighing accuracy, vehicle turning or traffic operations.')
        else if (_coolingLoopCad)
          const Text('Saving checks tangent geometry, radius and clearance fit. It does not check thermal movement, pipe stress, hydraulics or installation.')
        else if (_boardwalkCad)
          const Text('Saving checks centreline ground clearance continuously along the deck, support geometry and plot fit against submitted limits. It does not check loads, access or flood levels.')
        else if (_circularClarifierCad)
          const Text('Saving checks plot fit, level relationships, freeboard and geometric settling area. It does not verify treatment performance or hardware.')
        else if (_bladeLaydownCad)
          const Text('Saving checks both complete pad reserves, their geometric margins and site fit. It does not verify structural supports, lifting or supplier limits.')
        else if (_cricketNetsCad)
          const Text('Saving checks crease set-out, run-up, rear clearance and plot fit. It does not check netting, structures, ball containment or rules compliance.')
        else if (_skateTransitionCad)
          const Text('Saving checks the geometric curve, lip angle and plot fit against submitted limits. It does not check coping or skate safety.')
        else if (_parkFenceCad)
          const Text('Saving checks equal panel spans per run, the gate opening and plot fit. It does not check footings, hardware, gate swing or enclosure safety.')
        else if (_transformerBundCad)
          const Text('Saving checks plinth clearance, freeboard and net geometric containment against submitted limits. It does not assess spill demand, drainage or compliance.')
        else if (_footballPitchCad)
          const Text('Saving checks the measured marking geometry and the full run-off against the supplied limits. It does not check sports rules, pitch safety or approvals.')
        else if (_guyedMastCad)
          const Text('Saving checks reserve fit and overlaps, guy angles and anchor azimuth gaps. It does not check cable loading, ground clearance, foundation design or permits.')
        else if (_recyclingDropoffCad)
          const Text('Saving checks the required bay count and the two clear strips against the plot and submitted limits. It does not check vehicle access, turning or wayfinding.')
        else if (_spillwayCad)
          const Text('Saving checks plot fit, crest length, grades and plan tapers against supplied limits. It does not assess hydraulic performance or flood risk.')
        else if (_batteryYardCad)
          const Text('Saving checks the measured yard against submitted clearances and plot limits. It does not assess fire separation, emergency vehicle access or electrical design.')
        else if (_parkingRampCad)
          const Text('Saving checks submitted grade and grade-change limits, vertical centreline headroom and footprint. It does not check vehicle breakover, swept height or clearance off centreline.')
        else if (_cinemaSeatingCad)
          const Text('Saving checks measured rows, aisles, rear bays and the hall fit. It counts fixed seats separately from flexible bays and does not assess egress or accessibility.')
        else if (_switchbackStairCad)
          const Text('Saving checks the uniform riser range, landing depths and full plot fit. The plan does not check handrails, guards, accessibility or stairs for egress.')
        else if (_jumpRunwayCad)
          const Text('Saving checks the runway and sand envelope, clear approach to each take-off line and the submitted minimum distance to the far sand edge for each event.')
        else if (_plazaPavingCad)
          const Text('Saving checks the paving footprint and two matching border cuts per axis, allowing a 1 mm rounding difference. On an exact fit there are no border cuts. Counts are installed pieces, not purchase quantities.')
        else if (_shelterCanopyCad)
          const Text('Saving checks post and roof extents, walking strip width and headroom, and the full roof projection against setbacks and any submitted height limit.')
        else if (_publicToiletCad)
          const Text('Saving checks the block and gallery against setbacks and each fixture against the submitted clear entry strip and manoeuvring circle. No compliance is verified.')
        else if (_vehicleLiftCad)
          const Text('Saving checks doorway, lift-post and raised-vehicle clearances and the workshop-plus-apron footprint. No operation or installation is verified.')
        else if (_athleticsTrackCad)
          const Text('Saving checks the run-off against setbacks and lane 1 against the supplied lap target and tolerance. Staggers apply only to one geometric lap, not a competition marking plan.')
        else if (_playgroundCad)
          const Text('Saving checks submitted equipment zones for setback, path and zone conflicts. It does not determine safety clearances or certify the installation.')
        else if (_bicycleRackCad)
          const Text('Saving checks stand spacing with both positions loaded, total capacity and the fit of the full layout within supplied setbacks. No manoeuvre is simulated.')
        else if (_memorialNicheCad)
          const Text('Saving checks the complete layout against setbacks, the panel height against any supplied limit and the nominal count against the requested target.')
        else if (_tennisCad)
          const Text('Saving checks marking and net-post geometry and whether the whole court bank, including run-off and gaps, fits within the setbacks.')
        else if (_twinTankCad)
          const Text('Saving checks service clearance, both operating level ranges and total and single-cell usable volume. Independent operation is assumed, not designed.')
        else if (_coldRackCad)
          const Text('Saving checks pallet fit, loaded height, the chamber envelope and any Facility pallet-position target. The calculated count is nominal, not a rack load rating.')
        else if (_angledParkingCad)
          const Text('Saving checks angled static fit, end and side reserves, and supplied setbacks. It does not check movements or external access.')
        else if (_galleryPanelCad)
          const Text('Saving checks the viewing and through-clear widths, entrance, setbacks and supplied FSI/coverage limits. Exports show hanging space, not approved occupancy.')
        else if (_windrowYardCad)
          const Text('Saving checks pile geometry, aisles, headlands, setbacks and your geometric volume target. This is not a process capacity estimate.')
        else if (_parkLoopCad)
          const Text('Saving checks the path radius, entry opening, exact lawn corner clearance and supplied setbacks. The lap length is measured on the centreline.')
        else if (_amphitheatreCad)
          const Text('Saving checks plot fit and the supplied centreline sightline clearance. Nominal places are not an approved occupancy count.')
        else if (_raisedBedCad)
          const Text('Saving checks the bed interior, fill depth, supplied horizontal reach and garden path envelope. Failed fit blocks both DXF and CSV.')
        else if (_publicMarketCad)
          const Text('Saving checks stall openings, the approach width and whether the full circulation envelope fits the plot setbacks. Export is a concept layout, not an egress assessment.')
        else if (_lapPoolCad)
          const Text('Saving checks plot fit, the shallow and deep flats, and the supplied transition grade limit. This is geometry only, not pool safety approval.')
        else if (_rainwaterCad)
          const Text('Saving checks roof and tank service geometry, setbacks and your usable capacity target. The rainfall estimate assumes the tanks start empty.')
        else if (_basketballCad)
          const Text('Saving checks the marking geometry, the measured run-off envelope and plot setbacks. Failed fit blocks DXF.')
        else if (_hotelWingCad)
          const Text('Saving checks both guestroom banks, the shared corridor, bed clearances, openings and site fit. Failed fit blocks DXF.')
        else if (_teachingLabCad)
          const Text('Saving checks both bench banks, clear routes, seated-use depth and the enclosed prep room. Invalid fit blocks the DXF.')
        else if (_switchbackRampCad)
          const Text('Saving checks flight slope and rise, turning space at all landings, and footprint setbacks. Failed fit blocks the plan and profile DXFs.')
        else if (_orchardCad)
          const Text('Saving checks reserved canopies, the clear access loop, exclusions and plot setbacks. A failed fit blocks DXF and coordinate CSV.')
        else if (_evHubCad)
          const Text('Saving checks the site footprint, supplied setbacks, charger pads and clear connections beside each pad and transfer bay. Failed fit blocks DXF.')
        else if (_basinCad)
          const Text('Saving checks the inner crest footprint, vertical freeboard and active storage above normal pool. A failed check blocks both DXFs.')
        else if (_solarCad)
          const Text('Saving checks perimeter clearances, optional exclusions, row maintenance gap and shade clearance at the supplied sun angle. A failed fit blocks DXF.')
        else if (_truckSweepCad)
          const Text('Saving checks the clearance envelope continuously along the approach, the 90-degree turn and the straight docking leg. Collisions block DXF.')
        else if (_inpatientWardCad)
          const Text('Saving checks both bed banks, the nursing counter and the clear route from the entrance. Failed fit blocks DXF without falling back to zoning.')
        else if (_greenhouseCad)
          const Text('Saving checks the measured greenhouse, bench banks, door and clear aisles. If they do not fit, DXF is blocked rather than replaced with generic zoning.')
        else if (_hostelCad)
          const Text('Saving checks bedroom counts, bed and locker footprints, door-aligned aisles and the shared passage. A failed fit blocks DXF without generating another drawing.')
        else if (_badmintonCad)
          const Text('Saving checks measured court lines, run-offs, player access and optional separate spectator entry and seating. Failed fit does not fall back to zoning.')
        else if (_libraryCad)
          const Text('Saving checks the quiet threshold, shelf ranges and desk count against their measured rooms and aisles. Non-fitting requests do not fall back to zoning.')
        else if (_assemblyCad)
          const Text('Saving checks the staged material lane and both pads, independent staff access, and measured bench footprints and clearances. No fallback on failed fit.')
        else if (_cattleCad)
          const Text('Saving checks measured pen count, clear lanes, trough and gate clearances, and both rear pads. No fallback to zoning on failed fit.')
        else if (_diningCad)
          const Text('Saving checks customer aisle and seating fit, the two separate service hatches and both rear pads. Failed layouts do not fall back to zoning.')
        else if (_officeCad)
          const Text('Saving checks the visitor/staff doorway split, measured desk count, chair clearances and connected aisles. A blocked layout does not fall back to zoning.')
        else if (_schoolCad)
          Text(_schoolPlayground
            ? 'Saving checks the visitor lobby, student passage, rear door and entire fenced playground fit. A blocked layout does not fall back to zoning.'
            : 'Saving checks that the administration door opens into the visitor lobby and classroom and support-room doors open beyond the internal threshold. Invalid layouts do not fall back to zoning.')
        else if (_g1Cad)
          const Text('Saving attempts two measured floor plans with an aligned straight indoor stair. If requested, open parking or a separate open terrace sheet is also drawn. Unsupported or non-fitting layouts do not fall back to zoning.')
        else if (_retailCad)
          const Text('Saving checks the measured shell, sales fixtures, customer aisles and stock access. A blocked drawing does not fall back to zoning.')
        else if (_clinicCad)
          const Text('Saving checks and draws independent patient and staff/service wings. No internal transfer or specialist clinical approval is inferred.')
        else if (_crossDockCad)
          const Text('Saving checks both opposing dock banks, staging strips, transfer lane and staff approach. No vehicle swept path is calculated.')
        else if (_warehouseCad)
          const Text('Saving checks the measured warehouse shell, loading bays and separate approach routes. A blocked drawing will not fall back to zoning.')
        else if (_enclosedCad)
          const Text('Saving attempts a measured floor plan with walls, doors and connected passage. A blocked drawing will not fall back to zoning.')
        else if (_answers['cad_output'] != 'zones' && _canAutoPlan && _needsScenarioInputs)
          const Text('Input needed for CAD: confirm the floor count and parking on the facility page.')
        else if (_answers['cad_output'] != 'zones' && _canAutoPlan && _currentVariant?.generator == null)
          const Text('Brief only for this floor and parking variant. Saving will explain why a drawing could not be generated.')
        else if (_answers['cad_output'] != 'zones' && _canAutoPlan)
          const Text('Saving checks your requirements and automatically opens the CAD concept if they fit. If they do not, your brief is kept as entered and the app explains why no drawing was created.')
        else
          const Text('Saving attempts a measured concept zoning sheet. Enter clear width and length for each selected space. This is not a detailed architectural drawing.'),
        if (_canAutoPlan) const Text('A generated drawing can be saved as DXF. PDF is not available yet.'),
      ],
    );
  }

  Iterable<Widget> _reviewAnswers(List<RequirementField> fields, Map<String, Object> answers) sync* {
    for (final field in fields) {
      if (!field.applies(answers)) continue;
      final value = field.display(answers[field.id]);
      if (value != null) yield _reviewRow(field.label, value);
    }
  }

  Widget _reviewRow(String label, String? value) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(value == null || value.isEmpty ? 'Not provided' : value),
        dense: true,
      );
}
