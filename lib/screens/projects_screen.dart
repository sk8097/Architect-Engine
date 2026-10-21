import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/project_model.dart';
import '../providers/project_provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_drawer.dart';
import 'project_form_dialog.dart';

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
          p.bhk.toLowerCase().contains(q) ||
          p.facing.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: const CommonAppBar(title: 'PROJECTS MANAGER', icon: '📁'),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: const Color(0xFF0A1128),
        icon: const Icon(Icons.add),
        label: const Text('NEW PROJECT', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const ProjectFormDialog(),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search projects by name, BHK, facing...',
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
                      onPressed: () {
                        showDialog(context: context, builder: (_) => const ProjectFormDialog());
                      },
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
                                    '${project.bhk} • ${project.floors} • ${project.facing} Facing',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  showDialog(context: context, builder: (_) => ProjectFormDialog(existingProject: project));
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
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.darkIconBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Plot: ${project.length} × ${project.width} ft', style: const TextStyle(fontSize: 11)),
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
          ],
        ),
      ),
    );
  }
}
