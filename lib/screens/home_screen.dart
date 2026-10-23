import 'cad_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/project_provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_drawer.dart';
import 'project_form_dialog.dart';
import 'projects_screen.dart';
import 'design_screen.dart';
import 'tools_screen.dart';
import 'professional_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      appBar: const CommonAppBar(title: 'ARCHITECT ENGINE', icon: '📐'),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero Banner with Native Offline CAD Vector Blueprint Background
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorder),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2042), Color(0xFF0A1128)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  painter: _BlueprintVectorPainter(),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.darkPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.darkPrimary.withOpacity(0.4)),
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
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start your next architectural project today with automated spatial planning and Vastu rules.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFB0C4DE), height: 1.4),
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
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. My Projects Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Projects',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen()));
                  },
                  child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (!projectProvider.hasProjects)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text('📁', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    const Text('No Projects Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Create your first architectural project to get started.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkPrimary,
                        side: const BorderSide(color: AppColors.darkPrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        showDialog(context: context, builder: (_) => const ProjectFormDialog());
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
                itemCount: projectProvider.projects.take(2).length,
                itemBuilder: (context, index) {
                  final project = projectProvider.projects[index];
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
                                  Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(
                                    '${project.bhk} • ${project.floors} • ${project.facing} Facing',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${project.areaSqFt.toStringAsFixed(0)} sq.ft',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPrimary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // 3. Design Studio Modules Shortcut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Design Modules', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen()));
                  },
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
                _buildShortcutCard(
                  context,
                  icon: '📐',
                  title: 'Floor Plan',
                  sub: 'Detailed layouts',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen())),
                ),
                _buildShortcutCard(
                  context,
                  icon: '🏞️',
                  title: 'Site Plan',
                  sub: 'Plot & orientation',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen())),
                ),
                _buildShortcutCard(
                  context,
                  icon: '🏠',
                  title: 'Elevation',
                  sub: 'Exterior views',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen())),
                ),
                _buildShortcutCard(
                  context,
                  icon: '📦',
                  title: '3D View',
                  sub: 'Spatial model',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen())),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Tools & Utilities Shortcut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Engineering & Tools', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen()));
                  },
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
                _buildCompactToolCategory(
                  context,
                  icon: '📏',
                  title: 'Measurement',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'measure'))),
                ),
                _buildCompactToolCategory(
                  context,
                  icon: '👷',
                  title: 'Construction',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'const'))),
                ),
                _buildCompactToolCategory(
                  context,
                  icon: '🧱',
                  title: 'Materials & Steel',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'mat'))),
                ),
                _buildCompactToolCategory(
                  context,
                  icon: '💰',
                  title: 'Cost & BOQ',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'cost'))),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Professional Studio (MOVED TO LAST AT THE BOTTOM)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Professional CAD Studio',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen()));
                  },
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
                _buildShortcutCard(
                  context,
                  icon: '🖊️',
                  title: '2D CAD Workspace',
                  sub: 'Vector drafting',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen())),
                ),
                _buildShortcutCard(
                  context,
                  icon: '📐',
                  title: 'Precision Tools',
                  sub: 'Coordinates & snap',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen())),
                ),
                _buildShortcutCard(
                  context,
                  icon: '📑',
                  title: 'Layers Manager',
                  sub: 'Discipline layers',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen())),
                ),
                _buildShortcutCard(
                  context,
                  icon: '⚙️',
                  title: 'Standards & Codes',
                  sub: 'NBC / ISO compliance',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen())),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutCard(BuildContext context, {required String icon, required String title, required String sub, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactToolCategory(BuildContext context, {required String icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
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

// Native CAD Blueprint Background Painter
class _BlueprintVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.08)
      ..strokeWidth = 1.0;

    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final blueprintPaint = Paint()
      ..color = const Color(0xFFE5B05C).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTWH(size.width - 110, size.height - 90, 85, 65);
    canvas.drawRect(rect, blueprintPaint);
    canvas.drawLine(Offset(rect.left, rect.top + 25), Offset(rect.right, rect.top + 25), blueprintPaint);
    canvas.drawLine(Offset(rect.left + 35, rect.top), Offset(rect.left + 35, rect.bottom), blueprintPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
