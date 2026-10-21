import os

# 1. Create CommonAppBar widget
common_app_bar_code = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications_screen.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String icon;

  const CommonAppBar({
    super.key,
    required this.title,
    this.icon = '📐',
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open Menu',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Notification Bell Icon with Badge
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
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  alignment: Alignment.center,
                  child: Text(
                    '${notifProvider.unreadCount}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Dark / Light Theme Toggle
        IconButton(
          icon: Text(
            appState.isDarkMode ? '🌙' : '☀️',
            style: const TextStyle(fontSize: 18),
          ),
          tooltip: 'Toggle Theme',
          onPressed: () => appState.toggleTheme(),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
'''
with open("lib/widgets/common_app_bar.dart", "w", encoding="utf-8") as f:
    f.write(common_app_bar_code)
print("  ✓ Created lib/widgets/common_app_bar.dart")

# 2. Update AppDrawer to navigate cleanly across all screens
app_drawer_code = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../screens/home_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/design_screen.dart';
import '../screens/tools_screen.dart';
import '../screens/professional_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/unit_converter_screen.dart';
import '../screens/vastu_screen.dart';
import '../screens/tutorials_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/cloud_sync_screen.dart';
import '../screens/export_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
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
                    child: const Text('📐', style: TextStyle(fontSize: 24)),
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

            // Scrollable Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  _buildSectionTitle('MAIN SECTIONS'),
                  _buildMenuItem(
                    context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.folder_outlined,
                    title: 'Projects',
                    onTap: () => _nav(context, const ProjectsScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.architecture,
                    title: 'Design Studio',
                    onTap: () => _nav(context, const DesignScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.handyman_outlined,
                    title: 'Tools & Utilities',
                    onTap: () => _nav(context, const ToolsScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.draw_outlined,
                    title: 'Professional CAD',
                    onTap: () => _nav(context, const ProfessionalScreen()),
                  ),

                  const Divider(),
                  _buildSectionTitle('ACCOUNT & BACKUP'),
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
with open("lib/widgets/app_drawer.dart", "w", encoding="utf-8") as f:
    f.write(app_drawer_code)
print("  ✓ Updated lib/widgets/app_drawer.dart")

# 3. Create Dedicated ProjectsScreen (lib/screens/projects_screen.dart)
projects_screen_code = '''import 'package:flutter/material.dart';
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
'''
with open("lib/screens/projects_screen.dart", "w", encoding="utf-8") as f:
    f.write(projects_screen_code)
print("  ✓ Created lib/screens/projects_screen.dart")

# 4. Update ToolsScreen (lib/screens/tools_screen.dart)
tools_screen_code = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../data/tools_data.dart';
import '../models/tool_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_drawer.dart';
import 'calculator_dialog.dart';

class ToolsScreen extends StatefulWidget {
  final String? initialCategory;

  const ToolsScreen({super.key, this.initialCategory});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _selectedCat = 'all';
  String _searchQuery = '';
  int _renderLimit = 30;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCat = widget.initialCategory!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    List<ToolModel> list = ToolsData.allTools;
    if (_selectedCat == 'fav') {
      list = list.where((t) => appState.isFavorite(t.id)).toList();
    } else if (_selectedCat != 'all') {
      list = list.where((t) => t.category == _selectedCat).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) => t.name.toLowerCase().contains(q) || t.description.toLowerCase().contains(q)).toList();
    }

    final visibleTools = list.take(_renderLimit).toList();

    return Scaffold(
      appBar: const CommonAppBar(title: 'TOOLS & UTILITIES', icon: '🧰'),
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('168 Professional Tools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('Civil engineering, BOQ takeoffs, structural, and architectural calculators', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),

                  // Search Box
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search 168 tools (e.g. concrete, steel, tile, boq)...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 14),

                  // Horizontal Category Chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ToolsData.categories.length,
                      itemBuilder: (context, index) {
                        final cat = ToolsData.categories[index];
                        final isSelected = cat.id == _selectedCat;
                        final countText = (cat.id == 'fav' && appState.favoriteToolIds.isNotEmpty)
                            ? ' (${appState.favoriteToolIds.length})'
                            : '';

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('${cat.icon} ${cat.translationKey}$countText'),
                            selected: isSelected,
                            selectedColor: AppColors.darkPrimary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF0A1128) : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            backgroundColor: Theme.of(context).cardColor,
                            onSelected: (_) {
                              setState(() {
                                _selectedCat = cat.id;
                                _renderLimit = 30;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tools Grid
          if (visibleTools.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('🔍 No tools found matching criteria', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tool = visibleTools[index];
                    final isFav = appState.isFavorite(tool.id);

                    return InkWell(
                      onTap: () {
                        showDialog(context: context, builder: (_) => CalculatorDialog(tool: tool));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkIconBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(tool.icon, style: const TextStyle(fontSize: 19)),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    size: 18,
                                    color: isFav ? Colors.amber : Colors.grey,
                                  ),
                                  onPressed: () => appState.toggleFavorite(tool.id),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              tool.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tool.description,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: visibleTools.length,
                ),
              ),
            ),

          if (list.length > _renderLimit)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.darkPrimary),
                    foregroundColor: AppColors.darkPrimary,
                  ),
                  onPressed: () => setState(() => _renderLimit += 30),
                  child: Text('LOAD MORE (${_renderLimit}/${list.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
'''
with open("lib/screens/tools_screen.dart", "w", encoding="utf-8") as f:
    f.write(tools_screen_code)
print("  ✓ Updated lib/screens/tools_screen.dart")

# 5. Update ProfessionalScreen (lib/screens/professional_screen.dart)
prof_screen_code = '''import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/professional_data.dart';
import '../models/module_models.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_drawer.dart';

class ProfessionalScreen extends StatefulWidget {
  const ProfessionalScreen({super.key});

  @override
  State<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends State<ProfessionalScreen> {
  String _searchQuery = '';

  void _showModuleDetails(BuildContext context, ProfessionalModule m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.darkIconBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(m.icon, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.key.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              m.status == 'progress' ? 'In Development' : 'Planned Specification',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('📌 Architectural Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.fullDescription, style: const TextStyle(fontSize: 12, height: 1.5)),
                  ),
                  const SizedBox(height: 16),

                  const Text('🎯 Specific Professional Capabilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkPrimary)),
                  const SizedBox(height: 6),
                  ...m.uses.map((u) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✓ ', style: TextStyle(color: AppColors.darkPrimary, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(u, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),

                  const Text('🖥️ Interface & Canvas Specs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.screenDesign, style: const TextStyle(fontSize: 12, height: 1.5)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ProfessionalData.modules.where((m) {
      return m.fullDescription.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.key.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: const CommonAppBar(title: 'PROFESSIONAL CAD STUDIO', icon: '🖊️'),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).cardColor, Theme.of(context).scaffoldBackgroundColor],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROFESSIONAL CAD STUDIO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.darkPrimary)),
                  SizedBox(height: 10),
                  Text('Precision • Control • Documentation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Advanced CAD vector drafting, drafting standards, layers, and BIM export workflows.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                hintText: 'Search professional CAD modules...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Professional Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${filtered.length} modules', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final m = filtered[index];
                return InkWell(
                  onTap: () => _showModuleDetails(context, m),
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.darkIconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(m.icon, style: const TextStyle(fontSize: 18)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: m.status == 'progress' ? AppColors.statusProgressBg : AppColors.statusPlannedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                m.status == 'progress' ? 'In Progress' : 'Planned',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: m.status == 'progress' ? AppColors.statusProgressText : AppColors.statusPlannedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(m.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(m.fullDescription, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
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
'''
with open("lib/screens/professional_screen.dart", "w", encoding="utf-8") as f:
    f.write(prof_screen_code)
print("  ✓ Updated lib/screens/professional_screen.dart")

# 6. Update DesignScreen (lib/screens/design_screen.dart)
design_screen_code = '''import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/design_data.dart';
import '../models/module_models.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_drawer.dart';

class DesignScreen extends StatelessWidget {
  const DesignScreen({super.key});

  void _showModuleDetails(BuildContext context, DesignModule module) {
    final details = DesignData.moduleDetails[module.id] ?? {
      'name': 'Design Module',
      'desc': 'Architectural engineering module',
      'full': 'Building coordinated drawings and layouts.',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.darkIconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(module.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(details['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(details['desc']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text(details['full']!, style: const TextStyle(fontSize: 13, height: 1.5)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkPrimary.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Text('🛠️', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Interactive Editor In Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Full vector drawing and CAD editing tools are in active development.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'DESIGN STUDIO', icon: '📐'),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).cardColor, Theme.of(context).scaffoldBackgroundColor],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DESIGN STUDIO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.darkPrimary)),
                  SizedBox(height: 10),
                  Text('Turn concepts into coordinated designs.', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Start a design, review floor plans, or inspect building module specifications.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Design Modules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${DesignData.modules.length} modules', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: DesignData.modules.length,
              itemBuilder: (context, index) {
                final module = DesignData.modules[index];
                final details = DesignData.moduleDetails[module.id] ?? {'name': 'Module', 'desc': ''};

                return InkWell(
                  onTap: () => _showModuleDetails(context, module),
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.darkIconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(module.icon, style: const TextStyle(fontSize: 18)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: module.status == 'progress' ? AppColors.statusProgressBg : AppColors.statusPlannedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                module.status == 'progress' ? 'In Progress' : 'Planned',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: module.status == 'progress' ? AppColors.statusProgressText : AppColors.statusPlannedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(details['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(details['desc']!, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
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
'''
with open("lib/screens/design_screen.dart", "w", encoding="utf-8") as f:
    f.write(design_screen_code)
print("  ✓ Updated lib/screens/design_screen.dart")

# 7. Update HomeScreen (lib/screens/home_screen.dart) with Professional section AT THE BOTTOM / LAST
home_screen_code = '''import 'package:flutter/material.dart';
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
                          'Turn your ideas into\\nprofessional drawings.',
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
'''
with open("lib/screens/home_screen.dart", "w", encoding="utf-8") as f:
    f.write(home_screen_code)
print("  ✓ Updated lib/screens/home_screen.dart")

# 8. Update main.dart to start HomeScreen directly
main_code = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_themes.dart';
import 'providers/app_state_provider.dart';
import 'providers/project_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const ArchitectEngineApp(),
    ),
  );
}

class ArchitectEngineApp extends StatelessWidget {
  const ArchitectEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return MaterialApp(
      title: 'Architect Engine',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: appState.themeMode,
      home: const HomeScreen(),
    );
  }
}
'''
with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(main_code)
print("  ✓ Updated lib/main.dart")
print("\n🎉 All updates successfully configured!")
