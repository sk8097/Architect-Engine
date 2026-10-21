import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/project_provider.dart';
import '../providers/app_state_provider.dart';
import 'project_form_dialog.dart';
import 'projects_screen.dart';
import 'professional_screen.dart';
import 'design_screen.dart';
import 'tools_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Architectural Hero Banner
          _buildHeroBanner(context, isDark),
          const SizedBox(height: 24),

          // 2. Section: My Projects
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Projects',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProjectsScreen()),
                  );
                },
                child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (!projectProvider.hasProjects)
            _buildEmptyProjectsCard(context, isDark)
          else
            _buildProjectsList(context, projectProvider, isDark),

          const SizedBox(height: 24),

          // 3. Section: Professional Studio (Added)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text(
                    'Professional Studio',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 6),
                  Text('📐', style: TextStyle(fontSize: 16)),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfessionalScreen()),
                  );
                },
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
              _buildFeatureCard(
                context,
                isDark: isDark,
                title: 'CAD Drafting',
                subtitle: '2D Vector Canvas & Snap',
                badge: 'PRECISION',
                badgeColor: const Color(0xFF60A5FA),
                icon: Icons.architecture,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen())),
              ),
              _buildFeatureCard(
                context,
                isDark: isDark,
                title: 'Drawing Tools',
                subtitle: 'Shapes, Offset & Trim',
                badge: 'DRAFTING',
                badgeColor: const Color(0xFFF472B6),
                icon: Icons.draw_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen())),
              ),
              _buildFeatureCard(
                context,
                isDark: isDark,
                title: 'Layers Manager',
                subtitle: 'Arch, MEP & Structural',
                badge: 'LAYERS',
                badgeColor: const Color(0xFF34D399),
                icon: Icons.layers_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen())),
              ),
              _buildFeatureCard(
                context,
                isDark: isDark,
                title: 'Dimensions',
                subtitle: 'Linear, Angular & Scale',
                badge: 'STANDARDS',
                badgeColor: const Color(0xFFFBBF24),
                icon: Icons.straighten_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen())),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Section: Design Modules
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text(
                    'Design Modules',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 6),
                  Text('🏢', style: TextStyle(fontSize: 16)),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DesignScreen()),
                  );
                },
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
              _buildFeatureCard(
                context,
                isDark: isDark,
                title: 'Floor Plan',
                subtitle: '2D CAD Spatial Layouts',
                badge: 'ARCHITECTURE',
                badgeColor: const Color(0xFF38BDF8),
                icon: Icons.grid_view_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen())),
              ),
              _buildFeatureCard(
                context,
                isDark: isDark,
                title: 'Site Plan',
                subtitle: 'Plot & Vastu Zoning',
                badge: 'ORIENTATION',
                badgeColor: const Color(0xFF34D399),
                icon: Icons.explore_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen())),
              ),
              _buildFeatureCard(
                context,
                isDark: isDark,
                title: 'Elevation',
                subtitle: 'Facade & Height Levels',
                badge: 'EXTERIOR',
                badgeColor: const Color(0xFFFBBF24),
                icon: Icons.domain_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen())),
              ),
              _buildFeatureCard(
                context,
                isDark: isDark,
                title: '3D View',
                subtitle: 'Spatial 3D Massing Model',
                badge: 'VISUALIZER',
                badgeColor: const Color(0xFFA78BFA),
                icon: Icons.view_in_ar_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen())),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 5. Section: Engineering & Tools Shortcut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text(
                    'Engineering & Tools',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 6),
                  Text('⚡', style: TextStyle(fontSize: 16)),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ToolsScreen()),
                  );
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
                icon: '📐',
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
                icon: '🪙',
                title: 'Cost & BOQ',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(initialCategory: 'cost'))),
              ),
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
            Positioned.fill(
              child: CustomPaint(
                painter: ArchitecturalBlueprintPainter(isDarkMode: isDark),
              ),
            ),
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
                        'Turn your ideas into\nprofessional drawings.',
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

  Widget _buildFeatureCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
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

  Widget _buildProjectsList(BuildContext context, ProjectProvider projectProvider, bool isDark) {
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
            border: Border.all(color: isDark ? const Color(0x25FFFFFF) : const Color(0xFFE2E8F0)),
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
                      color: isDark ? AppColors.darkIconBg : const Color(0xFFF1F5F9),
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
                      color: isDark ? AppColors.darkIconBg : const Color(0xFFF1F5F9),
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

  Widget _buildCompactToolCategory(BuildContext context, {required String icon, required String title, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0x25FFFFFF) : const Color(0xFFE2E8F0)),
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
    canvas.drawLine(Offset(w * 0.62, h * 0.62), Offset(w * 0.96, h * 0.62), linePaint);

    final windowPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(w * 0.66, h * 0.42, w * 0.08, h * 0.14), windowPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.78, h * 0.42, w * 0.08, h * 0.14), windowPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.68, h * 0.68, w * 0.07, h * 0.20), windowPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.80, h * 0.68, w * 0.10, h * 0.14), windowPaint);

    final dimPaint = Paint()
      ..color = const Color(0xFFE5B05C).withOpacity(0.3)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(w * 0.58, h * 0.38), Offset(w * 0.58, h * 0.88), dimPaint);
    canvas.drawLine(Offset(w * 0.56, h * 0.38), Offset(w * 0.60, h * 0.38), dimPaint);
    canvas.drawLine(Offset(w * 0.56, h * 0.88), Offset(w * 0.60, h * 0.88), dimPaint);

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
