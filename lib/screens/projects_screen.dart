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
import 'healthcare_cad_screen.dart';
import 'school_cad_screen.dart';
import 'office_cad_screen.dart';
import '../services/office_cad_generator.dart';
import 'packhouse_cad_screen.dart';
import 'survey_corridor_screen.dart';
import '../services/survey_corridor_generator.dart';
import '../services/packhouse_cad_generator.dart';
import '../services/school_cad_generator.dart';
import 'retail_cad_screen.dart';
import 'mixed_retail_cad_screen.dart';
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
                                if (MixedRetailCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'mixed_shop_home', child: Text('Shop and dwelling CAD')),
                                if (RetailCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'retail_fixtures', child: Text('Retail fixture CAD')),
                                if (PackhouseCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'packhouse_flow', child: Text('Packhouse goods-flow CAD')),
                                if (OfficeCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value:'office_workplace',child:Text('Office workplace CAD')),
                                if (SchoolCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'school_arrival', child: Text('Primary school CAD')),
                                if (HealthcareCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'clinic_separated', child: Text('Clinic route CAD')),
                                if (CrossDockCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'warehouse_cross_dock',child:Text('Warehouse cross-dock CAD')),
                                if (WarehouseLoadingGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'warehouse_loading', child: Text('Warehouse loading CAD')),
                                if (EnclosedCadGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'enclosed', child: Text('Measured floor plan CAD')),
                                if (SurveyCorridorGenerator.requested(project.brief))
                                  const PopupMenuItem(value: 'survey_polyline', child: Text('Survey corridor CAD')),
                                if (!SurveyCorridorGenerator.requested(project.brief) && ConceptZoningGenerator.supportsBrief(project.brief))
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
