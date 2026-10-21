import os

home_screen_code = '''import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/project_provider.dart';
import '../providers/app_state_provider.dart';
import 'project_form_dialog.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Professional Architectural Hero Banner
          _buildHeroBanner(context, isDark),
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
                onPressed: () => onNavigateTab(1),
                child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Projects List or Empty State
          if (!projectProvider.hasProjects)
            _buildEmptyProjectsCard(context, isDark)
          else
            _buildProjectsList(context, projectProvider),

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
                onPressed: () => onNavigateTab(2),
                child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _buildDesignModuleCard(
                context,
                isDark: isDark,
                title: 'Floor Plan',
                subtitle: '2D CAD Layouts',
                badge: 'ARCHITECTURE',
                badgeColor: const Color(0xFF38BDF8),
                icon: Icons.grid_view_rounded,
                tabIndex: 2,
              ),
              _buildDesignModuleCard(
                context,
                isDark: isDark,
                title: 'Site Plan',
                subtitle: 'Plot & Vastu Zoning',
                badge: 'ORIENTATION',
                badgeColor: const Color(0xFF34D399),
                icon: Icons.explore_outlined,
                tabIndex: 2,
              ),
              _buildDesignModuleCard(
                context,
                isDark: isDark,
                title: 'Elevation',
                subtitle: 'Facade & Heights',
                badge: 'EXTERIOR',
                badgeColor: const Color(0xFFFBBF24),
                icon: Icons.domain_rounded,
                tabIndex: 2,
              ),
              _buildDesignModuleCard(
                context,
                isDark: isDark,
                title: '3D View',
                subtitle: 'Spatial 3D Model',
                badge: 'VISUALIZER',
                badgeColor: const Color(0xFFA78BFA),
                icon: Icons.view_in_ar_rounded,
                tabIndex: 2,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Engineering & Tools Shortcut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Engineering & Tools',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => onNavigateTab(3),
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
              _buildCompactToolCategory(context, icon: '📐', title: 'Measurement', tabIndex: 3),
              _buildCompactToolCategory(context, icon: '👷', title: 'Construction', tabIndex: 3),
              _buildCompactToolCategory(context, icon: '🧱', title: 'Materials & Steel', tabIndex: 3),
              _buildCompactToolCategory(context, icon: '🪙', title: 'Cost & BOQ', tabIndex: 3),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDark) {
    return Container(
      height: 215,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF080D18)]
              : [const Color(0xFF0F2042), const Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E3A8A)).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0x40E5B05C) : const Color(0x3360A5FA),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // Architectural CAD Blueprint Background
            Positioned.fill(
              child: CustomPaint(
                painter: ArchitecturalBlueprintPainter(isDarkMode: isDark),
              ),
            ),
            // Text & Action Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5B05C).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5B05C).withOpacity(0.6), width: 0.8),
                    ),
                    child: const Text(
                      'ARCHITECTURAL WORKSPACE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFFFDE68A),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Turn your ideas into\\nprofessional drawings.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Automated spatial planning, 2D CAD drafting & Vastu orientation.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFCBD5E1),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5B05C),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
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
          ],
        ),
      ),
    );
  }

  Widget _buildDesignModuleCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required int tabIndex,
  }) {
    return InkWell(
      onTap: () => onNavigateTab(tabIndex),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0x25FFFFFF) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: badgeColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProjectsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0x25FFFFFF) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.darkPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.architecture_rounded, size: 30, color: AppColors.darkPrimary),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Projects Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create your first architectural project to get started.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkPrimary,
              side: const BorderSide(color: AppColors.darkPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ProjectFormDialog(),
              );
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(BuildContext context, ProjectProvider projectProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projectProvider.projects.take(3).length,
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
                    child: const Icon(Icons.home_work_outlined, color: AppColors.darkPrimary, size: 22),
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
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'dup', child: Text('Duplicate')),
                      PopupMenuItem(value: 'del', child: Text('Delete', style: TextStyle(color: Colors.red))),
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
    );
  }

  Widget _buildCompactToolCategory(BuildContext context, {required String icon, required String title, required int tabIndex}) {
    return InkWell(
      onTap: () => onNavigateTab(tabIndex),
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

class ArchitecturalBlueprintPainter extends CustomPainter {
  final bool isDarkMode;
  ArchitecturalBlueprintPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDarkMode ? Colors.cyanAccent : Colors.lightBlueAccent).withOpacity(0.09)
      ..strokeWidth = 1.0;

    // Draw millimeter drafting grid
    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFE5B05C).withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFFE5B05C).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Modern Villa Architectural Outline
    final path = Path();
    path.moveTo(w * 0.62, h * 0.88);
    path.lineTo(w * 0.62, h * 0.38);
    path.lineTo(w * 0.74, h * 0.22);
    path.lineTo(w * 0.90, h * 0.22);
    path.lineTo(w * 0.96, h * 0.35);
    path.lineTo(w * 0.96, h * 0.88);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);

    // Floor Level Line
    canvas.drawLine(Offset(w * 0.62, h * 0.62), Offset(w * 0.96, h * 0.62), linePaint);

    // Windows & Door wireframe
    final windowPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(w * 0.66, h * 0.42, w * 0.08, h * 0.14), windowPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.78, h * 0.42, w * 0.08, h * 0.14), windowPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.68, h * 0.68, w * 0.07, h * 0.20), windowPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.80, h * 0.68, w * 0.10, h * 0.14), windowPaint);

    // Dimension Markings
    final dimPaint = Paint()
      ..color = const Color(0xFFE5B05C).withOpacity(0.3)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(w * 0.58, h * 0.38), Offset(w * 0.58, h * 0.88), dimPaint);
    canvas.drawLine(Offset(w * 0.56, h * 0.38), Offset(w * 0.60, h * 0.38), dimPaint);
    canvas.drawLine(Offset(w * 0.56, h * 0.88), Offset(w * 0.60, h * 0.88), dimPaint);

    // North Compass
    final compassCenter = Offset(w * 0.88, h * 0.18);
    final compassPaint = Paint()
      ..color = const Color(0xFFE5B05C).withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(compassCenter, 10, compassPaint);
    canvas.drawLine(Offset(compassCenter.dx, compassCenter.dy - 14), Offset(compassCenter.dx, compassCenter.dy + 14), compassPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
'''

with open('lib/screens/home_screen.dart', 'w') as f:
    f.write(home_screen_code)

print("✅ home_screen.dart successfully updated with Architectural Blueprint Vector Graphics!")
