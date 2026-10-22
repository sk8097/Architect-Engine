import 'cad_editor_screen.dart';
import 'tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/project_provider.dart';
import '../providers/app_state_provider.dart';
import 'project_form_dialog.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ARCHITECTURAL WORKSPACE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppColors.darkPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Turn your ideas into\nprofessional drawings.',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start your next architectural project today with automated spatial planning and Vastu rules.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPrimary,
                    foregroundColor: const Color(0xFF0A1128),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ProjectFormDialog(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Create New Project',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Header: My Projects
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Projects',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => onNavigateTab?.call(1),
                child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Projects List or Empty State
          if (!projectProvider.hasProjects)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text('📁', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 10),
                  const Text(
                    'No Projects Yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your first architectural project to get started.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkPrimary,
                      side: const BorderSide(color: AppColors.darkPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ProjectFormDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Project'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projectProvider.projects.take(3).length,
              itemBuilder: (context, index) {
                final project = projectProvider.projects[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CadEditorScreen(
                          projectName: project.name,
                          plotLength: project.length,
                          plotWidth: project.width,
                          bhk: project.bhk,
                          facing: project.facing,
                        ),
                      ),
                    );
                  },
                  child: Container(
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.darkPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text('📐', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '${project.bhk} • ${project.floors} • ${project.facing} Facing',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') {
                                showDialog(
                                  context: context,
                                  builder: (_) => ProjectFormDialog(existingProject: project),
                                );
                              } else if (val == 'dup') {
                                projectProvider.duplicateProject(project.id);
                              } else if (val == 'del') {
                                projectProvider.deleteProject(project.id);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'dup', child: Text('Duplicate')),
                              const PopupMenuItem(value: 'del', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.darkIconBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Plot: ${project.length} × ${project.width} ft',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
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

          const SizedBox(height: 24),

          // Design Studio Modules Shortcut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Design Modules',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => onNavigateTab?.call(2),
                child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _buildShortcutCard(context, icon: '📐', title: 'Floor Plan', sub: 'Detailed layouts', tabIndex: 2),
              _buildShortcutCard(context, icon: '🏞️', title: 'Site Plan', sub: 'Plot & orientation', tabIndex: 2),
              _buildShortcutCard(context, icon: '🏠', title: 'Elevation', sub: 'Exterior views', tabIndex: 2),
              _buildShortcutCard(context, icon: '📦', title: '3D View', sub: 'Spatial model', tabIndex: 2),
            ],
          ),

          const SizedBox(height: 24),

          // Tools & Utilities Shortcut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Engineering & Tools',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => onNavigateTab?.call(3),
                child: const Text('168 Tools', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildCompactToolCategory(context, icon: '📏', title: 'Measurement', tabIndex: 3),
              _buildCompactToolCategory(context, icon: '👷', title: 'Construction', tabIndex: 3),
              _buildCompactToolCategory(context, icon: '🧱', title: 'Materials & Steel', tabIndex: 3),
              _buildCompactToolCategory(context, icon: '💰', title: 'Cost & BOQ', tabIndex: 3),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShortcutCard(BuildContext context, {required String icon, required String title, required String sub, required int tabIndex}) {
    return InkWell(
      onTap: () {
        if (title == 'Floor Plan' || title == 'Site Plan' || title == 'Elevation' || title == '3D View') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CadEditorScreen(projectName: title)));
        } else if (title == 'Measurement') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'measure')));
        } else if (title == 'Construction') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'const')));
        } else if (title == 'Materials & Steel') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'mat')));
        } else if (title == 'Cost & BOQ') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'cost')));
        } else {
          onNavigateTab?.call(tabIndex);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactToolCategory(BuildContext context, {required String icon, required String title, required int tabIndex}) {
    return InkWell(
      onTap: () {
        if (title == 'Floor Plan' || title == 'Site Plan' || title == 'Elevation' || title == '3D View') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CadEditorScreen(projectName: title)));
        } else if (title == 'Measurement') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'measure')));
        } else if (title == 'Construction') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'const')));
        } else if (title == 'Materials & Steel') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'mat')));
        } else if (title == 'Cost & BOQ') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'cost')));
        } else {
          onNavigateTab?.call(tabIndex);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
