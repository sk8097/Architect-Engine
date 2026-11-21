import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/project_provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_drawer.dart';
import 'project_form_dialog.dart';
import 'project_wizard_screen.dart';
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
import 'public_toilet_cad_screen.dart';
import 'vehicle_lift_cad_screen.dart';
import 'athletics_track_cad_screen.dart';
import 'playground_cad_screen.dart';
import 'bicycle_rack_cad_screen.dart';
import 'memorial_niche_cad_screen.dart';
import 'tennis_cad_screen.dart';
import 'twin_tank_cad_screen.dart';
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
import 'footbridge_cad_screen.dart';
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
import '../services/concept_zoning_generator.dart';
import 'scenario_library_screen.dart';
import 'automatic_floor_plan_screen.dart';
import '../services/automatic_floor_plan_generator.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final projects = projectProvider.projects.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: const CommonAppBar(title: 'PROJECTS MANAGER', icon: '📁'),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: const Color(0xFF0A1128),
        icon: const Icon(Icons.add),
        label: const Text('NEW PROJECT', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => ProjectWizardScreen.open(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute(
              builder: (_) => const TowerPlannerScreen(),)), icon: const Icon(Icons.apartment),
              label: const Text('High-rise planner (up to 100 levels)')),
            const SizedBox(height: 12),
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, project type or layout...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 18),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute(
                  builder: (_) => const ScenarioLibraryScreen(),
                )),
                child: const Text('Browse scenario examples'),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('All Projects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${projects.length} Total', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            if (projects.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text('📁', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text('No Projects Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Start by creating your first architectural project.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkPrimary,
                        foregroundColor: const Color(0xFF0A1128),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => ProjectWizardScreen.open(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create New Project'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.darkPrimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text('🏛️', style: TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    project.description,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) async {
                                if (val == 'tower' && project.tower != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) =>
                                    TowerPlanScreen(projectName: project.name, brief: project.tower!)));
                                  return;
                                }
                                if (val == 'dwelling_g1' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => DwellingG1Screen(
                                    name: project.name, brief: project.brief!, widthFt: project.width,
                                    depthFt: project.length, facing: project.facing)));
                                  return;
                                }
                                if (val == 'shared_core_shop_office' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => SharedCoreCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'mixed_shop_below_home' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => StackedRetailCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'mixed_shop_home' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => MixedRetailCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,
                                    depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'retail_fixtures' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => RetailCadScreen(
                                    name: project.name, brief: project.brief!, widthFt: project.width,
                                    depthFt: project.length, facing: project.facing)));
                                  return;
                                }
                                if ((val == 'survey_t' || val == 'survey_cross') && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TJunctionCadScreen(name:project.name,brief:project.brief!)));
                                  return;
                                }
                                if (val == 'survey_footbridge' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => FootbridgeCadScreen(name:project.name,brief:project.brief!)));
                                  return;
                                }
                                if (val == 'survey_crossing' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => CulvertCadScreen(name:project.name,brief:project.brief!)));
                                  return;
                                }
                                if (val == 'survey_layby' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => BusLaybyCadScreen(name:project.name,brief:project.brief!)));
                                  return;
                                }
                                if (val == 'survey_open_drain' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => OpenDrainCadScreen(name:project.name,brief:project.brief!)));
                                  return;
                                }
                                if (val == 'survey_gravity' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => StormwaterCadScreen(name:project.name,brief:project.brief!)));
                                  return;
                                }
                                if (val == 'survey_earthwork' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => CorridorEarthworkScreen(name:project.name,brief:project.brief!)));
                                  return;
                                }
                                if (val == 'survey_section' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => CorridorSectionScreen(name:project.name,brief:project.brief!)));
                                  return;
                                }
                                if (val == 'survey_profile' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => LongitudinalProfileScreen(name:project.name,brief:project.brief!)));
                                  return;
                                }
                                if (val == 'survey_polyline' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => SurveyCorridorScreen(
                                    name: project.name, brief: project.brief!)));
                                  return;
                                }
                                if (val == 'packhouse_flow' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => PackhouseCadScreen(
                                    name: project.name, brief: project.brief!, widthFt: project.width,
                                    depthFt: project.length, facing: project.facing)));
                                  return;
                                }
                                if (val == 'inpatient_ward' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => InpatientWardCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'greenhouse_benches' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => GreenhouseCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'hostel_shared_rooms' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => HostelCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'badminton_hall' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => BadmintonCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'library_reading' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => LibraryCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'assembly_workflow' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => AssemblyCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'cattle_shed' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => CattleShedCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'dining_service' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => DiningCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'office_workplace' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => OfficeCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'school_arrival' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => SchoolCadScreen(
                                    name: project.name, brief: project.brief!, widthFt: project.width,
                                    depthFt: project.length, facing: project.facing)));
                                  return;
                                }
                                if (val == 'clinic_separated' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => HealthcareCadScreen(
                                    name: project.name, brief: project.brief!, widthFt: project.width,
                                    depthFt: project.length, facing: project.facing)));
                                  return;
                                }
                                if (val == 'paired_apartments' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => PairedApartmentScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'public_toilet_measured_bank' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => PublicToiletCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'workshop_measured_lifts' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => VehicleLiftCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'athletics_measured_track' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => AthleticsTrackCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'playground_measured_zones' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => PlaygroundCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'bicycle_measured_racks' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => BicycleRackCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'memorial_niche_walls' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => MemorialNicheCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'tennis_measured_bank' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TennisCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'tank_twin_cell' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TwinTankCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'cold_storage_racks' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => ColdRackCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'angled_surface_parking' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => AngledParkingCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'gallery_panel_layout' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => GalleryPanelCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'windrow_measured_yard' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => WindrowYardCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'park_measured_loop' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => ParkLoopCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'outdoor_tiered_amphitheatre' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => AmphitheatreCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'garden_raised_beds' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => RaisedBedCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'public_market_stalls' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => PublicMarketCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'lap_pool_measured' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => LapPoolCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'rainwater_roof_tanks' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => RainwaterCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'basketball_measured_court' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => BasketballCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'hotel_guestroom_wing' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => HotelWingScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'school_teaching_lab' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TeachingLabScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'measured_switchback' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => SwitchbackRampScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'orchard_measured_rows' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => OrchardCadScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'ev_measured_hub' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => EvHubScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if (val == 'basin_stage_storage' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => DetentionBasinScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'solar_fixed_tilt' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => SolarFarmScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length)));
                                  return;
                                }
                                if (val == 'truck_reverse_sweep' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TruckSweepScreen(
                                    name:project.name,brief:project.brief!,widthFt:project.width,depthFt:project.length,facing:project.facing)));
                                  return;
                                }
                                if ((val == 'warehouse_loading' || val == 'warehouse_cross_dock') && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => WarehouseLoadingScreen(
                                    name: project.name, brief: project.brief!, widthFt: project.width,
                                    depthFt: project.length, facing: project.facing)));
                                  return;
                                }
                                if (val == 'enclosed' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => EnclosedCadScreen(
                                    name: project.name, brief: project.brief!, widthFt: project.width,
                                    depthFt: project.length, facing: project.facing)));
                                  return;
                                }
                                if (val == 'zones' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => ConceptZoningScreen(
                                    name: project.name, brief: project.brief!, widthFt: project.width,
                                    depthFt: project.length, facing: project.facing)));
                                  return;
                                }
                                if (val == 'plan' && project.brief != null) {
                                  Navigator.of(context).push<void>(MaterialPageRoute(
                                    builder: (_) => AutomaticFloorPlanScreen(
                                      projectName: project.name, brief: project.brief!,
                                      frontageFt: project.width, depthFt: project.length,
                                      facing: project.facing),
                                  ));
                                  return;
                                }
                                if (val == 'edit') {
                                  if (project.tower != null) {
                                    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TowerPlannerScreen(existing: project)));
                                  } else if (project.brief != null) {
                                    ProjectWizardScreen.open(context, project: project);
                                  } else {
                                    showDialog(context: context, builder: (_) => ProjectFormDialog(existingProject: project));
                                  }
                                  return;
                                }
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  if (val == 'dup') await projectProvider.duplicateProject(project.id);
                                  if (val == 'del') await projectProvider.deleteProject(project.id);
                                } catch (_) {
                                  if (!mounted || !messenger.mounted) return;
                                  messenger.showSnackBar(const SnackBar(
                                    content: Text('Could not save the project change. Please try again.'),
                                  ));
                                }
                              },
                              itemBuilder: (ctx) => [
                                if (project.tower != null)
                                  const PopupMenuItem(value: 'tower', child: Text('High-rise CAD')),
                                if (AutomaticFloorPlanGenerator.supportsBrief(project.brief))
                                  const PopupMenuItem(value: 'plan', child: Text('Automatic floor plan')),
                                if (DwellingG1Generator.requested(project.brief))
                                  const PopupMenuItem(value: 'dwelling_g1', child: Text('G+1 house CAD')),
                                if (SharedCoreCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'shared_core_shop_office',child:Text('Shop below office CAD')),
                                if (StackedRetailCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'mixed_shop_below_home',child:Text('Shop below dwelling CAD')),
                                if (MixedRetailCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'mixed_shop_home', child: Text('Shop and dwelling CAD')),
                                if (RetailCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'retail_fixtures', child: Text('Retail fixture CAD')),
                                if (PackhouseCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'packhouse_flow', child: Text('Packhouse goods-flow CAD')),
                                if (InpatientWardCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'inpatient_ward',child:Text('General inpatient ward CAD')),
                                if (GreenhouseCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'greenhouse_benches',child:Text('Greenhouse bench CAD')),
                                if (HostelCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'hostel_shared_rooms',child:Text('Shared-room hostel CAD')),
                                if (BadmintonCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'badminton_hall',child:Text('Indoor badminton CAD')),
                                if (LibraryCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'library_reading',child:Text('Library reading CAD')),
                                if (AssemblyCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'assembly_workflow',child:Text('Factory assembly CAD')),
                                if (CattleShedCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'cattle_shed',child:Text('Cattle shed CAD')),
                                if (DiningCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'dining_service',child:Text('Dine-in service CAD')),
                                if (OfficeCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'office_workplace',child:Text('Office workplace CAD')),
                                if (SchoolCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'school_arrival', child: Text('Primary school CAD')),
                                if (HealthcareCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'clinic_separated', child: Text('Clinic route CAD')),
                                if (CrossDockCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'warehouse_cross_dock',child:Text('Warehouse cross-dock CAD')),
                                if (PairedApartmentGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'paired_apartments',child:Text('Paired apartment CAD')),
                                if (PublicToiletCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'public_toilet_measured_bank',child:Text('Public toilet block CAD')),
                                if (VehicleLiftCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'workshop_measured_lifts',child:Text('Vehicle service bay CAD')),
                                if (AthleticsTrackCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'athletics_measured_track',child:Text('Athletics track CAD')),
                                if (PlaygroundCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'playground_measured_zones',child:Text('Playground clearance CAD')),
                                if (BicycleRackCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'bicycle_measured_racks',child:Text('Bicycle rack CAD')),
                                if (MemorialNicheCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'memorial_niche_walls',child:Text('Memorial niche wall CAD')),
                                if (TennisCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'tennis_measured_bank',child:Text('Outdoor tennis court CAD')),
                                if (TwinTankCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'tank_twin_cell',child:Text('Twin-cell ground tank CAD')),
                                if (ColdRackCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'cold_storage_racks',child:Text('Cold-storage rack CAD')),
                                if (AngledParkingCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'angled_surface_parking',child:Text('Angled surface parking CAD')),
                                if (GalleryPanelCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'gallery_panel_layout',child:Text('Gallery display-panel CAD')),
                                if (WindrowYardCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'windrow_measured_yard',child:Text('Composting windrow yard CAD')),
                                if (ParkLoopCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'park_measured_loop',child:Text('Public park walking loop CAD')),
                                if (AmphitheatreCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'outdoor_tiered_amphitheatre',child:Text('Outdoor amphitheatre CAD')),
                                if (RaisedBedCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'garden_raised_beds',child:Text('Public garden raised-bed CAD')),
                                if (PublicMarketCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'public_market_stalls',child:Text('Open-air public market CAD')),
                                if (LapPoolCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'lap_pool_measured',child:Text('Outdoor lap pool CAD')),
                                if (RainwaterCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'rainwater_roof_tanks',child:Text('Roof rainwater harvesting CAD')),
                                if (BasketballCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'basketball_measured_court',child:Text('Outdoor basketball court CAD')),
                                if (HotelWingGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'hotel_guestroom_wing',child:Text('Hotel guestroom wing CAD')),
                                if (TeachingLabGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'school_teaching_lab',child:Text('Teaching lab CAD')),
                                if (SwitchbackRampGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'measured_switchback',child:Text('Switchback ramp CAD')),
                                if (OrchardCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'orchard_measured_rows',child:Text('Orchard planting CAD')),
                                if (EvHubGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'ev_measured_hub',child:Text('EV charging yard CAD')),
                                if (DetentionBasinGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'basin_stage_storage',child:Text('Detention basin CAD')),
                                if (SolarFarmGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'solar_fixed_tilt',child:Text('Fixed-tilt solar farm CAD')),
                                if (TruckSweepGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'truck_reverse_sweep',child:Text('Rigid truck swept-path CAD')),
                                if (WarehouseLoadingGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'warehouse_loading', child: Text('Warehouse loading CAD')),
                                if (EnclosedCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'enclosed', child: Text('Measured floor plan CAD')),
                                if (CrossJunctionCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_cross', child:Text('Survey four-arm intersection CAD')),
                                if (TJunctionCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_t',child:Text('Survey T-junction CAD')),
                                if (FootbridgeCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_footbridge',child:Text('Surveyed footbridge CAD')),
                                if (CulvertCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_crossing',child:Text('Survey culvert crossing CAD')),
                                if (BusLaybyCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_layby',child:Text('Surveyed bus stop lay-by CAD')),
                                if (OpenDrainCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_open_drain',child:Text('Surveyed open drain CAD')),
                                if (StormwaterCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_gravity',child:Text('Stormwater plan + profile CAD')),
                                if (CorridorEarthworkGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_earthwork',child:Text('Corridor earthwork takeoff')),
                                if (CorridorSectionGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_section',child:Text('Corridor cross-section CAD')),
                                if (LongitudinalProfileGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'survey_profile',child:Text('Longitudinal profile CAD')),
                                if (SurveyCorridorGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'survey_polyline', child: Text('Survey corridor CAD')),
                                if (!SurveyCorridorGenerator.requested(project.brief) && !TJunctionCadGenerator.requested(project.brief) && !CrossJunctionCadGenerator.requested(project.brief) && !LongitudinalProfileGenerator.requested(project.brief) && !CorridorSectionGenerator.requested(project.brief) && !CorridorEarthworkGenerator.requested(project.brief) && !StormwaterCadGenerator.requested(project.brief) && !OpenDrainCadGenerator.requested(project.brief) && !BusLaybyCadGenerator.requested(project.brief) && !CulvertCadGenerator.requested(project.brief) && !FootbridgeCadGenerator.requested(project.brief) && !TruckSweepGenerator.requested(project.brief) && !SolarFarmGenerator.requested(project.brief) && !DetentionBasinGenerator.requested(project.brief) && !EvHubGenerator.requested(project.brief) && !OrchardCadGenerator.requested(project.brief) && !SwitchbackRampGenerator.requested(project.brief) && !TeachingLabGenerator.requested(project.brief) && !HotelWingGenerator.requested(project.brief) && !BasketballCadGenerator.requested(project.brief) && !RainwaterCadGenerator.requested(project.brief) && !LapPoolCadGenerator.requested(project.brief) && !PublicMarketCadGenerator.requested(project.brief) && !RaisedBedCadGenerator.requested(project.brief) && !AmphitheatreCadGenerator.requested(project.brief) && !ParkLoopCadGenerator.requested(project.brief) && !WindrowYardCadGenerator.requested(project.brief) && !GalleryPanelCadGenerator.requested(project.brief) && !AngledParkingCadGenerator.requested(project.brief) && !ColdRackCadGenerator.requested(project.brief) && !PublicToiletCadGenerator.requested(project.brief) && !VehicleLiftCadGenerator.requested(project.brief) && !AthleticsTrackCadGenerator.requested(project.brief) && !PlaygroundCadGenerator.requested(project.brief) && !BicycleRackCadGenerator.requested(project.brief) && !MemorialNicheCadGenerator.requested(project.brief) && !TennisCadGenerator.requested(project.brief) && !TwinTankCadGenerator.requested(project.brief) && !PairedApartmentGenerator.requested(project.brief) && ConceptZoningGenerator.supportsBrief(project.brief))
                                  const PopupMenuItem(value: 'zones', child: Text('Concept zoning CAD')),
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'dup', child: Text('Duplicate')),
                                const PopupMenuItem(value: 'del', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.darkIconBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(project.hasPlotDimensions ? 'Plot: ${project.length} × ${project.width} ft' : 'Plot dimensions pending', style: const TextStyle(fontSize: 11)),
                            ),
                            if (project.hasPlotDimensions) Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.darkIconBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${project.areaSqFt.toStringAsFixed(0)} sq.ft',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkPrimary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
