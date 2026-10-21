import os

# 1. Create Projects Screen
projects_screen_code = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/project_model.dart';
import '../providers/project_provider.dart';
import 'project_form_dialog.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = projectProvider.projects.where((p) {
      return p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.bhk.toLowerCase().contains(_search.toLowerCase()) ||
          p.facing.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 24),
            tooltip: 'Create New Project',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ProjectFormDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search projects (name, BHK, facing)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0x25FFFFFF) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0x25FFFFFF) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: projects.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.darkPrimary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.architecture_rounded, size: 36, color: AppColors.darkPrimary),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Projects Found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Create your first architectural design project.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkPrimary,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const ProjectFormDialog(),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create New Project', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: projects.length,
                    itemBuilder: (ctx, idx) {
                      final project = projects[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0x25FFFFFF) : const Color(0xFFE2E8F0),
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
                                  child: const Icon(Icons.home_work_outlined, color: AppColors.darkPrimary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
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
                                  itemBuilder: (c) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit Project')),
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
                  ),
          ),
        ],
      ),
    );
  }
}
'''

# 2. Update Main Scaffold (Remove bottom navigation bar)
main_scaffold_code = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/app_drawer.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final isDark = appState.isDarkMode;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Row(
          children: const [
            Text('📐', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'ARCHITECT ENGINE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (notifProvider.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    alignment: Alignment.center,
                    child: Text(
                      '${notifProvider.unreadCount}',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Text(isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
            onPressed: () => appState.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: const HomeScreen(),
    );
  }
}
'''

# 3. Update Home Screen (Add Professional Studio section + clean direct navigations)
home_screen_code = '''import 'dart:math' as math;
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
'''

# 4. Update App Drawer
drawer_code = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../screens/projects_screen.dart';
import '../screens/professional_screen.dart';
import '../screens/design_screen.dart';
import '../screens/tools_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/unit_converter_screen.dart';
import '../screens/vastu_screen.dart';
import '../screens/tutorials_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/cloud_sync_screen.dart';
import '../screens/export_screen.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onSelectTab;

  const AppDrawer({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('👷', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Design • Plan • Build',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  _buildSectionTitle('MAIN NAVIGATION'),
                  _buildMenuItem(
                    context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.folder_outlined,
                    title: 'My Projects',
                    onTap: () => _nav(context, const ProjectsScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.architecture,
                    title: 'Professional CAD',
                    onTap: () => _nav(context, const ProfessionalScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.design_services_outlined,
                    title: 'Design Studio',
                    onTap: () => _nav(context, const DesignScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.handyman_outlined,
                    title: 'Tools & Utilities',
                    onTap: () => _nav(context, const ToolsScreen()),
                  ),

                  const Divider(),
                  _buildSectionTitle('ACCOUNT'),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    onTap: () => _nav(context, const ProfileScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.cloud_sync_outlined,
                    title: 'Cloud Sync',
                    onTap: () => _nav(context, const CloudSyncScreen()),
                  ),

                  const Divider(),
                  _buildSectionTitle('APP PREFERENCES'),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined, size: 22),
                    title: const Text('Theme Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: Text(
                      appState.isDarkMode ? '🌙 Dark' : '☀️ Light',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkPrimary),
                    ),
                    onTap: () => appState.toggleTheme(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language_outlined, size: 22),
                    title: const Text('Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: DropdownButton<String>(
                      value: appState.currentLanguage,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                        DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                        DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી')),
                        DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                      ],
                      onChanged: (val) {
                        if (val != null) appState.setLanguage(val);
                      },
                    ),
                  ),

                  const Divider(),
                  _buildSectionTitle('SMART FEATURES'),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_none,
                    title: 'Notification Inbox',
                    onTap: () => _nav(context, const NotificationsScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.straighten,
                    title: 'Unit Converter',
                    onTap: () => _nav(context, const UnitConverterScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.compass_calibration_outlined,
                    title: 'Vastu Guide',
                    onTap: () => _nav(context, const VastuScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.file_download_outlined,
                    title: 'Export Center',
                    onTap: () => _nav(context, const ExportScreen()),
                  ),

                  const Divider(),
                  _buildSectionTitle('COMMUNITY & GUIDES'),
                  _buildMenuItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    title: 'Tutorials',
                    onTap: () => _nav(context, const TutorialsScreen()),
                  ),

                  const Divider(),
                  _buildSectionTitle('SUPPORT & INFO'),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    onTap: () => _nav(context, const FAQScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.share_outlined,
                    title: 'Share App',
                    onTap: () => _nav(context, const ShareScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About Us',
                    onTap: () => _nav(context, const AboutScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _nav(context, const PrivacyPolicyScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 12, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
'''

with open('lib/screens/projects_screen.dart', 'w') as f:
    f.write(projects_screen_code)

with open('lib/screens/main_scaffold.dart', 'w') as f:
    f.write(main_scaffold_code)

with open('lib/screens/home_screen.dart', 'w') as f:
    f.write(home_screen_code)

with open('lib/widgets/app_drawer.dart', 'w') as f:
    f.write(drawer_code)

print("✅ Layout successfully updated: Bottom bar removed, Professional Studio section added!")
