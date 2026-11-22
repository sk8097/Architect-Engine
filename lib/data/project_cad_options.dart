import 'project_taxonomy.dart';
import 'project_requirements.dart';
import 'detailed_cad_fields.dart';
import 'warehouse_cad_fields.dart';
import 'solar_farm_fields.dart';
import 'detention_basin_fields.dart';
import 'ev_hub_fields.dart';
import 'orchard_cad_fields.dart';
import 'switchback_ramp_fields.dart';
import 'teaching_lab_fields.dart';
import 'hotel_wing_fields.dart';
import 'basketball_cad_fields.dart';
import 'rainwater_cad_fields.dart';
import 'lap_pool_cad_fields.dart';
import 'public_market_cad_fields.dart';
import 'raised_bed_cad_fields.dart';
import 'amphitheatre_cad_fields.dart';
import 'park_loop_cad_fields.dart';
import 'windrow_yard_cad_fields.dart';
import 'gallery_panel_cad_fields.dart';
import 'angled_parking_cad_fields.dart';
import 'cold_rack_cad_fields.dart';
import 'rain_garden_cad_fields.dart';
import 'facade_louvre_cad_fields.dart';
import 'typology_bay_cad_fields.dart';
import 'dock_leveller_cad_fields.dart';
import 'aquaculture_pond_cad_fields.dart';
import 'silage_bunker_cad_fields.dart';
import 'bouldering_bay_cad_fields.dart';
import 'weighbridge_cad_fields.dart';
import 'cooling_loop_cad_fields.dart';
import 'boardwalk_cad_fields.dart';
import 'circular_clarifier_cad_fields.dart';
import 'blade_laydown_cad_fields.dart';
import 'cricket_nets_cad_fields.dart';
import 'skate_transition_cad_fields.dart';
import 'park_fence_cad_fields.dart';
import 'transformer_bund_cad_fields.dart';
import 'football_pitch_cad_fields.dart';
import 'guyed_mast_cad_fields.dart';
import 'recycling_dropoff_cad_fields.dart';
import 'spillway_cad_fields.dart';
import 'battery_yard_cad_fields.dart';
import 'parking_ramp_cad_fields.dart';
import 'cinema_seating_cad_fields.dart';
import 'switchback_stair_cad_fields.dart';
import 'jump_runway_cad_fields.dart';
import 'plaza_paving_cad_fields.dart';
import 'shelter_canopy_cad_fields.dart';
import 'public_toilet_cad_fields.dart';
import 'vehicle_lift_cad_fields.dart';
import 'athletics_track_cad_fields.dart';
import 'playground_cad_fields.dart';
import 'bicycle_rack_cad_fields.dart';
import 'memorial_niche_cad_fields.dart';
import 'tennis_cad_fields.dart';
import 'twin_tank_cad_fields.dart';
import 'paired_apartment_fields.dart';
import 'cross_dock_cad_fields.dart';
import 'healthcare_cad_fields.dart';
import 'school_cad_fields.dart';
import 'office_cad_fields.dart';
import 'dining_cad_fields.dart';
import 'cattle_shed_cad_fields.dart';
import 'assembly_cad_fields.dart';
import 'library_cad_fields.dart';
import 'badminton_cad_fields.dart';
import 'hostel_cad_fields.dart';
import 'greenhouse_cad_fields.dart';
import 'shared_core_cad_fields.dart';
import 'inpatient_ward_cad_fields.dart';
import 'packhouse_cad_fields.dart';
import 'survey_corridor_fields.dart';
import 'stormwater_cad_fields.dart';
import 'bus_layby_cad_fields.dart';
import 'culvert_cad_fields.dart';
import 'refuge_crossing_cad_fields.dart';
import 'cycle_crossing_cad_fields.dart';
import 'promenade_cad_fields.dart';
import 'underpass_cad_fields.dart';
import 'stepped_wall_cad_fields.dart';
import 'street_light_cad_fields.dart';
import 'duct_bank_cad_fields.dart';
import 'rail_platform_cad_fields.dart';
import 'footbridge_cad_fields.dart';
import 't_junction_cad_fields.dart';
import 'retail_cad_fields.dart';
import 'mixed_retail_cad_fields.dart';
import 'dwelling_cad_fields.dart';

/// Shared source of truth for the Wizard picker and catalogue coverage.
/// Eligibility here only exposes a choice; it does not certify a valid fit.
class ProjectCadOptions {
  const ProjectCadOptions(this.category, this.group, this.type);
  final String? category, group, type;

  bool get warehouseEligible => category == 'industrial' && group == 'logistics' && warehouseLoadingTypes.contains(type);
  bool get crossDockEligible => category == 'industrial' && group == 'logistics' && crossDockTypes.contains(type);
  bool get pairedApartmentEligibleForType => pairedApartmentEligible(category,group,type);
  bool get rainGardenEligible => rainGardenCadEligible(category, group, type);
  bool get facadeLouvreEligible => facadeLouvreCadEligible(category, group, type);
  bool get typologyBayEligibleForType => typologyBayCadEligible(category, group, type);
  bool get dockLevellerEligible => dockLevellerCadEligible(category, group, type);
  bool get aquaculturePondEligible => aquaculturePondCadEligible(category, group, type);
  bool get silageBunkerEligible => silageBunkerCadEligible(category, group, type);
  bool get boulderingBayEligible => boulderingBayCadEligible(category, group, type);
  bool get weighbridgeEligible => weighbridgeCadEligible(category, group, type);
  bool get coolingLoopEligible => coolingLoopCadEligible(category, group, type);
  bool get boardwalkEligible => boardwalkCadEligible(category, group, type);
  bool get circularClarifierEligible => circularClarifierCadEligible(category, group, type);
  bool get bladeLaydownEligible => bladeLaydownCadEligible(category, group, type);
  bool get cricketNetsEligible => cricketNetsCadEligible(category, group, type);
  bool get skateTransitionEligible => skateTransitionCadEligible(category, group, type);
  bool get parkFenceEligible => parkFenceCadEligible(category, group, type);
  bool get transformerBundEligible => transformerBundCadEligible(category, group, type);
  bool get footballPitchEligible => footballPitchCadEligible(category, group, type);
  bool get guyedMastEligible => guyedMastCadEligible(category, group, type);
  bool get recyclingDropoffEligible => recyclingDropoffCadEligible(category, group, type);
  bool get spillwayEligible => spillwayCadEligible(category, group, type);
  bool get batteryYardEligible => batteryYardCadEligible(category, group, type);
  bool get parkingRampEligible => parkingRampCadEligible(category, group, type);
  bool get cinemaSeatingEligible => cinemaSeatingCadEligible(category, group, type);
  bool get switchbackStairEligible => switchbackStairCadEligible(category, group, type);
  bool get jumpRunwayEligible => jumpRunwayCadEligible(category, group, type);
  bool get plazaPavingEligible => plazaPavingCadEligible(category, group, type);
  bool get shelterCanopyEligible => shelterCanopyCadEligible(category, group, type);
  bool get publicToiletEligible => publicToiletCadEligible(category, group, type);
  bool get vehicleLiftEligible => vehicleLiftCadEligible(category, group, type);
  bool get athleticsTrackEligible => athleticsTrackCadEligible(category, group, type);
  bool get playgroundEligible => playgroundCadEligible(category, group, type);
  bool get bicycleRackEligible => bicycleRackCadEligible(category, group, type);
  bool get memorialNicheEligible => memorialNicheCadEligible(category, group, type);
  bool get tennisEligible => tennisCadEligible(category, group, type);
  bool get twinTankEligible => twinTankCadEligible(category, group, type);
  bool get coldRackEligible => coldRackCadEligible(category, group, type);
  bool get angledParkingEligible => angledParkingCadEligible(category, group, type);
  bool get galleryPanelEligible => galleryPanelCadEligible(category, group, type);
  bool get windrowYardEligible => windrowYardCadEligible(category, group, type);
  bool get parkLoopEligible => parkLoopCadEligible(category, group, type);
  bool get amphitheatreEligible => amphitheatreCadEligible(category, group, type);
  bool get raisedBedEligible => raisedBedCadEligible(category, group, type);
  bool get publicMarketEligible => publicMarketCadEligible(category, group, type);
  bool get lapPoolEligible => lapPoolCadEligible(category, group, type);
  bool get rainwaterEligible => rainwaterCadEligible(category, group, type);
  bool get basketballEligible => basketballCadEligible(category, group, type);
  bool get hotelWingEligibleForType => hotelWingEligible(category, group, type);
  bool get teachingLabEligibleForType => teachingLabEligible(category, group, type);
  bool get switchbackRampEligibleForType => switchbackRampEligible(category, group, type);
  bool get orchardEligible => orchardCadEligible(category, group, type);
  bool get evHubEligibleForType => evHubEligible(category, group, type);
  bool get basinEligible => detentionBasinEligible(category, group, type);
  bool get solarEligible => solarFarmEligible(category, group, type);
  bool get clinicEligible => category == 'institutional' && group == 'healthcare' && separatedClinicTypes.contains(type);
  bool get retailEligible => category == 'commercial' && group == 'retail' && retailFixtureTypes.contains(type);
  bool get g1Eligible => category == 'residential' && group == 'houses' && dwellingG1Types.contains(type);
  bool get inpatientWardEligibleForType => inpatientWardEligible(category, group, type);
  bool get sharedCoreEligible => sharedCoreCadEligible(category, group, type);
  bool get greenhouseEligible => greenhouseCadEligible(category, group, type);
  bool get hostelEligible => hostelCadEligible(category, group, type);
  bool get badmintonEligible => category=='institutional' && group=='sports' && badmintonCadTypes.contains(type);
  bool get libraryEligible => libraryCadEligible(category,group,type);
  bool get assemblyEligible => category=='industrial' && group=='manufacturing' && assemblyCadTypes.contains(type);
  bool get cattleEligible => category=='rural' && group=='farm' && cattleShedTypes.contains(type);
  bool get diningEligible => category=='commercial' && group=='food_service' && diningCadTypes.contains(type);
  bool get officeEligible => category == 'commercial' && group == 'office' && officeCadTypes.contains(type);
  bool get schoolEligible => category == 'institutional' && group == 'education' && schoolCadTypes.contains(type);
  bool get packhouseEligible => category == 'rural' && group == 'agro_processing' && packhouseCadTypes.contains(type);
  bool get cycleCrossingEligible => cycleCrossingCadEligible(category, group, type);
  bool get refugeCrossingEligible => refugeCrossingCadEligible(category, group, type);
  bool get promenadeEligible => promenadeCadEligible(category, group, type);
  bool get underpassEligible => underpassCadEligible(category, group, type);
  bool get steppedWallEligible => steppedWallCadEligible(category, group, type);
  bool get streetLightEligible => streetLightCadEligible(category, group, type);
  bool get ductBankEligible => ductBankCadEligible(category, group, type);
  bool get railPlatformEligible => railPlatformCadEligible(category, group, type);
  bool get footbridgeEligible => footbridgeCadEligible(category, group, type);
  bool get culvertEligible => culvertCadEligible(category, group, type);
  bool get stormwaterEligible => category == 'infrastructure' && group == 'water' && stormwaterCadTypes.contains(type);
  bool get busLaybyEligible => busLaybyCadEligible(category, group, type);
  bool get junctionEligible => category == 'infrastructure' && group == 'transport' && type == 'intersection';
  bool get surveyCorridorEligible => category == 'infrastructure' && group == 'transport' && surveyCorridorTypes.contains(type);
  bool get mixedEligible => category=='mixed_use' && group=='mixed_development' && type==mixedRetailCadType;

  RequirementField get corridorModeField => cycleCrossingEligible || refugeCrossingEligible
      ? surveyCorridorModeField(includeCycleCrossings: cycleCrossingEligible, includeRefugeCrossing: refugeCrossingEligible)
      : surveyCorridorMode;

  List<RequirementField> selectionFields({required bool linearSite}) => [
    if (surveyCorridorEligible) corridorModeField,
    if (junctionEligible) tJunctionCadMode,
    if (stormwaterEligible) stormwaterCadMode,
    if (culvertEligible) culvertCadMode,
    if (promenadeEligible) promenadeCadMode,
    if (underpassEligible) underpassCadMode,
    if (steppedWallEligible) steppedWallCadMode,
    if (streetLightEligible) streetLightCadMode,
    if (ductBankEligible) ductBankCadMode,
    if (railPlatformEligible) railPlatformCadMode,
    if (footbridgeEligible) footbridgeCadMode,
    if (busLaybyEligible) busLaybyCadMode,
    if (!linearSite) cadOutputOptions(
      warehouseLoading: warehouseEligible,
      clinicSeparated: clinicEligible,
      retailFixtures: retailEligible,
      dwellingG1: g1Eligible,
      schoolArrival: schoolEligible,
      packhouseFlow: packhouseEligible,
      mixedShopHome: mixedEligible,
      crossDock: crossDockEligible,
      officeWorkplace: officeEligible,
      diningService: diningEligible,
      cattleShed: cattleEligible,
      assembly: assemblyEligible,
      libraryReading: libraryEligible,
      badminton: badmintonEligible,
      hostel: hostelEligible,
      greenhouse: greenhouseEligible,
      sharedCore: sharedCoreEligible,
      inpatientWard: inpatientWardEligibleForType,
      truckSweep: warehouseEligible,
      pairedApartments: pairedApartmentEligibleForType,
      solarFarm: solarEligible,
      detentionBasin: basinEligible,
      evHub: evHubEligibleForType,
      orchard: orchardEligible,
      switchbackRamp: switchbackRampEligibleForType,
      teachingLab: teachingLabEligibleForType,
      hotelWing: hotelWingEligibleForType,
      basketball: basketballEligible,
      rainwater: rainwaterEligible,
      lapPool: lapPoolEligible,
      publicMarket: publicMarketEligible,
      raisedBeds: raisedBedEligible,
      amphitheatre: amphitheatreEligible,
      parkLoop: parkLoopEligible,
      windrowYard: windrowYardEligible,
      galleryPanels: galleryPanelEligible,
      angledParking: angledParkingEligible,
      coldRacks: coldRackEligible,
      twinTank: twinTankEligible,
      tennis: tennisEligible,
      memorialNiche: memorialNicheEligible,
      bicycleRack: bicycleRackEligible,
      playground: playgroundEligible,
      athleticsTrack: athleticsTrackEligible,
      vehicleLift: vehicleLiftEligible,
      publicToilet: publicToiletEligible,
      shelterCanopy: shelterCanopyEligible,
      plazaPaving: plazaPavingEligible,
      rainGarden: rainGardenEligible,
      jumpRunway: jumpRunwayEligible,
      switchbackStair: switchbackStairEligible,
      cinemaSeating: cinemaSeatingEligible,
      parkingRamp: parkingRampEligible,
      batteryYard: batteryYardEligible,
      spillway: spillwayEligible,
      recyclingDropoff: recyclingDropoffEligible,
      guyedMast: guyedMastEligible,
      footballPitch: footballPitchEligible,
      transformerBund: transformerBundEligible,
      parkFence: parkFenceEligible,
      skateTransition: skateTransitionEligible,
      cricketNets: cricketNetsEligible,
      bladeLaydown: bladeLaydownEligible,
      circularClarifier: circularClarifierEligible,
      boardwalk: boardwalkEligible,
      coolingLoop: coolingLoopEligible,
      weighbridge: weighbridgeEligible,
      boulderingBay: boulderingBayEligible,
      silageBunker: silageBunkerEligible,
      aquaculturePond: aquaculturePondEligible,
      dockLeveller: dockLevellerEligible,
      facadeLouvre: facadeLouvreEligible,
      typologyBay: typologyBayEligibleForType,
    ),
  ];

  /// Choices that represent measured specialist geometry (not generic layouts).
  List<TaxonomyChoice> specialistChoices({required bool linearSite}) => [
    for (final field in selectionFields(linearSite: linearSite))
      for (final choice in field.options)
        if (!const {'building', 'zones', 'straight'}.contains(choice.id)) choice,
  ];
}
